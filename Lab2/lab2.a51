;
;File:		Lab2.a51
;Class:		ECEN332
;Created:	09/23/2022
;Auth:		Patrick Cash
;

;--------- SETUP ---------
;setup origin
		org 0

;start by setting stack to 50H, lots of room for activities
START:	mov SP, #50H

		;initialize OPTREX Dot Matrix LCD
		acall INIT_PORTS
		acall INIT_LCD

;--------- MAIN ---------
;this is the main section that sends
;lab number and name to LCD then loops
;LCD data lines: port 1
;LCD control lines: port 3
		mov DPTR, #TXT
		acall PUTSTRING
		acall PUT_CRLF
		mov DPTR, #MYNAME
		acall PUTSTRING
HERE:	sjmp HERE
		
TXT:	DB 'Lab 2.1', 00H
MYNAME:	DB 'Patrick Cash', 00H


;--------- SUBROUTINES ---------
INIT_LCD:
		;LCD, 2 lines, 5x7 matrix
		mov A, #38H
		acall COMNWRT
		acall DELAY
		
		;display on, cursor on
		mov A, #0EH
		acall COMNWRT
		acall DELAY
		
		;clear LCD
		mov A, #01H
		acall COMNWRT
		acall DELAY
		
		;shift cursor right
		mov A, #06H
		acall COMNWRT
		acall DELAY
		
		;cursor at line 1 position 4
		mov A, #84H
		acall COMNWRT
		acall DELAY
		ret

INIT_PORTS:
		;safe to assume already clr, but just in case
		mov P3, #0
		mov P1, #0
		ret

PUTSTRING:
		;pull value from program memory
		clr A
		movc A, @A+DPTR
		
		;exit subroutine when zero char found
		jz EXIT1
		
		;send a single char to LCD, increment ptr
		acall PUTCHAR
		inc DPTR
		sjmp PUTSTRING
EXIT1:	ret
		
PUTCHAR:
		;send accum to port 1
		mov P1, A		;data
		
		;send data and write
		setb P3.0		;RS for data
		clr P3.1		;R/W for write
		
		;pulse E high, return
		setb P3.2		;E high pulse
		acall DELAY
		clr P3.2		;E high to low
		ret

;carriage return, line feed ASCII
CR		EQU 0C0H
LF		EQU 0AH

PUT_CRLF:
		;send to accum, call putchar
		mov A, #0C0H
		acall COMNWRT
		;mov A, LF
		;acall COMNWRT
		ret

COMNWRT:
		;send accum to port 1
		mov P1, A	;data
		
		;send cmd and write
		clr P3.0	;R/S for command
		clr P3.1	;R/W for write
		
		;pulse E high, return
		setb P3.2	;E for pulse high
		acall DELAY
		clr P3.2	;E for pulse high
		ret
		
;freq = 11MHz => T = 91.0ns
;255 * 50 * mc
;mc = 12 * clks
;t = 91 * 255 * 50 * 12 * clks ns = 13.9 * clks ms
DELAY:
		;free up regs 3,4 for use
		push 3
		push 4
		
		;255 * 50 * mc * 1/f
		mov R3, #50
HERE2:	mov R4, #255
HERE1:	djnz R4, HERE1
		djnz R3, HERE2
		
		;restore stack, return
		pop 4
		pop 3
		ret
end
