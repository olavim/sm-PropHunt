
#define MAX_SECTION_LENGTH  128

/**
 * Returns the name of a key or section at a specific index
 * under a section/tree
 *
 * @param kv        KeyValues handle.
 * @param index     Index of the wanted key.
 * @param key       Buffer in which to hold the key's name.
 * @param maxlength Max length of the buffer.
 * @return          True on success, otherwise false.
 */
stock bool KvGetKeyByIndex(Handle kv, int index, char[] key, int maxlength) {
    if (!KvGotoFirstSubKey(kv, false))
        return false;

    for (int i = 0; i < index; i++) {
        if (!KvGotoNextKey(kv, false))
            return false;
    }

    KvGetSectionName(kv, key, maxlength);
    KvGoBack(kv);
    return true;
}

/**
 * Returns the value of a key at a specific index
 * under a section/tree
 *
 * @param kv        KeyValues handle.
 * @param index     Index of the wanted key.
 * @param key       Buffer in which to hold the value.
 * @param maxlength Max length of the buffer.
 * @return          True on success, otherwise false.
 */
stock bool KvGetStringByIndex(Handle kv, int index, char[] value, int maxlength) {
    char section[MAX_SECTION_LENGTH];
    if (!KvGetKeyByIndex(kv, index, section, sizeof(section)))
        return false;

    KvGetString(kv, section, value, maxlength);
    return true;
}

/**
 * Returns whether ot not the current key is an empty tree (section).
 *
 * @param kv    KeyValues handle.
 * @return      True if current key is a tree and is empty, false otherwise.
 */
stock bool KvIsEmptyTree(Handle kv) {
    if (KvGotoFirstSubKey(kv, false)) {
        KvGoBack(kv);
        return false;
    }

    char value[128];
    KvGetString(kv, NULL_STRING, value, sizeof(value), "#novalue");
    return StrEqual(value, "#novalue"); // is it an empty tree
}

/**
 * Returns whether ot not the current key is a tree (section).
 *
 * @param kv    KeyValues handle.
 * @return      True if current key is a tree (section), false otherwise.
 */
stock bool KvIsTree(Handle kv) {
    if (KvGotoFirstSubKey(kv, false)) {
        KvGoBack(kv);
        return true;
    }

    char value[128];
    KvGetString(kv, NULL_STRING, value, sizeof(value), "#novalue");
    return StrEqual(value, "#novalue"); // is it an empty tree
}

/**
 * Returns whether or not the current section has a specific subkey.
 *
 * @param kv    KeyValues handle.
 * @return      True if current key exists under current key, false otherwise.
 */
stock bool KvKeyExists(Handle kv, char[] key) {
    bool keyExists;
    if (keyExists = KvJumpToKey(kv, key))
        KvGoBack(kv);
    
    return keyExists;
}

/**
 * Jumps to a key that is on the same level as the current one,
 * if such a key exists.
 *
 * @param kv    KeyValues handle.
 * @return      True if the key existed, false otherwise.
 */
stock bool KvJumpToSiblingKey(Handle kv, char[] target) {
    char start[MAX_SECTION_LENGTH];
    KvGetSectionName(kv, start, sizeof(start));

    if (KvNodesInStack(kv) == 0)
        return StrEqual(start, target);

    KvGoBack(kv);
    if (KvJumpToKey(kv, target))
        return true;

    KvJumpToKey(kv, start);
    return false;
}

/**
 * Merges two KeyValues into one.
 *
 * @param kv_to         KeyValues handle to which new information should be written.
 * @param kv_form       KeyValues handle from which new information should be copied.
 * @noreturn
 */
stock void KvMerge(Handle kv_to, Handle kv_from) {
    char key_from[MAX_SECTION_LENGTH];
    do {
        KvGetSectionName(kv_from, key_from, sizeof(key_from));

        if (KvIsEmptyTree(kv_from)) {
            KvGoBack(kv_to);
            KvJumpToKey(kv_to, key_from, true); 
        } else if (KvIsTree(kv_from)) {
            KvGotoFirstSubKey(kv_from, false);

            if (!KvJumpToSiblingKey(kv_to, key_from)) {
                KvJumpToKey(kv_to, key_from, true);
                KvGetSectionName(kv_from, key_from, sizeof(key_from));
                if (KvIsTree(kv_from)) {
                    KvJumpToKey(kv_to, key_from, true);
                    KvGoBack(kv_to);
                } else {
                    KvGetString(kv_from, NULL_STRING, value_from, sizeof(value_from));
                    KvSetString(kv_to, key_from, value_from);
                }
            }

            KvGotoFirstSubKey(kv_to, false);

            KvMerge(kv_to, kv_from);

            KvGoBack(kv_from);
            KvGoBack(kv_to);
        } else {
            KvGetString(kv_from, NULL_STRING, value_from, sizeof(value_from));
            KvGoBack(kv_to);
            KvSetString(kv_to, key_from, value_from);
            KvGotoFirstSubKey(kv_to, false);
        }
    } while (KvGotoNextKey(kv_from, false));
}

stock void KvAddIncludes(KeyValues kv) {
    ArrayStack includes = new ArrayStack(PLATFORM_MAX_PATH);
    ArrayStack recurses = new ArrayStack(4);
    ArrayList processed = new ArrayList(PLATFORM_MAX_PATH);
    kv.Rewind();

    char key[PLATFORM_MAX_PATH], recurseStr[4];
    char path[PLATFORM_MAX_PATH], include[PLATFORM_MAX_PATH];

    for (;;) {
        if (kv.JumpToKey("#include") && kv.GotoFirstSubKey(false)) {
            do {
                kv.GetSectionName(key, sizeof(key));
                kv.GetString("recurse", recurseStr, sizeof(recurseStr), "yes");

                if (processed.FindString(key) == -1) {
                    includes.PushString(key);
                    recurses.PushString(recurseStr);
                }
            } while (kv.DeleteThis() == 1);
        }

        kv.Rewind();
        if (includes.Empty)
            break;

        includes.PopString(include, sizeof(include));
        recurses.PopString(recurseStr, sizeof(recurseStr));
        processed.PushString(include);
        BuildPath(Path_SM, path, sizeof(path), "configs/prophunt/maps/%s", include); 
        KeyValues kv2 = CreateKeyValues("Models");

        if (FileToKeyValues(kv2, path)) {
            PrintToServer("[PropHunt] Included file: %s, recurse: %s", path, recurseStr);

            if (StrEqual(recurseStr, "no"))
                if (kv2.JumpToKey("#include"))
                    kv2.DeleteThis();

            kv2.Rewind();
            KvMerge(kv, kv2);
        } else {
            PrintToServer("[PropHunt] No such file: %s", path);
        }

        CloseHandle(kv2);
    }

    kv.Rewind();
}

