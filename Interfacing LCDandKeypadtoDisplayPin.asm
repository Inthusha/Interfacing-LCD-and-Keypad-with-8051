Org 0000h
		
RS 			Equ  P1.3
E			Equ  P1.2
; R/W* is hardwired to 0V, therefore it is always in write mode
; ---------------------------------- Main -------------------------------------
Main:		
			Clr RS		   	;RS=0 - Instruction register is selected. 
;------------------------- Set Instruction Codes ------------------------------ 
			Call FuncSet		;Function set (4 bit mode)
	
			Call DispCon		;Turn display and cursor on
			
			Call EntryMode		;Shift cursor to the right by 1
;-------------------------------------------------------------------------------			
			SetB RS			;RS=1 - Data register is selected. 
			
			Mov DPTR,#LUT1		;Look-up table for "Enter PIN:" message
Again:		Clr A
			Movc A,@A+DPTR		;Get the character
			Jz Next			;Exit when A=0
			Call SendChar		;Display character
			Inc DPTR			;Point ot the next character
			Jmp Again	
			
Next:		Mov R4,#00h			;Counter for checking the number of scans
			Mov R5,#00h		;Counter for checking for the number correct key input
			Mov DPTR,#LUT4 		;Copy the start of the look-up table for PIN
;----------------------------------- Get Input ----------------------------------			
Iterate:	Call ScanKeyPad		                                ;Scan for the key input
			SetB RS			;RS=1 - Data register is selected. 
			Clr A
			Mov A,#'*'
			Call SendChar		;Display the asterisk for each key pressed 
;------------------- Check for the number of correct code entered ---------------			
			Clr A
			Movc A,@A+DPTR		;Look-up table of PIN
			Call CheckInput		;Check for the number of correct inputs
			Inc DPTR
			Inc R4
			Cjne R4,#04h,Iterate
			
			Cjne R5,#04h,Wrong	;Check for the number of correct inputs
Right:		Call CursorPos  	                                ;Put cursor onto the next line
			SetB RS			;RS=1 - Data register is selected.
			Call Granted
			Jmp EndHere
Wrong: 		Call CursorPos  	                                ;Put cursor onto the next line
			SetB RS			;RS=1 - Data register is selected.
			Call Denied
EndHere:	Jmp $
;------------------------------ *End Of Main* ---------------------------------
;----------------- Note: Use 7 for Update Frequency in EdSim51 ----------------
;-------------------------------- Subroutines ---------------------------------				
; ------------------------- Function set --------------------------------------
FuncSet:	Clr  P1.7		; |
			Clr  P1.6		; |
			SetB P1.5		; | bit 5=1
			Clr  P1.4		; | (DB4)DL=0 - puts LCD module into 4-bit mode 
	
			Call Pulse

			Call Delay		; wait for BF to clear

			Call Pulse
							
			SetB P1.7		; P1.7=1 (N) - 2 lines 
			Clr  P1.6
			Clr  P1.5
			Clr  P1.4
			
			Call Pulse
			
			Call Delay
			Ret
;------------------------------------------------------------------------------
;------------------------------- Display on/off control -----------------------
; The display is turned on, the cursor is turned on
DispCon:	Clr P1.7		; |
			Clr P1.6		; |
			Clr P1.5		; |
			Clr P1.4		; | high nibble set (0H - hex)

			Call Pulse

			SetB P1.7		; |
			SetB P1.6		; |Sets entire display ON
			SetB P1.5		; |Cursor ON
			SetB P1.4		; |Cursor blinking ON
			Call Pulse

			Call Delay		; wait for BF to clear	
			Ret
;--------------------------------------------------------------------------------
;----------------------------- Entry mode set (4-bit mode) ----------------------
;    Set to increment the address by one and cursor shifted to the right
EntryMode:	Clr P1.7		; |P1.7=0
			Clr P1.6		; |P1.6=0
			Clr P1.5		; |P1.5=0
			Clr P1.4		; |P1.4=0

			Call Pulse

			Clr  P1.7		; |P1.7 = '0'
			SetB P1.6		; |P1.6 = '1'
			SetB P1.5		; |P1.5 = '1'
			Clr  P1.4		; |P1.4 = '0'
 
			Call Pulse

			Call Delay		; wait for BF to clear
			Ret
;--------------------------------------------------------------------------------			
;------------------------------------ Pulse --------------------------------------
Pulse:		SetB E		                ; |*P1.2 is connected to 'E' pin of LCD module*
			Clr  E		; | negative edge on E	
			Ret
;---------------------------------------------------------------------------------
;------------------------------------- SendChar ----------------------------------			
SendChar:	Mov C, ACC.7		
			Mov P1.7, C			
			Mov C, ACC.6		
			Mov P1.6, C			
			Mov C, ACC.5		
			Mov P1.5, C			
			Mov C, ACC.4		
			Mov P1.4, C			; | high nibble set
			;Jmp $
			Call Pulse

			Mov C, ACC.3		
			Mov P1.7, C			
			Mov C, ACC.2		
			Mov P1.6, C			
			Mov C, ACC.1		
			Mov P1.5, C			
			Mov C, ACC.0		
			Mov P1.4, C			; | low nibble set

			Call Pulse

			Call Delay			; wait for BF to clear
			
			Mov R1,#55h
			Ret
;--------------------------------------------------------------------------------
;------------------------------------- Delay ------------------------------------			
Delay:		Mov R0, #50
			Djnz R0, $
			Ret
;--------------------------------------------------------------------------------				
;---------------------------Scan Keypad Subroutines------------------------------
;------------------------------- Scan Row ---------------------------------------
ScanKeyPad:	CLR P0.3			                ;Clear Row3
			CALL IDCode0		;Call scan column subroutine
			SetB P0.3			;Set Row 3
			JB F0,Done  		;If F0 is set, end scan 
						
			;Scan Row2
			CLR P0.2			;Clear Row2
			CALL IDCode1		;Call scan column subroutine
			SetB P0.2			;Set Row 2
			JB F0,Done		;If F0 is set, end scan 						

			;Scan Row1
			CLR P0.1			;Clear Row1
			CALL IDCode2		;Call scan column subroutine
			SetB P0.1			;Set Row 1
			JB F0,Done		;If F0 is set, end scan

			;Scan Row0			
			CLR P0.0			;Clear Row0
			CALL IDCode3		;Call scan column subroutine
			SetB P0.0			;Set Row 0
			JB F0,Done		;If F0 is set, end scan 
														
			JMP ScanKeyPad		;Go back to scan Row3
							
Done:		Clr F0		                                ;Clear F0 flag before exit
			Ret
;--------------------------------------------------------------------------------			
;---------------------------- Scan column subroutine ----------------------------
IDCode0:	JNB P0.4, KeyCode03	                                ;If Col0 Row3 is cleared - key found
			JNB P0.5, KeyCode13	;If Col1 Row3 is cleared - key found
			JNB P0.6, KeyCode23	;If Col2 Row3 is cleared - key found
			RET					

KeyCode03:	SETB F0			;Key found - set F0
			Mov R7,#'3'		;Code for '3'
			RET				

KeyCode13:	SETB F0			;Key found - set F0
			Mov R7,#'2'		;Code for '2'
			RET				

KeyCode23:	SETB F0			;Key found - set F0
			Mov R7,#'1'		;Code for '1'
			RET				

IDCode1:	JNB P0.4, KeyCode02	                                ;If Col0 Row2 is cleared - key found
			JNB P0.5, KeyCode12	;If Col1 Row2 is cleared - key found
			JNB P0.6, KeyCode22	;If Col2 Row2 is cleared - key found
			RET					

KeyCode02:	SETB F0			;Key found - set F0
			Mov R7,#'6'		;Code for '6'

			RET				

KeyCode12:	SETB F0			;Key found - set F0
			Mov R7,#'5'		;Code for '5'
			;Mov P1,R7		;Display key pressed
			RET				

KeyCode22:	SETB F0			;Key found - set F0
			Mov R7,#'4'		;Code for '4'
			RET				

IDCode2:	JNB P0.4, KeyCode01	                                ;If Col0 Row1 is cleared - key found
			JNB P0.5, KeyCode11	;If Col1 Row1 is cleared - key found
			JNB P0.6, KeyCode21	;If Col2 Row1 is cleared - key found
			RET					

KeyCode01:	SETB F0			;Key found - set F0
			Mov R7,#'9'		;Code for '9'
			RET				

KeyCode11:	SETB F0			;Key found - set F0
			Mov R7,#'8'		;Code for '8'
			RET				

KeyCode21:	SETB F0			;Key found - set F0
			Mov R7,#'7'		;Code for '7'
			RET				

IDCode3:	JNB P0.4, KeyCode00	                                ;If Col0 Row0 is cleared - key found
			JNB P0.5, KeyCode10	;If Col1 Row0 is cleared - key found
			JNB P0.6, KeyCode20	;If Col2 Row0 is cleared - key found
			RET					

KeyCode00:	SETB F0			;Key found - set F0
			Mov R7,#'#'		;Code for '#' 
			RET				

KeyCode10:	SETB F0			;Key found - set F0
			Mov R7,#'0'		;Code for '0'
			RET				

KeyCode20:	SETB F0			;Key found - set F0
			Mov R7,#'*'	   	;Code for '*' 
			RET		
;--------------------------------------------------------------------------------
;--------------------------------- Check Input -----------------------------------
CheckInput:	
			Cjne A,07H,Exit	;07H is register R7 - it contains the code entered.
			Inc R5
Exit:					
			Ret
;--------------------------------------------------------------------------------			
;-----------------------------------CursorPos------------------------------------------
CursorPos:	Clr RS
			SetB P1.7		; Sets the DDRAM address
			SetB P1.6		; Set address. Address starts here - '1'
			Clr P1.5		; 									 '0'
			Clr P1.4		; 									 '0' 
							; high nibble
			Call Pulse

			Clr P1.7		; 									 '0'
			Clr P1.6		; 									 '0'
			Clr P1.5		; 									 '0'
			Clr P1.4		; 									 '0'
							; low nibble
			Call Pulse

			Call Delay		; wait for BF to clear	
			Ret	
;--------------------------------------------------------------------------------			
;------------------------------ Open ---------------------------------------------
Granted:	Mov DPTR,#LUT2		              ;Look-up table for "Access Granted"
GoBack:		Clr A
			Movc A,@A+DPTR
			Jz Home
			Call SendChar
			Inc DPTR
			Jmp	GoBack		
Home:		Ret	
;--------------------------------------------------------------------------------
;------------------------------ Deny --------------------------------------------
Denied:		Mov DPTR,#LUT3		;Look-up table for "Access Denied"
OneMore:	Clr A
			Movc A,@A+DPTR
			Jz BackHome
			Call SendChar
			Inc DPTR	
			Jmp OneMore
BackHome:	Ret					
;--------------------------------- End of subroutines ---------------------------
;------------------------------ Look-Up Table (LUT) -----------------------------
;---------------------------------- Messages ------------------------------------
			Org 0200h
LUT1:       DB 'E', 'n', 't', 'e', 'r', ' ','P', 'I', 'N',':',0
LUT2:	DB 'A', 'c', 'c', 'e', 's', 's', ' ', 'G', 'r', 'a', 'n', 't', 'e', 'd', 0
LUT3:	DB 'A', 'c', 'c', 'e', 's', 's', ' ', 'D', 'e', 'n', 'i', 'e', 'd', 0
;--------------------------------------------------------------------------------
;------------------------------------- PIN --------------------------------------
			Org 0240h		
LUT4:		DB '1', '2', '3', '4',0
;--------------------------------------------------------------------------------
;--------------------------------- End of Program -------------------------------	
Stop:		Jmp $
	
			End