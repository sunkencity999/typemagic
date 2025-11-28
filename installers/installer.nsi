!include "MUI2.nsh"

Name "TypeMagic Ollama Setup"
OutFile "TypeMagicOllamaInstaller-Windows.exe"
RequestExecutionLevel admin
InstallDir "$TEMP\TypeMagicOllama"

!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"

!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

Section "Install"
    SetOutPath "$INSTDIR"
    
    ; Extract the PowerShell script
    File "install_windows.ps1"
    
    DetailPrint "Running TypeMagic setup script..."
    
    ; Run the PowerShell script
    ; We use ExecWait to wait for it to finish
    ExecWait 'powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "$INSTDIR\install_windows.ps1"' $0
    
    ; Check exit code
    ${If} $0 != 0
        MessageBox MB_OK|MB_ICONSTOP "Installation failed with error code $0."
    ${Else}
        MessageBox MB_OK|MB_ICONINFORMATION "Installation completed successfully!"
    ${EndIf}
    
    ; Cleanup
    SetOutPath "$TEMP"
    RMDir /r "$INSTDIR"
SectionEnd
