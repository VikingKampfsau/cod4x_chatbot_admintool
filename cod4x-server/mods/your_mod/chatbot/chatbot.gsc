//mysql_close(<handle>)
//will the connection close on map change automatically?

/*-----------------------|
|	chatbot init		 |
|-----------------------*/
init()
{
	level.chatbotMySQL = undefined;

	if(getDvar("chatbot_mysql_ip") == "") setDvar("chatbot", 0);
	if(getDvar("chatbot_mysql_user") == "") setDvar("chatbot", 0);
	if(getDvar("chatbot_mysql_password") == "") setDvar("chatbot", 0);
	if(getDvar("chatbot_mysql_database") == "") setDvar("chatbot", 0);

	if(!getDvarInt("chatbot"))
		return;

	//prepare the mysql connection
	if(getDvar("chatbot_mysql_port") == "")
		level.chatbotMySQL = mysql_real_connect(getDvar("chatbot_mysql_ip"), getDvar("chatbot_mysql_user"), getDvar("chatbot_mysql_password"), getDvar("chatbot_mysql_database"));
	else
		level.chatbotMySQL = mysql_real_connect(getDvar("chatbot_mysql_ip"), getDvar("chatbot_mysql_user"), getDvar("chatbot_mysql_password"), getDvar("chatbot_mysql_database"), getDvar("chatbot_mysql_port"));

	//consolePrint("Connected to MySQL DB " + getDvar("chatbot_mysql_database") + "\n");
	
	thread loadCustomFunctions();
	thread loadAdvertisementsAndRules();	
	thread onPlayerConnect();

	wait 60;
	
	exec("say This server is monitored by 'Chatbot' v1.0");
	exec("say github.com/VikingKampfsau/cod4x_chatbot_admintool");
}

loadCustomFunctions()
{
	level.customCommands = [];

	importAdditionalFunctionsFromFile("defaultCmdTable");
	importAdditionalFunctionsFromFile("customCmdTable");
}

importAdditionalFunctionsFromFile(filename)
{
	customCmds = [];
	customCmdFile = "chatbot/config/" + filename + ".csv";
		
	if(!fs_testFile(customCmdFile))
		return;
	
	file = openFile(customCmdFile, "read");
	
	if(file <= 0)
		return;

	section = "";
	while(1)
	{
		line = fReadLn(file);
			
		if(!isDefined(line))
			break;
		
		if(isEmptyString(line))
			continue;

		line = StrRepl(line, "\r", "");
		line = StrRepl(line, "\n", "");
		line = trim(line);
		
		if(line == "[commands]" || line == "[power]" || line == "[help]" || line == "[alias]")
		{
			section = line;
			continue;
		}

		line = strToK(line, "=");
		
		if(line.size > 1)
		{
			cmd = trim(line[0]);
			parm = "";
			
			for(i=1;i<line.size;i++)
				parm = parm + line[i];
				
			parm = trim(parm);
				
			if(section == "[commands]")
			{
				entryNo = customCmds.size;
				customCmds[entryNo] = spawnStruct();
				customCmds[entryNo].cmd = cmd;
				customCmds[entryNo].parm = parm;
			}
			else if(section == "[power]")
			{
				entryNo = findCustomCmd(customCmds, cmd);
				
				if(isDefined(entryNo))
					customCmds[entryNo].power = int(parm);
			}
			else if(section == "[help]")
			{
				entryNo = findCustomCmd(customCmds, cmd);
				
				if(isDefined(entryNo))
					customCmds[entryNo].help = parm;
			}
			else if(section == "[alias]")
			{
				entryNo = findCustomCmd(customCmds, cmd);
				
				if(isDefined(entryNo))
					customCmds[entryNo].alias = parm;
			}
		}
	}

	closeFile(file);
	
	if(customCmds.size <= 0)
		return;
	
	for(i=0;i<customCmds.size;i++)
	{
		if(isDefined(customCmds[i].cmd))
		{
			if(!isDefined(customCmds[i].power))
				customCmds[i].power = 0;
			
			if(customCmds[i].cmd == "tell")
				continue;
				
			removeScriptCommand(customCmds[i].cmd);
			addScriptCommand(customCmds[i].cmd, 1);

			level.customCommands[level.customCommands.size] = customCmds[i];
			//consolePrint("Registered cmd '" + customCmds[i].cmd + "'\n");
			
			if(isDefined(customCmds[i].alias))
			{
				addScriptCommand(customCmds[i].alias, 1);
				//consolePrint("Registered alias '" + customCmds[i].alias + "' for cmd '" + customCmds[i].cmd + "'\n");
			}
		}
	}
}

loadAdvertisementsAndRules()
{
	infoMessages = [];
	infoMessageSetting = [];
	level.ruleMessages = [];
	customCmdFile = "chatbot/config/messages.csv";
		
	if(!fs_testFile(customCmdFile))
		return;
	
	file = openFile(customCmdFile, "read");
	
	if(file <= 0)
		return;

	section = "";
	while(1)
	{
		line = fReadLn(file);
			
		if(!isDefined(line))
			break;
		
		if(isEmptyString(line))
			continue;

		line = StrRepl(line, "\r", "");
		line = StrRepl(line, "\n", "");
		line = trim(line);
		
		if(line == "[settings]" || line == "[messages]" || line == "[rules]")
		{
			section = line;
			continue;
		}

		if(section == "[messages]")
			infoMessages[infoMessages.size] = line;
		else if(section == "[rules]")
			level.ruleMessages[level.ruleMessages.size] = line;
		else if(section == "[settings]")
		{
			line = strToK(line, "=");
			
			if(line.size > 1)
				infoMessageSetting[trim(line[0])] = int(trim(line[1]));
		}
	}

	closeFile(file);

	thread spamInfoMessages(infoMessages, infoMessageSetting);
}

spamInfoMessages(infoMessages, infoMessageSetting)
{	
	if(infoMessages.size <= 0)
		return;

	if(!isDefined(infoMessageSetting["delay"]))
		infoMessageSetting["delay"] = 60;
	
	current = 0;
	while(1)
	{
		if(!isDefined(infoMessages[current]) || isEmptyString(infoMessages[current]))
			current = 0;
		
		exec("say " + infoMessages[current]);
		
		current++;
		wait infoMessageSetting["delay"];
	}
}

/*-----------------------|
|	chatbot core		 |
|-----------------------*/
isMySqlCommand(command)
{
	switch(command)
	{
		//register master admin
		case "iamgod":  return 3;
	
		//reading from database
		case "admins":
		case "alias":
		case "aliases":
		case "find":
		case "lookup":
		case "guid":
		case "ipalias":
		case "ipaliases":
		case "leveltest":
		case "penalties":
		case "seen":
		case "warnings": return 2;
		
		//writing to database
		case "ban":
		case "ipban":
		case "kick":
		case "putgroup":
		case "tempban":
		case "unban":
		case "ungroup":
		case "warn":
		case "warnclear":
		case "warnremove": return 1;
		
		default: return 0;
	}
}

cmdIsCustom(command, arguments)
{
	argTokens = undefined;
	if(isDefined(arguments))
		argTokens = strToK(arguments, " ");
	
	if(command == "help")
	{
		if(!isDefined(argTokens) || !isDefined(argTokens[0]) || isEmptyString(argTokens[0]))
			exec("tell " + self.name + " ^1Add a custom command to the help call!");
		else
		{
			customCmdFound = false;
			
			for(i=0;i<level.customCommands.size;i++)
			{
				if(level.customCommands[i].cmd == argTokens[0] || (isDefined(level.customCommands[i].alias) && level.customCommands[i].alias == argTokens[0]))
				{
					customCmdFound = true;
					argTokens[0] = level.customCommands[i].cmd;
		
					if(isDefined(level.customCommands[i].help))
						exec("tell " + self.name + " " + level.customCommands[i].help);
					else
						exec("tell " + self.name + " ^1" + argTokens[0] + "^7 has no help text.");
						
					break;
				}
			}
			
			if(!customCmdFound)
				exec("tell " + self.name + " ^1Unknown custom command!");
		}
		
		return true;
	}
	else if(command == "rule" || command == "rules")
	{
		if(isDefined(level.ruleMessages))
		{
			if(level.ruleMessages.size <= 0)
				exec("tell " + self.name + " This server has no rules defined - please follow the admins!");
			else
			{
				for(i=0;i<level.ruleMessages.size;i++)
					exec("tell " + self.name + " " + level.ruleMessages[i]);
			}
		}
		
		return true;
	}
	else
	{
		for(i=0;i<level.customCommands.size;i++)
		{
			if(command == level.customCommands[i].cmd || (isDefined(level.customCommands[i].alias) && command == level.customCommands[i].alias))
			{
				command = level.customCommands[i].cmd;
			
				if(!self hasCmdPermission(level.customCommands[i].power))
				{
					exec("tell " + self.name + " ^1Not enough power to execute command!");
					return true;
				}
			
				task = level.customCommands[i].parm;

				if(isSubStr(task, "<NO_ARGS>"))
					task = undefined;
				else
				{
					task = StrRepl(task, "<ARG_EXECUTOR_ID>", self getEntityNumber());
					task = StrRepl(task, "<ARG_EXECUTOR_GUID>", self.guid);
					task = StrRepl(task, "<ARG_EXECUTOR_NAME>", self.name);
					
					taskRequiresTargetPlayer = false;
					if(isSubStr(task, "<ARG_TARGET_PLAYER_"))
					{
						taskRequiresTargetPlayer = true;
						if(!isDefined(argTokens[0]) || isEmptyString(argTokens[0]))
						{
							exec("tell " + self.name + " ^1Incomplete command call - Missing player!");
							return true;
						}

						if(argTokens[0][0] != "@")
						{
							player = getPlayer(argTokens[0], self);
				
							if(!isDefined(player))
								return true;

							task = StrRepl(task, "<ARG_TARGET_PLAYER_ID>", player getEntityNumber());
							task = StrRepl(task, "<ARG_TARGET_PLAYER_GUID>", player.guid);
							task = StrRepl(task, "<ARG_TARGET_PLAYER_NAME>", player.name);
						}
						else
						{
							//@ indicates the db id, so no matter which parameter the cmd requires
							//when the player is online, it has to be replaced witht he db id
							task = StrRepl(task, "<ARG_TARGET_PLAYER_ID>", argTokens[0]);
							task = StrRepl(task, "<ARG_TARGET_PLAYER_GUID>", argTokens[0]);
							task = StrRepl(task, "<ARG_TARGET_PLAYER_NAME>", argTokens[0]);
						}
					}

					if(isSubStr(task, "<ARG>"))
					{
						if(!taskRequiresTargetPlayer)
						{
							if(!isDefined(arguments) || isEmptyString(arguments))
							{
								exec("tell " + self.name + " ^1Incomplete command call - Missing argument!");
								return true;
							}
						
							task = StrRepl(task, "<ARG>", arguments);
						}
						else
						{
							if(argTokens.size <= 1)
							{
								//task = StrRepl(task, "<ARG>", "");
								exec("tell " + self.name + " ^1Incomplete command call - Missing argument!");
								return true;
							}

							if(!isDefined(argTokens[1]) || isEmptyString(argTokens[0]))
							{
								exec("tell " + self.name + " ^1Incomplete command call - Missing argument!");
								return true;
							}
						
							string = "";
							for(i=1;i<argTokens.size;i++)
							{
								string = string + argTokens[i];
								
								if(i < (argTokens.size -1))
									string = string + " ";
							}
						
							task = StrRepl(task, "<ARG>", string);
						}
					}
				}
				
				isMySqlCommand = isMySqlCommand(command);
				if(isMySqlCommand > 0)
				{
					if(!isDefined(level.chatbotMySQL))
					{
						exec("tell " + self.name + " ^1MySQL Database is not connected!");
						return true;
					}
				
					//register master admin
					if(isMySqlCommand == 3)
						addClientToMySqlDatabase(self.guid, self.name, self.ip, "superadmin");
					//reading from database
					else if(isMySqlCommand == 2)
						self readFromMySqlDatabase(command, task);
					//writing to database
					else
						writeToMySqlDatabase(command, task, self);
					
					return true;
				}
				else
				{
					if(isDefined(task))
						exec(task);
					
					return true;
				}
			}
		}
	}
	
	return false;
}

/*-----------------------|
|		MySQL things	 |
|-----------------------*/
addClientToMySqlDatabase(guid, name, ip, type)
{
	timeStamp = getRealTime();

	//`clients`: id, ip, connections, guid, name, level, last_connection 
	client = findInDB("id, connections, guid, name, level", "clients", "guid", guid);
	
	//player not in database yet
	if(!isDefined(client) || client.size <= 0)
	{
		adminLevel = 0;
		if(isDefined(type))
		{
			//`groups`: id, name, keyword, level
			adminLevel = findInDB("name, level", "groups", "keyword", type);
			if(isDefined(adminLevel) && adminLevel.size > 0)
				adminLevel = adminLevel[0]["level"];
		}
	
		//`clients`: id, ip, connections, guid, name, level, last_connection 
		addMySqlEntry("clients", "ip, connections, guid, name, level, last_connection", "'" + ip + "', '1', '" + guid + "', '" + name + "', '" + adminLevel + "', '" + timeStamp + "'");
	}
	else
	{
		if(name != client[0]["name"])
		{
			//add the stored name from client table to aliases if not already known
			//`aliases`: id, alias, client_id 
			alias = findFreeInDB("alias", "aliases", "alias = '" + name + "' AND client_id = '" + client[0]["id"] + "'");
			if(!isDefined(alias) || alias.size <= 0)
				addMySqlEntry("aliases", "alias, client_id", "'" + name + "', '" + client[0]["id"] + "'");
		}
			
		if(name != client[0]["name"])
		{
			//add the stored ip from client table to ipalias if not already known
			//`ipaliases`: id, ip, client_id 
			ipalias = findFreeInDB("ip", "ipaliases", "ip = '" + ip + "' AND client_id = '" + client[0]["id"] + "'");
			if(!isDefined(ipalias) || ipalias.size <= 0)
				addMySqlEntry("ipaliases", "ip, client_id", "'" + ip + "', '" + client[0]["id"] + "'");
		}
	
		//update the values in client table
		if(!isDefined(type))
		{
			//`clients`: id, ip, connections, guid, name, level, last_connection 
			updateMySqlEntries("clients", "name = '" + name + "', ip = '" + ip + "', connections = '" + (int(client[0]["connections"])+1) + "'", "id = '" + client[0]["id"] + "'");
			
			if(int(client[0]["level"]) == 0 && int(client[0]["connections"])+1 >= 5)
				updateMySqlEntry("clients", "level", "1", "id", client[0]["id"]);
			else if(int(client[0]["level"]) == 1 && int(client[0]["connections"])+1 >= 20)
				updateMySqlEntry("clients", "level", "2", "id", client[0]["id"]);
		}
		else
		{
			//`groups`: id, name, keyword, level
			adminLevel = findInDB("name, level", "groups", "keyword", type);
			if(isDefined(adminLevel) && adminLevel.size > 0)
			{
				//`clients`: id, ip, connections, guid, name, level, last_connection 
				updateMySqlEntries("clients", "name = '" + name + "', ip = '" + ip + "', level = '" + adminLevel[0]["level"] + "'", "id = '" + client[0]["id"] + "'");
			}
		}
	}
}

writeToMySqlDatabase(command, arguments, executor)
{
	timeStamp = getRealTime();

	argTokens = undefined;
	if(isDefined(arguments))
		argTokens = strToK(arguments, " ");

	//find the client db id
	//`clients`: id, ip, connections, guid, name, level, last_connection 
	if(argTokens[0][0] == "@")
		clientID = findInDB("id, ip, guid, name, level", "clients", "id", getSubStr(argTokens[0], 1, argTokens[0].size));
	else
	{
		clientID = findInDB("id, ip, guid, name, level", "clients", "guid", argTokens[0]);

		if(!isDefined(clientID) || clientID.size <= 0)
			clientID = findInDB("id, ip, guid, name, level", "clients", "id", argTokens[0]);
	}
	
	if(!isDefined(clientID) || clientID.size <= 0)
		return;

	if(clientID.size > 1)
	{
		if(isDefined(executor) && isPlayer(executor))
			exec("tell " + executor.name + " ^1Multiple entries found - please fix your database.");			
			
		return;
	}

	//find the admin id (in case it's required)
	//`clients`: id, ip, connections, guid, name, level, last_connection 
	adminID = undefined;
	if(isDefined(executor) && isPlayer(executor))
		adminID = findInDB("id, name, level", "clients", "guid", executor.guid);

	if(!isDefined(adminID) || adminID.size <= 0)
	{
		adminID[0] = [];
		adminID[0]["id"] = "-1";
		adminID[0]["name"] = "-";
		adminID[0]["level"] = "-1";
	}
	else
	{
		/*if(adminID.size > 1)
		{
			if(isDefined(executor) && isPlayer(executor))
				exec("tell " + executor.name + " ^1Multiple entries found - please fix your database.");			
			
			return;
		}*/
	}

	switch(command)
	{
		/* manual additions */
		//add new penalty
		case "kick":
			if(int(clientID[0]["level"]) >= int(adminID[0]["level"]))
				exec("tell " + executor.name + " ^1You can not kick a higher admin!");
			else
			{
				reason = extractReasonFromArguments(argTokens, 1);
				//`penalties`: id, type, client_id, admin_id, duration, active, keyword, reason, ip, time_add, time_edit, time_expire 
				addMySqlEntry("penalties", "type, client_id, admin_id, reason, time_add, time_expire", "'Kick', '" + clientID[0]["id"] + "', '" + adminID[0]["id"] + "', '" + reason + "', '" + timeStamp + "', '" + timeStamp + "'");
				
				victim = findPlayerInServer(clientID[0]["name"], clientID[0]["guid"]);
				
				if(isDefined(victim) && isPlayer(victim))
					exec("clientkick " + victim getEntityNumber() + " " + reason);
			}
			break;

		case "ban":
			if(int(clientID[0]["level"]) >= int(adminID[0]["level"]))
				exec("tell " + executor.name + " ^1You can not ban a higher admin!");
			else
			{
				reason = extractReasonFromArguments(argTokens, 1);
				//`penalties`: id, type, client_id, admin_id, duration, active, keyword, reason, ip, time_add, time_edit, time_expire 
				addMySqlEntry("penalties", "type, client_id, admin_id, active, reason, time_add, time_expire", "'Ban', '" + clientID[0]["id"] + "', '" + adminID[0]["id"] + "', '1', '" + reason + "', '" + timeStamp + "', '-1'");
				
				victim = findPlayerInServer(clientID[0]["name"], clientID[0]["guid"]);

				if(isDefined(victim) && isPlayer(victim))
					exec("clientkick " + victim getEntityNumber() + " ^1Permban^7: " + reason);
			}
			break;

		case "ipban":
			if(int(clientID[0]["level"]) >= int(adminID[0]["level"]))
				exec("tell " + executor.name + " ^1You can not ban a higher admin!");
			else
			{
				reason = extractReasonFromArguments(argTokens, 1);
				//`penalties`: id, type, client_id, admin_id, duration, active, keyword, reason, ip, time_add, time_edit, time_expire 
				addMySqlEntry("penalties", "type, admin_id, active, reason, ip, time_add, time_expire", "'Ban', '" + adminID[0]["id"] + "', '1', '" + reason + "', '" + clientID[0]["ip"] + "'" + timeStamp + "', '-1'");
				
				victim = findPlayerInServer(clientID[0]["name"], clientID[0]["guid"]);

				if(isDefined(victim) && isPlayer(victim))
					exec("clientkick " + victim getEntityNumber() + " ^1Permban^7: " + reason);
			}
			break;

		case "tempban":
			if(int(clientID[0]["level"]) >= int(adminID[0]["level"]))
				exec("tell " + executor.name + " ^1You can not ban a higher admin!");
			else
			{
				reason = extractReasonFromArguments(argTokens, 2);
				//`penalties`: id, type, client_id, admin_id, duration, active, keyword, reason, ip, time_add, time_edit, time_expire 
				addMySqlEntry("penalties", "type, client_id, admin_id, duration, active, reason, time_add, time_expire", "'TempBan', '" + clientID[0]["id"] + "', '" + adminID[0]["id"] + "', '" + int(int(argTokens[1])*60) + "', '1', '" + reason + "', '" + timeStamp + "', '" + int(timeStamp+int(argTokens[1])*60) + "'");

				victim = findPlayerInServer(clientID[0]["name"], clientID[0]["guid"]);
				
				if(isDefined(victim) && isPlayer(victim))
					exec("clientkick " + victim getEntityNumber() + " ^1Tempban^7: " + reason + " ^7(^1Expires: " + TimeToString(int(timeStamp+int(argTokens[1])*60), 0, "%d.%m.%Y %H:%M") + "^7)");
			}
			break;
		
		case "unban":
			//`penalties`: id, type, client_id, admin_id, duration, active, keyword, reason, ip, time_add, time_edit, time_expire 
			updateMySqlEntries("penalties", "type = 'Tempban'", "id = '" + clientID[0]["id"] + "' AND type = 'Ban'");
			updateMySqlEntries("penalties", "type = 'Tempban'", "ip = '" + clientID[0]["ip"] + "' AND type = 'IPBan'");
			updateMySqlEntries("penalties", "time_expire = " + timeStamp, "id = '" + clientID[0]["id"] + "' AND type = 'Tempban'");
			break;

		case "warn":
			if(int(clientID[0]["level"]) >= int(adminID[0]["level"]))
				exec("tell " + executor.name + " ^1You can not warn a higher admin!");
			else
			{
				reason = extractReasonFromArguments(argTokens, 1);
				//`penalties`: id, type, client_id, admin_id, duration, active, keyword, reason, ip, time_add, time_edit, time_expire 
				addMySqlEntry("penalties", "type, client_id, admin_id, active, reason, time_add, time_expire", "'Warning', '" + clientID[0]["id"] + "', '" + adminID[0]["id"] + "', '1', '" + reason + "', '" + timeStamp + "', '" + timeStamp + "'");
				
				//`penalties`: id, type, client_id, admin_id, duration, active, keyword, reason, ip, time_add, time_edit, time_expire 
				warnings = findFreeInDB("type, reason, admin_id, active", "penalties", "type = 'Warning' AND active = '1' AND client_id = '" + clientID[0]["id"] + "'");
				
				if(warnings.size > 0)
				{
					exec("tell " + clientID[0]["name"] + " ^3Warning " + warnings.size + "^7: " + reason);
				
					if(warnings.size >= 3)
					{
						//`penalties`: id, type, client_id, admin_id, duration, active, keyword, reason, ip, time_add, time_edit, time_expire 
						updateMySqlEntries("penalties", "active = '0'", "type = 'Warning' AND active = '1' AND client_id = '" + clientID[0]["id"] + "'");
					
						victim = findPlayerInServer(clientID[0]["name"], clientID[0]["guid"]);
						
						if(isDefined(victim) && isPlayer(victim))
							exec("clientkick " + victim getEntityNumber() + " " + reason);
					}
				}
			}
			break;
			
		case "warnclear":
			//`penalties`: id, type, client_id, admin_id, duration, active, keyword, reason, ip, time_add, time_edit, time_expire 
			updateMySqlEntries("penalties", "active = '0'", "type = 'Warning' AND active = '1' AND client_id = '" + clientID[0]["id"] + "'");
			
			if(isDefined(executor) && isPlayer(executor))
				exec("tell " + executor.name + " Removed all active warnings from " + clientID[0]["name"]);
			break;
		
		case "warnremove":
			//`penalties`: id, type, client_id, admin_id, duration, active, keyword, reason, ip, time_add, time_edit, time_expire 
			updateMySqlEntries("penalties", "active = '0'", "type = 'Warning' AND active = '1' AND client_id = '" + clientID[0]["id"] + "' ORDER BY id DESC LIMIT 1");
			
			if(isDefined(executor) && isPlayer(executor))
				exec("tell " + executor.name + " Removed last (active) warning from " + clientID[0]["name"]);
			break;
		
		case "putgroup":
			if(int(clientID[0]["level"]) >= int(adminID[0]["level"]))
				exec("tell " + executor.name + " ^1You can change group of a higher admin!");
			else
			{
				//`groups`: id, name, keyword, level
				groups = findInDB("name, level", "groups", "keyword", argTokens[1]);
				if(groups.size <= 0)
				{
					if(int(argTokens[1]) > 0 || argTokens[1] == "0")
						groups = findInDB("name, level", "groups", "level", int(argTokens[1]));
					
					if(groups.size <= 0)
					{
						exec("tell " + executor.name + " Group ^1" + argTokens[1] + " ^7does not exist!");
						break;
					}
				}
				
				//`clients`: id, ip, connections, guid, name, level, last_connection 
				updateMySqlEntry("clients", "level", groups[0]["level"], "id", clientID[0]["id"]);
				exec("tell " + executor.name + " " + clientID[0]["name"] + " added to group ^1" + groups[0]["name"] + " (" + groups[0]["level"] + ")");
			}
			break;
		
		case "ungroup":
			if(int(clientID[0]["level"]) >= int(adminID[0]["level"]))
				exec("tell " + executor.name + " ^1You can not ungroup a higher admin!");
			else
			{
				//`clients`: id, ip, connections, guid, name, level, last_connection 
				updateMySqlEntry("clients", "level", 0, "id", clientID[0]["id"]);
			}
			break;
			
		default: break;
	}
}

readFromMySqlDatabase(command, searchValue)
{
	//commands that don't need any input
	//list all online admins
	if(command == "admins")
	{
		//`groups`: id, name, keyword, level
		groups = findInDB("name, level", "groups");
	
		if(groups.size <= 0)
			exec("tell " + self.name + " Could not print admins - No groups in database.");
		else
		{
			foundAdmin = false;
			for(i=0;i<groups.size;i++)
			{
				if(groups[i]["name"] == "Regular" || groups[i]["name"] == "User" || groups[i]["name"] == "Guest")
					continue;
			
				//`clients`: id, ip, connections, guid, name, level, last_connection 
				admin = findInDB("guid, name", "clients", "level", groups[i]["level"]);
				
				for(j=0;j<admin.size;j++)
				{
					for(k=0;k<level.players.size;k++)
					{
						if(level.players[k].guid == admin[j]["guid"])
						{
							if(!foundAdmin)
							{
								foundAdmin = true;
								exec("tell " + self.name + " Online ^1Admins^7:");
							}
							
							exec("tell " + self.name + " " + level.players[k].name + " ^7(^3" + groups[i]["name"] + ", " + groups[i]["level"] + "^7)");
						}
					}
				}
			}
			
			if(!foundAdmin)
				exec("tell " + self.name + " Online ^1Admins^7: ^3None");
		}

		return;
	}
	
	if(!isDefined(searchValue) || isEmptyString(searchValue))
		return;
	
	//find aka. lookup is the only command that requires a string input
	//it will either return
	//- the id of a client if one client matches the exact search term only
	//- a set of ids when multiple clients contain the search term
	//find client
	if(command == "find" || command == "lookup")
	{
		//`clients`: id, ip, connections, guid, name, level, last_connection 
		clients = findInDB("id, name", "clients", "name", searchValue, false);
		
		exec("tell " + self.name + " Found:");
		
		for(i=0;i<clients.size;i++)
			exec("tell " + self.name + " " + clients[i]["name"] + " (^3" + clients[i]["id"] + "^7)");
		
		return;
	}

	//all other commands require the client id (integer) input
	//`clients`: id, ip, connections, guid, name, level, last_connection 
	if(searchValue[0] == "@")
		clientID = findInDB("id, ip, guid, name, level", "clients", "id", getSubStr(searchValue, 1, searchValue.size));
	else
	{
		clientID = findInDB("id, name", "clients", "name", searchValue, false);

		if(clientID.size <= 0)
			clientID = findInDB("id, name", "clients", "guid", searchValue, false);
	}

	if(clientID.size <= 0)
	{
		exec("tell " + self.name + " ^1No entry in database found!");
		return;
	}

	if(clientID.size > 1)
	{
		exec("tell " + self.name + " Did you mean:");
	
		for(i=0;i<clientID.size;i++)
			exec("tell " + self.name + " " + clientID[i]["name"] + " (^3" + clientID[i]["id"] + "^7)");
		
		return;
	}
	
	switch(command)
	{
		//find alias
		case "alias":
		case "aliases":
			//`aliases`: id, alias, client_id 
			aliases = findInDB("alias", "aliases", "client_id", int(clientID[0]["id"]));
			
			if(aliases.size <= 0)
				exec("tell " + self.name + " " + clientID[0]["name"] + " has no aliases.");
			else
			{
				exec("tell " + self.name + " " + clientID[0]["name"] + " is also known as:");
				for(i=0;i<aliases.size;i++)
					exec("tell " + self.name + " " + aliases[i]["alias"]);
			}
			break;
		
		//find guid
		case "guid":
			//`clients`: id, ip, connections, guid, name, level, last_connection 
			guid = findInDB("guid", "clients", "id", int(clientID[0]["id"]));
			exec("tell " + self.name + " " + clientID[0]["name"] + ": " + guid[0]["guid"]);
			break;
		
		//find ip alias
		case "ipalias":
		case "ipaliases":
			//`ipaliases`: id, ip, client_id 
			ips = findInDB("ip", "ipaliases", "client_id", int(clientID[0]["id"]));
			
			if(ips.size <= 0)
				exec("tell " + self.name + " " + clientID[0]["name"] + " has no other ip connections.");
			else
			{
				exec("tell " + self.name + " " + clientID[0]["name"] + " also connected from:");
				for(i=0;i<ips.size;i++)
					exec("tell " + self.name + " " + ips[i]["ip"]);
			}
			break;
		
		//find admin rank
		case "leveltest":
			//`clients`: id, ip, connections, guid, name, level, last_connection 
			adminRank = findInDB("level", "clients", "id", int(clientID[0]["id"]));
			exec("tell " + self.name + " " + clientID[0]["name"] + ": " + adminRank[0]["level"]);
			break;

		//find penalty
		//enum is a string of these: 'Ban','TempBan','Kick','Warning','Notice')
		case "penalty":
		case "penalties":
			//`penalties`: id, type, client_id, admin_id, duration, active, keyword, reason, ip, time_add, time_edit, time_expire 
			penalties = findInDB("type, reason, admin_id, time_add", "penalties", "client_id", int(clientID[0]["id"]));
			
			if(penalties.size <= 0)
				exec("tell " + self.name + " " + clientID[0]["name"] + " has no penalties.");
			else
			{
				exec("tell " + self.name + " " + clientID[0]["name"] + " has penalties:");
				for(i=0;i<penalties.size;i++)
				{
					//`clients`: id, ip, connections, guid, name, level, last_connection 
					adminName = findInDB("name", "clients", "id", penalties[i]["admin_id"]);
					if(!isDefined(adminName) || !isDefined(adminName[0]) || !isDefined(adminName[0]["name"]))
					{
						exec("tell " + self.name + " " + penalties[i]["type"] + ": " + penalties[i]["reason"] + " (Admin: ^1^-^7, Added: ^1" + TimeToString(int(penalties[i]["time_add"]), 0, "%d.%m.%Y") + "^7)");
						continue;
					}
					
					adminName = adminName[0]["name"];
					exec("tell " + self.name + " " + penalties[i]["type"] + ": " + penalties[i]["reason"] + " (Admin: ^1" + adminName + "^7, Added: ^1" + TimeToString(int(penalties[i]["time_add"]), 0, "%d.%m.%Y") + "^7)");
				}
			}
			break;
			
		//find last online time
		case "seen":
			//`clients`: id, ip, connections, guid, name, level, last_connection 
			seen = findInDB("last_connection", "clients", "id", int(clientID[0]["id"]));
			
			if(seen.size <= 0)
				exec("tell " + self.name + " Latest connection of " + clientID[0]["name"] + " on " + TimeToString(int(seen[0]["last_connection"]), 0, "%d.%m.%Y %H:%M"));
			else
				exec("tell " + self.name + " Latest connection of " + clientID[0]["name"] + " on " + TimeToString(int(seen[0]["last_connection"]), 0, "%d.%m.%Y %H:%M"));
			break;
			
		case "warnings":
			//`penalties`: id, type, client_id, admin_id, duration, active, keyword, reason, ip, time_add, time_edit, time_expire 
			warnings = findFreeInDB("type, reason, admin_id, time_add, active", "penalties", "type = 'Warning' AND client_id = '" + int(clientID[0]["id"]) + "' AND active = '1'");
			
			if(warnings.size <= 0)
				exec("tell " + self.name + " " + clientID[0]["name"] + " has no active warnings.");
			else
			{
				exec("tell " + self.name + " " + clientID[0]["name"] + " has active warnings:");
				for(i=0;i<warnings.size;i++)
				{
					//`clients`: id, ip, connections, guid, name, level, last_connection 
					adminName = findInDB("name", "clients", "id", warnings[i]["admin_id"]);
					if(!isDefined(adminName) || !isDefined(adminName[0]) || !isDefined(adminName[0]["name"]))
					{
						exec("tell " + self.name + " " + warnings[i]["type"] + ": " + warnings[i]["reason"] + " (Admin: ^1^-^7, Added: ^1" + TimeToString(int(warnings[i]["time_add"]), 0, "%d.%m.%Y") + "^7)");
						continue;
					}
					
					adminName = adminName[0]["name"];
					exec("tell " + self.name + " " + warnings[i]["type"] + ": " + warnings[i]["reason"] + " (Admin: ^1" + adminName + "^7, Added: ^1" + TimeToString(int(warnings[i]["time_add"]), 0, "%d.%m.%Y") + "^7)");
				}
			}
			break;
			
		default: break;
	}
}

addMySqlEntry(table, columns, values)
{
	//consolePrint("query: " + "INSERT INTO `" + table + "` (" + columns + ") VALUES (" + values + ");" + "\n");
	mysql_query(level.chatbotMySQL, "INSERT INTO `" + table + "` (" + columns + ") VALUES (" + values + ");"); 
}

updateMySqlEntry(table, alterColumn, alterValue, searchColumn, searchValue)
{
	//consolePrint("query: " + "UPDATE `" + table + "` SET " + alterColumn + " = " + alterValue + " WHERE " + searchColumn + " = '" + searchValue + "';" + "\n");
	mysql_query(level.chatbotMySQL, "UPDATE `" + table + "` SET " + alterColumn + " = " + alterValue + " WHERE " + searchColumn + " = '" + searchValue + "';"); 
}

updateMySqlEntries(table, alterString, condition)
{
	//consolePrint("query: " + "UPDATE `" + table + "` SET " + alterString + " WHERE " + condition + ";" + "\n");
	mysql_query(level.chatbotMySQL, "UPDATE `" + table + "` SET " + alterString + " WHERE " + condition + ";"); 
}

findInDB(columns, table, searchColumn, searchValue, exactMatch)
{
	if(!isDefined(exactMatch))
		exactMatch = true;

	if(isDefined(searchColumn) && isDefined(searchValue))
	{
		if(!exactMatch)
		{
			//consolePrint("query: " + "SELECT " + columns + " FROM `" + table + "` WHERE " + searchColumn + " LIKE '%%" + searchValue + "%%';" + "\n");
			mysql_query(level.chatbotMySQL, "SELECT " + columns + " FROM `" + table + "` WHERE " + searchColumn + " LIKE '%%" + searchValue + "%%';");
		}
		else
		{
			//consolePrint("query: " + "SELECT " + columns + " FROM `" + table + "` WHERE " + searchColumn + " = '" + searchValue + "';" + "\n");
			mysql_query(level.chatbotMySQL, "SELECT " + columns + " FROM `" + table + "` WHERE " + searchColumn + " = '" + searchValue + "';");
		}
	}
	else
	{
		//consolePrint("query: " + "SELECT " + columns + " FROM `" + table + "`;" + "\n");
		mysql_query(level.chatbotMySQL, "SELECT " + columns + " FROM `" + table + "`;");
	}

	data = collectResults();
	return data;
}

findFreeInDB(columns, table, searchQuery)
{
	//consolePrint("query: " + "SELECT " + columns + " FROM `" + table + "` WHERE " + searchQuery + ";" + "\n");
	mysql_query(level.chatbotMySQL, "SELECT " + columns + " FROM `" + table + "` WHERE " + searchQuery + ";");
	
	data = collectResults();
	return data;
}

collectResults()
{
	rowsCount = mysql_num_rows(level.chatbotMySQL);
	//consolePrint("rowsCount: " + rowsCount + "\n");
	
	data = [];
	if(isDefined(rowsCount) && rowsCount > 0)
	{
		if(rowsCount == 1)
		{
			result = mysql_fetch_row(level.chatbotMySQL);
			keys = getArrayKeys(result);
			
			for(i=0;i<keys.size;i++)
			{
				//consolePrint("Key=" + keys[i] + ", value=" + result[keys[i]] + "\n");
				data[0][keys[i]] = result[keys[i]];
			}
		}
		else
		{
			result = mysql_fetch_rows(level.chatbotMySQL);
			for(i=0;i<result.size;i++)
			{
				keys = getArrayKeys(result[i]);
								
				for(j=0;j<keys.size;j++)
				{
					//consolePrint("Row #" + i + ", Key=" + keys[j] + ", value=" + result[i][keys[j]] + "\n");
					data[i][keys[j]] = result[i][keys[j]];
				}
			}
		}
	}
	
	return data;
}

/*-----------------------|
| 	side functions		 |
|-----------------------*/
findCustomCmd(customCmds, cmd)
{
	for(i=0;i<customCmds.size;i++)
	{
		if(customCmds[i].cmd == cmd)
			return i;
	}
}

/* string manipulation */
//Check if a string is empty or contains spaces only
isEmptyString(string)
{
	if(string == "")
		return true;
		
	if(getSubStr(string, 0, 2) == "//")
		return true;
		
	index = 0;
	while(getSubStr(string, index, index + 1) == " " && index < string.size)
		index++;
	
	return (index >= string.size);
}

// Trims left spaces from a string
trimLeft(string)
{
	index = 0;
	while(getSubStr(string, index, index + 1) == " " && index < string.size)
		index++;

	return getSubStr(string, index, string.size);
}

// Trims right spaces from a string
trimRight(string)
{
	index = string.size;
	while(getSubStr(string, index - 1, index) == " " && index > 0)
		index--;

	return getSubStr(string, 0, index);
}

// Trims all the spaces left and right from a string
trim(string)
{
	return (trimLeft(trimRight(string)));
}

extractReasonFromArguments(argTokens, startToken)
{
	if(!isDefined(startToken))
		startToken = 0;

	reason = "";
	if(argTokens.size >= 2)
	{
		if(startToken < argTokens.size)
		{
			for(i=startToken;i<argTokens.size;i++)
			{
				reason = reason + argTokens[i];

				if(i < (argTokens.size -1))
					reason = reason + " ";
			}
		}
	}
	
	return reason;
}

/* player related */
onPlayerConnect()
{
	while(1)
	{
		level waittill("connected", player);
		
		player.ip = strToK(player getPlayerIP(), ":")[0];
		player.guid = player GetUniquePlayerID();

		if(!level.splitscreen && !isDefined(player.pers["score"]))
			thread addClientToMySqlDatabase(player.guid, player.name, player.ip);
		
		player thread kickOnActiveBans();
		player thread detectNameChange();		
	}
}

kickOnActiveBans()
{
	self endon("disconnect");

	//find the client db id
	//`clients`: id, ip, connections, guid, name, level, last_connection 
	clientID = findInDB("id, ip, guid, name", "clients", "guid", self.guid);

	if(!isDefined(clientID) || clientID.size <= 0)
		return;

	if(clientID.size > 1)
		return;

	//`penalties`: id, type, client_id, admin_id, duration, active, keyword, reason, ip, time_add, time_edit, time_expire 
	allbans = findFreeInDB("id, type, active, reason, ip, time_expire", "penalties", "(type = 'Ban' OR type = 'IPBan' OR type = 'TempBan') AND active = '1' AND (client_id = '" + clientID[0]["id"] + "' OR ip = '" + clientID[0]["ip"] + "')");
	
	if(allbans.size <= 0)
		return;

	timeStamp = getRealTime();
	for(i=0;i<allbans.size;i++)
	{
		if(allbans[i]["type"] == "Ban")
		{
			exec("clientkick " + self getEntityNumber() + " ^1Permban^7: " +  allbans[i]["reason"]);
			break;
		}
		
		if(allbans[i]["type"] == "IPBan")
		{
			exec("clientkick " + self getEntityNumber() + " ^1IP-Ban^7: " +  allbans[i]["reason"]);
			break;
		}
		
		if(allbans[i]["type"] == "TempBan")
		{
			//remove tempbans when bantime is over
			if(timeStamp >= int(allbans[i]["time_expire"]))
			{
				//`penalties`: id, type, client_id, admin_id, duration, active, keyword, reason, ip, time_add, time_edit, time_expire 
				updateMySqlEntry("penalties", "active", "0", "id", allbans[i]["id"]);
			}
			else
			{
				exec("clientkick " + self getEntityNumber() + " ^1Tempban^7: " +  allbans[i]["reason"] + " ^7(^1Expires: " + TimeToString(int(allbans[i]["time_expire"]), 0, "%d.%m.%Y %H:%M") + "^7)");
				break;
			}
		}
	}
}

detectNameChange()
{
	self endon("disconnect");
	
	curName = self.name;
	while(1)
	{
		wait 3;
		
		if(self.name != curName)
		{
			addClientToMySqlDatabase(self.guid, self.name, self.ip);
			curName = self.name;
		}
	}
}

hasCmdPermission(cmdLvl)
{
	//find the client db id
	//`clients`: id, ip, connections, guid, name, level, last_connection 
	clientID = findInDB("id, guid, name", "clients", "guid", self.guid);

	if(!isDefined(clientID) || clientID.size <= 0)
		return false;

	if(clientID.size > 1)
		return false;

	//`clients`: id, ip, connections, guid, name, level, last_connection 
	adminRank = findInDB("level", "clients", "id", clientID[0]["id"]);
	
	if(int(adminRank[0]["level"]) < cmdLvl)
		return false;
		
	return true;
}

findPlayerInServer(name, guid)
{
	for(i=0;i<level.players.size;i++)
	{
		if(isDefined(level.players[i].guid) && isDefined(guid) && level.players[i].guid == guid)
			return level.players[i];
		
		if(isDefined(level.players[i].name) && isDefined(name) && level.players[i].name == name)
			return level.players[i];
	}
	
	return undefined;
}

getPlayer(value, executor)
{
	if(isDefined(value) && value.size > 0)
	{
		//A Name for sure
		if(value.size > 2)
		{
			counter = 0;
			player = 0;

			for(i=0;i<level.players.size;i++)
			{
				if(isSubStr(toLower(level.players[i].name), toLower(value))) 
				{
					player = level.players[i];
					counter++;
				}
			}
			
			if(counter == 1)
				return player;

			if(isDefined(executor) && isPlayer(executor))
			{
				if(counter == 0)
					exec("tell " + executor getEntityNumber() + " ^1NO PLAYER FOUND");
				else
					exec("tell " + executor getEntityNumber() + " ^1MULTIPLE PLAYERS FOUND");
			}
		}
		//A Slot
		else
		{
			for(i=0;i<level.players.size;i++)
			{
				if(level.players[i] getEntityNumber() == int(value)) 
					return level.players[i];
			}
		}
	}
	
	return undefined;
}

GetUniquePlayerID()
{
	guid = self GetGuid();
	
	if(!isDefined(guid) || guid == "")
		guid = self GetPlayerID();
		
	if(!isDefined(guid))
		return "";
		
	return guid;
}