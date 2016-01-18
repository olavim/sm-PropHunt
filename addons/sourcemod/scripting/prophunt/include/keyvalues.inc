
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
 * Merges two KeyValues into one.
 *
 * @param kv_to         KeyValues handle to which new information should be written.
 * @param kv_form       KeyValues handle from which new information should be copied.
 * @noreturn
 */
stock void KvMerge(Handle kv_to, Handle kv_from) {
    bool keysExist = true;
    bool writeString = false;
    char key[128], value[128];

    //PrintToServer("debug: KvMerge start");
    if (KvGotoFirstSubKey(kv_from, false)) { // keep kv_from always one layer below kv_to
        //PrintToServer("debug: First GotoFirstSubKey");

        // get current section key
        KvGetSectionName(kv_from, key, sizeof(key));
        //PrintToServer("debug: section name is %s", key);

        if (KvGotoFirstSubKey(kv_from, false)) { // current key is a tree
            //PrintToServer("debug: Second GotoFirstSubKey");
            KvJumpToKey(kv_to, key, true); // create the key in kv_to if it didn't exist
            KvGoBack(kv_from); // kv_to and kv_from are on the same level now
        } else { // current key is not a tree
            //PrintToServer("debug: not a tree");
            writeString = true;
        }
    } else {
        KvGetSectionName(kv_from, key, sizeof(key));
        //PrintToServer("debug: section name is %s", key);
        keysExist = KvGotoNextKey(kv_from, false);
        writeString = true;
    }

    if (writeString) {
        KvGetString(kv_from, NULL_STRING, value, sizeof(value));
        if (StrEqual(value, ""))
            KvSetString(kv_to, key, value);
        //PrintToServer("Debug: key %s, value %s", key, value);
       
        // kv_from goes to the next key.
        // otherwise take both KeyValues up one level until kv_from can go to the next key.
        while (!KvGotoNextKey(kv_from, false)) {
            //PrintToServer("debug: no next key");

            // break if kv_to is at the root node (and kv_from is at the second level)
            if (KvNodesInStack(kv_to) == 0) {
                //PrintToServer("debug: set keysExist to false");

                // we have no more keys we can traverse
                keysExist = false;
                break;
            }

            KvGoBack(kv_to);
            KvGoBack(kv_from);
        }
    }

    if (keysExist) {

        // tail-recursive call
        KvMerge(kv_to, kv_from);
    } else {
        //PrintToServer("debug: no keys exist");
        KvRewind(kv_to);
        KvRewind(kv_from);
    }
}

