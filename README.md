# Vice Side Roleplay — Open.MP Gamemode

Paket gamemode Open.MP Linux dengan kompilasi dan packaging melalui GitHub Actions (`devbluen/openmp-build-action`). Repository ini juga memuat API autentikasi Google dan skema MySQL.

## Isi utama

- `gamemodes/gm.pwn` — gamemode utama.
- `backend-api/` — API Node.js untuk autentikasi Google native dan pendaftaran akun/karakter.
- `database/schema.sql` — tabel akun, karakter, dan tiket sesi.
- `scriptfiles/mysql.ini.example` — contoh konfigurasi MySQL privat.
- `.github/workflows/` — alur build Open.MP.

## Login dan pendaftaran Google native

1. Launcher Android meminta ID token melalui Google Credential Manager dan membuat nonce acak.
2. Launcher mengirim ID token dan nonce melalui HTTPS ke `POST /auth/google/mobile`.
3. API memverifikasi tanda tangan token, audience (`GOOGLE_CLIENT_ID`), email terverifikasi, expiry, dan nonce.
4. Jika Google identity belum punya akun, launcher menampilkan form pendaftaran. Pendaftaran membuat akun UCP dan karakter dalam satu transaksi MySQL; tiket login hanya terbit setelah keduanya tersimpan.
5. Form meminta nama UCP (3–31 karakter ASCII), nama karakter `NamaDepan_NamaBelakang` (maksimal 23 karakter ASCII), tempat/tanggal lahir karakter, dan gender karakter. Tinggi/berat memakai default server 175 cm/70 kg.
6. API membuat tiket acak sekali pakai yang berlaku 90 detik. Database hanya menyimpan hash SHA-256 tiket dan hash ID token.
7. Launcher menghubungkan game dengan nickname sementara `AUTH` + tiket. Gamemode mengklaim tiket sekali pakai di MySQL, lalu mengganti nickname ke karakter yang terikat pada tiket.

ID token Google tidak dikirim ke gamemode/MySQL, tidak dicatat ke Logcat, dan tidak disimpan oleh launcher. Email dan Google subject diambil dari token terverifikasi, bukan dari nilai yang dikirim aplikasi. Jika email sudah dipakai akun dengan Google identity berbeda, API tidak menautkannya otomatis; administrator harus membantu proses penautan agar akun lama tidak dapat diambil alih. Endpoint OAuth lama berbasis CEF tetap dinonaktifkan.

## Konfigurasi API

Salin `backend-api/.env.example` menjadi `.env` untuk pengembangan lokal, lalu isi variabel melalui penyimpanan rahasia host deployment (misalnya Vercel):

- `GOOGLE_CLIENT_ID` — **Web application OAuth client ID**, bukan Android client ID. Web client dan Android client harus berada di Google Cloud project yang sama.
- `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASS`, `DB_NAME` — koneksi database.

Jangan commit `.env`, password database, client secret, maupun `scriptfiles/mysql.ini`. API ini tidak lagi memakai Google client secret atau callback browser. `auth_login_tickets` dibuat otomatis oleh API; skema yang sama juga tersedia di `database/schema.sql`.

Akun database API memerlukan `SELECT` dan `INSERT` pada `ucp_accounts` serta `characters`, juga `CREATE`, `SELECT`, `INSERT`, dan `DELETE` pada `auth_login_tickets`. Gamemode membutuhkan `SELECT` dan `UPDATE` untuk mengklaim tiket, selain akses tabel gameplay yang sudah digunakan.

## Konfigurasi launcher Android

Build client memerlukan variabel build-time berikut:

- `GOOGLE_WEB_CLIENT_ID` — Web application OAuth client ID yang sama persis dengan `GOOGLE_CLIENT_ID` backend.
- `AUTH_API_BASE_URL` — base URL API; default source saat ini `https://openmp-gm.vercel.app`.

OAuth Android client di Google Cloud juga harus cocok dengan package name dan SHA-1 sertifikat release yang dipakai APK. Jangan simpan Google client secret di APK.

## Konfigurasi Open.MP dan database

1. Rotasi password MySQL jika sebelumnya pernah tersimpan pada file contoh/config yang masuk Git.
2. Di panel file hosting, salin `mysql.ini.example` ke direktori root server (contoh: `/home/container/mysql.ini`), lalu isi host, username, password baru, database, dan port. R41-4 `mysql_connect_file` hanya menerima nama file dan mencari `mysql.ini` di root server; jangan taruh file ini di `scriptfiles/` dan jangan tambahkan path direktori pada pemanggilannya. Opsi koneksi seperti `auto_reconnect` dibaca dari dalam file INI. File aktif `mysql.ini` di-ignore oleh Git.
3. Pastikan server Open.MP dan API dapat mengakses database yang sama; batasi akses database ke host yang diperlukan.
4. Pastikan tabel `ucp_accounts` dan `characters` tersedia sesuai `database/schema.sql`. `ucp_name`, Google ID/email, dan nama karakter harus tersedia/tidak bentrok.
5. Pemain baru dapat membuat akun dan karakter dari form launcher. Jika email sudah terikat ke Google identity lain, hubungi administrator; sistem tidak akan menghubungkan akun hanya berdasarkan email.
6. Jalankan server:
   ```bash
   chmod +x omp-server
   ./omp-server --config config.json
   ```

## Build

Push ke branch `main` menjalankan workflow build gamemode. Workflow menghasilkan deployment Windows, Linux standard, dan Linux dynamic sebagai artifacts. Build API lokal:

```bash
cd backend-api
npm ci
npm test
npm start
```
