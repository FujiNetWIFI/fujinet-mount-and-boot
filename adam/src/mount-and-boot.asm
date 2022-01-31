;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Mount And Boot
;;; Quickly boot what's in the slots
;;;
;;;  Author: Thomas Cherryhomes
;;;  Email: thom dot cherryhomes at gmail dot com
;;;  License: GPL 3.0
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;

Reboot			EQU	0FC30H
ConsPrintReg		EQU	0FC33H
InitConsole		EQU	0FC36H
ConsPrintSpecial	EQU	0FC39H	
FillVRAM		EQU	0FC26H
EndReadKeyboard		EQU	0FC4BH
EndWriteCharDevice	EQU	0FC51H
StartReadKeyboard	EQU	0FCA8H	
StartWriteCharDevice	EQU	0FCAEH	
WriteVDPReg		EQU	0FD20H	
InitTable		EQU	0FD29H
LoadAscii		EQU	0FD38H
DefPatternTable		EQU	0H
DefNameTable		EQU	1800H
DefSprAttrTable		EQU	1B00H
DefColorTable		EQU	2000H
DefSprPatTable		EQU	3800H

Color			EQU	0F5H
VDPReg0			EQU	000H		; Graphics I
VDPReg1			EQU	0E0H		; ..

ADAMNET_DONE		EQU	080H
ADAMNET_TIMEOUT		EQU	09BH
	
	SECTION	code_user
	PUBLIC _main
	
_main:						; Entry point
		ld	B,0
		ld	C,VDPReg0
		call	WriteVDPReg
		ld	B,1
		ld	C,VDPReg1
		call	WriteVDPReg
	
set_vdp:	ld	A,2			; Nametable
		ld	HL,DefNameTable
		call	InitTable
		ld	A,3			; Pattern table
		ld	HL,DefPatternTable
		call	InitTable
		ld	A,4			; Color Table
		ld	HL,DefColorTable
		call	InitTable
	
init_cons:	ld	BC,1F17H 		; 32x24
		ld	DE,0000H		; HOME at 0,0
		ld	HL,DefNameTable
		call	InitConsole
	
		ld	A,0x0C			; Clear 
		call	ConsPrintSpecial

load_vdp:	call	LoadAscii

main:		ld	HL,hello
		call 	print
	
		ld	BC,01FFFH
wait:		push	BC
		call	StartReadKeyboard
		pop	BC
		nop
		dec	BC
		ld	A,B
		or	C
		jz	booting
		push	BC
		call	EndReadKeyboard
		cp	1BH
		jr	Z,config
		pop	BC
		jr	wait

config:		ld	HL,configmsg
		call	print
		ld	HL,boot_config_cmd
		ld	BC,2
		call	fujiwrite
		jp	Reboot
	
booting:	ld	HL,mountmsg
		call	print

		ld	HL,mount_all_cmd
		ld	BC,1
		call	fujiwrite

		ld	HL,bootmsg
		call	print
		jp	Reboot
			
;;; Subroutines ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;; Print String to console
	;; HL = Address of string to print
	
print:		ld	A,(HL)			; Get Next Byte
		cp 	0
		ret	z			; End on NULL
		call	ConsPrintSpecial	; Print character
		inc	HL			; next char
		jr	print			; Go back and print

	;; Write to FujiNet Device
	;; BC = # of bytes
	;; HL = Buffer source
	
fujiwrite:	ld	A,0FH			; FujiNet Device
		call	StartWriteCharDevice 	; Start response
fujiwrite1:	call	EndWriteCharDevice   	; Wait for response
		cp	ADAMNET_DONE		; Are we done? (>7F?)
		jr	C,fujiwrite1 		; Loop back if not done
		cp	ADAMNET_TIMEOUT	    	; Did we time out?
		jr	Z,fujiwrite  		; Try again
		ret		     		; We're done.

;;; Fuji Commands ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mount_all_cmd:	defm "\xD7"
boot_config_cmd:	 defm	"\xD6\x00"
	
;;; Messages ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
hello:		defm	"WELCOME TO #FUJINET.\r\n\r\n\PRESS ESCAPE TO LOAD CONFIG\r\nOR WAIT 3 SECONDS TO BOOT\r\n\x00"
mountmsg:	defm	"MOUNTING...\r\n\x00"
bootmsg:	defm	"BOOTING...\r\n\x00"
configmsg:	defm	"LOADING CONFIG...\r\n\x00"
