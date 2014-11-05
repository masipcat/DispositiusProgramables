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

LENGTH = 7
TOP = 0x61

.global main
.global __vector_18

.macro ledOn
	sbi PORTB_o, 5
.endm

.macro ledOff
	cbi PORTB_o, 5
.endm

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
	rjmp checkVal
w:	subi r20, 65 - 10 			; restem l'offset de 'A'
checkVal:
	cpi r20, 16
	brsh asc2valErr
	pop r9
	ret
asc2valErr:
	pop r20
	cpi r20, '+'
	brne isResta
	ret
isResta:
	cpi r20, '-'
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
	push r17
	mov r20, r16
	call asc2val
	brts SMerr 				; si el caràcter enviat [^0-9a-zA-Z+\-] -> SMerror
	call tx 				; transmetem el caràcter que s'ha introduït

	st Z, r20
	dec r30 				; decrementem l'apuntador (Z)
	ld r17, Z
	cpi r17, '\0' 				; comprovem si hem arribat al final de la seq. calculem la operació
	brne SMend
	call SMcalc
	rjmp SMreset
SMerr:	call inputErr
SMreset:ldi r30, TOP 				; reset de l'apuntador
SMend:	pop r17
	ret
SMcalc:	push r18
	lds r18, 0x60
	cpi r18, '+' 				; comprovem quina és la operació que s'ha de fer
	brne minus
	call suma
	call printResult
	rjmp Oend
minus:	cpi r18, '-'
	brne SMerr
	call resta
	call printResult
Oend:	pop r18
	ret

/* rutina de transmissió de byte,
el valor a transmetre està al registre r16 */
tx:
	push r16
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

	/* preparem la seqüència */
	/*ldi r20, '\0' 				; final de la seq.
	ldi r21, 0x68 				; 3 H
	ldi r22, 0x67				; 3 L
	ldi r23, 0x66				; 2 H
	ldi r24, 0x65 				; 2 L
	ldi r25, 0x60 				; operacio
	ldi r26, 0x64 				; 1 H
	ldi r27, 0x63 				; 1 L
	ldi r28, 0x62 				; 0 H
	ldi r29, 0x61 				; 0 L*/
	ldi r30, TOP 				; pointer reg Z

	/* habilitem interrupcions */
	sei

	ledOff

loop: 	/* el bucle principal no fa res */
	rjmp loop
	ret