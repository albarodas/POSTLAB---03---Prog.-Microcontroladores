; Archivo:     lab03.S
; Dispositivo: PIC166F887
; Autor:       Alba Rodas
; Compilador:  pic-as (v2.30), MPLABX V5.40
; 
; Programa:    Contador binario de 4bits, cada 100ms + contador de 1s + reinicio cuando DISPLAY y contador 1s sean iguales
; Hardware:    PIC, LEDs.
;
; Creado: 06 feb, 2022
; Última modificación: 11 feb, 2022
    
 PROCESSOR 16F887
 #include <xc.inc>
 
;configuration word 1
  CONFIG FOSC=INTRC_NOCLKOUT //oscilador CRISTAL
  CONFIG WDTE=OFF // WDT disables  (reinicia repetitivamente el PIC)
  CONFIG PWRTE=ON // PWRT enabled (se espera 72ms al empezar el funcionamiento)
  CONFIG MCLRE=OFF // El pin MCLR de utiliza como INPUT/OUTPUT
  CONFIG CP=OFF // Sin proteccion de codigo
  CONFIG CPD=OFF // Sin protección de datos
  CONFIG BOREN=OFF //Se desabilita/OFF para que cuando exista una baja de voltaje <4V, no haya reinicio
  CONFIG IESO=OFF // Se establece un reinicio sin cambiar del reloj interno al externo
  CONFIG FCMEN=OFF // Si existiera un fallo, se configura el cambio de reloj de externo a interno
  CONFIG LVP=ON // Se permite el desarrollo de la programacion, incluso en bajo voltaje
  
 ;configuration word 2
  CONFIG WRT=OFF // Se programa como desactivada la protección de autoescritura 
  CONFIG BOR4V=BOR40V // Se programa reinicio cuando el voltaje sea menor a 4V
 
 PSECT udata_bank0 ; common memory
    counter: DS  2	; 2 byte
    display_variable: DS    1  ; 1 byte
    restamos:	    DS	1	; 1 byte
 PSECT resVect, class=CODE, abs, delta=2

   ;-------------vector reset----------------
 ORG 00h	; posicion 0000h para reset
 resetVec:
    PAGESEL main
    goto main
    
//CONFIGURACION DEL MICROCONTROLADOR
 PSECT code, delta=2, abs
 ORG 100h	; posicion para el codigo
//PARA PODER LLAMAR A MIS VALORES EN BINARIO - PARA  7 SEGMENTOS 
  values:
    clrf    PCLATH
    bsf	    PCLATH, 0	; PCLATH = LO HAGO = 01	; PCL = LO HAGO = 02
    andlw   0x0f
    addwf   PCL		; PC = PCLATH + PCL + w
    retlw   00111111B	; VALOR = 0
    retlw   00000110B	; VALOR = 1
    retlw   01011011B	; VALOR = 2
    retlw   01001111B	; VALOR = 3
    retlw   01100110B	; VALOR = 4
    retlw   01101101B	; VALOR = 5
    retlw   01111101B	; VALOR = 6
    retlw   00000111B	; VALOR = 7
    retlw   01111111B	; VALOR = 8
    retlw   01101111B	; VALOR = 9
    retlw   01110111B	; VALOR = A
    retlw   01111100B	; VALOR = B
    retlw   00111001B	; VALOR = C
    retlw   01011110B	; VALOR = D
    retlw   01111001B	; VALOR = E
    retlw   01110001B	; VALOR = F
   
    return
 ;-------------configuracion------------------
 main:
    call    config_ins_outs
    call    config_reloj
    call    config_tmr0
    
 ;-------------loop principal-----------------
 loop:

    call    contador_1s	
    btfsc   PORTB, 0
    call    incrementar_display		; AUMENTAR EL PORTB --> BOTON 1
    btfsc   PORTB, 1
    call    decrementar_display		; DECREMENTAR PORTB --> BOTON 2
    call    mostrar_display		; MUESTRO EL DISPLAY SEGUN EL ESTADO DE INC/DEC
    call    compare
    goto    loop

 ;-------------sub-rutinas--------------------
 
 ;---------------------------configuraciones---------------------------------
 config_ins_outs:
    banksel ANSEL	;Nos movemos al banco 03
    clrf    ANSEL	;Se definen I/O
    clrf    ANSELH	;LAS COLOCAMOS EN 0, PARA QUE SEAN SALIDAS DIGITALES
    
    //SALIDA DIGITAL - BANCO A
    banksel TRISA
    clrf    TRISA	; PORTA COMO SALIDA //LIMPIO PARA EVITAR ERRORES
    clrf    TRISC	; PORTC COMO SALIDA //LIMPIO PARA EVITAR ERRORES
    clrf    TRISD	; PORTD COMO SALIDA //LIMPIO PARA EVITAR ERRORES
    clrf    TRISE	; PORTE COMO SALIDA //LIMPIO PARA EVITAR ERRORES

    //SALIDA DIGITAL - BANCO B
    bsf	    TRISB, 0	;bsf = bit set f + pin = PS
    bsf	    TRISB, 1	; DEFINO PORTB (0 y 1) COMO ENTRADAS DIGITALES.
    
    //LIMPIEZA DE PUERTOS - PARA EVITAR ERRORES
    banksel PORTA
    clrf    PORTA	; LIMPIO PUERTO A
    clrf    PORTC	; LIMPIO PUERTO C 
    clrf    PORTB	; LIMPIO PUERTO B
    clrf    PORTD	; LIMPIO PUERTO D
    clrf    PORTE	; LIMPIO PUERTO E

   
    return
;-------------------configuracion----------------------------
  config_reloj:
    banksel OSCCON  //CONFIGURO FRECUENCIA DE OSCILADOR 1MHz
    bsf OSCCON, 0   ;Activo reloj interno, encendido.
    bcf OSCCON, 4   ;BIT 4, EN 0 --> BIT MENOS SIGNIFICATIVO.
    bcf OSCCON, 5   ;BIT 5, EN 0
    bsf OSCCON, 6   ;BIT 6, EN 1
    return
   //USO PINES 4, 5, 6 ya que me permiten configurar la frecuencia de oscilación
   //UTILIZO RELOJ INTERNO CON UNA FRECUENCIA DE 1MHz (100).
 
  config_tmr0:
 //CONFIGURO PRESCALER.
 ; Segun cálculos realizados, es encesario cargar un valor de PRESC => 158,
 ; para poder obtener un delay/salto de 100ms.
 // En base al PRESCALER obtenido, utilizando uno de 1:256 bits (111)
     // En base al PRESCALER obtenido, utilizando uno de 1:256bits
    banksel TRISA
    bcf	    OPTION_REG, 5   ; T0CS = TMR0 Clock Source Select Bit = reloj interno, bcf para encenderlo, uso el BIT 5.
    bcf	    OPTION_REG, 3   ; PSA = Prescaler Assignment Bit = necesito asignar un valor al modulo, utilizo el BIT 3 en cero.
    bsf	    OPTION_REG, 2   ; BIT MENOS SIGNIFICATIVO
    bsf	    OPTION_REG, 1   
    bsf	    OPTION_REG, 0   ; prescaler 111, (x256) 
    
;------------------MODO ALTERNATIVO DE CONFIGURAR TMR0------------------    
 // PRESCALER SELECT BIT = PS + N --> N = numero de bit a seleccionar 0 al 2
    //banksel OPTION_REG  ; --> REGISTRO DE BITS A MODIFICAR --> UTILIZO EL MACRO "OPTION_REG"
    //bcf	    PS2	    ; 111 --> BIT MENOS SIGNIFICATIVO
    //bsf	    PS1
    //bsf	    PS0	    ;Selecciono reloj a utilizar, PRESCALER 1:256 
    //bcf     T0CS    ; bcf = seteo a cero, activo el reloj interno, RELOJ INTERNO nos da los pulsos.   
    //banksel TMR0    ; Para asegurarnos que nuestro BANKSEL esté en el banco que buscamos, usamos "BANKSEL"
    //movlw   158	    ; 100ms
    //movwf   TMR0    ; Cargamos el valor inicial al "timer0"
    //bcf	    T0IF    ; Limpio bandera de interrumpcion del timer0, EVALUO SI EL TIEMPO SE CUMPLIÓ O NO.
    //return
    // bsf = bit set f + pin = PS --> Internamente, el PIC toma el OPTION REGISTER, pin 0 - 2.
    
    banksel PORTA
    call    reset_tmr0
    return
 
 reset_tmr0:
    movlw   158		; LE DOY VALOR INICIAL PARA SALTOS DE 0.1s
    movwf   TMR0	; ALMACENO VALORES EN TMR0
    bcf	    INTCON, 2	; LIMPIO BANDERAS PARA TMR0
    return
 
 ;---------------------------contador--------------------------------------
 contador_100ms:
    btfss   T0IF	    ; Elijo saltarme la bandera (overflow), si esta está activada FFh --> 00h.
    goto    $-1		    
    call    reset_tmr0	    ; Una vez alcanzado 4 bits, reinicio tmr0
    incf    PORTA	    ; Si no se han alcanzado 4bits, sigo aumentando el PORTA.
    
    btfsc   PORTA, 4	    ; REVISO EL 4TO BIT DEL PORTA.
    clrf    PORTA	    ; Si mi PORT A, supera los 4bits, lo "limpio" = clear.
    return
   
 contador_1s:
    movlw   10		    ; LE DOY LA INDICACION DE REPETIR 10 VECES
    movwf   counter	    ; ASIGNO EL "10" A LA VARIABLE DE "COUNTER"
    call    contador_100ms  ; LLAMO A LA SUBRUTINA DEL COUNTER DE 100ms
    decfsz  counter, 1	    ; LE DOY LA ORDEN DE REDUCIR/DECREMENTAR MI "COUNTER", si no es 0.
    goto    $-2
    incf    PORTD	    ; LE DIGO QUE INCREMENTE EL PORTD, cada 10s.
    
    btfsc   PORTD, 4	    ; BIT TEST PARA EL CUARTO BIT DEL PUERTO D
    clrf    PORTD	    ; SI EN MI PORTD, SE PASA DE 4 BITS, LE DOY "LIMPIAR"

    return

 ;-------------------configuracion display(7segmentos)---------------
 
 incrementar_display:
    ; ANTIRREBOTE ACTIVADO
    btfsc   PORTB, 0	    ; SE INCREMENTA EN BASE AL ANTIRREBOTE --> Mientras presionado RB0 (antirrebote), aumente el PUERTO C.
    goto    $-1		    ; ACCION SE REALIZA HASTA SOLTAR EL BOTON
    incf    display_variable	    
    btfsc   display_variable, 4  ; HAGO BIT TEST LE PIDO REVISAR EL BIT 4, DE: display_variable
    clrf    display_variable	    ; LIMPIAR EL DISPLAY SI SE PASA DE 
    return
    
  decrementar_display:
    ; ACTIVO EL ANTIRREBOTE
    btfsc   PORTB, 1	    ; SE INCREMENTA EN BASE AL ANTIRREBOTE -->
    goto    $-1		    ; ACCION SE REALIZA HASTA SOLTAR BOTON
    decf    display_variable
    
    btfsc   display_variable, 4  ; LE PIDO REVISAR EL BIT 4, DE LA VARIALBE: display_variable
    call    encender_display    ; ENCIENDO EL DISPLAY, SI SE PASA DE 4BITS
    
    return
 
 encender_display:
    clrf    display_variable	    ; QUIERO INICIAR DESDE CERO, ENTONCES "CLR"
    bsf	    display_variable, 0	    ; bsf = bit set f + pin = PS --> Internamente, el PIC toma el OPTION REGISTER, pin 0 - 2.
    bsf	    display_variable, 1
    bsf	    display_variable, 2
    bsf	    display_variable, 3  ; LE ORDENO ENCENDER LOS PRIMEROS 4 BITS
    return
    
 mostrar_display:
    movf    display_variable, w  ; MUEVO LA VARIABLE A DEL DISPLAY A "W" --> ESPACIO IMAGINARIO --> NO ES UN ESTADO FISICO 
    call    values	    ; MANDO A LLAMAR A LOS VALORES EN "VALUES" --> TABLA
    movwf   PORTC	    ; LO MUESTRO TODO, EN EL PUERTO C --> 
    return		    ; DESPUES DE LLAMARLO DE "W" --> ESPACIO IMAGINARIO.
    
  ;-----------------------------LED QUE DEBE ENCENDERSE--------------------------------------
 restar_counters:
    movf    display_variable, w  ; Para poder hacer funcionar EL LED DE ALERTA, muevo lo del display a "W"
    subwf   PORTD, w	    ; timer_1s - valor actual del display = uso palabra reservada "subwf"
    movwf   restamos	    ; Guardo el resultado de la resta anterior en mi variable definida como "restamos".
    return
 
 actualizar_LED:
    incf    PORTE	; En esta funcion, cambio/actualizo mi LED de alerta en el PORTE, porque allí lo 
    clrf    PORTD	; LE DOY "clrf" PARA EVITAR ERRORES Y LIMPIAR MI PUERTO D.
    return
    
 compare:
    call    restar_counters    ; COMO SE DETALLÓ, GUARDO EN MI VARIABLE "RESTA", A LA DIFERENCIA DE LOS CONTADORES.
    
    btfsc   restamos, 0
    goto    $+16	; AL HACER LA RESTA, SI EL RESULTADO NO ES CERO, ENVÍO A LA SUBRUTINA A "RETURN"
    btfsc   restamos, 1
    goto    $+14	; AL HACER LA RESTA, SI EL RESULTADO NO ES CERO, ENVÍO A LA SUBRUTINA A "RETURN"
    btfsc   restamos, 2
    goto    $+12	; AL HACER LA RESTA, SI EL RESULTADO NO ES CERO, ENVÍO A LA SUBRUTINA A "RETURN"
    btfsc   restamos, 3
    goto    $+10	; AL HACER LA RESTA, SI EL RESULTADO NO ES CERO, ENVÍO A LA SUBRUTINA A "RETURN"
    btfsc   restamos, 4
    goto    $+8		; AL HACER LA RESTA, SI EL RESULTADO NO ES CERO, ENVÍO A LA SUBRUTINA A "RETURN"
    btfsc   restamos, 5
    goto    $+6		; AL HACER LA RESTA, SI EL RESULTADO NO ES CERO, ENVÍO A LA SUBRUTINA A "RETURN"
    btfsc   restamos, 6
    goto    $+4		; AL HACER LA RESTA, SI EL RESULTADO NO ES CERO, ENVÍO A LA SUBRUTINA A "RETURN"
    btfsc   restamos, 7
    goto    $+2		; AL HACER LA RESTA, SI EL RESULTADO NO ES CERO, ENVÍO A LA SUBRUTINA A "RETURN"
    
    call    actualizar_LED	; ACTUALIZO EL VALOR DE MI LED, SI LA RESTA OBTENIDA = 0, de lo contrario "return"
    return
 
 END