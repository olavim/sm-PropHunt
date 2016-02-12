
#include "prophunt/include/phclient.inc"

public Action ReloadModels(int client, int args) {

    // reset the model menu
    OnMapEnd();

    // rebuild it
    BuildMainMenu();

    ReplyToCommand(client, "PropHunt: Reloaded config.");

    return Plugin_Handled;
}
