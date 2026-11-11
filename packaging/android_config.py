"""Point Godot at the Android SDK/JDK and the release keystore, from environment.

Required environment:
  JAVA_HOME, ANDROID_HOME            JDK 17 and Android SDK (build-tools + platform-tools)
  DBW_KEYSTORE                       path to the release keystore
  DBW_KEY_ALIAS, DBW_KEY_PASSWORD    alias and password (store and key password are the same)

Writes the user's editor settings and the git-ignored .godot/export_credentials.cfg.
Nothing is printed except paths; passwords are never echoed.
"""
import os
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def escaped(value: str) -> str:
    return str(value).replace("\\", "/").replace('"', '\\"')


presets = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
match = re.search(r'^\[preset\.(\d+)\]\s*\nname="Android"', presets, re.M)
if not match:
    raise SystemExit('export_presets.cfg has no preset named "Android"')
index = match.group(1)

config_dir = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))) / "godot"
config_dir.mkdir(parents=True, exist_ok=True)
settings = config_dir / "editor_settings-4.6.tres"
paths = {
    "export/android/java_sdk_path": os.environ["JAVA_HOME"],
    "export/android/android_sdk_path": os.environ["ANDROID_HOME"],
}
# Keep any existing editor settings (a developer's own machine); only replace these two keys.
text = settings.read_text(encoding="utf-8") if settings.exists() else '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
lines = [line for line in text.splitlines() if not any(line.startswith(key + " ") for key in paths)]
lines += [f'{key} = "{escaped(value)}"' for key, value in paths.items()]
settings.write_text("\n".join(lines) + "\n", encoding="utf-8")
credentials = ROOT / ".godot/export_credentials.cfg"
credentials.parent.mkdir(exist_ok=True)
credentials.write_text(
    f"[preset.{index}.options]\n"
    f'keystore/release="{escaped(os.environ["DBW_KEYSTORE"])}"\n'
    f'keystore/release_user="{escaped(os.environ["DBW_KEY_ALIAS"])}"\n'
    f'keystore/release_password="{escaped(os.environ["DBW_KEY_PASSWORD"])}"\n',
    encoding="utf-8",
)
credentials.chmod(0o600)
print(f"Android export configured: preset {index}, settings {settings}, credentials {credentials}")
