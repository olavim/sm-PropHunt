#include "prophunt/include/phclient.inc"

// say /tp /third /thirdperson
public Action Toggle_ThirdPerson(int client, int args) {
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Stop;

    // Only allow Terrorists to use thirdperson view
    if (GetClientTeam(client) != CS_TEAM_T) {
        PrintToChat(client, "%s%t", PREFIX, "Only terrorists can use");
        return Plugin_Handled;
    }

    if (!g_bInThirdPersonView[client]) {
        SetThirdPersonView(client, true);
        PrintToChat(client, "%s%t", PREFIX, "Type again for ego");
    } else {
        SetThirdPersonView(client, false);
    }

    return Plugin_Continue;
}

// say /+3rd
public Action Enable_ThirdPerson(int client, int args) {
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Stop;

    // Only allow Terrorists to use thirdperson view
    if (GetClientTeam(client) != CS_TEAM_T) {
        PrintToChat(client, "%s%t", PREFIX, "Only terrorists can use");
        return Plugin_Handled;
    }

    if (!g_bInThirdPersonView[client]) {
        SetThirdPersonView(client, true);
        PrintToChat(client, "%s%t", PREFIX, "Type again for ego");
    }

    return Plugin_Continue;
}

// say /-3rd
public Action Disable_ThirdPerson(int client, int args) {
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Stop;

    // Only allow Terrorists to use thirdperson view
    if (GetClientTeam(client) != CS_TEAM_T) {
        PrintToChat(client, "%s%t", PREFIX, "Only terrorists can use");
        return Plugin_Handled;
    }

    if (g_bInThirdPersonView[client]) {
        SetThirdPersonView(client, false);
    }

    return Plugin_Continue;
}

// say /whistle
public Action Play_Whistle(int _client, int args) {
    PHClient client = GetPHClient(_client);

    // check if whistling is enabled
    if (!GetConVarBool(cvar_Whistle) || !client.isAlive)
        return Plugin_Handled;

    bool cvarWhistleSeeker = view_as<bool>(GetConVarInt(cvar_WhistleSeeker));

    if (cvarWhistleSeeker && client.team != CS_TEAM_CT) {
        PrintToChat(client.index, "%s%t", PREFIX, "Only counter-terrorists can use");
        return Plugin_Handled;
    }
    // only Ts are allowed to whistle
    else if (!cvarWhistleSeeker && client.team != CS_TEAM_T) {
        PrintToChat(client.index, "%s%t", PREFIX, "Only terrorists can use");
        return Plugin_Handled;
    }

    int cvarWhistleTimes = GetConVarInt(cvar_WhistleTimes);
    char buffer[128];
    Format(buffer, sizeof(buffer), "*/%s", whistle_sounds[GetRandomInt(0, sizeof(whistle_sounds) - 1)]);

    if (g_iWhistleCount[client.index] < cvarWhistleTimes) {
        if (!cvarWhistleSeeker) {
            EmitSoundToAll(buffer, client.index, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
            PrintToChatAll("%s%N %t", PREFIX, client, "whistled");
            g_iWhistleCount[client.index]++;
            PrintToChat(client.index, "%s%t", PREFIX, "whistles left", (cvarWhistleTimes - g_iWhistleCount[client.index]));
        } else {
            int target, iCount;
            float maxrange, range, clientOrigin[3];

            client.GetOrigin(clientOrigin);
            for (int i = 1; i <= MaxClients; i++) {
                PHClient c = GetPHClient(i);
                if (c && c.isAlive && c.team == CS_TEAM_T) {
                    iCount++;
                    float targetOrigin[3];
                    c.GetOrigin(targetOrigin);
                    range = GetVectorDistance(clientOrigin, targetOrigin);
                    if (range > maxrange) {
                        maxrange = range;
                        target = i;
                    }
                }
            }

            if (iCount > 1) {
                EmitSoundToAll(buffer, target, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
                PrintToChatAll("%s %N forced %N to whistle.", PREFIX, client, target);
                g_iWhistleCount[client.index]++;
                PrintToChat(client.index, "%s%t", PREFIX, "whistles left", (cvarWhistleTimes - g_iWhistleCount[client.index]));
            }
        }
    } else {
        PrintToChat(client.index, "%s%t", PREFIX, "whistle limit exceeded", cvarWhistleTimes);
    }

    return Plugin_Handled;
}

// say /hidehelp
// Show the help menu
public Action Display_Help(int client, int args) {
    Menu menu = new Menu(Menu_Help);

    char buffer[512];
    Format(buffer, sizeof(buffer), "%T", "HnS Help", client);
    SetMenuTitle(menu, buffer);
    SetMenuExitButton(menu, true);

    Format(buffer, sizeof(buffer), "%T", "Running HnS", client);
    AddMenuItem(menu, "", buffer);

    Format(buffer, sizeof(buffer), "%T", "Instructions 1", client);
    AddMenuItem(menu, "", buffer);

    AddMenuItem(menu, "", "", ITEMDRAW_SPACER);

    Format(buffer, sizeof(buffer), "%T", "Available Commands", client);
    AddMenuItem(menu, "1", buffer);

    Format(buffer, sizeof(buffer), "%T", "Howto CT", client);
    AddMenuItem(menu, "2", buffer);

    Format(buffer, sizeof(buffer), "%T", "Howto T", client);
    AddMenuItem(menu, "3", buffer);

    DisplayMenu(menu, client, MENU_TIME_FOREVER);
    return Plugin_Handled;
}

// say /freeze
// Freeze hiders in position
public Action Freeze_Cmd(int _client, int args) {
    PHClient client = GetPHClient(_client);
    if (!GetConVarInt(cvar_HiderFreezeMode) || client.team != CS_TEAM_T || !client.isAlive)
        return Plugin_Handled;

    if (client.isFreezed) {
        client.SetFreezed(false);
        PrintToChat(client.index, "%s%t", PREFIX, "Hider Unfreezed");
    } else if (GetConVarBool(cvar_HiderFreezeInAir) || (GetEntityFlags(client.index) & FL_ONGROUND)) {
        client.SetFreezed(true);

        char buffer[128];
        Format(buffer, sizeof(buffer), "*/%s", g_sndFreeze);
        EmitSoundToClient(client.index, buffer);

        PrintToChat(client.index, "%s%t", PREFIX, "Hider Freezed");
    }

    return Plugin_Handled;
}

// Admin Command
// ph_force_whistle
// Forces a terrorist player to whistle
public Action ForceWhistle(int client, int args) {
    if (!GetConVarBool(cvar_Whistle)) {
        ReplyToCommand(client, "Disabled.");
        return Plugin_Handled;
    }

    if (GetCmdArgs() < 1) {
        ReplyToCommand(client, "Usage: ph_force_whistle <#userid|steamid|name>");
        return Plugin_Handled;
    }

    char player[70];
    GetCmdArg(1, player, sizeof(player));

    int target = FindTarget(client, player);
    if (target == -1)
        return Plugin_Handled;

    if (GetClientTeam(target) == CS_TEAM_T && IsPlayerAlive(target)) {
        EmitSoundToAll(whistle_sounds[GetRandomInt(0, sizeof(whistle_sounds) - 1)], target, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
        PrintToChatAll("%s%N %t", PREFIX, target, "whistled");
    } else {
        ReplyToCommand(client, "Hide and Seek: %t", "Only terrorists can use");
    }

    return Plugin_Handled;
}
