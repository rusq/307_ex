	.model tiny
	.code
	org	100h
start:
	call	font_l
	call	font_r
	ret
INCLUDE fontload.inc
buffer:
	end	start