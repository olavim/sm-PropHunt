
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

    ChangeTeam(client, iCTCount, iTCount);

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
    ChangeTeam(client.index, iCTCount, iTCount);

    return Plugin_Continue;
}

public void SwitchTeams() {
    char sName[64];
    for (int i = 1; i <= MaxClients; i++) {
        if (g_bCTToSwitch[i]) {
            if (IsClientInGame(i)) {
                GetClientName(i, sName, sizeof(sName));
                CS_SwitchTeam(i, CS_TEAM_T);
                PrintToChatAll("%s%t", PREFIX, "switched t", sName);
            }
            g_bCTToSwitch[i] = false;
        } else if (g_bTToSwitch[i]) {
            if (IsClientInGame(i)) {
                GetClientName(i, sName, sizeof(sName));
                CS_SwitchTeam(i, CS_TEAM_CT);
                PrintToChatAll("%s%t", PREFIX, "switched ct", sName);
            }
            g_bTToSwitch[i] = false;
        }
    }

    PrintToServer("Debug: SwitchTeams()");
}

public void ChangeTeam(int client, int iCTCount, int iTCount) {
    // Check, how many cts are going to get switched to terror at the end of the round
    for (int i = 1; i <= MaxClients; i++) {
        if (g_bCTToSwitch[i]) {
            iCTCount--;
            iTCount++;
        } else if (g_bTToSwitch[i]) {
            iCTCount++;
            iTCount--;
        }
    }
    //PrintToServer("Debug: %d players are flagged to switch at the end of the round.", iToBeSwitched);
    float fRatio = FloatDiv(float(iCTCount), float(iTCount));

    // optimal CT/T ratio
    float fCFGCTRatio = GetConVarFloat(cvar_CTRatio);

    if (FloatCompare(fRatio, fCFGCTRatio) != 0) { // ratio is not optimal
        int numClients;
        for (int i = 1; i <= MaxClients; i++) {
            if (IsClientInGame(i) && GetClientTeam(i) != CS_TEAM_SPECTATOR)
                numClients++;
        }
       
        int iOptTCount = RoundToCeil(FloatDiv(view_as<float>(numClients), view_as<float>(fCFGCTRatio + 1)));
        int iOptCTCount = numClients - iOptTCount;

        // in any case we don't want empty teams
        if (iOptCTCount == 0 && iOptTCount > 1) {
            iOptCTCount++;
            iOptTCount--;
        }

        while (iTCount < iOptTCount) {
            SwitchNextSeeker();
            iTCount++;
        }
    }

    //PrintToServer("Debug: Initial CTCount: %d TCount: %d Ratio: %f, CFGRatio: %f", iCTCount, iTCount, fRatio, fCFGRatio);

    //PrintToServer("Debug: CT: %d T: %d", iCTCount, iTCount);
}

public Action RequestCT(int client, int args) {
    if (GetClientTeam(client) == CS_TEAM_CT) {
        PrintToChat(client, "%s You are already on the seeking side", PREFIX);
        return Plugin_Handled;
    }

    if (g_iHiderToSeekerQueue[client] != NOT_IN_QUEUE) {
        PrintToChat(client, "%s You are already in the queue", PREFIX);
        return Plugin_Stop;
    }

    g_iHidersInSeekerQueue++;
    g_iHiderToSeekerQueue[client] = g_iHidersInSeekerQueue;

    PrintToChat(client, "%s You are now in the seeker queue", PREFIX);
    PrintToChat(client, "%s Turns until team switch: %d", PREFIX, SimulateTurnsToSeeker(g_iHidersInSeekerQueue));

    return Plugin_Handled;
}

public int SimulateTurnsToSeeker(int queueOrder) {
    int turns;
    int guaranteedCTTurns[MAXPLAYERS];
    int queue[MAXPLAYERS];
    for (int i = 1; i <= MaxClients; i++) {
        guaranteedCTTurns[i] = g_iGuaranteedCTTurns[i];
        queue[i] = g_iHiderToSeekerQueue[i];
    }

    while (queueOrder > 0) {
        int switches;
        for (int i = 1; i <= MaxClients; i++) {
            if (guaranteedCTTurns[i] > 0) {
                guaranteedCTTurns[i]--;
            }

            if (guaranteedCTTurns[i] == 0) {
                switches++;
                guaranteedCTTurns[i] = -1;
            }
        }
        queueOrder -= switches;
        turns++;
    }

    return turns;
}

public void SwitchNextSeeker() {
    int guaranteedTurnsToSeek;
    while (guaranteedTurnsToSeek <= GetConVarInt(cvar_GuaranteedCTTurns)) {
        for (int i = 1; i <= MaxClients; i++) {
            if (IsClientConnected(i) && GetClientTeam(i) == CS_TEAM_CT &&
                    !g_bCTToSwitch[i] && g_iGuaranteedCTTurns[i] == guaranteedTurnsToSeek) {
                g_bCTToSwitch[i] = true;
                return;
            }
        }

        guaranteedTurnsToSeek++;
    }
}

public void SwitchNextHiderInQueue() {
    if (g_iHidersInSeekerQueue < 1) {
        PHClient client = GetRandomClient(CS_TEAM_T);
        g_bTToSwitch[client.index] = true;
    } else {
        for (int i = 1; i <= MaxClients; i++) {
            if (g_iHiderToSeekerQueue[i] == 1) {
                g_bTToSwitch[i] = true;
                g_iHidersInSeekerQueue--;
                g_iHiderToSeekerQueue[i] = NOT_IN_QUEUE;
            } else if (g_iHiderToSeekerQueue[i] > 1) {
                g_iHiderToSeekerQueue[i]--;
            }
        }
    }
}

public Action Command_JoinTeam(int client, int args) {
    PrintToServer("CT ratio: %f", GetConVarFloat(cvar_CTRatio));
    if (!client || !IsClientInGame(client) || FloatCompare(GetConVarFloat(cvar_CTRatio), 0.0) == 0) {
        PrintToServer("JoinTeam: team balance disabled");
        return Plugin_Continue;
    }

    char arg[5];
    if (!GetCmdArgString(arg, sizeof(arg))) {
        return Plugin_Continue;
    }

    int team = StringToInt(arg);

    // Player wants to join CT
    if (team == CS_TEAM_CT) {
        int iCTCount = GetTeamClientCount(CS_TEAM_CT);
        int iTCount = GetTeamClientCount(CS_TEAM_T);

        // This client would be in CT if we continue.
        iCTCount++;

        // And would leave T
        if (GetClientTeam(client) == CS_TEAM_T)
            iTCount--;

        // Check, how many terrors are going to get switched to ct at the end of the round
        for (int i = 1; i <= MaxClients; i++) {
            if (g_bCTToSwitch[i]) {
                iCTCount--;
                iTCount++;
            }
        }

        float fRatio = FloatDiv(float(iCTCount), float(iTCount));

        float fCFGRatio = FloatDiv(1.0, GetConVarFloat(cvar_CTRatio));

        //PrintToServer("Debug: Player %N wants to join CT. CTCount: %d TCount: %d Ratio: %f", client, iCTCount, iTCount, FloatDiv(float(iCTCount), float(iTCount)));

        // There are more CTs than we want in the CT team.
        if (iCTCount > 1 && fRatio > fCFGRatio) {
            PrintCenterText(client, "CT team is full");
            //PrintToServer("Debug: Blocked.");
            return Plugin_Stop;
        }
    } else if (team == CS_TEAM_T) {
        int iCTCount = GetTeamClientCount(CS_TEAM_CT);
        int iTCount = GetTeamClientCount(CS_TEAM_T);

        iTCount++;

        if (GetClientTeam(client) == CS_TEAM_CT)
            iCTCount--;

        if (iCTCount == 0 && iTCount >= 2) {
            PrintCenterText(client, "Cannot leave CT empty");
            //PrintToServer("Debug: Blocked.");
            return Plugin_Stop;
        }
    }

    return Plugin_Continue;
}
