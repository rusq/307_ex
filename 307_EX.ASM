	.model tiny
	locals @@
	.186
	.code
	org	100h
start:	jmp	realstart

password	db	32 dup (0FFh)		;16 байт - зашифр. пароль, 16 байт - мусор
dataf		db	'307_ex.dat',0
fatal1		db	'Не найден файл с данными$'
fatal2		db	'Данная программа не настроена$'
inst_title	db	0B1h,0,29,'ПРОЧИТАЙТЕ ВНИМАТЕЛЬНО',0
instruc		db	10,'   Вам предлагается ответить на семь вопросов.',13,10
		db	'Для выбора ответа следует использовать клавиши [1]-[9].',13,10
		db	'Клавиша [─┘] служит для подтверждения выбора и перехода на следующий вопрос.',13,10
		db	'   Между вопросами возможна задержка из-за несовершенства алгоритма генерации ',13,10
		db	'случайных чисел (зависит от тактовой частоты CPU)',13,10
		db	'   Удачи!',13,10,10
		db	'Нажмите любую клавишу...$'
ask4surname	db	'Введите вашу фамилию: $'
sur_stat	db	30h,24,0,'Используйте только русские буквы, по окончанию ввода нажмите [─┘]',0
stat_arsehole	db	0C0h,24,0,'ТЕСТ ЗАВАЛЕН',0
stat_botan	db	0A0h,24,0,'Поздравляю, ТЕСТ ПРОЙДЕН',0

final_sur	db	'Фамилия        : $'

final_screen	db	13,10
		db	'Время начала   : '
st_hour		db	'00:00:00'
		db	13,10
final_end	db	'Время окончания: '
fn_hour		db	'00:00:00'
		db	13,10
final_q		db	'Ваш результат  : '
done		db	'00/00'
		db	13,10,10
		db	'Позовите преподавателя.$'
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
	xor	ax,ax
	call	fcursor
	call	font_l				;Loading screen font
	call	open				;Opening file with data
	call	passwd				;Decrypting password
	call	bufferize			;Copying file data to buffer (with deciphering)
	call	close				;Получаем длину файла и закрываем его
	call	genseed				;Генерируем seed
	call	fill_tbl			;Заполняем таблицы (возможна ошибка)
	mov	ax,1003h
	xor	bx,bx
	int	10h

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

;Спросим фамилию :)
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
	mov	bh,'А'
	mov	bl,'я'
	call	field
	cmp	ah,01					;Студент пожелал остаться неизвестным?
	je	@@reask					;Да - спросим ещё разок :)
	cmp	cx,2					;Фамилия должна быть хотя-бы 2 символа ("Тё" :) )
	jb	@@reask
	mov	bx,cx					;Пихаем $ в конец :)
	mov	byte ptr [surname+bx],'$'
	xor	ax,ax					;Выключим курсор нах!
	call	fcursor

	mov	bx,offset s_time			;Запомним время начала
	call	gettime
	mov	cx,3
	mov	bp,offset s_time
	mov	di,offset st_hour
	call	conv_t

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

aa:	mov	bx,offset s_time
	call	gettime

	mov	cx,3
	mov	bp,offset s_time
	mov	di,offset fn_hour
	call	conv_t

	mov	cx,2
	mov	bp,offset q_rite
	mov	di,offset done
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
	

aus:	call	font_r
	mov	al,1
	call	fcursor
	mov	bl,7
	call	fclsa
	ret


INCLUDE INCLUDE\NUM2ASC.PRC
INCLUDE INCLUDE\307_EX.INC			;Процедурки :)
INCLUDE INCLUDE\FONTLOAD.INC

;█████ Переменные █████

q_rite		db	0			;Количество правильных ответов
q_total		db	7			;Количество вопросов для задавания
q_togo		db	5			;Барьер, кот. необходимо преодолеть
q_num		dw	0			;Количество вопросов
l_count		dw	0			;Количество линий в буфере
surname		db	20 dup (?)		;Фамилия студента
s_time		db	3 dup (?)		;-- Время начала|окончания опроса
stat		dw	?
fhandle		dw	?
fsize		dw	?			;Размер файла
bread		dw	?
__seed		dw	?			;Для генератора случайных чисел
passwtmp	db	16 dup (?)
readbuf		db	512 dup (?)
decodbuf	db	512 dup (?)
t_rows		dw	1024 dup (?)		;Смещения строк
t_answ		db	1024 dup (?)		;Количество строк в вопросе
t_asked		db	1024 dup (?)		;Массив заданных вопросов

buffer:
	end	start