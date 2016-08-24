
REM backup hklm's ttf
reg export "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont" hklm-ttf.reg>nul

REM add default font
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont" /v 000 /t REG_SZ /d "White Rabbit"

REM backup hkcu's console
reg export "HKCU\Console" hkcu-console.reg>nul

REM setup console
reg add HKCU\Console /v CodePage /t REG_DWORD /d 65001 /f
reg add HKCU\Console /v FaceName /t REG_SZ /d "White Rabbit" /f
reg add HKCU\Console /v FontSize /t REG_DWORD /d 14 /f
reg add HKCU\Console /v QuickEdit /t REG_DWORD /d 1 /f


