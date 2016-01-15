#if defined _phentity_included
    #endinput
#endif
#define _phentity_included

#define MAXENTITIES 2048

methodmap PHEntity __nullable__
{
    /**
     * Creates a new PHEntity wrapper for an entity.
     *
     * @param entity     Entity to wrap.
     */
    public native PHEntity(int entity);

    /**
     * Returns the underlying entity.
     */ 
    property int index {
        public native get();
    }

    property bool isValid {
        
    }

    /**
     * Returns true if this entity has a child entity,
     * and the child is a valid entity.
     */
    property bool hasChild {
        public native get();
    }

    /**
     * Returns the entity whose parent this entity is,
     * if any.
     */
    property PHEntity child {
        public native get();
    }

    /**
     * Gets the absolute origin (position) of this entity.
     * 
     * @param vec       Vector array to hold the origin.
     * @noreturn
     */ 
    public native void GetOrigin(float vec[3]);

    /**
     * Gets the absolute angles (rotation) of this entity.
     * 
     * @param vec       Vector array to hold the angles.
     * @noreturn
     */ 
    public native void GetAbsAngles(float vec[3]);

    /**
     * Gets the absolute velocity of this entity.
     * 
     * @param vec       Vector array to hold the velocity.
     * @noreturn
     */ 
    public native void GetVelocity(float vec[3]);

    /**
     * Sets this entity's movetype.
     * @noreturn
     */
    public native void SetMoveType(MoveType mt);

    /**
     * Sets this entity's movement speed multiplier.
     *
     * @param speed     New speed multiplier. 1.0 for original speed.
     * @noreturn
     */
    public native void SetMovementSpeed(float speed);

    /**
     * Makes this entity an entity's parent.
     *
     * @param entity    Child entity.
     * @noreturn
     */
    public native void SetChild(PHEntity entity);

    /**
     * Detaches and forgets the entity whose parent this entity is.
     * Attaching will no more be possible with AttachChild().
     *
     * @noreturn
     */
    public native void RemoveChild();

    /**
     * Attaches this entity's child to this entity, if previously detached.
     * Not possible if the child has been removed.
     *
     * @noreturn
     */
    public native void AttachChild();
    
    /**
     * Detaches this entity's child from this entity. It may be reattached
     * with AttachChild().
     *
     * @noreturn
     */
    public native void DetachChild(); 

    /**
     * Teleports this entity.
     *
     * @param origin    New origin (position), or NULL_VECTOR for no change.
     * @param angles    New angles, or NULL_VECTOR for no change.
     * @param velocity    New velocity (position), or NULL_VECTOR for no change.
     * @noreturn
     */
    public native void Teleport(const float origin[3], const float angles[3], const float velocity[3]);

    /**
     * Teleports this entity to another entity.
     *
     * @param target        Target.
     * @noreturn
     */
    public native void TeleportTo(PHEntity target);

}

PHEntity g_iEntities[MAXENTITIES+1] = {null, ...};
PHEntity g_iEntityChildren[MAXENTITIES+1] = {null, ...};

stock PHEntity GetPHEntity(int entity) {
    if (entity < 1 || entity > MAXENTITIES)
        return null;

    return g_iEntities[entity];
}

stock PHEntity RegisterPHEntity(int entity) {
    if (entity < 1 || entity > MAXENTITIES)
        return null;

    g_iEntities[entity] = new PHEntity(entity);
    return g_iEntities[entity];
}

stock void UnregisterPHEntity(int _entity) {
    PHEntity entity = GetPHEntity(_entity);
    if (entity) {
        entity.RemoveChild();
        g_iEntities[entity.index] = null;
    }
}
