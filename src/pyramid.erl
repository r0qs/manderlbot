%%%-------------------------------------------------------------------
%%% File    : pyramid.erl
%%% Author  : Dimitri Fontaine <dfontaine@mail.cvf.fr>
%%% Description : Implementation of french TV game � Pyramide �
%%%
%%% Created :  7 Nov 2002 by Dimitri Fontaine <dfontaine@mail.cvf.fr>
%%%-------------------------------------------------------------------
-module(pyramid).

-behaviour(gen_server).
%%--------------------------------------------------------------------
%% Include files
%%--------------------------------------------------------------------

%%--------------------------------------------------------------------
%% External exports
-export([start_link/0, setWord/3, start/4, guess/3]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-define(timeout, 5000).

%%====================================================================
%% External functions
%%====================================================================

%%--------------------------------------------------------------------
%% Function: start_link/0
%% Description: Starts the server
%%--------------------------------------------------------------------
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

setWord(Nick, Channel, Word) ->
    gen_server:call(?MODULE, {setWord, Nick, Channel, Word}, ?timeout).

start(Nick, Channel, Player2, Nguess) ->
    gen_server:call(?MODULE,
		    {start, Nick, Channel, Player2, Nguess}, ?timeout).

guess(Nick, Channel, Word) ->
    gen_server:call(?MODULE, {guess, Nick, Channel, Word}, ?timeout).

%%====================================================================
%% Server functions
%%====================================================================

%%--------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%%--------------------------------------------------------------------
init([]) ->
    {ok, []}.

%%--------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%%--------------------------------------------------------------------
handle_call({setWord, Nick, Channel, Word}, From, State) ->
    %% We receive the word to guess in private. The game has to be started
    %% to be able to set the word.
    case lists:keysearch({Nick, Channel}, 1, State) of
	{value, {{Player1, Channel}, noword, Player2, Nguess, Ntries}} ->
	    {reply, {ok, Word ++ " has been set"}, 
	     lists:keyreplace({Player1, Channel}, 1, State,
			      {{Player1, Channel},
			       Word, Player2, Nguess, Ntries})
	    };

	{value, {{Player1, Channel}, GWord, Player2, Nguess, Ntries}} ->
	    {reply,
	     {error, "word to guess has already been set to: " ++ GWord},
	     State};

	false ->
	    {reply, {error, "No game started"}, State}
    end;

handle_call({start, Nick, Channel, Player2, Nguess}, From, State) ->
    %% The game will start once the word to guess will be given in private
    %% We juste prepare and tell the players
    %% Attention: one game at a time !
   
    case lists:keysearch({Nick, Channel}, 1, State) of
	{value, _} ->
	    %% Game already started
	    {reply, {error, "Game already started"}, State};

	false ->
	    %% We can start a new game
	    NewState = [{{Nick, Channel}, noword, Player2, Nguess, 1}|State],
	    {reply,
	     {ok,
	      Nick ++ ": please give me the word to guess (pv)"}, NewState}
    end;

handle_call({guess, Nick, Channel, Word}, From, State) ->
    %% The second player is trying to guess the word
    case lists:keysearch(Nick, 3, State) of
	{value, {{Player1, Channel}, noword, Player2, Nguess, Ntries}} ->
	    {reply, {ko, Player2 ++ ": please wait for " ++
		     Player1 ++ " to give a word to guess"}, State};
	    
	{value, {{Player1, Channel}, Word, Player2, Nguess, Ntries}} ->
	    {reply, {ok, Player2 ++ " won in " ++ [48+Ntries] ++ " tries !"},
	     lists:keydelete({Player1, Channel}, 1, State)};
	 
	{value, {{Player1, Channel}, GWord, Player2, Nguess, Nguess}} ->
	    {reply, {ko, Player2 ++ " failed to guess the word: " ++ GWord},
	     lists:keydelete({Player1, Channel}, 1, State)};

	{value, {{Player1, Channel}, GWord, Player2, Nguess, Ntries}} ->
	    %% Don't forget to increment the Ntries
	    {reply, {ko, Player2 ++ ": try again ! "},
	     lists:keyreplace({Player1, Channel}, 1, State,
			     {{Player1, Channel},
			      GWord, Player2, Nguess, Ntries + 1})};
	 
	false ->
	    {reply, {ko, "No game started"}, State}
    end;

handle_call(Request, From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%%--------------------------------------------------------------------
handle_cast(Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%%--------------------------------------------------------------------
handle_info(Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%%--------------------------------------------------------------------
terminate(Reason, State) ->
    ok.

%%--------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%%--------------------------------------------------------------------
code_change(OldVsn, State, Extra) ->
    {ok, State}.

%%--------------------------------------------------------------------
%%% Internal functions
%%--------------------------------------------------------------------