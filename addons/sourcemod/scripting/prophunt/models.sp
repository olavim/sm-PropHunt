
#include "prophunt/include/phclient.inc"

public Action ReloadModels(int client, int args) {
    OnMapEnd();
    BuildMainMenu();
    ReplyToCommand(client, "PropHunt: Reloaded config.");
    return Plugin_Handled;
}
