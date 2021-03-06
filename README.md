# PropHunt
### A SourceMod plugin for CS:GO

The game begins with a countdown: Counter-Terrorists, the seekers, are blinded and cannot move. During this time Terrorists, the hiders, choose a world model and try to hide themselves amongst the rubble of ~~de_dust2~~ the map being played.

Once the countdown is over, the seekers try to find and kill the hiders. Much like regular old hide and seek from our youth, if not for all the ungodly transforming into toilets and murdering.

---

Although this plugin has essentially been written from scratch, many snippets originate from the Hide and Seek plugin written (and abandoned) by [SelaX](https://forums.alliedmods.net/member.php?u=36536).

## Chat Commands

```
/rules                    Show instructions on how to play.
/hide /prop /model        Opens a menu with different models to choose as a hider.
/tp /third /thirdperson   Toggles thirdperson view for hiders
/whistle                  Plays a random sound from the hider's position to give the seekers a hint.
/whoami                   Displays the current model description in chat.
/freeze                   Toggles freezed state for hiders.
/ct                       Requests a switch to the seeking side.
```

## Cvars

- Here `on/off` means a variable accepts the values `1` (on) and `0` (off).
- The notation `0+` means a variable accepts integer values greater than or equal to 0, such as `0`, `1`, `255`...
- The notation `0.0+` again means a variable accepts floating point values greater than or equal to 0, such as `0`, `0.5`, `1`, `19.24`...
- `0-2` means a variable accepts integer numbers greater than or equal to 0, and smaller than or equal to 2, namely `0`, `1` and `2`.
- `String` means a variable accepts strings.

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
ph_show_help        	    on/off	Show helpmenu explaining the game on first player spawn
ph_ct_ratio             	0+		The ratio of hiders to 1 seeker - 0: disable team balance
ph_disable_use          	on/off	Disable seekers' use key
ph_hider_freeze_inair   	on/off	Allow hiders to freeze in the air
ph_hide_player_locations	on/off	Hide location shown next to a player's name on voice chat and teamsay
ph_auto_freeze_time     	0+		Amount of time after which stationary players should freeze automatically. 0 disables automatic freezing
ph_guaranteed_ct_turns  	1+		Number of turns after which seekers might be switched to the hiders' side
ph_knifespeed           	0.0+	Running speed when holding a knife (multiplier)
ph_limitspec                0-2     Who dead players are allowed to spectate - 0: Anyone, 1: Own team only, 2: CT only
ph_include_default_models   on/off  0: Include default models when one for current map doesn't exist, 1: Always include default models
ph_force_periodic_whistle   0+      Periodically, every x seconds, force a random hider to whistle - 0: disable periodic whistles.
ph_periodic_whistle_delay   0+      Number of seconds for the first periodic whistle, if they are enabled.
ph_turns_to_scramble        0+      Scramble teams every x turns. 0: disable scrambling. Disables the /ct command if enabled.

# not in any release, but included in latest commit:

ph_categorize_models        on/off  Enable splitting the model menu into categories.
ph_default_category         String  If categories are enabled, uncategorized models are put under this category.
```

## Protected server cvars

There are a number of cvars that are "protected", that is, the server enforces their values to ensure fluid gameplay.

```
mp_flashlight                       0
sv_footsteps                        0
mp_limitteams                       0
mp_autoteambalance                  0
mp_freezetime                       0
sv_nonemesis                        1
sv_nomvp                            1
sv_nostats                          1
mp_playerid                         1
sv_allowminmodels                   0
sv_turbophysics                     1
mp_teams_unbalance_limit            0
mp_show_voice_icons                 0
spec_freeze_time                    -1
mp_default_team_winner_no_objective 3   // might be removed
```

## Installation

This plugin has been tested (and built) on Metamod:Source `1.10.6` and SourceMod `1.7.3`, so go and install those if you haven't already. Earlier versions *might* work, I wouldn't know, but definitely don't count on it.

If you download this project zipped, just extract everything to your server's CS:GO install dir. If not... just make sure the following files are in correct place:

- `addons/sourcemod/plugins/prophunt.smx`
- `addons/sourcemod/configs/prophunt/default.cfg`
- `addons/sourcemod/translations/plugin.prophunt.txt`
- `sound/prophunt/` and all the files inside.

If everything seems to be in order, go and fire up the server! A config file should have been generated in
`cfg/sourcemod/plugin.prophunt.cfg`. Edit it as you see fit and restart your server to see the changes.

## Configuring model lists

You may specify what models are available in each map. There is also a special default listing, which will be applied to all maps in addition to the map-specific listings (will be further configurable in the future).

For example, if you want to make a listing for, say, `de_inferno`, you would make a file `de_inferno.cfg` in `addons/sourcemod/configs/prophunt/`. The default file is located in that same folder, and is named `default.cfg`.

All listing should obey the following format:

```
"Models"
{
    <model-path>  <model-nickname>
    ...
}
```

for example:

```
"Models
{
    "props_c17\oildrum001"          "Oil Drum"
    "props\de_dust\grainbasket01a"  "Grain Basket (closed)"
    ...
}
```

To add props yourself you will need to find out the paths. I used the Hammer editor (CS:GO SDK) to get the few that you can find in `default.cfg` and `de_dust2.cfg`. I'd appreciate if you shared your listings with me so I can update mine.

**IMPORTANT!** Always specify the model paths using backslashes (`\`) ! Forward slashes do not work, and will most likely invalidate the whole file.


#### Includes

You can also specify model list includes. Including works by specifying model list files inside an `#include` section, like so:

```
"Models"
{
    ...
    
    "#include" {
        "signs.cfg" {
            "recurse" "yes"
        }
    }
}
```

Includes are relative to `addons/sourcemod/configs/prophunt/maps/`, so if you had a file `signs.cfg` in the `maps` folder, you would only write `signs.cfg` in the `#include` section, like in the example above.

The `recurse` key specifies whether or not includes in the included file should be included as well. Valid values are `yes` and `no`.

### Categories

**Not in any release, but included in the latest commit.**

If enabled (see **ph_categorize_models**), models can be categorized and split among multiple menus. This may be beneficial if there are a lot of models. Categories are defined like so:

```
"Models"
{
    "Category A" {
        "props_c17\oildrum001"          "Oil Drum"
        "props\de_dust\grainbasket01a"  "Grain Basket (closed)"
    }
    
    "Category B" {
        "props\de_dust\grainbasket01b"  "Grain Basket (opened)"
    }
    
    ...
}
```

Any models that are not in a category will be put under the default category (see **ph_default_category**).

## Configuring whistles

Custom whistles may be specified by modifying `addons/sourcemod/configs/whistles.cfg`. To add a whistle, simply specify its path on a new line. The paths of the whistles should be relative to the `sound` directory (in the root directory of your CS:GO installation), so that if you had the sound file `sound/awesome/brilliant.mp3`, you would specify it just as `awesome/brilliant.mp3`.

Additionally, only **mp3** sound files seem work, except if they are in-game sounds. You can find the paths to in-game sounds from files such as `game_sounds.txt`, `game_sounds_ambient_generic.txt`, etc., which are located in `scripts` folder in your CS:GO installation's root folder.

## Compiling

You may want to add your own flavor to the plugin. Although I'd prefer you would make suggestions or downright contribute directly to this project, but you wouldn't want to do that, now would you.

And I'll lose interest in this plugin and abandon it to hell in no time anyway, so I might as well make my testimony now: instructions on how to compile to everyone!

First of all, just like the installation instructions **above**, you need Metamod:Source `1.10.6` and SourceMod `1.7.3` blah blah. Then you clone this repository to your workstation of choice and compile `prophunt.sp`. That's it. The file automatically links all the files together and makes a magical `prophunt.smx` to your `scripting/compiled` directory.

Elementary, dear Watson.

## Version history

**v1.0.5.1**

- Fixed CTs not being unfreezed.
- Fixed scoring and winner announcement.
- Fixed some teambalancing issues.
- Fixed some issues with periodic whistles.
- New phrases in the translation file.

**v1.0.5**

- Quick fixes from last release.
- New cvar: **ph_turns_to_scramble**

**v1.0.4**

- Fixed teambalancing issues.
- Fixed team scoring when terrorists win by time.
- Fixed terrorist frags resetting on round start when they win by time.
- New cvar: **ph_force_periodic_whistle**
- New cvar: **ph_periodic_whistle_delay**

**v1.0.3.1**

- Fixed players being invisible after switching from the hiding team to the seeking one.

**v1.0.3**

- Introduced `includes` to model lists. Further information in the **Configuring model lists** section.
- New cvar: **ph_include_default_models**

**v1.0.2**

- Fixed hiders not dying.
- New cvar: **ph_limitspec** - Restrict spectating to: Anyone (0), own team (1) or CT (2).

**v1.0.1**

- Configurable sounds.
- Changed the `addons/sourcemod/configs` folder structure.

**v1.0**

- Initial release.
