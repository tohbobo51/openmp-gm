/*
 * Open.MP Gamemode
 * Created for @tohbobo51
 * Server Version: Open.MP Linux x86 v1.5.8.3079
 * Automated CI/CD: devbluen/openmp-build-action
 */

#include <open.mp>

main()
{
    print("\n==============================================");
    print("   Open.MP Server Core - Gamemode Initialized  ");
    print("   Package: v1.5.8.3079 (Linux x86)           ");
    print("   Repository: github.com/tohbobo51/openmp-gm ");
    print("==============================================\n");
}

public OnGameModeInit()
{
    SetGameModeText("Open.MP GM v1.0");
    ShowPlayerMarkers(PLAYER_MARKERS_MODE_GLOBAL);
    ShowNameTags(true);
    EnableStuntBonusForAll(false);
    DisableInteriorEnterExits();

    // Default CJ spawn in Los Santos
    AddPlayerClass(0, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
    return 1;
}

public OnGameModeExit()
{
    return 1;
}

public OnPlayerConnect(playerid)
{
    new joinMessage[128], playerName[MAX_PLAYER_NAME];
    GetPlayerName(playerid, playerName, sizeof(playerName));
    format(joinMessage, sizeof(joinMessage), "{FFBB00}[SERVER]{FFFFFF} %s has connected to the Open.MP server.", playerName);
    SendClientMessageToAll(-1, joinMessage);
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    return 1;
}

public OnPlayerSpawn(playerid)
{
    SetPlayerInterior(playerid, 0);
    SetPlayerVirtualWorld(playerid, 0);
    SetPlayerPos(playerid, 1958.3783, 1343.1572, 15.3746);
    SetPlayerFacingAngle(playerid, 269.1425);
    SetCameraBehindPlayer(playerid);
    return 1;
}

public OnPlayerDeath(playerid, killerid, WEAPON:reason)
{
    return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
    SetPlayerPos(playerid, 1958.3783, 1343.1572, 15.3746);
    SetPlayerCameraPos(playerid, 1958.3783, 1347.1572, 15.3746);
    SetPlayerCameraLookAt(playerid, 1958.3783, 1343.1572, 15.3746);
    return 1;
}
