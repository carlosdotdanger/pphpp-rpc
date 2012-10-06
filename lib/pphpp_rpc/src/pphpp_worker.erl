-module(pphpp_worker).
-behaviour(gen_server).
-define(SERVER, ?MODULE).

%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------

-export([start_link/1,php_call/3,stop/1, status/1]).

%% ------------------------------------------------------------------
%% gen_server Function Exports
%% ------------------------------------------------------------------

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {status,calls=0,max_calls,call_timeout,port,reply_to}).

%% ------------------------------------------------------------------
%% API Function Definitions
%% ------------------------------------------------------------------

start_link([PHPSpec,MaxCalls,CallTimeout]) ->
    gen_server:start_link( ?MODULE, [PHPSpec,MaxCalls,CallTimeout], []).

php_call(Pid,ReplyTo,Payload)->
	gen_server:cast(Pid,{php_call,ReplyTo,Payload}).

stop(Pid)->
	gen_server:cast(Pid,stop).

status(Pid)->
	gen_server:call(Pid,status).

%% ------------------------------------------------------------------
%% gen_server Function Definitions
%% ------------------------------------------------------------------

init([PHPSpec,MaxCalls,CallTimeout]) ->
	process_flag(trap_exit,true),
    {ok, 	
    #state{status = ready, 
		call_timeout = CallTimeout, 
		max_calls = MaxCalls,
		port = php_port(PHPSpec)
	}}.


handle_call(status,_From,
		#state{calls = Calls, max_calls = MaxCalls, port = Port} = State)->
	{reply,{{port,Port},{calls,Calls},{ttl,MaxCalls - Calls}},State}.

handle_info({Port,{data,Response}}, 
	#state{port = Port,status = resp_wait, calls = Hits, reply_to = ReplyTo} = State) ->
	ReplyTo ! {ok,Response},
	case Hits < State#state.max_calls of
		true ->
			{noreply, State#state{calls = Hits + 1, status = ready, reply_to = undefined}};
		false ->
			{noreply, State#state{status = retired},0}
	end;
handle_info({Port,{exit_status,Es}}, #state{status = resp_wait, reply_to = ReplyTo} = State)->
	ReplyTo ! {error,{php_exit,Es}},
	error_logger:info_msg("pphpp_worker exit during call {~p,{exit_status,~p}}.~n",[Port,Es]),
	{stop,normal,State#state{status = {exit_status,Es}}};
handle_info({Port,{exit_status,Es}},State)->
	error_logger:info_msg("pphpp_worker exit while idle {~p,{exit_status,~p}}.~n",[Port,Es]),
	{stop,normal,State#state{status = {exit_status,Es}}};
handle_info({'EXIT',Port,Reason}, #state{ status = resp_wait, reply_to = ReplyTo} = State)->
	ReplyTo ! {error,{php_exit,unknown_server_error}},
	error_logger:info_msg("pphpp_worker got EXIT during call- ~n~p~n~p~n~p~n",[State,Port,Reason]),
	{stop,normal,State};
handle_info({'EXIT',_,shutdown},State)->
	error_logger:info_msg("pphpp_worker got {EXIT,_,shutdown} - ~p ~n",[State]),
	{stop,normal,State};
handle_info(timeout,#state{status = resp_wait, reply_to = ReplyTo, call_timeout = TO} = State)->
	ReplyTo ! {error,{php_timeout,TO}},
	{stop,normal,State#state{status = php_timeout}};
handle_info(timeout,State)->
	error_logger:info_msg("pphpp_worker timeout - ~n~p~n",[State]),
	{stop,normal,State}.

handle_cast({php_call,ReplyTo,Data}, 
		#state{calls = Hits, status=ready, port = Port, call_timeout = TO} = State) ->
	erlang:port_command(Port,Data),
	{noreply,State#state{reply_to = ReplyTo, status = resp_wait, calls = Hits + 1},TO};
handle_cast({php_call,ReplyTo,_}, #state{status = Status} = State) ->
	ReplyTo ! {error,{not_ready,Status}},
	{noreply, State};
handle_cast(stop, State) ->
    {stop,normal, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------
php_port({PhpExec,PortOpts})->
	open_port({spawn_executable,PhpExec},PortOpts).
