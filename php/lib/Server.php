<?php
require_once dirname(__FILE__) . '/Back.php';

class MessagePackRPC_STDIO_Server
{
  public $back = null;
  public $hand = null;

  public function __construct($hand, $back = null)
  {
    $this->back = $back == null ? new MessagePackRPC_Back() : $back;
    $this->hand = $hand;
  }

  public function __destruct()
  {
    
  }


  public function recv()
  {$hand = $this->hand;
    try {
      while (TRUE) {
 
            $data = fread(STDIN, 8192);
            list($code, $func, $args) = $this->back->serverRecvObject($data);
      	    $error = null;
      	    try {
      	      $ret = call_user_func_array(array($hand, $func), $args);
      	    } catch (Exception $e) {
      	      $ret = null;
      	      $error = $e->__toString();
      	    }
            $send = $this->back->serverSendObject($code, $ret, $error);
            fwrite(STDOUT,$send);
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
      // TODO:
    }
  }
}
