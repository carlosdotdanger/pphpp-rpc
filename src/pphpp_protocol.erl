-module(pphpp_protocol).
-behaviour(gen_server).

-include ("mpack.hrl").

-define(SERVER, ?MODULE).


%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------

-export([start_link/4,reply/2,err_reply/3]).

%% ------------------------------------------------------------------
%% gen_server Function Exports
%% ------------------------------------------------------------------

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record (state, {sck,tpt,lp,opt,pool}).
%% ------------------------------------------------------------------
%% API Function Definitions
%% ------------------------------------------------------------------

start_link(ListenerPid, Socket, Transport, Opts) ->
%	error_logger:info_msg("called mpack_protocol:start_link!~n",[]),
    gen_server:start_link(?MODULE, [ListenerPid, Socket, Transport, Opts], []).

reply(Pid,Data)->
	gen_server:cast(Pid,{reply,Data}).

err_reply(Pid,MsgId,Data)->
	gen_server:cast(Pid,{err_reply,MsgId,Data}).
%% ------------------------------------------------------------------
%% gen_server Function Definitions
%% ------------------------------------------------------------------
init([ListenerPid, Socket, Transport, Opts]) ->
	[Pool|_] = Opts,
    {ok, #state{sck = Socket,tpt = Transport, lp = ListenerPid, pool = Pool},0}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({reply,Data}, #state{tpt = Trans, sck = Sock}  = State) ->
	Trans:send(Sock,Data),
	Trans:setopts(Sock, [{active, once}]),
    {noreply, State};
handle_cast({err_reply,MsgId,Data}, #state{tpt = Trans, sck = Sock}  = State) ->
	Msg = err_msg(MsgId,Data),
	Trans:send(Sock,Msg),
	Trans:setopts(Sock, [{active, once}]),
    {noreply, State}.
handle_info({tcp,Socket, <<9:4,4:4,0:8,
						RawId:5/binary,
						_Rest/binary>> = Data}, 
						#state{tpt = Trans, pool = Pool}  = State) ->
	MsgId = case mpack:unpack(RawId) of 
		{ok,Val} -> Val;
		{ok,Val,_} -> Val;
		Err -> Err
	end,
	pphpp:handle_request(self(),Pool,MsgId,Data),
	Trans:setopts(Socket, [{active, once}]),
    {noreply, State};
handle_info({tcp,Socket, <<?FIX_ARR,3:4,2:8,_Rest/binary>> = Data},
									 #state{tpt = Trans, pool = Pool} = State) ->
	pphpp:handle_notify(self(),Pool,Data),
	Trans:setopts(Socket, [{active, once}]),
    {noreply, State};
handle_info({tcp,_Socket, <<Sample:8/binary,_Data/binary>>},State) ->
	error_logger:info_msg("got some weird shit! ~p~n",[Sample]),
			{stop,normal,State};
handle_info({tcp,_Socket, <<Sample:1/binary,_Data/binary>>},State) ->
	error_logger:info_msg("got some weird shit! ~p~n",[Sample]),
			{stop,normal,State};
handle_info({tcp_closed, _Socket},State)->
	{stop,normal,State};
handle_info({tcp_error, _Socket, Reason},State)->
	{stop,{tcp_error,Reason},State};
handle_info(timeout,#state{tpt = Tpt ,lp = LP,sck = Sck} = State)->
	Tpt:setopts(Sck, [{active, once}]),
	ok = ranch:accept_ack(LP),
	{noreply,State}.

terminate(_Reason, #state{tpt = Trans, sck = Sock}) ->
	Trans:close(Sock),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------


err_msg(MsgId,Data)->
	mpack:pack([?RESP,MsgId,Data,nil]).

