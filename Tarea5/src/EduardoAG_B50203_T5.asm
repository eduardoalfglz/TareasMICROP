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
BANDERAS:       ds 1


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


;FIXME faltan, pero estoy cansado



                
                
                org $3E70
                dw INIT_ISR
                org $3E4C
                dw PTH0_ISR
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
                addd #600
                std TC4



                bset PIEH, $01          ;habilitar interrupciones PH0
                bset PIFH, $01
                movb #$49, RTICTL       ;FIXME, esto lo pone en 9.26 ms
                bset CRGINT, $80        ;habilitar interrupciones rti
                movb #$F0, DDRA
                bset PUCR, $01          ;Super importante habilitar resistencia de pullup
;                bclr RDRIV, $01
                cli



;################################################

;               inicializacion
                lds #$3BFF
                movb #$18,BCD1
                movb #$45,BCD2
                movb #02,LEDS
                movb #0,DISP1
                movb #0,DISP2
                movb #0,DISP3
                movb #0,DISP4
                ;modser=1
                movb #1,CONT_DIG
                movb #0,CONT_TICKS
                movb #50, BRILLO

                movb #$FF, TECLA
                movb #$FF, TECLA_IN
                movb #$00, CONT_TCL
                movb #$00, CONT_REB
                bclr BANDERAS,$07      ;Poner las banderas en 0
                ldaa MAX_TCL
                ldx #NUM_ARRAY-1
LoopCLR:        movb #$FF,A,X          ;iniciar el arreglo en FF
                dbne A,LoopCLR


;       Programa                
mainL:          brset BANDERAS,$04,mainL
                jsr TAREA_TECLADO
                bra mainL
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
                movb #$64,CONT_REB                       ;iniciar contador de rebotes
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





;################################################
;################################################
;################################################
;       Subrutinas de proposito especifico


;        subrutina de PHO

                loc
PTH0_ISR:       bset PIFH, $01          
                brclr BANDERAS,$04,returnPH0        ;Si la bandera de array_ok no esta en alto ignorar subrutina
                bclr BANDERAS, $04                  ;limpiar la bandera
                ldy #NUM_ARRAY
                ldaa MAX_TCL
loop`           ldab 1,Y+
                cmpb #$FF                           ;primera condicion de parada
                beq returnPH0
                movb #$FF,-1,Y
                dbne A,loop`

returnPH0:      rti

;       subrutina de rti
                loc
INIT_ISR:       bset CRGFLG, $80
                tst CONT_REB
                beq return`
                dec CONT_REB
return`         rti


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;   Subrutina OC4
                loc
OC4_ISR:        ldaa CONT_TICKS
                beq check_digit`
                ldab #100
                subb BRILLO
                cba
                beq apagar`
                cmpa #100
                beq changeDigit`
incticks`       inc CONT_TICKS
                jmp part2`
;Apagar
apagar`         movb #$FF,PTP
                movb #$0, PORTB
                bra incticks`
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