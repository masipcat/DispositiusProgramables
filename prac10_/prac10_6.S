EICRA = 0x69
EIMSK =	0x1D
DDRD =	0x0A
PIND = 0x09
PORTB_o=0x05
DDRB = 0x04
PORTD = 0x0B
OCR1AL = 0x88
OCR1AH = 0x89
TCNT1H = 0x85
TCNT1L = 0x84
TIFR1 = 0x16
TCCR1A = 0x80
TCCR1B = 0x81
TCCR1C = 0x82
TIMSK1 = 0X6F
UDR0 = 0xC6
UBRR0H = 0XC5
UBRR0L = 0XC4
UCSR0C = 0XC2
UCSR0B = 0XC1
UCSR0A = 0XC0	
temps = (250*u_temps)-1
u_temps = 100

.global main
.global __vector_1
.global __vector_13

tx:	push r17
tx1:	lds 	r17,UCSR0A 
	sbrs	r17,5
	rjmp	tx1
	sts	UDR0,r20
	pop r17
	ret

compara:
	lds  r17, TCNT1H
	lds  r16, TCNT1L
	cpi r17,hi8(temps)
	breq menys
	brsh suma
menys: 	cpi r16,lo8(temps)
	brsh suma
	ldi r20, '-'
	ret
suma:	ldi r20, '+'
	ret

__vector_1:
	push r16
	rcall compara
	rcall tx
	ldi r16,0
	sbi TIFR1, 1
	sts TCNT1H, r16
	sts TCNT1L, r16
	pop r16
	reti
__vector_13:
	ldi r20, 'O'
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
		ldi r16, 0b10000000
		//Interrupció externa, portd D2
		ldi r16,0b00000001
		out EIMSK,r16
		ldi r16,0b00000001
		sts EICRA,r16
		ldi r16,0b00000100
		out PORTD,r16
		ldi r16,0b11111011
		out DDRD,r16
		ldi r16, 0b10000000
		sts TCCR1A, r16
		ldi r16, 0b00000011
		sts TCCR1B, r16
		ldi r16,0b00000001
		sts TIMSK1,r16
		sbi TIFR1, 1
		sts TCNT1H, r16
		sts TCNT1L, r16
		sei

loop:	
		rjmp loop