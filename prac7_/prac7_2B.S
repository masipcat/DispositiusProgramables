/*parametres es guardaran a  r31 r30 r29 r28 que es la cua*/
        /*a r17 es guardaan els flags*/
        /* estat r16=0 (omple el 1r operant), r16=1 el segon*/
        /* r18=1 suma i r18=0 resta*/
        /*r19, numero de caracters introduits */
        /* r21, numero que recorre la pila*/
        /*r22,valor extret de la pila*/
        
        
.set DDRB_o, 0x04
.equ PORTB_o, 0x05
PORTD_o = 0x0B
DDRD_o = 0x0A
UDR0 = 0xC6
UBRR0H = 0XC5
UBRR0L = 0XC4
UCSR0C = 0XC2
UCSR0B = 0XC1
UCSR0A = 0XC0
SREG = 0x3F
DEBUG = 0

.global main
.global __vector_18
/* es crea una cua a la memòria de dades. Es fa push de r17 */
pushStack:
        st Y+, r20              ; posa a la pila r20
        ret

/* retorna el primer valor de la cua a r17 */
popStack:
        ld r20, -Y
        cpi r28, 0
        brne _popEnd
        set
_popEnd:ret

/* fa un reset de la cua */
resetStack:
        ldi r28, 0x0
        ldi r29, 0x1
        clt
        ret

suma:   /*S=0*/
        add r0,r2
        adc r1,r3
        in r17,SREG
        ret

resta:
        push r16
        push r28
        push r29
        clc                     ; fem un clear del carry
        ldi r29, 0
        ldi r28, 2              ; r2 -> r3
_RLoop: ld r16, Y               ; rN
        brcs _Rnot              ; C=1 -> NOT(r16) [com r16]
        neg r16                 ; es mira el carry del de menys pes. Si C=0 (borrow=1) -> A2 del següent. Si C=1 -> Negat
        rjmp _Rst
_Rnot:  com r16
_Rst:   st Y+, r16              ; resultat a rN
        cpi r28, 4
        brlo _RLoop
        rcall suma
        pop r29
        pop r28
        pop r16
        ret

resta_b:
        sub r0,r2
        sbc r1,r3
        in r17, SREG
        ret

/* es mostren els flags */
showFlags:
        push r17
        push r20
        ldi r20, ' '
        call tx
        cpi r18, 0                    ; si es fa la operació resta, mostra el borrow
        breq _SFborr
        ldi r20, 'C'
        call tx
        ldi r20, ':'
        call tx
        ldi r20, '0'
        sbrc r17, 0
        ldi r20, '1'
        call tx
        rjmp _SFsign
_SFborr:ldi r20, 'B'                    ; B = Not(C)
        call tx
        ldi r20, ':'
        call tx
        ldi r20, '1'
        sbrc r17, 0
        ldi r20, '0'
        call tx
_SFsign:ldi r20, ' '
        call tx
        ldi r20, 'S'
        call tx
        ldi r20, ':'
        call tx
        ldi r20, '0'
        sbrc r17, 4
        ldi r20, '1'
        call tx
        ldi r20, ' '
        call tx
        pop r20
        pop r17
        ret
        
/*Rutina de transmissio de bytes, el valor a transmetre esta al registre r20 */ 
tx:     push r17
tx1:    lds r17, UCSR0A
        sbrs r17, 5
        rjmp tx1
        sts UDR0, r20
        pop r17
        ret
txt:    rcall val2asc
        rcall tx
        ret

/* converteix un valor enter a un caràcter que
   representa el número en hexadecimal */
val2asc:
        cpi r20, 16
        brsh valErr             ; si l'enter és >= 16 -> valErr
        cpi r20, 10             ; si l'enter és >= 10 -> lletra
        brsh w2
        subi r20, -48           ; r20 + 48
        rjmp endVal
w2:     subi r20, -65 + 10      ; r20 + 55
        rjmp endVal
valErr: ldi r20, '_'            ; caràcter per mostrar l'error
        set                     ; el flag T s'utilitza com a flag d'error
endVal: ret


/* converteix un caràcter que representa un
   número hexadecimal a un enter */
asc2val:
        cpi r20, '0'
        brlo _a2vErr
        cpi r20, 'a'
        brlo _a2vUp             ; si el caràcter introduit és < 'a'
        subi r20, 32            ; uppercase
_a2vUp: cpi r20, 'A'            ; si r16 >= 'A', salta:
        brsh _a2vOff
        cpi r20, ':'            ; si el valor no està entre ['0', ':')
        brsh _a2vErr
        subi r20, 48            ; restem l'offset de '0'
        rjmp _a2vChk
_a2vOff:subi r20, 65 - 10       ; restem l'offset de 'A'
_a2vChk:cpi r20, 16
        brsh _a2vErr
        ret
_a2vErr:set                     ; el flag T s'utilitza com a flag d'error
        ldi r20, 0xFF           ; caràcter d'error
        ret
        
/* subrutina reset */
reset:  rcall tx
reset2: ldi r20, '\r'
        rcall tx
        ldi r20, '\n'
        rcall tx
        ldi r16,0       /*omplir el primer operant*/
reset3: ldi r21,0       /*num caracter restaurat*/
        rcall resetStack
        ret
        
pri_op: rcall tx
        cpi r20,'+'
        breq prep_1op_sumo
        cpi r20,'-'
        breq prep_1op_resto
        rcall asc2val
        call pushStack
        reti

.macro print tot
        push r19        /*Proces de representar el resultat*/
        push r20
        push r21
        push \tot
        ldi r19,0b11110000      /*Masqueres per trobar els bits de major i menor posicio*/
        ldi r21,0b00001111
        push \tot
        and \tot,r19
        swap \tot
        mov r20,\tot
        rcall txt
        pop \tot
        and \tot,r21
        mov r20,\tot
        rcall txt
        pop \tot
        pop r21
        pop r20
        pop r19
.endm
        
.macro regs_zero re0 re1
        clr \re0
        clr \re1
.endm

prep_1op_resto:
        ldi r18,0
        rjmp prep_1op
prep_1op_sumo:
        ldi r18,1
        rjmp prep_1op
prep_1op:
        regs_zero r0 r1
comp:   brts se_fini
        rcall posa_numeros
        inc r21
seg:    rjmp comp
se_fini:
        rcall reset3
        ldi r16,1
        rcall resetStack
        reti

.macro parell r
        add \r,r20
.endm

.macro senar r
        swap r20
        add \r,r20
.endm

posa_numeros:
        call popStack
        
        cpi r21,0
        brne _PN1
        parell r0
        ret
        
_PN1:   cpi r21,1
        brne _PN2
        senar r0
        ret
        
_PN2:   cpi r21,2
        brne _PN3
        parell r1
        ret
        
_PN3:   senar r1
        ret

seg_op:
        rcall tx
        cpi r20,'='
        brne __n
        rcall prep_2op
        rcall resultat
        reti
__n:    rcall asc2val
        rcall pushStack
        reti

sumab:  rcall suma
        ret
restab: rcall resta
        ret 

prep_2op:
        regs_zero r2 r3
_comp:  brts _se_fini
        rcall posa_numeros2
        inc r21
        rjmp _comp
_se_fini:
        ldi r16, 0
        ret     

posa_numeros2:
        call popStack
        cpi r21,0
        brne _PN1_2
        parell r2
        ret
        
_PN1_2: cpi r21,1
        brne _PN2_2
        senar r2
        ret
        
_PN2_2: cpi r21,2
        brne _PN3_2
        parell r3
        ret
        
_PN3_2: senar r3
        ret
        
resultat:
        cpi r18, 1
        breq __suma
        rcall restab
        rcall showFlags
        rcall printa_tot
        rcall reset2
        ret
__suma: rcall sumab
        rcall showFlags
        rcall printa_tot
        rcall reset2
        ret

printa_tot:
        print r1
        print r0
        ret

printa_tot2:
.if DEBUG == 1
        print r2
        print r3
.endif
        ret
                
__vector_18:    
        lds r20, UDR0
        cpi r20, 'r'    /*Estat de reset, primera prioritat*/
        breq resete
        cpi r16,0
        breq pri_o      /* Si r16=0 vol dir que esta enviant el 1r operant*/    
        rjmp seg_o      /* Si r16=1 vol dir que esta enviant el 2r operant*/
pri_o:  rjmp pri_op
seg_o:  rjmp seg_op
resete: rcall reset
        reti
        
main:   
        /*set baud rate at 9600*/
        ldi r16, 0
        sts UBRR0H, r16
        ldi r16, 103
        sts UBRR0L, r16
        /*set frame format*/
        ldi r16, 0b00100000
        sts UCSR0A, r16
        ldi r16, 0b00000110
        sts UCSR0C, r16
        /*enable rx, tx, amb interrupcions*/
        ldi r16, 0b10011000
        sts UCSR0B, r16
        /*configuracio dels pins*/
        ldi r16, 0b00000010
        out DDRB_o, r16

        /* reset */
        ldi r16, 0
        ldi r21, 0
        rcall resetStack
        
        sei

loop:   rjmp loop
        ret