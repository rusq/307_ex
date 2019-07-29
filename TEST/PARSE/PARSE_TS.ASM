	.model tiny
	.code
	org	100h
start:
	call	fill_tbl
	ret

fill_tbl	PROC	NEAR		;Процедура заполнения таблиц
	push	si
	push	cx
	push	ax
	mov	si,offset buffer
	mov	cx,word ptr [fsize]
@@lp:	lodsb
	cmp	al,'\'			;Нарвались на начало вопроса?
	jne	@@10			;Нет - продолжить
	inc	byte ptr [q_num]	;Увеличить счётчик вопросов
@@10:	loop	@@lp

	mov	si,offset buffer
	mov	cx,word ptr [fsize]
	mov	bx,offset t_rows
	mov	word ptr [bx],si

@@tf:	lodsb
	cmp	al,0Dh			;Нашли окончание строки
	jne	@@nxt
	lodsb
	inc	l_count
	add	bx,2
	mov	word ptr [bx],si
@@nxt:	loop	@@tf

	mov	di,offset t_answ
	mov	bx,offset t_rows
	mov	cl,q_num		;Количество вопросов
	xor	ah,ah
	add	bx,2
@@ta:	mov	bp,word ptr [bx]
	mov	al,byte ptr [bp]
	and	al,0Fh			;Преобразуем к двоичному числу
	or	al,al			;Это ноль?
	jz	@@error			;Да - ошибка
	stosb
	shl	al,1
	add	al,4
	add	bx,ax
	loop	@@ta
	

	pop	ax
	pop	cx
	pop	si
	ret
@@error:
	mov	ax,4cffh
	int	21h
fill_tbl	ENDP	

fsize	dw	893
q_num	db	0
l_count	db	0		;Счётчик линий
	
buffer	label byte
db	'\Входящие в биогеоценоз живые существа со временем меняются, эволюционируют. Значит ли это, что биогеоценозы со временем выходят из устойчивого равновесия?',13,10
db	'4',13,10
db	'1. Да. Всё обстоит именно так',13,10
db	'2. Изменившийся организм покидает свой биогеоценоз. Поэтому биогеоценоз всегда остаётся в устойчивом равновесии.',13,10
db	'+3. Нет. По мере эволюционирования организмов биогеоценозы переходят из одного устойчивого состояния в другое.',13,10
db	'4. Не всегда. Всё зависит от конкретного биогеоценоза, от конкретных условий, в которых он существует.',13,10
db	'\Что объединяет в себе понятие "биосфера"?',13,10
db	'4',13,10
db	'1. Это понятие объединяет в себе всё живое на земле, включая человека.',13,10
db	'2. Это понятие объединяет атмосферу, гидросферу, осферу, литосферу и ноосферу со всем, что в них обитает.',13,10
db	'+3. Это понятие объединяет атмосферу, гидросферу и осферу со всем, что в них обитает.',13,10
db	'4. Это понятие объединяет всё живое на Земле, кроме человека',13,10

t_rows	dw	1024 dup (0)
t_answ	db	1024 dup (0)
	end	start