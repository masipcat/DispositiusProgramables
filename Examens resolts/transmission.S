/* rutina de transmissió de byte,
el valor a transmetre està al registre r16 */
tx:
	push r17
__tx:	lds r17, UCSR0A
	sbrs r17, 5
	rjmp __tx
	sts UDR0, r16
	pop r17
	ret

.macro configureUSART
	/* set frame format */
	/* el valor de reset ja és correcte:
	asíncron, sense paritat, 1 stop, 8 dades,
	velocitat normal, cominicació no multiprocessor */
	/*assegurem el que volem encara que en reset ja ho sigui*/
	push r16
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
	pop r16
	sei
.endm