
#include "prophunt/include/teamutils.inc"

public Action Event_OnTeamChange(Handle event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    int team = GetEventInt(event, "toteam");
    int oldteam = GetClientTeam(client);

    int iCTCount = GetTeamClientCount(CS_TEAM_CT);
    int iTCount = GetTeamClientCount(CS_TEAM_T);

    if (team == CS_TEAM_CT)
        iCTCount++;
    else if (team == CS_TEAM_T)
        iTCount++;
    if (oldteam == CS_TEAM_CT)
        iCTCount--;
    else if (oldteam == CS_TEAM_T)
        iTCount--;

    ChangeTeam(iCTCount, iTCount);

    return Plugin_Continue;
}

public Action Event_OnPlayerTeam(Handle event, const char[] name, bool dontBroadcast) {
    int _client = GetClientOfUserId(GetEventInt(event, "userid"));
    PHClient client = GetPHClient(_client);

    int team = GetEventInt(event, "team");
    int oldteam = GetEventInt(event, "oldteam");
    bool disconnect = GetEventBool(event, "disconnect");
    SetEventBool(event, "silent", true);

    // Handle the thirdperson view values
    // terrors are always allowed to view players in thirdperson
    if (client && !IsFakeClient(client.index) && GetConVarInt(g_hForceCamera) == 1) {
        if (team == CS_TEAM_T)
            SendConVarValue(client.index, g_hForceCamera, "0");
        else
            SendConVarValue(client.index, g_hForceCamera, "1");
    }

    // Player disconnected?
    if (disconnect) {
        g_bCTToSwitch[client.index] = false;
        g_bTToSwitch[client.index] = false;
    }

    if (team < CS_TEAM_T) {
        int queueNumber = g_iHiderToSeekerQueue[client.index];
        g_iHiderToSeekerQueue[client.index] = NOT_IN_QUEUE;
        if (queueNumber != NOT_IN_QUEUE) {
            for (int i = 1; i <= MaxClients; i++) {
                if (i != client.index && g_iHiderToSeekerQueue[i] > queueNumber) {
                    g_iHiderToSeekerQueue[i]--;
                }
            }

            g_iHidersInSeekerQueue--;
        }
    }

    // Player joined spectator?
    if (!disconnect && team < CS_TEAM_T) {
        g_bCTToSwitch[client.index] = false;
        g_bTToSwitch[client.index] = false;
        g_iGuaranteedCTTurns[client.index] = -1;

        // Unblind and show weapons again
        SetEntProp(client.index, Prop_Send, "m_bDrawViewmodel", 1);
        BlindClient(client.index, false);

        client.SetFreezed(false);
    }

    // Strip the player if joined T midround
    if (!disconnect && team == CS_TEAM_T && client.isAlive) {
        StripClientWeapons(client.index);
    }

    // Ignore, if Teambalance is disabled
    if (GetConVarFloat(cvar_CTRatio) == 0.0)
        return Plugin_Continue;

    int iCTCount = GetTeamClientCount(CS_TEAM_CT);
    int iTCount = GetTeamClientCount(CS_TEAM_T);

    if (team == CS_TEAM_CT) {
        g_iGuaranteedCTTurns[client.index] = GetConVarInt(cvar_GuaranteedCTTurns);
    } else {
        g_iGuaranteedCTTurns[client.index] = -1;
    }

    if (team == CS_TEAM_CT)
        iCTCount++;
    else if (team == CS_TEAM_T)
        iTCount++;
    if (oldteam == CS_TEAM_CT)
        iCTCount--;
    else if (oldteam == CS_TEAM_T)
        iTCount--;

    PrintToServer("Debug: PlayerTeam");

    // GetTeamClientCount() doesn't handle the teamchange we're called for in player_team,
    // so wait two frames to update the counts
    ChangeTeam(iCTCount, iTCount);

    return Plugin_Continue;
}

