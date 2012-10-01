
-module(php_pool_sup).

-behaviour(supervisor).

%% API
-export([start_link/0,start_link/1]).

%% Supervisor callbacks
-export([init/1]).

%% ===================================================================
%% API functions
%% ===================================================================

start_link()->
	start_link([]).
start_link(PoolSpecs) ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, PoolSpecs).


%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init(PoolSpecs) ->
    {ok, { {one_for_one, 5, 10}, PoolSpecs} }.

