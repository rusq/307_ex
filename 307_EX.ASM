	.model tiny
	locals @@
	.186
	.code
	org	100h
start:	jmp	realstart

password	db	32 dup (0FFh)		;16 ���� - �����. ��஫�, 16 ���� - ����
dataf		db	'307_ex.dat',0
screen		db	'307_ex.raw',0
fatal1		db	'�� ������ 䠩� � ����묨$'
fatal2		db	'������ �ணࠬ�� �� ����஥��$'
inst_title	db	0B1h,0,29,'���������� �����������',0
instruc		db	10,10,10,10,'   ��� �।�������� �⢥��� �� ��᪮�쪮 ����ᮢ. ��ࠢ�����:',13,10
		db	'   � ��� �롮� �⢥� ᫥��� �ᯮ�짮���� ������ [1]-[9].',13,10
		db	'   � ��� �⬥�� �롮� ᫥��� ������ �� ��� �� ������� ����୮.',13,10
		db	'   � ������ [��] �㦨� ��� ���⢥ত���� �롮� � �த������� ����.',13,10,10
		db	'������ ���� �������...$'
ask4surname	db	'������ ���� 䠬����: $'
sur_stat	db	30h,24,0,'�ᯮ���� ⮫쪮 ���᪨� �㪢�, �� ����砭�� ����� ������ [��]',0
stat_arsehole	db	0C0h,24,0,'���� ������� :-)',0
stat_botan	db	0A0h,24,0,'���� ������� :-(',0

final_sur	db	'�������      : $'

final_screen	db	13,10
final_end	db	'�६�        : '
fn_hour		db	'00:00:00'
		db	13,10
final_q		db	'��� १����: '
done		db	'00/00'
		db	13,10,10
		db	'������� �९�����⥫�.$'
realstart:
	cld
	mov	ax,0FACEh
	int	21h
	cmp	ax,2002h
	je	pst
	call	fatal

pst:	mov	bx,offset password
	cmp	byte ptr [bx],0FFh
	jne	pss
	mov	dx,offset fatal2
	mov	ah,9
	int	21h
	ret

pss:
	mov	ax,1a00h			;Is there any VGA?
	int	10h
	cmp	al,1ah
	jne	@@00				;There isn't.. Fuck..
	mov	dx,offset screen		;VGA!! Show title screen
	call	pcxshow

@@00:	xor	ax,ax
	call	fcursor
	call	font_l				;Loading screen font
	call	open				;Opening file with data
	call	passwd				;Decrypting password
	call	bufferize			;Copying file data to buffer (with deciphering)
	call	close				;����砥� ����� 䠩�� � ����뢠�� ���
	call	genseed				;������㥬 seed
	call	fill_tbl			;������塞 ⠡���� (�������� �訡��)
	mov	ax,1003h
	xor	bx,bx
	int	10h

green_mile:					;��᫥���� �ਣ�⮢�����
	push	es				;���墠� ���뢠��� 23h, 1bh

	mov	ax,351Bh
	int	21h
	mov	word ptr [old_int1Bh],bx
	mov	ax,es
	mov	word ptr [old_int1Bh+2],ax

	mov	ax,3523h
	int	21h
	mov	word ptr [old_int23h],bx
	mov	ax,es
	mov	word ptr [old_int23h],ax

	pop	es

	mov	ax,251Bh
	mov	dx,offset dummy
	int	21h
	mov	ax,2523h
	mov	dx,offset dummy
	int	21h

restart:
	mov	bl,1Bh
	call	fclsa
	mov	bx,0B1h
	call	faline
	mov	si,offset inst_title
	call	fwritea

	mov	ah,9
	mov	dx,offset instruc
	int	21h

	xor	ax,ax
	int	16h

;���ᨬ 䠬���� :)
@@reask:
	mov	ax,01
	call	fcursor
	mov	bl,1Bh
	call	infobar
	mov	si,offset sur_stat
	call	change_stat
	mov	ah,9
	mov	dx,offset ask4surname
	int	21h

	mov	di,offset surname
	mov	cx,19
	mov	bh,'�'
	mov	bl,'�'
	call	field
	cmp	ah,01					;��㤥�� ������� ������� ���������?
	je	@@reask					;�� - ��ᨬ ��� ࠧ�� :)
	cmp	cx,2					;������� ������ ���� ���-�� 2 ᨬ���� ("��" :) )
	jb	@@reask
	mov	bx,cx					;��堥� $ � ����� :)
	mov	byte ptr [surname+bx],'$'
	xor	ax,ax					;�몫�稬 ����� ���!
	call	fcursor

	xor	ah,ah
	int	1ah
	mov	word ptr [ticks_start],dx
	mov	word ptr [ticks_start+2],cx

	xor	cx,cx
	mov	cl,byte ptr [q_total]
;-------------------------
;	jmp	short aa
;-------------------------
exloop:	push	cx
	mov	bl,1Bh

	call	infobar
	call	gen_num
	call	ask
	cmp	bh,bl
	je	@@ex10
	jmp	short @@ex20
@@ex10:	inc	byte ptr [q_rite]
@@ex20:	pop	cx
	loop	exloop

aa:	xor	ah,ah
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
	call	div32			;��⠥� ᥪ㭤�
	call	divtime			;� �६�

	mov	cx,3
	mov	bp,offset test_time
	mov	di,offset fn_hour
	call	conv_t

	mov	cx,1
	mov	bp,offset q_rite
	mov	di,offset done
	call	conv_t

	mov	cx,1
	mov	bp,offset q_total
	mov	di,offset [done+3]
	call	conv_t

	mov	al,q_rite
	cmp	al,q_togo
	jb	@@dumb
	mov	word ptr [stat],offset stat_botan
	mov	bl,2Fh
	jmp	short @@qq
@@dumb:
	mov	word ptr [stat],offset stat_arsehole
	mov	bl,4Bh

@@qq:	call	infobar
	mov	si,word ptr [stat]
	call	change_stat
	mov	ah,9
	mov	dx,offset final_sur
	int	21h
	mov	dx,offset surname
	int	21h
	mov	dx,offset final_screen
	int	21h

@@in:	xor	ax,ax
	int	16h
	cmp	ax,2308h			;^H
	jne	@@in
	

aus:	
	push	ds				;����⠭���� INT Vectors
	mov	ax,251Bh
	mov	bx,word ptr [old_int1Bh+2]
	mov	dx,word ptr [old_int1Bh]
	mov	ds,bx
	int	21h
	mov	al,23h
	mov	bx,word ptr cs:[old_int23h+2]
	mov	dx,word ptr cs:[old_int23h]
	mov	ds,bx
	int	21h
	pop	ds


	call	font_r
	mov	al,1
	call	fcursor
	mov	bl,7
	call	fclsa

	ret

INCLUDE INCLUDE\NUM2ASC.PRC
INCLUDE INCLUDE\307_EX.INC			;��楤�ન :)
INCLUDE INCLUDE\FONTLOAD.INC

;����� ��६���� �����


q_total		db	7			;������⢮ ����ᮢ ��� ���������
q_togo		db	5			;�����, ���. ����室��� �८������
q_rite		db	0			;������⢮ �ࠢ����� �⢥⮢

q_num		dw	0			;������⢮ ����ᮢ
l_count		dw	0			;������⢮ �ப � ����

INCLUDE INCLUDE\PCXSHOW.INC

surname		db	20 dup (?)		;������� ��㤥��

ticks_start	dw	2 dup (?)		;��ᥪ��� ⨪� :)
ticks_end	dw	2 dup (?)		;���� � ���� ���
waited		dw	2 dup (?)		;����쪮 ⨪�� ���஢�����
secs_tot	dw	2 dup (?)		;����쪮 ᥪ㭤�� ���஢����� :)
test_time	db	3 dup (?)		;�����쭮� �६� ���!

stat		dw	?
fhandle		dw	?
fsize		dw	?			;������ 䠩��
bread		dw	?
__seed		dw	?			;��� ������� ��砩��� �ᥫ
passwtmp	db	16 dup (?)
readbuf		db	512 dup (?)
decodbuf	db	512 dup (?)
t_rows		dw	1024 dup (?)		;���饭�� ��ப
t_answ		db	1024 dup (?)		;������⢮ ��ப � �����
t_asked		db	1024 dup (?)		;���ᨢ �������� ����ᮢ

old_int1Bh	db	4 dup (?)		;���� ����� INT 1Bh
old_int23h	db	4 dup (?)		;���� ����� INT 23h
buffer:
	end	start