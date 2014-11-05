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

.global main
.global __vector_18

/* rutina de transmissió de byte,
el valor a transmetre està al registre r16 */
tx:
	lds r17,UCSR0A
	sbrs r17, 5
	rjmp tx
	sts	UDR0,r16
	ret

/* defineixo la rutina d'interrupció
per recepció de byte a la USART */
__vector_18:
	lds	r16, UDR0
	call tx
	reti

main:
	/* set baud rate a 9600 */
	ldi	r16, 0
	sts	UBRR0H,r16
	ldi	r16, 103
	sts	UBRR0L,r16

	/* set frame format */
	/* el valor de reset ja és correcte:
	asíncron, sense paritat, 1 stop, 8 dades,
	velocitat normal, cominicació no multiprocessor */
	/*assegurem el que volem encara que en reset ja ho sigui*/
	ldi	r16, 0b00100000
	sts	UCSR0A, r16

	ldi	r16, 0b00000110
	sts	UCSR0C, r16
	
	/* enable rx, tx, amb interrpció de rx */
	ldi r16, 0b10011000
	sts	UCSR0B,r16
	
	/* configuració dels pins, és possible que no calgui*/
	ldi	r16, 0b00000010
	out	DDRD_o,r16

	/*habilitem interrupcions */
	sei

	/*el bucle principal no fa res*/
loop:
	rjmp loop
	ret
