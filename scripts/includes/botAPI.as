

void gameCmd(int uid, string message)
{
	if((server.getUserAuthRaw(uid) & AUTH_BOT)>0)
	{
		if(message.substr(0,6)=="BOTAPI")
		{
			array<string>@ parts = message.substr(7).split('$');
			if(parts.length()<2)
				return;

			if(parts[0] == "IP")
			{
				// server.cmd(uid, 'botapi.IP('+parts[1]+', "'+server.getUserIPAddress(parseInt(parts[1]))+'");');
			}
			else if(parts[0] == "SAY_COMMENT")
			{
				// Add parts together again
				for(uint i=2; i<parts.length(); ++i)
					parts[1] += "$" + parts[i];
					
				string msg = stringReplace(parts[1], '"', '\\"');
				server.cmd(TO_ALL, "game.message(\"" + msg + "\", \"user_comment.png\", 30000.0f, true);");
				server.Log("CHAT| " + msg);
				server.cmd(uid, 'botapi.SAY_COMMENT("ok");');

			}
			else if(parts[0] == "MSG_UID")
			{
				// Add parts together again
				for(uint i=3; i<parts.length(); ++i)
					parts[2] += "$" + parts[i];
					
				gameScript script(TO_ALL);
				script.userSay(parts[2], parseInt(parts[1]));
				script.flush();
				server.cmd(uid, 'botapi.MSG_UID("ok");');
			}
			else if(parts[0] == "VERSION")
			{
				server.cmd(uid, 'botapi.VERSION(1);');
			}
		}
	}
}