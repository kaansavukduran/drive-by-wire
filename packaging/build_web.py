"""Build this checkout as a Godot Web export into build/web.

Used by Vercel (`vercel.json` buildCommand) and by CI. No account, token,
Node dependency or server runtime is needed.

* If GODOT_BIN is set (CI, local), that engine and its installed templates are used.
* Otherwise (Vercel) the pinned official Linux editor and the two no-threads Web
  templates are downloaded into work/, checked against upstream SHA-512 sums,
  and isolated from the user's own Godot settings via XDG_* directories.

The export uses the no-threads template, so the page needs no COOP/COEP
headers and no service worker. There is deliberately no offline/PWA layer.
"""
import hashlib
import os
import shutil
import subprocess
import urllib.request
import zipfile
from pathlib import Path

VERSION = "4.6.3"
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "build/web"
BAD = ("SCRIPT ERROR", "Parse Error", "Failed to load script")


def sha512(path: Path) -> str:
    digest = hashlib.sha512()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def download_engine(env: dict) -> str:
    work = ROOT / "work/web-build"
    work.mkdir(parents=True, exist_ok=True)
    (ROOT / "work/.gdignore").touch()
    for key, child in [("XDG_DATA_HOME", "data"), ("XDG_CONFIG_HOME", "config"), ("XDG_CACHE_HOME", "cache")]:
        env[key] = str(work / child)
        Path(env[key]).mkdir(parents=True, exist_ok=True)
    engine = work / "godot"
    templates = Path(env["XDG_DATA_HOME"]) / "godot/export_templates" / f"{VERSION}.stable"
    required = [templates / f"web_nothreads_{mode}.zip" for mode in ("debug", "release")]
    if engine.exists() and all(p.exists() for p in required):
        return str(engine)
    base = f"https://github.com/godotengine/godot/releases/download/{VERSION}-stable/"
    with urllib.request.urlopen(base + "SHA512-SUMS.txt", timeout=60) as response:
        checksums = {}
        for line in response.read().decode().splitlines():
            parts = line.split()
            if len(parts) >= 2:
                checksums[parts[1].lstrip("*")] = parts[0]
    editor_name = f"Godot_v{VERSION}-stable_linux.x86_64.zip"
    template_name = f"Godot_v{VERSION}-stable_export_templates.tpz"
    for name in (editor_name, template_name):
        archive = work / name
        print("Downloading official Godot:", name, flush=True)
        urllib.request.urlretrieve(base + name, archive)
        if sha512(archive) != checksums[name]:
            raise RuntimeError("Official download checksum mismatch: " + name)
        with zipfile.ZipFile(archive) as bundle:
            if name == editor_name:
                member = next(i for i in bundle.infolist() if not i.is_dir() and i.filename.startswith("Godot"))
                with bundle.open(member) as source, engine.open("wb") as target:
                    shutil.copyfileobj(source, target)
                engine.chmod(0o755)
            else:
                templates.mkdir(parents=True, exist_ok=True)
                for target in required:
                    with bundle.open("templates/" + target.name) as source, target.open("wb") as output:
                        shutil.copyfileobj(source, output)
        archive.unlink()  # do not keep the ~1 GB multi-platform archive around
    return str(engine)


def godot(engine: str, env: dict, *args: str, check_output: bool = False) -> None:
    cmd = [engine, "--headless", "--path", str(ROOT), *args]
    print("+", " ".join(cmd), flush=True)
    run = subprocess.run(cmd, cwd=ROOT, env=env, capture_output=True, text=True, errors="replace", timeout=900)
    output = run.stdout + run.stderr
    print(output[-6000:], flush=True)
    if run.returncode != 0:
        raise SystemExit(f"godot {' '.join(args)} failed with exit {run.returncode}")
    bad = [line for line in output.splitlines() if any(marker in line for marker in BAD)]
    if check_output and bad:
        raise SystemExit("Game entry has script errors:\n" + "\n".join(bad[:20]))


def main() -> None:
    env = dict(os.environ)
    env.setdefault("ANDROID_USER_HOME", str(ROOT / "work/android"))
    engine = env.get("GODOT_BIN") or download_engine(env)
    shutil.rmtree(OUT, ignore_errors=True)
    OUT.mkdir(parents=True)
    (ROOT / "build/.gdignore").touch()
    godot(engine, env, "--editor", "--import", "--quit", check_output=True)
    # Run the real main scene briefly before exporting, so a broken game fails the deploy.
    godot(engine, env, "--quit-after", "120", check_output=True)
    godot(engine, env, "res://scenes/main.tscn", "--quit-after", "120", check_output=True)
    godot(engine, env, "--export-release", "Web", str(OUT / "index.html"))
    for name in ("index.html", "index.js", "index.wasm", "index.pck"):
        if not (OUT / name).is_file():
            raise SystemExit("Missing Web export file: " + name)
    html = (OUT / "index.html").read_text(encoding="utf-8")
    if '<html lang="tr">' not in html or "$GODOT_" in html:
        raise SystemExit("index.html was not produced from packaging/web/shell.html")
    for icon in ("assets/icon-192.png", "assets/icon.png"):
        if (ROOT / icon).is_file():
            shutil.copy2(ROOT / icon, OUT / "favicon.png")
            break
    else:
        print("WARNING: no assets/icon-192.png or assets/icon.png; page has no favicon", flush=True)
    shutil.copy2(ROOT / "assets/fonts/Lexend.ttf", OUT / "loading-font.ttf")
    shutil.copy2(ROOT / "assets/ui/momo_face.png", OUT / "loading-momo.png")
    print("Web export ready:", OUT / "index.html", flush=True)


if __name__ == "__main__":
    main()
