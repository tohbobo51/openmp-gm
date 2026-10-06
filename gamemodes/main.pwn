/*
 * ========================================================================
 *                 Vice Side Roleplay - Open.MP Gamemode
 * ========================================================================
 * Server IP: 142.132.203.47:10125
 * Developed by: @tohbobo51
 * Core: Open.MP Linux x86 (v1.5.8.3079)
 * CEF Integration: aurora-mp/omp-cef
 * Automated CI/CD: devbluen/openmp-build-action
 * ========================================================================
 */

#include <open.mp>
#include <cef>

// Roleplay Color Definitions
#define COLOR_WHITE         0xFFFFFFFF
#define COLOR_GREY          0xAFAFAFAA
#define COLOR_YELLOW        0xFFFF00AA
#define COLOR_PURPLE        0xC2A2DAAA
#define COLOR_LIGHTBLUE     0x33CCFFAA
#define COLOR_GREEN         0x33AA33AA
#define COLOR_RED           0xAA3333AA
#define COLOR_ORANGE        0xFF9900AA

// Server Configuration Constants
#define SERVER_NAME         "Vice Side Roleplay"
#define SERVER_VERSION      "v1.0.0 Open.MP + CEF"
#define SERVER_HOST         "142.132.203.47:10125"

// CEF Browser ID Definitions
#define CEF_BROWSER_HUD     1000

// Default Spawn Position (Pershing Square / City Hall, Los Santos)
#define SPAWN_POS_X         1481.0425
#define SPAWN_POS_Y         -1750.0450
#define SPAWN_POS_Z         15.4453
#define SPAWN_POS_A         0.0

// Player State Variables
new bool:gPlayerHasCef[MAX_PLAYERS];

main()
{
    print("\n---------------------------------------------------------");
    print("      " SERVER_NAME " (" SERVER_VERSION ")");
    print("      Server Hosting Address: " SERVER_HOST);
    print("      CEF Engine: aurora-mp/omp-cef Enabled");
    print("      Developed by @tohbobo51 | Open.MP Linux x86");
    print("---------------------------------------------------------\n");
}

public OnGameModeInit()
{
    SetGameModeText(SERVER_NAME " " SERVER_VERSION);
    ShowNameTags(true);
    ShowPlayerMarkers(PLAYER_MARKERS_MODE_GLOBAL);
    EnableStuntBonusForAll(false);
    DisableInteriorEnterExits();
    UsePlayerPedAnims();

    // Register modern CEF Roleplay resource from scriptfiles/cef/roleplay
    CEF_AddResource("roleplay");

    // Default civilian classes
    AddPlayerClass(299, SPAWN_POS_X, SPAWN_POS_Y, SPAWN_POS_Z, SPAWN_POS_A, 0, 0, 0, 0, 0, 0);
    AddPlayerClass(101, SPAWN_POS_X, SPAWN_POS_Y, SPAWN_POS_Z, SPAWN_POS_A, 0, 0, 0, 0, 0, 0);
    AddPlayerClass(188, SPAWN_POS_X, SPAWN_POS_Y, SPAWN_POS_Z, SPAWN_POS_A, 0, 0, 0, 0, 0, 0);

    print("[INFO] Vice Side Roleplay with CEF initialized successfully.");
    return 1;
}

public OnGameModeExit()
{
    print("[INFO] Vice Side Roleplay gamemode unloaded.");
    return 1;
}

public OnCefInitialize(playerid, bool:success, E_CEF_INIT_REASON:reason, const message[])
{
    gPlayerHasCef[playerid] = success;

    if (success)
    {
        SendClientMessage(playerid, COLOR_GREEN, "[CEF] Modul Chromium Embedded Framework aktif & terhubung!");
        // Create custom HTML5 Roleplay HUD
        CEF_CreateBrowser(playerid, CEF_BROWSER_HUD, "http://cef/roleplay/index.html", false, true, 0.0, 0.0);
    }
    else
    {
        SendClientMessage(playerid, COLOR_GREY, "[INFO] Anda bermain menggunakan SA-MP standar tanpa CEF.");
    }
    return 1;
}

public OnPlayerConnect(playerid)
{
    gPlayerHasCef[playerid] = false;

    new playerName[MAX_PLAYER_NAME], str[144];
    GetPlayerName(playerid, playerName, sizeof(playerName));

    // Welcome player to server
    SendClientMessage(playerid, COLOR_LIGHTBLUE, "==========================================================");
    format(str, sizeof(str), "Selamat datang {FFFFFF}%s {33CCFF}di {FF9900}" SERVER_NAME "!", playerName);
    SendClientMessage(playerid, COLOR_LIGHTBLUE, str);
    SendClientMessage(playerid, COLOR_WHITE, "Server berjalan di platform {FFBB00}Open.MP Linux v1.5.8.3079 + CEF{FFFFFF}.");
    SendClientMessage(playerid, COLOR_GREY, "Gunakan {FFFFFF}/help {AFAFAF}untuk melihat daftar perintah roleplay.");
    SendClientMessage(playerid, COLOR_LIGHTBLUE, "==========================================================");

    format(str, sizeof(str), "{AFAFAF}[SERVER] {FFFFFF}%s {AFAFAF}bergabung ke server.", playerName);
    SendClientMessageToAll(COLOR_GREY, str);
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    if (gPlayerHasCef[playerid])
    {
        CEF_DestroyBrowser(playerid, CEF_BROWSER_HUD);
    }
    gPlayerHasCef[playerid] = false;

    new playerName[MAX_PLAYER_NAME], str[128];
    GetPlayerName(playerid, playerName, sizeof(playerName));
    format(str, sizeof(str), "{AFAFAF}[SERVER] {FFFFFF}%s {AFAFAF}meninggalkan server.", playerName);
    SendClientMessageToAll(COLOR_GREY, str);
    return 1;
}

public OnPlayerSpawn(playerid)
{
    SetPlayerInterior(playerid, 0);
    SetPlayerVirtualWorld(playerid, 0);
    SetPlayerPos(playerid, SPAWN_POS_X, SPAWN_POS_Y, SPAWN_POS_Z);
    SetPlayerFacingAngle(playerid, SPAWN_POS_A);
    SetCameraBehindPlayer(playerid);

    GivePlayerMoney(playerid, 500);
    SetPlayerHealth(playerid, 100.0);
    SetPlayerArmour(playerid, 0.0);

    SendClientMessage(playerid, COLOR_GREEN, "[SPAWN] Anda telah spawn di pusat kota Los Santos (City Hall).");

    // Sync stats with CEF HUD if connected
    if (gPlayerHasCef[playerid])
    {
        CEF_EmitEvent(playerid, CEF_BROWSER_HUD, "updateStats", CEF_INT(500), CEF_FLOAT(100.0), CEF_FLOAT(0.0));
    }
    return 1;
}

public OnPlayerDeath(playerid, killerid, WEAPON:reason)
{
    SendClientMessage(playerid, COLOR_RED, "[KEMATIAN] Anda telah pingsan / tewas. Respawn dalam beberapa detik...");
    return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
    SetPlayerPos(playerid, 1481.0, -1745.0, 15.5);
    SetPlayerCameraPos(playerid, 1481.0, -1740.0, 16.0);
    SetPlayerCameraLookAt(playerid, 1481.0, -1745.0, 15.5);
    return 1;
}

// Roleplay Chat & Commands
public OnPlayerText(playerid, text[])
{
    new playerName[MAX_PLAYER_NAME], formattedChat[160];
    GetPlayerName(playerid, playerName, sizeof(playerName));

    format(formattedChat, sizeof(formattedChat), "%s berkata: %s", playerName, text);
    SendClientMessage(playerid, COLOR_WHITE, formattedChat);

    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (IsPlayerConnected(i) && i != playerid)
        {
            if (IsPlayerInRangeOfPoint(i, 25.0, px, py, pz))
            {
                SendClientMessage(i, COLOR_WHITE, formattedChat);
            }
        }
    }
    return 0;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
    if (!strcmp(cmdtext, "/me", true, 3))
    {
        if (strlen(cmdtext) <= 4)
        {
            SendClientMessage(playerid, COLOR_GREY, "Gunakan: /me [tindakan roleplay]");
            return 1;
        }

        new playerName[MAX_PLAYER_NAME], str[160];
        GetPlayerName(playerid, playerName, sizeof(playerName));
        format(str, sizeof(str), "* %s %s", playerName, cmdtext[4]);

        new Float:px, Float:py, Float:pz;
        GetPlayerPos(playerid, px, py, pz);

        for (new i = 0; i < MAX_PLAYERS; i++)
        {
            if (IsPlayerConnected(i) && IsPlayerInRangeOfPoint(i, 25.0, px, py, pz))
            {
                SendClientMessage(i, COLOR_PURPLE, str);
            }
        }
        return 1;
    }

    if (!strcmp(cmdtext, "/do", true, 3))
    {
        if (strlen(cmdtext) <= 4)
        {
            SendClientMessage(playerid, COLOR_GREY, "Gunakan: /do [keadaan lingkungan]");
            return 1;
        }

        new playerName[MAX_PLAYER_NAME], str[160];
        GetPlayerName(playerid, playerName, sizeof(playerName));
        format(str, sizeof(str), "* %s (( %s ))", cmdtext[4], playerName);

        new Float:px, Float:py, Float:pz;
        GetPlayerPos(playerid, px, py, pz);

        for (new i = 0; i < MAX_PLAYERS; i++)
        {
            if (IsPlayerConnected(i) && IsPlayerInRangeOfPoint(i, 25.0, px, py, pz))
            {
                SendClientMessage(i, COLOR_YELLOW, str);
            }
        }
        return 1;
    }

    if (!strcmp(cmdtext, "/b", true, 2))
    {
        if (strlen(cmdtext) <= 3)
        {
            SendClientMessage(playerid, COLOR_GREY, "Gunakan: /b [pesan OOC]");
            return 1;
        }

        new playerName[MAX_PLAYER_NAME], str[160];
        GetPlayerName(playerid, playerName, sizeof(playerName));
        format(str, sizeof(str), "(( [OOC] %s: %s ))", playerName, cmdtext[3]);

        new Float:px, Float:py, Float:pz;
        GetPlayerPos(playerid, px, py, pz);

        for (new i = 0; i < MAX_PLAYERS; i++)
        {
            if (IsPlayerConnected(i) && IsPlayerInRangeOfPoint(i, 25.0, px, py, pz))
            {
                SendClientMessage(i, COLOR_GREY, str);
            }
        }
        return 1;
    }

    if (!strcmp(cmdtext, "/help", true))
    {
        SendClientMessage(playerid, COLOR_LIGHTBLUE, "--- Perintah Vice Side Roleplay ---");
        SendClientMessage(playerid, COLOR_WHITE, "/me [aksi] - Melakukan tindakan roleplay karakter");
        SendClientMessage(playerid, COLOR_WHITE, "/do [keadaan] - Mendeskripsikan lingkungan atau respon");
        SendClientMessage(playerid, COLOR_WHITE, "/b [chat] - Obrolan Out Of Character (OOC) lokal");
        SendClientMessage(playerid, COLOR_WHITE, "/stats - Melihat status karakter dan uang");
        SendClientMessage(playerid, COLOR_WHITE, "/cefhud - Toggle CEF web browser HUD");
        SendClientMessage(playerid, COLOR_WHITE, "/hostinfo - Melihat informasi koneksi hosting & IP server");
        return 1;
    }

    if (!strcmp(cmdtext, "/cefhud", true))
    {
        if (!gPlayerHasCef[playerid])
        {
            SendClientMessage(playerid, COLOR_YELLOW, "[CEF] Klien Anda belum terpasang omp-cef plugin.");
            return 1;
        }

        CEF_ReloadBrowser(playerid, CEF_BROWSER_HUD, true);
        SendClientMessage(playerid, COLOR_GREEN, "[CEF] Memuat ulang tampilan Roleplay HUD.");
        return 1;
    }

    if (!strcmp(cmdtext, "/stats", true))
    {
        new Float:health, Float:armour, str[128];
        GetPlayerHealth(playerid, health);
        GetPlayerArmour(playerid, armour);

        SendClientMessage(playerid, COLOR_ORANGE, "--- Statistik Karakter ---");
        format(str, sizeof(str), "Uang: $%d | HP: %.0f | Armor: %.0f", GetPlayerMoney(playerid), health, armour);
        SendClientMessage(playerid, COLOR_WHITE, str);

        if (gPlayerHasCef[playerid])
        {
            CEF_EmitEvent(playerid, CEF_BROWSER_HUD, "updateStats", CEF_INT(GetPlayerMoney(playerid)), CEF_FLOAT(health), CEF_FLOAT(armour));
        }
        return 1;
    }

    if (!strcmp(cmdtext, "/hostinfo", true))
    {
        SendClientMessage(playerid, COLOR_LIGHTBLUE, "--- Informasi Server Hosting ---");
        SendClientMessage(playerid, COLOR_WHITE, "Alamat IP: " SERVER_HOST);
        SendClientMessage(playerid, COLOR_WHITE, "Core Engine: Open.MP Linux x86 v1.5.8.3079 + CEF");
        SendClientMessage(playerid, COLOR_WHITE, "Developer: @tohbobo51 (Vice Side Roleplay)");
        return 1;
    }

    return 0;
}
