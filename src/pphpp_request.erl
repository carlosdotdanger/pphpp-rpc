-module (pphpp_request).

-export ([handle_request/4,handle_notify/3]).
-define (MAX_RETRIES, 2).


handle_request(From,Pool,MsgId,Data)->
	F = fun(Pid) -> pphpp:call(Pid,Data) end,
	spawn(?MODULE,do_request(From,Pool, MsgId,F,1)).

handle_notify(From,Pool,Data)->
	F = fun(Pid) -> pphpp:call(Pid,Data) end,
	spawn(?MODULE,do_notify(From,Pool,F,1)).


do_request(From,Pool,MsgId,F,?MAX_RETRIES)->
	case poolboy:transaction(Pool,F) of
		{error,{Type,Dat}} -> pphpp_protocol:err_reply(From,MsgId,[Type,Dat]);
		Resp -> pphpp_protocol:reply(From,Resp)
	end;
do_request(From,Pool,MsgId, F,Count)->
	case poolboy:transaction(Pool,F) of
		{error,_} -> do_request(From,Pool, MsgId,F,Count +1);
		Resp -> pphpp_protocol:reply(From,Resp)
	end.

do_notify(_From,Pool,F,?MAX_RETRIES)->
	case poolboy:transaction(Pool,F) of
		{error,{Type,Dat}} -> {error,{Type,Dat}};
		_ -> ok
	end;
do_notify(From,Pool,F,Count)->
	case poolboy:transaction(Pool,F) of
		{error,_} -> do_notify(From,Pool,F,Count +1);
		_ -> ok
	end.
