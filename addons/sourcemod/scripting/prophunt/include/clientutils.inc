
#if defined _clientutils_included
    #endinput
#endif
#define _clientutils_included

#include "prophunt/include/phclient.inc"

stock void OfferClientModel(int client) {
    float changeLimitTime = GetConVarFloat(cvar_ChangeLimittime);

    if (GetConVarBool(cvar_AutoChoose))
        SetRandomModel(client);
    else if (changeLimitTime > 0.0)
        DisplayMenu(g_hModelMenu, client, RoundToFloor(changeLimitTime));
    else 
        DisplayMenu(g_hModelMenu, client, MENU_TIME_FOREVER);
}

stock PHClient GetRandomClient(int team) {
    int clientIndex;
    PHClient clients[MAXPLAYERS];
    for (int i = 1; i <= MaxClients; i++) {
        PHClient client = GetPHClient(i);
        if (client && client.team == team) {
            if (!(team == CS_TEAM_CT && g_bCTToSwitch[i]) && !(team == CS_TEAM_T && g_bTToSwitch[i]))
                clients[clientIndex++] = client;
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

stock void UnFreezePlayer(PHClient client) {
    SetEntData(client.index, g_Freeze, FL_FAKECLIENT | FL_ONGROUND | FL_PARTIALGROUND, 4, true);
    client.SetMoveType(MOVETYPE_WALK);
    BlindClient(client.index, false);
    g_bIsCTWaiting[client.index] = false;
    EmitSoundToClient(client.index, "radio/go.wav");
    PrintToChat(client.index, "%s%t", PREFIX, "Go search");
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


