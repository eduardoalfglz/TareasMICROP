;**************************************
;       Aplicar mascaras y encontrar negativos
;       Eduardo Alfaro
;       Fecha Septiembre
;       Ultima vez modificado 23/9/19
;       Tarea 2
;
;
;*************************************
                    org $1000
TempM:              ds $2
TempN:              ds $2
                    org $1050
Datos:              db $63,$75,$63,$8,$64,$7,$56,$29,$71,$28,$80,$7,$41,$59
                    db $8,$5,$59,$93,$71,$7,$82,$68,$58,$34,$98,$2,$35,$87
                    db $51,$54,$23,$93,$47,$88,$0,$60,$22,$64,$6,$79,$68,$15
                    db $20,$17,$80,$38,$93,$80,$27,$36,$4,$41,$31,$25,$91,$FF
                    org $1150
Mascaras:           db $8,$5,$59,$93,$71,$7,$82,$68,$58,$34,$98,$2,$35,$87
                    db $63,$75,$63,$8,$64,$7,$56,$29,$71,$28,$80,$7,$41,$59
                    db $20,$17,$80,$38,$93,$80,$27,$36,$4,$41,$31,$25,$91,$30
                    db $51,$54,$23,$93,$47,$88,$0,$60,$22,$64,$6,$79,$68,$FE

                    org $1300
Negat               ds 1000

                    org $1100



                    org $2000
Negat_T2      	ldy #Negat
                sty TempN      ;Esto se podria evitar usando direccionamiento indexado indirecto, no se hace por enunciado
                ldy #Mascaras
                ldx #Datos
LoopIni         ldaa #$FF        ;Encontrar el ultimo valor de Datos
                cmpa 1,X+       ;En el ultimo se debe decrementar para volver al deseado
                bne LoopIni
                dex
MainLoop:       ldaa 0,Y
                eora 1,X-
                cmpa #0
                bge chk_Fin
                sty TempM        ;El numero es negativo por lo tanto se debe mover a negat
                ldy TempN
                staa 1,Y+
                sty TempN
                ldy TempM
chk_Fin:        ldaa #$FE
                cmpa 1,Y+
                beq Fin
                cpx #Datos
                bne MainLoop
Fin:            bra Fin
                
                
