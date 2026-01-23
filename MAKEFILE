#
# This makefile assumes you are using Borland's Turbo Assembler.
# If that is not the case, you will need to change the tasm and tlink lines to masm and link
#
pcwo2.exe: pcwo2.obj commln.obj ui.obj t_cpufpu.obj t_screen.obj  t_pcspkr.obj t_floppy.obj lib\kb.obj lib\screen.obj lib\cpuid3a.obj lib\disk_io.obj lib\strings.obj lib\time.obj lib\math.obj lib\window.obj
	tlink /3 /l /m /s /v @RESPFILE
	
pcwo2.obj:			pcwo2.asm
	tasm pcwo2;

commln.obj:			commln.asm
	tasm commln;
    
ui.obj:             ui.asm version.inc
	tasm ui;
	
t_screen.obj:       t_screen.asm
    tasm t_screen;

t_pcspkr.obj:       t_pcspkr.asm
	tasm t_pcspkr;

t_floppy.obj:       t_floppy.asm
	tasm t_floppy;
	
t_cpufpu.obj:      t_cpufpu.asm
    tasm t_cpufpu;

lib\kb.obj:			lib\kb.asm
	tasm lib\kb lib\kb.obj;

lib\screen.obj:		lib\screen.asm
	tasm lib\screen lib\screen.obj;
	
lib\cpuid3a.obj:	lib\cpuid3a.asm
	tasm lib\cpuid3a lib\cpuid3a.obj;
	
lib\disk_io.obj:	lib\disk_io.asm
	tasm lib\disk_io lib\disk_io.obj;

lib\strings.obj:	lib\strings.asm
	tasm lib\strings lib\strings.obj;
	
lib\time.obj:	lib\time.asm
	tasm lib\time lib\time.obj;

lib\math.obj:	lib\math.asm
	tasm lib\math lib\math.obj;
	
lib\window.obj:	lib\window.asm
	tasm lib\window lib\window.obj;