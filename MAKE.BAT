@echo off
if not exist OUT\nul md OUT
if not exist out\utils\nul md out\utils
echo Building distribution...
tasm *.asm
for %%i in (*.obj) do tlink /t/x %%i
utils\p.exe -e msavt.com
utils\p.exe -e service.com
copy 307_ex.txt out
del *.obj
utils\turbobat.exe install\install.bat
copy install\install.com .
del install\install.com
utils\p.exe -e install.com
copy utils\p.exe out\utils
copy utils\rk.com out\utils
copy *.com out
copy 307_doc.txt out
copy readme.txt out
del *.com
echo Done
