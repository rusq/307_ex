        .model tiny
        locals @@
        .186
        .code

PALETTE         equ     98h
PALETTE_1       equ     0E3h

        org     100h
start:  jmp     realstart

file_dat        db      '307_ex.dat',0
file_txt        db      '307_ex.txt',0

copyright       db      'SERVICE.COM - (C) 2002 Gilyazov R.',13,10
                db      '8x16 Russian VGA font (C) 1989 Pete I. Kvitek',13,10
                db      'Dedicated to the bright memory of Dmitry Gurtyak (1971-1998)',13,10,10,'$'
keine           db      'No actions taken$'
success         db      'Operation successfully completed$'
changed         db      'Parameters changed$'
updating        db      'Updating . . .',13,10,'$'
msg             db      'Select the function$'
menu            db      ' Update       ',0
                db      ' Decipher     ',0
                db      ' Cipher       ',0
                db      ' Setup        ',0
                db      ' Exit         ',0
newpass         db      13,'Input keyword',13,10
                db      '(8 chars): $'
confirm         db      13,10,'Repeat keyword: $'
getpass         db      13,' ',0FDh,' $'
endpass         db      'Wrong password',7,'$'
error1          db      13,10,'Not matched. Retry',13,10,10,'$'
error2          db      13,10,'Password must be 8 chars long',13,10,10,'$'
error3          db      13,10,'Fatal error$'
error4          db      'TSR reported error$'
error5          db      'This programme is a part of the INSTALL.COM!$'


out_message     dw      keine

errorlevel      db      9

menuitems       equ     5

realstart:
        cmp     byte ptr cs:[81h],'�'
        je      @@_ja
        mov     dx,offset error5
        mov     ah,9
        int     21h
        ret
@@_ja:  mov     ax,0FACEh
        int     21h
        cmp     ax,2002h
        je      @@strt
        mov     ah,9
        mov     dx,offset error4
        int     21h
        mov     ax,4c05h
        int     21h
@@strt: mov     ax,3
        int     10h
        call    font_l
        and     byte ptr [passf+5],0FEh

        mov     ah,9
        mov     dx,offset msg
        int     21h

        mov     ax,1000h
        mov     bl,01
        mov     bh,PALETTE
        int     10h
        mov     bl,07
        mov     bh,PALETTE_1
        int     10h

        mov     ax,0001h
        mov     bx,0F07h
        mov     cx,7101h
        call    makeframe

;-- start of decrypt ----------
        mov     bx,offset passf                 ;�����㥬 ��� 䠩��
        mov     byte ptr [bx+8],'O'
        mov     byte ptr [bx+9],'m'
        add     byte ptr [bx+2],17h
        mov     byte ptr [bx+6],'.'
        xor     byte ptr [bx+7],0E0h
;-- end of decrypt ------------

        mov     ax,0102h
        mov     bx,1F70h
        mov     cx,menuitems
        mov     si,offset menu
        call    makemenu

        cmp     bh,01h
        je      exit
        cmp     bl,04h
        je      exit
        cmp     bl,03h
        je      setup
        cmp     bl,01h
        je      call_decrypt
        cmp     bl,02h
        je      call_crypt
        or      bl,bl
        je      update

update:
        mov     byte ptr [errorlevel],8
        mov     word ptr [out_message],offset updating
        jmp     short exit
setup:
        call    set_quest
        jmp     short exit
call_crypt:
        call    crypt           ;����㥬 ��஫�
        call    savepass        ;���࠭塞 � 307_ex.com
        call    txt_2_dat       ;����㥬 ᠬ �� ������
        mov     word ptr [out_message],offset success
        mov     byte ptr [errorlevel],0
        jmp     short exit      ;��室

call_decrypt:
        call    decrypt
        call    dat_2_txt
        mov     word ptr [out_message],offset success
        mov     byte ptr [errorlevel],0

exit:
        call    emptypass       ;��頥� ��஫�� ���� (! :) )
        mov     bl,7
        call    fclsa           ;���頥� ��࠭
        mov     ah,9
        mov     dx,offset copyright
        int     21h
        mov     ax,1000h
        mov     bx,0101h
        int     10h
        mov     ax,1000h
        mov     bx,0707h
        int     10h
        call    font_r          ;����⠭�������� �ਣ������ ����
        mov     ah,9
        mov     dx,word ptr [out_message]
        int     21h
        mov     ah,4ch
        mov     al,errorlevel
        int     21h


INCLUDE INCLUDE\SERVICE.INC     ;����� ��直� �㫥��� ��楤�ન :)
INCLUDE INCLUDE\FONTLOAD.INC


passchars       db      ?               ;������⢮ ᨬ����� � ��஫�
fhandle         dw      ?               ;�������� �㪮�⪠
fhandle_txt     dw      ?               ;---"---- ��� TXT
bread           dw      ?               ;���⠭� ���⮢
pass1           db      8 dup (?)       ;��஫�1
pass2           db      8 dup (?)       ;��஫�2 (���⢥ত����)
passw           db      16 dup (?)      ;����

pbuf:           db      3 dup (?)       ;���� ��� �⥭�� ��஫�
passe           db      31 dup (?)      ;����஢���� ��஫�

buffer1         db      512 dup (?)     ;���� ��� �⥭��/�����
buffer2         db      512 dup (?)     ;-----------"-----------
buffer:                                 ;����� ��� FONT_L
        end     start