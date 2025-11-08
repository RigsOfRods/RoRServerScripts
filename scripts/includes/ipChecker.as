class ipChecker
{
	dictionary playerQueue; // maps displayname -> uid
    private string contactEmail = "";

	ipChecker(const string &in contactEmail_ = "")
	{
        if (contactEmail_ != "")
		{
			// Set the contact email for the IP checker
			this.contactEmail = contactEmail_;
		}
        else
        {
            // If you enabled this, please set your email address in Main.as.
            server.throwException("ipChecker exception: No contact email provided. Please provide a valid email address.");
        }
		server.setCallback("playerAdded", "playerAdded", @this);
		server.setCallback("curlStatus",  "curlStatus",  @this);
	}

    ~ipChecker()
    {
        destroy();
    }
    
    void destroy()
    {
        server.deleteCallback("playerAdded", "playerAdded", @this);
        server.deleteCallback("curlStatus",  "curlStatus",  @this);
    }


	void playerAdded(int uid)
	{
		string ip = server.getUserIPAddress(uid);
        // string ip = "144.217.84.5"; // Test IP, known VPN/Proxy
		if(ip == "")
            // huh??!
			return;

        // Create a unique displayname for this request
		string displayname = "ipchecker_" + uid;
		playerQueue.set(displayname, uid);

		string url = "https://check.getipintel.net/check.php?ip=" + ip +
		             "&contact=" + contactEmail;

		server.Log("ipChecker: Checking IP for UID " + uid + ": " + ip);
		server.curlRequestAsync(url, displayname);
	}

	void curlStatus(curlStatusType type, int n1, int n2, string displayname, string message)
	{
		if(!playerQueue.exists(displayname))
			return; // not our request

		int uid;
        // we're doing the request, get the uid and remove from list
		playerQueue.get(displayname, uid);
		playerQueue.delete(displayname);

        if (type == CURL_STATUS_FAILURE)
        {
            server.Log("ipChecker: Request failed for UID: " + uid);
            server.Log("ipChecker:      Error message: " + message);
            server.Log("ipChecker:      cURL code: " + n1);
            server.Log("ipChecker:      HTTP code: " + n2);
            return;
        }

        if (type == CURL_STATUS_SUCCESS)
        {
            // message contains the response
            // A response of -1 means the IP is invalid, -2 means it's an internal error,
            // > .95 means it's a VPN or Proxy, < .95 means it's probably not.
            // See https://getipintel.net/#check for details.
            float score = parseFloat(message);

            server.Log("ipChecker: UID " + uid + " confidence score: " + formatFloat(score, "", 0, 2));

            if(score > 0.95f)
            {
                server.say("Player " + server.getUserName(uid) + " (" + uid + 
                        ") appears to be using a VPN/Proxy. Kicking...", uid, FROM_SERVER);
                server.kick(uid, "VPN/Proxy detected, confidence score (" + formatFloat(score, "", 0, 2) + ")");
            }
        }
	}
}
