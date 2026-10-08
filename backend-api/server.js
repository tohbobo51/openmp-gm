'use strict';

require('dotenv').config();

const express = require('express');
const mysql = require('mysql2/promise');
const { OAuth2Client } = require('google-auth-library');
const { rateLimit } = require('express-rate-limit');
const { createGameTicket, sha256Hex, isGoogleNonce } = require('./auth-ticket');
const { validateRegistration } = require('./registration');

const app = express();
const PORT = Number(process.env.PORT || 3000);
const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID || process.env.GOOGLE_WEB_CLIENT_ID || '';
const googleClient = new OAuth2Client();

const dbConfig = {
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
};
const hasDatabaseConfig = Boolean(
  dbConfig.host && dbConfig.user && dbConfig.password && dbConfig.database
);
const db = hasDatabaseConfig
  ? mysql.createPool({
      ...dbConfig,
      waitForConnections: true,
      connectionLimit: 5,
      queueLimit: 0,
      timezone: 'Z',
      charset: 'utf8mb4',
    })
  : null;

app.disable('x-powered-by');
app.set('trust proxy', 1);
app.use(express.json({ limit: '16kb', type: 'application/json' }));

const mobileAuthLimiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  limit: 12,
  standardHeaders: true,
  legacyHeaders: false,
  message: { code: 'RATE_LIMITED' },
});

let ticketTableReady;
async function ensureTicketTable() {
  if (!db) {
    throw new Error('database_not_configured');
  }
  if (!ticketTableReady) {
    ticketTableReady = db.query(`
      CREATE TABLE IF NOT EXISTS auth_login_tickets (
        ticket_hash CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
        id_token_hash CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
        ucp_id INT NOT NULL,
        character_id INT NOT NULL,
        expires_at DATETIME(3) NOT NULL,
        id_token_expires_at DATETIME(3) NOT NULL,
        consumed_at DATETIME(3) NULL,
        created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
        PRIMARY KEY (ticket_hash),
        UNIQUE KEY uq_auth_login_tickets_id_token (id_token_hash),
        KEY idx_auth_login_tickets_expiry (expires_at),
        KEY idx_auth_login_tickets_character (character_id)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    `).catch((error) => {
      ticketTableReady = null;
      throw error;
    });
  }
  await ticketTableReady;
}

function sendCode(res, status, code) {
  return res.status(status).json({ code });
}

app.get('/', (_req, res) => {
  res.json({
    status: 'online',
    service: 'Vice Side Roleplay native Google auth API',
    nativeAuthReady: Boolean(GOOGLE_CLIENT_ID && hasDatabaseConfig),
    endpoints: ['POST /auth/google/mobile'],
  });
});

// Disable the old CEF flow: it returned client-supplied Google IDs without
// server-side ID-token verification and must not be used for game login.
app.all(['/auth/google', '/auth/google/callback'], (_req, res) => {
  res.status(410).json({ code: 'LEGACY_CEF_AUTH_DISABLED' });
});

app.post('/auth/google/mobile', mobileAuthLimiter, async (req, res) => {
  if (!GOOGLE_CLIENT_ID) {
    return sendCode(res, 503, 'GOOGLE_CLIENT_NOT_CONFIGURED');
  }
  if (!hasDatabaseConfig || !db) {
    return sendCode(res, 503, 'DATABASE_NOT_CONFIGURED');
  }

  const idToken = req.body && req.body.idToken;
  const nonce = req.body && req.body.nonce;
  if (typeof idToken !== 'string' || idToken.length < 100 || idToken.length > 8192
      || !isGoogleNonce(nonce)) {
    return sendCode(res, 400, 'INVALID_AUTH_REQUEST');
  }

  let payload;
  try {
    const verified = await googleClient.verifyIdToken({
      idToken,
      audience: GOOGLE_CLIENT_ID,
    });
    payload = verified.getPayload();
  } catch (_error) {
    return sendCode(res, 401, 'INVALID_GOOGLE_TOKEN');
  }

  if (!payload || typeof payload.sub !== 'string' || !payload.sub
      || typeof payload.email !== 'string' || !payload.email || payload.email.length > 128
      || payload.email_verified !== true || payload.nonce !== nonce
      || !Number.isFinite(Number(payload.exp))) {
    return sendCode(res, 401, 'INVALID_GOOGLE_TOKEN');
  }

  const idTokenHash = sha256Hex(idToken);
  const rawTicket = createGameTicket();
  const ticketHash = sha256Hex(rawTicket);
  const idTokenExpiresAt = new Date(Number(payload.exp) * 1000);
  const ticketExpiresAt = new Date(Date.now() + 90 * 1000);
  let connection;

  try {
    await ensureTicketTable();
    connection = await db.getConnection();
    await connection.beginTransaction();

    const [accounts] = await connection.execute(
      'SELECT id, ucp_name FROM ucp_accounts WHERE google_id = ? LIMIT 1',
      [String(payload.sub)]
    );
    let account = accounts[0] || null;
    let registration = null;

    if (!account) {
      if (!req.body.registration) {
        await connection.rollback();
        return sendCode(res, 403, 'REGISTRATION_REQUIRED');
      }
      const checked = validateRegistration(req.body.registration, { requireUcpName: true });
      if (!checked.ok) {
        await connection.rollback();
        return sendCode(res, 400, checked.code);
      }
      registration = checked.value;

      // Never silently link an existing UCP account by email alone.
      const [emailAccounts] = await connection.execute(
        'SELECT id FROM ucp_accounts WHERE LOWER(google_email) = LOWER(?) LIMIT 1',
        [String(payload.email).toLowerCase()]
      );
      if (emailAccounts.length > 0) {
        await connection.rollback();
        return sendCode(res, 409, 'ACCOUNT_LINK_REQUIRED');
      }

      const [ucpNames] = await connection.execute(
        'SELECT id FROM ucp_accounts WHERE LOWER(ucp_name) = LOWER(?) LIMIT 1',
        [registration.ucpName]
      );
      if (ucpNames.length > 0) {
        await connection.rollback();
        return sendCode(res, 409, 'UCP_NAME_TAKEN');
      }

      const [characterNames] = await connection.execute(
        'SELECT id FROM characters WHERE LOWER(character_name) = LOWER(?) LIMIT 1',
        [registration.characterName]
      );
      if (characterNames.length > 0) {
        await connection.rollback();
        return sendCode(res, 409, 'CHARACTER_NAME_TAKEN');
      }

      const [accountResult] = await connection.execute(
        'INSERT INTO ucp_accounts (google_id, google_email, ucp_name) VALUES (?, ?, ?)',
        [String(payload.sub), String(payload.email).toLowerCase(), registration.ucpName]
      );
      account = { id: accountResult.insertId, ucp_name: registration.ucpName };
    }

    let [characters] = await connection.execute(
      'SELECT id, character_name FROM characters WHERE ucp_id = ? ORDER BY id ASC LIMIT 1',
      [account.id]
    );

    if (characters.length === 0) {
      if (!req.body.registration) {
        await connection.rollback();
        return sendCode(res, 409, 'CHARACTER_REGISTRATION_REQUIRED');
      }
      const checked = validateRegistration(req.body.registration, { requireUcpName: false });
      if (!checked.ok) {
        await connection.rollback();
        return sendCode(res, 400, checked.code);
      }
      registration = checked.value;

      const [characterNames] = await connection.execute(
        'SELECT id FROM characters WHERE LOWER(character_name) = LOWER(?) LIMIT 1',
        [registration.characterName]
      );
      if (characterNames.length > 0) {
        await connection.rollback();
        return sendCode(res, 409, 'CHARACTER_NAME_TAKEN');
      }

      const [characterResult] = await connection.execute(
        `INSERT INTO characters
          (ucp_id, character_name, birthplace, birthdate, gender, height, weight)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [account.id, registration.characterName, registration.birthplace,
          registration.birthdate, registration.gender, registration.height, registration.weight]
      );
      characters = [{ id: characterResult.insertId, character_name: registration.characterName }];
    }

    // Store only one-way hashes. A Google ID token can be exchanged once,
    // even if its game ticket later expires or is consumed.
    await connection.execute(
      'DELETE FROM auth_login_tickets WHERE id_token_expires_at <= UTC_TIMESTAMP(3)'
    );
    await connection.execute(
      `INSERT INTO auth_login_tickets
        (ticket_hash, id_token_hash, ucp_id, character_id, expires_at, id_token_expires_at)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [ticketHash, idTokenHash, account.id, characters[0].id, ticketExpiresAt, idTokenExpiresAt]
    );

    await connection.commit();
    return res.status(200).json({
      ok: true,
      loginName: `AUTH${rawTicket}`,
      characterName: characters[0].character_name,
      expiresAt: ticketExpiresAt.toISOString(),
    });
  } catch (error) {
    if (connection) {
      try {
        await connection.rollback();
      } catch (_rollbackError) {
        // Do not expose database credentials, token data, or driver details.
      }
    }
    if (error && error.code === 'ER_DUP_ENTRY') {
      if (String(error.message || '').includes('uq_auth_login_tickets_id_token')) {
        return sendCode(res, 409, 'GOOGLE_TOKEN_REPLAYED');
      }
      return sendCode(res, 409, 'REGISTRATION_CONFLICT');
    }
    console.error('[native-google-auth] request failed:',
      error && (error.code || error.name) || 'unknown');
    return sendCode(res, 503, 'AUTH_SERVICE_UNAVAILABLE');
  } finally {
    if (connection) {
      connection.release();
    }
  }
});

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Native Google auth API listening on port ${PORT}`);
  });
}

module.exports = app;
