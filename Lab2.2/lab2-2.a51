;
;File:		Lab2-2.a51
;Class:		ECEN332
;Created:	09/23/2022
;Auth:		Patrick Cash
;

;--------- SETUP ---------
;setup origin
		org 120H
MYDATA:			DB '2020', 00H
		org 150H
MYBCD:			DB 42H, 58H, 64H, 29H, 00H
		org 180H
MYAVG:			DB '8','9','4','7','6','2','5'
		org 0
OPERAND_1		equ 00H
RAM				equ 01H
OPERAND_2		equ 02H
QUOTIENT		equ	03H
REMAINDER		equ 04H
MULTIPLIER		equ 05H
NIBBLE			equ 06H
RESULT			equ 07H

 		mov A, #00H
		mov DPTR, #MYDATA
		mov RAM, #40H

;--------- MAIN ---------
;THIS TAKES CHAR STRING '2020'
;FROM PROG MEM CONVERTS TO
;PACKED BCD, MOVES IT TO 40H IN RAM	

PART_ONE:
		clr A
		movc A, @A+DPTR
		jz PART_TWO

		acall CONVERT_BCD
		mov A, RESULT
		mov @R1, A
		inc R1
		inc DPTR
		sjmp PART_ONE

PART_TWO:
		mov RAM, #50H
		mov DPTR, #MYBCD
		
LP_TWO:	sjmp LP_TWO
		clr A
		movc A, @A+DPTR
		jz PART_THREE
		
		acall CONVERT_HEX
		mov A, RESULT
		mov @R1, A
		inc R1
		inc DPTR
		sjmp LP_TWO
		
PART_THREE:
		
		
HERE:	sjmp HERE

;--------- SUBROUTINES ---------
ADD_BCD:
		push OPERAND_1
		push OPERAND_2
		push NIBBLE

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

		pop NIBBLE
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
		clr C
		clr AC
		
		;split low nibbles off, mask upper
		mov A, OPERAND_2
		anl A, #0FH
		mov NIBBLE, A
		mov A, OPERAND_1
		anl A, #0FH
		
		;subtract nibbles, triggers carry if borrow, mask upper
		subb A, NIBBLE
		anl A, #0FH
		
		;if borrowing, subtract 0110, includes borrow
		jnc SKIP
		subb A, #0101B	;5 + CY
		setb AC			;let next nibble know to borrow
		setb C

		;set aside lower
SKIP:	mov RESULT, A

		;split high nibbles off, mask lower
		mov A, OPERAND_2
		anl A, #0F0H
		swap A
		mov NIBBLE, A
		mov A, OPERAND_1
		anl A, #0F0H
		swap A
		
		;subtract nibbles w/ lower borrow, triggers carry if new borrow, mask lower
		subb A, NIBBLE
		anl A, #0FH
		
		;if borrowing, subtract 0110, inclues borrow, set AC
		jnc SKIP_2
		subb A, #0101B	;5 + CY
		setb AC
		
		;combine nibbles
SKIP_2:	swap A
		orl A, RESULT
		mov RESULT, A

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
		push RESULT
		
		;this is for the remainder
		;when dividend < divisor
		mov RESULT, OPERAND_1
		clr AC
		clr C

		;subtract until less than zero,
		mov QUOTIENT, #0
DIV_LP:	push RESULT		;store for remainder
		acall SUB_BCD
		pop REMAINDER	;update remainder
		
		;break when AC set
		mov OPERAND_1, RESULT	;result of subtr NOT quotient
		jbc AC, BREAK
		
		;if successful subtraction branch
		inc QUOTIENT
		sjmp DIV_LP
		
		;find remainder by BCD_SUB
		;last result from zero
BREAK:	pop RESULT
		pop OPERAND_2
		pop OPERAND_1
		ret

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

CONVERT_HEX:
		push OPERAND_1
		push OPERAND_2
		
		mov OPERAND_2, #16H
		acall DIV_BCD
		mov NIBBLE, REMAINDER
		
		mov OPERAND_1, QUOTIENT
		acall DIV_BCD
		mov A, REMAINDER
		
		swap A
		orl A, NIBBLE
		mov RESULT, A
		
		pop OPERAND_2
		pop OPERAND_1
		ret

end