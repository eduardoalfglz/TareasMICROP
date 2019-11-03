;################################################
;               ED
;               Ejemplo int tiempo real
;               Mod 4.10.19
;
;################################################
;
#include registers.inc
;################################################
;       Rellenar vectores de interrupcion

;################################################
;       Estructuras de datos
                org $1000
LEDS            ds 1
CONT_DIG        ds 1
CONT_OC        ds 2

                org $3E66
                dw OC4_ISR


;################################################
;       Programa principal
                org $2000

;################################################
;       Definicion de hardware
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

MLEDS:          movb #$FF, DDRB
                bset DDRJ, $02
                bset PTJ, $02
                movb #$0F, DDRP
                movb #$07, PTP
                movb #$01, CONT_DIG
                cli



;################################################
;       Programa

                lds #$3BFF

                movb #$01,LEDS
                movw #50000, CONT_OC
                bra *
;################################################
;       Subrutinas


;################################################
;       Subrutinas Generales


;################################################
;       Subrutinas de proposito especifico
OC4_ISR:        ldx CONT_OC
                dex
                stx CONT_OC
                bne return
Loop:           movb LEDS, PORTB
                movw #100, CONT_OC
                lsl LEDS
                bne return
                movb #$01,LEDS
return:         ldd TCNT
                addd #60
                std TC4
                rti
                
                