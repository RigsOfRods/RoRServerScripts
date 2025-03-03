// Include the localStorage file
#include "localStorage.as"

class UserStatistics
{
	localStorage@ s;

	UserStatistics()
	{
		@s = @localStorage("userJoinStatistics."+server.get_listenPort()+".asdata");
	}
}
 
// Create our dictionary as global variable
UserStatistics userStats();
 
// This function will get called when a player joins the game
void playerAdded(int uid)
{
    // Create a new variable holding the username
    string name = server.getUserName(uid);
     
    // Get the amount of times that we've seen this player before
    int timesSeen;
    if( not userStats.s.get(name, timesSeen) )
    {
        timesSeen = 0;
    }
     
    // As the player just joined, we have to increase our timesSeen counter by 1
    timesSeen += 1;
	if(timesSeen==100) server.cmd(TO_ALL, "//game.message('User "+name+" has been on this server 100 times! Congratulations!', 'user_comment.png', 30000.0f, true);");
     
    // And we store the updated value of our counter
    userStats.s.set(name, timesSeen);
     
    // Save the statistics
    userStats.s.save();
     
    // And instead of showing a global message, we'll now show a private message to this user.
    // The message will be different, depending on whether this is the first time that this user joined the server.
    if(timesSeen==1)
        server.say("Welcome " + name + ", thank you for deciding to check out our server!", uid, FROM_HOST);
    else
        server.say("Welcome back " + name + ", this is the " + integerToOrdinalNumber(timesSeen) + " time that you joined our server :D", uid, FROM_HOST);
}
 
// The playerChat event that will happen at every chat message
int playerChat(int uid, string msg)
{
    // Split the message on spaces
    array<string>@ arguments = msg.split(" ");
     
    // We need at least 1 argument in our message
    if(arguments.length()>=1)
    {
        // We only need to do something if the first word in the message is the command (first word = argument 0)
        if( arguments[0] == "!seen" )
        {
            // For this command, we'll need at least 2 arguments in the message (the command itself, and a uid)
            if(arguments.length()<2)
            {
                server.say("!seen shows join statistics of a certain user.", uid, FROM_SERVER);
                server.say("Usage:   !seen <uid>", uid, FROM_SERVER);
                server.say("Example: !seen 152", uid, FROM_SERVER);
            }
            else
            {
                // The second word should be the unique identifier of the user of whom we want to get the statistics of
                int buid = parseInt(arguments[1]);
                 
                // Get the username that matches the unique identifier
                string name = server.getUserName(buid);
                 
                // The getUserName function returns something empty when the requested uid is not online
                if(name=="")
                {
                    server.say("!seen shows join statistics of a certain user.", uid, FROM_SERVER);
                    server.say("Usage:   !seen <uid>", uid, FROM_SERVER);
                    server.say("Example: !seen 152", uid, FROM_SERVER);
                }
                else
                {
                    // Get the amount of times that we've seen the player before
                    int timesSeen;
                    if( not userStats.s.get(name, timesSeen) )
                    {
                        timesSeen = 0;
                    }
                     
                    // And show it as output to the user that requested it
                    server.say("User " + name + " (" + buid + ") has been seen " + timesSeen + " times on this server.", uid, FROM_SERVER);
                }
            }
        }
    }
     
    // You can change broadcasting levels using this function, but here, we'll change nothing by returning BROADCAST_AUTO
    return BROADCAST_AUTO;
}
 
string integerToOrdinalNumber(int num)
{
        int modTen = num%10;
        int modHun = num%100;
       
        if(modHun-modTen==10)   // 11th, 12th, 13th, 14th, ...
                return ""+num+"th";
        else if(modTen==1)      // 1st, 21st, 31st, 41st, ...
                return ""+num+"st";
        else if(modTen==2)      // 2nd, 22nd, 32nd, 42nd, ...
                return ""+num+"nd";
        else if(modTen==3)      // 3rd, 23rd, 33rd, 43rd, ...
                return ""+num+"rd";
        else                    // 4th, 5th, 6th, 7th, ...
                return ""+num+"th";
}