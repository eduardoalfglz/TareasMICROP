;#################################################################################################################
;
;
;               Tarea 6
;               Eduardo Alfaro Gonzalez
;               B50203
;               Comunicacion serial y conversion AD
;               Ultima vez modificado 16/11/19
;
;
;#################################################################################################################
#include registers.inc



;#################################################################################################################
;               Definicion de estructuras de datos

                org $1000
CR:             equ $0D
LF:             equ $0A
FIN:            equ $FF
BS:             equ $08

                org $1010

Nivel_PROM:     ds 2
NIVEL:          ds 1
VOLUMEN:        ds 2
CONT_OC:        ds 2

Pointer1:       ds 2
Pointer2:       ds 2
Pointer3:       ds 2
Flags:          ds 1        ;0: la alarma de nivel bajo esta encendida, 1: la alarma de nivel alto esta encendida



                org $1070
MESS1:          db CR
                db BS
                db CR
                db BS
                db CR
                db BS
                db CR
                db BS
                db CR
                fcc "       Medicion de Volumen "
                db LF
                db CR
                fcc "Volumen Actual: "
VOL_C:          ds 1
VOL_D:          ds 1
VOL_U:          ds 1
                db LF
                db CR
                fcc "                               "
                db CR
                db FIN
MESS2:          fcc "Alarma: El nivel esta bajo"
                db CR
                db LF                
                db FIN
MESS3:          fcc "Tanque lleno, Bomba Apagada"                
                db CR
                db LF                
                db FIN





                
                

                org $3E4C
                dw PTH_ISR
                org $3E64
                dw OC5_ISR
                org $3E52
                dw ATD0_ISR
                org $3E54
                dw SCI1_ISR

;################################################################################################
;       Programa principal
                org $2000

;################################################################################################
;       Definicion de hardware
;       SCI1
                movw #39, SC1BDH      ;38400 BaudRate
                movb #$12, SC1CR1      ;Habilitar paridad y configurar paridad par
                movb #08, SC1CR2
;       Output compare
                movb #$90, TSCR1
                movb #$06, TSCR2
                movb #$20, TIOS
                movb #$08, TCTL1
                movb #$00, TCTL2
                movb #$20, TIE
                ldd TCNT
                addd #62500        
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

;################################################################################################

;               inicializacion
                lds #$3BFF
                cli
                movb #6,CONT_OC

;       Programa main               
main:           loc
                jsr Calculo
                nop
                bra main
                
                
                
;################################################################################################
;       Subrutinas
;################################################################################################
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
                ;stab PORTB          ;FIXME: Para pruebas                 
                ldaa #20
                mul
                std VOLUMEN
                ldx #100            ;Separar centenas decenas y unidades para imprimirlos en el mensaje
                idiv                ;En X centenas, en D residuo
                pshd
                tfr X,D
                addb #$30
                stab VOL_C
                puld
                ldx #10
                idiv 
                addb #$30
                stab VOL_U                       
                tfr X,D
                addb #$30
                stab VOL_D
                        
                rts

;################################################################################################
;################################################################################################
;################################################################################################
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
                movb #6,CONT_OC     ; Reset contador
                ldaa TCTL1
                eora #$04
                staa TCTL1                
                movb #$C8,SC1CR2
                ldx #MESS1
                ldaa SC1SR1
                movw #MESS1,Pointer1         ;apuntar el puntero al primer mensaje 
                movw #MESS2,Pointer2         ;apuntar el puntero2 al segundo mensaje 
                movw #MESS3,Pointer3         ;apuntar el puntero3 al tercer mensaje 
returnOC5       dec CONT_OC
                ldd TCNT
                addd #62500
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
                ldab NIVEL
                ldaa SC1SR1
                bset SC1SR1,$80
                stab PORTB          ;Fixme: Para pruebas
                ldx Pointer1
                ldaa 0,X
                cmpa #FIN
                beq CheckAlarm11
                movb 1,X+,SC1DRL
                stx Pointer1
                bra returnSC1
CheckAlarm11:   brclr Flags,$01, CheckAlarm12                                
                cmpb #7             ;30 por ciento
                ble pAlarm1         ;Salta a imprimir la alarma 1
                bclr Flags,$01      ;Apaga la bandera de alarma                    
CheckAlarm12:   cmpb #4             ;15 por ciento
                bgt CheckAlarm2
                bset Flags,$01
pAlarm1:        bset PORTE,#$04
                ldx Pointer2
                ldaa 0,X          ;Carga en A el byte del mensaje
                cmpa #FIN
                beq EndSCI1         
                movb 1,X+,SC1DRL                
                stx Pointer2
                bra returnSC1                    ;Activar alarma de nivel bajo
CheckAlarm2:    cmpb #23
                blt EndSCI1                         
pAlarm2:        bclr PORTE,#$04
                ldx Pointer3
                ldaa 0,X          ;Carga en A el byte del mensaje
                cmpa #FIN
                beq EndSCI1         
                movb 1,X+,SC1DRL
                stx Pointer3
                bra returnSC1
EndSCI1:        movb #$08,SC1CR2        
returnSC1:      rti
