.include "constants.S"

u_temps = 100
SUBD = 4
temps = (250*u_temps/SUBD)-1

DEBUGAR = 1

.global main
.global __vector_1
.global __vector_11

/* DURACIÓ MORSE (en u_temps)
        punt: 1
        ratlla: 3
        pausa: 1
        pausa caràcter: 3
        pausa paraula: 7
*/

/* Criteris:
        r0 = 0
        r1 = 1
        r2 = TEMP
*/

// Utiles
.macro ledOn
        sbi PORTB, 5
.endm

.macro ledOff
        cbi PORTB, 5
.endm

.macro isInputHigh
        push r16
        in r16, PIND                    ; entrada 2
        andi r16, 0b100
        cpi r16, 0b100
        pop r16
        breq 1f
        clt
        rjmp 2f
1:      set
2:
.endm

tx:     push r17
tx1:    lds r17, UCSR0A 
        sbrs r17, 5
        rjmp tx1
        sts UDR0, r20
        pop r17
        ret

.macro procesaEnd
        ;pop r2
        ;out SREG, r2                            ; preservar SREG
        ret
.endm

procesa:
        in r2, SREG
        ;push r2
.if DEBUGAR == 1
        cpi r22, 1 * SUBD + SUBD/4              ; es considera soroll
        brlo _d
        cpi r22, 3 * SUBD + SUBD/4              ; és un punt o un final de caràcter
        brsh _p
        ldi r20, '.'
        sbrc r2, 6
        procesaEnd
        ldi r20, ' '
        procesaEnd
_p:     cpi r22, 7 * SUBD + SUBD/4              ; és una ratlla o un espai
        brsh _r
        ldi r20, '-'
        sbrc r2, 6
        procesaEnd
        ldi r20, ' '
        procesaEnd
_r:     cpi r22, 29
        brsh _d
        ldi r20, ' '
        procesaEnd
_d:     ldi r20, ''
        procesaEnd
.else
        procesaEnd
.endif

__vector_1: // Interrupció de que canvia l'entrada
        ledOn
.if DEBUGAR == 1
        cpi r22, 0 // si no ha passat ni un 100/
        breq _v1e
.endif
        rcall procesa
        cpi r20, ''
        breq _v1e
        rcall tx

_v1e:   clr r22
        isInputHigh                     ; T = 1 if Input High, else T = 0
_seg:   rcall desactivaTimer1
        rcall clearTimer1
        rcall activaTimer1
        reti

__vector_11: // Interrupció timer1
        cpi r22, 255
        breq _v11e
        inc r22
_v11e:  reti

activaTimer1:
        push r16
        push r17
        ldi r16, hi8(temps)
        ldi r17, lo8(temps)
        sts OCR1AH, r16
        sts OCR1AL, r17
        ldi r17, 0b00001011             ; configurem que clk/64
        sts TCCR1B, r17
        pop r17
        pop r16
        ret

configuraTimer1:
        push r16
        push r17
        ldi r16, 0b10000000             ; configurem el mode de comparació 10 - CTC
        ldi r17, 0b00001011             ; configurem que clk/64
        sts TCCR1A, r16
        sts TCCR1B, r17
        ldi r16, 0b00000010             ; activem la interrupció de Ouput Compare match
        sts TIMSK1, r16
        pop r17
        pop r16
        ret

desactivaTimer1:
        push r16
        ldi r16, 0
        sts TCCR1B, r16
        sts TCNT1H, r16
        sts TCNT1L, r16
        pop r16
        ret

clearTimer1:
        push r16
        ldi r16, 0
        sts TCNT1H, r16
        sts TCNT1L, r16
        pop r16
        ret

main:   
        ldi r16, 0
        sts UBRR0H, r16
        ldi r16, 103
        sts UBRR0L, r16
        
        /*set frame format*/
        ldi r16, 0b00100000
        sts UCSR0A, r16
        ldi r16, 0b00000110
        sts UCSR0C, r16
        
        /*enable rx, tx, sense interrupcions*/
        ldi r16, 0b00011000
        sts UCSR0B, r16
        ldi r16, 0b10000000
        
        // Interrupció externa, portd D2
        ldi r16,0b00000001
        out EIMSK,r16
        ldi r16,0b00000001
        sts EICRA,r16
        ldi r16,0b00000100
        out PORTD,r16
        ldi r16,0b11111011
        out DDRD,r16
        ldi r16, 0b00011000
        sts UCSR0B, r16

        sbi DDRB, 5             // configurem el pin 13 com a sortida
        rcall configuraTimer1
        rcall desactivaTimer1

        ldi r22, 0              // N vegades que ha passat u_temps
        ldi r23, 0              // Si s'ha rebut un punt o una ratlla
        ldi r24, 0              // Número de punts i ratlles en un caràcter

        clr r0
        clr r1
        inc r1

        clt
        sei

        rcall activaTimer1

loop:   rjmp loop