;Manejo LCD
LCD_Clear	equ	b'00000001'	; Borra y cursor al principio
LCD_Inc		equ	b'00000110'	; Selecciona incrementos
Curs_Off	equ	b'00001100'	; Disp. on, sin cursor, no parp.
LCD_Funcion	equ	b'00111100'	; Bit 4 DL (=0 4 bit bus)
LCD_CGRAM	equ	b'01000000'	; Pone dirección CGRAM 
LCD_Linea1	equ	b'10000000'	; Posición  0 (00h). Línea 1
LCD_Linea2	equ	b'11000000'	; Posición 64 (40h). Línea 2
; Subrutinas manejo LCD
LCDReset
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
	movwf	LCD_Data		; LCD_Data = W
LCDEnable
	bsf		LCD_Control,LCD_E	; LCD_E = 1
	call	Pause				; retardo 1us
	bcf		LCD_Control,LCD_E	; LCD_E = 0
	return
; ---
LCDWrite
	bsf		LCD_Control,LCD_RS	; LCD_RS = 1 Caracter
	movwf	LCD_Data			; LCD_Data = W
	goto	LCDEnable
; ---
Pause
	movlw   0xff
    movwf   Counter1
	movlw   0x0A
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
