; In: DX - @ file name
; Out: if AX = FF - error
;         AX = BE - OK
pcxshow	proc	near	; Shows PCX file on the screen
	push	bx cx dx es si di
	jmp	short @@open

@@outexit:
	pop	di si es dx cx bx
	mov	ax,0FFh
	ret

@@open:	mov	ax,3D00h		;Open file
	int	21h
	jnc	@@read
	jmp	short @@outexit

@@read:
	mov	word ptr @@fhandle,ax		;Saving filehandle for future reference
	mov	cx,80h
	call	@@readbuf
	cmp	byte ptr [@@buff],0Ah		;Checking whether it's PCX or not
	je	@@read_else
	call	@@close				;A fint :)
	jmp	short @@outexit	

@@read_else:
	mov	cx,64000
	call	@@readbuf
	mov	si,dx
	xor	di,di
	mov	ax,0A000h			;Vidmem A000 in ES
	mov	es,ax				;for LODSB
	xor	cx,cx
	mov	ax,0013h			;320x200x256c
	int	10h

@@pcx_parse:
	lodsb
	mov	cl,al
	and	al,0C0h
	cmp	al,0C0h			;if equal - AND and
	jne	@@10			;
	and	cl,3Fh			;repeat CL times
	lodsb
@@05:	rep	stosb
	jmp	short @@20
@@10:	xchg	cl,al
	stosb
@@20:	cmp	di,64000
	jbe	@@pcx_parse

@@load_pal:				;Loading palette
	mov	dx,di
	mov	cx,768
@@30:
	lodsb
	shr	al,2
	stosb
	loop	@@30
	mov	ax,1012h
	xor	bx,bx
	mov	cx,255
	int	10h

	xor	ax,ax
	int	16h
	mov	ax,0003h
	int	10h
@@close:
	mov	ah,3Eh			;Close file
	mov	bx,@@fhandle
	int	21h

@@exit:	
	pop	di si es dx cx bx
	mov	ax,0BEh
	ret

@@readbuf:
	mov	ah,3Fh
	mov	bx,@@fhandle
	mov	dx,offset @@buff
	int	21h
	ret

@@fhandle	dw	?

@@buff:
pcxshow	endp	
