; T_FLOPPY.ASM
; Source for the Floppy drive tests
; Author: Homero Trevino <homerotl@gmail.com>
.MODEL small

	MAX_RETRIES EQU 4	

.DATA

	EXTRN _VerboseEnableFlag:BYTE	 ; Global flags
	EXTRN _AutoRunFlag:BYTE							
	EXTRN _DIO_NumberOfDisks:BYTE    ; From DISK_IO.ASM
	EXTRN _DIO_DriveType:BYTE	
	EXTRN _DIO_MediaType:BYTE			
  	EXTRN _UI_Drive_Index:BYTE       ; From UI.ASM
	EXTRN _UI_Progress_FDT:BYTE
	EXTRN _UI_Enter_Esc_Diag_Resp:BYTE
	EXTRN _NumToAsciiB:BYTE			 ; From LIB/STRINGS.ASM
	
	StatusEnumDrivesMsg	db 'Counting drives...', 0 		
	StatusDetDrTypeMsg  db 'Detect drive type...', 0 
	StatusDetMedTypeMsg db 'Detect media type...', 0 
	StatusReadTestMsg   db 'Surface read test...', 0
	RetryMsgQ      		db 'Would you like to retry? (Y/N)', 0
	NoFloppyDrivesMsg	db 'No drives detected', 0

	DDT_0				db '5.25"-360KB', 0
	DDT_1				db '5.25"-1.2MB', 0
	DDT_2				db '3.5"-720KB', 0
	DDT_3				db '3.5"-1.44MB', 0
	DDT_4				db '3.5"-2.88MB', 0
	DDT_UK				db 'Unknown', 0

	DMT_0				db '360KB', 0
	DMT_1				db '1.2MB', 0
	DMT_2				db '720KB', 0
	DMT_3				db '1.44MB', 0
	DMT_4				db '2.88MB', 0
	DMT_UNKNOWN			db 'Unknown', 0
	DMT_EMPTY           db 'Empty', 0
	DMT_FATAL_ERROR     db 'Error', 0
	
	FDTestSuccess       db 'Success!  ', 0
	FDTestFail          db 'Test Fail ', 0
	FDTestAbort         db 'Aborted   ', 0
	
	ReadRetries    		db 0
	CurrentDriveIndex 	db 0
	SectorsToRead		db 0
	CylindersToRead		db 0
	ReadTestStatus		db 0
	
.CODE
    .8086
	JUMPS

	EXTRN _STR_CHAR_TO_STRING:PROC				 	 ; From LIB/STRINGS.ASM	
	EXTRN _STR_PROGRESS_CALC:PROC
	EXTRN _DIO_READ_SECTOR:PROC                      ; From LIB/DISK_IO.ASM
	EXTRN _DIO_RESET_DISK_SYSTEM:PROC	
	EXTRN _DIO_INT13H_ERROR_IS_SYS_RETRIABLE:PROC
	EXTRN _DIO_INT13H_ERROR_IS_USER_RETRIABLE:PROC
	EXTRN _DIO_GET_NUMBER_OF_FD:PROC	
	EXTRN _DIO_DETECT_FD_TYPE:PROC
	EXTRN _DIO_DETECT_MEDIA_TYPE:PROC
	EXTRN _UI_SET_STATUS:PROC                        ; From UI.ASM
	EXTRN _UI_DRIVE_TEST_TITLES:PROC
	EXTRN _UI_ADD_FD_TYPE_VALUE:PROC
	EXTRN _UI_ADD_FD_MEDIA_VALUE:PROC
	EXTRN _UI_CLEAR_STATUS:PROC
	EXTRN _UI_PRINT_TRACK_NUM:PROC
	EXTRN _UI_DISPLAY_FD_PROGRESS:PROC
	EXTRN _UI_FD_READ_TEST_RESULT:PROC
	EXTRN _UI_PROMPT_INSERT_MEDIA:PROC
	EXTRN _UI_CLEAR_PROMPT:PROC
    EXTRN _UI_DISPLAY_PRESS_ANY_KEY:PROC
	EXTRN _KB_YES_NO_Q:PROC							; From LIB/KB.ASM
	EXTRN _KB_WAIT_ANY_KEY:PROC

;----
; _TEST_FLOPPY 
; Procedure to detect system floppy drives, identify and test them
; Inputs: None
; Output: None
; Destroys: All registers
;----
PUBLIC _TEST_FLOPPY
_TEST_FLOPPY PROC
	
	lea si,StatusEnumDrivesMsg			
    call _UI_SET_STATUS
    
	call _DIO_GET_NUMBER_OF_FD			; Check number of floppy drives,
										; retuns DIONumberOfDisks
    call _UI_CLEAR_STATUS
    
    mov bl,_DIO_NumberOfDisks
	cmp bl,0			; If its 0 we are done
	je TF_NoFloppyDrives
	
	cmp _DIO_NumberOfDisks,0feh			; If error we are done
	je TF_NoFloppyDrives
	
	cmp _DIO_NumberOfDisks,0ffh			; If error we are done
	je TF_NoFloppyDrives
	
	mov CurrentDriveIndex,0				; start with drive 0
	
TF_Continue:

	mov dl,CurrentDriveIndex	
	mov _UI_Drive_Index,dl				; copy it here so the UI lib knows which row is this
	
	lea si,StatusDetDrTypeMsg		
    call _UI_SET_STATUS
    
    mov dl,CurrentDriveIndex
	call _DIO_DETECT_FD_TYPE

    call _UI_CLEAR_STATUS

    call _UI_DRIVE_TEST_TITLES
          
	call DISPLAY_DRIVE_TYPE			
	
	cmp _DIO_DriveType,0ffh				; If drive type was error, skip to next drive
	je TF_NextDrive

TF_Retry_Media_Det:

	lea si,StatusDetMedTypeMsg 		
    call _UI_SET_STATUS
    
	mov dl,CurrentDriveIndex
	call _DIO_DETECT_MEDIA_TYPE
	
	call _UI_CLEAR_STATUS
	    
	call DISPLAY_MEDIA_TYPE

	cmp _DIO_MediaType,0fch				; If unknown, skip prompt
	je TF_NextDrive	

	cmp _DIO_MediaType,0feh				; If user retriable, prompt for 
	je TF_PromptMediaInsert	            ; media insert
	
	cmp _DIO_MediaType,0ffh				; If fatal error, skip prompt
	je TF_NextDrive	

	lea si,StatusReadTestMsg		    ; If we know the media, and
    call _UI_SET_STATUS                 ; things look ok, just do the read test
	
	mov dl,CurrentDriveIndex	
	call TF_READ_TEST

  	call _UI_CLEAR_STATUS    
  	
    cmp ReadTestStatus,0ffh             ; Check for error
    je TF_ReadTestError
    
    cmp ReadTestStatus,01h              ; Check for user-aborted
    je TF_Aborted
                                                                           
    lea si,FDTestSuccess                ; Otherwise assume success
    call _UI_FD_READ_TEST_RESULT
    jmp TF_NextDrive
 
TF_PromptMediaInsert:
    call _UI_PROMPT_INSERT_MEDIA        ; 0=ESC, 1 = ENTER               
    cmp _UI_Enter_Esc_Diag_Resp,1       ; If ENTER then try again
    je TF_Retry_Media_Det
    jmp TF_NextDrive                    ; Else, go to next drive
   
TF_ReadTestError:                                     
    lea si,FDTestFail
    call _UI_FD_READ_TEST_RESULT
    jmp TF_NextDrive
        
TF_Aborted:
    lea si,FDTestAbort
    call _UI_FD_READ_TEST_RESULT
	jmp TF_NextDrive
	
TF_NoFloppyDrives:
	lea si,NoFloppyDrivesMsg		
    call _UI_SET_STATUS
	jmp TF_Done

TF_NextDrive:
	inc CurrentDriveIndex
	mov dl,CurrentDriveIndex
	cmp dl,_DIO_NumberOfDisks
	je TF_Done
	jmp TF_Continue

TF_Done:
    call _UI_DISPLAY_PRESS_ANY_KEY
    call _KB_WAIT_ANY_KEY

	ret
_TEST_FLOPPY ENDP

;----
; TF_READ_TEST 
; Prompt the use to insert a floppy disk on drive A and test it
; Assumes 2 side, assumes 512 bytes per sector/track
; Inputs:
;	- dl = drive to use (Flopies 0 = a:, 1 = b:,)
;   - SectorsToRead is a byte in the data segment to indicate the number of sectors to read
;	- CylindersToRead is a byte in the data segment to indicate the number of tracks/cylinders to read
; Output: 
;	- ReadTestStatus will contain a byte wuth the decimal value
;       - 0 if the test was successful
;       - 1 if the test was incomplete (aborted)
;       - 255 if the test ended in error
; Destroys:
;	- None
;----
TF_READ_TEST PROC
    mov ReadTestStatus,1               ; Default status is incomplete
	mov ReadRetries,0                  ; Reset retries
	
	mov ch,0                           ; start cylinder
	mov dh,0                           ; start head 
	
ContinueReading:

	cmp ch,CylindersToRead
	jge DoneReadingOk
	
	push ax
	mov ah,CylindersToRead             ; Max = cylinders to read
	mov al,ch                          ; current progress
	call _STR_PROGRESS_CALC
    mov _UI_Progress_FDT,ah            ; send current progress
	pop ax
	
	call _UI_DISPLAY_FD_PROGRESS      ; display it
	
	mov al,SectorsToRead
	call _DIO_READ_SECTOR
	
	jnc SuccessReading                 ; Carry flag, that means error

                                       ; Error handling. We assume ah has the error code
    call _DIO_INT13H_ERROR_IS_SYS_RETRIABLE
    cmp al,0
    je ErrorNotSystemRetryable
    
    							       ; It is system retryable
	cmp ReadRetries,MAX_RETRIES        ; Failed, lets check retries
	jge ErrorNotSystemRetryable        ; Maybe it could be user retriable
	inc ReadRetries                    ; increment Retries

	call _DIO_RESET_DISK_SYSTEM
	
	jmp ContinueReading                ; Try again

ErrorNotSystemRetryable:
	
	call _DIO_INT13H_ERROR_IS_USER_RETRIABLE
	
	cmp al,0
	je DoneWithError

	call PRINT_ERROR_CODE		; If it ended in error
	
	push ax						; Save registers
	
	lea si,RetryMsgQ
	call _UI_SET_STATUS

	call _KB_YES_NO_Q			; Check for the answer
	cmp al,0					; If No
	
	call _UI_CLEAR_STATUS
	
	pop ax				        ; Restore registers
	
	jz TF_RT_Done				; Go to the end
	
	mov ReadRetries,0			; Reset retries
	jmp ContinueReading

SuccessReading:

	cmp dh,0					; Is this head 0? yes, change to 1,
	je ChangeSide
	mov dh,0					; set back to head 0
	inc ch						; cylinder++
	jmp ContinueReading

ChangeSide:

	push ax
	
	mov ah,ch					; put the track on ah for converting to string
	call _STR_CHAR_TO_STRING	; convert the value in ah to an ASCII decimal string
	
	lea si,_NumToAsciiB	; String to show
	call _UI_PRINT_TRACK_NUM

	pop ax	

	mov dh,1					; set head to 1
	jmp ContinueReading
	
DoneWithError:
    mov ReadTestStatus,0ffh
	call PRINT_ERROR_CODE		; If it ended in error
	
	jmp	TF_RT_Done

DoneReadingOk:
    mov ReadTestStatus,0
    	
TF_RT_Done:
	ret
TF_READ_TEST ENDP

;----
; PRINT_ERROR_CODE 
; Handles error codes returned by int 13h and prints the error code as a decimal
; Inputs:
; 	- ah - error code
; Output: 
;	- none
; Destroys: none
;----
PRINT_ERROR_CODE PROC           ; TODO: Concatenate error message
	call _STR_CHAR_TO_STRING	; convert the value in ah to an ASCII decimal string
	lea si,_NumToAsciiB
    call _UI_SET_STATUS
	ret
PRINT_ERROR_CODE ENDP

;----
; DISPLAY_DRIVE_TYPE 
; Display the type of drive
; Inputs:
; 	- DIO_DriveType
; Output: 
;	- none
; Destroys: none
;----
DISPLAY_DRIVE_TYPE PROC
        	
	cmp _DIO_DriveType,0
	je TF_DDT_0
	
	cmp _DIO_DriveType,1
	je TF_DDT_1
	
	cmp _DIO_DriveType,2
	je TF_DDT_2

	cmp _DIO_DriveType,3
	je TF_DDT_3
	
	cmp _DIO_DriveType,4
	je TF_DDT_4
	
	lea si,DDT_UK
	jmp TF_DDT_End
	
TF_DDT_0:
	lea si,DDT_0
	jmp TF_DDT_End

TF_DDT_1:
	lea si,DDT_1
	jmp TF_DDT_End

TF_DDT_2:
	lea si,DDT_2
	jmp TF_DDT_End

TF_DDT_3:
	lea si,DDT_3
	jmp TF_DDT_End

TF_DDT_4:
	lea si,DDT_4
	jmp TF_DDT_End

TF_DDT_End:
    call _UI_ADD_FD_TYPE_VALUE
	ret
DISPLAY_DRIVE_TYPE ENDP

;----
; DISPLAY_MEDIA_TYPE 
; Display the type of media in the drive
; Inputs:
; 	- _DIO_MediaType
; Output: 
;	- none
; Destroys: none
;----
DISPLAY_MEDIA_TYPE PROC

	cmp _DIO_MediaType,0
	je FT_DMT_360K
	
	cmp _DIO_MediaType,1
	je FT_DMT_1220K

	cmp _DIO_MediaType,2
	je FT_DMT_720K
	
	cmp _DIO_MediaType,3
	je FT_DMT_1440K

	cmp _DIO_MediaType,4
	je FT_DMT_2880K
	
	cmp _DIO_MediaType,0fch         ; Unknown media type
	je FT_DMT_UNKNOWN

	cmp _DIO_MediaType,0feh         ; User retriable error
	je FT_DMT_EMPTY

	lea si,DMT_FATAL_ERROR
	jmp FT_DMT_End

FT_DMT_360K:
	lea si, DMT_0
	mov SectorsToRead,09h			; 09 (09h) sectors
	mov CylindersToRead,28h			; 40 (28h) cylinders/tracks
	jmp FT_DMT_End
	
FT_DMT_1220K:
	lea si,DMT_1
	mov SectorsToRead,0fh			; 15 (0fh) sectors
	mov CylindersToRead,50h			; 80 (50h) cylinders/tracks
	jmp FT_DMT_End

FT_DMT_720K:
	lea si,DMT_2
	mov SectorsToRead,09h			; 09 (09h) sectors
	mov CylindersToRead,50h			; 80 (50h) cylinders/tracks	
	jmp FT_DMT_End

FT_DMT_1440K:
	lea si,DMT_3
	mov SectorsToRead,12h			; 18 (12h) sectors
	mov CylindersToRead,50h			; 80 (50h) cylinders/tracks
	jmp FT_DMT_End

FT_DMT_2880K:
	lea si,DMT_4
	mov SectorsToRead,24h			; 36 (24h) sectors
	mov CylindersToRead,50h			; 80 (50h) cylinders/tracks
	jmp FT_DMT_End

FT_DMT_UNKNOWN:
    lea si,DMT_UNKNOWN
	jmp FT_DMT_End

FT_DMT_EMPTY:
    lea si,DMT_EMPTY
 
FT_DMT_End:
	call _UI_ADD_FD_MEDIA_VALUE
	ret
DISPLAY_MEDIA_TYPE ENDP

END