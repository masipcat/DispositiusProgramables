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

LEN_TAULA = taulac1_fin - taulac1

.global main
.global __vector_18

.section .text

xifrar:
        cpi r16, ' '
        brne _v18a
        call tx
        ret
_v18a:  cpi r16, 0x5b
        brlo _v18n
        subi r16, 0x20          ; majúscules -> minúscules
_v18n:  ldi r26, lo8(taulac1)
        ldi r27, hi8(taulac1)
_v18:   ld r17, X+
        cp r17, r16
        brne _toN
        rjmp end
_toN:   cpi r26, LEN_TAULA      ; longitud taulac1
        brne _v18
        ret
end:    adiw r26, LEN_TAULA-1   ; longitud de la taula (-1 per compensar el post-increment)
        ld r16, X
        call tx                 ; mostra el caràcter codificat
        ret

desxifrar:
        cpi r16, ' '
        brne _v18da
        call tx
        ret
_v18da: ldi r26, lo8(taulac2)
        ldi r27, hi8(taulac2)
_v18d:  ld r17, X+
        cp r17, r16
        brne _toNd
        rjmp _end
_toNd:  cpi r26, lo8(taulac2_fin-1)  ; longitud taulac2
        brne _v18d
        ret
_end:   sbiw r26, LEN_TAULA+1     ; longitud de la taula (+1 per compensar el post-increment)
        ld r16, X
        call tx                   ; mostra el caràcter codificat
        ret

/* rutina de transmissió de byte,
el valor a transmetre està al registre r16 */
tx:
        lds r17,UCSR0A 
        sbrs r17,5
        rjmp tx
        sts UDR0,r16
        ret

.macro print txt_addr
        ldi r28, lo8(\txt_addr)
        ldi r29, hi8(\txt_addr)
1:      ld r16, Y+
        cpi r16, 0             ; null char
        breq 2f                ; salt a la següent instruccio després de la macro
        call tx
        rjmp 1b
2:
.endm

setModeKey:
        cpi r16, '0'
        brne _chk
        ldi r22, 0              ; definim el mode
        print txt_xifrar
        set
        ret
_chk:   cpi r16, '9'
        brne _do
        ldi r22, 1              ; definim el mode
        print txt_desxifrar
        set                     ; T = 1 indica que s'ha configurat el mode
        ret
_do:    clt
        ret
        
doAction:
        cpi r22, 0              ; 0 -> xifrar
        breq _ciph              ; 1 -> desxifrar
        rcall desxifrar
        ret
_ciph:  rcall xifrar
        ret

/* defineixo la rutina d'interrupció
per recepció de byte a la USART */
__vector_18:
        lds r16,UDR0
        rcall setModeKey
        brts __ev18             ; T = 1 indica que s'ha configurat el mode i no es xifra/desxifra l'entrada
        rcall doAction
__ev18: reti

main:
        /* set baud rate a 9600*/
        ldi r16, 0
        sts UBRR0H,r16
        ldi r16, 103
        sts UBRR0L,r16

        /* set frame format */
        /* el valor de reset ja és correcte: asíncron, sense paritat, 1 stop, 8 dades,
        velocitat normal, cominicació no multiprocessor */
        /*arreglem el bit U2X0 forçant el valor de reset
        al reglistre UCSR0A*/
        ldi r16, 0b00100000
        sts UCSR0A, r16
        
        /* enable rx, tx, amb interrpció de rx */
        ldi r16, 0b10011000
        sts UCSR0B,r16

        ldi r16, '0'
        call __vector_18

        /*habilitem interrupcions */
        sei

        /*el bucle principal no fa res*/
loop:   rjmp loop

.section .data

.include "taula8.S"

txt_xifrar:  .asciz "Mode xifrar\r\n"
txt_desxifrar:  .asciz "Mode desxifrar\r\n"

.global __do_copy_data