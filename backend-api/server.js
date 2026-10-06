const express = require('express');
const cors = require('cors');
const axios = require('axios');
const mysql = require('mysql2/promise');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;

// Database Connection Pool (LemeHost)
const db = mysql.createPool({
    host: process.env.DB_HOST || '142.132.203.47',
    port: process.env.DB_PORT || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASS || '',
    database: process.env.DB_NAME || 'samp',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// 1. Endpoint Awal Login Google OAuth
app.get('/auth/google', (req, res) => {
    const clientId = process.env.GOOGLE_CLIENT_ID;
    const redirectUri = process.env.GOOGLE_CALLBACK_URL;
    const scope = encodeURIComponent('openid email profile');
    
    // Redirect ke Google Accounts OAuth consent screen
    const googleAuthUrl = `https://accounts.google.com/o/oauth2/v2/auth?response_type=code&client_id=${clientId}&redirect_uri=${encodeURIComponent(redirectUri)}&scope=${scope}&access_type=offline&prompt=select_account`;
    
    res.redirect(googleAuthUrl);
});

// 2. Endpoint Callback Google OAuth
app.get('/auth/google/callback', async (req, res) => {
    const { code } = req.query;
    
    if (!code) {
        return res.status(400).send('Authorization code tidak ditemukan.');
    }

    try {
        // Exchange authorization code dengan access token
        const tokenResponse = await axios.post('https://oauth2.googleapis.com/token', {
            code,
            client_id: process.env.GOOGLE_CLIENT_ID,
            client_secret: process.env.GOOGLE_CLIENT_SECRET,
            redirect_uri: process.env.GOOGLE_CALLBACK_URL,
            grant_type: 'authorization_code'
        });

        const { access_token } = tokenResponse.data;

        // Ambil profil user dari Google Userinfo API
        const profileResponse = await axios.get('https://www.googleapis.com/oauth2/v2/userinfo', {
            headers: { Authorization: `Bearer ${access_token}` }
        });

        const googleUser = profileResponse.data;
        const googleId = googleUser.id;
        const email = googleUser.email;
        // Sanitasi display name untuk UCP Name (hanya alfanumerik)
        const rawName = (googleUser.name || email.split('@')[0]).replace(/[^a-zA-Z0-9]/g, '');
        const ucpName = rawName.substring(0, 20) || `UCP${googleId.substring(0, 6)}`;

        // Cek apakah UCP sudah terdaftar di MySQL
        const [ucpRows] = await db.query(
            'SELECT * FROM ucp_accounts WHERE google_id = ? LIMIT 1',
            [googleId]
        );

        let status = 'REGISTER';
        let character = null;

        if (ucpRows.length > 0) {
            const ucp = ucpRows[0];
            // Cek apakah karakter IC sudah dibuat
            const [charRows] = await db.query(
                'SELECT * FROM characters WHERE ucp_id = ? LIMIT 1',
                [ucp.id]
            );

            if (charRows.length > 0) {
                status = 'LOGIN';
                character = charRows[0];
            } else {
                status = 'REGISTER';
            }
        }

        // Return HTML respon yang langsung berkomunikasi dengan CEF Browser di dalam game
        const clientPayload = {
            status,
            email,
            googleId,
            ucpName,
            characterName: character ? character.character_name : ''
        };

        res.send(`
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="utf-8">
                <title>Google Auth Complete</title>
                <style>
                    body { font-family: sans-serif; background: #09090b; color: #fff; text-align: center; padding: 40px; }
                    .card { background: #18181b; padding: 25px; border-radius: 12px; max-width: 400px; margin: auto; }
                    .success { color: #22c55e; font-weight: bold; }
                </style>
            </head>
            <body>
                <div class="card">
                    <p class="success">Autentikasi Google Berhasil!</p>
                    <p>Menghubungkan ke game...</p>
                </div>
                <script>
                    const data = ${JSON.stringify(clientPayload)};
                    
                    // Jika di dalam WebView game open.mp CEF
                    if (window.cef) {
                        if (data.status === "LOGIN") {
                            cef.emit("OnGoogleLogin", data.email, data.googleId, data.ucpName);
                        } else {
                            // Buka form registrasi karakter IC
                            window.location.href = "http://cef/auth/index.html?step=register&email=" + encodeURIComponent(data.email) + "&googleId=" + encodeURIComponent(data.googleId) + "&ucpName=" + encodeURIComponent(data.ucpName);
                        }
                    } else if (window.opener) {
                        window.opener.postMessage(data, "*");
                        window.close();
                    } else {
                        // Fallback redirect ke file CEF lokal
                        window.location.href = "http://cef/auth/index.html?step=" + data.status.toLowerCase() + "&email=" + encodeURIComponent(data.email) + "&googleId=" + encodeURIComponent(data.googleId) + "&ucpName=" + encodeURIComponent(data.ucpName);
                    }
                </script>
            </body>
            </html>
        `);

    } catch (err) {
        console.error('Error Google OAuth Callback:', err.response?.data || err.message);
        res.status(500).send(`<h3>Gagal melakukan verifikasi Google:</h3><p>${err.message}</p>`);
    }
});

app.get('/', (req, res) => {
    res.json({
        status: 'online',
        service: 'Vice Side Roleplay - Open.MP Google OAuth API',
        endpoints: ['/auth/google', '/auth/google/callback']
    });
});

app.listen(PORT, () => {
    console.log(`Backend Auth API running on port ${PORT}`);
});
