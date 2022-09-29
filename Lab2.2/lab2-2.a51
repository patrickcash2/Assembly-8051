;
;File:		Lab2-2.a51
;Class:		ECEN332
;Created:	09/23/2022
;Auth:		Patrick Cash
;

;--------- SETUP ---------
;setup origin
		org 300H
MYDATA:			DB '2020', 00H

		org 0
OPERAND_1		equ 00H
RAM				equ 01H
OPERAND_2		equ 02H
QUOTIENT		equ	03H
DIVISOR			equ 04H
MULTIPLIER		equ 05H
NIBBLE			equ 06H
RESULT			equ 07H
	
 		mov A, #00H
		mov DPTR, #MYDATA
		mov RAM, #40H

;--------- TESTING ---------
		;test SUB_BCD
		mov OPERAND_1, #99H
		mov OPERAND_2, #33H
		acall SUB_BCD
		mov OPERAND_1, RESULT
		mov OPERAND_2, #33H
		acall SUB_BCD
		mov OPERAND_1, RESULT
		mov OPERAND_2, #33H
		acall SUB_BCD
		;end test
		
;--------- MAIN ---------
;THIS TAKES CHAR STRING '2020'
;FROM PROG MEM CONVERTS TO
;PACKED BCD, MOVES IT TO 40H IN RAM		
BEGIN:
		clr A
		movc A, @A+DPTR
		jz HERE
		
		acall CONVERT_BCD
		mov A, RESULT
		mov @R1, A
		inc R1
		inc DPTR
		sjmp BEGIN
		
HERE:	sjmp HERE

;--------- SUBROUTINES ---------
ADD_BCD:
		push OPERAND_1
		push OPERAND_2
		
		;split lows off
		mov A, OPERAND_1
		anl A, #0FH
		mov NIBBLE, A
		mov A, OPERAND_2
		anl A, #0FH
		
		;add low nibbles together
		add A, NIBBLE
		;if result > 0000 1001, +0000 0110 +1 to high nibble
		da A
		mov RESULT, A

		;split highs
		mov A, OPERAND_1
		anl A, #0F0H
		mov NIBBLE, A
		mov A, OPERAND_2
		anl A, #0F0H
		
		;add high nibbles+
		add A, NIBBLE
		;if result > 1001 0000, +0110 0000
		da A
		
		;combine nibbles
		add A, RESULT
		mov RESULT, A
		
		pop OPERAND_2
		pop OPERAND_1
		ret

;receives: OPERAND_1 as minuend and OPERAND_2 as subtrahend
;stores: in RESULT
;uses: NIBBLE
SUB_BCD:
		push OPERAND_1
		push OPERAND_2
		push NIBBLE
		
		;add 1s compliment subtrahend to minuend
		mov A, OPERAND_2
		cpl A
		addc A, OPERAND_1
		
		;checks if carry flag, wraps around
		jnc SKIP
		add A, #1
		
		;combine result
SKIP:	mov RESULT, A

		pop NIBBLE
		pop OPERAND_2
		pop OPERAND_1
		ret

;loop to divide, subtract OPERAND_1 as dividend,
;compare RESULT of subtracting, if success result>0,
;increment quotient, try again, if fail result<0,
;break loop
DIV_BCD:
		push OPERAND_1  ;dividend
		push OPERAND_2	;divisor

		;subtract BCD
		mov QUOTIENT, #0
DIV_LP:	acall SUB_BCD
		
		;check result
		mov A, RESULT
		jz A, BREAK
		
		;if success branch
		inc QUOTIENT
		djnz OPERAND_2, DIV_LP
		
		;fail branch
		pop OPERAND_2
		pop OPERAND_1
BREAK:	ret

;receives: OPERAND_1 and adds it to itself MULTIPLIER times
;stores: in RESULT
;uses: OPERAND_2, NIBBLE
MUL_BCD:
		push NIBBLE
		push OPERAND_2
		mov OPERAND_2, #0
		mov RESULT, #0
LOOP_MUL:
		mov A, RESULT
		mov OPERAND_2, A
		acall ADD_BCD
		djnz MULTIPLIER, LOOP_MUL
		pop OPERAND_2
		pop NIBBLE
		ret

CONVERT_BCD:
		;split high/low
		;swap high to low
		;use high as multipler for MUL_BCD
		swap A
		mov MULTIPLIER, A
		anl MULTIPLIER, #0FH
		
		;push low nibble aside
		swap A
		anl A, #0FH
		mov RESULT, A
		push RESULT
		
		;MUL_BCD 16 X high nibble
		mov OPERAND_1, #16H
		mov OPERAND_2, #00H
		clr A
		acall MUL_BCD
		
		;pop low nibble back,
		;adjust nibble
		;ADD_BCD low and converted
		pop NIBBLE
		mov A, NIBBLE
		da A
		mov OPERAND_2, A
		mov OPERAND_1, RESULT
		acall ADD_BCD
		
		;print result
		ret

end