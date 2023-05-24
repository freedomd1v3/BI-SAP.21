; Program always starts after reset ...
.org 0 ; ... at 0x00
jmp start

; Program start - main ...
.org 0x100 ; ... is at 0x100
start:

    ldi r16, 5
    ldi r17, 10
    ldi r18, 58
    
    ; 4 * R16
    lsl r16
    brvs overfw     ; We're screwed
    lsl r16
    brvs overfw
    
    ; R19 - tmp
    mov r19, r17
    lsl r17	    ; 2 * R17
    brvs overfw
    add r17, r19    ; 2 * R17 + R17 = 3 * R17
    brvs overfw
    clr r19         ; Clear tmp (reset r19 to 0)
    
    mov r20, r16    ; R20 = 4 * R16
    add r20, r17    ; R20 = 4 * R16 + 3 * R17
    brvs overfw
    sub r20, r18    ; R20 = 4 * R16 + 3 * R17 - R18
    brvs overfw	    ; Got overflow (e.g. - sub + = +)
    
    asr r20 ; R20 /= 2
    brcs overfw	; Arithmetic shift sets carry in case of losing accuracy
    asr r20 ; R20 /= 4
    brcs overfw
    asr r20 ; R20 /= 8
    brcs overfw
    
    jmp end ; All good - finish the program
    
    overfw:
	SEV
	ldi r25, 1  ; Signal
	jmp overfw

end: jmp end ; Finishing the program - endless loop
