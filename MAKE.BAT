@echo off
echo Building distribution...
tasm *.asm
for %%i in (*.obj) do tlink /t/x %%i
utils\$pirit.com msavt.com
utils\$pirit.com service.com
copy 307_ex.txt out
del *.obj
utils\turbobat.exe install\install.bat
copy install\install.com .
del install\install.com
utils\p.exe install.com
copy *.com out
copy 307_doc.txt out
copy service.txt out
del *.com
echo Done
