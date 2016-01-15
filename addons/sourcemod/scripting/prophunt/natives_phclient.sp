
#include "prophunt/include/phclient.inc"

public int Native_PHClient(Handle plugin, int numParams) {
    return GetNativeCell(1);
}

public int Native_PHClient_GetTeam(Handle plugin, int numParams) {
     PHClient client = view_as<PHClient>(GetNativeCell(1));
     return GetClientTeam(client.index);
}

public int Native_PHClient_GetIsAlive(Handle plugin, int numParams) {
     PHClient client = view_as<PHClient>(GetNativeCell(1));
     return IsPlayerAlive(client.index);
}

public int Native_PHClient_GetIsFreezed(Handle plugin, int numParams) {
     PHClient client = view_as<PHClient>(GetNativeCell(1));
     return g_ClientIsFreezed[client.index];
}

public int Native_PHClient_GetIsConnected(Handle plugin, int numParams) {
     PHClient client = view_as<PHClient>(GetNativeCell(1));
     return IsClientConnected(client.index);
}

public int Native_PHClient_SetFreezed(Handle plugin, int numParams) {
    PHClient client = view_as<PHClient>(GetNativeCell(1));

    bool freezed = view_as<bool>(GetNativeCell(2));
    // PrintToServer("bool: %b", freezed);

    if (freezed) { // freeze
        if (GetConVarInt(cvar_HiderFreezeMode) == 1) {
            client.SetMoveType(MOVETYPE_NONE); // Still able to move camera
        } else {
            SetEntData(client.index, g_Freeze, FL_CLIENT | FL_ATCONTROLS, 4, true); // Cant move anything
            client.SetMoveType(MOVETYPE_NONE);
        }

        // PrintToServer("freeze");
        float NO_VELOCITY[3] = {0.0, 0.0, 0.0};
        client.Teleport(NULL_VECTOR, NULL_VECTOR, NO_VELOCITY);
        g_ClientIsFreezed[client.index] = true;

        client.DetachChild();
    } else { // unfreeze
        if (GetConVarInt(cvar_HiderFreezeMode) == 1) {
            client.SetMoveType(MOVETYPE_WALK);
        } else {
            SetEntData(client.index, g_Freeze, FL_FAKECLIENT | FL_ONGROUND | FL_PARTIALGROUND, 4, true);
            client.SetMoveType(MOVETYPE_WALK);
        }

        // PrintToServer("unfreeze");
        g_ClientIsFreezed[client.index] = false;
        client.AttachChild();
    }
}

