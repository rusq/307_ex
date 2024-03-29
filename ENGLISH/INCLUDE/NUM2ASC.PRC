;---------------------------------------------------
; NumToASCII �८�ࠧ�� ����������� ����筮� ���祭�� � ASCII
;-------------------------------
; �室: ax = 16-��⮢�� �८�ࠧ㥬�� ���祭��
;       bx = �᭮����� १���� (2-BIN,10-DEC,16-HEX)
;	cx = ��������. ���-�� �뢮����� ���
;	di = ���� ��ப� � १���⮬
; ����砭��: �. � �����
; ��室: ���������
; ��������: ax,cx
;------------------------------------------------------
NumToASCII	proc	near
	push	dx
	push	di
	push	si

	xor	si,si
	jcxz	@@20
@@10:
	xor	dx,dx
	div	bx
	call	HexDigit
	push	dx
	inc	si
	loop	@@10
@@20:
	inc	cx
	or	ax,ax
	jnz	@@10
	mov	cx,si
	jcxz	@@40
	cld
@@30:
	pop	ax
	stosb
	loop	@@30
@@40:
	mov	byte ptr di,0
	pop	si
	pop	di
	pop	dx

	ret
NumToASCII	endp
;------------------------------------------------------
; HexDigit �८�ࠧ�� 4-��⮢�� ���祭�� � ASCII ����
;------------------------------------------------------
; �室: dl = ���祭�� � ��������� 0..15
; ��室: dl = ��⭠������ ���������� ASCII ����
; ��������: dl
;------------------------------------------------------
HexDigit proc
	cmp	dl,10
	jb	@@10
	add	dl,'A'-10
	ret
@@10:
	or	dl,'0'
	ret
HexDigit endp
