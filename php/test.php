<?php
// Please run client.php
include_once dirname(__FILE__) . '/lib/Back.php';
include_once dirname(__FILE__) . '/lib/Future.php';
include_once dirname(__FILE__) . '/lib/Server.php';

class App
{
  public function hello1($a)
  {
    return $a + 1;
  }

  public function hello2($a)
  {
    return $a + 2;
  }

  public function fail()
  {
    throw new Exception('hoge');
  }

  public function big($in,$num=1024){
		$out = $in;
		for($x =0; $x< $num;$x++){
			$out .= $in;
		}
		return $out;
	}

	public function breakme($signal)
	{
		exit(intval($signal));
	}
}

function testIs($no, $a, $b)
{
  if ($a === $b) {
    echo "OK:{$no}/{$a}/{$b}\n";
  } else {
    echo "NO:{$no}/{$a}/{$b}\n";
  }
}





try {
  $server = new MessagePackRPC_STDIO_Server( new App());
  $server->recv();
} catch (Exception $e) {
  echo $e->getMessage() . "\n";
}
exit;
