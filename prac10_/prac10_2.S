u_temps = 100
llindar_L= (250*2*u_temps)-1
llindar_H=(250*5*u_temps)-1
rAA=r19 			// 1 -> ".", 0 -> "-"
rBB=r20 			// longitud de . i -

.global main
.section .text

crea_codi:	push r18
	ldi r18, 8
	sub r18, rBB
desplaça:	clc
	rol rAA
	dec r18
	brne desplaça
	or rAA,rBB
	pop r18
	ret

troba_codi:	
	push r30
	push r31
	push r17	
	ldi r31, hi8(taulac1)
	ldi r30, lo8(taulac1)
tr:	ld r17,Z+
	cp r17,r16
	breq morse
	rjmp tr
morse:
	ldd r16, Z+36
	mov r17,r16 
	andi r17, 0b00000111
comp:	bst r16,7
	brts crida_ratlla
	rcall punt
next:	rol r16
	dec r17
	brne comp
	rcall sl1
	rcall espera
	pop r17
	pop r31
	pop r30
	ret


.section .data

.include "taula10.S"

.global __do_copy_data