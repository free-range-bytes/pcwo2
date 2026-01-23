; COMMLN.ASM
; Handle parsing of parameters in the command line
; Author: Homero Trevino <homerotl@gmail.com>

.MODEL small

.DATA
	
	; These are $ terminated because they are for use with Int 21h
    CommLineErrorMsg			db 'ERROR: Invalid command line option',13,10,'$' 

    SyntaxMsg					db 'Syntax:',13,10
    							db '   pcwo <options>',13,10
    							db '<options> can be:',13,10
    							db '   -v   Verbose mode enabled',13,10
    							db '   -a   Autorun. Skip all user prompts',13,10,'$' 
    
    VerboseEnMsg				db ' - Verbose mode enabled',13,10,'$'
    AutoRunMsg					db ' - Autorun mode enabled',13,10,'$'

    PUBLIC _CommandLineErrorFlag    
	_CommandLineErrorFlag 		db 0

    PUBLIC _AutoRunFlag
    _VerboseEnableFlag			db 0

	PUBLIC _VerboseEnableFlag
    _AutoRunFlag				db 0
    
.CODE
	.8086
	JUMPS
	
;----
; _CL_PARSE_COMMAND_LINE 
; Parses some command line options
; Inputs:
; 	- None
; Output: 
;	- cl = (in order of least to most significant bits)
;			Bit 0 - There was an error persing the command line
;			Bit 1 - Verbose flag 1=Enabled, 0=Disabled
;  	 		Bit 2 - Autorun flag 1=Enable, 0=Disabled
;			Bit 3-7 Not used
; Destroys: ax,bx,cx
;----
PUBLIC _CL_PARSE_COMMAND_LINE
_CL_PARSE_COMMAND_LINE PROC

								; We are assuming DS has the Program Segment Fix (PSP)
	mov cl,0					; clear cl
	mov bl,ds:[0080h]			; Check for command line params	
	cmp bl,0
	je PCL_End
	
	mov ah,0					; ah = state = 0 for init
	
	mov di,81h					; di to be used index the command line string
								; starts at 81h in the PSP
PCL_continue:
	
	mov al,ds:[di]				; read the next character into al
	
	; lowercase it (if alpha and uppercase)
	cmp al,41h					; Char A
	jl PCL_NotUpper
	cmp al,5ah					; Char Z
	jg PCL_NotUpper	
	add al,20h					; Add 32 (20h) to make it lowercase

PCL_NotUpper:
	
	cmp ah,0					; switch on the different states
	je PCL_status_0
	cmp ah,1
	je PCL_status_1
	cmp ah,2
	je PCL_status_2
	or cl,1						; set first bit to 1 indicating error
	jmp PCL_Ret					

PCL_status_0:
	cmp al,20h					; is char space?
	je PCL_next_char
	cmp al,2dh					; is char dash?
	je PCL_change_state1		
	or cl,1						; set first bit to 1 indicating error
	jmp PCL_Ret		
	
PCL_status_1:
	cmp al,61h					; is 'a'?
	je PCL_found_char
	cmp al,76h					; is 'v'?
	je PCL_found_char
	or cl,1						; set first bit to 1 indicating error
	jmp PCL_Ret		

PCL_status_2:
	cmp al,20h					; is char space?
	je PCL_store_and_move
	or cl,1						; set first bit to 1 indicating error
	jmp PCL_Ret	
	
PCL_store_and_move:
	mov ah,0
	cmp bh,61h					; is 'a'?
	je PCL_set_autorun_flag
	cmp bh,76h					; is 'v'?
	je PCL_set_verbose_flag
	or cl,1						; set first bit to 1 indicating error
	jmp PCL_Ret	

PCL_set_autorun_flag:
	or cl,4						; set 3rd bit to 1
	jmp PCL_next_char

PCL_set_verbose_flag:
	or cl,2						; set 2nd bit to 1
	jmp PCL_next_char

PCL_found_char:
	mov ah,2					; set state=2
	mov bh,al					; copy the found char to bh
	jmp PCL_next_char

PCL_change_state1:
	mov ah,1					; set state=1 

	; are there more characters? 
PCL_next_char:
	dec bl
	cmp bl,0
	je PCL_End
	inc di
	jmp PCL_continue

PCL_set_autorun_flag_last:
	or cl,4						; set 3rd bit to 1
	jmp PCL_Ret

PCL_set_verbose_flag_last:
	or cl,2						; set 2nd bit to 1
	jmp PCL_Ret
	
PCL_End:
	cmp ah,2					; if it is really done, check if we have
	jne PCL_Ret
	cmp bh,61h					; is 'a'?
	je PCL_set_autorun_flag_last
	cmp bh,76h					; is 'v'?
	je PCL_set_verbose_flag_last
	jmp PCL_End

PCL_Ret:

	ret	
_CL_PARSE_COMMAND_LINE ENDP

;----
; _CL_INITIALIZE
; Check parameters and determined run mode (command line vs interactive)
; Inputs:
; 	- cl contains the flags for command line
; Output: None
; Destroys: None
;----
PUBLIC _CL_INITIALIZE
_CL_INITIALIZE PROC
	mov ch,cl                                   ; Copy cl
	and ch,1									; if the first bit is 1 then we have error
	cmp ch,1
	je command_line_error
	
	mov ch,cl									; Copy cl
	and ch,2									; if the second bit is 1 then Verbose is enabled
	cmp ch,2					
	jne check_autorun
	
	mov ah,09h									; Display Verbose enabled message									
	mov dx,OFFSET VerboseEnMsg	
	int 21h										; INT 21h, Function 09h - Print string to console
	mov _VerboseEnableFlag,1
	
check_autorun:
	mov ch,cl									; Copy cl
	and ch,4									; if the third bit is 1 then Autorun is enabled
	cmp ch,4					
	jne init_end
	
	mov ah,09h
	mov dx,OFFSET AutoRunMsg	
	int 21h										; INT 21h, Function 09h - Print string to console
	mov _AutoRunFlag,1
	jmp init_end	

command_line_error:
	mov ah,09h
	mov dx,OFFSET CommLineErrorMsg
	int 21h										; INT 21h, Function 09h - Print string to console
	
	mov ah,09h
	mov dx,OFFSET SyntaxMsg
	int 21h										; INT 21h, Function 09h - Print string to console
	
	mov _CommandLineErrorFlag,1

init_end:	
	ret
_CL_INITIALIZE ENDP


END