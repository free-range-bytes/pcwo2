; PCWO2.ASM
; 
; Description: Main program for PC Workout - This small program is designed to 
; run multiple computer functions to ensure all aspects of the computer are 
; working as expected
;
; Author: Homero Trevino <homerotl@gmail.com>
    
.MODEL small

    F2_KEY_SCAN_CODE                EQU 3ch
    F3_KEY_SCAN_CODE                EQU 3dh
    F4_KEY_SCAN_CODE                EQU 3eh
    F5_KEY_SCAN_CODE                EQU 3fh    
    F10_KEY_SCAN_CODE               EQU 44h
    
.STACK 100h

.DATA

	EXTRN _SCRN_VideoMode:BYTE                  ; From LIB/SCREEN.ASM
	
    EXTRN _CommandLineErrorFlag:BYTE            ; From COMMLN.ASM

    ; On this table we have the valid key inputs and the address
    ; where the corresponding procedure should be called if pressed
    ; The table format is:
    ;       db      72
    ;       dw      OFFSET_TEXT:PROCNAME
    ;       ... repeat for each option
    ;       db      0   ; End of table
    dispatch_table LABEL BYTE
        db  F2_KEY_SCAN_CODE
        dw  OFFSET _TEXT:_TEST_FLOPPY
        db  F3_KEY_SCAN_CODE
        dw  OFFSET _TEXT:_SCREEN_GEOMETRY_TEST
        db  F4_KEY_SCAN_CODE
        dw  OFFSET _TEXT:_TEST_PC_SPEAKER
        db  F5_KEY_SCAN_CODE
        dw  OFFSET _TEXT:_TEST_BENCHMARK_CPU
        db  0                                   ; End of table
            
.CODE
    .8086
    JUMPS

    EXTRN _CL_PARSE_COMMAND_LINE:PROC           ; From COMMLN.ASM
    EXTRN _CL_INITIALIZE:PROC

    EXTRN _UI_SETUP:PROC                        ; From UI.ASM
    EXTRN _UI_DISPLAY_MENU:PROC
    EXTRN _UI_TEARDOWN:PROC
    EXTRN _UI_ENSURE_MENU_VIDEO_MODE:PROC

    EXTRN _TEST_PC_SPEAKER:PROC                 ; From T_SPEAKER.ASM 
    EXTRN _SCREEN_GEOMETRY_TEST:PROC            ; From T_SCREEN.ASM 
        
    EXTRN _SCRN_SET_VIDEO_MODE:PROC             ; From LIB/SCREEN.ASM
	EXTRN _SCRN_DISABLE_CURSOR:PROC
	EXTRN _SCRN_DISABLE_BLINKING_TEXT:PROC
	EXTRN _SCRN_SAVE_UI_SCR:PROC
	EXTRN _SCRN_RESTORE_UI_SCR:PROC
    
    
    EXTRN _TEST_FLOPPY:PROC                     ; From T_FLOPPY.ASM
    EXTRN _TEST_CPU_FPU_DETECTION:PROC          ; From T_CPU_FPU.ASM
    EXTRN _TEST_BENCHMARK_CPU:PROC

    EXTRN _KB_READ_KEY:PROC                     ; From LIB/KB.ASM
    EXTRN _KB_FLUSH_BUFFER:PROC

MAIN PROC                                       ; Main program

    call _CL_PARSE_COMMAND_LINE

    mov ax,@DATA                                ; Align data segment
    mov ds,ax                                   ; Set DS to the data segment
    and sp, not 3

    call _CL_INITIALIZE                         ; This checks for command line parameters
    
    cmp _CommandLineErrorFlag,1                 ; Check if command line parsing was fine
    je m_end

    call _UI_SETUP                              ; Change video mode and paint initial screen
    
    call _TEST_CPU_FPU_DETECTION                ; Run one-time detection procedure

    call _UI_DISPLAY_MENU                       ; Display menu

    call DISPATCHER                             ; Wait for KB input and act on it

    call _UI_TEARDOWN                           ; Return to 80 column text mode 

m_end:

    mov ah,4ch                                  ; INT 21h, Function 4ch - End program    
    int 21h    

MAIN ENDP

;----
; DISPATCHER
; Read a key press and attempts to map it to one of the function keys listed
; on dispatch_table
; Inputs: None
; Output: None
; Destroys: None
;----
DISPATCHER PROC
    push ax
    push bx
    push dx
    
dis_loop:
                 
    call _SCRN_SAVE_UI_SCR                      ; save current screen
    	
    call _KB_FLUSH_BUFFER                       ; Flush KB buffer
        
    call _KB_READ_KEY                           ; Read a character into ax
    or ah,ah                                    ; ax = -1 if no charcter read, 1 for
                                                ; extended code
    js dis_loop
    jnz dis_special_key
    jmp dis_loop
   
dis_special_key:
    
    cmp al,F10_KEY_SCAN_CODE                    ; Check for exit key
    je dis_end_dispatcher    
    lea bx,dispatch_table                       ; Lookup code on the table    
    
dis_special_loop:
    cmp byte ptr [bx],0                         ; End of table?
    je dis_loop                                 ; Key was not in table
    cmp al,[bx]
    je dis_dispatch
    add bx,3
    jmp dis_special_loop                        ; Check the next table entry

dis_dispatch:
    inc bx                                      ; point to the address of procedure
    call word ptr[bx]                           ; call procedure
                                        
	call _UI_ENSURE_MENU_VIDEO_MODE

	call _SCRN_RESTORE_UI_SCR                   ; restore screen

    jmp dis_loop                                ; wait for another key

dis_end_dispatcher:
    pop dx
    pop bx
    pop ax
    
    ret
DISPATCHER ENDP

END