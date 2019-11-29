;###################################################################################################################################################################################################
;
;
;               Trabajo Final
;               Eduardo Alfaro Gonzalez
;               B50203
;               Radar 623
;               Ultima vez modificado 23/11/19
;
;
;###################################################################################################################################################################################################
#include registers.inc



;################################################################################################################################################################################################
;################################################################################################################################################################################################
;################################################################################################################################################################################################
;################################################################################################################################################################################################
;               Definicion de estructuras de datos



CR:             equ $0D
LF:             equ $0A
FIN:            equ $0

                org $1000
BANDERAS2:      ds 1    ;7: MOD_H      6:MOD_L  3:Enable tick_vel  2:PRINT Calculando... 1:Data or Control LCD    0:Cambio_Modo
BANDERAS1:      ds 1    ;0: TCL_Lista   1:TCL_Leida     2:ARRAY_OK  3:PANT_FLAG     4:ALERTA        5:CALC_TICK
V_LIM:          ds 1    ;Velocidad limite
MAX_TCL:        db 2
TECLA:          ds 1
TECLA_IN:       ds 1

CONT_REB:       ds 1
CONT_TCL:       ds 1
PATRON:         ds 1
        

NUM_ARRAY:      ds 2
BRILLO:         ds 1        ; 0-100 cotrola el brillo de 7 seg
POT:            ds 1        ;Variable que almacena el valor promedio del ATD
TICK_EN:        ds 2        ;Cantidad de ticks necesarios para cubrir 100m
TICK_DIS:       ds 2        ;Cantidad de ticks necesarios para cubrir 200m
VELOC:          ds 1        ;VELOCIDAD MEDIDA POR LOS SENSORES
TICK_VEL:       ds 1        ;Ticks utilizados para sensar la velocidad del vehiculo    


BIN1:           ds 1        ;corresponde al valor de DISP1 y DISP2 en binario
BIN2:           ds 1        ;corresponde al valor de DISP4 y DISP3 en binario

BCD1:           ds 1        ;bin 1 en bcd
BCD2:           ds 1        ;bin 2 en bcd
BCD_L:          ds 1
LOW:            ds 1        ;ni idea


DISP1:          ds 1        ;izquierda bcd1
DISP2:          ds 1        ;derecha bcd1
DISP3:          ds 1        ;izquierda bcd 2
DISP4:          ds 1        ;derecha bcd2  

LEDS:           ds 1        ;valor que se envia al puerto B para los leds

CONT_DIG:       ds 1        ;digito actual de 7seg
CONT_TICKS:     ds 1        ;

DT:             ds 1        ;100 - BRILLO, valor donde se resetea CONT_TICKS


CONT_7SEG:      ds 2        ;cuando llega a 5000 se actualizan los valores de DISP
CONT_200        ds 2        ;contador para 200 ms para habilitar el atd, se cambia a word por el tamaño de lo que almacena
CONT_DELAY:     ds 1        ;
D2mS:           db 100
D240uS:         db 13
D60uS:          db 3

Clear_LCD:      db $01      ;constante igual a comando clear
ADD_L1:         db $80      ;constante igual a Adress linea 1 lcd
ADD_L2:         db $C0      ;constante igual a Adress linea 2 lcd
TEMP:           ds 1
LEDS37:         ds 1        ;Variable que define el desplazamiento de los leds 3:7 en modo alerta
Variable2:      ds 1
Variable3:      ds 1




                org $1030
TECLAS:         db $01,$02,$03,$04,$05,$06,$07,$08,$09,$0B,$00,$0E



 
                org $1040
SEGMENT:        db $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F,$40,$BB  ;0,1,2,3,4,5,6,7,8,9,-,Apagar
                
                
                
                org $1050


iniDsp:         db 04,$28,$28,$06,$0C     ;numero de bytes,function set, function set, entry mode, display on off

                org $1060
MESS1:          fcc "  MODO CONFIG"
                db FIN
MESS2:          fcc " VELOC. LIMITE"
                db FIN
MESS3:          fcc "  RADAR   623"
                db FIN
MESS4:          fcc "   MODO LIBRE"
                db FIN
MESS5:          fcc " MODO MEDICION"
                db FIN
MESS6:          fcc "SU VEL. VEL.LIM"
                db FIN
MESS7:          fcc "  ESPERANDO..."
                db FIN            
MESS8:          fcc "  CALCULANDO..."
                db FIN                





                
                
                org $3E70
                dw RTI_ISR
                org $3E4C
                dw PTH_ISR
                org $3E66
                dw OC4_ISR
                org $3E52
                dw ATD_ISR
                org $3E5E
                dw TCNT_ISR

;################################################
;       Programa principal
                org $2000


;################################################################################################################################################################################################
;################################################################################################################################################################################################
;################################################################################################################################################################################################
;################################################################################################################################################################################################
;       Definicion de hardware

;       LEDS
                movb #$FF, DDRB
                bset DDRJ,$02
                bset PTJ, $02

;       7SEG
                movb #$0F, DDRP
                movb #$0F, PTP
;       Output compare
                movb #$80, TSCR1
                movb #$03, TSCR2
                movb #$10, TIOS
                movb #$01, TCTL1
                movb #$00, TCTL2
                movb #$10, TIE
                ldd TCNT
                addd #60
                std TC4
                
                movb #$FF,DDRK          ;Utilizado en pantala LCD


;       ATD0
                movb #$C2, ATD0CTL2
                ldab #200
loopIATD:       dbne B,loopIATD         ;loop de retardo para encender el convertidor
                movb #$30, ATD0CTL3     ;6 mediciones
                movb #$B7, ATD0CTL4     ;8 bits, 4 ciclos de atd, PRS $17
                movb #$87, ATD0CTL5     
;       Puerto H sw

;               bset PIEH, $0C          ;habilitar interrupciones PH
                bset PIFH, $0F
;       RTI                 
                movb #$17, RTICTL       ; esto lo pone en 1.024 ms
                bset CRGINT, $80        ;habilitar interrupciones rti
;       Puerto A teclado                
                movb #$F0, DDRA
                bset PUCR, $01          ;Super importante habilitar resistencia de pullup
;                bclr RDRIV, $01

                cli



;################################################################################################################################################################################################
;################################################################################################################################################################################################
;################################################################################################################################################################################################
;################################################################################################################################################################################################

;               inicializacion
                lds #$3BFF
                movb #$00,BCD1
                movb #$00,BCD2
                movb #$00,BIN2
                movb #$00,BIN1
                movb #02,LEDS
                clr DISP1
                clr DISP2
                clr DISP3
                clr DISP4
                clr VELOC
                ;modser=1
                movb #1,CONT_DIG
                clr CONT_TICKS
                movb #50, BRILLO
                movb #00, V_LIM
                

                movb #$FF, TECLA
                movb #$FF, TECLA_IN
                movb #$00, CONT_TCL
                movb #$00, CONT_REB
                bclr BANDERAS1,$FF      ;Poner las banderas de teclados en 0 
                bset BANDERAS2,$01      ;Poner la bandera cambio nodo en 1 y el resto no importan
                bclr BANDERAS2,$C4      ;modo en 00 es decir MODO config, se borra la bandera print Calculando                
                ldaa MAX_TCL
                ldx #NUM_ARRAY-1
LoopCLR:        movb #$FF,A,X          ;iniciar el arreglo en FF
                dbne A,LoopCLR


;       Programa main   
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################
mainL:          loc
                tst V_LIM               ;La velocidad debe ser distanta de cero para salir de modo configs
                beq chkModoLC           ;Salta a revisar si es modo config o libre
                ldaa PTIH               ;se cargan los valores de los dipswitch
                anda #$C0               ;Se utilizan solo los bits de modo
                ldab BANDERAS2          ;Bits de banderas que corresponden a modos
                andb #$C0               ;Bits de modo
                cba
                beq nochange`
                cmpa #$40               ;se revisa que el modo no sea el valor invalido
                beq nochange`                
                bset BANDERAS2,$01      ;Se activa cambio de modo
                cmpa #$80               ;Revisar si es modo libre
                beq swML`
                cmpa #$C0
                beq swMM`
                bclr BANDERAS2,$C0      ;Si los switches estan en modo config se configura en el registro MOD
                bra nochange`
swML`           bset BANDERAS2,$80      ;Si los switches estan en modo libre se configura en el registro MOD
                bclr BANDERAS2,$40
                bra nochange`
swMM`           bset BANDERAS2,$C0      ;Si los switches estan en modo medicion se configura en el registro MOD

nochange`       brset BANDERAS2,$C0,chkModoM`

                
                
chkModoLC:      clr VELOC
                bclr PIEH,$09                       ;Se deshabilitan las interrupciones del puerto H, TOI y se pone veloc en 0
                bset PIFH,$09
                movb #$03,TSCR2
                bclr BANDERAS1,$18                  ;Se borra la bandera de alerta y la bandera de PANT_FLAG
                brclr BANDERAS2,$C0,chkModoC`       ;Salta a revisar el modo Config


chkModoL`       brclr BANDERAS2,$01,jmodolibre`           ;Tecnicamente aqui deberia saltar a modo libre, pero no hace nada
                bclr BANDERAS2,$01                  
                movb #$04,LEDS                                
                ldx #MESS3
                ldy #MESS4
                jsr CARGAR_LCD                
jmodolibre`     jsr MODO_LIBRE
                bra mainL

chkModoC`       brclr BANDERAS2,$01,jmodoconfig`
                bclr BANDERAS2,$01                                  
                movb V_LIM,BIN1             ;Si esta en modo config se revisa si hay cambio de modo para imprimir en la LCD
                movb #$BB,BIN2               
                ldx #MESS1
                ldy #MESS2
                movb #$01,LEDS
                jsr CARGAR_LCD
                

jmodoconfig`    jsr MODO_CONFIG
                jmp mainL

chkModoM`       brclr BANDERAS2,$01,jmodormedicion`
                bset PIEH,$09               ;La primera vez que se llega a este modo se habilitan las interrupciones del puerto H
                bset PIFH,$09                
                bclr BANDERAS2,$01
                movb #$02,LEDS
                movb #$BB,BIN1
                movb #$BB,BIN2              ;Se borra la pantalla de 7 seg
                ldx #MESS5
                ldy #MESS7
                jsr CARGAR_LCD
jmodormedicion` movb #$83,TSCR2
                jsr MODO_MEDICION
                jmp mainL



                
                
;################################################################################################################################################################################################
;       Subrutinas




;################################################################################################################################################################################################
;################################################################################################################################################################################################
;################################################################################################################################################################################################
;################################################################################################################################################################################################
;       Subrutinas de interrupciones

;       Subrutinas PH
;        subrutina de PHO

                loc
PTH_ISR:        brset PIFH,$01,PH0_ISR          ;Se revisa cual interrupcion es 1 y 2 estan siempre deshabilitadas
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
PH0_ISR:        ;bset PORTB,$04
                bset PIFH, $01 
                tst CONT_REB
                bne returnPH 
                movb #100,CONT_REB          ;Si el contador de rebotes es distinto de 0 se ejecuta el Calculo
                ldab TICK_VEL            ;Se revisa que tick_Vel sea diferente de cero
                ;movb #88,BIN2          
                beq returnPH
                bclr BANDERAS2,$08      
                cmpb #26                ;26 es el numero minimo de ticks si es menor el resultado de la velocidad es mayor a 255 y se desborda           
                bhs validSpeed`         ;Comparacion sin signo
                movb #$FF,VELOC
                bra SetTicks`
validSpeed`     ldaa #0                 ;Se carga en D TICK_VEL, ya que en X no se puede porque es un byte
                ldx #26367               
                xgdx                 ;Se intercambian para la division
                idiv
                tfr X,D                 ;Se vuelven a intercambiar para guardar el resultado en veloc que es un byte
                lsrd
                lsrd
                stab VELOC              ;Se procede a calcular los ticks para las banderas
SetTicks`       ldab TICK_VEL           ;Se multiplica tick_vel por 5 para obtener la cantidad de ticks para 200 m
                ldaa #5
                mul
                clr TICK_VEL
                std TICK_DIS
                lsrd
                std TICK_EN             ;Se divide entre 2 para obtener la cantidad de ticks para 100 m                                                        
                bra returnPH

;       subrutina PH1
;################################################################################################################################################
;Descripcion:
;       Esta subrutina nunca se utiliza

;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################
PH1_ISR:        bset PIFH, $02                                          
returnPH:       rti
;       subrutina PH2
;################################################################################################################################################
;Descripcion: 
;       Esta subrutina nunca se utiliza        


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################                
PH2_ISR:        bset PIFH, $04 
                             
                bra returnPH
;       subrutina PH3
;################################################################################################################################################
;Descripcion:
;       Incluye la subrutina Calculo


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################
PH3_ISR:        bset PIFH, $08
                tst CONT_REB
                bne returnPH                
                movb #100,CONT_REB
                clr TICK_VEL
                bset BANDERAS2,$04          ;Se levanta la bandera de print Calculando 
                bset BANDERAS2,$08          ;Se levanta la bandera que habilita el conteo de ticks
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
                tst CONT_REB            ;Es subrutina solo se usa para el contador de rebotes 
                beq return`
                dec CONT_REB
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
                ldab DT

                cba
                bge apagar`         ; Si n ticks son iguales al DT se apaga la pantalla
                tst CONT_TICKS
                beq check_digit`
checkN`         cmpa #100           ;Si es 100 se debe encender un digito
                beq changeDigit`
incticks`       inc CONT_TICKS
                jmp part2`
;Apagar
apagar`         movb #$FF,PTP
                movb #$0, PORTB
                bra checkN`
;           cambiar digito
changeDigit`    movb #$0, CONT_TICKS            ;Reset de contador
                inc CONT_DIG
                ldaa #6
                cmpa CONT_DIG
                bne jpart2`                 ;no me alcanzo para hacer el primer salto 
                movb #1,CONT_DIG
jpart2`         bra part2`
;           encender digito
check_digit`    ldaa CONT_DIG               ;Se verifica cual digito se debe configurar
                cmpa #1
                bne dig2`
                ldaa DISP1
                cmpa #$BB                   ;Si el valor en disp es BB el digito no se enciende
                beq incticks`
                bclr PTP, $08
                movb DISP1, PORTB
                bset PTJ, $02
ndig1`          bra  incticks`
dig2`           cmpa #2                     ;Se repite el mismo proceso para los otros digitos
                bne dig3`
                bclr PTP, $04
                ldaa DISP2
                cmpa #$BB
                beq incticks`
                movb DISP2, PORTB
                bset PTJ, $02
ndig2`          bra  incticks`
dig3`           cmpa #3
                bne dig4`
                ldaa DISP3
                cmpa #$BB
                beq ndig3`
                bclr PTP, $02                                
                movb DISP3, PORTB
                bset PTJ, $02
ndig3`          bra  incticks`
dig4`           cmpa #4
                bne digleds`                                          
                ldaa DISP4
                cmpa #$BB
                beq ndig4`
                bclr PTP, $01  
                movb DISP4, PORTB
                bset PTJ, $02
ndig4`          jmp  incticks`
digleds`        movb LEDS, PORTB
                bclr PTJ, $02
                inc CONT_TICKS


part2`          tst CONT_DELAY          ;Segunda parte de OC4, encargada de manejar cont_delay, cont_200 y la subrutina bcd_7seg
                beq tst7seg`
                dec CONT_DELAY
tst7seg`        ldx CONT_7SEG           ;cuando el contador de 7seg es 0 se debe llamar a la subrutina y configurar el contador en 5000
                beq JBCD_7SEG`
                dex
                stx CONT_7SEG
tst200`         ldx CONT_200
                beq enableATDLEDs`
                dex
                stx CONT_200
                bra returnOC4 
enableATDLEDs`  movw #1000,CONT_200         ;Reseteo de contador
                movb #$87, ATD0CTL5         ;Convertidor atd
                jsr PATRON_LEDS             ;Leds de alarma
returnOC4       jsr CONV_BIN_BCD
                ldd TCNT
                addd #60
                std TC4
                movb #$FF,TFLG1         ;Se hace borrado manual para evitar conflictos con TCNT
                rti
JBCD_7SEG`      movw #5000,CONT_7SEG
                jsr BCD_7SEG
                bra tst200`



;   Subrutina ATD

;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################
ATD_ISR:        loc
                ldx #6
                ldd ADR00H
                addd ADR01H 
                addd ADR02H
                addd ADR03H     ;Se calcula el promedio de las 6 medidas del potenciometro
                addd ADR04H
                addd ADR05H
                idiv 
                tfr X,D
                stab POT      ;Guardar el promedio
                ldaa #20
                mul
                ldx #255
                idiv
                tfr X,D
                stab BRILLO
                ldaa #5      ;Se multiplica por 5 para volverlo en escala a 100
                mul
                stab DT
                
                
                rti
;   Subrutina TCNT

;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################
                loc
TCNT_ISR:       ldaa TICK_VEL               
                cmpa #255                   ; si esta en valor maximo se mantiene ahi, esto resulta en una velocidad invalida
                beq next1`
                brclr BANDERAS2,$08,next1`      ;Revisa la bandera que habilita el conteo de ticks
                inc TICK_VEL
next1`          tst VELOC
                beq returnTCNT`
                ldx TICK_EN                 ;Se comprueba que ticks enable sea diferente de 0
                dex
                bne storeX1`
                ;movw #$FFFF,TICK_EN        ;Esta linea no es necesaria debido a que al restarle 1 se vuelve $FFFF
                bset BANDERAS1,$08          ;Banderas1.3 corresponde a pant_flag                    
storeX1`        stx TICK_EN
                ldx TICK_DIS                ;Se comprueba que ticks disable sea diferente de 0
                dex                                              
                bne storeX2`
                ;movw #$FFFF,TICK_DIS
                bclr BANDERAS1,$08 
storeX2`        stx TICK_DIS
returnTCNT`     movb #$FF,TFLG2 ;
                rti
;################################################################################################################################################
;################################################################################################################################################
;################################################################################################################################################
;################################################################################################################################################

;       Subrutinas Generales


;       Subrutina Tarea Teclado
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################

TAREA_TECLADO:  loc
                tst CONT_REB
                bne return`
                jsr MUX_TECLADO
                ldaa TECLA
                cmpa #$FF
                beq checkLista`
                brset BANDERAS1,$02,checkLeida`        ;revision de bandera Tecla leida
                movb TECLA,TECLA_IN
                bset BANDERAS1,$02
                movb #10,CONT_REB                       ;iniciar contador de rebotes
                bra return`
checkLeida`     cmpa TECLA_IN                           ;Comparar Tecla con tecla_in
                bne Diferente`
                bset BANDERAS1,$01
                bra return`
Diferente`      movb #$FF,TECLA                         ;Las teclas son invalidas
                movb #$FF,TECLA_IN
                bclr BANDERAS1,$03
                bra return`
checkLista`     brclr BANDERAS1,$01,return`              ;el numero esta listo
                bclr BANDERAS1,$03
                jsr FORMAR_ARRAY
return`         rts



;       Subrutina MUX_TECLADO
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################
MUX_TECLADO:    loc
                ldab #0
                clr PATRON
                ldx #TECLAS
mainloop`       tst PATRON
                bne p1
                movb #$EF,PORTA
                bra READ
p1:             ldaa #1
                cmpa PATRON
                bne p2
                movb #$DF,PORTA
                bra READ
p2:             inca                    ;A=2
                cmpa PATRON
                bne p3
                movb #$BF,PORTA
                bra READ
p3:             inca                    ;A=3
                cmpa PATRON             ;Se detecta cual patron se debe usar en la salida
                bne nk
                movb #$7F,PORTA
read:           nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop                     ;corrige problema de primera fila
                brclr PORTA,$01, treturn`       ;se leen las entradas para encontrar la tecla presionada
                incb
                brclr PORTA,$02, treturn`
                incb
                brclr PORTA,$04, treturn`
                incb
                inc PATRON
                bra mainloop`
nk              movb #$FF,TECLA                 ;Se guarda la tecla o se retorna FF
                bra return`
treturn`        movb B,X,TECLA
return`         rts
;       Subrutina formar array
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################

FORMAR_ARRAY:   loc
                ldx #NUM_ARRAY
                ldaa TECLA_IN
                ldab CONT_TCL
                beq check_MAX`
                cmpa #$0E
                beq t_enter`
                cmpa #$0B
                beq t_borrar`
                cmpb MAX_TCL
                beq return`
                bra guardar`
check_MAX`      cmpa #$0E
                beq return`
                cmpa #$0B
                beq return`
guardar`        staa B,X
                incb
                stab CONT_TCL
                bra return`
t_enter`        bset BANDERAS1,$04
                movb #$0,CONT_TCL
                bra return`
t_borrar`       decb
                movb #$FF,B,X
                stab CONT_TCL
return`         rts




;       BCD_7SEG
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################
BCD_7SEG:       loc
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
returnBCD_7SEG: rts


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
                bclr BANDERAS2,$02
                jsr Send
                movb D60uS,CONT_DELAY
                jsr Delay
                dbne B,loop1`           ;hasta aqui se estan mandando los comando iniciales de dsp
                bclr BANDERAS2,$02
                ldaa Clear_LCD
                jsr Send                ;hasta aqui se borra la pantalla
                movb D2mS,CONT_DELAY
                jsr Delay
                pulx
                ldaa ADD_L1                        ;aqui empieza cargar lcd
                bclr BANDERAS2,$02
                jsr Send
                movb D60uS,CONT_DELAY
                jsr Delay
loop2`          ldaa 1,X+
                cmpa #FIN
                beq linea2`
                bset BANDERAS2,$02
                jsr Send
                movb D60uS,CONT_DELAY
                jsr Delay
                bra loop2`
linea2`         ldaa ADD_L2                        ;aqui empieza cargar la linea 2
                bclr BANDERAS2,$02
                jsr Send
                movb D60uS,CONT_DELAY
                jsr Delay
loop3`          ldaa 1,Y+
                cmpa #FIN
                beq returnLCD`
                bset BANDERAS2,$02
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
;       Banderas.1: Indica si es un comando o datos
;Salida:
;################################################################################################################################################
                loc
Send:           psha
                anda #$F0
                lsra
                lsra
                staa PORTK
                brset BANDERAS2,$02,dato1`          ;Se revisa la bandera para determinar si es un dato o si es un comando
                bclr PORTK,$01          
                bra continue1`
dato1`          bset PORTK,$01
continue1`      bset PORTK,$02
                movb D240uS,CONT_DELAY
                jsr Delay
                bclr PORTK,$02
                pula
                anda #$0F
                lsla
                lsla
                staa PORTK
                brset BANDERAS2,$02,dato2`
                bclr PORTK,$01
                bra continue2`
dato2`          bset PORTK,$01
continue2`      bset PORTK,$02
                movb D240uS,CONT_DELAY
                jsr Delay
                bclr PORTK,$02
                rts    

;       Delay
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################
                loc
Delay:          tst CONT_DELAY 
                bne Delay
                rts

;       CONV_BIN_BCD
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################
                loc
CONV_BIN_BCD:   ldaa BIN1
                cmpa #$BB
                bne cont1`
                movb #$BB,BCD1
                bra next`
cont1`          cmpa #$AA
                bne cont2`
                movb #$AA,BCD1
                bra next`
cont2`          jsr BIN_BCD
                movb BCD_L,BCD1
next`           ldaa BIN2
                cmpa #$BB
                bne cont3`
                movb #$BB,BCD2
                bra return`
cont3`          cmpa #$AA
                bne cont4`
                movb #$AA,BCD2
                bra return`
cont4`          jsr BIN_BCD
                movb BCD_L,BCD2                                
return`         rts

;       BIN_BCD
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;       R1
;Salida: 
;       BCD_L        
;################################################################################################################################################
                loc
BIN_BCD:        ldab #7
                clr BCD_L
                ldx #BCD_L        
loop`           lsla
                rol 0,X
                staa TEMP
                ldaa 0,X
                anda #$0F
                cmpa #5
                blt continue1`
                adda #3
continue1`      staa LOW 
                ldaa 0,X
                anda #$F0
                cmpa #$50
                blt continue2`
                adda #$30
continue2`      adda LOW
                staa 0,X
                ldaa TEMP
                decb
                cmpb #$0 
                bne loop`
                lsla
                rol 0,X                           
                rts

;       BCD_BIN
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################
                loc
BCD_BIN:        ldx #NUM_ARRAY
                ldaa 1,X
                cmpa #$FF       ;verifica que el segundo numero no sea FF
                beq wrong`
                ldaa #0
loop`           cmpa #0
                beq mul10`;
                addb A,X    
                bra sumarA`
mul10`          ldab A,X
                lslb
                lslb
                lslb        ;mult por 8
                addb A,X
                addb A,X    ;mult por 10
sumarA`         movb #$FF,A,X
                inca
                cmpa MAX_TCL
                bne loop`
                stab V_LIM 
                bra return`
wrong`          movb #$FF,NUM_ARRAY
                movb #$0,V_LIM
return`         rts

;       MODO_CONFIG
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################
MODO_CONFIG:    loc
                
                brclr BANDERAS1,$04,jtarea_teclado`     ;Se revisa array ok
                jsr BCD_BIN
                bclr BANDERAS1,$04
                ldaa V_LIM
                cmpa #90
                bgt resetV_LIM`
                cmpa #45
                blt resetV_LIM`
                movb V_LIM,BIN1
                movb #$BB,BIN2
                bra returnCofig
jtarea_teclado` jsr TAREA_TECLADO
                bra returnCofig
resetV_LIM`     clr V_LIM
returnCofig:    rts

;       MODO_MEDICION
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################
MODO_MEDICION:  loc
                tst VELOC
                beq tstflg`
                jsr PANT_CTRL                       ;Si la velocidad es mayor a 0 se modifican las pantallas
                bra returnMM`
tstflg`         brclr BANDERAS2,$04,returnMM`       ;Si la bandera de imprimir Calculando está activa se imprime el mensaje
                bclr PIEH,$08
                ldx #MESS5
                ldy #MESS8  
                jsr CARGAR_LCD
                bclr BANDERAS2,$04                  ;Se borra la bandera de imprimir Calculando        
returnMM`       rts

;       MODO_LIBRE
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################
MODO_LIBRE:     loc                
                movb #$BB,BIN1
                movb #$BB,BIN2
                rts

;       PANT_CTRL
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################                

                loc
PANT_CTRL:      bclr PIEH,$09
                bset PIFH,$09
                ldaa VELOC
                cmpa #30                ;Se verifica que la velocidad este adentro del rango 30-99
                blt outOfBounds`
                cmpa #99
                bgt outOfBounds`
                cmpa V_LIM
                ble next`
                bset BANDERAS1,$10      ;Levantar Alerta si es mayor a la velocidad limite
                bra next`
outOfBounds`    cmpa #$AA
                beq next`
                movw #1,TICK_EN
                movw #92,TICK_DIS
                movb #$AA,VELOC                            
next`           brset BANDERAS1,$08,loadSpeed`  ;Se revisa PANT_FLAG si esta en 1 se carga en pantalla la velocidad y el mensaje correspondiente
                ldaa BIN1               ;En esta rama se decide si enviar el mensaje de espera y devolver las variables a 0
                cmpa #$BB               ;Si el valor de bin1 es diferente de #$BB es porque todavía no se ha enviado el mensaje
                beq returnPC`
                
                ldx #MESS5
                ldy #MESS7
                jsr CARGAR_LCD          ;Se enviar MODO_Medicion y esperando...
                movb #$BB,BIN1
                movb #$BB,BIN2
                clr VELOC
                bclr BANDERAS1,$10      ;Borrar Alerta 
                bset PIFH,$09
                bset PIEH,$09
                

                bra returnPC`
loadSpeed`      ldaa BIN1               ;Se decide si enviar el mensaje con las velocidades
                cmpa #$BB               ;Si el valor es #$BB no se ha enviado el mensaje
                bne returnPC`
                movb V_LIM,BIN1
                movb VELOC,BIN2
                ldx #MESS5
                ldy #MESS6
                jsr CARGAR_LCD          ;Se enviar MODO_Medicion y su.vel y vel limite

returnPC`       rts





;       PATRON_LEDS
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################                
                loc
PATRON_LEDS:    brset BANDERAS1,$10,activateAl`         ;Se revisa si la alarma está activada
                bclr LEDS,$F8
                bra returnPL`
activateAl`     ldaa #$80
                cmpa LEDS37                 ;Se revisa que no este en el ultimo led
                beq resLEDS37`
                lsl LEDS37          ;Si no esta en el ultimo led se realiza un desplazamiento
                bra chLEDS`
resLEDS37`      movb #$08,LEDS37        ;Si es igual se devuelve al primer led
chLEDS`         ldaa LEDS37
                adda #2             ;Se le suma 2 para encender el led de modo medicion
                staa LEDS   
returnPL`       rts                             
