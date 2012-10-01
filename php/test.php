<?php
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
		$out = $handler->do_it($in);
		fwrite(STDOUT,pack('N',strlen($out)).$out);
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
	public function do_it($raw_input){
		return strrev($raw_input);
	}

	public function shutdown(){
		return;
	}
}


//MAIN

$app = new Reverser();
pphpp_loop($app);
