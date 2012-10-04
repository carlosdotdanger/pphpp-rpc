-module(pphpp_protocol).
-behaviour(ranch_protocol).
-define(SERVER, ?MODULE).

-define (LISTEN_TIMEOUT, 60000).
-define (RECV_TIMEOUT, 10).
%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------


-export([start_link/4, init/4, err_reply/3,chk_msg/1]).

start_link(ListenerPid, Socket, Transport, Opts) ->
	Pid = spawn_link(?MODULE, init, [ListenerPid, Socket, Transport, Opts]),
	{ok, Pid}.

init(ListenerPid, Socket, Transport, Opts) ->
	[Pool] = Opts,
	Transport:setopts(Socket, [{active, false},{packet,raw}, binary]),
	loop(ranch:accept_ack(ListenerPid), Socket, Transport,Pool).


err_reply(Writr,MsgId,Dat)->
	Writr(mpack:pack([1,MsgId,Dat,nil])).

chk_msg(Dat) ->
	mpack:chk_msg(Dat).

%%INTERNALS
loop(ok, Socket, Transport,Pool) ->
	Status = case Transport:recv(Socket, 2, ?LISTEN_TIMEOUT) of
		%request - [type,msgid,func,[args]]
		{ok, <<9:4,4:4,0:8>>} ->
			do_request(Transport,Socket,Pool);
		%notify - [type,func,[args]]	
		{ok,<<9:4,3:4,2:8>>}->
			do_notify(Transport,Socket,Pool);
		Err -> Err
	end,
	loop(Status,Socket, Transport,Pool);
loop(_,Socket,Transport,_Pool)->
	ok = Transport:close(Socket).
	
do_request(Transport,Socket,Pool)->
	Readr = get_readr(Transport,Socket),
	Writr = get_writr(Transport,Socket),
	{ok,MsgId} = mpack_rpc:get_raw_msg(Readr),
	{ok,Fun} = mpack_rpc:get_raw_msg(Readr),
	{ok,Args} = mpack_rpc:get_raw_msg(Readr),
	pphpp:handle_request(Writr,Pool,<<9:4,4:4,0:8,MsgId/binary,Fun/binary,Args/binary>>,MsgId).
	
do_notify(Transport,Socket,Pool)->
	Readr = get_readr(Transport,Socket),
	{ok,Fun} = mpack_rpc:get_raw_msg(Readr),
	{ok,Args} = mpack_rpc:get_raw_msg(Readr),
	pphpp:handle_notify(Pool,<<9:4,3:4,2:8,Fun/binary,Args/binary>>).


get_readr(Transport,Socket)->
	fun(X) -> Transport:recv(Socket,X,?RECV_TIMEOUT) end.

get_writr(Transport,Socket)->
	fun(X) -> Transport:send(Socket,X) end.
