#
# This makefile assumes you are using Borland's Turbo Assembler.
# If that is not the case, you will need to change the tasm and tlink lines to masm and link
#
# Sources live in src and src\lib. Objects are written to obj.
# PCWO2.EXE is written to the project root.
#
pcwo2.exe: obj\pcwo2.obj obj\commln.obj obj\ui.obj obj\t_cpufpu.obj obj\t_screen.obj obj\t_pcspkr.obj obj\t_floppy.obj obj\screen.obj obj\kb.obj obj\cpuid3a.obj obj\disk_io.obj obj\strings.obj obj\time.obj obj\math.obj obj\window.obj
	tlink /3 /l /m /s /v @respfile

obj\dir.tag:
	if not exist obj mkdir obj
	echo ok> obj\dir.tag

obj\pcwo2.obj:		obj\dir.tag src\pcwo2.asm
	tasm src\pcwo2.asm,obj\pcwo2.obj;

obj\commln.obj:		obj\dir.tag src\commln.asm
	tasm src\commln.asm,obj\commln.obj;

obj\ui.obj:			obj\dir.tag src\ui.asm src\version.inc
	tasm /isrc src\ui.asm,obj\ui.obj;

obj\t_screen.obj:	obj\dir.tag src\t_screen.asm
	tasm src\t_screen.asm,obj\t_screen.obj;

obj\t_pcspkr.obj:	obj\dir.tag src\t_pcspkr.asm
	tasm src\t_pcspkr.asm,obj\t_pcspkr.obj;

obj\t_floppy.obj:	obj\dir.tag src\t_floppy.asm
	tasm src\t_floppy.asm,obj\t_floppy.obj;

obj\t_cpufpu.obj:	obj\dir.tag src\t_cpufpu.asm
	tasm src\t_cpufpu.asm,obj\t_cpufpu.obj;

obj\kb.obj:			obj\dir.tag src\lib\kb.asm
	tasm src\lib\kb.asm,obj\kb.obj;

obj\screen.obj:		obj\dir.tag src\lib\screen.asm
	tasm src\lib\screen.asm,obj\screen.obj;

obj\cpuid3a.obj:	obj\dir.tag src\lib\cpuid3a.asm
	tasm src\lib\cpuid3a.asm,obj\cpuid3a.obj;

obj\disk_io.obj:	obj\dir.tag src\lib\disk_io.asm
	tasm src\lib\disk_io.asm,obj\disk_io.obj;

obj\strings.obj:	obj\dir.tag src\lib\strings.asm
	tasm src\lib\strings.asm,obj\strings.obj;

obj\time.obj:		obj\dir.tag src\lib\time.asm
	tasm src\lib\time.asm,obj\time.obj;

obj\math.obj:		obj\dir.tag src\lib\math.asm
	tasm src\lib\math.asm,obj\math.obj;

obj\window.obj:		obj\dir.tag src\lib\window.asm
	tasm src\lib\window.asm,obj\window.obj;
