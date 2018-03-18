;*******************************************************************************
;	MSP430 Assembler Code Template for use with TI Code Composer Studio
;   dxp_Lab5_a1.asm
;	Displays a clockwise circle
;	dbp 0301_365_20053
;   Built with CCE for MSP430 Version: 1.00
;	Updated for version 4.x.x by Dorin Patru April 2011
;	Re-coded completely for CCS v5.4, Launch Pad and Capacitive Booster Pack
;		by Dorin Patru October 2013
;*******************************************************************************

;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430g2553.h"       ; Include device header file
;-------------------------------------------------------------------------------

;		.data			; presume .data begins at 0x0200
SPEED:	.word	0x7fff	; display half speed
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section
            .retainrefs                     ; Additionally retain any sections
                                            ; that have references to current
                                            ; section
;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer
;-------------------------------------------------------------------------------
                                            ; Main loop here
;-------------------------------------------------------------------------------
			clr		r10				; delay counter
			clr		r11				; LED select
			bic.b	#0xff,&P1DIR	; set up P1 as input
			bis.b	#0xf8,&P1DIR	; set up P1[7:3] as outputs
;-------------------------------------------------------------------------------
;	LEDs 4-1 not elegant display
;-------------------------------------------------------------------------------
CIRCLE:		bic.b	#0xf8,&P1OUT	; prepare to display LEDs 1-4
			bis.b	#0x80, &P1OUT	; turn on LED4
			call	#DELAY			; wait around
			bic.b	#0x80, &P1OUT	; turn off LED4
			bis.b	#0x40, &P1OUT	; turn on LED3
			call	#DELAY			; wait around
			bic.b	#0x40, &P1OUT	; turn off LED3
			bis.b	#0x20, &P1OUT	; turn on LED2
			call	#DELAY			; wait around
			bic.b	#0x20, &P1OUT	; turn off LED2
			bis.b	#0x10, &P1OUT	; turn on LED1
			call	#DELAY			; wait around
			bic.b	#0x10, &P1OUT	; turn off LED1
;-------------------------------------------------------------------------------
;	LEDs 5-8 display loop
;-------------------------------------------------------------------------------
			bic.b	#0xf8,&P1OUT	; turn out all LEDs
			bis.b	#0xf8,&P1OUT	; prepare to display LEDs 5-8
			mov.b	#0x08, r11		; prepare r11 for the loop
			clrc					; clear carry
DISP_LOOP	rla.b	r11				;
			jc		CIRCLE			; check if you need to display another LED
			bic.b	r11, &P1OUT		; turn on LEDs 5-8
			call	#DELAY			; wait around
			jmp		DISP_LOOP		; jump to display the next LED
			jmp		CIRCLE			; circle again
;-------------------------------------------------------------------------------
;	Delay Subroutine
;-------------------------------------------------------------------------------
DELAY:		mov.w	&SPEED,R10
MORE_DELAY:	dec.w   R10             ; Decrement R10
            jnz     MORE_DELAY   	; Delay over?
           	ret				    	; return
;-------------------------------------------------------------------------------
;           Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect 	.stack
;-------------------------------------------------------------------------------
;           Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
