
#include "prophunt/include/phentity.inc"

public int Native_PHEntity(Handle plugin, int numParams) {
    return GetNativeCell(1);
}

public int Native_PHEntity_GetIndex(Handle plugin, int numParams) {
    PHEntity entity = view_as<PHEntity>(GetNativeCell(1));
    return view_as<int>(entity); 
}

public int Native_PHEntity_GetHasChild(Handle plugin, int numParams) {
    PHEntity entity = view_as<PHEntity>(GetNativeCell(1));
    PHEntity child = g_iEntityChildren[entity.index];
    return child != null && IsValidEntity(child.index);
}

public int Native_PHEntity_GetChild(Handle plugin, int numParams) {
    PHEntity entity = view_as<PHEntity>(GetNativeCell(1));
    return view_as<int>(g_iEntityChildren[entity.index]);
}

public int Native_PHEntity_GetOrigin(Handle plugin, int numParams) {
    PHEntity entity = view_as<PHEntity>(GetNativeCell(1));
    float orig[3];
    GetEntPropVector(entity.index, Prop_Send, "m_vecOrigin", orig);
    return SetNativeArray(2, orig, 3);
}

public int Native_PHEntity_GetAbsAngles(Handle plugin, int numParams) {
    PHEntity entity = view_as<PHEntity>(GetNativeCell(1));
    float ang[3];
    GetEntPropVector(entity.index, Prop_Send, "m_angAbsRotation", ang);
    return SetNativeArray(2, ang, 3);
}

public int Native_PHEntity_GetVelocity(Handle plugin, int numParams) {
    PHEntity entity = view_as<PHEntity>(GetNativeCell(1));
    float vel[3];
    GetEntPropVector(entity.index, Prop_Send, "m_vecAbsVelocity", vel);
    return SetNativeArray(2, vel, 3);
}

public int Native_PHEntity_SetMoveType(Handle plugin, int numParams) {
    PHEntity entity = view_as<PHEntity>(GetNativeCell(1));
    MoveType mt = view_as<MoveType>(GetNativeCell(2));
    SetEntityMoveType(entity.index, mt);
}

public int Native_PHEntity_SetMovementSpeed(Handle plugin, int numParams) {
    PHEntity entity = view_as<PHEntity>(GetNativeCell(1));
    float speed = view_as<float>(GetNativeCell(2));
    SetEntPropFloat(entity.index, Prop_Send, "m_flLaggedMovementValue", speed);
}

public int Native_PHEntity_SetChild(Handle plugin, int numParams) {
    PHEntity entity = view_as<PHEntity>(GetNativeCell(1));
    if (entity.hasChild)
        entity.RemoveChild();

    PHEntity child = view_as<PHEntity>(GetNativeCell(2));
    if (IsValidEntity(child.index)) {
        g_iEntityChildren[entity.index] = child;
        entity.AttachChild();
    }
}

public int Native_PHEntity_RemoveChild(Handle plugin, int numParams) {
    PHEntity entity = view_as<PHEntity>(GetNativeCell(1));
    if (entity.hasChild) {
        entity.DetachChild();
        g_iEntityChildren[entity.index] = null;
    }
}

public int Native_PHEntity_AttachChild(Handle plugin, int numParams) {
    PHEntity entity = view_as<PHEntity>(GetNativeCell(1));
    if (entity.hasChild) {
        entity.child.TeleportTo(entity);

        SetVariantString("!activator");
        AcceptEntityInput(entity.child.index, "SetParent", entity.index, entity.child.index, 0);
    }
}

public int Native_PHEntity_DetachChild(Handle plugin, int numParams) {
    PHEntity entity = view_as<PHEntity>(GetNativeCell(1));
    if (entity.hasChild) {
        SetVariantString("");
        AcceptEntityInput(entity.child.index, "ClearParent");

        entity.child.TeleportTo(entity);
    }
}

public int Native_PHEntity_Teleport(Handle plugin, int numParams) {
    PHEntity entity = view_as<PHEntity>(GetNativeCell(1));
    float orig[3], ang[3], vel[3];
    GetNativeArray(2, orig, 3);
    GetNativeArray(3, ang, 3);
    GetNativeArray(4, vel, 3);
    TeleportEntity(entity.index, orig, ang, vel);
}

public int Native_PHEntity_TeleportTo(Handle plugin, int numParams) {
    PHEntity entity = view_as<PHEntity>(GetNativeCell(1));
    PHEntity target = view_as<PHEntity>(GetNativeCell(2));
    float orig[3];

    target.GetOrigin(orig);
    entity.Teleport(orig, NULL_VECTOR, NULL_VECTOR);
}

