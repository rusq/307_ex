	.model tiny
	.code
	org	100h
start:
	mov	si,offset string
	mov	bl,1fh
	mov	dh,24
	call	w_wrap
	ret

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


string	db	'4. Неизвестно. Свидетельствами, подтверждающими справедливость теории естественного отбора, современная наука не располагает, но на её справедливость косвенно указывают многочисленные успехи искуственного отбора, проводимого человеком на практике.',13
s_len	equ	$-offset string
	END	start