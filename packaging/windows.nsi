; Drive-By Wire per-user Windows installer (no administrator rights).
; Build from the repository root after exporting the "Windows Desktop" preset:
;   python3 packaging/png_to_ico.py assets/brand/ilin-icon.png build/DriveByWire.ico
;   makensis -DVERSION=0.1.0 packaging/windows.nsi
; Output: build/DriveByWire-<VERSION>-windows-x64-Setup.exe
Unicode true
!ifndef VERSION
  !error "Pass -DVERSION=x.y.z (python3 packaging/version.py)"
!endif
!ifndef ROOT
  !define ROOT "."
!endif
!define APP "Drive-By Wire"
!define EXE "DriveByWire.exe"
!define UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\DriveByWire"
!include "MUI2.nsh"

Name "${APP}"
OutFile "${ROOT}/build/DriveByWire-${VERSION}-windows-x64-Setup.exe"
InstallDir "$LOCALAPPDATA\Programs\${APP}"
InstallDirRegKey HKCU "Software\DriveByWire" "InstallDir"
RequestExecutionLevel user
SetCompressor /SOLID lzma
VIProductVersion "${VERSION}.0"
VIAddVersionKey /LANG=0 "ProductName" "${APP}"
VIAddVersionKey /LANG=0 "FileDescription" "${APP} Setup"
VIAddVersionKey /LANG=0 "CompanyName" "Kaan Savukduran"
VIAddVersionKey /LANG=0 "FileVersion" "${VERSION}"
VIAddVersionKey /LANG=0 "ProductVersion" "${VERSION}"
VIAddVersionKey /LANG=0 "LegalCopyright" "Kaan Savukduran"

!if /FileExists "${ROOT}/build/DriveByWire.ico"
  !define MUI_ICON "${ROOT}/build/DriveByWire.ico"
  !define MUI_UNICON "${ROOT}/build/DriveByWire.ico"
!endif
!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_RUN "$INSTDIR\${EXE}"
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "Turkish"
!insertmacro MUI_LANGUAGE "English"

Section "Game"
  SetOutPath "$INSTDIR"
  File "${ROOT}/build/windows/${EXE}"
  File "${ROOT}/LICENSE"
  File "${ROOT}/THIRD_PARTY_NOTICES.md"
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  CreateDirectory "$SMPROGRAMS\${APP}"
  CreateShortcut "$SMPROGRAMS\${APP}\${APP}.lnk" "$INSTDIR\${EXE}"
  CreateShortcut "$SMPROGRAMS\${APP}\Uninstall ${APP}.lnk" "$INSTDIR\Uninstall.exe"
  WriteRegStr HKCU "Software\DriveByWire" "InstallDir" "$INSTDIR"
  WriteRegStr HKCU "${UNINST_KEY}" "DisplayName" "${APP}"
  WriteRegStr HKCU "${UNINST_KEY}" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "${UNINST_KEY}" "Publisher" "Kaan Savukduran"
  WriteRegStr HKCU "${UNINST_KEY}" "DisplayIcon" "$INSTDIR\${EXE}"
  WriteRegStr HKCU "${UNINST_KEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "${UNINST_KEY}" "UninstallString" '"$INSTDIR\Uninstall.exe"'
  WriteRegStr HKCU "${UNINST_KEY}" "QuietUninstallString" '"$INSTDIR\Uninstall.exe" /S'
  WriteRegDWORD HKCU "${UNINST_KEY}" "NoModify" 1
  WriteRegDWORD HKCU "${UNINST_KEY}" "NoRepair" 1
SectionEnd

Section "Uninstall"
  Delete "$INSTDIR\${EXE}"
  Delete "$INSTDIR\LICENSE"
  Delete "$INSTDIR\THIRD_PARTY_NOTICES.md"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR"
  Delete "$SMPROGRAMS\${APP}\${APP}.lnk"
  Delete "$SMPROGRAMS\${APP}\Uninstall ${APP}.lnk"
  RMDir "$SMPROGRAMS\${APP}"
  DeleteRegKey HKCU "${UNINST_KEY}"
  DeleteRegKey HKCU "Software\DriveByWire"
  ; İLİN's trust and garage choices live in the Godot user data folder
  ; (%APPDATA%\Godot\app_userdata\Drive-By Wire) and are deliberately kept.
SectionEnd
