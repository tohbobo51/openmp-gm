# Vice Side Roleplay — Open.MP Gamemode

Paket gamemode Open.MP Linux dengan kompilasi dan packaging melalui GitHub Actions (`devbluen/openmp-build-action`). Repository ini juga memuat API autentikasi Google dan skema MySQL.

## Isi utama

- `gamemodes/gm.pwn` — gamemode utama.
- `backend-api/` — API Node.js untuk autentikasi Google native.
- `database/schema.sql` — tabel akun, karakter, dan tiket sesi.
- `scriptfiles/mysql.ini.example` — contoh konfigurasi MySQL privat.
- `.github/workflows/` — alur build Open.MP.

## Alur login native

1. Launcher Android meminta ID token melalui Google Credential Manager dan membuat nonce acak.
2. Launcher mengirim ID token dan nonce melalui HTTPS ke `POST /auth/google/mobile`.
3. API memverifikasi tanda tangan token, audience (`GOOGLE_CLIENT_ID`), email terverifikasi, expiry, dan nonce; API hanya menerima akun UCP dan karakter yang sudah ada.
4. API membuat tiket acak sekali pakai yang berlaku 90 detik. Database hanya menyimpan hash SHA-256 tiket dan hash ID token.
5. Launcher menghubungkan game dengan nickname sementara `AUTH` + tiket. Gamemode mengklaim tiket sekali pakai di MySQL, lalu mengganti nickname ke karakter yang terikat pada tiket.

ID token Google tidak dikirim ke gamemode/MySQL, tidak dicatat ke Logcat, dan tidak disimpan oleh launcher. Endpoint OAuth lama berbasis CEF dinonaktifkan karena menerima Google ID dari sisi client tanpa verifikasi token server-side.

## Konfigurasi API

Salin `backend-api/.env.example` menjadi `.env` untuk pengembangan lokal, lalu isi variabel melalui penyimpanan rahasia host deployment (misalnya Vercel):

- `GOOGLE_CLIENT_ID` — **Web application OAuth client ID**, bukan Android client ID. Web client dan Android client harus berada di Google Cloud project yang sama.
- `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASS`, `DB_NAME` — koneksi database.

Jangan commit `.env`, password database, client secret, maupun `scriptfiles/mysql.ini`. API ini tidak lagi memakai Google client secret atau callback browser. `auth_login_tickets` dibuat otomatis oleh API; skema yang sama juga tersedia di `database/schema.sql`.

Hak akses database API perlu mencakup `SELECT` pada `ucp_accounts` dan `characters`, serta `CREATE`, `SELECT`, `INSERT`, dan `DELETE` pada tabel tiket. Gamemode membutuhkan `SELECT` dan `UPDATE` untuk mengklaim tiket, selain akses tabel gameplay yang sudah digunakan.

## Konfigurasi launcher Android

Build client memerlukan variabel build-time berikut:

- `GOOGLE_WEB_CLIENT_ID` — Web application OAuth client ID yang sama persis dengan `GOOGLE_CLIENT_ID` backend.
- `AUTH_API_BASE_URL` — base URL API; default source saat ini `https://openmp-gm.vercel.app`.

OAuth Android client di Google Cloud juga harus cocok dengan package name dan SHA-1 sertifikat release yang dipakai APK. Jangan simpan Google client secret di APK.

## Konfigurasi Open.MP dan database

1. Rotasi password MySQL jika sebelumnya pernah tersimpan pada file contoh/config yang masuk Git.
2. Di server, salin `scriptfiles/mysql.ini.example` menjadi `scriptfiles/mysql.ini`, lalu isi host, username, password baru, database, dan port. File `mysql.ini` aktif di-ignore oleh Git.
3. Pastikan server Open.MP dan API dapat mengakses database yang sama; batasi akses database ke host yang diperlukan.
4. Pastikan tabel `ucp_accounts` dan `characters` tersedia dan akun Google telah memiliki karakter.
5. Jalankan server:
   ```bash
   chmod +x omp-server
   ./omp-server --config config.json
   ```

**Pendaftaran akun/karakter baru belum tersedia dalam alur launcher native ini.** Login hanya berhasil untuk akun yang sudah tercatat pada `ucp_accounts` dengan karakter pada `characters`; user tanpa karakter ditolak dan perlu bantuan administrator sampai alur registrasi native ditambahkan.

## Build

Push ke branch `main` menjalankan workflow build gamemode. Workflow menghasilkan deployment Windows, Linux standard, dan Linux dynamic sebagai artifacts. Build API lokal:

```bash
cd backend-api
npm ci
npm test
npm start
```
