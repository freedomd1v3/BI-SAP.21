.dseg	; Prepnuti do pameti dat
.org 0x100

flag: .byte 1

.cseg
.org 0x1000 ; Nacitani "printlib.inc" mimo dseg a cseg
    .include "printlib.inc"

; Zacatek programu - po resetu
.org 0
    jmp start
.org 0x16
    jmp interrupt   ; interrupt nesmi obsahovat zadny call

; Zacatek programu - hlavni program
.org 0x100
start:
    call init_disp
    call init_buttons
    call fetch_buttons
    
    call init_int
    ldi r16, 0
    sts flag, r16   ; Inicializace pametoveho mista - flag je ted pointer
    
set_timer:
    call lcd_clear
    ; r20 = minuty, r21 = sekundy
    clr r20
    clr r21
    
    ldi r16, '0'
    ldi r17, 0
    call show_char
    ldi r17, 1
    call show_char
    ldi r16, ':'
    ldi r17, 2
    call show_char
    ldi r16, '0'
    ldi r17, 3
    call show_char
    ldi r17, 4
    call show_char
    
    skip_select_before_getting_minutes:
	call get_button
	cpi r18, 0b11110000
	brne skip_select_before_getting_minutes
    clr r18
    call get_minutes
    skip_select_before_getting_seconds:
	call get_button
	cpi r18, 0b11110000
	brne skip_select_before_getting_seconds
    clr r18
    call get_seconds

main_loop:
    lds r19, flag
    cpi r19, 0	; Otestovani flagu
    breq main_loop  ; Pokud neni flag -> navrat na zacatek
    
    ; Je flag
    ldi r19, 0	; Vycisteni flagu
    sts flag, r19
    
    ; Akce provedena 1x za sekundu
    cpi r20, 0
    brne dont_finish_break_check
    cpi r21, 0
    breq finished
    ;breq finish_iteration  ; TODO: This!
    
    dont_finish_break_check:
    dec r21
    cpi r21, 255
    brne dont_decrement_minute
    ldi r21, 59
    dec r20
    
    dont_decrement_minute:
    call print_minutes
    call print_seconds
    
    jmp main_loop
    
finished:
    ldi r16, 4
    do_some_beeps:
	cpi r16, 0
	breq last_write
	call do_beep_with_zeros
	dec r16
	ldi r24, 25
	beeps_wait3: ldi r23, 255
	beeps_wait2: ldi r22, 255
	beeps_wait:  dec r22
		     brne beeps_wait
		     dec r23
		     brne beeps_wait2
		     dec r24
		     brne beeps_wait3
	jmp do_some_beeps

    last_write:
    ldi r16, 'V'
    ldi r17, 0
    call show_char
    ldi r16, 'A'
    ldi r17, 1
    call show_char
    ldi r16, 'J'
    ldi r17, 2
    call show_char
    ldi r16, 'I'
    ldi r17, 3
    call show_char
    ldi r16, 'C'
    ldi r17, 4
    call show_char
    ldi r16, 'K'
    ldi r17, 5
    call show_char
    ldi r16, 'A'
    ldi r17, 6
    call show_char
    ldi r16, ' '
    ldi r17, 7
    call show_char
    ldi r16, 'U'
    ldi r17, 8
    call show_char
    ldi r16, 'V'
    ldi r17, 9
    call show_char
    ldi r16, 'A'
    ldi r17, 10
    call show_char
    ldi r16, 'R'
    ldi r17, 11
    call show_char
    ldi r16, 'E'
    ldi r17, 12
    call show_char
    ldi r16, 'N'
    ldi r17, 13
    call show_char
    ldi r16, 'A'
    ldi r17, 14
    call show_char
    
    wait_for_last_select:
	call get_button
	; Tady by vzdy melo byt male cekani
	ldi r17, 255
	last_select_small_cooldown2: ldi r16, 255
	last_select_small_cooldown:  dec r16
				     brne last_select_small_cooldown
				     dec r17
				     brne last_select_small_cooldown2
	cpi r18, 0b10010000 ; Got select
	brne wait_for_last_select
    clr r18
    jmp set_timer


; Initialize button tapper
init_buttons:
    push r16
    lds r16, ADCSRA
    ori r16, (1<<ADEN)
    sts ADCSRA, r16

    ldi r16, (0b01<<REFS0) | (1<<ADLAR); 4
    sts ADMUX, r16

    pop r16
    ret

; Tell Arduino to fetch new button tap
fetch_buttons:
    push r16
    lds r16, ADCSRA
    ori r16, (1 << ADSC)    ; Nastaveni bitu ADSC na adrese ADCSRA na log. 1
    sts ADCSRA, r16

    pop r16
    ret

; Wait, until button conversion is over
wait_for_conversion:
    push r16
    check_adsc:
	lds r16, ADCSRA
	andi r16, (1 << ADSC)
	cpi r16, (1 << ADSC)
	breq check_adsc
    pop r16
    ret


; Read minutes
; @return r20
get_minutes:
    push r18
    clr r20
    get_minutes_until_select:
	call get_button
	; Tady by vzdy melo byt male cekani
	ldi r17, 255
	get_minutes_small_cooldown2: ldi r16, 255
	get_minutes_small_cooldown:  dec r16
				     brne get_minutes_small_cooldown
				     dec r17
				     brne get_minutes_small_cooldown2
	cpi r18, 0b11110000 ; Got nothing
	breq get_minutes_until_select
	
	cpi r18, 0b10010000 ; Select
	breq break_minutes_loop
	
	cpi r18, 0b00010000 ; Up
	breq increment_r20
    continue_increment_r20:
	cpi r18, 0b00110000 ; Down
	breq decrement_r20
    continue_decrement_r20:
	call print_minutes
	
	; Cekani mezi stisknutimi
	ldi r18, 15
	get_minutes_wait3: ldi r17, 255
	get_minutes_wait2: ldi r16, 255
	get_minutes_wait:  dec r16
			   brne get_minutes_wait
			   dec r17
			   brne get_minutes_wait2
			   dec r18
			   brne get_minutes_wait3
	jmp get_minutes_until_select
    break_minutes_loop:
    pop r18
    ret
    
    increment_r20:
    inc r20
    cpi r20, 60
    brne continue_increment_r20
    clr r20
    jmp continue_increment_r20

    decrement_r20:
    dec r20
    cpi r20, 255
    brne continue_decrement_r20
    ldi r20, 59
    jmp continue_decrement_r20

; Print minutes
; @param r20
print_minutes:
    push r21
    mov r21, r20
    clr r19
    get_first_number_minutes:
	cpi r21, 10
	brlo continue_minutes
	subi r19, -1
	subi r21, 10
	jmp get_first_number_minutes
    continue_minutes:
    mov r16, r19
    subi r16, -'0'
    ldi r17, 0
    call show_char
    mov r16, r21
    subi r16, -'0'
    ldi r17, 1
    call show_char
    pop r21
    ret

    
; Read seconds
; @return r21
get_seconds:
    clr r21
    get_seconds_until_select:
	call get_button
	; Tady by vzdy melo byt male cekani
	ldi r17, 255
	get_seconds_small_cooldown2: ldi r16, 255
	get_seconds_small_cooldown:  dec r16
				     brne get_seconds_small_cooldown
				     dec r17
				     brne get_seconds_small_cooldown2
	cpi r18, 0b11110000 ; Got nothing
	breq get_seconds_until_select
	
	cpi r18, 0b10010000 ; Select
	breq break_seconds_loop
	
	cpi r18, 0b00010000 ; Up
	breq increment_r21
    continue_increment_r21:
	cpi r18, 0b00110000 ; Down
	breq decrement_r21
    continue_decrement_r21:
	call print_seconds
	
	; Cekani mezi stisknutimi
	ldi r18, 15
	get_seconds_wait3: ldi r17, 255
	get_seconds_wait2: ldi r16, 255
	get_seconds_wait:  dec r16
			   brne get_seconds_wait
			   dec r17
			   brne get_seconds_wait2
			   dec r18
			   brne get_seconds_wait3
	jmp get_seconds_until_select
    break_seconds_loop:
    ret
    
    increment_r21:
    inc r21
    cpi r21, 60
    brne continue_increment_r21
    clr r21
    jmp continue_increment_r21

    decrement_r21:
    dec r21
    cpi r21, 255
    brne continue_decrement_r21
    ldi r21, 59
    jmp continue_decrement_r21

; Print seconds
; @param r21
print_seconds:
    push r20
    mov r20, r21
    clr r19
    get_first_number_seconds:
	cpi r20, 10
	brlo continue_seconds
	subi r19, -1
	subi r20, 10
	jmp get_first_number_seconds
    continue_seconds:
    mov r16, r19
    subi r16, -'0'
    ldi r17, 3
    call show_char
    mov r16, r20
    subi r16, -'0'
    ldi r17, 4
    call show_char
    pop r20
    ret
    

; Gets a button tap
; @return r18
get_button:
    call fetch_buttons
    call wait_for_conversion
    lds r18, ADCH
    andi r18, 0b11110000    ; Mask last 4 bits
    cpi r18, 0b11110000
    ret


do_beep_with_zeros:
    push r16
    call lcd_clear
    ;call init_disp
    ldi r24, 20
    zeros_wait3: ldi r23, 255
    zeros_wait2: ldi r22, 255
    zeros_wait:  dec r22
		 brne zeros_wait
		 dec r23
		 brne zeros_wait2
		 dec r24
		 brne zeros_wait3
    ldi r16, '0'
    ldi r17, 0
    call show_char
    ldi r17, 1
    call show_char
    ldi r17, 3
    call show_char
    ldi r17, 4
    call show_char
    
    ldi r16, ':'
    ldi r17, 2
    call show_char
    pop r16
    ret


init_int:
    push r16
    cli	; Globalni zakazani preruseni

    ; Vycisteni aktualni hodnoty citace TCNT1 (aby prvni sekunda nezacala nekde "od pulky")
    clr r16
    sts TCNT1H, r16
    sts TCNT1L, r16

    ; Povoleni preruseni ve chvili, kdy citac TCNT1 dosahne hodnoty OCR1A
    ldi r16, (1 << OCIE1A)
    sts TIMSK1, r16

    ; Nastaveni cisteni citace TCNT1 ve chvili, kdy dosahne hodnoty OCR1A (1 << WGM12)
    ; Nastaveni preddelicky na 1024 (0b101 << CS10 - bity CS12, CS11 a CS10 jsou za sebou)
    ldi r16, (1<<WGM12) | (0b101<<CS10)
    sts TCCR1B, r16

    ; Nastaveni OCR1A, tj. vysledne frekvence preruseni
    ; Frekvence preruseni = frekvence cipu 328P / preddelicka / (OCR1A+1)
    ; Frekvence cipu 328P je 16 MHz, tj. 16000000
    ; Preddelicka je nastavena na 1024
    ; Frekvenci preruseni chceme na 1 Hz
    ; OCR1A = (frekvence cipu 328P / preddelicka / frekvence preruseni) - 1
    ; OCR1A = (16000000 / 1024 / 1) - 1
    ; OCR1A = 15624
    ; 16bitovou hodnotu je treba nastavit do dvou registru OCR1AH:OCR1AL
    ; 15624 = 61 * 256 + 8
    ldi r16, 61
    sts OCR1AH, r16
    ldi r16, 8
    sts OCR1AL, r16

    ; Zakazani preruseni od tlacitek
    clr r16
    out EIMSK, r16

    sei	; Globalni povoleni preruseni
    pop r16
    ret

interrupt:
    ; Uklid registru a SREG
    push r16
    in r16, SREG
    push r16

    ; Nastav flag
    ldi r16, 1
    sts flag, r16

    ; Obnoveni SREG a registru
    pop r16
    out SREG, r16
    pop r16
    reti    ; Navrat z kodu preruseni