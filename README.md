# Open.MP Linux Server Gamemode Package

Open.MP Gamemode Server package for Linux x86 (v1.5.8.3079) with automated GitHub Actions compilation & packaging using [`devbluen/openmp-build-action`](https://github.com/devbluen/openmp-build-action).

Developed by [@tohbobo51](https://github.com/tohbobo51).

---

## 🚀 Features

- **Open.MP Core**: Based on official release `v1.5.8.3079` (`open.mp-linux-x86.tar.gz`).
- **Automated CI/CD**: Every push to `main` triggers `.github/workflows/openmp-build.yml` via `devbluen/openmp-build-action@v3`.
- **Pre-configured Includes**: Full `qawno/include/` headers including `<open.mp>`, `a_players`, `a_vehicles`, `a_objects`, etc.
- **Artifact Generation**: Automatically compiles `gamemodes/main.pwn` into `main.amx` and exports:
  - Windows Deployment (`build-windows`)
  - Linux Standard Deployment (`build-linux-standard`)
  - Linux Dynamic Deployment (`build-linux-dynamic`)

---

## 📁 Repository Structure

```
├── .github/workflows/
│   └── openmp-build.yml      # CI/CD workflow with devbluen/openmp-build-action
├── components/               # Open.MP server component shared objects (.so)
├── gamemodes/
│   ├── main.pwn              # Primary Open.MP gamemode script
│   ├── derby.pwn             # Example Derby gamemode
│   ├── gungame.pwn           # Example Gungame gamemode
│   └── simpletdm.pwn         # Example Team Deathmatch gamemode
├── qawno/
│   └── include/              # Open.MP Pawn headers & include library
├── filterscripts/            # Server filterscripts
├── scriptfiles/              # Data persistence, configs & logs
├── models/                   # Custom server artworks / CDN models
├── config.json               # Open.MP server configuration
├── bans.json                 # Ban storage
└── omp-server                # Native Linux executable binary
```

---

## 🛠️ Running Locally on Linux VPS / Lemehost

1. Give execution permission to the server binary:
   ```bash
   chmod +x omp-server
   ```

2. Start the Open.MP server:
   ```bash
   ./omp-server --config config.json
   ```

3. To run in background:
   ```bash
   nohup ./omp-server > server.log 2>&1 &
   ```

---

## ⚙️ Building via GitHub Actions

GitHub Actions automatically builds your gamemode on every commit. You can also trigger a manual build anytime from the **Actions** tab:

1. Go to **Actions** -> **Build and Deploy Open.MP Gamemode**
2. Click **Run workflow**
3. Once completed, download the generated artifacts (`build-windows`, `build-linux-standard`, `build-linux-dynamic`).
