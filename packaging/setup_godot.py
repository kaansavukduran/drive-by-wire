"""Install the pinned official Godot editor and export templates (CI helper).

Downloads into .ci-godot/ (cached by actions/cache), verifies every archive
against the upstream SHA512-SUMS.txt, puts `godot` in .ci-godot/bin and
installs the templates where Godot looks for them on this OS.
"""
import hashlib
import os
import platform
import shutil
import time
import urllib.error
import urllib.request
import zipfile
from pathlib import Path

VERSION = "4.6.3"
root = Path(".ci-godot").resolve()
root.mkdir(exist_ok=True)
system = platform.system()
suffix = {"Linux": "linux.x86_64.zip", "Windows": "win64.exe.zip"}[system]
base = f"https://github.com/godotengine/godot/releases/download/{VERSION}-stable/"
names = [f"Godot_v{VERSION}-stable_{suffix}", f"Godot_v{VERSION}-stable_export_templates.tpz"]


def download(url: str, target: Path) -> None:
    partial = target.with_suffix(target.suffix + ".partial")
    for attempt in range(5):
        try:
            with urllib.request.urlopen(url, timeout=60) as response, partial.open("wb") as output:
                shutil.copyfileobj(response, output)
            partial.replace(target)
            return
        except (OSError, urllib.error.URLError):
            partial.unlink(missing_ok=True)
            if attempt == 4:
                raise
            print("Download interrupted; retrying", target.name, flush=True)
            time.sleep(2 ** attempt)


def sha512(path: Path) -> str:
    digest = hashlib.sha512()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


sums_file = root / "SHA512-SUMS.txt"
download(base + "SHA512-SUMS.txt", sums_file)
checksums = {}
for line in sums_file.read_text().splitlines():
    parts = line.split()
    if len(parts) >= 2:
        checksums[parts[1].lstrip("*")] = parts[0]

for name in names:
    target = root / name
    if not target.exists():
        download(base + name, target)
    if sha512(target) != checksums[name]:
        target.unlink()
        raise RuntimeError("Checksum mismatch: " + name)
    directory = root / ("engine" if name.endswith(".zip") else "templates")
    with zipfile.ZipFile(target) as archive:
        archive.extractall(directory)
        if system != "Windows":
            for info in archive.infolist():
                mode = (info.external_attr >> 16) & 0o777
                if mode and not info.is_dir():
                    (directory / info.filename).chmod(mode)

bin_dir = root / "bin"
bin_dir.mkdir(exist_ok=True)
if system == "Windows":
    # The console wrapper finds its GUI twin by file name, so both keep their
    # upstream names; `godot.exe` is a copy of the GUI build (bash waits for it).
    for exe in (root / "engine").glob("*.exe"):
        shutil.copy2(exe, bin_dir / exe.name)
    gui = next(p for p in (root / "engine").glob("*.exe") if "console" not in p.name)
    shutil.copy2(gui, bin_dir / "godot.exe")
    template_dir = Path(os.environ["APPDATA"]) / "Godot/export_templates"
else:
    executable = next(p for p in (root / "engine").glob("Godot*") if p.is_file())
    dest = bin_dir / "godot"
    shutil.copy2(executable, dest)
    dest.chmod(0o755)
    template_dir = Path(os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local/share"))) / "godot/export_templates"
shutil.copytree(root / "templates/templates", template_dir / f"{VERSION}.stable", dirs_exist_ok=True)
print(f"Official Godot {VERSION} and export templates verified with upstream SHA-512.")
