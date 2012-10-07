<?php
//ini_set('memory_limit', '128M');
include_once dirname(__FILE__) . '/lib/Server.php';

class ExampleApp
{

  private $descriptions  = array(
    'hello' => 
      array('args'=> 'a: mixed','return' => 'string', 'desc'=>'prepends hello to input'),
    'big' => 
      array('args'=> 'in: mixed, num: int','return' => 'string', 'desc'=>'concats $in to itself to the power of $num'),
    'reverse_and_multiply' => 
      array('args'=> 'in: mixed, num: int','return' => 'string', 'desc'=>'reverses $in and concats to itself $num times'),
    'ping' => 
      array('args'=> 'none','return' => 'string', 'desc'=>'returns pong'),
    'make_exception' => 
      array('args'=> 'message: mixed','return' => 'error message', 'desc'=>'throws an exception'),
    'hang' => 
      array('args'=> 'seconds: int','return' => 'array', 'desc'=>'calls sleep($seconds) and then returns report.'),
    'services' => 
      array('args'=> 'func: string','return' => 'array', 'desc'=>'this function. returns description of $func or all functions if null')
   );
  //your funcs here
  public function hello($a){
    return 'hello '.$a;
  }

  public function big($in,$num=8){
		$out = $in;
		for($x = 0; $x< $num;$x++){
			$out .= $out;
		}
		return $out;
	}

  public function reverse_and_multiply($in,$num){
    $b = strrev($in);
    $out = "";
    for($x=0;$x < $num ;$x++){
      $out .= $b;
    }
    return $out;
  }
 
 public function ping($whatev = NULL){
  return 'pong';
 }

//list available interface
public function services($whatev = NULL){
  if($whatev)
    return array($whatev=>$this->descriptions[$whatev]);
  else
    return $this->descriptions;
}
//ERROR TESTS

 public function make_exception($message){
    throw new Exception($message);
  }

  public function exit_with($signal){
    exit(intval($signal));
  }

  public function hang($seconds){
    sleep($seconds);
    return array('STATUS'=>'ok', 'SLEPT_FOR' => $seconds);
  }

}



//MAIN LOOP

$server = new MessagePackRPC_STDIO_Server(new ExampleApp());
$server->recv();
exit(0);
