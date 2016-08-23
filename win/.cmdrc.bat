@echo off
setlocal enabledelayedexpansion enableextensions
set "cmd.con=HKCU\Console\%%SystemRoot%%_system32_cmd.exe /v"
set "ram=!tmp!\WRAM.tmp"
del "%tmp%\_$xy.bat">nul 2>&1
if [%1]==[ok] goto:init
Reg export HKCU\Console Backup.reg>nul
Reg delete HKCU\Console\%%SystemRoot%%_system32_cmd.exe /f>nul
for %%a in (
"FaceName /t REG_SZ /d "Terminal" /f"
"FontFamily /t REG_DWORD /d 48 /f"
"FontSize /t REG_DWORD /d 1024294 /f"
"FontWeight /t REG_DWORD /d 700 /f"
"ScreenBufferSize /t REG_DWORD /d 13107280 /f"
"CursorSize /t REG_DWORD /d 0 /f"
) do (
set "param=%%a"
set "param=!param:~1!"
set "param=%cmd.con% !param:~0,-1!"
Reg Add !param! >nul
)
start /high cmd /q /k "%~0" ok
for %%a in (
"FaceName /f"
"FontFamily /f"
"FontSize /f"
"FontWeight /f"
"CursorSize /f"
) do (
set "param=%%a"
set "param=!param:~1!"
set "param=%cmd.con% !param:~0,-1!"
Reg Delete !param! >nul
)
