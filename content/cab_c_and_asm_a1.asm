; assembly comment
	.cdecls	C, LIST, "msp430g2553.h"	;include device header file
	.text

	.global	asm_mult
	.global second_add


asm_mult:
	add R13, R12
	add second_add, R12
	;mov #1, R14
	;mov #2, R15
	ret

	.end
