; Zacatek programu - po resetu
.org 0 ; Zpracov�n� k�du po resetu za?�zen� za?�n� v?dy na adrese 0
jmp start

; Zacatek programu - hlavni program
.org 0x100 ; Na adrese 256 (0x100 ?estn�ctkov?) za?�n� program.
start:

    ldi r16, 5
    ldi r17, 10
    ldi r18, 58
    
    ; 4 * R16
    lsl r16
    brvs fucked	; We're screwed
    lsl r16
    brvs fucked
    
    ; R19 - tmp
    mov r19, r17
    lsl r17	    ; 2 * R17
    brvs fucked
    add r17, r19    ; 2 * R17 + R17 = 3 * R17
    brvs fucked
    ldi r19, 0x00   ; RESET r19
    
    mov r20, r16    ; R20 = 4 * R16
    add r20, r17    ; R20 = 4 * R16 + 3 * R17
    brvs fucked
    sub r20, r18    ; R20 = 4 * R16 + 3 * R17 - R18
    brvs fucked	    ; Got overflow (e.g. - sub + = +)
    
    asr r20 ; R20 /= 2
    brcs fucked	; Aritmetick� posuv nastavuje carry v p?�pad? ZP
    asr r20 ; R20 /= 4
    brcs fucked
    asr r20 ; R20 /= 8
    brcs fucked
    
    jmp end ; Dobr� - zastav�me program
    
    fucked:
	SEV
	ldi r25, 1  ; Sign�l
	jmp fucked  ; Dobr� v?etko neni - ale st�le program ukon?�me

end: jmp end ; Zastavime program - nekonecna smycka