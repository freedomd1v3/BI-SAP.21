.org 0x1000 ; Including "printlib.inc" outside of dseg a cseg
    .include "printlib.inc"
    
.dseg	    ; Switching to data memory
.org 0x100
    str_copy: .byte 35 + 32 ; Reserving space to copy "str"
 
.cseg	    ; Switching to program memory
.org 0
    jmp start

.org 0x100
str: .db "SOME REALLY COOL TEXT SLIDING HERE                                ", 0    ; String ended with '0'

start:
    ldi r16, high(str_copy * 2) - low(str_copy * 2)
    
    ; Setting Z as pointer to str
    ldi r30, low(str * 2)
    ldi r31, high(str * 2)
    
    ; Setting X as pointer to str_copy
    ldi r26, low(str_copy)
    ldi r27, high(str_copy)
    
    copying:
	lpm r16, Z+
	st X+, r16
	cpi r16, 0   ; Comparing r0 with 0
	brne copying
	
    ; Clearing register Z for better debugging
    clr r30
    clr r31
    
    ; X = &str_copy[0]
    ldi r26, low(str_copy)
    ldi r27, high(str_copy)
    
    call init_disp
    ldi r18, 1	    ; Amount of letters written on display
    clr r19	    ; Current position at str_copy
    printing:
	cpi r19, 35 + 32    ; sizeof(str_copy)
	brne printing_continuation
	call reset_current_position
	
	printing_continuation:
	    ldi r26, low(str_copy)
	    mov r20, r19
	    shift_X:
		inc r26
		dec r20
		brne shift_X
	    clr r20	; i = 0, also a position to output the ltter
	one_iteration:
	    cp r20, r18
	    breq increment_r18	; We're not sure, if r18 = 32 => jump to increment_r17
	    
	    ld r16, X+	; r16 = str_copy[X++]
	    cpi r16, 0
	    brne iteration_continuation
	    call reset_X
	    
	    iteration_continuation:
		mov r17, r20
		cpi r17, 16
		brlo both
		subi r17, 16
		subi r17, -0x40
		both: call show_char
		      inc r20
		      jmp one_iteration
	    
	increment_r18:
	    cpi r18, 32
	    breq waiting_loop
	    inc r18
	waiting_loop:	; Almost a second
	    ldi r22, 15
	    wait3: ldi r23, 255
	    wait2: ldi r24, 255
	    wait:
		dec r24
		brne wait
		dec r23
		brne wait2
		dec r22
		brne wait3
	    
	    cpi r18, 32
	    brne printing
	    inc r19
	    jmp printing    ; All is done - doing again and again

reset_current_position:
    ldi r19, 0
    ret 

reset_X:
    ldi r26, low(str_copy)
    ldi r27, high(str_copy)
    ld r16, X+
    ret
