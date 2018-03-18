;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
; Reads sensor status for wheel left, down, right, up, and center button
; Saves baseline and crt measurements in two arrays
; Updates the status of these sensors in sensor_status
; 	sensor_status can be used to turn on LEDs or trigger other actions
; For wheel left turn on LED D1
; For wheel down turn on LED D4
; For wheel right turn on LED D8
; For wheel up turn on LED D5
; For turning on each of these LEDs you can define constant values that when
; 	loade in P1OUT will turn on the right LED.  Constant array is shown below.
;	Un-comment to use.
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
SWdelay		.equ	0x0002	; delay value used by the SW timer
;-------------------------------------------------------------------------------
; Constant array with the values to turn on LEDs
;-------------------------------------------------------------------------------
;			.sect ".const" ;
;LEDdisplay: 	.byte 0x--		;
;				.byte 0x-- 		;
;				.byte 0x-- 		;
;				.byte 0x-- 		;
;				.byte 0x-- 		;
;-------------------------------------------------------------------------------
; Allocate 10 bytes for the baseline values
;-------------------------------------------------------------------------------
			.data
			.bss	meas_base, 10			;
;-------------------------------------------------------------------------------
; Allocate another 2 bytes for the current values
;-------------------------------------------------------------------------------
			.bss	meas_crt, 10			;
;-------------------------------------------------------------------------------
; Allocate one byte for sensor status - to be used by the display routine to
; determine which LED to turn on
;-------------------------------------------------------------------------------
			.bss	sensor_status, 1		;
;-------------------------------------------------------------------------------
; Here begins the code segment
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
; Setting up P1 to outputs - will be controlled in the display routine
;-------------------------------------------------------------------------------
			bis.b	#0xff, &P1DIR	; set up P1 as outputs
			bic.b	#0xff, &P1OUT	; P1 outputs 0
;-------------------------------------------------------------------------------
; The real mainloop starts here
;-------------------------------------------------------------------------------
			call #meas_base_val		; do this once
Mainloop	call #meas_crt_val		;
			call #det_sensor		;
			call #display			;
			jmp	Mainloop			;
;-------------------------------------------------------------------------------
; End mainloop ==> all subroutines from here on
;-------------------------------------------------------------------------------
; Measure base line values routine
;-------------------------------------------------------------------------------
meas_base_val:	mov.b	#0x02, R5	; initialize R5 to point to P2.x
				mov.b	#0x00, R6	; initialize R6 to the base of meas_base
meas_base_again	call #meas_setup	;
;-------------------------------------------------------------------------------
; Clear TAR and start TA0 in continuous mode; use BIS and not MOV
; so that you don't cancel previous settings
;-------------------------------------------------------------------------------
			bis #MC_2 + TACLR, &TA0CTL 	;
;-------------------------------------------------------------------------------
; Call the SW delay routine, which here it is used to provide the accumulation
; period; could use instead ACLK fed from VLO
;-------------------------------------------------------------------------------
			call #SWtimer			;
;-------------------------------------------------------------------------------
; Now, after the accumulation period has passed, generate a SW based
; capture trigger by toggeling CCIS0
;-------------------------------------------------------------------------------
			xor	#CCIS0, &TA0CCTL1	;
;-------------------------------------------------------------------------------
; Save the baseline captured value in meas_base array
;-------------------------------------------------------------------------------
			mov	TA0CCR1, meas_base(R6)	; note the use of the SYMBOLIC AM
			bic #MC1+MC0, &TA0CTL 	; Stop TA
			sub #2, meas_base(R6)	; Adjust this baseline
			bic.b 	R5,&P2SEL2		; Stop the oscillation on the crt. pin
			rla.b	R5				; Prepare next x
			add.b	#0x02, R6		; Prepare the next index into the array
			cmp.b	#0x40, R5		; Check if done with all five sensors
			jnz		meas_base_again	;
			ret						;
;-------------------------------------------------------------------------------
; Measure current values routine
;-------------------------------------------------------------------------------
meas_crt_val:	mov.b	#0x02, R5	; initialize R5 to point to P2.1
			mov.b	#0x00, R6		; initialize R6 to the base of meas_base
meas_crt_again	call #meas_setup	;
			bis #MC_2 + TACLR, &TA0CTL 	; Continuous, Clear TAR
			call #SWtimer			;
			xor #CCIS0, &TA0CCTL1	; Trigger SW capture
			mov TA0CCR1, meas_crt(R6)	; Save captured value in array
			bic #MC1+MC0, &TA0CTL 	; Stop timer
			bic.b 	R5,&P2SEL2		; Stop the oscillation on the crt. pin
			rla.b	R5				; Prepare next x
			add.b	#0x02, R6		; Prepare the next index into the array
			cmp.b	#0x40, R5		; Check if done with all five sensors
			jnz		meas_crt_again	;
			ret						;
;-------------------------------------------------------------------------------
; Determine which sensor was pressed routine
;-------------------------------------------------------------------------------
det_sensor:	clr.b	sensor_status	;
			mov.b	#0x02, R5		; initialize R5 to point to P2.1
			mov.b	#0x00, R6		; initialize R6 to the base of meas_base
CheckNextSensor		cmp	meas_crt(R6), meas_base(R6)	;
			jn	NotThisSensor		;
			bis.b	R5, sensor_status	; Update sensor_status
NotThisSensor	rla.b	R5			; Prepare next x
			add.b	#0x02, R6		; Prepare the next index into the array
			cmp.b	#0x40, R5		; Check if done with all five sensors
			jnz		CheckNextSensor	;
			ret						;
;-------------------------------------------------------------------------------
; Display routine.  To be filled in by you.  Turn on the LED that corresponds
; to the 1 position in sensor_status.
;-------------------------------------------------------------------------------
display:	nop						;
			ret						;
;-------------------------------------------------------------------------------
; Setting up P2.x and TA for the next measurement routine
;-------------------------------------------------------------------------------
; Setting up P2.x to pin oscillation mode
;-------------------------------------------------------------------------------
meas_setup:	bic.b R5,&P2DIR 		; P2.x input
				bic.b R5,&P2SEL 	;
				bis.b R5,&P2SEL2	;
;-------------------------------------------------------------------------------
; The oscillation from P2.x is driving INCLK input of TA0
; No division of this clock source
;-------------------------------------------------------------------------------
		 	mov #TASSEL_3, &TA0CTL 	;
;-------------------------------------------------------------------------------
; Setting up to capture the value of TAR on either rising or falling edges
; using SW based trigger
;-------------------------------------------------------------------------------
			mov #CM_3 + CCIS_2 + CAP, &TA0CCTL1 	;
			ret						;
;-------------------------------------------------------------------------------
; SW delay routine
;-------------------------------------------------------------------------------
SWtimer:	mov	#SWdelay, r8		; Load delay value in r5
Reloadr7	mov	#SWdelay, r7		; Load delay value in r6
ISr70		dec	r7					; Keep this PW for some time
			jnz	ISr70				; The total SW delay count is
			dec	r8					;  = SWdelay * SWdelay
			jnz	Reloadr7			;
			ret						; Return from this subroutine
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
