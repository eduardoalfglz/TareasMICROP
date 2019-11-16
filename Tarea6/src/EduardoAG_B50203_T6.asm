;#################################################################
;
;
;               Tarea 6
;               Eduardo Alfaro Gonzalez
;               B50203
;               Comunicacion serial y conversion AD
;               Ultima vez modificado 14/11/19
;
;
;#################################################################
#include registers.inc



;#################################################################
;               Definicion de estructuras de datos


CR:             equ $0D
LF:             equ $0A
FIN:            equ $0

                org $1010

Nivel_PROM:     ds 2
NIVEL:          ds 1
VOLUMEN:        ds 1
CONT_OC:        ds 2
VOL_C:          ds 1
VOL_D:          ds 1
VOL_U:          ds 1

                org $1070
MESS1:          fcc "MODO CONFIG"
                db FIN
MESS2:          fcc "INGRESE CPROG"
                db FIN
MESS3:          fcc "MODO RUN"
                db FIN
MESS4:          fcc "ACUMUL.-CUENTA"
                db FIN





                
                

                org $3E4C
                dw PTH_ISR
                org $3E64
                dw OC5_ISR
                org $3E52
                dw ATD0_ISR
                org $3E54
                dw SCI1_ISR

;################################################
;       Programa principal
                org $2000

;################################################
;       Definicion de hardware

;       Output compare
                movb #$90, TSCR1
                movb #$06, TSCR2
                movb #$20, TIOS
                movb #$04, TCTL1
                movb #$00, TCTL2
                movb #$20, TIE
                ldd TCNT
                addd #1500        ;FIXME
                std TC5
                

;       ATD0
                movb #$C2, ATD0CTL2
                ldab #200
loopIATD:       dbne B,loopIATD         ;loop de retardo para encender el convertidor
                movb #$30, ATD0CTL3
                movb #$10, ATD0CTL4
                movb #$87, ATD0CTL5
                
;       Puerto H sw

                bset PIEH, $01          ;habilitar interrupciones PH 
                bset PIFH, $01          ;Solo para pruebas

;       Puerto E rele
                bset DDRE,$04
                

;       LEDS for testing
                movb #$FF, DDRB
                bset DDRJ, $02
                bclr PTJ, $02
                movb #$0F, DDRP
                movb #$0F, PTP

;################################################

;               inicializacion
                lds #$3BFF
                cli
                movb #250,CONT_OC

;       Programa main               
main:           loc
                jsr Calculo
                nop
                bra main
                
                
                
;################################################
;       Subrutinas
;################################################
;       Subrutinas Generales
;       Subrutina calculo
Calculo:        loc
                ldd Nivel_PROM                
                ldy #30
                ldx #1024
                emul
                ediv                
                tfr Y,D
                stab NIVEL                
                ldaa #20
                mul
                std VOLUMEN
                ldx #100            ;Separar centenas decenas y unidades para imprimirlos en el mensaje
                idiv                ;En X centenas, en D residuo
                pshd
                tfr X,D
                stab VOL_C
                puld
                ldx #10
                idiv 
                stab VOL_U                       
                tfr X,D
                stab VOL_D
                stab PORTB          ;FIXME: Para pruebas         
                rts

;################################################
;################################################
;################################################
;       Subrutinas de proposito especifico

;       Subrutinas PH

;       subrutina PH0
PTH_ISR:        bset PIFH, $01        ;Solo se usa para prueba de break points                  
returnPH:       rti



;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;   Subrutina OC5
                loc
OC5_ISR:        tst CONT_OC
                bne returnOC5
                movb #250,CONT_OC
returnOC5       dec CONT_OC
                ldd TCNT
                addd #1500
                std TC5
                rti

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;   Subrutina ATD0
ATD0_ISR:       loc
                ldx #6
                ldd ADR00H
                addd ADR01H
                addd ADR02H
                addd ADR03H
                addd ADR04H
                addd ADR05H
                idiv 
                stx Nivel_PROM      ;Guardar el promedio
                ;tfr X,D             ;FIXME: para pruebas
                ;stab PORTB          ;FIXME: Para pruebas
                movb #$87, ATD0CTL5
                rti
;   Subrutina SCI1
SCI1_ISR:       loc
                rti
