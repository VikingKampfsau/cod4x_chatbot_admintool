# Chatbot - Ingame Administration Tool for CoD4X

## Overview

Chatbot is an ingame administration tool for CoD4X servers that allows server admins to easily maintain there server through the chat.<br/>
Players can also invoke commands to retrieve certain informations.

## Features
Core Features:
- Information about players are store in a MySQL database
- Admins can retrieve this informations through the chat and punish misbehaving players, even when they are offline
- Admins are separated into groups so the head admin can limit their power
- Define advertisement messages or rules within the config file and they are spammed to the server every now and then

Admins Commands:
- Warn, Kick, Tempban, Permban, IPban misbehaving players
- Remove Warnings and unban players
- Display previous punishments and warnings of a player
- Check old aliases of a player
- Check when a player was last online
- Change map
- Execute Rcon commands
- Add players to admin groups or remove them
- Send a PM to a player
- Screenshot a player to check for active hacks

Normal Player Commands:
- Display all online admins
- Find out your CoD4X (G)UID
- Display the server rules


## Installation

Install cod4x and add the required plugins to it.<br/>
Copy the files within the example mod folder to your mod folder<br/>
Create a new mysql database and import the empty example file from 'chatbot\config\mysql'.<br/>

In case you run a mod with modified '_globallogic.gsc' and/or '_callbacksetup.gsc' then compare the files and add the 'chatbot' parts to your source.<br/>

## Configuration

Add the dvars from 'codserver.cfg' to your server config file and change them to allow the server to connect to the database.<br/>
Also modify the config files found in 'chatbot\config\' as you desire.<br/>

## Support
For bug reports and issues, please visit the "Issues" tab at the top.<br/>
First look through the issues, maybe your problem has already been reported.<br/>
If not, feel free to open a new issue.<br/>

**Keep in mind that we only support the current state of the repository - older versions are not supported anymore!**

However, for any kind of question, feel free to visit our discord server at https://discord.gg/wDV8Eeu!

## Credits:
MySQL Plugin for CoD4X by T-Maxxx:
https://github.com/callofduty4x/mysql
