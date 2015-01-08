.include "constants.S"

u_temps = 100
SUBD = 4
temps = (250*u_temps/SUBD)-1

DEBUGAR = 0
TRACE = 0

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

isInputHigh:
        /* T = 1 -> input High
           T = 0 -> input Low
         */
        push r16
        in r16, PIND                    ; entrada 2
        andi r16, 0b100
        cpi r16, 0b100
        pop r16
        set
        brne iiH1
        ret
iiH1:   clt
        ret


tx:     push r17
tx1:    lds r17, UCSR0A 
        sbrs r17, 5
        rjmp tx1
        sts UDR0, r20
        pop r17
        ret

procesa:
        in r2, SREG
        cpi r22, 1 * SUBD               ; es considera soroll o senyal invàlid (no s'hauria de produir)
        brlo _d
        cpi r22, 3 * SUBD               ; és un punt o un final de caràcter
        brsh _p
        clr r25                         ; pausa entre punts i/o ratlles
.if DEBUGAR == 1
        ldi r20, ' '
.endif
        sbrs r2, 6                      ; comprovem l'estat de T
        ret
        clc
        rol r23                         ; afegim un zero a la dreta
        inc r24                         ; número de punts i ratlles
        clr r25                         ; esperant més punts i ratlles
.if DEBUGAR == 1
        ldi r20, '.'
.endif
        ret
_p:     cpi r22, 7 * SUBD + 2           ; és una ratlla o un pausa de char
        brsh _r
        ldi r25, 1
.if DEBUGAR == 1
        ldi r20, 'p'
.endif
        sbrs r2, 6                      ; comprovem l'estat de T
        ret
        clc
        rol r23
        inc r23                         ; afegim un 1 a la dreta
        inc r24                         ; número de punts i ratlles
        clr r25                         ; esperant més punts i ratlles
.if DEBUGAR == 1
        ldi r20, '-'
.endif
        ret
_r:     ldi r25, 2                      ; pausa paraula
.if DEBUGAR == 1
        ldi r20, 'P'
.endif
        ret
_d:     ldi r25, 3                      ; ignorem
.if DEBUGAR == 1
        ldi r20, 'i'
.endif
        ret

onInputChange:
.if TRACE == 1
        in r2, SREG
        ledOn
        sbrc r2, 6                      ; comprovem l'estat de T
        ledOff
.endif

.if DEBUGAR == 1
        cpi r25, 3                      ; si s'ha d'ignorar el processament...
        breq _ign
.endif
        rcall procesa
.if DEBUGAR == 1
        rcall tx
.endif
        cpi r25, 0                      ; si s'esperen més caràcters... -> _v1e
        breq _v1e

.if TRACE == 1 && DEBUGAR == 1
        mov r20, r23
        rcall tx
        mov r20, r24
        rcall tx
        mov r20, r25
        rcall tx
        ldi r20, '<'
        rcall tx
.endif
.if DEBUGAR == 1
        ldi r20, '='
        rcall tx
.endif

        // muntem a el valor del registre "morse"
        mov r16, r24                    ; desem el valor del comptador
        clr r2        
_next:  ror r23 
        ror r2
        dec r24
        brne _next
        eor r16, r2                     ; resultat (es busca el caràcter a la taula)
        rcall troba_codi
        cpi r16, 29
        breq _nn
        mov r20, r16
        rcall tx

_nn:    clr r23                         ; reset dels comptadors de Morse
        clr r24
        clr r25

        rjmp _v1e

_ign:
.if DEBUGAR == 1
        clr r25
        ldi r20, 'i'
        rcall tx
.endif

_v1e:   clr r22                         ; reset del comptador de 100/SUBD ms
        rcall isInputHigh               ; T = 1 if input is high, else T = 0
        rcall desactivaTimer1
        rcall clearTimer1
        rcall activaTimer1
        ret

__vector_1: // Interrupció de que canvia l'entrada
        rcall onInputChange
        reti

__vector_11: // Interrupció timer1
        cpi r22, 7 * SUBD + 3
        breq _v11e
        inc r22
        reti
_v11e:  rcall onInputChange
        //ldi r25, 2                     ; pausa llarga
        rcall desactivaTimer1          ; potser  es podria activar per optimitzar el consum de l'Arduino
        rcall clearTimer1
        reti

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

troba_codi:
        push r30
        push r31
        push r17
        ldi r31, hi8(taulac1)
        ldi r30, lo8(taulac1)
tr:     ld r17, Z+
        cp r17, r16
        brne tr
                                // S'afaga el valor ASCII
        ldd r16, Z+35
        pop r17
        pop r31
        pop r30
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

        sbi DDRB, 5                     // configurem el pin 13 com a sortida
        rcall configuraTimer1
        rcall desactivaTimer1

        ldi r22, 0                      // N vegades que ha passat u_temps
        ldi r23, 0                      // Punts i ratlles (omplim de dreta a esquerra)
        ldi r24, 0                      // Número de punts i ratlles en un caràcter
        ldi r25, 3                      // Estat del morse:
                                        //   0: processant
                                        //   1: final caràcter
                                        //   2: final paraula
                                        //   3: igonrar (pausa massa llarga o massa curta)

        clr r0
        clr r1
        inc r1

        ledOff

        clt
        sei

        rcall activaTimer1

loop:   rjmp loop

.section .data

.include "taula9.S"

.global __do_copy_data