.set DDRB_o, 0x4
.equ PORTB_o, 0x5
PORTD_o = 0x0b
DDRD_o = 0x0a

UDR0   = 0xC6
UBRR0H = 0xC5
UBRR0L = 0xC4
UCSR0C = 0xC2
UCSR0B = 0xC1
UCSR0A = 0xC0

SREG = 0x5F
PREC = 8                        ; Bytes

.global main
.global __vector_18

.macro ledOn
        sbi PORTB_o, 5
.endm

.macro ledOff
        cbi PORTB_o, 5
.endm

/* es crea una cua a la memòria de dades. Es fa push de r17 */
pushQueue:
        // Y = r29:28
        //       H:L
        // S'utilitza r29 per desar el "bottom" de la cua (s'usarà per fer el pop com un cua)
        push r17
        push r29
        ldi r29, 0x1            ; 0x01-- SRAM
        st Y+, r17
        ldi r17, 0xFF           ; 0xFF = delimitador
        st Y, r17               ; final de la cua
        pop r29 
        pop r17
        ret

/* retorna el primer valor de la cua a r17 */
popQueue:
        push r28
        mov r28, r29            ; movem el començament del bottom a r28
        ldi r29, 0x1
        ld r17, Y+
        mov r29, r28            ; ++bottom
        pop r28
        ret

resetQueue:
        push r16
        push r17
        ldi r28, 0x0
        ldi r29, 0x0
        ldi r16, PREC
        ldi r17, 0              ; valor que afegim al fer push
_RQpush:rcall pushQueue
        rcall pushQueue
        dec r16
        cpi r16, 0
        brne _RQpush
        pop r17
        pop r16
        ret

/* buida la cua des del registre indicat a r30 'n' vegades,
  inidcant la 'n' al registre r31 */
queue2reg:
        push r16
        push r20
        mov r20, r27            ; r27 trobem a quants registres s'han d'omplir
        dec r20
        inc r26                 ; compensem el pre-decrement (st -X)
        ldi r27, 0              ; ld reg -> 0x00-- (on -- és el valor de r16)
_q2r:   call popQueue
        mov r16, r17
        swap r16                ; half-byte de mes pes
        call popQueue
        eor r16, r17
        st -X, r16
        dec r20                 ; decrementem els registres restants
        cpi r20, 0
        brge _q2r               ; branch if r20 >= 0
        pop r20
        pop r16
        ret

/* converteix un caràcter que representa un
   número hexadecimal a un enter */
asc2val:
        cpi r16, 'a'
        brlo t                  ; si el caràcter introduit és < 'a'
        subi r16, 32            ; lowercase -> uppercase
t:      cpi r16, 'A'            ; si r16 >= 'A', salta:
        brsh w
        subi r16, 48            ; restem l'offset de '0'
        rjmp chkVal
w:      subi r16, 65 - 10       ; restem l'offset de 'A'
chkVal: cpi r16, 16
        brsh a2vErr
        ret
a2vErr: set                     ; el flag T s'utilitza com a flag d'error
        ldi r16, 0xFF           ; error
        ret

/* converteix un valor enter a un caràcter que
   representa el número en hexadecimal */
val2asc:
        push r16
        cpi r16, 16
        brsh valErr             ; si l'enter és >= 16 -> valErr
        cpi r16, 10             ; si l'enter és >= 10 -> lletra
        brsh w2
        subi r16, -48
        rjmp endVal
w2:     subi r16, -65 + 10
        rjmp endVal
valErr: pop r16
        set                     ; el flag T s'utilitza com a flag d'error
        ret
endVal: pop r15                 ; Queue -> r15 (volem ignorar el valor de la cua)
        ret

/* suma d'N registres */
suma:   push r16
        push r17
        push r18
        push r28
        push r29
        push r30

        rcall resetFlags

        ldi r29, 0
        ldi r28, 0
        ldi r30, PREC
_SLoop: ld r16, Y               ; rN
        push r28

        add r28, r30            ; rN + PREC. p.e.(PREC=8): r0 + r8
        ld r17, Y
        pop r28

        ;adc r16, r17
        add r16, r17
        st Y+, r16              ; resultat a rN

        brcc _SCC               ; si C=1 -> rN+1 = 1
        ld r16, Y
        inc r16
        st Y, r16

        clc                     ; clear carry

_SCC:   cpi r28, PREC
        brne _SLoop

        pop r30
        pop r29
        pop r28
        pop r18
        pop r17
        pop r16
        ret

/* resta d'N registres */
resta:  push r16
        push r28
        push r29
        rcall resetFlags
        ldi r29, 0
        ldi r28, PREC           ; rN -> rN+PREC
_RLoop: ld r16, Y               ; rN
        brcs _Rnot              ; C=1 -> NOT(r16) [com r16]
        neg r16                 ; mires el carry del de menys pes. Si C=0 (borrow=1) -> A2 del següent. Si C=1 -> Negat
        rjmp _Rst
_Rnot:  com r16
_Rst:   st Y+, r16              ; resultat a rN
        cpi r28, PREC * 2
        brne _RLoop

        pop r29
        pop r28
        pop r16
        rcall suma
        ret

/* mostra el resultat */
showResult:
        push r16
        push r17
        push r18
        push r28
        push r29

        ldi r16, ' '
        call tx
        ldi r16, '='
        call tx

        rcall showFlags

        ldi r29, 0
        ldi r28, PREC
_SRrec: ld r18, -Y
        ldi r17, 0b11110000     ; mask
        mov r16, r18
        and r16, r17
        swap r16
        call val2asc
        call tx
        swap r17
        mov r16, r18
        and r16, r17
        call val2asc
        call tx
        cpi r28, 0
        brne _SRrec
        pop r29
        pop r28
        pop r18
        pop r17
        pop r16
        ret

/* es mostren els flags */
showFlags:
        push r16
        push r17
        push r30
        push r31
        ldi r30, SREG 
        ldi r31, 0
        ld r17, Z
        ldi r16, ' '
        call tx
        cpi r24, '-'
        breq _SFborr
        ldi r16, 'C'
        call tx
        ldi r16, ':'
        call tx
        ldi r16, '0'
        sbrc r17, 0
        ldi r16, '1'
        call tx
        rjmp _SFsign
_SFborr:ldi r16, 'B'                    ; B = Not(C)
        call tx
        ldi r16, ':'
        call tx
        ldi r16, '1'
        sbrc r17, 0
        ldi r16, '0'
        call tx
_SFsign:ldi r16, ' '
        call tx
        ldi r16, 'S'
        call tx
        ldi r16, ':'
        call tx
        ldi r16, '0'
        sbrc r17, 4
        ldi r16, '1'
        call tx
        ldi r16, ' '
        call tx
        pop r31
        pop r30
        pop r17
        pop r16
        ret

/* Màquina d'estats */
stateMachine:
        ledOff
        cpi r16, 'r'
        breq SMreset
        cpi r16, '='
        breq SMshow
        cpi r16, '\r'           ; si es clica el Return es fa la operació
        breq SMshow
        cpi r16, '+'
        breq SMop
        cpi r16, '-'
        breq SMop

        push r16
        call asc2val            ; comprovem si s'ha introduit un caràcter valid
        brts SMerr              ; si el caràcter enviat [^0-9a-zA-Z+\-] -> SMerror
        mov r17, r16
        call pushQueue
        inc r25                 ; comptador de numeros a l'Queue
        pop r16 

        call tx                 ; mostra el caràcter introduït
        ret
SMop:   add r29, r25            ; mou el punter per apuntar als 'n' primers zeros a l'esquerra
        ldi r25, 0              ; reset del comptador de numeros de l'Queue
        ldi r26, PREC-1         ; començar a omplir el r1
        ldi r27, PREC   ; omplir 2 registres -> r1:0
        call queue2reg
        call resetQueue
        mov r24, r16            ; el registre r24 s'utilitza per desar quin el signe de la operació
        call tx
        ret
SMshow: add r29, r25            ; mou el punter per apuntar als 'n' primers zeros a l'esquerra
        ldi r26, (PREC-1)*2+1   ; començar a omplir el r3
        ldi r27, PREC           ; omplir 2 registres -> r3:2
        rcall queue2reg
        cpi r24, '+'
        brne SMresta
        rcall suma
        rjmp SMres
SMresta:rcall resta
SMres:  rcall showResult
        rjmp SMreset
SMerr:  ledOn
        clt
        ret
SMreset:ldi r16, '\n'
        call tx
        ldi r16, '\r'
        call tx
        rcall mainReset
        ret

/* rutina de transmissió de byte,
el valor a transmetre està al registre r16 */
tx:     push r17
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
        call stateMachine
        reti

/* set-up custom Queue */
mainReset:
        ldi r28, (PREC * 2) - 1
        ldi r29, 0
_MRclr: st Y, r29               ; resultat a rN
        dec r28
        cpi r28, 0
        brne _MRclr

        call resetQueue         ; la cua comença a la posició "1". A la posició "0" es guarda la longitud
        ldi r25, 0              ; comptadors de caràcters introduïts
        ldi r24, 0              ; es desa quina és la opearació que s'ha de fer quan es rep '='
        clt                     ; es desactiva el flag d'error (T)
        rcall resetFlags
        ret

/* fa un reset de tots els flags relacionats amb la ALU */
resetFlags:
        clc
        cln
        clz
        cls
        ret

main:   /* configuració dels pins, és possible que no calgui*/
        ldi r16, 0b00000010
        out DDRD_o, r16

        /* set baud rate a 9600 */
        ldi r16, 0
        sts UBRR0H,r16
        ldi r16, 103
        sts UBRR0L,r16

        sbi DDRB_o, 5                           ; configuració del LED

        /* set frame format */
        /* el valor de reset ja és correcte: asíncron, sense paritat, 1 stop, 8 dades,
        velocitat normal, cominicació no multiprocessor */
        /* assegurem el que volem encara que en reset ja ho sigui */
        ldi r16, 0b00100000
        sts UCSR0A, r16

        ldi r16, 0b00000110
        sts UCSR0C, r16
        
        /* enable rx, tx, amb interrpció de rx */
        ldi r16, 0b10011000
        sts UCSR0B, r16

        rcall mainReset

        /* habilitem interrupcions */
        sei
        ledOff

loop:   /* el bucle principal no fa res */
        rjmp loop
        ret