;**************************************
;       Mover si es multiplo de 4
;       Eduardo Alfaro
;       Fecha Septiembre
;       Ultima vez modificado 23/9/19
;       Tarea 2
;
;
;*************************************
                    org $1000
L:                  ds $1
Cont4               ds $1

                    org $1100
Datos               ds 255

                    org $1200
Div4                ds 255



                    org $1300
div4Prog:       movb #0,Cont4   ;Reinicio del contador
		ldx #Datos
                dex
                ldy #Div4
                ldaa L
                ldab #0
MainLoop:       ror A,X
                blo NotMul2             ;Detectar si es multiplo de 2
                ror A,X
                bhs Mult4
NotMul4:        rol A,X
NotMul2:        rol A,X              ;Si no es multiplo de 4 se devuelve al numero original
                dbne A, MainLoop       ; y se decrementa el contador
                bra Fin
Mult4:          rol A,X                 ;Si es multiplo de 4 se devuelve al numero original
                rol A,X                 ;Se hace dos veces en el codigo porque se necesita el carry para el branch
                movb A,X,B,Y            ;Se mueve al arreglo de multiplos de 4
                incb
                inc Cont4               ;Se incrementa el contador de multiplos de 4
                dbne A,MainLoop
Fin:            bra Fin
                