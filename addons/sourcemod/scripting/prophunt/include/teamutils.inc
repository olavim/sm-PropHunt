
#if defined _teamutils_included
    #endinput
#endif
#define _teamutils_included

stock void SwitchTeams() {
    char sName[64];
    for (int i = 1; i <= MaxClients; i++) {
        if (g_bCTToSwitch[i]) {
            if (IsClientInGame(i)) {
                GetClientName(i, sName, sizeof(sName));
                CS_SwitchTeam(i, CS_TEAM_T);
            }
            g_bCTToSwitch[i] = false;
        } else if (g_bTToSwitch[i]) {
            if (IsClientInGame(i)) {
                GetClientName(i, sName, sizeof(sName));
                CS_SwitchTeam(i, CS_TEAM_CT);
            }
            g_bTToSwitch[i] = false;
        }
    }
}

stock void ChangeTeam(int iCTCount, int iTCount) {

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
    float fRatio = FloatDiv(float(iTCount), float(iCTCount));

    // optimal T/CT ratio
    float fCFGCTRatio = GetConVarFloat(cvar_CTRatio);

    if (FloatCompare(fRatio, fCFGCTRatio) != 0) { // ratio is not optimal
        int numClients;
        for (int i = 1; i <= MaxClients; i++) {
            if (IsClientInGame(i) && GetClientTeam(i) != CS_TEAM_SPECTATOR)
                numClients++;
        }
       
        int iOptCTCount = RoundToFloor(FloatDiv(float(numClients), fCFGCTRatio));
        int iOptTCount = numClients - iOptCTCount;

        // in any case we don't want empty teams
        if (iOptCTCount == 0 && iOptTCount > 1) {
            iOptCTCount++;
            iOptTCount--;
        }

        while (iTCount < iOptTCount) {
            SwitchNextSeeker();
            iCTCount--;
            iTCount++;
        }

        while (iCTCount < iOptCTCount) {
            SwitchNextHiderInQueue();
            iCTCount++;
            iTCount--;
        }
    }

    //PrintToServer("Debug: Initial CTCount: %d TCount: %d Ratio: %f, CFGRatio: %f", iCTCount, iTCount, fRatio, fCFGRatio);

    //PrintToServer("Debug: CT: %d T: %d", iCTCount, iTCount);
}

stock int SimulateTurnsToSeeker(int queueOrder) {
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

stock void SwitchNextSeeker() {
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

stock void SwitchNextHiderInQueue() {
    if (g_iHidersInSeekerQueue < 1) {
        int client = GetRandomClient(CS_TEAM_T);
        g_bTToSwitch[client] = true;
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

stock void ScrambleTeams() {
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && GetClientTeam(i) != CS_TEAM_SPECTATOR) {
            int team = (GetRandomInt(0, 1) ? CS_TEAM_CT : CS_TEAM_T);
            CS_SwitchTeam(i, team);
        }
    }
}
