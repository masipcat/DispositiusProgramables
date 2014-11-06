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

/* es crea una pila a la memòria de dades. Es fa push de r17 */
pushStack1:
	// Y = r29:28
	//       H:L
	// S'utilitza r29 per desar el "bottom" de la pila (s'usarà per fer el pop com un cua)
	push r17
	push r29
	ldi r29, 0x1 		; 0x01-- SRAM
	st Y+, r17
	ldi r17, 0xFF 		; 0xFF = delimitador
	st Y, r17 		; final de la pila
	pop r29	
	pop r17
	ret

/* retorna el primer valor de la pila a r17 */
popStack1:
	push r28
	mov r28, r29 		; movem el començament del bottom
	ldi r29, 0x1
	ld r17, Y+
	mov r29, r28 		; ++bottom
	pop r28
	ret

resetStack1:
	ldi r28, 0x0
	ldi r29, 0x0
	ldi r17, 0 		; afegim 4 zeros al començament
	call pushStack1
	call pushStack1
	call pushStack1
	call pushStack1
	ret

/* buida la pila des del registre indicat a r30 'n' vegades,
  inidcant la 'n' al registre r31 */
stackToReg:
	push r16
	push r20

	mov r20, r27 		; r27 trobem a quants registres s'han d'omplir
	;mov r27, r26
	;mov r26, r27
	;inc r26 		; compensar el -X del 'ld'
	dec r20
	inc r26
	ldi r27, 0 		; ld reg -> 0x00-- (on -- és el valor de r16)

	// DEBUG
	/*ldi r16, '/'
	call tx
	mov r16, r20
	subi r16, -48
	call tx
	ldi r16, '/'
	call tx*/
	// END DEBUG

	/*ldi r16, '['
	call tx
	call popStack1
	mov r16, r17
	swap r16
	call val2asc
	call tx
	call popStack1
	eor r16, r17
	call val2asc
	call tx
	call popStack1
	mov r16, r17
	swap r16
	call val2asc
	call tx
	call popStack1
	eor r16, r17
	call val2asc
	call tx
	ldi r16, ']'
	call tx
	rjmp _eeend*/

_s2r:	
	// DEBUG
	/*ldi r16, '('
	call tx
	ldi r16, 'r'
	call tx
	mov r16, r27
	subi r16, -48
	call tx
	mov r16, r26
	subi r16, -48
	call tx
	ldi r16, ')'
	call tx*/
	// END DEBUG

	call popStack1
	mov r16, r17
	swap r16
	call popStack1
	eor r16, r17

	st -X, r16
	dec r20 		; decrementem els registres restants
	cpi r20, 0
	brge _s2r 		; branch if r20 >= 0

	// DEBUG
	/*mov r16, r0
	cpi r16, 0x10
	brne _eeend
	ledOn*/
	// END-DEBUG

_eeend:	pop r20
	pop r16
	ret

/* converteix un caràcter que representa un
   número hexadecimal a un enter */
asc2val:
	cpi r16, 'a'
	brlo t 			; si el caràcter introduit és < 'a'
	subi r16, 32 		; lowercase -> uppercase
t:	cpi r16, 'A' 		; si r16 >= 'A', salta:
	brsh w
	subi r16, 48 		; restem l'offset de '0'
	rjmp chkVal
w:	subi r16, 65 - 10 	; restem l'offset de 'A'
chkVal:	cpi r16, 16
	brsh a2vErr
	ret
a2vErr:	cpi r16, '+'
	brne isRest
	ret
isRest:	cpi r16, '-'
	breq endAsc
	set 			; el flag T s'utilitza com a flag d'error
	ldi r16, 0xFF 		; error
endAsc:	ret

/* converteix un valor enter a un caràcter que
   representa el número en hexadecimal */
val2asc:
	push r16
	cpi r16, 16
	brsh valErr 		; si l'enter és >= 16 -> valErr
	cpi r16, 10 		; si l'enter és >= 10 -> lletra
	brsh w2
	subi r16, -48
	rjmp endVal
w2:	subi r16, -65 + 10
	rjmp endVal
valErr:	pop r16
	set 			; el flag T s'utilitza com a flag d'error
	ret
endVal:	pop r15 		; stack -> r15 (volem ignorar el valor de la pila)
	ret

/* suma de dos registres */
suma:
	add r0, r2
	adc r1, r3

__next:	ldi r16, '='
	call tx

	brcc __nas 		; si el carry = 0 -> salta a __nas
	ldi r16, '1' 		; si no, el mostra per pantalla
	call tx

	// r1
__nas:	ldi r17, 0b11110000 	; mask
	mov r16, r1
	and r16, r17
	swap r16
	call val2asc
	call tx
	swap r17
	mov r16, r1
	and r16, r17
	call val2asc
	call tx

	// r0
	ldi r17, 0b11110000 	; mask
	mov r16, r0
	and r16, r17
	swap r16
	call val2asc
	call tx
	swap r17
	mov r16, r0
	and r16, r17
	call val2asc
	call tx

	/*ldi r16, ':'
	call tx

	// DEBUG:

	// r3
	ldi r17, 0b11110000 	; mask
	mov r16, r3
	and r16, r17
	swap r16
	call val2asc
	call tx
	swap r17
	mov r16, r3
	and r16, r17
	call val2asc
	call tx

	// r2
	ldi r17, 0b11110000 	; mask
	mov r16, r2
	and r16, r17
	swap r16
	call val2asc
	call tx
	swap r17
	mov r16, r2
	and r16, r17
	call val2asc
	call tx

	// END-debug*/

	// Falta implmenetar el Carry

	ret

resta:
	/*neg r2
	neg r3 			; fem el complement A2 del segon byte
	subi r3, 1 		; restem l'1 que s'ha sumat al fer el complement A2
	rcall suma*/
	sub r0, r2
	sbc r1, r3
	ret

/* Màquina d'estats */
stateMachine:
	ledOff
	cpi r16, 'r'
	breq SMreset
	cpi r16, '='
	breq SMshow
	cpi r16, '+'
	breq SMop
	cpi r16, '-'
	breq SMop

	push r16
	call asc2val 		; comprovem si s'ha introduit un caràcter valid
	brts SMerr 		; si el caràcter enviat [^0-9a-zA-Z+\-] -> SMerror
	
	mov r17, r16
	call pushStack1
	inc r25 		; comptador de numeros a l'stack
	
	pop r16 
	call tx
	ret
SMshow: add r29, r25 		; mou el punter per apuntar als 'n' primers zeros a l'esquerra
	ldi r26, 3 		; començar a omplir el r3
	ldi r27, 2 		; omplir 2 registres -> r3:2
	call stackToReg
	cpi r24, '+'
	brne SMresta
	call suma
	rjmp SMreset
SMresta:call resta
	rjmp SMreset
SMop:	add r29, r25 		; mou el punter per apuntar als 'n' primers zeros a l'esquerra
	ldi r25, 0 		; reset del comptador de numeros de l'stack
	ldi r26, 1 		; començar a omplir el r1
	ldi r27, 2 		; omplir 2 registres -> r1:0
	call stackToReg
	call resetStack1
	mov r24, r16 		; el registre r24 s'utilitza per desar quin el signe de la operació
	call tx
	ret
SMerr:	ledOn
	clt
	ret
SMreset:ldi r16, '\n'
	call tx
	ldi r16, '\r'
	call tx
	rcall mainReset

/* rutina de transmissió de byte,
el valor a transmetre està al registre r16 */
tx:	push r17
__tx:	lds r17, UCSR0A
	sbrs r17, 5
	rjmp __tx
	sts UDR0, r16
	pop r17
	ret

/* defineixo la rutina d'interrupció
per recepció de byte a la USART */
__vector_18:
	lds r16, UDR0
	call stateMachine
	reti

mainReset:
	/* set-up custom stacks/queues */
	// la pila comença a la posició "1". A la posició "0" es guarda la longitud
	call resetStack1

	ldi r25, 0 		; comptadors de caràcters introduïts
	
	/*ldi r26, 0
	ldi r27, 0*/

	/* es desa quina és la opearació que s'ha de fer quan es rep '=' */
	ldi r24, 0
	clt 			; es desactiva el flag d'error (T)
	ret

main:	/* configuració dels pins, és possible que no calgui*/
	ldi r16, 0b00000010
	out DDRD_o, r16

	ledOn

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

	/* habilitem interrupcions */
	sei

	rcall mainReset
	
	ledOff

loop: 	/* el bucle principal no fa res */
	rjmp loop
	ret