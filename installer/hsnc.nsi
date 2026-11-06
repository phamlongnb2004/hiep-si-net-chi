; Trình cài đặt Windows cho Hiệp Sĩ Nét Chì (không cần quyền quản trị: cài vào thư mục của người dùng)
; Dựng: makensis -DVERSION=2.0.0 -DSRC=../build/windows/HiepSiNetChi.exe -DOUT=../build/HiepSiNetChi-Setup.exe hsnc.nsi
Unicode true
SetCompressor /SOLID lzma
!ifndef VERSION
  !define VERSION "2.0.0"
!endif
!define NAME "Hiệp Sĩ Nét Chì"
!define KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\HiepSiNetChi"
Name "${NAME}"
OutFile "${OUT}"
InstallDir "$LOCALAPPDATA\HiepSiNetChi"
InstallDirRegKey HKCU "Software\HiepSiNetChi" "Dir"
RequestExecutionLevel user
Icon "icon.ico"
UninstallIcon "icon.ico"
VIProductVersion "${VERSION}.0"
VIAddVersionKey "ProductName" "${NAME}"
VIAddVersionKey "FileDescription" "Cài đặt ${NAME}"
VIAddVersionKey "FileVersion" "${VERSION}"
VIAddVersionKey "ProductVersion" "${VERSION}"
VIAddVersionKey "LegalCopyright" "Hiệp Sĩ Nét Chì"

!include "MUI2.nsh"
!define MUI_ICON "icon.ico"
!define MUI_UNICON "icon.ico"
!define MUI_FINISHPAGE_RUN "$INSTDIR\HiepSiNetChi.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Mở game ngay"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "Vietnamese"

Section "Game" SecMain
  ; đóng game đang mở (nếu có) để ghi đè được
  nsExec::Exec 'taskkill /F /IM HiepSiNetChi.exe'
  SetOutPath "$INSTDIR"
  File "/oname=HiepSiNetChi.exe" "${SRC}"
  File "icon.ico"
  WriteUninstaller "$INSTDIR\GoCaiDat.exe"
  CreateDirectory "$SMPROGRAMS\${NAME}"
  CreateShortcut "$SMPROGRAMS\${NAME}\${NAME}.lnk" "$INSTDIR\HiepSiNetChi.exe" "" "$INSTDIR\icon.ico"
  CreateShortcut "$SMPROGRAMS\${NAME}\Gỡ cài đặt.lnk" "$INSTDIR\GoCaiDat.exe"
  CreateShortcut "$DESKTOP\${NAME}.lnk" "$INSTDIR\HiepSiNetChi.exe" "" "$INSTDIR\icon.ico"
  WriteRegStr HKCU "Software\HiepSiNetChi" "Dir" "$INSTDIR"
  WriteRegStr HKCU "${KEY}" "DisplayName" "${NAME}"
  WriteRegStr HKCU "${KEY}" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "${KEY}" "Publisher" "${NAME}"
  WriteRegStr HKCU "${KEY}" "DisplayIcon" "$INSTDIR\icon.ico"
  WriteRegStr HKCU "${KEY}" "UninstallString" '"$INSTDIR\GoCaiDat.exe"'
  WriteRegDWORD HKCU "${KEY}" "NoModify" 1
  WriteRegDWORD HKCU "${KEY}" "NoRepair" 1
SectionEnd

Section "Uninstall"
  nsExec::Exec 'taskkill /F /IM HiepSiNetChi.exe'
  Delete "$INSTDIR\HiepSiNetChi.exe"
  Delete "$INSTDIR\icon.ico"
  Delete "$INSTDIR\GoCaiDat.exe"
  RMDir "$INSTDIR"
  Delete "$DESKTOP\${NAME}.lnk"
  RMDir /r "$SMPROGRAMS\${NAME}"
  DeleteRegKey HKCU "${KEY}"
  DeleteRegKey HKCU "Software\HiepSiNetChi"
  ; dữ liệu người chơi (phiên đăng nhập, gói cập nhật) ở %APPDATA%\Godot\app_userdata được giữ lại
SectionEnd
