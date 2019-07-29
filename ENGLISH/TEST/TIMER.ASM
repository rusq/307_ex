	.model tiny
	locals @@
	.code
	org	100h
start:
	xor	ah,ah
	int	1ah
	mov	word ptr [ticks_start],dx
	mov	word ptr [ticks_start+2],cx
	xor	ax,ax
	int	16h
	xor	ah,ah
	int	1ah
	mov	word ptr [ticks_end],dx
	mov	word ptr [ticks_end+2],cx

	mov	ax,word ptr [ticks_end]
	sub	ax,word ptr [ticks_start]
	mov	word ptr [waited],ax

	mov	ax,word ptr [ticks_end+2]
	sbb	ax,word ptr [ticks_start+2]

	mov	word ptr [waited+2],ax

	mov	si,offset waited
	mov	di,offset secs_tot
	mov	bx,18
	call	div32
	call	divtime

	ret

;SI - divident, DI - result, BX - divisor
div32	proc	near
	mov	ax,word ptr [si+2]
	xor	dx,dx
	div	bx
	mov	word ptr [di+2],ax
	mov	ax,word ptr [si]
	div	bx
	mov	word ptr [di],ax
	ret
div32	endp

divtime	proc	near
	mov	bx,3600
	mov	ax,word ptr [secs_tot+2]
	xor	dx,dx
	div	bx
	mov	ax,word ptr [secs_tot]
	div	bx
	mov	byte ptr [test_time],al

	mov	ax,dx
	xor	dx,dx
	mov	bx,60
	div	bx
	mov	byte ptr [test_time+1],al
	mov	byte ptr [test_time+2],dl
	ret
divtime	endp

ticks_start	dw	2 dup (?)
ticks_end	dw	2 dup (?)
waited		dw	2 dup (?)
secs_tot	dw	2 dup (?)
test_time	db	3 dup (?)
	end	start