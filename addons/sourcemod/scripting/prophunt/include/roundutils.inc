
#if defined _roundutils_included
    #endinput
#endif
#define _roundutils_included

#define ROUNDEND_CT_WIN  8
#define ROUNDEND_T_WIN   9

// removes hostages and bomb zones
stock void RemoveGameplayEdicts() {
    int maxent = GetMaxEntities();
    char eName[64];
    for (int i = MaxClients; i < maxent; i++) {
        if (IsValidEdict(i) && IsValidEntity(i)) {
            GetEdictClassname(i, eName, sizeof(eName));

            if (StrContains(eName, "hostage_entity") != -1
                    || StrContains(eName, "func_bomb_target") != -1
                    || (StrContains(eName, "func_buyzone") != -1 && GetEntProp(i, Prop_Data, "m_iTeamNum", 4) == CS_TEAM_T)) {
                RemoveEdict(i);
            }
        }
    }
}

stock void OpenDoors() {
    int maxent = GetMaxEntities();
    char eName[64];
    for (int i = MaxClients; i < maxent; i++) {
        if (IsValidEdict(i) && IsValidEntity(i)) {
            GetEdictClassname(i, eName, sizeof(eName));

            if (StrContains(eName, "_door", false) != -1) {
                AcceptEntityInput(i, "Open");
                HookSingleEntityOutput(i, "OnClose", EntOutput_OnClose);
            }
        }
    }
}

stock bool GiveAliveTerroristsFrags(int amount) {
    bool aliveTerrorists = false;

    // increase playerscore of all alive Terrorists
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T) {
            if (amount > 0) {

                // increase kills by amount
                g_iPlayerScore[i] += amount;
                SetEntProp(i, Prop_Data, "m_iFrags", g_iPlayerScore[i]);
                aliveTerrorists = true;
            }

            // set godmode for the rest of the round
            SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
        }
    }

    return aliveTerrorists;
}

stock void SlayTeam(int team) {
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == team) {
            ForcePlayerSuicide(i);
        }
    }
}

stock void ManageCTQueue() {
    for (int i = 1; i <= MaxClients; i++) {
        if (g_iGuaranteedCTTurns[i] > 0) {
            g_iGuaranteedCTTurns[i]--;
        }

        if (g_iGuaranteedCTTurns[i] == 0 && g_iHidersInSeekerQueue) {
            g_iClientTeam[i] = CS_TEAM_T;
            SwitchNextHiderInQueue();      
        }
    }
}

public void EntOutput_OnClose(const char[] output, int caller, int activator, float delay) {
    AcceptEntityInput(caller, "Open");
}

