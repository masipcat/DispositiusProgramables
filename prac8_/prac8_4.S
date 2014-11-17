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
SALTA = 0


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
        lds r16,UDR0

        cpi r16, '1'
        brne _v18n                      ; comprovem si s'ha introdüit
        ldi r26,lo8(taulac1+SALTA)
        ldi r27,hi8(taulac1)
        breq sigui
_v18n:  cpi r16, '2'
        brne _v18end
        ldi r26,lo8(taulac2+SALTA)
        ldi r27,hi8(taulac2)
sigui:
.if DEBUGAR == 1
        call tx
.endif
        ld r16, X
        call tx
_v18end:reti

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

texto:
        .ascii "Hola que tal"
texto_fin:

.section .bss
vegades: .byte 0
bufer: .space 32,0     /*repeteix 32 vegades, 1byte, amb valor 0. Mirar directiva .fill .skip també pot servir */

.global __do_copy_data
.global __do_clear_bss
