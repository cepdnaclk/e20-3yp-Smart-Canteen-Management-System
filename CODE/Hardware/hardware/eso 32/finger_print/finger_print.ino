#include <avr/io.h>

int main(void) {
    
    DDRB |= (1 << DDB3);

    // Set 50% duty cycle (127/255 ≈ 50%)
    OCR0A = 127;

    // Configure Timer0: Fast PWM, non-inverting, prescaler=64
    TCCR0A |= (1 << COM0A1) | (1 << WGM01) | (1 << WGM00); // Non-inverting, Fast PWM
    TCCR0B |= (1 << CS01) | (1 << CS00);  // Prescaler=64 (Freq=16e6/(64*256)=976.56Hz)

    while (1); 
}