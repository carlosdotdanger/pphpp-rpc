-module(pphpp_rpc_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    Pools =  case application:get_env(pphpp_rpc, pools) of
    			{ok,X} -> X;
    			_ -> []
    		end,
    PoolSpecs = lists:map(fun({Name, SizeArgs, WorkerArgs}) ->
        PoolArgs = [{name, {local, Name}},
            		{worker_module, pphpp_worker}] ++ SizeArgs,
        poolboy:child_spec(Name, PoolArgs, pphpp:config_to_args(WorkerArgs))
    end, Pools),
    {ok, Pid} = pphpp_rpc_sup:start_link(PoolSpecs,[]),
    Servers = case application:get_env(pphpp_rpc, servers) of
                {ok,Srvrs} -> Srvrs;
                _ -> []
             end,
 error_logger:info_msg("SERVERS ~p~n",[Servers]),
    [{ok, _} = ranch:start_listener(Name, 1,
        ranch_tcp, TcpOpts, pphpp_protocol, PphppArgs) || 
                    {Name,TcpOpts,PphppArgs} <- Servers  ],
    {ok,Pid}.
   % php_pool_sup:start_link(PoolSpecs).
stop(_State) ->
    ok.
