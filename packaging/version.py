"""Single source of the release version: project.godot `config/version`.

Usage:
  python3 packaging/version.py              print the version, e.g. 0.1.0
  python3 packaging/version.py --code       print the Android versionCode (0.1.0 -> 100)
  python3 packaging/version.py --github-env append DBW_VERSION / DBW_VERSION_CODE to $GITHUB_ENV
  python3 packaging/version.py --stamp      write version/code into export_presets.cfg (build copy only)

The Windows file/product version and the Android versionName are left empty in
export_presets.cfg on purpose: Godot then uses `config/version` itself.
Only the integer Android versionCode has to be derived, and --stamp does that.
"""
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def version() -> str:
    text = (ROOT / "project.godot").read_text(encoding="utf-8")
    match = re.search(r'^config/version="(\d+)\.(\d+)\.(\d+)"\s*$', text, re.M)
    if not match:
        raise SystemExit('project.godot needs config/version="MAJOR.MINOR.PATCH"')
    return ".".join(match.groups())


def version_code() -> int:
    major, minor, patch = (int(part) for part in version().split("."))
    if minor > 99 or patch > 99:
        raise SystemExit("minor/patch above 99 would break the versionCode scheme")
    return major * 10000 + minor * 100 + patch


def stamp() -> None:
    presets = ROOT / "export_presets.cfg"
    text = presets.read_text(encoding="utf-8")
    new, count = re.subn(r"^version/code=\d+$", f"version/code={version_code()}", text, flags=re.M)
    if count != 1:
        raise SystemExit(f"expected exactly one Android version/code line, found {count}")
    presets.write_text(new, encoding="utf-8")
    print(f"export_presets.cfg: Android version/code={version_code()} (versionName comes from config/version {version()})")


if __name__ == "__main__":
    arg = sys.argv[1] if len(sys.argv) > 1 else ""
    if arg == "--code":
        print(version_code())
    elif arg == "--github-env":
        with open(os.environ["GITHUB_ENV"], "a", encoding="utf-8") as env:
            env.write(f"DBW_VERSION={version()}\nDBW_VERSION_CODE={version_code()}\n")
        print(f"DBW_VERSION={version()} DBW_VERSION_CODE={version_code()}")
    elif arg == "--stamp":
        stamp()
    elif arg == "":
        print(version())
    else:
        raise SystemExit(__doc__)
