
#include "prophunt/include/phclient.inc"
#include "prophunt/include/menuutils.inc"

public int Menu_Group(Handle menu, MenuAction action, int _client, int param2) {
    PHClient client = GetPHClient(_client);

    if (client && client.team == CS_TEAM_T && g_bAllowModelChange[client.index]) {
        if (action == MenuAction_Select) {
            if (!GetConVarBool(cvar_CategorizeModels) || menu != g_hModelMenu) {
                PrintToServer("Model select");
                handleModelSelect(client, menu, param2);
            } else {
                PrintToServer("Category select");
                handleCategorySelect(client, menu, param2);
            }
        } else if (action == MenuAction_Cancel) {
            if (param2 == MenuCancel_ExitBack) {
                CancelClientMenu(client.index, false);
                DisplayMenu(g_hModelMenu, client.index, RoundToFloor(GetConVarFloat(cvar_ChangeLimittime)));
            } else {
                PrintToChat(client.index, "%s%t", PREFIX, "Type !hide");
            }
        }

        // display the help menu on first spawn
        if (GetConVarBool(cvar_ShowHelp) && g_bFirstSpawn[client.index]) {
            Cmd_DisplayHelp(client.index, 0);
            g_bFirstSpawn[client.index] = false;
        }
    }
}

public int Menu_Dummy(Handle menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_Cancel && param2 != MenuCancel_Exit) {
        if (IsClientInGame(param1))
            Cmd_DisplayHelp(param1, 0);
    } else if (action == MenuAction_End) {
        CloseHandle(menu);
    }
}

stock void BuildMainMenu() {
    PrintToServer("Debug: BuildMainMenu");
    g_iTotalModelsAvailable = 0;
    g_iTotalCategoriesAvailable = 0;

    g_hMenuKV = CreateKeyValues("Models");
    KeyValues defaultKV = new KeyValues("Models");

    bool useCategories = GetConVarBool(cvar_CategorizeModels);
    char mapFile[256], defFile[256], map[64], title[64], finalOutput[100];
    char name[32], path[100];
    char indexStr[4];

    GetCurrentMap(map, sizeof(map));

    BuildPath(Path_SM, mapFile, 255, "%s/%s.cfg", MAP_CONFIG_PATH,  map);
    BuildPath(Path_SM, defFile, 255, "%s/default.cfg", MAP_CONFIG_PATH);

    bool fileExists = FileToKeyValues(g_hMenuKV, mapFile);

    if (GetConVarBool(cvar_IncludeDefaultModels) || !fileExists) {
        FileToKeyValues(defaultKV, defFile);
        KvMerge(g_hMenuKV, defaultKV);
    }

    KvAddIncludes(g_hMenuKV);
    KvCategorize(g_hMenuKV);

    //KeyValuesToFile(g_hMenuKV, "kvdump.txt");

    PrintToServer("set menu");
    g_hModelMenu = new Menu(Menu_Group);
    Format(title, sizeof(title), "%T:", "Title Select Model", LANG_SERVER);

    SetMenuTitle(g_hModelMenu, title);
    SetMenuExitButton(g_hModelMenu, true);

    // Re-use the title char array
    Format(title, sizeof(title), "%T", "random", LANG_SERVER);
    AddMenuItem(g_hModelMenu, "random", title);

    if (useCategories) {
        int index = 0;
        KvGotoFirstSubKey(g_hMenuKV, false);
        do {
            KvGetSectionName(g_hMenuKV, path, sizeof(path));
            if (StrEqual("#include", path))
                continue;

            if (strlen(path) > 0) {
                IntToString(index, indexStr, sizeof(indexStr));
                AddMenuItem(g_hModelMenu, indexStr, path);

                g_hModelMenuCategory[index] = new Menu(Menu_Group);
                SetMenuTitle(g_hModelMenuCategory[index], path);
                SetMenuExitBackButton(g_hModelMenuCategory[index], true);
            }

            index++;
            g_iTotalCategoriesAvailable++;
        } while (KvGotoNextKey(g_hMenuKV, false));
        KvRewind(g_hMenuKV);
    }

    int index = 0;
    KvGotoFirstSubKey(g_hMenuKV, false);
    do {
        KvGetSectionName(g_hMenuKV, path, sizeof(path));
        if (StrEqual("#include", path))
            continue;

        if (KvGotoFirstSubKey(g_hMenuKV, false)) {
            do {

                // get the model path and precache it
                KvGetSectionName(g_hMenuKV, path, sizeof(path));
                KvGetString(g_hMenuKV, NULL_STRING, name, sizeof(name));
                ReplaceString(path, sizeof(path), ".mdl", "", false);
                FormatEx(finalOutput, sizeof(finalOutput), "models/%s.mdl", path);
                PrecacheModel(finalOutput, true);

                if (strlen(name) > 0) {
                    if (!useCategories)
                        AddMenuItem(g_hModelMenu, finalOutput, name);
                    else
                        AddMenuItem(g_hModelMenuCategory[index], finalOutput, name);
                }

                g_iTotalModelsAvailable++;
            } while (KvGotoNextKey(g_hMenuKV, false));
        }

        index++;
        KvGoBack(g_hMenuKV);
    } while (KvGotoNextKey(g_hMenuKV, false));
    KvRewind(g_hMenuKV);

    delete defaultKV;

    if (g_iTotalModelsAvailable == 0)
        SetFailState("No models parsed in %s.cfg", map);
}

public Action ShowSelectModelMenu(int client, int args) {
    if (g_hModelMenu == INVALID_HANDLE) {
        return Plugin_Stop;
    }

    if (GetClientTeam(client) == CS_TEAM_T) {
        int changeLimit = GetConVarInt(cvar_ChangeLimit);
        if (g_bAllowModelChange[client] && (changeLimit == 0 || g_iModelChangeCount[client] < (changeLimit + 1))) {
            if (GetConVarBool(cvar_AutoChoose))
                SetRandomModel(client);
            else
                DisplayMenu(g_hModelMenu, client, RoundToFloor(GetConVarFloat(cvar_ChangeLimittime)));
        } else
            PrintToChat(client, "%s%t", PREFIX, "Modelmenu Disabled");
    } else {
        PrintToChat(client, "%s%t", PREFIX, "Only terrorists can select models");
    }

    return Plugin_Continue;
}

public Action DisableModelMenu(Handle timer, int client) {
    g_hAllowModelChangeTimer[client] = INVALID_HANDLE;

    if (!IsClientInGame(client))
        return Plugin_Stop;

    g_bAllowModelChange[client] = false;

    if (IsPlayerAlive(client))
        PrintToChat(client, "%s%t", PREFIX, "Modelmenu Disabled");

    // didnt he chose a model?
    if (GetClientTeam(client) == CS_TEAM_T && g_iModelChangeCount[client] == 0) {
        // give him a random one.
        PrintToChat(client, "%s%t", PREFIX, "Did not choose model");
        SetRandomModel(client);
    }

    return Plugin_Continue;
}
