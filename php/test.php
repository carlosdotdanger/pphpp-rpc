<?php
dl('msgpack.so');
//call after all init is finished
function pphpp_loop($handler)
{
	while(1){
		$in = "";
		$out = "";
		$len_s =fread(STDIN,4);
		if(feof(STDIN))
			break;	
		$in = fread(STDIN,array_pop(unpack('N', $len_s)));
		if(feof(STDIN))
			break;


		list($type,$id,$f,$args) = msgpack_unpack($in);
		$out = $handler->do_it($f,$args);
		$msg = msgpack_pack(array(1,$id,NULL,$out));
		fwrite(STDOUT,pack('N',strlen($msg)).$msg);
		fflush(STDOUT);
		unset($in);
		unset($out);
		unset($len_s);
	}
	//cleanup
	$handler->shutdown();
	exit(0);
}


//requset handler
class Reverser{
	public function do_it($f,$args){
		list($s,$num) = $args;

		$b = strrev($s);
		$out = "";
		for($x=0;$x < $num ;$x++){
			$out .= $b;
		}
		return $out;
	}

	public function shutdown(){
	
	}
}


//MAIN

$app = new Reverser();
pphpp_loop($app);
