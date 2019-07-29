	.model tiny
	.code
	org	100h
start:
	call	font_l
	ret
INCLUDE INCLUDE\fontload.inc
buffer:
	end	start