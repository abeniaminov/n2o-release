-module(index).
-compile(export_all).
-include_lib("n2o/include/wf.hrl").

main() -> #template { file= code:priv_dir(web) ++ "/templates/index.html" }.
title() -> <<"N2O">>.

body() -> %% area of http handler
    {ok,Pid} = wf:comet(fun() -> chat_loop() end),
  [ #span { text= <<"Your chatroom name: ">> }, 
    #textbox { id=userName, text= <<"Anonymous">> },
    #panel { id=chatHistory, class=chat_history },
    #button{id=but,text="Click Me!",postback=change_me},
    #button{text="Replace Body",postback=replace},
    #textbox { id=message },
    #button { id=sendButton, text= <<"Chat">>, postback={chat,Pid}, source=[userName,message] },
    #panel { id=n2ostatus } ].

event(change_me) ->
    wf:replace(but,
        #link{
            url="http://erlang.org",
            text="Here's Erlang",
            actions=#show{effect=fade}
        }
    );

event(replace) ->
    action_redirect:redirect_nodrop("hello.html");

event({chat,Pid}) -> %% area of websocket handler
    Username = wf:q(userName),
    Message = wf:q(message),
    Terms = [ #span { text= <<"Message sent">> }, #br{} ],
    wf:insert_bottom(chatHistory, Terms),
    wf:wire("$('#message').focus(); $('#message').select(); "),
    wf:reg(room),
    Pid ! {message, Username, Message};

event(Event) -> error_logger:info_msg("Event: ~p", [Event]).

chat_loop() -> %% background worker ala comet
    receive 
        {message, Username, Message} ->
            Terms = [ #span { text=Username }, ": ",
                      #span { text=Message }, #br{} ],
            wf:insert_bottom(chatHistory, Terms),
            wf:wire("$('#chatHistory').scrollTop = $('#chatHistory').scrollHeight;"),
            wf:flush(room); %% we flush to websocket process by key
        Unknown -> error_logger:info_msg("Unknown Looper Message ~p",[Unknown])
    end,
    chat_loop().
