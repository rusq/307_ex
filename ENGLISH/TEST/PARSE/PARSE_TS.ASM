	.model tiny
	.code
	org	100h
start:
	call	fill_tbl
	ret

fill_tbl	PROC	NEAR		;��楤�� ���������� ⠡���
	push	si
	push	cx
	push	ax
	mov	si,offset buffer
	mov	cx,word ptr [fsize]
@@lp:	lodsb
	cmp	al,'\'			;��ࢠ���� �� ��砫� �����?
	jne	@@10			;��� - �த������
	inc	byte ptr [q_num]	;�������� ����稪 ����ᮢ
@@10:	loop	@@lp

	mov	si,offset buffer
	mov	cx,word ptr [fsize]
	mov	bx,offset t_rows
	mov	word ptr [bx],si

@@tf:	lodsb
	cmp	al,0Dh			;��諨 ����砭�� ��ப�
	jne	@@nxt
	lodsb
	inc	l_count
	add	bx,2
	mov	word ptr [bx],si
@@nxt:	loop	@@tf

	mov	di,offset t_answ
	mov	bx,offset t_rows
	mov	cl,q_num		;������⢮ ����ᮢ
	xor	ah,ah
	add	bx,2
@@ta:	mov	bp,word ptr [bx]
	mov	al,byte ptr [bp]
	and	al,0Fh			;�८�ࠧ㥬 � ����筮�� ���
	or	al,al			;�� ����?
	jz	@@error			;�� - �訡��
	stosb
	shl	al,1
	add	al,4
	add	bx,ax
	loop	@@ta
	

	pop	ax
	pop	cx
	pop	si
	ret
@@error:
	mov	ax,4cffh
	int	21h
fill_tbl	ENDP	

fsize	dw	893
q_num	db	0
l_count	db	0		;����稪 �����
	
buffer	label byte
db	'\�室�騥 � ������業�� ���� ����⢠ � �६���� ��������, �����樮������. ����� �� ��, �� ������業��� � �६���� ��室�� �� ��⮩稢��� ࠢ������?',13,10
db	'4',13,10
db	'1. ��. ��� ���⮨� ������ ⠪',13,10
db	'2. �������訩�� �࣠���� �������� ᢮� ������業��. ���⮬� ������業�� �ᥣ�� ������� � ��⮩稢�� ࠢ����ᨨ.',13,10
db	'+3. ���. �� ��� �����樮��஢���� �࣠������ ������業��� ���室�� �� ������ ��⮩稢��� ���ﭨ� � ��㣮�.',13,10
db	'4. �� �ᥣ��. ��� ������ �� �����⭮�� ������業���, �� �������� �᫮���, � ������ �� �������.',13,10
db	'\�� ��ꥤ���� � ᥡ� ����⨥ "������"?',13,10
db	'4',13,10
db	'1. �� ����⨥ ��ꥤ���� � ᥡ� ��� ����� �� �����, ������ 祫�����.',13,10
db	'2. �� ����⨥ ��ꥤ���� �⬮����, ��������, �����, ������� � ������� � �ᥬ, �� � ��� ���⠥�.',13,10
db	'+3. �� ����⨥ ��ꥤ���� �⬮����, �������� � ����� � �ᥬ, �� � ��� ���⠥�.',13,10
db	'4. �� ����⨥ ��ꥤ���� ��� ����� �� �����, �஬� 祫�����',13,10

t_rows	dw	1024 dup (0)
t_answ	db	1024 dup (0)
	end	start