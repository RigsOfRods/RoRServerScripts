
// list type
enum streamValidation_listType
{
	WHITELIST,
	BLACKLIST
}

class streamValidation
{
	array<int> informants;     // List of UIDs of admins, mods and bots
	array<string>@ filterList; // List of stream names
	int type;                  // Type of list
	bool registered;           // Internal flag

	streamValidation(array<string>@ list, streamValidation_listType type_ = BLACKLIST)
	{
		informants.resize(0); // TODO: scan playerlist
		@filterList = @list;
		registered = true;
		type       = type_;
		if(type!=BLACKLIST and type!=WHITELIST)
			server.throwException("Type should be eiter BLACKLIST or WHITELIST.");
	
		server.setCallback("streamAdded",   "streamAdded",   @this);
		server.setCallback("playerAdded",   "playerAdded",   @this);
		server.setCallback("playerDeleted", "playerDeleted", @this);
	}
	
	~streamValidation()
	{
		destroy();
	}
	
	void destroy()
	{
		if(registered)
		{
			server.deleteCallback("streamAdded",   "streamAdded",   @this);
			server.deleteCallback("playerAdded",   "playerAdded",   @this);
			server.deleteCallback("playerDeleted", "playerDeleted", @this);
			registered = false;
		}
	}
	
	void playerAdded(int uid)
	{
		if((server.getUserAuthRaw(uid) & (AUTH_BOT | AUTH_ADMIN | AUTH_MOD))>0)
			informants.insertLast(uid);
	}
	
	void playerDeleted(int uid, int)
	{
		int index = informants.find(uid);
		if(index>=0) informants.removeAt(index);
	}

	int streamAdded(int uid, StreamRegister@ reg)
	{
#if FALSE
		server.Log("New stream detected:");
		server.Log("	  UID " + uid);
		server.Log("	 NAME " + reg.getName());
		server.Log("	 TYPE " + reg.type);
		server.Log("   STATUS " + reg.status);
		server.Log("	  UID " + reg.origin_sourceid);
		server.Log("	  SID " + reg.origin_streamid);
#endif
		
		// Ignore chat and character streams
		string name = reg.getName();
		if(name=="chat" || name=="default")
			return BROADCAST_NORMAL;

		// Loop over the list and compare the vehicle name
		bool found = false;
		for(uint i=0; i<filterList.length; ++i)
		{
			if(name == filterList[i])
			{
				found = true;
				break;
			}
		}
		
		// Take action if required
		if( (found and type==BLACKLIST) or (not found and type==WHITELIST) )
		{
			// Let the user know
			server.say("#FF0000", uid, FROM_SERVER);
 			server.say("#FF0000============WARNING============", uid, FROM_SERVER); 
			server.say("#FF0000 This vehicle is not allowed on this server! Your vehicle is not visible to other players!", uid, FROM_SERVER); 
			server.say("#FF0000 All moderators and/or admins on the server have been messaged and you are now subject to being kicked!", uid, FROM_SERVER); 
			server.say("#FF0000===============================", uid, FROM_SERVER); 
			server.say("#FF0000", uid, FROM_SERVER); 
			
			// Let the informants know
			string msg = "User **'"+server.getUserName(uid)+"'** with uid **("+uid+")** has spawned a **'"+name+"'**, which is a banned vehicle.";
			for(uint i=0; i<informants.length; ++i)
			{
				server.say(msg, informants[i], FROM_SERVER);
			}
			
			return BROADCAST_BLOCK;
		}
		else
			return BROADCAST_NORMAL;
	}
}