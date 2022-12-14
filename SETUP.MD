# Chatbot - Ingame Administration Tool for CoD4X

**A fast written setup tutorial - will be updated soon**

## Phase 1: Preparation

Before you start download the chatbot files from github and save them anywhere you like, e.g. your desktop.<br/>
Make sure you have root/sudo access to your server and upload permissions in case it's not a local machine.

## Phase 2: Preparing the MySQL environment

Chatbot requires a database to store/read player informations therefore it's mandarory to have MySQL or similar installed.<br/>
To allow your cod4x server to connect to said database you need the plugin coming with this package.

**To keep things simple you can do the following steps through phpmyadmin**

### Step 1: Creating the MySQL database

Create a database in MySQL for Chatbot to use and name it as you wish.<br/>
For safety reasons create a new user that has full permissions on this database.

### Step 2: Initializing the MySQL database

Import the example database 'empty_db.sql' of chatbot which can be found in 'cod4x_chatbot_admintool\cod4x-server\mods\your_mod\chatbot\config\mysql'.

Either use the phpmyadmin import feature or the shell command<br/>
```mysql -u root -p <mysql password> <database name> empty_db.sql```

## Phase 3: Preparing the CoD4X environment

Copy the CoD4X plugin 'libcod4x_mysql.so' (linux) or 'libcod4x_mysql.dll' (windows) from 'cod4x_chatbot_admintool\cod4x-server\plugins' to the plugins folder of your CoD4X server.<br/>
If folder does not exist yet, then create it in your CoD4X server's root folder.<br/>
To load the plugin add this to your server config:<br/>
```loadplugin libcod4x_mysql```

On windows servers you also have to copy the mysql library 'cod4x_chatbot_admintool\cod4x-server\plugins\source\cod4x_mysql_plugin\mysql\windows\lib\libmysql.dll' to your CoD4X server's root folder.

## Phase 4: Setting up Chatbot's config files

### Step 1: CoD4X config - database login

Add the following lines to your server config and add the login data of the previously created MySQL database:<br/>
```
set chatbot 1 //0 = off, 1 = on
set chatbot_mysql_ip "" //IP or localhost when MySQL is running on the same machine
set chatbot_mysql_port "" //Optional
set chatbot_mysql_user ""
set chatbot_mysql_password ""
set chatbot_mysql_database ""
```

### Step 2: Chatbot config files

Copy the whole folder named 'chatbot' from 'cod4x-server\mods\your_mod' to your mod.<br/>
Within the config folder you will find three config files.<br/>
- defaultCmdTable.csv: contains the core functions - unless you know what you do you should not modify this file
- customCmdTable.csv: this is the place you can add your custom commands
- messages.csv: add advertisments (messages which are spammed after a delay) and server rules (which can be read by players with $rules)

**Chatbot was not tested without a mod - if you are lucky it will work without a mod when the files are copied to main_shared.**

### Step 3: Initializing Chatbot

If you add chatbot to an existing mod it is very likely that the mod already comes with a modified '_globallogic.gsc' and a '_callbacksetup.gsc'.<br/>
The two files coming with the chatbot package are default files which have the chatbot initialization already included.<br/>
Please compare the files with the files within your mod and add the chatbot lines.

## Phase 4: Starting Chatbot 

Since chatbot is no additional software it will start together with your CoD4X server.<br/>
**It's recommended to start the server with a password!<br/>
When your server boots without a crash related to chatbot or the chatbot MySQL database it's very likely that it successfully started.<br/>
By default a message is sent to the server after a minute - you can see this message in game and inside the server console.<br/>

To claim master admin rights join the server and type $iamgod into the chat.<br/>
This command is available once only!<br/>
You are now ready to use chatbot and remove the server password.

##Phase 5: Using Chatbot 

Chatbot - as the name suggests - is reading the chat and checks for entered commands.<br/>
To claim master admin rights use the command $iamgod - it's only available once!<br/>

For a detailed list of commands check the config files 'defaultCmdTable.csv' and 'customCmdTable.csv'.

**How to ban a player:**<br/>
```$ban <playername> <reason>```

**How to ban an offline player:**<br/>
Somtimes a player needs a punishment but he already left the server.<br/>
All you need is his database id and you can punish him.<br/>

```$find <playername>```

Identify the player from the outputted list and use his id in brackets<br/>

```$ban @id <reason>```
