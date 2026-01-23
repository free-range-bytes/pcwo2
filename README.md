# PC Workout Tool (PCWO) v2

Author: Homero Trevino <homerotl@gmail.com>

## Description
The purpose of this tool is to be able to test features available in vintage 
x86 computers running MS-DOS. The "workout" part comes from the idea that hardware 
parts, like floppy drives can break down more quickly if not used frequently. 

With this program, you can flex some of your computer's capabilities to ensure 
they are still in working order.

As a side benefit, I have always been curious about Assembly language, and 
this project is my pretext to learn it.

## Available Tests

 * CPU anf FPU identification
 * Floppy drive identification and read test
 * PC Speaker test with music
 * Screen geometry test (MCGA 320x200)
 * CPU Benchmark based on prime number calculations

## Usage
The program is portable. No installation is needed. Just copy the `PCWO2.EXE` 
file and run it from the command line. Follow the instructions.

## Binary
Use the following [link](https://homerotl.com/downloads/pcwo2/PCWO2-20231026.1.zip) to download the 
latest public build of this program. 

## Compiling PCWO2
Currently, I am using Borland's Turbo Assembler (TASM) Version 4.0. Once 
TASM is installed and configured on your path, simply download the source code
to your local dirive, open a command line, go to the directory where the source
code is and type `make`. This should generate the executable
file `PCWO2.EXE`

## Future Test ideas

  * Math Co-processor test (benchmark)
  * Hard drive detection
  * CD-ROM / DVD-ROM detection and test
  * ZIP Drive test
  * 3.5" LS-120 disk test
  * Screen color test (calibration in general)
  * Add more graphic modes to test
  * Graphics card detection (CGA/EGA/VGA)
  * AdLib Sound card test
  * SoundBlaster (16) Sound card test
  * MIDI (General) test
  * Gravis Sound card test
  * Keyboard test
  * Mouse test
 
## Other feature ideas

  * Graphical interface
  * Run with a pre-programmed sequence (no prompts)
  * Better error handling on disk read error
  * Able to cancel or pause a test
  * Be able to detect if you are in a real machine or DOSBox

## Recommended reading

  * PC Interrupts, Ralf Brown & Jim Kyle, Addison Wesley
  * Peter Norton's Assembly Language Book for the IBM PC, Peter Norton and John Socha, Brady New York
  * Programmer's Guide to PC&PS/2 Video Systems, Richard Wilton
  * The 8086 book, Russell Rector and George Alexy
  * Advanced MS-DOS, Ray Duncan
  * Assembly Language Primer for the IBM PC & XT, Robert Lafore
  * An introduction to Assembly Language Programming for the 8086 family, Thomas P. Skinner
  * 80386/80286 Assembly language programming, William H. Murray III and Chris H. Pappas
  * The IBM Personal Computer from Inside Out, Sargent and Shoemaker
  * Learn Multiplatform Assembly Programming with ChibiAkummas Vol 1, ChibiAkummas
  
  