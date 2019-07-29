gen_num	proc	near				;�����஢���� ����� �����
        push	bx
@@10:	call	rand16
	cmp	ax,word ptr [q_num]
	ja	@@10
	dec	ax
	mov	bx,ax
	cmp	byte ptr [t_asked+bx],1
	je	@@10
	mov	byte ptr [t_asked+bx],1
	pop	bx
	ret
gen_num	endp

;-------------------------------------------------------------------------------
; FCLSA : clears the screen with colour you specified
;   In:
;     BL : color (See TABLE 1)
;-------------------------------------------------------------------------------
fclsa	proc	near

	pushf
	push	ax bx cx di es

	cld
	push	bx
	mov	ah,02h
	xor	bx,bx
	mov	dx,bx
	int	10h
	pop	bx
        mov ax,0b800h
        mov es,ax
        xor di,di
        mov cx,4000h
	xchg ah,bl
        mov al,20h
        rep stosw

	pop	es di cx bx ax
	popf

	ret

fclsa	endp
;-------------------------------------------------------------------------------
; FALINE : Fills a line with spaces and given attributes
;   In :
;     BH = Y (row to fill 0 - 24)
;     BL = ATTRIBUTE (See TABLE#1)
;-------------------------------------------------------------------------------
faline	proc	near
	pushf
	push	ax bx cx es di
	mov	cx,0B800h
	mov	es,cx
	mov	al,bh
	
	push	bx
	xor	ah,ah
	mov	bx,ax			;Multiply AX by 10
	shl	ax,2			;  by 4
	add	ax,bx			;  ax=ax+bx
	shl	ax,1			;  by 2
	shl	ax,3			;Multiply AX by 8
					;Total ax=ax*10*8=ax*80

	shl	ax,1		;ax = ax * 2
	mov	di,ax           ;we'll put offset in di (for movsb)
	pop	bx
	mov	cx,80
	mov	al,20h
	mov	ah,bl
	rep	stosw

	pop	di es cx bx ax
	popf
	ret
faline	endp
;-------------------------------------------------------------------------------
; FWRITEA : Fast screen output with attributes
;   DS:SI : offset of ASCIIZ string in memory
;   Structure of this string: Color,Y,X,"Message", 0
;
;   Example: 15,5,15,"I'm an arsehole",0
;
;Bitfields for character's display attribute:
;Bit(s)  Description (TABLE 1)
; 7      foreground blink or (alternate) background bright (see also AX=1003h)
; 6-4    background color
; 3      foreground bright or (alternate) alternate character set (see AX=1103h)
; 2-0    foreground color (see #0014)
;-------------------------------------------------------------------------------
fwritea	proc	near
	
	pushf
	push	es ax bx cx di
	cld
	mov	ax,0b800h
	mov	es,ax			;Vidmem segment
	mov	cl,byte ptr [si]	;Color
	mov	al,byte ptr [si+1]	;Y
	mov	bl,byte ptr [si+2]	;X
	xor	bh,bh
	mov	ah,bh
	add	si,3

	push	bx
	xor	ah,ah
	mov	bx,ax			;Multiply AX by 10
	shl	ax,1
	shl	ax,1
	add	ax,bx
	shl	ax,1
	shl	ax,3			;Multiply AX by 8
					;Total ax=ax*10*8=ax*80
	pop	bx

	add	ax,bx		;ax=ax+bx (ax = X + ax)
	shl	ax,1		;ax = ax * 2
	mov	di,ax           ;we'll put offset in di (for stosb)
@@10:	
	lodsb			;ds:[si] -> al
	cmp	al,0		;If 0 then end of string
	je	@@20
	stosb			;al -> es:[di]
	mov	al,cl
	stosb
	jmp	short @@10
@@20:
	pop	di cx bx ax es
	popf
	ret
fwritea	endp


fill_tbl	PROC	NEAR		;��楤�� ���������� ⠡���
	push	si
	push	di
	push	cx
	push	ax
	push	bx

	mov	si,offset buffer
	mov	cx,word ptr [fsize]	;������ 䠩��
@@lp:	lodsb				;���� ����ᮢ
	cmp	al,'\'			;��ࢠ���� �� ��砫� �����?
	jne	@@10			;��� - �த������
	inc	word ptr [q_num]	;�������� ����稪 ����ᮢ
@@10:	loop	@@lp

	mov	si,offset buffer
	mov	bx,offset t_rows
	mov	cx,word ptr [fsize]
	mov	word ptr [bx],si	;���࠭塞 ���� ��ࢮ�� �����

@@tf:	lodsb				;������ ᬥ饭�� ��ப
	cmp	al,0Dh			;��諨 ����砭�� ��ப�?
	jne	@@nxt			;��� >> ᫥���騩 ᨬ���
	lodsb				;��⠥� ᨬ��� ������ ���⪨
	inc	l_count			;������⢮ ��ப
	add	bx,2			;��襬 ᫮��
	mov	word ptr [bx],si	;��࠭�� ������⢮ ��ப � �����
@@nxt:	loop	@@tf

	mov	di,offset t_answ
	mov	bx,offset t_rows
	mov	cx,word ptr q_num		;������⢮ ����ᮢ
	xor	ah,ah
	add	bx,2
@@ta:	mov	bp,word ptr [bx]	;�������� ⠡���� ��� ���-�� �⢥⮢
	mov	al,byte ptr [bp]
	and	al,0Fh			;�८�ࠧ㥬 � ����筮�� ���
	or	al,al			;�� ����?
	jz	@@error			;�� - �訡��
	stosb
	shl	al,1			;�������� �� 2 (��� ����祭�� ���� ��砫� ᫥���饣� �����)
	add	al,4			;�ਡ���塞 4, �⮡ ��३� �� ᫥���騥 ���� ��ப�, ����� ᮤ�ন� ������⢮ ����ᮢ
	add	bx,ax
	loop	@@ta

	mov	di,offset t_asked	;����襬 �㫨 � ⠡���� �������� ����ᮢ
	mov	cx,512
	xor	ax,ax
@@fz:	stosw
	loop	@@fz
	
	
	pop	bx
	pop	ax
	pop	cx
	pop	di
	pop	si
	ret
@@error:
	mov	ah,9
	mov	dx,offset @@errmsg
	int	21h
	mov	ax,4cffh
	int	21h
@@errmsg	db	'FILL_TBL: �訡�� � 䠩�� ������!$'
fill_tbl	ENDP	

close	PROC	NEAR			;��楤�� ������� 䠩�� � ����祭��� ��� ࠧ���
	push	ax bx cx dx
	mov	ax,4202h
	mov	bx,word ptr [fhandle]
	xor	cx,cx
	mov	dx,cx
	int	21h
	mov	word ptr [fsize],ax		;���࠭�� ࠧ��� 䠩��
	
	mov	ah,3eh
	int	21h
	pop	dx cx bx ax
	ret
close	ENDP

w_wrap	PROC	NEAR		;��७�� ᫮�, ����� �� ������� � 80 ᨬ�����
				;�� �室� - SI - ���� ��ப�. ��ப� ������ ������� ᨬ����� 0d (�����쭮 ��� ⥪�⮢�� 䠩���)
	push	cx
	push	bx
	push	ax
	mov	word ptr [margin],63
	mov	cx,0FFFFh
	xor	bx,bx
	xor	dl,dl
@@10:	lodsb
	cmp	al,0Dh
	je	@@99
	cmp	al,'@'			;������ ��砫� �ࠢ��쭮�� �⢥�
	jne	@@11
	inc	dl
	jmp	short @@15
	je	@@15
@@11:	cmp	al,'\'			;������ ��砫� �����
	je	@@15
	inc	bx
	cmp	bx,word ptr margin
	jb	@@12
	cmp	al,' '		; �� �஡��?
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
@@99:	int	29h
	mov	al,10
	int	29h
	pop	ax
	pop	bx
	pop	cx
	ret
margin	dw	63
w_wrap	ENDP

bufferize	proc	near		;����ਧ��� 䠩�� � ����ᠬ�

	mov	di,offset buffer

@@loc:	mov	ah,3fh
	mov	bx,word ptr fhandle
	mov	cx,512
	mov	dx,offset readbuf
	int	21h
	jnc	@@decod
	call	fatal

@@decod:
	or	ax,ax
	jz	@@99
	push	ax
	push	di
	mov	ax,0DEAFh
	mov	si,offset readbuf
	mov	di,offset decodbuf
	mov	dx,offset passwtmp
	mov	bx,16
	int	21h
	pop	di
	pop	ax

@@buff:
	mov	word ptr [bread],ax
	mov	cx,ax
	mov	si,offset decodbuf
	rep	movsb
	jmp	short @@loc

@@99:	ret
bufferize	endp

open	proc	near
	mov	ax,3D00h
	mov	dx,offset dataf
	int	21h
	jnc	@@98
	call	fatal
@@98:
	mov	word ptr [fhandle],ax
	ret
open	endp

fatal	proc	near
	mov	ah,9
	mov	dx,offset fatal1
	int	21h
	mov	ax,4c01h
	int	21h
fatal	endp

;Password decoder proc
passwd	proc	near
	mov	cx,32
	mov	si,offset password
	mov	di,offset passwtmp

@@10:
	lodsw
	xor	ax,06A61h
	xchg	ah,al
	sub	ax,4141h
	shl	al,04
	add	al,ah
	stosb
	loop	@@10
	ret
passwd	endp

rand16	proc	near
	push	bx
	call	rand8
	mov	bx,ax
	call	rand8
	mov	ah,bl
	pop	bx
	ret
rand16	endp


genseed	proc	near		;stores seed in local var. WORD __seed
	push	cx dx
	xor	ah,00
	int	1ah
	mov	ax,dx
	add	ax,cx
	mov	word ptr __seed,ax
	pop	dx cx
	ret
genseed	endp

rand8	proc	near		;Returns random number in WORD __seed
	push	bx cx
	mov	ax,word ptr __seed
	mov	cx,8
newbit:	mov	bx,ax
	and	bx,002Dh
	xor	bh,bl
	clc
	jpe	shift
	stc
shift:	rcr	ax,1
	loop	newbit
	mov	word ptr __seed,ax
	xor	ah,ah
	pop	cx bx
	ret
rand8	endp