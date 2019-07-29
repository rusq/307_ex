;SI - divident, DI - result, BX - divisor
div32	proc	near
	mov	ax,word ptr [si+2]
	xor	dx,dx
	div	bx
	mov	word ptr [di+2],ax
	mov	ax,word ptr [si]
	div	bx
	mov	word ptr [di],ax
	ret
div32	endp

divtime	proc	near
	mov	bx,3600
	mov	ax,word ptr [secs_tot+2]
	xor	dx,dx
	div	bx
	mov	ax,word ptr [secs_tot]
	div	bx
	mov	byte ptr [test_time],al

	mov	ax,dx
	xor	dx,dx
	mov	bx,60
	div	bx
	mov	byte ptr [test_time+1],al
	mov	byte ptr [test_time+2],dl
	ret
divtime	endp

;Процедура конвертирования времени
;На входе BP - адрес конвертируемого времени, DI - адрес буфера для времени, CX - количество разрядов
conv_t	proc	near
	push	ax
	push	bx

	xor	ax,ax
@@10:	push	cx
	mov	al,byte ptr [bp]
	mov	bx,10
	mov	cx,2
	call	NumToASCII
	add	di,3
	inc	bp
	pop	cx
	loop	@@10

	pop	bx
	pop	ax

	ret
conv_t	endp

;На входе - BX - адрес 3х байтного буфера (последовательность Часы, Минуты, Секунды)
gettime	proc	near
	push	ax
	push	cx
	push	dx
	mov	ah,2ch
	int	21h
	mov	byte ptr [bx],ch
	mov	byte ptr [bx+1],cl
	mov	byte ptr [bx+2],dh
	pop	dx cx ax
	ret
gettime	endp

;--------------------------------------------------
; FIELD: gets number and stores it in ax
;   In:
;     di : address of buffer
;     cx : number of digits to read
;     bh : lo char (i.e. 'A')
;     bl : hi char (i.e. 'Z')
;   Out:
;     String in buffer, or, if Enter or Esc was pressed returns scancodes of them
;--------------------------------------------------
field		proc	near
		jcxz	@@00
		push	dx
		push	di
		push	bp
		push	bx
		mov	bp,sp

		mov	dx,cx
		xor	cx,cx
		xor	bx,bx
@@10:		xor	ax,ax
		int	16h

		cmp	ah,1Ch
		je	@@99

		cmp	ah,01h
		je	@@99
		
@@20:		mov	ah,0Eh
		cmp	al,8
		jne	@@30
		cmp	cx,0
		je	@@10
		dec	cx
		dec	di
		
		int	10h
		mov	al,' '
		int	10h
		mov	al,8
		int	10h

@@30:		mov	bx,word ptr [bp]
		cmp	al,bh
		jb	@@10
		cmp	al,bl
		ja	@@10
		xor	bx,bx

		cmp	cx,dx
		je	@@10
		int	10h
		inc	cx
		stosb
		jmp	short @@10

@@99:		pop	bx
		pop	bp
		pop	di
		pop	dx
@@00:		ret
field		endp

;ASK: Задаёт вопрос номер AX
;На входе:
;	AX - номер вопроса
;На выходе: 
;	BH - всего правильных ответов
;	BL - выбрано правильных ответов
ask	proc	near

	mov	word ptr cs:[@@rite],0			;Инициализация переменных
	mov	byte ptr cs:[@@count],0
	push	bx
	push	cx
	mov	cx,10
	mov	bx,cx
@@cln:	dec	bx
	mov	byte ptr cs:[@@screen_ans+bx],0
	mov	byte ptr cs:[@@marked_ans+bx],0
	loop	@@cln

	pop	cx
	pop	bx

	mov	bx,ax
	push	ax

	mov	cx,bx
	mov	bp,bx
	xor	bx,bx
	dec	bp
	js	@@qq
@@00:	mov	al,byte ptr [t_answ+bp]
	xor	ah,ah
	add	bx,ax
	inc	bx
	inc	bx
	dec	bp
	loop	@@00

@@qq:	mov	word ptr cs:[@@ofs_in_rows],bx	

	pop	bx
	mov	cl,byte ptr [t_answ+bx]
	mov	byte ptr cs:[@@answ],cl

	mov	bx,word ptr cs:[@@ofs_in_rows]

	shl	bx,1				;Multiplying by 2 to receive offset in t_rows

	mov	si,word ptr [t_rows+bx]		;Printing question
	push	bx
	mov	bl,1Fh
	mov	dh,1
	call	w_wrap

	inc	dh				;!! Пропускаем строку!

	pop	bx

	add	bx,4				;Skipping amount of answers (we
	mov	word ptr cs:[@@rite],0
	mov	ax,word ptr [t_rows+bx]
	mov	word ptr cs:[@@beg_ans],ax		;Адрес первого ответа

@@10:	mov	si,word ptr [t_rows+bx]
	push	bx
	mov	bl,byte ptr cs:[@@NoLite]
	push	bx
	xor	bx,bx
	mov	bl,byte ptr cs:[@@count]
	mov	byte ptr cs:[@@screen_ans+bx],dh
	pop	bx
	call	w_wrap
	inc	byte ptr cs:[@@count]
	pop	bx
	cmp	dl,1
	jne	@@20
	inc	byte ptr cs:[@@rite+1]
@@20:	inc	bx
	inc	bx
	loop	@@10

@@inkey:
	xor	ax,ax
	int	16h

	cmp	ah,1Ch
	jne	@@_1
	jmp	short @@return
@@_1:	cmp	al,31h
	jb	@@inkey
	cmp	al,39h
	ja	@@inkey
	and	al,0Fh					;Преобразуем к двоичной байде :)
	cmp	al,byte ptr cs:[@@answ]
	ja	@@inkey

	xor	ah,ah
	mov	bx,ax
	dec	bx
	push	bx
	mov	dh,byte ptr cs:[@@screen_ans+bx]
	mov	ax,word ptr cs:[@@ofs_in_rows]		;Указатель на вопрос
	shl	ax,1
	add	ax,4					;Пропускаем вопрос и проч
	shl	bx,1					;Указатель на пункт * 2
	add	bx,ax
	mov	si,word ptr [t_rows+bx]
	pop	bx
	push	bx
	cmp	byte ptr cs:[@@marked_ans+bx],0		;Текущий вопрос помечен?
	jne	@@unmark				;Подопытный решил отменить вопрос.

	mov	bl,byte ptr cs:[@@HiLite]
	call	w_wrap
	pop	bx
	mov	byte ptr cs:[@@marked_ans+bx],1
	jmp	@@inkey

@@unmark:
	mov	bl,byte ptr cs:[@@NoLite]
	call	w_wrap
	pop	bx
	mov	byte ptr cs:[@@marked_ans+bx],0
	jmp	@@inkey
	

@@return:
	mov	cl,byte ptr cs:[@@answ]
	xor	ch,ch
	xor	ax,ax
	mov	bx,cx
@@99:	dec	bx
	add	al,byte ptr [@@marked_ans+bx]
	loop	@@99
	or	ax,ax
	jnz	@@out					;Нет - на inkey
	mov	si,offset cs:[@@stat_err1]
	call	change_stat
	jmp	@@inkey

@@out:	
;Подсчёт количества правильных и неправильных ответов
	mov	bx,word ptr cs:[@@ofs_in_rows]
	add	bx,2
	shl	bx,1
	xor	cx,cx
	mov	cl,byte ptr cs:[@@answ]
	mov	bp,cx

@@o10:	dec	bp
	mov	al,byte ptr cs:[@@marked_ans+bp]
	or	al,al
	jz	@@o99					;Следующий

	push	bp
	push	bx
	shl	bp,1
	add	bx,bp
	mov	si,word ptr [t_rows+bx]
	call	l_test
	pop	bx
	pop	bp

	cmp	dl,1
	je	@@o80
	mov	byte ptr cs:[@@rite],0
	jmp	short @@xit

@@o80:
	inc	byte ptr cs:[@@rite]
@@o99:	loop	@@o10

@@xit:	mov	bx,word ptr cs:[@@rite]
	ret

@@NoLite	db	1Bh
@@HiLite	db	30h

@@answ		db	0				;Количество ответов
@@rite		db	0				;Правильно отвечено
		db	0				;Всего вопросов
@@que		dw	0				;Номер вопроса
@@ofs_in_rows	dw	0				;Смещение вопроса в Общей куче
@@screen_ans	db	9 dup (0)
@@marked_ans	db	9 dup (0)
@@count		db	0
@@beg_ans	dw	0
@@stat_err1	db	4Fh,24,0,'Вы должны выбрать хотя бы один пункт',0
ask	endp
;На входе: Si - адрес строки

change_stat	proc	near
	push	ax
	push	bx
	push	cx
	push	dx
	mov	ah,03
	xor	bx,bx
	int	10h
	push	dx
	mov	bh,24
	mov	bl,byte ptr [si]
	call	faline
	call	fwritea
	mov	ah,02
	xor	bx,bx
	pop	dx
	int	10h
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
change_stat	endp

;Тест строк на помеченность
;На входе: 
;	   SI - адрес строки. 
;На выходе: DL - помеченая строка или нет? (FF - если нет, 1 если да)
;Строка должна кончаться символом 0d (идеально для текстовых файлов)
l_test	PROC	NEAR		
	push	ax

	mov	dl,0ffh
	lodsb
	cmp	al,'@'
	jne	@@100
	mov	dl,1
@@100:	pop	ax
	ret

l_test	ENDP

;-------------------------------------------------------------------------------
; FCURSOR : Turn Cursor off/on
;   In:
;      AL : Cursor status
;          AL = 0 - cursor turns off
;          AL != 0 - cursor turns on
;-------------------------------------------------------------------------------
fcursor	proc	near
	pushf
	push	bx cx
	push	ax
	mov	ah,03h
	mov	bh,00h
	int	10h
	pop	ax

	cmp	ax,0
	jne	@@10

	or	ch,00100000b
	jmp	short @@20

@@10:	and	ch,11011111b

@@20:	mov	ah,01h
	int	10h
	pop	cx bx
	popf

	ret
fcursor	endp

;Infobar - выводит балку с инфой внизу  (на 25й строке) и титульную балку вверху (на 1й строке)
infobar	proc	near
	push	ax
	push	bx
	push	dx
	push	si
;	mov	bl,1Bh
	call	fclsa
	mov	bx,0B1h
	call	faline
	mov	bx,1830h
	call	faline
	mov	si,offset @@info_bar
	call	fwritea
	mov	si,offset @@title_bar
	call	fwritea
	mov	ah,02
	xor	bx,bx
	mov	dx,0100h
	int	10h
	pop	si
	pop	dx
	pop	bx
	pop	ax
	ret
@@info_bar	db	30h,24,0,'Нажмите цифры ответов, которые Вы считаете правильными, затем [─┘]',0
@@title_bar	db	0B1h,0,0,'307_EX.COM: Программа тестирования ver 1.0.1 - ',0F7h,' 2k2 Gilyazov R.',0
infobar	endp

gen_num	proc	near				;Генерирование номера вопроса
        push	bx
	push	dx
	mov	dx,word ptr [q_num]		;всего вопросов
@@10:	call	rand16
	cmp	ax,dx
	ja	@@10
	or	ax,ax
	jz	@@10
	dec	ax
	mov	bx,ax
	cmp	byte ptr [t_asked+bx],1
	je	@@10
	mov	byte ptr [t_asked+bx],1
	pop	dx
	pop	bx
	ret
gen_num	endp

;-------------------------------------------------------------------------------
; FCLSA : clears the screen with colour you specified
;   In:
;     BL : color (See TABLE 1)
;-------------------------------------------------------------------------------
fclsa	proc	near

	pushf
	push	ax bx cx di es

	cld
	push	bx
	mov	ah,02h
	xor	bx,bx
	mov	dx,bx
	int	10h
	pop	bx
        mov ax,0b800h
        mov es,ax
        xor di,di
        mov cx,4000h
	xchg ah,bl
        mov al,20h
        rep stosw

	pop	es di cx bx ax
	popf

	ret

fclsa	endp
;-------------------------------------------------------------------------------
; FALINE : Fills a line with spaces and given attributes
;   In :
;     BH = Y (row to fill 0 - 24)
;     BL = ATTRIBUTE (See TABLE#1)
;-------------------------------------------------------------------------------
faline	proc	near
	pushf
	push	ax bx cx es di
	mov	cx,0B800h
	mov	es,cx
	mov	al,bh
	
	push	bx
	xor	ah,ah
	mov	bx,ax			;Multiply AX by 10
	shl	ax,2			;  by 4
	add	ax,bx			;  ax=ax+bx
	shl	ax,1			;  by 2
	shl	ax,3			;Multiply AX by 8
					;Total ax=ax*10*8=ax*80

	shl	ax,1		;ax = ax * 2
	mov	di,ax           ;we'll put offset in di (for movsb)
	pop	bx
	mov	cx,80
	mov	al,20h
	mov	ah,bl
	rep	stosw

	pop	di es cx bx ax
	popf
	ret
faline	endp
;-------------------------------------------------------------------------------
; FWRITEA : Fast screen output with attributes
;   DS:SI : offset of ASCIIZ string in memory
;   Structure of this string: Color,Y,X,"Message", 0
;
;   Example: 15,5,15,"I'm an arsehole",0
;
;Bitfields for character's display attribute:
;Bit(s)  Description (TABLE 1)
; 7      foreground blink or (alternate) background bright (see also AX=1003h)
; 6-4    background color
; 3      foreground bright or (alternate) alternate character set (see AX=1103h)
; 2-0    foreground color (see #0014)
;-------------------------------------------------------------------------------
fwritea	proc	near
	
	pushf
	push	es ax bx cx di
	cld
	mov	ax,0b800h
	mov	es,ax			;Vidmem segment
	mov	cl,byte ptr [si]	;Color
	mov	al,byte ptr [si+1]	;Y
	mov	bl,byte ptr [si+2]	;X
	xor	bh,bh
	mov	ah,bh
	add	si,3

	push	bx
	xor	ah,ah
	mov	bx,ax			;Multiply AX by 10
	shl	ax,1
	shl	ax,1
	add	ax,bx
	shl	ax,1
	shl	ax,3			;Multiply AX by 8
					;Total ax=ax*10*8=ax*80
	pop	bx

	add	ax,bx		;ax=ax+bx (ax = X + ax)
	shl	ax,1		;ax = ax * 2
	mov	di,ax           ;we'll put offset in di (for stosb)
@@10:	
	lodsb			;ds:[si] -> al
	cmp	al,0		;If 0 then end of string
	je	@@20
	stosb			;al -> es:[di]
	mov	al,cl
	stosb
	jmp	short @@10
@@20:
	pop	di cx bx ax es
	popf
	ret
fwritea	endp


fill_tbl	PROC	NEAR		;Процедура заполнения таблиц
	push	si
	push	di
	push	cx
	push	ax
	push	bx

	mov	si,offset buffer
	mov	cx,word ptr [fsize]	;Размер файла
@@lp:	lodsb				;Поиск вопросов
	cmp	al,'\'			;Нарвались на начало вопроса?
	jne	@@10			;Нет - продолжить
	inc	word ptr [q_num]	;Увеличить счётчик вопросов
@@10:	loop	@@lp

	mov	si,offset buffer
	mov	bx,offset t_rows
	mov	cx,word ptr [fsize]
	mov	word ptr [bx],si	;Сохраняем адрес первого вопроса

@@tf:	lodsb				;Таблица смещений строк
	cmp	al,0Dh			;Нашли окончание строки?
	jne	@@nxt			;Нет >> следующий символ
	lodsb				;Считаем символ возврата каретки
	inc	l_count			;Количество строк
	add	bx,2			;пишем слово
	mov	word ptr [bx],si	;сохраним количество строк в вопросе
@@nxt:	loop	@@tf

	mov	di,offset t_answ
	mov	bx,offset t_rows
	mov	cx,word ptr q_num		;Количество вопросов
	xor	ah,ah
	add	bx,2
@@ta:	mov	bp,word ptr [bx]	;Создание таблицы для кол-ва ответов
	mov	al,byte ptr [bp]
	and	al,0Fh			;Преобразуем к двоичному числу
	or	al,al			;Это ноль?
	jz	@@error			;Да - ошибка
	stosb
	shl	al,1			;Умножаем на 2 (для получения адреса начала следующего вопроса)
	add	al,4			;прибавляем 4, чтоб перейти на следующие адрес строки, которая содержит количество вопросов
	add	bx,ax
	loop	@@ta

	mov	di,offset t_asked	;Запишем нули в таблицу заданных вопросов
	mov	cx,512
	xor	ax,ax
@@fz:	stosw
	loop	@@fz
	
	
	pop	bx
	pop	ax
	pop	cx
	pop	di
	pop	si
	ret
@@error:
	mov	ah,9
	mov	dx,offset @@errmsg
	int	21h
	mov	ax,4cffh
	int	21h
@@errmsg	db	'FILL_TBL: Ошибка в файле данных!$'
fill_tbl	ENDP	

close	PROC	NEAR			;Процедура закрытия файла с получением его размера
	push	ax bx cx dx
	mov	ax,4202h
	mov	bx,word ptr [fhandle]
	xor	cx,cx
	mov	dx,cx
	int	21h
	mov	word ptr [fsize],ax		;Сохраним размер файла
	
	mov	ah,3eh
	int	21h
	pop	dx cx bx ax
	ret
close	ENDP

;Перенос слов, которые не влезают в 80 символов
;На входе: DH - строка, в которой печатать
;	   SI - адрес строки. 
;	   BL - цвет символов
;На выходе: DL - помеченая строка или нет? (FF - если нет, 1 если да)
;	   DH - строка, в которой кончилась печать поебени.
;Строка должна кончаться символом 0d (идеально для текстовых файлов)
;Используются средства BIOS.
w_wrap	PROC	NEAR		
	push	cx
	push	bp
	push	ax

	push	bx
	mov	ah,02			;Устанавливаем курсор на начало строки DH
	xor	bx,bx
	xor	dl,dl
	int	10h
	pop	bx

	mov	word ptr cs:[@@margin],65
	mov	word ptr cs:[@@line],0
	mov	cx,0FFFFh
	xor	bp,bp
	xor	dl,dl
@@10:	lodsb
	cmp	al,0Dh
	je	@@99
	cmp	al,'@'			;Символ начала правильного ответа
	jne	@@11
	mov	dl,1
	jmp	short @@15
@@11:	cmp	al,'\'			;Символ начала вопроса
	je	@@15
	inc	bp
	cmp	bp,word ptr cs:[@@margin]
	jb	@@12
	cmp	al,' '		; Это пробел?
	jne	@@12
	add	word ptr cs:[@@margin],80
	add	word ptr cs:[@@line],80
	mov	bp,word ptr cs:[@@line]
	mov	al,13
	int	29h
	mov	al,10
	int	29h
	mov	al,' '
	call	@@putch
	inc	bp
	call	@@putch
	inc	bp
@@12:	call	@@putch
@@15:	loop	@@10
@@99:	int	29h
	mov	al,10
	int	29h
	push	dx
	mov	ah,03
	xor	bx,bx
	int	10h
	xchg	dh,ch
	pop	dx
	xchg	ch,dh
	cmp	dl,1
	je	@@100
	mov	dl,0FFh
@@100:	pop	ax
	pop	bp
	pop	cx
	ret
@@putch:
	push	ax
	push	bx
	push	cx
	push	ds
	mov	cx,0040h
	mov	ds,cx
	mov	ah,09
	xor	bh,bh
	mov	cl,1
	int	10h
	inc	byte ptr ds:[0050h]
	pop	ds
	pop	cx
	pop	bx
	pop	ax
	ret
@@margin	dw	?
@@line		dw	?
w_wrap	ENDP

bufferize	proc	near		;Буфферизация файла с вопросами

	mov	di,offset buffer

@@loc:	mov	ah,3fh
	mov	bx,word ptr fhandle
	mov	cx,512
	mov	dx,offset readbuf
	int	21h
	jnc	@@decod
	call	fatal

@@decod:
	or	ax,ax
	jz	@@99
	push	ax
	push	di
	mov	ax,0DEAFh
	mov	si,offset readbuf
	mov	di,offset decodbuf
	mov	dx,offset passwtmp
	mov	bx,16
	int	21h
	pop	di
	pop	ax

@@buff:
	mov	word ptr [bread],ax
	mov	cx,ax
	mov	si,offset decodbuf
	rep	movsb
	jmp	short @@loc

@@99:	ret
bufferize	endp

open	proc	near
	mov	ax,3D00h
	mov	dx,offset dataf
	int	21h
	jnc	@@98
	call	fatal
@@98:
	mov	word ptr [fhandle],ax
	ret
open	endp

fatal	proc	near
	mov	ah,9
	mov	dx,offset fatal1
	int	21h
	mov	ax,4c01h
	int	21h
fatal	endp

;Password decoder proc
passwd	proc	near
	mov	cx,32
	mov	si,offset password
	mov	di,offset passwtmp

@@10:
	lodsw
	xor	ax,06A61h
	xchg	ah,al
	sub	ax,4141h
	shl	al,04
	add	al,ah
	stosb
	loop	@@10
	ret
passwd	endp

rand16	proc	near
	push	bx
	call	rand8
	mov	bx,ax
	call	rand8
	mov	ah,bl
	pop	bx
	ret
rand16	endp


genseed	proc	near		;stores seed in local var. WORD __seed
	push	cx dx
	xor	ah,ah
	int	1ah
	mov	ax,dx
	add	ax,cx
	mov	word ptr __seed,ax
	pop	dx cx
	ret
genseed	endp

rand8	proc	near		;Returns random number in WORD __seed
	push	bx cx
	mov	ax,word ptr __seed
	mov	cx,8
newbit:	mov	bx,ax
	and	bx,002Dh
	xor	bh,bl
	clc
	jpe	shift
	stc
shift:	rcr	ax,1
	loop	newbit
	mov	word ptr __seed,ax
	xor	ah,ah
	pop	cx bx
	ret
rand8	endp
