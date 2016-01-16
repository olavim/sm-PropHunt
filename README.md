# PropHunt
### A SourceMod plugin for CS:GO

The game begins with a countdown: Counter-Terrorists, the seekers, are blinded and cannot move. During this time Terrorists, the hiders, choose a world model and try to hide themselves amongst the rubble of ~~de_dust2~~ the map being played.

Once the countdown is over, the seekers try to find and kill the hiders. Much like regular old hide and seek from our youth, if not for all the ungodly transforming into toilets and murdering.

## Cvars

- Here `on/off` means a variable accepts the values `1` (on) and `0` (off).
- The notation `0+` means a variable accepts integer values greater than or equal to 0, such as `0`, `1`, `255`...
- The notation `0.0+` again means a variable accepts floating point values greater than or equal to 0, such as `0`, `0.5`, `1`, `19.24`...
- `0-2` means a variable accepts integer numbers greater than or equal to 0, and smaller than or equal to 2, namely `0`, `1` and `2`.

Any additional terminological magic you might encounter below should be possible to be deduced from the rules above.

```
ph_freezects            	on/off	Freeze and blind seekers on round start
ph_freezetime           	0+		Amount of time the seekers are freezed
ph_changelimit          	0+		Number of times a hider is allowed to change his model
ph_changelimittime      	0.0+	Amount of time a hider is allowed to change his model
ph_autochoose           	on/off	Choose random models for hiders at round start
ph_whistle              	on/off	Allow hiders to whistle
ph_whistle_times        	0+		Number of times a hider is allowed to whistle (per round)
ph_whistle_seeker       	on/off	Allow seekers to enforce hiders to whistle
ph_hider_win_fargs      	0-10	Number of kills surviving hiders receive on round end
ph_slay_seekers         	on/off	Slay all seekers on round end if alive hiders remain
ph_hp_seeker_enable     	on/off	Seekers lose damage when firing anything not-hider 
ph_hp_seeker_dec        	0+		Amount of hp a seeker loses on shooting
ph_hp_seeker_inc        	0+		Amount of hp a seeker gains when shooting a hider
ph_hp_seeker_inc_shotgun	0+		Amount of hp a seeker gains when shooting a hider with a shotgun
ph_hp_seeker_bonus      	0+		Amount of hp a seeker gains when killing a hider
ph_hiderspeed           	0.5+	Hiders' movement speed
ph_disable_ducking      	on/off	Disable ducking (crouching)
ph_auto_thirdperson     	on/off	Set thirdperson view for hiders automatically on round start
ph_hider_freeze_mode    	0-2		Set the /freeze command behaviour - 0: disable the command, 1: freeze on position, 2: freeze completely (no camera movements)
ph_hide_blood           	on/off	Hide hiders' blood when taking damage
ph_show_hidehelp        	on/off	Show helpmenu explaining the game on first player spawn
ph_ct_ratio             	0+		The ratio of hiders to 1 seeker - 0 disables team balance
ph_disable_use          	on/off	Disable seekers' use key
ph_hider_freeze_inair   	on/off	Allow hiders to freeze in the air
ph_hide_player_locations	on/off	Hide location shown next to a player's name on voice chat and teamsay
ph_auto_freeze_time     	0+		Amount of time after which stationary players should freeze automatically. 0 disables automatic freezing
ph_guaranteed_ct_turns  	1+		Number of turns after which seekers might be switched to the hiders' side
ph_knifespeed           	0.0+	Running speed when holding a knife (multiplier)
```

## Commands

```
/hide /hidemenu           Opens a menu with different models to choose as a hider.
/tp /third /thirdperson   Toggles thirdperson view for hiders
/+3rd                     Set to thirdperson view for hiders.
/-3rd                     Set to firstperson view for hiders.
/whistle                  Plays a random sound from the hider's position to give the seekers a hint.
/whoami                   Displays the current model description in chat.
/hidehelp                 Show instructions on how to play.
/freeze                   Toggles freezed state for hiders.
/ct                       Requests a switch to the seeking side.
```

## Natives

The plugin comes with a few native functions. And here's the list if you care...

```
file and doc:
addons/sourcemod/scripting/prophunt/include/phentity.inc

PHEntity
PHEntity.index
PHEntity.hasChild
PHEntity.child
PHEntity.GetOrigin
PHEntity.GetAbsAngles
PHEntity.GetVelocity
PHEntity.SetMoveType
PHEntity.SetMovementSpeed
PHEntity.SetChild
PHEntity.RemoveChild
PHEntity.AttachChild
PHEntity.DetachChild
PHEntity.Teleport
PHEntity.TeleportTo

file and doc:
addons/sourcemod/scripting/prophunt/include/phclient.inc

PHClient < PHEntity
PHClient.team
PHClient.isAlive
PHClient.isFreezed
PHClient.isConnected
PHClient.setFreezed
```

## Installation

This plugin has been tested (and built) on Metamod:Source `1.10.6` and SourceMod `1.7.3`, so go and install those if you haven't already. Earlier versions *might* work, I wouldn't know, but definitely don't count on it.

If you download this project zipped, just extract everything to your server's CS:GO install dir. If not... just make sure the folder hierarchy remains the same

## Version history

**v1.0**

Initial release.
