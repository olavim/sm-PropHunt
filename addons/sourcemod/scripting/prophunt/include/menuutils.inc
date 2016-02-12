#if defined _phmenuutils_included
    #endinput
#endif
#define _phmenuutils_included

stock void handleModelSelect(int client, Handle menu, int param2) {
    char info[100], info2[100], sModelPath[100];
    bool found = GetMenuItem(menu, param2, info, sizeof(info), _, info2, sizeof(info2));
    if (found) {
        if (StrEqual(info, "random")) {
            SetRandomModel(client);
        } else {
            strcopy(sModelPath, sizeof(sModelPath), info);

            SetEntityModel(client, sModelPath);
            Client_ReCreateFakeProp(client);

            PrintToChat(client, "%s%t \x01%s.", PREFIX, "Model Changed", info2);
        }

        g_iModelChangeCount[client]++;
    }
}

stock void handleCategorySelect(int client, Handle menu, int param2) {
    char info[32], info2[32];
    bool found = GetMenuItem(menu, param2, info, sizeof(info), _, info2, sizeof(info2));
    if (found) {
        if (StrEqual(info, "random")) {
            SetRandomModel(client);
        } else {
            int index = StringToInt(info);
            CancelClientMenu(client, false);
            DisplayMenu(g_hModelMenuCategory[index], client, RoundToFloor(GetConVarFloat(cvar_ChangeLimittime)));
        }
    }
}
