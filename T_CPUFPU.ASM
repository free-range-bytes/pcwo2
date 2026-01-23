; T_CPU_FPU.ASM
;
; Routines for CPU and FPU identification and testing
; Author: Homero Trevino <homerotl@gmail.com>

.MODEL small

.DATA

	EXTRN _cpu_type:BYTE						; From LIB/CPUID3A.ASM
	EXTRN _fpu_type:BYTE
	EXTRN _cpuid_flag:BYTE
	
	EXTRN _PRIME_N:WORD							; From LIB/MATH.ASM
	EXTRN _PRIME_NSQ:WORD

	EXTRN _IntToStringBuffer:BYTE				; FROM LIB/STRINGS.ASM
	
	EXTRN _TimerTimeLapse:BYTE					; From LIB/TIME.ASM
	EXTRN _TimerTimerExpired:BYTE
	
	CPUIDNameTable				db 0, '8086/8088 ', 0
								db 2, '80286     ', 0
								db 3, '80386     ', 0
								db 4, '80486     ', 0	
								db 5, 'Pentium   ', 0	
								db 6, 'PentiumPro', 0
								db 10,'Unknown   ', 0
								db 0ffh						; Table terminator
	
	FPUNameTable				db 0,'Not present', 0
								db 1,'Present    ', 0
								db 2,'287        ', 0
								db 3,'387        ', 0						
								db 0ffh						; Table terminator

	CPUUnknownLbl				db 'Unknown', 0	
	FPUUnknownLbl				db 'Unknown', 0
	CpuTestRunningMsg           db 'CPU Test running...'
	
.CODE
	.8086
	JUMPS
	
	EXTRN _get_cpu_type:PROC					; From LIB/CPUID3A.ASM
	EXTRN _get_fpu_type:PROC

    EXTRN _STR_INT_TO_STRING:PROC				; From LIB/STRINGS

    EXTRN _UI_PRINT_CPU_ID:PROC					; FROM UI.ASM
    EXTRN _UI_PRINT_FPU_ID:PROC
    EXTRN _UI_PRINT_CPU_BENCHMARK:PROC
    EXTRN _UI_SET_STATUS:PROC 
   	EXTRN _UI_CLEAR_STATUS:PROC
   	EXTRN _UI_DISPLAY_PRESS_ANY_KEY:PROC
   	        
    EXTRN _TIME_SETUP_PIT:PROC					; FROM LIB/TIME.ASM
    EXTRN _TIME_START_TIMER:PROC
    EXTRN _TIME_HAS_TIMER_EXPIRED:PROC

	EXTRN _MATH_PRIME_SIEVE:PROC				; FROM LIB/MATH.ASM
	EXTRN _MATH_PRIME_COUNT:PROC

	EXTRN _KB_WAIT_ANY_KEY:PROC                 ; From LIB/KB.ASM
	
;----
; _TEST_CPU_FPU_DETECTION
; Run one-time detection routines. Set found values to the screen
; Inputs: None
; Output: None
; Destroys: None
;----
PUBLIC _TEST_CPU_FPU_DETECTION
_TEST_CPU_FPU_DETECTION PROC
	push ax									; Save registers we will use
	push si
	push di
	
	call _get_cpu_type						; Get CPU type
	mov al, _cpu_type						; put it on al
	
	lea si, CPUUnknownLbl					; Get ref to default label
	lea di, CPUIDNameTable					; Get cpu table ref

T_CPU_Next:	
	cmp byte ptr [di],0ffh					; Check if we are at the end of the table
	je T_FPU								; Go to FPU detection
	
	cmp byte ptr [di],al					; Check if we found a matching entry on the table
	je T_CPU_Match							; yes, jump
	
	add di,0ch								; no, skip on the table to the next entry
	jmp T_CPU_Next							; jump

T_CPU_Match:
	inc di									; the labels starts on the next byte
	mov si,di								; but we need it on si
	
T_FPU:
	call _UI_PRINT_CPU_ID					; Print the CPU label
	
	call _get_fpu_type						; Get the FPU type
	mov al, _fpu_type						; put it on al
	
	lea si, FPUUnknownLbl					; Get ref to the default label
	lea di, FPUNameTable					; Get fpu table ref

T_FPU_Next:	
	cmp byte ptr [di],0ffh					; Check if we are at the end of the table
	je T_CPUFPU_End							; Go to the end
	
	cmp byte ptr [di],al					; Check if we found a matching entry on the table
	je T_FPU_Match							; yes, jump
	
	add di,0dh						; no, skip on the table to the next entry
	jmp T_FPU_Next							; jump

T_FPU_Match:
	inc di									; the labels starts on the next byte
	mov si,di								; but we need it on si
	
T_CPUFPU_End:
	call _UI_PRINT_FPU_ID					; Print the FPU label

	pop di									; restore used registers
	pop si
	pop ax
	
	ret
_TEST_CPU_FPU_DETECTION ENDP

;----
; _TEST_CPU_BENCHMARK
; Run a CPU intensive process as many times as we can in 2 seconds
; to determine a benchmark
; Inputs: None
; Output: None
; Destroys: None
;----
PUBLIC _TEST_BENCHMARK_CPU
_TEST_BENCHMARK_CPU PROC

	push ax	
	push cx
	
	lea si,CpuTestRunningMsg			
    call _UI_SET_STATUS
	
	mov _PRIME_N,2710h						; Set N, length of the array
	mov _PRIME_NSQ,0064h					; Set SQRT(N)
	
	call _TIME_SETUP_PIT					; Setup PIT
	
	lea si,_TimerTimeLapse

	mov word ptr [si],0000h					; Load timer with 2 seconds
	mov word ptr [si+2],0024h
	mov word ptr [si+4],69b8h
	
	xor cx,cx								; cx=0
	
	call _TIME_START_TIMER

T_BCPU_Repeat:

	call _MATH_PRIME_SIEVE
	call _MATH_PRIME_COUNT
	inc cx
	
	call _TIME_HAS_TIMER_EXPIRED			; Check if timer expired	

	cmp _TimerTimerExpired,01h				; 01 = expired
	je T_BCPU_Ended
	jmp T_BCPU_Repeat
	
T_BCPU_Ended:

	call _UI_CLEAR_STATUS

	mov ax,cx
	call _STR_INT_TO_STRING
	
	lea si,_IntToStringBuffer
	
	call _UI_PRINT_CPU_BENCHMARK
	
	call _UI_DISPLAY_PRESS_ANY_KEY
    call _KB_WAIT_ANY_KEY
    
	pop cx
	pop ax
	
	ret
_TEST_BENCHMARK_CPU ENDP

END