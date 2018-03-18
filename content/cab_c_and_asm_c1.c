#include <msp430g2553.h>
//#include "asm_mult.asm"

// C comment

int result;

int second_add;

extern int asm_mult(int, int);

void main(void) {
	//int result;
    WDTCTL = WDTPW | WDTHOLD;	// Stop watchdog timer

    second_add = 4;
    result = asm_mult(2, 3);
    //asm(" mov	#0x01, R15 ; ");
    result++;
    return;

}


