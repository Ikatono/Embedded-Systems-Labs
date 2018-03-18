#include <msp430g2553.h>



/*
 * main.c
 */


int main(void) {
    WDTCTL = WDTPW + WDTHOLD;	// Stop watchdog timer

	// MUST SETUP INTERRUPTS HERE

    while(1);

}



#pragma vector = TIMER0_A0_VECTOR
__interrupt void TA_FFF2_ISR(void) {
	// Timer FFF2 ISR CODE HERE
	// Only CCIE on CCR0 block generates an interrupt at this vector
	return;
}

#pragma vector = TIMER0_A1_VECTOR
__interrupt void TA_FFF0_ISR(void) {
	// Timer FFF0 ISR CODE HERE
	// Three sources (TAIE, CCIE on CCR1 and CCIE on CCR2) all generate interrupts at this vector
	return;
}

#pragma vector=ADC10_VECTOR
__interrupt void ADC10_ISR(void) {
	// ADC10 ISR CODE HERE
	return;
}
