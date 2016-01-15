
#include "prophunt/include/globals.inc"
#include "prophunt/include/utils.inc"

public void OnMapStart() {
    BuildMainMenu();
    BuildMainMenu(true);

    for (int i = 0; i < sizeof(whistle_sounds); i++)
        ReadySound(whistle_sounds[i]);

    PrecacheSound("radio/go.wav");
    ReadySound(g_sndFreeze);

    g_iFirstCTSpawn = 0;
    g_iFirstTSpawn = 0;

    UnsetTimer(g_hShowCountdownTimer);
}

public void OnMapEnd() {
    CloseHandle(g_hMenuKV);
    UnsetHandle(g_hModelMenu);

    g_iFirstCTSpawn = 0;
    g_iFirstTSpawn = 0;

    UnsetTimer(g_hShowCountdownTimer);
    UnsetTimer(g_hRoundTimeTimer);
    UnsetTimer(g_hWhistleDelay);

    for (int client = 1; client <= MaxClients; client++) {
        UnsetTimer(g_hAutoFreezeTimers[client]);
    }
}

