!include "MUI2.nsh"
!include LogicLib.nsh
!include Win\COM.nsh
!include Win\Propkey.nsh
!include "FileFunc.nsh"

!ifndef APPNAME
!define APPNAME "QOpenHD"
!endif

!ifndef EXENAME
!define EXENAME "QOpenHD"
!endif

!ifndef ORGNAME
!define ORGNAME "OpenHD"
!endif

!ifndef DESTDIR
!define DESTDIR "..\..\..\..\QOpenHD\build\Desktop_Qt_5_15_19_MinGW_32_bit-Release\release"
!endif

!ifndef OUTFILE
!define OUTFILE "..\..\..\..\QOpenHD\build\Desktop_Qt_5_15_19_MinGW_32_bit-Release\${APPNAME}-Installer.exe"
!endif


Name "${APPNAME}"
OutFile "${OUTFILE}"
Var StartMenuFolder

RequestExecutionLevel admin

InstallDir "$PROGRAMFILES32\${APPNAME}"

SetCompressor /SOLID /FINAL lzma

!ifdef HEADER_BITMAP
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "${HEADER_BITMAP}"
!endif

!ifdef INSTALLER_ICON
!define MUI_ICON "${INSTALLER_ICON}"
!define MUI_UNICON "${INSTALLER_ICON}"
!endif

!insertmacro MUI_PAGE_STARTMENU Application $StartMenuFolder
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"


Section

  ReadRegStr $R0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "UninstallString"
  StrCmp $R0 "" doinstall

  DetailPrint "Uninstalling previous version..."  
  ExecWait "$R0 /S _?=$INSTDIR -LEAVE_DATA=1"
  IntCmp $0 0 doinstall

  MessageBox MB_OK|MB_ICONEXCLAMATION \
        "Could not remove a previously installed ${APPNAME} version.$\n$\nPlease remove it before continuing."
  Abort

doinstall:
  SetOutPath $INSTDIR

  File /r /x ${EXENAME}.pdb /x ${EXENAME}.lib /x ${EXENAME}.exp ${DESTDIR}\*.*

  IfFileExists "$INSTDIR\vc_redist.x86.exe" 0 no_redist
    ExecWait '"$INSTDIR\vc_redist.x86.exe" /passive /norestart'
    Delete "$INSTDIR\vc_redist.x86.exe"
  no_redist:

  WriteUninstaller $INSTDIR\${EXENAME}-Uninstall.exe
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayName" "${APPNAME}"
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "UninstallString" "$\"$INSTDIR\${EXENAME}-Uninstall.exe$\""
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "Publisher" "${ORGNAME}"
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayIcon" "$INSTDIR\${EXENAME}.exe"
  SetRegView 64
  WriteRegDWORD HKLM "SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\${EXENAME}.exe" "DumpCount" 5 
  WriteRegDWORD HKLM "SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\${EXENAME}.exe" "DumpType" 1
  WriteRegExpandStr HKLM "SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\${EXENAME}.exe" "DumpFolder" "%LOCALAPPDATA%\QOpenHDCrashDumps"
  goto done

done:
  SetRegView lastused
SectionEnd 

Section "Uninstall"
  ${GetParameters} $R0
  ${GetOptions} $R0 "-LEAVE_DATA=" $R1
  !insertmacro MUI_STARTMENU_GETFOLDER Application $StartMenuFolder
  SetShellVarContext all
  RMDir /r /REBOOTOK $INSTDIR
  RMDir /r /REBOOTOK "$SMPROGRAMS\$StartMenuFolder\"
  SetShellVarContext current
  ${If} $R1 != 1
    RMDir /r /REBOOTOK "$APPDATA\${ORGNAME}\"
  ${Endif}
  DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"
  DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\${EXENAME}.exe"
SectionEnd

Section "create Start Menu Shortcuts"
  SetShellVarContext all
  CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
  CreateShortCut "$SMPROGRAMS\$StartMenuFolder\${APPNAME}.lnk" "$INSTDIR\${EXENAME}.exe" "" "$INSTDIR\${EXENAME}.exe" 0
  CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Uninstall ${APPNAME}.lnk" "$INSTDIR\${EXENAME}-Uninstall.exe"
SectionEnd
