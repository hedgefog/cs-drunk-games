#pragma semicolon 1

#include <amxmodx>

#include <drunkgames>

#define PLUGIN "[Drunk Games] Win Message HUD"
#define VERSION DRUNKGAME_VERSION
#define AUTHOR "Hedgehog Fog"

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_message(get_user_msgid("TextMsg"), "Message_TextMsg");
    register_message(get_user_msgid("SendAudio"), "Message_SendAudio");
}

public Message_TextMsg(iMsgId, iDest, pPlayer) {
    if (!DrunkGames_IsFreeForAll()) {
        return PLUGIN_CONTINUE;
    }

    static szMessage[32];
    get_msg_arg_string(2, szMessage, charsmax(szMessage));

    if (equal(szMessage, "#Terrorists_Win")) {
        return PLUGIN_HANDLED;
    }

    if (equal(szMessage, "#CTs_Win")) {
        return PLUGIN_HANDLED;
    }

    if (equal(szMessage, "#Round_Draw")) {
        if (DrunkGames_GetWinnerNum()) {
            return PLUGIN_HANDLED;
        }
    }

    return PLUGIN_CONTINUE;
}

public Message_SendAudio(iMsgId, iDest, pPlayer) {
    if (!DrunkGames_IsFreeForAll()) {
        return PLUGIN_CONTINUE;
    }

    static szMessage[32];
    get_msg_arg_string(2, szMessage, charsmax(szMessage));

    if (equal(szMessage[7], "terwin")) {
        return PLUGIN_HANDLED;
    }

    if (equal(szMessage[7], "ctwin")) {
        return PLUGIN_HANDLED;
    }

    if (equal(szMessage[7], "rounddraw")) {
        if (DrunkGames_GetWinnerNum()) {
            return PLUGIN_HANDLED;
        }
    }

    return PLUGIN_CONTINUE;
}
