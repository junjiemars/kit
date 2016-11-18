@echo off

set vstools="%1"

call "%vstools%/vsvars32.bat"
echo "%INCLUDE%"
