@echo off
title G-Tweaker

chcp 65001

:: Checa se o Batch foi Executado como Administrador
:: Se não foi, Abra com Previlégios de Administrador.
open_as_admin:
reg query "HKU\S-1-5-19" >nul 2>&1
if '%errorlevel%'=='0' goto :admin_check

echo O G-Tweaker necessita que você o abra como Administrador. Reabrindo como Administrador...
powershell.exe -Command "Start-Process cmd -ArgumentList '/c %~f0' -Verb RunAs"
exit /b

:admin_check
echo O G-Tweaker Está em Execução em Modo Administrador.
goto :main_menu

:: Função para Criar um Ponto de Restauração.
:CreateRestorePoint
echo Criando um Ponto de Restauração...
powershell.exe -Command "Checkpoint-Computer -Description 'Ponto de Restauração - G-Tweaker' -RestorePointType 'MODIFY_SETTINGS'"
if %errorlevel% neq 0 (
    echo Falha ao Criar o Ponto de Restauração. Fechando...
    pause
    exit /b 1
)
echo O Ponto de Restauração foi criado com Sucesso!
goto :main_menu

:: Função para Desabilitar o Game DVR
:DisableGameDVR
echo Desabilitando o Game DVR...
reg add "HKLM\Software\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" /v value /t REG_DWORD /d 0 /f
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 0 /f
goto :main_menu

:: Função para Aplicar Tweaks de Kernel
:KernelOptimizations
echo Aplicando Tweaks de Kernel...
bcdedit /set disabledynamictick yes
bcdedit /set useplatformtick yes
bcdedit /set tscsyncpolicy Enhanced
bcdedit /set useplatformclock true
bcdedit /deletevalue tscsyncpolicy
goto :main_menu

:: Função para Aplicar Otimizações do Monitor
:MonitorOptimizations
echo Aplicando Otimizações do Monitor...
reg add "HKCU\Control Panel\Desktop" /v WaitToKillAppTimeout /t REG_SZ /d 2000 /f
reg add "HKCU\Control Panel\Desktop" /v HungAppTimeout /t REG_SZ /d 2000 /f
goto :main_menu

:: Função para Aplicar Otimizações da CPU
:CPUOptimizations
echo Aplicando Otimizações da CPU...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v SecondLevelDataCache /t REG_DWORD /d 256 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\TimeBroker" /v Start /t REG_DWORD /d 4 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 26 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v IRQ8Priority /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v IRQ16Priority /t REG_DWORD /d 2 /f
goto :main_menu

:: Otimizações de GPU
:GPUOptimizations
echo Aplicando Otimizações de GPU...

:: Detectando a GPU
for /f "tokens=2 delims=:" %%i in ('wmic path win32_videocontroller get name /value ^| findstr Name') do set gpu=%%i

:: Trim leading/trailing spaces
set gpu=%gpu:~1%
set gpu=%gpu: =%

echo Placa de Vídeo Detectada: %gpu%

if /i "%gpu%"=="NVIDIA" (
    echo Otimizações NVIDIA...
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v TdrDelay /t REG_DWORD /d 10 /f
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v TdrLevel /t REG_DWORD /d 0 /f
    echo Aplicando Otimizações de Directx para NVIDIA...
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\NVIDIA Corporation\Global\NVTweak" /v "MaxFramesAllowed" /t REG_DWORD /d 1 /f
) else if /i "%gpu%"=="AMD" (
    echo Aplicando Otimizações para AMD...
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v TdrDelay /t REG_DWORD /d 10 /f
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v TdrLevel /t REG_DWORD /d 0 /f
    echo Desabilitando AMD Crash Defender...
    sc config "AmdCrashDefender" start= disabled
    sc stop "AmdCrashDefender"
    echo Aplicando Otimizações de Directx para NVIDIA...
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\AMD\CN" /v "EnableWaitForVerticalRetrace" /t REG_DWORD /d 0 /f
) else (
    echo GPU Desconhecida, Pule as Otimizações de GPU
)

:: Otimizações de DirectX, Direct3D, e DirectDraw 
echo Aplicando Tweaks de DirectX, Direct3D, e DirectDraw
reg add "HKCU\Software\Microsoft\Direct3D" /v "MaxFrameLatency" /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Direct3D" /v "MaxFrameLatencyInUse" /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Direct3D" /v "MaxFrameLatencyLowLatencyMode" /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\DirectDraw" /v "EmulationOnly" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\DirectDraw" /v "EnablePrintScreen" /t REG_DWORD /d 0 /f

goto :main_menu

:: Função para Limpar Caches e Arquivos Temporarios
:CleanCaches
echo Limpando Cache e Arquivos Temp...
del /q /f %SystemRoot%\Prefetch\*.*
del /q /f %TEMP%\*.*
del /q /f %SystemRoot%\Temp\*.*
del /s /q /f "%userprofile%\AppData\Local\Temp\*.*"
goto :main_menu

:: Tweaks Memória Ram
:RAMOptimizations
echo Aplicando Tweaks de Memória Ram...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v ClearPageFileAtShutdown /t REG_DWORD /d 1 /f
goto :main_menu

:: Função para Aplicar Otimizações de InputLag
:InputLagOptimizations
echo Aplicando Tweaks de InputLag...
reg add "HKCU\Control Panel\Mouse" /v MouseSensitivity /t REG_SZ /d 10 /f
reg add "HKCU\Control Panel\Mouse" /v MouseSpeed /t REG_SZ /d 2 /f
echo Disabling High Precision Event Timer...
sc config "HPET" start= disabled
sc stop "HPET"

:: Tweaks de Regedit
echo Ajustando Tweaks de Regedit...
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" /v KeyboardDataQueueSize /t REG_DWORD /d 40 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v SearchOrderConfig /t REG_DWORD /d 0 /f

set /p ramSize="Quanto você tem de Memória RAM? (4GB, 6GB, 8GB, 12GB, 16GB, 24GB, 32GB, 64GB): "
if "%ramSize%"=="4GB" set regValue=400000
if "%ramSize%"=="6GB" set regValue=600000
if "%ramSize%"=="8GB" set regValue=800000
if "%ramSize%"=="12GB" set regValue=c00000
if "%ramSize%"=="16GB" set regValue=1000000
if "%ramSize%"=="24GB" set regValue=1800000
if "%ramSize%"=="32GB" set regValue=2000000
if "%ramSize%"=="64GB" set regValue=4000000

reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control" /v SvcHostSplitThresHoldInKB /t REG_DWORD /d %regValue% /f

reg add "HKLM\Software\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" /v value /t REG_DWORD /d 0 /f
reg add "HKCU\System\GameConfigStore" /v FSEWindowsCompatible /t REG_DWORD /d 1 /f
reg add "HKCU\System\GameConfigStore" /v GameDVR_FSEBehaviorMode /t REG_DWORD /d 2 /f
reg add "HKCU\System\GameConfigStore" /v GameDVR_HonorUserFSEBehaviorMode /t REG_DWORD /d 1 /f

goto :main_menu

:: Função para Aplicar os Tweaks de Regedit
:RegistryOptimizations
echo Aplicando Tweaks de Regedit...
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 20 /f

:: Tweaks de Regedit Extras
echo Aplicando Tweaks de Regedit Extras...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d ffffffff /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 0 /f

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v BackgroundOnly /t REG_SZ /d False /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v GPU Priority /t REG_DWORD /d 12 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v Affinity /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v Priority /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v Scheduling Category /t REG_SZ /d High /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v SFIO Priority /t REG_SZ /d High /f

goto :main_menu

:: Função para Aplicar os Tweaks de Energia
:EnergyPlanOptimizations
echo Aplicando PowerTweaks...
powercfg -change -monitor-timeout-ac 0
powercfg -change -disk-timeout-ac 0
powercfg -change -standby-timeout-ac 0
powercfg -change -hibernate-timeout-ac 0
powercfg -change -monitor-timeout-dc 0
powercfg -change -disk-timeout-dc 0
powercfg -change -standby-timeout-dc 0
powercfg -change -hibernate-timeout-dc 0

:: Custom energy settings
powercfg -setacvalueindex SCHEME_CURRENT SUB_VIDEO VIDEOCONLOCK 0
powercfg -setacvalueindex SCHEME_CURRENT SUB_DISK DISKIDLE 0
powercfg -setacvalueindex SCHEME_CURRENT SUB_USB USBSELECT 0
powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR IDLEDISABLE 98
powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFMODE 100
powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR IDLEDISABLE 98
powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFMODE 100

echo Tweaks Aplicados Note: Algumas Opções Daqui Podem Resultar em um Uso maior de Energia que pode aumentar o preço da conta de luz, e pode fazer o seu notebook descarregar mais rapido, Use com Sabedoria.

goto :main_menu

:: Função para Desabilitar Serviços Inúteis
:DisableUnnecessaryServices
echo Desabilitando Serviços Inúteis...
set /p printer="Você usa Impressora? (S/N): "
set /p xbox="Você usa Xbox Live ou Usa Controle de XBOX? (S/N): "
set /p hotspot="Você usa Hotspot Móvel? (S/N): "
set /p bitlocker="Você usa BitLocker? (S/N): "
set /p emulators="Você usa Emuladores ou Maquinas Virtuais? (Hyper-V) (S/N): "

echo Desabilitando Serviços Inúteis
sc config "Network Connections" start= disabled
sc config "AMD Crash Defender Service" start= disabled
sc config "Offline Files" start= disabled
sc config "Windows Image Acquisition (WIA)" start= disabled
sc config "Network Connections" start= disabled
sc config "NetBIOS over TCP/IP" start= disabled
sc config "Windows Backup" start= disabled
sc config "Smart Card" start= disabled
sc config "Windows Event Collector" start= disabled
sc config "Windows Connection Manager" start= disabled
sc config "Remote Desktop Configuration" start= disabled
sc config "Parental Controls" start= disabled
sc config "Distributed Transaction Coordinator" start= disabled
sc config "diagsvc" start= disabled
sc config "DialogBlockingService" start= disabled
sc config "Connected User Experiences and Telemetry" start= disabled
sc config "Printer Extensions and Notifications" start= disabled
sc config "Fax" start= disabled
sc config "Microsoft Keyboard Filter" start= disabled
sc config "Xbox Live Auth Manager" start= disabled
sc config "Remote Access Connection Manager" start= disabled
sc config "Automatic Remote Dialer" start= disabled
sc config "Downloaded Maps Manager" start= disabled
sc config "NFC/SE and Payment" start= disabled
sc config "Mobile Hotspot" start= disabled
sc config "Windows Time" start= disabled
sc config "Diagnostic Policy Service" start= disabled
sc config "Guest Service" start= disabled
sc config "Windows Event Log" start= disabled
sc config "Network Logon" start= disabled
sc config "Secondary Logon" start= disabled
sc config "Performance Logs and Alerts" start= disabled
sc config "Link-Layer Topology Discovery Mapper" start= disabled
sc config "Microsoft App-V Client" start= disabled
sc config "Microsoft Update Health Service" start= disabled
sc config "OpenSSH Authentication Agent" start= disabled
sc config "Optimize Drive" start= disabled
sc config "Smart Card Removal Policy" start= disabled
sc config "PNRPsvc" start= disabled
sc config "Quality Windows Audio Video Experience" start= disabled
sc config "Remote Registry" start= disabled
sc config "Routing and Remote Access" start= disabled
sc config "Save Games to Xbox Live" start= disabled
sc config "Program Compatibility Assistant Service" start= disabled
sc config "AVCTP Service" start= disabled
sc config "Microsoft Diagnostics Hub Standard Collector Service" start= disabled
sc config "Windows Biometric Service" start= disabled
sc config "Windows Font Cache Service" start= disabled
sc config "Data Sharing Service" start= disabled
sc config "Net.Tcp Port Sharing Service" start= disabled
sc config "BitLocker Drive Encryption Service" start= disabled
sc config "Sensor Data Service" start= disabled
sc config "Spatial Data Service" start= disabled
sc config "Retail Demo" start= disabled
sc config "Hyper-V Guest Shutdown Service" start= disabled
sc config "Smart Card Device Enumeration Service" start= disabled
sc config "Bluetooth Audio Gateway Service" start= disabled
sc config "Location Service" start= disabled
sc config "Windows Mobile Hotspot Service" start= disabled
sc config "Radio Management Service" start= disabled
sc config "AppX Deployment Service (AppXSVC)" start= disabled
sc config "Microsoft Defender Network Inspection Service" start= disabled
sc config "Microsoft Store Install Service" start= disabled
sc config "Block Level Backup Engine Service" start= disabled
sc config "Sensor Monitor Service" start= disabled
sc config "System Event Notification Service" start= disabled
sc config "Windows Perception Input Service" start= disabled
sc config "Diagnostic Policy Service" start= disabled
sc config "Connected Devices Platform Service" start= disabled
sc config "Hyper-V Heartbeat Service" start= disabled
sc config "Xbox Live Networking Service" start= disabled
sc config "Windows Error Reporting Service" start= disabled
sc config "AllJoyn Router Service" start= disabled
sc config "SMS Router" start= disabled
sc config "Device Management Service" start= disabled
sc config "Sensor Service" start= disabled
sc config "Windows Perception Simulation Service" start= disabled
sc config "Hyper-V Time Synchronization Service" start= disabled
sc config "Recommended Troubleshooting Service" start= disabled
sc config "Bluetooth Support Service" start= disabled
sc config "Bluetooth Support Service_4f260" start= disabled
sc config "Virtual Keyboard and Mouse Input Service" start= disabled
sc config "Telephony" start= disabled
sc config "Themes" start= disabled
sc config "Data Usage" start= disabled
sc config "Time Broker" start= disabled
sc config "WalletService" start= disabled
sc config "Windows Mixed Reality OpenXR Service" start= disabled
sc config "Windows Presentation Foundation Font Cache 3.0.0.0" start= disabled
sc config "Windows Remote Management (WS-Management)" start= disabled
sc config "Windows Search" start= disabled
sc config "Windows Update" start= disabled
sc config "Xbox Accessory Management Service" start= disabled

:: Serviços Condicionais
if /i "%printer%"=="N" (
    sc config "Spooler" start= disabled
    sc stop "Spooler"
)

if /i "%xbox%"=="N" (
    sc config "XblGameSave" start= disabled
    sc stop "XblGameSave"
    sc config "XboxNetApiSvc" start= disabled
    sc stop "XboxNetApiSvc"
)

if /i "%hotspot%"=="N" (
    sc config "icssvc" start= disabled
    sc stop "icssvc"
)

if /i "%bitlocker[]"=="N" (
    sc config "BDESVC" start= disabled
    sc stop "BDESVC"
)

if /i "%emulators%"=="N" (
    sc config "vmicguestinterface" start= disabled
    sc stop "vmicguestinterface"
    sc config "vmickvpexchange" start= disabled
    sc stop "vmickvpexchange"
    sc config "vmicshutdown" start= disabled
    sc stop "vmicshutdown"
    sc config "vmicheartbeat" start= disabled
    sc stop "vmicheartbeat"
    sc config "vmictimesync" start= disabled
    sc stop "vmictimesync"
    sc config "vmicrdv" start= disabled
    sc stop "vmicrdv"
    sc config "vmicvss" start= disabled
    sc stop "vmicvss"
)
goto :main_menu

:: Debloater
:Debloater
echo Removendo Aplicativos Desnecessários (Debloat)

:: Lista de Apps para Remoção
set appsList=\
"Microsoft.BingNews" \
"Microsoft.GetHelp" \
"Microsoft.GetStarted" \
"Microsoft.MicrosoftSolitaireCollection" \
"Microsoft.MixedReality.Portal" \
"Microsoft.Office.OneNote" \
"Microsoft.People" \
"Microsoft.SkypeApp" \
"Microsoft.StorePurchaseApp" \
"Microsoft.WindowsCamera" \
"Microsoft.WindowsMaps" \
"Microsoft.WindowsSoundRecorder" \
"Microsoft.XboxGameOverlay" \
"Microsoft.XboxGamingOverlay" \
"Microsoft.XboxIdentityProvider" \
"Microsoft.YourPhone" 

set /p removeEdge="Você deseja remover o Microsoft Edge? (S/N): "
if /i "%removeEdge%"=="S" (
    set appsList=%appsList% "Microsoft.MicrosoftEdge"
)

set /p removeXboxApp="Você deseja remover o Xbox App? (S/N): "
if /i "%removeXboxApp%"=="S" (
    set appsList=%appsList% "Microsoft.XboxApp"
)

for %%a in (%appsList%) do (
    echo Removing %%a...
    powershell.exe -Command "Get-AppxPackage -Name %%a | Remove-AppxPackage"
)

echo Aplicativos Desnecessários foram Removidos com Sucesso!
goto :main_menu

:: Tweaks Adicionais
:AdditionalOptimizations
echo Aplicando Tweaks Adicionais

:: Reportar Erros do Windows
echo Desabilitando Reportar Erros do Windows...
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v Disabled /t REG_DWORD /d 1 /f

:: Telemetria do Windows
echo Desabilitar Telemetria do Windows...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f

:: Windows SmartScreen
echo Desabilitando Windows SmartScreen...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableSmartScreen /t REG_DWORD /d 0 /f

:: Windows Superfetch
echo Desabilitando Windows Superfetch...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableSuperfetch /t REG_DWORD /d 0 /f

:: Windows Hibernate
echo Desabilitando Windows Hibernate...
powercfg /hibernate off

goto :main_menu

:: Main Menu
:main_menu
cls
echo by GJ Tech/Gomes
color 05
echo •
echo [1] » Ponto de Restauração  [2] » Desabilitar Game DVR    [3] » Tweaks de Kernel
echo [4] » Tweaks de Monitor     [5] » Tweaks de CPU           [6] » Tweaks de GPU
echo [7] » Clean                 [8] » Tweaks de Memória       [9] » Tweaks de InputLag
echo [10] » Tweaks de Regedit    [11] » Tweaks de Energia      [12] » Desabilitar Serviços Desnecessários
echo [13] » Debloater            [14] » Tweaks DirectX         [15] » Tweaks Adicionais
echo •
echo [0] Sair
echo ─
set /p choice="Selecione uma Opção: "


if "%choice%"=="1" goto :CreateRestorePoint
if "%choice%"=="2" goto :DisableGameDVR
if "%choice%"=="3" goto :KernelOptimizations
if "%choice%"=="4" goto :MonitorOptimizations
if "%choice%"=="5" goto :CPUOptimizations
if "%choice%"=="6" goto :GPUOptimizations
if "%choice%"=="7" goto :CleanCaches
if "%choice%"=="8" goto :RAMOptimizations
if "%choice%"=="9" goto :InputLagOptimizations
if "%choice%"=="10" goto :RegistryOptimizations
if "%choice%"=="11" goto :EnergyPlanOptimizations
if "%choice%"=="12" goto :DisableUnnecessaryServices
if "%choice%"=="13" goto :Debloater
if "%choice%"=="14" goto :DirectXOptimizations
if "%choice%"=="15" goto :AdditionalOptimizations
if "%choice%"=="0" exit

goto :main_menu
