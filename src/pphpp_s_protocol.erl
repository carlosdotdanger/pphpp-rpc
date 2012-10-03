-module(pphpp_s_protocol).
-behaviour(ranch_protocol).
-define(SERVER, ?MODULE).
-include("mpack.hrl").

-define (LISTEN_TIMEOUT, 60000).
-define (RECV_TIMEOUT, 10).
%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------


-export([start_link/4, init/4]).

start_link(ListenerPid, Socket, Transport, Opts) ->
	Pid = spawn_link(?MODULE, init, [ListenerPid, Socket, Transport, Opts]),
	{ok, Pid}.

init(ListenerPid, Socket, Transport, Opts) ->
	[Pool] = Opts,
	Transport:setopts(Socket, [{active, false},{packet,raw}, binary]),
	loop(ranch:accept_ack(ListenerPid), Socket, Transport,Pool).

loop(ok, Socket, Transport,Pool) ->
	Status = case Transport:recv(Socket, 2, ?LISTEN_TIMEOUT) of
		%request - [type,msgid,func,[args]]
		{ok, <<?FIX_ARR,4:4,0:8>>} ->
			do_request(Transport,Socket,Pool);
		%notify - [type,func,[args]]	
		{ok,<<?FIX_ARR,3:4,2:8>>}->
			do_notify(Transport,Socket,Pool);
		Err -> Err
	end,
	loop(Status,Socket, Transport,Pool);
loop(_,Socket,Transport,_Pool)->
	ok = Transport:close(Socket).
	
do_request(Transport,Socket,Pool)->
	Readr = get_readr(Transport,Socket),
	MsgId = mpack_rpc:get_raw_msg(Readr),
	Fun = mpack_rpc:get_raw_msg(Readr),
	Args = mpack_rpc:get_raw_msg(Readr),
	pphpp:handle_request(Transport,Socket,Pool,<<?FIX_ARR,4:4,0:8,MsgId/binary,Fun/binary,Args/binary>>).
	
do_notify(Transport,Socket,Pool)->
	Readr = get_readr(Transport,Socket),
	Fun = mpack_rpc:get_raw_msg(Readr),
	Args = mpack_rpc:get_raw_msg(Readr),
	pphpp:handle_notify(Transport,Socket,Pool,<<?FIX_ARR,3:4,2:8,Fun/binary,Args/binary>>).


get_readr(Transport,Socket)->
	fun(X) -> Transport:recv(Socket,X,?RECV_TIMEOUT) end.
