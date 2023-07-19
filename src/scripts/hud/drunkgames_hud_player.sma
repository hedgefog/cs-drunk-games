#pragma semicolon 1

#include <amxmodx>
#include <cssdk_const>

#include <drunkgames>

#define PLUGIN "[Drunk Games] Player HUD"
#define VERSION DRUNKGAME_VERSION
#define AUTHOR "Hedgehog Fog"

#define HIDE_HUD_FLAGS HIDEHUD_HEALTH | HIDEHUD_MONEY | HIDEHUD_CROSSHAIR

new gmsgHideWeapon;

public plugin_init()  {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    gmsgHideWeapon = get_user_msgid("HideWeapon");

    register_event("ResetHUD", "Event_ResetHUD", "b");
    register_message(gmsgHideWeapon, "Message_HideWeapon");
}

public Event_ResetHUD(pPlayer) {
    if (is_user_bot(pPlayer)) {
        return;
    }

    message_begin(MSG_ONE, gmsgHideWeapon, _, pPlayer);
    write_byte(HIDE_HUD_FLAGS);
    message_end();
}

public Message_HideWeapon() {
    set_msg_arg_int(1, ARG_BYTE, get_msg_arg_int(1) | HIDE_HUD_FLAGS);
}
