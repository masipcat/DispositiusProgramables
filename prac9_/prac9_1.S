.include "constants.S"

u_temps = 100 // ms
valCR1A = 250*u_temps-1
MODE_TEST = 1

.global main
.global __vector_18
.global __vector_11

.section .text

// Utiles
.macro ledOn
        sbi PORTB, 5
.endm

.macro ledOff
        cbi PORTB, 5
.endm

// Beeps
.macro so
        rcall activaBeep
.endm

.macro silenci
        rcall desactivaBeep
.endm

// Queue 
.macro resetStartQueuePointer
        ldi r29, hi8(bufer)
        ldi r28, lo8(bufer)
.endm

.macro resetEndQueuePointer
        ldi r27, hi8(bufer)
        ldi r26, lo8(bufer)
.endm

.macro resetQueue
        resetStartQueuePointer
        resetEndQueuePointer
        clr r0                          ; desem a r0 al començament de la cua
.endm

// Subrutines Queue

addToQueue:
        st X+, r16
        cpi r26, lo8(bufer_end - 1)     ; ens reservem un registre per distinjir el ple complet i el buit
        brne _aQ                        ; si no hem arribat al final...
        rcall isQueueEmpty              ; si la cua no està buida (T=0) s'ignora afegir el valor
        brtc _aQ
        resetEndQueuePointer
_aQ:    ret

popQueue:
        ld r16, Y+
        cpi r28, lo8(bufer_end)
        brne _pR
        resetStartQueuePointer
_pR:    ret

/* és una subrutina que 'retorna' T=1 o T=0 segons
   si la cua està plena o buida*/
isQueueEmpty:
        cp r26, r28
        brne _no
        cp r27, r29
        breq _si
_no:    clt
        ret
_si:    set
        ret

isQueueFull:
        /*push r26
        push r27
        sub r26, r28
        sub r27, r29
        breq _si
_no:    clt
        pop r27
        pop r26
        ret
_si:    set
        pop r27
        pop r26*/
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
        rcall addToQueue
        rcall tx
        reti

__vector_11:
        ;push r16
        ;ldi r16, 'H'
        ;rcall tx
        ;pop r16

        cpi r20, 0                      ; fer beeps "n" unitats
        breq _v111
        so
        dec r20                         ; ara s'ha de processar una unitat menys
        reti
_v111:  cpi r21, 0                      ; fer silenci "n" unitats
        breq _v112
        silenci
        dec r21
        /*brne _vEnd                      ; si encara hi ha més silencis...
        rcall process                   ; preparem el següent caràcter
        */
        reti
_v112:  silenci                         ; si no hem d'esperar, processem el següent caràcter
        rcall process                   ; processem el següent caràcter
_vEnd:  reti

process:
        cpi r17, 0                      ; si r17 > 0, hi ha un caràcter a mig processar
        brne _PnextC                    ; per tant, es crida la subrutina "morse"
        rcall isQueueEmpty              ; si no hi ha cap char a mig processar, mirem si hi ha cap char a la cua
        brts _Pend                      ; si no hi ha cap char a la cua -> ret
        rcall popQueue                  ; obtenim el char a r16
        rcall prepareChar               ; preparem el char
_PnextC:rcall morse
_Pend:  ret

prepareChar:
        mov r17, r16                    ; preparem abans de fer el morse
        andi r17, 0b111                 ; mascara per obtenir la longitud
        ret

/* rutina que activa la pota de sortida*/
punt:
        inc r20                         ; una unitat més
        inc r21
        so
        ret

ratlla:
        subi r20, -3                    ; incrementem l'estona que ha de sonar un char
        inc r21
        so
        ret

/* rutina que genera la transmissió morse a partir d'un char r16 */
morse:
        or r16, r16                     ; si r16 == 0 -> no s'ha de processar cap char
        breq _mRet
        sbrc r16, 7                     ; si b7 == 0 -> ratlla
        rjmp _mDo                       ; si b7 == 1 -> punt
        rcall punt                      ; sona el punt
        rjmp _mNext
_mDo:   rcall ratlla                    ; sona la ratlla
_mNext: rol r16
        dec r17                         ; r17 == punts/ratlles restants                      
        breq _mEnd                      ; si ja s'ha processat tot el morse, afegim dos silencis al final
        ret
_mEnd:  subi r21, -2                    ; incrementar el silenci de dues unitats
        clr r16
_mRet:  ret

activaTimer1:
        push r16
        push r17
        ldi r16, hi8(valCR1A)
        ldi r17, lo8(valCR1A)
        sts OCR1AH, r16
        sts OCR1AL, r17
        pop r17
        pop r16
        ret

configuraTimer1:
        push r16
        push r17
_confT1:ldi r16, 0b00000010             ; activem la interrupció de Ouput Compare match
        sts TIMSK1, r16
        ldi r16, 0b10000000             ; configurem el mode de comparació 10 - CTC
        sts TCCR1A, r16
        ldi r16, 0b00001011             ; configurem que clk/64
        sts TCCR1B, r16
        pop r17
        pop r16
        ret

desactivaTimer1:
        push r16
        ldi r16, 0
        sts TCCR1A, r16
        sts TCCR1B, r16
        sts TCNT1H, r16
        sts TCNT1L, r16
        sts TIMSK1, r16
        pop r16
        ret

activaBeep:
        // 16*10^6 / (2*64*(1+124))
        // prescaler N = 64
        // compare output = 124
.if MODE_TEST == 1
        //ledOn
        sbi DDRB, 3
        sbi PORTB, 3
        ret
.else
        push r16
        ldi r16, 0b00000100             ; configurem que clk/64 = 250 kHz // 011
        sts TCCR2B, r16
configuraBeep:
        ldi r16, 0b01000010             ; configurem el mode de comparació "Toggle OC2A" i TimerCounter Mode 010 (CTC)
        sts TCCR2A, r16
        ldi r16, 0b00000100             ; configurem que clk/64 = 250 kHz // 011
        sts TCCR2B, r16
        ldi r16, 0
        sts OCR2B, r16
        ldi r16, 124                    ; TOP = 125; comptem mig període d'una oscil·lació 1kHz (0.0005s)
        sts OCR2A, r16
        sbi DDRB, 3                     ; configurem el pin 11 (OC2A) com a sortida
        pop r16
        ret
.endif

desactivaBeep:
.if MODE_TEST == 1
        //ledOff
        cbi PORTB, 3
        ret
.else
        //ledOff
        sts TCCR2A, r0
        sts TCCR2B, r0
        sts TCNT2, r0                   ; clear out
        //cbi DDRB, 3                   ; pin 11 com a entrada
        //cbi PORTB, 3                  ; posem un 0 al pin 11 (OC2A)
        ret
.endif

main:
        // solve 100 = (2*N*(1+F)) / 16*10^6 where N and F are Natural

        // set baud rate a 9600
        ldi r16, 0
        sts UBRR0H,r16
        ldi r16, 103
        sts UBRR0L,r16

        // set frame format 
        // el valor de reset ja és correcte: asíncron, sense paritat, 1 stop, 8 dades, velocitat normal, cominicació no multiprocessor
        // arreglem el bit U2X0 forçant el valor de reset al reglistre UCSR0A
        ldi r16, 0b00100000
        sts UCSR0A, r16
        
        // enable rx, tx, amb interrpció de rx
        ldi r16, 0b10011000
        sts UCSR0B,r16

        // Inicialització dels registres
        clr r0                          ; r0 sempre és zero
        ldi r20, 0                      ; quants cops s'ha d'esperar el beep
        ldi r21, 0                      ; quants cops s'ha d'esperar el silenci

        rcall desactivaBeep

        sbi DDRB, 5                     ; configurem el pin 13 com a sortida
        cbi DDRD, 7                     ; configurem el pin 7 com entrada
        sbi PIND, 7                     ; pull-up pin 7

        resetQueue                      ; inicialitzem la cua

        rcall configuraTimer1

        /*sbi DDRB, 3
        sbi PORTB, 3
        nop
        nop
        cbi PORTB, 3*/

        /*habilitem interrupcions */
        sei

        ledOff
        rcall activaTimer1

        /*el bucle principal no fa res*/
loop:   
        rjmp loop

.section .data

.include "taula9.S"

.section .bss

bufer:
        .space 32, 0                    ; limited to 255
bufer_end:

.global __do_copy_data
.global __do_clear_bss
