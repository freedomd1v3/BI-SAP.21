.org 0x1000 ; Nacitani "printlib.inc" mimo dseg a cseg
    .include "printlib.inc"
    
.dseg	    ; Prepnuti do pameti dat
.org 0x100
    str_copy: .byte 35 + 32 ; Rezervovani mista pro kopirovani "str"
 
.cseg	    ; Prepnuti do pameti programu
; Zacatek programu - po resetu
.org 0
    jmp start

; Zacatek programu - hlavni program
.org 0x100
str: .db "SOME REALLY COOL TEXT SLIDING HERE                                ", 0    ; Retezec zakonceny nulou

start:
    ldi r16, high(str_copy * 2) - low(str_copy * 2)
    
    ; Nastaveni Z jako pointeru na str
    ldi r30, low(str * 2)
    ldi r31, high(str * 2)
    
    ; Nastaveni X jako pointeru na str_copy
    ldi r26, low(str_copy)
    ldi r27, high(str_copy)
    
    copying:
	lpm r16, Z+
	st X+, r16
	cpi r16, 0   ; Porovnani r0 s 0: neni to "copy immediate", ale "compare immediate" :)
	brne copying
	
    ; Cisteni registru Z - neni to potreba, ale nechci mit registry
    ; oznaceny barevne v I/O memory
    clr r30
    clr r31
    
    ; X = str_copy
    ldi r26, low(str_copy)
    ldi r27, high(str_copy)
    
    call init_disp
    ldi r18, 1	    ; Pocet vypsanych pismen na displeji
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
	    clr r20	; i = 0, taky pozice pro vypis pismena
	one_iteration:
	    cp r20, r18
	    breq increment_r18	; Nejsem si jisty, jestli r18 = 32 => skok na increment_r17
	    
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
	waiting_loop:	; Skoro sekunda
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
	    jmp printing    ; Vsetko je hotovy - delame celej cylkus znovu

reset_current_position:
    ldi r19, 0
    ret 

reset_X:
    ldi r26, low(str_copy)
    ldi r27, high(str_copy)
    ld r16, X+
    ret