
#include "prophunt/include/phentity.inc"

#if defined _phclient_included
    #endinput
#endif
#define _phclient_included

float NO_VELOCITY[3] = {0.0, 0.0, 0.0};

/**
 * Has a client been freezed?
 *
 * @param client    Client.
 * @return          True if freezed, false otherwise
 */
stock bool IsClientFreezed(int client) {
    return g_bClientIsFreezed[client];
}

/**
 * Freezes or unfreezes a client.
 *
 * @param freezed   True to freeze, false to unfreeze.
 * @noreturn
 */
stock void Client_SetFreezed(int client, bool freeze) {
    if (!IsClientFreezed(client) && freeze) { // freeze
        if (GetConVarInt(cvar_HiderFreezeMode) == 1) {
            SetEntityMoveType(client, MOVETYPE_NONE); // Still able to move camera
        } else {
            SetEntData(client, g_Freeze, FL_CLIENT | FL_ATCONTROLS, 4, true); // Cant move anything
            SetEntityMoveType(client, MOVETYPE_NONE);
        }

        TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, NO_VELOCITY);
        g_bClientIsFreezed[client] = true;

        Entity_DetachChild(client);
    } else if (IsClientFreezed(client)) { // unfreeze
        if (GetConVarInt(cvar_HiderFreezeMode) == 1) {
            SetEntityMoveType(client, MOVETYPE_WALK);
        } else {
            SetEntData(client, g_Freeze, FL_FAKECLIENT | FL_ONGROUND | FL_PARTIALGROUND, 4, true);
            SetEntityMoveType(client, MOVETYPE_WALK);
        }

        g_bClientIsFreezed[client] = false;
        Entity_AttachChild(client);
    }
}
