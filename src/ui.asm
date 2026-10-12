; UI.ASM
;
; User interface routines for PCWO2

.MODEL small

	INCLUDE VERSION.INC

    DEFAULT_VIDEO_MODE      EQU 03h ; 03h is 80x25. Could be set to 01h for 40x25
    
    COLUMNS                 EQU 80
    ROWS                    EQU 25
    	
; Color schema

	BACKGROUND_STYLE		EQU 07h  ; White text over Black background
	TITLE_STYLE				EQU 0B5h ; Violet text over Intense cyan background
	LABEL_STYLE				EQU 05h  ; Violet text over Black background
	DYN_INFO_STYLE			EQU 07h  ; White text over Black background
	MENU_OPTION_STYLE_EN	EQU 0Dh  ; Intense violet text over Black background
	MENU_OPTION_STYLE_DI	EQU 05h  ; Violet text over Black background
	STATUS_STYLE			EQU 0Fh  ; Intense white text over Black background

	
; Text layout
    STATUS_COL 				EQU 0ch
    STATUS_ROW				EQU 16h
    PROMPT_COL				EQU 0ch
    PROMPT_ROW 				EQU 17h

	CPU_ID_COL				EQU 05h
    CPU_ID_ROW				EQU 04h
    
    FPU_ID_COL				EQU 17h
    FPU_ID_ROW				EQU 04h
    
    CPU_BENCH_RESULT_COL	EQU 03h
    CPU_BENCH_RESULT_ROW	EQU 0ch
    CPU_BENCH_RESULT_VA_COL	EQU 0eh

    DRIVE_TEST_COL			EQU 03h
    DRIVE_ID_COL			EQU 0bh
    DRIVE_MEDIA_COL			EQU 1eh
    TRACK_NUM_COL			EQU 23h
    FD_READ_TEST_COL		EQU 11h
    FD_START_ROW			EQU 0dh
    DRIVE_LETTER_COL		EQU 09h 

        
.DATA
	
    EXTRN _SCRN_VideoMode:BYTE					; From LIB/SCREEN.ASM
	EXTRN _SCRN_Attribute:BYTE		
	EXTRN _SCRN_Position_X:BYTE
	EXTRN _SCRN_Position_Y:BYTE
	EXTRN _SCRN_One_Char:BYTE
	
	EXTRN _VER_VersionLbl:BYTE					; From VERSION.ASM

	PUBLIC _UI_DisplayMode
	_UI_DisplayMode				db 0			; 0 = 80x25 mode
												; 1 = 40x25 mode
												; 2 = ? Graphical modes?

    PUBLIC _UI_Drive_Index		
    _UI_Drive_Index             db 0			; Index of the drive being tested (0 = a;)

	PUBLIC _UI_Progress_FDT	
	_UI_Progress_FDT 			db 0			; number from 0 to 10 indicating progress

	PUBLIC _UI_Enter_Esc_Diag_Resp	
	_UI_Enter_Esc_Diag_Resp     db 0			; Response to ENTER or ESC dialog
												; 0=ESC, 1 = ENTER 
	
	FDTestBaseRow               db 0

	; For Int 21h usage
    GoodbyeMsg					db 'Goodbye!',13,10,'$' 	

	DriveTypeNMediaMsg	        db 'Drive                Media', 0 
	DriveReadTestMsg	        db 'Reading Test [          ] Track', 0 
	BlankStatusMsg              db '                           ', 0
    MediaNotPresentMsg          db 'Media not present', 0
    RetrySkipMsg                db '[ENTER] retry  [ESC] skip  ', 0
	ProgressChar                db '=', 0
    PCSpeakerTestPlaying		db 'PC Speaker music playing..', 0
   	PressAnyKeyToStop			db 'Press any key to stop', 0
   	PressAnyKeyToContinue       db 'Press any key to continue', 0
   	TestingCPUMsg				db 'Testing CPU...', 0
    BenchmarkResultMsg          db 'CPU Score:',0
    
    HelloWorldMsg               db 'Hello World!',0 
    
	PUBLIC _BlankColStart
	_BlankColStart				db 0
	
	PUBLIC BlankColEnd
	BlankColEnd					db 0
	
	PUBLIC BlankRowStart
	BlankRowStart				db 0
	
	PUBLIC BlankRowEnd
	BlankRowEnd					db 0
   	
								;     X,   Y, Attribute  , String
   	StaticLabels				db	01h, 01h, TITLE_STYLE,	'PC Workout v2', 0
   								db	39h, 01h, TITLE_STYLE,	'Free Range Bytes, LLC', 0
   								db	01h, 03h, LABEL_STYLE,	'Information', 0
   								db	01h, 04h, LABEL_STYLE,	'CPU', 0
   								db	13h, 04h, LABEL_STYLE,	'FPU', 0						
   								db	44h, 18h ,BACKGROUND_STYLE, VERSION_LBL, 0							
   								db	0ffh ; End of data
    							
								;	  X,   Y, Enabled, String
	Buttons						db	01h, 06h, 01h, '[F2] Floppy Test  ', 0
								db	15h, 06h, 01h, '[F3] Video Test   ', 0
								db	29h, 06h, 01h, '[F4] Speaker Test ', 0
								db	3dh, 06h, 01h, '[F5] CPU Benchmark', 0
								db	01h, 17h, 01h, '[F10] Exit', 0
								db	0ffh ; End of data

.CODE		
	.8086
	JUMPS

    EXTRN _KB_ENTER_ESC_Q:PROC                      ; From LIB/KB.ASM    
	EXTRN _SCRN_PRINT_TEXT:PROC                     ; From LIB/SCREEN.ASM
	EXTRN _SCRN_SET_VIDEO_MODE:PROC				
	EXTRN _SCRN_SET_BACKGROUND:PROC
	EXTRN _SCRN_DISABLE_CURSOR:PROC
	EXTRN _SCRN_DISABLE_BLINKING_TEXT:PROC
	EXTRN _SCRN_PRINT_TEXT:PROC
	EXTRN _SCRN_PRINT_CHAR:PROC
	EXTRN _SCRN_SAVE_OSCREEN:PROC
	EXTRN _SCRN_RESTORE_OSCREEN:PROC
	EXTRN _STR_STR_LEN:PROC                         ; From LIB/STRINGS.ASM
	EXTRN _WINDOW_SETUP:PROC                        ; From LIB/WINDOW.ASM
	EXTRN _WINDOW_SHOW:PROC
	EXTRN _WINDOW_WRITELN:PROC
	
;----
; _UI_ENSURE_MENU_VIDEO_MODE
; Ensure menu video mode
; Inputs: None
; Output: None
; Destroys: None
;----
PUBLIC _UI_ENSURE_MENU_VIDEO_MODE
_UI_ENSURE_MENU_VIDEO_MODE PROC
	
	mov _SCRN_VideoMode,DEFAULT_VIDEO_MODE          ; Setup text mode 3 (Text 80x25)								
	call _SCRN_SET_VIDEO_MODE							
	call _SCRN_DISABLE_CURSOR			 
	call _SCRN_DISABLE_BLINKING_TEXT	
	
	ret
_UI_ENSURE_MENU_VIDEO_MODE ENDP


;----
; _UI_SETUP
; Set the basic screen with the video mode, background, titles and basic options.
; Inputs: None
; Output: None
; Destroys: None
;----
PUBLIC _UI_SETUP
_UI_SETUP PROC

	push si
	
	call _SCRN_SAVE_OSCREEN						; Save current video mode and screen
	
	call _UI_ENSURE_MENU_VIDEO_MODE

	mov _SCRN_Attribute,BACKGROUND_STYLE 
	call _SCRN_SET_BACKGROUND

	lea si,StaticLabels	
	call RENDER_LABELS
	
	pop si
	
	ret
_UI_SETUP ENDP

;----
; _UI_TEARDOWN
; Return text mode to 80x25.
; Inputs: None
; Output: None
; Destroys: None
;----
PUBLIC _UI_TEARDOWN
_UI_TEARDOWN PROC

	call _SCRN_RESTORE_OSCREEN					; Restore original screen
	
	mov ah,09h									; INT 21h, Function 09h - Print string to console
	mov dx,OFFSET GoodbyeMsg	
	int 21h		
	
	ret
_UI_TEARDOWN ENDP


RENDER_LABELS PROC
_UIS_PrintAllLabels:
	cmp byte ptr [si],0ffh
	je _UIS_AllLabelsDone

	mov al,byte ptr [si]
	mov _SCRN_Position_X,al						; Copy X (column)
	inc si
	mov al,byte ptr [si]
	mov _SCRN_Position_Y,al						; Copy Y (row)
	inc si	
	mov al, byte ptr [si]
	mov _SCRN_Attribute,al						; Copy color attribute
	inc si
	call _SCRN_PRINT_TEXT
_UIS_LookForEndOfLabel:
	cmp byte ptr [si],0
	je _UIS_FoundEndOfLabel
	inc si
	jmp _UIS_LookForEndOfLabel
_UIS_FoundEndOfLabel:
	inc si
	jmp _UIS_PrintAllLabels
_UIS_AllLabelsDone:
	ret
RENDER_LABELS ENDP

;----
; _UI_SET_STATUS
; Display text in the status area
; Inputs: si points to the text to display. Must be null terminated.
; Output: none
; Destroys: none
;----
PUBLIC _UI_SET_STATUS
_UI_SET_STATUS PROC
    push ax
    push cx                             ; save cx
    call _STR_STR_LEN                   ; get string length on cx
    mov ax,COLUMNS                      ; x = (80 - cx) / 2
    sub ax,cx
    shr ax,1                            ; divide by 2
	mov _SCRN_Attribute,STATUS_STYLE	
	mov _SCRN_Position_X,al
	mov _SCRN_Position_Y,STATUS_ROW
	call _SCRN_PRINT_TEXT
	pop cx
	pop ax
	ret
_UI_SET_STATUS ENDP

;----
; _UI_SET_PROMPT
; Display text in the prompt area
; Inputs: si points to the text to display. Must be null terminated.
; Output: none
; Destroys: none
;----
PUBLIC _UI_SET_PROMPT
_UI_SET_PROMPT PROC
    push ax
    push cx                             ; save cx
    call _STR_STR_LEN                   ; get string length on cx
    mov ax,COLUMNS                      ; x = (80 - cx) / 2
    sub ax,cx
    shr ax,1                            ; divide by 2
	mov _SCRN_Attribute,STATUS_STYLE	
	mov _SCRN_Position_X,al
	mov _SCRN_Position_Y,PROMPT_ROW
	call _SCRN_PRINT_TEXT
	pop cx
	pop ax
	ret
_UI_SET_PROMPT ENDP

;----
; _UI_CLEAR_STATUS
; Clear the status bar text
; Inputs: none
; Output: none
; Destroys: none
;----
PUBLIC _UI_CLEAR_STATUS
_UI_CLEAR_STATUS PROC
    lea si,BlankStatusMsg
	mov _SCRN_Attribute,STATUS_STYLE	
	mov _SCRN_Position_X,STATUS_COL
	mov _SCRN_Position_Y,STATUS_ROW
	call _SCRN_PRINT_TEXT
	ret
_UI_CLEAR_STATUS ENDP

;----
; _UI_CLEAR_PROMPT
; Clear the prompt text label
; Inputs: none
; Output: none
; Destroys: none
;----
PUBLIC _UI_CLEAR_PROMPT
_UI_CLEAR_PROMPT PROC
    lea si,BlankStatusMsg
	mov _SCRN_Attribute,STATUS_STYLE	
	mov _SCRN_Position_X,PROMPT_COL
	mov _SCRN_Position_Y,PROMPT_ROW
	call _SCRN_PRINT_TEXT
	ret
_UI_CLEAR_PROMPT ENDP

;----
; _UI_DRIVE_TEST_TITLES
; Display titles for one drive info
; Inputs: _UI_Drive_Index
; Output: none
; Destroys: none
;----
PUBLIC _UI_DRIVE_TEST_TITLES
_UI_DRIVE_TEST_TITLES PROC
    mov _SCRN_Attribute,LABEL_STYLE			; set style
    mov _SCRN_Position_X,DRIVE_TEST_COL		; set the column 
                                       		; calculate the row
    call FD_TEST_CALCULATE_BASE_ROW
											; calculate the row
    push ax                            		; save registers
    
    mov al,FDTestBaseRow
    mov _SCRN_Position_Y,al            
	
	lea si,DriveTypeNMediaMsg	
	call _SCRN_PRINT_TEXT
	
	mov al,'A'                              ; Starting drive letter in ASCII
	add al,_UI_Drive_Index                  ; plus the drive index
	mov _SCRN_One_Char,al
    mov _SCRN_Position_X,DRIVE_LETTER_COL	; set the column 
	call _SCRN_PRINT_CHAR					; output the char in the register al to the coordinates

    mov _SCRN_Position_X,DRIVE_TEST_COL		; set the column 
	inc _SCRN_Position_Y
	lea si,DriveReadTestMsg	
	call _SCRN_PRINT_TEXT
	
	pop ax									; restore registers                         

	ret
_UI_DRIVE_TEST_TITLES ENDP

;----
; _UI_ADD_FD_TYPE_VALUE
; Display the value for drive type
; Inputs: 
;  - _UI_Drive_Index
;  - si points to the text to display. Must be null terminated.
; Output: none
; Destroys: none
;----
PUBLIC _UI_ADD_FD_TYPE_VALUE
_UI_ADD_FD_TYPE_VALUE PROC
    mov _SCRN_Attribute,DYN_INFO_STYLE		; set style
    mov _SCRN_Position_X,DRIVE_ID_COL		; set the column 
											; calculate the row
    call FD_TEST_CALCULATE_BASE_ROW
											; calculate the row
    push ax									; save registers
    
    mov al,FDTestBaseRow
    mov _SCRN_Position_Y,al            

    pop ax 									; restore register                         
	call _SCRN_PRINT_TEXT
	ret
_UI_ADD_FD_TYPE_VALUE ENDP

;----
; _UI_ADD_FD_MEDIA_VALUE
; Display the value for media type
; Inputs: 
;  - _UI_Drive_Index
;  - si points to the text to display. Must be null terminated.
; Output: none
; Destroys: none
;----
PUBLIC _UI_ADD_FD_MEDIA_VALUE
_UI_ADD_FD_MEDIA_VALUE PROC
    mov _SCRN_Attribute,DYN_INFO_STYLE		; set style
    mov _SCRN_Position_X,DRIVE_MEDIA_COL	; set the column 
											; calculate the row
    call FD_TEST_CALCULATE_BASE_ROW
											; calculate the row
    push ax									; save registers
    mov al,FDTestBaseRow
    mov _SCRN_Position_Y,al            

    pop ax									; restore register                        
	call _SCRN_PRINT_TEXT
	ret
_UI_ADD_FD_MEDIA_VALUE ENDP

;----
; _UI_PRINT_TRACK_NUM
; Display the track number being read
; Inputs: 
;  - _UI_Drive_Index
;  - si points to a string with the track number being read
; Output: none
; Destroys: none
;----
PUBLIC _UI_PRINT_TRACK_NUM
_UI_PRINT_TRACK_NUM PROC
    mov _SCRN_Attribute,DYN_INFO_STYLE	; set style
    mov _SCRN_Position_X,TRACK_NUM_COL	; set the column 
    
    call FD_TEST_CALCULATE_BASE_ROW
										; calculate the row
    push ax								; save registers
    mov al,FDTestBaseRow
    inc al								; 2nd row    
    mov _SCRN_Position_Y,al            

    pop ax								; restore registers
	call _SCRN_PRINT_TEXT
	ret
_UI_PRINT_TRACK_NUM ENDP

;----
; _UI_DISPLAY_FD_PROGRESS
; Fill the progress bar of the current drive index with as many marks
; as indicated in _UI_Progress_FDT [0 to 10]
; Inputs: 
;  - _UI_Drive_Index
;  - _UI_Progress_FDT
; Output: none
; Destroys: none
;----
PUBLIC _UI_DISPLAY_FD_PROGRESS
_UI_DISPLAY_FD_PROGRESS PROC

    cmp _UI_Progress_FDT,0					; Reset progress at 0
    je ui_display_fd_prog_end
    
    lea si,ProgressChar
    mov _SCRN_Attribute,DYN_INFO_STYLE   	; set style
    mov _SCRN_Position_X,FD_READ_TEST_COL	; set the column 
                                            ; calculate the row

    call FD_TEST_CALCULATE_BASE_ROW
    
    push ax									; save registers
    push cx
    
    mov al,FDTestBaseRow
    inc al									; 2nd row
    mov _SCRN_Position_Y,al            
    
    xor cx,cx								; setup the counter
    mov cl,_UI_Progress_FDT

repeat_print_prog_char:
    call _SCRN_PRINT_TEXT 
    inc _SCRN_Position_X
    loop repeat_print_prog_char                 
    
    pop cx									; restore registers
    pop ax
    
ui_display_fd_prog_end:
	ret
_UI_DISPLAY_FD_PROGRESS ENDP


;----
; _UI_FD_READ_TEST_RESULT
; Display drive test status message
; Inputs: 
;  - _UI_Drive_Index
;  - si points to a string, null terminated of 10 chars
; Output: none
; Destroys: none
;----
PUBLIC _UI_FD_READ_TEST_RESULT
_UI_FD_READ_TEST_RESULT PROC
    
    call FD_TEST_CALCULATE_BASE_ROW
    
    push ax
    
    mov _SCRN_Attribute,DYN_INFO_STYLE		; set style
    mov _SCRN_Position_X,FD_READ_TEST_COL	; set the column 
    inc FDTestBaseRow
    mov al,FDTestBaseRow
    mov _SCRN_Position_Y,al
    call _SCRN_PRINT_TEXT 
    
    pop ax
    
	ret
_UI_FD_READ_TEST_RESULT ENDP

;----
; _UI_PROMPT_INSERT_MEDIA
; Display a user prompt to select between two options
; Inputs:
; Output: _UI_Enter_Esc_Diag_Resp = 0 if ESC, = 1 if ENTER
; Destroys: none
;----
PUBLIC _UI_PROMPT_INSERT_MEDIA
_UI_PROMPT_INSERT_MEDIA PROC
    
    push ax
    
    call _UI_CLEAR_PROMPT
    call _UI_CLEAR_STATUS

    lea si,MediaNotPresentMsg
    call _UI_SET_STATUS
    
    lea si,RetrySkipMsg
    call _UI_SET_PROMPT
 
kb_pimp_retry:
   
    call _KB_ENTER_ESC_Q

    cmp al,00h                 ; is it ESC?
    je kb_pimp_esc
    
    cmp al,01h                 ; is it ENTER?
    je kb_pimp_enter
    
    jmp kb_pimp_retry

kb_pimp_esc:
    mov _UI_Enter_Esc_Diag_Resp,0
    jmp kb_pimp_end

kb_pimp_enter:
    mov _UI_Enter_Esc_Diag_Resp,1
    jmp kb_pimp_end
       
kb_pimp_end:
    
    call _UI_CLEAR_PROMPT
    call _UI_CLEAR_STATUS
    
    pop ax
    
	ret
_UI_PROMPT_INSERT_MEDIA ENDP

;----
; _UI_DISPLAY_MENU
; Render all menu options in their correct status
; Inputs: None
; Output: None
; Destroys: None
;----
PUBLIC _UI_DISPLAY_MENU
_UI_DISPLAY_MENU PROC	
	lea si,Buttons
	call RENDER_BUTTONS
	
	; TODO: Remove from here
	; call _WINDOW_SETUP
	; call _WINDOW_SHOW
	
	; lea si,HelloWorldMsg
	; call _WINDOW_WRITELN
	
	ret
_UI_DISPLAY_MENU ENDP

RENDER_BUTTONS PROC
_UIS_RenderAllButtons:
	cmp byte ptr [si],0ffh
	je _UIS_AllButtonsDone

	mov al,byte ptr [si]
	mov _SCRN_Position_X,al						; Copy X (column)
	inc si
	mov al,byte ptr [si]
	mov _SCRN_Position_Y,al						; Copy Y (row)
	inc si	
	inc si										; skip the active-byte
	mov _SCRN_Attribute,MENU_OPTION_STYLE_EN	; Copy color attribute
	call _SCRN_PRINT_TEXT
_UIS_LookForEndOfString:
	cmp byte ptr [si],0
	je _UIS_FoundEndOfString
	inc si
	jmp _UIS_LookForEndOfString
_UIS_FoundEndOfString:
	inc si
	jmp _UIS_RenderAllButtons
_UIS_AllButtonsDone:
	ret
RENDER_BUTTONS ENDP

;----
; _UI_PRINT_CPU_ID
; Print the CPU ID
; Inputs: SI has the label to display
; Output: None
; Destroys: None
;----
PUBLIC _UI_PRINT_CPU_ID
_UI_PRINT_CPU_ID PROC    
	mov _SCRN_Attribute,DYN_INFO_STYLE	
	mov _SCRN_Position_X,CPU_ID_COL
	mov _SCRN_Position_Y,CPU_ID_ROW
	call _SCRN_PRINT_TEXT
	
	ret
_UI_PRINT_CPU_ID ENDP

;----
; _UI_PRINT_CPU_BENCHMARK
; Print the CPU benchmark results
; Inputs: SI has the string value of the benchmark result
; Output: None
; Destroys: None
;----
PUBLIC _UI_PRINT_CPU_BENCHMARK
_UI_PRINT_CPU_BENCHMARK PROC
    push si

	mov _SCRN_Attribute,DYN_INFO_STYLE	
	mov _SCRN_Position_X,CPU_BENCH_RESULT_COL
	mov _SCRN_Position_Y,CPU_BENCH_RESULT_ROW
    lea si,BenchmarkResultMsg    
    call _SCRN_PRINT_TEXT
    
    pop si  	
	mov _SCRN_Position_X,CPU_BENCH_RESULT_VA_COL
	call _SCRN_PRINT_TEXT
	ret
	
_UI_PRINT_CPU_BENCHMARK ENDP

;----
; _UI_PRINT_FPU_ID
; Print the FPU ID
; Inputs: SI has the label to display
; Output: None
; Destroys: None
;----
PUBLIC _UI_PRINT_FPU_ID
_UI_PRINT_FPU_ID PROC
	mov _SCRN_Attribute,DYN_INFO_STYLE	
	mov _SCRN_Position_X,FPU_ID_COL
	mov _SCRN_Position_Y,FPU_ID_ROW
	call _SCRN_PRINT_TEXT
	ret
_UI_PRINT_FPU_ID ENDP

;----
; FD_TEST_CALCULATE_BASE_ROW
; Calculate the base row for the floppy drive test results
; Inputs: 
;  - _UI_Drive_Index
; Output: FDTestBaseRow has the Y value for the base row
; Destroys: none
;----
FD_TEST_CALCULATE_BASE_ROW PROC
    push ax                            ; save registers
    push bx
    xor ax,ax                          ; ax=0
    mov al,_UI_Drive_Index
    mov bl,03h                         ; 
    mul bl                             ; each drive takes 3 rows,  ax = al*bl
    add al,FD_START_ROW                ; add start row
    mov FDTestBaseRow,al  
    pop bx                             ; restore registers
    pop ax  
	ret
FD_TEST_CALCULATE_BASE_ROW ENDP

;----
; _UI_PROMPT_PCSPKR_PLAYING
; Display a message to the user that the speaker test is playing,
; but that it can be interrupted with any key
; Inputs: none
; Output: none
; Destroys: none
;----
PUBLIC _UI_PROMPT_PCSPKR_PLAYING
_UI_PROMPT_PCSPKR_PLAYING PROC
        
    call _UI_CLEAR_PROMPT
    call _UI_CLEAR_STATUS

    lea si,PCSpeakerTestPlaying
    call _UI_SET_STATUS
    
    lea si,PressAnyKeyToStop
    call _UI_SET_PROMPT
    
    ret
_UI_PROMPT_PCSPKR_PLAYING ENDP


;----
; _UI_DISPLAY_PRESS_ANY_KEY
; Display a message to the user that the speaker test is playing,
; but that it can be interrupted with any key
; Inputs: none
; Output: none
; Destroys: none
;----
PUBLIC _UI_DISPLAY_PRESS_ANY_KEY
_UI_DISPLAY_PRESS_ANY_KEY PROC
        
    call _UI_CLEAR_PROMPT

    lea si,PressAnyKeyToContinue
    call _UI_SET_STATUS

    ret
_UI_DISPLAY_PRESS_ANY_KEY ENDP

END