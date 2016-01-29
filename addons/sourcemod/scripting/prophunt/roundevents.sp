
#include "prophunt/include/roundutils.inc"

public Action Event_OnRoundStart(Handle event, const char[] name, bool dontBroadcast) {
    g_bRoundEnded = false;
/*
    // internal score
    CS_SetTeamScore(CS_TEAM_CT, g_iScoreCT);
    CS_SetTeamScore(CS_TEAM_T, g_iScoreT);

    // update visually as well
    SetTeamScore(CS_TEAM_CT, g_iScoreCT);
    SetTeamScore(CS_TEAM_T, g_iScoreT);
*/
    // When disabling +use or "e" button open all doors on the map and keep them opened.
    bool isUseDisabled = GetConVarBool(cvar_DisableUse);

    RemoveGameplayEdicts();
    if (isUseDisabled)
        OpenDoors();

    for (int i = 1; i <= MaxClients; i++) {
        if (g_iHiderToSeekerQueue[i] != NOT_IN_QUEUE) {
            PrintToChat(i, "%s Turns until team switch: %d", PREFIX, SimulateTurnsToSeeker(g_iHiderToSeekerQueue[i]));
        }

        if (IsClientConnected(i)) {
            SetEntProp(i, Prop_Data, "m_iFrags", g_iPlayerScore[i]);
        }
    }

    CreateTimer(GetConVarFloat(cvar_FreezeTime), Timer_AfterFreezeTime, _, TIMER_FLAG_NO_MAPCHANGE); 

    return Plugin_Continue;
}

// make sure terrorists win on round time end
public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason) {
    if (reason != CSRoundEnd_TerroristWin) {
        for (int i = 1; i <= MaxClients; i++) {
            if (IsClientConnected(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T) {
                reason = CSRoundEnd_TerroristWin; 
                return Plugin_Changed;
            }
        }
    }

    return Plugin_Continue;
}

public Action Event_OnRoundEnd(Handle event, const char[] name, bool dontBroadcast) {

    // round has ended. used to not decrease seekers hp on shoot
    g_bRoundEnded = true;

    g_iFirstCTSpawn = 0;
    g_iFirstTSpawn = 0;

    UnsetHandle(g_hShowCountdownTimer);
    UnsetHandle(g_hRoundTimeTimer);
    UnsetHandle(g_hWhistleDelay);
    UnsetHandle(g_hPeriodicWhistleTimer);

    ManageCTQueue();

    //PrintToServer("Debug: RoundEnd");

    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientConnected(i))
            g_iPlayerScore[i] = GetEntProp(i, Prop_Data, "m_iFrags");
    }

    // balance teams
    if (GetConVarFloat(cvar_CTRatio) > 0.0) {
        ChangeTeam(GetTeamClientCount(CS_TEAM_CT), GetTeamClientCount(CS_TEAM_T));
    }

    // Switch the flagged players' teams
    SwitchTeams();

    return Plugin_Continue;
}

// give terrorists frags
public Action Event_OnRoundEnd_Pre(Handle event, const char[] name, bool dontBroadcast) {
    int winnerTeam = GetEventInt(event, "winner");
    bool aliveTs, aliveCTs;

    if (winnerTeam == CS_TEAM_T) {
        int increaseFrags = GetConVarInt(cvar_HiderWinFrags);
        bool aliveTerrorists = GiveAliveTerroristsFrags(increaseFrags);

        if (aliveTerrorists) {
            PrintToChatAll("%s%t", PREFIX, "got frags", increaseFrags);
        }

        if (GetConVarBool(cvar_SlaySeekers)) {
            SlayTeam(CS_TEAM_CT);
        }
    }

    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientConnected(i) && IsPlayerAlive(i)) {
            if (GetClientTeam(i) == CS_TEAM_T)
                aliveTs = true;
            else aliveCTs = true;
        }
    }

    if (aliveCTs && aliveTs) {
        // internal score
        CS_SetTeamScore(CS_TEAM_CT, CS_GetTeamScore(CS_TEAM_CT) - 1);
        CS_SetTeamScore(CS_TEAM_T, CS_GetTeamScore(CS_TEAM_T) + 1);

        // update visually as well
        SetTeamScore(CS_TEAM_CT, CS_GetTeamScore(CS_TEAM_CT));
        SetTeamScore(CS_TEAM_T, CS_GetTeamScore(CS_TEAM_T));
    }

    return Plugin_Continue;
}

public Action Timer_AfterFreezeTime(Handle timer) { 
    int whistleDelay = GetConVarInt(cvar_PeriodicWhistleDelay);
    if (GetConVarBool(cvar_ForcePeriodicWhistle)) {
        g_hPeriodicWhistleTimer = CreateTimer(FloatDiv(float(whistleDelay), 2.0), Timer_MakeRandomClientWhistle, true, TIMER_FLAG_NO_MAPCHANGE);
    }

    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i))
            UnFreezePlayer(i);
    }
}

public Action Timer_MakeRandomClientWhistle(Handle timer, bool firstcall) { 
    float repeatDelay = FloatDiv(GetConVarFloat(cvar_ForcePeriodicWhistle), 2.0);

    if (firstcall) {
        PrintToChatAll("%s%d seconds until someone whistles!", PREFIX, RoundToFloor(repeatDelay));
    } else {
        int client = GetRandomClient(CS_TEAM_T);
        MakeClientWhistle(client);

        char name[128];
        GetClientName(client, name, sizeof(name));
        PrintToChatAll("%sIt was %s's time to whistle!", PREFIX, name);
    }

    g_hPeriodicWhistleTimer = CreateTimer(repeatDelay, Timer_MakeRandomClientWhistle, !firstcall, TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Continue;
}
