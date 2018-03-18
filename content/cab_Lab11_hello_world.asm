;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;******************************************************************************
; MSP430G2553 Demo - USI-UART, 9600 Echo ISR, ~1 MHz SMCLK
;
; Description: Print "hello , world" over and over
; Default SMCLK = DCOCLK ~= 1.05 MHz
; Baud rate divider with SMCLK @9600 = 1MHz/2400 = 104.15
; Original functionality by M. Buccini / G. Morton
; Texas Instruments Inc., May 2005
; Built with Code Composer Essentials Version: 1.0
; Adapted for DB365 by Dorin Patru 05/14/08; updated May 2011
; Upgraded for LaunchPad and CCS 5.4 by Dorin Patru December 2013
;******************************************************************************
            .cdecls C,LIST,"msp430g2553.h"       ; Include device header file
;-------------------------------------------------------------------------------
			.bss TAFLAG,1	; TA SW FLG


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
; Setup P1.2 as TXD and P1.1 as RXD; see data sheet port schematic and UG
;-------------------------------------------------------------------------------
SetupP1 	bis.b #6h,&P1SEL 	; P1.2/P1.1 = USART0 TXD/RXD
			bis.b #6h,&P1SEL2 	; P1.2/P1.1 = USART0 TXD/RXD
;-------------------------------------------------------------------------------
; Setup USI in UART mode, minimal configuration, point to point
;-------------------------------------------------------------------------------
SetupUART0 	clr.b &UCA0CTL0 		; default values - see UG
			clr.b &UCA0CTL1 		; default values - see UG
			bis.b #UCSSEL1 + UCSSEL0,&UCA0CTL1 ; UCLK = SMCLK ~1 MHz
			clr.b &UCA0STAT 		; default values - see UG
			;bis.b #UCLISTEN,&UCA0STAT ; loopback - used for debugging only
;-------------------------------------------------------------------------------
; For a baud rate of 9600,the pre-scaler value is
;    = (UCAxBR0 + UCAxBR1 × 256) = 104 in decimal - integer part - see UG
;-------------------------------------------------------------------------------
			mov.b #050h,&UCA0BR0 	; Baud Rate = ?
			mov.b #000h,&UCA0BR1 	; UCBRx = ?
;-------------------------------------------------------------------------------
; Modulation Control Register - fractional part - see UG
;-------------------------------------------------------------------------------
			mov.b #002h,&UCA0MCTL 	; UCBRFx = 0, UCBRSx = 1, UCOS16 = 0
;-------------------------------------------------------------------------------
; SW reset of the USI state machine
;-------------------------------------------------------------------------------
			bic.b #UCSWRST,&UCA0CTL1 ; **Initialize USI state machine**
			bis.b #UCA0RXIE,&IE2 	; Enable USART0 RX interrupt
	 		bis.b #GIE,SR 			; General Interrupts Enabled
;-------------------------------------------------------------------------------
; After the state machine is reset, the TXD line seems to oscillate a few times
; It is therefore safer to check if the machine is in a state in which it is
; ready to transmit the next byte.  I learned it the hard way ;-(
;-------------------------------------------------------------------------------
TX2			bit.b #UCA0TXIFG,&IFG2 	; USI TX buffer ready?
			jz TX2 					; Jump if TX buffer not ready
			mov.b #0x55,&UCA0TXBUF 	; TX <U> charac. eq. to #0x55 in ASCII




			; Setup TimerA to generate an interrupt a few times per second
			mov #TASSEL1+ID1+ID0+TACLR,&TACTL; SMCLK, /8, STOP mode, clear
			bic #TAIFG, &TACTL
			mov #0xFFFF,&TACCR0		; Load count-up-to value
			mov #CCIE,&TACCTL0		; compare, enable compare interrupt

			clr.b &TAFLAG 	; Clear TA SW flag


;-------------------------------------------------------------------------------
; Main loop from here
;-------------------------------------------------------------------------------
Mainloop	eint 				; Enable general interrupts
			clrz 				; Clear Z
			clr.b &TAFLAG 		; Clear TA SW FLAG
			bis #MC_1,&TACTL	; Start counter in UP MODE
ChkTAFlag	tst.b &TAFLAG 		; Check to see if TA_ISR was
			jz ChkTAFlag 		; executed
			dint				; Disable general interrupts
			bic #MC_1+MC_0,&TACTL	; Stop counter
			call	#MyStrCpy
			nop					;
			jmp	Mainloop		;

;-----------------------------------------------------------------------
; Copy source string starting in R14 to output buffer
; No checks for overlap , space in destination , unterminated source ...
MyStrCpy:
			clr		R13				; will count 13 characters of the string
			mov.w    #SourceStr,R14           ; Load address of source

CopyTest:

            mov.b    @R14+,&UCA0TXBUF          ; [2 words , 5 cycles] copy src -> dst
            ;wait for buffer empty
TXempty:    BIT.B #UCA0TXIFG, &IFG2 ; USCI_A0 Transmit Interrupt?
			jz	TXempty
			inc	R13
            cmp.b    #15,R13                   ; [2 words , 4 cycles] test source
            jne      CopyTest                  ; [1 word , 2 cycles] continue if not \0
            ret                                ; Yes: return to caller






;------------------------------------------------------------------------------
; Echo back RXed character, confirm TX buffer is ready first
;------------------------------------------------------------------------------
USART0RX_ISR:	nop					;
TX1 		bit.b #UCA0TXIFG,&IFG2 	; USI TX buffer ready?
			jz TX1 					; Jump if TX buffer not ready
;-------------------------------------------------------------------------------
; The order of execution of the two instruction sequence above and the one
; below could be switched.
;-------------------------------------------------------------------------------
			mov.b &UCA0RXBUF,r10 	; Move received byte in r10
;-------------------------------------------------------------------------------
; For demonstration purposes, it is assumed that the remote terminal sends
; numbers which are eual to the upper case letter.  By adding the value 0x20 to
; it, the echoed number represents the same, but lower case letter.
;-------------------------------------------------------------------------------
			add.b #0x20, r10 		; add 0x20 to change upper -> lower case
			mov.b r10,&UCA0TXBUF 	; TX -> RXed character
			reti 					;

TA_ISR:
			nop							;
			bic.w #CCIFG, &TACCTL0		; clear interrupt flag
			mov.b #0x01, &TAFLAG 		; Set the TA SW flag
			reti

; Segment for constant data in ROM
SourceStr:                                     ; string constant, stored between 0xC000 and 0xFFFF
			.string	"hello , world!  "         ; "" should cause a '\0' to be appended
;------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
;           Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect 	.stack
;-----------------------------------------------------------------------

;-------------------------------------------------------------------------------
;           Interrupt Vectors - see device specific header file
;-------------------------------------------------------------------------------
            .sect   ".reset"		; RESET Vector
            .short  RESET
			.sect ".int07" 			; USI - RXD Vector
isr_USART:	.short USART0RX_ISR 	; USI receive ISR
			.sect ".int09" 			; TA0 Vector
isr_TA: 	.short TA_ISR ;
.end
