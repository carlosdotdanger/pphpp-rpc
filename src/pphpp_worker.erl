-module(pphpp_worker).
-behaviour(gen_server).
-define(SERVER, ?MODULE).

%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------

-export([start_link/1,php_call/2,stop/1, status/1]).

%% ------------------------------------------------------------------
%% gen_server Function Exports
%% ------------------------------------------------------------------

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {status,calls=0,max_calls,call_timeout,port}).

%% ------------------------------------------------------------------
%% API Function Definitions
%% ------------------------------------------------------------------

start_link([PHPSpec,MaxCalls,CallTimeout]) ->
    gen_server:start_link( ?MODULE, [PHPSpec,MaxCalls,CallTimeout], []).

php_call(Pid,Payload)->
	gen_server:call(Pid,{php_call,Payload}).

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

handle_call({php_call,Data},_Frm, 
		#state{calls = Hits, status=ready, port = Port} = State) ->
	erlang:port_command(State#state.port,Data),
	receive 
		{Port,{data,Response}} ->
			NewHits = Hits + 1,
			case NewHits < State#state.max_calls of
				true ->
					{reply, {ok,Response}, State#state{calls = NewHits}};
				false ->
					{reply, {ok,Response}, State#state{status = retired},0}
				end;
    	Err ->
     		{reply, {error,Err}, State#state{status=err},0}
    after State#state.call_timeout ->
    	{reply,{error,timeout},State#state{status=err},0}
    end;
handle_call({php_call,_}, _From, #state{status = Status} = State) ->
	{reply, {error,{not_ready,Status}}, State};
handle_call(status,_From,
		#state{calls = Calls, max_calls = MaxCalls, port = Port} = State)->
	{reply,{{port,Port},{calls,Calls},{ttl,MaxCalls - Calls}},State}.

handle_info({_,{exit_status,Es}},State)->
	{stop,normal,State#state{status = {exit_status,Es}}};
handle_info({'EXIT',_,shutdown},State)->
	{stop,normal,State};
handle_info(timeout,State)->
	{stop,normal,State}.

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
