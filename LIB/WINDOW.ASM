; WINDOW.ASM
;
; Library to allow a text window which is resizable, movable
; scrollable and can be shown and hidden dynamically.
; Author: Homero Trevino <homerotl@gmail.com>

.MODEL small
	
	; Characteristics of the actual screen	
	SCREEN_BYTE_COUNT          EQU 0fa0h       ; 80x2x25 = 4000 = 0fa0h 	
	SCREEN_CHAR_COUNT          EQU 07d0h       ; 80x25 = 2000 = 07d0h
	SCREEN_WIDTH               EQU 50h         ; 80 columns
    SCREEN_BUFFER_BYTE_WIDTH   EQU 0a0h        ; 160 bytes		
	SCREEN_HEIGHT              EQU 19h         ; 25 rows
	VIDEO_MEMORY_ADDR          EQU 0b800h      
	
    ; Window painting ASCII characters
    V_LINE                     EQU 179
    H_LINE                     EQU 196
    TOP_RIGHT_CORNER           EQU 191
    BOTTOM_LEFT_CORNER         EQU 192
    BOTTOM_RIGHT_CORNER        EQU 217 
    TOP_LEFT_CORNER            EQU 218

.DATA
    Window_Pos_Row          db 0
    Window_Pos_Column       db 0
    Window_Width            db 0
    Window_Height           db 0
    
    Window_Cursor_Row       db 0
    Window_Cursor_Column    db 0
    
    Window_Border_Style     db 0
    Window_Content_Style    db 0
    
    Window_Bg_Save_Buffer   db 4000 dup (?)
    Window_Content_Buffer   db 2000 dup (' ')
    
    Window_ViewPort_Start_Column    db 0
    Window_ViewPort_Start_Row       db 0
    
    Window_Content_Width    db 0
    Window_Content_Heighh   db 0
        
    HLine_Start_Column      db 0
    HLine_Start_Row         db 0
    HLine_Length            db 0
    
    VLine_Start_Column      db 0
    VLine_Start_Row         db 0
    VLine_Lemgth            db 0
    
.CODE		
	.8086
    JUMPS

;----
; Setup values for a text window
; Inputs: None
; Output: None
; Destroys: None
;----
PUBLIC _WINDOW_SETUP
_WINDOW_SETUP PROC
    ; Hardcoded values for now
    mov Window_Pos_Row,0ch              ; make it 12h for testing (0ch normal)
    mov Window_Pos_Column,01h           ; make it 0ah a for testing (01h normal)
    mov Window_Width,4eh                ; 78
    mov Window_Height,0bh               ; 11
    mov Window_Cursor_Row,0
    mov Window_Cursor_Column,0
    mov Window_Border_Style,07h         ; White text, black background
    mov Window_Content_Style,07h        ; White text, black background
    mov Window_ViewPort_Start_Column,0
    mov Window_ViewPort_Start_Row,0
    mov Window_Content_Width,50h        ; 80
    mov Window_Content_Heighh,19h       ; 25
	ret
_WINDOW_SETUP ENDP

;----
; Show a text window
; Inputs: None
; Output: None
; Destroys: None
;----
PUBLIC _WINDOW_SHOW
_WINDOW_SHOW PROC
    call SAVE_BACKGOUND
    call RENDER_BORDERS
    call _WINDOW_REDRAW_CONTENT
	ret
_WINDOW_SHOW ENDP

;----
; Render window borders
; Inputs: All the WINDOW_* variables
; Output: None
; Destroys: None
;----
RENDER_BORDERS PROC
    push ax                         ; Save registers
    push bx
    push es
    push di
    
    ; align es to write to screen buffer
   	mov ax,VIDEO_MEMORY_ADDR        ; Align es with screen memory
   	mov es,ax    
    
    ; validate top left corner inside screen bounds
    mov al,Window_Pos_Row
    cmp al,SCREEN_HEIGHT
    jge rb_end
    mov al,Window_Pos_Column
    cmp al,SCREEN_WIDTH
    jge rb_end

    ; set index to top left coords
    mov al,Window_Pos_Row
   	mov bl,SCREEN_WIDTH
   	mul bl
   	xor bx,bx
   	mov bl,Window_Pos_Column
	add ax,bx                       ; ax = (Window_Pos_Row * SCREEN_WIDTH) + Window_Pos_Column
	shl ax,1                        ; ax = ax * 2
	mov di,ax                       ; align index register
    
    ; print top left character
    mov al,TOP_LEFT_CORNER
    mov es:[di],al                  ; Copy character
	inc di
	mov al,Window_Border_Style
	mov es:[di],al                  ; Copy attribute byte to destination
	inc di
    
    ; set cursor to hline start
    mov al,Window_Pos_Column
    inc al
    mov HLine_Start_Column,al
    mov al,Window_Pos_Row
    mov HLine_Start_Row,al
    
    ; set line length
    mov al,Window_Width
    sub al,2
    mov HLine_Length,al
        
    ; draw horizontal line
    call DRAW_HLINE
    
    ; validate top right corner inside screen bounds
    mov al,Window_Pos_Column
    add al,Window_Width
    dec al
    cmp al,SCREEN_WIDTH
    jge rb_vline_start

    ; set index to top right coords
    mov al,Window_Pos_Row
   	mov bl,SCREEN_WIDTH
   	mul bl
   	xor bx,bx
   	mov bl,Window_Pos_Column   	
	add ax,bx                       ; ax = (Window_Pos_Row * SCREEN_WIDTH) + Window_Pos_Column
	xor bx,bx
	mov bl,Window_Width
	add ax,bx
	dec ax
	shl ax,1                        ; ax = ax * 2
	mov di,ax                       ; align index register
    
    ; print top right character
    mov al,TOP_RIGHT_CORNER
    mov es:[di],al                  ; Copy character
	inc di
	mov al,Window_Border_Style
	mov es:[di],al                  ; Copy attribute byte to destination
	inc di

rb_vline_start:

    ; set cursor to left line start
    mov al,Window_Pos_Column
    mov VLine_Start_Column,al
    mov al,Window_Pos_Row
    inc al
    mov VLine_Start_Row,al
        
    ; set line length
    mov al,Window_Height
    sub al,2
    mov VLine_Lemgth,al
    
    ; draw vline
    call DRAW_VLINE
    
    ; set cursor to right line start
    mov al,Window_Pos_Column
    add al,Window_Width
    dec al
    mov VLine_Start_Column,al        
    mov al,Window_Pos_Row
    inc al
    mov VLine_Start_Row,al
        
    ; set line length
    mov al,Window_Height
    sub al,2
    mov VLine_Lemgth,al
    
    ; draw vline
    call DRAW_VLINE
        
    ; validate bottom left corner inside screen bounds
    mov al,Window_Pos_Row
    add al,Window_Height
    cmp al,SCREEN_HEIGHT
    jge rb_end
    mov al,Window_Pos_Column
    cmp al,SCREEN_WIDTH
    jge rb_end
    
    ; set index to bottom left corner
    mov al,Window_Pos_Row
    add al,Window_Height
    dec al
   	mov bl,SCREEN_WIDTH
   	mul bl
   	xor bx,bx
   	mov bl,Window_Pos_Column   	
	add ax,bx                       ; ax = (Window_Pos_Row * SCREEN_WIDTH) + Window_Pos_Column
	shl ax,1                        ; ax = ax * 2
	mov di,ax                       ; align index register
    
    ; print bottom left character
    mov al,BOTTOM_LEFT_CORNER
    mov es:[di],al                  ; Copy character
	inc di
	mov al,Window_Border_Style
	mov es:[di],al                  ; Copy attribute byte to destination
	inc di
	
    ; set cursor to hline start
    mov al,Window_Pos_Column
    inc al
    mov HLine_Start_Column,al
    mov al,Window_Pos_Row
    add al,Window_Height
    sub al,1    
    mov HLine_Start_Row,al
            
    ; set line length
    mov al,Window_Width
    sub al,2
    mov HLine_Length,al
    
    ; draw hline
    call DRAW_HLINE
    
    ; validate bottom right corner inside screen bounds
    mov al,Window_Pos_Row
    add al,Window_Height
    cmp al,SCREEN_HEIGHT
    jge rb_end
    mov al,Window_Pos_Column
    add al,Window_Width
    cmp al,SCREEN_WIDTH
    jge rb_end
   
    ; set index to bottom right corner
    mov al,Window_Pos_Row
    add al,Window_Height
    dec al
   	xor bx,bx
   	mov bl,SCREEN_WIDTH   	
   	mul bl   	
   	mov bl,Window_Pos_Column   	
	add ax,bx                       ; ax = (Window_Pos_Row * SCREEN_WIDTH) + Window_Pos_Column + Window_Width
    xor bx,bx
	mov bl,Window_Width
	add ax,bx
	dec ax
	shl ax,1                        ; ax = ax * 2
	mov di,ax                       ; align index register
	    
    ; print bottom right character
    mov al,BOTTOM_RIGHT_CORNER
    mov es:[di],al                  ; Copy character
	inc di
	mov al,Window_Border_Style
	mov es:[di],al                  ; Copy attribute byte to destination
	inc di
    
rb_end:

    pop di
    pop es
    pop bx
    pop ax                      ; Restore registers
    
    ret
RENDER_BORDERS ENDP

;----
; Draw a horizontal border line
; Inputs: 
;   - es already pointing to the start of the text screen buffer
;   - HLine_Start_Column
;   - HLine_Start_Row
;   - HLine_Length
; Output: None
; Destroys: None
;----
DRAW_HLINE PROC

    push ax                      ; Save registers
    push bx
    push cx
    push dx
    push di
    
    ; validate we are within bounds
    mov al,HLine_Start_Column
    cmp al,SCREEN_WIDTH
    jge dhline_end
    mov al,HLine_Start_Row
    cmp al,SCREEN_HEIGHT
    jge dhline_end
    
    ; set index to left coords
    mov al,HLine_Start_Row
   	mov bl,SCREEN_WIDTH
   	mul bl
   	xor bx,bx
   	mov bl,HLine_Start_Column
	add ax,bx                       ; ax = (HLine_Start_Row * SCREEN_WIDTH) + HLine_Start_Column
	shl ax,1                        ; ax = ax * 2
	mov di,ax                       ; align index register
    
    ; pre for loop
    xor cx,cx
    mov cl,HLine_Length
    xor bx,bx
    mov bl,SCREEN_BUFFER_BYTE_WIDTH
 
 dhline_loop:  
 
    ; draw character
    mov ax,di                       ; compute row before and save it to dl
    div bl                          ; al = di/bl
    mov dl,al
        
    mov al,H_LINE
	mov es:[di],al                  ; Copy character
	inc di
	mov al,Window_Border_Style
	mov es:[di],al                  ; Copy attribute byte to destination
	inc di
	
	mov ax,di                       ; compute row after and save it to dh
    div bl                          ; al = di/bl
    mov dh,al
	
	cmp dh,dl                       ; check if we have gone out of bounds
	jg dhline_end
	
	loop dhline_loop
    
dhline_end:

    pop di
    pop dx
    pop cx
    pop bx
    pop ax                      ; Restore registes
	ret
DRAW_HLINE ENDP

;----
; Draw a vertical border line
; Inputs: 
;   - es already pointing to the start of the text screen buffer
;   - VLine_Start_Column
;   - VLine_Start_Row
;   - VLine_Lemgth
; Output: None
; Destroys: None
;----
DRAW_VLINE PROC
    
    push ax                         ; save registers
    push bx
    push cx
    push dx
    push di
    
    ; validate we are within bounds
    mov al,VLine_Start_Column
    cmp al,SCREEN_WIDTH
    jge dvline_end
    mov al,VLine_Start_Row
    cmp al,SCREEN_HEIGHT
    jge dvline_end
    
    ; set index to top of the line
    mov al,VLine_Start_Row
   	mov bl,SCREEN_WIDTH
   	mul bl
   	xor bx,bx
   	mov bl,VLine_Start_Column
	add ax,bx                       ; ax = (VLine_Start_Row * SCREEN_WIDTH) + VLine_Start_Column
	shl ax,1                        ; ax = ax * 2
	mov di,ax                       ; align index register
	
    ; prepare loop
    xor cx,cx
    mov cl,VLine_Lemgth
    mov dl,VLine_Start_Row
    
dvline_loop:
    
    ; draw character
    mov al,V_LINE
	mov es:[di],al                  ; Copy character
	inc di
	mov al,Window_Border_Style
	mov es:[di],al                  ; Copy attribute byte to destination
	inc di

    inc dl                          ; check if we are out of bounds
    cmp dl,SCREEN_HEIGHT
    jge dvline_end
    
	xor ax,ax
	mov ax,di
	add ax,SCREEN_BUFFER_BYTE_WIDTH
	sub ax,2
    mov di,ax
        
    loop dvline_loop
    
dvline_end:
    
    pop di
    pop dx
    pop cx
    pop bx
    pop ax                          ; restore registers
    
	ret
DRAW_VLINE ENDP

;----
; (Re)draw the content of the window
; Inputs: None
; Output: None
; Destroys: None
;----
PUBLIC _WINDOW_REDRAW_CONTENT
_WINDOW_REDRAW_CONTENT PROC
    push ax                             ; save registers
    push bx
    push cx
    push es
    push di
    
    ; align es with the start of the text screen buffer
   	mov ax,VIDEO_MEMORY_ADDR            ; Align es with screen memory
   	mov es,ax

    ; align source index with window buffer
    lea si,Window_Content_Buffer
    
    ; TODO: Consider viewport

    mov cl,0                            ; cl = counter for the row

 _win_redraw_next_row:
    mov ch,0                            ; ch = counter for the column
    
   	; find start of the window content in the screen
   	mov al,Window_Pos_Row
   	inc al
   	add al,cl
   	mov bl,SCREEN_WIDTH
   	mul bl
   	xor bx,bx
   	mov bl,Window_Pos_Column
   	inc bl
	add ax,bx                       ; ax = ((Window_Pos_Row+1) * SCREEN_WIDTH) + (Window_Pos_Column+1)
	shl ax,1                        ; ax = ax * 2
	mov di,ax                       ; align index register
  
   	; copy bytes from the content buffer to
   	mov al,[si]
   	mov es:[di],al
   	inc di
   	; the screen, using the defined content style
    mov al,Window_Content_Style
   	mov es:[di],al
   	inc di
   	inc ch
    cmp ch,Window_Content_Width
    jge _win_redraw_next_row
    
    
   	; until we reach the end of the content line
   	; or we reach the edge of the window
   	; repeat this for all the lines in the buffer until
   	; we reach the end of the buffer or the bottom of the window
    
    pop di
    pop es
    pop cx
    pop bx
    pop ax                              ; restore registers
	ret
_WINDOW_REDRAW_CONTENT ENDP

PUBLIC _WINDOW_CLOSE
_WINDOW_CLOSE PROC
    call RESTORE_BACKGROUND
	ret
_WINDOW_CLOSE ENDP

PUBLIC _WINDOW_CLEAR
_WINDOW_CLEAR PROC

	ret
_WINDOW_CLEAR ENDP

PUBLIC _WINDOW_HIDE
_WINDOW_HIDE PROC
    call RESTORE_BACKGROUND
	ret
_WINDOW_HIDE ENDP

;----
; Write a line of text at the current cursor location
; Assume DS is already pointing to the data segment and SI has the effective address
; Inputs: di points to a null-terminated string to be written to the screen
; Output: None
; Destroys: None
;----
PUBLIC _WINDOW_WRITELN
_WINDOW_WRITELN PROC
    push ax                         ; save registers
    push di
    push si
    
    ; TODO: Determine cursor location on the buffer and offset
    
    lea di,Window_Content_Buffer
_win_writeln_loop:
    mov al,[si]
    cmp al,0
    je _win_writeln_end
    mov [di],al    
    inc di
    inc si
    ; TODO: Check if we need to scroll text up
    
    jmp _win_writeln_loop
_win_writeln_end:

    ; TODO: Complete what remains of the line and go to the next line
    
    ; TODO: Update the new cursor position

    pop si
    pop di
    pop ax                          ; restore registers 
    
    call _WINDOW_REDRAW_CONTENT
    
	ret
_WINDOW_WRITELN ENDP

PUBLIC _WINDOW_WRITE
_WINDOW_WRITE PROC

	ret
_WINDOW_WRITE ENDP

PUBLIC _WINDOW_GOTOXY
_WINDOW_GOTOXY PROC

	ret
_WINDOW_GOTOXY ENDP

SAVE_BACKGOUND PROC
    
	ret
SAVE_BACKGOUND ENDP

RESTORE_BACKGROUND PROC

	ret
RESTORE_BACKGROUND ENDP

END