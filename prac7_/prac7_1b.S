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

TOP = 25

.global main
.global __vector_18

.macro ledOn
	sbi PORTB_o, 5
.endm

.macro ledOff
	cbi PORTB_o, 5
.endm

/* R30: Low
   R31: Hight
   Es crea una pila a la memòria de dades. Es fa push de r17 */
pushStack1:
	// Y = r28:29
	//     Low:Hig
	// S'utilitza r29 per desar el "bottom" de la pila (s'usarà per fer el pop com un cua)
	push r17
	push r29
	ldi r29, 0x1
	st Y+, r17
	ldi r17, 0xFF 			; 0xFF = delimitador
	st Y, r17 			; final de la pila
	pop r29
	pop r17
	ret

/* retorna el primer valor de la pila a r17 */
popStack1:
	push r28
	push r29
	mov r28, r29 			; movem el començament del bottom
	ldi r29, 0x1
	ld r17, Y+
	mov r29, r28 			; ++bottom
	pop r28 			; ignorem el valor anterior de r29
	pop r28
	ret

/* es crea una pila a la memòria de dades. Es fa push de r17 */
pushStack2:
	// Z = r30:31
	//     Low:Hig
	// S'utilitza r31 per desar el "bottom" de la pila (s'usarà per fer el pop com un cua)
	push r17
	push r31
	ldi r31, 0x1
	st Y+, r17
	ldi r17, 0xFF 			; 0xFF = delimitador
	st Y, r17 			; final de la pila
	pop r31
	pop r17
	ret

/* retorna el primer valor de la pila a r17 */
popStack2:
	push r30
	push r31
	mov r30, r31 			; movem el començament del bottom
	ldi r31, 0x1
	ld r17, Y+
	mov r31, r30 			; ++bottom
	pop r31 			; ignorem el valor anterior de r31
	pop r30
	ret

/* suma tots els registres que es troben des del que es troba a 'Z' fins a trobar un '\0' */
suma:
	ledOn
	push r22
	ldi r24, 0 				; temp reg
	ldi r23, 0
	ldi r31, 0x61
_sloop:	ld r22, Z+
	cpi r22, '+'
	breq _esuma 				; mentre no arribi al final
	cpi r23, 1 				;
	breq _sadd
	swap r22 
	mov r24, r22				;
	rjmp _sloop
_sadd:	eor r24, r22
	st Y, r24
	rjmp _sloop
_esuma:	add r0, r2 				; suma del primer byte
	adc r1, r3 				; suma del segon byte
	pop r22
	ret

resta:
	/*neg r2
	neg r3 					; fem el complement A2 del segon byte
	subi r3, 1 				; restem l'1 que s'ha sumat al fer el complement A2
	rcall suma*/
	sub r0, r2
	sbc r1, r3
	ret

/* converteix un caràcter que representa un
   número hexadecimal a un enter */
asc2val:
	push r20
	cpi r20, 'a'
	brlo t 					; si el caràcter introduit és < 'a'
	subi r20, 32 				; lowercase -> uppercase
t:	cpi r20, 'A' 				; si r20 >= 'A', salta:
	brsh w
	subi r20, 48 				; restem l'offset de '0'
	rjmp a2vCheck
w:	subi r20, 65 - 10 			; restem l'offset de 'A'
a2vCheck:
	cpi r20, 16
	brsh a2vErr
	pop r9
	ret
a2vErr:	pop r20
	cpi r20, '+'
	brne isResta
	ret
isResta:cpi r20, '-'
	breq endAsc
	set 					; el flag T s'utilitza com a flag d'error
	ldi r20, 0
endAsc:	ret

/* converteix un valor enter a un caràcter que
   representa el número en hexadecimal */
val2asc:
	cpi r20, 16
	brsh valErr 				; si l'enter és >= 16 -> valErr
	cpi r20, 10 				; si l'enter és >= 10 -> lletra
	brsh w2
	subi r20, -48
	ret
w2:	subi r20, -65 + 10
	ret
valErr:	cpi r20, '+'
	breq endVal
	cpi r20, '-'
	breq endVal 				; si els caràcters són diferents de +/-
	set 					; el flag T s'utilitza com a flag d'error
endVal:	ret

/* Màquina d'estats */
stateMachine:
	cpi r16, '=' 				; comprovem si hem de fer la operació
	breq SMcalc


	mov r20, r16
	call asc2val
	brts SMerr 				; si el caràcter enviat [^0-9a-zA-Z+\-] (T = 1) -> SMerror
	call tx 				; transmetem el caràcter que s'ha introduït
	call pushStack1

	rjmp Oend
	//call SMcalc
	//rjmp SMreset

SMerr:	call inputErr
SMreset:ldi r30, TOP 				; reset de l'apuntador
SMend:	ret
SMcalc:	lds r18, 0x60
	cpi r18, '+' 				; comprovem quina és la operació que s'ha de fer
	brne minus
	call suma
	call printResult
	rjmp Oend
minus:	cpi r18, '-'
	brne SMerr
	call resta
	call printResult
Oend:	ret

/* rutina de transmissió de byte,
el valor a transmetre està al registre r16 */
tx:	push r16
	push r17
__tx:	lds r17, UCSR0A
	sbrs r17, 5
	rjmp __tx
	sts UDR0, r16
	pop r17
	pop r16
	ret

/* transmetem el resultat de r1:r0 */
printResult:
	ldi r16, '='
	call tx
	mov r20, r0
	call val2asc
	mov r16, r20
	call tx
	mov r20, r1
	call val2asc
	mov r16, r20
	call tx
	ret

inputErr:
	clt 					; es desactiva el flag d'error (T)
	push r16
	ldi r16, ' '
	call tx
	ldi r16, 'E'
	call tx
	ldi r16, 'R'
	call tx
	ldi r16, 'R'
	call tx
	ldi r16, '\r'
	call tx
	ldi r16, '\n'
	call tx
	pop r16
	ret

/* defineixo la rutina d'interrupció
per recepció de byte a la USART */
__vector_18:
	lds r16, UDR0
	call stateMachine
	reti

main:
	/* set baud rate a 9600 */
	ldi r16, 0
	sts UBRR0H,r16
	ldi r16, 103
	sts UBRR0L,r16

	sbi DDRB_o, 5 				; configuració del LED

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
	
	/* configuració dels pins, és possible que no calgui*/
	ldi r16, 0b00000010
	out DDRD_o, r16

	/* habilitem interrupcions */
	sei

	/* set-up custom stacks/queues */
	ldi r28, 0x0 				; stack1
	ldi r29, 0x1 				; Y = 0x100
	ldi r30, 0x0 				; stack2
	ldi r31, 0x2 				; Z = 0x200
	ldi r17, 0xFF
	call pushStack1
	ldi r17, 0xFF
	call pushStack2

	ledOff

loop: 	/* el bucle principal no fa res */
	rjmp loop
	ret