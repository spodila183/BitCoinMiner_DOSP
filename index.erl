  %%%-------------------------------------------------------------------
  %%% @author sharathbhushanpodila
  %%% @copyright (C) 2022, <COMPANY>
  %%% @doc
  %%%
  %%% @end
  %%% Created : 17. Sep 2022 2:28 PM
  %%%-------------------------------------------------------------------
  -module(index).

  -export([client_generateRandomString/4, server_start/1, server_getHashCode/3, generateRandomString/2,
    server_printBitCoin/2, server_for/2, server_message_client/2, client_message_server/0,
    client_getHashCode/5, client_start/2, main/0]).


  client_message_server() ->
    receive
      {get_started, K,CompareString,Client_id, Server_id} ->
        client_generateRandomString(K, CompareString,Client_id, Server_id)
    end.

  client_generateRandomString(K, CompareString,Client_id, Server_id) ->
    GeneratedString = base64:encode_to_string(crypto:strong_rand_bytes(100)),
    UpdatedString = string:concat("spodila", GeneratedString),
    client_getHashCode(K, UpdatedString, CompareString,Client_id, Server_id).

  client_getHashCode(K, RandomString, CompareString,Client_id,Server_id) ->
    HashedString = io_lib:format("~64.16.0b", [binary:decode_unsigned(crypto:hash(sha256, RandomString))]),
    SubString = string:sub_string(HashedString, 1, K),
    NextChar = string:sub_string(HashedString, K + 1, K + 1),
    Bool = string:equal(SubString, CompareString) and not string:equal(NextChar, "0"),
    %change the print statement on client terminal
    if Bool ->
      Server_id ! {eureka,Client_id, HashedString},
      client_generateRandomString(K, CompareString,Client_id,Server_id);
      true ->
        client_generateRandomString(K, CompareString,Client_id,Server_id)
    end.

  server_message_client(K,CompareString) ->
    receive
      {started, Client_id} ->
        io:format("~p~n",[Client_id]),
        Client_id ! {get_started, K,CompareString,Client_id,self()},
        server_message_client(K,CompareString);
      {eureka,Client_id, Coin} ->
        server_printBitCoin(Client_id,Coin),
        server_message_client(K,CompareString)
    end,
    server_message_client(K,CompareString).

  generateRandomString(K, CompareString) ->
    GeneratedString = base64:encode_to_string(crypto:strong_rand_bytes(100)),
    UpdatedString = string:concat("spodila", GeneratedString),
    server_getHashCode(K, UpdatedString, CompareString).

  server_getHashCode(K, RandomString, CompareString) ->
    HashedString = io_lib:format("~64.16.0b", [binary:decode_unsigned(crypto:hash(sha256, RandomString))]),
    SubString = string:sub_string(HashedString, 1, K),
    NextChar = string:sub_string(HashedString, K + 1, K + 1),
    Bool = string:equal(SubString, CompareString) and not string:equal(NextChar, "0"),
    if Bool ->
      server_printBitCoin(server,HashedString),
      generateRandomString(K, CompareString);
      true ->
        generateRandomString(K, CompareString)
    end.

  server_printBitCoin(Client_id,BitCoin) ->
    io:fwrite("~p",[Client_id]),
    io:fwrite("\n"),
    io:fwrite(BitCoin),
    io:fwrite("\n").

  server_for(List, 0) ->
    lists:concat(List);

  server_for(ZeroList, N) when N > 0 ->
    UpdateList = ZeroList ++ [0],

    server_for(UpdateList, N - 1).

  server_start(K) ->
    CompareString = server_for([], K),
    %register(server, spawn(index, generateRandomString, [K, CompareString])),
    Pid = spawn(index, server_message_client, [K,CompareString]),
    client_start(Pid,1).

  client_start(Server_id,0)->
    done;

  client_start(Server_id,Count) ->
    io:fwrite("~w",[Count]),
    Pid = spawn(index,client_message_server,[]),
    timer:kill_after(timer:seconds(10), Pid),
    Server_id ! {started, Pid},
    client_start(Server_id,Count-1).

  main()->
    {ok, K} = io:read("Enter K value"),
    server_start(K).
