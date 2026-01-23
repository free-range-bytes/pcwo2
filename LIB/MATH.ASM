; MATH.ASM
;
; Math and math related procedures
; Author: Homero Trevino <homerotl@gmail.com>
.MODEL small

.DATA
	PUBLIC _PRIME_N
	_PRIME_N			dw 0			; Size of the array
	
	PUBLIC _PRIME_NSQ
	_PRIME_NSQ			dw 0			; Square root of _PRIME_N

PRIMES_SEGMENT SEGMENT
	_PRIME_Array		db 10000 dup(?)	; Array with N bytes
PRIMES_SEGMENT ENDS

.CODE
	.8086   ; Force 8086 code 
	JUMPS   ; Enable jump re-mapping
	
;----
; _MATH_PRIME_SIEVE
;
; An x86 8080 Implementation of Sieve of Eratosthenes
; Based on the BASIC program by DAVEPL beleow
;
; 10 REMARKABLE BASIC SIEVE BY DAVEPL
; 20 DIM A%(10000)
; 30 N = 10000
; 40 NSQ% = INT(SQR(N))
; 50 FOR I = 2 TO N
; 60     A%(I) = 1
; 70 NEXT I
; 80 FOR I = 2 TO NSQ%
; 90     IF A%(I) = 0 THEN GOTO 130
; 100    FOR J = I * 2 TO N STEP I
; 110        A%(J) = 0
; 120    NEXT J
; 130 NEXT I
; 140 COUNT% = 0
; 150 FOR I = 2 TO N
; 160     IF A%(I) = 1 THEN COUNT% = COUNT% + 1
; 170 NEXT I
; 180 PRINT "NUMBER OF PRIMES UP TO"; N; "IS:"; COUNT%
; 190 END
;
; Inputs: 
;    _PRIME_Array points to a space of memory of size N; where N > 3 and N < 65535 
;    _PRIME_N is the size of _PRIME_Array in bytes and is > 3 < 65535
;    _PRIME_NSQ is the integer part of the square root of N 
; Output: 
;   _PRIME_Array with have on each position a value 1 if its index is a prime and 0 if not.
;     For example, _PRIME_Array[2] will have a value of 1 and _PRIME_Array[3] as well,
;     but _PRIME_Array[4] will have 0, since 4 is not a prime number
; Destroys: None
;----
PUBLIC _MATH_PRIME_SIEVE
_MATH_PRIME_SIEVE PROC

	push ax										; Save registers we are going to use
	push bx
	push cx
	push ds
	
	mov ax,_PRIME_N								; Copy the variables we need
	mov bx,_PRIME_NSQ							; before we change ds

	mov cx,PRIMES_SEGMENT						; Align ds with the PRIMES_SEGMENT
	mov ds,cx
	
	lea di,_PRIME_Array							; di should be starting at 0

; 50 FOR I = 2 TO N
	mov cx,ax									; initialize counter
PS_Setup_Loop:									; Setup the whole array with 1s
; 60     A%(I) = 1
	mov byte ptr [di],1
	inc di
; 70 NEXT I	
	loop PS_Setup_Loop
	
	lea di,_PRIME_Array
	mov byte ptr [di],0							; 0 and 1 are not primes
	mov byte ptr [di+1],0
	
; 80 FOR I = 2 TO NSQ%
	lea di,_PRIME_Array	
	mov cx,bx
	sub cx,2									; We are starting at I=2
	add di,2
PS_Outer_Loop:
; 90     IF A%(I) = 0 THEN GOTO 130
	cmp byte ptr [di],0
	je PS_Next_I

; 100    FOR J = I * 2 TO N STEP I
	mov si,di									; si = J
	shl si,1	
PS_Inner_Loop:
	cmp si,ax
	jg PS_Next_I
; 110        A%(J) = 0
	mov byte ptr [si],0
	add si,di
; 120    NEXT J
	jmp PS_Inner_Loop	
	
; 130 NEXT I
PS_Next_I:
	inc di
	loop PS_Outer_Loop
	
	pop ds
	pop cx
	pop bx
	pop ax
	
	ret
_MATH_PRIME_SIEVE ENDP

;----
; _MATH_PRIME_COUNT 
; Take the current _PRIME_Array and count primes up until _PRIME_N
; Inputs: _PRIME_Array and _PRIME_N
; Output: ax is the number of prime numbers in _PRIME_Array, up until _PRIME_N
; Destroys: ax, di
;----
PUBLIC _MATH_PRIME_COUNT
_MATH_PRIME_COUNT PROC
	push cx
	push ds

	mov ax,_PRIME_N								; Copy the variables we need
	
	mov cx,PRIMES_SEGMENT						; Align ds with the PRIMES_SEGMENT
	mov ds,cx
	
	lea di,_PRIME_Array
	mov cx,ax
	mov ax,0
	sub cx,2
	add di,2

Main_Count_Loop:
	cmp byte ptr [di],0
	je MAIN_Is_Not_Prime
	inc ax
MAIN_Is_Not_Prime:
	inc di
	loop Main_Count_Loop
	
	pop ds	
	pop cx

	ret
_MATH_PRIME_COUNT ENDP

END