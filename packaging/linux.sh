#!/usr/bin/env bash
# Package an exported Linux build (build/linux/DriveByWire.x86_64) as
#   build/DriveByWire-<version>-linux-x64-portable.tar.gz
#   build/DriveByWire-<version>-linux-x64.AppImage   (only if appimagetool is on PATH)
#   build/DriveByWire-<version>-linux-x64.deb
# Version comes from project.godot via packaging/version.py.
set -euo pipefail
cd "$(dirname "$0")/.."
version="$(python3 packaging/version.py)"
binary=build/linux/DriveByWire.x86_64
icon=assets/icon.png
test -f "$binary" || { echo "missing $binary; run: godot --headless --export-release Linux" >&2; exit 1; }
test -f "$icon" || { echo "missing $icon" >&2; exit 1; }
chmod +x "$binary"

docs=(LICENSE THIRD_PARTY_NOTICES.md)
[ -f README.md ] && docs+=(README.md)

# 1. Portable tarball: the single executable (PCK embedded) plus notices.
portable=build/portable-linux/DriveByWire
rm -rf build/portable-linux
mkdir -p "$portable"
cp "$binary" "$portable/"
cp "${docs[@]}" "$portable/"
tar -czf "build/DriveByWire-${version}-linux-x64-portable.tar.gz" -C build/portable-linux DriveByWire

desktop_entry() {
  cat <<EOF
[Desktop Entry]
Type=Application
Name=Drive-By Wire
Comment=Yazarak sürülen roguelite araba çatışması
Comment[en]=Typing-driven roguelite car combat
Exec=$1
Icon=drivebywire
Terminal=false
Categories=Game;ActionGame;
Keywords=car;typing;roguelite;araba;
EOF
}

# 2. AppImage.
appdir=build/DriveByWire.AppDir
rm -rf "$appdir"
mkdir -p "$appdir/usr/bin" "$appdir/usr/share/applications" "$appdir/usr/share/icons/hicolor/256x256/apps"
cp "$binary" "$appdir/usr/bin/DriveByWire"
cp "$icon" "$appdir/drivebywire.png"
cp "$icon" "$appdir/usr/share/icons/hicolor/256x256/apps/drivebywire.png"
desktop_entry DriveByWire > "$appdir/drivebywire.desktop"
cp "$appdir/drivebywire.desktop" "$appdir/usr/share/applications/"
cat > "$appdir/AppRun" <<'EOF'
#!/bin/sh
exec "$(dirname "$(readlink -f "$0")")/usr/bin/DriveByWire" "$@"
EOF
chmod +x "$appdir/AppRun"
if command -v desktop-file-validate >/dev/null 2>&1; then
  desktop-file-validate "$appdir/drivebywire.desktop"
fi
if command -v appimagetool >/dev/null 2>&1; then
  ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 appimagetool --no-appstream "$appdir" "build/DriveByWire-${version}-linux-x64.AppImage"
else
  echo "appimagetool not found: AppImage skipped" >&2
fi

# 3. Debian package (installs to /usr/games, menu entry + icon).
deb=build/deb
rm -rf "$deb"
mkdir -p "$deb/DEBIAN" "$deb/usr/games" "$deb/usr/share/applications" \
  "$deb/usr/share/icons/hicolor/256x256/apps" "$deb/usr/share/doc/drive-by-wire"
install -m 0755 "$binary" "$deb/usr/games/DriveByWire"
desktop_entry /usr/games/DriveByWire > "$deb/usr/share/applications/drivebywire.desktop"
install -m 0644 "$icon" "$deb/usr/share/icons/hicolor/256x256/apps/drivebywire.png"
install -m 0644 LICENSE THIRD_PARTY_NOTICES.md "$deb/usr/share/doc/drive-by-wire/"
installed_kb="$(du -sk "$deb" | cut -f1)"
cat > "$deb/DEBIAN/control" <<EOF
Package: drive-by-wire
Version: $version
Architecture: amd64
Maintainer: Kaan Savukduran <kaansavukduran@users.noreply.github.com>
Section: games
Priority: optional
Installed-Size: $installed_kb
Depends: libc6 (>= 2.31), libx11-6, libxcursor1, libxinerama1, libxi6, libxrandr2, libgl1, libfontconfig1
Recommends: libasound2t64 | libasound2, libpulse0
Homepage: https://github.com/kaansavukduran/drive-by-wire
Description: Typing-driven roguelite car combat (prototype)
 Drive-By Wire: yazarak sürülen roguelite araba çatışması. Arabanın
 yapay zekâsı MOMO komutlarını ruh haline göre yorumlar.
EOF
dpkg-deb --root-owner-group --build "$deb" "build/DriveByWire-${version}-linux-x64.deb"
ls -l build/DriveByWire-"${version}"-linux-x64*
