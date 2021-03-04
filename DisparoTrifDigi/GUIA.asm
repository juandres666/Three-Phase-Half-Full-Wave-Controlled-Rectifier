		list		p=16f877A		;Tipo de procesador
		#include	<p16f877A.inc>	;Definiciones de registros internos
		__config 	0x3f39
		errorlevel	-302

LCD_Control	equ		PORTB	;LCDcontrol'-----,RW*,E,RS'*NoUsado;0(off)/1(on),0/1
LCD_RS		equ		1		;Comando o dato
LCD_E		equ		2		;EnableLCD
LCD_Data	equ		PORTD	;LCDbus'd7,d6,d5,d4,d3,d2,d1,d0'

	cblock	0x20
LCD_Counter1
COMP_L
COMP_H
Delay_L
Delay_H
UNIDAD
DECENA
CENTENA
LCD_Counter2
UMIL
DMIL
INC12
Delay_L_A
Delay_H_A
Resultado_L
Resultado_H
REG_W
REG_S


				;SUMA
Dato_A_L			;Define la posición del dato A (bajo)
Dato_A_H			;Define la posición del dato A (alto)
;Resultado_L		;Define la posición del resultado (bajo)
;Resultado_H		;Define la posición del resultado (alto)

				;MULT
Multiplicando	;Variable para el multiplicando
Multiplicador	;Variable para el multiplicador
ResultadoM_H	;Parte alta del resultado
ResultadoM_L	;Parte baja del resultado
Estatus_Temp	;Reg. de estado temporal
Contador		;Variable con número de veces a operar

cont40

	endc

		org		0x00		;Reset
		goto	Inicio
		org		0x04		;Interrupt
							;Tratamiento de interrupción.
		MOVWF 	REG_W 		;SaVe W en Reg_W
		SWAPF 	STATUS,W 	;invierto nibbles Status y paso a W
		MOVWF 	REG_S 		;SaVe ESTADO

		bcf		PORTB,7		;Triac Off

		BTFSC	INTCON,INTF
		GOTO	INT_RB0
		BTFSC	PIR1,TMR1IF
		GOTO	INT_TR1
		GOTO	INT_FIN

INT_RB0	bcf		INTCON,INTF	;Restaura flag de interrupción RB0/INT

		MOVF	Delay_L_A,0
		MOVWF	Delay_L
		MOVF	Delay_H_A,0
		MOVWF	Delay_H

		bcf		STATUS,C
		rlf		Delay_L,F
		rlf		Delay_H,F
		rlf		Delay_L,F
		rlf		Delay_H,F
		rlf		Delay_L,F
		rlf		Delay_H,F	;Multiplica por 8
		comf	Delay_L,W
		movwf	TMR1L
		comf	Delay_H,W
		movwf	TMR1H		;Carga el TMR1
		GOTO	INT_FIN

INT_TR1	bcf		PIR1,TMR1IF	;clear flag TMR1
		bsf		PORTB,7		;Triac On

INT_FIN	SWAPF 	REG_S,W		;invierto nibbles REG_S y paso a W
		MOVWF 	STATUS		;Restauro Status
		SWAPF 	REG_W,f		;invierto nibbles de Reg_W
		SWAPF 	REG_W,W		;invierto y paso a w
		RETFIE

Inicio  clrf	PORTB		
		bsf		STATUS,RP0	;Selecciona banco 1
		movlw	b'11001111'
		movwf	OPTION_REG	;Preescaler de 128 asociado al WDT
		movlw 	b'11111111'
		movwf	TRISA		;RA0 entrada analógica
		movlw	b'01111001'
		movwf	TRISB		;'S1,S2,---,E*,RS*,INT'	*LCDcontrolRB0 entrada. RB7 salida
		MOVLW	b'11110000'	;Filas y Columnas del teclado
		MOVWF	TRISC
		MOVLW	b'00000000'	;LCDbus
		MOVWF	TRISD
		BSF		PIE1,TMR1IE	;TMR1 overflow interrupt*
		movlw	b'10001110'
		movwf	ADCON1		;Puerta A analógica. Vref.=Vdd
		bcf		STATUS,RP0	;Selecciona banco 0

		CALL 	LCDReset
		CALL	CursorOff
		Call	LCDLine1

SELEC	MOVLW	B'00000010'		;REVISAR FILA 2
		MOVWF	PORTC
		BTFSC	PORTC,7
		GOTO	DIGIT
		GOTO	SELEC

MOD_DIG	ADDWF	PCL,1
		DT		"__DiGiTaL mOdE_*"

DIGIT	CLRF	INC12
		CLRF	Resultado_L
		CLRF	Resultado_H
		CLRF	COMP_L
		CLRF	COMP_H
		CLRF	Delay_L_A
		CLRF	Delay_H_A
		CALL	LCDLine1
DIGIT_1	MOVF	INC12,0
		CALL	MOD_DIG
		CALL	LCDWrite
		INCF	INC12,1
		MOVF	INC12,0
		XORLW	D'16'		;¿INC12 es 
		BTFSS	STATUS,Z	;			16?
		GOTO  	DIGIT_1		;NO:
		clrf	INC12		;SI: clear INC12 
		call	LCDLine2	;	 LCD en 2 linea y Revisa teclas
TECLAS	MOVLW	B'00000001'	;Revisa fila 1
		MOVWF	PORTC			
		BTFSC	PORTC,4
		GOTO	UNO
		BTFSC	PORTC,5
		GOTO	DOS
		BTFSC	PORTC,6
		GOTO	TRES
		MOVLW	B'00000010'	;Revisa fila 2
		MOVWF	PORTC
		BTFSC	PORTC,4
		GOTO	CUATRO
		BTFSC	PORTC,5
		GOTO	CINCO
		BTFSC	PORTC,6
		GOTO	SEIS
		MOVLW	B'00000100'	;Revisa fila 3
		MOVWF	PORTC
		BTFSC	PORTC,4
		GOTO	SIETE
		BTFSC	PORTC,5
		GOTO	OCHO
		BTFSC	PORTC,6
		GOTO	NUEVE
		MOVLW	B'00001000'	;Revisa fila 4
		MOVWF	PORTC
		BTFSC	PORTC,5
		GOTO	CERO
		GOTO	TECLAS

CERO	BTFSC 	PORTC,5
		GOTO 	CERO
		MOVLW	"0"
		CALL   	LCDWrite
		MOVLW	D'0'
		MOVWF	UNIDAD		;Dato pulsado
		GOTO	ES_UDCM

UNO		BTFSC	PORTC,4
		GOTO	UNO
		MOVLW	"1"
		CALL   	LCDWrite
		MOVLW	D'1'
		MOVWF	UNIDAD		;Dato pulsado
		GOTO	ES_UDCM
DOS		BTFSC	PORTC,5
		GOTO	DOS
		MOVLW	"2"
		CALL  	LCDWrite
		MOVLW	D'2'
		MOVWF	UNIDAD		;Dato pulsado
		GOTO	ES_UDCM
TRES 	BTFSC	PORTC,6
		GOTO	TRES
		MOVLW	"3"
		CALL   LCDWrite
		MOVLW	D'3'
		MOVWF	UNIDAD		;Dato pulsado
		GOTO	ES_UDCM
CUATRO	BTFSC	PORTC,4
		GOTO	CUATRO
		MOVLW	"4"
		CALL   LCDWrite
		MOVLW	D'4'
		MOVWF	UNIDAD		;Dato pulsado
		GOTO	ES_UDCM
CINCO	BTFSC	PORTC,5
		GOTO	CINCO
		MOVLW	"5"
		CALL   LCDWrite
		MOVLW	D'5'
		MOVWF	UNIDAD		;Dato pulsado
		GOTO	ES_UDCM
SEIS	BTFSC	PORTC,6
		GOTO	SEIS
		MOVLW	"6"
		CALL   LCDWrite
		MOVLW	D'6'
		MOVWF	UNIDAD		;Dato pulsado
		GOTO	ES_UDCM
SIETE	BTFSC	PORTC,4
		GOTO	SIETE
		MOVLW	"7"
		CALL   LCDWrite
		MOVLW	D'7'
		MOVWF	UNIDAD		;Dato pulsado
		GOTO	ES_UDCM
OCHO	BTFSC	PORTC,5
		GOTO	OCHO
		MOVLW	"8"
		CALL   LCDWrite
		MOVLW	D'8'
		MOVWF	UNIDAD		;Dato pulsado
		GOTO	ES_UDCM	
NUEVE	BTFSC	PORTC,6
		GOTO	NUEVE
		MOVLW	"9"
		CALL   LCDWrite
		MOVLW	D'9'
		MOVWF	UNIDAD		;Dato pulsado
ES_UDCM	INCF	INC12,1
		MOVF	INC12,0		;¿INC12 es 
		XORLW	D'1'		;			1
		BTFSC	STATUS,Z	;				?
		GOTO	DMILd		;SI:es Decena de mil
		MOVF	INC12,0		;NO:¿INC12 es
		XORLW	D'2'		;				2
		BTFSC	STATUS,Z	;					?
		GOTO	UMILd		;SI:es Unidad de mil
		MOVF	INC12,0		;NO:¿INC12 es
		XORLW	D'3'		;				3
		BTFSC	STATUS,Z	;				?
		GOTO	CEN			;SI:es Centena
		MOVF	INC12,0		;NO:¿INC12 es
		XORLW	D'4'		;				4
		BTFSC	STATUS,Z	;					?
		GOTO	DEC			;SI:es Decena
UNI		CLRF	INC12		;NO:es Unidad
		MOVF	UNIDAD,0	;Dato pulsado
		MOVWF	Dato_A_L
		CLRF	Dato_A_H
		CALL	SUMA

CALCULA	movf 	Resultado_L,0;SI: ¿Es
		XORWF	COMP_L,0	;		Resultado_L
		BTFSS	STATUS,Z	;			= COMP_L?
        GOTO	INCRd		;NO
		movf 	Resultado_H,0;SI	¿Es
		XORWF	COMP_H,0	;		Resultado_H
		BTFSS	STATUS,Z	;			= COMP_H?
        GOTO	INCRd		;NO

		BSF		T1CON,TMR1ON;SI: TMR1 en On
		movlw	b'11010000'	;Enable global,
		movwf	INTCON		;peripherial interrupt,RB0,

Loop	clrwdt
		goto	Loop

INCRd	INCF	Delay_L_A,1	;
		MOVF	Delay_L_A,0	;¿COMP_L
		XORLW	0x00		;		es 
		BTFSC	STATUS,Z	;			0?
		INCF	Delay_H_A,1	;SI:

		MOVLW	D'12'		;Carga menos peso del dato A
		addwf	COMP_L,W	;Suma menos peso del dato B
		movwf	COMP_L	;Almacena el resultado
		movLW	D'0'		;Carga más peso del dato A
		btfsc	STATUS,C	;Hubo acarreo anterior ??
		addlw	1		;Si, suma 1 al acumulador
		addwf	COMP_H,W	;Suma más peso del dato B
		movwf	COMP_H	;Guarda el resultado	
		GOTO    CALCULA

DEC		MOVF	UNIDAD,0	;Dato pulsado
		MOVWF	Multiplicando
		MOVLW	D'10'
		MOVWF	Multiplicador
		call	MULT

		MOVF	ResultadoM_L,0
		MOVWF	Dato_A_L
		MOVF	ResultadoM_H,0
		MOVWF	Dato_A_H
		CALL	SUMA

		GOTO	TECLAS

CEN		MOVF	UNIDAD,0	;Dato pulsado
		MOVWF	Multiplicando
		MOVLW	D'100'
		MOVWF	Multiplicador
		call	MULT

		MOVF	ResultadoM_L,0
		MOVWF	Dato_A_L
		MOVF	ResultadoM_H,0
		MOVWF	Dato_A_H
		CALL	SUMA

		GOTO	TECLAS

UMILd	MOVF	UNIDAD,0	;Dato pulsado
		MOVWF	Multiplicando
		MOVLW	D'250'
		MOVWF	Multiplicador
		call	MULT		;DATO*250
		
		bcf		STATUS,C
		rlf		ResultadoM_L,F
		rlf		ResultadoM_H,F
		rlf		ResultadoM_L,F
		rlf		ResultadoM_H,F;DATO*250*4=DATO*1000
		
		MOVF	ResultadoM_L,0
		MOVWF	Dato_A_L
		MOVF	ResultadoM_H,0
		MOVWF	Dato_A_H
		CALL	SUMA
		
		GOTO	TECLAS

DMILd	MOVF	UNIDAD,0	;Dato pulsado
		MOVWF	Multiplicando
		MOVLW	D'250'
		MOVWF	Multiplicador
		call	MULT		;ResuM1=DATO*250
							;ResuM*40=ResuM1+ResuM2ResuM3+...ResuM40
		clrf	cont40		;ResuM*40+ResultadoSuma=ResuM*40+0=ResuM
SUM40	incf	cont40
		movf	ResultadoM_L,w
		MOVWF	Dato_A_L
		movf	ResultadoM_H,w
		MOVWF	Dato_A_H
		CALL	SUMA
		MOVF	cont40,0	;¿cont40
		XORLW	d'40'		;		es 
		BTFSS	STATUS,Z	;			40?
		goto	SUM40		;NO:
		GOTO	TECLAS		;SI:

SUMA	;Resultado_L		Dato_A_L		Resultado_L
		;				=				+
		;Resultado_H		Dato_A_H		Resultado_H
		movf	Dato_A_L,W	;Carga menos peso del dato A
		addwf	Resultado_L,W;Suma menos peso del dato B
		movwf	Resultado_L	;Almacena el resultado
		movf	Dato_A_H,W	;Carga más peso del dato A
		btfsc	STATUS,C	;Hubo acarreo anterior ??
		addlw	1			;Si, suma 1 al acumulador
		addwf	Resultado_H,W;Suma más peso del dato B
		movwf	Resultado_H	;Guarda el resultado
		RETURN

MULT	;Resultado_L	
		;				=	Multiplicando	* Multiplicador
		;Resultado_H
		clrf	Resultado_H
		clrf	Resultado_L	;Pone a 0000 el resultado inicial
		movlw	0x08
		movwf	Contador	;Inicia el contador con 8		
		bcf		STATUS,C	;Borra el carry
Bucle	movf	Multiplicando,W;Carga el multiplicando
		btfsc	Multiplicador,0;Es 1 el bit de menos peso del multiplicador ??
		addwf	Resultado_H,F;Si, se suma el multiplicando
		rrf		Resultado_H,F
		rrf		Resultado_L,F;Desplazamiento a la derecha del resultado
		movf	STATUS,W	;Rota a la derecha el multiplicador sin que se modifique el flag Carry
		movwf	Estatus_Temp;Salva temporalmente el carry
		rrf		Multiplicador,F;Desplaza a la derecha el multiplicador		
		movf	Estatus_Temp,W
		movwf	STATUS		;Recupera el carry original
		decfsz	Contador,F	;Repite el bucle 8 veces
		goto	Bucle
		RETURN
		
	include	"LCDsoft.asm"
	END
