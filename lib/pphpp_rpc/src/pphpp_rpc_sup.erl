
-module(pphpp_rpc_sup).

-behaviour(supervisor).

%% API
-export([start_link/2,start_pool/1,stop_pool/1,restart_pool/1]).

%% Supervisor callbacks
-export([init/1]).

%% Helper macro for declaring children of supervisor
-define(CHILD(I,Args), {I, {I, start_link, [Args]}, permanent, 2000, supervisor, [I]}).

%% ===================================================================
%% API functions
%% ===================================================================

start_link(PoolSpecs,ServerSpecs) ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, [PoolSpecs,ServerSpecs]).

start_pool(PoolSpecs)->
	supervisor:start_child(?MODULE,?CHILD(php_pool_sup,PoolSpecs)).

stop_pool(PoolName)->
	supervisor:terminate_child(?MODULE,PoolName),
	supervisor:delete_child(?MODULE,PoolName).

restart_pool(PoolName)->
	supervisor:restart_child(?MODULE,PoolName).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([PoolSpecs,_ServerSpecs]) ->
	PoolSup = ?CHILD(php_pool_sup,PoolSpecs),
    {ok, { {one_for_one, 5, 10}, [PoolSup]} }.

