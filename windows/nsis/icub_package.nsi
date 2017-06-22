##############################################################################
#
# Copyright: (C) 2011 Department of Robotics Brain and Cognitive Sciences, Istituto Italiano di Tecnologia
# Authors: Lorenzo Natale
# CopyPolicy: Released under the terms of the LGPLv2.1 or later, see LGPL.TXT

!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "EnvVarUpdate.nsh"
!include "x64.nsh"

!define MULTIUSER_EXECUTIONLEVEL Highest
!include MultiUser.nsh

Name "iCub ${ICUB_VERSION}"
OutFile "${NSIS_OUTPUT_PATH}\iCub_${ICUB_VERSION}_${BUILD_VERSION}_${ICUB_TWEAK}.exe"
InstallDir "$PROGRAMFILES\${VENDOR}"
InstallDirRegKey HKCU "Software\iCub\Common" "LastInstallLocation"
RequestExecutionLevel admin

!define MUI_ABORTWARNING

################# the following piece could be used also as a header e.g. myheader.nsh
##          HEADER PART BEGINS HERE
!define SF_USELECTED  0
###############################
 
!macro SecSelect SecId
  Push $0
  IntOp $0 ${SF_SELECTED} | ${SF_RO}
  SectionSetFlags ${SecId} $0
  SectionSetInstTypes ${SecId} 1
  Pop $0
!macroend
 
!define SelectSection '!insertmacro SecSelect'
#################################
 
!macro SecUnSelect SecId
  Push $0
  IntOp $0 ${SF_USELECTED} | ${SF_RO}
  SectionSetFlags ${SecId} $0
  SectionSetText  ${SecId} ""
  Pop $0
!macroend
 
!define UnSelectSection '!insertmacro SecUnSelect'
###################################
 
!macro SecExtract SecId
  Push $0
  IntOp $0 ${SF_USELECTED} | ${SF_RO}
  SectionSetFlags ${SecId} $0
  SectionSetInstTypes ${SecId} 2
  Pop $0
!macroend
 
!define SetSectionExtract '!insertmacro SecExtract'
###################################
 
!macro Groups GroupId
  Push $0
  SectionGetFlags ${GroupId} $0
  IntOp $0 $0 | ${SF_RO}
  IntOp $0 $0 ^ ${SF_BOLD}
  IntOp $0 $0 ^ ${SF_EXPAND}
  SectionSetFlags ${GroupId} $0
  Pop $0
!macroend
 
!define SetSectionGroup "!insertmacro Groups"
####################################
 
!macro GroupRO GroupId
  Push $0
  IntOp $0 ${SF_SECGRP} | ${SF_RO}
  SectionSetFlags ${GroupId} $0
  Pop $0
!macroend
 
!define MakeGroupReadOnly '!insertmacro GroupRO' 
##        HEADER PART for selections ENDS HERE

;--------------------------------
;Utilities

!macro UpdateEnvironmentAppend var value
  ${EnvVarUpdate} $0 "${var}" "A" "${WriteEnvStr_Base}" "${value}" 
!macroend

!macro un.UpdateEnvironmentAppend var value
  ${un.EnvVarUpdate} $0 "${var}" "R" "${WriteEnvStr_Base}" "${value}" 
!macroend

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
   !insertmacro ReplaceInFile "$INSTDIR\${INST2}\lib\ICUB\icub-export-inst-includes.cmake" ${package_key} ${dir}
   !insertmacro ReplaceInFile "$INSTDIR\${INST2}\lib\ICUB\icub-export-install-release.cmake"  ${package_key} ${dir}
   !insertmacro ReplaceInFile "$INSTDIR\${INST2}\lib\ICUB\icub-export-install-debug.cmake"  ${package_key} ${dir}
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
  Var /GLOBAL YARP_PATH
  Var /GLOBAL YARP_FOUND
  
  SetOutPath "$INSTDIR"
  !insertmacro RegisterPackage ipopt ${IPOPT_SUB}
  !insertmacro RegisterPackage OpenCV ${OPENCV_SUB}
  !insertmacro RegisterPackage sdl ${SDL_SUB}
  !insertmacro RegisterPackage ode ${ODE_SUB}
  !insertmacro RegisterPackage glut ${GLUT_SUB}
  !insertmacro RegisterPackage gsl ${GSL_SUB}
  SectionIn RO
SectionEnd

SectionGroup "iCub" SeciCub

  Section "Modules" SecModules
    SetOutPath "$INSTDIR"
    !include ${NSIS_OUTPUT_PATH}\icub_modules_add.nsi
  SectionEnd

  Section "DataDirs" SecDataDirs
    SetOutPath "$INSTDIR"
    !include ${NSIS_OUTPUT_PATH}\icub_data_dirs_add.nsi
  FileOpen $1 '$INSTDIR\${INST2}\share\iCub\plugins\iCub.ini' w
    FileWrite $1 '###### This file is automatically generated by NSIS'
    FileWrite $1 '$\r$\n'
    FileWrite $1 '[search iCub]'
    FileWrite $1 '$\r$\n'
  ${StrRepLocal} $2 "$INSTDIR\${INST2}\lib\iCub" "\" "/"
    FileWrite $1 'path "$2"'
    FileWrite $1 '$\r$\n'
    FileWrite $1 'extension ".dll"'
    FileWrite $1 '$\r$\n'
    FileWrite $1 'type "shared"'
    FileWrite $1 '$\r$\n'    
  FileClose $1
  SectionEnd

  Section "Libraries" SecLibraries
    SetOutPath "$INSTDIR"
    !include ${NSIS_OUTPUT_PATH}\icub_libraries_add.nsi
  SectionEnd

  Section "Header files" SecHeaders
    SetOutPath "$INSTDIR"
    !include ${NSIS_OUTPUT_PATH}\icub_headers_add.nsi
  SectionEnd
  
  Section "Visual Studio DLLs (nonfree)" SecVcDlls
    SetOutPath "$INSTDIR"
    !include ${NSIS_OUTPUT_PATH}\icub_vc_dlls_add.nsi
  SectionEnd
    
  Section "CMake Files" SecCMake
    SetOutPath "$INSTDIR"
    !include ${NSIS_OUTPUT_PATH}\icub_base_add.nsi
    ${StrRepLocal} $0 "$INSTDIR\${INST2}" "\" "/"
    !insertmacro FixCMakeForPackage __NSIS_ICUB_INSTALLED_LOCATION__ $\"$0$\"
  ${StrRepLocal} $0 "$INSTDIR\${GSL_SUB}" "\" "/"
    !insertmacro FixCMakeForPackage __NSIS_GSL_INSTALLED_LOCATION__ $\"$0$\"
    ${StrRepLocal} $0 "$INSTDIR\${ACE_SUB}" "\" "/"
    !insertmacro FixCMakeForPackage __NSIS_ACE_INSTALLED_LOCATION__ $\"$0$\"
  ${StrRepLocal} $0 "$INSTDIR\${IPOPT_SUB}" "\" "/"
    !insertmacro FixCMakeForPackage __NSIS_IPOPT_INSTALLED_LOCATION__ $\"$0$\"
  ${StrRepLocal} $0 "$INSTDIR\${OPENCV_SUB}" "\" "/"
    !insertmacro FixCMakeForPackage __NSIS_OPENCV_INSTALLED_LOCATION__ $\"$0$\"
  SectionEnd
 
SectionGroupEnd

Section "Ipopt files" SecIpopt
    SetOutPath "$INSTDIR"
    !include ${NSIS_OUTPUT_PATH}\icub_ipopt_add.nsi
SectionEnd

Section "OpenCV files" SecOpenCV
    SetOutPath "$INSTDIR"
    !include ${NSIS_OUTPUT_PATH}\icub_opencv_add.nsi
  !include ${NSIS_OUTPUT_PATH}\icub_opencv_bin_add.nsi
  ${StrRepLocal} $0 "$INSTDIR\${OPENCV_SUB}" "\" "/"
    !insertmacro ReplaceInFile "$INSTDIR\${OPENCV_SUB}\OpenCVConfig.cmake" __NSIS_OPENCV_INSTALLED_LOCATION__ $\"$0$\"
SectionEnd

Section "ODE files" SecODE
    SetOutPath "$INSTDIR"
    !include ${NSIS_OUTPUT_PATH}\icub_ode_add.nsi
SectionEnd

Section "GSL files" SecGSL
    SetOutPath "$INSTDIR"
    !include ${NSIS_OUTPUT_PATH}\icub_gsl_add.nsi
    
SectionEnd

Section "SDL files" SecSDL
    SetOutPath "$INSTDIR"
    !include ${NSIS_OUTPUT_PATH}\icub_sdl_add.nsi
  !include ${NSIS_OUTPUT_PATH}\icub_sdl_bin_add.nsi
SectionEnd

Section "GLUT files" SecGLUT
    SetOutPath "$INSTDIR"
    !include ${NSIS_OUTPUT_PATH}\icub_glut_add.nsi
  !include ${NSIS_OUTPUT_PATH}\icub_glut_bin_add.nsi
SectionEnd

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
 
   !insertmacro SectionFlagIsSet ${SeciCub} ${SF_PSELECTED} isSel chkAll
   chkAll:
     !insertmacro SectionFlagIsSet ${SeciCub} ${SF_SELECTED} isSel notSel
   notSel:
      DetailPrint "Skipping iCub environment variables and PATH"
    Goto endif 
   isSel:
      DetailPrint "Adding iCub environment variables and PATH"
      WriteRegExpandStr ${WriteEnvStr_RegKey} ICUB_DIR "$INSTDIR\${INST2}"
    !insertmacro UpdateEnvironmentAppend PATH "$INSTDIR\${INST2}\bin"
    !insertmacro UpdateEnvironmentAppend YARP_DATA_DIRS "$INSTDIR\${INST2}\share\iCub"
   endif:

   !insertmacro SectionFlagIsSet ${SecIpopt} ${SF_SELECTED} isIpoptSel notIpoptSel
   notIpoptSel:
     DetailPrint "Skipping IPOPT environment variables and PATH"
    Goto ipoptEndIf 
   isIpoptSel:
      WriteRegExpandStr ${WriteEnvStr_RegKey} IPOPT_DIR "$INSTDIR\${IPOPT_SUB}"
    !insertmacro UpdateEnvironmentAppend PATH "$INSTDIR\${IPOPT_SUB}\bin"
   ipoptEndIf:
   
   !insertmacro SectionFlagIsSet ${SecODE} ${SF_SELECTED} isODESel notODESel
   notODESel:
    DetailPrint "Skipping ODE environment variables and PATH"
    Goto odeEndif 
   isODESel:
       WriteRegExpandStr ${WriteEnvStr_RegKey} ODE_DIR "$INSTDIR\${ODE_SUB}"
   odeEndif:
  
   !insertmacro SectionFlagIsSet ${SecOpenCV} ${SF_SELECTED} isOpenCVSel notOpenCVSel
   notOpenCVSel:
    DetailPrint "Skipping OpenCV environment variables and PATH"
    Goto endOpenCVIf 
   isOpenCVSel:
      WriteRegExpandStr ${WriteEnvStr_RegKey} OPENCV_DIR "$INSTDIR\${OPENCV_SUB}"
        ${If} ${ICUB_PLATFORM} == "x64"
    ${OrIf} ${ICUB_PLATFORM} == "amd64"
    ${OrIf} ${ICUB_PLATFORM} == "x86_amd64"
      StrCpy $0 "x64"
     ${EndIf}
     ${If} ${ICUB_PLATFORM} == "x86"
      StrCpy $0 "x86"
    ${EndIf}
    ${If} ${ICUB_VARIANT} == "v10"
      StrCpy $1 "vc10"
      ${EndIf}
      ${If} ${ICUB_VARIANT} == "v11"
      StrCpy $1 "vc11"
      ${EndIf}
      ${If} ${ICUB_VARIANT} == "v12"
      StrCpy $1 "vc12"
      ${EndIf}
    !insertmacro UpdateEnvironmentAppend PATH "$INSTDIR\${OPENCV_SUB}\$0\$1\bin"
   endOpenCVIf:
   
   !insertmacro SectionFlagIsSet ${SecGSL} ${SF_SELECTED} isSelGSL notGSLSel
   notGSLSel:
    DetailPrint "Skipping GSL environment variables and PATH"
    Goto gslEndif 
   isSelGSL:
    !insertmacro UpdateEnvironmentAppend "LIB" "$INSTDIR\${GSL_SUB}\lib"
    !insertmacro UpdateEnvironmentAppend "INCLUDE" "$INSTDIR\${GSL_SUB}\include"
    !insertmacro UpdateEnvironmentAppend "GSL_DIR" "$INSTDIR\${GSL_SUB}"
    WriteRegExpandStr ${WriteEnvStr_RegKey} GSL_DIR "$INSTDIR\${GSL_SUB}"
   gslEndif:

   !insertmacro SectionFlagIsSet ${SecSDL} ${SF_SELECTED} isSelSDL notSDLSel
   notSDLSel:
    DetailPrint "Skipping SDL environment variables and PATH"
    Goto sdlEndif 
   isSelSDL:
    !insertmacro UpdateEnvironmentAppend PATH "$INSTDIR\${SDL_SUB}\lib"
    WriteRegExpandStr ${WriteEnvStr_RegKey} SDLDIR "$INSTDIR\${SDL_SUB}"
   sdlEndif:
   
   !insertmacro SectionFlagIsSet ${SecGLUT} ${SF_SELECTED} isGLUTSel notGLUTSel
   notGLUTSel:
    DetailPrint "Skipping GLUT environment variables and PATH"
    Goto endifGLUT 
   isGLUTSel:
    WriteRegExpandStr ${WriteEnvStr_RegKey} GLUT_DIR "$INSTDIR\${GLUT_SUB}"
    !insertmacro UpdateEnvironmentAppend PATH "$INSTDIR\${GLUT_SUB}"
   endifGLUT:
  
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
SectionEnd

Section "-last"

   !insertmacro SectionFlagIsSet ${SeciCub} ${SF_PSELECTED} isSel chkAll
   chkAll:
     !insertmacro SectionFlagIsSet ${SeciCub} ${SF_SELECTED} isSel notSel
   notSel:
    Goto endif 
   isSel:
      !insertmacro RegisterPackage iCub ${INST2}
   endif:
  
  WriteUninstaller "$INSTDIR\Uninstall_iCub.exe"
SectionEnd

;--------------------------------
;Descriptions
  
;Language strings
LangString DESC_SeciCub ${LANG_ENGLISH} "iCub software. You need first to install YARP binaries or you can uncheck this item if you want to compile the iCub software from svn."
LangString DESC_SecModules ${LANG_ENGLISH} "Modules."
LangString DESC_SecDataDirs ${LANG_ENGLISH} "All data, config, templates and XML files."
LangString DESC_SecDevelopment ${LANG_ENGLISH} "Files for developers."
LangString DESC_SecLibraries ${LANG_ENGLISH} "C++ libraries."
LangString DESC_SecHeaders ${LANG_ENGLISH} "Header files."
LangString DESC_SecCMake ${LANG_ENGLISH} "CMake files."
LangString DESC_SecIpopt ${LANG_ENGLISH} "Interior Point OPTimizer (Ipopt), used for solving inverse problems."
LangString DESC_SecOpenCV ${LANG_ENGLISH} "Open Source Computer Vision library (OpenCV)."
LangString DESC_SecVcDlls ${LANG_ENGLISH} "Visual Studio runtime redistributable files.  Not free software. If you already have Visual Studio installed, you may want to skip this."
LangString DESC_SecSDL ${LANG_ENGLISH} "Simple Direct Layer (SDL). Used by the simulator."
LangString DESC_SecGLUT ${LANG_ENGLISH} "The OpenGL Utility Toolkit (GLUT). Used by the iCub visualization gui."
LangString DESC_SecODE ${LANG_ENGLISH} "Open Dynamics Engine (ODE). Used by the simulator"
LangString DESC_SecGSL ${LANG_ENGLISH} "GNU Scientific Library (GSL)."
LangString DESC_SecPath ${LANG_ENGLISH} "Modify user environment. Add executables and DLLs to the PATH, set variables used by CMake (e.g. ICUB_DIR, IPOPT_DIR, etc.)"

;Assign language strings to sections
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SeciCub} $(DESC_SeciCub)
  ; !insertmacro MUI_DESCRIPTION_TEXT ${SecBase} $(DESC_SecBase)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecModules} $(DESC_SecModules)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecDataDirs} $(DESC_SecDataDirs)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecLibraries} $(DESC_SecLibraries)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecIpopt} $(DESC_SecIpopt)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecOpenCV} $(DESC_SecOpenCV)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecHeaders} $(DESC_SecHeaders)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecCMake} $(DESC_SecCMake)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecVcDlls} $(DESC_SecVcDlls)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecPath} $(DESC_SecPath)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecGLUT} $(DESC_SecGLUT)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecSDL} $(DESC_SecSDL)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecODE} $(DESC_SecODE)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecGSL} $(DESC_SecGSL)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------
;Uninstaller Section

Section "Uninstall"
# iCub
  ClearErrors
  ReadRegStr $0 HKCU "Software\${VENDOR}\iCub\${INST2}" ""
  IfErrors 0 iCubFound
  DetailPrint "iCub was not found in the system"
  Goto iCubNotFound
  iCubFound:
    DetailPrint "Removing iCub registry key"
    DeleteRegValue ${WriteEnvStr_RegKey} ICUB_DIR
    DetailPrint "Removing iCub environment variables"
    !insertmacro un.UpdateEnvironmentAppend PATH "$INSTDIR\${INST2}\bin"
    !insertmacro un.UpdateEnvironmentAppend YARP_DATA_DIRS "$INSTDIR\${INST2}\share\iCub"
  iCubNotFound:
# IPOPT
  ClearErrors
  ReadRegStr $0 HKCU "Software\${VENDOR}\ipopt\${IPOPT_SUB}" ""
  IfErrors 0 ipoptFound
  DetailPrint "Ipopt was not found in the system"
  Goto ipoptNotFound
  ipoptFound:
    DetailPrint "Removing ipopt registry key"
    DeleteRegValue ${WriteEnvStr_RegKey} IPOPT_DIR
    DetailPrint "Removing ipopt environment variables"
    !insertmacro un.UpdateEnvironmentAppend PATH "$INSTDIR\${IPOPT_SUB}\bin"
  ipoptNotFound:
  ClearErrors
  ReadRegStr $0 HKCU "Software\${VENDOR}\ode\${ODE_SUB}" ""
# ODE
  IfErrors 0 odeFound
  DetailPrint "ode was not found in the system"
  Goto odeNotFound
  odeFound:
    DetailPrint "Removing ode registry key"
    DeleteRegValue ${WriteEnvStr_RegKey} ODE_DIR
  odeNotFound:
# GSL
  ClearErrors
  ReadRegStr $0 HKCU "Software\${VENDOR}\gsl\${GSL_SUB}" ""
  IfErrors 0 gslFound
  DetailPrint "GSL was not found in the system"
  Goto gslNotFound
  gslFound:
    DetailPrint "Removing GSL registry key"
    DeleteRegValue ${WriteEnvStr_RegKey} GSL_DIR
    DetailPrint "Removing GSL environment variables"
    !insertmacro un.UpdateEnvironmentAppend "LIB" "$INSTDIR\${GSL_SUB}\lib"
    !insertmacro un.UpdateEnvironmentAppend "INCLUDE" "$INSTDIR\${GSL_SUB}\include"
    !insertmacro un.UpdateEnvironmentAppend "GSL_DIR" "$INSTDIR\${GSL_SUB}"
  gslNotFound:
# OPENCV  
  ClearErrors
  ReadRegStr $0 HKCU "Software\${VENDOR}\opencv\${OPENCV_SUB}" ""
  IfErrors 0 opencvFound
  DetailPrint "OpenCV was not found in the system"
  Goto opencvNotFound
  opencvFound:
    DetailPrint "Removing opencv registry key"
    DeleteRegValue ${WriteEnvStr_RegKey} OPENCV_DIR
    ${If} ${ICUB_PLATFORM} == "x64"
    ${OrIf} ${ICUB_PLATFORM} == "amd64"
    ${OrIf} ${ICUB_PLATFORM} == "x86_amd64"
      StrCpy $0 "x64"
     ${EndIf}
     ${If} ${ICUB_PLATFORM} == "x86"
      StrCpy $0 "x86"
    ${EndIf}
    ${If} ${ICUB_VARIANT} == "v10"
      StrCpy $1 "vc10"
      ${EndIf}
      ${If} ${ICUB_VARIANT} == "v11"
      StrCpy $1 "vc11"
      ${EndIf}
      ${If} ${ICUB_VARIANT} == "v12"
      StrCpy $1 "vc12"
      ${EndIf}
    DetailPrint "Removing opencv environment variables"
    !insertmacro un.UpdateEnvironmentAppend PATH "$INSTDIR\${OPENCV_SUB}\$0\$1\bin"
  opencvNotFound:
# SDL  
  ClearErrors
  ReadRegStr $0 HKCU "Software\${VENDOR}\sdl\${SDL_SUB}" ""
  IfErrors 0 sdlFound
  DetailPrint "SDL was not found in the system"
  Goto sqlNotFound
  sdlFound:
    DetailPrint "Removing sdl registry key"
    DeleteRegValue ${WriteEnvStr_RegKey} SDLDIR 
    DetailPrint "Removing sdl environment variables"
    !insertmacro un.UpdateEnvironmentAppend PATH "$INSTDIR\${SDL_SUB}\lib"
  sqlNotFound:
# GLUT  
  ClearErrors
  ReadRegStr $0 HKCU "Software\${VENDOR}\glut\${GLUT_SUB}" ""
  IfErrors 0 glutFound
  DetailPrint "GLUT was not found in the system"
  Goto glutNotFound
  glutFound:
    DetailPrint "Removing GLUT registry key"
    DeleteRegValue ${WriteEnvStr_RegKey} GLUT_DIR
    DetailPrint "Removing GLUT environment variables"
    !insertmacro un.UpdateEnvironmentAppend PATH "$INSTDIR\${GLUT_SUB}"
  glutNotFound:
  
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
  !include ${NSIS_OUTPUT_PATH}\icub_gsl_remove.nsi
  !include ${NSIS_OUTPUT_PATH}\icub_modules_remove.nsi
  !include ${NSIS_OUTPUT_PATH}\icub_data_dirs_remove.nsi
  !include ${NSIS_OUTPUT_PATH}\icub_headers_remove.nsi
  !include ${NSIS_OUTPUT_PATH}\icub_vc_dlls_remove.nsi
      
  Delete "$INSTDIR\Uninstall_iCub.exe"

  RMDir /r "$INSTDIR\${INST2}\bin"
  RMDir /r "$INSTDIR\${INST2}\lib"
  RMDir /r "$INSTDIR\${INST2}\include"
  RMDir /r "$INSTDIR\${INST2}\cmake"
  RMDir /r "$INSTDIR\${INST2}\lib"
  RMDir /r "$INSTDIR\${INST2}\share"
  RMDir /r "$INSTDIR\${INST2}"
  
  RMDir /r "$INSTDIR\${IPOPT_SUB}"
  RMDir /r "$INSTDIR\${OPENCV_SUB}"
  RMDir /r "$INSTDIR\${SDL_SUB}"
  RMDir /r "$INSTDIR\${GLUT_SUB}"
  RMDir /r "$INSTDIR\${ODE_SUB}"
  RMDir /r "$INSTDIR\${GSL_SUB}"

  !insertmacro UnregisterPackage iCub ${INST2}
  !insertmacro UnregisterPackage ipopt ${IPOPT_SUB}
  !insertmacro UnregisterPackage OpenCV ${OPENCV_SUB}
  !insertmacro UnregisterPackage sdl ${SDL_SUB}
  !insertmacro UnregisterPackage glut ${GLUT_SUB}
  !insertmacro UnregisterPackage ode ${ODE_SUB}
  !insertmacro UnregisterPackage gsl ${GSL_SUB}
  
SectionEnd

Function .onInit
  Call CheckYARPVersion
  ;Call CheckGSLVersion
  
  ${If} ${ICUB_PLATFORM} == "x64"
  ${OrIf} ${ICUB_PLATFORM} == "amd64"
  ${OrIf} ${ICUB_PLATFORM} == "x86_amd64"
    ${If} ${RUNNINGX64}
      StrCpy $instdir "$PROGRAMFILES64\${VENDOR}"
      SetRegView 64
    ${Else}
      MessageBox MB_OK "Sorry, but this version runs only on 64 bit machines, please use a 32 bit package"
      Abort
    ${EndIf}
  ${Else}
    ${If} ${RUNNINGX64}
      StrCpy $instdir "$PROGRAMFILES32\${VENDOR}"
    ${EndIf}
  ${EndIf}

  StrCmp $YARP_FOUND "1" yarp notyarp
  yarp:
  DetailPrint "YARP found at $YARP_PATH"
  Goto yarpdone
  notyarp:
  DetailPrint "YARP was not found at $YARP_PATH"
  ${SetSectionGroup} ${SeciCub}
  ${UnSelectSection} ${SecModules}
  ${UnSelectSection} ${SecDataDirs}
  ${UnSelectSection} ${SecLibraries}
  ${UnSelectSection} ${SecHeaders}
  ${UnSelectSection} ${SecHeaders}
  ${UnSelectSection} ${SecVcDlls}
  ${UnSelectSection} ${SecCMake}
  ${MakeGroupReadOnly} ${SeciCub}
  ;IntOp $R0 ${SECTION_OFF} | ${SF_RO}
  ;SectionSetFlags ${SecCMake} $R0
  yarpdone:
 !insertmacro MULTIUSER_INIT
FunctionEnd

Function un.onInit
  !insertmacro MULTIUSER_UNINIT
FunctionEnd

Function CheckYARPVersion
 
  ClearErrors
  ReadRegStr $0 HKCU "Software\${VENDOR}\YARP\yarp-${YARP_VERSION}" ""
  DetailPrint "Got registry key $0"
 
  StrCpy $YARP_FOUND "0"
  
  IfErrors ExitFunction NoAbort
  
  NoAbort:
    DetailPrint "YARP was found in the system"
    StrCpy $YARP_PATH $0
    StrCpy $YARP_FOUND "1"
    Goto ExitFunction

  ExitFunction:
 
FunctionEnd