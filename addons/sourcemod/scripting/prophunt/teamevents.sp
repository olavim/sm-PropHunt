
#include "prophunt/include/teamutils.inc"

// player team change pending
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

// disable team join messages
public Action Event_OnPlayerTeam_Pre(Handle event, const char[] name, bool dontBroadcast) {
    SetEventBroadcast(event, true);
    return Plugin_Continue;
}

// player joined team
public Action Event_OnPlayerTeam(Handle event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsClientConnected(client))
        return Plugin_Continue;

    int team = GetEventInt(event, "team");
    bool disconnect = GetEventBool(event, "disconnect");
    g_iClientTeam[client] = team;

    BlindClient(client, false);
    Client_SetFreezed(client, false);

    // Handle the thirdperson view values
    // terrors are always allowed to view players in thirdperson
    if (!IsFakeClient(client) && GetConVarInt(g_hForceCamera) == 1) {
        if (team == CS_TEAM_T)
            SendConVarValue(client, g_hForceCamera, "0");
        else
            SendConVarValue(client, g_hForceCamera, "1");
    }

    if (team < CS_TEAM_T) {
        int queueNumber = g_iHiderToSeekerQueue[client];
        g_iHiderToSeekerQueue[client] = NOT_IN_QUEUE;
        if (queueNumber != NOT_IN_QUEUE) {
            for (int i = 1; i <= MaxClients; i++) {
                if (i != client && g_iHiderToSeekerQueue[i] > queueNumber) {
                    g_iHiderToSeekerQueue[i]--;
                }
            }

            g_iHidersInSeekerQueue--;
        }
    }

    // Player joined spectator?
    if (!disconnect && team < CS_TEAM_T) {
        g_iGuaranteedCTTurns[client] = -1;

        // show weapons again
        SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
    }

    // Strip the player if joined T midround
    if (!disconnect && team == CS_TEAM_T && IsPlayerAlive(client)) {
        StripClientWeapons(client);
    }

    // Ignore, if Teambalance is disabled
    if (GetConVarFloat(cvar_CTRatio) == 0.0)
        return Plugin_Continue;

    if (team == CS_TEAM_CT) {
        g_iGuaranteedCTTurns[client] = GetConVarInt(cvar_GuaranteedCTTurns);
    } else {
        g_iGuaranteedCTTurns[client] = -1;
    }

    return Plugin_Continue;
}
