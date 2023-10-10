### access config ###
# these should never change once set
$clientID     = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
$clientsecret = "yyyyyyyyyyyyyyyyyyyyyyyyyyyyyy"

# your channel name
$yourchannelname = "yournamehere"

# the location of the VLC Player
$global:VLCExeLocation = "C:\Program Files\VideoLAN\VLC\vlc.exe"

# the location of the source csv file to use
$sourcecsv = ".\sounds.csv"

# Step 1)
# copy and paste your clientID from above into the url below after the "client_id=" part
# https://id.twitch.tv/oauth2/authorize?response_type=code&client_id=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx&redirect_uri=http://localhost&scope=chat%3Aread
# then copy the completed URL into the same browser you use for logging into Twitch
# you'll get redirect to localhost (your own computer) after logging in with a url that looks like this
# http://localhost/?code=zzzzzzzzzzzzzzzzzzzzzzzzzzzzzz&scope=chat%3Aread

# copy and paste the code part from the redirected url here
$accesscode = "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"

# getting the final OAUTH token
$i = Invoke-RestMethod -Method Post -uri "https://id.twitch.tv/oauth2/token" -Body(@{client_id=$clientID;client_secret=$clientsecret;code=$accesscode;grant_type="authorization_code";redirect_uri="http://localhost"}) -ContentType 'application/x-www-form-urlencoded'
$oauthtoken = $i.access_token

### rest of script, don't modify this unless you know what you are doing ###

class TwitchSound
{
	[System.String]$Trigger
	[System.String]$FileLocation
	[System.Int32]$Timeout
	[System.Int32]$NumberOfPlays
	[System.String]$Group
	[System.DateTime]$LastPlayed

	TwitchSound ([PSCustomObject]$t)
	{
		$this.Trigger       = $t.Trigger
		$this.FileLocation  = $t.Sound
		$this.Timeout       = $t.Timeout
		$this.NumberOfPlays = $t.NumberOfPlays
		$this.Group         = $t.Group
		$this.LastPlayed    = (Get-Date)
	}# TwitchSound ([PSCustomObject]$t)

	playSound()
	{
		# plays using VLC player and its options
		Invoke-Expression -Command ('& "{0}" --play-and-stop "{1}" --one-instance' -f $global:VLCExeLocation, $this.FileLocation)
		$this.LastPlayed = Get-Date
		$this.NumberOfPlays = $this.NumberOfPlays - 1
	}
}# class TwitchSound

function Can-PlayTwitchSound
{
	param ([TwitchSound]$sound, $user)

	# re reading the twitchusers.ps1 file, this is so that you can updated twitchusers.ps1 without having to rerun this script
	$scriptpath = ($Script:MyInvocation.MyCommand).Path -replace ($Script:MyInvocation.MyCommand).Name,''
	Invoke-Expression -Command $([System.IO.File]::ReadAllText(("{0}twitchusers.ps1" -f $scriptpath)))

	# if the user is banned
	if ($bannedusers -contains $user)
	{
		Write-Host ("Not playing sound [{0}] for user [{1}] because user is banned." -f $sound.Trigger, $user)
		return $false
	}
	
	# if this group is not the everyone group and the users isn't banned
	if ($sound.Group -ne "everyone" -and $bannedusers -notcontains $user)
	{
		# getting the group variable
		$thisgroup = Get-Variable -Name $sound.Group | Select-Object -ExpandProperty Value

		# if this group does not contain the user, return false
		if ($thisgroup -notcontains $user)
		{
			Write-Host ("Not playing sound [{0}] for user [{1}] because of invalid group." -f $sound.Trigger, $user)
			return $false
		}
	}# if ($sound.Group -ne "EVERYONE")
	
	# is this sound still on it's timeout
	$timesincelastplayed = New-TimeSpan -Start $sound.LastPlayed -End (Get-Date) | Select-Object -ExpandProperty TotalSeconds

	# if the time since it was last played is less than the sound Timeout value, return false
	if ($timesincelastplayed -lt $sound.Timeout)
	{
		Write-Host ("Not playing sound [{0}] for user [{1}] because it is still on cooldown [Seconds {2} / Cooldown {3}]." -f $sound.Trigger, $user, $timesincelastplayed, $sound.Timeout)
		return $false
	}

	# if the number of plays left is 0
	if ($sound.NumberOfPlays -eq 0)
	{
		Write-Host ("Not playing sound [{0}] for user [{1}] becasuse Number of Plays is at 0." -f $sound.Trigger, $user)
		return $false
	}

	# if we got here, then everything is good to go
	return $true
}# function Can-PlayTwitchSound

# new arraylist to hold sounds
$TwitchSounds = New-Object System.Collections.ArrayList

# initial import CSV information and process it
$csv = Import-Csv $sourcecsv

foreach ($entry in $csv)
{
	$obj = New-Object TwitchSound -ArgumentList $entry
	$TwitchSounds.Add($obj) | Out-Null
}

# connecting to Twitch chat
$socket = New-Object System.Net.Sockets.TcpClient( "irc.chat.twitch.tv", 6667 )
$stream = $socket.GetStream()
$buffer = New-Object System.Byte[] 2048
$encode = New-Object System.Text.utf8Encoding
$writer = New-Object System.IO.StreamWriter($stream)
$writer.AutoFlush = $true
$writer.WriteLine("PASS oauth:$oauthtoken")
$writer.WriteLine("NICK $yourchannelname")
$writer.WriteLine("CAP REQ :twitch.tv/tags twitch.tv/commands twitch.tv/membership");
$writer.WriteLine("JOIN #$yourchannelname")
# if you want the bot to announce itself in chat
#$writer.WriteLine("PRIVMSG #$yourchannelname : Hello everyone!");

Try
{
	# this repeats endlessly until you Ctrl + C out of it
	while ($true) 
	{
		$read = $stream.Read($buffer, 0, 2048)
		$lines = $encode.GetString($buffer, 0, $read).TrimEnd() -split [Environment]::NewLine

		foreach ($line in $lines) 
		{
			#Write-Host $line
			# ping pong required by Twitch API to stay connected to chat
			if ($line.StartsWith("PING")) 
			{ 
				$writer.WriteLine("PONG" + $line.Substring(4)) 
			}

			# if a trigger word is detected in the line, get the TwitchSound object that triggered it
			if ($sound = $TwitchSounds | Where-Object {$line -match ('^.*?:[\w\d]+![\w\d]+@[\w\d]+\.tmi\.twitch\.tv PRIVMSG #[\w\d]+ :.*?{0}.*?$' -f $_.Trigger)})
			{
				# using text wizardry to get the triggering user's name
				$triggeringuser = $line -replace '^.*?:([\w\d]+)![\w\d]+@[\w\d]+\.tmi\.twitch\.tv PRIVMSG #[\w\d]+ :.*$','$1'
				
				# checking if the sound can be played
				if (Can-PlayTwitchSound -Sound $sound -User $triggeringuser)
				{
					Write-Host ("[{0}] Playing sound [{1}] by user [{2}]" -f (Get-Date), $sound.Trigger, $triggeringuser)
					$sound.playSound()
				}
			}# if ($sound = $TwitchSounds | Where-Object {$line -match ('^.*?:[\w\d]+![\w\d]+@[\w\d]+\.tmi\.twitch\.tv PRIVMSG #[\w\d]+ :.*?{0}.*?$' -f $_.Trigger)})
		}# foreach ($line in $lines) 
	}# while ($true)
}# Try
Finally 
{
	Write-Host ("Closing TCP connections.")
    if ( $writer ) { $writer.Close( ) }
    if ( $stream ) { $stream.Close( ) }
} 