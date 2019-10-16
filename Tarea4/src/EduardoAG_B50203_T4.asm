;#################################################################
;
;
;               Tarea 4
;               Eduardo Alfaro Gonzalez
;               B50203
;               Lectura teclado matricial
;               Ultima vez modificado 15/10/19
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
MAX_TCL:        db 5
TECLA:          ds 1
TECLA_IN:       ds 1
CONT_REB:       ds 1
CONT_TCL:       ds 1
PATRON:         ds 1
BANDERAS:       ds 1


NUM_ARRAY:      ds 6
TECLAS:         db $01,$02,$03,$04,$05,$06,$07,$08,$09,$0B,$00,$0E


                org $1100
MESS1:          fcc "Prueba"
                db CR,LF,CR,LF,FIN
                
                
                org $3E70
                dw INIT_ISR
                org $3E4C
                dw PTH0_ISR

;################################################
;       Programa principal
                org $2000

;################################################
;       Definicion de hardware

                bset PIEH, $01          ;habilitar interrupciones PH0
                bset PIFH, $01
                movb #$49, RTICTL       ;FIXME, esto lo pone en 9.26 ms
                bset CRGINT, $80        ;habilitar interrupciones rti
                movb #$F0, DDRA
		cli



;################################################
;       Programa

                lds #$3BFF
                movb #$FF, TECLA
                movb #$FF, TECLA_IN
                movb #$00, CONT_REB
                bclr BANDERAS,$07      ;Poner las banderas en 0
                ldaa MAX_TCL
                ldx #NUM_ARRAY
LoopCLR:        movb #$0,A,X
                dbne A,LoopCLR
mainL:          brset BANDERAS,$04,mainL
                jsr TAREA_TECLADO
                bra mainL
;################################################
;       Subrutinas
;################################################
;       Subrutinas Generales


;       Subrutina Tarea Teclado
TAREA_TECLADO:  ldx #$0
                ldd #MESS1
                jsr [printf,X]
                rts
;       Subrutina formar array

FORMAR_ARRAY:

                rts

;################################################
;       Subrutinas de proposito especifico


;        subrutina de PHO
                org $2100
PTH0_ISR:       bset PIFH, $01
                bset BANDERAS, $04
;FIXMe
returnPH0:      rti

;       subrutina de rti
                loc
INIT_ISR:       bset CRGFLG, $80
                tst CONT_REB
                beq return`
                dec CONT_REB
return`         rti





