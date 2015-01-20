.include "../constants.S"
.include "../transmission.S"

.global main

.macro ferSuma num
	push r16 				; resultat H
	push r16 				; resultat L

	ldi r16, \num
	push r16 				; param num

	rcall suma
	pop r16 				; pop p1
	pop r17 				; resultat L
	pop r16 				; resulat H
	
	rcall tx
	mov r16, r17
	rcall tx 				; mostrem el resulat
.endm

suma:
	push r28
	push r29
	in r29, SPH
	in r28, SPL

	push r0
	push r1
	push r16
	push r17
	
	ldd r16, Y+5 				; agafem el valor
	cpi r16, 1
	brne _ne
	clr r1 					; retorna 1 en cas que l'exponent == 0
	clr r0
	inc r0 					; 0x0001
	rjmp _end

_ne:	dec r16

	push r0 				; resultat H 
	push r0 				; resultat L
	push r16 				; num
	rcall suma
	pop r16 				; num
	pop r0 					; resultat L
	pop r1 					; resultat H

	clr r17
	sec
	
	adc r0, r16 				; rL + (valor-1) + 1
	adc r1, r17 				; rH + 0 + C

_end:	std Y+6, r0 				; actualitzar el resultat L
	std Y+7, r1 				; actualitzar el resultat H
	pop r17
	pop r16
	pop r1
	pop r0
	pop r29
	pop r28
	ret

main:
	configureUSART
	ferSuma 5
	ldi r16, '-'
	rcall tx
	ferSuma 20
	ldi r16, '-'
	rcall tx
	ferSuma 50
	ldi r16, '-'
	rcall tx

loop:	
	rjmp loop
