
#include "prophunt/include/globals.inc"
#include "prophunt/include/utils.inc"
#include "prophunt/include/whistles.inc"

public void OnMapStart() {
    BuildMainMenu();
    LoadWhistles();

    char sound[MAX_WHISTLE_LENGTH];
    int numWhistles = g_WhistleSounds.Length;
    for (int i = 0; i < numWhistles; i++) {
        g_WhistleSounds.GetString(i, sound, sizeof(sound));
        ReadySound(sound);
    }

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

