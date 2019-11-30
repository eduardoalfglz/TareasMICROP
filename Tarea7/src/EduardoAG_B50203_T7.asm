;#################################################################
;
;
;               Tarea 7
;               Eduardo Alfaro Gonzalez
;               B50203
;               IIC 
;               Ultima vez modificado 30/11/19
;
;
;#################################################################
#include registers.inc



;#################################################################
;               Definicion de estructuras de datos


CR:             equ $0D
LF:             equ $0A
FIN:            equ $0

                org $1000

CONT_RTI        ds 1
BANDERAS:       ds 1        ;bit 5 Alarma?, bit 4 rtc activado, bit 6 rs , bit 7 ESCRITURALECTURAIIC, bit 1: ya se puede leer
BRILLO:         ds 1        ; 0-100 cotrola el brillo de 7 seg
CONT_DIG:       ds 1        ;digito actual de 7seg
CONT_TICKS:     ds 1        ;
DT:             ds 1        ;100 - BRILLO, valor donde se resetea CONT_TICKS
BCD1:           ds 1        ;bin 1 en bcd
BCD2:           ds 1        ;bin 2 en bcd
DISP1:          ds 1        ;izquierda bcd1
DISP2:          ds 1        ;derecha bcd1
DISP3:          ds 1        ;izquierda bcd 2
DISP4:          ds 1        ;derecha bcd2   
LEDS:           ds 1        ;valor que se envia al puerto B para los leds
SEGMENT:        db $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F  ;0,1,2,3,4,5,6,7,8,9
CONT_7SEG:      ds 2        ;cuando llega a 5000 se actualizan los valores de DISP
CONT_DELAY:     ds 1        ;
D2mS:           db 100
D240uS:         db 13
D60uS:          db 3
Clear_LCD:      db $01      ;constante igual a comando clear
ADD_L1:         db $80      ;constante igual a Adress linea 1 lcd
ADD_L2:         db $C0      ;constante igual a Adress linea 2 lcd
iniDsp:         db 04,$28,$28,$06,$0C     ;numero de bytes,function set, function set, entry mode, display on off


Index_RTC:      ds 1            ;Posicion actual que se va a enviar o recibir
Dir_WR:         db $D0              ;Direccion de escritura del DS1307
Dir_RD:         db $D1              ;Direccion de lectura del DS1307
Dir_Seg:        db $00              ;direccion en la que se debe realizar la primera escritura y lectura del DS1307
ALARMA:         dw $0009
T_WRITE_RTC:    db $45,$59,$08,$02,$04,$12      ;Hexadecimal porque es bcd, El bit 6 de horas se deja abajo porque es en formato 24 H. Se ajusta a 15 s antes de que suene la alarma
                org $1040
T_Read_RTC:     ds 6


CONT_REB:       ds 1
CONT_TCL:       ds 1
PATRON:         ds 1



                org $1050
MESS1:          fcc "     RELOJ"
                db FIN
MESS2:          fcc " DESPERTADOR 623"
                db FIN





                
                
                org $3E70
                dw RTI_ISR
                org $3E4C
                dw PTH_ISR
                org $3E66
                dw OC4_ISR
                org $3E64
                dw OC5_ISR
                org $3E40
                dw IIC_ISR

;################################################
;       Programa principal
                org $2000

;################################################
;       Definicion de hardware

;       LEDS
                movb #$FF, DDRB
                bset DDRJ,$02
                bset PTJ, $02

;       7SEG
                movb #$0F, DDRP
                movb #$0F, PTP
;       Output compare
                movb #$90, TSCR1        ;Habilita las interrupciones con tffca
                movb #$03, TSCR2        ;Prescaler en 8 
                movb #$10, TIOS         ;Se habilita la salida de oc4
                movb #$05, TCTL1        ;Se ponen en toggle oc4 y oc5
                clr  TCTL2
                movb #$10, TIE          ;Solo se habilita la interrupcion de oc4
                ldd TCNT
                addd #60
                std TC4
                std TC5
                
                movb #$FF,DDRK

;       Puerto H sw

                bset PIEH, $0F          ;habilitar interrupciones PH
                bset PIFH, $0F
;       RTI                 
                movb #$65, RTICTL       ; esto lo pone en 25.152 ms no se puede en 1 s porque no se observan bien los leds de segundos en el reloj
                bset CRGINT, $80        ;habilitar interrupciones rti

;       IIC
                movb #$1F,IBFD          ;1f divider es igual a 240, da un tiempo 1.375 us mayor a 0.3 del periferico y menor que 3.45 maximo de iic
                movb #$C0,IBCR           ;IBEN = 1, IBIE=1, el resto cero porque aun no se inicia la comunicacion 
                cli



;################################################

;               inicializacion
                lds #$3BFF
                clr BCD1
                clr BCD2
                clr T_Read_RTC
                clr T_Read_RTC+1
                clr T_Read_RTC+2
                movb #02,LEDS
                clr DISP1
                clr DISP2
                clr DISP3
                clr DISP4
                ;modser=1
                movb #1,CONT_DIG
                clr CONT_TICKS
                movb #50, BRILLO
                
                clr  CONT_REB
                bclr BANDERAS,$1F      ;Poner las banderas en 0 FIXME
                ;bset BANDERAS,$00      ;Poner la bandera cambio nodo en 1 y modo en 1
                


;       Programa main               
                loc
                ldx #MESS1
                ldy #MESS2
                jsr CARGAR_LCD
mLoop`          ldd ALARMA
                cmpa T_Read_RTC+1       ;Se compara los minutos de alarma con los de memoria
                bne mLoop`
                cmpb T_Read_RTC+2       ;Se compara las horas de alarma con las de memoria
                bne mLoop`
                brset BANDERAS,$10,mLoop`       ;FIXME:Agregar esto a diagrama de flujos
                bset BANDERAS,$10
                movb #$30, TIOS
                movb #$30, TIE
                bra mLoop`

                
                
;################################################
;       Subrutinas
;################################################
;       Subrutinas Generales


;       BCD_7SEG
BCD_7SEG:       loc
                movb T_Read_RTC+1,BCD1
                movb T_Read_RTC+2,BCD2
                ldx #SEGMENT
                ldy #DISP1
                ldaa #0
                ldab BCD1
                bra subrutinabcd`
loadBCD2`       ldab BCD2
subrutinabcd`   pshb 
                andb #$0F
                movb B,X,1,Y+      ;muevo la parte baja de bcd a disp2 o disp 4
                pulb 
                lsrb
                lsrb
                lsrb
                lsrb
                movb B,X,1,Y+     ;muevo la parte alta de bcd a disp 1 o disp4
                cpy #DISP3
                beq loadBCD2`
returnBCD_7SEG: brclr T_Read_RTC,$01,erasedots`
                bset DISP2,$80
                bset DISP3,$80
                bra return`
erasedots`      bclr DISP2,$80
                bclr DISP3,$80          
return`         rts


;       CARGAR_LCD
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################
CARGAR_LCD:     loc
                pshx
                ldx #iniDsp
                ldab 1,X+
loop1`          ldaa 1,X+
                bclr BANDERAS,$20
                jsr Send
                movb D60uS,CONT_DELAY
                jsr Delay
                dbne B,loop1`           ;hasta aqui se estan mandando los comando iniciales de dsp
                bclr BANDERAS,$20
                ldaa Clear_LCD
                jsr Send                ;hasta aqui se borra la pantalla
                movb D2mS,CONT_DELAY
                jsr Delay
                pulx
                ldaa ADD_L1                        ;aqui empieza cargar lcd
                bclr BANDERAS,$20
                jsr Send
                movb D60uS,CONT_DELAY
                jsr Delay
loop2`          ldaa 1,X+
                cmpa #FIN
                beq linea2`
                bset BANDERAS,$20
                jsr Send
                movb D60uS,CONT_DELAY
                jsr Delay
                bra loop2`
linea2`         ldaa ADD_L2                        ;aqui empieza cargar la linea 2
                bclr BANDERAS,$20
                jsr Send
                movb D60uS,CONT_DELAY
                jsr Delay
loop3`          ldaa 1,Y+
                cmpa #FIN
                beq returnLCD`
                bset BANDERAS,$20
                jsr Send
                movb D60uS,CONT_DELAY
                jsr Delay
                bra loop3`
returnLCD`      rts


;       Send
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################
                loc
Send:           psha
                anda #$F0
                lsra
                lsra
                staa PORTK
                brset BANDERAS,$20,dato1`
                bclr PORTK,$01
                bra continue1`
dato1`           bset PORTK,$01
continue1`      bset PORTK,$02
                movb D240uS,CONT_DELAY
                jsr Delay
                bclr PORTK,$02
                pula
                anda #$0F
                lsla
                lsla
                staa PORTK
                brset BANDERAS,$20,dato2`
                bclr PORTK,$01
                bra continue2`
dato2`          bset PORTK,$01
continue2`      bset PORTK,$02
                movb D240uS,CONT_DELAY
                jsr Delay
                bclr PORTK,$02
                rts    

;       Delay
                loc
Delay:          tst CONT_DELAY 
                bne Delay
                rts




;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;   Subrutina READ_RTC
;################################################################################################################################################
;Descripcion:   
        ;Lectura de ds1307


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################                

                loc
READ_RTC:       ldaa Index_RTC
                bne next0`          ;Primera?
                movb Dir_Seg,IBDR       ;Se envia la direccion a leer (Segundos)
                bra return_rrtc
next0`          cmpa #1             ;Segunda?
                bne next1`
                bset IBCR,$04       ;Repeate start
                movb Dir_RD,IBDR
                bra return_rrtc
next1`          cmpa #2             ;Tercera?
                bne next2`
                bclr IBCR,$1C       ;Borra repeated start y pasa a modo rx y pone en 0 el ack por seguridad
                ldab IBDR           ;Lectura dummy
                bra return_rrtc
next2`          cmpa #9             ;Ultimo lista?
                bne next3`
                bclr IBCR,$28       ;borra el no ack (8) y manda señal de stop (2)
                bset IBCR,$10       ;pasa a modo tx      
                bra return_rrtc
next3`          cmpa #8             ;Penultima?     FIXME: esto significa que no se lee el ultimo dato?
                bne next4`
                bset IBCR,$08       ;Pone un no ack       
next4`          deca
                deca
                deca                ;A -3 porque se consideran las primeras 3 interrupciones en el index
                ldx #T_Read_RTC
                movb IBDR,A,X       ;Se mueve el dato a la posicion deseada

return_rrtc     inc Index_RTC           
                rts




;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;   Subrutina WRITE_RTC
;################################################################################################################################################
;Descripcion:   
        ;Escritura de ds1307


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################                

                loc
WRITE_RTC:      brset IBSR,$02,error_wrtc       ;No se recibe el ack
                ldaa Index_RTC
                bne next`
                movb Dir_Seg,IBDR       ;Mandar la direccion de la primera palabra es decir segundos                
                bra return_wrtc
next`           cmpa #7
                beq finishwrite`
                deca                    ;offset de -1 porque se toma en cuenta el envio de la direccion
                ldx #T_WRITE_RTC
                movb A,X,IBDR           ;Mandar el dato correspondiente segun el index 
                cmpa #6                 ;Es el ultimo dato?
                bne return_wrtc         ;Cuano es el ultimo se envia señal de stop
                bclr IBCR,$20                        
                
                bra return_wrtc
                
                
finishwrite`    bset BANDERAS,$01
return_wrtc:    inc Index_RTC
                rts 
error_wrtc:     movb #$FF,LEDS                  ;Enciende todos los leds como alarma
                bra return_wrtc



;################################################
;################################################
;################################################
;       Subrutinas de atencion de interrupciones

;       Subrutinas PH
;        subrutina de PHO
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################

                loc
PTH_ISR:        brset PIFH,$01,PH0_ISR 
                brset PIFH,$02,PH1_ISR
                brset PIFH,$04,PH2_ISR
                brset PIFH,$08,PH3_ISR

;       subrutina PH1
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################
PH0_ISR:        bset PIFH, $01  
                
                tst CONT_REB
                bne returnPH                 
                movb #2,CONT_REB
                ;INICIO de comunicaciones en escritura
                bclr BANDERAS,$80 ;MODOEscritura         
                bclr BANDERAS,$10       ;Reset de alarma
                movb #$F0,IBCR                 ;IBEN 1, IBIE 1 MS 1(START), TX 1 txak 0(Para calling address no importa),RSTA 0                
                movb Dir_WR,IBDR               ;Se envia direccion de escritura                         
                   
                          
                clr Index_RTC             ;Index en 0
                bra returnPH

;       subrutina PH1
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################
PH1_ISR:        bset PIFH, $02 
                tst CONT_REB
                bne returnPH                
                movb #2,CONT_REB                         
                movb #$10, TIOS
                movb #$10, TIE      ;Se deshabilitan las interrupciones de OC5
returnPH:       rti
;       subrutina PH2
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################                
PH2_ISR:        bset PIFH, $04
                ldaa BRILLO
                beq returnPH
                suba #5
                staa BRILLO
                bra returnPH
;       subrutina PH3
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################
PH3_ISR:        bset PIFH, $08
                ldaa BRILLO
                cmpa #100
                beq returnPH
                adda #5
                staa BRILLO
                bra returnPH                



;       subrutina de rti
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################
                loc
RTI_ISR:        bset CRGFLG, $80
                tst CONT_REB
                beq checkREAD
                dec CONT_REB
checkREAD:      tst CONT_RTI        ;Se verifica que el contador llegue a 0 es decir 1 s
                beq initREAD
                dec CONT_RTI
                bra return`
initREAD:       movb #20,CONT_RTI   ;Reset contador
                brclr BANDERAS,$01,return`                
                ;INICIO de comunicaciones en LECTURA
                bset BANDERAS,$80 ; MODOLectura         
                movb Dir_WR,IBDR                ;Mando la direccion de escritura para resetear el puntero de memoria DS1307
                ;movb #$F0,IBCR                 ;IBEN 1, IBIE 1 MS 1(START), TX 1 txak 0(Para calling address no importa),RSTA 0
                bset IBCR,$30
                clr Index_RTC             ;Index en 0

return`         rti


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;   Subrutina OC4
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################
                loc
OC4_ISR:        ldaa CONT_TICKS
                ldab #100
                subb BRILLO
                cba
                bge apagar`
                tst CONT_TICKS
                beq check_digit`
checkN`         cmpa #100
                beq changeDigit`
incticks`       inc CONT_TICKS
                jmp part2`
;Apagar
apagar`         movb #$FF,PTP
                movb #$0, PORTB
                bra checkN`
;           cambiar digito
changeDigit`    movb #$0, CONT_TICKS
                inc CONT_DIG
                ldaa #6
                cmpa CONT_DIG
                bne jpart2`                 ;no me alcanzo para hacer el primer salto 
                movb #1,CONT_DIG
jpart2`         bra part2`
;           encender digito
check_digit`    ldaa CONT_DIG
                cmpa #1
                bne dig2`
                bclr PTP, $08
                movb DISP1, PORTB
                bset PTJ, $02
                bra  incticks`
dig2`           cmpa #2
                bne dig3`
                bclr PTP, $04
                ldaa DISP2
                movb DISP2, PORTB
                bset PTJ, $02
ndig2`          bra  incticks`
dig3`           cmpa #3
                bne dig4`
                bclr PTP, $02                
                movb DISP3, PORTB
                bset PTJ, $02
ndig3`          bra  incticks`
dig4`           cmpa #4
                bne digleds`
                bclr PTP, $01
                ldaa DISP4
                movb DISP4, PORTB
                bset PTJ, $02
ndig4`          jmp  incticks`
digleds`        movb LEDS, PORTB
                bclr PTJ, $02
                inc CONT_TICKS


part2`          tst CONT_DELAY
                beq tst7seg`
                dec CONT_DELAY
tst7seg`        ldx CONT_7SEG
                beq JBCD_7SEG`
                dex
                stx CONT_7SEG
returnOC4       ldd TCNT
                addd #60
                std TC4
                ;bset TFLG1,$10          ;Se borra la bandera manualmente ERROR
                rti
JBCD_7SEG`      movw #500,CONT_7SEG
                jsr BCD_7SEG
                bra returnOC4



;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;   Subrutina OC5
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################                
                loc
OC5_ISR:        ldd TCNT
                addd #75
                std TC5                
                rti



;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;   Subrutina IIC
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################                

                loc
IIC_ISR:        bset IBSR,$20
                brset BANDERAS,$80,jLectura
                jsr WRITE_RTC     
                bra return_IIC
jLectura:       jsr READ_RTC
return_IIC:     rti





