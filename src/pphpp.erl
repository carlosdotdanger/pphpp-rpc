-module(pphpp).

-export ([call/2,status/1,stop/1]).
-export([config_to_args/1,config_to_service_specs/1]).
-export ([handle_request/4,handle_notify/2]).

-export ([do_request/5,do_notify/3]).

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

handle_request(Writr,Pool,Data,MsgId)->
	F = fun(Pid) -> pphpp:call(Pid,Data) end,
	do_request(Writr, Pool, MsgId,F,1).

handle_notify(Pool,Data)->
	F = fun(Pid) -> 
		pphpp:call(Pid,Data) end,
		do_notify(Pool,F,1).

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
		X <-[Args,Env,Dir,binary,exit_status,stream], X =/= undefined],
	[{PhpExec,Opts},MaxCalls,CallTimeOut].

config_to_service_specs(Config) when is_list(Config)->
	[{Name,config_to_args(Conf)} || {Name,Conf} <- Config ].


%%INTERNAL
do_request(Writr,Pool,MsgId,F,?MAX_RETRIES)->
	case poolboy:transaction(Pool,F) of
		{error,{Type,Dat}} -> pphpp_protocol:err_reply(Writr,MsgId,[Type,Dat]);
		{ok,Resp} -> Writr(Resp)
	end;
do_request(Writr,Pool, MsgId, F,Count)->
	case poolboy:transaction(Pool,F) of
		{error,_} -> do_request(Writr,Pool, MsgId,F,Count + 1);
		{ok,Resp} -> Writr(Resp)
	end.

do_notify(Pool,F,?MAX_RETRIES)->
	case poolboy:transaction(Pool,F) of
		{error,{Type,Dat}} -> {error,{Type,Dat}};
		_ -> ok
	end;
do_notify(Pool,F,Count)->
	case poolboy:transaction(Pool,F) of
		{error,_} -> do_notify(Pool,F,Count + 1);
		_ -> ok
	end.
