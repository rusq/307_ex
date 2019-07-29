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

	mov	ax,0DEAFh
	mov	si,dx
	mov	dx,offset keyword
	mov	di,offset buffer2
	mov	cx,100h
	mov	bx,keywlen
	int	21h

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

buffer1	db	512 dup (0)
buffer2	db	512 dup (0)
	end	start