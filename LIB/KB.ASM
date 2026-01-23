; KB.ASM
; Source for keyboard realted procedures
; Author: Homero Trevino

.MODEL small

.CODE
	.8086
	JUMPS

;----
; _KB_YES_NO_Q 
; Wait for a Y/N answer (case insensitive)
; Inputs:
; 	- None
; Output: 
;	- al = 1 if YES, 0 if NO. 
; Destroys: AX
;----
PUBLIC _KB_YES_NO_Q
_KB_YES_NO_Q PROC					
	
YNAskAgain:

	mov ah,07h					; Function 07h int 21h - Wait for a character w/o echo
	int 21h	
	
	cmp al,'y'					; Check Yes lowercase
	je YNAnswerYes
	cmp al,'Y'					; Check Yes uppercase
	je YNAnswerYes
	cmp al,'n'					; Check No lowercase
	je YNAnswerNo
	cmp al,'N'					; Check No uppercase
	je YNAnswerNo	
	jmp YNAskAgain				; None of them, then ask again
	
YNAnswerYes:
	mov al,1
	jmp YNEnd
	
YNAnswerNo:
	mov al,0
	
YNEnd:
	ret
_KB_YES_NO_Q ENDP

;----
; _KB_WAIT_ANY_KEY
; Wait for any key press and returns 
; Inputs:
; 	- None
; Output: 
;	- None
; Destroys: None
;----
PUBLIC _KB_WAIT_ANY_KEY
_KB_WAIT_ANY_KEY PROC

	push ax
	mov ah,07h					; Function 07h int 21h - Wait for a character w/o echo
	int 21h	
	pop ax

	ret
_KB_WAIT_ANY_KEY ENDP

;----
; _KB_READ_KEY
; Read one key from the keyboard
; Inputs:
; 	- None
; Output: 
;	- al: character code unless AH = 1
;   - ah: 0 if read is ASCII, 1 if read special key
; Destroys: ax
;----
PUBLIC _KB_READ_KEY
_KB_READ_KEY PROC
    xor ah,ah
    int 16h
    or al,al
    jz rk_extended_code
    xor ah,ah
rk_done_reading:
    ret
rk_extended_code:
    mov al,ah
    mov ah,1
    jmp rk_done_reading
_KB_READ_KEY ENDP

;----
; _KB_ENTER_ESC_Q 
; Wait for an ESC or ENTER response
; Inputs:
; 	- None
; Output: 
;	- al 0=ESC, 1 = ENTER  
; Destroys: AX
;----
PUBLIC _KB_ENTER_ESC_Q
_KB_ENTER_ESC_Q PROC
kb_enter_esc_loop:
    call _KB_READ_KEY
    or ah,ah                           ; ax = -1 if no charcter read, 1 for
                                       ; extended code
    js kb_enter_esc_loop
    jnz kb_enter_esc_loop

    cmp al,0dh                         ; is it Enter?
    je kb_enter_esc_enter
    
    cmp al,1bh                         ; is it Esc?
    je kb_enter_esc_esc

    jmp kb_enter_esc_loop

kb_enter_esc_enter:
    mov al,01h
    jmp kb_enter_esc_end
    
kb_enter_esc_esc:
    mov al,00h

kb_enter_esc_end:
    ret   
_KB_ENTER_ESC_Q ENDP

;----
; _KB_FLUSH_BUFFER 
; Flush the KB buffer, and nothing else
; Inputs: None
; Output: None
; Destroys: None
;----
PUBLIC _KB_FLUSH_BUFFER
_KB_FLUSH_BUFFER PROC
	push ax
	mov ax,0cffh						; Int 21h function 0ch - flush kb buffer
	int 21h
	pop ax
	ret
_KB_FLUSH_BUFFER ENDP

END