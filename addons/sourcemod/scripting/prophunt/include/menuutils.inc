#if defined _phmenuutils_included
    #endinput
#endif
#define _phmenuutils_included

stock void handleModelSelect(PHClient client, Handle menu, int param2) {
    char info[100], info2[100], sModelPath[100];
    bool found = GetMenuItem(menu, param2, info, sizeof(info), _, info2, sizeof(info2));
    if (found) {
        if (StrEqual(info, "random")) {
            SetRandomModel(client.index);
        } else {
            strcopy(sModelPath, sizeof(sModelPath), info);

            SetEntityModel(client.index, sModelPath);
            Client_ReCreateFakeProp(client);

            PrintToChat(client.index, "%s%t \x01%s.", PREFIX, "Model Changed", info2);
        }

        g_iModelChangeCount[client.index]++;
    }
}

stock void handleCategorySelect(PHClient client, Handle menu, int param2) {
    char info[32], info2[32];
    bool found = GetMenuItem(menu, param2, info, sizeof(info), _, info2, sizeof(info2));
    if (found) {
        if (StrEqual(info, "random")) {
            SetRandomModel(client.index);
        } else {
            int index = StringToInt(info);
            CancelClientMenu(client.index, false);
            DisplayMenu(g_hModelMenuCategory[index], client.index, RoundToFloor(GetConVarFloat(cvar_ChangeLimittime)));
        }
    }
}
