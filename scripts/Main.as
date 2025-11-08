#include "chatManager.as"
#include "terrainEditor.as"
#include "gameScriptWrapper.as"
#include "welcome.as"
#include "streamValidation.as"
#include "botAPI.as"
#include "kickNotificationWrapper.as"
#include "ipChecker.as"

// Create a chatManager object instance
chatManager chatSystem();



// Create a gameScriptManager object instance.
gameScriptManager gsm();



// Add the autoModerator plugin.
// This plugin allows the following commands:
//     - !suspendchat   Suspend all chat traffic for a certain time
//     - !schat         Short for !suspendchat
//     - !chatban       Blocks all chat messages from a certain user for a
//                      certain time
//     - !cban          Short for !chatban
//     - !temporaryban  Not yet implemented
//     - !tempban       Short for !temporaryban
//     - !tban       Short for !temporaryban
// Furthermore, it adds the profanity filter and flood filter to the chat.
chatPlugin_autoModerator autoModerator(@chatSystem);

// This small plugin transform messages like:
//      Anonymous: OMG LOOK ATZ ME
// to:
//      Anonymous: Omg look atz me
chatPlugin_disallowAllUpperCase disallowAllUpperCase(@chatSystem);

// This plugin adds the following commands:
//     - !afk           Prints "<username> is now away from keyboard."
//     - !back          Prints "<username> is now back."
//     - !gtg           Prints "<username> has got to go."
//     - !brb           Prints "<username> will be right back."
chatPlugin_miscellaneousCommands miscellaneousCommands(@chatSystem);

// This command adds the !move command, which will move your avatar in the
// specified direction.
chatPlugin_moveCommand moveCommand(@chatSystem);

// This commands adds the !goto, !setgoto (!sgoto) and !delelegoto (!dgoto)
// command. It allows you to store the position of your avatar (!setgoto <name>)
// and later teleport to that position (!goto <name>).
// Note: The !setgoto command works only with RoR 0.39! (not with 0.38)
chatPlugin_gotoCommand gotoCommand(@chatSystem, @gsm);

// This keeps track of what terrains are being used on the server and gives a
// list when the !terrainlist (!tlist) command is used.
// Note: All clients with RoR 0.38 will be shown as 'unknown terrain'.
chatPlugin_terrainList terrainList(@chatSystem, @gsm);

// This checks the latency of all RoR 0.39 players every 20 seconds and responds
// to !ping commands.
chatPlugin_ping ping(@chatSystem, @gsm);

// Another example, to show how to add commands.
// This adds a command !boost that gives a temporary boost to the truck of
// the user.
customCommand boostCommand(@chatSystem, "boost", customCommand_boost);
void customCommand_boost(chatMessage@ cmsg)
{
	cmsg.privateGameCommand.boostCurrentTruck(2);
}
// Extra boost commands
customCommand boost2Command(@chatSystem, "boost2", customCommand_boost2);
void customCommand_boost2(chatMessage@ cmsg)
{
	cmsg.privateGameCommand.boostCurrentTruck(5);
}
customCommand boost3Command(@chatSystem, "boost3", customCommand_boost3);
void customCommand_boost3(chatMessage@ cmsg)
{
	cmsg.privateGameCommand.boostCurrentTruck(8);
}
customCommand boost4Command(@chatSystem, "boost4", customCommand_boost4);
void customCommand_boost4(chatMessage@ cmsg)
{
	cmsg.privateGameCommand.boostCurrentTruck(10);
}


// Add the terrain editor (RoR 0.39 only!)
// Commented out, doesn't work correctly yet.
//terrainEditor ternnditor(@chatSystem, @gsm);



// Load the terrain edits
terrainFileLoader terrain(@gsm, server.getServerTerrain());



// Add some commands that allow you to reload the terrain file, without having to restart the server.
customCommand reloadTerrainCommand(@chatSystem, "reloadterrain", customCommand_reloadTerrain, null, true, AUTH_ADMIN);
void customCommand_reloadTerrain(chatMessage@) { terrain.reload(); }

customCommand unloadTerrainCommand(@chatSystem, "unloadterrain", customCommand_unloadTerrain, null, true, AUTH_ADMIN);
void customCommand_unloadTerrain(chatMessage@) { terrain.unload(); }

customCommand loadTerrainCommand(@chatSystem, "loadterrain", customCommand_loadTerrain, null, true, AUTH_ADMIN);
void customCommand_loadTerrain(chatMessage@)   { terrain.load();   }

// This is a list of stream names that will not be broadcasted 
array<string>  streamFilterList =  
{ 
	"foo.truck","bar.truck"
}; 
//streamValidation bannedCars(@streamFilterList, BLACKLIST);

// Remove the // in front of the next line to enable the IP checker system.
// Make sure to set your email address in ipChecker.as, otherwise this won't work
// we don't have a config file for scripts yet, sooo... yeah
// ipChecker ip("mysupersecret@notvalid.com");


// Our main function (never remove this, even when it does nothing useful!)
void main()
{
	server.Log("The script file is working :D");
	server.setCallback("playerAdded", "authWarning_playerAdded", null);
}

// Add this somewhere else, for example at the very bottom of ExampleScript.as
void authWarning_playerAdded(int uid)
{
	if((server.getUserAuthRaw(uid)&(AUTH_ADMIN|AUTH_MOD))>0)
		server.say(server.getUserName(uid)+" is a server "+server.getUserAuth(uid), TO_ALL, FROM_HOST);
}