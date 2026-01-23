;
; I found this code online as the specification from
; Intel on how to detect the CPU. I am leaving all original 
; comments and the Copyright notice.
;
; I am adding my own comments as well. To distinguish the
; original file comments from the new ones I am using an 
; asterisk as the begining -Homero

; START OF ORIGINAL INTEL COMMENTS ->
; 
; Filename: cpuid3a.asm
; Copyright 1993, 1994, 1995, 1996 by Intel Corp
;
; This program has been developed by Intel Corporation. Intel
; has various intellectual proprty rights which it may assert
; under certain circumstances, such as if another 
; manufacturer's processor mis-identifies itself as being
; "GenuineIntel" when the CPUID instruction is executed.
;
; Intel specifically disclaims all warranties, express or 
; implied, and all liability, including consequential and
; other indirect damages, for the use of this program,
; including liability for infringement of any propietary 
; rights, and including the warranties of merchantability and
; fitness for a particular purpose. Intel does not assume any
; responsability for any errors which may appear in this 
; program nor any responsability to update it.
;
; This code contains two procedures:
; _get_cpu_type: Identifies processor type in _cpu_type:
;       0=8086/8088 processor
;       2=Intel 286 processor
;       3=Intel386(TM) family processor
;       4=Intel486(TM) family processor
;       5=Pentium(R) family processor
;       6=Pentium(R) Pro family processor
; *    10=Unknown processor
;
; _get_fpu_type: Identifies FPU type in _fpu_type
;       0=FPU not present
;       1=FPU present
;       2=287 present (only if _cpu_type=3)
;       3=387 present (only if _cpu_type=3)
;
; This program has been tested wit	h the MASM assembler
; This code correctly detects the current Intel 8086/8088,
; 80286, 80386, 80486, Pentium(R) and Pentium(R) Pro 
; processors in the real-address mode only
;
; To assemble this code with TASM add the JUMPS directive.
; jumps   ; Uncomment this line for TASM
; 
; <- END OF ORIGINAL INTEL COMMENTS

JUMPS				; * I am using TASM, so I added JUMPS
TITLE cpuid3
;DOSSEG				; * This was in the original file, but it was causing me problems.
.model small

CPU_ID MACRO
	db 0fh
	db 0a2h						; Hardcoded CPUID instruction
ENDM

.data
	public _cpu_type
	public _fpu_type
	public _v86_flag
	public _cpuid_flag
	public _intel_CPU
	public _vendor_id
	public _cpu_signature
	public _features_ecx
	public _features_edx
	public _features_ebx


	_cpu_type 		db 0
	_fpu_type 		db 0
	_v86_flag 		db 0
	_cpuid_flag 	db 0
	_intel_CPU 		db 0
	_vendor_id 		db "------------" 
	intel_id		db "GenuineIntel"
	_cpu_signature	dd 0	
	_features_ecx	dd 0
	_features_edx	dd 0
	_features_ebx	dd 0
	fp_status		dw 0

	.code
	.8086

;*****************************************************************************
	public _get_cpu_type
_get_cpu_type proc

; This procedure determines the type of processor in a system
; and sets the _cpu_variable with the appropriate
; value. If the CPUID instruction is available, it is used
; to determine more specific details about the processor.
; All registers are used by the procedure, none are preserved.
; To avoid AC faults, the AM bit in CR0 must not be set

; Intel 8086 processor check
; Bits 12-15 of the FLAGS register are always set on the
; 8086 processor.

check_8086:
	pushf					; push the original FLAGS
	pop ax					; get original FLAGS
	mov cx,ax				; save original FLAGS
	and ax,0fffh			; clear bits 12-15 in FLAGS
	push ax					; save new FLAGS value on stack
	popf					; replace current FLAGS value
	pushf					; get new FLAGS
	pop ax					; store new FLAGS in AX
	and ax,0f000h			; if bits 12-15 are set, then
	cmp ax,0f000h			; processor is an 8086/8080
	mov _cpu_type,0			; turn on 8086/8080 flag
	jne check_80286			; go check for 80286
	push sp					; double check with push sp
	pop dx					; if value pushed was different
	cmp dx,sp				; means it's really not an 8086
	jne end_cpu_type		; jump if processor is 8086/8088
	mov _cpu_type,10h		; indicate unknown processor
	jmp end_cpu_type

; Intel 286 processor check
; Bits 12-15 of the FLAGS register are always clear on the
; Intel 286 processor in real-address mode
    
;   .286					
	.286p					; * In TASM we need to use .286p because smsw is a 
	check_80286: 			; * privileged instruction
	smsw ax					; save machine status word
	and ax,1				; isolate PE bit of MSW
	mov _v86_flag,al		; save PE bit to indicate V86	
	or cx,0f000h			; try to set bits 12-15
	push cx					; save new FLAGS value on stack
	popf					; replace current FLAGS value
	pushf					; get new FLAGS
	pop ax					; store new FLAGS in AX
	and ax,0f000h			; if bits 12-15 are clear
	mov _cpu_type,2			; processor=80286, turn on 8026 flag
	jz end_cpu_type			; jump if processor is 80286

; Intel386 processor check
; The AC bit, but #18, is a new bit introduced in the EFLAGS
; register on the Intel486 processor to generate alignment
; faults.
; This bit cannot be set on the Intel386 processor

	.386					; it is safe to use 386 instructions
check_80386:
	pushfd					; push original EFLAGS
	pop eax					; get original EFLAGS
	mov ecx,eax				; save original EFLAGS
	xor eax,40000h			; flip AC bit in EFLAGS
	push eax				; save new EFLAGS value on stack
	popfd					; replace current EFLAGS value
	pushfd					; get new EFLAGS
	pop eax					; store new EFLAGS in EAX
	xor eax,ecx				; can't toggle AC bit, processor=80386
	mov _cpu_type,3			; turn on 80386 processor flag
	jz end_cpu_type			; jump if 80386
	
	push ecx				
	popfd					; restore AC bit in EFLAGS
	
; Intel486 processor check
; Checking for ability to set/clear ID flag (Bit 21) in EFLAGS
; which indicates the presence of a processor with the CPUID
; instruction

	.486
check_80486:
	mov _cpu_type,4			; turn on 80486 processor flag
	mov eax,ecx				; get original EFLAGS
	xor eax,200000h			; flip ID bit in EFLAGS
	push eax				; save new EFLAGS value on stack
	popfd					; replace current EFLAGS value
	pushfd					; get new EFLAGS
	pop eax					; store new EFLAGS in EAX
	xor eax,ecx				; can't toggle ID bit
	je end_cpu_type			; processor=80486

; Execute CPUID instruction to not determine vendor, family
; model, stepping and features. For the purpose of this 
; code, only the initial set of CPUID information is saved.	
	
	mov _cpuid_flag,1		; flag indicating use of CPUID inst
	push ebx				; save registers
	push esi
	push edi
	mov eax,0				; set up for CPUID instruction
	CPU_ID					; get and save vendor Id
	
	mov dword ptr _vendor_id,ebx
	mov dword ptr _vendor_id[+4], edx
	mov dword ptr _vendor_id[+8], ecx
	
	cmp dword ptr intel_id,ebx
	jne end_cpuid_type
	cmp dword ptr intel_id[+4],edx
	jne end_cpuid_type
	cmp dword ptr intel_id[+8],ecx
	jne end_cpuid_type		; if not equal, not an Intel processor
	
	mov _intel_CPU, 1			; indicate an Intel processor
	cmp eax,1					; make sure 1 is valid input for CPUID
	jl end_cpu_type				; if not, jump to end
	mov eax,1
	CPU_ID						; get family/model/stepping/features
	mov _cpu_signature,eax
	mov _features_ebx,ebx
	mov _features_edx,edx
	mov _features_ecx,ecx
	
	shr eax,8					; isolate family
	and eax,0fh
	mov _cpu_type, al			; set _cpu_type with family
	
end_cpuid_type:
	pop edi						; restore registers
	pop esi
	pop ebx
	
	.8086
end_cpu_type:
	ret
_get_cpu_type endp

;*****************************************************************************
 
	public _get_fpu_type
_get_fpu_type proc

; This procedure determinees the type of FPU in a system
; and sets the _fpu_type variable with the appropriate value.
; All registers are used by this procedure, none are preserved.
;
; Coprocessor check
; The algorithm is to determine whether the floating-point
; status and control words are present. If not no
; coprocessor exists. If the status and control words can
; be saved, the correct coprocessor is then determined
; depending on the processor type. The Intel386 processor can
; work with either an Intel287 NDP or an Intel387 NDP.
; The infinity or the coprocessor must be checked to determine
; the correct coprocessor type.

	fninit						; reset FP status word
	mov fp_status,5a5ah			; initialize temp word to non-zero
	fnstsw fp_status			; save FP status word
	mov ax, fp_status			; check FP status word
	cmp al,0					; was correct status written
	mov _fpu_type,0				; no FPU present
	jne end_fpu_type			

check_control_word:
	fnstcw fp_status			; save FP control word
	mov ax,fp_status			; check FP control word
	and ax,103fh				; selected parts to examine
	cmp ax,3fh					; was control word correct
	mov _fpu_type,0
	jne end_fpu_type			; incorrect control word, no FPU
	mov _fpu_type,1

; 80287/80387 check for the Intel386 processor

check_infinity:
	cmp _cpu_type, 3
	jne end_fpu_type
	fld1						; must use default control from FNINT
	fldz						; from infinity
	fdiv						; 8087/Intel287 NDP say _inf = -inf
	fld st						; form negative infinity
	fchs						; Intel387 NDP says +inf <> -inf
	fcompp						; see if they are the same
	fstsw fp_status				; look at the status from FCOMPP
	mov ax, fp_status			
	mov _fpu_type,2				; store Intel287 NDP for FPU type
	sahf						; see if infinities matched
	jz end_fpu_type				; jump if 8087 or Intel287 is present
	mov _fpu_type,3				; store Intel387 NDP for FPU type
end_fpu_type:
	ret
_get_fpu_type endp
	end