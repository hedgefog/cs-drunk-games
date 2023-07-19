#pragma semicolon 1

#include <amxmodx>

#include <drunkgames>

#define PLUGIN "[Drunk Games] Player Radio"
#define VERSION DRUNKGAME_VERSION
#define AUTHOR "Hedgehog Fog"

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_clcmd("radio1", "Command_Radio1");
    register_clcmd("radio2", "Command_Radio2");
    register_clcmd("radio3", "Command_Radio3");
    register_clcmd("radio4", "Command_Radio4");

    register_message(get_user_msgid("SendAudio"), "Message_SendAudio");
}

public Command_Radio1(pPlayer) {
    return PLUGIN_HANDLED;
}

public Command_Radio2(pPlayer) {
    return PLUGIN_HANDLED;
}

public Command_Radio3(pPlayer) {
    return PLUGIN_HANDLED;
}

public Command_Radio4(pPlayer) {
    return PLUGIN_HANDLED;
}

public Message_SendAudio()  {
    static szAudio[8];
    get_msg_arg_string(2, szAudio, charsmax(szAudio));

    return equali(szAudio, "%!MRAD_", 7) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}
