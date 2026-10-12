# The Deadlands

*The world burned. You are a robot built from salvage, wandering what's left. Defeat other machines, tear off their parts and bolt them onto yourself, and fight your way across the Deadlands to recover the one thing that can bring the world back to life.*

## Download

### Windows

**[Download the launcher (Windows)](https://github.com/TheDrTesla/Deadlands-launcher/releases/latest/download/TheDeadlandsLauncher.exe)**

1. Run `TheDeadlandsLauncher.exe`.
2. The launcher downloads the game the first time, and installs any update each time you start it.
3. Press **PLAY**.

> **Windows SmartScreen:** the launcher isn't code-signed yet, so Windows may say *"Windows protected your PC"*. Click **More info → Run anyway**.

### Linux (x86_64)

**[Download the launcher (Linux)](https://github.com/TheDrTesla/Deadlands-launcher/releases/latest/download/TheDeadlandsLauncher-linux.tar.gz)**

1. Extract it: `tar -xzf TheDeadlandsLauncher-linux.tar.gz`
2. Run `./TheDeadlandsLauncher.x86_64` (or double-click it in your file manager).
3. The launcher downloads the game the first time, and installs any update each time you start it. Press **PLAY**.

## How updates stay safe

Every game build is signed by the developer. Before installing anything, the launcher:

- checks the release's digital signature against a public key built into the launcher,
- checks the SHA-256 checksum of the download and of every file inside it,
- refuses to install files outside the game folder, and
- never "updates" to an older build.

If any check fails, the update is ignored and your current version keeps working. If your game files get damaged, the launcher notices and re-downloads them (or press **Repair**).

Files live in `%APPDATA%\TheDeadlandsLauncher\game` (Linux: `~/.local/share/TheDeadlandsLauncher/game`). Your saves live separately in `%APPDATA%\TheDeadlands` (Linux: `~/.local/share/TheDeadlands`) and are never touched by updates.

---

## For the developer

This repo holds the launcher source (`launcher/`, a Godot 4.7 project) and hosts releases:

| Release tag | What it is | Published by |
|---|---|---|
| `launcher-v*` | The launcher players download | This repo's workflow, when you push a `launcher-v1.2.3` tag |
| `game-v*` | Signed game builds (Windows zip + `manifest.json`, Linux zip + `manifest-linux.json`, each manifest signed) | The private game repo's workflow, on every push to `main` |

The launcher contains no passwords or tokens, only the public key in `launcher/scripts/updater.gd`.
