;**************************************
;       Ordenar Array Menor a Mayor
;       Eduardo Alfaro
;       Fecha Septiembre
;       Ultima vez modificado 23/9/19
;       Tarea 2
;
;
;*************************************

                    org $1000
Cant:               db 200  ;tiempo de ensamblado
Temp                ds $1   ;Variable para guardar J temporalmente


                    org $1100
Ordenar:            db $63,$75,$63,$8,$64,$7,$56,$29,$71,$28,$80,$7,$41,$59
		    db $8,$5,$59,$93,$71,$7,$82,$68,$58,$34,$98,$2,$35,$87
		    db $51,$54,$23,$93,$47,$88,$0,$60,$22,$64,$6,$79,$68,$15
		    db $20,$17,$80,$38,$93,$80,$27,$36,$4,$41,$31,$25,$91,$1
                    org $1200
Ordenados:          ds 200


                    org $1500
Ordenar_Ar      ldx #Ordenar
                ldy #Ordenados
Loop:           ldaa #1
LoopInt:        ldab 0,X
                cmpb A,X
                blt Lthan
GtEq:           beq Eq
                movb 0,X,Temp           ;Si el numero es menor intercambiarlos
                movb A,X,0,X
                movb Temp,A,X
                bra LoopInt
Eq:             dec Cant
                inx                     ;Si son iguales mover X para saltarse el dato
                bra ChkFin
Lthan:          inca                    ;Si el numero es mayor pasar al siguiente
                cmpa Cant
                bne LoopInt
                movb 1,X+,1,Y+          ;Mover los datos a ordenados
                dec Cant
ChkFin:         ldab #1
                cmpb Cant               ;Revisar si ya se pasaron todos los datos
                bne Loop
                movb 0,X,0,Y
Fin:            bra Fin