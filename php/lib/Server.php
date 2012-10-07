<?php
if (!extension_loaded('msgpack')) {
    if (!dl('msgpack.so')) {
        exit(101);
    }
}
require_once dirname(__FILE__) . '/Back.php';

class MessagePackRPC_STDIO_Server
{
  public $back = null;
  public $hand = null;

  public function __construct($hand, $back = null)
  {
    $this->back = $back == null ? new MessagePackRPC_STDIO_Back() : $back;
    $this->hand = $hand;
  }

  public function __destruct()
  {
    
  }


  public function recv()
  {
    $hand = $this->hand;
    try {
      while (TRUE) {
            try {
            $len_s =fread(STDIN,4);
            $len  = array_pop(unpack('N', $len_s));
            if(feof(STDIN))
              break;  
            $data = "";
            while (strlen($data) < $len) {
             $data .= fread(STDIN,$len);
            }
            
            if(feof(STDIN))
              break;
            list($code, $func, $args) = $this->back->serverRecvObject($data);
      	    $error = null;
      	    
      	      $ret = call_user_func_array(array($hand, $func), $args);
      	    } catch (Exception $e) {
      	      $ret = null;
      	      $error = $e->__toString();
      	    }
            $send = $this->back->serverSendObject($code, $ret, $error);
            fwrite(STDOUT,pack('N',strlen($send)).$send);
            fflush(STDOUT);
            unset($error);
            unset($send);
            unset($ret);
            unset($data);
            unset($code);
            unset($func);
            unset($args);
      }
    } catch (Exception $e) {
      exit(86);
    }
  }
}
