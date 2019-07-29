	.model tiny
	locals
	.code
	org	100h


start:	mov	ax,offset realstart
	push	ax
	ret
;keyword:
;	mov	ah,3ch
;	mov	dx,offset start-4
;	int	21h
;	ret
keyword		db	'scum'
keywlen		equ	$-keyword
file		db	'test.dat',0
file1		db	'c.asm',0
fhandle1	dw	0
fhandle2	dw	0
realstart:
	mov	ax,3d00h
	mov	dx,offset file
	mov	cx,20h
	int	21h
	mov	word ptr [fhandle1],ax

	mov	ah,3ch
	mov	cx,20h
	mov	dx,offset file1
	int	21h

	mov	word ptr [fhandle2],ax

	mov	ah,3fh
	mov	bx,word ptr [fhandle1]
	mov	cx,512
	mov	dx,offset buffer1
	int	21h

	mov	si,dx
	mov	dx,offset keyword
	mov	di,offset buffer2
	mov	bx,keywlen
	call	crypt

	mov	ah,40h
	mov	bx,fhandle2
	mov	cx,512
	mov	dx,offset buffer2
	int	21h

	mov	ah,3eh
	mov	bx,fhandle1
	int	21h
	mov	bx,fhandle2
	int	21h
	ret

crypt	proc	near;si - @buffer, dx - @keyword,di-@2nd buffer,bx-length_of_keyword
	push	ax
	push	cx
	push	bp
	dec	bx
	push	bx
	mov	bp,sp
	and	byte ptr cs:inc_bx,0EFh

	xor	ax,ax
	mov	cx,4
@@05:	mov	bx,cx
	dec	bx
	add	bx,dx
	add	al,byte ptr [bx]
	loop	@@05
	push	ax

	xor	bx,bx
	mov	cx,512
@@10:	lodsb
	xor	al,byte ptr [bp-2]
	push	bx
	add	bx,dx
	mov	ah,byte ptr [bx]
	sub	al,ah
	inc	al
	stosb
	pop	bx
inc_bx:	push	bx			;<<<
	cmp	bx,word ptr [bp]
	jbe	@@15
	xor	bx,bx
@@15:	loop	@@10

	pop	ax
	pop	bx
	pop	bp
	pop	cx
	pop	ax

	pop	bx
	jmp	bx
crypt	endp
buffer1	db	512 dup (?)
buffer2	db	512 dup (?)
	end	start