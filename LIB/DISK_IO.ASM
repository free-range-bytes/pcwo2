; DISK_IO.ASM
; Source for Disk I/O Procedures, mostly INT 13h calls
; Author: Homero Trevino <homerotl@gmail.com>

.MODEL small

	MAX_RETRIES						EQU 4
	BIOS_DATA_AREA					EQU 0040h

	DIO_DRIVE_TYPE_5_25_360KB		EQU 0
	DIO_DRIVE_TYPE_5_25_1200KB		EQU 1
	DIO_DRIVE_TYPE_3_5_720KB		EQU 2
	DIO_DRIVE_TYPE_3_5_1440KB		EQU 3
	DIO_DRIVE_TYPE_3_5_2880KB		EQU 4
	DIO_DRIVE_TYPE_UNKNOWN			EQU 0ffh
	
	DIO_MEDIA_TYPE_360K				EQU	0
	DIO_MEDIA_TYPE_1200K			EQU	1
	DIO_MEDIA_TYPE_720K				EQU 2
	DIO_MEDIA_TYPE_1440K			EQU 3
	DIO_MEDIA_TYPE_2880K			EQU 4	
	DIO_MEDIA_TYPE_UNKNOWN			EQU 0fch	; No error, but type unknown
	DIO_MEDIA_TYPE_SYS_RET_ERROR	EQU	0fdh	; System retryable error
	DIO_MEDIA_TYPE_USR_RET_ERROR	EQU	0feh	; User retryable error
	DIO_MEDIA_TYPE_FATAL_ERROR		EQU 0ffh	; Fatal error
	
.DATA
      	
	public _DIO_NumberOfDisks
	_DIO_NumberOfDisks 			db 0

	public _DIO_DriveType
	_DIO_DriveType 				db 0

	public _DIO_MediaType
	_DIO_MediaType				db 0
	
	SysRetryableList			db 06h,0ah,0bh,10h,80h,0aah,0cch,0ffh,00h ; 00 terminated
	UsrRetryableList			db 03h,0ah,0bh,10h,80h,0aah,0cch,0ffh,00h ; 00 terminated
	
								; Type,	Tracks,	Sectors,	Type
	Int_13h_Drive_Type_Table	db 01h, 27h, 	09h,		DIO_DRIVE_TYPE_5_25_360KB
								db 02h, 27h,	09h,		DIO_DRIVE_TYPE_5_25_360KB
								db 02h, 4fh,	0fh,		DIO_DRIVE_TYPE_5_25_1200KB
								db 03h, 4fh,	09h,		DIO_DRIVE_TYPE_3_5_720KB
								db 04h, 4fh,	09h,		DIO_DRIVE_TYPE_3_5_720KB
								db 04h, 4fh,	12h,		DIO_DRIVE_TYPE_3_5_1440KB
								db 05h, 4fh,	24h,		DIO_DRIVE_TYPE_3_5_2880KB
								db 00h	; Terminate data

																		  ; Stored little-endian style
	Media_Type_Total_Sectors_Table	db 0d0h, 02h,	DIO_MEDIA_TYPE_360K	  ; 02d0h (720 total sectors)
									db 60h, 09h,	DIO_MEDIA_TYPE_1200K  ; 0960h (2400 total sectors)
									db 0a0h, 05h,	DIO_MEDIA_TYPE_720K	  ; 05a0h (1440 total sectors)
									db 40h, 0bh,	DIO_MEDIA_TYPE_1440K  ; 0b40h (2880 total sectors)
									db 80h, 16h,	DIO_MEDIA_TYPE_2880K  ; 0b40h (5760 total sectors)
									db 00h	; Terminate data
	
	DIO_RetryCount              db 0
	DIO_DiskReadBuf				db 9216 dup(?) ; buffer to read from disk, uninitialized
		
.CODE
	.8086
	JUMPS

;----
; _DIO_DETECT_FD_TYPE
; Get type of floppy drive
; Inputs:
;   dl = drive number
; Output: 
;	DIO_DriveType will have a number with the type
; Destroys: none
;----
PUBLIC _DIO_DETECT_FD_TYPE
_DIO_DETECT_FD_TYPE PROC
	
	push ax							; save registers
	push bx
	push cx
	push dx
	push es
	push di
	push si
									; Default is Unknown
	mov _DIO_DriveType,DIO_DRIVE_TYPE_UNKNOWN
	
	mov ah,08h						; Function 08h int 13h - Get drive params
	int 13h							; bl=type, ch=tracks, cl=sectors
	
	lea si,Int_13h_Drive_Type_Table

DIO_DFDT_Loop:

	cmp byte ptr [si],00h			; Check if we are at the end
	je DIO_DFDT_END
	
	cmp byte ptr [si],bl			; Check drive type
	je DIO_DFDT_DriveTypeMatch		; Found drive type
	
	add si,4						; Skip to the next record
	
	jmp DIO_DFDT_Loop

DIO_DFDT_DriveTypeMatch:
	
	inc si
	cmp byte ptr [si],ch
	je DIO_DFDT_TrackNumMatch		; Found drive type

	add si,3						; Skip to the next record

	jmp DIO_DFDT_Loop
	
DIO_DFDT_TrackNumMatch:
	
	inc si
	cmp byte ptr [si],cl
	je DIO_DFDT_SectorNumMatch

	add si,2						; Skip to the next record
	
	jmp DIO_DFDT_Loop
	
DIO_DFDT_SectorNumMatch:
	
	inc si
	mov al,byte ptr [si]
	mov _DIO_DriveType,al
	
	jmp DIO_DFDT_END

DIO_DFDT_END:
	
	pop si
	pop di
	pop es
	pop dx							; restore registers
	pop cx
	pop bx
	pop ax
	
	ret
_DIO_DETECT_FD_TYPE ENDP

;----
; _DIO_DETECT_MEDIA_TYPE
; Detect the type of media currently in the dirive.
; Inputs:
;   dl = drive number
; Output: 
;	_DIO_MediaType will have a number with the type
; Destroys: none
;----
PUBLIC _DIO_DETECT_MEDIA_TYPE
_DIO_DETECT_MEDIA_TYPE PROC

	push ax
	push bx
	push cx
	push di
	                            ; set max retries
	mov DIO_RetryCount,MAX_RETRIES

DIO_DMT_Retry:
								; Read boot sector
	mov ch,0					; track 0
	mov dh,0					; side/head 0
	mov al,1					; read 1 sector
								; data will be at DIO_DiskReadBuf
	call _DIO_READ_SECTOR

    jnc DIO_DMT_Continue        ; if successful, continue
    
    cmp DIO_RetryCount,0
    je DIO_DMT_No_More_Retries
    
    call _DIO_INT13H_ERROR_IS_SYS_RETRIABLE
    cmp al,01h
    je DIO_DMT_Setup_Retry
    
    call _DIO_INT13H_ERROR_IS_USER_RETRIABLE
    cmp al,01h
    je DIO_DMT_User_Ret_Error
    
    jmp DIO_DMT_FATAL_ERROR  
    
DIO_DMT_Setup_Retry:
    dec DIO_RetryCount
    jmp DIO_DMT_Retry

DIO_DMT_No_More_Retries:
    call _DIO_INT13H_ERROR_IS_USER_RETRIABLE
    cmp al,01h
    je DIO_DMT_User_Ret_Error
    jmp DIO_DMT_Fatal_Error  
    
DIO_DMT_User_Ret_Error:	
	mov al,DIO_MEDIA_TYPE_USR_RET_ERROR
	mov _DIO_MediaType,al		
	jmp DIO_DMT_End

DIO_DMT_Fatal_Error:	
	mov al,DIO_MEDIA_TYPE_FATAL_ERROR
	mov _DIO_MediaType,al	
  	jmp DIO_DMT_End  
    
DIO_DMT_Continue:
	
	lea di,DIO_DiskReadBuf		; align di with the read buffer
	mov ax,di[13h]				; copy to ax the total number of sectors

								; align di with 
	lea di,Media_Type_Total_Sectors_Table

DIO_DMT_Keep_Looking:	
	cmp byte ptr [di],00h		; are we at the end?
	je DIO_DMT_Unknown

	cmp [di],ax					; Compare AX with pointer
	je DIO_DMT_Found_Media

	add di,3					; advance index to the next entry
	jmp DIO_DMT_Keep_Looking

DIO_DMT_Found_Media:
	add di,2					; skip the two bytes
	mov al,byte ptr [di]		; copy value of the media type to destination
	mov _DIO_MediaType,al	
	jmp DIO_DMT_End

DIO_DMT_Unknown:	
	mov al,DIO_MEDIA_TYPE_UNKNOWN
	mov _DIO_MediaType,al		

DIO_DMT_End:
	pop di
	pop cx
	pop bx
	pop ax
	ret
_DIO_DETECT_MEDIA_TYPE ENDP

;----
; _DIO_READ_SECTOR 
; Read one disk sector into memory with 3 automatic retries
; Inputs:
; 	- ch - track (0,79)
;   - dh - head / side (0-1)
;   - dl - drive (0 = a:, 1=b: ...)
;   - al - sectors to read
; Output: 
;	- Carry flag set if there was an error. Register ah contains error code
; Destroys:
;----
PUBLIC _DIO_READ_SECTOR
_DIO_READ_SECTOR PROC
	clc							; Clear carry flag
	cld							; Ensure the right direction
	mov ah,02h					; Function
	mov cl,01h					; sector number (bits 0-5) (high 2 bits of cylinder, 6-7 HD only) (1-18)
	mov bx,@DATA				; Align es with the data segment
	mov es,bx
	lea bx,DIO_DiskReadBuf		; load es:bx with the segment:offset to the read buffer
	int 13h						; Function 02h int 13h - Read sector(s) into memory
	ret
_DIO_READ_SECTOR ENDP

;----
; _DIO_RESET_DISK_SYSTEM 
; Reset the disk system
; Inputs: none
; Output: none
; Destroys: none
;----
PUBLIC _DIO_RESET_DISK_SYSTEM
_DIO_RESET_DISK_SYSTEM PROC
	mov ah,00h					; 
	int 13h						; Function 00h int 13h - Reset disk system 
	ret
_DIO_RESET_DISK_SYSTEM ENDP

;----
; _DIO_INT13H_ERROR_IS_SYS_RETRIABLE 
; Check if an int 13h error code status should be auto-retried by the system
; Inputs:
;   ah = status from the int 13h operation
; Output: 
;	al = 1 if yes, 0 if not
; Destroys: al
;----
PUBLIC _DIO_INT13H_ERROR_IS_SYS_RETRIABLE
_DIO_INT13H_ERROR_IS_SYS_RETRIABLE PROC
	push si
	mov al,0							; Default is not retryable
	lea si,SysRetryableList
_DIO_INT13H_IsSysRet_Loop:
	cmp byte ptr [si],00h				; Are we at the end of the list?
	je _DIO_INT13H_IsSysRet_End	

	cmp byte ptr [si],ah				; Check if input on the list
	je _DIO_INT13H_IsSysRet_Yes
	inc si								; increment index
	jmp _DIO_INT13H_IsSysRet_Loop		; and keep trying
	
_DIO_INT13H_IsSysRet_Yes:
	mov al,1							; Found it
	
_DIO_INT13H_IsSysRet_End:
	pop si
	ret
_DIO_INT13H_ERROR_IS_SYS_RETRIABLE ENDP

;----
; _DIO_INT13H_ERROR_IS_USER_RETRIABLE 
; Check if we should ask the user to retry for a given int 13h error code
; Inputs:
;   ah = status from the int 13h operation
; Output: 
;	al = 1 if yes, 0 if not
; Destroys: al
;----
PUBLIC _DIO_INT13H_ERROR_IS_USER_RETRIABLE
_DIO_INT13H_ERROR_IS_USER_RETRIABLE PROC
	push si
	mov al,0							; Default is not retryable
	lea si,UsrRetryableList
_DIO_INT13H_IsUsrRet_Loop:
	cmp byte ptr [si],00h				; Are we at the end of the list?
	je _DIO_INT13H_IsUsrRet_End	

	cmp byte ptr [si],ah				; Check if input on the list
	je _DIO_INT13H_IsUsrRet_Yes
	inc si								; increment index
	jmp _DIO_INT13H_IsUsrRet_Loop		; and keep trying
	
_DIO_INT13H_IsUsrRet_Yes:
	mov al,1							; Found it
	
_DIO_INT13H_IsUsrRet_End:
	pop si
	ret
_DIO_INT13H_ERROR_IS_USER_RETRIABLE ENDP

;----
; _DIO_GET_NUMBER_OF_FD
; Get the number of floppy drives in the system, from values the BIOS
; detected
; Inputs:
;   none
; Output: 
;	result is in public byte _DIO_NumberOfDisks. If error, then returns 255 (ffh)
; Destroys: none
;----
PUBLIC _DIO_GET_NUMBER_OF_FD
_DIO_GET_NUMBER_OF_FD PROC
	
	push ax							; save registers we affect
	push bx
	push dx
	push ds 				

	mov ax,BIOS_DATA_AREA			; align the data segment with the BIOS data area
	mov ds,ax
	
	mov bx,0010h					; this is the offset where the number of detected drive will be (word)

	mov ax,ds:[bx]					; read one word at that address
	pop ds							; restore DS

	and ax,00c0h					; apply mask to isolate bits 7-6
	shr al,6						; shift bits right 6 times to get number
	
	cmp al,0						; if 0, could be 1 or 0
	je DIO_GNumFD2ndCheck

	inc al							; plus one
	mov	_DIO_NumberOfDisks,al		; put it on the output variable
	jmp DIO_GNumFDEnd

DIO_GNumFD2ndCheck:

	clc								; clear carry flag	
	
	mov ah,08h						; Function 08h int 13h - Get drive params
	mov dl,0						; use drive 0
	int 13h

	jc DIO_GNumFDError				; If error jump
	
	mov _DIO_NumberOfDisks,dl		; save the number of drives in the public variable
	jmp DIO_GNumFDEnd				; get to the end
	
DIO_GNumFDError:
	mov _DIO_NumberOfDisks,0ffh		; 255 = error
	
DIO_GNumFDEnd:
	
	pop dx							; restore other registers we used
	pop bx							
	pop ax
	
	ret		
	
_DIO_GET_NUMBER_OF_FD ENDP

END