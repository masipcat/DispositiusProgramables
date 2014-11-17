.set DDRB_o , 0x4
.equ PORTB_o , 0x5
PORTD_o = 0x0b
DDRD_o = 0x0a

UDR0 = 0xc6
UBRR0H = 0xc5
UBRR0L = 0xc4
UCSR0C = 0xc2
UCSR0B = 0xC1
UCSR0A = 0xC0

DEBUGAR = 1
SALTA = 2
LEN_TAULA = taulac2_fin - taulac2

.global main
.global __vector_18

.section .text

/* rutina de transmissió de byte,
el valor a transmetre està al registre r16 */
tx:
        lds     r17,UCSR0A 
        sbrs    r17,5
        rjmp    tx
        sts     UDR0,r16
        ret

/* defineixo la rutina d'interrupció
per recepció de byte a la USART */
__vector_18:
        lds r16, UDR0
        cpi r16, ' '
        brne _v18a
        call tx
        reti
_v18a:  ldi r26, lo8(taulac2)
        ldi r27, hi8(taulac2)
_v18:   ld r17, X+
        cp r17, r16
        brne _toN
        rjmp end
_toN:   cpi r26, lo8(taulac2_fin-1)
        brlo _v18
        reti
end:    sbiw r26, LEN_TAULA+1  ; longitud de la taula (+1 per compensar el post-increment)
        ld r16, X
        call tx                 ; mostra el caràcter codificat
        reti

main:
        /* set baud rate a 9600*/
        ldi r16, 0
        sts UBRR0H,r16
        ldi r16, 103
        sts UBRR0L,r16

        /* set frame format */
        /* el valor de reset ja és correcte:
        asíncron, sense paritat, 1 stop, 8 dades,
        velocitat normal, cominicació no multiprocessor */
        /*arreglem el bit U2X0 forçant el valor de reset
        al reglistre UCSR0A*/
        ldi r16, 0b00100000
        sts UCSR0A, r16
        
        /* enable rx, tx, amb interrpció de rx */
        ldi r16, 0b10011000
        sts UCSR0B,r16

        /*habilitem interrupcions */
        sei

        /*el bucle principal no fa res*/
loop:   rjmp loop

.section .data

.include "taula8.S"

.section .bss
vegades: .byte 0
bufer: .space 32,0     /*repeteix 32 vegades, 1byte, amb valor 0. Mirar directiva .fill .skip també pot servir */

.global __do_copy_data
.global __do_clear_bss
