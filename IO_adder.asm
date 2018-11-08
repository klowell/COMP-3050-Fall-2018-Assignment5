start:		
	LODD on:			; AC = on = 8 = 0000 0000 0000 1000
	STOD 4095			; XMTR_STATUS = AC = 8								; Turn on XMTR by setting ON bit to 1
	CALL xbsywt:															; Wait for XMTR to be done/not busy
	LOCO str1:			; AC = *str1										; Load entry prompt pointer into accumulator

prline:
	PSHI				; M[SP] = M[AC] = str1[i]							; Push current two-character "string" onto stack
	ADDD c1:			; AC = AC + c1 = AC + 1								; Increment pointer to progress to next two-character "string"
	STOD pstr1:			; pstr = AC											; Stored incremented pointer to next two-character "string"
	POP					; AC = M[SP] = str1[i]								; Put current two-character "string" into accumulator
	JZER crnl:			; if (str1[i] == 0) goto crnl						; If "string" is empty, print out carriage return and new line
	STOD 4094			; M[XMTR] = AC										; Send current character to XMTR
	PUSH				; M[SP] = AC										; Push current two-character "string" onto stack
	CALL xbsywt:															; Wait for XMTR to be done/not busy
	POP																		; Return the two-character "string" back into accumulator
	SUBD c255:			; AC = AC - c255 = AC - 255							; If no second character is stored, print carriage return and new line
	JNEG crnl:			; if (AC < 0) goto crnl
	ADDD c255:
	PUSH
	CALL swpbts:															; If there is a second character, swap left and right bytes of current two-character "string"
	POP																		; Since the stack will have to be cleared and the result is stored at the top of stack
	STOD 4094			; M[XMTR] = AC										; Send second character to XMTR
	CALL xbsywt:															; Wait for XMTR to be done/not busy
	LODD pstr1:			; AC = pstr1										; Load pointer to next two-charater "string" within the string
	JUMP prline:																; Loop until either, no bytes 

crnl:
	LODD cr:			; AC = cr = 13										; Load carriage return value into accumulator
	STOD 4094			; M[XTMR] = AC = cr = 13							; Send carriage return to XMTR
	CALL xbsywt:															; Wait for XMTR to be done/not busy
	LODD nl:			; AC = nl = 10										; Load return line value into accumulator
	STOD 4094			; M[XTMR] = AC = nl = 10							; Send new line to XMTR
	CALL xbsywt:															; Wait for XMTR to be done/not busy
	LODD numcnt:		; AC = numcnt
	JPOS rcvon:			; if (numcnt >= 0) goto rcvon						; If no or 1 numbers hasn't been entered yet, start receiving for entries
	RETN																	; Allows for other strings to be printed using the same routine

rcvon:
	LODD on:			; AC = on = 8 = 0000 0000 0000 1000
	STOD 4093			; XMTR_STATUS = AC = 8								; Turn on RCVR by setting ON bit to 1

bgndig:
	CALL rbsywt:															; Wait for RCVR to be done/not busy
	LODD 4092			; AC = M[RCVR]
	SUBD numoff:		; AC = AC - numoff = AC - 48						; Offset entered character by 48 to get numerical value
	PUSH																	; Push numerical value of entry to stack

nxtdig:
	CALL rbsywt:															; Wait for RCVR to be done/not busy
	LODD 4092			; AC = M[RCVR]										; Load next character into accumulator
	STOD nxtchr:		; nxtchr = AC
	SUBD nl:			
	JZER endnum:		; if (nxtchr == '\n') goto endnum					; If next character is new line, marks the end of the entry
	MULT 10				; M[SP] = M[SP] * 10								; Multiply current digits by 10 to get ready for next digit
	LODD nxtchr:		; AC = nxtchar										; If next character isn't a new line, multiply current digits by 10
	SUBD numoff:		; AC = AC - numoff = AC - 48						; Offset next character by 48 to get numerical value
	ADDL 0				; AC = AC + M[SP]									; Add the multiplied previous digits to the next value
	STOL 0				; M[SP] = AC										; Store the new digits (numerical value) into stack
	JUMP nxtdig:															; Loop until a new line character is found

endnum:
	LODD numptr:		; AC = numptr										; Load pointer to target variable into accumulator
	POPI				; M[AC] = M[SP]										; Store number into target variable
	ADDD c1:			; AC = AC + c1 = AC + 1								; Increment pointer to store next number
	STOD numptr:															; Store next address for the next number variable
	LODD numcnt:		; AC = numcnt
	JZER addnms:		; if (numcnt == 0) goto addnms						; If both numbers have been stored, goto addnums
	SUBD c1:			; AC = AC - c1 = numcnt - 1							; if only one number has been stored, decrement number count variable
	STOD numcnt:		; numcnt = AC = numcnt - 1							; Store decremented value
	JUMP start:																; Go back to start to load in next entry number

addnms:
	LODD binum1:		; AC = binum1										; Load first entered number into accumulator
	ADDD binum2:		; AC = AC + binum2 = binum1 + binum2				; Add second entered number to first entered number
	STOD sum:			; sum = AC = binum1 + binum2						; Store sum of numbers into sum variable

sumis:
	LOCO 0				; AC = 0
	SUBD c1:			; AC = AC - c1 = 0 - 1 = -1							; Set number count variable to -1 to enable use of previous print routine
	STOD numcnt:		; numcnt = -1
	LOCO str2:			; AC = *str2										; Load sum prompt pointer into accumulator
	CALL prline:															; Using previous printing routine, print the sum prompt
	LODD sum:			; AC = sum
	JNEG ovrflw:		; if (AC < 0) goto ovrflw							; In the case of an over flow

prdig1:
	LODD c10000:		; AC = c10000 = 10000								; Load 10000 into accumulator
	PUSH				; M[SP] = AC = 10000								; Push 10000 onto stack to act as divisor
	LODD sum:			; AC = sum											; By taking quotient of sum and 10000, it will give us the first value of the first digit
	PUSH				; M[SP] = AC = sum									; Push sum onto stack to act as dividend
	DIV					; M[SP + 1] = sum % 10000, M[SP] = sum / 10000
	LODD c10000:		; AC = c10000 = 10000								; By taking the quotient, we get the first digit
	SUBD sum:			; AC = AC - sum = 10000 - sum						; By taking the remainder, we get the remaining 4 digits
	JPOS lt5dig:		; if (sum < 10000) goto prdig2						; If the sum is less than 10000, no need to print out the first digit
	POP					; AC = M[SP] = sum / 10000							; Load quotient/first digit into accumulator from the stack
	ADDD numoff:		; AC = AC + numoff = AC + 48						; Add the offset to get the ASCII value for the first digit
	STOD 4094			; M[XMTR] = AC										; Send first digit to transmitter
	CALL xbsywt:															; Wait for XMTR to be done/not busy
	JUMP prdig2:

lt5dig:
	POP

prdig2:
	POP					; AC = M[SP] = sum % 10000							; Load remaining four digits into accumulator
	STOL 0				; M[SP] = AC										; Store remaining four digits into top of stack to act as dividend
	LODD c1000:			; AC = c1000 = 1000									; Load 1000 into accumulator
	STOL 1				; M[SP + 1] = AC = 1000								; Store 1000 to just under the top of stack to act as divisor
	DIV					; M[SP + 1] = (sum % 10000) % 1000, M[SP] = (sum % 10000) / 1000
	LODD c1000:			; AC = c1000 = 1000
	SUBD sum:			; AC = AC - sum = 1000 - sum
	JPOS lt4dig:		; if (sum < 1000) goto prdig3						; If the sum is less than 1000, no need to print out the first two digits
	POP					; AC = M[SP] = (sum % 10000) / 1000					; Load quotient/second digit into accumulator from the stack
	ADDD numoff:		; AC = AC + numoff = AC + 48						; Add the offset to get ASCII value for the second digit
	STOD 4094			; M[XMTR] = AC										; Send second digit to transmitter
	CALL xbsywt:															; Wait for XMTR to be done/not busy
	JUMP prdig3:

lt4dig:
	POP

prdig3:
	POP					; AC = M[SP] = (sum % 10000) % 1000					; Load remaining three digits into accumulator
	STOL 0				; M[SP] = AC = sum % 10000) % 1000					; Store remaining three digits into top of stack to act as dividend
	LODD c100:			; AC = c100 = 100									; Load 100 into accumulator
	STOL 1				; M[SP + 1] = AC = 100								; Store 100 to just under the top of stack to act as divisor
	DIV					; M[SP + 1] = ((sum % 10000) % 1000) % 100, M[SP] = ((sum % 10000) % 1000) / 100
	LODD c100:			; AC = c100 = 100
	SUBD sum:			; AC = AC - sum = 100 - sum
	JPOS lt3dig:		; if (sum < 100) goto prdig4						; If the sum is less than 100, no need to print out the first three digits
	POP					; AC = M[SP] = ((sum % 10000) % 1000) / 100			; Load quotient/third digit into accumulator from the stack
	ADDD numoff:		; AC = AC + numoff = AC + 48						; Add the offset to get ASCII value for the third digit
	STOD 4094			; M[XMTR] = AC										; Send third digit to transmitter
	CALL xbsywt:															; Wait for the XMTR to be done/not busy
	JUMP prdig4:

lt3dig:
	POP

prdig4:
	POP					; AC = M[SP] = ((sum % 10000) % 1000) % 100			; Load remaining two digits into accumulator
	STOL 0				; M[SP] = AC = ((sum % 10000) % 1000) % 100			; Store remaining two digitis into top of stack to act as dividend
	LODD c10:			; AC = c10 = 10										; Load 10 into accumulator
	STOL 1				; M[SP + 1] = AC = 10								; Store 10 to just under top of the stack to act as divisor
	DIV					; M[SP + 1] = (((sum % 10000) % 1000) % 100)) % 10, M[SP] = (((sum % 10000) % 1000) % 100) / 10
	LODD c10:			; AC = c10 = 10
	SUBD sum:			; AC = AC - sum = 10 - sum
	JPOS lt2dig:		; if (sum < 10) goto prdig5							; If the sum is less than 10, no need to print out first four digits
	POP					; AC = M[SP] = (((sum % 10000) % 1000) % 100) / 10	; Load quotient/fourth digit into accumulator from the stack
	ADDD numoff:		; AC = AC + numoff = AC + 48						; Add the offset to get ASCII value for the fourth digit
	STOD 4094			; M[XMTR] = AC										; Send fourth digit to transmitter
	CALL xbsywt:															; Wait for the XMTR to be done/not busy
	JUMP prdig5:

lt2dig:
	POP

prdig5:
	POP					; AC = M[SP] = (((sum % 10000) % 1000) % 100) % 10	; Load last digit into accumulator
	ADDD numoff:
	STOD 4094
	CALL xbsywt:
	CALL crnl:																; Print out carriage return and new line
	INSP 2				; SP = SP + 2										; Clear the stack
	LOCO 0				; AC = 0											; A successful addition results in the accumulator being set to 0
	JUMP done:			; goto done											; Finish program

ovrflw:
	LOCO str3:			; AC = *str3										; Load overflow prompt pointer into accumulator
	CALL prline:															; Using the previous printing routine, print the overflow prompt
	LOCO 0				; AC = 0
	SUBD c1:			; AC = AC - c1 = 0 - 1 = -1							; An addition that results in an overflow results with the accumulator being set to -1

done:
	HALT																	; End program

xbsywt:
	LODD 4095			; AC = XMTR_STATUS									; Looking at transmitter status
	SUBD mask:			; AC = AC - mask  = XMTR_STATUS - 10				; Waiting for both ON and DONE bits to be set
	JNEG xbsywt:		; if (XMTR_STATUS < 10) goto xbsywt					; If not done, then XMTR must be busy so loop until it's done
	RETN

rbsywt:
	LODD 4093			; AC = RCVR_STATUS									; Looking at receiver status
	SUBD mask:			; AC = AC - mask = RCVR_STATUS - 10					; Waiting for both ON and DONE bits to be set
	JNEG rbsywt:		; if (RCVR_STATUS < 10) goto rbsywt					; If not done, then RCVR must be busy so loop until it's done
	RETN

swpbts:
	LOCO 8				; AC = 8											; Swapping the bits ultimately requires a left rotate eight times

loop1:
	JZER finish:		; if (AC == 0) goto finish
	SUBD c1:			; AC = AC - c1 = AC - 1
	STOD lpcnt:			; lpcnt = AC
	LODL 1				; AC = M[SP + 1]
	JNEG add1:			; if(AC < 0) goto add1
	ADDL 1				; AC = AC + M[SP + 1]
	STOL 1				; M[SP + 1] = AC
	LODD lpcnt:			; AC = lpcnt
	JUMP loop1:			; goto loop1

add1:
	ADDL 1				; AC = AC + M[SP + 1]
	ADDD c1:			; AC = AC + c1 = AC + 1
	STOL 1				; M[SP + 1] = AC
	LODD lpcnt:			; AC = lpcnt
	JUMP loop1:			; goto loop1

finish:
	LODL 1				; AC = M[SP + 1]									; Store end result in the stack as well as the accumulator
	RETN

numoff:		48
nxtchr:		0
numptr:		binum1:
binum1:		0
binum2:		0
lpcnt:		0
mask:		10
on:			8
nl:			10
cr:			13
c1:			1
c10:		10
c100:		100
c1000:		1000
c10000:		10000
c255:		255
sum:		0
numcnt:		1
pstr1:		0
str1:		"Please enter an integer between 1 and 32767:"
str2:		"The sum of these integers is:"
str3:		"Overflow, no sum possible."