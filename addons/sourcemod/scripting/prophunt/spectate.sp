
public Action Cmd_spec_next(int client, const char[] command, int argc) {
    return SpecNext(client);
}

public Action SpecNext(int client) {
    if (client == 0 || IsPlayerAlive(client))
        return Plugin_Handled;

    int target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
    int nextTarget = GetNextClient(target);
    
    PrintToServer("Debug: next spectator target requested");

    if (nextTarget != -1) {
        SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", nextTarget);
    } else {
        PrintToServer("Debug: next spectator target not found");
        return Plugin_Continue;
    }

    return Plugin_Handled;
}

public Action Cmd_spec_prev(int client, const char[] command, int argc) {
    return SpecPrev(client);
}

public Action SpecPrev(int client) {
    if (client == 0 || IsPlayerAlive(client))
        return Plugin_Handled;

    int target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
    int nextTarget = GetNextClient(target, true);

    if (nextTarget != -1) {
        SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", nextTarget);
    } else return Plugin_Continue;

    return Plugin_Handled;
}

public Action Cmd_spec_player(int client, const char[] command, int argc) {
    if (client == 0 || IsPlayerAlive(client))
        return Plugin_Handled;

    if (GetClientTeam(client) == CS_TEAM_SPECTATOR)
        return Plugin_Continue;

    char arg[128];
    GetCmdArg(1, arg, sizeof(arg));
    if (arg[0]) {
        char targetName[128];
        int targets[MAXPLAYERS];
        bool tn_is_ml;
        int numTargets = ProcessTargetString(
                arg,
                client,
                targets,
                MaxClients,
                COMMAND_FILTER_CONNECTED,
                targetName,
                sizeof(targetName),
                tn_is_ml);

        if (numTargets <= 0) {
            ReplyToTargetError(client, numTargets);
            return SpecNext(client);
        }

        if (numTargets != 1) {
            PrintToServer("Debug: Bad target count");
            return SpecNext(client);
        }

        int target = targets[0];

        // only allow spectating CTs
        if (GetClientTeam(target) != CS_TEAM_CT) {
            PrintToServer("Debug: Picking a random spectating target from CT");
            SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", GetRandomClient(CS_TEAM_CT).index);
            return Plugin_Continue;
        }
    }

    return Plugin_Handled;
}

public Action Cmd_spec_mode(int client, const char[] command, int argc) {
    if (client == 0 || IsPlayerAlive(client))
        return Plugin_Handled;

    SetEntProp(client, Prop_Send, "m_iObserverMode", 4);
    SetThirdPersonView(client, false);
    PrintToServer("Spectator mode entered");
    return Plugin_Handled;
}

stock int GetNextClient(int client, bool backwards=false, int team=CS_TEAM_CT) {
    int d = (backwards ? -1 : 1);
    int i = client + d;
    int begin = (backwards ? MaxClients : 1);
    int limit = (backwards ? 0 : MaxClients+1);
    while (!IsClientInTeam(i, team)) {

        // move index; if index == limit, move it to the beginning
        i = (i + d == limit ? begin : i + d);

        // we made a full circle. no suitable client found
        if (i == client)
            return -1;
    }

    return i;
}

stock bool IsClientInTeam(int client, int team) {
    return client != 0
            && IsClientConnected(client)
            && IsPlayerAlive(client)
            && GetClientTeam(client) == team;
}

public Action Timer_SetObserv(Handle timer, int client) {
    if (IsClientInGame(client) && !IsPlayerAlive(client)) {
        int target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
        if (target == -1 || GetClientTeam(target) != CS_TEAM_CT) {
            if (target == -1)
                target = client;

            int nextTarget = GetNextClient(target);
            if (nextTarget != -1) {
                SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", nextTarget);

                char name[128];
                GetClientName(nextTarget, name, sizeof(name));
                PrintToServer("Debug: spectator target set to: %s", name);
            }
        }

        CreateTimer(0.1, Timer_SetMode, client);
    }
}

// make any players observing a dead CT observe another CT 
public Action Timer_CheckObservers(Handle timer, int client) {
    if (IsClientInGame(client) && !IsPlayerAlive(client)) {
        for (int i = 1; i <= MaxClients; i++) {
            if (IsClientInGame(i) && !IsPlayerAlive(i) && i != client) {

                // who this player is observing now
                int target = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
                if (target == client) {

                    // if it's the dead player, pick a int target
                    int nextTarget = GetNextClient(client);
                    if (nextTarget > 0)
                        SetEntPropEnt(i, Prop_Send, "m_hObserverTarget", nextTarget);
                }
            }
        }
    }
}

public Action Timer_SetMode(Handle timer, int client) {
    if (IsClientConnected(client) && IsClientInGame(client) && !IsPlayerAlive(client)) {
        SetEntProp(client, Prop_Send, "m_iObserverMode", 4);
    }
}

