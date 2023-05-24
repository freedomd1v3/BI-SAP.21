; Headers to work with the display
.org 0x1000 ; <1>
.include "printlib.inc"

.org 0
    jmp start

.org 0x100
start:
    call init_disp
    ldi r18, 0x75
    
    mov r19, r18    ; r19 = 0x5A
    ldi r20, 4	    ; i = 4
    get_first_character:
	lsr r19	    ; 0x0 - 0xff => unsigned => we'll use logic shifts, not arith.
	dec r20
	brne get_first_character

    ; Outputting first character
    ; If r19 >= 10
    cpi r19, 10	; Thanks to Stack Overflow
    brcs inject_first_digit
    ; Else ("inject_first_letter")
    ldi r16, 65	; 'A'
    subi r19, 0x0A
    add r16, r19
    jmp print_first_character
    inject_first_digit:
	ldi r16, 48 ; '0'
	add r16, r19
    print_first_character:
	ldi r17, 0
	call show_char
	
    ; Getting rid of first character
    ldi r19, 4
    shift_to_left_four_times:
	lsl r18
	dec r19
	brne shift_to_left_four_times
    ldi r19, 4
    shift_to_right_four_times:
	lsr r18
	dec r19
	brne shift_to_right_four_times

    ; Outputting the second character
    cpi r18, 10
    brcs inject_second_digit
    ldi r16, 65	; 'A'
    subi r18, 0x0A
    add r16, r18
    jmp print_second_character
    inject_second_digit:
	ldi r16, 48 ; '0'
	add r16, r18
    print_second_character:
	ldi r17, 1
	call show_char

    jmp end

end: jmp end
