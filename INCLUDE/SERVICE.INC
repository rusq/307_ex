;INCLUDE FILE FOR SERVICE.ASM
;Изменяет настройки программы (сколько вопросов задавать, сколько надо для успеха)
set_quest	proc	near

offs	equ	1A98h

	mov	bl,7
	call	fclsa

	mov	ax,3d02h
	mov	dx,offset passf
	int	21h
	jnc	@@lseek
	call	_fatal				;Оповещаем об ошибке открытия

@@lseek:
	mov	word ptr [@@fhandle],ax		;Сохраняем файловую рукоятку
	mov	bx,ax

	mov	ax,4200h
	xor	cx,cx
	mov	dx,offs
	int	21h
	jnc	@@fread

@@fread:
	mov	ah,3fh
	mov	cx,2
	mov	dx,offset @@buffer
	int	21h

	mov	ax,word ptr cs:[@@buffer]
	or	ax,3030h
	mov	byte ptr [msg_q_tot], al
	mov	byte ptr [msg_q_togo], ah

	mov	dx,offset @@msg
	mov	ah,9
	int	21h

@@ask:	xor	ax,ax
	int	16h

	cmp	ah,15h
	jne	@@aus

@@change:
	mov	ah,9
	mov	dx,offset @@chg_q_tot
	int	21h

	mov	di,offset @@q_total
	mov	cx,1
	call	num_field

	cmp	byte ptr [@@q_total],'0'
	je	@@change


@@reask:
	mov	ah,9
	mov	dx,offset @@chg_q_togo
	int	21h

	mov	di,offset @@q_togo
	mov	cx,1
	call	num_field

	mov	al,byte ptr [@@q_togo]
	cmp	al,'0'
	je	@@reask
	cmp	al,byte ptr [@@q_total]
	ja	@@reask

	mov	ax,word ptr [@@buffer]
	and	ax,0F0Fh
	mov	word ptr [@@buffer],ax

	mov	ax,4200h
	mov	bx,word ptr [@@fhandle]
	xor	cx,cx
	mov	dx,offs
	int	21h

	mov	ah,40h
	mov	cx,2
	mov	dx,offset @@buffer
	int	21h

	mov	word ptr [out_message],offset changed
	mov	byte ptr [errorlevel],0

@@aus:	mov	ah,3eh
	mov	bx,[@@fhandle]
	int	21h

	ret
@@fhandle	dw	?
@@buffer:
@@q_total	db	?
@@q_togo	db	?
@@msg		db	'Настройки программы:',13,10
		db	'Задаётся вопросов            : '
msg_q_tot	db	'0',13,10
		db	'Правильных ответов для успеха: '
msg_q_togo	db	'0',13,10,10
		db	'Нажмите клавишу [Y] для изменения, или любую другую для отмены$'


@@chg_q_tot	db	13,10,'Задаётся вопросов            : $'
@@chg_q_togo	db	13,10,'Правильных ответов для успеха: $'

set_quest	endp

;--------------------------------------------------
; FIELD: gets number and stores it in ax
;   In:
;     di : address of buffer
;     cx : number of digits to read
;   Out:
;     String in buffer, or, if Enter or Esc was pressed returns scancodes of them
;--------------------------------------------------
num_field	proc	near
		jcxz	@@00
		push	dx
		push	di

		mov	dx,cx
		xor	cx,cx
		xor	bx,bx
@@10:		xor	ax,ax
		int	16h

		cmp	ah,1Ch
		je	@@99

@@20:		mov	ah,0Eh
		cmp	al,8
		jne	@@30
		cmp	cx,0
		je	@@10
		dec	cx
		dec	di
		
		int	10h
		mov	al,' '
		int	10h
		mov	al,8
		int	10h

@@30:		cmp	al,30h
		jb	@@10
		cmp	al,39h
		ja	@@10
		xor	bx,bx

		cmp	cx,dx
		je	@@10
		int	10h
		inc	cx
		stosb
		jmp	short @@10

@@99:		or	cx,cx
		jz	@@10
		pop	di
		pop	dx
@@00:		ret
num_field	endp

decrypt	proc	near
	mov	bl,7
	call	fclsa

	mov	ah,9
	mov	dx,offset getpass
	int	21h

	mov	cx,16
	mov	di,offset pass1
	mov	bx,20FFh
	call	field

	cmp	cx,8
	je	@@10
	mov	word ptr [out_message],offset endpass
	call	exit

	mov	ax,4c04h
	int	21h

@@10:	call	genpass
	ret
decrypt	endp

dat_2_txt	proc	near
	mov	ax,3D00h
	mov	dx,offset file_dat
	int	21h
	jnc	@@10
	call	_fatal

@@10:	mov	[fhandle],ax
	mov	ah,3ch
	mov	cx,20h
	mov	dx,offset file_txt
	int	21h
	jnc	@@20
	call	@@99
	call	_fatal

@@20:	mov	[fhandle_txt],ax
	
@@30:	mov	ah,3Fh
	mov	bx,[fhandle]
	mov	cx,512
	mov	dx,offset buffer1
	int	21h
	or	ax,ax
	jz	@@99

	mov	word ptr [bread],ax

	mov	cx,ax
	mov	ax,0DEAFh
	mov	bx,16
	mov	si,offset buffer1
	mov	di,offset buffer2
	mov	dx,offset passw
	int	21h

	mov	ah,40h
	mov	bx,[fhandle_txt]
	mov	cx,[bread]
	mov	dx,offset buffer2
	int	21h
	jnc	@@35
	call	@@99
	call	_fatal
@@35:	jmp	short @@30

@@99:	mov	ah,3eh
	mov	bx,[fhandle_txt]
	int	21h
	mov	bx,[fhandle]
	int	21h
	ret
dat_2_txt	endp

txt_2_dat	proc	near
	mov	ax,3D00h
	mov	dx,offset file_txt
	int	21h
	jnc	@@10
	call	_fatal

@@10:	mov	[fhandle_txt],ax
	mov	ah,3ch
	mov	cx,20h
	mov	dx,offset file_dat
	int	21h
	jnc	@@20
	call	@@99
	call	_fatal

@@20:	mov	[fhandle],ax
	
@@30:	mov	ah,3Fh
	mov	bx,[fhandle_txt]
	mov	cx,512
	mov	dx,offset buffer1
	int	21h
	or	ax,ax
	jz	@@99

	mov	word ptr [bread],ax

	mov	cx,ax
	mov	ax,0BEEFh
	mov	bx,16
	mov	si,offset buffer1
	mov	di,offset buffer2
	mov	dx,offset passw
	int	21h

	mov	ah,40h
	mov	bx,[fhandle]
	mov	cx,[bread]
	mov	dx,offset buffer2
	int	21h
	jnc	@@35
	call	@@99
	call	_fatal
@@35:	jmp	short @@30

@@99:	mov	ah,3eh
	mov	bx,[fhandle_txt]
	int	21h
	mov	bx,[fhandle]
	int	21h
	ret
txt_2_dat	endp

_fatal	proc	near
	call	emptypass
	mov	dx,offset error3
	mov	ah,9
	int	21h
	mov	ax,4c03h
	int	21h
_fatal	endp

;Процедура сохранения зашифрованного пароля в файл
savepass	proc	near
	push	ax bx cx dx
	mov	ax,3D02h
	mov	dx,offset passf
	int	21h
	jnc	@@10

@@10:
	mov	fhandle,ax
	mov	bx,ax
	mov	ax,4200h
	xor	cx,cx
	mov	dx,3
	int	21h

	mov	ah,40h
	mov	bx,word ptr [fhandle]
	mov	cx,32
	mov	dx,offset passe
	int	21h
	jnc	@@20
	call	_fatal

@@20:	mov	ah,3Eh
	mov	bx,word ptr [fhandle]
	int	21h

	pop	dx cx bx ax
	ret
savepass	endp

emptypass	proc	near
	push	di cx ax
	mov	di,offset pass1
	mov	cx,68
	xor	ax,ax
	rep	movsb
	pop	ax cx di
	ret
emptypass	endp

;Процедура запроса пароля
crypt	proc	near
	mov	bl,7
	call	fclsa
@@10:	mov	cx,16			;Cleaning password buffer
	mov	di,offset pass1		;from last attempts
	xor	ax,ax
	rep	stosb

	mov	dx,offset newpass
	mov	ah,9
	int	21h
	mov	di,offset pass1
	mov	cx,8
	mov	bx,20FFh
	call	field
	cmp	cx,8
	je	@@15

	mov	dx,offset error2
	mov	ah,9
	int	21h
	jmp	short @@10

@@15:	mov	[passchars],cl

	mov	dx,offset confirm
	mov	ah,9
	int	21h
	mov	di,offset pass2
	mov	cx,8
	mov	bx,20FFh
	call	field

	mov	si,offset pass1			;comparing pass1 and pass2
	mov	di,offset pass2
	mov	cl,9
	repe	cmpsb

	jcxz	@@20

	mov	ah,9
	mov	dx,offset error1
	int	21h
	jmp	short @@10
@@20:	call	genpass
@@99:	ret
crypt	endp

;Процедура генерирования дополнительного кода и шифрования пароля
genpass	proc	near
	push	cx
	push	si
	push	di
	xor	cx,cx
	mov	cl,4
	mov	dx,5723h		;_SEED!!!
	mov	si,offset pass1
@@05:	lodsw
	xor	dx,ax
	sub	dx,ax
	loop	@@05

	mov	__seed,dx
	
	mov	di,offset passw
	mov	cl,16

@@10:	call	rand8
	stosb
	loop	@@10

	mov	cx,16
	mov	si,offset passw
	mov	di,offset passe
;--- Encoding in_buff ---
@@20:	
	lodsb
	mov	ah,al
	and	ah,0Fh
	shr	al,4
	add	ax,4141h
	xchg	ah,al
	xor	ax,06A61h
	stosw
	loop	@@20

	pop	di
	pop	si
	pop	cx
	ret
genpass	endp

;--------------------------------------------------
; FIELD: gets number and stores it in ax
;   In:
;     di : address of buffer
;     cx : number of digits to read
;     bh : lo char (i.e. 'A')
;     bl : hi char (i.e. 'Z')
;   Out:
;     String in buffer, or, if Enter or Esc was pressed returns scancodes of them
;--------------------------------------------------
field		proc	near
		jcxz	@@00
		push	dx
		push	di
		push	bp
		push	bx
		mov	bp,sp

		mov	dx,cx
		xor	cx,cx
		xor	bx,bx
@@10:		xor	ax,ax
		int	16h

		cmp	ah,1Ch
		je	@@99

		cmp	ah,01h
		je	@@99
		
@@20:		mov	ah,0Eh
		cmp	al,8
		jne	@@30
		or	cx,cx
		jz	@@10
		dec	cx
		dec	di
		
		int	10h
		mov	al,' '
		int	10h
		mov	al,8
		int	10h

@@30:		mov	bx,word ptr [bp]
		cmp	al,bh
		jb	@@10
		cmp	al,bl
		ja	@@10
		xor	bx,bx

		cmp	cx,dx
		je	@@10
		push	ax
		mov	al,0FCh
		int	10h
		pop	ax
		inc	cx
		stosb
		jmp	short @@10

@@99:		pop	bx
		pop	bp
		pop	di
		pop	dx
@@00:		ret
field		endp
;--------------------------------
; MAKEMENU: Creates menu on the screen
; Parameters
;    AX = POSITION AH=X AL=Y
;    BH = Highlight attributes
;    BL = Normal Attributes
;    ES:SI = ADDRESS OF THE MENU
;    CL = COUNT OF ITEMS
; RETURN:
;    DX = Pointer to ASCIZ String of current item
;    BL = number of item selected (first is 0)
;    BH = key pressed:
;        1Ch = ENTER
;        01h = ESC
;--------------------------------
makemenu        proc    near

;Stack Variables
;  POSITION   = [BP]
;  NUM_ITEMS  = [BP+2]
;  ATTRIBUTES = [BP+4]
;  ITEMS      = [BP-(X*2)], where X - number of item

	pushf				;We're using flags :)
	push	si bp di dx bx cx ax	;Saving registers
	mov     bp,sp			;Storing BASE

	cld
	xor	ax,ax			;Hiding cursor
	call	fcursor

	jcxz	@@99			;If NUM_ITEMS is not specified
	mov	dx,0001h		;Current menuitem pointer


;----------------------
_do:
	push    si			;We'll have in stack pointers to every
					;menu_item
@@10:   lodsb
	or      al,al			;if we found 00h, then it's the end of
	jz      _while			;the menu_item
	jmp     short @@10		;not? then current menu_item continues
	
_while: loop    _do
;---------------------- 
@@15:	mov	ax,[bp]			;Restoring POSITION

	mov	cx,[bp+2]		;Restoring NUM_ITEMS
	mov	bx,bp			;For indexing
	add	al,cl			;Position+NUM_ITEMS
	dec	al			; - 1

	push	cx			;Saving CX
	shl	cx,1			;CX *= 2
	sub	bx,cx			;Indexing mode
	pop	cx			;Restoring original CX

@@20:	mov	si,[bx]			;Printing menu from the last item
	push	bx
	mov	bx,[bp+4]		;attributes
	cmp	dx,cx			;if this MENU_ITEM is selected
	je	@@30			;we must invert attributes
	xchg	bh,bl
@@30:	call	print
	pop	bx
	inc	bx			;increasing bx to point to the next item
	inc	bx			;in STACK
	dec	al			;Decreasing line number
	loop	@@20			;Looping CX times

	xor	ax,ax
	int	16h

	cmp	ah,1ch			;Return
	je	key_Out
	cmp	ah,01h			;ESC
	je	key_Out
	or	al,al			;if scancode is not zero then do
	jnz	@@15			;nothing
	cmp	ah,47h			;we need scancodes from Home to Down
	jb	@@15
	cmp	ah,50h
	ja	@@15
	sub	ah,47h			;converting to match our table
	mov	bl,ah
	xor	bh,bh
	shl	bx,1
	jmp	word ptr cs:jump_table[bx]

key_Home:				;47h
	mov	dx,1
	jmp	short @@15
key_Up:					;48h
	dec	dx
	cmp	dx,1
	jb	key_End
	jmp	short @@15
key_End:
	mov	dx,[bp+2]		;4Fh
	jmp	short @@15
key_Down:				;50h
	inc	dx
	cmp	dx,[bp+2]
	ja	key_Home
	jmp	short @@15
key_Out:
	mov	dh,ah


;------ Restoring used registers -----
@@99:	mov	al,dl
	xor	ah,ah
	shl	ax,1
	mov	bx,bp
	sub	bx,ax
	mov	ax,[bx]
	mov	word ptr [bp+6],ax
	dec	dx
	mov	[bp+4],dx

	mov     sp,bp			;restoring BASE

	mov	ah,1			;show cursor
	call	fcursor

	pop	ax cx bx dx di bp si	;restoring registers
	popf				;restoring FLAGS
	ret
jump_table:
	dw	key_Home	;47h
	dw	key_Up		;48h
	dw	@@15		;49h
	dw	@@15		;4Ah
	dw	key_Up		;4Bh (Left)
	dw	@@15		;4Ch
	dw	key_Down	;4Dh (Right)
	dw	@@15		;4Eh
	dw	key_End		;4Fh
	dw	key_Down	;50h
makemenu        endp
passf		db	'30 _Ey Г  ',0
;-------------------------------------------------------------------------------
; PRINT : Fast screen output w/o attributes (overlays on current attr)
;   AX    : Position.AL=Y, AH=X 0000h is top left
;   BH    : Attributes
;   DS:SI : offset of ASCIIZ string in memory
;   Structure of this string: "Message", 0
;
;   Example: "I'm an arsehole",0
;-------------------------------------------------------------------------------

print	proc	near

	pushf
	push    es ax di cx si

	push	bx

	cld
	push	ax
	mov     ax,0b800h
	mov     es,ax		;Vidmem segment
	pop	ax

	push	ax
	xor     ah,ah
	mov     bx,ax                   ;Multiply AX by 10
	shl     ax,1
	shl     ax,1
	add     ax,bx
	mov	cx,4
	shl     ax,cl			;Multiply AX by 8
					;Total ax=ax*10*8=ax*80

	pop	bx
	xor	bl,bl
	xchg	bl,bh
	add     ax,bx           ;ax=ax+bx (ax = X + ax)
	shl     ax,1            ;ax = ax * 2
	mov     di,ax           ;we'll put offset in di (for stosb)
	pop	bx
	mov	ah,bh
@@10:   
	lodsb                   ;ds:[si] -> al
	or     al,al            ;If 0 then end of string
	jz      @@20
	stosw			;writing with attributes
	jmp     short @@10
@@20:
	pop     si cx di ax es
	popf
	ret

print	endp
	
;-------------------------------------------------------------------------------
; FCURSOR : Turn Cursor off/on
;   In:
;      AL : Cursor status
;          AL = 0 - cursor turns off
;          AL != 0 - cursor turns on
;-------------------------------------------------------------------------------
fcursor	proc	near
	pushf
	push	bx cx dx
	push	ax
	mov	ah,03h
	xor	bh,bh
	int	10h
	pop	ax

	or	ax,ax
	jnz	@@10

	or	ch,00100000b
	jmp	short @@20

@@10:	and	ch,11011111b

@@20:	mov	ah,01h
	int	10h
	pop	dx cx bx
	popf

	ret
fcursor endp

;---------------------------
;MAKEFRAME: creates frame with given attributes
;  IN:
;      AH = RIGHT COORDINATE
;      AL = TOP COORDINATE
;      BH = LEFT COORDINATE
;      BL = BOTTOM COORDINATE
;      CH = ATTRIBUTE TO USE
;      CL = CHARSET TO USE (0 - 3)
;-----------------------------
makeframe	proc	near
;INTERNAL VARIABLES
;[BP]   - frametype and colour
;[BP+2] - lower right corner
;[BP+4] - upper left corner
;[BP-2] - start position
;[BP-4] - end position
	pushf
	push	es di bp si ax bx cx
	mov	bp,sp

	mov	bl,cl
	xor	bh,bh
	shl	bl,1
	mov	si,cs:set_X[bx]
	
	mov	bx,0B800h
	mov	es,bx

	call	mul80			;converting start position
	push	ax

	mov	ax,[bp+2]		;converting end position
	call	mul80
	push	ax

	mov     di,[bp-2]		;we'll put offset in di (for stosb)
;- UpLeft char -
	mov	ax,[bp]			;attributes (in AH)
	mov	al,[si+2]	;top left char
	stosw
;- Line -
	mov	cx,[bp+2]		;lower right CH - X
	mov	ax,[bp+4]		;upper left
	sub	ch,ah
	mov	cl,ch
	xor	ch,ch
	dec	cl

	push	cx			;[BP+6] - lines :)

	mov	ax,[bp]
	mov	al,[si+1]
@@10:
	stosw
	loop	@@10

;- UpRight char -
	mov	al,[si+3]
	stosw

	mov	cx,[bp+2]		;Checking if we have more than 
	mov	ax,[bp+4]		;2 lines...
	sub	cl,al
	xor	ch,ch
	cmp	cl,1
	je	@@30
	dec	cl
;--- Next Line ---
@@20:	add	word ptr[bp-2],160
	mov	di,[bp-2]

	mov	ax,[bp]			;vertical line
	mov	al,[si]
	stosw

	push	cx			;spaces
	mov	cx,[bp-6]
	mov	al,20h
@@25:
	stosw
	loop	@@25
	pop	cx
	
	mov	al,[si]
	stosw

	loop	@@20
@@30:	add	word ptr [bp-2],160
	mov	di,[bp-2]
	
	mov	ax,[bp]
	mov	al,[si+4]
	stosw
	mov	cx,[bp-6]
	mov	al,[si+1]

@@35:	stosw
	loop	@@35

	mov	al,[si+5]
	stosw
	
;------------------------------------------
	mov	sp,bp

	pop	cx bx ax si bp di es
	popf

	ret

set_X	dw	set_0,set_1,set_2,set_3
set_0	db	'│─┌┐└┘'
set_1	db	'║═╔╗╚╝'
set_2	db	'│═╒╕╘╛'
set_3	db	'║─╓╖╙╜'
makeframe endp

;MUL80: AX = AL*80+AH

mul80	proc	near

	push	bx cx

	push	ax

	xor	ah,ah
	mov     bx,ax                   ;Multiply AX by 10
	shl     ax,1
	shl     ax,1
	add     ax,bx
	mov	cx,4
	shl     ax,cl			;Multiply AX by 8
					;Total ax=ax*10*8=ax*80

	pop	bx
	xor	bl,bl
	xchg	bl,bh
	add     ax,bx           ;ax=ax+bx (ax = X + ax)

	shl     ax,1            ;ax = ax * 2

	pop	cx bx
	ret
mul80	endp

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

__seed	dw	?
