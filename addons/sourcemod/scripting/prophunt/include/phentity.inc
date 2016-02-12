#if defined _phentity_included
    #endinput
#endif
#define _phentity_included

#define MAXENTITIES 2048

int g_iEntities[MAXENTITIES+1] = {0, ...};
int g_iEntityChildren[MAXENTITIES+1] = {0, ...};
int g_iNumEntities = 0;

stock bool Entity_HasChild(int entity) {
    int child = g_iEntityChildren[entity];
    return child != 0 && IsValidEntity(child);
}

stock int Entity_GetChild(int entity) {
    return g_iEntityChildren[entity];
}

stock void Entity_GetAbsOrigin(int entity, float vec[3]) {
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vec);
}

stock void Entity_GetAbsAngles(int entity, float vec[3]) {
    GetEntPropVector(entity, Prop_Send, "m_angAbsRotation", vec);
}

stock void Entity_GetVelocity(int entity, float vec[3]) {
    GetEntPropVector(entity, Prop_Send, "m_vecAbsVelocity", vec);
}

stock void Entity_SetMovementSpeed(int entity, float speed) {
    SetEntPropFloat(entity, Prop_Send, "m_flLaggedMovementValue", speed);
}

stock void Entity_SetChild(int entity, int child) {
    if (Entity_HasChild(entity))
        Entity_RemoveChild(entity);

    g_iEntityChildren[entity] = child;
    Entity_AttachChild(entity);
    g_iNumEntities++;
 }

stock void Entity_RemoveChild(int entity) {
    if (g_iEntityChildren[entity] != 0) {
        Entity_DetachChild(entity);
        if (Entity_HasChild(entity))
            AcceptEntityInput(Entity_GetChild(entity), "kill");

        g_iEntityChildren[entity] = 0;
        g_iNumEntities--;
    }
}

stock void Entity_AttachChild(int entity) {
    if (Entity_HasChild(entity)) {
        int child = Entity_GetChild(entity);
        Entity_TeleportTo(child, entity);

        SetVariantString("!activator");
        AcceptEntityInput(child, "SetParent", entity, child, 0);
    }
}

stock void Entity_DetachChild(int entity) {
    if (Entity_HasChild(entity)) {
        SetVariantString("");
        AcceptEntityInput(Entity_GetChild(entity), "ClearParent");
    }
}

stock void Entity_TeleportTo(int entity, int target, const float ang[3]=NULL_VECTOR, const float vel[3]=NULL_VECTOR) {
    float orig[3];
    Entity_GetAbsOrigin(target, orig);
    TeleportEntity(entity, orig, ang, vel);
}
