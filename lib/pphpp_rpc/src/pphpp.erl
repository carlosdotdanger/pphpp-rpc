-module(pphpp).

-export ([call/2,status/1,stop/1]).
-export([config_to_args/1,config_to_service_specs/1]).
-export ([handle_request/4,handle_notify/3]).
-export ([do_request/5]).

-define (MAX_RETRIES, 2).
-define (DEFAULT_CALL_TIMEOUT, 2000).
-define (DEFAULT_MAX_CALLS, 100).


%%API
call(Pid,Data)->
	pphpp_worker:php_call(Pid,Data).

status(Pid)->
	pphpp_worker:status(Pid).

stop(Pid)->
	pphpp_worker:stop(Pid).

handle_request(From,Pool,MsgId,Data)->
	F = fun(Pid) -> pphpp:call(Pid,Data) end,
	spawn(?MODULE,do_request,[From,Pool, MsgId,F,1]).

handle_notify(From,Pool,Data)->
	F = fun(Pid) -> pphpp:call(Pid,Data) end,
	spawn(?MODULE,do_notify(From,Pool,F,1)).

config_to_args(Config)->
	PhpExec =  proplists:get_value(php_exec,Config),
	Script =  proplists:get_value(php_script,Config),
	CallTimeOut = 
		proplists:get_value(php_call_timeout,Config,?DEFAULT_CALL_TIMEOUT),
	MaxCalls = proplists:get_value(php_max_calls,Config,?DEFAULT_MAX_CALLS),
	Args = case proplists:get_value(php_args,Config) of
			undefined -> {args,[Script]};
			A -> {args,[Script|A]}
		end,
	Dir = case proplists:get_value(php_working_dir,Config) of
			undefined -> undefined;
			D -> {dir,D}
		end,
	Env = case proplists:get_value(php_env,Config) of
			undefined -> undefined;
			E -> {env,E}
		end,	
	Opts = [ X || 
		X <-[Args,Env,Dir,binary,exit_status,{packet,4}], X =/= undefined],
	[{PhpExec,Opts},MaxCalls,CallTimeOut].

config_to_service_specs(Config) when is_list(Config)->
	[{Name,config_to_args(Conf)} || {Name,Conf} <- Config ].


%%INTERNAL
do_request(From,Pool,MsgId,F,?MAX_RETRIES)->
	case poolboy:transaction(Pool,F) of
		{ok,Resp} -> pphpp_protocol:reply(From,Resp);
		{error,{Type,Dat}} -> pphpp_protocol:err_reply(From,MsgId,[Type,Dat]);
		_Err -> pphpp_protocol:err_reply(From,MsgId,[unknown_err])
	end;
do_request(From,Pool,MsgId, F,Count)->
	case poolboy:transaction(Pool,F) of
		{ok,Resp} -> pphpp_protocol:reply(From,Resp);
		{error,_} -> spawn(?MODULE,do_request,[From,Pool, MsgId,F,Count +1])
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
