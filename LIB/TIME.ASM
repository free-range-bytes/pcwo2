; TIME.ASM
;
; Libraries for handling time and timing related tasks
; Author: Homero Trevino <homerotl@gmail.com>

.MODEL small

.DATA      

	; Time here is measured using the Intel 8253 PIT ticks
	; The most significant 32 bits are stored in memory in a double word
	; at 0040:006c. The least significant 16 bits are available in
	; reading from the IC itself.
	
	public _TimerTimeLapse
	_TimerTimeLapse db 6 dup (?) 	; Input for how many ticks we need to wait for

	public _TimerTimerExpired
	_TimerTimerExpired db 0ffh		; Flag for timer expired

	TimerTarget db 6 dup (?) 		; Target number of clicks before times expires

.CODE
	.8086   ; Force 8086 code 
	JUMPS   ; Enable jump re-mapping
	
;----
; _TIME_SETUP_PIT 
; This routine ensure the 8253 PIT is in rate generator
; not square wave mode.
; Inputs: None 
; Output: None
; Destroys: None
;----
PUBLIC _TIME_SETUP_PIT 
_TIME_SETUP_PIT PROC

	push ax

	mov al,34h
	out 43h,al

	mov al,00h
	out 40h,al

	mov al,00h
	out 40h,al
	
	pop ax
	
	ret
_TIME_SETUP_PIT ENDP

;----
; _TIME_START_TIMER 
; 
; Inputs: None 
; Output: None
; Destroys: None
;----
public _TIME_START_TIMER
_TIME_START_TIMER PROC
	
	; Get the current number of ticks from BIOS
	push ax
	push bx
	push cx
	push dx
	push di
	
	mov _TimerTimerExpired,00h					; reset timer
	
	CALL GET_TICKS								; Current ticks at BX:DX:AX
	
	; Now add the desired time in clicks to the current count
	lea di,_TimerTimeLapse
	mov cx,[di+4]								; Start with the lo word
	add ax,cx
	mov cx,[di+2]
	adc dx,cx
	mov cx,[di]
	adc bx,cx

	; finally, copy the updated number to memory
	lea di,TimerTarget
	mov [di+4],ax
	mov [di+2],dx
	mov [di],bx
	
	pop di
	pop dx										; restore other registers
	pop cx
	pop bx
	pop ax
	
	ret
_TIME_START_TIMER ENDP

;----
; _TIME_HAS_TIMER_EXPIRED 
; 
; Inputs: None 
; Output: None
; Destroys: None
;----
public _TIME_HAS_TIMER_EXPIRED
_TIME_HAS_TIMER_EXPIRED PROC

	push ax										; save registers we affect
	push bx
	push cx
	push dx
	push di
	
	call GET_TICKS								; Current ticks at BX:DX:AX

	lea di,TimerTarget							; Get pointer to the target timer
	mov si,[di]
	cmp bx,si									; compare current (bx) vs target (si)
	jg hte_yes
	jl hte_end

	mov si,[di+2]
	cmp dx,si
	jg hte_yes
	jl hte_end

	mov si,[di+4]
	cmp ax,si
	jg hte_yes
	jmp hte_end

hte_yes:
	mov _TimerTimerExpired,01h
	jmp hte_end
	
hte_end:

	pop di										; restore registers we used
	pop dx										
	pop cx
	pop bx
	pop ax

	ret
_TIME_HAS_TIMER_EXPIRED ENDP

;----
; GET_TICKS 
; Gets the number of ticks since the OS booted, as measured by the 
; Intel 8253 PIT. After this call the registers BX:DX:AX has the number
; with BX havin the most significant digits and AX the least
; Inputs: None 
; Output: 
; Destroys: ax,bx,dx
;----
GET_TICKS PROC

	push ds 				; save registers we affect
	pushf					; save flags

tst_try_again:

	mov ax,0040h			; align the data segment with the BIOS data area
	mov ds,ax
	
	mov bx,006ch			; this is the offset where the number of IRQ0 ticks is stored (word)

	cli						; stop interrupts, ensure our read is atomic (affect flags)
	mov cx,ds:[bx]			; read BIOS ticks - lo word
	mov di,ds:[bx+2]		; hi-word
	sti						; re-enable interrupts
	
	mov al,04h
	out 43h,al				; latch timer 0 (ensures read is atomic)
	in al,40h				; read latched timer 0 lo-byte 
	mov ah,al				; save it
	in al,40h				; read latched timer 0 hi-byte 
	xchg al,ah				; correct order hi and lo

	cli						; stop interrupts, ensure our read is atomic (affect flags)
	mov dx,ds:[bx]			; read again to ensure it did not change
	mov bx,ds:[bx+2]
	
	cmp cx,dx				; check that the BIOS counter has not changed
	jne	tst_try_again

	not ax					; time is counting down so, so invert it
	
							; At this point the number of ticks is
							; in BX:DX:AX
	popf					; restore caller flags
	pop ds

	ret
GET_TICKS ENDP

END
