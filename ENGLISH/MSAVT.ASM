;MSAVT.ASM: ��������� (��)����� � ��७�ᮬ ���� � PSP
;१�����: 288 ���� (MSDOS 7.1), 272 ���� (TOSHIBA DOS 5.0)
;��� ��७�� ������� 416 :)

;��蠥��� �� ���뢠��� 21h
;AX=0DEAFh - ������஢���
;AX=0BEEFh - ����஢���
;AX=0FACEh - �஢�ઠ �� ��⠭����. �����頥� 2002, �᫨ ��⠭�����
;�ᯮ������ ��ࠡ�⠭�� ������ ��஢���� ���� ��஫��, ��᫥ �⮣�
;��⠥��� ����஫쭠� �㬬� � १���� XOR���� ����஫쭮� �㬬��.
;(��)������� ������� �� CX ����.

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
		db	0EAh	; JMP FAR (��砫� ���� ������� ���쭥�� ���室�
old_int21h	dd	0	; � ��楤�� ���樠����樨 ������ ����
				; �।��饣� ��ࠡ��稪� INT 21h
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

	mov	dx,80h+t_length	; ���� ���� ��᫥ ���� १�����
	int	27h

not_install:
	ret
	db	256 dup ('MSAV')
	end	start