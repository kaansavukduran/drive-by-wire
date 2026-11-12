# Build and packaging

Engine: official Godot **4.6.3** standard build (GDScript, GL Compatibility; no .NET). CI downloads the editor and export templates with `packaging/setup_godot.py` and checks them against upstream SHA-512 sums.

**Version: one place.** `project.godot` → `config/version` (now `0.4.0`). `packaging/version.py` prints it; the Windows file/product version and the Android versionName are left empty in `export_presets.cfg` so Godot fills them from `config/version`; the Android versionCode is derived (`MAJOR*10000 + MINOR*100 + PATCH`, so 0.1.0 → 100) and stamped by `python3 packaging/version.py --stamp`. To release a new version, change only `config/version`, then either push the tag `v<version>` or run the workflow from the Actions tab on `main` with **publish_release** ticked (the release job then creates the `v<version>` tag itself).

## Outputs

| File | Built by | What it is |
| --- | --- | --- |
| `DriveByWire-<v>-windows-x64-portable.zip` | CI (windows-latest) | One `DriveByWire.exe` with the game data embedded, plus notices. Unzip and run. |
| `DriveByWire-<v>-windows-x64-Setup.exe` | CI (NSIS) | Per-user installer, no admin: `%LOCALAPPDATA%\Programs\Drive-By Wire`, Start menu shortcut, uninstaller in Apps & features. |
| `DriveByWire-<v>-linux-x64-portable.tar.gz` | CI (ubuntu-24.04) | `DriveByWire/DriveByWire.x86_64` (data embedded) plus notices. |
| `DriveByWire-<v>-linux-x64.AppImage` | CI | Single-file Linux app. |
| `DriveByWire-<v>-linux-x64.deb` | CI | Installs `/usr/games/DriveByWire`, a menu entry and an icon. |
| `DriveByWire-<v>-web-offline.tar.gz` | CI | The `build/web` folder (same as Vercel). Needs a local web server; `file://` does not work. |
| `DriveByWire-<v>-android-arm64-x64.apk` | CI | Android 7.0+ (API 24), ARM64 and x86_64, landscape, no internet permission. |

Save data (MOMO's trust, garage choices) lives in Godot's user data folder, not next to the executable, so "portable" means "no installation", not "save next to the exe". Uninstalling keeps the save.

## CI (`.github/workflows/build.yml`)

Runs on push to `main`, on pull requests, on `v*` tags and manually (`workflow_dispatch`).

1. `test`: import, then `bash tests/run_all.sh`.
2. `linux_web`, `windows`, `android` (parallel, after `test`): export, package, smoke-run (`packaging/smoke.py`: `--headless --quit-after 300`, fails on non-zero exit or GDScript errors). Linux runs the raw export, the extracted tarball, the AppImage and the installed `.deb`. Windows runs the exported exe, then silently installs the Setup, runs the installed exe, checks the Start menu shortcut and uninstalls. The web job runs `packaging/build_web.py`, the same script Vercel runs.
3. `release` (on a `v*` tag, or a manual run on `main` with `publish_release`): checks the tag equals `v` + `config/version`, collects the 7 files, writes `SHA256SUMS`, and creates a GitHub Release (pre-release while the version is 0.x) with `docs/RELEASE.md` as notes.

A headless smoke run proves the binary starts, loads its data and runs the main scene. It does not prove rendering, sound or input on a real desktop or phone.

## Local builds

```sh
mkdir -p build/linux build/windows build/android && touch build/.gdignore
godot --headless --editor --import --quit
bash tests/run_all.sh

# Linux: export + tar.gz/AppImage/deb (AppImage only if appimagetool is on PATH)
godot --headless --export-release Linux
python3 packaging/smoke.py build/linux/DriveByWire.x86_64
bash packaging/linux.sh

# Windows: export (works from Linux too) + installer (needs NSIS: apt install nsis / choco install nsis)
godot --headless --export-release "Windows Desktop"
python3 packaging/png_to_ico.py assets/icon.png build/DriveByWire.ico
makensis -NOCD -DVERSION=$(python3 packaging/version.py) packaging/windows.nsi

# Web: build/web, then serve it
GODOT_BIN=godot python3 packaging/build_web.py
python3 -m http.server 8000 --directory build/web   # open http://localhost:8000
```

Without `GODOT_BIN`, `build_web.py` downloads the pinned Godot and Web templates into `work/` (this is what Vercel does). The web build uses the no-threads template, so it needs no COOP/COEP headers. There is no service worker or offline cache: the page needs the network on every load, and updates appear on the next reload.

### Android

Needs JDK 17 and the Android SDK with `platform-tools` and `build-tools;35.0.0` (the export does not use Gradle).

```sh
export JAVA_HOME=... ANDROID_HOME=...
# Set DBW_KEYSTORE and DBW_KEY_ALIAS from your local signing configuration.
read -r -s -p "Keystore password: " DBW_KEY_PASSWORD
export DBW_KEYSTORE DBW_KEY_ALIAS DBW_KEY_PASSWORD
python3 packaging/android_config.py      # editor SDK paths + git-ignored .godot/export_credentials.cfg
python3 packaging/version.py --stamp     # versionCode from config/version (do not commit the result if it differs)
godot --headless --editor --import --quit
godot --headless --export-release Android
```

Android export requires `textures/vram_compression/import_etc2_astc=true` under `[rendering]` in `project.godot`. If it is missing, `android_config.py` adds it to the build checkout and prints a warning; the permanent fix is to add that line to `project.godot`.

## Android signing: owner key required

No public prototype key fallback is allowed in the current tree. CI runs the Android job only when repository variable `DBW_ANDROID_SIGNING_READY` is `true`. Configure these Actions settings outside the repository:

- `DBW_ANDROID_KEYSTORE_B64`: base64 of the owner's release keystore.
- repository variable `DBW_ANDROID_KEY_ALIAS`: signing alias (defaults to `dbwrelease`).
- `DBW_ANDROID_KEY_PASSWORD`: matching store/key password.

The job fails if any required value is empty. Its temporary keystore uses private file permissions; credentials stay in the ignored Godot export credentials file. No new signing key has been configured or validated in this task. The release job depends on Android, so an unconfigured signing job also keeps the multi-platform release from publishing.

The previously published prototype key remains public in Git history. It must not be reused for distribution. A new owner key cannot update an installation signed by that key; players would need to uninstall the old prototype, losing Android local data. Real keystores and export credentials must never be committed.

## Not covered

No macOS or iOS build. No Windows Authenticode signature: SmartScreen may warn on first launch ("More info → Run anyway"). No Play Store upload.
