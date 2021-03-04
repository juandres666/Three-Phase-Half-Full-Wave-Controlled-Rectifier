		list		p=16F871		;Tipo de procesador
		#include	<P16F871.inc>	;Definiciones de registros internos
		__config 	0x3D39
		errorlevel	-302
								;Config LCD Port's
LCD_Control	equ	PORTD	;LCDcontrol'-----,RW*,E,RS'*NoUsado;,
LCD_RS		equ	2		;Comando o dato		0/1
LCD_E		equ	3		;EnableLCD			0(off)/1(on)
LCD_Data	equ	PORTD	;LCDbus'd7,d6,d5,d4,d3,d2,d1,d0'

	cblock	0x20
Counter1
Counter2
LCDdato

REG_W
REG_S

tiempo

Resultado_H
Resultado_L
Contador
Multiplicador
Estatus_Temp

DEC7

UNIDAD
DECENA
CENTENA
MIL
COMPARA
	endc

		org		0x00		;Reset
		goto	Inicio
		org		0x04		;Interrupt
							;Tratamiento de interrupción.
		MOVWF 	REG_W 		;SaVe W en Reg_W
		SWAPF 	STATUS,W 	;invierto nibbles Status y paso a W
		MOVWF 	REG_S 		;SaVe ESTADO
							;Interrupt?¿
		BTFSC	INTCON,INTF ;RB0
		GOTO	INT_RB0
		BTFSC	INTCON,T0IF	;TMR0
		GOTO	INT_TR0
		BTFSC	PIR1,TMR1IF	;TMR1
		GOTO	INT_TR1
		BTFSC	PIR1,TMR2IF	;TMR2
		GOTO	INT_TR2
		GOTO	INT_FIN

INT_RB0	bcf		INTCON,INTF	;Restaura flag de interrupción RB0/INT

		BTFSC	PORTB,1
		GOTO	RB0_TR0
		BTFSC	PORTB,2
		GOTO	RB0_TR1
		BTFSC	PORTB,3
		GOTO	RB0_TR2
		GOTO	INT_FIN

RB0_TR0	bcf		PORTB,5		;Triac Off
		COMf	ADRESH,W
		MOVWF	TMR0
		
		GOTO	INT_FIN
		
RB0_TR1	bcf		PORTB,6		;Triac Off
		bcf		INTCON,INTF	;Restaura flag de interrupción RB0/INT

		clrf	Resultado_H
		clrf	Resultado_L		;Pone a 0000 el resultado inicial
		movlw	0x08
		movwf	Contador		;Inicia el contador con 8		
		bcf		STATUS,C		;Borra el carry
		
		movlw	d'32'
		movwf	Multiplicador	;Multiplicador=32
Bucle	movf	ADRESH,W		;Carga el multiplicando=ADRESH//Delay_A
		btfsc	Multiplicador,0	;Es 1 el bit de menos peso del multiplicador ??
		addwf	Resultado_H,F	;Si, se suma el multiplicando
		rrf		Resultado_H,F	;NO
		rrf		Resultado_L,F	;Desplazamiento a la derecha del resultado
								;Rota a la derecha el multiplicador sin que se modifique el flag Carry

		movf	STATUS,W		;Rota_sin_Carry
		movwf	Estatus_Temp	;Salva temporalmente el carry
		rrf		Multiplicador,F	;Desplaza a la derecha el multiplicador		
		movf	Estatus_Temp,W
		movwf	STATUS			;Recupera el carry original
		decfsz	Contador,F		;Repite el bucle 8 veces
		goto	Bucle

		comf	Resultado_L,W
		movwf	TMR1L
		comf	Resultado_H,W
		movwf	TMR1H			;Carga el TMR1

		GOTO	INT_FIN
		
RB0_TR2	bcf		PORTB,7		;Triac Off
		bcf		INTCON,INTF	;Restaura flag de interrupción RB0/INT
		
		bsf		T2CON,TMR2ON;Timer2 ON
		
		MOVf	ADRESH,W
		bsf		STATUS,RP0	;Selecciona banco 1
		MOVWF	PR2
		bcf		STATUS,RP0	;Selecciona banco 0

		GOTO	INT_FIN

INT_TR0	bcf		INTCON,T0IF		;clear flag TMR1

		movlw	0x5F
		movwf	tiempo
DISP0	bsf		PORTB,5		;Triac On
		decfsz	tiempo,f
		goto	DISP0
		
		bcf		PORTB,5		;Triac Off
		GOTO	INT_FIN
		
INT_TR1	bcf		PIR1,TMR1IF		;clear flag TMR1

		movlw	0x0f
		movwf	tiempo
DISP1	bsf		PORTB,6		;Triac On
		decfsz	tiempo,f
		goto	DISP1
		
		bcf		PORTB,6		;Triac Off
		GOTO	INT_FIN
		
INT_TR2	bcf		PIR1,TMR2IF		;clear flag TMR2

		bcf		T2CON,TMR2ON;Timer2 OFF

		movlw	0x5F
		movwf	tiempo
DISP2	bsf		PORTB,7		;Triac On
		decfsz	tiempo,f
		goto	DISP2
		
		bcf		PORTB,7		;Triac Off

INT_FIN	SWAPF 	REG_S,W		;invierto nibbles REG_S y paso a W
		MOVWF 	STATUS		;Restauro Status
		SWAPF 	REG_W,f		;invierto nibbles de Reg_W
		SWAPF 	REG_W,W		;invierto y paso a w
		RETFIE

Inicio  bsf		STATUS,RP0	;Selecciona banco 1
		movlw	b'00011111'
		movwf	TRISB		;'----,Triac,--,INT'
		MOVLW	b'00000011'	;LCDbus&LCDcontrol
		MOVWF	TRISD
		MOVLW	b'00000100'
		MOVWF	TRISE

		MOVLW	b'00001110'	;justIZQ,---,1canalRA0 Vref=VddVss
		MOVWF 	ADCON1
		
		BSF		PIE1,TMR1IE	;TMR1 overflow interrupt*
		BSF		PIE1,TMR2IE	;TMR1 overflow interrupt*
		
		movlw	b'11000100'
		movwf	OPTION_REG	;Preescaler de 32 asociado al TMR0
		bcf		STATUS,RP0	;Selecciona banco 0
		
		MOVLW	b'01000001'	;Fosc/8-,RA0--,NoConv,-,ActivadoCAD
		MOVWF 	ADCON0		;
		
		call 	LCDReset	;Inicia LCD
		call   	CursorOff	;Sin Cursor
		
		movlw	b'00001111'	;Postscale1:2,Timer2 OFF,Prescale1:16
		movwf	T2CON		;TMR2
		
		BSF		T1CON,TMR1ON;TMR1 en On
		movlw	b'11110000'	;Enable global,
		movwf	INTCON		;peripherial interrupt,RB0

START	bsf 	ADCON0,2	;Comienza conversión
		CLRF	UNIDAD		;borrando registro
		CLRF	DECENA		;borrando registro
		CLRF	CENTENA		;borrando registro
		CLRF	MIL			;borrando registro
		CLRF	COMPARA		;borrando registro

STOP 	btfsc	ADCON0,2 	;ver si acaba de convertir
		goto 	STOP

COMPAR	movf 	ADRESH,W	;SI: ¿Es
		XORWF	COMPARA,W	;		ADRESH
		BTFSS	STATUS,Z	;			= COMPARA?
        GOTO	INCR		;NO
        
		call	LCDLine1	;SI:Situa cursor en 1ª linea
		MOVF	MIL,W		;W=MIL
		CALL	TABLA		;W=ASCII(MIL)
		CALL	LCDWrite
		MOVF	CENTENA,W	;W=CENTENA
		CALL	TABLA		;W=ASCII(CENTENA)
		CALL	LCDWrite
		MOVF	DECENA,W	;W=DECENA
		CALL	TABLA		;W=ASCII(DECENA)
		CALL	LCDWrite
		MOVLW	","			;W=ASCII(,)
		CALL	LCDWrite
		MOVF	UNIDAD,W	;W=UNIDAD
		CALL	TABLA		;W=ASCII(UNIDAD)
		CALL	LCDWrite
		GOTO	START
		
TABLA	ADDWF	PCL,1
		DT		"0123456789"

INCR	INCF	COMPARA,F	;incremento COMPARA ahi mismo

		MOVLW	d'08'		;Incrementa UNIDAD de 7 en 7
		MOVWF	DEC7
INC7	DECFSZ	DEC7,F
		GOTO	NO_7
		GOTO  	COMPAR

NO_7	INCF	UNIDAD,F	;incremento decena ahi mismo
		MOVF	UNIDAD,W	;muevo decena a w
		XORLW	0x0A		;hago xor entre 10 Y w
		BTFSS	STATUS,Z	;veo que tiene el Z del status
		GOTO    INC7

		CLRF	UNIDAD
		INCF	DECENA,F	;incremento decena ahi mismo
		MOVF	DECENA,W	;muevo decena a w
		XORLW	0x0A		;hago xor entre 10 Y w
		BTFSS	STATUS,Z	;veo que tiene el Z del status
		GOTO    INC7

		CLRF	DECENA
		INCF	CENTENA,F
		MOVF	CENTENA,W
		XORLW	0x0A
		BTFSS	STATUS,Z
		GOTO    INC7

		CLRF	CENTENA
		INCF	MIL,1
		GOTO    INC7

		include "LCDsoft4bits.asm"
		END
