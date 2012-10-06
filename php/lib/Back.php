<?php
require_once dirname(__FILE__) . '/Future.php';

class MessagePackRPC_STDIO_Back
{
  public $size = 8192;
  protected static $shared_unpacker = null;
  protected $unpacker = null;

  public function __construct()
  {

    $this->unpacker = new MessagePackUnpacker();
  }

  public function __destruct()
  {
  }

  public function clientCallObject($code, $func, $args)
  {
    $data    = array();
    $data[0] = 0;
    $data[1] = $code;
    $data[2] = $func;
    $data[3] = $args;

    return $data;
  }


  public function readMsg($io) {
    stream_set_blocking($io, 0);
    while (!feof($io)) {
      $r = array($io);
      $n = null;
      stream_select($r, $n, $n, null);
      $read = fread($io, $this->size);
      if ($read === FALSE) throw new MessagePackRPC_Error_NetworkError(error_get_last());
      $this->unpacker->feed($read);
      if ($this->unpacker->execute()) {
        return $this->unpacker->data();
      }
    }
  }


  public function clientRecvObject($data)
  {
    $type = $data[0];
    $code = $data[1];
    $errs = $data[2];
    $sets = $data[3];

    if ($type != 1) {
      throw new MessagePackRPC_Error_ProtocolError("Invalid message type for response: {$type}");
    }

    $feature = new MessagePackRPC_Future();
    $feature->setErrors($errs);
    $feature->setResult($sets);

    return $feature;
  }

  public function serverSendObject($code, $sets, $errs)
  {
    $data    = array();
    $data[0] = 1;
    $data[1] = $code;
    $data[2] = $errs;
    $data[3] = $sets;

    $send = $this->msgpackEncode($data);

    return $send;
  }

  public function serverRecvObject($recv)
  {
    $data = $this->msgpackDecode($recv);

    if (count($data) != 4) {
      throw new MessagePackRPC_Error_ProtocolError("Invalid message structure.");
    }

    $type = $data[0];
    $code = $data[1];
    $func = $data[2];
    $args = $data[3];

    if ($type != 0) {
      throw new MessagePackRPC_Error_ProtocolError("Invalid message type for request: {$type}");
    }

    return array($code, $func, $args);
  }

  public function msgpackDecode($data)
  {
    return msgpack_unpack($data);
  }

  public function msgpackEncode($data)
  {
    return   msgpack_pack($data);
  }
}
