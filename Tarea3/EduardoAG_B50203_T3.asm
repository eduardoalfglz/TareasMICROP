;#################################################################
;
;
;               Tarea 3
;               Eduardo Alfaro Gonzalez
;               B50203
;               Calculo de Raices cuadradas
;               Ultima vez modificado 1/10/19
;
;
;#################################################################




;#################################################################
;               Definicion de estructuras de datos
PRINTF:         equ $EE88
GETCHAR:        equ $EE84
PUTCHAR:        equ $EE86
CR:             equ $0D
LF:             equ $0A
FIN:            equ $0

                org $1000
LONG:           db 15
CANT:           ds 1
CONT:           ds 1
CurENTERO:      ds 2    ;Posicion actual de entero para el direccionamiento de la tabla
CalcRoot:       ds 2    ;Variable temporal para el calculo de raiz
ResDiv:         ds 2    ;Resultado de div
                org $1150
MESS1:          fcc "Ingrese el valor de cant Entre 1 y 99"
                db CR,LF,FIN
MESS2:          fcc "Cantidad de valores encontrados %i"
                db CR,LF
MESS3:          fcc "Entero: "
                db FIN
MESS4:          db CR,LF
                fcc "La cantidad ingresada es: %i"
                db CR,LF,FIN
MESS5:          fcc "%i,"
                db LF,FIN
                
                org $1020
DATOS:          db 4,9,18,4,27,63,12,32,36,15,144,100,56,49
                org $1040
CUAD:           db 1,4,9,16,25,36,49,64,81,100,121,144,169,196,225
                org $1100
ENTERO:         ds 100


;#################################################################
;               Inicio de programa principal
                org $2000
                lds #$3BFF              ;Definicion del Stack
                ldd #MESS1              ;Imprimir el primer mensaje
                ldx #0
                jsr [PRINTF,X]
                jsr Leer_Cant           ;Salto a Leer Cantidad
                jsr Buscar
                jsr Print_Res
                bra *
                





;#################################################################
;               Subrutina Leer_Cant
Leer_Cant:      ldaa #1
                psha
                deca
                staa CANT
                staa CONT
                ldx #$0000
                loc
Loop`           jsr [GETCHAR,X]
                ldaa #48
                cba
                bgt Loop`              ;El numero es menor que 0
                ldaa #57
                cba
                blt Loop`              ;El numero es mayor que 9
                jsr [PUTCHAR,X]
                subb #48
                pula
                dbne A,SaveRES`           ;si no es 1 hace branch
                ldaa #10
                psha                    ;Guarda un numero diferente de 1 en el stack
                mul
                stab CANT
                bra Loop`
SaveRES`        addb CANT
                ldaa #0
                cba
                beq Leer_Cant           ;En caso de que se introduzcan dos 0s
                stab CANT
                pshd
                ldab #LF
                jsr [PUTCHAR,X]
                ldd #MESS4
                jsr [PRINTF,X]
                leas 2,SP
                rts


;#################################################################
;               Subrutina Bucar
                loc
Buscar:         ldaa #0
                movw #ENTERO,CurENTERO  ;Crear contador de tabla
Loop1`          ldx #DATOS
                ldy #CUAD            ;Cuad más el numero maximo de datos
Loop2`          ldab A,X
                cmpb 0,Y
                bne FindCuad`           ;Revisa si el numero está en la tabla
                psha
                ldaa A,X
                psha
                jsr RAIZ                ;Despues de respaldo en stack salta a raiz
                pula                    ;obtiene resultado
                ldx #0
                staa [#CurENTERO,X]     ;Guarda el resultado
                inc CurENTERO+1
                pula                    ;recupera el valor de R1
                inc CONT
chk_FIN`        dec CANT
                ldab CANT               ;Check si ya logro la cantidad solicitada
                bne chk2`
                bra return`
chk2`           inca
                cmpa LONG
                bne Loop1`          ;Check si ya no hay datos
return`         rts
FindCuad`       cpy #CUAD+15
                bge chk2`
InTable`        iny
                bra Loop2`
                

;#################################################################
;               Subrutina Raiz
                loc
RAIZ:           puly                    ;Save return location
                pulb                    ;Pull number to calc root
                ldaa #0
                std CalcRoot
                tfr D,X
Loop`           pshx                    ;Save b
                idiv                    ;j=x/b d=res
                puld                    ;get b
                stx ResDiv
                cpd ResDiv
                beq CheckFin`
                abx
                tfr X,D                 ;transfer para hacer lsr
                lsrd
                tfr D,X
                ldd CalcRoot
                bra Loop`
CheckFin`       pshb
                pshy
                rts

;#################################################################
;               Subrutina Print_Result
Print_Res:      loc
                ldab CONT
                ldaa #0
                pshd
                ldd #MESS2
                ldx #0
                jsr [PRINTF,X]
                leas 2,SP
                ldy #ENTERO
LoopF`          ldx #0
                ldab 1,Y+
                pshy
                pshb
                ldab #0
                pshb
                ldd #MESS5
                jsr [PRINTF,X]
                leas 2,SP
                puly
                dec CONT
                ldaa CONT
                cmpa #0
                bne LoopF`
                rts


                