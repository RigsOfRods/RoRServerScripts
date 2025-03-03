#include "utils.as"
#include "gameScriptWrapper.as"
#include "localStorage.as"
#include "profanityFilter.as"

funcdef void CHAT_CALLBACK(chatMessage@);


/**
 * This class allows you to add commands, without having to do a 'addCommand' function call in your main() function.
 * @code
 *  	void myCallback(chatMessage@ ccmsg)
 *  	{
 *  		ccmsg.generalGameCommand.message("You used the 'test' command!", "cake.png", 30000.0f, true);
 *  	}
 *  	chatManager chtmngr();
 *  	customCommand test(@chtmngr, "test", myCallback);
 * @endcode
 */
class customCommand
{
	chatManager@ chtmngr;
	string command;

	customCommand(chatManager@ _chtmngr, const string &in cmd, CHAT_CALLBACK@ callback, any@ argument = null, const bool &in showInHelp = true, const int &in authorizations = AUTH_ALL)
	{
		@chtmngr = @_chtmngr;
		command = cmd;
		chtmngr.addCommand(cmd, callback, argument, showInHelp, authorizations);
	}

	void destroy()
	{
		chtmngr.removeCommand(command);
	}
}

class chatMessage
{
	bool isCommand;
	string cmd;

	string msg
	{
		get const 
		{
			return realMsg;
		}
		set 
		{
			realMsg = value;
			msgEdited = true;
		}
	}
	
	string realMsg;
	uint msgLen;
	bool msgEdited;
	
	array<string>@ emsg;
	uint emsgLen;

	int uid;
	int userAuth;

	chatManager@ chatManager;
	any@ argument;
	chatBroadcast@ broadcast;
	gameScript@ privateGameCommand;
	gameScript@ generalGameCommand;
}

class chatCommand
{
	CHAT_CALLBACK@ callback;
	any@ argument;
	int auth;
}

class chatManager
{
	// A dictionary with all the registered commands.
	dictionary commandList;
	
	// A list of all registered chat callbacks
	array<chatCommand@> chatCallbackList;
	
	// The command character that will be used
	string commandCharacter;
	uint8 commandCharacter_ord;
	
	// Ordinal value of an exclamation mark
	uint8 exclMark_ord;
	
	// True if this class has been destroyed
	bool destroyed;

	// The help plugin is hacked into here
	chatPlugin_help@ plugin_help;
		
	// constructor
	chatManager(const string &in cmdChar = "!")
	{
		// Initialize some variables
		exclMark_ord = ord('!');
		chatCallbackList.resize(0);
		destroyed = false;
		
		// Set the command character
		setCommandCharacter(cmdChar);
		
		// Required plugin
		@plugin_help = @chatPlugin_help(@this);
		
		// Set a callback for the chat
		server.setCallback("playerChat", "playerChat", @this);
	}
	
	// This replaces the destructor
	void destroy()
	{
		if(destroyed) return;
		
		// Remove the callback for the chat again
		server.deleteCallback("playerChat", "playerChat", @this);
		
		// destroy the help plugin
		if(plugin_help !is null) plugin_help.destroy();
		
		// Successfully destroyed
		destroyed = true;
	}
	
	// Get's the command character
	string getCommandCharacter() const { return commandCharacter; }
	
	// set's the command character
	void setCommandCharacter(const string &in cmdChar)
	{
		commandCharacter = cmdChar;
		commandCharacter_ord = ord(commandCharacter);
	}
	
	// Our chat callback
	int playerChat(int uid, const string &in msg)
	{
		// Create a new message object and start initializing it
		chatMessage cmsg;
		
		cmsg.realMsg = trim(msg);
		cmsg.msgLen  = cmsg.msg.length();
		cmsg.msgEdited = false;

		if(cmsg.msgLen==0) return BROADCAST_BLOCK;
		
		@cmsg.emsg    = @splitExcludeEmpty(cmsg.msg, " ");
		cmsg.emsgLen  = cmsg.emsg.length();

		cmsg.uid      = uid;
		cmsg.userAuth = server.getUserAuthRaw(uid);
		@cmsg.chatManager = @this;
		@cmsg.broadcast = @chatBroadcast(BROADCAST_AUTO);
		@cmsg.privateGameCommand  = @gameScript(uid);
		@cmsg.generalGameCommand  = @gameScript(TO_ALL);

		// If the message is actually a command
		if(cmsg.emsgLen>0 && cmsg.emsg[0][0]==commandCharacter_ord)
		{
			// Store the command as lowercase, without the command character
			cmsg.cmd       = stringToLowerCase(cmsg.emsg[0].substr(1));
			cmsg.isCommand = true;

			// By default, we don't broadcast commands
			// Also, the server blocks messages starting with '!' anyway.
			cmsg.broadcast.block();

			// do the callback
			chatCommand ccmd;
			if(commandList.get(cmsg.cmd, ccmd))
			{
				// display header
				cmsg.privateGameCommand.message("COMMAND: "+cmsg.cmd, "control_rewind_blue.png", 30000.0f, true);
				
				// If the user had permission to use this command, then do the callback, otherwise, output an error.
				if(ccmd.auth==AUTH_ALL || (ccmd.auth & cmsg.userAuth)>0)
				{
					@cmsg.argument = @ccmd.argument;
					ccmd.callback(cmsg);
				}
				else
					cmsg.privateGameCommand.message("You do not have permission to use this command!", "error_delete.png", 30000.0f, true);
			}
		}
		else
		{
			// not a command
			cmsg.isCommand = false;
			cmsg.cmd = "";
		}

		// Do all the chat callbacks
		for(uint i=0; i<chatCallbackList.length(); ++i)
		{
			@cmsg.argument = @chatCallbackList[i].argument;
			chatCallbackList[i].callback(cmsg);
		}

		// If the message was edited by a callback, then we'll need to broadcast the new message
		if(cmsg.msgEdited && cmsg.broadcast.value!=BROADCAST_BLOCK && (cmsg.broadcast.value!=BROADCAST_AUTO || msg[0]!=exclMark_ord))
		{
			cmsg.generalGameCommand.userSay(cmsg.realMsg, cmsg.uid);
			cmsg.broadcast.block();
		}
		
		// Actual broadcast happens here
		cmsg.privateGameCommand.flush();
		cmsg.generalGameCommand.flush();

		// Return the broadcasting mode of the current message
		return cmsg.broadcast.value;
	}
	
	/**
	 * This allows you to add a command to the system
	 * @param cmd The command (no spaces, all lower case, do not include the command character).
	 * @param callback The callback function that should be called when the command is received.
	 * @param argument An argument that will be passed to the callback function.
	 * @param showInHelp True if you want your command to be shown in the commandlist, shown when someone uses the help command.
	 * @param authorizations A raw authorization, defining who can use this command.
	 */
	void addCommand(const string &in cmd, CHAT_CALLBACK@ callback, any@ argument, const bool &in showInHelp = true, const int &in authorizations = AUTH_ALL)
	{
		if(cmd.length()==0) return;
		
		// Create the command object
		chatCommand ccmd;
		@ccmd.callback = @callback;
		@ccmd.argument = @argument;
		ccmd.auth      = authorizations;
		
		// Do some basic check before possibly overwriting a command
		if(commandList.exists(cmd))
		{
			server.Log("WARNING| chatManager::addCommand(...): Overwriting command '"+cmd+"'.");
			removeCommand(cmd);
		}

		// Add the new command to the command list
		commandList.set(cmd, ccmd);

		// The help plugin is kind of hacked into here...
		if(showInHelp && plugin_help !is null)
			plugin_help.add(cmd, authorizations);
	}
	
	/**
	 * Checks if a command is already registered.
	 * @param cmd The command (no spaces, all lower case, do not include the command character).
	 * @return true if the command exists.
	 */
	bool commandExists(const string &in cmd)
	{
		return commandList.exists(cmd);
	}

	/**
	 * Removes a command from the system.
	 * @param cmd The command (no spaces, all lower case, do not include the command character).
	 */
	void removeCommand(const string &in cmd)
	{
		commandList.delete(cmd);

		// The help plugin was hacked into here again
		if(plugin_help !is null)
			plugin_help.delete(cmd);
	}
	
	/**
	 * Removes all commands from the system.
	 */
	void removeAllCommands()
	{
		commandList.deleteAll();
	}

	/**
	 * Adds a chat callback.
	 * @param callback the callback function.
	 * @param argument the argument that should be passed to the callback function.
	 */
	void addChatCallback(CHAT_CALLBACK@ callback, any@ argument)
	{
		// Create a command object
		chatCommand ccmd;
		@ccmd.callback = @callback;
		@ccmd.argument = @argument;
		
		// Add the object to the list
		chatCallbackList.insertLast(ccmd);
	}
	
	/**
	 * Removes a chat callback again.
	 * @param callback the callback function.
	 */
	void removeChatCallback(CHAT_CALLBACK@ callback)
	{
		for(uint i=0; i<chatCallbackList.length(); ++i)
		{
			if(@chatCallbackList[i].callback==@callback)
				chatCallbackList.removeAt(i);
		}
	}
}

//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////

void chatPlugin_autoModerator_floodFilterChatCallback(chatMessage@ cmd)
{
	chatPlugin_autoModerator@ obj;
	cmd.argument.retrieve(@obj);
	obj.floodFilterChatCallback(cmd);
}

void chatPlugin_autoModerator_profanityFilterChatCallback(chatMessage@ cmd)
{
	chatPlugin_autoModerator@ obj;
	cmd.argument.retrieve(@obj);
	obj.profanityFilterChatCallback(cmd);
}

void chatPlugin_autoModerator_chatBanChatCallback(chatMessage@ cmd)
{
	chatPlugin_autoModerator@ obj;
	cmd.argument.retrieve(@obj);
	obj.chatBanChatCallback(cmd);
}

void chatPlugin_autoModerator_suspendchat(chatMessage@ cmd)
{
	chatPlugin_autoModerator@ obj;
	cmd.argument.retrieve(@obj);
	obj.callback_suspendchat(cmd);
}

void chatPlugin_autoModerator_chatban(chatMessage@ cmd)
{
	chatPlugin_autoModerator@ obj;
	cmd.argument.retrieve(@obj);
	obj.callback_chatban(cmd);
}

void chatPlugin_autoModerator_temporaryban(chatMessage@ cmd)
{
	chatPlugin_autoModerator@ obj;
	cmd.argument.retrieve(@obj);
	obj.callback_temporaryban(cmd);
}

class chatPlugin_autoModerator_client
{
	int uid;
	int auth;
	
	uint chat_timeNumber_smallLimit;
	uint chat_timeNumber_grandLimit;
	uint chat_timeNumber_in;
	array<int> chat_time;
	int chat_blockTime;
}

const uint PROFANITYFILTER_CHATBANTIME = 60;
const uint PROFANITYFILTER_LOGSIZE = 3;

class chatPlugin_autoModerator
{
	chatManager@ chtmngr;
	array<chatPlugin_autoModerator_client> clients;
	int chat_blocked;
	bool destroyed;

	array<int> profanityFilterLog;
	uint profanityFilterLogIndex;
	
	chatPlugin_autoModerator(chatManager@ _chtmngr, bool _enableProfanityFilter = true, bool _enableFloodFilter = true, bool _enableCommands = true)
	{
		@chtmngr = @_chtmngr;
		clients.resize(0);
		server.setCallback("playerDeleted", "playerDeleted", @this);
		server.setCallback("playerAdded", "playerAdded", @this);
		chat_blocked = 0;
		destroyed = false;

		// Initialize profanity filter
		profanityFilterLogIndex = 0;
		profanityFilterLog.resize(PROFANITYFILTER_LOGSIZE);
		for(uint i=0; i<PROFANITYFILTER_LOGSIZE; ++i)
		{
			profanityFilterLog[i] = i-9999;
		}
		
		if(_enableCommands)        this.registerChatModerationCommands();
		if(_enableFloodFilter)     this.enableFloodFilter();
		if(_enableProfanityFilter) this.enableProfanityFilter();
	}

	void destroy()
	{
		if(destroyed) return;
		destroyed = true;
		unregisterChatModerationCommands();
		disableFloodFilter();
		server.deleteCallback("playerDeleted", "playerDeleted", @this);
		server.deleteCallback("playerAdded", "playerAdded", @this);
	}
	
	int getClientIndexByUid(chatMessage@ cmsg)
	{
		for(uint i=0; i<clients.length(); ++i)
		{
			if(clients[i].uid==cmsg.uid)
				return i;
		}
		
		// client not found => add it
		chatPlugin_autoModerator_client cl;
		cl.uid = cmsg.uid;
		cl.auth = cmsg.userAuth;
		cl.chat_timeNumber_in = 0;
		cl.chat_timeNumber_smallLimit = 17;
		cl.chat_timeNumber_grandLimit = 1;
		cl.chat_blockTime = -999;
		cl.chat_time.resize(20);
		for(int i=0; i<20; ++i)
		{
			cl.chat_time[i] = -999;
		}
		clients.insertLast(cl);
		return (clients.length()-1);
	}
	
	int getClientIndexByUid(int uid)
	{
		for(uint i=0; i<clients.length(); ++i)
		{
			if(clients[i].uid==uid)
				return i;
		}
		
		// client not found
		return -1;
	}
	
	void playerDeleted(int uid, int crash)
	{
		for(uint i=0; i<clients.length(); ++i)
		{
			if(clients[i].uid==uid)
			{
				clients.removeAt(i);
				return;
			}
		}
	}
	
	void playerAdded(int uid)
	{
		chatPlugin_autoModerator_client cl;
		cl.uid = uid;
		cl.auth = server.getUserAuthRaw(uid);
		cl.chat_timeNumber_in = 0;
		cl.chat_timeNumber_smallLimit = 17;
		cl.chat_timeNumber_grandLimit = 1;
		cl.chat_blockTime = -999;
		cl.chat_time.resize(20);
		for(int i=0; i<20; ++i)
		{
			cl.chat_time[i] = -999;
		}
		clients.insertLast(cl);
	}
	
	void registerChatModerationCommands()
	{
		chtmngr.addChatCallback(chatPlugin_autoModerator_chatBanChatCallback, @any(@this));
		chtmngr.addCommand("suspendchat", chatPlugin_autoModerator_suspendchat, @any(@this), true,  AUTH_ADMIN | AUTH_MOD);
		chtmngr.addCommand("schat",       chatPlugin_autoModerator_suspendchat, @any(@this), false, AUTH_ADMIN | AUTH_MOD);
		
		chtmngr.addCommand("chatban", chatPlugin_autoModerator_chatban, @any(@this), true, AUTH_ADMIN | AUTH_MOD);
		chtmngr.addCommand("cban",    chatPlugin_autoModerator_chatban, @any(@this), false, AUTH_ADMIN | AUTH_MOD);
		
		chtmngr.addCommand("temporaryban", chatPlugin_autoModerator_temporaryban, @any(@this), true,  AUTH_ADMIN | AUTH_MOD);
		chtmngr.addCommand("tempban",      chatPlugin_autoModerator_temporaryban, @any(@this), false, AUTH_ADMIN | AUTH_MOD);
		chtmngr.addCommand("tban",         chatPlugin_autoModerator_temporaryban, @any(@this), false, AUTH_ADMIN | AUTH_MOD);
	}
	
	void unregisterChatModerationCommands()
	{
		chtmngr.removeChatCallback(chatPlugin_autoModerator_chatBanChatCallback);
		chtmngr.removeCommand("suspendchat");
		chtmngr.removeCommand("schat");
		
		chtmngr.removeCommand("chatban");
		chtmngr.removeCommand("cban");
		
		chtmngr.removeCommand("temporaryban");
		chtmngr.removeCommand("tempban");
		chtmngr.removeCommand("tban");
	}
	
	// FLOOD FILTER
	void enableFloodFilter()
	{
		chtmngr.addChatCallback(chatPlugin_autoModerator_floodFilterChatCallback, @any(@this));
	}
	
	void disableFloodFilter()
	{
		chtmngr.removeChatCallback(chatPlugin_autoModerator_floodFilterChatCallback);
	}
	
	void floodFilterChatCallback(chatMessage@ cmsg)
	{
		if(cmsg.broadcast.isBlocked() or (cmsg.userAuth & (AUTH_ADMIN | AUTH_MOD | AUTH_BOT)>0)) return;

		if( (cmsg.broadcast.value!=BROADCAST_ALL) && (cmsg.broadcast.value!=BROADCAST_AUTO) ) return;
		const int pos = getClientIndexByUid(cmsg);
		const int time = server.getTime();
		
		if(clients[pos].chat_blockTime>time)
		{
			cmsg.privateGameCommand.message("You currently do not have the required permission to chat.", "server_delete.png", 30000.0f, true);
			cmsg.broadcast.block();
			return;
		}
		else if(
			// small limit: 4 messages/7 seconds
			(time-clients[pos].chat_time[clients[pos].chat_timeNumber_smallLimit]<=7)
			// grand limit: 20 messages/60 seconds
			|| (time-clients[pos].chat_time[clients[pos].chat_timeNumber_grandLimit]<=60)
		) {
			cmsg.privateGameCommand.message("Please do not flood the chat with too many messages in a too short time frame.", "server_error.png", 30000.0f, true);
			cmsg.privateGameCommand += giveChatBan(cmsg.uid, ((time-clients[pos].chat_time[clients[pos].chat_timeNumber_grandLimit])%60)+20);
			cmsg.generalGameCommand.message("User '"+server.getUserName(cmsg.uid)+"'s chat permission has been automatically revoked.", "server_error.png", 30000.0f, true);
			cmsg.broadcast.block();
			return;
		}
		else
		{
			++clients[pos].chat_timeNumber_smallLimit;
			if(clients[pos].chat_timeNumber_smallLimit>=clients[pos].chat_time.length())
				clients[pos].chat_timeNumber_smallLimit = 0;

			++clients[pos].chat_timeNumber_grandLimit;
			if(clients[pos].chat_timeNumber_grandLimit>=clients[pos].chat_time.length())
				clients[pos].chat_timeNumber_grandLimit = 0;

			++clients[pos].chat_timeNumber_in;
			if(clients[pos].chat_timeNumber_in>=clients[pos].chat_time.length())
				clients[pos].chat_timeNumber_in = 0;

			clients[pos].chat_time[clients[pos].chat_timeNumber_in] = time;
		}
	}

	// PROFANITY FILTER
	void enableProfanityFilter()
	{
		chtmngr.addChatCallback(chatPlugin_autoModerator_profanityFilterChatCallback, @any(@this));
	}
	
	void disableProfanityFilter()
	{
		chtmngr.removeChatCallback(chatPlugin_autoModerator_profanityFilterChatCallback);
	}

	void profanityFilterChatCallback(chatMessage@ cmsg)
	{
		// profanity filter
		if(not cmsg.broadcast.isBlocked() and (cmsg.userAuth & (AUTH_ADMIN | AUTH_MOD | AUTH_BOT)==0))
		{
			string newMsg;
			if(filterProfanity(cmsg.msg, newMsg))
			{
				// Check if the message contains any other characters than *
				// commented for anti-link protection
				bool blockMessage = true;
				//for(uint i=0; i<newMsg.length(); ++i)
				//{
				//	if(newMsg[i]!=profanityFilter_replacementChar)
				//	{
				//		blockMessage = false;
				//	}
				//}
			
				if(blockMessage)
				{
					cmsg.broadcast.block();
					cmsg.privateGameCommand.message("Your message contained a prohibited word. It was not broadcasted to other players!", "lock_delete.png", 30000.0f, true);
					server.Log("CHAT_BLOCK| "+server.getUserName(cmsg.uid)+": "+newMsg);
				}
				else
				{
					// Set the new (censored) message.
				//	cmsg.msg = newMsg;
				//	server.Log("CHAT| "+server.getUserName(cmsg.uid)+": "+newMsg);
				
					// log this event
					profanityFilterLog[profanityFilterLogIndex] = cmsg.uid;
					profanityFilterLogIndex = (profanityFilterLogIndex+1)%PROFANITYFILTER_LOGSIZE;

					// Time for a sanction against this user?
					bool allBySameUser = true;
					for(uint i=0; i<profanityFilterLog.length(); ++i)
					{
						if(profanityFilterLog[i]!=cmsg.uid)
						{
							allBySameUser = false;
							break;
						}
					}
					if(allBySameUser)
					{	
						// Give him a chat ban
						cmsg.privateGameCommand += giveChatBan(cmsg.uid, PROFANITYFILTER_CHATBANTIME, "Auto-ban after " + PROFANITYFILTER_LOGSIZE + " subsequent censored messages.");
						cmsg.generalGameCommand.message("User '"+server.getUserName(cmsg.uid)+"'s chat permission has been automatically revoked.", "server_error.png", 30000.0f, true);
						
						// reset variables
						profanityFilterLogIndex = 0;
						for(uint i=0; i<PROFANITYFILTER_LOGSIZE; ++i)
						{
							profanityFilterLog[i] = i-9999;
						}
					}
				}
			}
		}
	}
	
	// COMMAND suspendchat schat
	bool chatBlocked() const
	{
		return chat_blocked>server.getTime();
	}

	void blockChat(const int &in length)
	{
		chat_blocked = server.getTime()+length;
	}
	
	void unblockChat()
	{
		chat_blocked = 0;
	}

	void chatBanChatCallback(chatMessage@ cmsg)
	{
		// chat blocked?
		if( (cmsg.broadcast.value==BROADCAST_ALL || cmsg.broadcast.value==BROADCAST_AUTO) && chatBlocked() && (cmsg.userAuth & (AUTH_ADMIN | AUTH_MOD | AUTH_BOT))==0)
		{
			cmsg.privateGameCommand.message("The chat is currently disabled. Your message was not broadcasted to other players!", "lock_delete.png", 30000.0f, true);
			cmsg.broadcast.block();
		}

		// User has a chat ban?
		else if( (cmsg.broadcast.value==BROADCAST_ALL || cmsg.broadcast.value==BROADCAST_AUTO)  && clients[getClientIndexByUid(cmsg)].chat_blockTime>server.getTime() )
		{
			cmsg.privateGameCommand.message("You're not authorized to use the chat system. Your message was not broadcasted to other players!", "lock_delete.png", 30000.0f, true);
			cmsg.broadcast.block();
		}
	}

	void callback_suspendchat(chatMessage@ cmsg)
	{
		cmsg.broadcast.block();

		if(cmsg.emsgLen<2 && chatBlocked())
		{ // !schat && chat is currently blocked => unblock it
			cmsg.generalGameCommand.message(COLOUR_BLUE+"The chat has been re-opened.", "lock_open.png", 30000.0f, true);
			unblockChat();
		}
		else if(cmsg.emsgLen<2)
		{ // !schat && chat is currently not blocked => block it
			blockChat(60);
			cmsg.generalGameCommand.message(COLOUR_BLUE+"The chat has been suspended for 60 seconds by a server administrator.", "lock.png", 30000.0f, true);
		}
		else if(chatBlocked() && !isNumber(cmsg.emsg[1]))
		{ // !schat off && chat is currently blocked => unblock it

			cmsg.generalGameCommand.message(COLOUR_BLUE+"The chat has been re-opened.", "lock_open.png", 30000.0f, true);
			unblockChat();
		}
		else if(!isNumber(cmsg.emsg[1]))
		{ // !schat off && chat is currently not blocked => show help
			cmsg.privateGameCommand.message("!suspendchat will suspend all chat traffic for a given amount of seconds.", "information.png", 30000.0f, true);
			cmsg.privateGameCommand.message("  usage: !suspendchat [seconds=60]", "information.png", 30000.0f, true);
			cmsg.privateGameCommand.message("example: !suspendchat 30", "information.png", 30000.0f, true);
		}
		else
		{ // !schat <int>

			// get the time
			const int time = parseInt(cmsg.emsg[1]);
			
			if(chatBlocked() && time<=0)
			{
				cmsg.generalGameCommand.message(COLOUR_BLUE+"The chat has been re-opened.", "lock_open.png", 30000.0f, true);
				unblockChat();
			}
			else if(time<=0)
			{
				cmsg.privateGameCommand.message("!suspendchat will suspend all chat traffic for a given amount of seconds.", "information.png", 30000.0f, true);
				cmsg.privateGameCommand.message("  usage: !suspendchat [seconds=60]", "information.png", 30000.0f, true);
				cmsg.privateGameCommand.message("example: !suspendchat 30", "information.png", 30000.0f, true);
			}
			else
			{
				cmsg.generalGameCommand.message(COLOUR_BLUE+"The chat has been suspended for "+formatTime(time)+" by a server administrator.", "lock.png", 30000.0f, true);
				blockChat(time);
			}
		}
	}
	
	// COMMAND chatban cban
	gameScript@ giveChatBan(int uid, int seconds, const string &in reason = "")
	{
		const int pos = getClientIndexByUid(uid); if(pos<0) return @gameScript(uid);
		clients[pos].chat_blockTime = server.getTime()+seconds;

		gameScript game(uid);	
		if(reason!="")
			game.message("Your chat permission has been revoked for "+formatTime(seconds)+" because: "+reason+".", "server_error.png");
		else
			game.message("Your chat permission has been revoked for "+formatTime(seconds)+".", "server_error.png");
		return @game;
	}

	void callback_chatban(chatMessage@ cmsg)
	{
		cmsg.broadcast.block();

		if(cmsg.emsgLen<2 || !isNumber(cmsg.emsg[1]))
		{ // first argument is required
			cmsg.privateGameCommand.message("!cban will give someone a chat ban for an amount of seconds.", "information.png", 30000.0f, true);
			cmsg.privateGameCommand.message("usage 2: !cban <uid> [seconds=60] [reason]", "information.png", 30000.0f, true);
			cmsg.privateGameCommand.message("example: !cban 456 30 violating rule number 3", "information.png", 30000.0f, true);
		}
		else
		{
			string busername = "";
			int buid = -1;
			int bseconds = -1;
			string breason = "";

			// Check if correct uid
			buid = parseInt(cmsg.emsg[1]);
			busername = server.getUserName(buid);
			if(busername.length()==0) // TODO: add decent method to server scriptengine to check if uid is online
			{
				cmsg.privateGameCommand.message("User with unique ID "+buid+" was not found!", "cross.png", 30000.0f, true);
				return;
			}
				

			// get the amount of seconds
			if(cmsg.emsgLen>=3)
				bseconds = parseInt(cmsg.emsg[2]);
			if(bseconds<10)
				bseconds = 60;

			// get the reason
			if(cmsg.emsgLen>=4)
				breason = joinFrom(cmsg.emsg, ' ', 3);

			// give the ban
			giveChatBan(buid, bseconds, breason).flush();
			cmsg.privateGameCommand.message("Ban given to "+busername+" ("+buid+").", "server.png", 30000.0f, true);
		}
	}
	
	// COMMAND temporaryban tempban tban
	void callback_temporaryban(chatMessage@ cmsg)
	{
		cmsg.broadcast.block();

		if(cmsg.emsgLen<2 || !isNumber(cmsg.emsg[1]))
		{ // first argument is required
			cmsg.privateGameCommand.message("!tban will give someone a temporary ban for an amount of seconds.", "information.png", 30000.0f, true);
			cmsg.privateGameCommand.message("usage 2: !tban <uid> [seconds=600] [reason]", "information.png", 30000.0f, true);
			cmsg.privateGameCommand.message("example: !tban 456 900 violating rule number 3", "information.png", 30000.0f, true);
		}
		else
		{
			string busername = "";
			int buid = -1;
			int bseconds = -1;
			string breason = "";

			// Let's check if we have a number, and if that's an existing uid.
			buid = parseInt(cmsg.emsg[1]);
			busername = server.getUserName(buid);
			if(busername.length()==0)
			{
				cmsg.privateGameCommand.message("User with unique ID "+buid+" was not found!", "cross.png", 30000.0f, true);
				return;
			}

			// get the amount of seconds
			if(cmsg.emsgLen>=3)
				bseconds = parseInt(cmsg.emsg[2]);
			if(bseconds<10)
				bseconds = 60;

			// get the reason
			if(cmsg.emsgLen>=4)
				breason = joinFrom(cmsg.emsg, ' ', 3);

			// give the ban
			const int bpos = getClientIndexByUid(buid); if(bpos<0) return;
			// TODO: add ban (should be done in a frameStep method -> register framestep method, register chat callback, remove framestep again on first next chat message))
			cmsg.privateGameCommand.message("Ban given to "+busername+" ("+buid+").", "server.png", 30000.0f, true);
			quickGameMessage(buid, "You will now be banned for "+formatTime(bseconds)+" because: "+breason+".", "server_error.png");
		}
	}
}

//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////

void chatPlugin_help_CmdHelp(chatMessage@ cmd)
{
	chatPlugin_help@ obj;
	cmd.argument.retrieve(@obj);
	obj.callback_help(cmd);
}

class chatPlugin_help
{
	private array<string> commandsAdmin;
	private array<string> commandsMod;
	private array<string> commandsRanked;
	private array<string> commandsBot;
	private array<string> commandsNone;

	private chatManager@ chtmngr;
	string cmdPrefix;
	bool destroyed;

	chatPlugin_help(chatManager@ _chtmngr)
	{
		@chtmngr = @_chtmngr;
		cmdPrefix = chtmngr.getCommandCharacter();
		commandsAdmin.resize(0);
		commandsMod.resize(0);
		commandsRanked.resize(0);
		commandsBot.resize(0);
		commandsNone.resize(0);
		chtmngr.addCommand("help", @chatPlugin_help_CmdHelp, @any(@this), false,  AUTH_ALL);
		destroyed = false;
	}

	void destroy()
	{
		if(!destroyed)
		{
			chtmngr.removeCommand("help");
			destroyed = true;
		}
	}

	void add(const string &in cmd, const int &in auth)
	{
		if((auth & AUTH_ADMIN)>0)
			commandsAdmin.insertLast(cmd);
		if((auth & AUTH_MOD)>0)
			commandsMod.insertLast(cmd);
		if((auth & AUTH_RANKED)>0)
			commandsRanked.insertLast(cmd);
		if((auth & AUTH_BOT)>0)
			commandsBot.insertLast(cmd);
		if(auth == AUTH_ALL || auth == AUTH_NONE)
			commandsNone.insertLast(cmd);
	}

	void delete(const string &in cmd)
	{
		int index;

		index = commandsAdmin.find(cmd);
		if(index>=0) commandsAdmin.removeAt(index);

		index = commandsMod.find(cmd);
		if(index>=0) commandsMod.removeAt(index);

		index = commandsRanked.find(cmd);
		if(index>=0) commandsRanked.removeAt(index);

		index = commandsBot.find(cmd);
		if(index>=0) commandsBot.removeAt(index);

		index = commandsNone.find(cmd);
		if(index>=0) commandsNone.removeAt(index);
			
	}

	void callback_help(chatMessage@ cmsg)
	{
		// don't broadcast this command
		cmsg.broadcast.block();

		const string auth = server.getUserAuth(cmsg.uid);
		if(auth=="none")
			sayCommandsList(cmsg.privateGameCommand, commandsNone);
		else if(auth=="bot")
			sayCommandsList(cmsg.privateGameCommand, commandsBot);
		else if(auth=="ranked")
			sayCommandsList(cmsg.privateGameCommand, commandsRanked);
		else if(auth=="admin")
			sayCommandsList(cmsg.privateGameCommand, commandsAdmin);
		else if(auth=="moderator")
			sayCommandsList(cmsg.privateGameCommand, commandsMod);
	}

	void sayCommandsList(gameScript@ game, const array<string> &in arr)
	{
		if(arr.length()==0)
		{
			game.message("There are no script-commands available for you.", "text_list_bullets.png", 30000.0f, true);
		}
		else
		{
			string tmp = cmdPrefix+arr[0];
			for(uint i=1; i<arr.length(); ++i)
			{
				if(i%10==0 && i!=0)
				{
					game.message("Available commands: "+tmp, "text_list_bullets.png", 30000.0f, true);
					tmp = cmdPrefix+arr[i];
				}
				else
					tmp += ", "+cmdPrefix+arr[i];
			}
			if(tmp.length()>0)
				game.message("Available commands: "+tmp, "text_list_bullets.png", 30000.0f, true);
		}
	}
}

//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////


class chatBroadcast
{
	int value;
	
	chatBroadcast()
	{
		this.value = BROADCAST_AUTO;
	}
	
	chatBroadcast(const int &in initialValue)
	{
		this.value = initialValue;
	}
	
	chatBroadcast(const chatBroadcast &in other)
	{
		this.value = other.value;
	}
	
	chatBroadcast@ opAssign(const chatBroadcast &in other)
	{
		this.value = other.value;
		return this;
	}
	
	chatBroadcast@ opAssign(const int &in other)
	{
		this.value = other;
		return this;
	}
	
	bool isBlocked() const
	{
		return this.value == BROADCAST_BLOCK;
	}
	
	void block()
	{
		this.value = BROADCAST_BLOCK;
	}
	
	void safeBlock()
	{
		this.value = BROADCAST_BLOCK;
	}
	
	void all()
	{
		this.value = BROADCAST_ALL;
	}
	
	void safeAll()
	{
		if(this.value!=BROADCAST_BLOCK && this.value!=BROADCAST_AUTHED && this.value!=BROADCAST_NORMAL)
			this.value = BROADCAST_ALL;
	}
	
	void none()
	{
		this.value = BROADCAST_BLOCK;
	}
	
	void safeNone()
	{
		this.value = BROADCAST_BLOCK;
	}
	
	void authed()
	{
		this.value = BROADCAST_AUTHED;
	}
	
	void safeAuthed()
	{
		if(this.value!=BROADCAST_BLOCK)
			this.value = BROADCAST_AUTHED;
	}
	
	void SetAuto()
	{
		this.value = BROADCAST_AUTO;
	}
	
	void safeAuto()
	{
		if(this.value!=BROADCAST_BLOCK)
			this.value = BROADCAST_AUTO;
	}
	
	void normal()
	{
		this.value = BROADCAST_NORMAL;
	}
	
	void safeNormal()
	{
		if(this.value!=BROADCAST_BLOCK && this.value!=BROADCAST_AUTHED)
			this.value = BROADCAST_NORMAL;
	}
}

//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////

// This is actually some sort of dummy class
class chatPlugin_disallowAllUpperCase
{
	private chatManager@ chtmngr;
	bool destroyed;

	chatPlugin_disallowAllUpperCase(chatManager@ _chtmngr)
	{
		@chtmngr = @_chtmngr;
		destroyed = false;
		
		// Enable stuff
		chtmngr.addChatCallback(chatPlugin_disallowAllUpperCase_chatCallback, null);
	}
	
	void destroy()
	{
		if(destroyed) return;
		
		// disable stuff
		chtmngr.removeChatCallback(chatPlugin_disallowAllUpperCase_chatCallback);
		
		// destroyed :)
		destroyed = true;
	}
}


void chatPlugin_disallowAllUpperCase_chatCallback(chatMessage@ cmsg)
{
	if(not cmsg.broadcast.isBlocked() and (cmsg.userAuth & (AUTH_ADMIN | AUTH_MOD | AUTH_BOT)==0))
	{
		if(isUpperCase(cmsg.msg))
		{
			// Log it for debug purposes
			// server.Log("Uppercase detected: '" + cmsg.msg + "'.");
		
			// Convert the message to lower case
			cmsg.msg = stringToLowerCase(cmsg.msg);
			
			// make the first letter upper case
			string firstchar = stringToUpperCase(cmsg.msg.substr(0,1));
			cmsg.msg = firstchar + cmsg.msg.substr(1);
		}
	}
}

//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////
	
// This is actually some sort of dummy class
class chatPlugin_miscellaneousCommands
{
	private chatManager@ chtmngr;
	bool destroyed;

	chatPlugin_miscellaneousCommands(chatManager@ _chtmngr)
	{
		@chtmngr = @_chtmngr;
		destroyed = false;
		
		// Enable stuff
		chtmngr.addCommand("brb",  chatPlugin_miscellaneousCommands_brb,  null, true, AUTH_ALL);
		chtmngr.addCommand("afk",  chatPlugin_miscellaneousCommands_afk,  null, true, AUTH_ALL);
		chtmngr.addCommand("gtg",  chatPlugin_miscellaneousCommands_gtg,  null, true, AUTH_ALL);
		chtmngr.addCommand("back", chatPlugin_miscellaneousCommands_back, null, true, AUTH_ALL);
	}
	
	void destroy()
	{
		if(destroyed) return;
		
		// disable stuff
		chtmngr.removeCommand("brb");
		chtmngr.removeCommand("afk");
		chtmngr.removeCommand("gtg");
		chtmngr.removeCommand("back");
		
		// destroyed :)
		destroyed = true;
	}
}
	
void chatPlugin_miscellaneousCommands_afk(chatMessage@ cmsg)
{
	cmsg.broadcast.block();
	cmsg.generalGameCommand.message(server.getUserName(cmsg.uid) + " is now away from keyboard :(", "cup_add.png", 30000.0f, true);
}

void chatPlugin_miscellaneousCommands_brb(chatMessage@ cmsg)
{
	cmsg.broadcast.block();
	cmsg.generalGameCommand.message(server.getUserName(cmsg.uid) + " will be right back!", "cup_add.png", 30000.0f, true);
}

void chatPlugin_miscellaneousCommands_back(chatMessage@ cmsg)
{
	cmsg.broadcast.block();
	cmsg.generalGameCommand.message(server.getUserName(cmsg.uid) + " is now back :D", "cup_delete.png", 30000.0f, true);
}

void chatPlugin_miscellaneousCommands_gtg(chatMessage@ cmsg)
{
	cmsg.broadcast.block();
	cmsg.generalGameCommand.message(server.getUserName(cmsg.uid) + " has got to go! Say bye!", "cup_go.png", 30000.0f, true);
}

//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////

// This is actually some sort of dummy class
class chatPlugin_moveCommand
{
	private chatManager@ chtmngr;
	bool destroyed;

	chatPlugin_moveCommand(chatManager@ _chtmngr)
	{
		@chtmngr = @_chtmngr;
		destroyed = false;
		
		// Enable stuff
		chtmngr.addCommand("move", chatPlugin_moveCommand_callback, null, true, AUTH_ALL);
	}
	
	void destroy()
	{
		if(destroyed) return;
		
		// disable stuff
		chtmngr.removeCommand("move");
		
		// destroyed :)
		destroyed = true;
	}
}

void chatPlugin_moveCommand_callback(chatMessage@ cmsg)
{
	// Block this message
	cmsg.broadcast.block();

	// Needs 1 argument
	if(cmsg.emsgLen<2)
	{
		cmsg.privateGameCommand.message("!move will move your avatar in the specified direction", "information.png", 30000.0f, true);
		cmsg.privateGameCommand.message("  usage: !move <north|east|south|west|up|down> [distance]", "information.png", 30000.0f, true);
		cmsg.privateGameCommand.message("example: !move up 5", "information.png", 30000.0f, true);
		return;
	}

	// Get and format the first argument
	string dir = stringToLowerCase(cmsg.emsg[1]);
	
	// Get and parse the second argument
	float distance = 1.0f;
	if(cmsg.emsgLen>2 && isNumber(cmsg.emsg[2]))
		distance = parseFloat(cmsg.emsg[2]);

	// note: triangle with side lengths sqrt(0.5), sqrt(0.5), 1 (Pythagoras)
	// note: sqrt(0.5) = 0.7
	//   1 /| 0.7
	//    /_|
	//    0.7
	if(dir=="north" || dir=="n")
		cmsg.privateGameCommand.movePerson(vector3( 1.0f, 0.0f, 0.0f)*distance);
	else if(dir=="south" || dir=="s")
		cmsg.privateGameCommand.movePerson(vector3(-1.0f, 0.0f, 0.0f)*distance);
	else if(dir=="east" || dir=="e")
		cmsg.privateGameCommand.movePerson(vector3( 0.0f, 0.0f, 1.0f)*distance);
	else if(dir=="west" || dir=="w")
		cmsg.privateGameCommand.movePerson(vector3( 0.0f, 0.0f,-1.0f)*distance);
	else if(dir=="ne")
		cmsg.privateGameCommand.movePerson(vector3( 0.7f, 0.0f, 0.7f)*distance);
	else if(dir=="se")
		cmsg.privateGameCommand.movePerson(vector3(-0.7f, 0.0f, 0.7f)*distance);
	else if(dir=="sw")
		cmsg.privateGameCommand.movePerson(vector3(-0.7f, 0.0f,-0.7f)*distance);
	else if(dir=="nw")
		cmsg.privateGameCommand.movePerson(vector3( 0.7f, 0.0f,-0.7f)*distance);
	else if(dir=="up" || dir=="u")
		cmsg.privateGameCommand.movePerson(vector3( 0.0f, 1.0f, 0.0f)*distance);
	else if(dir=="down" || dir=="d")
		cmsg.privateGameCommand.movePerson(vector3( 0.0f,-1.0f, 0.0f)*distance);
	else
		cmsg.privateGameCommand.message("Unknown direction: '"+dir+"'.", "information.png", 30000.0f, true);

	cmsg.privateGameCommand.addCmd(
		"if(game.getCurrentTruckNumber()>=0)game.message('You cannot use this command while driving!', 'map_delete.png', 30000, true);"
	);
}

//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////


void chatPlugin_gotoCommand_goto(chatMessage@ cmd)
{
	chatPlugin_gotoCommand@ obj;
	cmd.argument.retrieve(@obj);
	obj.callback_goto(cmd);
}

void chatPlugin_gotoCommand_setgoto(chatMessage@ cmd)
{
	chatPlugin_gotoCommand@ obj;
	cmd.argument.retrieve(@obj);
	obj.callback_setgoto(cmd);
}

void chatPlugin_gotoCommand_deletegoto(chatMessage@ cmd)
{
	chatPlugin_gotoCommand@ obj;
	cmd.argument.retrieve(@obj);
	obj.callback_deletegoto(cmd);
}

void chatPlugin_gotoCommand_gameCmd(gameScriptManager_argument@ arg)
{
	chatPlugin_gotoCommand@ obj;
	arg.argument.retrieve(@obj);
	obj.gameCmd(@arg);
}

class chatPlugin_gotoCommand
{
	private array<string> locations;
	private array<string> positions;
	private array<string> rotations;
	private dictionary locationsLookupTable;
	private uint free_pos;	
	private array<string> possible_locations;
	private uint free_posloc;
	private localStorage@ storage;
	private bool useStorage;
	private gameScriptManager@ gsm;
	private chatManager@ chtmngr;
	bool registered;
	string gameCmdPrefix;
	
	chatPlugin_gotoCommand(chatManager@ _chtmngr, gameScriptManager@ _gsm)
	{
		@chtmngr = @_chtmngr;
		@gsm = @_gsm;

		locations.resize(0);
		positions.resize(0);
		rotations.resize(0);
		free_pos = 0;
		
		possible_locations.resize(0);
		free_posloc = 0;

		@storage = @localStorage("chatPlugin_gotoCommand.asdata");
		useStorage = true;
		if(storage.fileExists() && storage.getDescription().substr(0,22)!="CHATPLUGIN_GOTOCOMMAND")
		{
			server.Log("chatPlugin_gotoCommand::chatPlugin_gotoCommand exception: File '"+storage.getFilename()+"' already exists. Please delete this file first.");
			useStorage = false;
		}
		if(storage.fileExists() && !storage.loadSuccessful())
			useStorage = false;

		chtmngr.addCommand("goto",        @chatPlugin_gotoCommand_goto,       @any(@this), true,  AUTH_ALL);
		chtmngr.addCommand("sgoto",       @chatPlugin_gotoCommand_setgoto,    @any(@this), false, AUTH_ALL);
		chtmngr.addCommand("setgoto",     @chatPlugin_gotoCommand_setgoto,    @any(@this), true,  AUTH_ALL);
		chtmngr.addCommand("agoto",       @chatPlugin_gotoCommand_setgoto,    @any(@this), false, AUTH_ALL);
		chtmngr.addCommand("addgoto",     @chatPlugin_gotoCommand_setgoto,    @any(@this), false, AUTH_ALL);
		chtmngr.addCommand("dgoto",       @chatPlugin_gotoCommand_deletegoto, @any(@this), false, AUTH_ADMIN | AUTH_MOD);
		chtmngr.addCommand("delgoto",     @chatPlugin_gotoCommand_deletegoto, @any(@this), false, AUTH_ADMIN | AUTH_MOD);
		chtmngr.addCommand("deletegoto",  @chatPlugin_gotoCommand_deletegoto, @any(@this), true,  AUTH_ADMIN | AUTH_MOD);
		chtmngr.addCommand("destroygoto", @chatPlugin_gotoCommand_deletegoto, @any(@this), false, AUTH_ADMIN | AUTH_MOD);
		chtmngr.addCommand("rgoto",       @chatPlugin_gotoCommand_deletegoto, @any(@this), false, AUTH_ADMIN | AUTH_MOD);
		chtmngr.addCommand("removegoto",  @chatPlugin_gotoCommand_deletegoto, @any(@this), false, AUTH_ADMIN | AUTH_MOD);
		
		gameCmdPrefix = gsm.addGameCmdCallback(chatPlugin_gotoCommand_gameCmd, @any(@this));
		registered = true;
		load();
	}

	~chatPlugin_gotoCommand()
	{
		destroy();
	}

	void destroy()
	{
		save();
		useStorage = true;

		if(registered)
		{
			chtmngr.removeCommand("goto"       );
			chtmngr.removeCommand("sgoto"      );
			chtmngr.removeCommand("setgoto"    );
			chtmngr.removeCommand("agoto"      );
			chtmngr.removeCommand("addgoto"    );
			chtmngr.removeCommand("dgoto"      );
			chtmngr.removeCommand("delgoto"    );
			chtmngr.removeCommand("deletegoto" );
			chtmngr.removeCommand("destroygoto");
			chtmngr.removeCommand("rgoto"      );
			chtmngr.removeCommand("removegoto" );
			gsm.removeGameCmdCallback(chatPlugin_gotoCommand_gameCmd);
			registered = false;
		}
	}
	
	int add(string &in location, const vector3 &in position, const vector3 &in rotation)
	{
		// ';' is not allowed, so we replace it by '_'
		location = stringReplace(location, ";", "_");
		
		// We don't overwrite locations
		if(locationsLookupTable.exists(location)) return -1;
		
		// Resize the lists
		locations.resize(free_pos+1);
		positions.resize(free_pos+1);
		rotations.resize(free_pos+1);

		// Add the location to all lists
		locationsLookupTable.set(location, free_pos);
		locations[free_pos] = location;
		positions[free_pos] = vector3ToString(position);
		rotations[free_pos] = vector3ToString(rotation);
		++free_pos;
		
		// Rebuild the help list
		rebuildPossibleLocations();
		
		// save
		save();
		
		// and return the index
		return (free_pos-1);
	}

	void remove(string &in location)
	{
		uint pos;
		location = stringReplace(location, ";", "_");
		if(locationsLookupTable.get(location, pos))
		{
			locations.removeAt(pos);
			positions.removeAt(pos);
			rotations.removeAt(pos);
			locationsLookupTable.delete(location);
			--free_pos;
			rebuildPossibleLocations();
			save();
		}
	}

	void rebuildPossibleLocations()
	{
		if(free_pos==0)
		{
			free_posloc = 1;
			possible_locations.resize(free_posloc);
			possible_locations[0] = "There are no possible locations to go to. You can add one using the !setgoto command.";
		}
		else
		{
			free_posloc = 0;
			for(uint i=0; i<free_pos; ++i)
			{
				if(i%10==0)
				{
					if(i!=0) ++free_posloc;
					possible_locations.resize(free_posloc+1);
					possible_locations[free_posloc] = "Possible locations: "+locations[i];
				}
				else
					possible_locations[free_posloc] += ", "+locations[i];
			}
			++free_posloc;
		}
	}
	
	void sayPossibleLocations(gameScript@ game) const
	{
		for(uint i=0; i<free_posloc; ++i)
		{
			game.message(possible_locations[i],  "information.png", 30000.0f, true);
		}
	}

	void callback_goto(chatMessage@ cmsg)
	{
		// don't broadcast this command
		cmsg.broadcast.block();

		if(cmsg.emsgLen<2)
		{
			cmsg.privateGameCommand.message("This command will move you to another location.", "information.png", 30000.0f, true);
			cmsg.privateGameCommand.message("usage: !goto <location>", "information.png", 30000.0f, true);
			cmsg.privateGameCommand.message("note: You cannot use this command when you're inside a vehicle.", "information.png", 30000.0f, true);
			sayPossibleLocations(cmsg.privateGameCommand);
			return;
		}

		// get and check the location
		const string loc = stringReplace(cmsg.emsg[1], ';', '_');
		int index;
		if(!locationsLookupTable.get(loc, index))
		{
			cmsg.privateGameCommand.message("Unknown location: "+loc, "cross.png", 30000.0f, true);
			sayPossibleLocations(cmsg.privateGameCommand);
			return;
		}

		// Move the user
		cmsg.privateGameCommand.addCmd(
			"""if(game.getCurrentTruckNumber()<0)
			{
				game.setPersonPosition("""+positions[index]+""");
				game.message("Welcome to '"""+loc+"""'.", "map_go.png", 30000, true);
			}
			else
			{
				game.message("You cannot use this command while driving!", "map_delete.png", 30000, true);
			}"""
		);
	}

	void callback_setgoto(chatMessage@ cmsg)
	{
		// don't broadcast this command
		cmsg.broadcast.block();
		
		// 0.39 only
		if(server.getUserVersion(cmsg.uid).findFirst("0.38")>=0)
		{
			cmsg.privateGameCommand.message("This command is not available for your game version.", "cross.png", 30000.0f, true);
			return;
		}

		if(cmsg.emsgLen<2)
		{
			cmsg.privateGameCommand.message("This command will add another location that can be used with the !goto command.", "information.png", 30000.0f, true);
			cmsg.privateGameCommand.message("usage: !sgoto <location>", "information.png", 30000.0f, true);
			cmsg.privateGameCommand.message("note: You cannot use this command when you're inside a vehicle.", "information.png", 30000.0f, true);
			return;
		}

		// get and check the location
		const string loc = stringReplace(stringReplace(cmsg.emsg[1], ';', '_'), '\'', '\\\'');
		if(locationsLookupTable.exists(loc))
		{
			cmsg.privateGameCommand.message("Location '"+loc+"' already exists!", "cross.png", 30000.0f, true);
			cmsg.privateGameCommand.message("Please try using another name.", "cross.png", 30000.0f, true);
			return;
		}
		if(containsProfanity(loc))
		{
			cmsg.privateGameCommand.message("You're not allowed to add a location with as name '"+loc+"'.", "cross.png", 30000.0f, true);
			cmsg.privateGameCommand.message("Please try using another name.", "cross.png", 30000.0f, true);
			return;
		}

		// Request the location of the user
		cmsg.privateGameCommand.addCmd(
			"""if(game.getCurrentTruckNumber()<0)
				game.sendGameCmd('"""+gameCmdPrefix+"""ADD$"""+loc+"""$'+game.getPersonPosition().x+'$'+game.getPersonPosition().y+'$'+game.getPersonPosition().z+'$0$0$0');
			else
				game.message("You cannot use this command while driving!", "map_delete.png", 30000, true);"""
		);
	}

	void callback_deletegoto(chatMessage@ cmsg)
	{
		// don't broadcast this command
		cmsg.broadcast.block();

		if(cmsg.emsgLen<2)
		{
			cmsg.privateGameCommand.message("This command will delete a location from the !goto command.", "information.png", 30000.0f, true);
			cmsg.privateGameCommand.message("usage: !dgoto <location>", "information.png", 30000.0f, true);
			sayPossibleLocations(cmsg.privateGameCommand);
			return;
		}

		// get and check the location
		const string loc = stringReplace(cmsg.emsg[1], ';', '_');
		if(!locationsLookupTable.exists(loc))
		{
			cmsg.privateGameCommand.message("Unknown location: "+loc, "cross.png", 30000.0f, true);
			sayPossibleLocations(cmsg.privateGameCommand);
			return;
		}

		// Delete it
		remove(loc);
	}

	void gameCmd(gameScriptManager_argument@ arg)
	{
		if(arg.msg.substr(0, 3)=="ADD")
		{
			// ADD$name;posx;posy;posz;rotx;roty;rotz
			array<string>@ args = arg.msg.split('$');
			if(args.length()!=8) return;
			if(add(args[1], vector3(parseFloat(args[2]), parseFloat(args[3]), parseFloat(args[4])),vector3(parseFloat(args[5]), parseFloat(args[6]), parseFloat(args[7])))<0)
				quickGameMessage(arg.uid, "Location '"+args[1]+"' already exists. Please try using another name.", "map_error.png");
			else
				quickGameMessage(arg.uid, "Location added. Say '!goto "+args[1]+"' to go to the new location.", "map_add.png");
		}
	}

	void save()
	{
		if(!useStorage) return;

		// Add the .terrn extension if it's not present
		string terrain = getTerrain();

		// TODO: only add changes
		// TODO: what did I mean when I wrote that?
		storage.load();
		storage.setDescription("CHATPLUGIN_GOTOCOMMAND This file contains the stored locations for the !goto command.");

		storage.set(terrain+"_locations", join(locations, ";"));
		storage.set(terrain+"_positions", join(positions, ";"));
		storage.set(terrain+"_rotations", join(rotations, ";"));

		if(!storage.save())
			server.Log("ERROR| chatPlugin_gotoCommand::save(): Saving failed.");
	}

	void load()
	{
		if(!useStorage) return;

		// Add the .terrn extension if it's not present
		string terrain = getTerrain();

		string tmp;
		if(storage.get(terrain+"_locations", tmp))
		{
			locations = tmp.split(";");
			for(uint i=0; i<locations.length(); ++i)
			{
				locationsLookupTable.set(locations[i], i);
			}
		}
		else
			locations.resize(0);

		if(storage.get(terrain+"_positions", tmp))
			positions = tmp.split(";");
		else
			positions.resize(0);

		if(storage.get(terrain+"_rotations", tmp))
			rotations = tmp.split(";");
		else
			rotations.resize(0);

		if(locations.length()!=rotations.length() || locations.length()!=positions.length())
		{
			locations.resize(0);
			positions.resize(0);
			rotations.resize(0);
			server.Log("chatPlugin_gotoCommand exception: The storage file did not meet expectations.");
		}

		free_pos = locations.length();
		rebuildPossibleLocations();
	}
	
	string getTerrain() const
	{
		string terrain = server.getServerTerrain();
	
		// We can't use the stringToLowerCase function from utils.as here, as utils.as may not be initialized yet
		array<uint8> charactersLowerCase =
		{ 
			0,        ord("a"), ord("b"), ord("c"), ord("d"), ord("e"), ord("f"),
			ord("g"), ord("h"), ord("i"), ord("j"), ord("k"), ord("l"), ord("m"),
			ord("n"), ord("o"), ord("p"), ord("q"), ord("r"), ord("s"), ord("t"),
			ord("u"), ord("v"), ord("w"), ord("x"), ord("y"), ord("z")
		};

		array<uint8> charactersUpperCase =
		{
			0,        ord("A"), ord("B"), ord("C"), ord("D"), ord("E"), ord("F"),
			ord("G"), ord("H"), ord("I"), ord("J"), ord("K"), ord("L"), ord("M"),
			ord("N"), ord("O"), ord("P"), ord("Q"), ord("R"), ord("S"), ord("T"),
			ord("U"), ord("V"), ord("W"), ord("X"), ord("Y"), ord("Z")
		};
		
		int index;
		for(int i=terrain.length()-1; i>=0; --i)
		{
			index = charactersUpperCase.find(terrain[i]);
			if(index>0) // ignore index==0 (some strange AS bug in linux otherwise)
				terrain[i] = charactersLowerCase[index];
		}
		
		if((terrain.length()<7 || terrain.substr(terrain.length()-6)!=".terrn") && terrain!="any")
			terrain += ".terrn";

		return terrain;
	}
}

//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////

void chatPlugin_terrainList_callback(chatMessage@ cmd)
{
	chatPlugin_terrainList@ obj;
	cmd.argument.retrieve(@obj);
	obj.chatCommand_terrainList(@cmd);
}

void chatPlugin_terrainList_gameCmd(gameScriptManager_argument@ arg)
{
	chatPlugin_terrainList@ obj;
	arg.argument.retrieve(@obj);
	obj.gameCmd(@arg);
}

class chatPlugin_terrainList_client
{
	int uid;
	bool initialized;
	string terrain;
	int version;
}

class chatPlugin_terrainList
{
	array<chatPlugin_terrainList_client> clients;
	array<string> terrainNames;
	array<int> terrainUsage;
	
	float timeSinceLastCheck;
	string gameCmdPrefix;

	bool destroyed;
	bool frameStepRegistered;
	
	private gameScriptManager@ gsm;
	private chatManager@ chtmngr;
	
	chatPlugin_terrainList(chatManager@ _chtmngr, gameScriptManager@ _gsm)
	{
		@chtmngr = @_chtmngr;
		@gsm = @_gsm;
		destroyed = false;
		frameStepRegistered = false;
		
		if(server.getServerTerrain()!="any")
		{
			server.Log("INFO| 'chatPlugin_terrainList' is disabled because the server has a fixed terrain.");
			destroyed = true;
			return;
		}
		
		server.setCallback("playerAdded",   "playerAdded", @this);
		server.setCallback("playerDeleted", "playerDeleted", @this);
		gameCmdPrefix = gsm.addGameCmdCallback(chatPlugin_terrainList_gameCmd, @any(@this));

		chtmngr.addCommand("terrainlist",  @chatPlugin_terrainList_callback, @any(@this), true,  AUTH_ALL);
		chtmngr.addCommand("terrainslist", @chatPlugin_terrainList_callback, @any(@this), false, AUTH_ALL);
		chtmngr.addCommand("terrnlist",    @chatPlugin_terrainList_callback, @any(@this), false, AUTH_ALL);
		chtmngr.addCommand("tlist",        @chatPlugin_terrainList_callback, @any(@this), false, AUTH_ALL);
	}
		
	void destroy()
	{
		if(destroyed) return;
		destroyed = true;

		if(frameStepRegistered)
			server.deleteCallback("frameStep",     "frameStep", @this);
		frameStepRegistered = false;
		
		server.deleteCallback("playerAdded",   "playerAdded", @this);
		server.deleteCallback("playerDeleted", "playerDeleted", @this);
		gsm.removeGameCmdCallback(chatPlugin_terrainList_gameCmd);
		
		chtmngr.removeCommand("terrainlist");
		chtmngr.removeCommand("terrainslist");
		chtmngr.removeCommand("terrnlist");
		chtmngr.removeCommand("tlist");
	}
	
	void frameStep(float dt)
	{
		if(clients.length()==0) return;

		timeSinceLastCheck += dt/1000;
		if(timeSinceLastCheck>5)
		{
			timeSinceLastCheck = 0;
			
			for(uint i=0; i<clients.length(); ++i)
			{
				if(!clients[i].initialized && clients[i].version>38)
				{
					// (the only reason why the gameScript object is used here, is so that all game commands go through the same wrapper)
					gameScript(clients[i].uid, "string terrain; game.getLoadedTerrain(terrain); if(terrain!='none') {game.sendGameCmd('"+gameCmdPrefix+"'+terrain); }").flush();
				}
			}
		}
	}
	
	void playerAdded(int uid)
	{		
		// Add the client
		chatPlugin_terrainList_client cl;
		cl.uid = uid;
		cl.terrain = "[unknown]";
		cl.version = (server.getUserVersion(uid).findFirst("0.38")>=0) ? 38 : 39;
		cl.initialized = false;
		clients.insertLast(cl);
		
		// Show the client as unknown in the terrainlist
		addTerrain(uid, cl.terrain);
		
		// If the client version is 0.38, then he is as initialized as he can be
		if(cl.version==38) cl.initialized = true;
		
		// Start the frameStep callback if not already running
		if(!frameStepRegistered && cl.version>38)
		{
			frameStepRegistered = true;
			server.setCallback("frameStep",     "frameStep", @this);
		}
	}
	
	void playerDeleted(int uid, int crash)
	{
		const int pos = getClientIndexByUid(uid); if(pos<0) return;
		
		delTerrain(uid);
		clients.removeAt(pos);

		if(clients.length()==0 && frameStepRegistered)
		{
			frameStepRegistered = false;
			server.deleteCallback("frameStep",     "frameStep", @this);
		}
	}

	void gameCmd(gameScriptManager_argument@ arg)
	{
		addTerrain(arg.uid, arg.msg);
		
		bool complete = true;
		for(uint i=0; i<clients.length(); ++i)
		{
			if(!clients[i].initialized)
			{
				complete = false;
				break;
			}
		}
		
		if(complete && frameStepRegistered)
		{
			frameStepRegistered = false;
			server.deleteCallback("frameStep",     "frameStep", @this);
		}
	}
	
	void addTerrain(int uid, string &in terrain)
	{
		const int pos = getClientIndexByUid(uid); if(pos<0) return;
		
		// Remove the .terrn extension and the terrain UID
		terrain = stringToLowerCase(terrain);
		if(terrain.length()>=7 && terrain.substr(terrain.length()-6)==".terrn")
			terrain = terrain.substr(0, terrain.length()-6);
		int uidIndex = terrain.findFirst("uid-");
		if(uidIndex>=0)
			terrain = terrain.substr(uidIndex+4);
		
		// Remove possible old terrain from the lists
		delTerrain(uid);
		
		// Add the new terrain to the lists
		int index = terrainNames.find(terrain);
		if(index<0)
		{
			terrainNames.insertLast(terrain);
			terrainUsage.insertLast(1);
		}
		else
		{
			terrainUsage[index] += 1;
		}
		
		// Update clients list
		clients[pos].terrain = terrain;
		clients[pos].initialized = (terrain!="[unknown]");
		
		// Show the terrain list to the user
		if(clients[pos].initialized)
		{
			if(clients.length()>1)
			{
				gameScript script(uid);
				createTerrainList(@script);
				script.flush();
			}
			//quickGameMessage(TO_ALL, server.getUserName(clients[pos].uid) + " arrived in " + terrain + ".", "map.png");
		}
	}
	
	void delTerrain(int uid)
	{
		const int pos = getClientIndexByUid(uid); if(pos<0) return;

		// find the old terrain in the terrains list
		int index = terrainNames.find(clients[pos].terrain);
		if(index>=0)
		{
			terrainUsage[index] -= 1;
			if(terrainUsage[index]<=0)
			{
				terrainUsage.removeAt(index);
				terrainNames.removeAt(index);
			}
		}
		
		clients[pos].terrain = "[unknown]";
		clients[pos].initialized = false;
	}
	
	void chatCommand_terrainList(chatMessage@ cmd)
	{
		createTerrainList(@cmd.privateGameCommand);
	}
	
	void createTerrainList(gameScript@ script)
	{
		if(terrainNames.length()==0)
		{
			script.message("There's currently no terrain information available.", "map.png", 30000.0f, true);
		}
		else
		{
			for(uint i=0; i<terrainNames.length(); ++i)
			{
				script.message("Terrain "+terrainNames[i]+" has "+terrainUsage[i]+" players.", "map.png", 30000.0f, true);
			}
		}
	}
	
	int getClientIndexByUid(const int &in uid) const
	{
		for(uint i=0; i<clients.length(); ++i)
		{
			if(clients[i].uid==uid)
				return i;
		}
		return -1;
	}
}

//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////

const uint PING_LOGSIZE   = 15; //!< How many ping results that we store and calculate the average of.
const uint PING_FREQUENCY = 3; //!< How many times a minute do we ping clients?

void chatPlugin_ping_cmdCallback(chatMessage@ ccmsg)
{
	chatPlugin_ping@ obj;
	ccmsg.argument.retrieve(@obj);
	obj.chatCommand_ping(ccmsg);
}

void chatPlugin_ping_gameCmd(gameScriptManager_argument@ arg)
{
	chatPlugin_ping@ obj;
	arg.argument.retrieve(@obj);
	obj.gameCmd(@arg);
}

class chatPlugin_ping_result
{
	float ping;
	int64 time;
	
	chatPlugin_ping_result()
	{
		ping = -1.0f;
		time = 0;
	}
}
		
class chatPlugin_ping_client
{
	int uid;
	
	array<chatPlugin_ping_result@> log;
	uint index;
}
		
class chatPlugin_ping
{
	array<chatPlugin_ping_client@> clients;
	float timeBetweenPingRequests;
	float timeSinceLastPingRequest;
	bool destroyed;
	bool frameStepRegistered;
	
	private gameScriptManager@ gsm;
	private chatManager@ chtmngr;
	string gameCmdPrefix;
	
	chatPlugin_ping(chatManager@ _chtmngr, gameScriptManager@ _gsm)
	{
		@chtmngr = @_chtmngr;
		@gsm = @_gsm;
		timeBetweenPingRequests = 60.0f/float(PING_FREQUENCY);
		timeSinceLastPingRequest = 0.0f;
		destroyed = false;
		frameStepRegistered = false;
		
		server.setCallback("playerAdded",   "playerAdded",   @this);
		server.setCallback("playerDeleted", "playerDeleted", @this);

		chtmngr.addCommand("ping", @chatPlugin_ping_cmdCallback, @any(@this), true,  AUTH_ALL);


		gameCmdPrefix = gsm.addGameCmdCallback(chatPlugin_ping_gameCmd, @any(@this));
	}
		
	void destroy()
	{
		if(destroyed) return;
		destroyed = true;
		frameStepRegistered = false;
		
		server.deleteCallback("frameStep",     "frameStep", @this);
		server.deleteCallback("playerAdded",   "playerAdded", @this);
		server.deleteCallback("playerDeleted", "playerDeleted", @this);
		gsm.removeGameCmdCallback(chatPlugin_ping_gameCmd);
		
		chtmngr.removeCommand("ping");
	}
	
	void frameStep(float dt)
	{
		if(clients.length()==0) return;

		timeSinceLastPingRequest += dt/1000;
		if(timeSinceLastPingRequest>timeBetweenPingRequests)
		{
			timeSinceLastPingRequest = 0;
			
			// Create a gameScript object
			gameScript cmd(-2, "game.sendGameCmd('"+gameCmdPrefix+"REQ$'+game.getTime()+'$internal$1');");
			
			// Send a the ping request to all clients
			// We can't use TO_ALL here, due to 0.38 compatibility
			for(uint i=0; i<clients.length(); ++i)
			{
				cmd.sendTo(clients[i].uid);
			}
			
			// Clear the gameScript object
			cmd.clearBuffer();
		}
	}
	
	void playerAdded(int uid)
	{
		// Ignore 0.38 players
		if(server.getUserVersion(uid).findFirst("0.38")>=0)
			return;
		
		// Ignore bots
		if((server.getUserAuthRaw(uid)&AUTH_BOT)>0)
			return;

		chatPlugin_ping_client cl;
		cl.uid = uid;
		cl.index = 0;
		cl.log.resize(PING_LOGSIZE);
		clients.insertLast(@cl);
		
		if(!frameStepRegistered && clients.length()==1)
		{
			frameStepRegistered = true;
			server.setCallback("frameStep",     "frameStep", @this);
		}
	}
	
	void playerDeleted(int uid, int crash)
	{
		const int pos = getClientIndexByUid(uid); if(pos<0) return;
		clients.removeAt(pos);
		if(clients.length()==0 && frameStepRegistered)
		{
			frameStepRegistered = false;
			server.deleteCallback("frameStep",     "frameStep", @this);
		}
	}

	void gameCmd(gameScriptManager_argument@ gsa)
	{
		if(gsa.msg.substr(0, 3)=="REQ")
		{
			const array<string>@ arg = gsa.msg.split('$');
			if(arg.length()!=4) return;
			
			// Send a response
			// (the only reason why the gameScript object is used here, is so that all game commands go through the same wrapper)
			gameScript(gsa.uid, "game.sendGameCmd('"+gameCmdPrefix+"RES$'+(game.getTime()-"+arg[1]+")+'$"+arg[2]+"$"+arg[3]+"');").flush();
		}
		else if(gsa.msg.substr(0, 3)=="RES")
		{
			const array<string>@ arg = gsa.msg.split('$');
			if(arg.length()!=4) return;
			const float ping = parseFloat(arg[1])*1000;
			if(arg[2]=='by_cmd')
			{
				gameScript game(gsa.uid);
				game.message("PING: current ping: "+ping+" ms.", "server_connect.png", 30000.0f, true);
				int num = parseInt(arg[3]);
				if(--num>0)
					game.addCmd("game.sendGameCmd('"+gameCmdPrefix+"REQ$'+game.getTime()+'$by_cmd$"+num+"');");
				game.flush();
			}
			else if(arg[2]=='internal')
			{
				addPing(gsa.uid, ping);
			}
		}
	}
	
	void chatCommand_ping(chatMessage@ ccmsg)
	{
		if(getClientIndexByUid(ccmsg.uid)<0)
		{
			ccmsg.privateGameCommand.message("This command is not available for your game version.", "cross.png", 30000.0f, true);
			return;
		}
	
		// show the ping results
		ccmsg.privateGameCommand.message("PING: "+formatPing(ccmsg.uid), "server_connect.png", 30000.0f, true);
		
		// do a new ping request
		ccmsg.privateGameCommand.addCmd("game.sendGameCmd('"+gameCmdPrefix+"REQ$'+game.getTime()+'$by_cmd$1');");
	}
	
	string formatPing(int uid)
	{
		// get the slot for this uid
		const int pos = getClientIndexByUid(uid); if(pos<0) return "Service currently not available.";
		
		// Accumulate all the ping results that we have available for this user
		array<float> pingList;
		for(uint i=0; i<PING_LOGSIZE; ++i)
		{
			if(clients[pos].log[i] !is null)
				pingList.insertLast(clients[pos].log[i].ping);
		}
		pingList.sortAsc();
		
		
		// If we didn't find any ping that was set, then we return a negative value
		if(pingList.length()==0)
			return "No ping from history found.";
		
		float min = pingList[0];
		float max = pingList[pingList.length()-1];
		float avg = average(pingList);
		
		// return the ping numbers
		return "min/avg/max: "+formatFloat(min, "", 0, 3)+"/"+formatFloat(avg, "", 0, 3)+"/"+formatFloat(max, "", 0, 3)+" ms (from ping results over the past "+formatTime(pingList.length()*timeBetweenPingRequests)+")";
	}
	
	void addPing(int uid, float ping)
	{
		// get the slot for this uid
		const int pos = getClientIndexByUid(uid); if(pos<0) return;
		
		// create a ping result object
		chatPlugin_ping_result res;
		res.ping = ping;
		res.time = server.getTime();
		
		// Get the index where we need to insert the ping into
		clients[pos].index++;
		if(clients[pos].index>=PING_LOGSIZE)
			clients[pos].index = 0;
		
		// And add the ping
		@clients[pos].log[clients[pos].index] = @res;
	}

	float getPing(int uid)
	{
		// get the slot for this uid
		const int pos = getClientIndexByUid(uid); if(pos<0) return -1.0f;
		
		// Accumulate all the ping results that we have available for this user
		float ping = 0.0f;
		int pingCount = 0;
		for(uint i=0; i<PING_LOGSIZE; ++i)
		{
			if(clients[pos].log[i] !is null)
			{
				ping += clients[pos].log[i].ping;
				++pingCount;
			}
		}
		
		// If we didn't find any ping that was set, then we return a negative value
		if(pingCount==0)
			return -1.0f;
		
		// return the ping that we found, divided by the amount of pings that we accumulated
		// So we return an average ping
		return (ping/float(pingCount));
	}
	
	int getClientIndexByUid(const int &in uid) const
	{
		for(uint i=0; i<clients.length(); ++i)
		{
			if(clients[i].uid==uid)
				return i;
		}
		return -1;
	}
}
