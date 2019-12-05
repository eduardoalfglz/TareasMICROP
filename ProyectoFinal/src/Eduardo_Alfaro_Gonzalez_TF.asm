;###################################################################################################################################################################################################
;
;
;               Trabajo Final
;               Eduardo Alfaro Gonzalez
;               B50203
;               Radar 623
;               Ultima vez modificado 28/11/19
;
;
;###################################################################################################################################################################################################
#include registers.inc
;###################################################################################################################################################################################################
;Descripcion General:
;El siguiente código para la tarjeta dragon 12 de FreeScale corresponde a un sensor de velocidad para vehiculos,
;este cuenta con 3 modos, el primero es utilizado para configurar la velocidad limite de la zona, esto se hace 
;por medio del uso del teclado matricial de la tarjeta y los displays de 7 segmentos para mostrar la velocidad
;configurada, el segundo modo corresponde a un modo libre donde el sensor no realiza ninguna operacion, finalmente
;el ultimo modo corresponde a la medicion de velocidades la cual se realiza por medio de los botones del puerto H
;una vez que se determina la velocidad se muestra en pantalla si es un valor valido y si se pasa de la velocidad 
;limite configurada se enciende una alarma representada en los leds. Cada modo cuenta con sus respectivos mensajes
;en la pantlla LCD.


;###################################################################################################################################################################################################


;################################################################################################################################################################################################
;################################################################################################################################################################################################
;################################################################################################################################################################################################
;################################################################################################################################################################################################
;               Definicion de estructuras de datos



CR:             equ $0D
LF:             equ $0A
FIN:            equ $0

                org $1000
BANDERAS:      ds 2    ;7: MOD_H      6:MOD_L  3:Enable tick_vel  2:PRINT Calculando... 1:Data or Control LCD    0:Cambio_Modo
    ;0: TCL_Lista   1:TCL_Leida     2:ARRAY_OK  3:PANT_FLAG     4:ALERTA        5:CALC_TICK
V_LIM:          ds 1    ;Velocidad limite
MAX_TCL:        db 2    ;Maximo numero de teclas que se aceptan del teclado matricial, en este caso 2
TECLA:          ds 1    ;Tecla ingresada
TECLA_IN:       ds 1    ;Tecla anterior

CONT_REB:       ds 1    ;Contador de rebotes, utilizado para suprimirlos
CONT_TCL:       ds 1    ;
PATRON:         ds 1    ;Patron a enviar para leer las teclas del teclado
        

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
D2mS:           db 100      ;Constante para generar un delay de 2 ms
D240uS:         db 13       ;Constante para generar un delay de 260 ms
D60uS:          db 3        ;Constante para generar un delay de 60 ms

Clear_LCD:      db $01      ;constante igual a comando clear
ADD_L1:         db $80      ;constante igual a Adress linea 1 lcd
ADD_L2:         db $C0      ;constante igual a Adress linea 2 lcd
TEMP:           ds 1
LEDS37:         ds 1        ;Variable que define el desplazamiento de los leds 3:7 en modo alerta
Variable2:      ds 1
Variable3:      ds 1




                org $1030
TECLAS:         db $01,$04,$07,$02,$05,$08,$03,$06,$09,$0B,$00,$0E



 
                org $1040
SEGMENT:        db $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F,$40,$00  ;0,1,2,3,4,5,6,7,8,9,-,Apagar
                
                
                
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





                
;Subrutinas de interrupcion                
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
                movb #$80, TSCR1        ;Habilita el modulo sin tffca
                movb #$03, TSCR2        ;Prescaler de 8
                movb #$10, TIOS         ;Habilita la salida del oc4
                movb #$01, TCTL1        ;Salida de oc4 en toggle
                clr TCTL2
                movb #$10, TIE          ;Habilita la interrupcion de oc4
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
                clr BCD1        ;Se borra el contenido de las varibles de la pantalla de 7 seg
                clr BCD2
                clr BIN2
                clr BIN1
                movb #02,LEDS
                movb #$80,LEDS37
                clr DISP1
                clr DISP2
                clr DISP3
                clr DISP4
                clr VELOC
                ;modser=1
                movb #1,CONT_DIG
                clr CONT_TICKS
                movb #50, BRILLO        ;El brillo se inicializa en la mitad, luego se le asigna el valor del atd
                movb #00, V_LIM
                

                movb #$FF, TECLA
                movb #$FF, TECLA_IN
                clr CONT_TCL
                clr CONT_REB
                bclr (BANDERAS+1),$FF      ;Poner las banderas de teclados en 0 
                bset BANDERAS,$01      ;Poner la bandera cambio nodo en 1 y el resto no importan
                bclr BANDERAS,$C4      ;modo en 00 es decir MODO config, se borra la bandera print Calculando                
                ldaa MAX_TCL
                ldx #NUM_ARRAY-1
LoopCLR:        movb #$FF,A,X          ;iniciar el arreglo en FF
                dbne A,LoopCLR


;       Programa main   
;################################################################################################################################################
;Descripcion:   
;       Es el programa principal del codigo es el encargado de detectar por medio de los dipswitch
;       cual modo ha sido selecionado y mostrar en pantalla el mensaje correspondiente.


;Paso de parametros:
;Entrada:
    ;V_LIM: Velocidad limite, si es 0 no puede cambiar de modo
    ;MESS1 
    ;MESS2
    ;MESS3
    ;MESS4
    ;MESS5
    ;MESS7
;Salida:
    ;LEDS: Se enciende dependiendo del modo
    ;BIN1: Dependiendo del modo se resetea a $BB
    ;BIN2: Dependiendo del modo se resetea a $BB
;################################################################################################################################################
mainL:          loc
                tst V_LIM               ;La velocidad debe ser distanta de cero para salir de modo configs
                beq chkModoLC           ;Salta a revisar si es modo config o libre
                ldaa PTIH               ;se cargan los valores de los dipswitch
                anda #$C0               ;Se utilizan solo los bits de modo
                ldab BANDERAS          ;Bits de banderas que corresponden a modos
                andb #$C0               ;Bits de modo
                cba
                beq nochange`
                cmpa #$40               ;se revisa que el modo no sea el valor invalido
                beq nochange`                
                bset BANDERAS,$01      ;Se activa cambio de modo
                cmpa #$80               ;Revisar si es modo libre
                beq swML`
                cmpa #$C0
                beq swMM`
                bclr BANDERAS,$C0      ;Si los switches estan en modo config se configura en el registro MOD
                bra nochange`
swML`           bset BANDERAS,$80      ;Si los switches estan en modo libre se configura en el registro MOD
                bclr BANDERAS,$40
                bra nochange`
swMM`           bset BANDERAS,$C0      ;Si los switches estan en modo medicion se configura en el registro MOD

nochange`       brset BANDERAS,$C0,chkModoM`

                
                
chkModoLC:      clr VELOC
                bclr PIEH,$09                       ;Se deshabilitan las interrupciones del puerto H, TOI y se pone veloc en 0
                bset PIFH,$09
                movb #$03,TSCR2
                bclr (BANDERAS+1),$18                  ;FIXME:Se borra la bandera de alerta y la bandera de PANT_FLAG
                brclr BANDERAS,$C0,chkModoC`       ;Salta a revisar el modo Config


chkModoL`       brclr BANDERAS,$01,jmodolibre`           ;Tecnicamente aqui deberia saltar a modo libre, pero no hace nada
                bclr BANDERAS,$01                  
                movb #$04,LEDS                                
                ldx #MESS3
                ldy #MESS4
                jsr CARGAR_LCD                
jmodolibre`     jsr MODO_LIBRE
                bra mainL

chkModoC`       brclr BANDERAS,$01,jmodoconfig`
                bclr BANDERAS,$01                                  
                movb V_LIM,BIN1             ;Si esta en modo config se revisa si hay cambio de modo para imprimir en la LCD
                movb #$BB,BIN2               ;88 para pruebas
                ldx #MESS1
                ldy #MESS2
                movb #$01,LEDS
                jsr CARGAR_LCD
                

jmodoconfig`    jsr MODO_CONFIG
                jmp mainL

chkModoM`       brclr BANDERAS,$01,jmodormedicion`
                bset PIEH,$09               ;La primera vez que se llega a este modo se habilitan las interrupciones del puerto H
                bset PIFH,$09                
                bclr BANDERAS,$01
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


                loc
PTH_ISR:        brset PIFH,$01,PH0_ISR          ;Se revisa cual interrupcion es 1 y 2 estan siempre deshabilitadas
                brset PIFH,$02,PH1_ISR
                brset PIFH,$04,PH2_ISR
                brset PIFH,$08,PH3_ISR

;       subrutina PH0
;################################################################################################################################################
;Descripcion:
;       Simula el segundo sensor, aparte de eso incluye la subrutina calculo, es decir a partir de la cantidad de 
;       Ticks calcula la velocidad del vehiculo así como la los ticks necesarios para mostrar la velocidad y los 
;       necesarios para borrarla de pantalla


;Paso de parametros:
;Entrada:
;       TICK_VEL: ticks que tarda el vehiculo en recorrer 40 m
;       CONT_REB: contador de rebotes


;Salida:

;       VELOC: Velocidad del vehiculo
;       TICK_EN: Ticks para habilitar el mensaje en pantalla y velocidad en 7 seg
;       TICK_DIS: Ticks para deshabilitar el mensaje en pantalla y borrar velocidad en 7 seg      
;################################################################################################################################################
PH0_ISR:        ;bset PORTB,$04
                bset PIFH, $01 
                tst CONT_REB
                bne returnPH 
                movb #100,CONT_REB          ;Si el contador de rebotes es distinto de 0 se ejecuta el Calculo
                ldab TICK_VEL            ;Se revisa que tick_Vel sea diferente de cero         
                beq returnPH
                bclr BANDERAS,$08      
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
;       Sensor 1 inicia el conteo de ticks


;Paso de parametros:
;Entrada:
;       CONT_REB
;Salida:
;       TICK_VEL: se borran en esta interrupcion
;################################################################################################################################################
PH3_ISR:        bset PIFH, $08
                tst CONT_REB
                bne returnPH                
                movb #100,CONT_REB
                clr TICK_VEL
                bset BANDERAS,$04          ;Se levanta la bandera de print Calculando 
                bset BANDERAS,$08          ;Se levanta la bandera que habilita el conteo de ticks
                bra returnPH                



;       subrutina de rti
;################################################################################################################################################
;Descripcion:
;      Subrutina encarga del manejo de los rebotes de los botones     

;Paso de parametros:
;Entrada:
;      CONT_REB: se debe verificar que no sea 0
;Salida:
;      CONT_REB: si no es cero se decrementa
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
;       Subrutina encargada del manejo de la pantalla de 7 segmentos, maneja el contenido de los displays y como se multiplexan
;       ademas cada cierto tiempo debe llamar al convertidor analogico digital y el control de los leds en el modo alarma, tambien
;       llama a la subrutina bcd 7 segmnetos


;Paso de parametros:
;Entrada:
        ;DT: determina si se debe apagar la pantalla actual determinado por atd
        ;DISP1,DISP2,DISP3,DISP4: Contenido que se debe mostrar en los 
        ;LEDS:Variable que determina el patron de los leds
;Salida:
        ;CONT_DELAY: contador de retraso para contador de pantalla de 7 segmentos
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
                bra part2`
;Apagar
apagar`         movb #$FF,PTP
                bclr PTJ, $02
                clr PORTB
                bra checkN`
;           cambiar digito
changeDigit`    clr CONT_TICKS            ;Reset de contador
                inc CONT_DIG
                ldaa #5
                cmpa CONT_DIG
                bne part2`                 
                clr CONT_DIG                    ;Reset del contador de digito
;           encender digito
check_digit`    ldaa CONT_DIG               ;Se verifica cual digito se debe configurar 

                ldx #DISP1
                movb A,X,PORTB                  ;Direcciona el valor por direccionamiento indexado
                bset PTJ, $02
                cmpa #0
                bne dig2`                
                movb #$07,PTP
ndig1`          bra  incticks`
dig2`           cmpa #1                     ;Se repite el mismo proceso para los otros digitos
                bne dig3`
                movb #$0B,PTP                                
ndig2`          bra  incticks`
dig3`           cmpa #2
                bne dig4`                
                movb #$0D,PTP                                                
ndig3`          bra  incticks`
dig4`           cmpa #3
                bne digleds`                                          
                movb #$0E,PTP  
ndig4`          bra  incticks`
digleds`        bclr PTJ, $02
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
enableATDLEDs`  movw #10000,CONT_200         ;Reseteo de contador
                movb #$87, ATD0CTL5         ;Convertidor atd
                jsr PATRON_LEDS             ;Leds de alarma
returnOC4       jsr CONV_BIN_BCD
                ldd TCNT
                addd #60
                std TC4
                movb #$FF,TFLG1         ;Se hace borrado manual para evitar conflictos con TCNT
                rti
JBCD_7SEG`      movw #499,CONT_7SEG
                jsr BCD_7SEG
                bra tst200`



;   Subrutina ATD

;################################################################################################################################################
;Descripcion:
;       Subrutina utilizada para la conversion analogica digital del potenciometro de la tarjeta dragon 12, utilizado para
;       controlar el brillo de los leds y las pantallas de 7 segmentos. Se toman 6 mediciones y se calcula el promedio.


;Paso de parametros:
;Entrada:
        ;ADR00H,ADR01H,ADR02H,ADR03H,ADR04H,ADR05H: Registros de datos del convertidor analogico digital        
;Salida:
        ;Brillo: variable correspondiente a k en el ciclo de trabajo del control de los leds 
        ;DT: Duty time, variable que determina cuanto tiempo deben permancer los leds encendidos.
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
;       Interrupcion causada por el overflow del contador de tiempo, esta encargada de incrementar el valor de los ticks que se usan para medir 
;       la velocidad del vehiculo, así como el decremento de las variables que determinan el tiempo que se muestran las velocidades en la pantalla

;Paso de parametros:
;Entrada:
;Salida:
        ;TICK_VEL: Ticks para medir la velocidad, solo si incrementan cuando se encuentra entre los dos sensores
        ;TICK_EN: Ticks necesarios para mostrar la velocidad el medidor, se decrementan
        ;TICK_DIS: Ticks necesarios para eliminar la velocidad el medidor, se decrementan
;################################################################################################################################################
                loc
TCNT_ISR:       ldaa TICK_VEL               
                cmpa #255                   ; si esta en valor maximo se mantiene ahi, esto resulta en una velocidad invalida
                beq next1`
                brclr BANDERAS,$08,next1`      ;Revisa la bandera que habilita el conteo de ticks
                inc TICK_VEL
next1`          tst VELOC
                beq returnTCNT`
                ldx TICK_EN                 ;Se comprueba que ticks enable sea diferente de 0
                dex
                bne storeX1`
                ;movw #$FFFF,TICK_EN        ;Esta linea no es necesaria debido a que al restarle 1 se vuelve $FFFF
                bset (BANDERAS+1),$08          ;Banderas1.3 corresponde a pant_flag                    
storeX1`        stx TICK_EN
                ldx TICK_DIS                ;Se comprueba que ticks disable sea diferente de 0
                dex                                              
                bne storeX2`
                ;movw #$FFFF,TICK_DIS
                bclr (BANDERAS+1),$08 
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
;       Subrutina encargada de manejar el teclado matricial de la tarjeta, suprime rebotes.

;Paso de parametros:
;Entrada:
;       TECLA:  Tecla presionada en el teclado
;       TECLA_IN:   Tecla presionada antes de suprimir los rebotes, se debe verificar que sea igual a TECLA
;Salida:
;################################################################################################################################################

TAREA_TECLADO:  loc
                tst CONT_REB
                bne return`
                jsr MUX_TECLADO
                ldaa TECLA
                cmpa #$FF
                beq checkLista`
                brset (BANDERAS+1),$02,checkLeida`        ;revision de bandera Tecla leida
                movb TECLA,TECLA_IN
                bset (BANDERAS+1),$02
                movb #10,CONT_REB                       ;iniciar contador de rebotes
                bra return`
checkLeida`     cmpa TECLA_IN                           ;Comparar Tecla con tecla_in
                bne Diferente`
                bset (BANDERAS+1),$01
                bra return`
Diferente`      movb #$FF,TECLA                         ;Las teclas son invalidas
                movb #$FF,TECLA_IN
                bclr (BANDERAS+1),$03
                bra return`
checkLista`     brclr (BANDERAS+1),$01,return`              ;el numero esta listo
                bclr (BANDERAS+1),$03
                jsr FORMAR_ARRAY
return`         rts



;       Subrutina MUX_TECLADO
;################################################################################################################################################
;Descripcion:
;       Subrutina encargada de capturar el valor presionado en el teclado matricial, para esto se envian un patron al puerto A, y se detecta
;       la señal de entrada correspondiente, para esto se tiene una tabla de valores correspondientes a cada tecla.

;Paso de parametros:
;Entrada:
;       TECLAS: Tabla que incluye los valores de cada una de las teclas del teclado
;Salida:
;       TECLA: Valor de la tecla presionada.
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
;       Esta subrutina es la encargada de almacenar los valores del teclado en memoria, para esto los valores de TECLA_in y TECLA deben ser iguales
;       se tiene una cantidad maxima de teclas determinada por MAX_TCL, ademas al precionar la tecla enter no se pueden introducir más teclas,
;       también al presionar la tecla B se puede eliminar un valor de memoria.

;Paso de parametros:
;Entrada:
;       MAX_TCL: Cantidad maxima de teclas en el arreglo
;       TECLA_IN: Valor de la tecla presionada.
;       CONT_TCL: Puntero a la tecla actual
;Salida:
;       NUM_ARRAY: Arreglo donde se almacenan los valores en memoria.
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
t_enter`        bset (BANDERAS+1),$04
                movb #$0,CONT_TCL
                bra return`
t_borrar`       decb
                movb #$FF,B,X
                stab CONT_TCL
return`         rts




;       BCD_7SEG
;################################################################################################################################################
;Descripcion:
;       Subrutina encargada convertir valores en formato BCD a los valores necesarios para poder visualizarlos en la pantalla de 7 segmentos.

;Paso de parametros:
;Entrada:
;       BC1,BCD2: Valores en bcd a convertir
;       SEGMENT: Tabla que contiene los valores para cada uno de los digitos.
;Salida:
;       DISP1,DISP2,DISP3,DISP4: Valores en 7 segmentos para cada uno de los displays
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
;           Subrutina encargada de enviar la información a desplegar en la pantalla LCD

;Paso de parametros:
;Entrada:
;       ;iniDsp: Tabla de comandos para iniciar la comunicación con la pantalla
;       ADD_L1,ADD_L2: Comandos para añadir lineas
;       Registro X: Contiene el puntero para el contenido de la linea 1
;       Registro Y: Contiene el puntero para el contenido de la linea 2           
;       D60us,D2ms: Constantes para el tiempo de espera necesario para la comunicación correcta con la pantalla.
;Salida:
;################################################################################################################################################
CARGAR_LCD:     loc                
                pshx
                ldx #iniDsp
                ldab 1,X+
loop1`          ldaa 1,X+
                bclr BANDERAS,$02
                jsr Send
                movb D60uS,CONT_DELAY
                jsr Delay
                dbne B,loop1`           ;hasta aqui se estan mandando los comando iniciales de dsp
                bclr BANDERAS,$02
                ldaa Clear_LCD
                jsr Send                ;hasta aqui se borra la pantalla
                movb D2mS,CONT_DELAY
                jsr Delay
                pulx
                ldaa ADD_L1                        ;aqui empieza cargar lcd
                bclr BANDERAS,$02
                jsr Send
                movb D60uS,CONT_DELAY
                jsr Delay
loop2`          ldaa 1,X+
                cmpa #FIN
                beq linea2`
                bset BANDERAS,$02
                jsr Send
                movb D60uS,CONT_DELAY
                jsr Delay
                bra loop2`
linea2`         ldaa ADD_L2                        ;aqui empieza cargar la linea 2
                bclr BANDERAS,$02
                jsr Send
                movb D60uS,CONT_DELAY
                jsr Delay
loop3`          ldaa 1,Y+
                cmpa #FIN
                beq returnLCD`
                bset BANDERAS,$02
                jsr Send
                movb D60uS,CONT_DELAY
                jsr Delay
                bra loop3`
returnLCD`      rts


;       Send
;################################################################################################################################################
;Descripcion:
;       Subrutina encarga de enviar los datos o comando a la pantalla LCD

;Paso de parametros:
;Entrada:
;       Banderas.1: Indica si es un comando o datos
;       Registro: Contenido del comando o dato a enviar a la pantalla
;       D240us: Constante con el valor necesario para generar el delay
;Salida:
;################################################################################################################################################
                loc
Send:           psha
                anda #$F0               ;Inicialmente se debe mandar la parte alta 
                lsra                    ;desplazamiento necesario
                lsra
                staa PORTK
                brset BANDERAS,$02,dato1`          ;Se revisa la bandera para determinar si es un dato o si es un comando
                bclr PORTK,$01          
                bra continue1`
dato1`          bset PORTK,$01
continue1`      bset PORTK,$02
                movb D240uS,CONT_DELAY          ;Se genera el retraso correspondiente
                jsr Delay
                bclr PORTK,$02
                pula
                anda #$0F               ;Cuando se completa la transferencia de la parte alta se envia la parte baja del dato
                lsla
                lsla
                staa PORTK
                brset BANDERAS,$02,dato2`
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
;       Subrutina de retraso, solo debe consumir el tiempo necesario para la comunicacion con la pantalla.               

;Paso de parametros:
;Entrada:
;       CONT_DELAY: Contador que indica que tanto se debe esperar.
;Salida:
;################################################################################################################################################
                loc
Delay:          tst CONT_DELAY 
                bne Delay
                rts

;       CONV_BIN_BCD
;################################################################################################################################################
;Descripcion:
;       Subrutina de llamado a conversion Binaria a BCD, determina si el valor se en binario se puede convertir o si es el correspondiente
;       a apagar la pantalla o mostrar guines.


;Paso de parametros:
;Entrada:
;       BIN1,BIN2: Valores a convertir
;Salida:
;       BCD1,BCD2: Valores convertidos.
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
;       Conversion de 1 valor en binario de 8 bits a BCD

;Paso de parametros:
;Entrada:
;       Registro A: En este registro se encuentra el contenido a convertir
;Salida: 
;       BCD_L: Posicion de memoria donde se retorna el resultado en BCD        
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
;       Conversion de BCD a binario, utilizada para convertir el valor del arreglo del teclado a un valor numerico.

;Paso de parametros:
;Entrada:
;       NUM_ARRAY: Arreglo de numero en bcd producidos por el teclado.
;Salida:
;       V_LIM: Valor en binario resultante de la conversion, corresponde a la velocidad limite.    
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
;       Modo de operación del sensor de velocidad, en este modo se configura la velocidad limite del sensor. Para esto se debe verificar que 
;       el valor ingresado en el teclado sea valido es decir entre el rango de 45 y 90 km/h, si no es valido se borra el valor ingresado, si 
;       sí es valido se muestra en pantalla y se mantiene en memoria.

;Paso de parametros:
;Entrada:
;       V_LIM: Velocidad limite ingresada.
;Salida:
;       BIN1: Valor en binario que se debe mostrar en los displays de 7 segmentos 1 y 2
;       BIN2: Valor en binario que se debe mostrar en los displays de 7 segmentos 3 y 4, en este caso BB para que se apaguen
;################################################################################################################################################
MODO_CONFIG:    loc
                
                brclr (BANDERAS+1),$04,jtarea_teclado`     ;Se revisa array ok
                jsr BCD_BIN
                bclr (BANDERAS+1),$04
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
;       Modo de operación del sensor de velocidad, determinar si la velocidad es mayor a 0, si los es llama a la subrutina de control de la 
;       pantalla, además cuando el vehiculo pasa por el primer sensor muestra el mensaje "Calculando" en pantalla.

;Paso de parametros:
;Entrada:
;       BANDERAS.4: Bandera que indica cuando imprimir el mensaje.
;       VELOC: Velocidad actual del vehiculo.
;Salida:
;################################################################################################################################################
MODO_MEDICION:  loc
                tst VELOC
                beq tstflg`
                jsr PANT_CTRL                       ;Si la velocidad es mayor a 0 se modifican las pantallas
                bra returnMM`
tstflg`         brclr BANDERAS,$04,returnMM`       ;Si la bandera de imprimir Calculando está activa se imprime el mensaje
                bclr PIEH,$08
                ldx #MESS5
                ldy #MESS8  
                jsr CARGAR_LCD
                bclr BANDERAS,$04                  ;Se borra la bandera de imprimir Calculando        
returnMM`       rts

;       MODO_LIBRE
;################################################################################################################################################
;Descripcion:
        ;Modo de operación del sensor, este es un modo donde no se realiza ninguna operación, solo se borran los valores desplegados en las
        ;pantallas de 7 segmentos.

;Paso de parametros:
;Entrada:
;Salida:
;       BIN1,BIN2: Se debe borrar la pantalla de 7seg, para esto se envia BB a estas posiciones de memoria.
;################################################################################################################################################
MODO_LIBRE:     loc                
                movb #$BB,BIN1
                movb #$BB,BIN2
                rts

;       PANT_CTRL
;################################################################################################################################################
;Descripcion:
;       Subrutina encargada de manipular las pantallas cuando se detecta el paso de un vehiculo, si la velocidad se sale de los limites que se 
;       pueden leer se muestran guiones acompañados de la velocidad limite, si es un valor valido pero mayor que la velocidad limite se activa 
;       una alarma en los leds, luego se muestra la velocidad cuando el vehiculo pasa 100 m después del segundo sensor, lo mismo ocurre para una
;       velocidad adentro del limite pero no se activa la alarma de los leds.

;Paso de parametros:
;Entrada:
;       VELOC: Velocidad del vehiculo
;       V_LIM: Velocidad limite, configurada en modo config
;Salida:
;       BIN1: Se configura segun la velocidad del vehiculo, se apaga (BB) cuando ya el vehiculo pasa el sensor
;       BIN2: Se envia el valor de la velocidad limite, se apaga (BB) cuando ya el vehiculo pasa el sensor
;       (BANDERAS+1).4: Bandera de alarma.
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
                bset (BANDERAS+1),$10      ;Levantar Alerta si es mayor a la velocidad limite
                bra next`
outOfBounds`    cmpa #$AA
                beq next`
                movw #1,TICK_EN
                movw #92,TICK_DIS
                movb #$AA,VELOC                            
next`           brset (BANDERAS+1),$08,loadSpeed`  ;Se revisa PANT_FLAG si esta en 1 se carga en pantalla la velocidad y el mensaje correspondiente
                ldaa BIN1               ;En esta rama se decide si enviar el mensaje de espera y devolver las variables a 0
                cmpa #$BB               ;Si el valor de bin1 es diferente de #$BB es porque todavía no se ha enviado el mensaje
                beq returnPC`
                
                ldx #MESS5
                ldy #MESS7
                jsr CARGAR_LCD          ;Se enviar MODO_Medicion y esperando...
                movb #$BB,BIN1
                movb #$BB,BIN2
                clr VELOC
                bclr (BANDERAS+1),$10      ;Borrar Alerta 
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
;       Controla lo que se muestra en los leds en el modo medicion, si la alarma esta activada se encienden en forma secuencial los leds de 3 a 7

;Paso de parametros:
;Entrada:
;       (BANDERAS+1).4: Bandera de alarma.
;Salida:
;       LEDS: Variable que controla el patron de los leds
;################################################################################################################################################                
                loc
PATRON_LEDS:    brset (BANDERAS+1),$10,activateAl`         ;Se revisa si la alarma está activada
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
