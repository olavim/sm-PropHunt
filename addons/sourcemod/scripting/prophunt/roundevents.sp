
#include "prophunt/include/roundutils.inc"

public Action Event_OnRoundStart(Handle event, const char[] name, bool dontBroadcast) {
    g_bRoundEnded = false;

    // When disabling +use or "e" button open all doors on the map and keep them opened.
    bool isUseDisabled = GetConVarBool(cvar_DisableUse);

    RemoveGameplayEdicts();
    if (isUseDisabled)
        OpenDoors();

    for (int i = 1; i <= MaxClients; i++) {
        if (g_iHiderToSeekerQueue[i] != NOT_IN_QUEUE) {
            PrintToChat(i, "%s Turns until team switch: %d", PREFIX, SimulateTurnsToSeeker(g_iHiderToSeekerQueue[i]));
        }
    }

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

// give terrorists frags
public Action Event_OnRoundEnd(Handle event, const char[] name, bool dontBroadcast) {

    // round has ended. used to not decrease seekers hp on shoot
    g_bRoundEnded = true;

    g_iFirstCTSpawn = 0;
    g_iFirstTSpawn = 0;

    UnsetTimer(g_hShowCountdownTimer);
    UnsetTimer(g_hRoundTimeTimer);
    UnsetTimer(g_hWhistleDelay);

    int winnerTeam = GetEventInt(event, "winner");

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

    ManageCTQueue();

    //PrintToServer("Debug: RoundEnd");

    // Switch the flagged players' teams
    SwitchTeams();

    return Plugin_Continue;
}

