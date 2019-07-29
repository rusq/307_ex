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
inst_title	db	128+1Ch,0,29,'ПРОЧИТАЙТЕ ВНИМАТЕЛЬНО!',0
instruc		db	10,'Вам предлагается ответить на семь вопросов.',13,10
		db	'Для выбора ответа следует использовать клавиши [1]-[9].',13,10
		db	'Клавиша [Enter] служит для подтверждения выбора и перехода на следующий вопрос.',13,10,'$'
realstart:
	cld
	mov	ax,0FACEh
	int	21h
	cmp	ax,2002h
	je	pst
	call	fatal

pst:	mov	ax,1003h
	mov	bx,0001h
	int	10h
	mov	bx,offset password
	cmp	byte ptr [bx],0FFh
	jne	pss
	mov	dx,offset fatal2
	mov	ah,9
	int	21h
	ret

pss:
	call	font_l				;Loading screen font
	call	open				;Opening file with data
	call	passwd				;Decrypting password
	call	bufferize			;Copying file data to buffer (with deciphering)
	call	close				;Получаем длину файла и закрываем его
	call	genseed				;Генерируем seed
	call	fill_tbl			;Заполняем таблицы (возможна ошибка)
	mov	bl,70h
	call	fclsa
	mov	bx,1Ch
	call	faline
	mov	si,offset inst_title
	call	fwritea

	mov	ah,9
	mov	dx,offset instruc
	int	21h

	call	gen_num
	call	ask
	xor	ax,ax
	int	16h

;	mov	bx,offset t_rows
;	mov	si,word ptr [bx]
;	call	w_wrap
;	add	bx,4
;	mov	si,word ptr [bx]
;	call	w_wrap

	call	font_r
	ret

;ASK: Задаёт вопрос номер AX
;На входе:
;	AX - номер вопроса
;На выходе: 
;	BH - всего правильных ответов
;	BL - выбрано правильных ответов
ask	proc	near
	mov	bx,ax
	push	ax

	mov	cx,bx
	mov	bp,bx
	xor	bx,bx
	dec	bp
@@00:	mov	al,byte ptr [t_answ+bp]
	xor	ah,ah
	add	bx,ax
	inc	bx
	inc	bx
	dec	bp
	loop	@@00

	mov	word ptr [@@ofs_in_rows],bx	

	pop	bx
	mov	cl,byte ptr [t_answ+bx]
;	xor	ch,ch

	mov	bx,word ptr [@@ofs_in_rows]

	shl	bx,1				;Multiplying by 2 to receive offset in t_rows

	mov	si,word ptr [t_rows+bx]		;Printing question
	call	w_wrap

	add	bx,4				;Skipping amount of answers (we
	mov	word ptr [@@rite],0

@@10:	mov	si,word ptr [t_rows+bx]
	call	w_wrap
	cmp	dl,1
	jne	@@20
	inc	byte ptr [@@rite+1]
@@20:	inc	bx
	inc	bx
	loop	@@10

	mov	bx,word ptr [@@rite]
	ret
@@answ		db	0				;Количество ответов
@@rite		db	0				;Правильно отвечено
		db	0				;Всего вопросов
@@que		dw	0				;Номер вопроса
@@ofs_in_rows	dw	0				;Смещение вопроса в Общей куче

ask	endp

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
