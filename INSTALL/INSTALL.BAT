@echo off
	cls

	if not	exist msavt.com		goto error0
	if not	exist service.com	goto error0
	if not	exist 307_ex.com	goto error0
	if not	exist 307_ex.txt	goto error0

	if	-%1==- %0 DOS
	if	-%1==- goto end
	echo Устанавливаемся на диск C:...
	if not	exist C:\%1\nul		goto error1
	if	exist C:\307_TEST\nul	goto error2

rem	Собсно, установка :)

	copy	msavt.com C:\%1 >nul
	md	C:\307_TEST
	copy	307_ex.com C:\307_TEST >nul
	copy	307_ex.txt C:\307_TEST >nul

	copy	C:\AUTOEXEC.BAT C:\AUTOEXEC.TMP >nul
	del	C:\AUTOEXEC.BAT >nul
	echo @echo off >C:\AUTOEXEC.BAT
	echo C:\%1\msavt.com >>C:\AUTOEXEC.BAT
	copy /b C:\AUTOEXEC.BAT + C:\AUTOEXEC.TMP C:\AUTOEXEC.BAT >nul
	del	C:\AUTOEXEC.TMP

	echo Сейчас последует запуск системной программы для шифрования файла данных
	echo В этой программе следует выбрать пункт ЗАШИФРОВАТЬ, и ввести пароль.
	pause
	copy	service.com C:\307_TEST
	C:\%1\msavt.com
	C:
	cd	\307_TEST
	service.com
	if not	errorlevel 0 goto error3
	del	307_ex.txt
	del	service.com
	cls

	goto	success
:error0
	echo Не найден один или несколько программных компонентов.
	goto	end
:error1
	echo Каталог C:\%1 не найден. Установка прервана.
	echo Если MS-DOS находится в другом каталоге, укажите его
	echo.
	echo в качестве первого параметра в командной строке.
	echo Например, если DOS установлен в каталоге C:\MSDOS следует запускать так:
	echo %0 MSDOS
	goto end

:error2
	echo Программа уже установлена. Установка прервана.
	goto end

:error3
	echo Непредвиденная ошибка
	goto end

:success
	echo Установка успешно завершена. Спасибо за Ваш выбор.

:end
	if not	-%1==- echo (C) 2002 GruppenFuhrer.
