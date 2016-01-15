
#include "prophunt/include/phentity.inc"

#if defined _phclient_included
    #endinput
#endif
#define _phclient_included

bool g_ClientIsFreezed[MAXPLAYERS] = {false, ...};

methodmap PHClient < PHEntity 
{
    /**
     * Creates a new PHClient wrapper for a client.
     *
     * @param client     Client index to wrap.
     */
    public native PHClient(int client);

    /**
     * Team the client belongs to.
     */ 
    property int team {
        public native get();
    }

    /**
     * Is this client alive?
     */
    property bool isAlive {
        public native get();
    }

    /**
     * Has this client been freezed?
     */
    property bool isFreezed {
        public native get();
    }

    /**
     * Is this client connected to the server?
     */
    property bool isConnected {
        public native get();
    }

    /**
     * Freezes or unfreezes the client.
     *
     * @param freezed   True to freeze, false to unfreeze.
     */
    public native void SetFreezed(bool freezed);

}

stock PHClient GetPHClient(int client) {
    if (client < 1 || client > MAXPLAYERS)
        return null;

    return view_as<PHClient>(GetPHEntity(client));
}

stock PHClient RegisterPHClient(int client) {
    if (client < 1 || client > MAXPLAYERS)
        return null;

    return view_as<PHClient>(RegisterPHEntity(client));
}

stock void UnregisterPHClient(int client) {
    UnregisterPHEntity(client);
}

