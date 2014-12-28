EICRA = 0x69
EIMSK =	0x1D
DDRD =	0x0A
PIND = 0x09
PORTB_o=0x05
DDRB = 0x04
PORTD = 0x0B
UDR0 = 0xC6
UBRR0H = 0XC5
UBRR0L = 0XC4
UCSR0C = 0XC2
UCSR0B = 0XC1
UCSR0A = 0XC0

.global main
.global __vector_1

.section .text

tx:	push r17
tx1:	lds 	r17,UCSR0A 
	sbrs	r17,5
	rjmp	tx1
	sts	UDR0,r20
	pop r17
	ret

__vector_1:
	in r16,PIND
	bst r16,2
	brts Hi
	ldi r20, 'L'
	rcall tx
	reti
Hi:	ldi r20, 'H'
	rcall tx
	reti

main:	ldi r16, 0
		sts UBRR0H, r16
		ldi r16, 103
		sts UBRR0L, r16
		/*set frame format*/
		ldi r16, 0b00100000
		sts UCSR0A, r16
		ldi r16, 0b00000110
		sts UCSR0C, r16
		/*enable rx, tx, sense interrupcions*/
		ldi r16, 0b00011000
		sts UCSR0B, r16
		ldi r16,0b00000001
		out EIMSK,r16
		ldi r16,0b00000001
		sts EICRA,r16
		ldi r16,0b00000100
		out PORTD,r16
		ldi r16,0b11111011
		out DDRD,r16
		ldi r16,0b11111111
		out DDRB,r16
		sei 

loop: 
	rjmp loop

