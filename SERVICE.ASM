        .model tiny
        locals @@
        .186
        .code

PALETTE         equ     98h
PALETTE_1       equ     0E3h

        org     100h
start:  jmp     realstart

file_dat        db      '307_ex.dat',0
file_txt        db      '307_ex.txt',0

copyright       db      'SERVICE.COM - (C) 2002 Gilyazov R.',13,10
                db      '8x16 Russian VGA font (C) 1989 Pete I. Kvitek',13,10,'$'
keine           db      'Никаких операций не выполнено$'
success         db      'Операция завершена успешно$'
changed         db      'Настройки изменены$'
updating        db      'Файлы обновляются',13,10,'$'
msg             db      'Выберите функцию:$'
menu            db      ' Обновить     ',0
                db      ' Расшифровать ',0
                db      ' Зашифровать  ',0
                db      ' Настроить    ',0
                db      ' Отмена       ',0
newpass         db      13,'Введите пароль для шифрования',13,10
                db      '(8 символов): $'
confirm         db      13,10,'Повторите пароль: $'
getpass         db      13,' ',0FDh,' $'
endpass         db      'Неверный пароль',7,'$'
error1          db      13,10,'Вы ошиблись. Повторите попытку',13,10,10,'$'
error2          db      13,10,'Пароль должен содержать 8 символов',13,10,10,'$'
error3          db      13,10,'Фатальная ошибка$'
error4          db      'Ошибка резидента$'
error5          db      'Эта программа является частью INSTALL.COM!$'


out_message     dw      keine

errorlevel      db      9

menuitems       equ     5

realstart:
        cmp     byte ptr cs:[81h],'Я'
        je      @@_ja
        mov     dx,offset error5
        mov     ah,9
        int     21h
        ret
@@_ja:  mov     ax,0FACEh
        int     21h
        cmp     ax,2002h
        je      @@strt
        mov     ah,9
        mov     dx,offset error4
        int     21h
        mov     ax,4c05h
        int     21h
@@strt: mov     ax,3
        int     10h
        call    font_l

	and     byte ptr [passf+5],0FEh

	mov	bl,7
	call	fclsa
        mov     ah,9
        mov     dx,offset msg
        int     21h

	mov     ax,1000h
        mov     bl,01
        mov     bh,PALETTE
        int     10h
        mov     bl,07
        mov     bh,PALETTE_1
        int     10h

        mov     ax,0001h
        mov     bx,0F07h
        mov     cx,7101h
        call    makeframe

;-- start of decrypt ----------
        mov     bx,offset passf                 ;Дешифруем имя файла
        mov     byte ptr [bx+8],'O'
        mov     byte ptr [bx+9],'m'
        add     byte ptr [bx+2],17h
        mov     byte ptr [bx+6],'.'
        xor     byte ptr [bx+7],0E0h
;-- end of decrypt ------------

        mov     ax,0102h
        mov     bx,1F70h
        mov     cx,menuitems
        mov     si,offset menu
        call    makemenu

        cmp     bh,01h
        je      exit
        cmp     bl,04h
        je      exit
        cmp     bl,03h
        je      setup
        cmp     bl,01h
        je      call_decrypt
        cmp     bl,02h
        je      call_crypt
        or      bl,bl
        je      update

update:
        mov     byte ptr [errorlevel],8
        mov     word ptr [out_message],offset updating
        jmp     short exit
setup:
        call    set_quest
        jmp	realstart
call_crypt:
        call    crypt           ;Шифруем пароль
        call    savepass        ;Сохраняем в 307_ex.com
        call    txt_2_dat       ;Шифруем сам фаёл данных
        mov     word ptr [out_message],offset success
        mov     byte ptr [errorlevel],0
        jmp     short exit      ;Выход

call_decrypt:
        call    decrypt
        call    dat_2_txt
        mov     word ptr [out_message],offset success
        mov     byte ptr [errorlevel],0

exit:
        call    emptypass       ;Очищаем парольные буфера (! :) )
        mov     bl,7
        call    fclsa           ;Обчищаем экран
        mov     ah,9
        mov     dx,offset copyright
        int     21h
        mov     ax,1000h
        mov     bx,0101h
        int     10h
        mov     ax,1000h
        mov     bx,0707h
        int     10h
        call    font_r          ;Восстанавливаем оригинальный шрифт
        mov     ah,9
        mov     dx,word ptr [out_message]
        int     21h
        mov     ah,4ch
        mov     al,errorlevel
        int     21h


INCLUDE INCLUDE\SERVICE.INC     ;Здесь всякие рулезные процедурки :)
INCLUDE INCLUDE\FONTLOAD.INC


passchars       db      ?               ;Количество символов в пароле
fhandle         dw      ?               ;ФайлОвая рукоятка
fhandle_txt     dw      ?               ;---"---- для TXT
bread           dw      ?               ;Прочитано байтов
pass1           db      8 dup (?)       ;Пароль1
pass2           db      8 dup (?)       ;Пароль2 (подтверждение)
passw           db      16 dup (?)      ;Ключ

pbuf:           db      3 dup (?)       ;Буфер для чтения пароля
passe           db      31 dup (?)      ;Зашифрованный пароль

buffer1         db      512 dup (?)     ;Буфер для чтения/записи
buffer2         db      512 dup (?)     ;-----------"-----------
buffer:                                 ;Буффер для FONT_L
        end     start