#include "prophunt/include/phclient.inc"
#include "prophunt/include/clientutils.inc"
#include "prophunt/include/utils.inc"

public void OnClientPutInServer(int client) {

    // Hook weapon pickup
    SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
    SDKHook(client, SDKHook_WeaponCanSwitchTo, OnWeaponCanUse);
    SDKHook(client, SDKHook_WeaponEquip, OnWeaponCanUse);
    SDKHook(client, SDKHook_WeaponSwitch, OnWeaponCanUse);
    SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);

    // Hook attackings to hide blood
    SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);

    // Hide player location info
    SDKHook(client, SDKHook_PostThinkPost, Hook_OnPostThinkPost);
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage,
        int &damagetype, int &weapon, float damageForce[3], float damagePosition[3]) {
    if (damagetype & DMG_BURN) {
        Entity_SetMovementSpeed(client, 0.5);
        CreateTimer(3.0, Timer_RestoreSpeed, client);
    }

    return Plugin_Continue;
}

public void OnWeaponSwitchPost(int client, int weapon) {
    char wpn[24];
    GetClientWeapon(client, wpn, 24);
    if (StrEqual(wpn, "weapon_knife"))
        Entity_SetMovementSpeed(client, GetConVarFloat(cvar_KnifeSpeed));
    else
        Entity_SetMovementSpeed(client, 1.0);
}

public void OnClientDisconnect(int client) {

    // set the default values for cvar checking
    g_bInThirdPersonView[client] = false;
    g_iModelChangeCount[client] = 0;
    g_bIsCTWaiting[client] = false;
    g_iWhistleCount[client] = 0;
    g_iGuaranteedCTTurns[client] = NOT_IN_QUEUE;

    UnsetHandle(g_hAllowModelChangeTimer[client]);
    UnsetHandle(g_hFreezeCTTimer[client]);
    UnsetHandle(g_hAutoFreezeTimers[client]);

    g_bAllowModelChange[client] = true;
    g_bFirstSpawn[client] = true;
    g_iLowModelSteps[client] = 0;
    g_iPlayerScore[client] = 0;

    // Teambalance
    g_iClientTeam[client] = CS_TEAM_SPECTATOR;

    int iCTCount = GetTeamClientCount(CS_TEAM_CT);
    int iTCount = GetTeamClientCount(CS_TEAM_T);
    ChangeTeam(iCTCount, iTCount);

    // AFK check
    for (int i = 0; i < 3; i++) {
        g_fSpawnPosition[client][i] = 0.0;
    }

    SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
    SDKUnhook(client, SDKHook_WeaponCanSwitchTo, OnWeaponCanUse);
    SDKUnhook(client, SDKHook_WeaponEquip, OnWeaponCanUse);
    SDKUnhook(client, SDKHook_WeaponSwitch, OnWeaponCanUse);
    SDKUnhook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
    SDKUnhook(client, SDKHook_TraceAttack, OnTraceAttack);
    SDKUnhook(client, SDKHook_PostThinkPost, Hook_OnPostThinkPost);
    SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);

    Entity_RemoveChild(client);
    g_iEntities[client] = 0;
}

// prevent players from ducking
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3],
        int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2]) {
    //PrintToServer("client: %d index: %d", view_as<int>(client), client.index);

    int iInitialButtons = buttons;

    PreventCTFire(client, buttons);

    //Freeze and rotation fix
    Client_UpdateFakeProp(client);

    bool moving = buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT || buttons & IN_JUMP;
    if (IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_T) {
        if (IsClientFreezed(client) && moving) {
            Cmd_Freeze(client, 0);
        }

        float AutoFreezeTime = GetConVarFloat(cvar_AutoFreezeTime);
        if (moving && g_hAutoFreezeTimers[client] != INVALID_HANDLE) {
            UnsetHandle(g_hAutoFreezeTimers[client]);
        } else if (AutoFreezeTime && !IsClientFreezed(client) && g_hAutoFreezeTimers[client] == INVALID_HANDLE) {
            g_hAutoFreezeTimers[client] = CreateTimer(AutoFreezeTime, Timer_AutoFreezeClient, client, TIMER_FLAG_NO_MAPCHANGE);
        }
    }

    // disable ducking for everyone
    if (GetConVarBool(cvar_DisableDucking) && buttons & IN_DUCK)
        buttons &= ~IN_DUCK;

    // disable use for everyone
    if (GetConVarBool(cvar_DisableUse) && buttons & IN_USE)
        buttons &= ~IN_USE;

    if (iInitialButtons != buttons)
        return Plugin_Changed;

    return Plugin_Continue;
}

public Action OnWeaponCanUse(int client, int weapon) {

    // Allow only CTs to use a weapon
    if (IsClientInGame(client) && GetClientTeam(client) != CS_TEAM_CT) {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

// balance life hit when using shotguns
public Action Event_ItemEquip(Handle event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    int type = GetEventInt(event, "weptype");
    if (type == WEAPON_SHOTGUN) {
        g_bShotgun[client] = true;
    } else g_bShotgun[client] = false;

    return Plugin_Continue;
}

// block blood
public Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup) {
    if (GetClientTeam(victim) == CS_TEAM_T) {
        int remainingHealth = GetClientHealth(victim) - RoundToFloor(damage);

        if (GetConVarBool(cvar_HPSeekerEnable) && attacker > 0 && attacker <= MaxClients && IsPlayerAlive(attacker)) {
            int decrease = GetConVarInt(cvar_HPSeekerDec);

            if (g_bShotgun[attacker])
                SetEntityHealth(attacker, GetClientHealth(attacker) + GetConVarInt(cvar_HPSeekerIncShotgun) + decrease);
            else SetEntityHealth(attacker, GetClientHealth(attacker) + GetConVarInt(cvar_HPSeekerInc) + decrease);

            // give bonus health if the hider died
            if (remainingHealth < 0)
                SetEntityHealth(attacker, GetClientHealth(attacker) + GetConVarInt(cvar_HPSeekerBonus));
        }

        if (remainingHealth < 0) {
            return Plugin_Continue;
        }

        if (GetConVarBool(cvar_HideBlood)) {
            SetEntityHealth(victim, remainingHealth);
            return Plugin_Handled;
        }
    }

    return Plugin_Continue;
}

public void Hook_OnPostThinkPost(int client) {
    if (GetConVarBool(cvar_HidePlayerLocation) && GetClientTeam(client) == CS_TEAM_T)
        SetEntPropString(client, Prop_Send, "m_szLastPlaceName", "");
}

public Action Event_OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    int team = GetClientTeam(client);
    if (team <= CS_TEAM_SPECTATOR || !IsPlayerAlive(client))
        return Plugin_Continue;

    if (team == CS_TEAM_T) {
        HandleTSpawn(client);
    } else if (team == CS_TEAM_CT) {
        HandleCTSpawn(client);
    }

    CreateTimer(0.5, Timer_SaveClientSpawnPosition, client, TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(0.0, Timer_RemoveClientRadar, client, TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Continue;
}

public Action Event_OnWeaponFire(Handle event, const char[] name, bool dontBroadcast) {
    if (!GetConVarBool(cvar_HPSeekerEnable) || g_bRoundEnded)
        return Plugin_Continue;

    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    int decreaseHP = GetConVarInt(cvar_HPSeekerDec);
    int clientHealth = GetClientHealth(client);

    if ((clientHealth - decreaseHP) > 0) {
        SetEntityHealth(client, (clientHealth - decreaseHP));
    } else {
        CreateTimer(0.1, Timer_SlayClient, client, TIMER_FLAG_NO_MAPCHANGE);
    }

    return Plugin_Continue;
}

public Action Event_OnPlayerDeath_Pre(Handle event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    SendConVarValue(client, g_hForceCamera, "0");
    SetThirdPersonView(client, false);
    return Plugin_Continue;
}

public Action Event_OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (!IsValidEntity(client))
        return Plugin_Continue;

    Client_SetFreezed(client, false);
    //SetEntityMoveType(client.index, MOVETYPE_OBSERVER);

    // remove ragdolls
    int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
    if (ragdoll < 0)
        return Plugin_Continue;

    RemoveEdict(ragdoll);

    UnFreezePlayer(client);

    UnsetHandle(g_hFreezeCTTimer[client]);
    UnsetHandle(g_hAutoFreezeTimers[client]);

    CreateTimer(0.1, Timer_SetObserv, client, TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(0.1, Timer_CheckObservers, client, TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Continue;
}

public Action Timer_RestoreSpeed(Handle timer, int client) {
    if (!IsClientInGame(client))
        return Plugin_Stop;

    Entity_SetMovementSpeed(client, 1.0);
    return Plugin_Handled;
}

public Action Timer_RemoveClientRadar(Handle timer, int client) {
    if (!IsClientInGame(client))
        return Plugin_Stop;

    RemoveClientRadar(client);
    return Plugin_Continue;
}

public Action Timer_AutoFreezeClient(Handle handle, int client) {
    g_hAutoFreezeTimers[client] = INVALID_HANDLE;

    if (IsClientInGame(client)) {
        return Plugin_Stop;
    }

    if (!IsClientFreezed(client))
        Cmd_Freeze(client, 0);

    return Plugin_Continue;
}

public Action Timer_SlayClient(Handle timer, int client) {
    if (!IsClientInGame(client))
        return Plugin_Stop;

    SlayClient(client);
    return Plugin_Continue;
}

public Action Timer_FreezePlayer(Handle timer, int client) {
    g_hFreezeCTTimer[client] = INVALID_HANDLE;

    if (!IsClientInGame(client) || !IsPlayerAlive(client) || !g_bIsCTWaiting[client])
        return Plugin_Stop;

    FreezePlayer(client);
    return Plugin_Continue;
}

// Make sure CTs have knifes
public Action Timer_CheckClientHasKnife(Handle timer, int client) {
    if (!IsClientInGame(client))
        return Plugin_Stop;

    CheckClientHasKnife(client);
    return Plugin_Continue;
}

public Action Timer_SaveClientSpawnPosition(Handle timer, int client) {
    if (!IsClientInGame(client))
        return Plugin_Stop;

    SaveClientSpawnPosition(client);
    return Plugin_Continue;
}

// show all players a countdown
public Action Timer_ShowClientCountdown(Handle timer, int freezeTime) {
    int seconds = freezeTime - GetTime() + g_iFirstCTSpawn;
    PrintCenterTextAll("%d", seconds);
    if (seconds <= 0) {
        g_hShowCountdownTimer = INVALID_HANDLE;
        return Plugin_Stop;
    }

    g_hShowCountdownTimer = CreateTimer(0.5, Timer_ShowClientCountdown, freezeTime, TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Continue;
}

static void HandleTSpawn(int client) {

    // set the mp_forcecamera value correctly, so he can use thirdperson again
    if (!IsFakeClient(client) && GetConVarInt(g_hForceCamera) == 1)
        SendConVarValue(client, g_hForceCamera, "0");

    // reset model change count
    g_iModelChangeCount[client] = 0;
    g_bInThirdPersonView[client] = false;
    g_bAllowModelChange[client] = true;
    UnsetHandle(g_hAllowModelChangeTimer[client]);
    UnsetHandle(g_hFreezeCTTimer[client]);

    if (g_bIsCTWaiting[client]) {
        g_bIsCTWaiting[client] = false;
        UnFreezePlayer(client);
    }

    // set the speed
    SetEntDataFloat(client, g_flLaggedMovementValue, GetConVarFloat(cvar_HiderSpeed), true);

    // Assign a model to bots immediately and disable all menus or timers.
    if (IsFakeClient(client))
        g_hAllowModelChangeTimer[client] = CreateTimer(0.1, DisableModelMenu, client, TIMER_FLAG_NO_MAPCHANGE);
    else {
        SetModelChangeTimer(client);

        // Set them to thirdperson automatically
        if (GetConVarBool(cvar_AutoThirdPerson))
            SetThirdPersonView(client, true);

        OfferClientModel(client);
    }

    g_iWhistleCount[client] = 0;
    Client_SetFreezed(client, false);

    if (g_iFirstTSpawn == 0)
        g_iFirstTSpawn = GetTime();

    if (GetConVarBool(cvar_FreezeCTs))
        PrintToChat(client, "%s%t", PREFIX, "seconds to hide", RoundToFloor(GetConVarFloat(cvar_FreezeTime)));
    else
        PrintToChat(client, "%s%t", PREFIX, "seconds to hide", 0);

    SetRandomModel(client);
}

static void HandleCTSpawn(int client) {
    if (!IsPlayerAlive(client))
        return;

    SetThirdPersonView(client, false);
    if (!IsFakeClient(client))
        SendConVarValue(client, g_hForceCamera, "1");

    int currentTime = GetTime();
    float freezeTime = GetConVarFloat(cvar_FreezeTime);

    // dont keep late spawning cts blinded longer than the others :)
    if (g_iFirstCTSpawn == 0) {
        if (g_hShowCountdownTimer != INVALID_HANDLE) {
            UnsetHandle(g_hShowCountdownTimer);
        } else if (GetConVarBool(cvar_FreezeCTs)) {

            // show time in center
            g_hShowCountdownTimer = CreateTimer(0.01, Timer_ShowClientCountdown, RoundToFloor(GetConVarFloat(cvar_FreezeTime)), TIMER_FLAG_NO_MAPCHANGE);
        }

        g_iFirstCTSpawn = currentTime;
    }

    // only freeze spawning players if the freezetime is still running.
    float elapsedFreezeTime = float(currentTime - g_iFirstCTSpawn);
    if (GetConVarBool(cvar_FreezeCTs) && elapsedFreezeTime < freezeTime) {
        g_bIsCTWaiting[client] = true;
        CreateTimer(0.05, Timer_FreezePlayer, client, TIMER_FLAG_NO_MAPCHANGE);

        // Start freezing player
        g_hFreezeCTTimer[client] = CreateTimer(2.0, Timer_FreezePlayer, client, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);

        // Start Unfreezing player
        float timerDelay = freezeTime - elapsedFreezeTime;
        PrintToChat(client, "%s%t", PREFIX, "Wait for t to hide", RoundToFloor(timerDelay));
    }

    // show help menu on first spawn
    if (GetConVarBool(cvar_ShowHelp) && g_bFirstSpawn[client]) {
        Cmd_DisplayHelp(client, 0);
        g_bFirstSpawn[client] = false;
    }

    // Make sure CTs have a knife
    CreateTimer(2.0, Timer_CheckClientHasKnife, client, TIMER_FLAG_NO_MAPCHANGE);

    g_bShowFakeProp[client] = true;
}
