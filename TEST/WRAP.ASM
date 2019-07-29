	.model tiny
	.code
	org	100h
start:
	mov	si,offset string
	call	w_wrap
	ret

w_wrap	PROC	NEAR		;Перенос слов, которые не влезают в 80 символов
				;На входе - SI - адрес строки. Строка должна кончатся символом 0d (идеально для текстовых файлов)
	push	bx
	push	ax
	xor	bx,bx
@@10:	lodsb
	cmp	al,0Dh
	je	@@99
	cmp	al,'@'			;Символ начала правильного ответа
	je	@@15
	cmp	al,'\'			;Символ начала вопроса
	je	@@15
	inc	bx
	cmp	bx,word ptr margin
	jb	@@12
	cmp	al,' '		; Это пробел?
	jne	@@12
	add	word ptr margin,80
	mov	al,13
	int	29h
	mov	al,10
	int	29h
	mov	al,' '
	int	29h
	int	29h
@@12:	int	29h
@@15:	loop	@@10
@@99:	pop	ax
	pop	bx
	ret
margin	dw	63
w_wrap	ENDP

string	db	'\Входящие в биогеоценоз живые существа со временем меняются, эволюционируют. Значит ли это, что биогеоценозы со временем выходят из устойчивого равновесия?',13
s_len	equ	$-offset string
	END	start