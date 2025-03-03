#include "utils"

#if DEBUG
#include "Logger.as"
Logger gameScriptDebugLog("Log_gameScript_"+server.getTime()+".asdata");
#endif

void quickGameMessage(int uid, const string &in msg, const string &in icon)
{
	gameScript game(uid);
	game.message(msg, icon, 30000.0f, true);
	game.flush();
}

class gameScript
{
	int uid;
	string[] cmd;
	uint cmdIndex;
	
	gameScript()
	{
		uid = TO_ALL;
		clearBuffer();
	}
	
	gameScript(const int &in _uid)
	{
		uid = _uid;
		clearBuffer();
	}
	
	gameScript(const int &in _uid, const string &in _cmd)
	{
		uid = _uid;
		clearBuffer();
		addCmd(_cmd);
	}

	gameScript(const string &in _cmd)
	{
		uid = TO_ALL;
		clearBuffer();
		addCmd(_cmd);
	}
	
	gameScript(const gameScript &in other)
	{
		uid       = other.uid;
		cmd       = other.cmd;
		cmdIndex  = other.cmdIndex;
	}

	void setDestination(const int &in _uid)
	{
		uid = _uid;
	}

	int getDestination() const
	{
		return uid;
	}

	string getGameCmd(uint part)
	{
		if(part<=cmdIndex)
			return cmd[part];
		return "";
	}
	
	~gameScript()
	{}
	
	void sendTo(const int &in _uid) const
	{
		for(uint i=0; i<=cmdIndex; ++i)
		{
			if(cmd[i].length()>0)
			{
				server.cmd(_uid, cmd[i]);
#if DEBUG
				// Log this
				gameScriptDebugLog.Log("S>"+((_uid==-1) ? " ALL" : formatInt(_uid, "", 4))+"| "+cmd[i]);
#endif
			}
		}
	}
	
	void flush()
	{
		sendTo(uid);
		clearBuffer();
	}

	void clearBuffer()
	{
		cmdIndex = 0;
		cmd.resize(1);
		cmd[cmdIndex] = "";
	}
	
	void addCmd(const string &in cmd_in)
	{
		if(cmd_in.length()>4000)
		{
			server.Log("Script exception in gameScript::addCmd(...): Trying to add a cmd of length "+cmd_in.length()+" while maximum allowed is 4000.");
			return;
		}
		
		if(cmd[cmdIndex].length()+cmd_in.length()>4000)
		{
			splitCommandHere();
		}

		cmd[cmdIndex] += "{\n" + cmd_in + "\n}";
	}

	void addCmdFront(const string &in cmd_in)
	{
		if(cmd_in.length()>4000)
		{
			server.Log("Script exception in gameScript::addCmd(...): Trying to add a cmd of length "+cmd_in.length()+" while maximum allowed is 4000.");
			return;
		}
		
		if(cmd[0].length()+cmd_in.length()>4000)
		{
			++cmdIndex;
			cmd.insertAt(0, "");
		}

		cmd[cmdIndex] += "{\n" + cmd_in + "\n}";
	}

	void splitCommandHere()
	{
		cmd.resize(++cmdIndex+1);
		cmd[cmdIndex] = "";
	}
	
	gameScript@ opAssign(const gameScript &in other)
	{
		uid       = other.uid;
		cmd       = other.cmd;
		cmdIndex  = other.cmdIndex;
		return this;
	}
	
	gameScript@ opAddAssign(const gameScript &in other)
	{
		for(uint i=0; i<=other.cmdIndex; ++i)
		{
			addCmd(other.cmd[i]);
		}
		return this;
	}
	
	// Game script wrapper
	void Log(string &in text)
	{
		text = stringReplace(text, "'", "\\'");
		addCmd("Log('"+text+"');");
	}

	void setPersonPosition(const vector3 &in vec)
	{
		addCmd("game.setPersonPosition("+vector3ToString(vec)+");");
	}
	
	void loadTerrain(string &in terrain)
	{
		terrain = stringReplace(terrain, "'", "\\'");
		addCmd("game.loadTerrain('"+terrain+"');");
	}

	void movePerson(const vector3 &in vec)
	{
		addCmd("game.movePerson("+floatToString(vec.x)+", "+floatToString(vec.y)+", "+floatToString(vec.z)+");");
	}

	void movePerson(float x, float y, float z)
	{
		addCmd("game.movePerson("+floatToString(x)+", "+floatToString(y)+", "+floatToString(z)+");");
	}
	
	void setCaelumTime(const float &in value)
	{
		addCmd("game.setCaelumTime("+floatToString(value)+");");
	}

	void setWaterHeight(const float &in value)
	{
		addCmd("game.setWaterHeight("+floatToString(value)+");");
	}
	
	void setGravity(const float &in value)
	{
		addCmd("game.setGravity("+floatToString(value)+");");
	}
	
	void registerForEvent(const int &in eventValue)
	{
		addCmd("game.registerForEvent("+eventValue+");");
	}
	
	void flashMessage(string &in text, const float &in time, const float &in charHeight)
	{
		// Log message
		server.Log("MSG|S>"+((uid==-1) ? " ALL" : formatInt(uid, " ", 4))+"| "+text);

		text = stringReplace(text, "'", "\\'");
		addCmd("game.flashMessage('"+text+"', "+floatToString(time)+", "+floatToString(charHeight)+");");
	}

	void setDirectionArrow(string &in text, const vector3 &in position)
	{
		text = stringReplace(text, "'", "\\'");
		addCmd("game.setDirectionArrow('"+text+"', vector3("+floatToString(position.x)+", "+floatToString(position.y)+", "+floatToString(position.z)+"));");
	}

	void setChatFontSize(const int &in size)
	{
		addCmd("game.setChatFontSize("+size+");");
	}
	
	void setCameraPosition(const vector3 &in position)
	{
		addCmd("game.setCameraPosition(vector3("+floatToString(position.x)+", "+floatToString(position.y)+", "+floatToString(position.z)+"));");
	}
	
	void setCameraDirection(const vector3 &in direction)
	{
		addCmd("game.setCameraDirection(vector3("+floatToString(direction.x)+", "+floatToString(direction.y)+", "+floatToString(direction.z)+"));");
	}
	
	void setCameraRoll(const float &in angle)
	{
		addCmd("game.setCameraRoll("+floatToString(angle)+");");
	}
	
	void setCameraYaw(const float &in angle)
	{
		addCmd("game.setCameraYaw("+floatToString(angle)+");");
	}
	
	void setCameraPitch(const float &in angle)
	{
		addCmd("game.setCameraPitch("+floatToString(angle)+");");
	}
	
	void cameraLookAt(const vector3 &in targetPoint)
	{
		addCmd("game.cameraLookAt(vector3("+floatToString(targetPoint.x)+", "+floatToString(targetPoint.y)+", "+floatToString(targetPoint.z)+"));");
	}

	void showChooser(string &in type, string &in instance, string &in box)
	{
		type     = stringReplace(type, "'", "\\'");
		instance = stringReplace(instance, "'", "\\'");
		box      = stringReplace(box, "'", "\\'");
		addCmd("game.showChooser('"+type+"', '"+instance+"', '"+box+"');");
	}

	void repairVehicle(string &in instance, string &in box, const bool &in keepPosition)
	{
		instance = stringReplace(instance, "'", "\\'");
		box      = stringReplace(box, "'", "\\'");
		addCmd("game.repairVehicle('"+instance+"', '"+box+"', "+boolToString(keepPosition)+");");
	}

	void removeVehicle(string &in instance, string &in box)
	{
		instance = stringReplace(instance, "'", "\\'");
		box      = stringReplace(box, "'", "\\'");
		addCmd("game.removeVehicle('"+instance+"', '"+box+"');");
	}

	void spawnObject(string &in objectName, string &in instanceName, const vector3 &in pos, const vector3 &in rot, string &in eventhandler, const bool &in uniquifyMaterials)
	{
		objectName   = stringReplace(objectName, "'", "\\'");
		instanceName = stringReplace(instanceName, "'", "\\'");
		eventhandler = stringReplace(eventhandler, "'", "\\'");
		addCmd("game.spawnObject('"+objectName+"', '"+instanceName+"', "+vector3ToString(pos)+", "+vector3ToString(rot)+", '"+eventhandler+"', "+boolToString(uniquifyMaterials)+");");
	}

	void spawnObject(string &in objectName, string &in instanceName, const string &in vec3pos, const string &in vec3rot, string &in eventhandler, const bool &in uniquifyMaterials)
	{
		objectName   = stringReplace(objectName, "'", "\\'");
		instanceName = stringReplace(instanceName, "'", "\\'");
		eventhandler = stringReplace(eventhandler, "'", "\\'");
		addCmd("game.spawnObject('"+objectName+"', '"+instanceName+"', "+vec3pos+", "+vec3rot+", '"+eventhandler+"', "+boolToString(uniquifyMaterials)+");");
	}

	void destroyObject(string &in instanceName)
	{
		instanceName = stringReplace(instanceName, "'", "\\'");
		addCmd("game.destroyObject('"+instanceName+"');");
	}

	void stopTimer()
	{
		addCmd("game.stopTimer();");
	}

	void startTimer()
	{
		addCmd("game.startTimer();");
	}

	void hideDirectionArrow()
	{
		addCmd("game.hideDirectionArrow();");
	}
	
	// TODO: add these methods
	void setMaterialAmbient(const string materialName, float red, float green, float blue) { server.throwException("method not supported."); }
	void setMaterialDiffuse(const string materialName, float red, float green, float blue, float alpha) { server.throwException("method not supported."); }
	void setMaterialSpecular(const string materialName, float red, float green, float blue, float alpha) { server.throwException("method not supported."); }
	void setMaterialEmissive(const string materialName, float red, float green, float blue) { server.throwException("method not supported."); }
	void useOnlineAPI (const string apiquery, const dictionary dict, string result) { server.throwException("method not supported."); }

	void clearEventCache()
	{
		addCmd("game.clearEventCache();");
	}
	
	void message(string &in text, string &in icon, const float &in msTime = 30000.0f, const bool &in forceVisible = true)
	{
		// Log message
		server.Log("MSG|S>"+((uid==-1) ? " ALL" : formatInt(uid, " ", 4))+"| "+text);

		text = stringReplace(text, "'", "\\'");
		icon = stringReplace(icon, "'", "\\'");
		addCmd("game.message('"+text+"', '"+icon+"', "+floatToString(msTime)+", "+boolToString(forceVisible)+");");
	}
	
	void boostCurrentTruck(const float &in factor)
	{
		addCmd("game.boostCurrentTruck("+floatToString(factor)+");");
	}
	
	void addScriptFunction(string &in func)
	{
		func = stringReplace(func, '"""', '\\"\\"\\"');
		addCmd('game.addScriptFunction("""'+func+'""");');
	}
	
	void safeAddScriptFunction(string &in func)
	{
		func = stringReplace(func, '"""', '\\"\\"\\"');
		int declEnd = func.findFirst(')'); // TODO: this won't always work ( void func(string foo = "error (5)") { /*...*/ }")
		addCmd('if(game.scriptFunctionExists("""'+func.substr(0, declEnd+1)+'""")<0) game.addScriptFunction("""'+func+'""");');
	}
	
	void deleteScriptFunction(string &in func)
	{
		func = stringReplace(func, '"""', '\\"\\"\\"');
		addCmd('game.deleteScriptFunction("""'+func+'""");');
	}
	
	void addScriptVariable(string &in var)
	{
		var = stringReplace(var, '"""', '\\"\\"\\"');
		addCmd('game.addScriptVariable("""'+var+'""");');
	}
	
	void deleteScriptVariable(string &in var)
	{
		var = stringReplace(var, '"""', '\\"\\"\\"');
		addCmd('game.deleteScriptVariable("""'+var+'""");');
	}
	
	void sendGameCmd(string &in cmd)
	{
		cmd = stringReplace(cmd, '"""', '\\"\\"\\"');
		addCmd('game.sendGameCmd("""'+cmd+'""");');
	}

	// TODO: add these methods
	void setMaterialTextureName(const string &in, int, int, int, const string &in) { server.throwException("method not supported."); }
	void setMaterialTextureRotate(const string &in, int, int, int, float) { server.throwException("method not supported."); }
	void setMaterialTextureScroll(const string &in, int, int, int, float, float) { server.throwException("method not supported."); }
	void setMaterialTextureScale(const string &in, int, int, int, float, float) { server.throwException("method not supported."); }
	
	void userSay(string &in msg, const int &in uid)
	{
		msg = stringReplace(msg, "'", "\\'");
		addCmd("game.message(\""+playerColours[server.getUserColourNum(uid)] + server.getUserName(uid) + COLOUR_NORMAL + ": " + msg + "\", \"user_comment.png\", 30000.0f, true);");
	}
}

class gameScriptManager_section
{
	uint slotnum;
	string name;
	gameScript cmd;
	bool enabled;
	uint objCount;

	GAMESCRIPTMANAGER_CONDITION@ conditionCheck;
	any@ argument;
}

class gameScriptManager_callback
{
	GAMESCRIPTMANAGER_CALLBACK@ callback;
	any@ argument;
}

class gameScriptManager_argument
{
	any@ argument;
	int uid;
	string msg;
}

funcdef void GAMESCRIPTMANAGER_CALLBACK(gameScriptManager_argument@);
funcdef bool GAMESCRIPTMANAGER_CONDITION(int, any@);
bool gameScriptManager_positiveCondition(int, any@) { return true; }

class gameScriptManager
{
	array<gameScriptManager_section> sections;
	uint sectionCount;
	bool destroyed;
	array<gameScriptManager_callback@> gameCmdCallbackList;
	string frameStepContents;

	uint8 gameCmdHeader_0;
	uint8 gameCmdHeader_1;
	uint8 gameCmdHeader_2;
	uint8 gameCmdHeader_5;
	int eventCallbackNum;
	bool initialized;

	gameScriptManager()
	{
		sections.resize(0);
		sectionCount = 0;
		destroyed = false;
		frameStepContents = "";
		gameCmdHeader_0 = ord('#');
		gameCmdHeader_1 = ord('G');
		gameCmdHeader_2 = ord('S');
		gameCmdHeader_5 = ord('#');
		initialized = false;
		
		server.setCallback("playerAdded", "playerAdded", @this);
		server.setCallback("gameCmd",     "gameCmd",     @this);

	}
	
	void destroy()
	{
		if(destroyed) return;
		server.deleteCallback("playerAdded", "playerAdded", @this);
		destroyed = true;
	}
	
	// This may look stupid, but it's need to avoid null access if this is declared as global variable
	void initialize()
	{
		initialized = true;
	}

	string addGameCmdCallback(GAMESCRIPTMANAGER_CALLBACK@ callback, any@ argument)
	{
		gameScriptManager_callback cb;
		@cb.callback = @callback;
		@cb.argument = @argument;

		int assigned = -1;
		for(uint i=0; i<gameCmdCallbackList.length(); ++i)
		{
			if(gameCmdCallbackList[i] is null)
			{
				@gameCmdCallbackList[i] = @cb;
				assigned = int(i);
				break;
			}
		}
		if(assigned<0)
		{
			assigned = gameCmdCallbackList.length();
			if(assigned>99)
			{
				server.throwException("This script doesn't support more than 100 gameCmd callbacks!");
				return "#ERRR#";
			}
			gameCmdCallbackList.insertLast(@cb);
		}
		
		return "#GS"+formatInt(assigned, "0", 2)+"#";
	}

	void removeGameCmdCallback(GAMESCRIPTMANAGER_CALLBACK@ callback)
	{
		for(uint i=0; i<gameCmdCallbackList.length(); ++i)
		{
			if(gameCmdCallbackList[i] !is null && gameCmdCallbackList[i].callback is callback)
			{
				@gameCmdCallbackList[i] = null;
			}
		}
	}

	void gameCmd(int uid, const string &in msg)
	{
#if DEBUG
		server.Log("GAMECMD| "+msg);
#endif
		if(msg.length()>6 && msg[0]==gameCmdHeader_0 && msg[1]==gameCmdHeader_1 && msg[2]==gameCmdHeader_2 && msg[5]==gameCmdHeader_5)
		{
			int callbackNum = parseInt(msg.substr(3,2));
			
			// Special cases
			if(callbackNum==eventCallbackNum)
			{
				eventCallback(uid, msg.substr(6));
			}
			else if(callbackNum<0)
			{
				server.Log("Unhandled special gameCmd number "+callbackNum+" from "+uid+": "+msg);
			}
			else
			{
				// Do a callback
				gameScriptManager_callback@ cb = gameCmdCallbackList[callbackNum];
				gameScriptManager_argument ga;
				@ga.argument = @cb.argument;
				ga.uid = uid;
				ga.msg = msg.substr(6);
				cb.callback(@ga);
			}
		}
	}
	
	void eventCallback(int uid, const string &in msg)
	{
		// msg: currTime$eventnum$value$argument
		array<string>@ parts = msg.split('$');
		if(parts.length()!=4) return;
		
		float time      = parseFloat(parts[0]);
		int eventNum    = parseInt(parts[1]);
		int value       = parseInt(parts[2]);
		string argument = parts[3];
		
		// TODO: do callbacks
	}

	void addFrameStepCode(const string &in code)
	{
		// This doesn't work because you can't call a function from here, as it won't be defined yet
		// It could work by adding playerAdded callbacks from here as well (before frameStep), or by somehow enforcing that the playerAdded of the frameStep is the last playerAdded method
		// TODO: how to enforce it to be last? Add a priority to the server?
		frameStepContents += "{\n"+stringReplace(code, '"""', '\\"\\"\\"')+"\n}";
	}
	
	void add(const string &in section, gameScript@ cmd)
	{
		uint secID = getSectionByName(section);
		sections[secID].cmd += cmd;
	}
	
	void addObjectList(const string &in section_add, const string &in section_del, const string &in list, bool debug = true)
	{
		uint secID_add = getSectionByName(section_add);
		uint secID_del = getSectionByName(section_del);

		const uint8 semicolon = ord(';');
		const uint8 slash = ord('/');

		array<string>@ list2 = list.split("\r\n");
		for(uint k=0; k<list2.length(); ++k)
		{
			array<string>@ lines = list2[k].split("\n");
			for(uint i=0; i<lines.length(); ++i)
			{

				if(lines[i].length()==0)
				{
					if(debug) server.Log("Skipping line "+(k+i+1)+": empty line.");
					continue;
				}

				if(lines[i][0]==semicolon || lines[i][0]==slash)
				{
					if(debug) server.Log("Skipping line "+(k+i+1)+": comment.");
					continue;
				}
			
				array<string>@ parts = splitExcludeEmpty(lines[i], ", ");

				if(parts.length()<7)
				{
					if(debug) server.Log("Skipping line "+(k+i+1)+": syntax error: not enough commas.");
					continue;
				}

				array<string>@ args = splitExcludeEmpty(parts[6], " ");

				if(args.length()<1)
				{
					if(debug) server.Log("Skipping line "+(k+i+1)+": syntax error: no object specified.");
					continue;
				}
			
				if(args[0]=="truck" || parts[0]=="truck2" || parts[0]=="load")
				{
					if(debug) server.Log("Skipping line "+(k+i+1)+": Cannot spawn trucks or loads in multiplayer.");
					continue;
				}

				string iname = "gameScriptManager|addObjectList|"+secID_add+"|"+sections[secID_add].objCount++;
				if(args.length()>=3)
					iname = args[2];
			
				sections[secID_add].cmd.spawnObject(trim(parts[6]), iname, "vector3("+normalizeFloatFormat(parts[0])+", "+normalizeFloatFormat(parts[1])+", "+normalizeFloatFormat(parts[2])+")", "vector3("+normalizeFloatFormat(parts[3])+", "+normalizeFloatFormat(parts[4])+", "+normalizeFloatFormat(parts[5])+")", "", false);
				sections[secID_del].cmd.destroyObject(iname);
			}
		}
		
	}
	
	void playerAdded(int uid)
	{
		initialized = true;
	
		// TODO: This should all be sent after terrain loading
		for(uint i=0; i<sectionCount; ++i)
		{
			if(sections[i].enabled && sections[i].conditionCheck(uid, @sections[i].argument))
				sections[i].cmd.sendTo(uid);
		}

		//server.cmd(uid, 'game.addScriptFunction("""void frameStep(float dt) { '+frameStepContents+' }""");');
	}
	
	void enableSection(const string &in section, const bool &in broadcast = true)
	{
		uint secID = getSectionByName(section);
		sections[secID].enabled = true;
		
		if(broadcast && initialized)
			sections[secID].cmd.sendTo(TO_ALL);
	}
	
	void disableSection(const string &in section)
	{
		uint secID = getSectionByName(section);
		sections[secID].enabled = false;
	}
	
	void broadcastSection(const string &in section)
	{
		uint secID = getSectionByName(section);
		sections[secID].cmd.sendTo(TO_ALL);
	}
	
	void sendTo(const string &in section, const int &in uid)
	{
		uint secID = getSectionByName(section);
		sections[secID].cmd.sendTo(uid);
	}
	
	bool sectionExists(const string &in name)
	{
		// Try to find the section
		for(uint i=0; i<sectionCount; ++i)
		{
			if(sections[i].name==name)
				return true;
		}
		return false;
	}
	
	void removeSection(const string &in name)
	{
		// Try to find the section
		for(uint i=0; i<sectionCount; ++i)
		{
			if(sections[i].name==name)
			{
				sections.removeAt(i);
				--sectionCount;
				break;
			}
		}
	}

	void addSectionCondition(const string &in section, GAMESCRIPTMANAGER_CONDITION@ func, any@ arg)
	{
		uint secID = getSectionByName(section);
		@sections[secID].conditionCheck = @func;
		@sections[secID].argument = @arg;

	}
	
	uint getSectionByName(const string &in name)
	{
		// Try to find the section
		for(uint i=0; i<sectionCount; ++i)
		{
			if(sections[i].name==name)
				return i;
		}
		
		// Or create it if it doesn't exist
		server.Log("INFO| gameScriptManager: Creating new section: '"+name+"'.");
		const int index = sectionCount;
		sections.resize(++sectionCount);
		sections[index].slotnum  = index;
		sections[index].name     = name;
		sections[index].enabled  = true;
		sections[index].objCount = 0;
		@sections[index].conditionCheck = @gameScriptManager_positiveCondition;
		any a(null);
		@sections[index].argument = @a;
		return index;
	}
}

string normalizeFloatFormat(string fl)
{
	const int count = fl.length();
	const uint8 zero_ord = ord("0");
	const uint8 point_ord = ord(".");
	const uint8 f_ord = ord("f");
	
	int point_pos = -1;
	int f_pos = -1;
	
	if( count <= 0 )
		return ""; // error
		
	for( int i = count-1 ; i >= 0 ; i-- )
	{
		if(fl[i]==point_ord)
		{
			point_pos = i;
			if(f_pos>=0)
				break;
		}
		else if(fl[i]==f_ord)
			f_pos = i;
	}
	
	if(point_pos<0)
		return fl+".0f";
	else if(f_pos<0 && point_pos<int(fl.length())-1)
		return fl+"f";
	else if(f_pos<0)
		return fl+".0f";

	return ""; // error
}

class terrainFileLoader
{
	gameScriptManager@ gsm;
	string name;
	vector3 cameraSpawn;
	vector3 avatarSpawn;
	vector3 truckSpawn;
	string filename;

	bool initialized;
	
	terrainFileLoader(gameScriptManager@ _gsm, const string &in _filename = "")
	{
		@gsm = @_gsm;
		name = "";
		filename = _filename;
		initialized = false;

		if(filename!="")
			load();
	}
	
	~terrainFileLoader()
	{
		destroy();
	}
	
	void destroy()
	{
		gsm.removeSection("LOAD_TERRAIN "+filename);
		gsm.removeSection("UNLOAD_TERRAIN "+filename);
		initialized = false;
	}

	void setFile(const string &in _filename)
	{
		filename = _filename;
	}

	void preload()
	{
		file f;
		string fileContents = "";
		cameraSpawn = vector3(0,0,0);
		avatarSpawn = vector3(0,0,0);
		truckSpawn = vector3(0,0,0);
		gameScript script();
		name = "";
		initialized = false;
		
		// Open the file in 'read' mode
		if( f.open(filename, "r") >= 0 ) 
		{
			// Temporary variables
			string tmp;
			int len = 0;
		
			// Read the first line of the terrain
			len += f.readLine(tmp);

			// Our syntax
			if(tmp.substr(0, 18)=="TERRN_FILE_VERSION")
			{
				if(parseInt(tmp.substr(19))!=1)
				{
					server.Log("ERROR| terrainFileLoader: The terrain file '"+filename+"' is made in a unsupported syntax version. (Supported version=1, fileversion="+tmp.substr(19)+".");
					f.close();
					return;
				}

				const uint8 semicolon = ord(';');
				const uint8 slash = ord('/');
				string section = "MAIN";
				uint lineNum = 1;
				while(!f.isEndOfFile())
				{
					// read a line
					len += f.readLine(tmp);

					// Increase the line count
					++lineNum;

					// Trim the line
					tmp = trim(tmp);

					// Parse the line
					if(tmp.length()==0)
					{
						continue;
					}
					if(tmp[0]==semicolon)
					{
						continue;
					}
					if(tmp[0]==slash)
					{
						// Why 2 comment styles?
						//server.Log("WARNING| terrainFileLoader: Found '/' comment in '"+filename+"'  at line "+lineNum+". It's recommended to use ';' comments instead.");
						continue;
					}
					if(tmp.substr(0,11) == "END_SECTION")
					{
						if(section!=trim(tmp.substr(12)))
							server.Log("WARNING| terrainFileLoader: Ending section '"+trim(tmp.substr(12))+"', which was never opened. File: '"+filename+"' ("+lineNum+"). Current section: '"+section+"'.");
						
						// end the main section = stop parsing
						if(section=="MAIN")
						{
							section = "MAIN";
							break;
						}

						// Otherwise, just continue
						section = "MAIN";
						continue;
					}
					if(section=="COMMENT")
					{
						continue;
					}
					if(section=="MAIN")
					{
						if(tmp.substr(0,11) == "NEW_SECTION")
						{
							section = trim(tmp.substr(12));
						}
						else
						{
							server.Log("WARNING| terrainFileLoader: Syntax error in file '"+filename+"' ("+lineNum+"): Unknown keyword for section '"+section+"'.");
						}
						continue;
					}
					if(section=="OBJECTS")
					{
						fileContents += tmp+"\n";
						continue;
					}
					if(section=="PROPERTIES")
					{
						if(tmp.substr(0, 11)=="TERRAINNAME")
						{
							name = trim(tmp.substr(12));
						}
						else if(tmp.substr(0, 10)=="CONFIGFILE") {}
						else if(tmp.substr(0, 10)=="USE_CALEUM") {}
						else if(tmp.substr(0, 11)=="WATERHEIGTH") {}
						else if(tmp.substr(0, 9)=="SKYCOLOUR") {}
						else
						{
							server.Log("WARNING| terrainFileLoader: Syntax error in file '"+filename+"' ("+lineNum+"): Unknown keyword for section '"+section+"'.");
						}
						continue;
					}
					if(section=="SPAWNPOINTS")
					{
						// Get the coordinates of the spawnpoint
						array<string>@ res = tmp.substr(tmp.findFirst(" ")).split(",");
						if(res.length()!=3)
						{
							server.Log("WARNING| terrainFileLoader: Syntax error in file '"+filename+"' ("+lineNum+").");
						}
						else if(tmp.substr(0,5)=="TRUCK")
						{
							truckSpawn = vector3(parseFloat(res[0]), parseFloat(res[1]), parseFloat(res[2]));
						}
						else if(tmp.substr(0,6)=="CAMERA")
						{
							cameraSpawn = vector3(parseFloat(res[0]), parseFloat(res[1]), parseFloat(res[2]));
							script.setCameraPosition(cameraSpawn);
						}
						else if(tmp.substr(0,6)=="PERSON")
						{
							avatarSpawn = vector3(parseFloat(res[0]), parseFloat(res[1]), parseFloat(res[2]));
							script.setPersonPosition(avatarSpawn);
						}
						else
						{
							server.Log("WARNING| terrainFileLoader: Syntax error in file '"+filename+"' ("+lineNum+"): Unknown keyword for section '"+section+"'.");
						}
						continue;
					}
					if(section=="AUTHOR")
					{
						// Section contains no relevant information for us
						continue;
					}

					server.Log("WARNING| terrainFileLoader: Syntax error in file '"+filename+"' ("+lineNum+"): Unknown keyword or keyword in wrong section ('"+section+"').");
				}

				// Normally, we should be in the main section now. Otherwise, an END_SECTION was missing.
				if(section!="MAIN")
					server.Log("WARNING| terrainFileLoader: Syntax error in file '"+filename+"' ("+lineNum+"): Missing 'END_SECTION "+section+"'.");

				// For our purposes, we need it to have an objects section
				if(fileContents=="")
				{
					server.Log("ERROR| terrainFileLoader: Missing 'OBJECTS' section.");
					f.close();
					return;
				}
			}

			// Default terrn syntax
			else {
				name = tmp;

				// Read the config of the terrain
				len += f.readLine(tmp);
			
				// parse Colour, water and caelum
				len += f.readLine(tmp);
				if(tmp.length()==0)
				{
					server.Log("ERROR| terrainFileLoader: Syntax error in file '"+filename+"'.");
					f.close();
					return;
				}
				if(tmp[0]==ord('w'))
				{
					len += f.readLine(tmp);
				}
				if(tmp.length()<6)
				{
					server.Log("ERROR| terrainFileLoader: Syntax error in file '"+filename+"'.");
					f.close();
					return;
				}
				if(tmp.substr(0,6)=='caelum')
				{
					len += f.readLine(tmp);
				}
			
				// spawn positions
				len += f.readLine(tmp);
				array<string>@ res = tmp.split(",");
				if(res.length()<6)
				{
					server.Log("ERROR| terrainFileLoader: Syntax error in file '"+filename+"'.");
					f.close();
					return;
				}
				truckSpawn = vector3(parseFloat(res[0]), parseFloat(res[1]), parseFloat(res[2]));
				cameraSpawn = vector3(parseFloat(res[3]), parseFloat(res[4]), parseFloat(res[5]));
				script.setCameraPosition(cameraSpawn);
				if(res.length()>=9)
				{
					avatarSpawn = vector3(parseFloat(res[6]), parseFloat(res[7]), parseFloat(res[8]));
					script.setPersonPosition(avatarSpawn);
				}
				else
					avatarSpawn = vector3(0,0,0);
			
				// Read the rest of the file into the string buffer
				f.readString(f.getSize()-len, fileContents);
			}
			
			// Close the file
			f.close();
		}
		else
		{
			server.Log("ERROR| terrainFileLoader: File '"+filename+"' does not exist.");
			return;
		}		
		
		// Parse the object list
		gsm.addObjectList("LOAD_TERRAIN "+filename, "UNLOAD_TERRAIN "+filename, fileContents);

		// Add the other script stuff to the terrain loading script
		gsm.add("LOAD_TERRAIN "+filename, script);

		// Disable everything, as we're only pre-loading it
		gsm.disableSection("LOAD_TERRAIN "+filename);
		gsm.disableSection("UNLOAD_TERRAIN "+filename);

		// Loading successful
		initialized = true;
	}
	
	bool load(bool broadcast = true)
	{
		// Parse the file
		if(!gsm.sectionExists("LOAD_TERRAIN "+filename))
			preload();
		
		// Enable the terrain broadcasting
		if(initialized)
		{
			gsm.enableSection("LOAD_TERRAIN "+filename, true);
			return true;
		}
		
		return false;
	}
	
	void unload()
	{
		if(!initialized) return;

		// Disable the terrain broadcasting
		gsm.disableSection("LOAD_TERRAIN "+filename);
		
		// Send the unload command to everyone
		gsm.sendTo("UNLOAD_TERRAIN "+filename, TO_ALL);
	}
	
	bool reload()
	{
		unload();
		return load();
	}
}
