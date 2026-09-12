; Oh Mummy (Amsoft, 1984, Amstrad CPC) -- motor del juego (MUMMY1.BIN)
; Ingenieria inversa: Rafael Eduardo Martin Candial (raemca@hotmail.com)
; Ver ../FINDINGS.md para el diario de reconstruccion sesion a sesion.
;
; Direccion de carga real: $6000 -- confirmada en el propio cargador
; BASIC (src/load_disk/mummy_bas.bas, linea 570-580: LOAD"!mummy1",&6000
; : CALL &6000). Longitud real: 13190 bytes ($3386).
;
; Estado (Sesion 6): el bloque $6000-$6400 (1025 bytes) esta
; desensamblado y verificado -- reconstruccion MECANICA de primera
; pasada, sigue sin nombres semanticos (llamadas a $78xx/$7Dxx/$7Exx/
; $7Bxx sin resolver todavia en ese tramo concreto). Mas alla de
; $6400, siguiendo el hilo de llamadas real (no linealmente, ver
; prompts/sesion_03..06_*.md), se han identificado y RECONSTRUIDO con
; nombre funcional 26 rutinas (1539 bytes) repartidas en 2 bloques
; contiguos -- cada una con su comentario de hipotesis y nivel de
; confianza, NINGUNA verificada en emulador todavia (nombres
; provisionales, no definitivos -- ver FINDINGS.md Sesiones 3-6). El
; resto (10626 bytes) sigue sin analizar, incluido tal cual con varios
; INCBIN (con offset/longitud, para dejar hueco a las rutinas ya
; reconstruidas) -- se ira reduciendo sesion a sesion, igual que en
; los proyectos hermanos.

; Rutinas del "fixed jumpblock" del firmware del CPC ($BB00-$BD5D,
; direcciones fijas en RAM) llamadas desde este tramo -- identificadas
; contra el manual oficial (AMSTRAD CPC464/664/6128 FIRMWARE, seccion
; 14.1). Ver FINDINGS.md Sesion 3 para el detalle de cada una.
FIRM_KM_READ_CHAR       EQU $BB09   ; Test si hay caracter de teclado disponible
FIRM_KM_TEST_KEY        EQU $BB1E   ; Test si una tecla concreta esta pulsada
FIRM_TXT_OUTPUT         EQU $BB5A   ; Sacar caracter/codigo de control al Text VDU
FIRM_TXT_WIN_ENABLE     EQU $BB66   ; Fijar tamano de la ventana de texto actual
FIRM_TXT_CLEAR_WINDOW   EQU $BB6C   ; Borrar la ventana de texto actual
FIRM_TXT_SET_CURSOR     EQU $BB75   ; Fijar posicion del cursor de texto
FIRM_TXT_SET_PEN        EQU $BB90   ; Fijar tinta de trazo (pen) para texto
FIRM_TXT_SET_PAPER      EQU $BB96   ; Fijar tinta de fondo para texto
FIRM_SCR_DOT_POSITION   EQU $BC1D   ; Convertir coordenadas base a direccion de pantalla
FIRM_SOUND_RESET        EQU $BCA7   ; Reset del gestor de sonido (silencia PSG, vacia colas)
FIRM_SOUND_AMPL_ENV     EQU $BCBC   ; Definir una envolvente de amplitud
FIRM_SOUND_TONE_ENV     EQU $BCBF   ; Definir una envolvente de tono
FIRM_KL_TIME_PLEASE     EQU $BD0D   ; Leer el contador de tiempo transcurrido
FIRM_KM_CHAR_RETURN     EQU $BB0C   ; Devolver un caracter al buffer de teclado
FIRM_SOUND_QUEUE        EQU $BCAA   ; Anadir un sonido a una cola de sonido

; Codigos de control del Text VDU (valores 0-31 enviados a FIRM_TXT_OUTPUT):
; NO se imprimen como caracter, se interpretan como ordenes (con 0 o mas
; parametros, que SI son bytes de datos literales, no mas codigos).
; Tabla oficial completa: AMSTRAD CPC464/664/6128 FIRMWARE, Appendix VII
; "Text VDU Control Codes" -- cpctech.cpcwiki.de/docs/manual/s968ap07.pdf.
; Usada para reescribir en Sesion 21 los bloques de texto con codigos de
; control mezclados (antes en hexadecimal en bruto) como los habria
; escrito el programador original: texto entre comillas + estas
; constantes con nombre. Ver FINDINGS.md Sesion 21.
CTRL_TXT_CURSOR_LEGAL           EQU 0   ; NUL, 0 param: fuerza el cursor a posicion legal (firmware v1.1)
CTRL_TXT_IMPRIMIR_CHAR          EQU 1   ; SOH, 1 param: imprime literalmente el caracter dado (permite imprimir 0-31)
CTRL_TXT_CURSOR_OFF             EQU 2   ; STX, 0 param: desactiva el cursor parpadeante
CTRL_TXT_CURSOR_ON              EQU 3   ; ETX, 0 param: activa el cursor parpadeante
CTRL_TXT_MODO_PANTALLA          EQU 4   ; EOT, 1 param: fija el modo de pantalla (parametro MOD 4)
CTRL_TXT_IMPRIMIR_GRAFICO       EQU 5   ; ENQ, 1 param: imprime el caracter via Graphics VDU
CTRL_TXT_VDU_ON                 EQU 6   ; ACK, 0 param: activa el VDU
CTRL_TXT_BEEP                   EQU 7   ; BEL, 0 param: pitido corto, vacia las colas de sonido
CTRL_TXT_CURSOR_IZQUIERDA       EQU 8   ; BS,  0 param: cursor legal, mueve una posicion a la izquierda
CTRL_TXT_CURSOR_DERECHA         EQU 9   ; TAB, 0 param: cursor legal, mueve una posicion a la derecha
CTRL_TXT_CURSOR_ABAJO           EQU 10  ; LF,  0 param: cursor legal, mueve una linea abajo
CTRL_TXT_CURSOR_ARRIBA          EQU 11  ; VT,  0 param: cursor legal, mueve una linea arriba
CTRL_TXT_BORRAR_VENTANA         EQU 12  ; FF,  0 param: borra la ventana actual y cursor a esquina superior izq.
CTRL_TXT_RETORNO_CARRO          EQU 13  ; CR,  0 param: cursor legal, mueve al borde izquierdo de la linea actual
CTRL_TXT_FIJAR_PAPEL            EQU 14  ; SO,  1 param: tinta de papel (fondo), parametro MOD 16
CTRL_TXT_FIJAR_TINTA            EQU 15  ; SI,  1 param: tinta de trazo (pen), parametro MOD 16
CTRL_TXT_BORRAR_CASILLA         EQU 16  ; DLE, 0 param: cursor legal, borra la casilla actual (tinta de papel)
CTRL_TXT_BORRAR_INICIO_LINEA    EQU 17  ; DC1, 0 param: borra desde el borde izq. de la ventana hasta el cursor
CTRL_TXT_BORRAR_FIN_LINEA       EQU 18  ; DC2, 0 param: borra desde el cursor hasta el borde derecho de la ventana
CTRL_TXT_BORRAR_INICIO_VENTANA  EQU 19  ; DC3, 0 param: borra desde el inicio de la ventana hasta el cursor
CTRL_TXT_BORRAR_FIN_VENTANA     EQU 20  ; DC4, 0 param: borra desde el cursor hasta el final de la ventana
CTRL_TXT_VDU_OFF                EQU 21  ; NAK, 0 param: desactiva el VDU
CTRL_TXT_MODO_ESCRITURA         EQU 22  ; SYN, 1 param: modo de escritura de caracter (0 opaco, 1 transparente)
CTRL_TXT_MODO_GRAFICO           EQU 23  ; ETB, 1 param: modo de escritura de la Graphics VDU (MOD 4)
CTRL_TXT_INTERCAMBIAR_TINTAS    EQU 24  ; CAN, 0 param: intercambia la tinta de trazo y la de papel
CTRL_TXT_DEFINIR_MATRIZ_CARACTER EQU 25 ; EM,  9 param: define la matriz de un caracter definible por el usuario
CTRL_TXT_FIJAR_VENTANA          EQU 26  ; SUB, 4 param: fija los limites de la ventana de texto (izq,der,arriba,abajo)
CTRL_TXT_ESC_SIN_EFECTO         EQU 27  ; ESC, 0 param: sin efecto, disponible para el usuario
CTRL_TXT_FIJAR_COLOR_TINTA      EQU 28  ; FS,  3 param: fija los colores de una tinta (indice, color1, color2)
CTRL_TXT_FIJAR_COLOR_BORDE      EQU 29  ; GS,  2 param: fija los colores del borde (color1, color2)
CTRL_TXT_CURSOR_HOME            EQU 30  ; RS,  0 param: cursor a la esquina superior izq. de la ventana
CTRL_TXT_POSICIONAR_CURSOR      EQU 31  ; US,  2 param: posiciona el cursor (columna, fila) dentro de la ventana

    ORG $6000

; ---- Inicializacion de sonido: 3 envolventes (amplitud+tono), cada
; una definida por una tabla de datos aun sin extraer a fichero propio
; ($7FCA/$7FD4/$7FDE = envolventes de amplitud 1/2/3; $7FE5/$7FF5/$7FF9
; = envolventes de tono 1/2/3) ----
    CALL FIRM_SOUND_RESET         ; 6000: cda7bc
    LD A,$01                     ; 6003: 3e01
    LD HL,ENVOLVENTE_AMPLITUD_1   ; 6005: 21ca7f
    CALL FIRM_SOUND_AMPL_ENV                   ; 6008: cdbcbc
    LD A,$01                     ; 600B: 3e01
    LD HL,ENVOLVENTE_TONO_1       ; 600D: 21e57f
    CALL FIRM_SOUND_TONE_ENV                   ; 6010: cdbfbc
    LD A,$02                     ; 6013: 3e02
    LD HL,ENVOLVENTE_AMPLITUD_2   ; 6015: 21d47f
    CALL FIRM_SOUND_AMPL_ENV                   ; 6018: cdbcbc
    LD A,$02                     ; 601B: 3e02
    LD HL,ENVOLVENTE_TONO_2       ; 601D: 21f57f
    CALL FIRM_SOUND_TONE_ENV                   ; 6020: cdbfbc
    LD A,$03                     ; 6023: 3e03
    LD HL,ENVOLVENTE_AMPLITUD_3   ; 6025: 21de7f
    CALL FIRM_SOUND_AMPL_ENV                   ; 6028: cdbcbc
    LD A,$03                     ; 602B: 3e03
    LD HL,ENVOLVENTE_TONO_3       ; 602D: 21f97f
    CALL FIRM_SOUND_TONE_ENV                   ; 6030: cdbfbc
    LD HL,GUION_SONIDO_CIRCULAR   ; 6033: 215c90
    LD (PUNTERO_GUION_SONIDO),HL  ; 6036: 225a90
; REINICIAR_MODO_ATRACCION ($6039): destino de "JP C,$6039" desde
; ACTUALIZAR_TABLA_PUNTUACIONES cuando la puntuacion no entra ni en el
; ultimo puesto de la tabla HI-SCORE -- vuelve aqui, DENTRO de la
; cabecera ya reconstruida, sin pedir nombre. Resiembra el generador
; aleatorio con el reloj del sistema y encadena con BORRAR_BLOQUE_
; ESTADO/dibujo del marco/tabla de puntuaciones/menu principal, es
; decir, es el mismo camino que sigue el arranque en frio del
; programa. Confianza alta (verificado byte a byte).
REINICIAR_MODO_ATRACCION:
    CALL FIRM_KL_TIME_PLEASE                   ; 6039: cd0dbd
    LD ($8151),HL                ; 603C: 225181  ; hipotesis: semilla de aleatoriedad a partir del reloj del sistema
; ACTUALIZAR_SECUENCIA_SONIDO se llama decenas de veces en todo este
; bloque, siempre suelta entre otras llamadas -- confirmado (Sesion 8):
; bombea GUION_SONIDO_CIRCULAR via PUNTERO_GUION_SONIDO, avanzando de 9
; en 9 bytes hasta GUION_SONIDO_ULTIMO_REGISTRO, y llama a SOUND QUEUE
; del firmware cuando FLAG_MUSICA_FONDO='Y'.
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;603F: cdd178
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;6042: cdd178
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;6045: cdd178
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;6048: cdd178
; BORRAR_BLOQUE_ESTADO: pone a 0 el byte ARRAY_ENTIDADES+5 ($8172) y lo
; propaga con LDIR (truco clasico de Z80: origen=destino-1) a lo largo
; de 1181 bytes mas -- confirmado (Sesion 8) que cubre el resto de
; ARRAY_ENTIDADES, y ESTADO_PARTIDA/VENTANA_TEXTO_HUD/MAPA_CASILLAS
; completos (el rango termina justo en el ultimo byte de MAPA_CASILLAS).
    CALL BORRAR_BLOQUE_ESTADO                   ; 604B: cdab7e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;604E: cdd178
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;6051: cdd178
    LD A,$06                     ; 6054: 3e06
    LD ($8169),A                 ; 6056: 326981
    XOR A                        ; 6059: af
    LD ($816C),A                 ; 605A: 326c81
    LD ($8168),A                 ; 605D: 326881
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;6060: cdd178
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;6063: cdd178
; $7EF4 (IMPRIMIR_BYTES_CON_LONGITUD, nombre corregido en Sesion 19 --
; la hipotesis original de la Sesion 3, "repetir un caracter N veces",
; era incorrecta): lee (HL)=longitud, y saca por FIRM_TXT_OUTPUT los
; "longitud" bytes siguientes uno a uno, avanzando el puntero en cada
; uno -- formato "longitud + secuencia de bytes", no "cuenta+caracter
; fijo". Aqui imprime bytes de TABLA_PARAMETROS_TRANSICION_PUNTUACIONES
; (mezcla de codigos de control VDU y/o mascara, sin decodificar a
; texto en este punto). Ver FINDINGS.md Sesiones 3 y 19.
    LD HL,TABLA_PARAMETROS_TRANSICION_PUNTUACIONES+8 ; 6066: 215386
    CALL IMPRIMIR_BYTES_CON_LONGITUD                   ; 6069: cdf47e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;606C: cdd178
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;606F: cdd178
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;6072: cdd178
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;6075: cdd178
    LD IX,TABLA_DIRECCIONES_PANTALLA ; 6078: dd21ca8e
    LD B,$C8                     ; 607C: 06c8
; Bucle $607E-$6093: confirmado (Sesion 8) -- 200 iteraciones (B=$C8),
; cada una calcula con el firmware FIRM_SCR_DOT_POSITION la direccion
; de pantalla de una fila y la guarda en TABLA_DIRECCIONES_PANTALLA
; (200 entradas x 2 bytes). Tecnica muy comun en juegos de CPC para
; acelerar el acceso a filas de pantalla.
BUCLE_CALCULAR_DIRECCIONES_PANTALLA:
    LD DE,$0000                  ; 607E: 110000
    LD H,D                       ; 6081: 62
    LD L,B                       ; 6082: 68
    DEC L                        ; 6083: 2d
    PUSH BC                      ; 6084: c5
    CALL FIRM_SCR_DOT_POSITION                   ; 6085: cd1dbc
    LD (IX+0),L                  ; 6088: dd7500
    LD (IX+1),H                  ; 608B: dd7401
    INC IX                       ; 608E: dd23
    INC IX                       ; 6090: dd23
    POP BC                       ; 6092: c1
    DJNZ BUCLE_CALCULAR_DIRECCIONES_PANTALLA                   ; 6093: 10e9
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;6095: cdd178
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;6098: cdd178
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;609B: cdd178
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;609E: cdd178
    LD HL,TEXTO_COPYRIGHT_Y_HUD   ; 60A1: 214087
    CALL IMPRIMIR_BYTES_CON_LONGITUD                   ; 60A4: cdf47e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;60A7: cdd178
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;60AA: cdd178
; BORRAR_RECTANGULO_VENTANA, llamada 14 veces seguidas con pares HL/DE
; distintos: hipotesis "borrar un rectangulo de la ventana de texto" --
; HL/DE parecen ser (fila,columna) de inicio y (ancho,alto) o esquina
; opuesta; recorre VENTANA_TEXTO_HUD (paso de 40 = $28 bytes por fila,
; el ancho de pantalla en modo texto) escribiendo espacios. Consistente
; con ir despejando varios paneles de HUD/marco antes de dibujarlos. Ver
; FINDINGS.md Sesion 3.
    LD HL,$0203                  ; 60AD: 210302
    LD DE,$2604                  ; 60B0: 110426
    CALL BORRAR_RECTANGULO_VENTANA                   ; 60B3: cdb97e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;60B6: cdd178
    LD HL,$0408                  ; 60B9: 210804
    LD DE,$2409                  ; 60BC: 110924
    CALL BORRAR_RECTANGULO_VENTANA                   ; 60BF: cdb97e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;60C2: cdd178
    LD HL,$040D                  ; 60C5: 210d04
    LD DE,$080E                  ; 60C8: 110e08
    CALL BORRAR_RECTANGULO_VENTANA                   ; 60CB: cdb97e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;60CE: cdd178
    LD HL,$0D0D                  ; 60D1: 210d0d
    LD DE,$1B0E                  ; 60D4: 110e1b
    CALL BORRAR_RECTANGULO_VENTANA                   ; 60D7: cdb97e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;60DA: cdd178
    LD HL,$200D                  ; 60DD: 210d20
    LD DE,$240E                  ; 60E0: 110e24
    CALL BORRAR_RECTANGULO_VENTANA                   ; 60E3: cdb97e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;60E6: cdd178
    LD HL,$0412                  ; 60E9: 211204
    LD DE,$2413                  ; 60EC: 111324
    CALL BORRAR_RECTANGULO_VENTANA                   ; 60EF: cdb97e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;60F2: cdd178
    LD HL,$0417                  ; 60F5: 211704
    LD DE,$2418                  ; 60F8: 111824
    CALL BORRAR_RECTANGULO_VENTANA                   ; 60FB: cdb97e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;60FE: cdd178
    LD HL,$0205                  ; 6101: 210502
    LD DE,$0318                  ; 6104: 111803
    CALL BORRAR_RECTANGULO_VENTANA                   ; 6107: cdb97e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;610A: cdd178
    LD HL,$0905                  ; 610D: 210509
    LD DE,$0A18                  ; 6110: 11180a
    CALL BORRAR_RECTANGULO_VENTANA                   ; 6113: cdb97e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;6116: cdd178
    LD HL,$1005                  ; 6119: 210510
    LD DE,$1107                  ; 611C: 110711
    CALL BORRAR_RECTANGULO_VENTANA                   ; 611F: cdb97e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;6122: cdd178
    LD HL,$1705                  ; 6125: 210517
    LD DE,$1807                  ; 6128: 110718
    CALL BORRAR_RECTANGULO_VENTANA                   ; 612B: cdb97e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;612E: cdd178
    LD HL,$1E05                  ; 6131: 21051e
    LD DE,$1F18                  ; 6134: 11181f
    CALL BORRAR_RECTANGULO_VENTANA                   ; 6137: cdb97e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;613A: cdd178
    LD HL,$2505                  ; 613D: 210525
    LD DE,$2618                  ; 6140: 111826
    CALL BORRAR_RECTANGULO_VENTANA                   ; 6143: cdb97e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;6146: cdd178
    LD HL,$1014                  ; 6149: 211410
    LD DE,$1116                  ; 614C: 111611
    CALL BORRAR_RECTANGULO_VENTANA                   ; 614F: cdb97e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;6152: cdd178
    LD HL,$1714                  ; 6155: 211417
    LD DE,$1816                  ; 6158: 111618
    CALL BORRAR_RECTANGULO_VENTANA                   ; 615B: cdb97e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;615E: cdd178
    LD HL,$0000                  ; 6161: 210000
    LD DE,$2718                  ; 6164: 111827
    CALL FIRM_TXT_WIN_ENABLE                   ; 6167: cd66bb
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;616A: cdd178
; $616D-$61E5: hipotesis "dibujar el marco decorativo" -- $7D85/$7D9D/
; $7DB5/$7DCD preparan una posicion+tabla y llaman a una rutina comun
; ($7E73) que a su vez usa uno de los 6 puntos de entrada de mascaras
; AND/OR $7DFC/$7E05/$7E0E/$7E17/$7E20/$7E29 (cada uno con su propio
; par de bytes de patron) -- muy propio de un dibujado de borde/marco
; por tramos con distinto patron segun el lado. Equivalente funcional
; al "marco_decorativo" de los proyectos hermanos. Ver FINDINGS.md
; Sesion 3.
    LD HL,$2808                  ; 616D: 210828
    CALL DIBUJAR_ICONO_SARCOFAGO                   ; 6170: cd857d
    LD HL,$2816                  ; 6173: 211628
    CALL RELLENAR_MARCO_DIAGONAL_1                   ; 6176: cdfc7d
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;6179: cdd178
    LD HL,$2824                  ; 617C: 212428
    CALL DIBUJAR_ICONO_TESORO                   ; 617F: cdcd7d
    LD HL,$2832                  ; 6182: 213228
    CALL RELLENAR_MARCO_DIAGONAL_3                   ; 6185: cd0e7e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;6188: cdd178
    LD HL,$2840                  ; 618B: 214028
    CALL DIBUJAR_ICONO_LLAVE                   ; 618E: cd9d7d
    LD HL,$5008                  ; 6191: 210850
    CALL RELLENAR_MARCO_DIAGONAL_6                   ; 6194: cd297e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;6197: cdd178
    LD HL,$889D                  ; 619A: 219d88
    CALL IMPRIMIR_BYTES_CON_LONGITUD                   ; 619D: cdf47e
    LD HL,$5040                  ; 61A0: 214050
    CALL RELLENAR_MARCO_DIAGONAL_6                   ; 61A3: cd297e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;61A6: cdd178
    LD HL,$7808                  ; 61A9: 210878
    CALL RELLENAR_MARCO_DIAGONAL_6                   ; 61AC: cd297e
    LD HL,$8906                  ; 61AF: 210689
    CALL IMPRIMIR_BYTES_CON_LONGITUD                   ; 61B2: cdf47e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;61B5: cdd178
    LD HL,$7840                  ; 61B8: 214078
    CALL RELLENAR_MARCO_DIAGONAL_6                   ; 61BB: cd297e
    LD HL,$A008                  ; 61BE: 2108a0
    CALL DIBUJAR_ICONO_TESORO                   ; 61C1: cdcd7d
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;61C4: cdd178
    LD HL,$A016                  ; 61C7: 2116a0
    CALL RELLENAR_MARCO_DIAGONAL_4                   ; 61CA: cd177e
    LD HL,$A024                  ; 61CD: 2124a0
    CALL DIBUJAR_ICONO_PERGAMINO                   ; 61D0: cdb57d
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;61D3: cdd178
    LD HL,$A032                  ; 61D6: 2132a0
    CALL RELLENAR_MARCO_DIAGONAL_2                   ; 61D9: cd057e
    LD HL,$A040                  ; 61DC: 2140a0
    CALL DIBUJAR_ICONO_TESORO                   ; 61DF: cdcd7d
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;61E2: cdd178
    LD HL,TABLA_POSICIONES_INICIALES_ENTIDADES-2                  ; 61E5: 210f86
    LD (VARIABLE_TEMPORAL_HL_1),HL                ; 61E8: 224586
    CALL INICIALIZAR_ENTIDADES                   ; 61EB: cd4f79
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;61EE: cdd178
    LD HL,$6828                  ; 61F1: 212868
    LD ($8155),HL                ; 61F4: 225581
    LD A,$02                     ; 61F7: 3e02
    LD ($8157),A                 ; 61F9: 325781
    LD A,$02                     ; 61FC: 3e02
    LD ($815E),A                 ; 61FE: 325e81
; $6201-$6221: hipotesis "menu de seleccion" (1 o 2 jugadores) -- B=1
; y B=2 son las dos opciones; $78B7 parece animar/temporizar la
; opcion resaltada, $78F7 posiciona un indicador segun la opcion
; activa, $7893 espera pulsacion de una tecla concreta ($2C).
; FIRM_KM_TEST_KEY con A=$3E comprueba la tecla de confirmar (Enter,
; a falta de confirmar el mapa de scancodes del CPC). Ver FINDINGS.md
; Sesion 3 -- ninguna de estas hipotesis esta verificada en emulador.
BUCLE_SELECCIONAR_JUGADORES:
    CALL FIRM_KM_READ_CHAR                   ; 6201: cd09bb
    LD B,$01                     ; 6204: 0601
    CALL ANIMAR_OPCION_MENU                   ; 6206: cdb778
    CALL MOVER_INDICADOR_MENU                   ; 6209: cdf778
    CALL ESPERAR_TECLA_2C                   ; 620C: cd9378
    LD B,$02                     ; 620F: 0602
    CALL ANIMAR_OPCION_MENU                   ; 6211: cdb778
    CALL MOVER_INDICADOR_MENU                   ; 6214: cdf778
    LD A,$3E                     ; 6217: 3e3e
    CALL FIRM_KM_TEST_KEY                   ; 6219: cd1ebb
    JR NZ,PREPARAR_ENTRADA_NOMBRE                  ; 621C: 2005
    CALL ESPERAR_TECLA_2C                   ; 621E: cd9378
    JR BUCLE_SELECCIONAR_JUGADORES                     ; 6221: 18de
; PREPARAR_ENTRADA_NOMBRE ($6223): punto de convergencia real (5
; referencias: confirmar 1/2 jugadores arriba, "L"/Intro tras STOP
; PRESS/GAME OVER, y el JP final de ACTUALIZAR_TABLA_PUNTUACIONES tras
; insertar una puntuacion nueva). Vacia el buffer de teclado, imprime
; el prompt "Well done!! Please enter your name" ($866D, dentro de
; TEXTO_MENU_PRINCIPAL) y borra el estado antes de caer en el bucle de
; tecleo del nombre. Confianza alta (verificado byte a byte).
PREPARAR_ENTRADA_NOMBRE:
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;6223: cdd178
    CALL FIRM_KM_READ_CHAR                   ; 6226: cd09bb
    JR C,PREPARAR_ENTRADA_NOMBRE                   ; 6229: 38f8
    LD HL,$866D                  ; 622B: 216d86
    CALL IMPRIMIR_BYTES_CON_LONGITUD                   ; 622E: cdf47e
    CALL BORRAR_BLOQUE_ESTADO                   ; 6231: cdab7e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;6234: cdd178
    XOR A                        ; 6237: af
    LD ($816C),A                 ; 6238: 326c81
    LD A,$06                     ; 623B: 3e06
    LD ($8169),A                 ; 623D: 326981
    LD HL,$0803                  ; 6240: 210308
    LD DE,$1F14                  ; 6243: 11141f
    CALL FIRM_TXT_WIN_ENABLE                   ; 6246: cd66bb
    CALL FIRM_TXT_CLEAR_WINDOW                   ; 6249: cd6cbb
    XOR A                        ; 624C: af
    CALL FIRM_TXT_SET_PAPER                   ; 624D: cd96bb
    LD HL,$0C05                  ; 6250: 21050c
    LD DE,$1B07                  ; 6253: 11071b
    CALL FIRM_TXT_WIN_ENABLE                   ; 6256: cd66bb
    CALL FIRM_TXT_CLEAR_WINDOW                   ; 6259: cd6cbb
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;625C: cdd178
    LD HL,$0A08                  ; 625F: 21080a
    LD DE,$1D12                  ; 6262: 11121d
    CALL FIRM_TXT_WIN_ENABLE                   ; 6265: cd66bb
    CALL FIRM_TXT_CLEAR_WINDOW                   ; 6268: cd6cbb
    LD DE,$2812                  ; 626B: 111228
    LD ($8155),DE                ; 626E: ed535581
    LD A,$02                     ; 6272: 3e02
    LD ($8157),A                 ; 6274: 325781
    LD A,$41                     ; 6277: 3e41
    CALL DIBUJAR_ENTIDAD                   ; 6279: cd397b
    LD DE,$283A                  ; 627C: 113a28
    LD ($8155),DE                ; 627F: ed535581
    LD A,$04                     ; 6283: 3e04
    LD ($8157),A                 ; 6285: 325781
    LD A,$41                     ; 6288: 3e41
    CALL DIBUJAR_ENTIDAD                   ; 628A: cd397b
    LD A,$01                     ; 628D: 3e01
    CALL FIRM_TXT_SET_PAPER                   ; 628F: cd96bb
    LD HL,$0601                  ; 6292: 210106
    LD DE,$0716                  ; 6295: 111607
    CALL BORRAR_RECTANGULO_VENTANA                   ; 6298: cdb97e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;629B: cdd178
    LD HL,$2001                  ; 629E: 210120
    LD DE,$2116                  ; 62A1: 111621
    CALL BORRAR_RECTANGULO_VENTANA                   ; 62A4: cdb97e
    LD HL,$0801                  ; 62A7: 210108
    LD DE,$1F02                  ; 62AA: 11021f
    CALL BORRAR_RECTANGULO_VENTANA                   ; 62AD: cdb97e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;62B0: cdd178
    LD HL,$0815                  ; 62B3: 211508
    LD DE,$1F16                  ; 62B6: 11161f
    CALL BORRAR_RECTANGULO_VENTANA                   ; 62B9: cdb97e
    LD HL,$0000                  ; 62BC: 210000
    LD DE,$2718                  ; 62BF: 111827
    CALL FIRM_TXT_WIN_ENABLE                   ; 62C2: cd66bb
    LD HL,$8676                  ; 62C5: 217686
    CALL IMPRIMIR_BYTES_CON_LONGITUD                   ; 62C8: cdf47e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;62CB: cdd178
    LD HL,$0C0A                  ; 62CE: 210a0c
    CALL FIRM_TXT_SET_CURSOR                   ; 62D1: cd75bb
    LD HL,($868C)                ; 62D4: 2a8c86
    CALL IMPRIMIR_NUMERO_HL                   ; 62D7: cd6c78
    LD HL,$868E                  ; 62DA: 218e86
    CALL IMPRIMIR_BYTES_CON_LONGITUD                   ; 62DD: cdf47e
    LD HL,$0C0C                  ; 62E0: 210c0c
    CALL FIRM_TXT_SET_CURSOR                   ; 62E3: cd75bb
    LD HL,($869E)                ; 62E6: 2a9e86
    CALL IMPRIMIR_NUMERO_HL                   ; 62E9: cd6c78
    LD HL,$86A0                  ; 62EC: 21a086
    CALL IMPRIMIR_BYTES_CON_LONGITUD                   ; 62EF: cdf47e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;62F2: cdd178
    LD HL,$0C0E                  ; 62F5: 210e0c
    CALL FIRM_TXT_SET_CURSOR                   ; 62F8: cd75bb
    LD HL,($86B0)                ; 62FB: 2ab086
    CALL IMPRIMIR_NUMERO_HL                   ; 62FE: cd6c78
    LD HL,$86B2                  ; 6301: 21b286
    CALL IMPRIMIR_BYTES_CON_LONGITUD                   ; 6304: cdf47e
    LD HL,$0C10                  ; 6307: 21100c
    CALL FIRM_TXT_SET_CURSOR                   ; 630A: cd75bb
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;630D: cdd178
    LD HL,($86C2)                ; 6310: 2ac286
    CALL IMPRIMIR_NUMERO_HL                   ; 6313: cd6c78
    LD HL,$86C4                  ; 6316: 21c486
    CALL IMPRIMIR_BYTES_CON_LONGITUD                   ; 6319: cdf47e
    LD HL,$0C12                  ; 631C: 21120c
    CALL FIRM_TXT_SET_CURSOR                   ; 631F: cd75bb
    LD HL,($86D4)                ; 6322: 2ad486
    CALL IMPRIMIR_NUMERO_HL                   ; 6325: cd6c78
    LD HL,$86D6                  ; 6328: 21d686
    CALL IMPRIMIR_BYTES_CON_LONGITUD                   ; 632B: cdf47e
    LD HL,TABLA_POSICIONES_INICIALES_ENTIDADES+38                  ; 632E: 213786
    LD (VARIABLE_TEMPORAL_HL_1),HL                ; 6331: 224586
    CALL INICIALIZAR_ENTIDADES                   ; 6334: cd4f79
    LD HL,$6828                  ; 6337: 212868
    LD ($8155),HL                ; 633A: 225581
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;633D: cdd178
    LD A,($8168)                 ; 6340: 3a6881
    OR A                         ; 6343: b7
    JR Z,REANUDAR_MENU_TRAS_NOMBRE ; 6344: 2826
    LD HL,$8710                  ; 6346: 211087
    CALL IMPRIMIR_BYTES_CON_LONGITUD                   ; 6349: cdf47e
    XOR A                        ; 634C: af
    CALL FIRM_TXT_SET_PAPER                   ; 634D: cd96bb
    LD HL,($7FC6)                ; 6350: 2ac67f
    CALL FIRM_TXT_SET_CURSOR                   ; 6353: cd75bb
    XOR A                        ; 6356: af
    LD (VARIABLE_TEMPORAL_A_1),A                 ; 6357: 324986
    LD A,$8F                     ; 635A: 3e8f
    CALL FIRM_TXT_OUTPUT                   ; 635C: cd5abb
    LD HL,($7FC6)                ; 635F: 2ac67f
    CALL FIRM_TXT_SET_CURSOR                   ; 6362: cd75bb
ESPERAR_PRIMERA_TECLA_NOMBRE:
    CALL FIRM_KM_READ_CHAR                   ; 6365: cd09bb
    JR C,ESPERAR_PRIMERA_TECLA_NOMBRE                   ; 6368: 38fb
    JR BUCLE_LEER_NOMBRE                     ; 636A: 1806
; REANUDAR_MENU_TRAS_NOMBRE ($636C): destino de 2 saltos -- JR Z,$636C
; en $6344 (bucle de tecleo del nombre, cuando el flag ($8168) ya esta
; a 0) y, desde la Sesion 12, JP $636C en el nuevo FIN_INTRODUCIR_NOMBRE
; ($6401), alcanzado por caida natural cuando se confirma el nombre con
; Intro. Nunca se alcanza por caida natural desde arriba (la
; instruccion anterior, $636A, es un JR incondicional que se lo salta
; siempre) -- confirma que es un punto de entrada real, no relleno.
; Redibuja $86E8 (hipotesis media: posible cursor/indicador de fin de
; edicion), anima los 2 indicadores de menu (B=1/B=2, mismo mecanismo
; que la seleccion de 1/2 jugadores) y decide, segun ($8168), si seguir
; leyendo caracteres del nombre o pasar a DESPACHAR_MENU_PRINCIPAL
; ($6404) -- confianza alta en el flujo, media en el papel visual
; exacto de $86E8. Ver FINDINGS.md Sesion 12.
REANUDAR_MENU_TRAS_NOMBRE:
    LD HL,$86E8                  ; 636C: 21e886
    CALL IMPRIMIR_BYTES_CON_LONGITUD                   ; 636F: cdf47e
BUCLE_LEER_NOMBRE:
    LD B,$01                     ; 6372: 0601
    CALL ANIMAR_OPCION_MENU                   ; 6374: cdb778
    LD B,$02                     ; 6377: 0602
    CALL ANIMAR_OPCION_MENU                   ; 6379: cdb778
    LD A,($8168)                 ; 637C: 3a6881
    OR A                         ; 637F: b7
    JP Z,DESPACHAR_MENU_PRINCIPAL ; 6380: ca0464
    CALL FIRM_KM_READ_CHAR                   ; 6383: cd09bb
    JR NC,BUCLE_LEER_NOMBRE                  ; 6386: 30ea
    CP $0D                       ; 6388: fe0d
    JR Z,CONFIRMAR_NOMBRE_JUGADOR                   ; 638A: 2867
    CP $7F                       ; 638C: fe7f
    JR Z,BORRAR_CARACTER_NOMBRE                   ; 638E: 2834
    LD B,A                       ; 6390: 47
    LD A,(VARIABLE_TEMPORAL_A_1)                 ; 6391: 3a4986
    CP $0C                       ; 6394: fe0c
    JR Z,BUCLE_LEER_NOMBRE                   ; 6396: 28da
    LD A,B                       ; 6398: 78
    CP $20                       ; 6399: fe20
    JR C,BUCLE_LEER_NOMBRE                   ; 639B: 38d5
    CP $80                       ; 639D: fe80
    JR NC,BUCLE_LEER_NOMBRE                  ; 639F: 30d1
    LD HL,($7FC8)                ; 63A1: 2ac87f
    LD (HL),A                    ; 63A4: 77
    INC HL                       ; 63A5: 23
    LD ($7FC8),HL                ; 63A6: 22c87f
    CALL FIRM_TXT_OUTPUT                   ; 63A9: cd5abb
    LD A,$8F                     ; 63AC: 3e8f
    CALL FIRM_TXT_OUTPUT                   ; 63AE: cd5abb
    LD HL,($7FC6)                ; 63B1: 2ac67f
    INC H                        ; 63B4: 24
    LD ($7FC6),HL                ; 63B5: 22c67f
    CALL FIRM_TXT_SET_CURSOR                   ; 63B8: cd75bb
    LD A,(VARIABLE_TEMPORAL_A_1)                 ; 63BB: 3a4986
    INC A                        ; 63BE: 3c
    LD (VARIABLE_TEMPORAL_A_1),A                 ; 63BF: 324986
    JR BUCLE_LEER_NOMBRE                     ; 63C2: 18ae
BORRAR_CARACTER_NOMBRE:
    LD A,(VARIABLE_TEMPORAL_A_1)                 ; 63C4: 3a4986
    OR A                         ; 63C7: b7
    JR Z,BUCLE_LEER_NOMBRE                   ; 63C8: 28a8
    DEC A                        ; 63CA: 3d
    LD (VARIABLE_TEMPORAL_A_1),A                 ; 63CB: 324986
    LD HL,($7FC8)                ; 63CE: 2ac87f
    DEC HL                       ; 63D1: 2b
    LD A,$20                     ; 63D2: 3e20
    LD (HL),A                    ; 63D4: 77
    LD ($7FC8),HL                ; 63D5: 22c87f
    CALL FIRM_TXT_OUTPUT                   ; 63D8: cd5abb
    LD HL,($7FC6)                ; 63DB: 2ac67f
    DEC H                        ; 63DE: 25
    LD ($7FC6),HL                ; 63DF: 22c67f
    CALL FIRM_TXT_SET_CURSOR                   ; 63E2: cd75bb
    LD A,$8F                     ; 63E5: 3e8f
    CALL FIRM_TXT_OUTPUT                   ; 63E7: cd5abb
    LD HL,($7FC6)                ; 63EA: 2ac67f
    CALL FIRM_TXT_SET_CURSOR                   ; 63ED: cd75bb
    JP BUCLE_LEER_NOMBRE                     ; 63F0: c37263
CONFIRMAR_NOMBRE_JUGADOR:
    LD A,$20                     ; 63F3: 3e20
    CALL FIRM_TXT_OUTPUT                   ; 63F5: cd5abb
    XOR A                        ; 63F8: af
    LD ($8168),A                 ; 63F9: 326881
    LD A,$03                     ; 63FC: 3e03
    CALL FIRM_TXT_SET_PAPER                   ; 63FE: cd96bb

; ---- Mas alla de $6400: reconstruccion completa del motor (Sesion 14
; cierra el ultimo hueco INCBIN, ver $68B2-$7862 mas abajo). Ver
; FINDINGS.md Sesiones 3-14 para el detalle y el nivel de confianza de
; cada hipotesis. ----

; ---- $6401-$6528 (296 bytes): primer tramo promovido del INCBIN --
; Sesion 12. Dos puntos de entrada reales (ver cabecera del fichero):
; FIN_INTRODUCIR_NOMBRE (caida natural, cuando SI se tecleo nombre) y
; DESPACHAR_MENU_PRINCIPAL (JP Z desde $6380, cuando NO se tecleo).
; Verificado que ambos convergen: el primero solo redirige al bucle de
; la cabecera (REANUDAR_MENU_TRAS_NOMBRE, $636C) que a su vez cae en
; DESPACHAR_MENU_PRINCIPAL en cuanto el flag ($8168) esta a 0. ----
FIN_INTRODUCIR_NOMBRE:
; Confianza alta: unico codigo entre $63FE (fin de cabecera) y $6404,
; alcanzado solo cuando ($8168)<>0 -- justo el flujo que acaba de
; teclear "Intro" para confirmar el nombre ($63F3-$6400: imprime un
; espacio, pone ($8168)=0 y PAPER=3). Vuelve al bucle de la cabecera
; para redibujar una vez mas antes de caer al despachador principal.
    JP REANUDAR_MENU_TRAS_NOMBRE     ; 6401: c36c63
; DESPACHAR_MENU_PRINCIPAL: lee un caracter de teclado y compara contra
; P/p, I/i, O/o -- confianza alta, coincide exactamente con el menu
; principal ya confirmado como texto literal en TEXTO_MENU_PRINCIPAL
; (Sesion 8, "Instructions/Options/Play" o similar). P/p -> $6529
; (jugar/empezar partida, hipotesis alta -- inicializa contadores de
; partida, ver mas abajo); I/i -> PANTALLA_INSTRUCCIONES ($68B2, Sesion
; 14); O/o -> PANTALLA_OPCIONES. Sin coincidencia, vuelve a
; REANUDAR_MENU_TRAS_NOMBRE ($6372, dentro de ese bucle) a seguir
; animando y esperando tecla.
DESPACHAR_MENU_PRINCIPAL:
    CALL FIRM_KM_READ_CHAR           ; 6404: cd09bb
    JP NC,BUCLE_LEER_NOMBRE                      ; 6407: d27263
    CP $50                           ; 640A: fe50  ; 'P'
    JP Z,INICIAR_PARTIDA                       ; 640C: ca2965
    CP $70                           ; 640F: fe70  ; 'p'
    JP Z,INICIAR_PARTIDA                       ; 6411: ca2965
    CP $49                           ; 6414: fe49  ; 'I'
    JP Z,PANTALLA_INSTRUCCIONES                       ; 6416: cab268
    CP $69                           ; 6419: fe69  ; 'i'
    JP Z,PANTALLA_INSTRUCCIONES                       ; 641B: cab268
    CP $4F                           ; 641E: fe4f  ; 'O'
    JP Z,PANTALLA_OPCIONES           ; 6420: ca2b64
    CP $6F                           ; 6423: fe6f  ; 'o'
    JP Z,PANTALLA_OPCIONES           ; 6425: ca2b64
    JP BUCLE_LEER_NOMBRE                         ; 6428: c37263
; PANTALLA_OPCIONES: pantalla "OH MUMMY - OPTIONS" (texto literal
; confirmado en TEXTO_MENU_OPCIONES, $7EFD, Sesion 8). Confianza alta
; en la estructura y en el papel de las 4 variables de partida que fija
; (coincide exactamente con los 4 prompts del texto, en el mismo
; orden, y 2 de ellas ya tenian usos conocidos en codigo ya
; reconstruido -- ver comentarios de cada tramo):
;   - "SPEED OF GAME (1-5) ?" (1 IS FASTEST) -> digito 1-5 escalado a
;     ($8153)=$0100+digito*$00E0 (alta: ($8153) ya es el contador de
;     retardo que consume ANIMAR_OPCION_MENU con DEC/JR NZ -- a mas
;     digito, mas retardo, cuadra con "1 = mas rapido").
;   - "DIFFICULTY LEVEL (1-5) ?" (1 IS HARDEST) -> digito 1-5 escalado
;     por duplicado sucesivo a ($8161)=15/31/63/127/255 (alta: ($8161)
;     ya se usa en COLOCAR_ENTIDAD como limite de GENERAR_ALEATORIO
;     para decidir si un enemigo persigue al jugador -- a mas digito,
;     mayor el limite, menos probable el 0 exacto, menos persecucion;
;     cuadra con "1 = mas dificil").
;   - "BACKGROUND MUSIC (Y-N) ?" -> tecla '+'/'.' alterna
;     FLAG_MUSICA_FONDO entre 'Y'/'N' (alta, ya nombrada y usada por
;     ACTUALIZAR_SECUENCIA_SONIDO).
;   - "SOUND EFFECTS (Y-N) ?" -> tecla '+'/'.' alterna
;     FLAG_EFECTOS_SONIDO entre 'Y'/'N' (sube de media a alta: esta
;     sesion localiza por fin el punto donde se ESCRIBE el flag, que
;     FINDINGS.md Sesion 8 dejaba pendiente; el codigo que la LEE
;     sigue sin localizarse).
; Sesion 19 RESUELVE lo que quedaba pendiente aqui: los IMPRIMIR_BYTES_
; CON_LONGITUD(HL) de este tramo SI imprimen el texto/codigos de
; control real de TEXTO_MENU_OPCIONES/TEXTO_HISTORIA_ATRACCION -- la
; hipotesis previa ("repite un caracter, no recorre una cadena") era
; incorrecta (ver correccion junto a la rutina, $7EF4). Verificado con
; aritmetica exacta sobre los datos reales: la llamada con HL=$7EFD
; (longitud $4E=78) imprime el titulo "OH MUMMY - OPTIONS" con sus
; codigos de control, y termina EXACTO en $7F4C -- la siguiente
; llamada, confirmando que son bloques consecutivos sin hueco.
; HL=$7F4C (longitud $35=53) imprime "SPEED OF GAME (1-5) ?" y
; termina EXACTO en $7F82, la siguiente llamada. El patron se rompe
; adrede a partir de ahi porque el programa empieza a ramificar segun
; la tecla pulsada: HL=$7FBD (byte de longitud $03, reutilizado desde
; dentro de otro bloque) imprime literalmente "YES", y HL=$7FC1
; (longitud $02) imprime literalmente "NO" -- confirmado letra a letra
; contra los DB reales. Confianza alta: el mecanismo de impresion de
; rotulos de esta pantalla queda identificado por completo.
PANTALLA_OPCIONES:
    CALL FIRM_KM_READ_CHAR           ; 642B: cd09bb
    JR C,PANTALLA_OPCIONES           ; 642E: 38fb  ; vacia el buffer de teclado antes de dibujar
    LD HL,$7EFD                      ; 6430: 21fd7e  ; TEXTO_MENU_OPCIONES (titulo)
    CALL IMPRIMIR_BYTES_CON_LONGITUD            ; 6433: cdf47e
; -- "SPEED OF GAME (1-5) ?": lee un digito '1'-'5', lo eco a pantalla
; y calcula ($8153) = $0100 + digito*$00E0 --
BUCLE_LEER_VELOCIDAD_PARTIDA:
    CALL ACTUALIZAR_SECUENCIA_SONIDO ; 6436: cdd178
    CALL FIRM_KM_READ_CHAR           ; 6439: cd09bb
    JR NC,BUCLE_LEER_VELOCIDAD_PARTIDA                      ; 643C: 30f8
    CP $31                           ; 643E: fe31  ; '1'
    JR C,BUCLE_LEER_VELOCIDAD_PARTIDA                       ; 6440: 38f4
    CP $36                           ; 6442: fe36  ; '6' (excluido)
    JR NC,BUCLE_LEER_VELOCIDAD_PARTIDA                      ; 6444: 30f0
    CALL FIRM_TXT_OUTPUT             ; 6446: cd5abb  ; eco del digito tecleado
    SUB $30                          ; 6449: d630   ; ASCII -> 1..5
    LD HL,$0100                      ; 644B: 210001
    LD DE,$00E0                      ; 644E: 11e000
    LD B,A                           ; 6451: 47
BUCLE_ESCALAR_RETARDO_PARTIDA:
    ADD HL,DE                        ; 6452: 19
    DJNZ BUCLE_ESCALAR_RETARDO_PARTIDA                       ; 6453: 10fd
    LD ($8153),HL                    ; 6455: 225381  ; retardo de partida (ya usado por ANIMAR_OPCION_MENU)
; -- "DIFFICULTY LEVEL (1-5) ?": mismo patron, digito 1-5 -> ($8161) =
; $07F8 duplicado (digito) veces, byte alto --
    LD HL,$7F4C                      ; 6458: 214c7f  ; TEXTO_MENU_OPCIONES+$4F
    CALL IMPRIMIR_BYTES_CON_LONGITUD            ; 645B: cdf47e
BUCLE_LEER_NIVEL_DIFICULTAD:
    CALL ACTUALIZAR_SECUENCIA_SONIDO ; 645E: cdd178
    CALL FIRM_KM_READ_CHAR           ; 6461: cd09bb
    JR NC,BUCLE_LEER_NIVEL_DIFICULTAD                       ; 6464: 30f8
    CP $31                           ; 6466: fe31
    JR C,BUCLE_LEER_NIVEL_DIFICULTAD                        ; 6468: 38f4
    CP $36                           ; 646A: fe36
    JR NC,BUCLE_LEER_NIVEL_DIFICULTAD                       ; 646C: 30f0
    CALL FIRM_TXT_OUTPUT             ; 646E: cd5abb
    SUB $30                          ; 6471: d630
    LD B,A                           ; 6473: 47
    LD HL,$07F8                      ; 6474: 21f807
BUCLE_ESCALAR_LIMITE_DIFICULTAD:
    ADD HL,HL                        ; 6477: 29
    DJNZ BUCLE_ESCALAR_LIMITE_DIFICULTAD                       ; 6478: 10fd
    LD A,H                           ; 647A: 7c
    LD ($8161),A                     ; 647B: 326181  ; limite de persecucion IA (ya usado por COLOCAR_ENTIDAD)
; -- "BACKGROUND MUSIC (Y-N) ?": tecla '+' -> 'Y' (y reinicia el guion
; de sonido circular), '.' -> 'N' --
    LD HL,$7F82                      ; 647E: 21827f  ; TEXTO_MENU_OPCIONES+$85
    CALL IMPRIMIR_BYTES_CON_LONGITUD            ; 6481: cdf47e
BUCLE_LEER_MUSICA_FONDO:
    CALL ACTUALIZAR_SECUENCIA_SONIDO ; 6484: cdd178
    LD A,$2B                         ; 6487: 3e2b  ; '+'
    CALL FIRM_KM_TEST_KEY            ; 6489: cd1ebb
    JR NZ,ACTIVAR_MUSICA_FONDO                      ; 648C: 201d
    LD A,$2E                         ; 648E: 3e2e  ; '.'
    CALL FIRM_KM_TEST_KEY            ; 6490: cd1ebb
    JR Z,BUCLE_LEER_MUSICA_FONDO                    ; 6493: 28ef
    LD A,$4E                         ; 6495: 3e4e  ; 'N'
    LD (FLAG_MUSICA_FONDO),A         ; 6497: 32c47f
    LD HL,$7FC1                      ; 649A: 21c17f  ; TEXTO_MENU_OPCIONES+$C4
    CALL IMPRIMIR_BYTES_CON_LONGITUD            ; 649D: cdf47e
    CALL FIRM_SOUND_RESET            ; 64A0: cda7bc
    LD HL,GUION_SONIDO_CIRCULAR      ; 64A3: 215c90
    LD (PUNTERO_GUION_SONIDO),HL     ; 64A6: 225a90
    JR ESPERAR_LIBERAR_TECLAS_MUSICA ; 64A9: 181b
ACTIVAR_MUSICA_FONDO:
    LD A,(FLAG_MUSICA_FONDO)         ; 64AB: 3ac47f
    CP $4E                           ; 64AE: fe4e  ; 'N'
    JR NZ,FIJAR_MUSICA_FONDO_SI      ; 64B0: 2009
    CALL FIRM_SOUND_RESET            ; 64B2: cda7bc
    LD HL,GUION_SONIDO_CIRCULAR      ; 64B5: 215c90
    LD (PUNTERO_GUION_SONIDO),HL     ; 64B8: 225a90
FIJAR_MUSICA_FONDO_SI:
    LD A,$59                         ; 64BB: 3e59  ; 'Y'
    LD (FLAG_MUSICA_FONDO),A         ; 64BD: 32c47f
    LD HL,$7FBD                      ; 64C0: 21bd7f  ; TEXTO_MENU_OPCIONES+$C0
    CALL IMPRIMIR_BYTES_CON_LONGITUD            ; 64C3: cdf47e
; -- "SOUND EFFECTS (Y-N) ?": mismo patron '+'/'.', sin reinicio de
; sonido (solo cambia el flag) --
ESPERAR_LIBERAR_TECLAS_MUSICA:
    CALL ACTUALIZAR_SECUENCIA_SONIDO ; 64C6: cdd178
    LD A,$2B                         ; 64C9: 3e2b
    CALL FIRM_KM_TEST_KEY            ; 64CB: cd1ebb
    JR NZ,ESPERAR_LIBERAR_TECLAS_MUSICA             ; 64CE: 20f6
    LD A,$2E                         ; 64D0: 3e2e
    CALL FIRM_KM_TEST_KEY            ; 64D2: cd1ebb
    JR NZ,ESPERAR_LIBERAR_TECLAS_MUSICA             ; 64D5: 20ef
ESPERAR_TECLA_TRAS_MUSICA:
    CALL ACTUALIZAR_SECUENCIA_SONIDO ; 64D7: cdd178
    CALL FIRM_KM_READ_CHAR           ; 64DA: cd09bb
    JR C,ESPERAR_TECLA_TRAS_MUSICA                  ; 64DD: 38f8
    LD HL,$7FA1                      ; 64DF: 21a17f  ; TEXTO_MENU_OPCIONES+$A4
    CALL IMPRIMIR_BYTES_CON_LONGITUD            ; 64E2: cdf47e
BUCLE_LEER_EFECTOS_SONIDO:
    CALL ACTUALIZAR_SECUENCIA_SONIDO ; 64E5: cdd178
    LD A,$2B                         ; 64E8: 3e2b
    CALL FIRM_KM_TEST_KEY            ; 64EA: cd1ebb
    JR NZ,FIJAR_EFECTOS_SONIDO_SI    ; 64ED: 2014
    LD A,$2E                         ; 64EF: 3e2e
    CALL FIRM_KM_TEST_KEY            ; 64F1: cd1ebb
    JR Z,BUCLE_LEER_EFECTOS_SONIDO                  ; 64F4: 28ef
    LD A,$4E                         ; 64F6: 3e4e
    LD (FLAG_EFECTOS_SONIDO),A       ; 64F8: 32c57f
    LD HL,$7FC1                      ; 64FB: 21c17f
    CALL IMPRIMIR_BYTES_CON_LONGITUD            ; 64FE: cdf47e
    JR MOSTRAR_CONFIRMACION_OPCIONES ; 6501: 180b
FIJAR_EFECTOS_SONIDO_SI:
    LD A,$59                         ; 6503: 3e59
    LD (FLAG_EFECTOS_SONIDO),A       ; 6505: 32c57f
    LD HL,$7FBD                      ; 6508: 21bd7f
    CALL IMPRIMIR_BYTES_CON_LONGITUD            ; 650B: cdf47e
; -- Confirmar con 'L' o Intro; cualquier otra tecla reinicia el bucle
; de esta ultima pregunta ($6514) --
MOSTRAR_CONFIRMACION_OPCIONES:
    LD HL,$80FB                      ; 650E: 21fb80  ; TEXTO_HISTORIA_ATRACCION+$DE
    CALL IMPRIMIR_BYTES_CON_LONGITUD            ; 6511: cdf47e
BUCLE_CONFIRMAR_SALIDA_OPCIONES:
    CALL ACTUALIZAR_SECUENCIA_SONIDO ; 6514: cdd178
    LD A,$4C                         ; 6517: 3e4c  ; 'L'
    CALL FIRM_KM_TEST_KEY            ; 6519: cd1ebb
    JP NZ,PREPARAR_ENTRADA_NOMBRE                      ; 651C: c22362  ; vuelve al flujo de la cabecera (confirmar 1/2 jugadores)
    LD A,$3E                         ; 651F: 3e3e  ; Intro
    CALL FIRM_KM_TEST_KEY            ; 6521: cd1ebb
    JP NZ,PREPARAR_ENTRADA_NOMBRE                      ; 6524: c22362
    JR BUCLE_CONFIRMAR_SALIDA_OPCIONES ; 6527: 18eb

; ---- $6529-$68B1 (905 bytes): segundo tramo promovido del INCBIN --
; Sesion 13. Arranca desde el punto de entrada real confirmado en la
; Sesion 12 ($6529, destino de los 2 "JP Z,$6529" de tecla P/p en
; DESPACHAR_MENU_PRINCIPAL) y sigue el hilo de llamadas/saltos hasta
; $68B1 (justo antes de la entrada 'I' de instrucciones en $68B2,
; PANTALLA_INSTRUCCIONES, reconstruida en la Sesion 14 mas abajo). Cubre: arranque de
; partida e inicio de cada nivel (INICIAR_PARTIDA/PREPARAR_NIVEL),
; colocacion aleatoria de tesoros (PREPARAR_TESOROS_NIVEL), HUD de
; vidas/puntuacion (ACTUALIZAR_HUD_VIDAS), limpieza de paneles
; (LIMPIAR_PANELES_NIVEL), el llamador de RELLENAR_MARCO_DIAGONAL_1..6
; que quedaba pendiente desde la Sesion 7/12
; (SELECCIONAR_DIAGONAL_MARCO_NIVEL), colocacion del jugador
; (COLOCAR_JUGADOR_INICIAL), el bucle principal de juego
; (BUCLE_PRINCIPAL_JUEGO, con 5 llamadas internas -- $7578, $77D1,
; $7637, $7566, $7513 -- resueltas en la Sesion 14: PROCESAR_ENCUENTROS_
; ENTIDADES/PROCESAR_MOVIMIENTO_JUGADOR/ACTUALIZAR_MARCO_TRAS_MOVIMIENTO/
; COMPROBAR_SALIDA_NIVEL/ANIMAR_APARICION_MOMIA_GUARDIANA, ver mas abajo),
; y las pantallas de fin de partida (PANTALLA_STOP_PRESS/PANTALLA_GAME_OVER/
; ACTUALIZAR_TABLA_PUNTUACIONES). Ver FINDINGS.md Sesiones 13-14 para el
; detalle completo, confianza por rutina, y los pendientes exactos. ----

; INICIAR_PARTIDA ($6529): punto de entrada real confirmado -- destino
; de los 2 "JP Z,$6529" en DESPACHAR_MENU_PRINCIPAL (tecla P/p). Fija
; vidas=5 y puntuacion=0 (unica vez que se hace en todo el tramo) y cae
; en PREPARAR_NIVEL. Confianza alta en el papel de entrada; alta en
; puntuacion/vidas (ver comentario de PREPARAR_NIVEL mas abajo).
INICIAR_PARTIDA:
    LD A,$05                          ; 6529: 3e05
    LD ($816A),A                      ; 652B: 326a81
    LD HL,$0000                       ; 652E: 210000
    LD ($815A),HL                     ; 6531: 225a81

; PREPARAR_NIVEL ($6534): reentrada real -- destino de los 2
; "JP NZ,$6534" de PANTALLA_STOP_PRESS (teclas L/Intro tras completar
; los 6 niveles). A diferencia de INICIAR_PARTIDA, esta reentrada NO
; toca vidas ($816A) ni puntuacion ($815A) -- solo reinicia el nivel a 0
; y continua con el resto de la preparacion. Confianza alta en la
; estructura (verificada byte a byte); confianza media en que sea
; intencional que la partida siguiente conserve vidas/puntuacion en vez
; de reiniciarlas del todo -- no se ha encontrado ningun otro punto en
; este tramo que las reinicie, asi que es el comportamiento real tal
; cual esta compilado.
;
; Si la puntuacion no es 0 (solo posible llegando por esta reentrada,
; nunca la primera vez), se ajusta a la baja el limite de persecucion
; de la IA ($8161, SRL+OR $03): parte de un valor 15/31/63/127/255
; (fijado en PANTALLA_OPCIONES) y lo reduce aproximadamente a la mitad
; (con suelo minimo efectivo de $03) -- un limite mas pequeno hace mas
; probable el 0 exacto de GENERAR_ALEATORIO en COLOCAR_ENTIDAD, es decir
; MAS persecucion/dificultad. Hipotesis media-alta: partidas sucesivas
; (tras completar el juego) se vuelven mas dificiles.
PREPARAR_NIVEL:
    XOR A                             ; 6534: af
    LD ($815C),A                      ; 6535: 325c81
    LD ($8169),A                      ; 6538: 326981
    LD HL,($815A)                     ; 653B: 2a5a81
    LD A,H                            ; 653E: 7c
    OR L                              ; 653F: b5
    JR Z,LIMPIAR_ESTADO_NIVEL          ; 6540: 280a
    LD A,($8161)                      ; 6542: 3a6181
    SRL A                             ; 6545: cb3f
    OR $03                            ; 6547: f603
    LD ($8161),A                      ; 6549: 326181

; BORRAR_BLOQUE_ESTADO limpia entidades/mapa/HUD; el bucle siguiente
; (DE=$00C8=200) es una pausa que bombea sonido -- mismo patron que
; otros retardos fijos del fichero.
LIMPIAR_ESTADO_NIVEL:
    CALL BORRAR_BLOQUE_ESTADO         ; 654C: cdab7e
    LD DE,$00C8                       ; 654F: 11c800
BUCLE_RETARDO_PREPARAR_NIVEL:
    PUSH DE                           ; 6552: d5
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 6553: cdd178
    POP DE                            ; 6556: d1
    DEC DE                            ; 6557: 1b
    LD A,D                            ; 6558: 7a
    OR E                              ; 6559: b3
    JR NZ,BUCLE_RETARDO_PREPARAR_NIVEL              ; 655A: 20f6

; Incrementa en paralelo un contador general ($8169, reutilizado --
; en el arranque del programa vale 6 para la demo de fondo del menu;
; aqui se reinicio a 0 en PREPARAR_NIVEL y ahora sube en sincronia con
; el nivel) y el nivel real ($815C). Si el nivel llega a 6 (completados
; los 5 niveles jugables, numerados 1..5) salta a PANTALLA_STOP_PRESS.
; Confianza alta en nivel/tope; media en el papel exacto de ($8169)
; aqui (structuralmente identico al nivel, sin uso propio localizado
; en este tramo mas alla de alimentar INICIALIZAR_ENTIDADES mas abajo).
    LD A,($8169)                      ; 655C: 3a6981
    INC A                             ; 655F: 3c
    LD ($8169),A                      ; 6560: 326981
    LD A,($815C)                      ; 6563: 3a5c81
    INC A                             ; 6566: 3c
    LD ($815C),A                      ; 6567: 325c81
    CP $06                            ; 656A: fe06
    JP Z,PANTALLA_STOP_PRESS          ; 656C: ca3967

; Limpia a mano el indice de entidades ($816C) y los 5 bytes de la
; entidad #1 ($816D-$8171) -- el hueco exacto que BORRAR_BLOQUE_ESTADO
; no cubre (su LDIR empieza en $8172). Tambien reinicia el flag de
; fotograma de animacion ($8158). Confianza alta (encaja exactamente
; con el limite documentado de BORRAR_BLOQUE_ESTADO, Sesion 8).
    XOR A                             ; 656F: af
    LD ($816C),A                      ; 6570: 326c81
    LD ($816D),A                      ; 6573: 326d81
    LD ($816E),A                      ; 6576: 326e81
    LD ($816F),A                      ; 6579: 326f81
    LD ($8170),A                      ; 657C: 327081
    LD ($8171),A                      ; 657F: 327181
    LD ($8158),A                      ; 6582: 325881

; PREPARAR_TESOROS_NIVEL ($6585): sin llamador externo dentro de lo ya
; reconstruido -- alcanzada solo por caida desde PREPARAR_NIVEL, se
; nombra igualmente por ser una unidad logica clara (regla del fichero:
; nombrar tramos grandes aunque solo tengan un llamador). Rellena de
; $60 (marcador "vacio") las 25 casillas $81DE-$81F6, y fuerza a 0 seis
; celdas concretas dentro de ese rango via IY+13/14/20/21/27/28
; (offsets de $81D6) -- hipotesis media: celdas fijas no disponibles
; para tesoros (paredes/columnas del diamante central de la piramide).
;
; El bucle de $65AD-$65D2 coloca 14 "tesoros" en casillas libres
; elegidas al azar dentro de $81DE-$81F7 (GENERAR_ALEATORIO(26)+8,
; reintenta si la celda no vale $60). El valor que escribe en cada
; celda sube de $10 en $10 (=$10,$20,$30,$40) y a partir de $50 se
; queda fijo en $50 para el resto de colocaciones -- confirmado leyendo
; el propio bucle (CP $50:JR Z,salta-el-incremento). Confianza alta en
; la estructura; media-alta en la interpretacion (tesoros con 4 valores
; crecientes seguidos de 10 tesoros "comunes" del valor mas alto,
; consistente con "colocacion aleatoria de 14 elementos" que dejo
; apuntado FINDINGS.md Sesion 12). Sin confirmar en emulador el efecto
; visual/de puntuacion exacto de cada valor.
PREPARAR_TESOROS_NIVEL:
    LD HL,$81DE                       ; 6585: 21de81
    LD A,$60                          ; 6588: 3e60
    LD (HL),A                         ; 658A: 77
    LD DE,$81DF                       ; 658B: 11df81
    LD BC,$0019                       ; 658E: 011900
    LDIR                              ; 6591: edb0
    XOR A                             ; 6593: af
    LD IY,$81D6                       ; 6594: fd21d681
    LD (IY+13),A                      ; 6598: fd770d
    LD (IY+14),A                      ; 659B: fd770e
    LD (IY+20),A                      ; 659E: fd7714
    LD (IY+21),A                      ; 65A1: fd7715
    LD (IY+27),A                      ; 65A4: fd771b
    LD (IY+28),A                      ; 65A7: fd771c
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 65AA: cdd178
    LD B,$0E                          ; 65AD: 060e
    LD A,$10                          ; 65AF: 3e10
BUCLE_COLOCAR_TESOROS_NIVEL:
    PUSH BC                           ; 65B1: c5
    PUSH AF                           ; 65B2: f5
BUSCAR_CASILLA_TESORO_LIBRE:
    LD A,$1A                          ; 65B3: 3e1a
    CALL GENERAR_ALEATORIO            ; 65B5: cd537d
    LD B,$08                          ; 65B8: 0608
    ADD A,B                           ; 65BA: 80
    LD HL,$81D6                       ; 65BB: 21d681
    LD B,$00                          ; 65BE: 0600
    LD C,A                            ; 65C0: 4f
    ADD HL,BC                         ; 65C1: 09
    LD A,(HL)                         ; 65C2: 7e
    CP $60                            ; 65C3: fe60
    JR NZ,BUSCAR_CASILLA_TESORO_LIBRE               ; 65C5: 20ec
    POP AF                            ; 65C7: f1
    LD (HL),A                         ; 65C8: 77
    POP BC                            ; 65C9: c1
    CP $50                            ; 65CA: fe50
    JR Z,CONTINUAR_BUCLE_TESOROS      ; 65CC: 2802
    ADD A,$10                         ; 65CE: c610
CONTINUAR_BUCLE_TESOROS:
    DJNZ BUCLE_COLOCAR_TESOROS_NIVEL                        ; 65D0: 10df
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 65D2: cdd178

; ACTUALIZAR_HUD_VIDAS ($65D5): redibuja una etiqueta ($8764, dato aun
; sin desglosar) y llama a IMPRIMIR_PUNTUACION_HUD (ver mas abajo, cierra
; el ultimo tramo del INCBIN en $7863-$786B). Despues dibuja tantos
; iconos de jugador ('A', $8155 avanzando de 4 en 4, alternando el
; fotograma via el flag $8158) como vidas queden en ($816A) -- por eso
; ($816A) se nombra VIDAS/NUM_VIDAS con confianza alta en su papel de
; "contador de vidas visible en el HUD": se inicializa a 5 en
; INICIAR_PARTIDA y puede subir hasta un tope de 7 como premio en
; PANTALLA_STOP_PRESS (ver mas abajo). Confianza MEDIA en que sea
; literalmente el clasico contador de "vidas restantes" que se
; consume al ser atrapado por una momia: no se ha localizado en este
; tramo ningun punto que lo DECREMENTE -- ese consumo, si existe,
; caeria dentro de alguna de las 4 llamadas todavia sin resolver del
; bucle principal ($7578/$77D1/$7637/$7566, ver BUCLE_PRINCIPAL_JUEGO).
ACTUALIZAR_HUD_VIDAS:
    LD HL,$8764                       ; 65D5: 216487
    CALL IMPRIMIR_BYTES_CON_LONGITUD             ; 65D8: cdf47e
    CALL IMPRIMIR_PUNTUACION_HUD      ; 65DB: cd6378
    LD A,$01                          ; 65DE: 3e01
    CALL FIRM_TXT_SET_PAPER           ; 65E0: cd96bb
    LD A,($816A)                      ; 65E3: 3a6a81
    LD B,A                            ; 65E6: 47
    LD A,$02                          ; 65E7: 3e02
    LD ($8157),A                      ; 65E9: 325781
    LD DE,$0034                       ; 65EC: 113400
    LD ($8155),DE                     ; 65EF: ed535581
BUCLE_DIBUJAR_ICONOS_VIDAS:
    PUSH BC                           ; 65F3: c5
    LD A,$41                          ; 65F4: 3e41
    CALL DIBUJAR_ENTIDAD              ; 65F6: cd397b
    LD A,($8158)                      ; 65F9: 3a5881
    XOR $01                           ; 65FC: ee01
    LD ($8158),A                      ; 65FE: 325881
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 6601: cdd178
    LD DE,($8155)                     ; 6604: ed5b5581
    LD HL,$0004                       ; 6608: 210400
    ADD HL,DE                         ; 660B: 19
    LD ($8155),HL                     ; 660C: 225581
    EX DE,HL                          ; 660F: eb
    POP BC                            ; 6610: c1
    DJNZ BUCLE_DIBUJAR_ICONOS_VIDAS                        ; 6611: 10e0

; LIMPIAR_PANELES_NIVEL ($6613): 9 llamadas a BORRAR_RECTANGULO_VENTANA
; con pares HL/DE distintos (mismo patron ya documentado en el arranque
; del programa, $60AD y siguientes) -- despeja los paneles del HUD/marco
; antes de dibujar el nivel. Confianza alta en la estructura (identica
; al patron ya confirmado), media en el detalle exacto de cada panel.
LIMPIAR_PANELES_NIVEL:
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 6613: cdd178
    LD HL,$0203                       ; 6616: 210302
    LD DE,$2604                       ; 6619: 110426
    CALL BORRAR_RECTANGULO_VENTANA    ; 661C: cdb97e
    LD HL,$0408                       ; 661F: 210804
    LD DE,$2409                       ; 6622: 110924
    CALL BORRAR_RECTANGULO_VENTANA    ; 6625: cdb97e
    LD HL,$040D                       ; 6628: 210d04
    LD DE,$240E                       ; 662B: 110e24
    CALL BORRAR_RECTANGULO_VENTANA    ; 662E: cdb97e
    LD HL,$0412                       ; 6631: 211204
    LD DE,$2413                       ; 6634: 111324
    CALL BORRAR_RECTANGULO_VENTANA    ; 6637: cdb97e
    LD HL,$0217                       ; 663A: 211702
    LD DE,$2618                       ; 663D: 111826
    CALL BORRAR_RECTANGULO_VENTANA    ; 6640: cdb97e
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 6643: cdd178
    LD HL,$0205                       ; 6646: 210502
    LD DE,$0316                       ; 6649: 111603
    CALL BORRAR_RECTANGULO_VENTANA    ; 664C: cdb97e
    LD HL,$0905                       ; 664F: 210509
    LD DE,$0A16                       ; 6652: 11160a
    CALL BORRAR_RECTANGULO_VENTANA    ; 6655: cdb97e
    LD HL,$1001                       ; 6658: 210110
    LD DE,$1116                       ; 665B: 111611
    CALL BORRAR_RECTANGULO_VENTANA    ; 665E: cdb97e
    LD HL,$1705                       ; 6661: 210517
    LD DE,$1816                       ; 6664: 111618
    CALL BORRAR_RECTANGULO_VENTANA    ; 6667: cdb97e
    LD HL,$1E05                       ; 666A: 21051e
    LD DE,$1F16                       ; 666D: 11161f
    CALL BORRAR_RECTANGULO_VENTANA    ; 6670: cdb97e
    LD HL,$2505                       ; 6673: 210525
    LD DE,$2616                       ; 6676: 111626
    CALL BORRAR_RECTANGULO_VENTANA    ; 6679: cdb97e
    LD HL,$0000                       ; 667C: 210000
    LD DE,$2718                       ; 667F: 111827
    CALL FIRM_TXT_WIN_ENABLE          ; 6682: cd66bb

; SELECCIONAR_DIAGONAL_MARCO_NIVEL ($6685): RESUELVE el pendiente
; explicito de la Sesion 7/12 -- el llamador de RELLENAR_MARCO_DIAGONAL_
; 1..6. Segun el nivel actual ($815C) elige una de 5 variantes (nivel
; 0/1->_6, 2->_4, 3->_5, 4->_1, >=5->_3; _2 SIGUE sin usarse en ningun
; punto de este tramo, confirma la sospecha de la Sesion 12) y parchea
; con codigo automodificable el operando de "CALL $7E29" en $66B9 (los
; 2 bytes en $66BA) para que apunte a la variante elegida antes de
; ejecutarla. El bucle de B=4 (paso HL+=$2800) anidado con B=5 (paso
; HL+=$000E) dibuja una rejilla de 4x5=20 bloques diagonales -- probable
; borde/patron decorativo de la piramide de este nivel. Confianza alta
; en la estructura (verificada byte a byte, cuadra exacto con la
; pista dejada por la Sesion 12); confianza media en el papel visual
; exacto (sin confirmar en emulador).
SELECCIONAR_DIAGONAL_MARCO_NIVEL:
    LD A,($815C)                      ; 6685: 3a5c81
    CP $02                            ; 6688: fe02
    JR C,SELECCIONAR_VARIANTE_MARCO_6 ; 668A: 381c
    JR Z,SELECCIONAR_VARIANTE_MARCO_4 ; 668C: 2815
    CP $04                            ; 668E: fe04
    JR C,SELECCIONAR_VARIANTE_MARCO_5 ; 6690: 380c
    JR Z,SELECCIONAR_VARIANTE_MARCO_1 ; 6692: 2805
    LD HL,RELLENAR_MARCO_DIAGONAL_3   ; 6694: 210e7e
    JR PARCHEAR_LLAMADA_MARCO_DIAGONAL ; 6697: 1812
SELECCIONAR_VARIANTE_MARCO_1:
    LD HL,RELLENAR_MARCO_DIAGONAL_1   ; 6699: 21fc7d
    JR PARCHEAR_LLAMADA_MARCO_DIAGONAL ; 669C: 180d
SELECCIONAR_VARIANTE_MARCO_5:
    LD HL,RELLENAR_MARCO_DIAGONAL_5   ; 669E: 21207e
    JR PARCHEAR_LLAMADA_MARCO_DIAGONAL ; 66A1: 1808
SELECCIONAR_VARIANTE_MARCO_4:
    LD HL,RELLENAR_MARCO_DIAGONAL_4   ; 66A3: 21177e
    JR PARCHEAR_LLAMADA_MARCO_DIAGONAL ; 66A6: 1803
SELECCIONAR_VARIANTE_MARCO_6:
    LD HL,RELLENAR_MARCO_DIAGONAL_6   ; 66A8: 21297e
PARCHEAR_LLAMADA_MARCO_DIAGONAL:
    LD ($66BA),HL                     ; 66AB: 22ba66
    LD B,$04                          ; 66AE: 0604
    LD HL,$2808                       ; 66B0: 210828
BUCLE_DIBUJAR_FONDO_FILA:
    PUSH BC                           ; 66B3: c5
    PUSH HL                           ; 66B4: e5
    LD B,$05                          ; 66B5: 0605
BUCLE_DIBUJAR_FONDO_COLUMNA:
    PUSH BC                           ; 66B7: c5
    PUSH HL                           ; 66B8: e5
    CALL RELLENAR_MARCO_DIAGONAL_6    ; 66B9: cd297e
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 66BC: cdd178
    POP HL                            ; 66BF: e1
    LD BC,$000E                       ; 66C0: 010e00
    ADD HL,BC                         ; 66C3: 09
    POP BC                            ; 66C4: c1
    DJNZ BUCLE_DIBUJAR_FONDO_COLUMNA                        ; 66C5: 10f0
    POP HL                            ; 66C7: e1
    LD BC,$2800                       ; 66C8: 010028
    ADD HL,BC                         ; 66CB: 09
    POP BC                            ; 66CC: c1
    DJNZ BUCLE_DIBUJAR_FONDO_FILA                        ; 66CD: 10e4

; COLOCAR_JUGADOR_INICIAL ($66CF): fija el puntero de posiciones
; (VARIABLE_TEMPORAL_HL_1 = TABLA_POSICIONES_INICIALES_ENTIDADES-2, el
; mismo puntero base que usa la demo de fondo del menu en $61E5) y
; llama a INICIALIZAR_ENTIDADES -- coloca tantas entidades
; (enemigos/coleccionables) como indique ($8169), que en PREPARAR_NIVEL
; se dejo sincronizado con el nivel actual (hipotesis media-alta: cada
; nivel introduce tantos enemigos como su numero). Despues dibuja al
; jugador ('A') en la posicion de salida fija $0820 con ($8157)=3.
; Confianza alta en la estructura; media en el papel exacto de
; ($8157)=3 (una de las 4 orientaciones/grupos de SPRITE_JUGADOR_Gx,
; sin resolver cual exactamente -- pendiente de sesiones anteriores).
COLOCAR_JUGADOR_INICIAL:
    LD HL,TABLA_POSICIONES_INICIALES_ENTIDADES-2                       ; 66CF: 210f86
    LD (VARIABLE_TEMPORAL_HL_1),HL                     ; 66D2: 224586
    CALL INICIALIZAR_ENTIDADES        ; 66D5: cd4f79
    LD DE,$0820                       ; 66D8: 112008
    LD ($8155),DE                     ; 66DB: ed535581
    LD A,$03                          ; 66DF: 3e03
    LD ($8157),A                      ; 66E1: 325781
    LD A,$41                          ; 66E4: 3e41
    CALL DIBUJAR_ENTIDAD              ; 66E6: cd397b
    XOR A                             ; 66E9: af
    CALL FIRM_TXT_SET_PAPER           ; 66EA: cd96bb

; BUCLE_PRINCIPAL_JUEGO ($66ED): RESUELVE el bucle de juego que dejaba
; apuntado FINDINGS.md Sesion 12. Empieza comprobando la tecla 'B' --
; confirmado que AMBAS ramas (pulsada o no) confluyen en el mismo
; destino, TRAMPOLIN_TECLA_B/INICIO_TURNO_JUGADOR1 -- sin efecto
; funcional observable (confianza alta en la estructura, verificada
; byte a byte; confianza baja en su proposito: posible resto de una
; funcionalidad no terminada, o un simple consumo del buffer de
; teclado). Para cada jugador (B=1, luego B=2) hace: ANIMAR_OPCION_MENU,
; y una secuencia de 4 llamadas -- $7578, $77D1, $7637, $7566 -- que la
; Sesion 14 identifico y nombro (ver $68B2-$7862 mas abajo):
; PROCESAR_ENCUENTROS_ENTIDADES, PROCESAR_MOVIMIENTO_JUGADOR,
; ACTUALIZAR_MARCO_TRAS_MOVIMIENTO y COMPROBAR_SALIDA_NIVEL, que
; implementan el movimiento/logica de turno de cada jugador -- 2 de
; ellas comprueban el acarreo ("JP C,PANTALLA_GAME_OVER") tras
; CALL $7578, hipotesis alta de que el acarreo senaliza "jugador
; atrapado por una momia" (fin de partida inmediato). Tras ambos
; jugadores, comprueba si hay coleccionables restantes (($816D),
; primer byte de la entidad #1) y si no hay ninguno CALL NZ,$7513
; (tambien sin resolver -- hipotesis media: avance al siguiente nivel,
; posible punto de reentrada a PREPARAR_NIVEL o similar sin confirmar).
; Confianza alta en la estructura general (verificada byte a byte);
; media en el papel de cada llamada sin resolver -- pendiente para la
; siguiente sesion resolver $7578/$77D1/$7637/$7566/$7513.
BUCLE_PRINCIPAL_JUEGO:
    LD A,$42                          ; 66ED: 3e42
    CALL FIRM_KM_TEST_KEY             ; 66EF: cd1ebb
    JP NZ,TRAMPOLIN_TECLA_B           ; 66F2: c2af68
INICIO_TURNO_JUGADOR1:
    LD B,$01                          ; 66F5: 0601
    CALL ANIMAR_OPCION_MENU           ; 66F7: cdb778
    CALL PROCESAR_ENCUENTROS_ENTIDADES ; 66FA: cd7875
    JP C,PANTALLA_GAME_OVER           ; 66FD: dab367
    CALL PROCESAR_MOVIMIENTO_JUGADOR   ; 6700: cdd177
    CALL PROCESAR_ENCUENTROS_ENTIDADES ; 6703: cd7875
    JP C,PANTALLA_GAME_OVER           ; 6706: dab367
    CALL ACTUALIZAR_MARCO_TRAS_MOVIMIENTO ; 6709: cd3776
    CALL COMPROBAR_SALIDA_NIVEL        ; 670C: cd6675
    CALL ESPERAR_TECLA_2C             ; 670F: cd9378
    LD A,($816D)                      ; 6712: 3a6d81
    OR A                              ; 6715: b7
    CALL NZ,ANIMAR_APARICION_MOMIA_GUARDIANA ; 6716: c41375
    LD B,$02                          ; 6719: 0602
    CALL ANIMAR_OPCION_MENU           ; 671B: cdb778
    CALL PROCESAR_ENCUENTROS_ENTIDADES ; 671E: cd7875
    JP C,PANTALLA_GAME_OVER           ; 6721: dab367
    CALL PROCESAR_MOVIMIENTO_JUGADOR   ; 6724: cdd177
    CALL PROCESAR_ENCUENTROS_ENTIDADES ; 6727: cd7875
    JP C,PANTALLA_GAME_OVER           ; 672A: dab367
    CALL ACTUALIZAR_MARCO_TRAS_MOVIMIENTO ; 672D: cd3776
    CALL COMPROBAR_SALIDA_NIVEL        ; 6730: cd6675
    CALL ESPERAR_TECLA_2C             ; 6733: cd9378
    JP BUCLE_PRINCIPAL_JUEGO          ; 6736: c3ed66

; PANTALLA_STOP_PRESS ($6739): alcanzada solo al completar los 6
; niveles ("JP Z,PANTALLA_STOP_PRESS" en PREPARAR_NIVEL). Imprime la
; noticia de periodico "STOP PRESS...excavation of ancient Egyptian
; pyramid" (TEXTO_HISTORIA_ATRACCION, Sesion 8) y sortea (GENERAR_
; ALEATORIO(2)) entre dar 200 puntos de bonus ("his efforts of 200
; points") o -- si ($816A, vidas) no ha llegado ya al tope de 7 --
; conceder una vida extra ("extra man for next dig", $816A++); si ya
; esta en 7 tambien da los 200 puntos. Termina esperando 'L' o Intro,
; y en ese caso salta DIRECTAMENTE a PREPARAR_NIVEL -- IMPORTANTE:
; confirmado que este camino NO pasa por ACTUALIZAR_TABLA_PUNTUACIONES,
; es decir, "ganar" completando los 6 niveles no ofrece insertar la
; puntuacion en la tabla de highscores en este tramo (solo lo hace
; PANTALLA_GAME_OVER, alcanzada por "morir"). Confianza alta en toda
; la estructura (verificada byte a byte); es una asimetria real del
; juego compilado, no una hipotesis.
PANTALLA_STOP_PRESS:
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 6739: cdd178
    LD HL,$801B                       ; 673C: 211b80
    CALL IMPRIMIR_BYTES_CON_LONGITUD             ; 673F: cdf47e
    LD HL,$8040                       ; 6742: 214080
    CALL IMPRIMIR_BYTES_CON_LONGITUD             ; 6745: cdf47e
    LD HL,$8064                       ; 6748: 216480
    CALL IMPRIMIR_BYTES_CON_LONGITUD             ; 674B: cdf47e
    LD HL,$8088                       ; 674E: 218880
    CALL IMPRIMIR_BYTES_CON_LONGITUD             ; 6751: cdf47e
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 6754: cdd178
    LD HL,$809D                       ; 6757: 219d80
    CALL IMPRIMIR_BYTES_CON_LONGITUD             ; 675A: cdf47e
    LD A,$02                          ; 675D: 3e02
    CALL GENERAR_ALEATORIO            ; 675F: cd537d
    OR A                              ; 6762: b7
    JR Z,COMPROBAR_VIDA_EXTRA_STOP_PRESS ; 6763: 2819
DAR_BONUS_PUNTOS_STOP_PRESS:
    LD HL,($815A)                     ; 6765: 2a5a81
    LD BC,$00C8                       ; 6768: 01c800
    ADD HL,BC                         ; 676B: 09
    LD ($815A),HL                     ; 676C: 225a81
    LD HL,$80B8                       ; 676F: 21b880
    CALL IMPRIMIR_BYTES_CON_LONGITUD             ; 6772: cdf47e
    LD HL,$80C2                       ; 6775: 21c280
    CALL IMPRIMIR_BYTES_CON_LONGITUD             ; 6778: cdf47e
    JP MOSTRAR_CONFIRMACION_STOP_PRESS ; 677B: c39567
COMPROBAR_VIDA_EXTRA_STOP_PRESS:
    LD A,($816A)                      ; 677E: 3a6a81
    CP $07                            ; 6781: fe07
    JR Z,DAR_BONUS_PUNTOS_STOP_PRESS  ; 6783: 28e0
    INC A                             ; 6785: 3c
    LD ($816A),A                      ; 6786: 326a81
    LD HL,$80E0                       ; 6789: 21e080
    CALL IMPRIMIR_BYTES_CON_LONGITUD             ; 678C: cdf47e
    LD HL,$80EA                       ; 678F: 21ea80
    CALL IMPRIMIR_BYTES_CON_LONGITUD             ; 6792: cdf47e
MOSTRAR_CONFIRMACION_STOP_PRESS:
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 6795: cdd178
    LD HL,$80FB                       ; 6798: 21fb80
    CALL IMPRIMIR_BYTES_CON_LONGITUD             ; 679B: cdf47e
BUCLE_CONFIRMAR_STOP_PRESS:
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 679E: cdd178
    LD A,$4C                          ; 67A1: 3e4c
    CALL FIRM_KM_TEST_KEY             ; 67A3: cd1ebb
    JP NZ,PREPARAR_NIVEL              ; 67A6: c23465
    LD A,$3E                          ; 67A9: 3e3e
    CALL FIRM_KM_TEST_KEY             ; 67AB: cd1ebb
    JP NZ,PREPARAR_NIVEL              ; 67AE: c23465
    JR BUCLE_CONFIRMAR_STOP_PRESS     ; 67B1: 18eb

; PANTALLA_GAME_OVER ($67B3): alcanzada solo por las 4 "JP C,
; PANTALLA_GAME_OVER" del bucle principal (acarreo = jugador atrapado,
; hipotesis alta). Imprime el titulo "GAME OVER" (TEXTO_HISTORIA_
; ATRACCION+$108, ya confirmado como texto literal en Sesion 8) letra
; a letra con una pausa de $0400 iteraciones entre cada una (efecto de
; revelado dramatico), mas una pausa final de $4000 iteraciones, y
; despues entra en ACTUALIZAR_TABLA_PUNTUACIONES sin preguntar nada --
; a diferencia de PANTALLA_STOP_PRESS, aqui NO hay espera de tecla
; L/Intro: se pasa automaticamente a comprobar/insertar la puntuacion.
; Confianza alta (verificada byte a byte).
PANTALLA_GAME_OVER:
    LD HL,$8125                       ; 67B3: 212581
    CALL IMPRIMIR_BYTES_CON_LONGITUD             ; 67B6: cdf47e
    LD HL,$090A                       ; 67B9: 210a09
    LD DE,$1F11                       ; 67BC: 11111f
    CALL BORRAR_RECTANGULO_VENTANA    ; 67BF: cdb97e
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 67C2: cdd178
    LD HL,$0000                       ; 67C5: 210000
    LD DE,$2718                       ; 67C8: 111827
    CALL FIRM_TXT_WIN_ENABLE          ; 67CB: cd66bb
    LD HL,$0D0E                       ; 67CE: 210e0d
    CALL FIRM_TXT_SET_CURSOR          ; 67D1: cd75bb
    LD HL,$812D                       ; 67D4: 212d81
    LD B,$09                          ; 67D7: 0609
BUCLE_IMPRIMIR_GAME_OVER:
    PUSH BC                           ; 67D9: c5
    PUSH HL                           ; 67DA: e5
    LD DE,$0400                       ; 67DB: 110004
BUCLE_RETARDO_LETRA_GAME_OVER:
    PUSH DE                           ; 67DE: d5
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 67DF: cdd178
    POP DE                            ; 67E2: d1
    DEC DE                            ; 67E3: 1b
    LD A,D                            ; 67E4: 7a
    OR E                              ; 67E5: b3
    JR NZ,BUCLE_RETARDO_LETRA_GAME_OVER             ; 67E6: 20f6
    POP HL                            ; 67E8: e1
    LD A,(HL)                         ; 67E9: 7e
    INC HL                            ; 67EA: 23
    CALL FIRM_TXT_OUTPUT              ; 67EB: cd5abb
    LD A,$20                          ; 67EE: 3e20
    CALL FIRM_TXT_OUTPUT              ; 67F0: cd5abb
    POP BC                            ; 67F3: c1
    DJNZ BUCLE_IMPRIMIR_GAME_OVER                        ; 67F4: 10e3
    LD DE,$4000                       ; 67F6: 110040
BUCLE_RETARDO_FINAL_GAME_OVER:
    PUSH DE                           ; 67F9: d5
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 67FA: cdd178
    POP DE                            ; 67FD: d1
    DEC DE                            ; 67FE: 1b
    LD A,D                            ; 67FF: 7a
    OR E                              ; 6800: b3
    JR NZ,BUCLE_RETARDO_FINAL_GAME_OVER             ; 6801: 20f6

; ACTUALIZAR_TABLA_PUNTUACIONES ($6803): compara la puntuacion actual
; ($815A) contra la ultima entrada (mas baja) de la tabla HI-SCORE de 5
; entradas de 18 bytes en $86C2-$8749 (confirmada por el codigo del
; propio arranque del programa, $6310-$6325, que ya la lee para
; mostrarla). Si no supera ni siquiera la ultima entrada (acarreo),
; salta a $6039 -- DENTRO de la cabecera ya reconstruida, justo el
; punto que reinicia la semilla aleatoria y encadena con
; BORRAR_BLOQUE_ESTADO/dibujo del marco/tabla de puntuaciones/menu
; principal -- es decir, vuelve al modo atraccion sin pedir nombre.
; Si SI hay una puntuacion nueva: activa ($8168)=1 (el flag que
; REANUDAR_MENU_TRAS_NOMBRE usa para saber si hay que teclear un
; nombre -- Sesion 12), calcula el rango (1-5) comparando contra cada
; entrada de la tabla (IX retrocede 18 bytes por cada entrada superior
; que encuentra), fija la ventana de texto para la fila de entrada del
; nombre segun el rango, desplaza con LDIR las entradas peores un
; puesto hacia abajo, y escribe la puntuacion nueva + 11 espacios (el
; hueco del nombre, que se rellenara letra a letra en el bucle de
; tecleo de nombre ya reconstruido) en el hueco liberado. Termina con
; "JP $6223" -- tambien dentro de la cabecera ya reconstruida, la
; pantalla que dibuja los indicadores de 1/2 jugadores y de ahi cae en
; el bucle de tecleo de nombre. Confianza alta en toda la estructura
; (verificada byte a byte, encaja exactamente con el codigo de lectura
; de la tabla ya confirmado en la cabecera).
ACTUALIZAR_TABLA_PUNTUACIONES:
    XOR A                             ; 6803: af
    LD HL,($815A)                     ; 6804: 2a5a81
    LD BC,($86D4)                     ; 6807: ed4bd486
    SBC HL,BC                         ; 680B: ed42
    JP C,REINICIAR_MODO_ATRACCION                        ; 680D: da3960
    LD A,$01                          ; 6810: 3e01
    LD ($8168),A                      ; 6812: 326881
    LD DE,$0012                       ; 6815: 111200
    LD IX,$86D4                       ; 6818: dd21d486
    XOR A                             ; 681C: af
    LD B,$05                          ; 681D: 0605
BUCLE_CALCULAR_RANGO_PUNTUACION:
    PUSH BC                           ; 681F: c5
    LD HL,($815A)                     ; 6820: 2a5a81
    LD C,(IX+0)                       ; 6823: dd4e00
    LD B,(IX+1)                       ; 6826: dd4601
    SBC HL,BC                         ; 6829: ed42
    POP BC                            ; 682B: c1
    JR Z,FIJAR_RANGO_PUNTUACION       ; 682C: 280d
    JR C,COMPLETAR_RANGO_PUNTUACION   ; 682E: 380a
    PUSH IX                           ; 6830: dde5
    POP HL                            ; 6832: e1
    SBC HL,DE                         ; 6833: ed52
    PUSH HL                           ; 6835: e5
    POP IX                            ; 6836: dde1
    DJNZ BUCLE_CALCULAR_RANGO_PUNTUACION                        ; 6838: 10e5
COMPLETAR_RANGO_PUNTUACION:
    INC B                             ; 683A: 04
FIJAR_RANGO_PUNTUACION:
    LD A,B                            ; 683B: 78
    ADD A,A                           ; 683C: 87
    ADD A,$08                         ; 683D: c608
    LD H,$12                          ; 683F: 2612
    LD L,A                            ; 6841: 6f
    LD ($7FC6),HL                     ; 6842: 22c67f
    LD HL,$86D4                       ; 6845: 21d486
    LD A,$05                          ; 6848: 3e05
    CP B                              ; 684A: b8
    JR Z,ESCRIBIR_PUNTUACION_EN_TABLA ; 684B: 2846
    SUB B                             ; 684D: 90
    LD B,A                            ; 684E: 47
    PUSH BC                           ; 684F: c5
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 6850: cdd178
    POP BC                            ; 6853: c1
    LD HL,$86C2                       ; 6854: 21c286
    LD DE,$86D4                       ; 6857: 11d486
BUCLE_DESPLAZAR_TABLA_PUNTUACIONES:
    PUSH BC                           ; 685A: c5
    LD BC,$0012                       ; 685B: 011200
    LDIR                              ; 685E: edb0
    XOR A                             ; 6860: af
    LD BC,$0024                       ; 6861: 012400
    SBC HL,BC                         ; 6864: ed42
    EX DE,HL                          ; 6866: eb
    SBC HL,BC                         ; 6867: ed42
    EX DE,HL                          ; 6869: eb
    POP BC                            ; 686A: c1
    DJNZ BUCLE_DESPLAZAR_TABLA_PUNTUACIONES                        ; 686B: 10ed
    PUSH HL                           ; 686D: e5
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 686E: cdd178
    POP HL                            ; 6871: e1
    LD BC,$0012                       ; 6872: 011200
    ADD HL,BC                         ; 6875: 09
    PUSH HL                           ; 6876: e5
    LD HL,$8691                       ; 6877: 219186
    LD A,$0A                          ; 687A: 3e0a
    LD (HL),A                         ; 687C: 77
    ADD HL,BC                         ; 687D: 09
    LD A,$0C                          ; 687E: 3e0c
    LD (HL),A                         ; 6880: 77
    ADD HL,BC                         ; 6881: 09
    LD A,$0E                          ; 6882: 3e0e
    LD (HL),A                         ; 6884: 77
    ADD HL,BC                         ; 6885: 09
    LD A,$10                          ; 6886: 3e10
    LD (HL),A                         ; 6888: 77
    ADD HL,BC                         ; 6889: 09
    LD A,$12                          ; 688A: 3e12
    LD (HL),A                         ; 688C: 77
    LD HL,$86D6                       ; 688D: 21d686
    DEC A                             ; 6890: 3d
    LD (HL),A                         ; 6891: 77
    POP HL                            ; 6892: e1
ESCRIBIR_PUNTUACION_EN_TABLA:
    LD DE,($815A)                     ; 6893: ed5b5a81
    LD (HL),E                         ; 6897: 73
    INC HL                            ; 6898: 23
    LD (HL),D                         ; 6899: 72
    LD BC,$0005                       ; 689A: 010500
    ADD HL,BC                         ; 689D: 09
    LD ($7FC8),HL                     ; 689E: 22c87f
    LD A,$20                          ; 68A1: 3e20
    LD (HL),A                         ; 68A3: 77
    PUSH HL                           ; 68A4: e5
    POP DE                            ; 68A5: d1
    INC DE                            ; 68A6: 13
    LD BC,$000B                       ; 68A7: 010b00
    LDIR                              ; 68AA: edb0
    JP PREPARAR_ENTRADA_NOMBRE                          ; 68AC: c32362

; TRAMPOLIN_TECLA_B ($68AF): destino de la comprobacion de la tecla
; 'B' al principio de BUCLE_PRINCIPAL_JUEGO -- ver comentario alli.
TRAMPOLIN_TECLA_B:
    JP INICIO_TURNO_JUGADOR1          ; 68AF: c3f566

; ---- PANTALLA_INSTRUCCIONES / IMPRIMIR_PARRAFO_INSTRUCCIONES / LIMPIAR_VENTANA_INSTRUCCIONES /
; RESTAURAR_VENTANA_TEXTO_COMPLETA / ESPERAR_CONTINUAR_INSTRUCCIONES ----
; Sesion 14: primer tramo del ultimo hueco del motor ($68B2-$69EA, 313
; bytes). Destino de la entrada 'I'/'i' (instrucciones) desde
; DESPACHAR_MENU_PRINCIPAL (dos "JP Z,$68B2" ya reconstruidos). Es un
; DESPACHADOR de pantalla de texto a paginas: dibuja dos iconos de
; contenido de casilla (DIBUJAR_ICONO_SARCOFAGO/DIBUJAR_ICONO_LLAVE,
; Sesion 17 -- ver mas abajo, antes mal identificados como "marco
; decorativo") como cabecera visual y despues
; imprime, en orden, los 23 parrafos de texto literal declarados mas abajo
; (TEXTO_INSTR_01..23 -- el texto real de "OH MUMMY" en ingles: historia,
; reglas del tablero de 20 casillas, controles y niveles de dificultad),
; con una pausa "pulsa C o el boton de fuego para continuar" entre grupos
; de 2-3 parrafos (ESPERAR_CONTINUAR_INSTRUCCIONES). Confianza ALTA --
; verificado instruccion a instruccion; la Sesion 13 ya habia intuido esta
; estructura sin promoverla a codigo fuente (ver FINDINGS.md Sesion 13),
; esta sesion la confirma y establece el limite EXACTO (verificado con el
; primer byte de longitud de cada bloque de texto, ver mas abajo) entre
; el codigo del despachador y el primer bloque de texto en $69EB.
PANTALLA_INSTRUCCIONES:
    LD HL,TEXTO_INSTR_01              ; 68B2: 21eb69
    CALL IMPRIMIR_PARRAFO_INSTRUCCIONES; 68B5: cdd269
    CALL LIMPIAR_VENTANA_INSTRUCCIONES; 68B8: cd8a69
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 68BB: cdd178
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 68BE: cdd178
    LD HL,$0004                       ; 68C1: 210400
    CALL DIBUJAR_ICONO_SARCOFAGO        ; 68C4: cd857d
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 68C7: cdd178
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 68CA: cdd178
    LD HL,$0042                       ; 68CD: 214200
    CALL DIBUJAR_ICONO_LLAVE        ; 68D0: cd9d7d
    LD HL,TEXTO_INSTR_02              ; 68D3: 21f469
    CALL IMPRIMIR_PARRAFO_INSTRUCCIONES; 68D6: cdd269
    LD HL,TEXTO_INSTR_03              ; 68D9: 210f6a
    CALL IMPRIMIR_PARRAFO_INSTRUCCIONES; 68DC: cdd269
    LD HL,TEXTO_INSTR_04              ; 68DF: 21ba6a
    CALL IMPRIMIR_PARRAFO_INSTRUCCIONES; 68E2: cdd269
    CALL ESPERAR_CONTINUAR_INSTRUCCIONES; 68E5: cdac69
    CALL LIMPIAR_VENTANA_INSTRUCCIONES; 68E8: cd8a69
    LD HL,TEXTO_INSTR_05              ; 68EB: 21786b
    CALL IMPRIMIR_PARRAFO_INSTRUCCIONES; 68EE: cdd269
    LD HL,TEXTO_INSTR_06              ; 68F1: 21ec6b
    CALL IMPRIMIR_PARRAFO_INSTRUCCIONES; 68F4: cdd269
    LD HL,TEXTO_INSTR_07              ; 68F7: 21756c
    CALL IMPRIMIR_PARRAFO_INSTRUCCIONES; 68FA: cdd269
    CALL ESPERAR_CONTINUAR_INSTRUCCIONES; 68FD: cdac69
    CALL LIMPIAR_VENTANA_INSTRUCCIONES; 6900: cd8a69
    LD HL,TEXTO_INSTR_08              ; 6903: 21e06c
    CALL IMPRIMIR_PARRAFO_INSTRUCCIONES; 6906: cdd269
    LD HL,TEXTO_INSTR_09              ; 6909: 213a6d
    CALL IMPRIMIR_PARRAFO_INSTRUCCIONES; 690C: cdd269
    LD HL,TEXTO_INSTR_10              ; 690F: 21a26d
    CALL IMPRIMIR_PARRAFO_INSTRUCCIONES; 6912: cdd269
    CALL ESPERAR_CONTINUAR_INSTRUCCIONES; 6915: cdac69
    CALL LIMPIAR_VENTANA_INSTRUCCIONES; 6918: cd8a69
    LD HL,TEXTO_INSTR_11              ; 691B: 210a6e
    CALL IMPRIMIR_PARRAFO_INSTRUCCIONES; 691E: cdd269
    LD HL,TEXTO_INSTR_12              ; 6921: 21966e
    CALL IMPRIMIR_PARRAFO_INSTRUCCIONES; 6924: cdd269
    CALL ESPERAR_CONTINUAR_INSTRUCCIONES; 6927: cdac69
    CALL LIMPIAR_VENTANA_INSTRUCCIONES; 692A: cd8a69
    LD HL,TEXTO_INSTR_13              ; 692D: 217d6f
    CALL IMPRIMIR_PARRAFO_INSTRUCCIONES; 6930: cdd269
    LD HL,TEXTO_INSTR_14              ; 6933: 213c70
    CALL IMPRIMIR_PARRAFO_INSTRUCCIONES; 6936: cdd269
    CALL ESPERAR_CONTINUAR_INSTRUCCIONES; 6939: cdac69
    CALL LIMPIAR_VENTANA_INSTRUCCIONES; 693C: cd8a69
    LD HL,TEXTO_INSTR_15              ; 693F: 21ae70
    CALL IMPRIMIR_PARRAFO_INSTRUCCIONES; 6942: cdd269
    LD HL,TEXTO_INSTR_16              ; 6945: 217071
    CALL IMPRIMIR_PARRAFO_INSTRUCCIONES; 6948: cdd269
    CALL ESPERAR_CONTINUAR_INSTRUCCIONES; 694B: cdac69
    CALL LIMPIAR_VENTANA_INSTRUCCIONES; 694E: cd8a69
    LD HL,TEXTO_INSTR_17              ; 6951: 21f471
    CALL IMPRIMIR_PARRAFO_INSTRUCCIONES; 6954: cdd269
    LD HL,TEXTO_INSTR_18              ; 6957: 218872
    CALL IMPRIMIR_PARRAFO_INSTRUCCIONES; 695A: cdd269
    CALL ESPERAR_CONTINUAR_INSTRUCCIONES; 695D: cdac69
    CALL LIMPIAR_VENTANA_INSTRUCCIONES; 6960: cd8a69
    LD HL,TEXTO_INSTR_19              ; 6963: 216e73
    CALL IMPRIMIR_PARRAFO_INSTRUCCIONES; 6966: cdd269
    LD HL,TEXTO_INSTR_20              ; 6969: 218d73
    CALL IMPRIMIR_PARRAFO_INSTRUCCIONES; 696C: cdd269
    LD HL,TEXTO_INSTR_21              ; 696F: 21dd73
    CALL IMPRIMIR_PARRAFO_INSTRUCCIONES; 6972: cdd269
    LD HL,TEXTO_INSTR_22              ; 6975: 212474
    CALL IMPRIMIR_PARRAFO_INSTRUCCIONES; 6978: cdd269
    LD HL,TEXTO_INSTR_23              ; 697B: 21e774
    CALL IMPRIMIR_PARRAFO_INSTRUCCIONES; 697E: cdd269
    CALL ESPERAR_CONTINUAR_INSTRUCCIONES; 6981: cdac69
    CALL RESTAURAR_VENTANA_TEXTO_COMPLETA; 6984: cd9c69
    JP PREPARAR_ENTRADA_NOMBRE                          ; 6987: c32362

; LIMPIAR_VENTANA_INSTRUCCIONES ($698A): pausa de sonido + define una
; ventana de texto (HL=$0005/DE=$2718, ver firmware TXT WIN ENABLE) y la
; borra -- hipotesis media en la geometria exacta de la ventana (formato
; de parametros H/L/D/E sin confirmar del todo). Cae directamente en
; RESTAURAR_VENTANA_TEXTO_COMPLETA para volver a dejar la ventana de texto
; a pantalla completa (columnas 0-39, filas 0-24) antes de la siguiente
; pagina.
LIMPIAR_VENTANA_INSTRUCCIONES:
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 698A: cdd178
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 698D: cdd178
    LD HL,$0005                       ; 6990: 210500
    LD DE,$2718                       ; 6993: 111827
    CALL FIRM_TXT_WIN_ENABLE          ; 6996: cd66bb
    CALL FIRM_TXT_CLEAR_WINDOW        ; 6999: cd6cbb
RESTAURAR_VENTANA_TEXTO_COMPLETA:
    LD HL,$0000                       ; 699C: 210000
    LD DE,$2718                       ; 699F: 111827
    CALL FIRM_TXT_WIN_ENABLE          ; 69A2: cd66bb
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 69A5: cdd178
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 69A8: cdd178
    RET                               ; 69AB: c9

; ESPERAR_CONTINUAR_INSTRUCCIONES ($69AC): imprime el aviso "Press C or
; Fire Button to Continue" reutilizando el MISMO texto que la pantalla de
; GAME OVER ($80FB, ver TABLA_DESCONOCIDA_GAME_OVER/bloque "Press...to
; Continue" mas arriba) y espera a que se pulse la tecla 'C' ($4C) o el
; boton de fuego ($3E) bombeando el motor de sonido mientras tanto;
; despues vacia el buffer de teclado (drena cualquier caracter que haya
; quedado pendiente) antes de devolver el control. Confianza alta.
ESPERAR_CONTINUAR_INSTRUCCIONES:
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 69AC: cdd178
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 69AF: cdd178
    LD HL,$80FB                       ; 69B2: 21fb80
    CALL IMPRIMIR_PARRAFO_INSTRUCCIONES; 69B5: cdd269
ESPERAR_CONTINUAR_INSTRUCCIONES_BUCLE:
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 69B8: cdd178
    LD A,$4C                          ; 69BB: 3e4c
    CALL FIRM_KM_TEST_KEY             ; 69BD: cd1ebb
    JR NZ,ESPERAR_CONTINUAR_INSTRUCCIONES_VACIAR                       ; 69C0: 2007
    LD A,$3E                          ; 69C2: 3e3e
    CALL FIRM_KM_TEST_KEY             ; 69C4: cd1ebb
    JR Z,ESPERAR_CONTINUAR_INSTRUCCIONES_BUCLE                        ; 69C7: 28ef
ESPERAR_CONTINUAR_INSTRUCCIONES_VACIAR:
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 69C9: cdd178
    CALL FIRM_KM_READ_CHAR            ; 69CC: cd09bb
    RET NC                            ; 69CF: d0
    JR ESPERAR_CONTINUAR_INSTRUCCIONES_VACIAR                          ; 69D0: 18f7

; IMPRIMIR_PARRAFO_INSTRUCCIONES ($69D2): HL apunta a un bloque de texto
; con formato [longitud][bytes...] (ver TEXTO_INSTR_01..23 mas abajo).
; Imprime cada byte con el firmware TXT OUTPUT; el codigo de control $1F
; (posicionar cursor, seguido de 2 bytes columna/fila) recibe un bombeo
; extra del motor de sonido antes de imprimirse -- igual que $1F y sus 2
; parametros se imprimen como bytes normales en las siguientes 2
; iteraciones del bucle (no hay tratamiento especial aparte del bombeo de
; sonido). Confianza alta -- verificado ademas por el propio formato de
; los 23 bloques de texto (cada linea del parrafo empieza con $1F,col,fila).
IMPRIMIR_PARRAFO_INSTRUCCIONES:
    LD B,(HL)                         ; 69D2: 46
IMPRIMIR_PARRAFO_INSTRUCCIONES_BUCLE:
    INC HL                            ; 69D3: 23
    LD A,(HL)                         ; 69D4: 7e
    CP $1F                            ; 69D5: fe1f
    JR NZ,IMPRIMIR_PARRAFO_INSTRUCCIONES_CARACTER                       ; 69D7: 200c
    PUSH AF                           ; 69D9: f5
    PUSH BC                           ; 69DA: c5
    PUSH HL                           ; 69DB: e5
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 69DC: cdd178
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 69DF: cdd178
    POP HL                            ; 69E2: e1
    POP BC                            ; 69E3: c1
    POP AF                            ; 69E4: f1
IMPRIMIR_PARRAFO_INSTRUCCIONES_CARACTER:
    CALL FIRM_TXT_OUTPUT              ; 69E5: cd5abb
    DJNZ IMPRIMIR_PARRAFO_INSTRUCCIONES_BUCLE                        ; 69E8: 10e9
    RET                               ; 69EA: c9

; ---- TEXTO_INSTR_01..23 ($69EB-$7512, 2856 bytes): texto literal de la
; pantalla de instrucciones ----
; Sesion 14: confirma y ACOTA CON EXACTITUD BYTE A BYTE la hipotesis de la
; Sesion 13 ("a partir de $69EA, mayormente texto literal"). Son 23
; bloques CONTIGUOS (sin huecos ni relleno entre ellos, verificado
; programaticamente: cada bloque empieza justo donde termina el anterior)
; con formato [1 byte de longitud][texto de esa longitud], exactamente el
; formato que consume IMPRIMIR_PARRAFO_INSTRUCCIONES. El ultimo bloque
; (TEXTO_INSTR_23) termina EXACTAMENTE en $7512, el byte justo antes de
; $7513 -- que es el primer punto de entrada real del bucle de juego (ver
; ANIMAR_APARICION_MOMIA_GUARDIANA mas abajo). Es decir: el limite entre
; "despachador de instrucciones" y "bucle de juego" cae EXACTAMENTE en la
; frontera entre datos y codigo, sin solape ni relleno -- confirmacion muy
; fuerte de que la reconstruccion de ambos tramos es correcta. Es el texto
; real de "OH MUMMY" (escenario, reglas de las 20 casillas, controles y
; niveles de dificultad), en ingles, identico al de la version original.
; Bloque 1/23 de PANTALLA_INSTRUCCIONES (separador/cabecera de control antes del titulo (codigos VDU, sin texto legible)).
TEXTO_INSTR_01:
    DB $08                    ; 69EB (longitud: 8)
    DB $0E,$00,$0C,$1D,$18,$18,$0E,$01 ; 69EC

; Bloque 2/23 de PANTALLA_INSTRUCCIONES ("OH MUMMY - SCENARIO" (titulo de la pantalla de historia)).
TEXTO_INSTR_02:
    DB $1A                    ; 69F4 (longitud: 26)
    DB $0E,$00,$0F,$03,$1F,$0C,$02    ; 69F5
    DB "OH MUMMY - SCENARIO"          ; 69FC

; Bloque 3/23 de PANTALLA_INSTRUCCIONES (historia: expedicion arqueologica a Egipto).
TEXTO_INSTR_03:
    DB $AA                    ; 6A0F (longitud: 170)
    DB $0E,$01,$0F,$00,$1F,$05,$08    ; 6A10
    DB "You have been appointed head of an" ; 6A17
    DB $1F,$03,$09                    ; 6A39
    DB "archeological expedition,  sponsored" ; 6A3C
    DB $1F,$03,$0A                    ; 6A60
    DB "by the British Museum, and have been" ; 6A63
    DB $1F,$03,$0B                    ; 6A87
    DB "sent to Egypt to explore newly found" ; 6A8A
    DB $1F,$03,$0C                    ; 6AAE
    DB "pyramids."                    ; 6AB1

; Bloque 4/23 de PANTALLA_INSTRUCCIONES (historia: el equipo y el objetivo (5 miembros, 5 niveles, momias reales)).
TEXTO_INSTR_04:
    DB $BD                    ; 6ABA (longitud: 189)
    DB $1F,$05,$0F                    ; 6ABB
    DB "Your party, initially, consists of" ; 6ABE
    DB $1F,$03,$10                    ; 6AE0
    DB "five members.  Your task is to enter" ; 6AE3
    DB $1F,$03,$11                    ; 6B07
    DB "the five levels of each pyramid, and" ; 6B0A
    DB $1F,$03,$12                    ; 6B2E
    DB "recover from them five Royal Mummies" ; 6B31
    DB $1F,$03,$13                    ; 6B55
    DB "and as much treasure as you can." ; 6B58

; Bloque 5/23 de PANTALLA_INSTRUCCIONES (historia: los niveles ya semi-excavados).
TEXTO_INSTR_05:
    DB $73                    ; 6B78 (longitud: 115)
    DB $1F,$05,$08,$0F,$00            ; 6B79
    DB "Each level has already been partly" ; 6B7E
    DB $1F,$03,$09                    ; 6BA0
    DB "uncovered by local workers and it is" ; 6BA3
    DB $1F,$03,$0A                    ; 6BC7
    DB "up to your team to finish the dig." ; 6BCA

; Bloque 6/23 de PANTALLA_INSTRUCCIONES (historia: los guardianes despertados).
TEXTO_INSTR_06:
    DB $88                    ; 6BEC (longitud: 136)
    DB $1F,$05,$0D                    ; 6BED
    DB "Unfortunately, the workers digging" ; 6BF0
    DB $1F,$03,$0E                    ; 6C12
    DB "aroused Guardians left behind by the" ; 6C15
    DB $1F,$03,$0F                    ; 6C39
    DB "ancient Egyptian Pharoahs to protect" ; 6C3C
    DB $1F,$03,$10                    ; 6C60
    DB "their royal tombs."           ; 6C63

; Bloque 7/23 de PANTALLA_INSTRUCCIONES (historia: las 2 momias guardianas por nivel).
TEXTO_INSTR_07:
    DB $6A                    ; 6C75 (longitud: 106)
    DB $1F,$05,$13                    ; 6C76
    DB "Each level has 2 Guardian Mummies," ; 6C79
    DB $1F,$03,$14                    ; 6C9B
    DB "one lies hidden while the other goes" ; 6C9E
    DB $1F,$03,$15                    ; 6CC2
    DB "in search of the intruders."  ; 6CC5

; Bloque 8/23 de PANTALLA_INSTRUCCIONES (reglas: el tablero son 20 casillas (grid)).
TEXTO_INSTR_08:
    DB $59                    ; 6CE0 (longitud: 89)
    DB $1F,$05,$08,$0F,$00            ; 6CE1
    DB "The partly excavated levels are in" ; 6CE6
    DB $1F,$03,$09                    ; 6D08
    DB "the form of a grid made up of twenty" ; 6D0B
    DB $1F,$03,$0A                    ; 6D2F
    DB "'boxes'."                     ; 6D32

; Bloque 9/23 de PANTALLA_INSTRUCCIONES (reglas: como descubrir una casilla).
TEXTO_INSTR_09:
    DB $67                    ; 6D3A (longitud: 103)
    DB $1F,$05,$0D                    ; 6D3B
    DB "To uncover a 'box', move your team" ; 6D3E
    DB $1F,$03,$0E                    ; 6D60
    DB "along the four sides of the box from" ; 6D63
    DB $1F,$03,$0F                    ; 6D87
    DB "each corner to the next."     ; 6D8A

; Bloque 10/23 de PANTALLA_INSTRUCCIONES (reglas: no hace falta descubrirlas todas para salir).
TEXTO_INSTR_10:
    DB $67                    ; 6DA2 (longitud: 103)
    DB $1F,$05,$12                    ; 6DA3
    DB "Not all boxes need to be uncovered" ; 6DA6
    DB $1F,$03,$13                    ; 6DC8
    DB "to enable you to go through the Exit" ; 6DCB
    DB $1F,$03,$14                    ; 6DEF
    DB "and into the next level."     ; 6DF2

; Bloque 11/23 de PANTALLA_INSTRUCCIONES (reglas: contenido de las casillas (tesoro, momia real, momia guardiana, llave, pergamino)).
TEXTO_INSTR_11:
    DB $8B                    ; 6E0A (longitud: 139)
    DB $1F,$05,$08,$0F,$00            ; 6E0B
    DB "Each level contains,  ten Treasure" ; 6E10
    DB $1F,$03,$09                    ; 6E32
    DB "boxes, six empty boxes, and the rest" ; 6E35
    DB $1F,$03,$0A                    ; 6E59
    DB "hold a Royal Mummy, a Guardian Mummy" ; 6E5C
    DB $1F,$03,$0B                    ; 6E80
    DB "a Key and a Scroll."          ; 6E83

; Bloque 12/23 de PANTALLA_INSTRUCCIONES (reglas: la momia guardiana persigue y mata al equipo (o viceversa)).
TEXTO_INSTR_12:
    DB $E6                    ; 6E96 (longitud: 230)
    DB $1F,$05,$0E                    ; 6E97
    DB "If you uncover the box holding the" ; 6E9A
    DB $1F,$03,$0F                    ; 6EBC
    DB "Guardian Mummy, it will dig it's way" ; 6EBF
    DB $1F,$03,$10                    ; 6EE3
    DB "out and persue you.  Being caught by" ; 6EE6
    DB $1F,$03,$11                    ; 6F0A
    DB "a Guardian Mummy kills one member of" ; 6F0D
    DB $1F,$03,$12                    ; 6F31
    DB "your team and the Mummy, unless that" ; 6F34
    DB $1F,$03,$13                    ; 6F58
    DB "is, you have uncovered the Scroll." ; 6F5B

; Bloque 13/23 de PANTALLA_INSTRUCCIONES (reglas: el pergamino protege de una momia guardiana).
TEXTO_INSTR_13:
    DB $BE                    ; 6F7D (longitud: 190)
    DB $1F,$05,$08,$0F,$00            ; 6F7E
    DB "The Magic Scroll will allow you to" ; 6F83
    DB $1F,$03,$09                    ; 6FA5
    DB "be caught by a Guardian, without any" ; 6FA8
    DB $1F,$03,$0A                    ; 6FCC
    DB "harm to your team.  The Scroll works" ; 6FCF
    DB $1F,$03,$0B                    ; 6FF3
    DB "only on the level on which found, it" ; 6FF6
    DB $1F,$03,$0C                    ; 701A
    DB "will only destroy one Guardian." ; 701D

; Bloque 14/23 de PANTALLA_INSTRUCCIONES (reglas: como se consiguen puntos).
TEXTO_INSTR_14:
    DB $71                    ; 703C (longitud: 113)
    DB $1F,$05,$0F                    ; 703D
    DB "There are two ways to gain points," ; 7040
    DB $1F,$03,$10                    ; 7062
    DB "one is by uncovering the Royal Mummy" ; 7065
    DB $1F,$03,$11                    ; 7089
    DB "the other, by uncovering Treasure." ; 708C

; Bloque 15/23 de PANTALLA_INSTRUCCIONES (reglas: la llave y la momia real abren la salida).
TEXTO_INSTR_15:
    DB $C1                    ; 70AE (longitud: 193)
    DB $1F,$05,$08,$0F,$00            ; 70AF
    DB "When the boxes holding the Key and" ; 70B4
    DB $1F,$03,$09                    ; 70D6
    DB "the Royal Mummy have been uncovered," ; 70D9
    DB $1F,$03,$0A                    ; 70FD
    DB "you will be able to leave the level." ; 7100
    DB $1F,$03,$0B                    ; 7124
    DB "Any remaining Guardians will be able" ; 7127
    DB $1F,$03,$0C                    ; 714B
    DB "to follow you onto the next level." ; 714E

; Bloque 16/23 de PANTALLA_INSTRUCCIONES (reglas: paso a la siguiente piramide tras el nivel 5).
TEXTO_INSTR_16:
    DB $83                    ; 7170 (longitud: 131)
    DB $1F,$05,$0F                    ; 7171
    DB "After completing all 5 levels of a" ; 7174
    DB $1F,$03,$10                    ; 7196
    DB "pyramid you will, when you leave the" ; 7199
    DB $1F,$03,$11                    ; 71BD
    DB "fifth level, move to level 1, of the" ; 71C0
    DB $1F,$03,$12                    ; 71E4
    DB "next pyramid."                ; 71E7

; Bloque 17/23 de PANTALLA_INSTRUCCIONES (reglas: recompensa al completar una piramide).
TEXTO_INSTR_17:
    DB $93                    ; 71F4 (longitud: 147)
    DB $1F,$05,$08,$0F,$00            ; 71F5
    DB "When you have completed a pyramid," ; 71FA
    DB $1F,$03,$09                    ; 721C
    DB "your success will be rewarded either" ; 721F
    DB $1F,$03,$0A                    ; 7243
    DB "by bonus points or the arrival of an" ; 7246
    DB $1F,$03,$0B                    ; 726A
    DB "extra member for your team."  ; 726D

; Bloque 18/23 de PANTALLA_INSTRUCCIONES (reglas: dificultad creciente entre piramides).
TEXTO_INSTR_18:
    DB $E5                    ; 7288 (longitud: 229)
    DB $1F,$05,$0E                    ; 7289
    DB "The Guardians in the next pyramid," ; 728C
    DB $1F,$03,$0F                    ; 72AE
    DB "having been warned by those you have" ; 72B1
    DB $1F,$03,$10                    ; 72D5
    DB "escaped from, will be more alert, so" ; 72D8
    DB $1F,$03,$11                    ; 72FC
    DB "although the Guardians cannot follow" ; 72FF
    DB $1F,$03,$12                    ; 7323
    DB "you from one pyramid to the next, it" ; 7326
    DB $1F,$03,$13                    ; 734A
    DB "will pay to be even more careful." ; 734D

; Bloque 19/23 de PANTALLA_INSTRUCCIONES ("OH MUMMY - INSTRUCTIONS" (titulo de la pantalla de controles)).
TEXTO_INSTR_19:
    DB $1E                    ; 736E (longitud: 30)
    DB $0E,$00,$0F,$03,$1F,$0A,$02    ; 736F
    DB "OH MUMMY - INSTRUCTIONS"      ; 7376

; Bloque 20/23 de PANTALLA_INSTRUCCIONES (controles: joystick o teclado).
TEXTO_INSTR_20:
    DB $4F                    ; 738D (longitud: 79)
    DB $1F,$05,$08,$0E,$01,$0F,$00    ; 738E
    DB "You can control your team by using" ; 7395
    DB $1F,$03,$09                    ; 73B7
    DB "either a Joystick, or the Keyboard." ; 73BA

; Bloque 21/23 de PANTALLA_INSTRUCCIONES (controles: teclas A/Z///\\ (arriba/abajo/izquierda/derecha)).
TEXTO_INSTR_21:
    DB $46                    ; 73DD (longitud: 70)
    DB $1F,$05,$0B                    ; 73DE
    DB "The keyboard keys are :-"     ; 73E1
    DB $1F,$02,$0D,$0F,$02            ; 73F9
    DB "A - Up  Z - Down   / - Left  " ; 73FE
    DB $5C                            ; 741B
    DB " - Right"                     ; 741C

; Bloque 22/23 de PANTALLA_INSTRUCCIONES (niveles de dificultad (velocidad de las momias)).
TEXTO_INSTR_22:
    DB $C2                    ; 7424 (longitud: 194)
    DB $0F,$00,$1F,$05,$0F            ; 7425
    DB "The game has 5 skill levels, these" ; 742A
    DB $1F,$03,$10                    ; 744C
    DB "determine how 'clever' the Guardians" ; 744F
    DB $1F,$03,$11                    ; 7473
    DB "are at the beginning of a game.  You" ; 7476
    DB $1F,$03,$12                    ; 749A
    DB "may choose between 5 different speed" ; 749D
    DB $1F,$03,$13                    ; 74C1
    DB "levels, from moderate to murderous." ; 74C4

; Bloque 23/23 de PANTALLA_INSTRUCCIONES (despedida ("May Ankh-Sun-Ahmun guide your steps...")).
TEXTO_INSTR_23:
    DB $2B                    ; 74E7 (longitud: 43)
    DB $1F,$02,$15,$0F,$03            ; 74E8
    DB "May Ankh-Sun-Ahmun guide your steps .." ; 74ED
; ---- ANIMAR_APARICION_MOMIA_GUARDIANA / COMPROBAR_SALIDA_NIVEL /
; PROCESAR_ENCUENTROS_ENTIDADES / ACTUALIZAR_MARCO_TRAS_MOVIMIENTO /
; CALCULAR_TRAMO_MARCO_DESDE_CONTENIDO / MARCO_CONTENIDO_* /
; PROCESAR_MOVIMIENTO_JUGADOR ($7513-$7862, 350 bytes) ----
; Sesion 14: SEGUNDO Y ULTIMO tramo del ultimo hueco del motor. Contiene
; los 5 puntos de entrada llamados desde BUCLE_PRINCIPAL_JUEGO/
; INICIO_TURNO_JUGADOR1 que la Sesion 12/13 dejaron sin resolver ($7578,
; $77D1, $7637, $7566, $7513 -- ver comentario de BUCLE_PRINCIPAL_JUEGO
; mas arriba). CORRIGE la hipotesis de la Sesion 13 ("$68B2-$7862 es
; sobre todo texto"): este segundo tramo es CODIGO REAL de principio a
; fin (confirmado por decodificacion mecanica sin interrupciones y por
; el encaje exacto de los 5 puntos de entrada con limites de instruccion).
;
; Juntas, estas rutinas implementan el NUCLEO del mecanismo de juego tipo
; "Amidar" (pintar los lados de las casillas del tablero al recorrerlas):
; ACTUALIZAR_MARCO_TRAS_MOVIMIENTO detecta que el jugador se ha movido a
; una interseccion valida de la rejilla (CPIR contra TABLA_FILAS_VALIDAS_
; CASILLAS/TABLA_COLUMNAS_VALIDAS_CASILLAS, ver mas arriba) y calcula, via
; CALCULAR_TRAMO_MARCO_DESDE_CONTENIDO, que contenido hay en el lado de
; casilla recien recorrido -- un valor leido del marco que se despacha en
; 5 rangos (MARCO_CONTENIDO_MOMIA_REAL/LLAVE/MOMIA_GUARDIANA/PERGAMINO/
; TESORO) mas un caso por defecto que simplemente redibuja el patron
; diagonal segun el nivel actual (RELLENAR_MARCO_DIAGONAL_1/3/4/5/6,
; nombradas en la Sesion 7 y con un primer llamador ya encontrado por
; la Sesion 13 en SELECCIONAR_DIAGONAL_MARCO_NIVEL -- este es un
; SEGUNDO llamador independiente, mismo patron de 5 variantes,
; _2 sin usar en ninguno de los dos).
; Confianza alta en la estructura general; media-alta en que cada uno de
; los 4 flags ($816E/$816F/$8170 + el contador $816D) corresponda
; exactamente a Pergamino/Llave/Momia Real/Momia Guardiana en ese orden --
; la correspondencia se apoya en: (a) COMPROBAR_SALIDA_NIVEL exige que
; ($8170) Y ($816F) esten ambos activos antes de permitir la salida,
; coherente con TEXTO_INSTR_15 ("When the boxes holding the Key and the
; Royal Mummy have been uncovered, you will be able to leave the level");
; (b) MARCO_CONTENIDO_MOMIA_GUARDIANA arranca el contador $816D=31 que
; ANIMAR_APARICION_MOMIA_GUARDIANA usa para dibujar PROGRESIVAMENTE (4
; bytes por turno) el sprite SPRITE_MOMIA_G1_F1 ($8CB9, ya declarado mas
; abajo) en la casilla, coherente con TEXTO_INSTR_12 ("it will dig its way
; out"); (c) unicamente MARCO_CONTENIDO_MOMIA_REAL y MARCO_CONTENIDO_
; TESORO otorgan puntos (+50 y +5), coherente con TEXTO_INSTR_14 ("There
; are two ways to gain points... Royal Mummy... Treasure"). Nunca
; verificado en emulador.

; ANIMAR_APARICION_MOMIA_GUARDIANA ($7513): llamada condicionalmente cada
; turno desde BUCLE_PRINCIPAL_JUEGO ("CALL NZ,$7513" cuando ($816D)<>0).
; Decrementa el contador ($816D) iniciado en 31 por MARCO_CONTENIDO_
; MOMIA_GUARDIANA; en cada llamada con el contador PAR (RET C si el bit 0
; tras SRA es 1, es decir solo actua 1 de cada 2 llamadas) copia 4 bytes
; del sprite SPRITE_MOMIA_G1_F1 (indexados por el propio contador) a la
; casilla de pantalla calculada desde VARIABLE_CASILLA_APARICION_MOMIA
; ($8136) -- efecto visual de "la momia emergiendo poco a poco". Al llegar
; el contador a 0, limpia con espacios la casilla del mapa en esa posicion
; y genera una entidad de reemplazo (INICIALIZAR_UNA_ENTIDAD) colocada en
; la misma posicion. Confianza media-alta en la estructura; media en el
; papel exacto de "limpia y regenera" (podria ser el momento en que la
; Momia Guardiana queda activa como entidad persiguiendo al jugador).
ANIMAR_APARICION_MOMIA_GUARDIANA:
    DEC A                             ; 7513: 3d
    LD ($816D),A            ; 7514: 326d81
    SRA A                             ; 7517: cb2f
    RET C                             ; 7519: d8
    LD H,$00                          ; 751A: 2600
    LD L,A                            ; 751C: 6f
    ADD HL,HL                         ; 751D: 29
    ADD HL,HL                         ; 751E: 29
    EX DE,HL                          ; 751F: eb
    LD IY,$8CB9                       ; 7520: fd21b98c
    ADD IY,DE                         ; 7524: fd19
    LD HL,($8136)                     ; 7526: 2a3681
    ADD A,H                           ; 7529: 84
    LD H,A                            ; 752A: 67
    CALL CASILLA_A_DIRECCION_PANTALLA ; 752B: cd927e
    LD B,$04                          ; 752E: 0604
BUCLE_COPIAR_SPRITE_MOMIA_GUARDIANA:
    LD A,(IY+0)                       ; 7530: fd7e00
    LD (HL),A                         ; 7533: 77
    INC IY                            ; 7534: fd23
    INC HL                            ; 7536: 23
    DJNZ BUCLE_COPIAR_SPRITE_MOMIA_GUARDIANA                        ; 7537: 10f7
    LD A,($816D)            ; 7539: 3a6d81
    OR A                              ; 753C: b7
    RET NZ                            ; 753D: c0
    LD DE,($8136)                     ; 753E: ed5b3681
    CALL CONSULTAR_CASILLA_MAPA       ; 7542: cd3e7d
    LD A,$20                          ; 7545: 3e20
    LD (HL),A                         ; 7547: 77
    INC HL                            ; 7548: 23
    LD (HL),A                         ; 7549: 77
    LD DE,$0028                       ; 754A: 112800
    ADD HL,DE                         ; 754D: 19
    LD (HL),A                         ; 754E: 77
    DEC HL                            ; 754F: 2b
    LD (HL),A                         ; 7550: 77
    LD A,($8169)                      ; 7551: 3a6981
    INC A                             ; 7554: 3c
    LD ($8169),A                      ; 7555: 326981
    CALL INICIALIZAR_UNA_ENTIDAD      ; 7558: cd5b79
    LD DE,($8136)                     ; 755B: ed5b3681
    LD (IX+2),D                       ; 755F: dd7202
    LD (IX+3),E                       ; 7562: dd7303
    RET                               ; 7565: c9

; COMPROBAR_SALIDA_NIVEL ($7566): llamada cada turno tras ACTUALIZAR_MARCO_
; TRAS_MOVIMIENTO ($7637, ver mas abajo). Sale sin hacer nada si no estan
; activos AMBOS flags ($8170)=Momia Real Y ($816F)=Llave (AND logico -- ver
; hipotesis de correspondencia arriba), o si la columna del jugador
; ($8156) no es exactamente $08 (posicion de la casilla de Salida,
; hipotesis media). Si ambas condiciones se cumplen, DESCARTA la direccion
; de retorno de su propio CALL (POP HL) y salta a $654C -- un punto MEDIO
; de PREPARAR_NIVEL (justo antes de su "CALL BORRAR_BLOQUE_ESTADO", el
; mismo destino de "JR Z,$654C" un poco mas arriba en esa rutina cuando la
; puntuacion es 0) -- efectivamente aborta el turno en curso y reinicia el
; estado del tablero saltandose el reset de nivel/vidas/puntuacion de
; PREPARAR_NIVEL. Confianza media-alta en la estructura; media en que sea
; literalmente "avanzar de nivel por la Salida" (no se ha verificado que
; $815C, el nivel, se incremente en algun punto de este camino -- posible
; pendiente).
COMPROBAR_SALIDA_NIVEL:
    LD A,($8170)                      ; 7566: 3a7081
    LD HL,$816F                       ; 7569: 216f81
    AND (HL)                          ; 756C: a6
    RET Z                             ; 756D: c8
    LD A,($8156)                      ; 756E: 3a5681
    CP $08                            ; 7571: fe08
    RET NZ                            ; 7573: c0
    POP HL                            ; 7574: e1
    JP LIMPIAR_ESTADO_NIVEL           ; 7575: c34c65

; PROCESAR_ENCUENTROS_ENTIDADES ($7578): llamada 2 veces por jugador y por
; turno desde BUCLE_PRINCIPAL_JUEGO, con "JP C,PANTALLA_GAME_OVER"
; inmediatamente despues de cada llamada. Recorre las entidades de
; ARRAY_ENTIDADES (de la ultima a la primera, tantas como indique
; ($816C)) comparando su posicion almacenada (IY+2/IY+3) contra la del
; jugador (DE=($8155)) con un margen de tolerancia (+/-8 en fila, +/-2 en
; columna). Si hay coincidencia, borra esa entidad (la pone a 0) y redibuja
; las 4 casillas de mapa alrededor de esa posicion (llamando a mitad de
; DIBUJAR_CASILLA_MAPA) ademas de redibujar al jugador ('A'). Segun el flag
; ($816E): si esta activo, lo interpreta como "recogida de coleccionable"
; (refresca la puntuacion con parpadeo de tinta) y continua con la
; siguiente entidad; si no, lo interpreta como "atrapado por una Momia
; Guardiana" -- resta una vida ($816A), y si llegan a 0 sale con acarreo
; activado (SCF) para que el bucle de juego salte a PANTALLA_GAME_OVER.
; Confianza alta en la estructura; media-alta en el papel de cada rama
; (coleccionable vs. momia).
PROCESAR_ENCUENTROS_ENTIDADES:
    LD DE,($8155)                     ; 7578: ed5b5581
    LD IY,ARRAY_ENTIDADES             ; 757C: fd216d81
    LD A,($816C)                      ; 7580: 3a6c81
    LD B,A                            ; 7583: 47
PROCESAR_ENCUENTROS_ENTIDADES_BUCLE:
    PUSH BC                           ; 7584: c5
    LD BC,$0005                       ; 7585: 010500
    ADD IY,BC                         ; 7588: fd09
    LD A,(IY+0)                       ; 758A: fd7e00
    OR (IY+1)                         ; 758D: fdb601
    JP Z,PROCESAR_ENCUENTROS_ENTIDADES_SIGUIENTE; 7590: ca3076
    LD A,(IY+2)                       ; 7593: fd7e02
    SUB D                             ; 7596: 92
    CP $F8                            ; 7597: fef8
    JR Z,COMPROBAR_COLUMNA_ENCUENTRO  ; 7599: 2808
    CP $08                            ; 759B: fe08
    JR Z,COMPROBAR_COLUMNA_ENCUENTRO  ; 759D: 2804
    OR A                              ; 759F: b7
    JP NZ,PROCESAR_ENCUENTROS_ENTIDADES_SIGUIENTE; 75A0: c23076
COMPROBAR_COLUMNA_ENCUENTRO:
    LD A,(IY+3)                       ; 75A3: fd7e03
    SUB E                             ; 75A6: 93
    CP $FE                            ; 75A7: fefe
    JR Z,PROCESAR_ENCUENTRO_CONFIRMADO ; 75A9: 2807
    CP $02                            ; 75AB: fe02
    JR Z,PROCESAR_ENCUENTRO_CONFIRMADO ; 75AD: 2803
    OR A                              ; 75AF: b7
    JR NZ,PROCESAR_ENCUENTROS_ENTIDADES_SIGUIENTE; 75B0: 207e
PROCESAR_ENCUENTRO_CONFIRMADO:
    XOR A                             ; 75B2: af
    LD (IY+0),A                       ; 75B3: fd7700
    LD (IY+1),A                       ; 75B6: fd7701
    LD D,(IY+2)                       ; 75B9: fd5602
    LD E,(IY+3)                       ; 75BC: fd5e03
    CALL CONSULTAR_CASILLA_MAPA       ; 75BF: cd3e7d
    LD A,(HL)                         ; 75C2: 7e
    CALL DIBUJAR_CASILLA_MAPA                        ; 75C3: cde67c  ; entrada intermedia en DIBUJAR_CASILLA_MAPA (linea 'CP $02'), ver arriba
    INC E                             ; 75C6: 1c
    INC E                             ; 75C7: 1c
    CALL CONSULTAR_CASILLA_MAPA       ; 75C8: cd3e7d
    LD A,(HL)                         ; 75CB: 7e
    CALL DIBUJAR_CASILLA_MAPA                        ; 75CC: cde67c  ; entrada intermedia en DIBUJAR_CASILLA_MAPA (linea 'CP $02'), ver arriba
    LD A,$08                          ; 75CF: 3e08
    ADD A,D                           ; 75D1: 82
    LD D,A                            ; 75D2: 57
    CALL CONSULTAR_CASILLA_MAPA       ; 75D3: cd3e7d
    LD A,(HL)                         ; 75D6: 7e
    CALL DIBUJAR_CASILLA_MAPA                        ; 75D7: cde67c  ; entrada intermedia en DIBUJAR_CASILLA_MAPA (linea 'CP $02'), ver arriba
    DEC E                             ; 75DA: 1d
    DEC E                             ; 75DB: 1d
    CALL CONSULTAR_CASILLA_MAPA       ; 75DC: cd3e7d
    LD A,(HL)                         ; 75DF: 7e
    CALL DIBUJAR_CASILLA_MAPA                        ; 75E0: cde67c  ; entrada intermedia en DIBUJAR_CASILLA_MAPA (linea 'CP $02'), ver arriba
    LD HL,$8169                       ; 75E3: 216981
    DEC (HL)                          ; 75E6: 35
    LD DE,($8155)                     ; 75E7: ed5b5581
    LD A,$41                          ; 75EB: 3e41
    CALL DIBUJAR_ENTIDAD              ; 75ED: cd397b
    LD A,($816E)                      ; 75F0: 3a6e81
    OR A                              ; 75F3: b7
    JR Z,PROCESAR_ENCUENTROS_ENTIDADES_PERDER_VIDA                        ; 75F4: 2815
    XOR A                             ; 75F6: af
    LD ($816E),A                      ; 75F7: 326e81
    CALL FIRM_TXT_SET_PAPER           ; 75FA: cd96bb
    LD A,$03                          ; 75FD: 3e03
    CALL FIRM_TXT_SET_PEN             ; 75FF: cd90bb
    PUSH IY                           ; 7602: fde5
    CALL IMPRIMIR_PUNTUACION_HUD      ; 7604: cd6378
    POP IY                            ; 7607: fde1
    JR PROCESAR_ENCUENTROS_ENTIDADES_SIGUIENTE; 7609: 1825
PROCESAR_ENCUENTROS_ENTIDADES_PERDER_VIDA:
    LD HL,$816A                       ; 760B: 216a81
    DEC (HL)                          ; 760E: 35
    LD A,(HL)                         ; 760F: 7e
    ADD A,A                           ; 7610: 87
    ADD A,A                           ; 7611: 87
    ADD A,$34                         ; 7612: c634
    LD D,$00                          ; 7614: 1600
    LD E,A                            ; 7616: 5f
    LD A,$20                          ; 7617: 3e20
    CALL DIBUJAR_ENTIDAD              ; 7619: cd397b
    LD HL,$8000                       ; 761C: 210080
    LD A,($7FC5)                      ; 761F: 3ac57f
    CP $59                            ; 7622: fe59
    CALL Z,FIRM_SOUND_QUEUE           ; 7624: ccaabc
    LD A,($816A)                      ; 7627: 3a6a81
    OR A                              ; 762A: b7
    JR NZ,PROCESAR_ENCUENTROS_ENTIDADES_SIGUIENTE; 762B: 2003
    POP BC                            ; 762D: c1
    SCF                               ; 762E: 37
    RET                               ; 762F: c9
PROCESAR_ENCUENTROS_ENTIDADES_SIGUIENTE:
    POP BC                            ; 7630: c1
    DEC B                             ; 7631: 05
    JP NZ,PROCESAR_ENCUENTROS_ENTIDADES_BUCLE; 7632: c28475
    XOR A                             ; 7635: af
    RET                               ; 7636: c9

; ACTUALIZAR_MARCO_TRAS_MOVIMIENTO ($7637): llamada 2 veces por jugador y
; por turno. Compara la posicion actual del jugador ($8155) contra la
; ultima posicion registrada ($8138) y sale sin hacer nada si coinciden.
; Si son distintas, valida que la NUEVA posicion caiga en una interseccion
; real de la rejilla de 20 casillas usando CPIR contra
; TABLA_FILAS_VALIDAS_CASILLAS (5 valores) y TABLA_COLUMNAS_VALIDAS_
; CASILLAS (6 valores, ver arriba, junto a TABLA_DESCONOCIDA_GAME_OVER) --
; si no es una interseccion valida, sale sin actuar (RET NZ). Si lo es,
; actualiza ($8138) a la nueva posicion y calcula en B/HL el lado de la
; casilla recorrido segun la orientacion del jugador (($8157), 4 casos) y
; llama a CALCULAR_TRAMO_MARCO_DESDE_CONTENIDO. Confianza alta.
ACTUALIZAR_MARCO_TRAS_MOVIMIENTO:
    LD HL,($8155)                     ; 7637: 2a5581
    LD BC,($8138)                     ; 763A: ed4b3881
    XOR A                             ; 763E: af
    LD A,H                            ; 763F: 7c
    LD E,L                            ; 7640: 5d
    SBC HL,BC                         ; 7641: ed42
    RET Z                             ; 7643: c8
    LD HL,$813A                       ; 7644: 213a81
    LD BC,$0005                       ; 7647: 010500
    CPIR                              ; 764A: edb1
    RET NZ                            ; 764C: c0
    LD D,C                            ; 764D: 51
    LD A,E                            ; 764E: 7b
    LD HL,$813F                       ; 764F: 213f81
    LD BC,$0006                       ; 7652: 010600
    CPIR                              ; 7655: edb1
    RET NZ                            ; 7657: c0
    LD HL,($8155)                     ; 7658: 2a5581
    LD ($8138),HL                     ; 765B: 223881
    LD A,$04                          ; 765E: 3e04
    SUB D                             ; 7660: 92
    LD D,A                            ; 7661: 57
    ADD A,A                           ; 7662: 87
    ADD A,A                           ; 7663: 87
    ADD A,A                           ; 7664: 87
    SUB D                             ; 7665: 92
    LD D,A                            ; 7666: 57
    LD A,$05                          ; 7667: 3e05
    SUB C                             ; 7669: 91
    ADD A,D                           ; 766A: 82
    LD H,A                            ; 766B: 67
    LD L,A                            ; 766C: 6f
    LD A,($8157)                      ; 766D: 3a5781
    CP $02                            ; 7670: fe02
    JR C,CALCULAR_LADO_MARCO_ORIENTACION_01         ; 7672: 3815
    JR Z,CALCULAR_LADO_MARCO_ORIENTACION_2          ; 7674: 280e
    CP $03                            ; 7676: fe03
    JR Z,CALCULAR_LADO_MARCO_ORIENTACION_3          ; 7678: 2805
    LD BC,$0108                       ; 767A: 010801
    JR SUMAR_LADO_MARCO               ; 767D: 180d
CALCULAR_LADO_MARCO_ORIENTACION_3:
    LD BC,$0001                       ; 767F: 010100
    JR SUMAR_LADO_MARCO               ; 7682: 1808
CALCULAR_LADO_MARCO_ORIENTACION_2:
    LD BC,$0007                       ; 7684: 010700
    JR SUMAR_LADO_MARCO               ; 7687: 1803
CALCULAR_LADO_MARCO_ORIENTACION_01:
    LD BC,$0708                       ; 7689: 010807
SUMAR_LADO_MARCO:
    ADD HL,BC                         ; 768C: 09
    LD B,H                            ; 768D: 44
    LD C,L                            ; 768E: 4d
    LD IX,$81D6                       ; 768F: dd21d681
    LD IY,$81D6                       ; 7693: fd21d681
    LD E,C                            ; 7697: 59
    LD D,$00                          ; 7698: 1600
    LD C,B                            ; 769A: 48
    LD B,D                            ; 769B: 42
    ADD IX,BC                         ; 769C: dd09
    ADD IY,DE                         ; 769E: fd19
    BIT 0,A                           ; 76A0: cb47
    JR Z,MARCAR_LADO_MARCO_PAR        ; 76A2: 280a
    SET 0,(IX+0)                      ; 76A4: ddcb00c6
    SET 2,(IY+0)                      ; 76A8: fdcb00d6
    JR COMPROBAR_LADO_MARCO_IX        ; 76AC: 1808
MARCAR_LADO_MARCO_PAR:
    SET 1,(IX+0)                      ; 76AE: ddcb00ce
    SET 3,(IY+0)                      ; 76B2: fdcb00de
COMPROBAR_LADO_MARCO_IX:
    LD A,(IX+0)                       ; 76B6: dd7e00
    AND $0F                           ; 76B9: e60f
    CP $0F                            ; 76BB: fe0f
    JR NZ,COMPROBAR_LADO_MARCO_IY     ; 76BD: 2015
    LD A,(IX+0)                       ; 76BF: dd7e00
    LD B,C                            ; 76C2: 41
    PUSH IX                           ; 76C3: dde5
    PUSH IY                           ; 76C5: fde5
    PUSH DE                           ; 76C7: d5
    CALL CALCULAR_TRAMO_MARCO_DESDE_CONTENIDO; 76C8: cdec76
    POP DE                            ; 76CB: d1
    POP IY                            ; 76CC: fde1
    POP IX                            ; 76CE: dde1
    XOR A                             ; 76D0: af
    LD (IX+0),A                       ; 76D1: dd7700
COMPROBAR_LADO_MARCO_IY:
    LD A,(IY+0)                       ; 76D4: fd7e00
    AND $0F                           ; 76D7: e60f
    CP $0F                            ; 76D9: fe0f
    RET NZ                            ; 76DB: c0
    LD A,(IY+0)                       ; 76DC: fd7e00
    LD B,E                            ; 76DF: 43
    PUSH IY                           ; 76E0: fde5
    CALL CALCULAR_TRAMO_MARCO_DESDE_CONTENIDO; 76E2: cdec76
    POP IY                            ; 76E5: fde1
    XOR A                             ; 76E7: af
    LD (IY+0),A                       ; 76E8: fd7700
    RET                               ; 76EB: c9

; CALCULAR_TRAMO_MARCO_DESDE_CONTENIDO ($76EC): a partir de B (indice de
; tramo de marco) calcula en HL la casilla de pantalla correspondiente
; (aritmetica de escalado, sin resolver la formula exacta -- confianza
; media) y, tras recuperar A (el codigo de "contenido" de ese tramo,
; preservado en la pila), despacha segun su valor: <$1F ignora (RET C,
; casilla ya vacia/procesada); ==$1F Momia Real; $20-$3E Llave; ==$3F
; Momia Guardiana; $40-$5E Pergamino; ==$5F Tesoro/generico; >=$60 usa
; ($815C) (nivel actual, 0-4) para elegir una de las 5 variantes de
; RELLENAR_MARCO_DIAGONAL_1/3/4/5/6 (RELLENAR_MARCO_DIAGONAL_2 queda SIN
; NINGUN llamador incluso tras esta reconstruccion completa -- hallazgo
; confirmado, ver FINDINGS.md). Confianza alta en la estructura de
; despacho; media en la formula de calculo de HL.
CALCULAR_TRAMO_MARCO_DESDE_CONTENIDO:
    PUSH AF                           ; 76EC: f5
    LD A,B                            ; 76ED: 78
    DEC A                             ; 76EE: 3d
    LD B,$00                          ; 76EF: 0600
BUCLE_DIVIDIR_INDICE_TRAMO_MARCO:
    SUB $07                           ; 76F1: d607
    JR C,RESTAURAR_RESTO_TRAMO_MARCO  ; 76F3: 3803
    INC B                             ; 76F5: 04
    JR BUCLE_DIVIDIR_INDICE_TRAMO_MARCO             ; 76F6: 18f9
RESTAURAR_RESTO_TRAMO_MARCO:
    ADD A,$07                         ; 76F8: c607
    ADD A,A                           ; 76FA: 87
    LD C,A                            ; 76FB: 4f
    ADD A,A                           ; 76FC: 87
    ADD A,A                           ; 76FD: 87
    ADD A,A                           ; 76FE: 87
    SUB C                             ; 76FF: 91
    ADD A,$08                         ; 7700: c608
    LD L,A                            ; 7702: 6f
    LD A,B                            ; 7703: 78
    ADD A,A                           ; 7704: 87
    ADD A,A                           ; 7705: 87
    ADD A,A                           ; 7706: 87
    LD B,A                            ; 7707: 47
    ADD A,A                           ; 7708: 87
    ADD A,A                           ; 7709: 87
    ADD A,B                           ; 770A: 80
    LD H,A                            ; 770B: 67
    POP AF                            ; 770C: f1
    CP $1F                            ; 770D: fe1f
    RET C                             ; 770F: d8
    JR Z,MARCO_CONTENIDO_MOMIA_REAL   ; 7710: 2852
    CP $3F                            ; 7712: fe3f
    JR C,MARCO_CONTENIDO_LLAVE        ; 7714: 383b
    JR Z,MARCO_CONTENIDO_MOMIA_GUARDIANA; 7716: 286c
    CP $5F                            ; 7718: fe5f
    JR C,MARCO_CONTENIDO_PERGAMINO    ; 771A: 3821
    JP Z,MARCO_CONTENIDO_TESORO       ; 771C: cab477
    LD A,($815C)                      ; 771F: 3a5c81
    CP $02                            ; 7722: fe02
    JR C,DESPACHAR_DIAGONAL_NIVEL_01  ; 7724: 3814
    JR Z,DESPACHAR_DIAGONAL_NIVEL_2   ; 7726: 280f
    CP $04                            ; 7728: fe04
    JR C,DESPACHAR_DIAGONAL_NIVEL_3   ; 772A: 3808
    JR Z,DESPACHAR_DIAGONAL_NIVEL_4   ; 772C: 2803
    JP RELLENAR_MARCO_DIAGONAL_1      ; 772E: c3fc7d
DESPACHAR_DIAGONAL_NIVEL_4:
    JP RELLENAR_MARCO_DIAGONAL_5      ; 7731: c3207e
DESPACHAR_DIAGONAL_NIVEL_3:
    JP RELLENAR_MARCO_DIAGONAL_4      ; 7734: c3177e
DESPACHAR_DIAGONAL_NIVEL_2:
    JP RELLENAR_MARCO_DIAGONAL_6      ; 7737: c3297e
DESPACHAR_DIAGONAL_NIVEL_01:
    JP RELLENAR_MARCO_DIAGONAL_3      ; 773A: c30e7e

; MARCO_CONTENIDO_PERGAMINO ($773D): rango $40-$5E. Marca ($816E) y
; parpadea la tinta del HUD (paper=3, pen=0) antes de refrescar la
; puntuacion -- sin variacion de puntos. Redibuja DIBUJAR_ICONO_PERGAMINO.
MARCO_CONTENIDO_PERGAMINO:
    LD ($816E),A                      ; 773D: 326e81
    PUSH HL                           ; 7740: e5
    LD A,$03                          ; 7741: 3e03
    CALL FIRM_TXT_SET_PAPER           ; 7743: cd96bb
    XOR A                             ; 7746: af
    CALL FIRM_TXT_SET_PEN             ; 7747: cd90bb
    CALL IMPRIMIR_PUNTUACION_HUD      ; 774A: cd6378
    POP HL                            ; 774D: e1
    JP DIBUJAR_ICONO_PERGAMINO          ; 774E: c3b57d

; MARCO_CONTENIDO_LLAVE ($7751): valores $20-$3E. Marca ($816F) y encola
; un sonido -- sin variacion de puntos. Redibuja DIBUJAR_ICONO_LLAVE.
MARCO_CONTENIDO_LLAVE:
    LD ($816F),A                      ; 7751: 326f81
    PUSH HL                           ; 7754: e5
    LD HL,$8012                       ; 7755: 211280
    LD A,($7FC5)                      ; 7758: 3ac57f
    CP $59                            ; 775B: fe59
    CALL Z,FIRM_SOUND_QUEUE           ; 775D: ccaabc
    POP HL                            ; 7760: e1
    JP DIBUJAR_ICONO_LLAVE          ; 7761: c39d7d

; MARCO_CONTENIDO_MOMIA_REAL ($7764): valor exacto $1F. Marca ($8170),
; suma 50 puntos ($0032) a la puntuacion y la refresca, encola un sonido.
; Redibuja DIBUJAR_ICONO_SARCOFAGO.
MARCO_CONTENIDO_MOMIA_REAL:
    LD ($8170),A                      ; 7764: 327081
    PUSH HL                           ; 7767: e5
    LD HL,($815A)                     ; 7768: 2a5a81
    LD BC,$0032                       ; 776B: 013200
    ADD HL,BC                         ; 776E: 09
    LD ($815A),HL                     ; 776F: 225a81
    CALL IMPRIMIR_PUNTUACION_HUD      ; 7772: cd6378
    LD HL,$8012                       ; 7775: 211280
    LD A,($7FC5)                      ; 7778: 3ac57f
    CP $59                            ; 777B: fe59
    CALL Z,FIRM_SOUND_QUEUE           ; 777D: ccaabc
    POP HL                            ; 7780: e1
    JP DIBUJAR_ICONO_SARCOFAGO          ; 7781: c3857d

; MARCO_CONTENIDO_MOMIA_GUARDIANA ($7784): valor exacto $3F. Arranca el
; contador de animacion ($816D=31, ver ANIMAR_APARICION_MOMIA_GUARDIANA)
; y calcula, a partir de la diferencia entre la posicion del jugador y la
; casilla del tramo, un desplazamiento que guarda en
; VARIABLE_CASILLA_APARICION_MOMIA ($8136) -- NO otorga puntos ni redibuja
; marco (a diferencia de las otras 4 ramas): la Momia Guardiana emerge
; poco a poco en vez de completar el tramo al instante.
MARCO_CONTENIDO_MOMIA_GUARDIANA:
    LD A,$1F                          ; 7784: 3e1f
    LD ($816D),A            ; 7786: 326d81
    LD DE,($8155)                     ; 7789: ed5b5581
    LD A,D                            ; 778D: 7a
    SUB H                             ; 778E: 94
    ADD A,E                           ; 778F: 83
    SUB L                             ; 7790: 95
    CP $EC                            ; 7791: feec
    JR Z,APARICION_MOMIA_DESPLAZAMIENTO_A           ; 7793: 280d
    CP $14                            ; 7795: fe14
    JR Z,APARICION_MOMIA_DESPLAZAMIENTO_C           ; 7797: 2813
    CP $FA                            ; 7799: fefa
    JR Z,APARICION_MOMIA_DESPLAZAMIENTO_B           ; 779B: 280a
    LD DE,$0806                       ; 779D: 110608
    JR APLICAR_DESPLAZAMIENTO_APARICION_MOMIA       ; 77A0: 180d
; -- 3 casos de desplazamiento segun el lado por el que aparece la Momia
; Guardiana relativo al jugador (confianza media: no se ha confirmado en
; emulador la correspondencia exacta lado<->valor) --
APARICION_MOMIA_DESPLAZAMIENTO_A:
    LD DE,$0000                       ; 77A2: 110000
    JR APLICAR_DESPLAZAMIENTO_APARICION_MOMIA       ; 77A5: 1808
APARICION_MOMIA_DESPLAZAMIENTO_B:
    LD DE,$0006                       ; 77A7: 110600
    JR APLICAR_DESPLAZAMIENTO_APARICION_MOMIA       ; 77AA: 1803
APARICION_MOMIA_DESPLAZAMIENTO_C:
    LD DE,$0800                       ; 77AC: 110008
APLICAR_DESPLAZAMIENTO_APARICION_MOMIA:
    ADD HL,DE                         ; 77AF: 19
    LD ($8136),HL                     ; 77B0: 223681
    RET                               ; 77B3: c9

; MARCO_CONTENIDO_TESORO ($77B4): valor exacto $5F (caso "generico"/
; tesoro). Suma 5 puntos ($0005), la refresca, encola un sonido. Redibuja
; DIBUJAR_ICONO_TESORO.
MARCO_CONTENIDO_TESORO:
    PUSH HL                           ; 77B4: e5
    LD HL,($815A)                     ; 77B5: 2a5a81
    LD BC,$0005                       ; 77B8: 010500
    ADD HL,BC                         ; 77BB: 09
    LD ($815A),HL                     ; 77BC: 225a81
    CALL IMPRIMIR_PUNTUACION_HUD      ; 77BF: cd6378
    LD HL,$8009                       ; 77C2: 210980
    LD A,($7FC5)                      ; 77C5: 3ac57f
    CP $59                            ; 77C8: fe59
    CALL Z,FIRM_SOUND_QUEUE           ; 77CA: ccaabc
    POP HL                            ; 77CD: e1
    JP DIBUJAR_ICONO_TESORO          ; 77CE: c3cd7d

; PROCESAR_MOVIMIENTO_JUGADOR ($77D1): llamada una vez por jugador y por
; turno, ANTES de las 2 llamadas a PROCESAR_ENCUENTROS_ENTIDADES/
; ACTUALIZAR_MARCO_TRAS_MOVIMIENTO. Es la rutina de LECTURA DE CONTROLES:
; comprueba 8 codigos de tecla de firmware (TABLA_TECLAS_DIRECCION, ver
; arriba -- 2 por direccion, hipotesis alta: uno de teclado y otro de
; joystick, coherente con TEXTO_INSTR_20 "either a Joystick, or the
; Keyboard") y construye un registro de 4 prioridades; las REORDENA segun
; la orientacion actual del jugador (($8157), 4 casos) para dar prioridad
; a "seguir de frente" sobre "girar"; y para la primera direccion
; disponible en ese orden de prioridad, comprueba colision (entrando a
; mitad de CALCULAR_CASILLA_ADYACENTE y de HAY_COLISION) antes de mover
; realmente al jugador saltando a mitad de MOVER_INDICADOR_MENU (que ya
; hacia exactamente este trabajo para el cursor del menu -- confirma que
; esa rutina, pese a su nombre historico, es la MISMA logica de "avanzar
; 8 pixels en una direccion" reutilizada tanto en menus como en partida).
; Confianza alta en la estructura; media en el mapeo exacto de cada uno de
; los 8 codigos de tecla a una direccion fisica concreta.
PROCESAR_MOVIMIENTO_JUGADOR:
    LD HL,$0000                       ; 77D1: 210000
    LD ($814D),HL                     ; 77D4: 224d81
    LD ($814F),HL                     ; 77D7: 224f81
    LD IX,$8150                       ; 77DA: dd215081
    LD DE,$814C                       ; 77DE: 114c81
    LD B,$04                          ; 77E1: 0604
BUCLE_LEER_TECLAS_DIRECCION:
    LD A,(DE)                         ; 77E3: 1a
    CALL FIRM_KM_TEST_KEY             ; 77E4: cd1ebb
    DEC DE                            ; 77E7: 1b
    JR NZ,MARCAR_TECLA_DIRECCION_PULSADA            ; 77E8: 2006
    LD A,(DE)                         ; 77EA: 1a
    CALL FIRM_KM_TEST_KEY             ; 77EB: cd1ebb
    JR Z,CONTINUAR_BUCLE_TECLAS_DIRECCION           ; 77EE: 2803
MARCAR_TECLA_DIRECCION_PULSADA:
    LD (IX+0),B                       ; 77F0: dd7000
CONTINUAR_BUCLE_TECLAS_DIRECCION:
    DEC DE                            ; 77F3: 1b
    DEC IX                            ; 77F4: dd2b
    DJNZ BUCLE_LEER_TECLAS_DIRECCION                        ; 77F6: 10eb
    LD A,($8157)                      ; 77F8: 3a5781
    CP $02                            ; 77FB: fe02
    JR C,REORDENAR_PRIORIDAD_ORIENTACION_01         ; 77FD: 3830
    JR Z,REORDENAR_PRIORIDAD_ORIENTACION_2          ; 77FF: 2820
    CP $04                            ; 7801: fe04
    JR C,REORDENAR_PRIORIDAD_ORIENTACION_3          ; 7803: 380e
    LD L,(IX+1)                       ; 7805: dd6e01
    LD H,(IX+3)                       ; 7808: dd6603
    LD E,(IX+2)                       ; 780B: dd5e02
    LD D,(IX+4)                       ; 780E: dd5604
    JR GUARDAR_PRIORIDAD_DIRECCION    ; 7811: 1828
REORDENAR_PRIORIDAD_ORIENTACION_3:
    LD L,(IX+4)                       ; 7813: dd6e04
    LD H,(IX+2)                       ; 7816: dd6602
    LD E,(IX+1)                       ; 7819: dd5e01
    LD D,(IX+3)                       ; 781C: dd5603
    JR GUARDAR_PRIORIDAD_DIRECCION    ; 781F: 181a
REORDENAR_PRIORIDAD_ORIENTACION_2:
    LD L,(IX+3)                       ; 7821: dd6e03
    LD H,(IX+1)                       ; 7824: dd6601
    LD E,(IX+4)                       ; 7827: dd5e04
    LD D,(IX+2)                       ; 782A: dd5602
    JR GUARDAR_PRIORIDAD_DIRECCION    ; 782D: 180c
REORDENAR_PRIORIDAD_ORIENTACION_01:
    LD L,(IX+2)                       ; 782F: dd6e02
    LD H,(IX+4)                       ; 7832: dd6604
    LD E,(IX+3)                       ; 7835: dd5e03
    LD D,(IX+1)                       ; 7838: dd5601
GUARDAR_PRIORIDAD_DIRECCION:
    LD ($814D),HL                     ; 783B: 224d81
    LD ($814F),DE                     ; 783E: ed534f81
    LD B,$04                          ; 7842: 0604
BUCLE_INTENTAR_MOVER_JUGADOR:
    PUSH BC                           ; 7844: c5
    INC IX                            ; 7845: dd23
    LD A,(IX+0)                       ; 7847: dd7e00
    OR A                              ; 784A: b7
    JR Z,CONTINUAR_INTENTO_MOVER_JUGADOR            ; 784B: 2812
    LD ($8157),A                      ; 784D: 325781
    LD HL,($8155)                     ; 7850: 2a5581
    CALL CALCULAR_CASILLA_ADYACENTE_DESDE_HL                        ; 7853: cd987a  ; entrada intermedia en CALCULAR_CASILLA_ADYACENTE (usa HL ya cargado en vez de ($8164))
    CALL COMPROBAR_ACCESIBILIDAD_CASILLA                        ; 7856: cd647a  ; entrada intermedia en HAY_COLISION (linea 'LD ($8166),DE')
    JR Z,CONTINUAR_INTENTO_MOVER_JUGADOR            ; 7859: 2804
    POP BC                            ; 785B: c1
    JP MOVER_INDICADOR_8PX                          ; 785C: c30b79  ; entra en mitad de MOVER_INDICADOR_MENU (linea 'LD A,$54'), reutiliza el movimiento de 8px
CONTINUAR_INTENTO_MOVER_JUGADOR:
    POP BC                            ; 785F: c1
    DJNZ BUCLE_INTENTAR_MOVER_JUGADOR                        ; 7860: 10e2
    RET                               ; 7862: c9

; ---- $7863-$786B (9 bytes): tercer tramo promovido del INCBIN --
; Sesion 13. Cierra el ultimo hueco del INCBIN original: cae, sin
; ningun salto de por medio, en IMPRIMIR_NUMERO_HL ($786C, ya
; reconstruida desde antes de la Sesion 12) -- confirmado que las 3
; instrucciones enlazan exactamente con el primer byte de esa rutina,
; sin solape ni hueco. Localizada porque ACTUALIZAR_HUD_VIDAS ($65D5,
; mas arriba) la llama con "CALL $7863" para refrescar la puntuacion
; del HUD al empezar cada nivel. Confianza alta (verificada byte a
; byte, encaja exacto con el limite del INCBIN y con IMPRIMIR_NUMERO_HL).
; IMPRIMIR_PUNTUACION_HUD: coloca el cursor en columna 9, fila 1 (la
; posicion de la puntuacion en el HUD, coherente con las otras
; posiciones de cursor ya usadas en este tramo) y cae directamente en
; IMPRIMIR_NUMERO_HL con HL=($815A) (puntuacion).
IMPRIMIR_PUNTUACION_HUD:
    LD HL,$0901                      ; 7863: 210109
    CALL FIRM_TXT_SET_CURSOR         ; 7866: cd75bb
    LD HL,($815A)                    ; 7869: 2a5a81

; ---- IMPRIMIR_NUMERO_HL / ESPERAR_TECLA_2C / ANIMAR_OPCION_MENU / ACTUALIZAR_SECUENCIA_SONIDO /
; MOVER_INDICADOR_MENU / INICIALIZAR_ENTIDADES / INICIALIZAR_UNA_ENTIDAD / COLOCAR_ENTIDAD /
; HAY_COLISION / CALCULAR_CASILLA_ADYACENTE / ELEGIR_DIRECCION_HACIA_OBJETIVO /
; PREPARAR_DIBUJAR_ENTIDAD+DIBUJAR_ENTIDAD / DIBUJAR_CASILLA_MAPA / CONSULTAR_CASILLA_MAPA /
; GENERAR_ALEATORIO+MEZCLAR_ALEATORIO / DIBUJAR_ICONO_SARCOFAGO..TESORO ----
; Bloque grande (1401 bytes, 21 rutinas) -- Sesion 6: se confirmo que
; $78D1 (bombeo de sonido) esta pegado sin hueco a $78F7, $7996,
; $7A10, $7AB6 y $7AF2->$7B39 (que cae sin RET propio, es un solo
; bloque logico con dos puntos de entrada), y estos a su vez sin
; hueco hasta el final del tramo de marco decorativo ya conocido
; desde la Sesion 5 -- todo un unico tramo contiguo. Hipotesis por
; rutina (todas SIN verificar en emulador, nombres provisionales):
; ACTUALIZAR_SECUENCIA_SONIDO (alta) avanza una tabla CIRCULAR de
; guion de sonido en $905C-$937D (confirmado: al llegar al final
; vuelve al principio) y encola sonido via FIRM_SOUND_QUEUE cuando
; toca. MOVER_INDICADOR_MENU (media) borra y redibuja un indicador
; de menu via DIBUJAR_ENTIDAD. COLOCAR_ENTIDAD (media) intenta
; colocar una entidad de $816D comprobando colision (HAY_COLISION)
; en dos casillas, y si falla llama a DIBUJAR_ENTIDAD directamente.
; HAY_COLISION (alta) comprueba solapes con otras entidades Y
; accesibilidad contra la estructura de mapa en $8200 (2 bytes de
; estado por casilla, offset 40/41 de la entrada de 42 bytes).
; ELEGIR_DIRECCION_HACIA_OBJETIVO (media-alta) compara ejes con
; desempate aleatorio -- patron de IA de persecucion. DIBUJAR_
; ENTIDAD (media-alta) es un gran dispatcher de unas 20 tablas de
; sprite de 4x16 bytes, seleccionadas por tipo (caracter ' '/T/A/O),
; direccion y un bit de animacion de 2 fotogramas (IX+4 de la
; entidad) -- usa el mismo patron de volcado que COPIAR_BLOQUE_A_
; LIENZO. DIBUJAR_CASILLA_MAPA (media) hace lo mismo pero para
; casillas de 2x8 bytes, seleccionadas por el valor de la casilla
; del mapa. Ver FINDINGS.md Sesion 6.
IMPRIMIR_NUMERO_HL:
    LD B,$04                         ; 786C: 0604
    LD IY,TABLA_POSICIONES_DECIMALES-2 ; 786E: fd213687
BUCLE_CALCULAR_DIGITO_DECIMAL:
    INC IY                           ; 7872: fd23
    INC IY                           ; 7874: fd23
    LD E,(IY+0)                      ; 7876: fd5e00
    LD D,(IY+1)                      ; 7879: fd5601
    XOR A                            ; 787C: af
    LD A,$30                         ; 787D: 3e30
BUCLE_RESTAR_PESO_DECIMAL:
    SBC HL,DE                        ; 787F: ed52
    JR C,RESTAURAR_RESTO_DECIMAL     ; 7881: 3803
    INC A                            ; 7883: 3c
    JR BUCLE_RESTAR_PESO_DECIMAL     ; 7884: 18f9
RESTAURAR_RESTO_DECIMAL:
    ADD HL,DE                        ; 7886: 19
    CALL FIRM_TXT_OUTPUT             ; 7887: cd5abb
    DJNZ BUCLE_CALCULAR_DIGITO_DECIMAL                       ; 788A: 10e6
    LD A,$30                         ; 788C: 3e30
    ADD A,L                          ; 788E: 85
    CALL FIRM_TXT_OUTPUT             ; 788F: cd5abb
    RET                              ; 7892: c9
ESPERAR_TECLA_2C:
    LD A,$2C                         ; 7893: 3e2c
    CALL FIRM_KM_TEST_KEY            ; 7895: cd1ebb
    RET Z                            ; 7898: c8
BUCLE_ESPERAR_TECLA_2C_LIBERADA:
    CALL ACTUALIZAR_SECUENCIA_SONIDO ; 7899: cdd178
    LD A,$2C                         ; 789C: 3e2c
    CALL FIRM_KM_TEST_KEY            ; 789E: cd1ebb
    JR NZ,BUCLE_ESPERAR_TECLA_2C_LIBERADA            ; 78A1: 20f6
BUCLE_ESPERAR_CARACTER_TECLADO:
    CALL ACTUALIZAR_SECUENCIA_SONIDO ; 78A3: cdd178
    CALL FIRM_KM_READ_CHAR           ; 78A6: cd09bb
    JR C,BUCLE_ESPERAR_CARACTER_TECLADO            ; 78A9: 38f8
BUCLE_VACIAR_BUFER_TECLADO:
    CALL ACTUALIZAR_SECUENCIA_SONIDO ; 78AB: cdd178
    CALL FIRM_KM_READ_CHAR           ; 78AE: cd09bb
    JR NC,BUCLE_VACIAR_BUFER_TECLADO            ; 78B1: 30f8
    CALL FIRM_KM_CHAR_RETURN         ; 78B3: cd0cbb
    RET                              ; 78B6: c9
ANIMAR_OPCION_MENU:
    PUSH BC                          ; 78B7: c5
    CALL COLOCAR_ENTIDAD             ; 78B8: cd9679
    CALL ACTUALIZAR_SECUENCIA_SONIDO ; 78BB: cdd178
    LD DE,($8153)                    ; 78BE: ed5b5381
BUCLE_DECREMENTAR_RETARDO_MENU:
    DEC DE                           ; 78C2: 1b
    LD A,D                           ; 78C3: 7a
    OR E                             ; 78C4: b3
    JR NZ,BUCLE_DECREMENTAR_RETARDO_MENU            ; 78C5: 20fb
    POP BC                           ; 78C7: c1
    LD A,$02                         ; 78C8: 3e02
    ADD A,B                          ; 78CA: 80
    CP $15                           ; 78CB: fe15
    LD B,A                           ; 78CD: 47
    JR C,ANIMAR_OPCION_MENU          ; 78CE: 38e7
    RET                              ; 78D0: c9
ACTUALIZAR_SECUENCIA_SONIDO:
    LD HL,(PUNTERO_GUION_SONIDO)     ; 78D1: 2a5a90
    PUSH HL                          ; 78D4: e5
    LD A,(FLAG_MUSICA_FONDO)         ; 78D5: 3ac47f
    CP $59                           ; 78D8: fe59
    CALL Z,FIRM_SOUND_QUEUE          ; 78DA: ccaabc
    POP HL                           ; 78DD: e1
    RET NC                           ; 78DE: d0
    LD DE,GUION_SONIDO_ULTIMO_REGISTRO ; 78DF: 117d93
    XOR A                            ; 78E2: af
    EX DE,HL                         ; 78E3: eb
    SBC HL,DE                        ; 78E4: ed52
    JR Z,REINICIAR_GUION_SONIDO      ; 78E6: 2808
    LD HL,$0009                      ; 78E8: 210900
    ADD HL,DE                        ; 78EB: 19
    LD (PUNTERO_GUION_SONIDO),HL     ; 78EC: 225a90
    RET                              ; 78EF: c9
REINICIAR_GUION_SONIDO:
    LD HL,GUION_SONIDO_CIRCULAR      ; 78F0: 215c90
    LD (PUNTERO_GUION_SONIDO),HL     ; 78F3: 225a90
    RET                              ; 78F6: c9
MOVER_INDICADOR_MENU:
    LD A,($8155)                     ; 78F7: 3a5581
    CP $1A                           ; 78FA: fe1a
    JR NZ,COMPROBAR_LIMITE_INFERIOR_INDICADOR            ; 78FC: 2004
    LD A,$02                         ; 78FE: 3e02
    JR GUARDAR_DIRECCION_INDICADOR   ; 7900: 1806
COMPROBAR_LIMITE_INFERIOR_INDICADOR:
    CP $34                           ; 7902: fe34
    JR NZ,MOVER_INDICADOR_8PX        ; 7904: 2005
    LD A,$04                         ; 7906: 3e04
GUARDAR_DIRECCION_INDICADOR:
    LD ($8157),A                     ; 7908: 325781
MOVER_INDICADOR_8PX:
    LD A,$54                         ; 790B: 3e54
    LD DE,($8155)                    ; 790D: ed5b5581
    CALL DIBUJAR_ENTIDAD             ; 7911: cd397b
    LD A,($8157)                     ; 7914: 3a5781
    CP $02                           ; 7917: fe02
    JR C,INDICADOR_RETROCEDER_COLUMNA            ; 7919: 3814
    JR Z,INDICADOR_AVANZAR_FILA      ; 791B: 280b
    CP $03                           ; 791D: fe03
    JR Z,INDICADOR_AVANZAR_COLUMNA   ; 791F: 2816
    LD A,($8155)                     ; 7921: 3a5581
    DEC A                            ; 7924: 3d
    DEC A                            ; 7925: 3d
    JR GUARDAR_FILA_INDICADOR        ; 7926: 181a
INDICADOR_AVANZAR_FILA:
    LD A,($8155)                     ; 7928: 3a5581
    INC A                            ; 792B: 3c
    INC A                            ; 792C: 3c
    JR GUARDAR_FILA_INDICADOR        ; 792D: 1813
INDICADOR_RETROCEDER_COLUMNA:
    LD A,($8156)                     ; 792F: 3a5681
    LD B,$08                         ; 7932: 0608
    SUB B                            ; 7934: 90
    JR GUARDAR_COLUMNA_INDICADOR     ; 7935: 1806
INDICADOR_AVANZAR_COLUMNA:
    LD A,($8156)                     ; 7937: 3a5681
    LD B,$08                         ; 793A: 0608
    ADD A,B                          ; 793C: 80
GUARDAR_COLUMNA_INDICADOR:
    LD ($8156),A                     ; 793D: 325681
    JR REDIBUJAR_INDICADOR_MENU      ; 7940: 1803
GUARDAR_FILA_INDICADOR:
    LD ($8155),A                     ; 7942: 325581
REDIBUJAR_INDICADOR_MENU:
    LD A,$41                         ; 7945: 3e41
    LD DE,($8155)                    ; 7947: ed5b5581
    CALL DIBUJAR_ENTIDAD             ; 794B: cd397b
    RET                              ; 794E: c9
INICIALIZAR_ENTIDADES:
    LD A,($8169)                     ; 794F: 3a6981
    LD B,A                           ; 7952: 47
BUCLE_INICIALIZAR_ENTIDADES:
    PUSH BC                          ; 7953: c5
    CALL INICIALIZAR_UNA_ENTIDAD     ; 7954: cd5b79
    POP BC                           ; 7957: c1
    DJNZ BUCLE_INICIALIZAR_ENTIDADES                       ; 7958: 10f9
    RET                              ; 795A: c9
INICIALIZAR_UNA_ENTIDAD:
    LD A,($816C)                     ; 795B: 3a6c81
    INC A                            ; 795E: 3c
    LD ($816C),A                     ; 795F: 326c81
    LD B,A                           ; 7962: 47
    LD IX,ARRAY_ENTIDADES             ; 7963: dd216d81
    LD DE,$0005                      ; 7967: 110500
BUCLE_AVANZAR_ENTIDAD_NUEVA:
    ADD IX,DE                        ; 796A: dd19
    DJNZ BUCLE_AVANZAR_ENTIDAD_NUEVA                       ; 796C: 10fc
    LD A,$04                         ; 796E: 3e04
    CALL GENERAR_ALEATORIO           ; 7970: cd537d
    INC A                            ; 7973: 3c
    LD (IX+0),A                      ; 7974: dd7700
    LD A,$04                         ; 7977: 3e04
    CALL GENERAR_ALEATORIO           ; 7979: cd537d
    INC A                            ; 797C: 3c
    LD (IX+1),A                      ; 797D: dd7701
    LD H,$00                         ; 7980: 2600
    LD A,($816C)                     ; 7982: 3a6c81
    LD L,A                           ; 7985: 6f
    ADD HL,HL                        ; 7986: 29
    LD DE,(VARIABLE_TEMPORAL_HL_1)                    ; 7987: ed5b4586
    ADD HL,DE                        ; 798B: 19
    LD E,(HL)                        ; 798C: 5e
    INC HL                           ; 798D: 23
    LD D,(HL)                        ; 798E: 56
    LD (IX+2),D                      ; 798F: dd7202
    LD (IX+3),E                      ; 7992: dd7303
    RET                              ; 7995: c9
COLOCAR_ENTIDAD:
    LD IX,ARRAY_ENTIDADES             ; 7996: dd216d81
    LD DE,$0005                      ; 799A: 110500
BUCLE_AVANZAR_ENTIDAD_COLOCAR:
    ADD IX,DE                        ; 799D: dd19
    DJNZ BUCLE_AVANZAR_ENTIDAD_COLOCAR                       ; 799F: 10fc
    LD A,(IX+0)                      ; 79A1: dd7e00
    OR A                             ; 79A4: b7
    JR NZ,GUARDAR_PUNTERO_ENTIDAD_COLOCAR            ; 79A5: 2005
    LD A,(IX+1)                      ; 79A7: dd7e01
    OR A                             ; 79AA: b7
    RET Z                            ; 79AB: c8
GUARDAR_PUNTERO_ENTIDAD_COLOCAR:
    LD ($8162),IX                    ; 79AC: dd226281
    LD D,(IX+2)                      ; 79B0: dd5602
    LD E,(IX+3)                      ; 79B3: dd5e03
    LD ($8164),DE                    ; 79B6: ed536481
    LD A,($8161)                     ; 79BA: 3a6181
    CALL GENERAR_ALEATORIO           ; 79BD: cd537d
    OR A                             ; 79C0: b7
    CALL Z,ELEGIR_DIRECCION_HACIA_OBJETIVO ; 79C1: ccb67a
    LD HL,($8162)                    ; 79C4: 2a6281
    CALL HAY_COLISION                ; 79C7: cd107a
    JP NZ,PREPARAR_DIBUJAR_ENTIDAD   ; 79CA: c2f27a
    LD HL,($8162)                    ; 79CD: 2a6281
    INC HL                           ; 79D0: 23
    CALL HAY_COLISION                ; 79D1: cd107a
    JP NZ,PREPARAR_DIBUJAR_ENTIDAD   ; 79D4: c2f27a
    LD A,$02                         ; 79D7: 3e02
    CALL GENERAR_ALEATORIO           ; 79D9: cd537d
    OR A                             ; 79DC: b7
    JR NZ,OBTENER_POSICION_ACTUAL_ENTIDAD            ; 79DD: 200b
    LD D,(IX+2)                      ; 79DF: dd5602
    LD E,(IX+3)                      ; 79E2: dd5e03
    LD A,$4F                         ; 79E5: 3e4f
    JP DIBUJAR_ENTIDAD               ; 79E7: c3397b
OBTENER_POSICION_ACTUAL_ENTIDAD:
    LD B,(IX+0)                      ; 79EA: dd4600
    LD C,(IX+1)                      ; 79ED: dd4e01
    DEC A                            ; 79F0: 3d
    JR Z,INCREMENTAR_POSICION_ENTIDAD            ; 79F1: 2804
    DEC B                            ; 79F3: 05
    DEC C                            ; 79F4: 0d
    JR NORMALIZAR_POSICION_ENTIDAD   ; 79F5: 1802
INCREMENTAR_POSICION_ENTIDAD:
    INC B                            ; 79F7: 04
    INC C                            ; 79F8: 0c
NORMALIZAR_POSICION_ENTIDAD:
    LD HL,$864B                      ; 79F9: 214b86
    LD D,$00                         ; 79FC: 1600
    LD E,B                           ; 79FE: 58
    INC E                            ; 79FF: 1c
    ADD HL,DE                        ; 7A00: 19
    LD B,(HL)                        ; 7A01: 46
    LD HL,$864B                      ; 7A02: 214b86
    LD E,C                           ; 7A05: 59
    INC E                            ; 7A06: 1c
    ADD HL,DE                        ; 7A07: 19
    LD C,(HL)                        ; 7A08: 4e
    LD (IX+0),B                      ; 7A09: dd7000
    LD (IX+1),C                      ; 7A0C: dd7101
    RET                              ; 7A0F: c9
HAY_COLISION:
    LD A,(HL)                        ; 7A10: 7e
    LD ($8159),A                     ; 7A11: 325981
    OR A                             ; 7A14: b7
    RET Z                            ; 7A15: c8
    CALL CALCULAR_CASILLA_ADYACENTE  ; 7A16: cd957a
    XOR A                            ; 7A19: af
    LD ($8610),A                     ; 7A1A: 321086
    LD IY,ARRAY_ENTIDADES             ; 7A1D: fd216d81
    LD A,($816C)                     ; 7A21: 3a6c81
    LD B,A                           ; 7A24: 47
BUCLE_COMPROBAR_COLISION_ENTIDADES:
    PUSH BC                          ; 7A25: c5
    LD BC,$0005                      ; 7A26: 010500
    ADD IY,BC                        ; 7A29: fd09
    LD A,(IY+0)                      ; 7A2B: fd7e00
    OR (IY+1)                        ; 7A2E: fdb601
    JR Z,SIGUIENTE_ENTIDAD_COLISION  ; 7A31: 2825
    LD A,(IY+2)                      ; 7A33: fd7e02
    SUB D                            ; 7A36: 92
    CP $F8                           ; 7A37: fef8
    JR Z,COMPROBAR_COLISION_EJE_Y    ; 7A39: 2807
    CP $08                           ; 7A3B: fe08
    JR Z,COMPROBAR_COLISION_EJE_Y    ; 7A3D: 2803
    OR A                             ; 7A3F: b7
    JR NZ,SIGUIENTE_ENTIDAD_COLISION ; 7A40: 2016
COMPROBAR_COLISION_EJE_Y:
    LD A,(IY+3)                      ; 7A42: fd7e03
    SUB E                            ; 7A45: 93
    CP $FE                           ; 7A46: fefe
    JR Z,CONTAR_ENTIDAD_EN_COLISION  ; 7A48: 2807
    CP $02                           ; 7A4A: fe02
    JR Z,CONTAR_ENTIDAD_EN_COLISION  ; 7A4C: 2803
    OR A                             ; 7A4E: b7
    JR NZ,SIGUIENTE_ENTIDAD_COLISION ; 7A4F: 2007
CONTAR_ENTIDAD_EN_COLISION:
    LD A,($8610)                     ; 7A51: 3a1086
    INC A                            ; 7A54: 3c
    LD ($8610),A                     ; 7A55: 321086
SIGUIENTE_ENTIDAD_COLISION:
    POP BC                           ; 7A58: c1
    DJNZ BUCLE_COMPROBAR_COLISION_ENTIDADES                       ; 7A59: 10ca
    LD A,($8610)                     ; 7A5B: 3a1086
    CP $01                           ; 7A5E: fe01
    JR Z,COMPROBAR_ACCESIBILIDAD_CASILLA            ; 7A60: 2802
    XOR A                            ; 7A62: af
    RET                              ; 7A63: c9
COMPROBAR_ACCESIBILIDAD_CASILLA:
    LD ($8166),DE                    ; 7A64: ed536681
    LD IY,MAPA_CASILLAS               ; 7A68: fd210082
    LD A,E                           ; 7A6C: 7b
    SRL A                            ; 7A6D: cb3f
    LD B,$00                         ; 7A6F: 0600
    LD C,A                           ; 7A71: 4f
    ADD IY,BC                        ; 7A72: fd09
    LD E,D                           ; 7A74: 5a
    LD D,$00                         ; 7A75: 1600
    ADD IY,DE                        ; 7A77: fd19
    ADD IY,DE                        ; 7A79: fd19
    ADD IY,DE                        ; 7A7B: fd19
    ADD IY,DE                        ; 7A7D: fd19
    ADD IY,DE                        ; 7A7F: fd19
    LD A,(IY+0)                      ; 7A81: fd7e00
    OR A                             ; 7A84: b7
    RET Z                            ; 7A85: c8
    LD A,(IY+1)                      ; 7A86: fd7e01
    OR A                             ; 7A89: b7
    RET Z                            ; 7A8A: c8
    LD A,(IY+40)                     ; 7A8B: fd7e28
    OR A                             ; 7A8E: b7
    RET Z                            ; 7A8F: c8
    LD A,(IY+41)                     ; 7A90: fd7e29
    OR A                             ; 7A93: b7
    RET                              ; 7A94: c9
CALCULAR_CASILLA_ADYACENTE:
    LD HL,($8164)                    ; 7A95: 2a6481
CALCULAR_CASILLA_ADYACENTE_DESDE_HL:
    CP $02                           ; 7A98: fe02
    JR C,RESTAR_FILA_ADYACENTE       ; 7A9A: 3814
    JR Z,SUMAR_COLUMNA_ADYACENTE     ; 7A9C: 280e
    CP $03                           ; 7A9E: fe03
    JR Z,SUMAR_FILA_ADYACENTE        ; 7AA0: 2804
    DEC L                            ; 7AA2: 2d
    DEC L                            ; 7AA3: 2d
    JR DEVOLVER_CASILLA_ADYACENTE    ; 7AA4: 180e
SUMAR_FILA_ADYACENTE:
    LD A,H                           ; 7AA6: 7c
    ADD A,$08                        ; 7AA7: c608
    LD H,A                           ; 7AA9: 67
    JR DEVOLVER_CASILLA_ADYACENTE    ; 7AAA: 1808
SUMAR_COLUMNA_ADYACENTE:
    INC L                            ; 7AAC: 2c
    INC L                            ; 7AAD: 2c
    JR DEVOLVER_CASILLA_ADYACENTE    ; 7AAE: 1804
RESTAR_FILA_ADYACENTE:
    LD A,H                           ; 7AB0: 7c
    SUB $08                          ; 7AB1: d608
    LD H,A                           ; 7AB3: 67
DEVOLVER_CASILLA_ADYACENTE:
    EX DE,HL                         ; 7AB4: eb
    RET                              ; 7AB5: c9
ELEGIR_DIRECCION_HACIA_OBJETIVO:
    LD BC,($8164)                    ; 7AB6: ed4b6481
    LD A,($8156)                     ; 7ABA: 3a5681
    SUB B                            ; 7ABD: 90
    JR C,DIRECCION_X_NEGATIVA        ; 7ABE: 3806
    JR Z,GUARDAR_DIRECCION_EJE_X     ; 7AC0: 2806
    LD A,$03                         ; 7AC2: 3e03
    JR GUARDAR_DIRECCION_EJE_X       ; 7AC4: 1802
DIRECCION_X_NEGATIVA:
    LD A,$01                         ; 7AC6: 3e01
GUARDAR_DIRECCION_EJE_X:
    LD ($815F),A                     ; 7AC8: 325f81
    LD A,($8155)                     ; 7ACB: 3a5581
    SUB C                            ; 7ACE: 91
    JR C,DIRECCION_Y_NEGATIVA        ; 7ACF: 3806
    JR Z,GUARDAR_DIRECCION_EJE_Y     ; 7AD1: 2806
    LD A,$02                         ; 7AD3: 3e02
    JR GUARDAR_DIRECCION_EJE_Y       ; 7AD5: 1802
DIRECCION_Y_NEGATIVA:
    LD A,$04                         ; 7AD7: 3e04
GUARDAR_DIRECCION_EJE_Y:
    LD ($8160),A                     ; 7AD9: 326081
    LD A,$02                         ; 7ADC: 3e02
    CALL GENERAR_ALEATORIO           ; 7ADE: cd537d
    LD BC,($815F)                    ; 7AE1: ed4b5f81
    OR A                             ; 7AE5: b7
    JR Z,GUARDAR_DIRECCION_ELEGIDA   ; 7AE6: 2803
    LD A,B                           ; 7AE8: 78
    LD B,C                           ; 7AE9: 41
    LD C,A                           ; 7AEA: 4f
GUARDAR_DIRECCION_ELEGIDA:
    LD (IX+0),B                      ; 7AEB: dd7000
    LD (IX+1),C                      ; 7AEE: dd7101
    RET                              ; 7AF1: c9
PREPARAR_DIBUJAR_ENTIDAD:
    LD DE,($8164)                    ; 7AF2: ed5b6481
    LD A,($8159)                     ; 7AF6: 3a5981
    CP $02                           ; 7AF9: fe02
    JR C,DESPLAZAR_FILA_CASILLA_ANTERIOR            ; 7AFB: 381c
    JR Z,REDIBUJAR_CASILLA_FILA_ACTUAL            ; 7AFD: 2806
    CP $03                           ; 7AFF: fe03
    JR Z,REDIBUJAR_CASILLA_FILA_SIGUIENTE            ; 7B01: 281a
    INC E                            ; 7B03: 1c
    INC E                            ; 7B04: 1c
REDIBUJAR_CASILLA_FILA_ACTUAL:
    CALL CONSULTAR_CASILLA_MAPA      ; 7B05: cd3e7d
    LD A,(HL)                        ; 7B08: 7e
    CALL DIBUJAR_CASILLA_MAPA        ; 7B09: cde67c
    LD A,$08                         ; 7B0C: 3e08
    ADD A,D                          ; 7B0E: 82
    LD D,A                           ; 7B0F: 57
    CALL CONSULTAR_CASILLA_MAPA      ; 7B10: cd3e7d
    LD A,(HL)                        ; 7B13: 7e
    CALL DIBUJAR_CASILLA_MAPA        ; 7B14: cde67c
    JR GUARDAR_NUEVA_POSICION_ENTIDAD            ; 7B17: 1814
DESPLAZAR_FILA_CASILLA_ANTERIOR:
    LD A,$08                         ; 7B19: 3e08
    ADD A,D                          ; 7B1B: 82
    LD D,A                           ; 7B1C: 57
REDIBUJAR_CASILLA_FILA_SIGUIENTE:
    CALL CONSULTAR_CASILLA_MAPA      ; 7B1D: cd3e7d
    LD A,(HL)                        ; 7B20: 7e
    CALL DIBUJAR_CASILLA_MAPA        ; 7B21: cde67c
    INC E                            ; 7B24: 1c
    INC E                            ; 7B25: 1c
    CALL CONSULTAR_CASILLA_MAPA      ; 7B26: cd3e7d
    LD A,(HL)                        ; 7B29: 7e
    CALL DIBUJAR_CASILLA_MAPA        ; 7B2A: cde67c
GUARDAR_NUEVA_POSICION_ENTIDAD:
    LD DE,($8166)                    ; 7B2D: ed5b6681
    LD (IX+2),D                      ; 7B31: dd7202
    LD (IX+3),E                      ; 7B34: dd7303
    LD A,$4F                         ; 7B37: 3e4f
; Sesion 8: confirmado el despacho por tipo de entidad (byte en A al
; entrar): ' '($20)->IY=$8959, 'T'($54)->sub-dispatch en ($8157) con
; anchos/altos variables (32-64 bytes; Sesion 11: las 4 losetas que
; faltaban por nombrar -- LOSETA_PISADA_ESCRITURA_VALOR4/_5/_6/_7 --
; ya tienen etiqueta, ver mas abajo), 'A'($41)
; y 'O'($4F)->sub-dispatch en ($8157)/($8159) respectivamente hacia 8
; sprites de 64 bytes cada uno (SPRITE_JUGADOR_G1_F1.. / SPRITE_MOMIA_
; G1_F1.., ver mas abajo), cualquier otro caracter (por defecto,
; incluido fallthrough)->IY=TABLAS_SPRITE_CASILLA ($8919). Ver
; FINDINGS.md Sesion 8 y Sesion 11.
DIBUJAR_ENTIDAD:
    PUSH AF                          ; 7B39: f5
    LD A,$10                         ; 7B3A: 3e10
    LD ($7CC6),A                     ; 7B3C: 32c67c
    LD A,$04                         ; 7B3F: 3e04
    LD ($7CD0),A                     ; 7B41: 32d07c
    POP AF                           ; 7B44: f1
    CP $20                           ; 7B45: fe20
    JR Z,DIBUJAR_ENTIDAD_CARACTER_ESPACIO            ; 7B47: 2815
    CP $54                           ; 7B49: fe54
    JR Z,DIBUJAR_ENTIDAD_LETRA_T     ; 7B4B: 2818
    CP $41                           ; 7B4D: fe41
    JP Z,DIBUJAR_ENTIDAD_LETRA_A     ; 7B4F: ca2f7c
    CP $4F                           ; 7B52: fe4f
    JP Z,DIBUJAR_ENTIDAD_LETRA_O     ; 7B54: ca7c7c
    LD IY,TABLAS_SPRITE_CASILLA       ; 7B57: fd211989
    JP VOLCAR_SPRITE_A_PANTALLA      ; 7B5B: c3c47c
DIBUJAR_ENTIDAD_CARACTER_ESPACIO:
    LD IY,$8959                      ; 7B5E: fd215989
    JP VOLCAR_SPRITE_A_PANTALLA      ; 7B62: c3c47c
DIBUJAR_ENTIDAD_LETRA_T:
    LD A,($8157)                     ; 7B65: 3a5781
    CP $02                           ; 7B68: fe02
    JP C,DIBUJAR_LETRA_T_PISADA_VERTICAL            ; 7B6A: da017c
    JR Z,DIBUJAR_LETRA_T_PISADA_3    ; 7B6D: 2862
    CP $03                           ; 7B6F: fe03
    JR Z,DIBUJAR_LETRA_T_PISADA_6    ; 7B71: 2832
    LD IY,LOSETA_MAPA_PISADA_7        ; 7B73: fd21898a
    LD A,$02                         ; 7B77: 3e02
    LD ($7CD0),A                     ; 7B79: 32d07c
    INC E                            ; 7B7C: 1c
    INC E                            ; 7B7D: 1c
    CALL CONSULTAR_CASILLA_MAPA      ; 7B7E: cd3e7d
    LD A,$08                         ; 7B81: 3e08
    LD (HL),A                        ; 7B83: 77
    ADD A,$18                        ; 7B84: c618
    LD BC,$0028                      ; 7B86: 012800
    ADD HL,BC                        ; 7B89: 09
    LD (HL),A                        ; 7B8A: 77
    LD A,($8158)                     ; 7B8B: 3a5881
    XOR $01                          ; 7B8E: ee01
    LD ($8158),A                     ; 7B90: 325881
    JP Z,VOLCAR_SPRITE_A_PANTALLA    ; 7B93: cac47c
    LD IY,LOSETA_PISADA_ESCRITURA_VALOR7 ; 7B96: fd21998a
    LD A,$07                         ; 7B9A: 3e07
    LD (HL),A                        ; 7B9C: 77
    ADD A,$19                        ; 7B9D: c619
    SBC HL,BC                        ; 7B9F: ed42
    LD (HL),A                        ; 7BA1: 77
    JP VOLCAR_SPRITE_A_PANTALLA      ; 7BA2: c3c47c
DIBUJAR_LETRA_T_PISADA_6:
    LD IY,LOSETA_PISADA_ESCRITURA_VALOR6 ; 7BA5: fd21298a
    LD A,$08                         ; 7BA9: 3e08
    LD ($7CC6),A                     ; 7BAB: 32c67c
    CALL CONSULTAR_CASILLA_MAPA      ; 7BAE: cd3e7d
    LD A,$06                         ; 7BB1: 3e06
    LD (HL),A                        ; 7BB3: 77
    LD A,$20                         ; 7BB4: 3e20
    INC HL                           ; 7BB6: 23
    LD (HL),A                        ; 7BB7: 77
    LD A,($8158)                     ; 7BB8: 3a5881
    XOR $01                          ; 7BBB: ee01
    LD ($8158),A                     ; 7BBD: 325881
    JP Z,VOLCAR_SPRITE_A_PANTALLA    ; 7BC0: cac47c
    LD IY,LOSETA_PISADA_ESCRITURA_VALOR5 ; 7BC3: fd21498a
    LD A,$05                         ; 7BC7: 3e05
    LD (HL),A                        ; 7BC9: 77
    LD A,$20                         ; 7BCA: 3e20
    DEC HL                           ; 7BCC: 2b
    LD (HL),A                        ; 7BCD: 77
    JP VOLCAR_SPRITE_A_PANTALLA      ; 7BCE: c3c47c
DIBUJAR_LETRA_T_PISADA_3:
    LD IY,LOSETA_MAPA_PISADA_3        ; 7BD1: fd21f989
    LD A,$02                         ; 7BD5: 3e02
    LD ($7CD0),A                     ; 7BD7: 32d07c
    CALL CONSULTAR_CASILLA_MAPA      ; 7BDA: cd3e7d
    LD A,$03                         ; 7BDD: 3e03
    LD (HL),A                        ; 7BDF: 77
    ADD A,$1D                        ; 7BE0: c61d
    LD BC,$0028                      ; 7BE2: 012800
    ADD HL,BC                        ; 7BE5: 09
    LD (HL),A                        ; 7BE6: 77
    LD A,($8158)                     ; 7BE7: 3a5881
    XOR $01                          ; 7BEA: ee01
    LD ($8158),A                     ; 7BEC: 325881
    JP Z,VOLCAR_SPRITE_A_PANTALLA    ; 7BEF: cac47c
    LD IY,LOSETA_PISADA_ESCRITURA_VALOR4 ; 7BF2: fd21098a
    LD A,$04                         ; 7BF6: 3e04
    LD (HL),A                        ; 7BF8: 77
    ADD A,$1C                        ; 7BF9: c61c
    SBC HL,BC                        ; 7BFB: ed42
    LD (HL),A                        ; 7BFD: 77
    JP VOLCAR_SPRITE_A_PANTALLA      ; 7BFE: c3c47c
DIBUJAR_LETRA_T_PISADA_VERTICAL:
    LD IY,LOSETA_PISADAS_VERTICAL_1   ; 7C01: fd219989
    LD A,$08                         ; 7C05: 3e08
    LD ($7CC6),A                     ; 7C07: 32c67c
    ADD A,D                          ; 7C0A: 82
    LD D,A                           ; 7C0B: 57
    CALL CONSULTAR_CASILLA_MAPA      ; 7C0C: cd3e7d
    LD A,$01                         ; 7C0F: 3e01
    LD (HL),A                        ; 7C11: 77
    LD A,$20                         ; 7C12: 3e20
    INC HL                           ; 7C14: 23
    LD (HL),A                        ; 7C15: 77
    LD A,($8158)                     ; 7C16: 3a5881
    XOR $01                          ; 7C19: ee01
    LD ($8158),A                     ; 7C1B: 325881
    JP Z,VOLCAR_SPRITE_A_PANTALLA    ; 7C1E: cac47c
    LD IY,LOSETA_PISADAS_VERTICAL_2   ; 7C21: fd21b989
    LD A,$02                         ; 7C25: 3e02
    LD (HL),A                        ; 7C27: 77
    LD A,$20                         ; 7C28: 3e20
    DEC HL                           ; 7C2A: 2b
    LD (HL),A                        ; 7C2B: 77
    JP VOLCAR_SPRITE_A_PANTALLA      ; 7C2C: c3c47c
DIBUJAR_ENTIDAD_LETRA_A:
    LD A,($8157)                     ; 7C2F: 3a5781
    CP $02                           ; 7C32: fe02
    JR C,DIBUJAR_LETRA_A_GRUPO_1     ; 7C34: 3836
    JR Z,DIBUJAR_LETRA_A_GRUPO_2     ; 7C36: 2824
    CP $03                           ; 7C38: fe03
    JR Z,DIBUJAR_LETRA_A_GRUPO_3     ; 7C3A: 2810
    LD IY,SPRITE_JUGADOR_G4_F1        ; 7C3C: fd21398c
    LD A,($8158)                     ; 7C40: 3a5881
    OR A                             ; 7C43: b7
    JR Z,VOLCAR_SPRITE_A_PANTALLA    ; 7C44: 287e
    LD IY,SPRITE_JUGADOR_G4_F2        ; 7C46: fd21798c
    JR VOLCAR_SPRITE_A_PANTALLA      ; 7C4A: 1878
DIBUJAR_LETRA_A_GRUPO_3:
    LD IY,SPRITE_JUGADOR_G3_F1        ; 7C4C: fd21b98b
    LD A,($8158)                     ; 7C50: 3a5881
    OR A                             ; 7C53: b7
    JR Z,VOLCAR_SPRITE_A_PANTALLA    ; 7C54: 286e
    LD IY,SPRITE_JUGADOR_G3_F2        ; 7C56: fd21f98b
    JR VOLCAR_SPRITE_A_PANTALLA      ; 7C5A: 1868
DIBUJAR_LETRA_A_GRUPO_2:
    LD IY,SPRITE_JUGADOR_G2_F1        ; 7C5C: fd21398b
    LD A,($8158)                     ; 7C60: 3a5881
    OR A                             ; 7C63: b7
    JR Z,VOLCAR_SPRITE_A_PANTALLA    ; 7C64: 285e
    LD IY,SPRITE_JUGADOR_G2_F2        ; 7C66: fd21798b
    JR VOLCAR_SPRITE_A_PANTALLA      ; 7C6A: 1858
DIBUJAR_LETRA_A_GRUPO_1:
    LD IY,SPRITE_JUGADOR_G1_F1        ; 7C6C: fd21b98a
    LD A,($8158)                     ; 7C70: 3a5881
    OR A                             ; 7C73: b7
    JR Z,VOLCAR_SPRITE_A_PANTALLA    ; 7C74: 284e
    LD IY,SPRITE_JUGADOR_G1_F2        ; 7C76: fd21f98a
    JR VOLCAR_SPRITE_A_PANTALLA      ; 7C7A: 1848
DIBUJAR_ENTIDAD_LETRA_O:
    LD A,(IX+4)                      ; 7C7C: dd7e04
    XOR $01                          ; 7C7F: ee01
    LD (IX+4),A                      ; 7C81: dd7704
    PUSH AF                          ; 7C84: f5
    LD A,($8159)                     ; 7C85: 3a5981
    CP $02                           ; 7C88: fe02
    JR C,DIBUJAR_LETRA_O_GRUPO_1     ; 7C8A: 382d
    JR Z,DIBUJAR_LETRA_O_GRUPO_2     ; 7C8C: 281e
    CP $03                           ; 7C8E: fe03
    JR Z,DIBUJAR_LETRA_O_GRUPO_3     ; 7C90: 280d
    POP AF                           ; 7C92: f1
    LD IY,SPRITE_MOMIA_G4_F1          ; 7C93: fd21398e
    JR Z,VOLCAR_SPRITE_A_PANTALLA    ; 7C97: 282b
    LD IY,SPRITE_MOMIA_G4_F2          ; 7C99: fd21798e
    JR VOLCAR_SPRITE_A_PANTALLA      ; 7C9D: 1825
DIBUJAR_LETRA_O_GRUPO_3:
    POP AF                           ; 7C9F: f1
    LD IY,SPRITE_MOMIA_G3_F1          ; 7CA0: fd21b98d
    JR Z,VOLCAR_SPRITE_A_PANTALLA    ; 7CA4: 281e
    LD IY,SPRITE_MOMIA_G3_F2          ; 7CA6: fd21f98d
    JR VOLCAR_SPRITE_A_PANTALLA      ; 7CAA: 1818
DIBUJAR_LETRA_O_GRUPO_2:
    POP AF                           ; 7CAC: f1
    LD IY,SPRITE_MOMIA_G2_F1          ; 7CAD: fd21398d
    JR Z,VOLCAR_SPRITE_A_PANTALLA    ; 7CB1: 2811
    LD IY,SPRITE_MOMIA_G2_F2          ; 7CB3: fd21798d
    JR VOLCAR_SPRITE_A_PANTALLA      ; 7CB7: 180b
DIBUJAR_LETRA_O_GRUPO_1:
    POP AF                           ; 7CB9: f1
    LD IY,SPRITE_MOMIA_G1_F1          ; 7CBA: fd21b98c
    JR Z,VOLCAR_SPRITE_A_PANTALLA    ; 7CBE: 2804
    LD IY,SPRITE_MOMIA_G1_F2          ; 7CC0: fd21f98c
VOLCAR_SPRITE_A_PANTALLA:
    PUSH DE                          ; 7CC4: d5
    LD B,$10                         ; 7CC5: 0610
    EX DE,HL                         ; 7CC7: eb
    LD (PUNTERO_FILA_PANTALLA_BLIT),HL                    ; 7CC8: 224786
BUCLE_COPIAR_FILAS_SPRITE:
    PUSH BC                          ; 7CCB: c5
    CALL CASILLA_A_DIRECCION_PANTALLA ; 7CCC: cd927e
    LD B,$04                         ; 7CCF: 0604
BUCLE_COPIAR_FILA_SPRITE:
    LD A,(IY+0)                      ; 7CD1: fd7e00
    INC IY                           ; 7CD4: fd23
    LD (HL),A                        ; 7CD6: 77
    INC HL                           ; 7CD7: 23
    DJNZ BUCLE_COPIAR_FILA_SPRITE                       ; 7CD8: 10f7
    LD HL,(PUNTERO_FILA_PANTALLA_BLIT)                    ; 7CDA: 2a4786
    INC H                            ; 7CDD: 24
    LD (PUNTERO_FILA_PANTALLA_BLIT),HL                    ; 7CDE: 224786
    POP BC                           ; 7CE1: c1
    DJNZ BUCLE_COPIAR_FILAS_SPRITE                       ; 7CE2: 10e7
    POP DE                           ; 7CE4: d1
    RET                              ; 7CE5: c9
DIBUJAR_CASILLA_MAPA:
; Despacho confirmado de las ocho losetas de pisadas: los valores de
; casilla 1..8 seleccionan, respectivamente, $89D9, $89E9, $89F9,
; $8A19, $8A79, $8A69, $8AA9 y $8A89. El orden de las dos variantes
; dentro de cada direccion queda demostrado por el valor escrito, pero
; "pie izquierdo/derecho" sigue siendo una interpretacion visual.
    CP $02                           ; 7CE6: fe02
    JR C,DIBUJAR_CASILLA_PISADA_1    ; 7CE8: 3844
    JR Z,DIBUJAR_CASILLA_PISADA_2    ; 7CEA: 283c
    CP $04                           ; 7CEC: fe04
    JR C,DIBUJAR_CASILLA_PISADA_3    ; 7CEE: 3832
    JR Z,DIBUJAR_CASILLA_PISADA_4    ; 7CF0: 282a
    CP $06                           ; 7CF2: fe06
    JR C,DIBUJAR_CASILLA_PISADA_6    ; 7CF4: 3820
    JR Z,DIBUJAR_CASILLA_PISADA_5    ; 7CF6: 2818
    CP $08                           ; 7CF8: fe08
    JR C,DIBUJAR_CASILLA_PISADA_8    ; 7CFA: 380e
    JR Z,DIBUJAR_CASILLA_PISADA_7    ; 7CFC: 2806
    LD IY,$8959                      ; 7CFE: fd215989
    JR CONFIGURAR_VOLCADO_CASILLA_MAPA            ; 7D02: 182e
DIBUJAR_CASILLA_PISADA_7:
    LD IY,LOSETA_MAPA_PISADA_7        ; 7D04: fd21898a
    JR CONFIGURAR_VOLCADO_CASILLA_MAPA            ; 7D08: 1828
DIBUJAR_CASILLA_PISADA_8:
    LD IY,LOSETA_MAPA_PISADA_8        ; 7D0A: fd21a98a
    JR CONFIGURAR_VOLCADO_CASILLA_MAPA            ; 7D0E: 1822
DIBUJAR_CASILLA_PISADA_5:
    LD IY,LOSETA_MAPA_PISADA_5        ; 7D10: fd21698a
    JR CONFIGURAR_VOLCADO_CASILLA_MAPA            ; 7D14: 181c
DIBUJAR_CASILLA_PISADA_6:
    LD IY,LOSETA_MAPA_PISADA_6        ; 7D16: fd21798a
    JR CONFIGURAR_VOLCADO_CASILLA_MAPA            ; 7D1A: 1816
DIBUJAR_CASILLA_PISADA_4:
    LD IY,LOSETA_MAPA_PISADA_4        ; 7D1C: fd21198a
    JR CONFIGURAR_VOLCADO_CASILLA_MAPA            ; 7D20: 1810
DIBUJAR_CASILLA_PISADA_3:
    LD IY,LOSETA_MAPA_PISADA_3        ; 7D22: fd21f989
    JR CONFIGURAR_VOLCADO_CASILLA_MAPA            ; 7D26: 180a
DIBUJAR_CASILLA_PISADA_2:
    LD IY,LOSETA_MAPA_PISADA_2        ; 7D28: fd21e989
    JR CONFIGURAR_VOLCADO_CASILLA_MAPA            ; 7D2C: 1804
DIBUJAR_CASILLA_PISADA_1:
    LD IY,LOSETA_MAPA_PISADA_1        ; 7D2E: fd21d989
CONFIGURAR_VOLCADO_CASILLA_MAPA:
    LD A,$08                         ; 7D32: 3e08
    LD ($7CC6),A                     ; 7D34: 32c67c
    LD A,$02                         ; 7D37: 3e02
    LD ($7CD0),A                     ; 7D39: 32d07c
    JR VOLCAR_SPRITE_A_PANTALLA      ; 7D3C: 1886
CONSULTAR_CASILLA_MAPA:
    PUSH DE                          ; 7D3E: d5
    LD HL,MAPA_CASILLAS               ; 7D3F: 210082
    LD A,E                           ; 7D42: 7b
    SRL A                            ; 7D43: cb3f
    LD B,$00                         ; 7D45: 0600
    LD C,A                           ; 7D47: 4f
    ADD HL,BC                        ; 7D48: 09
    LD E,D                           ; 7D49: 5a
    LD D,$00                         ; 7D4A: 1600
    ADD HL,DE                        ; 7D4C: 19
    ADD HL,DE                        ; 7D4D: 19
    ADD HL,DE                        ; 7D4E: 19
    ADD HL,DE                        ; 7D4F: 19
    ADD HL,DE                        ; 7D50: 19
    POP DE                           ; 7D51: d1
    RET                              ; 7D52: c9
GENERAR_ALEATORIO:
    LD DE,($8151)                    ; 7D53: ed5b5181
    CALL MEZCLAR_ALEATORIO           ; 7D57: cd787d
    PUSH HL                          ; 7D5A: e5
    LD E,$4B                         ; 7D5B: 1e4b
    LD A,($8151)                     ; 7D5D: 3a5181
    CALL MEZCLAR_ALEATORIO           ; 7D60: cd787d
    LD DE,$004B                      ; 7D63: 114b00
    ADD HL,DE                        ; 7D66: 19
    LD DE,$0101                      ; 7D67: 110101
    XOR A                            ; 7D6A: af
BUCLE_REDUCIR_MODULO_ALEATORIO:
    SBC HL,DE                        ; 7D6B: ed52
    JR C,RESTAURAR_RESTO_ALEATORIO   ; 7D6D: 3802
    JR BUCLE_REDUCIR_MODULO_ALEATORIO            ; 7D6F: 18fa
RESTAURAR_RESTO_ALEATORIO:
    ADD HL,DE                        ; 7D71: 19
    DEC HL                           ; 7D72: 2b
    LD ($8151),HL                    ; 7D73: 225181
    POP AF                           ; 7D76: f1
    RET                              ; 7D77: c9
MEZCLAR_ALEATORIO:
    LD H,A                           ; 7D78: 67
    LD L,$00                         ; 7D79: 2e00
    LD D,L                           ; 7D7B: 55
    LD B,$08                         ; 7D7C: 0608
BUCLE_MEZCLAR_BITS_ALEATORIOS:
    ADD HL,HL                        ; 7D7E: 29
    JR NC,CONTINUAR_MEZCLAR_BIT_ALEATORIO            ; 7D7F: 3001
    ADD HL,DE                        ; 7D81: 19
CONTINUAR_MEZCLAR_BIT_ALEATORIO:
    DJNZ BUCLE_MEZCLAR_BITS_ALEATORIOS                       ; 7D82: 10fa
    RET                              ; 7D84: c9
DIBUJAR_ICONO_SARCOFAGO:
    LD (VARIABLE_TEMPORAL_HL_1),HL                    ; 7D85: 224586
    CALL RELLENAR_MARCO_SOLIDO       ; 7D88: cded7d
    LD HL,(VARIABLE_TEMPORAL_HL_1)                    ; 7D8B: 2a4586
    LD BC,$0602                      ; 7D8E: 010206
    ADD HL,BC                        ; 7D91: 09
    LD (VARIABLE_TEMPORAL_HL_1),HL                    ; 7D92: 224586
    LD IY,SPRITE_ICONO_SARCOFAGO               ; 7D95: fd217d87
    CALL COPIAR_BLOQUE_A_LIENZO      ; 7D99: cd737e
    RET                              ; 7D9C: c9
DIBUJAR_ICONO_LLAVE:
    LD (VARIABLE_TEMPORAL_HL_1),HL                    ; 7D9D: 224586
    CALL RELLENAR_MARCO_SOLIDO       ; 7DA0: cded7d
    LD HL,(VARIABLE_TEMPORAL_HL_1)                    ; 7DA3: 2a4586
    LD BC,$0602                      ; 7DA6: 010206
    ADD HL,BC                        ; 7DA9: 09
    LD (VARIABLE_TEMPORAL_HL_1),HL                    ; 7DAA: 224586
    LD IY,SPRITE_ICONO_LLAVE               ; 7DAD: fd21c587
    CALL COPIAR_BLOQUE_A_LIENZO      ; 7DB1: cd737e
    RET                              ; 7DB4: c9
DIBUJAR_ICONO_PERGAMINO:
    LD (VARIABLE_TEMPORAL_HL_1),HL                    ; 7DB5: 224586
    CALL RELLENAR_MARCO_SOLIDO       ; 7DB8: cded7d
    LD HL,(VARIABLE_TEMPORAL_HL_1)                    ; 7DBB: 2a4586
    LD BC,$0602                      ; 7DBE: 010206
    ADD HL,BC                        ; 7DC1: 09
    LD (VARIABLE_TEMPORAL_HL_1),HL                    ; 7DC2: 224586
    LD IY,SPRITE_ICONO_PERGAMINO               ; 7DC5: fd210d88
    CALL COPIAR_BLOQUE_A_LIENZO      ; 7DC9: cd737e
    RET                              ; 7DCC: c9
DIBUJAR_ICONO_TESORO:
    LD (VARIABLE_TEMPORAL_HL_1),HL                    ; 7DCD: 224586
    CALL RELLENAR_MARCO_MEDIO        ; 7DD0: cde57d
    LD HL,(VARIABLE_TEMPORAL_HL_1)                    ; 7DD3: 2a4586
    LD BC,$0602                      ; 7DD6: 010206
    ADD HL,BC                        ; 7DD9: 09
    LD (VARIABLE_TEMPORAL_HL_1),HL                    ; 7DDA: 224586
    LD IY,SPRITE_ICONO_TESORO               ; 7DDD: fd215588
    CALL COPIAR_BLOQUE_A_LIENZO      ; 7DE1: cd737e
    RET                              ; 7DE4: c9
; ---- RELLENAR_MARCO_MEDIO / RELLENAR_MARCO_SOLIDO / RELLENAR_MARCO_VACIO /
; RELLENAR_MARCO_DIAGONAL_1..6 / RELLENAR_MARCO_DIAGONAL_BUCLE /
; PREPARAR_RELLENO_MASCARA_UNICA / RELLENAR_FILAS_MASCARA ----
; Cierra el hueco $7DE5-$7E72 (Sesion 7): son los destinos de las
; CALL $7DED/CALL $7DE5 de DIBUJAR_ICONO_SARCOFAGO..TESORO (arriba),
; ahora ya nombrados. CORRIGE la hipotesis previa de FINDINGS.md/
; flujo_programa.html ("variantes de mascara AND/OR"): no hay
; ninguna instruccion AND ni OR en todo el bloque -- son escrituras
; directas (LD (HL),A) de un byte de mascara repetido 10 veces por
; fila x 24 filas (RELLENAR_FILAS_MASCARA, reusa
; CASILLA_A_DIRECCION_PANTALLA para cada fila), mas 6 variantes que
; ALTERNAN dos mascaras fila a fila mediante codigo AUTOMODIFICABLE
; (RELLENAR_MARCO_DIAGONAL_BUCLE parchea en caliente el operando
; inmediato del "XOR $0F" en $7E47 antes de ejecutarlo, y llama a
; RELLENAR_FILAS_MASCARA con B=1 para dibujar una sola fila cada vez).
; Confianza ALTA en la estructura (compilada, 0 diferencias byte a
; byte). Sesion 17 PRECISA su papel: no rellenan "el marco decorativo
; del nivel" (hipotesis de la Sesion 3, ya corregida en otros puntos),
; sino el fondo/backdrop de 24x10 bytes sobre el que
; DIBUJAR_ICONO_SARCOFAGO..TESORO dibuja despues (via
; COPIAR_BLOQUE_A_LIENZO) el icono de 12x6 del contenido de la casilla
; (sarcofago/llave/pergamino/tesoro) que el jugador acaba de
; descubrir -- solido/vacio/a medias (las 3 primeras) o con una veta a
; rayas alternas (las 6 diagonales, probablemente el fondo usado segun
; el nivel actual, ver SELECCIONAR_DIAGONAL_MARCO_NIVEL). Identidad del
; icono en si confirmada visualmente por el usuario con el explorador
; de recursos/sprites.html; el patron de fondo (solido/vacio/diagonal)
; sigue sin confirmar en emulador. RELLENAR_MARCO_MEDIO y
; RELLENAR_MARCO_SOLIDO son las unicas llamadas desde codigo ya
; conocido (DIBUJAR_ICONO_TESORO y DIBUJAR_ICONO_SARCOFAGO/LLAVE/
; PERGAMINO); RELLENAR_MARCO_VACIO y las 6 variantes
; RELLENAR_MARCO_DIAGONAL_1..6 no tienen todavia un llamador conocido
; dentro de lo ya reconstruido -- pendiente localizarlo en uno de los
; huecos INCBIN restantes. Ver FINDINGS.md Sesion 7.
RELLENAR_MARCO_MEDIO:
    LD A,$0F                         ; 7DE5: 3e0f
    LD (MASCARA_RELLENO_ACTUAL),A                     ; 7DE7: 324a86
    JP PREPARAR_RELLENO_MASCARA_UNICA ; 7DEA: c34f7e
RELLENAR_MARCO_SOLIDO:
    LD A,$FF                         ; 7DED: 3eff
    LD (MASCARA_RELLENO_ACTUAL),A                     ; 7DEF: 324a86
    JP PREPARAR_RELLENO_MASCARA_UNICA ; 7DF2: c34f7e
RELLENAR_MARCO_VACIO:
    XOR A                            ; 7DF5: af
    LD (MASCARA_RELLENO_ACTUAL),A                     ; 7DF6: 324a86
    JP PREPARAR_RELLENO_MASCARA_UNICA ; 7DF9: c34f7e
RELLENAR_MARCO_DIAGONAL_1:
    LD A,$FF                         ; 7DFC: 3eff
    LD ($7E47),A                     ; 7DFE: 32477e
    LD A,$A5                         ; 7E01: 3ea5
    JR RELLENAR_MARCO_DIAGONAL_BUCLE ; 7E03: 182b
RELLENAR_MARCO_DIAGONAL_2:
    LD A,$F0                         ; 7E05: 3ef0
    LD ($7E47),A                     ; 7E07: 32477e
    LD A,$AF                         ; 7E0A: 3eaf
    JR RELLENAR_MARCO_DIAGONAL_BUCLE ; 7E0C: 1822
RELLENAR_MARCO_DIAGONAL_3:
    LD A,$0F                         ; 7E0E: 3e0f
    LD ($7E47),A                     ; 7E10: 32477e
    LD A,$FA                         ; 7E13: 3efa
    JR RELLENAR_MARCO_DIAGONAL_BUCLE ; 7E15: 1819
RELLENAR_MARCO_DIAGONAL_4:
    LD A,$F0                         ; 7E17: 3ef0
    LD ($7E47),A                     ; 7E19: 32477e
    LD A,$50                         ; 7E1C: 3e50
    JR RELLENAR_MARCO_DIAGONAL_BUCLE ; 7E1E: 1810
RELLENAR_MARCO_DIAGONAL_5:
    LD A,$FF                         ; 7E20: 3eff
    LD ($7E47),A                     ; 7E22: 32477e
    LD A,$55                         ; 7E25: 3e55
    JR RELLENAR_MARCO_DIAGONAL_BUCLE ; 7E27: 1807
RELLENAR_MARCO_DIAGONAL_6:
    LD A,$0F                         ; 7E29: 3e0f
    LD ($7E47),A                     ; 7E2B: 32477e
    LD A,$05                         ; 7E2E: 3e05
RELLENAR_MARCO_DIAGONAL_BUCLE:
    LD (MASCARA_RELLENO_ACTUAL),A                     ; 7E30: 324a86
    LD A,$0A                         ; 7E33: 3e0a
    LD (VARIABLE_TEMPORAL_A_1),A                     ; 7E35: 324986
    LD (PUNTERO_FILA_PANTALLA_BLIT),HL                    ; 7E38: 224786
    LD B,$18                         ; 7E3B: 0618
BUCLE_ALTERNAR_MASCARA_DIAGONAL:
    PUSH BC                          ; 7E3D: c5
    LD B,$01                         ; 7E3E: 0601
    CALL RELLENAR_FILAS_MASCARA      ; 7E40: cd597e
    LD A,(MASCARA_RELLENO_ACTUAL)                     ; 7E43: 3a4a86
    XOR $0F                          ; 7E46: ee0f
    LD (MASCARA_RELLENO_ACTUAL),A                     ; 7E48: 324a86
    POP BC                           ; 7E4B: c1
    DJNZ BUCLE_ALTERNAR_MASCARA_DIAGONAL                       ; 7E4C: 10ef
    RET                              ; 7E4E: c9
PREPARAR_RELLENO_MASCARA_UNICA:
    LD A,$0A                         ; 7E4F: 3e0a
    LD (VARIABLE_TEMPORAL_A_1),A                     ; 7E51: 324986
    LD B,$18                         ; 7E54: 0618
    LD (PUNTERO_FILA_PANTALLA_BLIT),HL                    ; 7E56: 224786
RELLENAR_FILAS_MASCARA:
    PUSH BC                          ; 7E59: c5
    CALL CASILLA_A_DIRECCION_PANTALLA ; 7E5A: cd927e
    LD A,(VARIABLE_TEMPORAL_A_1)                     ; 7E5D: 3a4986
    LD B,A                           ; 7E60: 47
    LD A,(MASCARA_RELLENO_ACTUAL)                     ; 7E61: 3a4a86
BUCLE_ESCRIBIR_MASCARA_FILA:
    LD (HL),A                        ; 7E64: 77
    INC HL                           ; 7E65: 23
    DJNZ BUCLE_ESCRIBIR_MASCARA_FILA                       ; 7E66: 10fc
    LD HL,(PUNTERO_FILA_PANTALLA_BLIT)                    ; 7E68: 2a4786
    INC H                            ; 7E6B: 24
    LD (PUNTERO_FILA_PANTALLA_BLIT),HL                    ; 7E6C: 224786
    POP BC                           ; 7E6F: c1
    DJNZ RELLENAR_FILAS_MASCARA      ; 7E70: 10e7
    RET                              ; 7E72: c9

; ---- COPIAR_BLOQUE_A_LIENZO / CASILLA_A_DIRECCION_PANTALLA / BORRAR_BLOQUE_ESTADO / BORRAR_RECTANGULO_VENTANA / IMPRIMIR_BYTES_CON_LONGITUD ----
; hipotesis: copia un bloque de 6x12 bytes a un lienzo de trabajo (media);
; indexa la tabla de 200 direcciones de pantalla por fila (alta); borra
; 1182 bytes de estado en $8172 (alta); borra un rectangulo de la
; ventana de texto via el firmware (alta, confirma uso de TXT WIN
; ENABLE/TXT CLEAR WINDOW); imprime una secuencia de bytes con longitud
; (alta -- Sesion 19 corrige la hipotesis previa de "repite un
; caracter"). Ver FINDINGS.md Sesiones 3-5 y 19.
COPIAR_BLOQUE_A_LIENZO:
    LD B,$0C                         ; 7E73: 060c
    LD (PUNTERO_FILA_PANTALLA_BLIT),HL                    ; 7E75: 224786
BUCLE_COPIAR_FILAS_BLOQUE:
    PUSH BC                          ; 7E78: c5
    CALL CASILLA_A_DIRECCION_PANTALLA ; 7E79: cd927e
    LD B,$06                         ; 7E7C: 0606
BUCLE_COPIAR_BYTES_FILA:
    LD A,(IY+0)                      ; 7E7E: fd7e00
    INC IY                           ; 7E81: fd23
    LD (HL),A                        ; 7E83: 77
    INC HL                           ; 7E84: 23
    DJNZ BUCLE_COPIAR_BYTES_FILA                       ; 7E85: 10f7
    LD HL,(PUNTERO_FILA_PANTALLA_BLIT)                    ; 7E87: 2a4786
    INC H                            ; 7E8A: 24
    LD (PUNTERO_FILA_PANTALLA_BLIT),HL                    ; 7E8B: 224786
    POP BC                           ; 7E8E: c1
    DJNZ BUCLE_COPIAR_FILAS_BLOQUE                       ; 7E8F: 10e7
    RET                              ; 7E91: c9
CASILLA_A_DIRECCION_PANTALLA:
    PUSH IX                          ; 7E92: dde5
    LD IX,TABLA_DIRECCIONES_PANTALLA  ; 7E94: dd21ca8e
    LD B,$00                         ; 7E98: 0600
    LD C,L                           ; 7E9A: 4d
    LD D,B                           ; 7E9B: 50
    LD E,H                           ; 7E9C: 5c
    ADD IX,DE                        ; 7E9D: dd19
    ADD IX,DE                        ; 7E9F: dd19
    LD L,(IX+0)                      ; 7EA1: dd6e00
    LD H,(IX+1)                      ; 7EA4: dd6601
    ADD HL,BC                        ; 7EA7: 09
    POP IX                           ; 7EA8: dde1
    RET                              ; 7EAA: c9
BORRAR_BLOQUE_ESTADO:
    XOR A                            ; 7EAB: af
    LD HL,ARRAY_ENTIDADES+5           ; 7EAC: 217281
    LD (HL),A                        ; 7EAF: 77
    PUSH HL                          ; 7EB0: e5
    POP DE                           ; 7EB1: d1
    INC DE                           ; 7EB2: 13
    LD BC,$049D                      ; 7EB3: 019d04
    LDIR                             ; 7EB6: edb0
    RET                              ; 7EB8: c9
BORRAR_RECTANGULO_VENTANA:
    PUSH HL                          ; 7EB9: e5
    LD IY,VENTANA_TEXTO_HUD           ; 7EBA: fd21d881
    LD B,$00                         ; 7EBE: 0600
    LD C,H                           ; 7EC0: 4c
    ADD IY,BC                        ; 7EC1: fd09
    LD B,L                           ; 7EC3: 45
    INC B                            ; 7EC4: 04
    PUSH DE                          ; 7EC5: d5
    LD DE,$0028                      ; 7EC6: 112800
BUCLE_LOCALIZAR_FILA_VENTANA:
    ADD IY,DE                        ; 7EC9: fd19
    DJNZ BUCLE_LOCALIZAR_FILA_VENTANA                       ; 7ECB: 10fc
    POP DE                           ; 7ECD: d1
    LD A,E                           ; 7ECE: 7b
    INC A                            ; 7ECF: 3c
    SUB L                            ; 7ED0: 95
    LD B,A                           ; 7ED1: 47
BUCLE_BORRAR_FILAS_VENTANA:
    PUSH BC                          ; 7ED2: c5
    LD A,D                           ; 7ED3: 7a
    INC A                            ; 7ED4: 3c
    SUB H                            ; 7ED5: 94
    LD B,A                           ; 7ED6: 47
    LD A,$20                         ; 7ED7: 3e20
    PUSH IY                          ; 7ED9: fde5
BUCLE_BORRAR_FILA_VENTANA:
    LD (IY+0),A                      ; 7EDB: fd7700
    INC IY                           ; 7EDE: fd23
    DJNZ BUCLE_BORRAR_FILA_VENTANA                       ; 7EE0: 10f9
    LD BC,$0028                      ; 7EE2: 012800
    POP IY                           ; 7EE5: fde1
    ADD IY,BC                        ; 7EE7: fd09
    POP BC                           ; 7EE9: c1
    DJNZ BUCLE_BORRAR_FILAS_VENTANA                       ; 7EEA: 10e6
    POP HL                           ; 7EEC: e1
    CALL FIRM_TXT_WIN_ENABLE         ; 7EED: cd66bb
    CALL FIRM_TXT_CLEAR_WINDOW       ; 7EF0: cd6cbb
    RET                              ; 7EF3: c9
; IMPRIMIR_BYTES_CON_LONGITUD ($7EF4): antes nombrada REPETIR_CARACTER
; desde la Sesion 3, con la hipotesis "formato cuenta+caracter, repite
; el mismo caracter N veces". Sesion 19 CORRIGE esa hipotesis leyendo
; el propio bucle byte a byte: el DJNZ salta a "INC HL" (BUCLE_
; IMPRIMIR_BYTE), no a "LD A,(HL)" -- HL avanza en TODAS las
; iteraciones, incluida la primera. Con B=(HL) iteraciones, imprime los
; B bytes siguientes (HL+1..HL+B) UNO A UNO via FIRM_TXT_OUTPUT, no el
; mismo byte repetido: es un formato "longitud + secuencia de bytes".
; Como FIRM_TXT_OUTPUT interpreta los valores bajos (<$20) como
; codigos de control VDU (posicion de cursor, tinta...) en vez de
; caracteres imprimibles, esto explica de forma natural por que los
; argumentos observados mezclan codigos de control y texto ASCII en la
; misma secuencia (p.ej. TEXTO_MENU_OPCIONES: $4E=78 seguido de bytes
; de control + "OH MUMMY - OPTIONS" + mas control). Confianza alta en
; la estructura (verificada byte a byte); el significado exacto de
; cada codigo de control individual sigue sin decodificar. Todos los
; puntos de llamada de esta sesion en adelante se documentan con esta
; semantica corregida -- ver FINDINGS.md Sesion 19.
IMPRIMIR_BYTES_CON_LONGITUD:
    LD B,(HL)                        ; 7EF4: 46
BUCLE_IMPRIMIR_BYTE:
    INC HL                           ; 7EF5: 23
    LD A,(HL)                        ; 7EF6: 7e
    CALL FIRM_TXT_OUTPUT             ; 7EF7: cd5abb
    DJNZ BUCLE_IMPRIMIR_BYTE                       ; 7EFA: 10f9
    RET                              ; 7EFC: c9
; ---- TEXTO_MENU_OPCIONES / FLAG_MUSICA_FONDO / FLAG_EFECTOS_SONIDO /
; ENVOLVENTE_AMPLITUD_1..3 / ENVOLVENTE_TONO_1..3 / TEXTO_HISTORIA_ATRACCION /
; TABLA_DESCONOCIDA_GAME_OVER / VARIABLES_INICIO_ENTIDADES / ARRAY_ENTIDADES /
; ESTADO_PARTIDA / TABLA_POSICIONES_INICIALES_ENTIDADES / VARIABLE_TEMPORAL_HL_1..2 /
; TABLA_PARAMETROS_TRANSICION_PUNTUACIONES / TEXTO_TABLA_PUNTUACIONES /
; TEXTO_MENU_PRINCIPAL / TABLA_POSICIONES_DECIMALES / TEXTO_COPYRIGHT_Y_HUD /
; SPRITE_ICONO_SARCOFAGO..TESORO / DATOS_MARCO_Y_TEXTO_CONTINUAR / TABLAS_SPRITE_CASILLA /
; TABLA_DIRECCIONES_PANTALLA / PUNTERO_GUION_SONIDO / GUION_SONIDO_CIRCULAR ----
; Cierra el ultimo hueco INCBIN (Sesion 8): $7EFD-$9385, el resto del
; motor tras el bloque de codigo de la Sesion 7. Es DATO, no codigo --
; no se encontro ningun CALL/JP de codigo ya reconstruido que aterrice
; aqui dentro (regla base: no convertir datos en codigo sin evidencia).
; Contiene texto literal legible (confirmado por lectura directa, sin
; hipotesis: menu de opciones, texto de "STOP PRESS" tipo periodico de
; la excavacion de la piramide, tabla HI-SCORE con 5 rangos, menu
; principal Instructions/Options/Play, y el copyright real del juego),
; mas varias tablas cuyos limites SI estan confirmados por las
; instrucciones que ya las referencian por direccion en el codigo ya
; reconstruido (envolventes de sonido, tabla de posiciones decimales,
; las 4 tablas de icono de contenido de casilla (sarcofago/llave/
; pergamino/tesoro, Sesion 17 -- antes mal identificadas como "marco
; decorativo") -- offsets exactos de 72 bytes confirmados por las 4
; LD IY,$87xx de DIBUJAR_ICONO_SARCOFAGO..TESORO --,
; el bloque de estado que borra BORRAR_BLOQUE_ESTADO, el array de
; entidades de $816D, y el guion de sonido circular de $905C).
; Algunas tablas menores (offsets tipo "diamante" en $8611, parametros
; antes de HI-SCORE-TABLE, cola de bytes tras "GAME OVER", las
; ~29 tablas de sprite/casilla de $8919) quedan como bytes en bruto
; con hipotesis de confianza baja/media -- limites confirmados por
; los huecos de texto/tablas vecinas, contenido interno sin descifrar
; del todo. Ver FINDINGS.md Sesion 8.
; Cada bloque DB longitud+datos de aqui en adelante corresponde EXACTO a
; un punto de entrada real confirmado de IMPRIMIR_BYTES_CON_LONGITUD
; (CALL con ese HL, ver PANTALLA_OPCIONES mas abajo). Los codigos de
; control (<$20) usan las constantes CTRL_TXT_* (Appendix VII del
; firmware); el resto son bytes de datos (parametros del codigo previo,
; texto ASCII entre comillas, o graficos de bloque $80-$FF en hex).
; Confianza alta: longitudes y limites verificados byte a byte contra
; los 6 CALL reales (aritmetica exacta, ver FINDINGS.md Sesion 21).
TEXTO_MENU_OPCIONES:
    DB 78                             ; 7EFD longitud
    DB CTRL_TXT_FIJAR_PAPEL,$01       ; 7EFE
    DB CTRL_TXT_FIJAR_TINTA,$02       ; 7F00
    DB CTRL_TXT_BORRAR_VENTANA        ; 7F02
    DB CTRL_TXT_POSICIONAR_CURSOR,$0C,$03 ; 7F03
    DB "OH MUMMY - OPTIONS"           ; 7F06
    DB CTRL_TXT_POSICIONAR_CURSOR,$09,$07 ; 7F18
    DB CTRL_TXT_FIJAR_TINTA,$00       ; 7F1B
    DB "SPEED OF GAME (1-5) ?"        ; 7F1D
    DB CTRL_TXT_POSICIONAR_CURSOR,$0C,$08 ; 7F32
    DB CTRL_TXT_FIJAR_TINTA,$03       ; 7F35
    DB "(1 IS FASTEST)"               ; 7F37
    DB CTRL_TXT_POSICIONAR_CURSOR,$1F,$07 ; 7F45
    DB $8F                            ; 7F48 -- grafico de bloque, sin decodificar
    DB CTRL_TXT_CURSOR_IZQUIERDA      ; 7F49
    DB CTRL_TXT_FIJAR_TINTA,$00       ; 7F4A
; -- entrada real: $6458 LD HL,$7F4C --
    DB 53                             ; 7F4C longitud
    DB CTRL_TXT_POSICIONAR_CURSOR,$08,$0B ; 7F4D
    DB "DIFFICULTY LEVEL (1-5) ?"     ; 7F50
    DB CTRL_TXT_POSICIONAR_CURSOR,$0C,$0C ; 7F68
    DB CTRL_TXT_FIJAR_TINTA,$03       ; 7F6B
    DB "(1 IS HARDEST)"               ; 7F6D
    DB CTRL_TXT_POSICIONAR_CURSOR,$21,$0B ; 7F7B
    DB $8F                            ; 7F7E -- grafico de bloque, sin decodificar
    DB CTRL_TXT_CURSOR_IZQUIERDA      ; 7F7F
    DB CTRL_TXT_FIJAR_TINTA,$00       ; 7F80
; -- entrada real: $647E LD HL,$7F82 --
    DB 30                             ; 7F82 longitud
    DB CTRL_TXT_POSICIONAR_CURSOR,$08,$0F ; 7F83
    DB "BACKGROUND MUSIC (Y-N) ? "    ; 7F86
    DB $8F                            ; 7F9F -- grafico de bloque, sin decodificar
    DB CTRL_TXT_CURSOR_IZQUIERDA      ; 7FA0
; -- entrada real: $64DF LD HL,$7FA1 --
    DB 27                             ; 7FA1 longitud
    DB CTRL_TXT_POSICIONAR_CURSOR,$09,$13 ; 7FA2
    DB "SOUND EFFECTS (Y-N) ? "       ; 7FA5
    DB $8F                            ; 7FBB -- grafico de bloque, sin decodificar
    DB CTRL_TXT_CURSOR_IZQUIERDA      ; 7FBC
; -- entrada real: $64C0/$6508 LD HL,$7FBD (respuesta "YES") --
    DB 3                              ; 7FBD longitud
    DB "YES"                          ; 7FBE
; -- entrada real: $649A/$64FB LD HL,$7FC1 (respuesta "NO") --
    DB 2                              ; 7FC1 longitud
    DB "NO"                           ; 7FC2
FLAG_MUSICA_FONDO:
    DB "Y"                            ; 7FC4 confirmado: ACTUALIZAR_SECUENCIA_SONIDO hace LD A,($7FC4):CP $59
FLAG_EFECTOS_SONIDO:
    DB "Y"                            ; 7FC5 hipotesis (media): simetria con FLAG_MUSICA_FONDO, sin CALL que la lea todavia localizado
RELLENO_FLAGS_OPCIONES:
    DB $00,$00,$00,$00                               ; 7FC6
; Confirmado: $6005 LD HL,$7FCA + LD A,$01 + CALL FIRM_SOUND_AMPL_ENV
ENVOLVENTE_AMPLITUD_1:
    DB $03,$00,$05,$01,$0A,$01,$02,$00,$00,$0A       ; 7FCA
; Confirmado: $6015 LD HL,$7FD4 + LD A,$02 + CALL FIRM_SOUND_AMPL_ENV
ENVOLVENTE_AMPLITUD_2:
    DB $03,$00,$0A,$01,$05,$01,$01,$05,$FD,$01       ; 7FD4
; Confirmado: $6025 LD HL,$7FDE + LD A,$03 + CALL FIRM_SOUND_AMPL_ENV
ENVOLVENTE_AMPLITUD_3:
    DB $02,$00,$0A,$01,$05,$01,$02                   ; 7FDE
; Confirmado: $600D LD HL,$7FE5 + LD A,$01 + CALL FIRM_SOUND_TONE_ENV
ENVOLVENTE_TONO_1:
    DB $05,$F1,$7B,$1E,$F1,$92,$1E,$F1,$AA,$1E,$F1,$C3,$1E,$F1,$DE,$1E ; 7FE5
; Confirmado: $601D LD HL,$7FF5 + LD A,$02 + CALL FIRM_SOUND_TONE_ENV
ENVOLVENTE_TONO_2:
    DB $01,$0A,$FB,$01                               ; 7FF5
; Confirmado: $602D LD HL,$7FF9 + LD A,$03 + CALL FIRM_SOUND_TONE_ENV
ENVOLVENTE_TONO_3:
    DB $02,$F0,$8C,$01,$0A,$FB,$01,$04,$01,$01,$00,$00,$00,$00,$FA,$FF ; 7FF9
    DB $04,$02,$02,$64,$00,$00,$00,$00,$00,$04,$03,$03,$00,$00,$00,$00 ; 8009
    DB $FC,$FF                                       ; 8019
; Texto literal confirmado (attract mode / pantalla "periodico"):
; "STOP PRESS!! British Museum today announced successful excavation
; of ancient Egyptian pyramid. Leader of team given bonus for his
; efforts of 200 points. extra man for next dig. Press "C" or Fire
; Button to Continue" ... "GAME OVER".
; Igual que TEXTO_MENU_OPCIONES: cada bloque longitud+datos corresponde
; EXACTO a un CALL real de PANTALLA_STOP_PRESS (10 puntos de entrada
; distintos, no una unica tirada continua -- ver FINDINGS.md Sesion 21).
; CORRECCION Sesion 21 al limite de ENVOLVENTE_TONO_3: la etiqueta
; estaba 2 bytes tarde -- el CALL real ($673C, LD HL,$801B) demuestra
; que el bloque empieza en $801B, no en $801D como se documentaba
; (los 2 bytes "$24,$0E" pertenecian aqui, no al final de la envolvente
; de sonido). Contenido de bytes sin cambios, solo el limite.
TEXTO_HISTORIA_ATRACCION:
    DB 36                             ; 801B longitud
    DB CTRL_TXT_FIJAR_PAPEL,$01       ; 801C
    DB CTRL_TXT_FIJAR_TINTA,$02       ; 801E
    DB CTRL_TXT_BORRAR_VENTANA        ; 8020
    DB CTRL_TXT_POSICIONAR_CURSOR,$07,$05 ; 8021
    DB "!!  S T O P    P R E S S  !!"  ; 8024
; -- entrada real: $673F LD HL,$8040 --
    DB 35                             ; 8040 longitud
    DB CTRL_TXT_FIJAR_TINTA,$00       ; 8041
    DB CTRL_TXT_POSICIONAR_CURSOR,$07,$0A ; 8043
    DB "British Museum today announced" ; 8046
; -- entrada real: $6745 LD HL,$8064 --
    DB 35                             ; 8064 longitud
    DB CTRL_TXT_POSICIONAR_CURSOR,$05,$0B ; 8065
    DB "successful excavation of ancient" ; 8068
; -- entrada real: $674B LD HL,$8088 --
    DB 20                             ; 8088 longitud
    DB CTRL_TXT_POSICIONAR_CURSOR,$05,$0C ; 8089
    DB "Egyptian pyramid."              ; 808C
; -- entrada real: $675A LD HL,$809D --
    DB 26                             ; 809D longitud
    DB CTRL_TXT_FIJAR_TINTA,$03       ; 809E
    DB CTRL_TXT_POSICIONAR_CURSOR,$07,$11 ; 80A0
    DB "Leader of team given "          ; 80A3
; -- entrada real: $6772 LD HL,$80B8 --
    DB 9                              ; 80B8 longitud
    DB "bonus for"                      ; 80B9
; -- entrada real: $6778 LD HL,$80C2 --
    DB 29                             ; 80C2 longitud
    DB CTRL_TXT_POSICIONAR_CURSOR,$05,$12 ; 80C3
    DB "his efforts of 200 points."     ; 80C6
; -- entrada real: $678C LD HL,$80E0 --
    DB 9                              ; 80E0 longitud
    DB "extra man"                      ; 80E1
; -- entrada real: $6792 LD HL,$80EA --
    DB 16                             ; 80EA longitud
    DB CTRL_TXT_POSICIONAR_CURSOR,$05,$12 ; 80EB
    DB "for next dig."                  ; 80EE
; -- entrada real: $6511/$679B/$67B6-2 LD HL,$80FB --
    DB 41                             ; 80FB longitud
    DB CTRL_TXT_FIJAR_TINTA,$02       ; 80FC
    DB CTRL_TXT_POSICIONAR_CURSOR,$03,$17 ; 80FE
    DB 'Press "C" or Fire Button to Continue' ; 8101
; -- entrada real: $67B6 LD HL,$8125 (PANTALLA_GAME_OVER) -- solo el
; preambulo de codigos de control pasa por IMPRIMIR_BYTES_CON_LONGITUD;
; "GAME OVER" en si (812D) es texto ASCII plano ya legible, impreso por
; otra via (ver BUCLE_IMPRIMIR_GAME_OVER) -- se deja como estaba.
    DB 7                              ; 8125 longitud
    DB CTRL_TXT_FIJAR_PAPEL,$01       ; 8126
    DB CTRL_TXT_FIJAR_TINTA,$02       ; 8128
    DB CTRL_TXT_POSICIONAR_CURSOR,$0C,$0D ; 812A
    DB "GAME OVER"                      ; 812D
; VARIABLE_CASILLA_APARICION_MOMIA ($8136, 4 bytes): posicion (fila,
; columna del "marco") donde ACTUALIZAR_MARCO_TRAS_MOVIMIENTO deja
; anotada la casilla de la Momia Guardiana recien descubierta --
; ANIMAR_APARICION_MOMIA_GUARDIANA la lee cada turno para dibujar el
; sprite progresivamente en esa casilla. Confianza alta (Sesion 14,
; ver mas abajo $7513-$7862).
VARIABLE_CASILLA_APARICION_MOMIA:
    DB $00,$00,$00,$00                 ; 8136
; CORRECCION Sesion 14 a la hipotesis anterior ("tabla desconocida
; tras GAME OVER, posibles umbrales de puntuacion"): localizados sus
; 3 llamadores reales dentro del hueco $7637-$77D0 (ver
; ACTUALIZAR_MARCO_TRAS_MOVIMIENTO y PROCESAR_MOVIMIENTO_JUGADOR mas
; abajo). Los bytes NO son umbrales de puntuacion: son 2 tablas de
; validacion de rejilla (CPIR contra la fila/columna del movimiento
; del jugador) + 8 codigos de tecla de firmware. Confianza alta en la
; estructura (verificada por los CPIR que las consultan); media-alta
; en el papel exacto de la tabla de teclas (dos codigos por direccion,
; hipotesis: uno de teclado y uno de joystick, coherente con el texto
; "you can control your team using either a Joystick, or the
; Keyboard" de TEXTO_INSTR_20).
TABLA_FILAS_VALIDAS_CASILLAS:
    DB $18,$40,$68,$90,$B8             ; 813A -- 5 valores validos de fila (paso $28), CPIR en ACTUALIZAR_MARCO_TRAS_MOVIMIENTO
TABLA_COLUMNAS_VALIDAS_CASILLAS:
    DB $04,$12,$20,$2E,$3C,$4A         ; 813F -- 6 valores validos de columna (paso $0E) -- (5-1)x(6-1) = 20 casillas, coincide con "twenty boxes" de TEXTO_INSTR_08
TABLA_TECLAS_DIRECCION:
    DB $45,$48,$16,$4B,$47,$49,$1E,$4A ; 8145 -- 8 codigos de tecla de firmware (leidos por pares en PROCESAR_MOVIMIENTO_JUGADOR, direcciones $814C..$8145 decreciendo)
; Continuacion: $814D/$814F (4 bytes) son el buffer de prioridad de
; direccion que rellena y relee PROCESAR_MOVIMIENTO_JUGADOR; $8151
; es la semilla de GENERAR_ALEATORIO (ya usada mas arriba via "LD
; DE,($8151)"). Resto sin desglosar variable a variable.
    DB $00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00     ; 814D
    DB $00,$00,$00,$00,$00,$00,$00,$1F,$00,$00,$00,$00,$00,$00 ; 815A
; Confirmado por el arranque ($6054-$605D): LD A,$06:LD ($8169),A
; (CONTADOR_ENTIDADES=6, confianza media-alta -- encaja con "6
; enemigos/coleccionables" de ARRAY_ENTIDADES) + XOR A:LD ($816C),A +
; LD ($8168),A (dos flags puestos a 0, confianza baja en su papel
; exacto). Los bytes de fichero no tienen por que coincidir con el
; valor real de arranque (se sobrescriben antes de leerse).
VARIABLES_INICIO_ENTIDADES:
    DB $00,$04,$00,$00,$00                           ; 8168
; Confirmado por 3 referencias directas ya reconstruidas: LD IX,$816D
; en INICIALIZAR_UNA_ENTIDAD/COLOCAR_ENTIDAD, LD IY,$816D en
; HAY_COLISION. Hipotesis (media): 6 registros de 5 bytes -- entidades
; (enemigos/coleccionables). Todo el array esta a 0 en el fichero
; compilado (se rellena en tiempo de ejecucion via INICIALIZAR_ENTIDADES).
ARRAY_ENTIDADES:
    DEFS 30                              ; 816D 30 bytes, todo cero
; Confirmado: es la continuacion exacta de lo que borra
; BORRAR_BLOQUE_ESTADO (XOR A:LD ($8172),A + LDIR con BC=$049D,
; 1182 bytes desde $8172 -- de los cuales los primeros 5 son los
; ultimos bytes de ARRAY_ENTIDADES, ya declarados arriba). Resto de
; "estado de partida" sin desglosar en variables individuales todavia.
ESTADO_PARTIDA:
    DEFS 77                              ; 818B 77 bytes, todo cero
; Confirmado por BORRAR_RECTANGULO_VENTANA: LD IY,$81D8 ($7EBA).
; Hipotesis previa (Sesion 3-5, media): tabla/buffer de texto o
; atributos, paso de 40 bytes/fila. Solo caben aqui 40 bytes (una
; fila) antes de MAPA_CASILLAS -- posible solapamiento de uso: esta
; zona parece reutilizarse para el buffer de ventanas de texto (menus)
; y para el mapa del laberinto (fuera de menus), sin confirmar.
VENTANA_TEXTO_HUD:
    DEFS 40                              ; 81D8 40 bytes, todo cero
; Confirmado por HAY_COLISION (LD IY,$8200, $7A68) y
; CONSULTAR_CASILLA_MAPA (LD HL,$8200, $7D3F). Hipotesis previa
; (Sesion 6, media): estructura de paso 5 bytes, entradas de 42 bytes
; totales (offset 40/41 = estado de colision/accesibilidad). 1040
; bytes disponibles / 42 no es una division exacta -- limite real de
; la estructura sin confirmar del todo.
MAPA_CASILLAS:
    DEFS 1040                              ; 8200 1040 bytes, todo cero
RELLENO_TRAS_ESTADO:
    DEFS 1                            ; 8610 1 byte cero, justo tras el rango que limpia BORRAR_BLOQUE_ESTADO
; CORRECCION Sesion 22 a la hipotesis previa ("sin CALL/LD conocido"):
; localizado el llamador real. Son 26 direcciones de pantalla CPC de 16
; bits (modo 1, byte alto $B8/$90/$A8 -- rangos validos de pantalla),
; leidas por INICIALIZAR_UNA_ENTIDAD ($7987, "LD DE,(VARIABLE_TEMPORAL_
; HL_1)") para colocar la posicion inicial de cada entidad (enemigo o
; coleccionable) segun su numero de orden. El puntero base se fija en 2
; puntos distintos del codigo, ambos dentro de esta misma tabla:
; TABLA_POSICIONES_INICIALES_ENTIDADES-2 (word 0..5, usado por la demo
; de fondo del menu en $61E5 y por COLOCAR_JUGADOR_INICIAL en $66CF --
; cada nivel usa tantas de las primeras posiciones como entidades tenga,
; ($8169)) y TABLA_POSICIONES_INICIALES_ENTIDADES+38 (word 20..25,
; usado una sola vez al empezar partida real en $632E). Confianza alta
; en la estructura (verificada por el codigo que la consume); el
; reparto exacto demo/nivel/partida sigue siendo hipotesis media-alta.
; Ver FINDINGS.md Sesion 22.
TABLA_POSICIONES_INICIALES_ENTIDADES:
    DB $04,$B8,$4A,$B8,$0A,$B8,$44,$B8,$10,$B8,$3E,$B8,$16,$B8,$38,$B8 ; 8611
    DB $1C,$B8,$32,$B8,$22,$B8,$2C,$B8,$0A,$90,$44,$90,$10,$90,$3E,$90 ; 8621
    DB $16,$90,$38,$90,$1C,$90,$32,$90,$16,$A8,$38,$A8,$1C,$A8,$32,$A8 ; 8631
    DB $22,$A8,$2C,$A8                               ; 8641
; VARIABLE_TEMPORAL_HL_1/_2 y VARIABLE_TEMPORAL_A_1: bloque de 6 bytes
; de RAM que 3 familias de rutinas SIN RELACION ENTRE SI reutilizan como
; almacenamiento temporal (nunca coinciden en el tiempo de ejecucion --
; reciclaje deliberado de RAM escasa, tal y como hacian los juegos de
; 8 bits de la epoca). Confianza alta en cada uso individual (todos
; confirmados por el codigo que los lee/escribe), media en llamarlo
; "temporal" en vez de darle nombre propio a cada rutina que lo usa --
; se prefiere aqui documentar todos los usos en vez de imponer un
; nombre que solo seria correcto en uno de ellos:
;   - VARIABLE_TEMPORAL_HL_1 ($8645): puntero BASE a esta misma tabla
;     en INICIALIZAR_UNA_ENTIDAD (ver arriba, $61E8/$6331/$66D2/$7987);
;     Y ADEMAS posicion de pantalla temporal en DIBUJAR_ICONO_SARCOFAGO/
;     _LLAVE/_PERGAMINO/_TESORO mientras preparan el icono ($7D85-$7DDA)
;     -- dos usos sin relacion, confirmados por separado.
;   - VARIABLE_TEMPORAL_A_1 ($8649): ancho en bytes de la fila de
;     relleno actual en RELLENAR_FILAS_MASCARA ($7E35/$7E51/$7E5D); Y
;     ADEMAS contador de caracteres ya tecleados del nombre del jugador
;     en BUCLE_LEER_NOMBRE ($6357-$63CB) -- dos usos sin relacion.
; PUNTERO_FILA_PANTALLA_BLIT ($8647) y MASCARA_RELLENO_ACTUAL ($864A)
; se declaran aparte (mas abajo): cada uno tiene un unico papel
; coherente en todos sus usos, sin ambiguedad, y merecen nombre propio.
VARIABLE_TEMPORAL_HL_1:
    DW $0000                                          ; 8645
PUNTERO_FILA_PANTALLA_BLIT:
    DW $0000                                          ; 8647 -- puntero a la fila de pantalla actual del volcado en curso: VOLCAR_SPRITE_A_PANTALLA ($7CC8-$7CDE), RELLENAR_FILAS_MASCARA ($7E38-$7E6C) y COPIAR_BLOQUE_A_LIENZO ($7E75-$7E8B), los 3 con el mismo patron (INC H tras cada fila)
VARIABLE_TEMPORAL_A_1:
    DB $00                                            ; 8649
MASCARA_RELLENO_ACTUAL:
    DB $00                                            ; 864A -- byte que RELLENAR_FILAS_MASCARA escribe en cada fila; fijado por RELLENAR_MARCO_SOLIDO/_VACIO/_DIAGONAL_1..6 ($7DEF-$7E48)
; Hipotesis baja: pequena tabla de parametros justo antes de
; TEXTO_TABLA_PUNTUACIONES, con grupos cortos repetidos -- posible
; animacion/temporizado de la transicion a la pantalla de
; puntuaciones, sin descifrar.
TABLA_PARAMETROS_TRANSICION_PUNTUACIONES:
    DB $03,$04,$01,$02,$03,$04,$01,$02,$19,$1D,$18,$18,$1C,$00,$18,$18 ; 864B
    DB $1C,$01,$00,$00,$1C,$02,$0F,$0F,$1C,$03,$0B,$0B,$0E,$00,$04,$01 ; 865B
    DB $0F,$01                                       ; 866B
; CORRECCION Sesion 21: los siguientes bytes ($866D en adelante) NO son
; parte de esta tabla de hipotesis -- son la cola real de
; IMPRIMIR_BYTES_CON_LONGITUD que llama BUCLE_SELECCIONAR_JUGADORES
; ($622B, LD HL,$866D), confirmado byte a byte (longitud+datos encajan
; exacto hasta $8676, la siguiente entrada real). Ver FINDINGS.md
; Sesion 21.
COLA_TEXTO_PRE_PUNTUACIONES:
    DB 8                              ; 866D longitud
    DB CTRL_TXT_FIJAR_COLOR_BORDE,$0B,$0B ; 866E
    DB CTRL_TXT_FIJAR_PAPEL,$03       ; 8671
    DB CTRL_TXT_BORRAR_VENTANA        ; 8673
    DB CTRL_TXT_FIJAR_PAPEL,$02       ; 8674
; Texto literal confirmado: "HI-SCORE-TABLE" + 5 rangos con su umbral
; de puntuacion en 16 bits little-endian intercalado -- valores leidos
; por IMPRIMIR_NUMERO_HL justo antes de cada CALL IMPRIMIR_BYTES_CON_
; LONGITUD (ver $62D4-$6328 en BUCLE_SELECCIONAR_JUGADORES). Bloque
; confirmado por 9 puntos de entrada reales -- confianza alta.
TEXTO_TABLA_PUNTUACIONES:
; -- entrada real: $62C5 LD HL,$8676 --
    DB 21                             ; 8676 longitud
    DB CTRL_TXT_FIJAR_PAPEL,$00       ; 8677
    DB CTRL_TXT_FIJAR_TINTA,$01       ; 8679
    DB CTRL_TXT_POSICIONAR_CURSOR,$0E,$07 ; 867B
    DB "HI-SCORE-TABLE"                 ; 867E
    DB $C4,$09                        ; 868C -- umbral 16 bits (2500), leido por IMPRIMIR_NUMERO_HL, no por esta secuencia
; -- entrada real: $62DA LD HL,$868E --
    DB 15                             ; 868E longitud
    DB CTRL_TXT_POSICIONAR_CURSOR,$12,$0A ; 868F
    DB "Stupendous !"                   ; 8692
    DB $D0,$07                        ; 869E -- umbral 16 bits (2000)
; -- entrada real: $62EF LD HL,$86A0 --
    DB 15                             ; 86A0 longitud
    DB CTRL_TXT_POSICIONAR_CURSOR,$12,$0C ; 86A1
    DB "Excellent ! "                   ; 86A4
    DB $DC,$05                        ; 86B0 -- umbral 16 bits (1500)
; -- entrada real: $6304 LD HL,$86B2 --
    DB 15                             ; 86B2 longitud
    DB CTRL_TXT_POSICIONAR_CURSOR,$12,$0E ; 86B3
    DB "Very Good ! "                   ; 86B6
    DB $E8,$03                        ; 86C2 -- umbral 16 bits (1000)
; -- entrada real: $6319 LD HL,$86C4 --
    DB 15                             ; 86C4 longitud
    DB CTRL_TXT_POSICIONAR_CURSOR,$12,$10 ; 86C5
    DB "Quite Good  "                   ; 86C8
    DB $F4,$01                        ; 86D4 -- umbral 16 bits (500)
; -- entrada real: $632B LD HL,$86D6 --
    DB 17                             ; 86D6 longitud
    DB CTRL_TXT_POSICIONAR_CURSOR,$12,$12 ; 86D7
    DB "Not Bad     "                   ; 86DA
    DB CTRL_TXT_FIJAR_PAPEL,$03       ; 86E6
; Texto literal confirmado: "I-Instructions  O-Options  P-Play  ?"
; (coincide con MOVER_INDICADOR_MENU/ANIMAR_OPCION_MENU) y "Well
; done !!  Please enter your name" (pantalla de posicion en el
; ranking). CORRIGE Sesion 21 la nota previa ("sin CALL localizado"):
; SI hay 2 CALL reales, ver entradas de abajo.
TEXTO_MENU_PRINCIPAL:
; -- entrada real: $636F/$636C LD HL,$86E8 (REANUDAR_MENU_TRAS_NOMBRE) --
    DB 39                             ; 86E8 longitud
    DB CTRL_TXT_POSICIONAR_CURSOR,$03,$19 ; 86E9
    DB "I-Instructions  O-Options  P-Play  ?" ; 86EC
; -- entrada real: $6349 LD HL,$8710 --
    DB 39                             ; 8710 longitud
    DB CTRL_TXT_POSICIONAR_CURSOR,$03,$19 ; 8711
    DB "Well done !!  Please enter your name" ; 8714
; Confirmado por IMPRIMIR_NUMERO_HL ($786E LD IY,$8736 + 2x INC IY
; -> primera lectura real en $8738): tabla de 4 valores de 16 bits,
; potencias de diez para imprimir HL como texto decimal por resta
; repetida (10000,1000,100,10 -- el digito de las unidades se anade
; aparte al final de la rutina). Corrige la hipotesis previa de
; FINDINGS.md/mapa_memoria.html, que databa el inicio en $8736 (son
; en realidad los 2 ultimos bytes de TEXTO_MENU_PRINCIPAL, "me" de
; "name").
TABLA_POSICIONES_DECIMALES:
    DW 10000,1000,100,10  ; 8738
; Texto literal confirmado: copyright real del juego ("OH MUMMY" (c)
; 1984 GEM SOFTWARE, confirma AVISO-LEGAL.md) y las etiquetas de HUD
; "SCORE"/"MEN". Confirmado por IMPRIMIR_BYTES_CON_LONGITUD: $60A1
; hace LD HL,$8740 e imprime esta tabla como longitud+bytes (Sesion 19
; corrige la semantica de esta rutina, antes REPETIR_CARACTER).
; Dos puntos de entrada reales de IMPRIMIR_BYTES_CON_LONGITUD: el
; copyright ($60A1, cabecera) y el HUD SCORE/MEN ($65D8,
; ACTUALIZAR_HUD_VIDAS) -- confianza alta, longitudes verificadas byte
; a byte contra ambos CALL. El caracter $22 es una comilla doble
; literal (delimita "OH MUMMY" en pantalla); se representa entre
; comillas simples para evitar conflicto con las comillas dobles de
; SjASMPlus.
TEXTO_COPYRIGHT_Y_HUD:
; -- entrada real: $60A1 LD HL,$8740 --
    DB 35                             ; 8740 longitud
    DB CTRL_TXT_POSICIONAR_CURSOR,$06,$02 ; 8741
    DB '"OH MUMMY" '                  ; 8744
    DB $A4                            ; 874F -- grafico de bloque (simbolo copyright), sin decodificar
    DB " 1984 GEM SOFTWARE"           ; 8750
    DB CTRL_TXT_FIJAR_PAPEL,$01       ; 8762
; -- entrada real: $65D8 LD HL,$8764 (ACTUALIZAR_HUD_VIDAS) --
    DB 24                             ; 8764 longitud
    DB CTRL_TXT_FIJAR_COLOR_BORDE,$18,$18 ; 8765
    DB CTRL_TXT_FIJAR_PAPEL,$00       ; 8768
    DB CTRL_TXT_FIJAR_TINTA,$02       ; 876A
    DB CTRL_TXT_BORRAR_VENTANA        ; 876C
    DB CTRL_TXT_POSICIONAR_CURSOR,$03,$01 ; 876D
    DB "SCORE"                          ; 8770
    DB CTRL_TXT_POSICIONAR_CURSOR,$17,$01 ; 8775
    DB "MEN"                            ; 8778
    DB CTRL_TXT_FIJAR_TINTA,$03       ; 877B
; Confirmado por DIBUJAR_ICONO_SARCOFAGO: LD IY,$877D. 72 bytes exactos
; = lo que consume COPIAR_BLOQUE_A_LIENZO (12 filas x 6 bytes).
; Sesion 17: identidad visual "sarcofago" confirmada por el usuario
; probando el explorador parametrizable de recursos/sprites.html
; (Sesion 16), y corroborada de forma independiente por el codigo --
; DIBUJAR_ICONO_SARCOFAGO solo se llama desde MARCO_CONTENIDO_MOMIA_REAL
; ($7764), el contenido de casilla que suma puntos y marca ($8170) al
; encontrar la Momia Real. CORRIGE la hipotesis de la Sesion 3
; ("mascara/bitmap de un tramo del marco decorativo"): no es parte del
; marco del nivel, es el icono que se dibuja al descubrir el contenido
; de una de las 20 casillas del tablero. Confianza alta.
SPRITE_ICONO_SARCOFAGO:
    INCBIN "data/img/sprites/sprite_icono_sarcofago.spr"  ; 877D, 72 bytes
; Confirmado por DIBUJAR_ICONO_LLAVE: LD IY,$87C5. 72 bytes exactos.
; Sesion 17: identidad visual "llave" confirmada por el usuario
; (recursos/sprites.html) y corroborada por el codigo -- solo se llama
; desde MARCO_CONTENIDO_LLAVE ($7751). Ver nota de Sesion 17 en
; SPRITE_ICONO_SARCOFAGO (misma correccion sobre la hipotesis de
; Sesion 3). Confianza alta.
SPRITE_ICONO_LLAVE:
    INCBIN "data/img/sprites/sprite_icono_llave.spr"  ; 87C5, 72 bytes
; Confirmado por DIBUJAR_ICONO_PERGAMINO: LD IY,$880D. 72 bytes exactos.
; Sesion 17: identidad visual "pergamino" confirmada por el usuario
; (recursos/sprites.html) y corroborada por el codigo -- solo se llama
; desde MARCO_CONTENIDO_PERGAMINO ($773D). Ver nota de Sesion 17 en
; SPRITE_ICONO_SARCOFAGO. Confianza alta.
SPRITE_ICONO_PERGAMINO:
    INCBIN "data/img/sprites/sprite_icono_pergamino.spr"  ; 880D, 72 bytes
; Confirmado por DIBUJAR_ICONO_TESORO: LD IY,$8855. 72 bytes exactos.
; Sesion 17: identidad visual "tesoro" confirmada por el usuario
; (recursos/sprites.html) y corroborada por el codigo -- solo se llama
; desde MARCO_CONTENIDO_TESORO ($77B4). Ver nota de Sesion 17 en
; SPRITE_ICONO_SARCOFAGO. Confianza alta.
SPRITE_ICONO_TESORO:
    INCBIN "data/img/sprites/sprite_icono_tesoro.spr"  ; 8855, 72 bytes
; Sesion 19 CORRIGE la hipotesis previa ("mascara/grafico sin separar
; con precision, similar a las tablas de icono de arriba"): esto NO es
; grafico. Confirmado que es una llamada a IMPRIMIR_BYTES_CON_LONGITUD
; con HL=$889D ($619D en la cabecera) -- longitud $68=104, imprime los
; 104 bytes siguientes ($889E-$8905) como codigos de control VDU +
; texto. Termina EXACTO donde empieza la siguiente llamada real, HL=
; $8906 ($61B2), que imprime otro bloque de longitud igual de precisa
; hasta el literal '"C" TO CONTINUE' al final. Confianza alta en la
; estructura (dos bloques longitud+bytes consecutivos, verificado por
; aritmetica exacta de direcciones); el significado de cada codigo de
; control individual sigue sin decodificar. Ver FINDINGS.md Sesion 19.
DATOS_MARCO_Y_TEXTO_CONTINUAR:
; -- entrada real: $619A LD HL,$889D --
    DB 104                            ; 889D longitud
    DB CTRL_TXT_POSICIONAR_CURSOR,$0C,$0B ; 889E
    DB CTRL_TXT_FIJAR_PAPEL,$00       ; 88A1
    DB CTRL_TXT_FIJAR_TINTA,$02       ; 88A3
    DB $88,$8C,$88,$88                ; 88A5 -- graficos de bloque (marco), sin decodificar
    DB "  "                           ; 88A9
    DB $8C,$8C,$84,$84,$84,$8C,$8C,$84,$8C,$8C,$84,$84,$84 ; 88AB -- graficos de bloque (marco)
; -- 19 CTRL_TXT_CURSOR_IZQUIERDA seguidos ($88B8-$88CA): mueve el
; cursor a la izquierda tantas veces como columnas dibujadas, para
; volver al inicio de la fila antes de dibujar la siguiente pieza del
; marco (patron verificado byte a byte, longitud 19 confirmada).
    DB CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA ; 88B8
    DB CTRL_TXT_CURSOR_ABAJO                                        ; 88CB
    DB $8A,$8A,$8A,$8F                 ; 88CC -- graficos de bloque (marco)
    DB "  "                           ; 88D0
    DB $87,$87,$85,$8D,$85,$87,$87,$85,$87,$87,$85,$8F,$85 ; 88D2 -- graficos de bloque (marco)
; -- de nuevo 19 CTRL_TXT_CURSOR_IZQUIERDA seguidos ($88DF-$88F1) --
    DB CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA,CTRL_TXT_CURSOR_IZQUIERDA ; 88DF
    DB CTRL_TXT_CURSOR_ABAJO                                        ; 88F2
    DB $82,$83,$82,$82                 ; 88F3 -- graficos de bloque (marco)
    DB "  "                           ; 88F7
    DB $81                            ; 88F9 -- grafico de bloque (marco)
    DB " "                            ; 88FA
    DB $81,$83,$81,$81                 ; 88FB -- graficos de bloque (marco)
    DB " "                            ; 88FF
    DB $81,$81                         ; 8900 -- graficos de bloque (marco)
    DB " "                            ; 8902
    DB $81                            ; 8903 -- grafico de bloque (marco)
    DB " "                            ; 8904
    DB $81                            ; 8905 -- grafico de bloque (marco)
; -- entrada real: $61AF LD HL,$8906 --
    DB 18                             ; 8906 longitud
    DB CTRL_TXT_POSICIONAR_CURSOR,$0E,$11 ; 8907
    DB '"C" TO CONTINUE'              ; 890A
; Confirmado que empieza aqui: DIBUJAR_ENTIDAD hace LD IY,$8919
; ($7B57). Hipotesis media: ~20 tablas de sprite de 4x16 bytes
; (dispatcher de DIBUJAR_ENTIDAD, por tipo+direccion+fotograma) + 9
; tablas de casilla de 2x8 bytes (DIBUJAR_CASILLA_MAPA) -- limites de
; cada tabla individual sin desglosar todavia. Patron de bytes
; consistente con mascaras de pantalla CPC modo 1 (bloques solidos
; $00/$FF/$F0 alternando con datos variables).
TABLAS_SPRITE_CASILLA:
; Sesion 21: reescritos como DEFS con byte de relleno (igual que
; ARRAY_ENTIDADES/ESTADO_PARTIDA/MAPA_CASILLAS mas abajo, mismo
; fichero) en vez de 64 DB sueltos -- son bytes de relleno solido, no
; una tabla de valores variables, y asi es como ya se escriben en este
; mismo fichero los bloques de un unico byte repetido. Byte a byte
; identico, solo cambia la notacion.
TABLA_BASE:
    DEFS 64, $00 ; 8919 -- relleno de "entidad no reconocida" en DIBUJAR_ENTIDAD (tipo por defecto)
TABLA_ESPACIO:
    DEFS 64, $F0 ; 8959 -- relleno de ' ' en DIBUJAR_ENTIDAD / valor de casilla fuera de 1-8 en DIBUJAR_CASILLA_MAPA
; ---- LOSETA_PISADAS_VERTICAL_1 / LOSETA_PISADAS_VERTICAL_2 ---- 2
; sprites de 32 bytes (4x8, 16x8 px en Modo 1), CONFIRMADOS por
; DIBUJAR_ENTIDAD: la rama de tipo 'T' ($7B65) con ($8157)<2 hace
; "LD IY,$8999" (fija outer=8 via automodificacion de $7CC6) y su
; pareja de alternancia "LD IY,$89B9" (flag $8158). Esta misma rama
; escribe $01/$02 en dos celdas del mapa devueltas por
; CONSULTAR_CASILLA_MAPA -- consistente con marcar una casilla como
; "cavada" en dos posiciones verticales. Identidad visual confirmada
; por el usuario probando recursos/sprites.html (Modo 1, 4x16, offset
; 124, salto 64): "loseta que dibuja en el suelo pisadas en
; vertical" -- el patron de puntos alternos de las 2 mitades de 32
; bytes, vistas juntas, forma un rastro de pisadas verticales.
; Confianza alta en estructura, media-alta en identidad (encaja con
; la hipotesis de rastro de excavacion del jugador). Ver FINDINGS.md
; Sesion 8.
LOSETA_PISADAS_VERTICAL_1:
    INCBIN "data/img/tiles/loseta_pisadas_vertical_1.spr"  ; 8999, 32 bytes
LOSETA_PISADAS_VERTICAL_2:
    INCBIN "data/img/tiles/loseta_pisadas_vertical_2.spr"  ; 89B9, 32 bytes
; ---- LOSETA_MAPA_PISADA_1..8 ---- 8 sprites de 16 bytes (2x8, 8x8 px
; en Modo 1), CONFIRMADOS como los 8 destinos (de los 9 totales) de
; DIBUJAR_CASILLA_MAPA (ver mas abajo) para los valores de casilla
; 0/1,2,3,4,6,5,8,7 respectivamente. Dos de ellos ($89F9 y $8A89)
; coinciden exactos con los sprites que ya pinta en directo la rama
; 'T' de DIBUJAR_ENTIDAD para los valores 3 y 8 -- la misma casilla
; de mapa marcada por 'T' se vuelve a leer despues con
; DIBUJAR_CASILLA_MAPA para redibujarla como parte del suelo.
; Identidad visual confirmada por el usuario probando
; recursos/sprites.html (Modo 1, 2x8, offset 192=$89D9 en adelante,
; salto 16): "8 sprites que corresponden a cada uno de los pasos: los
; dos primeros en vertical, los dos siguientes horizontales, los dos
; siguientes verticales y los dos siguientes horizontales" --
; verificado pixel a pixel, coincide exacto. Refuerza la hipotesis de
; que 'T' es el rastro de pisadas del jugador al excavar, con 4
; variantes de direccion (2 verticales + 2 horizontales) de 2
; fotogramas cada una. Confianza alta en estructura, media-alta en
; identidad. Ver FINDINGS.md Sesion 8.
LOSETA_MAPA_PISADA_1:
    INCBIN "data/img/tiles/loseta_mapa_pisada_1.spr"  ; 89D9, 16 bytes
LOSETA_MAPA_PISADA_2:
    INCBIN "data/img/tiles/loseta_mapa_pisada_2.spr"  ; 89E9, 16 bytes
LOSETA_MAPA_PISADA_3:
    INCBIN "data/img/tiles/loseta_mapa_pisada_3.spr"  ; 89F9, 16 bytes
; ---- LOSETA_PISADA_ESCRITURA_VALOR4 ---- Sesion 11: fotograma de
; escritura de 'T' para el valor de casilla 4 (rama ($8157)==2,
; segundo fotograma, alternado con LOSETA_MAPA_PISADA_3 via el flag
; $8158, ver $7BF2). CONFIRMADO por el codigo que DIBUJAR_ENTIDAD lo
; vuelca como 2x16 (outer=16 por defecto, inner=2 fijado en $7BD7 para
; toda la rama) -- 32 bytes, $8A09-$8A28. Esto SOLAPA con los 16 bytes
; de LOSETA_MAPA_PISADA_4 (2x8, $8A19-$8A28), que es la loseta que lee
; DIBUJAR_CASILLA_MAPA para redibujar esa misma celda mas tarde: son
; bytes fisicamente distintos en $8A09-$8A18, pero comparten los ultimos
; 16 bytes con LOSETA_MAPA_PISADA_4. Confianza alta en estructura y
; geometria, media-alta en identidad visual (sin confirmar en
; emulador). Ver FINDINGS.md Sesion 11.
LOSETA_PISADA_ESCRITURA_VALOR4:
    INCBIN "data/img/tiles/loseta_pisada_escritura_valor4.spr"  ; 8A09, 16 bytes
LOSETA_MAPA_PISADA_4:
    INCBIN "data/img/tiles/loseta_mapa_pisada_4.spr"  ; 8A19, 16 bytes
; ---- LOSETA_PISADA_ESCRITURA_VALOR6 ---- Sesion 11: fotograma de
; escritura de 'T' para el valor de casilla 6 (rama ($8157)==3, primer
; fotograma, ver $7BA5). CONFIRMADO por el codigo que DIBUJAR_ENTIDAD
; lo vuelca como 4x8 (outer=8 fijado en $7BAB, inner=4 por defecto) --
; 32 bytes, $8A29-$8A48, sin solape con ninguna LOSETA_MAPA_PISADA_*.
; Confianza alta en estructura y geometria, sin confirmar identidad
; visual/orientacion. Ver FINDINGS.md Sesion 11.
LOSETA_PISADA_ESCRITURA_VALOR6:
    INCBIN "data/img/tiles/loseta_pisada_escritura_valor6.spr"  ; 8A29, 32 bytes
; ---- LOSETA_PISADA_ESCRITURA_VALOR5 ---- Sesion 11: fotograma de
; escritura de 'T' para el valor de casilla 5 (rama ($8157)==3,
; segundo fotograma, alternado con LOSETA_PISADA_ESCRITURA_VALOR6 via
; el flag $8158, ver $7BC3). Misma geometria 4x8 (32 bytes,
; $8A49-$8A68), sin solape. Confianza alta en estructura y geometria,
; sin confirmar identidad visual/orientacion. Ver FINDINGS.md Sesion 11.
LOSETA_PISADA_ESCRITURA_VALOR5:
    INCBIN "data/img/tiles/loseta_pisada_escritura_valor5.spr"  ; 8A49, 32 bytes
LOSETA_MAPA_PISADA_5:
    INCBIN "data/img/tiles/loseta_mapa_pisada_5.spr"  ; 8A69, 16 bytes
LOSETA_MAPA_PISADA_6:
    INCBIN "data/img/tiles/loseta_mapa_pisada_6.spr"  ; 8A79, 16 bytes
LOSETA_MAPA_PISADA_7:
    INCBIN "data/img/tiles/loseta_mapa_pisada_7.spr"  ; 8A89, 16 bytes
; ---- LOSETA_PISADA_ESCRITURA_VALOR7 ---- Sesion 11: fotograma de
; escritura de 'T' para el valor de casilla 7 (rama ($8157)>=4, segundo
; fotograma, alternado con LOSETA_MAPA_PISADA_7 via el flag $8158, ver
; $7B96). CONFIRMADO por el codigo que DIBUJAR_ENTIDAD lo vuelca como
; 2x16 (outer=16 por defecto, inner=2 fijado en $7B77 para toda la
; rama) -- 32 bytes, $8A99-$8AB8. Esto SOLAPA con los 16 bytes de
; LOSETA_MAPA_PISADA_8 (2x8, $8AA9-$8AB8), que es la loseta que lee
; DIBUJAR_CASILLA_MAPA para redibujar esa misma celda mas tarde: bytes
; fisicamente distintos en $8A99-$8AA8, comparten los ultimos 16 bytes
; con LOSETA_MAPA_PISADA_8. Confianza alta en estructura y geometria,
; media-alta en identidad visual (sin confirmar en emulador). Ver
; FINDINGS.md Sesion 11.
LOSETA_PISADA_ESCRITURA_VALOR7:
    INCBIN "data/img/tiles/loseta_pisada_escritura_valor7.spr"  ; 8A99, 16 bytes
LOSETA_MAPA_PISADA_8:
    INCBIN "data/img/tiles/loseta_mapa_pisada_8.spr"  ; 8AA9, 16 bytes
; ---- SPRITE_JUGADOR_G1_F1..SPRITE_JUGADOR_G4_F2 / SPRITE_MOMIA_G1_F1..
; SPRITE_MOMIA_G4_F2 ---- 16 sprites de 64 bytes (4x16, 16x16 px en
; Modo 1), CONFIRMADOS por DIBUJAR_ENTIDAD: las ramas de tipo 'A'
; ($7C2F) y 'O' ($7C7C) hacen "LD IY,$8AB9/$8AF9/.../$8E79" -- 8
; direcciones (agrupadas en 4 grupos: <2, ==2, ==3, >=4 segun
; ($8157) para 'A' y ($8159) para 'O') x 2 fotogramas de animacion
; cada una (alternados via XOR $01 de un flag). Confirmado de forma
; independiente por el usuario probando el explorador de
; recursos/sprites.html (Modo 1, 4x16, offset inicial 416 = $8AB9,
; salto 64): identifica visualmente 8 sprites del jugador y 8 del
; zombie/momia, primero en $8AB9 y ultimo en $8E79 -- coincide exacto
; con lo derivado del codigo. Hipotesis de identidad visual
; ("jugador"/"momia"), confianza media-alta (dos fuentes
; independientes de acuerdo: codigo y ojo humano, pero sin verificar
; todavia contra una captura de pantalla real en emulador); la
; estructura (16 sprites de 64 bytes perfectamente contiguos) esta
; confirmada al 100% por el codigo. Ver FINDINGS.md Sesion 8.
SPRITE_JUGADOR_G1_F1:
    INCBIN "data/img/sprites/sprite_jugador_g1_f1.spr"  ; 8AB9, 64 bytes
SPRITE_JUGADOR_G1_F2:
    INCBIN "data/img/sprites/sprite_jugador_g1_f2.spr"  ; 8AF9, 64 bytes
SPRITE_JUGADOR_G2_F1:
    INCBIN "data/img/sprites/sprite_jugador_g2_f1.spr"  ; 8B39, 64 bytes
SPRITE_JUGADOR_G2_F2:
    INCBIN "data/img/sprites/sprite_jugador_g2_f2.spr"  ; 8B79, 64 bytes
SPRITE_JUGADOR_G3_F1:
    INCBIN "data/img/sprites/sprite_jugador_g3_f1.spr"  ; 8BB9, 64 bytes
SPRITE_JUGADOR_G3_F2:
    INCBIN "data/img/sprites/sprite_jugador_g3_f2.spr"  ; 8BF9, 64 bytes
SPRITE_JUGADOR_G4_F1:
    INCBIN "data/img/sprites/sprite_jugador_g4_f1.spr"  ; 8C39, 64 bytes
SPRITE_JUGADOR_G4_F2:
    INCBIN "data/img/sprites/sprite_jugador_g4_f2.spr"  ; 8C79, 64 bytes
SPRITE_MOMIA_G1_F1:
    INCBIN "data/img/sprites/sprite_momia_g1_f1.spr"  ; 8CB9, 64 bytes
SPRITE_MOMIA_G1_F2:
    INCBIN "data/img/sprites/sprite_momia_g1_f2.spr"  ; 8CF9, 64 bytes
SPRITE_MOMIA_G2_F1:
    INCBIN "data/img/sprites/sprite_momia_g2_f1.spr"  ; 8D39, 64 bytes
SPRITE_MOMIA_G2_F2:
    INCBIN "data/img/sprites/sprite_momia_g2_f2.spr"  ; 8D79, 64 bytes
SPRITE_MOMIA_G3_F1:
    INCBIN "data/img/sprites/sprite_momia_g3_f1.spr"  ; 8DB9, 64 bytes
SPRITE_MOMIA_G3_F2:
    INCBIN "data/img/sprites/sprite_momia_g3_f2.spr"  ; 8DF9, 64 bytes
SPRITE_MOMIA_G4_F1:
    INCBIN "data/img/sprites/sprite_momia_g4_f1.spr"  ; 8E39, 64 bytes
SPRITE_MOMIA_G4_F2:
    INCBIN "data/img/sprites/sprite_momia_g4_f2.spr"  ; 8E79, 64 bytes
    DB $10,$1D,$01,$01,$1C,$00,$01,$01,$1C,$01,$18,$18,$0E,$00,$0F,$01 ; 8EB9
    DB $0C                                           ; 8EC9
; Confirmado: $6078 LD IX,$8ECA + bucle de 200 iteraciones que llama
; a FIRM_SCR_DOT_POSITION y guarda el resultado aqui (200 entradas x
; 2 bytes = 400 bytes). Se construye en tiempo de ejecucion -- el
; fichero compilado la tiene a 0 porque nunca se lee antes de que
; ese bucle la rellene.
TABLA_DIRECCIONES_PANTALLA:
    DEFS 400                              ; 8ECA 400 bytes, todo cero
; Confirmado: ACTUALIZAR_SECUENCIA_SONIDO hace LD HL,($905A) y
; LD ($905A),HL -- puntero de 2 bytes a la entrada actual de
; GUION_SONIDO_CIRCULAR, inicializado a GUION_SONIDO_CIRCULAR en el
; arranque ($6033-$6036).
PUNTERO_GUION_SONIDO:
    DB $00,$00                                       ; 905A
; Confirmado: tabla CIRCULAR de guion de sonido consumida por
; ACTUALIZAR_SECUENCIA_SONIDO -- avanza PUNTERO_GUION_SONIDO de 9 en
; 9 bytes, vuelve a GUION_SONIDO_CIRCULAR al llegar a
; GUION_SONIDO_ULTIMO_REGISTRO ($937D), y llama a FIRM_SOUND_QUEUE
; cuando ($7FC4)=FLAG_MUSICA_FONDO='Y'. 90 registros de 9 bytes
; exactos (810 bytes = el resto justo hasta el final del motor,
; $9385). Hipotesis media-alta: cada registro es un bloque de
; parametros de SOUND QUEUE del firmware (estado 2B + tono 2B +
; volumen/envolvente 1B + duracion 2B + envolventes 2B), formato sin
; desglosar campo a campo.
GUION_SONIDO_CIRCULAR:
    DB $11,$00,$00,$DE,$01,$00,$0C,$20,$00 ; 905C
    DB $0A,$00,$00,$FC,$04,$00,$0C,$08,$00 ; 9065
    DB $11,$00,$00,$AA,$01,$00,$0C,$20,$00 ; 906E
    DB $0A,$00,$00,$7E,$02,$00,$0C,$08,$00 ; 9077
    DB $11,$00,$00,$92,$01,$00,$0C,$20,$00 ; 9080
    DB $0A,$00,$00,$BC,$03,$00,$0C,$08,$00 ; 9089
    DB $11,$00,$00,$92,$01,$00,$0C,$20,$00 ; 9092
    DB $0A,$00,$00,$7E,$02,$00,$0C,$08,$00 ; 909B
    DB $02,$00,$00,$7E,$03,$00,$00,$08,$00 ; 90A4
    DB $02,$00,$00,$7E,$02,$00,$0C,$08,$00 ; 90AD
    DB $11,$00,$00,$AA,$01,$00,$0C,$20,$00 ; 90B6
    DB $0A,$00,$00,$FC,$04,$00,$0C,$08,$00 ; 90BF
    DB $11,$00,$00,$AA,$01,$00,$0C,$20,$00 ; 90C8
    DB $0A,$00,$00,$7E,$02,$00,$0C,$08,$00 ; 90D1
    DB $11,$00,$00,$DE,$01,$00,$0C,$20,$00 ; 90DA
    DB $0A,$00,$00,$BC,$03,$00,$0C,$08,$00 ; 90E3
    DB $11,$00,$00,$DE,$01,$00,$0C,$1F,$00 ; 90EC
    DB $0A,$00,$00,$7E,$02,$00,$0C,$08,$00 ; 90F5
    DB $02,$00,$00,$7E,$02,$00,$00,$08,$00 ; 90FE
    DB $02,$00,$00,$7E,$02,$00,$0C,$08,$00 ; 9107
    DB $11,$00,$00,$DE,$01,$00,$0C,$20,$00 ; 9110
    DB $0A,$00,$00,$FC,$04,$00,$0C,$08,$00 ; 9119
    DB $11,$00,$00,$AA,$01,$00,$0C,$20,$00 ; 9122
    DB $0A,$00,$00,$7E,$02,$00,$0C,$08,$00 ; 912B
    DB $11,$00,$00,$92,$01,$00,$0C,$20,$00 ; 9134
    DB $0A,$00,$00,$BC,$03,$00,$0C,$08,$00 ; 913D
    DB $11,$00,$00,$3F,$01,$00,$0C,$20,$00 ; 9146
    DB $0A,$00,$00,$7E,$02,$00,$0C,$08,$00 ; 914F
    DB $02,$00,$00,$7E,$02,$00,$00,$08,$00 ; 9158
    DB $02,$00,$00,$7E,$02,$00,$0C,$08,$00 ; 9161
    DB $11,$00,$00,$AA,$01,$00,$0C,$20,$00 ; 916A
    DB $0A,$00,$00,$FC,$04,$00,$0C,$08,$00 ; 9173
    DB $11,$00,$00,$92,$01,$00,$0C,$20,$00 ; 917C
    DB $0A,$00,$00,$7E,$02,$00,$0C,$08,$00 ; 9185
    DB $11,$00,$00,$DE,$01,$00,$0C,$20,$00 ; 918E
    DB $0A,$00,$00,$BC,$03,$00,$0C,$08,$00 ; 9197
    DB $11,$00,$00,$DE,$01,$00,$0C,$20,$00 ; 91A0
    DB $0A,$00,$00,$7E,$02,$00,$0C,$08,$00 ; 91A9
    DB $02,$00,$00,$7E,$02,$00,$00,$08,$00 ; 91B2
    DB $02,$00,$00,$7E,$02,$00,$0C,$08,$00 ; 91BB
    DB $11,$00,$00,$92,$01,$00,$0C,$20,$00 ; 91C4
    DB $0A,$00,$00,$FC,$04,$00,$0C,$08,$00 ; 91CD
    DB $11,$00,$00,$66,$01,$00,$0C,$20,$00 ; 91D6
    DB $0A,$00,$00,$7E,$02,$00,$0C,$08,$00 ; 91DF
    DB $11,$00,$00,$3F,$01,$00,$0C,$0F,$00 ; 91E8
    DB $0A,$00,$00,$BC,$03,$00,$0C,$08,$00 ; 91F1
    DB $01,$00,$00,$3F,$01,$00,$00,$01,$00 ; 91FA
    DB $01,$00,$00,$3F,$01,$00,$0C,$0F,$00 ; 9203
    DB $01,$00,$00,$3F,$01,$00,$00,$01,$00 ; 920C
    DB $11,$00,$00,$3F,$01,$00,$0C,$0F,$00 ; 9215
    DB $0A,$00,$00,$7E,$02,$00,$0C,$08,$00 ; 921E
    DB $01,$00,$00,$3F,$01,$00,$00,$01,$00 ; 9227
    DB $11,$00,$00,$3F,$01,$00,$0C,$0F,$00 ; 9230
    DB $0A,$00,$00,$7E,$02,$00,$0C,$08,$00 ; 9239
    DB $01,$00,$00,$3F,$01,$00,$00,$01,$00 ; 9242
    DB $11,$00,$00,$3F,$01,$00,$0C,$20,$00 ; 924B
    DB $0A,$00,$00,$FC,$04,$00,$0C,$08,$00 ; 9254
    DB $11,$00,$00,$2D,$01,$00,$0C,$20,$00 ; 925D
    DB $0A,$00,$00,$7E,$02,$00,$0C,$08,$00 ; 9266
    DB $11,$00,$00,$3F,$01,$00,$0C,$20,$00 ; 926F
    DB $0A,$00,$00,$BC,$03,$00,$0C,$08,$00 ; 9278
    DB $11,$00,$00,$66,$01,$00,$0C,$20,$00 ; 9281
    DB $0A,$00,$00,$7E,$02,$00,$0C,$08,$00 ; 928A
    DB $02,$00,$00,$7E,$02,$00,$00,$08,$00 ; 9293
    DB $02,$00,$00,$7E,$02,$00,$0C,$08,$00 ; 929C
    DB $11,$00,$00,$AA,$01,$00,$0C,$20,$00 ; 92A5
    DB $0A,$00,$00,$FC,$04,$00,$0C,$08,$00 ; 92AE
    DB $11,$00,$00,$92,$01,$00,$0C,$20,$00 ; 92B7
    DB $0A,$00,$00,$7E,$02,$00,$0C,$08,$00 ; 92C0
    DB $11,$00,$00,$66,$01,$00,$0C,$0F,$00 ; 92C9
    DB $0A,$00,$00,$BC,$03,$00,$0C,$08,$00 ; 92D2
    DB $01,$00,$00,$3F,$01,$00,$00,$01,$00 ; 92DB
    DB $01,$00,$00,$66,$01,$00,$0C,$0F,$00 ; 92E4
    DB $01,$00,$00,$3F,$01,$00,$00,$01,$00 ; 92ED
    DB $11,$00,$00,$66,$01,$00,$0C,$0F,$00 ; 92F6
    DB $0A,$00,$00,$7E,$02,$00,$0C,$08,$00 ; 92FF
    DB $01,$00,$00,$3F,$01,$00,$00,$01,$00 ; 9308
    DB $11,$00,$00,$66,$01,$00,$0C,$0F,$00 ; 9311
    DB $0A,$00,$00,$7E,$02,$00,$0C,$08,$00 ; 931A
    DB $01,$00,$00,$3F,$01,$00,$00,$01,$00 ; 9323
    DB $11,$00,$00,$66,$01,$00,$0C,$20,$00 ; 932C
    DB $0A,$00,$00,$FC,$04,$00,$0C,$08,$00 ; 9335
    DB $11,$00,$00,$3F,$01,$00,$0C,$20,$00 ; 933E
    DB $0A,$00,$00,$7E,$02,$00,$0C,$08,$00 ; 9347
    DB $11,$00,$00,$66,$01,$00,$0C,$20,$00 ; 9350
    DB $0A,$00,$00,$BC,$03,$00,$0C,$08,$00 ; 9359
    DB $11,$00,$00,$92,$01,$00,$0C,$20,$00 ; 9362
    DB $0A,$00,$00,$7E,$02,$00,$0C,$08,$00 ; 936B
    DB $02,$00,$00,$7E,$02,$00,$00,$08,$00 ; 9374
GUION_SONIDO_ULTIMO_REGISTRO:
    DB $02,$00,$00,$7E,$02,$00,$0C,$08,$00 ; 937D
