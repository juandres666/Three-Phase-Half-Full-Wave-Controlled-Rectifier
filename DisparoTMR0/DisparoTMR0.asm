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
		GOTO	INT_FIN

INT_RB0	bcf		PORTB,3		;Triac Off
		bcf		INTCON,INTF	;Restaura flag de interrupción RB0/INT

		COMf	ADRESH,W
		MOVWF	TMR0
		
		GOTO	INT_FIN

INT_TR0	bcf		INTCON,T0IF		;clear flag TMR1

		movlw	0x5F
		movwf	tiempo
DISP	bsf		PORTB,3		;Triac On
		decfsz	tiempo,1
		goto	DISP
		
		bcf		PORTB,3		;Triac Off

INT_FIN	SWAPF 	REG_S,W		;invierto nibbles REG_S y paso a W
		MOVWF 	STATUS		;Restauro Status
		SWAPF 	REG_W,f		;invierto nibbles de Reg_W
		SWAPF 	REG_W,W		;invierto y paso a w
		RETFIE

Inicio  bsf		STATUS,RP0	;Selecciona banco 1
		movlw	b'11110111'
		movwf	TRISB		;'----,Triac,--,INT'
		MOVLW	b'00000011'	;LCDbus&LCDcontrol
		MOVWF	TRISD

		MOVLW	b'00001110'	;justIZQ,---,1canalRA0 Vref=VddVss
		MOVWF 	ADCON1
		
		movlw	b'01000100'
		movwf	OPTION_REG	;Preescaler de 32 asociado al TMR0
		bcf		STATUS,RP0	;Selecciona banco 0
		
		MOVLW	b'01000001'	;Fosc/8-,RA0--,NoConv,-,ActivadoCAD
		MOVWF 	ADCON0		;
		
		call 	LCDReset	;Inicia LCD
		call   	CursorOff	;Sin Cursor

		movlw	b'10110000'	;Enable global,
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
		MOVLW	"G"			;W=ASCII(V)
		CALL	LCDWrite
		GOTO	START
		
TABLA	ADDWF	PCL,1
		DT		"0123456789"

INCR	INCF	COMPARA,F	;incremento COMPARA ahi mismo

		MOVLW	d'08'		;Incrementa UNIDAD de 7 en 7
		MOVWF	INC7
INC7	DECFSZ	INC7,F
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
