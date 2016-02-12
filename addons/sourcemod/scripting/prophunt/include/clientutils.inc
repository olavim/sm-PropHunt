
#if defined _clientutils_included
    #endinput
#endif
#define _clientutils_included

#include "prophunt/include/phclient.inc"

#define SPECMODE_NONE           0
#define SPECMODE_FIRSTPERSON    4
#define SPECMODE_THIRDPERSON    5
#define SPECMODE_FREELOOK       6

stock void OfferClientModel(int client) {
    float changeLimitTime = GetConVarFloat(cvar_ChangeLimittime);
    PrintToServer("Offer model");

    if (GetConVarBool(cvar_AutoChoose))
        SetRandomModel(client);
    else if (changeLimitTime > 0.0)
        DisplayMenu(g_hModelMenu, client, RoundToFloor(changeLimitTime));
    else
        DisplayMenu(g_hModelMenu, client, MENU_TIME_FOREVER);
}

stock int GetRandomClient(int team, bool onlyAlive=false, bool onlyNonSwitching=false) {
    int clientIndex;
    int[] clients = new int[MaxClients];
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && GetClientTeam(i) == team && (IsPlayerAlive(i) || !onlyAlive)) {
            bool isBeingSwitched = g_iClientTeam[i] != team;
            if (!onlyNonSwitching || !isBeingSwitched) {
                clients[clientIndex] = i;
                clientIndex++;
            }
        }
    }

    return clients[GetRandomInt(0, clientIndex-1)];
}

stock void PreventCTFire(PHClient client, int &buttons) {
    if (!client || client.team != CS_TEAM_CT)
        return;

    char weaponName[30];

    GetClientWeapon(client.index, weaponName, sizeof(weaponName));
    if (g_bIsCTWaiting[client.index] && (buttons & IN_ATTACK || buttons & IN_ATTACK2)) {
        // dont allow shooting in the beginning of the round
        buttons &= ~IN_ATTACK;
        buttons &= ~IN_ATTACK2;
    } else if (buttons & IN_ATTACK2 && StrEqual(weaponName, "weapon_knife")) {

        // disable rightclick knifing
        buttons &= ~IN_ATTACK2;
    }
}

stock void BlindClient(int client, bool blind=true) {
    Handle hFadeClient = StartMessageOne("Fade", client);
    PbSetInt(hFadeClient, "duration", 1);
    PbSetInt(hFadeClient, "hold_time", 3);

    if (blind) {
        PbSetInt(hFadeClient, "flags", FFADE_STAYOUT);
    } else {
        PbSetInt(hFadeClient, "flags", FFADE_PURGE);
    }

    int color[] = {255, 0, 0, 255};
    PbSetColor(hFadeClient, "clr", color);
    EndMessage();
}

stock void StripClientWeapons(int client) {
    int iWeapon = -1;
    for (int i = CS_SLOT_PRIMARY; i <= CS_SLOT_C4; i++) {
        while ((iWeapon = GetPlayerWeaponSlot(client, i)) != -1) {
            RemovePlayerItem(client, iWeapon);
            RemoveEdict(iWeapon);
        }
    }
}

stock void SetModelChangeTimer(int client) {
    float changeLimitTime = GetConVarFloat(cvar_ChangeLimittime);

    // only set the timer if it's not unlimited
    if (changeLimitTime > 0.0)
        g_hAllowModelChangeTimer[client] = CreateTimer(changeLimitTime, DisableModelMenu, client);
}

stock bool IsPlayerAFK(int client) {
    float fOrigin[3];
    GetClientAbsOrigin(client, fOrigin);

    // Did he move after spawn?
    return UTIL_VectorEqual(fOrigin, g_fSpawnPosition[client], 0.1);
}

stock void RemoveClientRadar(int client) {
    int hud = GetEntProp(client, Prop_Send, "m_iHideHUD");
    SetEntProp(client, Prop_Send, "m_iHideHUD", hud | 1<<12);
}

stock void SlayClient(PHClient client) {
    if (client && client.isAlive)
        ForcePlayerSuicide(client.index);
}

stock void FreezePlayer(PHClient client) {

    // Force him to watch at the ground.
    float fPlayerEyes[3];
    GetClientEyeAngles(client.index, fPlayerEyes);
    fPlayerEyes[0] = 180.0;
    client.Teleport(NULL_VECTOR, fPlayerEyes, NULL_VECTOR);
    SetEntData(client.index, g_Freeze, FL_CLIENT | FL_ATCONTROLS, 4, true);
    client.SetMoveType(MOVETYPE_NONE);
    BlindClient(client.index, true);
}

stock void UnFreezePlayer(int client) {
    SetEntData(client, g_Freeze, FL_FAKECLIENT | FL_ONGROUND | FL_PARTIALGROUND, 4, true);
    SetEntityMoveType(client, MOVETYPE_WALK);
    BlindClient(client, false);
    g_bIsCTWaiting[client] = false;
    EmitSoundToClient(client, "radio/go.wav");
    PrintToChat(client, "%s%t", PREFIX, "Go search");
}

stock void CheckClientHasKnife(PHClient client) {
    if (client.isAlive) {
        int iWeapon = GetPlayerWeaponSlot(client.index, 2);
        if (iWeapon == -1) {
            iWeapon = GivePlayerItem(client.index, "weapon_knife");
        }
    }
}

stock void SaveClientSpawnPosition(PHClient client) {
    client.GetOrigin(g_fSpawnPosition[client]);
}

static stock bool UTIL_VectorEqual(const float vec1[3], const float vec2[3], const float tolerance) {
    for (int i = 0; i < 3; i++)
        if (vec1[i] > (vec2[i] + tolerance) || vec1[i] < (vec2[i] - tolerance))
            return false;
    return true;
}

/**
 * Returns the next or previous client by id.
 *
 * @param client        Client from which the searching begins
 * @param fw            If false, returns a previous client instead of next.
 * @param team          Limit searching to a specific team, or -1 to search any.
 * @return The next or previous client.
 */
stock int GetNextClient(int client, bool fw=true, int team=-1) {
    int d = (fw ? 1 : -1);
    int i = client + d;
    int begin = (fw ? 1 : MaxClients);
    int limit = (fw ? MaxClients + 1 : 0);

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
            && (GetClientTeam(client) == team || team == -1);
}

stock int DetermineSpecMode(int client) {
    int currMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
    int limitSpec = GetConVarInt(cvar_LimitSpec);
    int newMode = currMode + 1;
    if (newMode > SPECMODE_FREELOOK)
        newMode = SPECMODE_FIRSTPERSON;

    if (limitSpec == 1 && newMode == SPECMODE_FREELOOK)
        newMode = SPECMODE_FIRSTPERSON;
    else if (limitSpec == 2)
        newMode = SPECMODE_FIRSTPERSON;

    return newMode;
}

stock int DetermineAllowedSpecTeams(int client) {
    int limitSpec = GetConVarInt(cvar_LimitSpec);
    int team = -1;
    if (limitSpec == 1)
        team = GetClientTeam(client);
    else if (limitSpec == 2)
        team = CS_TEAM_CT;

    return team;
}

stock void MakeClientWhistle(int client) {
    char buffer[128], sound[MAX_WHISTLE_LENGTH];
    int soundIndex = GetRandomInt(0, g_WhistleSounds.Length - 1);
    g_WhistleSounds.GetString(soundIndex, sound, MAX_WHISTLE_LENGTH);
    Format(buffer, sizeof(buffer), "*/%s", sound);

    EmitSoundToAll(buffer, client, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
}

stock void Client_ResetFakeProp(PHClient client) {
    if (client) {
        client.RemoveChild();
        client.SetFreezed(false);
    }
}

stock void Client_UpdateFakeProp(int _client) {
    PHClient client = GetPHClient(_client);
    if (!client)
        return;

    if (client.team != CS_TEAM_T || !client.isAlive) {
        if (g_bShowFakeProp[client.index]) {
            g_bShowFakeProp[client.index] = false;

            SetEntityRenderMode(client.index, RENDER_TRANSCOLOR);
        }

        if (client.hasChild || client.isFreezed)
            Client_ResetFakeProp(client);

        return;
    }

    //No fake prop exist? Create a one
    if (!client.hasChild) {
        PrintToServer("Debug: no child");
        if (g_bShowFakeProp[client.index]) {
            g_bShowFakeProp[client.index] = false;

            SetEntityRenderMode(client.index, RENDER_TRANSCOLOR);
        }
        Client_ReCreateFakeProp(client);
        return;
    }
}

stock void Client_ReCreateFakeProp(PHClient client) {
    client.RemoveChild();

    //Det model
    char fullPath[100];
    GetClientModel(client.index, fullPath, sizeof(fullPath));

    //Create Fake Model
    int entity = CreateEntityByName("prop_physics_override");
    if (IsValidEntity(entity)) {
        PrecacheModel(fullPath, true);
        SetEntityModel(entity, fullPath);
        SetEntityMoveType(entity, MOVETYPE_NONE);
        SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client.index);
        SetEntProp(entity, Prop_Data, "m_CollisionGroup", 1);
        SetEntProp(entity, Prop_Send, "m_usSolidFlags", 12);
        SetEntProp(entity, Prop_Send, "m_nSolidType", 6);
        DispatchSpawn(entity);
        SetEntData(entity, g_Freeze, FL_CLIENT | FL_ATCONTROLS, 4, true);
        SetEntityMoveType(entity, MOVETYPE_NONE);
        SetEntPropEnt(entity, Prop_Data, "m_hLastAttacker", client.index);

        SetEntityRenderMode(client.index, RENDER_NONE);
        SetEntityRenderMode(entity, RENDER_TRANSCOLOR);

        PHEntity child = new PHEntity(entity);
        //child.TeleportTo(client);
        client.SetChild(child);
        if (client.isFreezed)
            client.DetachChild();
    } else {
        client.RemoveChild();
    }
}

// set a random model to a client
stock void SetRandomModel(int _client) {
    PHClient client = GetPHClient(_client);
    if (!client)
        return;

    // give him a random one.
    char ModelPath[80], finalPath[100], ModelName[60];
    if (GetConVarBool(cvar_CategorizeModels)) {
        int categoryIndex = GetRandomInt(0, g_iTotalCategoriesAvailable - 1);
        int modelIndex = GetRandomInt(0, GetMenuItemCount(g_hModelMenuCategory[categoryIndex]) - 1);
        char key[128];
        KvGetKeyByIndex(g_hMenuKV, categoryIndex, key, sizeof(key));
        KvJumpToKey(g_hMenuKV, key);
        KvGetKeyByIndex(g_hMenuKV, modelIndex, ModelPath, sizeof(ModelPath));
    } else {
        int modelIndex = GetRandomInt(0, g_iTotalModelsAvailable - 1);
        KvGetKeyByIndex(g_hMenuKV, modelIndex, ModelPath, sizeof(ModelPath));
    }

    FormatEx(finalPath, sizeof(finalPath), "models/%s.mdl", ModelPath);

    SetEntityModel(client.index, finalPath);
    Client_ReCreateFakeProp(client);

    if (!IsFakeClient(client.index)) {
        KvGetString(g_hMenuKV, ModelPath, ModelName, sizeof(ModelName));
        PrintToChat(client.index, "%s%t \x01%s.", PREFIX, "Model Changed", ModelName);
    }

    KvRewind(g_hMenuKV);
    g_iModelChangeCount[client.index]++;

    // display the help menu on first spawn
    if (GetConVarBool(cvar_ShowHelp) && g_bFirstSpawn[client.index]) {
        Cmd_DisplayHelp(client.index, 0);
        g_bFirstSpawn[client.index] = false;
    }
}

stock bool SetThirdPersonView(int client, bool third) {
    static Handle m_hAllowTP = INVALID_HANDLE;
    if (m_hAllowTP == INVALID_HANDLE)
        m_hAllowTP = FindConVar("sv_allow_thirdperson");

    SetConVarInt(m_hAllowTP, 1);

    if (third) {
        ClientCommand(client, "thirdperson");
        g_bInThirdPersonView[client] = true;
    } else {
        ClientCommand(client, "firstperson");
        g_bInThirdPersonView[client] = false;
    }

    return true;
}
