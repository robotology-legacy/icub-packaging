
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "EnvVarUpdate.nsh"

!define MULTIUSER_EXECUTIONLEVEL Highest
!include MultiUser.nsh

Name "iCub ${ICUB_VERSION}"
OutFile "${NSIS_OUTPUT_PATH}\iCub_${ICUB_VERSION}-${ICUB_TWEAK}_${BUILD_VERSION}.exe"
InstallDir "$PROGRAMFILES\${VENDOR}"
InstallDirRegKey HKCU "Software\iCub\Common" "LastInstallLocation"
RequestExecutionLevel admin

!define MUI_ABORTWARNING

;--------------------------------
;Utilities

# this function register a package into the registry
!macro RegisterPackage package version
  
  WriteRegStr HKCU "Software\${VENDOR}\${package}\${version}" "" "$INSTDIR\${version}"
  WriteRegStr HKCU "Software\${VENDOR}\${package}\Common" "LastInstallLocation" $INSTDIR\${version}
  WriteRegStr HKCU "Software\${VENDOR}\${package}\Common" "LastInstallVersion" "${version}"
  
!macroend

!macro UnregisterPackage package version
  DeleteRegKey HKCU "Software\${VENDOR}\${package}\Common\LastInstallVersion"
  DeleteRegKey HKCU "Software\${VENDOR}\${package}\Common\LastInstallLocation"
  DeleteRegKey HKCU "Software\${VENDOR}\${package}\Common"
  DeleteRegKey /ifempty HKCU "Software\${VENDOR}\${package}\${version}"
  DeleteRegKey /ifempty HKCU "Software\${VENDOR}\${package}"
!macroend

!macro FixCMakeForPackage package_key dir
   !insertmacro ReplaceInFile "$INSTDIR\${INST2}\lib\ICUB\icub-config.cmake" ${package_key} ${dir}
   !insertmacro ReplaceInFile "$INSTDIR\${INST2}\lib\ICUB\icub-export-install-includes.cmake" ${package_key} ${dir}
   !insertmacro ReplaceInFile "$INSTDIR\${INST2}\lib\ICUB\icub-export-install-includes.cmake" ${package_key} ${dir}
   !insertmacro ReplaceInFile "$INSTDIR\${INST2}\lib\ICUB\icub-export-install-release.cmake"  ${package_key} ${dir}
!macroend

!define StrRepLocal "!insertmacro StrRepLocal"
!macro StrRepLocal output string old new
    Push "${string}"
    Push "${old}"
    Push "${new}"
    !ifdef __UNINSTALL__
        Call un.StrRepLocal
    !else
        Call StrRepLocal
    !endif
    Pop ${output}
!macroend
 
!macro Func_StrRepLocal un
    Function ${un}StrRepLocal
        Exch $R2 ;new
        Exch 1
        Exch $R1 ;old
        Exch 2
        Exch $R0 ;string
        Push $R3
        Push $R4
        Push $R5
        Push $R6
        Push $R7
        Push $R8
        Push $R9
 
        StrCpy $R3 0
        StrLen $R4 $R1
        StrLen $R6 $R0
        StrLen $R9 $R2
        loop:
            StrCpy $R5 $R0 $R4 $R3
            StrCmp $R5 $R1 found
            StrCmp $R3 $R6 done
            IntOp $R3 $R3 + 1
            Goto loop
        found:
            StrCpy $R5 $R0 $R3
            IntOp $R8 $R3 + $R4
            StrCpy $R7 $R0 "" $R8
            StrCpy $R0 $R5$R2$R7
            StrLen $R6 $R0
            IntOp $R3 $R3 + $R9
            Goto loop
        done:
 
        Pop $R9
        Pop $R8
        Pop $R7
        Pop $R6
        Pop $R5
        Pop $R4
        Pop $R3
        Push $R0
        Push $R1
        Pop $R0
        Pop $R1
        Pop $R0
        Pop $R2
        Exch $R1
    FunctionEnd
!macroend
!insertmacro Func_StrRepLocal ""

Function ReplaceInFileFunction
 
  ClearErrors
  Exch $0      ; REPLACEMENT
  Exch
  Exch $1      ; SEARCH_TEXT
  Exch 2
  Exch $2      ; SOURCE_FILE
 
  Push $R0
  Push $R1
  Push $R2
  Push $R3
  Push $R4
 
  IfFileExists $2 +1 RIF_error
  FileOpen $R0 $2 "r"
 
  GetTempFileName $R2
  FileOpen $R1 $R2 "w"
 
  RIF_loop:
    FileRead $R0 $R3
    IfErrors RIF_leaveloop
    #RIF_sar:
      Push "$R3"
      Push "$1"
      Push "$0"
      Call StrRepLocal
      StrCpy $R4 "$R3"
      Pop $R3
      #StrCmp "$R3" "$R4" +1 RIF_sar
    FileWrite $R1 "$R3"
  Goto RIF_loop
 
  RIF_leaveloop:
    FileClose $R1
    FileClose $R0
 
    Delete "$2" 
    Rename "$R2" "$2"
 
    ClearErrors
    Goto RIF_out
 
  RIF_error:
    SetErrors
 
  RIF_out:
  Pop $R4
  Pop $R3
  Pop $R2
  Pop $R1
  Pop $R0
  Pop $2
  Pop $0
  Pop $1
 
FunctionEnd


!macro ReplaceInFile SOURCE_FILE SEARCH_TEXT REPLACEMENT
  Push "${SOURCE_FILE}"
  Push "${SEARCH_TEXT}"
  Push "${REPLACEMENT}"
  Call ReplaceInFileFunction
!macroend

;--------------------------------
;Pages

  !define MUI_PAGE_HEADER_TEXT "Welcome to the iCub software"
  !define MUI_PAGE_HEADER_SUBTEXT "iCub.  Free software for free iCubs."
  !define MUI_LICENSEPAGE_TEXT_TOP "iCub is distributed under the GPL Free Software license."
  !define MUI_LICENSEPAGE_TEXT_BOTTOM "You are free to use this software personally without agreeing to this license. Follow the terms of the license if you wish to take advantage of the extra rights it grants."
  !define MUI_LICENSEPAGE_BUTTON "Next >"
  !insertmacro MUI_PAGE_LICENSE "${ICUB_LICENSE}"
  !insertmacro MUI_PAGE_COMPONENTS
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  
;--------------------------------
;Languages
 
  !insertmacro MUI_LANGUAGE "English"

;--------------------------------
;Installer Sections

Section "-first"
  Var /GLOBAL  GSL_PATH
  Var /GLOBAL YARP_PATH
  
  Call CheckYARPVersion
  StrCpy $YARP_PATH $0
  
  Call CheckGSLVersion
  StrCpy $GSL_PATH $0
  
  DetailPrint "YARP found at $YARP_PATH"
  DetailPrint "GSL found at $GSL_PATH"
  
  SetOutPath "$INSTDIR"
  !insertmacro RegisterPackage iCub ${INST2}
  !insertmacro RegisterPackage ipopt ${IPOPT_SUB}
  !insertmacro RegisterPackage OpenCV ${OPENCV_SUB}
  !insertmacro RegisterPackage sdl ${SDL_SUB}
  !insertmacro RegisterPackage ode ${ODE_SUB}
  !insertmacro RegisterPackage glut ${GLUT_SUB}
  !insertmacro RegisterPackage qt3 ${QT3_SUB}
  
  WriteUninstaller "$INSTDIR\Uninstall_iCub.exe"
  SectionIn RO
  !include ${NSIS_OUTPUT_PATH}\icub_base_add.nsi
  ${StrRepLocal} $0 "$INSTDIR\${INST2}" "\" "/"

  DetailPrint "Fixing: $INSTDIR\${INST2}\lib\ICUB\icub-config.cmake"
  
  !insertmacro FixCMakeForPackage __NSIS_ICUB_INSTALLED_LOCATION__ $\"$0$\"
  ${StrRepLocal} $0 "$GSL_PATH" "\" "/"
  !insertmacro FixCMakeForPackage __NSIS_GSL_INSTALLED_LOCATION__ $\"$0$\"
  
  ${StrRepLocal} $0 "$INSTDIR\${IPOPT_SUB}" "\" "/"
  !insertmacro FixCMakeForPackage __NSIS_IPOPT_INSTALLED_LOCATION__ $\"$0$\"

  ${StrRepLocal} $0 "$INSTDIR\${OPENCV_SUB}" "\" "/"
  !insertmacro FixCMakeForPackage __NSIS_OPENCV_INSTALLED_LOCATION__ $\"$0$\"
  
SectionEnd

Section "Modules" SecModules
  SetOutPath "$INSTDIR"
  !include ${NSIS_OUTPUT_PATH}\icub_modules_add.nsi
SectionEnd

Section "Applications" SecApplications
  SetOutPath "$INSTDIR"
  !include ${NSIS_OUTPUT_PATH}\icub_applications_add.nsi
SectionEnd

SectionGroup "Development" SecDevelopment

  Section "Libraries" SecLibraries
    SetOutPath "$INSTDIR"
    !include ${NSIS_OUTPUT_PATH}\icub_libraries_add.nsi
  SectionEnd

  Section "Header files" SecHeaders
    SetOutPath "$INSTDIR"
    !include ${NSIS_OUTPUT_PATH}\icub_headers_add.nsi
  SectionEnd

SectionGroupEnd

SectionGroup "Dependencies" SecDependencies
  Section "Ipopt files" SecIpopt
    SetOutPath "$INSTDIR"
    !include ${NSIS_OUTPUT_PATH}\icub_ipopt_add.nsi
  SectionEnd

  Section "OpenCV files" SecOpenCV
    SetOutPath "$INSTDIR"
    !include ${NSIS_OUTPUT_PATH}\icub_opencv_add.nsi
	!include ${NSIS_OUTPUT_PATH}\icub_opencv_bin_add.nsi
  SectionEnd

  Section "ODE files" SecODE
    SetOutPath "$INSTDIR"
    !include ${NSIS_OUTPUT_PATH}\icub_ode_add.nsi
  SectionEnd

  Section "SDL files" SecSDL
    SetOutPath "$INSTDIR"
    !include ${NSIS_OUTPUT_PATH}\icub_sdl_add.nsi
	!include ${NSIS_OUTPUT_PATH}\icub_sdl_bin_add.nsi
  SectionEnd

  Section "QT3 files" SecQt3
    SetOutPath "$INSTDIR"
    !include ${NSIS_OUTPUT_PATH}\icub_qt3_add.nsi
	!include ${NSIS_OUTPUT_PATH}\icub_qt3_bin_add.nsi
  SectionEnd

  Section "GLUT files" SecGLUT
    SetOutPath "$INSTDIR"
    !include ${NSIS_OUTPUT_PATH}\icub_glut_add.nsi
	!include ${NSIS_OUTPUT_PATH}\icub_glut_bin_add.nsi
  SectionEnd
SectionGroupEnd

SectionGroup "Runtime" SecRuntime

  Section "Visual Studio DLLs (nonfree)" SecVcDlls
    SetOutPath "$INSTDIR"
    !include ${NSIS_OUTPUT_PATH}\icub_vc_dlls_add.nsi
  SectionEnd
  
SectionGroupEnd


!ifndef WriteEnvStr_Base
  !ifdef ALL_USERS
    !define WriteEnvStr_Base "HKLM"
    !define WriteEnvStr_RegKey \
       'HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"'
  !else
    !define WriteEnvStr_Base "HKCU"
    !define WriteEnvStr_RegKey 'HKCU "Environment"'
  !endif
!endif

Section "Environment variables" SecPath
  ${EnvVarUpdate} $0 "PATH" "A" "${WriteEnvStr_Base}" "$INSTDIR\${RUNTIMES_DIR}"
  ${EnvVarUpdate} $0 "PATH" "A" "${WriteEnvStr_Base}" "$INSTDIR\${INST2}"
  ${EnvVarUpdate} $0 "LIB" "A" "${WriteEnvStr_Base}" "$INSTDIR\${INST2}\lib"
  ${EnvVarUpdate} $0 "INCLUDE" "A" "${WriteEnvStr_Base}" "$INSTDIR\${INST2}\include"
  
  ${EnvVarUpdate} $0 "CMAKE_PREFIX_PATH" "A" "${WriteEnvStr_Base}" "$INSTDIR"
  
  #WriteRegExpandStr ${WriteEnvStr_RegKey} ICUB_DIR "$INSTDIR\${INST2}"
  WriteRegExpandStr ${WriteEnvStr_RegKey} ICUB_ROOT "$INSTDIR\${INST2}"
  
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
SectionEnd

Section "-last"
  
SectionEnd

;--------------------------------
;Descriptions
  
;Language strings
LangString DESC_SecModules ${LANG_ENGLISH} "iCub modules."
LangString DESC_SecApplications ${LANG_ENGLISH} "iCub applications."
LangString DESC_SecDevelopment ${LANG_ENGLISH} "Files for developers."
LangString DESC_SecLibraries ${LANG_ENGLISH} "C++ libraries."
LangString DESC_SecHeaders ${LANG_ENGLISH} "Header files."
LangString DESC_SecIpopt ${LANG_ENGLISH} "Ipopt files."
LangString DESC_SecOpenCV ${LANG_ENGLISH} "OpenCV files."
LangString DESC_SecVcDlls ${LANG_ENGLISH} "Visual Studio runtime redistributable files.  Not free software. If you already have Visual Studio installed, you may want to skip this."
LangString DESC_SecSDL ${LANG_ENGLISH} "Simple Direct Layer (SDL)."
LangString DESC_SecGLUT ${LANG_ENGLISH} "GLUT."
LangString DESC_SecQT3 ${LANG_ENGLISH} "QT3."
LangString DESC_SecPath ${LANG_ENGLISH} "Add iCub software to PATH, LIB, and INCLUDE variables, and set ICUB_DIR and ICUB_ROOT variable."

;Assign language strings to sections
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  ; !insertmacro MUI_DESCRIPTION_TEXT ${SecBase} $(DESC_SecBase)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecModules} $(DESC_SecModules)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecApplications} $(DESC_SecApplications)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecDevelopment} $(DESC_SecDevelopment)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecLibraries} $(DESC_SecLibraries)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecIpopt} $(DESC_SecIpopt)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecOpenCV} $(DESC_SecOpenCV)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecHeaders} $(DESC_SecHeaders)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecVcDlls} $(DESC_SecVcDlls)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecPath} $(DESC_SecPath)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------
;Uninstaller Section

Section "Uninstall"
  ${un.EnvVarUpdate} $0 "PATH" "R" "${WriteEnvStr_Base}" "$INSTDIR\${RUNTIMES_DIR}"
  ${un.EnvVarUpdate} $0 "PATH" "R" "${WriteEnvStr_Base}" "$INSTDIR\${INST2}\bin"
  ${un.EnvVarUpdate} $0 "LIB" "R" "${WriteEnvStr_Base}" "$INSTDIR\${INST2}\lib"
  ${un.EnvVarUpdate} $0 "INCLUDE" "R" "${WriteEnvStr_Base}" "$INSTDIR\${INST2}\include"
  #Push "$INSTDIR\bin"
  #Call un.RemoveFromPath
  #Push "LIB"
  #Push "$INSTDIR\lib"
  #Call un.RemoveFromEnvVar
 # DeleteRegValue ${WriteEnvStr_RegKey} ICUB_DIR
 # SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000

  DeleteRegValue ${WriteEnvStr_RegKey} ICUB_ROOT
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
  
  !include ${NSIS_OUTPUT_PATH}\icub_base_remove.nsi
  !include ${NSIS_OUTPUT_PATH}\icub_libraries_remove.nsi
  !include ${NSIS_OUTPUT_PATH}\icub_ipopt_remove.nsi
  !include ${NSIS_OUTPUT_PATH}\icub_opencv_remove.nsi
  !include ${NSIS_OUTPUT_PATH}\icub_opencv_bin_remove.nsi
  !include ${NSIS_OUTPUT_PATH}\icub_headers_remove.nsi
  !include ${NSIS_OUTPUT_PATH}\icub_vc_dlls_remove.nsi
  !include ${NSIS_OUTPUT_PATH}\icub_sdl_remove.nsi
  !include ${NSIS_OUTPUT_PATH}\icub_sdl_bin_remove.nsi
  !include ${NSIS_OUTPUT_PATH}\icub_glut_remove.nsi
  !include ${NSIS_OUTPUT_PATH}\icub_glut_bin_remove.nsi
  !include ${NSIS_OUTPUT_PATH}\icub_ode_remove.nsi
  !include ${NSIS_OUTPUT_PATH}\icub_qt3_remove.nsi
  !include ${NSIS_OUTPUT_PATH}\icub_qt3_bin_remove.nsi
  !include ${NSIS_OUTPUT_PATH}\icub_modules_remove.nsi
  !include ${NSIS_OUTPUT_PATH}\icub_applications_remove.nsi
    
  Delete "$INSTDIR\Uninstall_iCub.exe"

  RMDir /r "$INSTDIR\${INST2}\bin"
  RMDir /r "$INSTDIR\${INST2}\lib"
  RMDir /r "$INSTDIR\${INST2}\include"
  RMDir /r "$INSTDIR\${INST2}"
  
  RMDir /r "$INSTDIR\${IPOPT_SUB}"
  RMDir /r "$INSTDIR\${OPENCV_SUB}"
  RMDir /r "$INSTDIR\${SDL_SUB}"
  RMDir /r "$INSTDIR\${GLUT_SUB}"
  RMDir /r "$INSTDIR\${ODE_SUB}"
  RMDir /r "$INSTDIR\${QT3_SUB}"

  !insertmacro UnregisterPackage iCub ${INST2}
  !insertmacro UnregisterPackage ipopt ${IPOPT_SUB}
  !insertmacro UnregisterPackage OpenCV ${OPENCV_SUB}
  
  !insertmacro UnregisterPackage sdl ${SDL_SUB}
  !insertmacro UnregisterPackage glut ${GLUT_SUB}
  !insertmacro UnregisterPackage qt3 ${QT3_SUB}
  !insertmacro UnregisterPackage ode ${ODE_SUB}
  
SectionEnd

Function .onInit
 !insertmacro MULTIUSER_INIT
FunctionEnd

Function un.onInit
  !insertmacro MULTIUSER_UNINIT
FunctionEnd

Function CheckYARPVersion
 
	ClearErrors
	ReadRegStr $0 HKCU "Software\${VENDOR}\YARP\yarp-${YARP_VERSION}" ""
	DetailPrint "Got registry key $0"
 
	IfErrors 0 NoAbort
	Abort "Setup could not find YARP; this is required for installation. Please install YARP."
 
    IfFileExists $0\cmake\YARPConfig.cmake NoAbort
	Abort "YARP was found in the registry but no YARPConfig.cmake was located in $0. Please re-install YARP."
	
	NoAbort:
		DetailPrint "YARP was found in the system"
		Goto ExitFunction
 

	ExitFunction:
 
FunctionEnd

Function CheckGSLVersion
 
	ClearErrors
	ReadRegStr $0 HKCU "Software\${VENDOR}\GSL\gsl-${GSL_VERSION}" ""
	DetailPrint "Got registry key $0"
 
	IfErrors 0 NoAbort
	Abort "Setup could not find GSL; this is required for installation. Please install GSL."
 
	NoAbort:
		DetailPrint "GSL was found in the system"
		Goto ExitFunction
 	ExitFunction:
 
FunctionEnd


