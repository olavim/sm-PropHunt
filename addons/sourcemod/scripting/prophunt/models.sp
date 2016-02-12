
#include "prophunt/include/phclient.inc"

public Action Debug_ModelInfo(int client, int args) {
    ReplyToCommand(client, "Child entities: %d", g_iNumEntities);
    ReplyToCommand(client, "Clients: %d", GetTeamClientCount(CS_TEAM_CT) + GetTeamClientCount(CS_TEAM_T));

    for (int i = 1; i <= MaxClients; i++) {
        char name[64];
        if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T) {
            GetClientName(i, name, sizeof(name));
            RenderMode modeParent = GetEntityRenderMode(i);
            RenderMode modeChild;

            PHClient c = GetPHClient(i);
            if (c.hasChild)
                modeChild = GetEntityRenderMode(c.child.index);

            char strMP[16] = "other";
            char strMC[16] = "other";
            if (modeParent == RENDER_TRANSCOLOR) strMP = "TRANSCOLOR";
            if (modeParent == RENDER_NONE) strMP = "NONE";
            if (modeChild == RENDER_TRANSCOLOR) strMC = "TRANSCOLOR";
            if (modeChild == RENDER_NONE) strMC = "NONE";

            ReplyToCommand(client, "%s render mode: %s", name, strMP);
            if (c.hasChild)
                ReplyToCommand(client, "- Child render mode: %s", strMC);
        }
    }

    PHClient c = GetPHClient(client);
    if (c.hasChild)
        ReplyToCommand(client, "client has a child... removing");
    else
        ReplyToCommand(client, "client does not have a child!");
    c.RemoveChild();
    return Plugin_Handled;
}

public Action ReloadModels(int client, int args) {
    OnMapEnd();
    BuildMainMenu();
    ReplyToCommand(client, "PropHunt: Reloaded config.");
    return Plugin_Handled;
}
