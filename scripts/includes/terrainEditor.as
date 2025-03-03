#include "gameScriptWrapper.as"
#include "utils.as"
#include "localStorage.as"

void terrainEditor_chatCommand_build(chatMessage@ cmd)
{
	terrainEditor@ obj;
	cmd.argument.retrieve(@obj);
	obj.chatCommand_build(@cmd);
}

void terrainEditor_chatCommand_editmode(chatMessage@ cmd)
{
	terrainEditor@ obj;
	cmd.argument.retrieve(@obj);
	obj.chatCommand_editmode(@cmd);
}

void terrainEditor_chatCommand_setBrush(chatMessage@ cmd)
{
	terrainEditor@ obj;
	cmd.argument.retrieve(@obj);
	obj.chatCommand_setBrush(@cmd);
}

void terrainEditor_chatCommand_setRadius(chatMessage@ cmd)
{
	terrainEditor@ obj;
	cmd.argument.retrieve(@obj);
	obj.chatCommand_setRadius(@cmd);
}

void terrainEditor_chatCommand_setRotation(chatMessage@ cmd)
{
	terrainEditor@ obj;
	cmd.argument.retrieve(@obj);
	obj.chatCommand_setRotation(@cmd);
}

void terrainEditor_chatCommand_setTilt(chatMessage@ cmd)
{
	terrainEditor@ obj;
	cmd.argument.retrieve(@obj);
	obj.chatCommand_setTilt(@cmd);
}

void terrainEditor_chatCommand_setBank(chatMessage@ cmd)
{
	terrainEditor@ obj;
	cmd.argument.retrieve(@obj);
	obj.chatCommand_setBank(@cmd);
}

void terrainEditor_chatCommand_setHeight(chatMessage@ cmd)
{
	terrainEditor@ obj;
	cmd.argument.retrieve(@obj);
	obj.chatCommand_setHeight(@cmd);
}

void terrainEditor_chatCommand_setRelativeRadius(chatMessage@ cmd)
{
	terrainEditor@ obj;
	cmd.argument.retrieve(@obj);
	obj.chatCommand_setRelativeRadius(@cmd);
}

void terrainEditor_chatCommand_setRelativeRotation(chatMessage@ cmd)
{
	terrainEditor@ obj;
	cmd.argument.retrieve(@obj);
	obj.chatCommand_setRelativeRotation(@cmd);
}

void terrainEditor_chatCommand_setRelativeTilt(chatMessage@ cmd)
{
	terrainEditor@ obj;
	cmd.argument.retrieve(@obj);
	obj.chatCommand_setRelativeTilt(@cmd);
}

void terrainEditor_chatCommand_setRelativeBank(chatMessage@ cmd)
{
	terrainEditor@ obj;
	cmd.argument.retrieve(@obj);
	obj.chatCommand_setRelativeBank(@cmd);
}

void terrainEditor_chatCommand_setRelativeHeight(chatMessage@ cmd)
{
	terrainEditor@ obj;
	cmd.argument.retrieve(@obj);
	obj.chatCommand_setRelativeHeight(@cmd);
}

void terrainEditor_chatCommand_clear(chatMessage@ cmd)
{
	terrainEditor@ obj;
	cmd.argument.retrieve(@obj);
	obj.chatCommand_clear(@cmd);
}

void terrainEditor_chatCommand_brushInfo(chatMessage@ cmd)
{
	terrainEditor@ obj;
	cmd.argument.retrieve(@obj);
	obj.chatCommand_brushInfo(@cmd);
}

void terrainEditor_chatCommand_undo(chatMessage@ cmd)
{
	terrainEditor@ obj;
	cmd.argument.retrieve(@obj);
	obj.chatCommand_undo(@cmd);
}

void terrainEditor_gameCmd(gameScriptManager_argument@ arg)
{
	terrainEditor@ obj;
	arg.argument.retrieve(@obj);
	obj.gameCmd(@arg);
}

bool terrainEditor_v39OrLater(int uid, any@ arg)
{
	terrainEditor@ obj;
	arg.retrieve(@obj);
	return (obj.getClientVersion(uid)>=39);
}

bool terrainEditor_v38Only(int uid, any@ arg)
{
	terrainEditor@ obj;
	arg.retrieve(@obj);
	return (obj.getClientVersion(uid)==38);
}

class terrainEditor_object
{
	string oname;
	vector3 pos;
	vector3 rot;
}

class terrainEditor_client
{
	int uid;
	string username;
	int version;

	bool initialized;
	bool enabled;
	int objectCount;
	array<string> cmd_add;


	string brushObject;
	float brushRadius;
	vector3 brushRotation;
	vector3 brushOffset;
}

class terrainEditor
{
	chatManager@ chatman;
	gameScriptManager@ gsm;

	
	gameScript clientSideScript_common;
	gameScript clientSideScript_v38;
	gameScript clientSideScript_v39;

	array<terrainEditor_client@> clients;
	array<string> objects;

	string gameCmdPrefix;
	localStorage@ storage;

	terrainEditor(chatManager@ chatman_, gameScriptManager@ gsm_)
	{
		@chatman = @chatman_;
		@gsm = @gsm_;
		@storage = @localStorage("terrainEditor_userBuilds.asdata");

		// Register some commands
		chatman.addCommand("build", terrainEditor_chatCommand_build, @any(@this), true,  AUTH_ALL);
		chatman.addCommand("b",     terrainEditor_chatCommand_build, @any(@this), false, AUTH_ALL);

		chatman.addCommand("setbrush", terrainEditor_chatCommand_setBrush, @any(@this), true,  AUTH_ALL);
		chatman.addCommand("sbr",      terrainEditor_chatCommand_setBrush, @any(@this), false, AUTH_ALL);

		//chatman.addCommand("nextbrush", terrainEditor_chatCommand_nextbrush, @any(@this), true, AUTH_ALL);
		//chatman.addCommand("brushlist", terrainEditor_chatCommand_brushlist, @any(@this), true, AUTH_ALL);

		chatman.addCommand("clear", terrainEditor_chatCommand_clear, @any(@this), true,  AUTH_ALL);
		chatman.addCommand("cls",   terrainEditor_chatCommand_clear, @any(@this), false, AUTH_ALL);

		chatman.addCommand("editmode", terrainEditor_chatCommand_editmode, @any(@this), true, AUTH_ALL);

		chatman.addCommand("brushinfo", terrainEditor_chatCommand_brushInfo, @any(@this), true,  AUTH_ALL);
		chatman.addCommand("binfo",     terrainEditor_chatCommand_brushInfo, @any(@this), false, AUTH_ALL);
		chatman.addCommand("bi",        terrainEditor_chatCommand_brushInfo, @any(@this), false, AUTH_ALL);

		chatman.addCommand("undo",      terrainEditor_chatCommand_undo, @any(@this), true, AUTH_ALL);

		//chatman.addCommand("loadpreset", terrainEditor_chatCommand_loadPreset, @any(@this), true,  AUTH_ALL);
		//chatman.addCommand("lpr",        terrainEditor_chatCommand_loadPreset, @any(@this), false, AUTH_ALL);

		//chatman.addCommand("savepresetas", terrainEditor_chatCommand_savePresetAs, @any(@this), true,  AUTH_ALL);
		//chatman.addCommand("spra",         terrainEditor_chatCommand_savePresetAs, @any(@this), false, AUTH_ALL);

		//chatman.addCommand("quicksave", terrainEditor_chatCommand_quickSave, @any(@this), true,  AUTH_ALL);
		//chatman.addCommand("qs",        terrainEditor_chatCommand_quickSave, @any(@this), false, AUTH_ALL);

		// absolute movements
		chatman.addCommand("setradius",   terrainEditor_chatCommand_setRadius, @any(@this), true,  AUTH_ALL);
		chatman.addCommand("setdistance", terrainEditor_chatCommand_setRadius, @any(@this), false, AUTH_ALL);
		chatman.addCommand("setdist",     terrainEditor_chatCommand_setRadius, @any(@this), false, AUTH_ALL);
		chatman.addCommand("sd",          terrainEditor_chatCommand_setRadius, @any(@this), false, AUTH_ALL);

		chatman.addCommand("setrotation", terrainEditor_chatCommand_setRotation, @any(@this), true,  AUTH_ALL);
		chatman.addCommand("setrot",      terrainEditor_chatCommand_setRotation, @any(@this), false, AUTH_ALL);
		chatman.addCommand("sr",          terrainEditor_chatCommand_setRotation, @any(@this), false, AUTH_ALL);
		chatman.addCommand("setpan",      terrainEditor_chatCommand_setRotation, @any(@this), false, AUTH_ALL);
		chatman.addCommand("sp",          terrainEditor_chatCommand_setRotation, @any(@this), false, AUTH_ALL);

		chatman.addCommand("settilt", terrainEditor_chatCommand_setTilt, @any(@this), true,  AUTH_ALL);
		chatman.addCommand("st",      terrainEditor_chatCommand_setTilt, @any(@this), false, AUTH_ALL);

		chatman.addCommand("setbank", terrainEditor_chatCommand_setBank, @any(@this), true,  AUTH_ALL);
		chatman.addCommand("sba",     terrainEditor_chatCommand_setBank, @any(@this), false, AUTH_ALL);

		chatman.addCommand("setheight", terrainEditor_chatCommand_setHeight, @any(@this), true,  AUTH_ALL);
		chatman.addCommand("sh",        terrainEditor_chatCommand_setHeight, @any(@this), false, AUTH_ALL);

		// relative movements
		chatman.addCommand("setrradius",   terrainEditor_chatCommand_setRelativeRadius, @any(@this), true,  AUTH_ALL);
		chatman.addCommand("setrdistance", terrainEditor_chatCommand_setRelativeRadius, @any(@this), false, AUTH_ALL);
		chatman.addCommand("setrdist",     terrainEditor_chatCommand_setRelativeRadius, @any(@this), false, AUTH_ALL);
		chatman.addCommand("srd",          terrainEditor_chatCommand_setRelativeRadius, @any(@this), false, AUTH_ALL);

		chatman.addCommand("setrrotation", terrainEditor_chatCommand_setRelativeRotation, @any(@this), true,  AUTH_ALL);
		chatman.addCommand("setrrot",      terrainEditor_chatCommand_setRelativeRotation, @any(@this), false, AUTH_ALL);
		chatman.addCommand("srr",          terrainEditor_chatCommand_setRelativeRotation, @any(@this), false, AUTH_ALL);
		chatman.addCommand("setrpan",      terrainEditor_chatCommand_setRelativeRotation, @any(@this), false, AUTH_ALL);
		chatman.addCommand("srp",          terrainEditor_chatCommand_setRelativeRotation, @any(@this), false, AUTH_ALL);

		chatman.addCommand("setrtilt", terrainEditor_chatCommand_setRelativeTilt, @any(@this), true,  AUTH_ALL);
		chatman.addCommand("srt",      terrainEditor_chatCommand_setRelativeTilt, @any(@this), false, AUTH_ALL);

		chatman.addCommand("setrbank", terrainEditor_chatCommand_setRelativeBank, @any(@this), true,  AUTH_ALL);
		chatman.addCommand("srb",      terrainEditor_chatCommand_setRelativeBank, @any(@this), false, AUTH_ALL);

		chatman.addCommand("setrheight", terrainEditor_chatCommand_setRelativeHeight, @any(@this), true,  AUTH_ALL);
		chatman.addCommand("srh",        terrainEditor_chatCommand_setRelativeHeight, @any(@this), false, AUTH_ALL);

		// I decided to change the name of relative movements to delta movements :) (only the command names though)
		chatman.addCommand("setdradius",   terrainEditor_chatCommand_setRelativeRadius, @any(@this), true,  AUTH_ALL);
		chatman.addCommand("setddistance", terrainEditor_chatCommand_setRelativeRadius, @any(@this), false, AUTH_ALL);
		chatman.addCommand("setddist",     terrainEditor_chatCommand_setRelativeRadius, @any(@this), false, AUTH_ALL);
		chatman.addCommand("sdd",          terrainEditor_chatCommand_setRelativeRadius, @any(@this), false, AUTH_ALL);

		chatman.addCommand("setdrotation", terrainEditor_chatCommand_setRelativeRotation, @any(@this), true,  AUTH_ALL);
		chatman.addCommand("setdrot",      terrainEditor_chatCommand_setRelativeRotation, @any(@this), false, AUTH_ALL);
		chatman.addCommand("sdr",          terrainEditor_chatCommand_setRelativeRotation, @any(@this), false, AUTH_ALL);
		chatman.addCommand("setdpan",      terrainEditor_chatCommand_setRelativeRotation, @any(@this), false, AUTH_ALL);
		chatman.addCommand("sdp",          terrainEditor_chatCommand_setRelativeRotation, @any(@this), false, AUTH_ALL);

		chatman.addCommand("setdtilt", terrainEditor_chatCommand_setRelativeTilt, @any(@this), true,  AUTH_ALL);
		chatman.addCommand("sdt",      terrainEditor_chatCommand_setRelativeTilt, @any(@this), false, AUTH_ALL);

		chatman.addCommand("setdbank", terrainEditor_chatCommand_setRelativeBank, @any(@this), true,  AUTH_ALL);
		chatman.addCommand("sdb",      terrainEditor_chatCommand_setRelativeBank, @any(@this), false, AUTH_ALL);

		chatman.addCommand("setdheight", terrainEditor_chatCommand_setRelativeHeight, @any(@this), true,  AUTH_ALL);
		chatman.addCommand("sdh",        terrainEditor_chatCommand_setRelativeHeight, @any(@this), false, AUTH_ALL);

		// Register some callbacks
		server.setCallback("playerAdded",   "playerAdded", @this);
		server.setCallback("playerDeleted", "playerDeleted", @this);
		string gameCmdPrefix = gsm.addGameCmdCallback(terrainEditor_gameCmd, @any(@this));

		// Initialize the gameScriptManager with some functions
		clientSideScript_common.addScriptVariable("int personalObjectCount;");
		clientSideScript_common.addScriptVariable("bool terrainEditModeEnabled;");
		clientSideScript_common.addScriptVariable("string currentBrushObject;");
		clientSideScript_common.addScriptVariable("float currentBrushRadius;");
		clientSideScript_common.addScriptVariable("vector3 currentBrushRotation;");
		clientSideScript_common.addScriptVariable("float timeSinceLastUpdate;");
		clientSideScript_common.addScriptVariable("vector3 currentBrushOffset;");
		clientSideScript_common.addScriptVariable("int terrainEditorMyUid;");
		clientSideScript_common.addScriptVariable("string terrainEditor_gameCmdPrefix;");
		clientSideScript_common.addScriptVariable("bool terrainEditor_frameStepRegistered;");
		clientSideScript_common.addScriptVariable("bool terrainEditor_sendFrameToServer;");
		clientSideScript_common.splitCommandHere();
		clientSideScript_common.addCmd("personalObjectCount = 0;");
		clientSideScript_common.addCmd("terrainEditModeEnabled = false;");
		clientSideScript_common.addCmd("currentBrushObject = 'road';");
		clientSideScript_common.addCmd("timeSinceLastUpdate = 1.0f;");
		clientSideScript_common.addCmd("currentBrushRadius = 15.0f;");
		clientSideScript_common.addCmd("currentBrushRotation = vector3(0.0f, 0.0f, 0.0f);");
		clientSideScript_common.addCmd("currentBrushOffset = vector3(0.0f, 0.2f, 0.0f);");
		clientSideScript_common.addCmd("terrainEditor_gameCmdPrefix = '"+gameCmdPrefix+"';");
		clientSideScript_common.addCmd("terrainEditor_frameStepRegistered = false;");
		clientSideScript_common.addCmd("terrainEditor_sendFrameToServer = true;");

		clientSideScript_common.addScriptFunction(
			'void terrainEditor_sendGameCmd(const array<string> &in args)'
			'{'
			'	string result = "";'
			'	for(uint i=0; i<args.length(); ++i)'
			'	{'
			'		result += args[i];'
			'		if(i!=(args.length()-1))'
			'		{'
			'			result += "$";'
			'		}'
			'	}'
			'	sendGameCmd(terrainEditor_gameCmdPrefix+result);'
			'}'
		);
		clientSideScript_common.addScriptFunction("""
			string terrainEditor_serializeVector3(const vector3 &in v)
			{
				return formatFloat(v.x, "", 5, 5)+"f,"+formatFloat(v.y, "", 5, 5)+"f,"+formatFloat(v.z, "", 5, 5)+"f";
			}
		""");
		clientSideScript_common.addScriptFunction("""
			string terrainEditor_vector3ToString(const vector3 &in v)
			{
				return "("+formatFloat(v.x, "", 5, 5)+", "+formatFloat(v.y, "", 5, 5)+", "+formatFloat(v.z, "", 5, 5)+")";
			}
		""");	
		clientSideScript_common.addScriptFunction("""
			void buildBrush()
			{
				// Get the brush position
				vector3 dir(game.getCameraDirection());
				dir.normalise();
				vector3 position = (game.getPersonPosition()+(dir*vector3(1,0,1)*currentBrushRadius)+currentBrushOffset);

				// Get the instance name
				string iname = "object_"+personalObjectCount+"_"+terrainEditorMyUid;

				// Build
				game.spawnObject(currentBrushObject, iname, position, currentBrushRotation, "defaultEventCallback", false);

				// Notify server
				array<string> args = {
					"SPAWN",
					currentBrushObject,
					iname,
					terrainEditor_serializeVector3(position),
					terrainEditor_serializeVector3(currentBrushRotation)
				};
				terrainEditor_sendGameCmd(args);
				
				// Increase the object counter
				personalObjectCount++;
			}
		""");
		clientSideScript_common.addScriptFunction("""
			void clearObjects(const int &in uid, const int &in ocount)
			{
				for(int i=0; i<ocount; ++i)
				{
					game.destroyObject("object_"+i+"_"+uid);
				}
				if(uid==terrainEditorMyUid)
					personalObjectCount = 0;
			}
		""");
		clientSideScript_common.addScriptFunction("""
			void setBrush(const string &in obj)
			{
				currentBrushObject = obj;
			}
		""");
		clientSideScript_common.addScriptFunction("""
			void setBrushOffset(const vector3 &in vec)
			{
				currentBrushOffset = vec;
			}
		""");
		clientSideScript_common.addScriptFunction("""
			void setRadius(const float &in rad)
			{
				currentBrushRadius = rad;
			}
		""");
		clientSideScript_common.addScriptFunction("""
			void setRotation(const vector3 &in vec)
			{
				currentBrushRotation = vec;
			}
		""");
		clientSideScript_common.addScriptFunction("""
			void showBrushInfo()
			{
				// Get the brush position
				vector3 dir(game.getCameraDirection());
				dir.normalise();
				vector3 brushPosition = (game.getPersonPosition()+(dir*vector3(1,0,1)*currentBrushRadius)+currentBrushOffset);

				// Start outputting stuff
				game.message("Terrain edit mode enabled: "+(terrainEditModeEnabled ? "yes" : "no"), "information.png", 30000, true);
				game.message("Brush object: "+currentBrushObject, "information.png", 30000, true);
				game.message("Brush position: "+terrainEditor_vector3ToString(brushPosition), "information.png", 30000, true);
				game.message("Brush rotation: "+terrainEditor_vector3ToString(currentBrushRotation), "information.png", 30000, true);
				game.message("Brush offset: "+terrainEditor_vector3ToString(currentBrushOffset), "information.png", 30000, true);
				game.message("Brush radius: "+currentBrushRadius, "information.png", 30000, true);
				game.message("Amount of objects built: "+personalObjectCount, "information.png", 30000, true);
				game.message("Game version: Rigs of Rods 0."+clientVersion, "information.png", 30000, true);
				game.message("Object sharing support: "+((clientVersion>=39) ? "yes" : "no"), "information.png", 30000, true);
				game.message("Amount of shared objects: "+((clientVersion>=39) ? (""+personalObjectCount) : "0"), "information.png", 30000, true);
			}
		""");
		// TODO: this can only undo building atm
		clientSideScript_common.addScriptFunction("""
			void undo()
			{
				// Subtract 1 of the object count
				--personalObjectCount;
				
				// Get the instance name
				string iname = "object_"+personalObjectCount+"_"+terrainEditorMyUid;

				// Destroy
				game.destroyObject(iname);

				// Notify server
				array<string> args = {
					"UNDO",
					iname
				};
				terrainEditor_sendGameCmd(args);
			}
		""");
		clientSideScript_common.addScriptFunction("""
			void enterEditMode()
			{
				if(game.getCurrentTruckNumber()>=0)
				{
					// Notify user
					game.message("You cannot use this command while driving!", "map_delete.png", 30000, true);

					// Notify the server
					array<string> args = {
						"ERROR",
						"TRUCK",
						"Error while enabling edit mode: Cannot enter edit mode while inside vehicle."
					};
					terrainEditor_sendGameCmd(args);

					// stop here
					return;
				}

				if(not terrainEditor_frameStepRegistered)
				{
					terrainEditor_frameStepRegistered = true;

					if(game.scriptFunctionExists('void frameStep(float dt)')<0)
					{
						game.addScriptFunction(
							"void frameStep(float dt)"
							"{"
							"	if(terrainEditModeEnabled)"
							"	{"
							"		timeSinceLastUpdate += dt;"
							
									// < 4 FPS
							"		if(timeSinceLastUpdate > 0.25f)"
							"		{"
							"			timeSinceLastUpdate = 0.0f;"
							
										// destroy brush
							"			game.destroyObject('terrainEditorBrush');"
							
										// Get new brush position
							"			vector3 dir(game.getCameraDirection());"
							"			dir.normalise();"
							"			vector3 position = (game.getPersonPosition()+(dir*vector3(1,0,1)*currentBrushRadius)+currentBrushOffset);"

										// spawn the object
							"			game.spawnObject(currentBrushObject, 'terrainEditorBrush', position, currentBrushRotation, '', false);"
										
										// Notify the server (at only 2FPS!)
							"			if(terrainEditor_sendFrameToServer)"
							"			{"
							"				array<string> args = {"
							"					'BRUSH',"
							"					terrainEditor_serializeVector3(position),"
							"					terrainEditor_serializeVector3(currentBrushRotation)"
							"				};"
							"				terrainEditor_sendGameCmd(args);"
							"			}"
							"			terrainEditor_sendFrameToServer = not terrainEditor_sendFrameToServer;"
							"		}"
							"	}"
							"}"
						);
					}
					else
					{
						// Notify user
						game.message("Script exception in file 'terrainEditor.as': Framestep already exists (conflicting server plugins?)", "cross.png", 30000.0f, true);
										
						// Notify the server
						array<string> args = {
							"ERROR",
							"FRAMESTEP",
							"Error while enabling edit mode: The frameStep method already exists. (conflicting server plugins?)"
						};
						terrainEditor_sendGameCmd(args);

						// stop here
						return;
					}
				}

				// Spawn the brush object
				game.spawnObject(currentBrushObject, 'terrainEditorBrush', vector3(0,0,0), vector3(0,0,0), '', false);

				// Terrain edit mode enabled :)
				terrainEditModeEnabled = true;
			}
		""");
		clientSideScript_common.addScriptFunction("""
			void exitEditMode()
			{
				terrainEditModeEnabled = false;
				game.destroyObject("terrainEditorBrush");
			}
		""");
	}

	int getClientVersion(int uid)
	{
		// Get the position from the clients list
		const int pos = getClientIndexByUid(uid); if(pos<0) return -1;
	
		return clients[pos].version;
	}

	void chatCommand_setHeight(chatMessage@ cmd)
	{
		// do not broadcast
		cmd.broadcast.block();

		// Get the position from the clients list
		const int pos = getClientIndexByUid(cmd.uid); if(pos<0) return;

		// Only set if the client is in edit mode
		if(not clients[pos].enabled)
		{
			cmd.privateGameCommand.message("You're currently not in edit mode. Say !editmode to enter edit mode.", "brick.png", 30000.0f, true);
			return;
		}

		// parse the argument
		string arg;
		float height;
		bool ok = false;
		if(cmd.emsgLen>=2 && cmd.emsg[1].length()>0)
		{
			arg = trim(cmd.emsg[1]);
			if(isNumber(arg))
			{
				height = parseFloat(arg);
				ok = true;
			}
		}
		
		// Show help if something went wrong
		if(!ok)
		{
			cmd.privateGameCommand.message("!setheight will set the height offset of your brush.", "information.png", 30000.0f, true);
			cmd.privateGameCommand.message("usage:   !setheight <height>", "information.png", 30000.0f, true);
			cmd.privateGameCommand.message("example: !setheight 3", "information.png", 30000.0f, true);
			return;
		}

		// set the variables
		clients[pos].brushOffset.y = height;

		// Send the command to the client
		cmd.privateGameCommand.addCmd("setBrushOffset("+vector3ToString(clients[pos].brushOffset)+");");
	}

	void chatCommand_setTilt(chatMessage@ cmd)
	{
		// do not broadcast
		cmd.broadcast.block();

		// Get the position from the clients list
		const int pos = getClientIndexByUid(cmd.uid); if(pos<0) return;

		// Only set if the client is in edit mode
		if(not clients[pos].enabled)
		{
			cmd.privateGameCommand.message("You're currently not in edit mode. Say !editmode to enter edit mode.", "brick.png", 30000.0f, true);
			return;
		}

		// parse the argument
		string arg;
		float angle;
		bool ok = false;
		if(cmd.emsgLen>=2 && cmd.emsg[1].length()>0)
		{
			arg = trim(cmd.emsg[1]);
			if(isNumber(arg))
			{
				angle = parseFloat(arg);
				ok = true;
			}
		}
		
		// Show help if something went wrong
		if(!ok)
		{
			cmd.privateGameCommand.message("!settilt will set the rotation of your brush around a horizontal axis.", "information.png", 30000.0f, true);
			cmd.privateGameCommand.message("usage:   !settilt <angle (in degrees)>", "information.png", 30000.0f, true);
			cmd.privateGameCommand.message("example: !settilt 180", "information.png", 30000.0f, true);
			return;
		}

		// set the variables
		clients[pos].brushRotation.z = angle;

		// Send the command to the client
		cmd.privateGameCommand.addCmd("setRotation("+vector3ToString(clients[pos].brushRotation)+");");
	}

	void chatCommand_setBank(chatMessage@ cmd)
	{
		// do not broadcast
		cmd.broadcast.block();

		// Get the position from the clients list
		const int pos = getClientIndexByUid(cmd.uid); if(pos<0) return;

		// Only set if the client is in edit mode
		if(not clients[pos].enabled)
		{
			cmd.privateGameCommand.message("You're currently not in edit mode. Say !editmode to enter edit mode.", "brick.png", 30000.0f, true);
			return;
		}

		// parse the argument
		string arg;
		float angle;
		bool ok = false;
		if(cmd.emsgLen>=2 && cmd.emsg[1].length()>0)
		{
			arg = trim(cmd.emsg[1]);
			if(isNumber(arg))
			{
				angle = parseFloat(arg);
				ok = true;
			}
		}
		
		// Show help if something went wrong
		if(!ok)
		{
			cmd.privateGameCommand.message("!setbank will set the rotation of your brush around a horizontal axis.", "information.png", 30000.0f, true);
			cmd.privateGameCommand.message("usage:   !setbank <angle (in degrees)>", "information.png", 30000.0f, true);
			cmd.privateGameCommand.message("example: !setbank 180", "information.png", 30000.0f, true);
			return;
		}

		// set the variables
		clients[pos].brushRotation.x = angle;

		// Send the command to the client
		cmd.privateGameCommand.addCmd("setRotation("+vector3ToString(clients[pos].brushRotation)+");");
	}

	void chatCommand_setRotation(chatMessage@ cmd)
	{
		// do not broadcast
		cmd.broadcast.block();

		// Get the position from the clients list
		const int pos = getClientIndexByUid(cmd.uid); if(pos<0) return;

		// Only set if the client is in edit mode
		if(not clients[pos].enabled)
		{
			cmd.privateGameCommand.message("You're currently not in edit mode. Say !editmode to enter edit mode.", "brick.png", 30000.0f, true);
			return;
		}

		// parse the argument
		string arg;
		float angle;
		bool ok = false;
		if(cmd.emsgLen>=2 && cmd.emsg[1].length()>0)
		{
			arg = trim(cmd.emsg[1]);
			if(isNumber(arg))
			{
				angle = parseFloat(arg);
				ok = true;
			}
		}
		
		// Show help if something went wrong
		if(!ok)
		{
			cmd.privateGameCommand.message("!setrotation will set the rotation of your brush around the vertical axis.", "information.png", 30000.0f, true);
			cmd.privateGameCommand.message("usage:   !setrotation <angle (in degrees)>", "information.png", 30000.0f, true);
			cmd.privateGameCommand.message("example: !setrotation 180", "information.png", 30000.0f, true);
			return;
		}

		// set the variables
		clients[pos].brushRotation.y = angle;

		// Send the command to the client
		cmd.privateGameCommand.addCmd("setRotation("+vector3ToString(clients[pos].brushRotation)+");");
	}

	void chatCommand_setRadius(chatMessage@ cmd)
	{
		// do not broadcast
		cmd.broadcast.block();

		// Get the position from the clients list
		const int pos = getClientIndexByUid(cmd.uid); if(pos<0) return;

		// Only set if the client is in edit mode
		if(not clients[pos].enabled)
		{
			cmd.privateGameCommand.message("You're currently not in edit mode. Say !editmode to enter edit mode.", "brick.png", 30000.0f, true);
			return;
		}

		// parse the argument
		string arg;
		float rad = -1.0f;
		bool ok = false;
		if(cmd.emsgLen>=2 && cmd.emsg[1].length()>0)
		{
			arg = trim(cmd.emsg[1]);
			if(isNumber(arg))
			{
				rad = parseFloat(arg);
				ok = true;
			}
		}
		
		// Show help if something went wrong
		if(!ok)
		{
			cmd.privateGameCommand.message("!setradius will set the distance between you and your brush object.", "information.png", 30000.0f, true);
			cmd.privateGameCommand.message("usage:   !setradius <radius>", "information.png", 30000.0f, true);
			cmd.privateGameCommand.message("example: !setradius 15", "information.png", 30000.0f, true);
			return;
		}

		// set the variables
		clients[pos].brushRadius = rad;

		// Send the command to the client
		cmd.privateGameCommand.addCmd("setRadius("+floatToString(rad)+");");
	}

	void chatCommand_setRelativeHeight(chatMessage@ cmd)
	{
		// do not broadcast
		cmd.broadcast.block();

		// Get the position from the clients list
		const int pos = getClientIndexByUid(cmd.uid); if(pos<0) return;

		// Only set if the client is in edit mode
		if(not clients[pos].enabled)
		{
			cmd.privateGameCommand.message("You're currently not in edit mode. Say !editmode to enter edit mode.", "brick.png", 30000.0f, true);
			return;
		}

		// parse the argument
		string arg;
		float height;
		bool ok = false;
		if(cmd.emsgLen>=2 && cmd.emsg[1].length()>0)
		{
			arg = trim(cmd.emsg[1]);
			if(isNumber(arg))
			{
				height = parseFloat(arg);
				ok = true;
			}
		}
		
		// Show help if something went wrong
		if(!ok)
		{
			cmd.privateGameCommand.message("!setrheight will change height offset of your brush.", "information.png", 30000.0f, true);
			cmd.privateGameCommand.message("usage:   !setrheight <delta height>", "information.png", 30000.0f, true);
			cmd.privateGameCommand.message("example: !setrheight 3", "information.png", 30000.0f, true);
			return;
		}

		// set the variables
		clients[pos].brushOffset.y += height;

		// Send the command to the client
		cmd.privateGameCommand.addCmd("setBrushOffset("+vector3ToString(clients[pos].brushOffset)+");");
	}

	void chatCommand_setRelativeTilt(chatMessage@ cmd)
	{
		// do not broadcast
		cmd.broadcast.block();

		// Get the position from the clients list
		const int pos = getClientIndexByUid(cmd.uid); if(pos<0) return;

		// Only set if the client is in edit mode
		if(not clients[pos].enabled)
		{
			cmd.privateGameCommand.message("You're currently not in edit mode. Say !editmode to enter edit mode.", "brick.png", 30000.0f, true);
			return;
		}

		// parse the argument
		string arg;
		float angle;
		bool ok = false;
		if(cmd.emsgLen>=2 && cmd.emsg[1].length()>0)
		{
			arg = trim(cmd.emsg[1]);
			if(isNumber(arg))
			{
				angle = parseFloat(arg);
				ok = true;
			}
		}
		
		// Show help if something went wrong
		if(!ok)
		{
			cmd.privateGameCommand.message("!setrtilt will change the rotation of your brush around a horizontal axis.", "information.png", 30000.0f, true);
			cmd.privateGameCommand.message("usage:   !setrtilt <delta angle (in degrees)>", "information.png", 30000.0f, true);
			cmd.privateGameCommand.message("example: !setrtilt 180", "information.png", 30000.0f, true);
			return;
		}

		// set the variables
		clients[pos].brushRotation.z += angle;

		// Send the command to the client
		cmd.privateGameCommand.addCmd("setRotation("+vector3ToString(clients[pos].brushRotation)+");");
	}

	void chatCommand_setRelativeBank(chatMessage@ cmd)
	{
		// do not broadcast
		cmd.broadcast.block();

		// Get the position from the clients list
		const int pos = getClientIndexByUid(cmd.uid); if(pos<0) return;

		// Only set if the client is in edit mode
		if(not clients[pos].enabled)
		{
			cmd.privateGameCommand.message("You're currently not in edit mode. Say !editmode to enter edit mode.", "brick.png", 30000.0f, true);
			return;
		}

		// parse the argument
		string arg;
		float angle;
		bool ok = false;
		if(cmd.emsgLen>=2 && cmd.emsg[1].length()>0)
		{
			arg = trim(cmd.emsg[1]);
			if(isNumber(arg))
			{
				angle = parseFloat(arg);
				ok = true;
			}
		}
		
		// Show help if something went wrong
		if(!ok)
		{
			cmd.privateGameCommand.message("!setrbank will change the rotation of your brush around a horizontal axis.", "information.png", 30000.0f, true);
			cmd.privateGameCommand.message("usage:   !setrbank <delta angle (in degrees)>", "information.png", 30000.0f, true);
			cmd.privateGameCommand.message("example: !setrbank 180", "information.png", 30000.0f, true);
			return;
		}

		// set the variables
		clients[pos].brushRotation.x += angle;

		// Send the command to the client
		cmd.privateGameCommand.addCmd("setRotation("+vector3ToString(clients[pos].brushRotation)+");");
	}

	void chatCommand_setRelativeRotation(chatMessage@ cmd)
	{
		// do not broadcast
		cmd.broadcast.block();

		// Get the position from the clients list
		const int pos = getClientIndexByUid(cmd.uid); if(pos<0) return;

		// Only set if the client is in edit mode
		if(not clients[pos].enabled)
		{
			cmd.privateGameCommand.message("You're currently not in edit mode. Say !editmode to enter edit mode.", "brick.png", 30000.0f, true);
			return;
		}

		// parse the argument
		string arg;
		float angle;
		bool ok = false;
		if(cmd.emsgLen>=2 && cmd.emsg[1].length()>0)
		{
			arg = trim(cmd.emsg[1]);
			if(isNumber(arg))
			{
				angle = parseFloat(arg);
				ok = true;
			}
		}
		
		// Show help if something went wrong
		if(!ok)
		{
			cmd.privateGameCommand.message("!setrrotation will change the rotation of your brush around the vertical axis.", "information.png", 30000.0f, true);
			cmd.privateGameCommand.message("usage:   !setrrotation <delta angle (in degrees)>", "information.png", 30000.0f, true);
			cmd.privateGameCommand.message("example: !setrrotation 180", "information.png", 30000.0f, true);
			return;
		}

		// set the variables
		clients[pos].brushRotation.y += angle;

		// Send the command to the client
		cmd.privateGameCommand.addCmd("setRotation("+vector3ToString(clients[pos].brushRotation)+");");
	}

	void chatCommand_setRelativeRadius(chatMessage@ cmd)
	{
		// do not broadcast
		cmd.broadcast.block();

		// Get the position from the clients list
		const int pos = getClientIndexByUid(cmd.uid); if(pos<0) return;

		// Only set if the client is in edit mode
		if(not clients[pos].enabled)
		{
			cmd.privateGameCommand.message("You're currently not in edit mode. Say !editmode to enter edit mode.", "brick.png", 30000.0f, true);
			return;
		}

		// parse the argument
		string arg;
		float rad = -1.0f;
		bool ok = false;
		if(cmd.emsgLen>=2 && cmd.emsg[1].length()>0)
		{
			arg = trim(cmd.emsg[1]);
			if(isNumber(arg))
			{
				rad = parseFloat(arg);
				ok = true;
			}
		}
		
		// Show help if something went wrong
		if(!ok)
		{
			cmd.privateGameCommand.message("!setrradius will change the distance between you and your brush object.", "information.png", 30000.0f, true);
			cmd.privateGameCommand.message("usage:   !setrradius <delta radius>", "information.png", 30000.0f, true);
			cmd.privateGameCommand.message("example: !setrradius 15", "information.png", 30000.0f, true);
			return;
		}

		// set the variables
		clients[pos].brushRadius += rad;

		// Send the command to the client
		cmd.privateGameCommand.addCmd("setRadius("+floatToString(rad)+");");
	}

	void chatCommand_setBrush(chatMessage@ cmd)
	{
		// do not broadcast
		cmd.broadcast.block();

		// Get the position from the clients list
		const int pos = getClientIndexByUid(cmd.uid); if(pos<0) return;

		// Only set if the client is in edit mode
		if(not clients[pos].enabled)
		{
			cmd.privateGameCommand.message("You're currently not in edit mode. Say !editmode to enter edit mode.", "brick.png", 30000.0f, true);
			return;
		}

		// parse the argument
		string arg;
		if(cmd.emsgLen>=2 && cmd.emsg[1].length()>0)
		{
			arg = trim(cmd.emsg[1]);
		}
		else
		{
			cmd.privateGameCommand.message("!setbrush will set your building brush object type.", "information.png", 30000.0f, true);
			cmd.privateGameCommand.message("usage:   !setbrush <object_name>", "information.png", 30000.0f, true);
			cmd.privateGameCommand.message("example: !setbrush road", "information.png", 30000.0f, true);
			return;
		}

		// search the object in the list
		/*int objectNum = objects.find(arg);
		if(objectNum<0)
		{
			cmd.privateGameCommand.message("Object '"+arg+"' is not supported.", "information.png", 30000.0f, true);
			return;
		}*/

		// Ok, set the variables
		//clients[pos].brushObject = objectNum;
		clients[pos].brushObject = arg;

		// Send the command to the client
		cmd.privateGameCommand.addCmd("setBrush('"+arg+"');");
		cmd.privateGameCommand.message("Current brush: '"+arg+"'.", "brick.png", 30000.0f, true);
	}

	void chatCommand_build(chatMessage@ cmd)
	{
		// do not broadcast
		cmd.broadcast.block();

		// Get the position from the clients list
		const int pos = getClientIndexByUid(cmd.uid); if(pos<0) return;

		// Only build if the client is in edit mode
		if(not clients[pos].enabled)
		{
			cmd.privateGameCommand.message("You're currently not in edit mode. Say !editmode to enter edit mode.", "brick.png", 30000.0f, true);
			return;
		}

		// Send the command to build the object
		cmd.privateGameCommand.addCmd("buildBrush();");
	}

	void chatCommand_clear(chatMessage@ cmd)
	{
		// do not broadcast
		cmd.broadcast.block();

		// Get the position from the clients list
		const int pos = getClientIndexByUid(cmd.uid); if(pos<0) return;

		// Make all the clients delete the objects of this client
		cmd.generalGameCommand.addCmd("clearObjects("+cmd.uid+", "+clients[pos].objectCount+");");

		// Reset local variables
		clients[pos].objectCount = 0;
		
	}

	void chatCommand_editmode(chatMessage@ cmd)
	{
		// do not broadcast
		cmd.broadcast.block();

		// Get the position from the clients list
		const int pos = getClientIndexByUid(cmd.uid); if(pos<0) return;

		// Initialize the client, if not yet done.
		if(not clients[pos].initialized)
		{
			// Send client side scripts (order is important!)
			if(clients[pos].version==38) clientSideScript_v38.sendTo(clients[pos].uid);
			else clientSideScript_v39.sendTo(clients[pos].uid);
			clientSideScript_common.sendTo(clients[pos].uid);
			cmd.privateGameCommand.addCmd("terrainEditorMyUid = "+cmd.uid+";");

			// Spawn all custom objects
			for(uint i=0; i<clients.length(); ++i)
			{
				if(i!=uint(pos))
				{
					for(uint k=0; k<clients[i].cmd_add.length(); ++k)
					{
						cmd.privateGameCommand.addCmd(clients[i].cmd_add[k]);
					}
				}
			}

			clients[pos].initialized = true;
		}

		// Switch the edit mode
		clients[pos].enabled = not clients[pos].enabled;
		
		if(clients[pos].enabled)
		{
			// show the brush
			server.cmd(cmd.uid, 'enterEditMode();');

			// show a message
			cmd.privateGameCommand.message("Now in terrain edit mode. Say !editmode again to hide the brush again.", "brick.png", 30000.0f, true);
		}
		else
		{
			// hide the brush
			cmd.privateGameCommand.addCmd('exitEditMode();');
			cmd.generalGameCommand.destroyObject("brush_"+cmd.uid);

			// show a message
			cmd.privateGameCommand.message("Say !editmode again to continue editing the terrain.", "brick.png", 30000.0f, true);
		}
	}

	void chatCommand_brushInfo(chatMessage@ cmd)
	{
		// do not broadcast
		cmd.broadcast.block();

		// Get the position from the clients list
		const int pos = getClientIndexByUid(cmd.uid); if(pos<0) return;

		// Let the client do the work
		cmd.privateGameCommand.addCmd("showBrushInfo();");
	}

	void chatCommand_undo(chatMessage@ cmd)
	{
		// do not broadcast
		cmd.broadcast.block();

		// Get the position from the clients list
		const int pos = getClientIndexByUid(cmd.uid); if(pos<0) return;

		// Let the client do the work
		cmd.privateGameCommand.addCmd("undo();");
	}

	void playerAdded(int uid)
	{
		// Create and add the client to the list
		terrainEditor_client cl;
		cl.uid           = uid;
		cl.version       = (server.getUserVersion(uid).findFirst("0.38")>=0) ? 38 : 39;
		cl.objectCount   = 0;
		cl.enabled       = false;
		cl.initialized   = false;
		cl.brushObject   = "road";
		cl.brushRotation = vector3(0.0f, 0.0f, 0.0f);
		cl.brushOffset   = vector3(0.0f, 0.2f, 0.0f);
		cl.brushRadius   = 0;
		clients.insertLast(@cl);

		clientSideScript_common.sendTo(cl.uid);

		gameScript script(uid, "terrainEditorMyUid = "+uid+";");
		// Spawn all custom objects
		for(uint i=0; i<clients.length()-1; ++i)
		{
			for(uint k=0; k<clients[i].cmd_add.length(); ++k)
			{
				script.addCmd(clients[i].cmd_add[k]);
			}
		}
		script.flush();

		cl.initialized = true;
	}

	void playerDeleted(int uid, int crash)
	{
		// Get the position from the clients list
		const int pos = getClientIndexByUid(uid); if(pos<0) return;

		// Delete all the objects that the user had on the terrain
		gameScript cmd(TO_ALL, "clearObjects("+uid+", "+clients[pos].objectCount+");");
		cmd.flush();

		// Remove the client from our list.
		clients.removeAt(pos);

		// TODO: Keep history

	}

	void gameCmd(gameScriptManager_argument@ arg)
	{
		// Get the position from the clients list
		const int pos = getClientIndexByUid(arg.uid); if(pos<0) return;

		// Split the message
		array<string>@ emsg = arg.msg.split('$');

		if(emsg.length()<1)
			return;
		else if(emsg[0]=="BRUSH")
		{
			if(emsg.length()!=3)
				return;

			// Broadcast the brush
			gameScript script();
			script.destroyObject("brush_"+arg.uid);
			script.spawnObject(clients[pos].brushObject, "brush_"+arg.uid, "vector3("+emsg[1]+")", "vector3("+emsg[2]+")", "", false);
			for(uint i=0; i<clients.length(); ++i)
			{
				if(i!=uint(pos))
					script.sendTo(clients[i].uid);
			}
			script.clearBuffer();
		}
		else if(emsg[0]=="SPAWN")
		{
			if(emsg.length()!=5)
				return;

			// Broadcast the object
			gameScript script(TO_ALL);
			script.spawnObject(emsg[1], emsg[2], "vector3("+emsg[3]+")", "vector3("+emsg[4]+")", "defaultEventCallback", false);
			for(uint i=0; i<clients.length(); ++i)
			{
				if(i!=uint(pos))
					script.sendTo(clients[i].uid);
			}
			clients[pos].cmd_add.insertLast(script.getGameCmd(0));
			clients[pos].objectCount++;
		}
		else if(emsg[0]=="UNDO")
		{
			if(emsg.length()!=2)
				return;

			// Broadcast the destroyal
			gameScript script(TO_ALL);
			script.destroyObject(emsg[1]);
			for(uint i=0; i<clients.length(); ++i)
			{
				if(i!=uint(pos))
					script.sendTo(clients[i].uid);
			}

			// subtract 1 object from the client
			clients[pos].objectCount--;

			// Delete the object from the list
			clients[pos].cmd_add.removeLast();
		}
		else if(emsg[0]=="ERROR")
		{
			if(emsg.length()!=3)
				return;

			// Tried to enter edit mode while inside a vehicle
			if(emsg[1]=="TRUCK")
				clients[pos].enabled = false;
			
			// The frameStep method already exists on the client.
			else if(emsg[1]=="FRAMESTEP")
				clients[pos].enabled = false;

			server.Log("ERROR| "+emsg[2]);
		}
		else
		{
			server.Log("WARN| Unhandled game command message!");
		}
	}

	int getClientIndexByUid(int uid) const
	{
		for(uint i=0; i<clients.length(); ++i)
		{
			if(clients[i].uid==uid)
				return i;
		}
		return -1;
	}

	
}
