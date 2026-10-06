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
#define MYSQL_HOST          "142.132.203.47"
#define MYSQL_USER          "u289578_mReRZTCxjz"
#define MYSQL_PASS          "FroO15LuABiyU=.5^TLCiFhE"
#define MYSQL_DATABASE      "s289578_db1791315867361"
#define MYSQL_PORT          3306

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
forward OnGoogleLoginEvent(playerid, const email[], const googleId[], const ucpName[]);
forward OnGoogleRegisterEvent(playerid, const email[], const googleId[], const ucpName[], const characterName[], const birthplace[], const birthdate[], const gender[], height, weight);

// Forward deklarasi query callback
forward OnAccountCheckLogin(playerid, const googleId[]);
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

    g_SQL = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DATABASE, options);
    if (mysql_errno(g_SQL) != 0)
    {
        printf("[MYSQL ERROR] Gagal terhubung ke MySQL (%s) Error ID: %d", MYSQL_HOST, mysql_errno(g_SQL));
    }
    else
    {
        print("[MYSQL SUCCESS] Berhasil terhubung ke database MySQL LemeHost!");
    }

    // Registrasi Resource CEF (scriptfiles/cef/auth dan scriptfiles/cef/roleplay)
    CEF_AddResource("auth");
    CEF_AddResource("roleplay");

    // Registrasi Event Bridge dari CEF JavaScript ke Pawn
    CEF_RegisterEvent("OnGoogleLogin", "OnGoogleLoginEvent", Argument_String, Argument_String, Argument_String);
    CEF_RegisterEvent("OnGoogleRegister", "OnGoogleRegisterEvent", Argument_String, Argument_String, Argument_String, Argument_String, Argument_String, Argument_String, Argument_String, Argument_Integer, Argument_Integer);

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
        SendClientMessage(playerid, COLOR_GREEN, "[CEF] WebView siap. Membuka formulir login Google OAuth...");
        // Buka WebView CEF Login Google secara otomatis (Fokus & kontrol kursor diaktifkan)
        CEF_CreateBrowser(playerid, CEF_BROWSER_AUTH, "http://cef/auth/index.html", true, true, 0.0, 0.0);
    }
    else
    {
        SendClientMessage(playerid, COLOR_YELLOW, "[INFO] Perangkat Anda belum memiliki CEF. Bermain dengan mode standar.");
    }
    return 1;
}

public OnPlayerConnect(playerid)
{
    // Reset data pemain
    PlayerData[playerid][pLoggedIn] = false;
    PlayerData[playerid][pHasCef] = false;
    PlayerData[playerid][pMoney] = 500;
    PlayerData[playerid][pSkin] = 299;

    SendClientMessage(playerid, COLOR_LIGHTBLUE, "==========================================================");
    SendClientMessage(playerid, COLOR_WHITE, "Selamat datang di {FF9900}" SERVER_NAME "{FFFFFF}!");
    SendClientMessage(playerid, COLOR_GREY, "Sistem pendaftaran & login terintegrasi dengan Google OAuth 2.0.");
    SendClientMessage(playerid, COLOR_LIGHTBLUE, "==========================================================");
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    if (PlayerData[playerid][pHasCef])
    {
        CEF_DestroyBrowser(playerid, CEF_BROWSER_AUTH);
        CEF_DestroyBrowser(playerid, CEF_BROWSER_HUD);
    }
    PlayerData[playerid][pLoggedIn] = false;
    return 1;
}

// ========================================================================
// 5. EVENT RECEIVER: LOGIN GOOGLE
// ========================================================================
public OnGoogleLoginEvent(playerid, const email[], const googleId[], const ucpName[])
{
    printf("[LOGIN] Menerima event Google Login untuk ID: %s (Email: %s)", googleId, email);

    format(PlayerData[playerid][pGoogleEmail], 128, "%s", email);
    format(PlayerData[playerid][pGoogleId], 64, "%s", googleId);
    format(PlayerData[playerid][pUcpName], 32, "%s", ucpName);

    // Query ke MySQL untuk mengambil data karakter
    new query[320];
    mysql_format(g_SQL, query, sizeof(query), 
        "SELECT c.*, u.id as ucp_account_id FROM characters c INNER JOIN ucp_accounts u ON c.ucp_id = u.id WHERE u.google_id = '%e' LIMIT 1;", 
        googleId
    );
    mysql_tquery(g_SQL, query, "OnAccountCheckLogin", "ds", playerid, googleId);
    return 1;
}

public OnAccountCheckLogin(playerid, const googleId[])
{
    new rows = cache_num_rows();
    if (rows > 0)
    {
        // Ambil data karakter dari database
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
            CEF_DestroyBrowser(playerid, CEF_BROWSER_AUTH);
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
        SendClientMessage(playerid, COLOR_YELLOW, "[INFO] Akun Google Anda belum memiliki karakter IC. Silakan isi form di layar.");
    }
    return 1;
}

// ========================================================================
// 6. EVENT RECEIVER: REGISTER GOOGLE & KARAKTER IC
// ========================================================================
public OnGoogleRegisterEvent(playerid, const email[], const googleId[], const ucpName[], const characterName[], const birthplace[], const birthdate[], const gender[], height, weight)
{
    printf("[REGISTER] Pembuatan karakter baru: %s (UCP: %s, Asal: %s)", characterName, ucpName, birthplace);

    // Simpan ke struct lokal
    format(PlayerData[playerid][pGoogleEmail], 128, "%s", email);
    format(PlayerData[playerid][pGoogleId], 64, "%s", googleId);
    format(PlayerData[playerid][pUcpName], 32, "%s", ucpName);
    format(PlayerData[playerid][pCharacterName], 24, "%s", characterName);
    format(PlayerData[playerid][pBirthplace], 64, "%s", birthplace);
    format(PlayerData[playerid][pBirthdate], 16, "%s", birthdate);
    format(PlayerData[playerid][pGender], 8, "%s", gender);
    PlayerData[playerid][pHeight] = height;
    PlayerData[playerid][pWeight] = weight;
    PlayerData[playerid][pMoney] = 500;
    PlayerData[playerid][pSkin] = (!strcmp(gender, "Female", true)) ? 193 : 299; // Skin default sesuai gender
    PlayerData[playerid][pPosX] = DEFAULT_SPAWN_X;
    PlayerData[playerid][pPosY] = DEFAULT_SPAWN_Y;
    PlayerData[playerid][pPosZ] = DEFAULT_SPAWN_Z;
    PlayerData[playerid][pPosA] = DEFAULT_SPAWN_A;
    PlayerData[playerid][pLoggedIn] = true;

    // 1. Insert atau Update UCP Account ke MySQL
    new queryUcp[320];
    mysql_format(g_SQL, queryUcp, sizeof(queryUcp),
        "INSERT INTO ucp_accounts (google_id, google_email, ucp_name) VALUES ('%e', '%e', '%e') ON DUPLICATE KEY UPDATE ucp_name = '%e';",
        googleId, email, ucpName, ucpName
    );
    mysql_query(g_SQL, queryUcp);

    // Ambil UCP ID yang baru dibuat
    new ucpId = cache_insert_id();
    if (ucpId == 0)
    {
        // Jika sudah ada sebelumnya, ambil id-nya
        new fetchQuery[200];
        mysql_format(g_SQL, fetchQuery, sizeof(fetchQuery), "SELECT id FROM ucp_accounts WHERE google_id = '%e' LIMIT 1;", googleId);
        new Cache:result = mysql_query(g_SQL, fetchQuery);
        if (cache_num_rows() > 0)
        {
            cache_get_value_name_int(0, "id", ucpId);
        }
        cache_delete(result);
    }
    PlayerData[playerid][pUcpId] = ucpId;

    // 2. Insert Karakter Baru ke Tabel characters
    new queryChar[500];
    mysql_format(g_SQL, queryChar, sizeof(queryChar),
        "INSERT INTO characters (ucp_id, character_name, birthplace, birthdate, gender, height, weight, money, skin, pos_x, pos_y, pos_z, pos_a) \
         VALUES (%d, '%e', '%e', '%e', '%e', %d, %d, 500, %d, %.4f, %.4f, %.4f, %.4f);",
        ucpId, characterName, birthplace, birthdate, gender, height, weight, PlayerData[playerid][pSkin],
        DEFAULT_SPAWN_X, DEFAULT_SPAWN_Y, DEFAULT_SPAWN_Z, DEFAULT_SPAWN_A
    );
    mysql_query(g_SQL, queryChar);

    // Set nama pemain di dalam server menjadi Nama Karakter IC baru
    SetPlayerName(playerid, characterName);

    // Berikan modal awal
    ResetPlayerMoney(playerid);
    GivePlayerMoney(playerid, 500);
    SetPlayerSkin(playerid, PlayerData[playerid][pSkin]);

    // Hancurkan WebView login
    if (PlayerData[playerid][pHasCef])
    {
        CEF_DestroyBrowser(playerid, CEF_BROWSER_AUTH);
        // Buat HUD Roleplay
        CEF_CreateBrowser(playerid, CEF_BROWSER_HUD, "http://cef/roleplay/index.html", false, true, 0.0, 0.0);
        CEF_EmitEvent(playerid, CEF_BROWSER_HUD, "updateStats", CEF_INT(500), CEF_FLOAT(100.0), CEF_FLOAT(0.0));
    }

    // Spawn ke titik awal Los Santos
    SpawnPlayer(playerid);

    new msg[144];
    format(msg, sizeof(msg), "{33AA33}[REGISTER SUCCESS] Selamat datang di Vice Side, {FFFFFF}%s {33AA33}(Uang Awal: $500, Asal: %s)!", characterName, birthplace);
    SendClientMessage(playerid, COLOR_GREEN, msg);
    return 1;
}

// ========================================================================
// 7. SPAWN HANDLER & ROLEPLAY COMMANDS
// ========================================================================
public OnPlayerSpawn(playerid)
{
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
