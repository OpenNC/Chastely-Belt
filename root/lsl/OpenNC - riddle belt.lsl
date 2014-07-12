////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                            OpenNC - riddle belt                                //
//                            version 3.968                                       //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.                                      //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2013  Individual Contributors and OpenCollar - submission set free™ //
// ©   2013 - 2014  OpenNC                                                        //
// ------------------------------------------------------------------------------ //
// Not now supported by OpenCollar at all                                         //
////////////////////////////////////////////////////////////////////////////////////

// --- MESSAGE MAP conform with OC ---
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer CHAT = 505;
integer POPUP_HELP = 1001;
integer HTTPDB_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//str must be in form of "token=value"
integer HTTPDB_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer HTTPDB_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer HTTPDB_DELETE = 2003;//delete token from DB
integer HTTPDB_EMPTY = 2004;//sent when a token has no value in the httpdb
integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer SUBMENU = 3002;
integer MENUNAME_REMOVE = 3003;

// --- END MESSAGE MAP ---

float waittime = 300;
float gettime;

integer counter;
integer debugger = 1;
integer dialogtoggle;
integer findletter;
integer i;
integer index;
integer index2;
integer length;
integer listen_menu;
integer locked = FALSE;
integer menuchan;
string newwords;
integer NotecardLine = 0;
integer num_notecard_lines = 0;
integer notecard_line = 0;
integer random;
integer strlen;
integer timeout = 300;
integer trials;

string button;
string ButtonsString;
string FirstLetter;
string FirstName;
string letter;

string alphabet = "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz";
string GuessedLetters = "";
string newdata;
string NewWord = "";
string NotecardName = "encrypted";
string ObjectShortName = "Chastity Belt";
string parentmenu = "Main1"; //so it no longer shows in main menu NG
string randomletter;
string RcvdSecretWord;
string SafedWord;
string SecretWord;
string submenu = "PickLock";
string SubOwnerName;
string timertext;
string word;

list buttons;
list mybuttons;
list card_data; // the data in the card

key wearer;
key SubOwnerKey;
key id = NULL_KEY;
key notecard_request = NULL_KEY;
key pick;

// ------------------------ functions -------------------------------- //

string GetDBPrefix()
{//get db prefix from list in object desc
    return llList2String(llParseString2List(llGetObjectDesc(), ["~"], []), 2);
}

generateSecretWord(list allwords)
{
    random = llFloor(llFrand(llGetListLength(allwords+1)));
    RcvdSecretWord = llToLower((string)llList2List(allwords,random,random));
    index = llStringLength(RcvdSecretWord);
    i=0;
    SecretWord = "";
    for(;i < index; ++i)
    {
        letter = llGetSubString(RcvdSecretWord,i,i);
        findletter = llSubStringIndex(alphabet,letter);
        SecretWord = SecretWord + llGetSubString(alphabet,findletter,findletter);
    }
    SafedWord = SecretWord;
    length = llStringLength(SecretWord);
    llOwnerSay(SecretWord);
}

buttongenerator(string abcd)
{
    mybuttons = [];
    strlen = llStringLength(abcd);
    i=0;
    for(;i < strlen; ++i)
    {
        letter = llGetSubString(abcd,i,i);
        mybuttons += [letter];
    }
    mybuttons = llListSort( mybuttons, 1, TRUE );
    mybuttons += ["Redo"];
    mybuttons = RestackMenu(FillMenu(mybuttons));
}

generateButtonsString(string abcd,string efgh)
{
    FirstLetter = "";
    GuessedLetters = "";
    while (llStringLength(SecretWord+NewWord) < 12)
    {

        random = llFloor(llFrand(52));
        randomletter = llGetSubString(alphabet,random,random);
        index = llSubStringIndex(NewWord,randomletter);
        index2 = llSubStringIndex(SecretWord,randomletter);
        NewWord += randomletter;
        if (index != -1 || index2 != -1)
        {
            NewWord = llDeleteSubString(NewWord, index, index );
        }
    }


    ButtonsString = SecretWord + NewWord;
    FirstLetter = llGetSubString(ButtonsString,0,0);
    GuessedLetters += FirstLetter;
    ButtonsString = llGetSubString(ButtonsString,1,11);
}

list FillMenu(list in)
{ //adds empty buttons until the list length is multiple of 3, to max of 12
    while (llGetListLength(in) != 3 && llGetListLength(in) != 6 && llGetListLength(in) != 9 && llGetListLength(in) < 12)
    {
        in += [" "];
    }
    return in;
}

list RestackMenu(list in)
{ //re-orders a list so dialog buttons start in the top row
    list out = llList2List(in, 9, 11);
    out += llList2List(in, 6, 8);
    out += llList2List(in, 3, 5);
    out += llList2List(in, 0, 2);
    return out;
}

say_it_nicer(string text)
{
    string temp = llGetObjectName();
    llSetObjectName(FirstName + "'s " + ObjectShortName);
    llWhisper(0,text);
    llSetObjectName(temp);
}


// ------------------------------------------------------------------ //

default
{
    state_entry()
    {
        llSleep(1.0);
        dialogtoggle = 1;
        wearer = llGetOwner();
        index = llSubStringIndex(llKey2Name(wearer), " ");
        FirstName =  llGetSubString(llKey2Name(wearer), 0, index-1);
        menuchan = -(integer)(llFrand(999999.0) - 5555);
        timertext= "Menu will time out in " + (string)(timeout/60) + " minutes.\n";
        notecard_request = NULL_KEY;
        notecard_line = 0;
        num_notecard_lines = 0;
        notecard_request = llGetNumberOfNotecardLines(NotecardName); // ask for the number of lines in the card
    }

    dataserver(key query_id, string data)
    {
        if (query_id == notecard_request) // make sure it's an answer to a question we asked - this should be an unnecessary check
        {
            if (data == EOF) // end of the notecard, erase float text and done...
            {
                llSetText("",<1,1,1>,0.0);
                say_it_nicer("Notecard read. PickLock module is ready.");

            }
            else if (num_notecard_lines == 0) // first request is for the number of lines
            {
                num_notecard_lines = (integer)data;
                notecard_request = llGetNotecardLine(NotecardName, notecard_line); // now get the first line
            }
            else
            {
                if (data != "" && llGetSubString(data, 0, 0) != "#") // ignore empty lines, or lines beginning with "#"
                {
                    say_it_nicer(" reading and decrypting line# " + (string)(notecard_line+1));
                    while (index > -1)
                    {
                        index = llSubStringIndex(data,",");    //finds index(location) of "," in string 'data'
                        word = llGetSubString(data,0,index-1); // finds word before ","
                        data = llDeleteSubString(data, 0, index );//deletes word followed by ","
                        index2 = llStringLength(word);
                        for(i=0;i < index2; ++i)
                        {
                            letter = llGetSubString(word,i,i);
                            newwords = newwords + llGetSubString(alphabet,llSubStringIndex(alphabet,letter)+21,llSubStringIndex(alphabet,letter)+21);
                        }
                        card_data = card_data + newwords;
                        newwords = "";
                    }
                }
                index = 0;
                ++notecard_line;
                notecard_request = llGetNotecardLine(NotecardName, notecard_line); // ask for the next line
                llSetText("read " + (string)(notecard_line) + " of " + (string)num_notecard_lines + " lines", <1, 1, 1>, 1);
            }
        }
    }




    // --- I leave that here for testing purposes to respond to touch --- //
   /* 
        touch(integer ii)
        {
            for(i = 0; i < ii; i++)
            {
                if (llDetectedKey(i) == SubOwnerKey || llDetectedKey(i) == wearer)
                {
                    id = llDetectedKey(i);
                    listen_menu = llListen(menuchan,"",id,"");
                    generateSecretWord(card_data);
                    generateButtonsString(SecretWord,NewWord);
                    buttongenerator(ButtonsString);
                    llSetTimerEvent((float)timeout);
                    llDialog(id,timertext + "Try to guess the " + (string)length + " letter word\nstarting with \"" + FirstLetter + "\"\nLetters we got so far:" + "\n" + GuessedLetters + "\n\"Redo\" lets you start over.",mybuttons,menuchan);
                    dialogtoggle = 1;
                }
            }
        }
    */
        link_message(integer sender, integer num, string str, key id)
        {
            if (str == "detach=n" || str == "detach=y")
            {
                if (str == "detach=n")
                {
                    locked = TRUE;
                }
                else
                {
                    locked = FALSE;
                }
            }
            else if ((str  == "menu " + submenu || str == "picklock") && (num ==  COMMAND_NOAUTH))
            {
                //someone asked for our menu
                //give this plugin's menu to id
                if (locked){
                pick = id;
                llDialog (wearer,"\n\n" + llKey2Name(id) +" wants to pick your lock",["Yes OK", "No"], menuchan);
                listen_menu = llListen(menuchan,"","","");}
/*                if (locked)
                {
                    if (gettime <= llGetTime())
                    {
                    listen_menu = llListen(menuchan,"",id,"");
                    generateSecretWord(card_data);
                    generateButtonsString(SecretWord,NewWord);
                    buttongenerator(ButtonsString);
                    llSetTimerEvent((float)timeout);
                    llDialog(id,timertext + "Try to guess the " + (string)length + " letter word\nstarting with \"" + FirstLetter + "\"\nLetters we got so far:" + "\n" + GuessedLetters + "\n\"Redo\" lets you start over.",mybuttons,menuchan);
                    dialogtoggle = 1;
                    }
                    else
                    {
                        listen_menu = llListen(menuchan,"",id,"");
                        llDialog(id,"Your wait time is not over yet!",["OK"],menuchan);   
                    }
                }
                else
                {
                    listen_menu = llListen(menuchan,"",id,"");
                    llDialog(id,"Currently this device is not locked.\nLucky you.",["OK"],menuchan);
                }  */

            }
            else if (num == MENUNAME_REQUEST)// && str == parentmenu)
            {

                llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, parentmenu + "|" + submenu, NULL_KEY);
            }
            else if (num == MENUNAME_RESPONSE)
            {
                list parts = llParseString2List(str, ["|"], []);
                if (llList2String(parts, 0) == submenu)
                {//someone wants to stick something in our menu
                    button = llList2String(parts, 1);
                    if (llListFindList(buttons, [button]) == -1)
                    {
                        buttons = llListSort(buttons + [button], 1, TRUE);
                    }
                }
            }
            else if (num == HTTPDB_RESPONSE)
            {
                list params = llParseString2List(str, ["="], []);
                string token = llList2String(params, 0);
                string value = llList2String(params, 1);
                if (token == "owner")
                {//owner is in the form key,name
                    SubOwnerName = llList2String(llParseString2List(value, [","], []), 1);
                    SubOwnerKey = llList2String(llParseString2List(value, [","], []), 0);
                }
                /*          else if (token == "secretwords")
                {
                    card_data = [];
                    card_data = llParseString2List(llToLower(value), ["~"], []);
                    generateSecretWord(card_data);
                }*/
            }

            else if (num >= COMMAND_OWNER && num <= COMMAND_WEARER)
            {
                if (str == "refreshmenu")
                {
                    buttons = [];
                    llMessageLinked(LINK_SET, MENUNAME_REQUEST, submenu, NULL_KEY);
                }
            }
        }

    listen( integer channel, string name, key id, string message )
    {
        if (message == "Redo")
        {
            NewWord = "";
            generateButtonsString(SafedWord,NewWord);
            buttongenerator(ButtonsString);
            dialogtoggle = 1;
        }
        else if (message == "OK")
        {
            llMessageLinked(LINK_THIS, SUBMENU, parentmenu, id);
            llListenRemove(listen_menu);
            dialogtoggle = 0;
        }
        
        else if (message == "Yes OK")
        {
                if (locked)
                {
                    if (gettime <= llGetTime())
                    {
                    listen_menu = llListen(menuchan,"",pick,"");
                    generateSecretWord(card_data);
                    generateButtonsString(SecretWord,NewWord);
                    buttongenerator(ButtonsString);
                    llSetTimerEvent((float)timeout);
                    llDialog(pick,timertext + "Try to guess the " + (string)length + " letter word\nstarting with \"" + FirstLetter + "\"\nLetters we got so far:" + "\n" + GuessedLetters + "\n\"Redo\" lets you start over.",mybuttons,menuchan);
                    dialogtoggle = 1;
                    }
                    else
                    {
                        listen_menu = llListen(menuchan,"",pick,"");
                        llDialog(pick,"\n\nYour wait time is not over yet!",["OK"],menuchan);   
                    }
                }
                else
                {
                    listen_menu = llListen(menuchan,"",pick,"");
                    llDialog(pick,"\n\nCurrently this device is not locked.\nLucky you.",["OK"],menuchan);
                }
        }
        
        else
        {
            ButtonsString = llDumpList2String(mybuttons,"");
            index = llSubStringIndex(ButtonsString, "Redo");
            ButtonsString = llDeleteSubString( ButtonsString, index, index+3 ); // Remove "Redo" from mybuttons
            index = llSubStringIndex(ButtonsString, message);
            ButtonsString = llDeleteSubString( ButtonsString, index, index ); // Remove guessed letter from mybuttons
            while((index = llSubStringIndex(ButtonsString, " ")) > -1) // Remove empty spaces
            {
                ButtonsString = llDeleteSubString( ButtonsString, index, index );
            }
            GuessedLetters += message;
            buttongenerator(ButtonsString);
            trials = llStringLength(GuessedLetters);
            if (trials == length)
            {
                if (GuessedLetters == SecretWord)
                {
                    say_it_nicer("Hurray\nI'll try to unlock this device.");
                    dialogtoggle = 0;
                    llMessageLinked(LINK_THIS,COMMAND_OWNER,"unlock",wearer);
                    SafedWord = "";
                    SecretWord = "";
                    llSetTimerEvent(0.0);
                    llListenRemove(listen_menu);
                }
                else
                {
                    ++counter;
                    if (counter >=2)
                    {
                        say_it_nicer("\n\nA new word will be generated and you may start over in " + llGetSubString((string)(waittime/60),0,2) + " minutes.");
                        gettime = llGetTime() + waittime;
                        dialogtoggle = 0;
                        llListenRemove(listen_menu);
                        if (gettime <= llGetTime())
                        {
                            SafedWord = "";
                            SecretWord = "";
                            NewWord = "";
                            generateSecretWord(card_data);
                            generateButtonsString(SecretWord,NewWord);
                            buttongenerator(ButtonsString);
                        }
                    }
                    else
                    {
                        say_it_nicer("\n\nSorry, that was wrong. You have 1 more try!");
                        NewWord = "";
                        generateButtonsString(SafedWord,NewWord);
                        buttongenerator(ButtonsString);
                    }
                }
            }
        }
        if (dialogtoggle == 1)
        {
            llDialog(pick,timertext + "Try to guess the " + (string)length + " letter word\nstarting with \"" + FirstLetter + "\"\nLetters we got so far:" + "\n" + GuessedLetters + "\n\"Redo\" lets you start over(debug).",mybuttons,menuchan);
        }
    }
    timer()
    {
        llListenRemove(listen_menu);
        llSetTimerEvent(0.0);
    }


    changed(integer change)
    {
        if (change&CHANGED_OWNER)
            llResetScript();
    }


}

