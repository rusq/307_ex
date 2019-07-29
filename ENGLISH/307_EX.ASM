        .model tiny
        locals @@
        .186
        .code
        org     100h
start:  jmp     realstart

password        db      32 dup (0FFh)           ;16 байт - зашифр. пароль, 16 байт - мусор
dataf           db      '307_ex.dat',0
fatal1          db      'Can''t find data file$'
fatal2          db      'This program has not been set up properly$'
inst_title      db      0B1h,0,33,'READ CAREFULLY',0
instruc         db      10,'   You''ve got to answer some questions',13,10
                db      'You can use [1]-[9] keys to select the right answer.',13,10
                db      '[─┘] key is used to confirm your selection and to advance to next question',13,10
                db      '   There can be a delay between questions because of random number generator',13,10
                db      '(depends on your CPU)',13,10
                db      '   Have a nice test!',13,10,10
                db      'Strike any key...$'
ask4surname     db      'Enter your surname: $'
sur_stat        db      30h,24,0,'Use only English letters, and press [─┘] when finished',0
stat_arsehole   db      0C0h,24,0,'TEST FAILED :(',0
stat_botan      db      0A0h,24,0,'TEST PASSED :)',0

final_sur       db      'Surname    : $'

final_screen    db      13,10
final_end       db      'Time passed: '
fn_hour         db      '00:00:00'
                db      13,10
final_q         db      'Your result: '
done            db      '00/00'
                db      13,10,10
                db      'Call your teacher$'
realstart:
        cld
        mov     ax,0FACEh
        int     21h
        cmp     ax,2002h
        je      pst
        call    fatal

pst:    mov     bx,offset password
        cmp     byte ptr [bx],0FFh
        jne     pss
        mov     dx,offset fatal2
        mov     ah,9
        int     21h
        ret

pss:
        xor     ax,ax
        call    fcursor
        call    font_l                          ;Loading screen font
        call    open                            ;Opening file with data
        call    passwd                          ;Decrypting password
        call    bufferize                       ;Copying file data to buffer (with deciphering)
        call    close                           ;Получаем длину файла и закрываем его
        call    genseed                         ;Генерируем seed
        call    fill_tbl                        ;Заполняем таблицы (возможна ошибка)
        mov     ax,1003h
        xor     bx,bx
        int     10h

restart:
        mov     bl,1Bh
        call    fclsa
        mov     bx,0B1h
        call    faline
        mov     si,offset inst_title
        call    fwritea

        mov     ah,9
        mov     dx,offset instruc
        int     21h

        xor     ax,ax
        int     16h

;Спросим фамилию :)
@@reask:
        mov     ax,01
        call    fcursor
        mov     bl,1Bh
        call    infobar
        mov     si,offset sur_stat
        call    change_stat
        mov     ah,9
        mov     dx,offset ask4surname
        int     21h

        mov     di,offset surname
        mov     cx,19
        mov     bh,'A'
        mov     bl,'z'
        call    field
        cmp     ah,01                                   ;Студент пожелал остаться неизвестным?
        je      @@reask                                 ;Да - спросим ещё разок :)
        cmp     cx,2                                    ;Фамилия должна быть хотя-бы 2 символа ("Тё" :) )
        jb      @@reask
        mov     bx,cx                                   ;Пихаем $ в конец :)
        mov     byte ptr [surname+bx],'$'
        xor     ax,ax                                   ;Выключим курсор нах!
        call    fcursor

        xor     ah,ah
        int     1ah
        mov     word ptr [ticks_start],dx
        mov     word ptr [ticks_start+2],cx

        xor     cx,cx
        mov     cl,byte ptr [q_total]
;-------------------------
;       jmp     short aa
;-------------------------
exloop: push    cx
        mov     bl,1Bh

        call    infobar
        call    gen_num
        call    ask
        cmp     bh,bl
        je      @@ex10
        jmp     short @@ex20
@@ex10: inc     byte ptr [q_rite]
@@ex20: pop     cx
        loop    exloop

aa:     xor     ah,ah
        int     1ah
        mov     word ptr [ticks_end],dx
        mov     word ptr [ticks_end+2],cx

        mov     ax,word ptr [ticks_end]
        sub     ax,word ptr [ticks_start]
        mov     word ptr [waited],ax

        mov     ax,word ptr [ticks_end+2]
        sbb     ax,word ptr [ticks_start+2]

        mov     word ptr [waited+2],ax

        mov     si,offset waited
        mov     di,offset secs_tot
        mov     bx,18
        call    div32                   ;Считаем секунды
        call    divtime                 ;И время

        mov     cx,3
        mov     bp,offset test_time
        mov     di,offset fn_hour
        call    conv_t

        mov     cx,2
        mov     bp,offset q_rite
        mov     di,offset done
        call    conv_t

        mov     al,q_rite
        cmp     al,q_togo
        jb      @@dumb
        mov     word ptr [stat],offset stat_botan
        mov     bl,2Fh
        jmp     short @@qq
@@dumb:
        mov     word ptr [stat],offset stat_arsehole
        mov     bl,4Bh

@@qq:   call    infobar
        mov     si,word ptr [stat]
        call    change_stat
        mov     ah,9
        mov     dx,offset final_sur
        int     21h
        mov     dx,offset surname
        int     21h
        mov     dx,offset final_screen
        int     21h

@@in:   xor     ax,ax
        int     16h
        cmp     ax,2308h                        ;^H
        jne     @@in


aus:    call    font_r
        mov     al,1
        call    fcursor
        mov     bl,7
        call    fclsa

        ret

INCLUDE INCLUDE\NUM2ASC.PRC
INCLUDE INCLUDE\307_EX.INC                      ;Процедурки :)
INCLUDE INCLUDE\FONTLOAD.INC

;█████ Переменные █████

q_rite          db      0                       ;Количество правильных ответов
q_total         db      7                       ;Количество вопросов для задавания
q_togo          db      5                       ;Барьер, кот. необходимо преодолеть
q_num           dw      0                       ;Количество вопросов
l_count         dw      0                       ;Количество линий в буфере
surname         db      20 dup (?)              ;Фамилия студента

ticks_start     dw      2 dup (?)               ;Засекаем тики :)
ticks_end       dw      2 dup (?)               ;Тики в конце теста
waited          dw      2 dup (?)               ;Сколько тиков тестировались
secs_tot        dw      2 dup (?)               ;Сколько секундов тестировались :)
test_time       db      3 dup (?)               ;Финальное время теста!

stat            dw      ?
fhandle         dw      ?
fsize           dw      ?                       ;Размер файла
bread           dw      ?
__seed          dw      ?                       ;Для генератора случайных чисел
passwtmp        db      16 dup (?)
readbuf         db      512 dup (?)
decodbuf        db      512 dup (?)
t_rows          dw      1024 dup (?)            ;Смещения строк
t_answ          db      1024 dup (?)            ;Количество строк в вопросе
t_asked         db      1024 dup (?)            ;Массив заданных вопросов

buffer:
        end     start