@echo off

set face_name="Lucida Console"
set code_page=65001
set font_size=14
set quick_edit=1

set argc=0
for %%x in (%*) do set /a argc+=1
if %argc% equ 1 set face_name=%1

echo "set face_name to %face_name%"
echo "set code_page to %code_page%"
echo "set font_size to %font_size%"
echo "set quick_edit to %quick_edit%"

echo 
echo "backup to hklm-console.reg"
reg export "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont" hklm-console.reg /y >nul

echo "add hklm>console>ttf"
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont" /v 000 /t REG_SZ /d %face_name% /f

echo "backup to hkcu-console.reg"
reg export "HKCU\Console" hkcu-console.reg /y >nul

echo "setup console"
reg add "HKCU\Console" /v CodePage /t REG_DWORD /d %code_page% /f
reg add "HKCU\Console" /v FaceName /t REG_SZ /d %face_name% /f
reg add "HKCU\Console" /v FontSize /t REG_DWORD /d %font_size% /f
reg add "HKCU\Console" /v QuickEdit /t REG_DWORD /d %quick_edit% /f

reg add "HKCU\Console\%%SystemRoot%%_system32_cmd.exe" /v CodePage /t REG_DWORD /d %code_page% /f
reg add "HKCU\Console\%%SystemRoot%%_system32_cmd.exe" /v FaceName /t REG_SZ /d %face_name% /f
reg add "HKCU\Console\%%SystemRoot%%_system32_cmd.exe" /v FontSize /t REG_DWORD /d %font_size% /f
reg add "HKCU\Console\%%SystemRoot%%_system32_cmd.exe" /v QuickEdit /t REG_DWORD /d %quick_edit% /f
