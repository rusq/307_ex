@echo off
	if	exist C:\307_TEST\nul	goto only_307

	cls

	if not	exist msavt.com		goto error0
	if not	exist service.com	goto error0
	if not	exist 307_ex.com	goto error0
	if not	exist 307_ex.txt	goto error0
	if not	exist 307_doc.txt	goto error0
	if not	exist readme.txt	goto error0
	if not	exist utils\p.exe	goto error0

	if	-%1==- %0 DOS
	if	-%1==- goto end
	if	-%2==-remove goto remove
	echo Устанавливаемся на диск C:...
	if not	exist C:\%1\nul		goto error1

rem	Собсно, установка :)

	copy	msavt.com C:\%1 >nul
	md	C:\307_TEST

	copy	C:\AUTOEXEC.BAT C:\AUTOEXEC.TMP >nul
	del	C:\AUTOEXEC.BAT >nul
	echo @echo off >C:\AUTOEXEC.BAT
	echo C:\%1\msavt.com >>C:\AUTOEXEC.BAT
	copy /b C:\AUTOEXEC.BAT + C:\AUTOEXEC.TMP C:\AUTOEXEC.BAT >nul
	del	C:\AUTOEXEC.TMP
	goto only_307

:error0
	echo Не найден один или несколько программных компонентов.
	goto	end
:error1
	echo Каталог C:\%1 не найден. Установка прервана.
	echo Если MS-DOS находится в другом каталоге, укажите его
	echo в качестве первого параметра в командной строке.
	echo.
	echo Например, если DOS установлен в каталоге C:\MSDOS следует запускать так:
	echo INSTALL MSDOS
	goto end

:only_307
	service.com Я
	if errorlevel 5 if not errorlevel 6 goto msavt
	if errorlevel 8 if not errorlevel 9 goto copy
	if errorlevel 9 if not errorlevel 10 goto end
:copy
	copy	307_ex.com C:\307_TEST >nul
	copy	307_ex.dat C:\307_TEST >nul
	utils\p.exe -e C:\307_TEST\307_EX.COM
	
	goto end
:msavt
	msavt.com
	goto	only_307
:error3
	echo.
	echo Непредвиденная ошибка. Удаляю все файлы
:remove	del	C:\307_TEST\SERVICE.COM
	del	C:\307_TEST\307_EX.COM
	del	C:\307_TEST\307_EX.TXT
	del	C:\%1\MSAVT.COM
	rd	C:\307_TEST

:end
	if not	-%1==- echo.
	if not	-%1==- echo (C) 2002 Gilyazov R..

