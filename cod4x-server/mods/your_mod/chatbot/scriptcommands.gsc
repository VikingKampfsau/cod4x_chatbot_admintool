init()
{
	/* mod included commands */
	addScriptCommand("i_am_an_example", 1);
	
	/* chatbot = replacement for b3 or similar */
	thread chatbot\chatbot::init();
}

Callback_ScriptCommand(command, arguments)
{
	waittillframeend;

	//if self is defined it was called by a player (chat) -  else with rcon
	if(!isDefined(self) || !isPlayer(self))
		return;
	
	//custom commands (chatbot)
	if(chatbot\chatbot::cmdIsCustom(command, arguments))
		return;
	
	//mod included commands
	switch(command)
	{
		/* mod included commands */
		case "i_am_an_example":
			exec("tell " + self.name + " ^2example cmd executed");
			break;

		default:
			exec("tell " + self.name + " ^1Unknown command!");
			break;
	}
}