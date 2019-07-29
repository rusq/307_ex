	.model tiny
	.code
	org	100h
start:
	mov	si,offset string
	mov	bl,1fh
	call	w_wrap
	ret

;Перенос слов, которые не влезают в 80 символов
;На входе: SI - адрес строки. 
;	   BL - цвет символов
;Строка должна кончаться символом 0d (идеально для текстовых файлов)
;Используются средства BIOS.
w_wrap	PROC	NEAR		
	push	cx
	push	bp
	push	ax
	mov	word ptr [margin],63
	mov	cx,0FFFFh
	xor	bp,bp
	xor	dl,dl
@@10:	lodsb
	cmp	al,0Dh
	je	@@99
	cmp	al,'@'			;Символ начала правильного ответа
	jne	@@11
	inc	dl
	jmp	short @@15
	je	@@15
@@11:	cmp	al,'\'			;Символ начала вопроса
	je	@@15
	inc	bp
	cmp	bp,word ptr margin
	jb	@@12
	cmp	al,' '		; Это пробел?
	jne	@@12
	add	word ptr margin,80
	mov	al,13
	int	29h
	mov	al,10
	int	29h
	mov	al,' '
	call	@@putch
	call	@@putch
@@12:	call	@@putch
@@15:	loop	@@10
@@99:	int	29h
	mov	al,10
	int	29h
	pop	ax
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
margin	dw	63

w_wrap	ENDP

string	db	'\Входящие в биогеоценоз живые существа со временем меняются, эволюционируют. Значит ли это, что биогеоценозы со временем выходят из устойчивого равновесия?',13
s_len	equ	$-offset string
	END	start