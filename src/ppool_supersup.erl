-module(ppool_supersup).
-behavior(supervisor).
-export([start_link/0, start_pool/3, stop_pool/1, stop/0]).
-export([init/1]).

start_link() ->
    supervisor:start_link({local, ppool}, ?MODULE, []).

%% a supervisor cannot be killed in an easy way so we do it brutally
stop() ->
    case whereis(ppool) of 
        P when is_pid(P) ->
            exit(P, kill);
            _ -> ok
    end.

% What is the top-level supervisor exactly? Well, its only task is to hold
% pools in memory and supervise them. In this case, it will be a childless
% supervisor.
init([]) ->
    MaxRestart = 6,
    MaxTime = 3600,
    {ok, {{one_for_one, MaxRestart, MaxTime}, []}}.

    % Given our initial requirements, we can determine
    % that we’ll need two parameters: the number of workers the pool will accept
    % and the {M,F,A} tuple that the worker supervisor will need to start each worker.
    % We’ll also add a name for good measure. We then pass this ChildSpec to the
    % process pool’s supervisor as we start it.
start_pool(Name, Limit, MFA) ->
    ChildSpec = {Name,
                {ppool_sup, start_link, [Name, Limit, MFA]},
                permanent, 10500, supervisor, [ppool_sup]},
    supervisor:start_child(ppool, ChildSpec).

stop_pool(Name) ->
    supervisor:terminate_child(ppool, Name),
    supervisor:delete_child(ppool, Name).

