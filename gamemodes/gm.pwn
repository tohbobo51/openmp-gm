/*
 * ========================================================================
 *         VICE SIDE ROLEPLAY - OPEN.MP GAMEMODE CORE (gm.pwn)
 * ========================================================================
 * Platform: Open.MP Linux x86 (v1.5.8.3079) / SA-MP Android & PC
 * Integrasi: CEF (Chromium Embedded Framework) + MySQL Google OAuth 2.0
 * Server IP: 142.132.203.47:10125
 * Developer: @tohbobo51
 * ========================================================================
 */

#include <open.mp>
#include <a_mysql>
#include <cef>

// ========================================================================
// 1. KONFIGURASI DATABASE & SERVER (SESUAIKAN DENGAN LEMEHOST ANDA)
// ========================================================================

// Konfigurasi Server
#define SERVER_NAME         "Vice Side Roleplay"
#define SERVER_VERSION      "v1.0.0 Open.MP"
#define SERVER_HOST         "142.132.203.47:10125"

// Definisi CEF Browser ID
#define CEF_BROWSER_HUD     1000
#define CEF_BROWSER_AUTH    1001

// Lokasi Spawn Default (City Hall / Pershing Square Los Santos)
#define DEFAULT_SPAWN_X     1481.0425
#define DEFAULT_SPAWN_Y     -1750.0450
#define DEFAULT_SPAWN_Z     15.4453
#define DEFAULT_SPAWN_A     0.0

// Definisi Warna
#define COLOR_WHITE         0xFFFFFFFF
#define COLOR_GREY          0xAFAFAFAA
#define COLOR_YELLOW        0xFFFF00AA
#define COLOR_PURPLE        0xC2A2DAAA
#define COLOR_LIGHTBLUE     0x33CCFFAA
#define COLOR_GREEN         0x33AA33AA
#define COLOR_RED           0xAA3333AA
#define COLOR_ORANGE        0xFF9900AA

// ========================================================================
// 2. DATA STRUKTUR PLAYER & KARAKTER
// ========================================================================
enum E_PLAYER_DATA
{
    pUcpId,
    pGoogleId[64],
    pGoogleEmail[128],
    pUcpName[32],
    pCharacterName[24],
    pBirthplace[64],
    pBirthdate[16],
    pGender[8],
    pHeight,
    pWeight,
    pMoney,
    pBankMoney,
    pSkin,
    Float:pPosX,
    Float:pPosY,
    Float:pPosZ,
    Float:pPosA,
    pInterior,
    pVirtualWorld,
    bool:pLoggedIn,
    bool:pHasCef
};

new PlayerData[MAX_PLAYERS][E_PLAYER_DATA];
new MySQL:g_SQL;

// Forward deklarasi untuk event receiver CEF

// Forward deklarasi query callback
forward OnAccountCreated(playerid, ucpId);

// ========================================================================
// 3. MAIN & GAMEMODE INITIALIZATION
// ========================================================================
main()
{
    print("\n---------------------------------------------------------");
    print("      " SERVER_NAME " (" SERVER_VERSION ")");
    print("      Server Hosting: " SERVER_HOST);
    print("      Google OAuth 2.0 & CEF WebView Active");
    print("      Developer: @tohbobo51 | Open.MP Linux x86");
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

    // Inisialisasi Database MySQL
    new MySQLOpt:options = mysql_init_options();
    mysql_set_option(options, AUTO_RECONNECT, true);

    g_SQL = mysql_connect_file("scriptfiles/mysql.ini");
    if (mysql_errno(g_SQL) != 0)
    {
        printf("[MYSQL ERROR] mysql_connect_file(\"scriptfiles/mysql.ini\") failed. Error ID: %d", mysql_errno(g_SQL));
    }
    else
    {
        print("[MYSQL SUCCESS] Berhasil terhubung ke database MySQL LemeHost!");
    }

    // Registrasi Resource CEF (scriptfiles/cef/auth dan scriptfiles/cef/roleplay)
    CEF_AddResource("auth");
    CEF_AddResource("roleplay");

    // Registrasi Event Bridge dari CEF JavaScript ke Pawn

    // Default skins
    AddPlayerClass(299, DEFAULT_SPAWN_X, DEFAULT_SPAWN_Y, DEFAULT_SPAWN_Z, DEFAULT_SPAWN_A, WEAPON_FIST, 0, WEAPON_FIST, 0, WEAPON_FIST, 0);
    AddPlayerClass(101, DEFAULT_SPAWN_X, DEFAULT_SPAWN_Y, DEFAULT_SPAWN_Z, DEFAULT_SPAWN_A, WEAPON_FIST, 0, WEAPON_FIST, 0, WEAPON_FIST, 0);
    return 1;
}

public OnGameModeExit()
{
    if (g_SQL != MYSQL_INVALID_HANDLE)
    {
        mysql_close(g_SQL);
    }
    return 1;
}

// ========================================================================
// 4. CEF INITIALIZATION & PLAYER CONNECT
// ========================================================================
public OnCefInitialize(playerid, bool:success, E_CEF_INIT_REASON:reason, const message[])
{
    PlayerData[playerid][pHasCef] = success;
    if (success)
    {
        if (PlayerData[playerid][pLoggedIn])
        {
            CEF_CreateBrowser(playerid, CEF_BROWSER_HUD, "http://cef/roleplay/index.html", false, true, 0.0, 0.0);
            CEF_EmitEvent(playerid, CEF_BROWSER_HUD, "updateStats", CEF_INT(PlayerData[playerid][pMoney]), CEF_FLOAT(100.0), CEF_FLOAT(0.0));
        }
        else
        {
            SendClientMessage(playerid, COLOR_YELLOW, "[LOGIN] Gunakan launcher dan login Google sebelum masuk ke server.");
        }
    }
    else
    {
        SendClientMessage(playerid, COLOR_YELLOW, "[INFO] CEF tidak tersedia; login tetap dilakukan melalui launcher.");
    }
    return 1;
}

public OnPlayerConnect(playerid)
{
    PlayerData[playerid][pLoggedIn] = false;
    PlayerData[playerid][pHasCef] = false;
    PlayerData[playerid][pMoney] = 500;
    PlayerData[playerid][pSkin] = 299;

    SendClientMessage(playerid, COLOR_LIGHTBLUE, "==========================================================");
    SendClientMessage(playerid, COLOR_WHITE, "Selamat datang di {FF9900}" SERVER_NAME "{FFFFFF}!");
    SendClientMessage(playerid, COLOR_GREY, "Login Google harus dilakukan dari launcher resmi.");
    SendClientMessage(playerid, COLOR_LIGHTBLUE, "==========================================================");

    new playerName[MAX_PLAYER_NAME + 1];
    new loginTicket[17];
    GetPlayerName(playerid, playerName, sizeof(playerName));
    if (strlen(playerName) != 20 || strcmp(playerName, "AUTH", false, 4) != 0)
    {
        SendClientMessage(playerid, COLOR_RED, "[LOGIN] Tiket launcher tidak ditemukan atau sudah kedaluwarsa.");
        SetTimerEx("KickUnauthenticatedPlayer", 1200, false, "d", playerid);
        return 1;
    }

    strmid(loginTicket, playerName, 4, 20, sizeof(loginTicket));
    for (new i = 0; i < 16; i++)
    {
        new ch = loginTicket[i];
        if (!((ch >= 'A' && ch <= 'Z' && ch != 'I' && ch != 'O') || (ch >= '2' && ch <= '9')))
        {
            SendClientMessage(playerid, COLOR_RED, "[LOGIN] Format tiket tidak valid.");
            SetTimerEx("KickUnauthenticatedPlayer", 1200, false, "d", playerid);
            return 1;
        }
    }

    new query[512];
    mysql_format(g_SQL, query, sizeof(query),
        "UPDATE auth_login_tickets SET consumed_at = UTC_TIMESTAMP(3) WHERE ticket_hash = LOWER(SHA2('%e', 256)) AND consumed_at IS NULL AND expires_at > UTC_TIMESTAMP(3) LIMIT 1;",
        loginTicket
    );
    mysql_tquery(g_SQL, query, "OnAuthTicketClaimed", "ds", playerid, loginTicket);
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    if (PlayerData[playerid][pHasCef])
    {
        CEF_DestroyBrowser(playerid, CEF_BROWSER_HUD);
    }
    PlayerData[playerid][pLoggedIn] = false;
    return 1;
}

forward OnAuthTicketClaimed(playerid, const loginTicket[]);
forward KickUnauthenticatedPlayer(playerid);
forward OnAccountCheckLogin(playerid, const loginTicket[]);

public OnAuthTicketClaimed(playerid, const loginTicket[])
{
    if (!IsPlayerConnected(playerid)) return 1;
    if (cache_affected_rows() != 1)
    {
        SendClientMessage(playerid, COLOR_RED, "[LOGIN] Tiket tidak valid, sudah dipakai, atau kedaluwarsa.");
        SetTimerEx("KickUnauthenticatedPlayer", 1200, false, "d", playerid);
        return 1;
    }

    new playerName[MAX_PLAYER_NAME + 1];
    new expectedName[21];
    format(expectedName, sizeof(expectedName), "AUTH%s", loginTicket);
    GetPlayerName(playerid, playerName, sizeof(playerName));
    if (strcmp(playerName, expectedName, false) != 0) return 1;

    new query[768];
    mysql_format(g_SQL, query, sizeof(query),
        "SELECT c.*, u.id AS ucp_account_id, u.google_email, u.google_id, u.ucp_name FROM auth_login_tickets t INNER JOIN ucp_accounts u ON u.id = t.ucp_id INNER JOIN characters c ON c.id = t.character_id AND c.ucp_id = u.id WHERE t.ticket_hash = LOWER(SHA2('%e', 256)) AND t.consumed_at IS NOT NULL AND t.expires_at > UTC_TIMESTAMP(3) LIMIT 1;",
        loginTicket
    );
    mysql_tquery(g_SQL, query, "OnAccountCheckLogin", "ds", playerid, loginTicket);
    return 1;
}

public KickUnauthenticatedPlayer(playerid)
{
    if (IsPlayerConnected(playerid)) Kick(playerid);
    return 1;
}

public OnAccountCheckLogin(playerid, const loginTicket[])
{
    if (!IsPlayerConnected(playerid)) return 1;
    new playerName[MAX_PLAYER_NAME + 1];
    new expectedName[21];
    format(expectedName, sizeof(expectedName), "AUTH%s", loginTicket);
    GetPlayerName(playerid, playerName, sizeof(playerName));
    if (strcmp(playerName, expectedName, false) != 0) return 1;

    new rows = cache_num_rows();
    if (rows > 0)
    {
        cache_get_value_name(0, "google_email", PlayerData[playerid][pGoogleEmail], 128);
        cache_get_value_name(0, "google_id", PlayerData[playerid][pGoogleId], 64);
        cache_get_value_name(0, "ucp_name", PlayerData[playerid][pUcpName], 32);
        // Ambil data karakter yang terikat pada tiket sesi.
        cache_get_value_name_int(0, "ucp_account_id", PlayerData[playerid][pUcpId]);
        cache_get_value_name(0, "character_name", PlayerData[playerid][pCharacterName], 24);
        cache_get_value_name(0, "birthplace", PlayerData[playerid][pBirthplace], 64);
        cache_get_value_name(0, "birthdate", PlayerData[playerid][pBirthdate], 16);
        cache_get_value_name(0, "gender", PlayerData[playerid][pGender], 8);
        cache_get_value_name_int(0, "height", PlayerData[playerid][pHeight]);
        cache_get_value_name_int(0, "weight", PlayerData[playerid][pWeight]);
        cache_get_value_name_int(0, "money", PlayerData[playerid][pMoney]);
        cache_get_value_name_int(0, "skin", PlayerData[playerid][pSkin]);
        cache_get_value_name_float(0, "pos_x", PlayerData[playerid][pPosX]);
        cache_get_value_name_float(0, "pos_y", PlayerData[playerid][pPosY]);
        cache_get_value_name_float(0, "pos_z", PlayerData[playerid][pPosZ]);
        cache_get_value_name_float(0, "pos_a", PlayerData[playerid][pPosA]);
        cache_get_value_name_int(0, "interior", PlayerData[playerid][pInterior]);
        cache_get_value_name_int(0, "virtual_world", PlayerData[playerid][pVirtualWorld]);

        PlayerData[playerid][pLoggedIn] = true;

        // Ubah nama pemain di dalam server menjadi Nama IC
        SetPlayerName(playerid, PlayerData[playerid][pCharacterName]);

        // Berikan uang dan skin
        ResetPlayerMoney(playerid);
        GivePlayerMoney(playerid, PlayerData[playerid][pMoney]);
        SetPlayerSkin(playerid, PlayerData[playerid][pSkin]);

        // Hancurkan WebView login
        if (PlayerData[playerid][pHasCef])
        {
            // Buat HUD Roleplay
            CEF_CreateBrowser(playerid, CEF_BROWSER_HUD, "http://cef/roleplay/index.html", false, true, 0.0, 0.0);
            CEF_EmitEvent(playerid, CEF_BROWSER_HUD, "updateStats", CEF_INT(PlayerData[playerid][pMoney]), CEF_FLOAT(100.0), CEF_FLOAT(0.0));
        }

        // Spawn pemain ke posisi tersimpan
        SpawnPlayer(playerid);

        new welcomeMsg[128];
        format(welcomeMsg, sizeof(welcomeMsg), "{33CCFF}[LOGIN SUCCESS] Selamat datang kembali, {FFFFFF}%s {33CCFF}(UCP: %s)!", PlayerData[playerid][pCharacterName], PlayerData[playerid][pUcpName]);
        SendClientMessage(playerid, COLOR_LIGHTBLUE, welcomeMsg);
    }
    else
    {
        SendClientMessage(playerid, COLOR_RED, "[LOGIN] Karakter tidak ditemukan. Hubungi administrator server.");
        SetTimerEx("KickUnauthenticatedPlayer", 1500, false, "d", playerid);
    }
    return 1;
}

// ========================================================================
// 6. EVENT RECEIVER: REGISTER GOOGLE & KARAKTER IC
// ========================================================================
// Native launcher registration is intentionally not exposed through CEF.

public OnPlayerRequestSpawn(playerid)
{
    if (!PlayerData[playerid][pLoggedIn]) return 0;
    return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
    if (!PlayerData[playerid][pLoggedIn]) return 0;
    return 1;
}

public OnPlayerSpawn(playerid)
{
    if (!PlayerData[playerid][pLoggedIn])
    {
        SetTimerEx("KickUnauthenticatedPlayer", 1200, false, "d", playerid);
        return 1;
    }
    SetPlayerInterior(playerid, PlayerData[playerid][pInterior]);
    SetPlayerVirtualWorld(playerid, PlayerData[playerid][pVirtualWorld]);
    SetPlayerPos(playerid, PlayerData[playerid][pPosX], PlayerData[playerid][pPosY], PlayerData[playerid][pPosZ]);
    SetPlayerFacingAngle(playerid, PlayerData[playerid][pPosA]);
    SetCameraBehindPlayer(playerid);
    SetPlayerSkin(playerid, PlayerData[playerid][pSkin]);
    return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
    if (!strcmp(cmdtext, "/stats", true))
    {
        if (!PlayerData[playerid][pLoggedIn])
        {
            SendClientMessage(playerid, COLOR_RED, "[ERROR] Anda belum login!");
            return 1;
        }

        new str[144];
        SendClientMessage(playerid, COLOR_ORANGE, "========== STATISTIK KARAKTER ==========");
        format(str, sizeof(str), "Nama IC: %s | UCP: %s | Asal: %s", PlayerData[playerid][pCharacterName], PlayerData[playerid][pUcpName], PlayerData[playerid][pBirthplace]);
        SendClientMessage(playerid, COLOR_WHITE, str);
        format(str, sizeof(str), "Gender: %s | Lahir: %s | Tinggi: %d cm | Berat: %d kg", PlayerData[playerid][pGender], PlayerData[playerid][pBirthdate], PlayerData[playerid][pHeight], PlayerData[playerid][pWeight]);
        SendClientMessage(playerid, COLOR_WHITE, str);
        format(str, sizeof(str), "Uang: $%d | Skin ID: %d", GetPlayerMoney(playerid), GetPlayerSkin(playerid));
        SendClientMessage(playerid, COLOR_WHITE, str);
        SendClientMessage(playerid, COLOR_ORANGE, "=========================================");
        return 1;
    }

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

    if (!strcmp(cmdtext, "/help", true))
    {
        SendClientMessage(playerid, COLOR_LIGHTBLUE, "--- Perintah Vice Side Roleplay ---");
        SendClientMessage(playerid, COLOR_WHITE, "/stats - Melihat statistik karakter IC & data kelahiran");
        SendClientMessage(playerid, COLOR_WHITE, "/me [aksi] - Melakukan tindakan roleplay");
        SendClientMessage(playerid, COLOR_WHITE, "/do [keadaan] - Mendeskripsikan lingkungan sekitar");
        return 1;
    }

    return 0;
}
