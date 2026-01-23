; STRINGS.ASM
; Source for string related procedures
; Author: Homero Trevino <homerotl@gmail.com>

.MODEL small

.DATA  

	PUBLIC _NumToAsciiB
	_NumToAsciiB		db '   ', 0
	
	PUBLIC _IntToStringBuffer
	_IntToStringBuffer	db '     ',0
	
	; This one is $ terminated because it is for INT 21h usage
	PUBLIC _CRLF
	_CRLF				db 13,10,'$' 
	
.CODE
	.8086
	JUMPS
	
;----
; _STR_CHAR_TO_STRING 
; Converts the value in ah to a decimal string. Only 8-bit unsigned int.
; Inputs:
; 	- ah = the value to conver to decimal 
; Output: 
;	- NumToAsciiB contains the decimal string.
; Destroys: None
;----
PUBLIC _STR_CHAR_TO_STRING
_STR_CHAR_TO_STRING PROC NEAR	; Assuming the value we want to convert is in ah

	lea di,_NumToAsciiB			; Point di to the buffer where we are going to write number		

	push ax						; we are going to use these registers, so save them
	push bx
	
	mov bl,20h					; Reset buffer with blank space char (20h)
	mov [di],bl
	mov [di+1],bl
	mov [di+2],bl

	add di,2					; start from the back, move index to position 2
	
	mov bl,0ah					; prep to divide by 10 (0ah)
	mov al,ah					; Prep AX

STR_CTS_Loop:
	mov ah,0					; Prep AX
	div bl						; We divide ax/bl. al has the quotient and ah has the reminder
	add ah,30h					; Make ah ASCII
	mov [di],ah					; Copy the ASCII value to the buffer
	dec di						; increment the index for the buffer
	cmp al,0					; if the quotient is 0, we are done				
	je STR_CTS_Trim
	jmp STR_CTS_Loop			; repeat
	
STR_CTS_Trim:

	lea di,_NumToAsciiB
	cmp BYTE PTR [di],20h
	jne STR_CTS_Done

	mov bl,[di+1]
	mov [di],bl
	mov bl,[di+2]
	mov [di+1],bl
	mov BYTE PTR [di+2],0
	jmp STR_CTS_Trim

STR_CTS_Done:
	pop bx						; Restore registers
	pop ax						

	ret
_STR_CHAR_TO_STRING ENDP

;----
; _STR_INT_TO_STRING 
; Converts the value in ah to a decimal string. Only 8-bit unsigned int.
; Inputs:
; 	- ax = the value to conver to decimal 
; Output: 
;	- _IntToStringBuffer contains the decimal string.
; Destroys: None
;----
PUBLIC _STR_INT_TO_STRING
_STR_INT_TO_STRING PROC NEAR	; Assuming the value we want to convert is in ah

	lea di,_IntToStringBuffer	; Point di to the buffer where we are going to write number		

	push ax						; we are going to use these registers, so save them
	push bx	
	push dx
	
	mov bl,20h					; Reset buffer with blank space char (20h)
	mov [di],bl
	mov [di+1],bl
	mov [di+2],bl
	mov [di+3],bl
	mov [di+4],bl

	add di,4					; start from the back, move index to position 4
	
	mov bx,000ah				; prep to divide by 10 (0ah)

STR_ITS_Loop:
	mov dx,0
	div bx						; We divide AX/BX. AX has the quotient and DX has the reminder
	add dl,30h					; Make ah ASCII
	mov [di],dl					; Copy the ASCII value to the buffer
	dec di						; increment the index for the buffer
	cmp ax,0					; if the quotient is 0, we are done				
	je STR_ITS_Trim				;
	jmp STR_ITS_Loop			; repeat
	
STR_ITS_Trim:
	lea di,_IntToStringBuffer
	cmp BYTE PTR [di],20h
	jne STR_ITS_Done
	
	mov bl,[di+1]
	mov [di],bl
	mov bl,[di+2]
	mov [di+1],bl
	mov bl,[di+3]
	mov [di+2],bl
	mov bl,[di+4]
	mov [di+3],bl
	mov BYTE PTR [di+4],0
	
	jmp STR_ITS_Trim

STR_ITS_Done:
	pop dx
	pop bx						; Restore registers
	pop ax						

	ret
_STR_INT_TO_STRING ENDP

;----
; _PROGRESS_CALC 
; Calculates progress between a max value and a current value
; as a value from 0 to 10
;
; Inputs:
; 	- ah - is the max value
;   - al - is the current progress
; Output: 
;	- ah - is the corresponding value from 0 to 10
; Destroys: None
;----
PUBLIC _STR_PROGRESS_CALC
_STR_PROGRESS_CALC PROC
    push bx             ; save register we will use
    mov bl,ah           ; save max value
    xor ah,ah           ; make ah=0
    mov bh,0ah          ; bh=10
    mul bh              ; ax=al*bh
    div bl              ; al=ax/bl
    mov ah,al
    pop bx              ; restore register used
	ret
_STR_PROGRESS_CALC ENDP

;----
; _STR_BUFFER_COPY 
; Copy from the buffer pointed by si to di a number of bytes specified by cx
; Inputs:
; 	- cx - number of bytes to copy
;   - si - source index
;   - di - destination index
; Output: 
; Destroys: None
;----
PUBLIC _STR_BUFFER_COPY
_STR_BUFFER_COPY PROC
	push ax

S_BC_Continue:

	mov ah,[si]
	mov [di],ah
	inc si
	inc di
	loop S_BC_Continue
	
	pop ax
	
	ret
_STR_BUFFER_COPY ENDP

;----
; _STR_STR_LEN 
; Returns the length of a null-terminated string. 
; Inputs:
;   - si - start index of the string
; Output: 
; 	- cx - length of the string
; Destroys: cx
;----
PUBLIC _STR_STR_LEN
_STR_STR_LEN PROC
    push si                 ; save si
    push ax
    xor cx,cx               ; cx = 0
STR_Str_Len_Loop:
    mov al,[si]
    cmp al,0
    je STR_Str_Len_End
    inc cx
    jo STR_Str_Len_End      ; we exceeded the maximum length 
    inc si
    jmp STR_Str_Len_Loop
STR_Str_Len_End:
    pop ax
    pop si
	ret
_STR_STR_LEN ENDP

END