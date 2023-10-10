# TwitchSoundChat

This is a minimum-permission, self-hosted bot that reads Twitch chat and plays sounds via VLC Player based on what it reads. This uses PowerShell, which is on already on all Windows systems. If you're running Windows, you already have everything installed to run this bot. PowerShell does not need to be run as Administrator to use this.

# Minimum-permission, self-hosted

What this means is that the only permission that this bot requests is the ability to read Twitch chat. Self-hosted means that YOU register this bot through your Dev console which means you are in complete control of it. There is a little more manual work on your end to get it up and running, but you are in 100% control of it.

Another benefit of this bot is that since everything is self-hosts, latency between the triggering word/phrase and playing the media file is nearly instantenous.

# Requirements

- VLC Player must be installed. (https://www.videolan.org/vlc/)
- PowerShell version 5+ must be installed, if you're running Windows, anything remotely recent you should be okay.
- Sounds (duh) that you want to have played on stream in response to a triggering word or phrase. Any media file playable by VLC Player will work.
- You have some technical literacy in configuring stuff on your computer. If you're comfortable tinkering with OBS, you should be fine.

# Why I made this

Originally I wanted a dice rolling bot for our board game streams. There's already a number of bots out there that can do dice rolling but its usually one of many features that the bot can do. Unfortunately, that means just for dice rolling, I have to grant way too many permissions on our channel to that bot than I'm comfortable for just dice rolling. And unlike an Android/iOS app, where you can deny certain permissions to an app, you can't really do that with a Twitch Application Connection. So I decided to make this in the hopes that others might want just a dice-rolling bot, or just a sound-player bot.

# Setting up the self-hosted bot (perform once only)

To register and set up the bot, perform the following steps:

- Go to your developer console, at dev.twitch.tv/console. (log in if you need to).
- Navigate to Applications and click "Register Your Application".
- Give your sound bot a name, in this example, I'm calling it the DanielAndMayaSoundBot.
  - ensure that the OAuth Redirect URLs is `http://localhost`.
  - ensure that the Category is Chat Bot.
- Click Create, this will create the bot.
- In Applications, click "Manage" for your newly created bot.
- In this view, you'll see two new parts of this app, Client ID and Client Secret (example from mine have been blurred).
  - Your Client ID is like an SSN (Social Security Number) for your bot.
  - Your Client Secret is like a special password (not your Twitch password) that the bot can use to authenticate to Twitch.
- Click on New Secret to generate a new Client Secret (example from mine have been blurred).
- Once its generated copy both Client ID and Client Secret to the `Start-TwitchSoundChat.ps1` script.
- Copy the Client ID and paste it in the following line 3 of the `Start-TwitchSoundChat.ps1` script. Replace the xxx's with the Client ID:
  - `$clientID     = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"`
- Copy the Client ID and paste it in the following line 8 of the `Start-TwitchSoundChat.ps1` script. Replace the xxx's with the Client ID:
  - `#https://id.twitch.tv/oauth2/authorize?response_type=code&client_id=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx&redirect_uri=http://localhost&scope=chat%3Aread`
- Copy the Client Secret and paste it in the following line 4 of the `Start-TwitchSoundChat.ps1` script. Replace the yyy's with the Client Secret:
  - `$clientsecret = "yyyyyyyyyyyyyyyyyyyyyyyyyyyyyy"`
- Enter your channel name on line 7 of the `Start-TwitchSoundChat.ps1` script.
  - `$yourchannelname = "yourchannelname"`
- If necessary, enter in the install location for VLC on line 10 of the `Start-TwitchSoundChat.ps1` script. If you did not change the default install location, you should not need to change this.
- Optionally, if you want the bot to say something when it connects to Twitch chat, uncomment line 126 and change the text to whatever you need.
- This completes the one-time setup process for your new bot.

# running the bot after registering it (perform every time you want to use it)

To use the bot, you must perform these steps every time you want it to read chat on stream.

- Open VLC Player, ensure that your streaming software targets VLC.exe as an audio source.
- Open the `Start-TwitchSoundChat.ps1` script, and copy line 8, skipping the `#` symbol. It will look something like this with your replaced Client ID already entered into it.
  - `https://id.twitch.tv/oauth2/authorize?response_type=code&client_id=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx&redirect_uri=http://localhost&scope=chat%3Aread`
- Open the same browser you use to log into Twitch, and paste the link there and go to that address.
- You should see an authorization request, from your own bot with the permissions to "View live Stream Chat and Room messages". Click "Authorize". **(Once you perform this step, it will be skipped in future login attempts).**
- You'll see a "Redirecting" message but eventually you land at a page that seems to be broken:
- Despite this, we're looking for a code that now appears in the URL of the broken page:
- Copy the code and paste it in the following line 23 of the `Start-TwitchSoundChat.ps1` script. Replace the zzz's with the Access Code:
  - `$accesscode = "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"`
- Open the folder where the script and files are located, and hold `SHIFT` and right-click on open whitespace. This will bring up a special context menu where `Open PowerShell window here` is an option, select it. This will open up a PowerShell window in this current directory.
- Run the `Start-TwitchSoundChat.ps1` script using the following syntax:
  - `.\Start-TwitchSoundChat.ps1`
- You should now be connected to Twitch chat and sounds should play from VLC player if the trigger word/phrase is read and the conditions are met.

# sounds.csv and twitchusers.ps1

These two files support the `Start-TwitchSoundChat.ps1` script and are required by it. `twitchusers.ps1` lets you group some users together so they can access sounds that others cannot. `sounds.csv` controls what trigger word/phrases set off which sounds. It also has some control mechanisms to avoid spamming.

## twitchusers.ps1

This file specifies groups of users to be named in the `sounds.csv` file and can be opened with any text editor (preferably Notepad.exe). By creating new variables, you can categorize users into groups that the `sounds.csv` can refer to for who can play this sound. For example, take the following line:

```
$vipusers    = "number1fan","johhny"
```

With this grouping, any sound with the Group category of "vipusers" (which include "number1fan" and "johhny") can trigger the relevant sound file.

The group name can be anything you like, here is another example:

```
$mystreamergroup = "toddman","flashsword123","bigbaxbux"
```

In this example, the Group category "mystreamgroup" includes 3 members ("toddman","flashsword123" and "bigbaxbux")

This file is read every time a trigger word/phrase is parsed, so updating it while `Start-TwitchSoundChat.ps1` is running will update the groups accordingly.

### bannedusers special group

The group "bannedusers" contains any users that should never be allowed to play sounds. These listed users will always fail to trigger a sound even if they exist in other Groups.

### example twitchusers.ps1

Here is another example twitchusers.ps1:

```
$vipusers    = "somename"
$moderators  = "yournamehere","theirnamealsohere"
$bannedusers = "badnamehere"
$mydndgroup  = "dndmember","soandso"
```

## sounds.csv

This csv (comma separated values) file can be opened with any text editor (preferably Notepad.exe). Each entry in this file is one sound that can be played. The columns are as follows:

| Column | Description | Example |
| ------ | ----------- | ------- | 
| Trigger | The word or phrase that will trigger and play this sound. | bruh |
| Sound | The absolute path of the media file to play. | C:\Users\myname\Downloads\sound\bruh.mp3 |
| Timeout | The timeout value (in seconds) between plays of this sound. | 15 |
| NumberofPlays | The total number of times this sound can be played during this stream. | 5000 |
| Group | The group of users that can use this sound. Specified by `twitchusers.ps1`. | everyone |

- By default, only the Group category "everyone" will be playable by everyone. Except when the user is also in the bannedusers Group.

### Trigger Column

The word/phrase entered in this column will be checked for with a LIKE match operator. Meaning that the triggering word/phrase can appear anywhere in the Twitch chat message. Take the following example entry in sounds.csv:

```
bruh,C:\Users\myname\Downloads\sound\bruh.mp3,5,5000,vipusers
```

In this example, a member of the "vipusers" Group will trigger the bruh.mp3 sound with any of the following text examples:

```
bruh
wtf bruh
bruh omg
```

### another example sounds.csv

Here is another example sounds.csv:

```
Trigger,Sound,Timeout,NumberofPlays,Group
fartwithreverb,C:\users\myname\Desktop\Fart01.wav,15,5000,everyone
bruh,C:\Users\myname\Downloads\sound\bruh.mp3,5,5000,vipusers
```