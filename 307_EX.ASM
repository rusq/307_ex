	.model tiny
	locals @@
	.186
	.code
	org	100h
start:	jmp	realstart

password	db	32 dup (0FFh)		;16 байт - зашифр. пароль, 16 байт - мусор
dataf		db	'307_ex.dat',0
fatal1		db	'Не найден файл с данными. Продолжение невозможно.$'
fatal2		db	'Данная программа не настроена$'
inst_title	db	0B1h,0,29,'ПРОЧИТАЙТЕ ВНИМАТЕЛЬНО!',0
instruc		db	10,'   Вам предлагается ответить на семь вопросов.',13,10
		db	'Для выбора ответа следует использовать клавиши [1]-[9].',13,10
		db	'Клавиша [Enter] служит для подтверждения выбора и перехода на следующий вопрос.',13,10
		db	'   Между вопросами возможна задержка из-за несовершенства алгоритма генерации ',13,10
		db	'случайных чисел (зависит от тактовой частоты CPU)',13,10
		db	'   Удачи!',13,10,10
		db	'Нажмите любую клавишу для начала тестирования...$'
realstart:
	cld
	mov	ax,0FACEh
	int	21h
	cmp	ax,2002h
	je	pst
	call	fatal

pst:	mov	bx,offset password
	cmp	byte ptr [bx],0FFh
	jne	pss
	mov	dx,offset fatal2
	mov	ah,9
	int	21h
	ret

pss:
	xor	ax,ax
	call	fcursor
	call	font_l				;Loading screen font
	call	open				;Opening file with data
	call	passwd				;Decrypting password
	call	bufferize			;Copying file data to buffer (with deciphering)
	call	close				;Получаем длину файла и закрываем его
	call	genseed				;Генерируем seed
	call	fill_tbl			;Заполняем таблицы (возможна ошибка)
	mov	ax,1003h
	xor	bx,bx
	int	10h

	mov	bl,1Bh
	call	fclsa
	mov	bx,0B1h
	call	faline
	mov	si,offset inst_title
	call	fwritea

	mov	ah,9
	mov	dx,offset instruc
	int	21h

	xor	ax,ax
	int	16h

	call	infobar
	
exloop:	call	gen_num
	call	ask

	

aus:	call	font_r
	mov	al,1
	call	fcursor
	ret

;ASK: Задаёт вопрос номер AX
;На входе:
;	AX - номер вопроса
;На выходе: 
;	BH - всего правильных ответов
;	BL - выбрано правильных ответов
ask	proc	near

	mov	word ptr cs:[@@rite],0			;Инициализация переменных
	mov	byte ptr cs:[@@count],0

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
	mov	bl,byte ptr cs:[@@NoLite]
	mov	dh,1
	call	w_wrap
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
	jmp	@@return
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
;Подсчёт количества правильных и не - ответов
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
@@stat_err1	db	34h,24,0,'Вы должны выбрать хотя бы один пункт',0
ask	endp

;На входе: Si - адрес строки

change_stat	proc	near
	push	ax
	push	bx
	push	cx
	mov	al,7
	int	29h
	mov	bx,1830h
	call	faline
	call	fwritea
	pop	cx
	pop	bx
	pop	ax
	ret
change_stat	endp
INCLUDE INCLUDE\307_EX.INC			;Процедурки :)
INCLUDE INCLUDE\FONTLOAD.INC

;█████ Переменные █████

q_asked		db	0			;Количество уже заданных вопросов
q_num		dw	0			;Количество вопросов
l_count		dw	0			;Количество линий в буфере
fhandle		dw	?
fsize		dw	?			;Размер файла
bread		dw	?
__seed		dw	?			;Для генератора случайных чисел
passwtmp	db	16 dup (?)
readbuf		db	512 dup (?)
decodbuf	db	512 dup (?)
t_rows		dw	1024 dup (?)		;Смещения строк
t_answ		db	1024 dup (?)		;Количество строк в вопросе
t_asked		db	1024 dup (?)		;Массив заданных вопросов

buffer:
	end	start
