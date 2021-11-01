
// You can use these colours in the chat!
// E.g.: server.say(COLOUR_RED+"this is red text"+COLOUR_BLUE+" and this is blue text", TO_ALL, FROM_SERVER);
const string COLOUR_BLACK    = "#000000";
const string COLOUR_RED      = "#FF0000";
const string COLOUR_YELLOW   = "#FFFF00";
const string COLOUR_WHITE    = "#FFFFFF";
const string COLOUR_CYAN     = "#00FFFF";
const string COLOUR_BLUE     = "#0000FF";
const string COLOUR_GREEN    = "#00FF00";
const string COLOUR_MAGENTA  = "#FF00FF";
const string COLOUR_COMMAND  = "#941e8d";
const string COLOUR_NORMAL   = "#FFFFFF";
const string COLOUR_WHISPER  = "#967417";
const string COLOUR_SCRIPT   = "#32436f";

// This translates the colournumber of a player to the colour code.
// E.g.: server.say(playerColours[server.getUserColourNum(154)]+server.getUserName(154)+COLOUR_BLACK+": hi :)", 154, FROM_SERVER);
const string[] playerColours = {
	"#00CC00",
	"#0066B3",
	"#FF8000",
	"#FFCC00",
//	"#330099",
//	"#990099",
	"#CCFF00",
	"#FF0000",
	"#808080",
	"#008F00",
//	"#00487D",
	"#B35A00",
	"#B38F00",
//	"#6B006B",
	"#8FB300",
	"#B30000",
	"#BEBEBE",
	"#80FF80",
	"#80C9FF",
	"#FFC080",
	"#FFE680",
	"#AA80FF",
	"#EE00CC",
	"#FF8080",
	"#666600",
	"#FFBFFF",
	"#00FFCC",
	"#CC6699",
	"#999900"
};

// Useful for the game.registerForEvent function
enum clientScriptEvents {
	SE_COLLISION_BOX_ENTER             = 0x00000001, //!< triggered when truck or person enters a previous registered collision box, the argument refers to the collision box ID
	SE_COLLISION_BOX_LEAVE             = 0x00000002, //!< triggered when truck or person leaves a previous registered and entered collision box, the argument refers to the collision box ID

	SE_TRUCK_ENTER                     = 0x00000004, //!< triggered when switching from person mode to truck mode, the argument refers to the truck number
	SE_TRUCK_EXIT                      = 0x00000008, //!< triggered when switching from truck mode to person mode, the argument refers to the truck number

	SE_TRUCK_ENGINE_DIED               = 0x00000010, //!< triggered when the trucks engine dies (from underrev, water, etc), the argument refers to the truck number
	SE_TRUCK_ENGINE_FIRE               = 0x00000020, //!< triggered when the planes engines start to get on fire, the argument refers to the truck number
	SE_TRUCK_TOUCHED_WATER             = 0x00000040, //!< triggered when any part of the truck touches water, the argument refers to the truck number
	SE_TRUCK_BEAM_BROKE                = 0x00000080, //!< triggered when a beam breaks, the argument refers to the truck number
	SE_TRUCK_LOCKED                    = 0x00000100, //!< triggered when the truck got lock to another truck, the argument refers to the truck number
	SE_TRUCK_UNLOCKED                  = 0x00000200, //!< triggered when the truck unlocks again, the argument refers to the truck number
	SE_TRUCK_LIGHT_TOGGLE              = 0x00000400, //!< triggered when the main light is toggled, the argument refers to the truck number
	SE_TRUCK_SKELETON_TOGGLE           = 0x00000800, //!< triggered when the user enters or exits skeleton mode, the argument refers to the truck number
	SE_TRUCK_TIE_TOGGLE                = 0x00001000, //!< triggered when the user toggles ties, the argument refers to the truck number
	SE_TRUCK_PARKINGBREAK_TOGGLE       = 0x00002000, //!< triggered when the user toggles the parking break, the argument refers to the truck number
	SE_TRUCK_BEACONS_TOGGLE            = 0x00004000, //!< triggered when the user toggles beacons, the argument refers to the truck number
	SE_TRUCK_CPARTICLES_TOGGLE         = 0x00008000, //!< triggered when the user toggles custom particles, the argument refers to the truck number
	SE_TRUCK_GROUND_CONTACT_CHANGED    = 0x00010000, //!< triggered when the trucks ground contact changed (no contact, different ground models, etc), the argument refers to the truck number

	SE_GENERIC_NEW_TRUCK               = 0x00020000, //!< triggered when the user spawns a new truck, the argument refers to the truck number
	SE_GENERIC_DELETED_TRUCK           = 0x00040000, //!< triggered when the user deletes a truck, the argument refers to the truck number

	SE_GENERIC_INPUT_EVENT             = 0x00080000, //!< triggered when an input event bound to the scripting engine is toggled, the argument refers to event id
	SE_GENERIC_MOUSE_BEAM_INTERACTION  = 0x00100000, //!< triggered when the user uses the mouse to interact with the truck, the argument refers to the truck number

	SE_TRUCK_TRACTIONCONTROL_TOGGLE    = 0x00200000, //!< triggered when the user toggles the tractioncontrol system, the argument refers to the truck number
	SE_TRUCK_ANTILOCKBRAKE_TOGGLE      = 0x00400000, //!< triggered when the user toggles the antilockbrake, the argument refers to the truck number

	SE_ANGELSCRIPT_MANIPULATIONS       = 0x00800000, //!< triggered when the user tries to dynamically use the scripting capabilities (prevent cheating)
	
	SE_TRUCK_RESET                     = 0x01000000, //!< triggered when a truck gets reset

	SE_ALL_EVENTS                      = 0x0fffffff,
};

// Useful for the gameScript::getNumTrucksByFlag method
enum truckState {
	ACTIVATED,      //!< leading truck
	DESACTIVATED,   //!< not leading but active 
	MAYSLEEP,       //!< active but wanting to sleep
	GOSLEEP,        //!< active but ordered to sleep ASAP (synchronously)
	SLEEPING,       //!< not active, sleeping
	NETWORKED,      //!< not calculated, gets remote data
	RECYCLE,        //!< waiting for reusage
	DELETED,        //!< special used when truck pointer is 0
};


// Some constants
const array<uint8> charactersLowerCase =
{ 
	0,        ord("a"), ord("b"), ord("c"), ord("d"), ord("e"), ord("f"),
	ord("g"), ord("h"), ord("i"), ord("j"), ord("k"), ord("l"), ord("m"),
	ord("n"), ord("o"), ord("p"), ord("q"), ord("r"), ord("s"), ord("t"),
	ord("u"), ord("v"), ord("w"), ord("x"), ord("y"), ord("z")
};
const array<uint8> charactersUpperCase =
{
	0,        ord("A"), ord("B"), ord("C"), ord("D"), ord("E"), ord("F"),
	ord("G"), ord("H"), ord("I"), ord("J"), ord("K"), ord("L"), ord("M"),
	ord("N"), ord("O"), ord("P"), ord("Q"), ord("R"), ord("S"), ord("T"),
	ord("U"), ord("V"), ord("W"), ord("X"), ord("Y"), ord("Z")
};

// Converts seconds to string
string formatTime(const float &in _seconds, const string &in type = "long")
{
	if(type=="long")
	{
		if(_seconds>3600.0f)
		{
			const int hours   = int(_seconds/3600);
			const int minutes = int((_seconds%3600)/60);
			const float seconds = ((_seconds-hours*3600)%60.0f);
			return hours+" hours, "+minutes+" minutes and "+seconds+" seconds";
		}
		else if(_seconds>60.0f)
			return int(_seconds/60.0f)+" minutes and "+(_seconds%60.0f)+" seconds";
		else
			return _seconds+" seconds";
	}
	else
	{
		if(_seconds>3600.0f)
		{
			const int hours   = int(_seconds/3600);
			const int minutes = int((_seconds%3600)/60);
			const float seconds = ((_seconds-hours*3600)%60.0f);
			return hours+"h "+minutes+"m "+seconds+"s";
		}
		else if(_seconds>60.0f)
			return int(_seconds/60.0f)+"m "+(_seconds%60.0f)+"s";
		else
			return _seconds+"s";
	}
}

// returns the absolute value of an integer
int abs(const int &in number)
{
	if(number<0) return number*(-1);
	else return number;
}

// Returns the ASCII value of the first character of a string.
// This function complements chr()
uint8 ord(const string &in character)
{
	if(character.length()<=0) return 0;
	return character[0];
}

// Returns a one-character string containing the character specified by ascii. 
// This function complements ord().
string chr(const uint8 &in ascValue)
{
	string str = " ";
	str[0] = ascValue;
	return str;
}

// Returns the portion of string specified by the start and length parameters.
// Returns an empty string on failure.
string substr(string &in str_in, int &in start, int &in length)
{
	int max = str_in.length()-1;
	if(start<0)
		start = max+start+1;
	if(length<0)
		length = max-start+length+1;
		
	return str_in.substr(start, length);
}

// Returns the portion of string specified by the start parameter and the end of the string.
// Returns an empty string on failure.
string substr(string &in str_in, int &in start)
{
	return substr(str_in, start, str_in.length());
}

array<string>@ splitExcludeEmpty(const string &in str_in, const string &in delimiter)
{
	array<string> res = str_in.split(delimiter);
	for(int i=res.length()-1; i>=0; --i)
	{
		if(res[i].length()==0) res.removeAt(i);
	}
	return res;
}

// Join pieces from an array, but leave out a few in the beginning
string joinFrom(array<string> &in pieces, const string &in glue, const uint &in from)
{
	pieces.reverse();
	pieces.resize(pieces.length()-from);
	pieces.reverse();
	return join(pieces, glue);
}

// Replace all occurrences of the search string with the replacement string
string stringReplace(string &in subject, const string &in needle, const string &in replace)
{
	const uint nlen = needle.length();
	const uint rlen = replace.length();

	int index = subject.findFirst(needle, 0);
	while(index>=0)
	{
		subject = subject.substr(0, index) + replace + subject.substr(index+nlen);
		index = subject.findFirst(needle, index+rlen);
	}
	return subject;
}

// Replace all occurrences of the search string array with the replacement string array
string stringReplace(string &in subject, const string[] &in needles, const string[] &in replaces)
{
	const uint ncount = needles.length();
	
	if( ncount != replaces.length() )
	{
		server.throwException("the size of the search and replace array should be the same!");
		return subject;
	}
			
	for( uint i = 0 ; i < ncount ; i++ )
	{
		subject = stringReplace(subject, needles[i], replaces[i]);
	}
	return subject;
}

// Replace all occurrences of the search string array with the replacement string
string stringReplace(string &in subject, const string[] &in needles, const string &in replace)
{
	const uint ncount = needles.length();
					
	for( uint i = 0 ; i < ncount ; i++ )
	{
		subject = stringReplace(subject, needles[i], replace);
	}
	return subject;
}

// Case-insensitive version of stringReplace()
string stringReplaceCaseInsensitive(string &in subject, const string &in needle, const string &in replace)
{
	return __stringReplaceCaseInsensitive(subject, needle, replace, stringToLowerCase(subject), stringToLowerCase(needle), needle.length(), replace.length());
}

string __stringReplaceCaseInsensitive(string &in subject, const string &in needle, const string &in replace, const string &in isubj, const string &in ineedle, const uint nlen, const uint rlen)
{
	int iindex = isubj.findFirst(ineedle, 0);
	int index = iindex;
	while(iindex>=0)
	{
		subject = subject.substr(0, index) + replace + subject.substr(index+nlen);
		int iindex2 = isubj.findFirst(ineedle, iindex+nlen);
		index += iindex2-iindex + rlen-nlen;
		iindex = iindex2;
	}
	return subject;
}

// Replace all occurrences of the search string array with the replacement string array
string stringReplaceCaseInsensitive(string &in subject, const string[] &in needles, const string[] &in replaces)
{
	const uint ncount = needles.length();
	
	if( ncount != replaces.length() )
	{
		server.throwException("the size of the search and replace array should be the same!");
		return subject;
	}
			
	for( uint i = 0 ; i < ncount ; i++ )
	{
		subject = stringReplaceCaseInsensitive(subject, needles[i], replaces[i]);
	}
	return subject;
}

// Replace all occurrences of the search string array with the replacement string
string stringReplaceCaseInsensitive(string &in subject, const string[] &in needles, const string &in replace)
{
	const uint ncount = needles.length();
					
	for( uint i = 0 ; i < ncount ; i++ )
	{
		subject = stringReplaceCaseInsensitive(subject, needles[i], replace);
	}
	return subject;
}

string stringToLowerCase(string str_in)
{
	int index;
	for(int i=str_in.length()-1; i>=0; --i)
	{
		index = charactersUpperCase.find(str_in[i]);
		if(index>0) // ignore index==0 (some strange AS bug in linux otherwise)
			str_in[i] = charactersLowerCase[index];
	}
	return str_in;
}

string stringToUpperCase(string &in str_in)
{	
	int index;
	for(int i=str_in.length()-1; i>=0; --i)
	{
		index = charactersLowerCase.find(str_in[i]);
		if(index>0) // ignore index==0 (some strange as bug in linux otherwise)
			str_in[i] = charactersUpperCase[index];
	}
	return str_in;
}

bool isUpperCase(const string &in str_in)
{
	int index;
	for(int i=str_in.length()-1; i>=0; --i)
	{
		index = charactersUpperCase.find(str_in[i]);
		if(index<0)
		{
			index = charactersLowerCase.find(str_in[i]);
			if(index>0)
				return false;
		}
	}
	return true;
}

string boolToString(const bool &in myBoolean)
{
	if(myBoolean) return "true";
	else          return "false";
}

string floatToString(const float &in myFloat)
{
	string f = ""+myFloat;

	// if no point is present, add it
	// also add the f at the end
	if(f.findFirst("e")>0)
		return f;
	else if(f.findFirst(".")>=0)
		return f+"f";
	else
		return f+".0f";
}

string vector3ToString(const vector3 &in vec)
{
	return "vector3("+floatToString(vec.x)+", "+floatToString(vec.y)+", "+floatToString(vec.z)+")";
}

// Note: this doesn't support exponential numbers
bool isNumber(const string &in number)
{
	const int count = number.length();
	const uint8 zero_ord = ord("0");
	const uint8 point_ord = ord(".");
	const uint8 f_ord = ord("f");
	const uint8 minus_ord = ord("-");
	
	if( count <= 0 )
		return false;
		
	for( int i = count-1 ; i >= 0 ; i-- )
	{
		if( ((number[i]-zero_ord)>9 || (number[i]-zero_ord)<0) && number[i]!=point_ord && number[i]!=minus_ord && (number[i]!=f_ord || i!=(count-1)))
			return false;
	}
	return true;
}

string trim(string &in str)
{
	int spaceCounter = 0;
	int strLength = str.length();
	for(int i=0; (strLength>i && str[i]<=32); ++i)
	{
		++spaceCounter;
	}
	str = substr(str, spaceCounter, strLength);

	strLength = strLength-spaceCounter;
	spaceCounter = 0;
	for(int i=strLength-1; (i>=0 && str[i]<=32); --i)
	{
		++spaceCounter;
	}
	str = substr(str, 0, strLength-spaceCounter);

	return str;
}

string padLeft(string &in str, const string &in char, const uint &in width)
{
	while(str.length()<width)
	{
		str = char+str;
	}
	return str;
}

string padRight(string &in str, const string &in char, const uint &in width)
{
	while(str.length()<width)
	{
		str += char;
	}
	return str;
}

float sum(const array<float> &in arr)
{
	float sum = 0.0f;
	for(uint i=0; i<arr.length(); ++i)
	{
		sum += arr[i];
	}
	return sum;
}

float average(const array<float> &in arr)
{
	if(arr.length()==0) return 0.0f;

	return sum(arr)/float(arr.length());
}

int64 sum(const array<int64> &in arr)
{
	int64 sum = 0;
	for(uint i=0; i<arr.length(); ++i)
	{
		sum += arr[i];
	}
	return sum;
}

int64 average(const array<int64> &in arr)
{
	if(arr.length()==0) return 0;

	return sum(arr)/int64(arr.length());
}
