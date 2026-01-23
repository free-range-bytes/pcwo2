; T_PCSPKR.ASM
; Source for the PC Speaker test
; Author: Homero Trevino <homerotl@gmail.com>
.MODEL small

.DATA

    ; PC Speaker music format BNF
    ;-----------------------------------------------------
    ; <musical-piece> ::= <tempo> <score> <terminator>
    ; <tempo> ::= 00h - 09h (see Tempo table below)
    ; <score> ::= "" | <note> <score>
    ; <note> ::= <playing-note> | <rest-note>
    ; <playing-note> ::= 00h-08h (see Note table) <pitch> 
    ; <pitch> ::= 00h-57h (see Pitch table)
    ; <rest-note> ::= 09h-0dh (see Note table)
    ; <terminator> ::= ffh

	; Tempo
	;-------------
	; Grave	   00h
	; Largo	   01h
	; Lento	   02h
	; Adagio   03h
	; Andante  04h
	; Moderato 05h
	; Allegro  06h
	; Vivace   07h
	; Presto   08h
	
	; Notes
	;---------------
	; 1/16 note         00h
	; 1/16 note dotted	01h
	; 1/8 note          02h
	; 1/8 note dotted   03h
	; 1/4 note          04h
	; 1/4 note dotted   05h
	; 1/2 note          06h
	; 1/2 note dotted   07h
	; whole note        08h
	; 1/16 rest         09h
	; 1/8 rest          0ah
	; 1/4 rest          0bh
	; 1/2 rest          0ch
	; whole rest        0dh
	
	; Pitch (see whole table at http://homerotl.com/downloads/pcwo2/pc_spk_pitch.png)
	;--------------
	; La  (A0)  00h
	; La# (A#0) 01h
	; Si (B0)   02h
	; Do (C1)   03h
	; ...
	; Do (C4)   27h
	; Do# (C#4) 28h
	; ...
	; Si (B7)   56h
	; Do (C8)   57h
	
	; Moderato
	; To see how these durations are calculated visit:
	; https://docs.google.com/spreadsheets/d/1tf4jzSlPmdI96fO9jnqa351eW87LG8teQzGnEYhJR9A/edit?usp=sharing
    ; Stored in reverse order from least significant to most significant
    ; [  ls   ] [  ms  ]
    ; [ls] [ms] [ls][ms]
    NoteTypesPITCliks db 0d8h, 95h, 02h, 00h
		db 1ah, 0dch, 03h, 00h
		db 06h, 27h, 05h, 00h
		db 0deh, 0bch, 07h, 00h
		db 0ch, 4eh, 0ah, 00h
		db 12h, 75h, 0fh, 00h
		db 18h, 9ch, 14h, 00h
		db 24h, 0eah, 1eh, 00h
		db 30h, 38h, 29h, 00h
		db 0d8h, 95h, 02h, 00h
		db 06h, 27h, 05h, 00h
		db 0ch, 4eh, 0ah, 00h
		db 18h, 9ch, 14h, 00h
		db 30h, 38h, 29h, 00h
		

    MelodySwanLake  db 06h ; Moderato                               measure
		;db 0dh                                                     ; 1 (skip initial silence)
		db 06h,39h, 02h,32h, 02h,34h, 02h,35h                       ; 2
		db 02h,37h,  05h,39h, 02h,35h, 05h,39h, 02h,35h             ; 3
		db 05h,39h, 02h,32h, 02h,35h, 02h,32h, 02h,2eh, 02h,35h     ; 4
		db 06h,32h, 02h,32h, 02h,37h, 02h,35h, 02h,34h              ; 5
		db 06h,39h, 02h,32h, 02h,34h, 02h,35h, 02h,37h              ; 6
		db 05h,39h, 02h,35h, 05h,39h, 02h,35h                       ; 7
		db 05h,39h, 02h,32h, 02h,35h, 02h,32h, 02h,2eh, 02h,35h     ; 8
		db 07h,32h, 04h,32h                                         ; 9
		db 04h,34h, 04h,35h, 04h,37h, 02h,39h, 02h,3ah              ; 10
		db 05h,3ch, 02h,3ah, 04h,39h, 02h,3ah, 02h,3ch              ; 11
		db 05h,3eh, 02h,3ch, 04h,3ah, 02h,3ch, 02h,3eh              ; 12
		db 05h,40h, 02h,3eh, 02h,39h, 02h,35h, 02h,34h, 02h,32h     ; 13
		db 04h,34h, 04h,35h, 04h,37h, 02h,39h, 02h,3ah              ; 14
		db 05h,3ch, 02h,3ah, 04h,39h, 02h,3ah, 02h,3ch              ; 15
		db 05h,3eh, 02h,3ch, 04h,3ah, 02h,3ch, 02h,3eh              ; 16
		db 05h,3fh, 02h,3ah, 04h,37h, 02h,3ah, 02h,40h              ; 17
		db 05h,40h, 02h,3bh, 05h,40h								; 18                    
		db 0ffh ; terminator
    
    ; Here we only have the range of pitch used in the melody above
	NoteFrequencies db 27h, 11h, 0d1h		; C4
   		db 28h, 10h, 0d1h					; C#4
   		db 29h, 0fh, 0e0h					; D4
   		db 2ah, 0eh, 0fbh					; ..
   		db 2bh, 0eh, 24h
   		db 2ch, 0dh, 59h
   		db 2dh, 0ch, 99h
   		db 2eh, 0bh, 0e4h
   		db 2fh, 0bh, 3ah
   		db 30h, 0ah, 98h
   		db 31h, 0ah, 00h					; ..
   		db 32h, 09h, 70h					; B4
   		db 33h, 08h, 0e9h					; C5
   		db 34h, 08h, 69h					; C#5
   		db 35h, 07h, 0f0h					; ..
   		db 36h, 07h, 7eh
   		db 37h, 07h, 12h
   		db 38h, 06h, 0adh
   		db 39h, 06h, 4dh
   		db 3ah, 05h, 0f2h
   		db 3bh, 05h, 9dh
   		db 3ch, 05h, 4ch
   		db 3dh, 05h, 00h
   		db 3eh, 04h, 0b8h					; ..
   		db 3fh, 04h, 75h					; C6
   		db 40h, 04h, 35h					; C#6
   		db 0ffh							; End of the table
   
	EXTRN _TimerTimeLapse:BYTE
	EXTRN _TimerTimerExpired:BYTE
   
.CODE
	.8086
	JUMPS
	
	EXTRN _UI_PROMPT_PCSPKR_PLAYING:PROC	; From UI.ASM 
	EXTRN _UI_CLEAR_PROMPT:PROC				
	EXTRN _UI_CLEAR_STATUS:PROC	
	EXTRN _TIME_SETUP_PIT:PROC				; From LIB/TIME.ASM
	EXTRN _TIME_START_TIMER:PROC
	EXTRN _TIME_HAS_TIMER_EXPIRED:PROC
	
;----
; _TEST_PC_SPEAKER 
; Test the PC Speaker by sending one C note for 1/4 time
; Inputs:
;   - None
; Output: 
;	- None
; Destroys:
;	- si,di
;----
PUBLIC _TEST_PC_SPEAKER
_TEST_PC_SPEAKER PROC
	
	push ax
	push bx
	push cx
	push dx
	
	call _UI_PROMPT_PCSPKR_PLAYING
	
	call _TIME_SETUP_PIT					; Setup counter
	
	mov al,0b6h
	out 43h,al								; Send value 182 to port 43h. This setups the speaker
	
	lea di,MelodySwanLake					; Get pointer to the music
	
	inc di									; For now, skip the tempo
	
_T_PCST_ReadNextNote:

	; check for a key stroke
	mov ah,0bh
	int 21h
	cmp al,00h								; no character available
	je _T_PCST_NoChar
	
	jmp _T_PCST_EndOfSong
	
_T_PCST_NoChar:
	cmp byte ptr [di],0ffh
	je _T_PCST_EndOfSong					; check if we are at the end
	
	cmp byte ptr [di],08h
	jle _T_PCST_PlayNote					; looks like a playing note?
	
	cmp byte ptr [di],0dh
	jle _T_PCST_Rest						; looks like rest?
	
	jmp _T_PCST_EndOfSong					; Unknown code, just exit  

_T_PCST_PlayNote:
	
	xor ax,ax								; ax = 0
	mov al,[di]								; Copy note code
	
	; Lookup note type in NoteTypes for duration
	mov bl,04h
	mul bl									; (offset) ax = code * 04h
	lea si,NoteTypesPITCliks	
	add si,ax								; si = si + offset

	mov dx,[si]
	mov cx,[si+2]

	lea si,_TimerTimeLapse
	mov ax,0000h
	mov [si],ax
	mov [si+2],cx
	mov [si+4],dx
	
	; Lookup note frequency in NoteFrequencies	
	inc di									; load next song byte
	mov al,[di]

	lea si,NoteFrequencies

_T_PCST_NextFreq:

	mov bl,0ffh
	cmp [si],bl								; At the end of the table?
	je _T_PCST_EndOfSong					; ERROR: Could not find frequency. End

	cmp [si],al
	je _T_PCST_FreqFound
	add si,03h
	jmp _T_PCST_NextFreq
 
_T_PCST_FreqFound:
	inc si									; move over one byte to skip the node code
	
	mov ah,[si]								; Set frequency in AX
	inc si
	mov al,[si]
	
	out 42h,al								; Out can only be done from al or AX
	mov al,ah
	out 42h,al
	
	; Play the note
	in al,61h								; Enable speaker
	or al,03h								; Set lower 2 bits to 1
	out 61h,al								; without affecting the other bits
	
	call _TIME_START_TIMER

_T_PCST_KeepWaiting:

	call _TIME_HAS_TIMER_EXPIRED
	cmp _TimerTimerExpired,01h				; 01 = expired
	je _T_PCST_WaitEnded
	
	nop
	
	jmp _T_PCST_KeepWaiting

_T_PCST_WaitEnded:	

	; Stop the note
	in al,61h								; Disable speaker
	and al,0fch								; Set lower 2 bits to 0
	out 61h,al								; without affecting the other bits
	
	inc di									; move on to the next byte
	jmp _T_PCST_ReadNextNote
	
_T_PCST_Rest:

	xor ax,ax								; ax = 0
	mov al,[di]								; Copy note code
	
	; Lookup note type in NoteTypes for duration
	mov bl,04h
	mul bl									; (offset) ax = code * 04h
	lea si,NoteTypesPITCliks	
	add si,ax								; si = si + offset

	mov dx,[si]								; Load CX:DX with the note duration
	mov cx,[si+2]
	
	lea si,_TimerTimeLapse
	mov ax,0000h
	mov [si],ax
	mov [si+2],cx
	mov [si+4],dx

	call _TIME_START_TIMER

_T_PCST_KeepWaitingRest:

	call _TIME_HAS_TIMER_EXPIRED
	cmp _TimerTimerExpired,01h				; 01 = expired
	je _T_PCST_WaitEndedRest
	
	nop
	
	jmp _T_PCST_KeepWaitingRest

_T_PCST_WaitEndedRest:

	inc di
	jmp _T_PCST_ReadNextNote

_T_PCST_EndOfSong:
	
	call _UI_CLEAR_STATUS
	call _UI_CLEAR_PROMPT	
	
	pop dx
	pop cx
	pop bx
	pop ax	
	
	ret
	
_TEST_PC_SPEAKER ENDP

END