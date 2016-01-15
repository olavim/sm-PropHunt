
#include "prophunt/include/phclient.inc"

stock void Client_ResetFakeProp(PHClient client) {
    if (client) {
        if (client.hasChild)
            AcceptEntityInput(client.child.index, "kill");
        client.RemoveChild();
        client.SetFreezed(false);
    }
}

stock void Client_UpdateFakeProp(int _client) {
    PHClient client = GetPHClient(_client);
    if (!client)
        return;

    //Not alive, reset prop
    if (!client.isAlive) {
        if (g_bShowFakeProp[client.index]) {
            g_bShowFakeProp[client.index] = false;

            SetEntityRenderMode(client.index, RENDER_TRANSCOLOR);
        }
        Client_ResetFakeProp(client);
        return;
    }

    //Wrong team, reset prop
    if (client.team != CS_TEAM_T) {
        if (g_bShowFakeProp[client.index]) {
            g_bShowFakeProp[client.index] = false;

            SetEntityRenderMode(client.index, RENDER_TRANSCOLOR);
        }
        Client_ResetFakeProp(client);
        return;
    }

    //No fake prop exist? Create a one
    if (!client.hasChild) {
        if (g_bShowFakeProp[client.index]) {
            g_bShowFakeProp[client.index] = false;

            SetEntityRenderMode(client.index, RENDER_TRANSCOLOR);
        }
        Client_ReCreateFakeProp(client);
        return;
    }
}

stock void Client_ReCreateFakeProp(PHClient client) {

    //delete old one if valid
    if (client.hasChild)
        AcceptEntityInput(client.child.index, "kill");
    client.RemoveChild();

    //Det model
    char fullPath[100];
    GetClientModel(client.index, fullPath, sizeof(fullPath));

    //Create Fake Model
    int entity = CreateEntityByName("prop_physics_override");
    if (IsValidEntity(entity)) {
        //g_iEntity[client] = entity;
        PrecacheModel(fullPath, true);
        SetEntityModel(entity, fullPath);
        SetEntityMoveType(entity, MOVETYPE_NONE);
        SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client.index);
        SetEntProp(entity, Prop_Data, "m_CollisionGroup", 1);
        SetEntProp(entity, Prop_Send, "m_usSolidFlags", 12);
        SetEntProp(entity, Prop_Send, "m_nSolidType", 6);
        DispatchSpawn(entity);
        SetEntData(entity, g_Freeze, FL_CLIENT | FL_ATCONTROLS, 4, true);
        SetEntityMoveType(entity, MOVETYPE_NONE);
        SetEntPropEnt(entity, Prop_Data, "m_hLastAttacker", client.index);

        SetEntityRenderMode(client.index, RENDER_NONE);
        SetEntityRenderMode(entity, RENDER_TRANSCOLOR);

        float vecClientOrigin[3];
        client.GetOrigin(vecClientOrigin);
        TeleportEntity(entity, vecClientOrigin, NULL_VECTOR, NULL_VECTOR);

        client.SetChild(new PHEntity(entity));
    } else {
        client.RemoveChild();
    }
}

// set a random model to a client
stock void SetRandomModel(int _client) {
    PHClient client = GetPHClient(_client);
    if (!client) {
        return;
    }

    // give him a random one.
    char ModelPath[80], finalPath[100], ModelName[60];
    int RandomNumber = GetRandomInt(0, g_iTotalModelsAvailable - 1);

    // set the model
    KvGetStringByIndex(g_hMenuKV, RandomNumber, ModelPath, sizeof(ModelPath));

    FormatEx(finalPath, sizeof(finalPath), "models/%s.mdl", ModelPath);

    SetEntityModel(client.index, finalPath);
    Client_ReCreateFakeProp(client);

    if (!IsFakeClient(client.index)) {
        KvGetKeyByIndex(g_hMenuKV, RandomNumber, ModelName, sizeof(ModelName));
        PrintToChat(client.index, "%s%t \x01%s.", PREFIX, "Model Changed", ModelName);
    }

    KvRewind(g_hMenuKV);
    g_iModelChangeCount[client.index]++;

    // display the help menu afterwards on first spawn
    if (GetConVarBool(cvar_ShowHideHelp) && g_bFirstSpawn[client.index]) {
        Display_Help(client.index, 0);
        g_bFirstSpawn[client.index] = false;
    }
}

stock bool SetThirdPersonView(int client, bool third) {
    static Handle m_hAllowTP = INVALID_HANDLE;
    if (m_hAllowTP == INVALID_HANDLE)
        m_hAllowTP = FindConVar("sv_allow_thirdperson");

    SetConVarInt(m_hAllowTP, 1);

    if (third) {
        ClientCommand(client, "thirdperson");
        g_bInThirdPersonView[client] = true;
    } else {
        ClientCommand(client, "firstperson");
        g_bInThirdPersonView[client] = false;
    }

    return true;
}

public Action ReloadModels(int client, int args) {

    // reset the model menu
    OnMapEnd();

    // rebuild it
    BuildMainMenu();
    BuildMainMenu(true);

    ReplyToCommand(client, "Hide and Seek: Reloaded config.");

    return Plugin_Handled;
}

// say /whoami
// displays the model name in chat again
public Action Display_ModelName(int client, int args) {
    // only enable command, if player already chose a model
    if (!IsPlayerAlive(client) || g_iModelChangeCount[client] == 0)
        return Plugin_Handled;

    // only Ts can use a model
    if (GetClientTeam(client) != CS_TEAM_T) {
        PrintToChat(client, "%s%t", PREFIX, "Only terrorists can use");
        return Plugin_Handled;
    }

    char modelName[128];
    GetClientModel(client, modelName, sizeof(modelName));
    PrintToChat(client, "%s%t\x01 %s.", PREFIX, "Model Changed", modelName);

    return Plugin_Handled;
}


