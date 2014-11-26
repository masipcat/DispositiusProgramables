.set DDRB_o , 0x4
.equ PORTB_o , 0x5
PIND_o = 0x09
DDRD_o = 0x0a
PORTD_o = 0x0b

OCR2B = 0xB4
OCR2A = 0xB3
TCNT2 = 0xB2
TCCR2B = 0xB1
TCCR2A = 0xB0
TIFR2 = 0x37

UDR0 = 0xc6
UBRR0H = 0xc5
UBRR0L = 0xc4
UCSR0C = 0xc2
UCSR0B = 0xC1
UCSR0A = 0xC0

DEBUGAR = 1
u_temps = 100 // ms

.global main
.global __vector_18

.section .text

.macro ledOn
        sbi PORTB_o, 5
.endm

.macro ledOff
        cbi PORTB_o, 5
.endm

/* rutina que espera una unitat de temps */
espera:
        // ..
        ret

/* rutina que activa la pota de sortida*/
punt:
        rcall espera
        ret

ratllat:
        rcall espera
        rcall espera
        rcall espera
        ret

/* rutina que genera la transmissió morse a partir d'un char r16 */
morse:
        // sileci de dos unitats
        rcall espera
        rcall espera
        ret

/* rutina de transmissió de byte,
el valor a transmetre està al registre r16 */
tx:
        push r17
_tx:    lds r17, UCSR0A 
        sbrs r17, 5
        rjmp _tx
        sts UDR0, r16
        pop r17
        ret

/* defineixo la rutina d'interrupció
per recepció de byte a la USART */
__vector_18:
        lds r16, UDR0
        reti

activaTimer2:
        // 16*10^6 / (2*64*(1+124))
        // prescaler N = 64
        // compare output = 124
        //OCR = 124
        ledOn
        ldi r16, 0b00000100             ; configurem que clk/64 = 250 kHz // 011
        sts TCCR2B, r16
        ret

desactivaTimer2:
        ledOff
        ldi r16, 0b0                    ; stop timer
        sts TCCR2B, r16
        sts TCNT2, r16                  ; clear out
        ret

main:
        // Configuració Timer 1
        // ..

        // Configuració Timer 2
        ldi r16, 0b01000010             ; configurem el mode de comparació "Toggle OC2A" i TimerCounter Mode 010 (CTC)
        sts TCCR2A, r16
        ldi r16, 0b00000100             ; configurem que clk/64 = 250 kHz // 011
        sts TCCR2B, r16
        ldi r16, 0
        sts OCR2B, r16
        ldi r16, 124                    ; TOP = 125; comptem mig període d'una oscil·lació 1kHz (0.0005s)
        sts OCR2A, r16
        sbi DDRB_o, 3                   ; configurem el pin 11 (OC2A) com a sortida
        
        ldi r16, 0b0                    ; configurem el pin 7 com entrada
        out DDRD_o, r16

        /*ldi r16, 0b101000               ; configurar pin 11 (OC2A) i pin 13 com sortida
        out DDRB_o, r16*/

        sbi DDRB_o, 5                   ; configurem el pin 13 com a sortida

        /* set baud rate a 9600*/
        ldi r16, 0
        sts UBRR0H, r16
        ldi r16, 103
        sts UBRR0L, r16

        sbi PIND_o, 7                   ; pull-up pin 7

        /* set frame format */
        /* el valor de reset ja és correcte:
        asíncron, sense paritat, 1 stop, 8 dades,
        velocitat normal, cominicació no multiprocessor */
        /*arreglem el bit U2X0 forçant el valor de reset
        al reglistre UCSR0A*/
        /*ldi r16, 0b00100000
        sts UCSR0A, r16
        
        /* enable rx, tx, amb interrpció de rx 
        ldi r16, 0b10011000
        sts UCSR0B, r16*/

        //rcall activaTimer2

        /*habilitem interrupcions */
        sei

        rcall desactivaTimer2

        /*el bucle principal no fa res*/
loop:   
        in r16, PIND_o          ; pin 7 de l'Arduino
        rol r16
        brcc lOff
        rcall activaTimer2
        rjmp loop
lOff:   rcall desactivaTimer2
        rjmp loop

.section .data

.include "taula9.S"

.section .bss

.global __do_copy_data
.global __do_clear_bss
