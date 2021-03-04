;Manejo LCD
LCD_Clear	equ	b'00000001'	; Borra y cursor al principio
LCD_Inc		equ	b'00000110'	; Selecciona incrementos
Curs_Off	equ	b'00001100'	; Disp. on, sin cursor, no parp.
LCD_Funcion	equ	b'00101100'	; Bit 4 DL (=0 4 bit bus)
LCD_CGRAM	equ	b'01000000'	; Pone dirección CGRAM 
LCD_Linea1	equ	b'10000000'	; Posición  0 (00h). Línea 1
LCD_Linea2	equ	b'11000000'	; Posición 64 (40h). Línea 2
; Subrutinas manejo LCD
LCDReset
	bcf 	LCD_Control,LCD_RS	; LCD_RS = 0 Comando
	movlw	b'00101000'			;manda MSB
	movwf	LCD_Data			;LCD_Data = W

	;bsf		LCD_Control,LCD_E	;LCD_E = 1
	call	Pause				;retardo 1us
	bcf		LCD_Control,LCD_E	; LCD_E = 0

	movlw	LCD_Funcion		; Repite orden
	call	LCDComando
	movlw	LCD_Clear		; 
	call 	LCDComando
	movlw	LCD_Inc			;
	call	LCDComando
	return
; ---
LCDComando
	bcf 	LCD_Control,LCD_RS	; LCD_RS = 0 Comando

	movwf	LCDdato				;guarda el comando en LCDdato
	andlw	b'11110000'			;manda MSB
	movwf	LCD_Data			;LCD_Data = W

	bsf		LCD_Control,LCD_E	;LCD_E = 1
	call	Pause				;retardo 1us
	bcf		LCD_Control,LCD_E	; LCD_E = 0

	SWAPF	LCDdato,0
	andlw	b'11110000'			;manda LSB
	movwf	LCD_Data			;LCD_Data = W
LCDEnable
	bsf		LCD_Control,LCD_E	; LCD_E = 1
	call	Pause				; retardo 1us
	bcf		LCD_Control,LCD_E	; LCD_E = 0
	return
; ---
LCDWrite
	bsf		LCD_Control,LCD_RS	; LCD_RS = 1 Caracter
;	bcf		LCD_Control,LCD_RS	; LCD_RS = 0 Comando

	movwf	LCDdato				;guarda el comando en LCDdato
	andlw	b'11110000'			;manda MSB
	addlw	b'00000100'
	movwf	LCD_Data			;LCD_Data = W
	;bsf		LCD_Control,LCD_RS	; LCD_RS = 1 Caracter

	bsf		LCD_Control,LCD_E	;LCD_E = 1
	call	Pause				;retardo 1us
	bcf		LCD_Control,LCD_E	; LCD_E = 0

	SWAPF	LCDdato,0
	andlw	b'11110000'			;manda LSB
	addlw	b'00000100'
	movwf	LCD_Data			;LCD_Data = W
;	bsf		LCD_Control,LCD_RS	; LCD_RS = 1 Caracter

	goto	LCDEnable
; ---
Pause
	movlw   0xff
    movwf   Counter1
	movlw   0x05
    movwf   Counter2
LCDLoop
	decfsz  Counter1,1
	goto    LCDLoop
	decfsz  Counter2,1
	goto    LCDLoop
	return
; --- NEW --- NEW
LCDClear
	movlw   LCD_Clear
	call    LCDComando
	return
; ---
LCDInc
	movlw   LCD_Inc
	call    LCDComando
	return
; ---
CursorOff
	movlw   Curs_Off
	call    LCDComando
	return
; ---
LCDCGRAM
	movlw   LCD_CGRAM
	call    LCDComando
	return
; ---
LCDLine1
	movlw	LCD_Linea1
	call	LCDComando
	return
; ---
LCDLine2
	movlw   LCD_Linea2
	call    LCDComando
	return
; ---
