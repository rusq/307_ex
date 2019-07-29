;MSAVT.ASM: Резидентный (де)шифратор с переносом кода в PSP
;резидент: 288 байт (MSDOS 7.1), 272 байта (TOSHIBA DOS 5.0)
;без переноса занимал 416 :)

;Вешается на прерывание 21h
;AX=0DEAFh - декодировать
;AX=0BEEFh - кодировать
;AX=0FACEh - Проверка на установку. Возвращает 2002, если установлен
;Используется доработанный алгоритм шифрования Льюиса Кэролла, после этого
;считается контрольная сумма и результат XORится контрольной суммой.
;(Де)кодирует блоками по CX байт.

	.model tiny
	.code
	org	2ch
envseg	dw	?
	org	100h
start:
	jmp	init

new_int21h	proc	far
;ax=0DEAFh - decode
;ax=0BEEFh - encode
;si - @buffer
;dx - @keyword
;di-@2nd buffer;
;bx-length_of_keyword
	pushf
	cmp	ax,0DEAFh
	je	@@decode
	cmp	ax,0BEEFh
	je	@@encode
	cmp	ax,0FACEh
	je	@@ident
	jmp	short @@99

@@decode:
	push	cx
	push	bp
	dec	bx
	push	bx
	mov	bp,sp

	xor	ax,ax
	mov	cx,4

@@d05:	mov	bx,cx
	dec	bx
	add	bx,dx
	add	al,byte ptr [bx]
	loop	@@d05
	push	ax

	xor	bx,bx
	mov	cx,[bp+4]
@@d10:	lodsb
	xor	al,byte ptr [bp-2]
	push	bx
	add	bx,dx
	mov	ah,byte ptr [bx]
	sub	al,ah
	inc	ax
	stosb
	pop	bx
	inc	bx			;<<<
	cmp	bx,word ptr [bp]
	jbe	@@d15
	xor	bx,bx
@@d15:	loop	@@d10

	jmp	short @@98

@@encode:
	push	cx
	push	bp
	dec	bx
	push	bx
	mov	bp,sp

	xor	ax,ax
	mov	cx,4
@@05:	mov	bx,cx
	dec	bx
	add	bx,dx
	add	al,byte ptr [bx]
	loop	@@05
	push	ax

	xor	bx,bx
	mov	cx,[bp+4]
@@10:	lodsb
	push	bx
	add	bx,dx
	mov	ah,byte ptr [bx]
	add	al,ah
	dec	al
	xor	al,byte ptr [bp-2]
	stosb
	pop	bx
	inc	bx			;<<<
	cmp	bx,word ptr [bp]
	jbe	@@15
	xor	bx,bx
@@15:	loop	@@10

@@98:	pop	ax
	pop	bx
	pop	bp
	pop	cx
@@ident:
	popf
	mov	ax,2002h
	iret

@@99:	popf
		db	0EAh	; JMP FAR (начало кода команды дальнего перехода
old_int21h	dd	0	; сюда процедура инициализации запишет адрес
				; предыдущего обработчика INT 21h
new_int21h	endp
;-----------------------------------------------
t_length	=	$-new_int21h
init:
	mov	ax,0FACEh
	int	21h
	cmp	ax,2002h
	je	not_install
	push	es
	mov	ax,3521h
	int	21h
	mov	word ptr old_int21h,bx
	mov	word ptr old_int21h+2,es
	pop	es
	
	cld
	mov	si,offset new_int21h
	mov	di,80h
	mov	cx,t_length
	rep movsb
	
	mov	ax,2521h
	mov	dx,80h
	int	21h

	mov	ah,49h
	mov	es,word ptr envseg
	int	21h

	mov	dx,80h+t_length	; Первый байт после конца резидента
	int	27h

not_install:
	ret
	db	256 dup ('MSAV')
	end	start