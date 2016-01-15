# PropHunt
### A SourceMod plugin for CS:GO

The game begins with a countdown: Counter-Terrorists, the seekers, are blinded and cannot move. During this time Terrorists, the hiders, choose a world model and try to hide themselves amongst the rubble of ~~de_dust2~~ the map being played.

Once the countdown is over, the seekers try to find and kill the hiders. Much like regular old hide and seek from our youth, if not for all the ungodly transforming into inanimate objects and murdering.

## Cvars

```
ph_freezects              Should CTs get freezed and blinded on spawn?    on/off (1 or 0)
ph_freezetime             How long should the CTs be freezed after spawn?    on/off (1 or 0)
ph_changelimit            How often a T is allowed to choose his model ingame?    on/off (1 or 0)
ph_changelimittime        How long should a T be allowed to change his model again after spawn?    on/off (1 or 0)
ph_autochoose             Should the plugin choose models for the hiders automatically?    on/off (1 or 0)
ph_whistle                Are terrorists allowed to whistle?    on/off (1 or 0)
ph_whistle_times          How many times a hider is allowed to whistle per round?    on/off (1 or 0)
ph_whistle_seeker         Allow CTs to enforce T whistle?    on/off (1 or 0)
ph_hider_win_fargs        How many frags should surviving terrorists gain?    on/off (1 or 0)
ph_slay_seekers           Should we slay all seekers on round end and there are still some hiders alive?    on/off (1 or 0)
ph_hp_seeker_enable       Should CT lose HP when shooting?    on/off (1 or 0)
ph_hp_seeker_dec          How much hp should a CT lose on shooting?    on/off (1 or 0)
ph_hp_seeker_inc          How much hp should a CT gain when hitting a hider?    on/off (1 or 0)
ph_hp_seeker_inc_shotgun  How much hp should a CT gain when hitting a hider with shotgun?    on/off (1 or 0)
ph_hp_seeker_bonus        How much hp should a CT gain when killing a hider?    on/off (1 or 0)
ph_hiderspeed             Hiders' speed    on/off (1 or 0)
ph_disable_ducking        Disable ducking (crouching)    on/off (1 or 0)
ph_auto_thirdperson       Should thirdperson view be set automatically for hiders on round start    on/off (1 or 0)
ph_hider_freeze_mode      0: Disables /freeze command for hiders, 1: Only freeze on position, be able to move camera, 2: Freeze completely (no cameramovements)    on/off (1 or 0)
ph_hide_blood             Hide blood on hider damage?    on/off (1 or 0)
ph_show_hidehelp          Show helpmenu explaining the game on first player spawn?    on/off (1 or 0)
ph_ct_ratio               The ratio of hiders to 1 seeker. 0 to disables teambalance.    on/off (1 or 0)
ph_disable_use            Disable CTs pushing things?    on/off (1 or 0)
ph_hider_freeze_inair     Are hiders allowed to freeze in the air?    on/off (1 or 0)
ph_hide_player_locations  Hide the location info shown next to players name on voice chat and teamsay?    on/off (1 or 0)
ph_auto_freeze_time       Time after which stationary players should freeze automatically    on/off (1 or 0)
ph_guaranteed_ct_turns    Turns after which CTs might be switched to the T side    on/off (1 or 0)
ph_knifespeed             Running speed when holding a knife (multiplier)    on/off (1 or 0)
```

## Version history

**v1.0**

Initial release.
