
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
