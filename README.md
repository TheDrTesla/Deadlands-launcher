# Tesla Games

One launcher for all of TheDrTesla's games. Pick a game, install it, and the launcher tells you when there's an update.

| Game | |
|---|---|
| **The Deadlands** | *The world burned. You are a robot built from salvage, wandering what's left. Defeat other machines, tear off their parts and bolt them onto yourself, and fight your way across the Deadlands to recover the one thing that can bring the world back to life.* |
| **Ctrl+Alt+Salvage** | *Forty years after the Collapse, the machines woke up. You are UNIT K-7, a salvage robot searching the Dead Zone for the Verdant Core, the device that could bring the planet back to life.* |
| **Lucky Pinball** | *Pick a pinball table and play. The first one is the Dead Zone: knock the scrap raiders flat, fill the Salvage Cache for multiball, and hit the Sawbot for the jackpot. More tables are on the way.* |

## Download

### Windows

**[Download the launcher (Windows)](https://github.com/TheDrTesla/Tesla-Games-launcher/releases/latest/download/TeslaGamesLauncher.exe)**

1. Run `TeslaGamesLauncher.exe`.
2. Pick a game at the top and press **INSTALL**. Only the games you install are downloaded.
3. Press **PLAY**. When a new version is out, the launcher tells you and shows its patch notes; press **Update** when you want it, or keep playing the version you have.

> **Windows SmartScreen:** the launcher isn't code-signed yet, so Windows may say *"Windows protected your PC"*. Click **More info → Run anyway**.

### Linux (x86_64)

**[Download the launcher (Linux)](https://github.com/TheDrTesla/Tesla-Games-launcher/releases/latest/download/TeslaGamesLauncher-linux.tar.gz)**

1. Extract it: `tar -xzf TeslaGamesLauncher-linux.tar.gz`
2. Run `./TeslaGamesLauncher.x86_64` (or double-click it in your file manager).
3. Pick a game and press **INSTALL**, then **PLAY**. Updates are installed only when you press **Update**.

### Coming from the old Deadlands or Ctrl+Alt+Salvage launcher?

Download the launcher above and use it instead; the old ones no longer get updates. It downloads the game again once, into its own folder. Your saves are kept: they live in each game's own folder, which the launcher never touches. You can then delete the old launcher and its folder (`%APPDATA%\TheDeadlandsLauncher` or `%APPDATA%\CtrlAltSalvageLauncher`).

## How updates stay safe

Every game build is signed by the developer, and each game has its own key. Before installing anything, the launcher:

- checks the release's digital signature against that game's public key built into the launcher,
- checks that the release belongs to the game you picked,
- checks the SHA-256 checksum of the download and of every file inside it,
- refuses to install files outside the game's folder, and
- never "updates" to an older build.

If any check fails, the update is ignored and your current version keeps working. If your game files get damaged, the launcher notices and asks you to press **Repair**, which downloads them again.

The launcher shows where each game is installed, with an **Open folder** button. By default that's `%APPDATA%\TeslaGamesLauncher\games\<game>\game` (Linux: `~/.local/share/TeslaGamesLauncher/games/<game>/game`). Saves live separately in each game's own folder (`%APPDATA%\TheDeadlands`, `%APPDATA%\CtrlAltSalvage`, `%APPDATA%\LuckyPinball`; Linux: under `~/.local/share/`) and are never touched by updates.

---

## For the developer

This repo holds the launcher source (`launcher/`, a Godot 4.7 project) and hosts releases. The games' source is in the private repo `Tesla-games`.

| Release tag | What it is | Published by |
|---|---|---|
| `launcher-v*` | The launcher players download | This repo's workflow, when you push a `launcher-v1.2.3` tag |
| `deadlands-v*` | Signed The Deadlands builds (Windows zip + `manifest.json`, Linux zip + `manifest-linux.json`, each manifest signed); release notes are the game's `PATCH_NOTES.md` | `Tesla-games`' `release-the-deadlands.yml`, on every push to `main` that changes `the-deadlands/` |
| `salvage-v*` | Signed Ctrl+Alt+Salvage builds, same layout | `Tesla-games`' `release-ctrl-alt-salvage.yml`, on every push to `main` that changes `ctrl-alt-salvage/` |
| `pinball-v*` | Signed Lucky Pinball builds, same layout | `Tesla-games`' `release-lucky-pinball.yml`, on every push to `main` that changes `lucky-pinball/` |
| `game-v*` | Old The Deadlands builds from before the move, kept for launchers 1.x | Nobody any more |

The games, their tag prefixes and their public keys are listed in `GAMES` in `launcher/scripts/updater.gd`; the colours and background of each game's page are in `LOOKS` in `launcher/scripts/launcher.gd`. Adding a game means an entry in both and a new launcher release. The launcher contains no passwords or tokens, only public keys.

To test an update without GitHub, run a debug build against a local server: `godot --headless --path launcher res://tools/run_update.tscn -- --api=http://127.0.0.1:8765 --game=<id>`.
