;#################################################################
;
;
;               Tarea 5
;               Eduardo Alfaro Gonzalez
;               B50203
;               Pantalla
;               Ultima vez modificado 1/11/19
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
MAX_TCL:        db 2
TECLA:          ds 1
TECLA_IN:       ds 1

CONT_REB:       ds 1
CONT_TCL:       ds 1
PATRON:         ds 1
BANDERAS:       ds 1        ;bit 5 cambio nodo, bit 4 modsel, bit 6 rs


                org $1030
NUM_ARRAY:      ds $10
                org $1040
TECLAS:         db $01,$02,$03,$04,$05,$06,$07,$08,$09,$0B,$00,$0E

                org $1007
CUENTA:         ds 1        ;Cantidad de clavos
ACUMUL:         ds 1        ;Cantidad de bolsas
CPROG:          ds 1        ;Cantidad maxima de clavos por bolsa
VMAX:           db 250      ;valor maximo de contador TIMER_CUENTA que simula los clavos, 250 para lograr 4 Hz
TIMER_CUENTA:   ds 1        ;contador de rti simula clavos
LEDS:           ds 1        ;valor que se envia al puerto B para los leds
BRILLO:         ds 1        ; 0-100 cotrola el brillo de 7 seg
CONT_DIG:       ds 1        ;digito actual de 7seg
CONT_TICKS:     ds 1        ;
BIN1:           ds 1        ;corresponde al valor de DISP1 y DISP2 en binario
BIN2:           ds 1        ;corresponde al valor de DISP4 y DISP3 en binario
DT:             ds 1        ;100 - BRILLO, valor donde se resetea CONT_TICKS
LOW:            ds 1        ;ni idea
BCD1:           ds 1        ;bin 1 en bcd
BCD2:           ds 1        ;bin 2 en bcd
DISP1:          ds 1        ;
DISP2:          ds 1        ;
DISP3:          ds 1        ;
DISP4:          ds 1        ;   
                org $1050
SEGMENT:        db $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F  ;0,1,2,3,4,5,6,7,8,9
                org $1021
CONT_7SEG:      ds 2        ;cuando llega a 5000 se actualizan los valores de DISP
CONT_DELAY:     ds 1        ;
D2mS:           db 100
D240uS:         db 13
D60uS:          db 3
Clear_LCD:      db $01      ;constante igual a comando clear
ADD_L1:         db $80      ;constante igual a Adress linea 1 lcd
ADD_L2:         db $C0      ;constante igual a Adress linea 2 lcd
iniDsp:         db 04,$28,$28,$06,$0C     ;numero de bytes,function set, function set, entry mode, display on off

                org $1070
MESS1:          fcc "MODO CONFIG"
                db FIN
MESS2:          fcc "INGRESE CPROG"
                db FIN
MESS3:          fcc "MODO RUN"
                db FIN
MESS4:          fcc "ACUMUL.-CUENTA"
                db FIN
TEMP:           ds 1
BCD_t:          ds 1




                
                
                org $3E70
                dw INIT_ISR
                org $3E4C
                dw PTH_ISR
                org $3E66
                dw OC4_ISR

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
                movb #$90, TSCR1
                movb #$03, TSCR2
                movb #$10, TIOS
                movb #$01, TCTL1
                movb #$00, TCTL2
                movb #$10, TIE
                ldd TCNT
                addd #60
                std TC4
                movb #$FF,DDRK

;       Puerto H sw

                bset PIEH, $0F          ;habilitar interrupciones PH0
                bset PIFH, $0F
                movb #$17, RTICTL       ; esto lo pone en 1.024 ms
                bset CRGINT, $80        ;habilitar interrupciones rti
                movb #$F0, DDRA
                bset PUCR, $01          ;Super importante habilitar resistencia de pullup
;                bclr RDRIV, $01
;       Puerto E rele
                bset DDRE,$04
                cli



;################################################

;               inicializacion
                lds #$3BFF
                movb #$00,BCD1
                movb #$00,BCD2
                movb #$00,BIN2
                movb #$00,BIN1
                movb #02,LEDS
                movb #0,DISP1
                movb #0,DISP2
                movb #0,DISP3
                movb #0,DISP4
                ;modser=1
                movb #1,CONT_DIG
                movb #0,CONT_TICKS
                movb #50, BRILLO
                movb #00, CPROG
                movb VMAX,TIMER_CUENTA

                movb #$FF, TECLA
                movb #$FF, TECLA_IN
                movb #$00, CONT_TCL
                movb #$00, CONT_REB
                bclr BANDERAS,$07      ;Poner las banderas en 0
                bset BANDERAS,$10      ;Poner la bandera cambio nodo en 1
                ldaa MAX_TCL
                ldx #NUM_ARRAY-1
LoopCLR:        movb #$FF,A,X          ;iniciar el arreglo en FF
                dbne A,LoopCLR


;       Programa main               
mainL:          loc
                tst CPROG
                beq chknodoM1
                ldaa PTIH
                anda #$80
                ldab BANDERAS
                andb #$08
                lslb 
                lslb 
                lslb 
                lslb 
                cba
                beq nochange`
                bset BANDERAS,$10
                cmpa #$80
                beq ph1`
                bclr BANDERAS,$08
                bra nochange`
ph1`            bset BANDERAS,$08

nochange`       brclr BANDERAS,$08,chknodoM0
chknodoM1:      brclr BANDERAS,$10,jmodoconfig`
                bclr BANDERAS,$10
                movb #$02,LEDS
                ldx #MESS1
                ldy #MESS2
                jsr CARGAR_LCD
jmodoconfig`    jsr MODO_CONFIG
                bra returnmain
chknodoM0:      brclr BANDERAS,$10,jmodorun`
                bclr BANDERAS,$10
                movb #$01,LEDS
                ldx #MESS3
                ldy #MESS4
                jsr CARGAR_LCD
jmodorun`       jsr MODO_RUN
              
returnmain:     jsr BIN_BCD
                jmp mainL



                
                
;################################################
;       Subrutinas
;################################################
;       Subrutinas Generales


;       Subrutina Tarea Teclado
TAREA_TECLADO:  loc
                tst CONT_REB
                bne return`
                jsr MUX_TECLADO
                ldaa TECLA
                cmpa #$FF
                beq checkLista`
                brset BANDERAS,$02,checkLeida`        ;revision de bandera Tecla leida
                movb TECLA,TECLA_IN
                bset BANDERAS,$02
                movb #50,CONT_REB                       ;iniciar contador de rebotes
                bra return`
checkLeida`     cmpa TECLA_IN                           ;Comparar Tecla con tecla_in
                bne Diferente`
                bset BANDERAS,$01
                bra return`
Diferente`      movb #$FF,TECLA                         ;Las teclas son invalidas
                movb #$FF,TECLA_IN
                bclr BANDERAS,$03
                bra return`
checkLista`     brclr BANDERAS,$01,return`              ;el numero esta listo
                bclr BANDERAS,$03
                jsr FORMAR_ARRAY
return`         rts

;       Subrutina MUX_TECLADO
MUX_TECLADO:    loc
                ldab #0
                movb #0,PATRON
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
read:           brclr PORTA,$01, treturn`       ;se leen las entradas para encontrar la tecla presionada
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
t_enter`        bset BANDERAS,$04
                movb #$0,CONT_TCL
                bra return`
t_borrar`       decb
                movb #$FF,B,X
                stab CONT_TCL
return`         rts

;       BCD_7SEG
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


;       SendCommand
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


;       BIN_BCD
                loc
BIN_BCD:        ldab #14
                movb #0,BCD_t
                ldaa BIN1   ;inicio con bcd1
                ldx #BCD_t    
                bra loop`
changeBCD`      lsla
                rol 0,X
                ldaa BIN2   ;continua con bcd2
                movb BCD_t,BCD1
                movb #0,BCD_t    
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
                cmpb #7
                beq changeBCD`
                cmpb #$0 
                bne loop`
                lsla
                rol 0,X
                movb BCD_t,BCD2                             
                rts

;       BCD_BIN
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
                stab CPROG 
                bra return`
wrong`          movb #$FF,NUM_ARRAY
                movb #$0,CPROG
return`         rts

;       MODO_CONFIG
MODO_CONFIG:    loc
                bclr PIEH,$03
                brclr BANDERAS,$04,jtarea_teclado`
                jsr BCD_BIN
                bclr BANDERAS,$04
                ldaa CPROG
                cmpa #96
                bgt resetCPROG`
                cmpa #12
                blt resetCPROG`
                movb CPROG,BIN1
                movb #0,BIN2
                bra returnCofig
jtarea_teclado` jsr TAREA_TECLADO
                bra returnCofig
resetCPROG`     movb #0,CPROG
returnCofig:    rts

;       MODO_RUN
MODO_RUN:       bset PIEH,$03
                ldaa CPROG
                cmpa CUENTA
                beq returnRUN`
                tst TIMER_CUENTA
                bne returnRUN`
                movb VMAX,TIMER_CUENTA
                inc CUENTA
                cmpa CUENTA
                bne returnRUN`
                inc ACUMUL
                bset PORTE,$04
                ldaa ACUMUL
                cmpa #100
                bne returnRUN`
                movb #0,ACUMUL
returnRUN`      movb CUENTA,BIN1
                movb ACUMUL,BIN2                            
                rts





;################################################
;################################################
;################################################
;       Subrutinas de proposito especifico

;       Subrutinas PH
;        subrutina de PHO

                loc
PTH_ISR:        brset PIFH,$01,PH0_ISR 
                brset PIFH,$02,PH1_ISR
                brset PIFH,$04,PH2_ISR
                brset PIFH,$08,PH3_ISR

;       subrutina PH1
PH0_ISR:        bset PIFH, $01          
                bclr PORTE,$04
                tst CONT_REB
                bne returnPH
                movb #0,CUENTA
                movb #50,CONT_REB
                bra returnPH

;       subrutina PH1
PH1_ISR:        bset PIFH, $02          
                bclr PORTE,$04
                tst CONT_REB
                bne returnPH
                movb #0,ACUMUL
                movb #50,CONT_REB
returnPH:       rti
;       subrutina PH2                
PH2_ISR:        bset PIFH, $04
                ldaa BRILLO
                beq returnPH
                suba #5
                staa BRILLO
                bra returnPH
;       subrutina PH3
PH3_ISR:        bset PIFH, $08
                ldaa BRILLO
                cmpa #100
                beq returnPH
                adda #5
                staa BRILLO
                bra returnPH                



;       subrutina de rti
                loc
INIT_ISR:       bset CRGFLG, $80
                tst CONT_REB
                beq chktimercnt
                dec CONT_REB
chktimercnt:    tst TIMER_CUENTA
                beq return`
                dec TIMER_CUENTA
return`         rti


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;   Subrutina OC4
                loc
OC4_ISR:        ldaa CONT_TICKS
                ldab #100
                subb BRILLO
                cba
                beq apagar`
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
                bne part2`
                movb #1,CONT_DIG
                bra part2`
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
                movb DISP2, PORTB
                bset PTJ, $02
                bra  incticks`
dig3`           cmpa #3
                bne dig4`
                bclr PTP, $02
                movb DISP3, PORTB
                bset PTJ, $02
                bra  incticks`
dig4`           cmpa #4
                bne digleds`
                bclr PTP, $01
                movb DISP4, PORTB
                bset PTJ, $02
                bra  incticks`
digleds`        movb LEDS, PORTB
                bclr PTJ, $02
                inc CONT_TICKS


part2`          tst CONT_DELAY
                beq tst7seg`
                dec CONT_DELAY
tst7seg`        ldx CONT_7SEG
                beq JBCD_7SEG`
                inx
                stx CONT_7SEG
returnOC4       ldd TCNT
                addd #60
                std TC4
                rti
JBCD_7SEG`      jsr BCD_7SEG
                bra returnOC4