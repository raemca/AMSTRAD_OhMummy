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
FIRM_TXT_SET_PAPER      EQU $BB96   ; Fijar tinta de fondo para texto
FIRM_SCR_DOT_POSITION   EQU $BC1D   ; Convertir coordenadas base a direccion de pantalla
FIRM_SOUND_RESET        EQU $BCA7   ; Reset del gestor de sonido (silencia PSG, vacia colas)
FIRM_SOUND_AMPL_ENV     EQU $BCBC   ; Definir una envolvente de amplitud
FIRM_SOUND_TONE_ENV     EQU $BCBF   ; Definir una envolvente de tono
FIRM_KL_TIME_PLEASE     EQU $BD0D   ; Leer el contador de tiempo transcurrido
FIRM_KM_CHAR_RETURN     EQU $BB0C   ; Devolver un caracter al buffer de teclado
FIRM_SOUND_QUEUE        EQU $BCAA   ; Anadir un sonido a una cola de sonido

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
; $7EF4: hipotesis "repetir un caracter N veces por FIRM_TXT_OUTPUT" --
; lee (HL)=contador, (HL+1)=caracter, y saca ese caracter "contador"
; veces sin avanzar mas el puntero (formato de datos de 2 bytes por
; llamada: cuenta+caracter). Encaja con dibujar tramos rectos de un
; marco/borde decorativo. Ver FINDINGS.md Sesion 3.
    LD HL,TABLA_PARAMETROS_TRANSICION_PUNTUACIONES+8 ; 6066: 215386
    CALL REPETIR_CARACTER                   ; 6069: cdf47e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;606C: cdd178
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;606F: cdd178
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;6072: cdd178
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;6075: cdd178
    LD IX,TABLA_DIRECCIONES_PANTALLA ; 6078: dd21ca8e
    LD B,$C8                     ; 607C: 06c8
    LD DE,$0000                  ; 607E: 110000
; Bucle $607E-$6093: confirmado (Sesion 8) -- 200 iteraciones (B=$C8),
; cada una calcula con el firmware FIRM_SCR_DOT_POSITION la direccion
; de pantalla de una fila y la guarda en TABLA_DIRECCIONES_PANTALLA
; (200 entradas x 2 bytes). Tecnica muy comun en juegos de CPC para
; acelerar el acceso a filas de pantalla.
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
    DJNZ $607E                   ; 6093: 10e9
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;6095: cdd178
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;6098: cdd178
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;609B: cdd178
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;609E: cdd178
    LD HL,TEXTO_COPYRIGHT_Y_HUD   ; 60A1: 214087
    CALL REPETIR_CARACTER                   ; 60A4: cdf47e
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
    CALL DIBUJAR_TRAMO_MARCO_1                   ; 6170: cd857d
    LD HL,$2816                  ; 6173: 211628
    CALL $7DFC                   ; 6176: cdfc7d
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;6179: cdd178
    LD HL,$2824                  ; 617C: 212428
    CALL DIBUJAR_TRAMO_MARCO_4                   ; 617F: cdcd7d
    LD HL,$2832                  ; 6182: 213228
    CALL $7E0E                   ; 6185: cd0e7e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;6188: cdd178
    LD HL,$2840                  ; 618B: 214028
    CALL DIBUJAR_TRAMO_MARCO_2                   ; 618E: cd9d7d
    LD HL,$5008                  ; 6191: 210850
    CALL $7E29                   ; 6194: cd297e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;6197: cdd178
    LD HL,$889D                  ; 619A: 219d88
    CALL REPETIR_CARACTER                   ; 619D: cdf47e
    LD HL,$5040                  ; 61A0: 214050
    CALL $7E29                   ; 61A3: cd297e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;61A6: cdd178
    LD HL,$7808                  ; 61A9: 210878
    CALL $7E29                   ; 61AC: cd297e
    LD HL,$8906                  ; 61AF: 210689
    CALL REPETIR_CARACTER                   ; 61B2: cdf47e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;61B5: cdd178
    LD HL,$7840                  ; 61B8: 214078
    CALL $7E29                   ; 61BB: cd297e
    LD HL,$A008                  ; 61BE: 2108a0
    CALL DIBUJAR_TRAMO_MARCO_4                   ; 61C1: cdcd7d
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;61C4: cdd178
    LD HL,$A016                  ; 61C7: 2116a0
    CALL $7E17                   ; 61CA: cd177e
    LD HL,$A024                  ; 61CD: 2124a0
    CALL DIBUJAR_TRAMO_MARCO_3                   ; 61D0: cdb57d
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;61D3: cdd178
    LD HL,$A032                  ; 61D6: 2132a0
    CALL $7E05                   ; 61D9: cd057e
    LD HL,$A040                  ; 61DC: 2140a0
    CALL DIBUJAR_TRAMO_MARCO_4                   ; 61DF: cdcd7d
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;61E2: cdd178
    LD HL,$860F                  ; 61E5: 210f86
    LD ($8645),HL                ; 61E8: 224586
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
    CALL FIRM_KM_READ_CHAR                   ; 6201: cd09bb
    LD B,$01                     ; 6204: 0601
    CALL ANIMAR_OPCION_MENU                   ; 6206: cdb778
    CALL $78F7                   ; 6209: cdf778
    CALL ESPERAR_TECLA_2C                   ; 620C: cd9378
    LD B,$02                     ; 620F: 0602
    CALL ANIMAR_OPCION_MENU                   ; 6211: cdb778
    CALL $78F7                   ; 6214: cdf778
    LD A,$3E                     ; 6217: 3e3e
    CALL FIRM_KM_TEST_KEY                   ; 6219: cd1ebb
    JR NZ,$6223                  ; 621C: 2005
    CALL ESPERAR_TECLA_2C                   ; 621E: cd9378
    JR $6201                     ; 6221: 18de
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;6223: cdd178
    CALL FIRM_KM_READ_CHAR                   ; 6226: cd09bb
    JR C,$6223                   ; 6229: 38f8
    LD HL,$866D                  ; 622B: 216d86
    CALL REPETIR_CARACTER                   ; 622E: cdf47e
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
    CALL $7B39                   ; 6279: cd397b
    LD DE,$283A                  ; 627C: 113a28
    LD ($8155),DE                ; 627F: ed535581
    LD A,$04                     ; 6283: 3e04
    LD ($8157),A                 ; 6285: 325781
    LD A,$41                     ; 6288: 3e41
    CALL $7B39                   ; 628A: cd397b
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
    CALL REPETIR_CARACTER                   ; 62C8: cdf47e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;62CB: cdd178
    LD HL,$0C0A                  ; 62CE: 210a0c
    CALL FIRM_TXT_SET_CURSOR                   ; 62D1: cd75bb
    LD HL,($868C)                ; 62D4: 2a8c86
    CALL $786C                   ; 62D7: cd6c78
    LD HL,$868E                  ; 62DA: 218e86
    CALL REPETIR_CARACTER                   ; 62DD: cdf47e
    LD HL,$0C0C                  ; 62E0: 210c0c
    CALL FIRM_TXT_SET_CURSOR                   ; 62E3: cd75bb
    LD HL,($869E)                ; 62E6: 2a9e86
    CALL $786C                   ; 62E9: cd6c78
    LD HL,$86A0                  ; 62EC: 21a086
    CALL REPETIR_CARACTER                   ; 62EF: cdf47e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;62F2: cdd178
    LD HL,$0C0E                  ; 62F5: 210e0c
    CALL FIRM_TXT_SET_CURSOR                   ; 62F8: cd75bb
    LD HL,($86B0)                ; 62FB: 2ab086
    CALL $786C                   ; 62FE: cd6c78
    LD HL,$86B2                  ; 6301: 21b286
    CALL REPETIR_CARACTER                   ; 6304: cdf47e
    LD HL,$0C10                  ; 6307: 21100c
    CALL FIRM_TXT_SET_CURSOR                   ; 630A: cd75bb
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;630D: cdd178
    LD HL,($86C2)                ; 6310: 2ac286
    CALL $786C                   ; 6313: cd6c78
    LD HL,$86C4                  ; 6316: 21c486
    CALL REPETIR_CARACTER                   ; 6319: cdf47e
    LD HL,$0C12                  ; 631C: 21120c
    CALL FIRM_TXT_SET_CURSOR                   ; 631F: cd75bb
    LD HL,($86D4)                ; 6322: 2ad486
    CALL $786C                   ; 6325: cd6c78
    LD HL,$86D6                  ; 6328: 21d686
    CALL REPETIR_CARACTER                   ; 632B: cdf47e
    LD HL,$8637                  ; 632E: 213786
    LD ($8645),HL                ; 6331: 224586
    CALL INICIALIZAR_ENTIDADES                   ; 6334: cd4f79
    LD HL,$6828                  ; 6337: 212868
    LD ($8155),HL                ; 633A: 225581
    CALL ACTUALIZAR_SECUENCIA_SONIDO ;633D: cdd178
    LD A,($8168)                 ; 6340: 3a6881
    OR A                         ; 6343: b7
    JR Z,$636C                   ; 6344: 2826
    LD HL,$8710                  ; 6346: 211087
    CALL REPETIR_CARACTER                   ; 6349: cdf47e
    XOR A                        ; 634C: af
    CALL FIRM_TXT_SET_PAPER                   ; 634D: cd96bb
    LD HL,($7FC6)                ; 6350: 2ac67f
    CALL FIRM_TXT_SET_CURSOR                   ; 6353: cd75bb
    XOR A                        ; 6356: af
    LD ($8649),A                 ; 6357: 324986
    LD A,$8F                     ; 635A: 3e8f
    CALL FIRM_TXT_OUTPUT                   ; 635C: cd5abb
    LD HL,($7FC6)                ; 635F: 2ac67f
    CALL FIRM_TXT_SET_CURSOR                   ; 6362: cd75bb
    CALL FIRM_KM_READ_CHAR                   ; 6365: cd09bb
    JR C,$6365                   ; 6368: 38fb
    JR $6372                     ; 636A: 1806
    LD HL,$86E8                  ; 636C: 21e886
    CALL REPETIR_CARACTER                   ; 636F: cdf47e
    LD B,$01                     ; 6372: 0601
    CALL ANIMAR_OPCION_MENU                   ; 6374: cdb778
    LD B,$02                     ; 6377: 0602
    CALL ANIMAR_OPCION_MENU                   ; 6379: cdb778
    LD A,($8168)                 ; 637C: 3a6881
    OR A                         ; 637F: b7
    JP Z,$6404                   ; 6380: ca0464
    CALL FIRM_KM_READ_CHAR                   ; 6383: cd09bb
    JR NC,$6372                  ; 6386: 30ea
    CP $0D                       ; 6388: fe0d
    JR Z,$63F3                   ; 638A: 2867
    CP $7F                       ; 638C: fe7f
    JR Z,$63C4                   ; 638E: 2834
    LD B,A                       ; 6390: 47
    LD A,($8649)                 ; 6391: 3a4986
    CP $0C                       ; 6394: fe0c
    JR Z,$6372                   ; 6396: 28da
    LD A,B                       ; 6398: 78
    CP $20                       ; 6399: fe20
    JR C,$6372                   ; 639B: 38d5
    CP $80                       ; 639D: fe80
    JR NC,$6372                  ; 639F: 30d1
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
    LD A,($8649)                 ; 63BB: 3a4986
    INC A                        ; 63BE: 3c
    LD ($8649),A                 ; 63BF: 324986
    JR $6372                     ; 63C2: 18ae
    LD A,($8649)                 ; 63C4: 3a4986
    OR A                         ; 63C7: b7
    JR Z,$6372                   ; 63C8: 28a8
    DEC A                        ; 63CA: 3d
    LD ($8649),A                 ; 63CB: 324986
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
    JP $6372                     ; 63F0: c37263
    LD A,$20                     ; 63F3: 3e20
    CALL FIRM_TXT_OUTPUT                   ; 63F5: cd5abb
    XOR A                        ; 63F8: af
    LD ($8168),A                 ; 63F9: 326881
    LD A,$03                     ; 63FC: 3e03
    CALL FIRM_TXT_SET_PAPER                   ; 63FE: cd96bb

; ---- Mas alla de $6400: 2 bloques reconstruidos (26 rutinas, 1539
; bytes) intercalados con el resto sin analizar todavia (INCBIN con
; offset/longitud). Ver FINDINGS.md Sesiones 3-6 para el detalle y
; el nivel de confianza de cada hipotesis. ----

    INCBIN "data/mummy1_resto_sin_analizar.bin", 0, 5227  ; $6401-$786B, sin analizar todavia

; ---- IMPRIMIR_NUMERO_HL / ESPERAR_TECLA_2C / ANIMAR_OPCION_MENU / ACTUALIZAR_SECUENCIA_SONIDO /
; MOVER_INDICADOR_MENU / INICIALIZAR_ENTIDADES / INICIALIZAR_UNA_ENTIDAD / COLOCAR_ENTIDAD /
; HAY_COLISION / CALCULAR_CASILLA_ADYACENTE / ELEGIR_DIRECCION_HACIA_OBJETIVO /
; PREPARAR_DIBUJAR_ENTIDAD+DIBUJAR_ENTIDAD / DIBUJAR_CASILLA_MAPA / CONSULTAR_CASILLA_MAPA /
; GENERAR_ALEATORIO+MEZCLAR_ALEATORIO / DIBUJAR_TRAMO_MARCO_1-4 ----
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
    INC IY                           ; 7872: fd23
    INC IY                           ; 7874: fd23
    LD E,(IY+0)                      ; 7876: fd5e00
    LD D,(IY+1)                      ; 7879: fd5601
    XOR A                            ; 787C: af
    LD A,$30                         ; 787D: 3e30
    SBC HL,DE                        ; 787F: ed52
    JR C,$7886                       ; 7881: 3803
    INC A                            ; 7883: 3c
    JR $787F                         ; 7884: 18f9
    ADD HL,DE                        ; 7886: 19
    CALL FIRM_TXT_OUTPUT             ; 7887: cd5abb
    DJNZ $7872                       ; 788A: 10e6
    LD A,$30                         ; 788C: 3e30
    ADD A,L                          ; 788E: 85
    CALL FIRM_TXT_OUTPUT             ; 788F: cd5abb
    RET                              ; 7892: c9
ESPERAR_TECLA_2C:
    LD A,$2C                         ; 7893: 3e2c
    CALL FIRM_KM_TEST_KEY            ; 7895: cd1ebb
    RET Z                            ; 7898: c8
    CALL ACTUALIZAR_SECUENCIA_SONIDO ; 7899: cdd178
    LD A,$2C                         ; 789C: 3e2c
    CALL FIRM_KM_TEST_KEY            ; 789E: cd1ebb
    JR NZ,$7899                      ; 78A1: 20f6
    CALL ACTUALIZAR_SECUENCIA_SONIDO ; 78A3: cdd178
    CALL FIRM_KM_READ_CHAR           ; 78A6: cd09bb
    JR C,$78A3                       ; 78A9: 38f8
    CALL ACTUALIZAR_SECUENCIA_SONIDO ; 78AB: cdd178
    CALL FIRM_KM_READ_CHAR           ; 78AE: cd09bb
    JR NC,$78AB                      ; 78B1: 30f8
    CALL FIRM_KM_CHAR_RETURN         ; 78B3: cd0cbb
    RET                              ; 78B6: c9
ANIMAR_OPCION_MENU:
    PUSH BC                          ; 78B7: c5
    CALL COLOCAR_ENTIDAD             ; 78B8: cd9679
    CALL ACTUALIZAR_SECUENCIA_SONIDO ; 78BB: cdd178
    LD DE,($8153)                    ; 78BE: ed5b5381
    DEC DE                           ; 78C2: 1b
    LD A,D                           ; 78C3: 7a
    OR E                             ; 78C4: b3
    JR NZ,$78C2                      ; 78C5: 20fb
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
    JR Z,$78F0                       ; 78E6: 2808
    LD HL,$0009                      ; 78E8: 210900
    ADD HL,DE                        ; 78EB: 19
    LD (PUNTERO_GUION_SONIDO),HL     ; 78EC: 225a90
    RET                              ; 78EF: c9
    LD HL,GUION_SONIDO_CIRCULAR      ; 78F0: 215c90
    LD (PUNTERO_GUION_SONIDO),HL     ; 78F3: 225a90
    RET                              ; 78F6: c9
MOVER_INDICADOR_MENU:
    LD A,($8155)                     ; 78F7: 3a5581
    CP $1A                           ; 78FA: fe1a
    JR NZ,$7902                      ; 78FC: 2004
    LD A,$02                         ; 78FE: 3e02
    JR $7908                         ; 7900: 1806
    CP $34                           ; 7902: fe34
    JR NZ,$790B                      ; 7904: 2005
    LD A,$04                         ; 7906: 3e04
    LD ($8157),A                     ; 7908: 325781
    LD A,$54                         ; 790B: 3e54
    LD DE,($8155)                    ; 790D: ed5b5581
    CALL DIBUJAR_ENTIDAD             ; 7911: cd397b
    LD A,($8157)                     ; 7914: 3a5781
    CP $02                           ; 7917: fe02
    JR C,$792F                       ; 7919: 3814
    JR Z,$7928                       ; 791B: 280b
    CP $03                           ; 791D: fe03
    JR Z,$7937                       ; 791F: 2816
    LD A,($8155)                     ; 7921: 3a5581
    DEC A                            ; 7924: 3d
    DEC A                            ; 7925: 3d
    JR $7942                         ; 7926: 181a
    LD A,($8155)                     ; 7928: 3a5581
    INC A                            ; 792B: 3c
    INC A                            ; 792C: 3c
    JR $7942                         ; 792D: 1813
    LD A,($8156)                     ; 792F: 3a5681
    LD B,$08                         ; 7932: 0608
    SUB B                            ; 7934: 90
    JR $793D                         ; 7935: 1806
    LD A,($8156)                     ; 7937: 3a5681
    LD B,$08                         ; 793A: 0608
    ADD A,B                          ; 793C: 80
    LD ($8156),A                     ; 793D: 325681
    JR $7945                         ; 7940: 1803
    LD ($8155),A                     ; 7942: 325581
    LD A,$41                         ; 7945: 3e41
    LD DE,($8155)                    ; 7947: ed5b5581
    CALL DIBUJAR_ENTIDAD             ; 794B: cd397b
    RET                              ; 794E: c9
INICIALIZAR_ENTIDADES:
    LD A,($8169)                     ; 794F: 3a6981
    LD B,A                           ; 7952: 47
    PUSH BC                          ; 7953: c5
    CALL INICIALIZAR_UNA_ENTIDAD     ; 7954: cd5b79
    POP BC                           ; 7957: c1
    DJNZ $7953                       ; 7958: 10f9
    RET                              ; 795A: c9
INICIALIZAR_UNA_ENTIDAD:
    LD A,($816C)                     ; 795B: 3a6c81
    INC A                            ; 795E: 3c
    LD ($816C),A                     ; 795F: 326c81
    LD B,A                           ; 7962: 47
    LD IX,ARRAY_ENTIDADES             ; 7963: dd216d81
    LD DE,$0005                      ; 7967: 110500
    ADD IX,DE                        ; 796A: dd19
    DJNZ $796A                       ; 796C: 10fc
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
    LD DE,($8645)                    ; 7987: ed5b4586
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
    ADD IX,DE                        ; 799D: dd19
    DJNZ $799D                       ; 799F: 10fc
    LD A,(IX+0)                      ; 79A1: dd7e00
    OR A                             ; 79A4: b7
    JR NZ,$79AC                      ; 79A5: 2005
    LD A,(IX+1)                      ; 79A7: dd7e01
    OR A                             ; 79AA: b7
    RET Z                            ; 79AB: c8
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
    JR NZ,$79EA                      ; 79DD: 200b
    LD D,(IX+2)                      ; 79DF: dd5602
    LD E,(IX+3)                      ; 79E2: dd5e03
    LD A,$4F                         ; 79E5: 3e4f
    JP DIBUJAR_ENTIDAD               ; 79E7: c3397b
    LD B,(IX+0)                      ; 79EA: dd4600
    LD C,(IX+1)                      ; 79ED: dd4e01
    DEC A                            ; 79F0: 3d
    JR Z,$79F7                       ; 79F1: 2804
    DEC B                            ; 79F3: 05
    DEC C                            ; 79F4: 0d
    JR $79F9                         ; 79F5: 1802
    INC B                            ; 79F7: 04
    INC C                            ; 79F8: 0c
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
    PUSH BC                          ; 7A25: c5
    LD BC,$0005                      ; 7A26: 010500
    ADD IY,BC                        ; 7A29: fd09
    LD A,(IY+0)                      ; 7A2B: fd7e00
    OR (IY+1)                        ; 7A2E: fdb601
    JR Z,$7A58                       ; 7A31: 2825
    LD A,(IY+2)                      ; 7A33: fd7e02
    SUB D                            ; 7A36: 92
    CP $F8                           ; 7A37: fef8
    JR Z,$7A42                       ; 7A39: 2807
    CP $08                           ; 7A3B: fe08
    JR Z,$7A42                       ; 7A3D: 2803
    OR A                             ; 7A3F: b7
    JR NZ,$7A58                      ; 7A40: 2016
    LD A,(IY+3)                      ; 7A42: fd7e03
    SUB E                            ; 7A45: 93
    CP $FE                           ; 7A46: fefe
    JR Z,$7A51                       ; 7A48: 2807
    CP $02                           ; 7A4A: fe02
    JR Z,$7A51                       ; 7A4C: 2803
    OR A                             ; 7A4E: b7
    JR NZ,$7A58                      ; 7A4F: 2007
    LD A,($8610)                     ; 7A51: 3a1086
    INC A                            ; 7A54: 3c
    LD ($8610),A                     ; 7A55: 321086
    POP BC                           ; 7A58: c1
    DJNZ $7A25                       ; 7A59: 10ca
    LD A,($8610)                     ; 7A5B: 3a1086
    CP $01                           ; 7A5E: fe01
    JR Z,$7A64                       ; 7A60: 2802
    XOR A                            ; 7A62: af
    RET                              ; 7A63: c9
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
    CP $02                           ; 7A98: fe02
    JR C,$7AB0                       ; 7A9A: 3814
    JR Z,$7AAC                       ; 7A9C: 280e
    CP $03                           ; 7A9E: fe03
    JR Z,$7AA6                       ; 7AA0: 2804
    DEC L                            ; 7AA2: 2d
    DEC L                            ; 7AA3: 2d
    JR $7AB4                         ; 7AA4: 180e
    LD A,H                           ; 7AA6: 7c
    ADD A,$08                        ; 7AA7: c608
    LD H,A                           ; 7AA9: 67
    JR $7AB4                         ; 7AAA: 1808
    INC L                            ; 7AAC: 2c
    INC L                            ; 7AAD: 2c
    JR $7AB4                         ; 7AAE: 1804
    LD A,H                           ; 7AB0: 7c
    SUB $08                          ; 7AB1: d608
    LD H,A                           ; 7AB3: 67
    EX DE,HL                         ; 7AB4: eb
    RET                              ; 7AB5: c9
ELEGIR_DIRECCION_HACIA_OBJETIVO:
    LD BC,($8164)                    ; 7AB6: ed4b6481
    LD A,($8156)                     ; 7ABA: 3a5681
    SUB B                            ; 7ABD: 90
    JR C,$7AC6                       ; 7ABE: 3806
    JR Z,$7AC8                       ; 7AC0: 2806
    LD A,$03                         ; 7AC2: 3e03
    JR $7AC8                         ; 7AC4: 1802
    LD A,$01                         ; 7AC6: 3e01
    LD ($815F),A                     ; 7AC8: 325f81
    LD A,($8155)                     ; 7ACB: 3a5581
    SUB C                            ; 7ACE: 91
    JR C,$7AD7                       ; 7ACF: 3806
    JR Z,$7AD9                       ; 7AD1: 2806
    LD A,$02                         ; 7AD3: 3e02
    JR $7AD9                         ; 7AD5: 1802
    LD A,$04                         ; 7AD7: 3e04
    LD ($8160),A                     ; 7AD9: 326081
    LD A,$02                         ; 7ADC: 3e02
    CALL GENERAR_ALEATORIO           ; 7ADE: cd537d
    LD BC,($815F)                    ; 7AE1: ed4b5f81
    OR A                             ; 7AE5: b7
    JR Z,$7AEB                       ; 7AE6: 2803
    LD A,B                           ; 7AE8: 78
    LD B,C                           ; 7AE9: 41
    LD C,A                           ; 7AEA: 4f
    LD (IX+0),B                      ; 7AEB: dd7000
    LD (IX+1),C                      ; 7AEE: dd7101
    RET                              ; 7AF1: c9
PREPARAR_DIBUJAR_ENTIDAD:
    LD DE,($8164)                    ; 7AF2: ed5b6481
    LD A,($8159)                     ; 7AF6: 3a5981
    CP $02                           ; 7AF9: fe02
    JR C,$7B19                       ; 7AFB: 381c
    JR Z,$7B05                       ; 7AFD: 2806
    CP $03                           ; 7AFF: fe03
    JR Z,$7B1D                       ; 7B01: 281a
    INC E                            ; 7B03: 1c
    INC E                            ; 7B04: 1c
    CALL CONSULTAR_CASILLA_MAPA      ; 7B05: cd3e7d
    LD A,(HL)                        ; 7B08: 7e
    CALL DIBUJAR_CASILLA_MAPA        ; 7B09: cde67c
    LD A,$08                         ; 7B0C: 3e08
    ADD A,D                          ; 7B0E: 82
    LD D,A                           ; 7B0F: 57
    CALL CONSULTAR_CASILLA_MAPA      ; 7B10: cd3e7d
    LD A,(HL)                        ; 7B13: 7e
    CALL DIBUJAR_CASILLA_MAPA        ; 7B14: cde67c
    JR $7B2D                         ; 7B17: 1814
    LD A,$08                         ; 7B19: 3e08
    ADD A,D                          ; 7B1B: 82
    LD D,A                           ; 7B1C: 57
    CALL CONSULTAR_CASILLA_MAPA      ; 7B1D: cd3e7d
    LD A,(HL)                        ; 7B20: 7e
    CALL DIBUJAR_CASILLA_MAPA        ; 7B21: cde67c
    INC E                            ; 7B24: 1c
    INC E                            ; 7B25: 1c
    CALL CONSULTAR_CASILLA_MAPA      ; 7B26: cd3e7d
    LD A,(HL)                        ; 7B29: 7e
    CALL DIBUJAR_CASILLA_MAPA        ; 7B2A: cde67c
    LD DE,($8166)                    ; 7B2D: ed5b6681
    LD (IX+2),D                      ; 7B31: dd7202
    LD (IX+3),E                      ; 7B34: dd7303
    LD A,$4F                         ; 7B37: 3e4f
; Sesion 8: confirmado el despacho por tipo de entidad (byte en A al
; entrar): ' '($20)->IY=$8959, 'T'($54)->sub-dispatch en ($8157) con
; anchos/altos variables (32-64 bytes, pendiente de nombrar), 'A'($41)
; y 'O'($4F)->sub-dispatch en ($8157)/($8159) respectivamente hacia 8
; sprites de 64 bytes cada uno (SPRITE_JUGADOR_G1_F1.. / SPRITE_MOMIA_
; G1_F1.., ver mas abajo), cualquier otro caracter (por defecto,
; incluido fallthrough)->IY=TABLAS_SPRITE_CASILLA ($8919). Ver
; FINDINGS.md Sesion 8.
DIBUJAR_ENTIDAD:
    PUSH AF                          ; 7B39: f5
    LD A,$10                         ; 7B3A: 3e10
    LD ($7CC6),A                     ; 7B3C: 32c67c
    LD A,$04                         ; 7B3F: 3e04
    LD ($7CD0),A                     ; 7B41: 32d07c
    POP AF                           ; 7B44: f1
    CP $20                           ; 7B45: fe20
    JR Z,$7B5E                       ; 7B47: 2815
    CP $54                           ; 7B49: fe54
    JR Z,$7B65                       ; 7B4B: 2818
    CP $41                           ; 7B4D: fe41
    JP Z,$7C2F                       ; 7B4F: ca2f7c
    CP $4F                           ; 7B52: fe4f
    JP Z,$7C7C                       ; 7B54: ca7c7c
    LD IY,TABLAS_SPRITE_CASILLA       ; 7B57: fd211989
    JP $7CC4                         ; 7B5B: c3c47c
    LD IY,$8959                      ; 7B5E: fd215989
    JP $7CC4                         ; 7B62: c3c47c
    LD A,($8157)                     ; 7B65: 3a5781
    CP $02                           ; 7B68: fe02
    JP C,$7C01                       ; 7B6A: da017c
    JR Z,$7BD1                       ; 7B6D: 2862
    CP $03                           ; 7B6F: fe03
    JR Z,$7BA5                       ; 7B71: 2832
    LD IY,$8A89                      ; 7B73: fd21898a
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
    JP Z,$7CC4                       ; 7B93: cac47c
    LD IY,$8A99                      ; 7B96: fd21998a
    LD A,$07                         ; 7B9A: 3e07
    LD (HL),A                        ; 7B9C: 77
    ADD A,$19                        ; 7B9D: c619
    SBC HL,BC                        ; 7B9F: ed42
    LD (HL),A                        ; 7BA1: 77
    JP $7CC4                         ; 7BA2: c3c47c
    LD IY,$8A29                      ; 7BA5: fd21298a
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
    JP Z,$7CC4                       ; 7BC0: cac47c
    LD IY,$8A49                      ; 7BC3: fd21498a
    LD A,$05                         ; 7BC7: 3e05
    LD (HL),A                        ; 7BC9: 77
    LD A,$20                         ; 7BCA: 3e20
    DEC HL                           ; 7BCC: 2b
    LD (HL),A                        ; 7BCD: 77
    JP $7CC4                         ; 7BCE: c3c47c
    LD IY,$89F9                      ; 7BD1: fd21f989
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
    JP Z,$7CC4                       ; 7BEF: cac47c
    LD IY,$8A09                      ; 7BF2: fd21098a
    LD A,$04                         ; 7BF6: 3e04
    LD (HL),A                        ; 7BF8: 77
    ADD A,$1C                        ; 7BF9: c61c
    SBC HL,BC                        ; 7BFB: ed42
    LD (HL),A                        ; 7BFD: 77
    JP $7CC4                         ; 7BFE: c3c47c
    LD IY,$8999                      ; 7C01: fd219989
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
    JP Z,$7CC4                       ; 7C1E: cac47c
    LD IY,$89B9                      ; 7C21: fd21b989
    LD A,$02                         ; 7C25: 3e02
    LD (HL),A                        ; 7C27: 77
    LD A,$20                         ; 7C28: 3e20
    DEC HL                           ; 7C2A: 2b
    LD (HL),A                        ; 7C2B: 77
    JP $7CC4                         ; 7C2C: c3c47c
    LD A,($8157)                     ; 7C2F: 3a5781
    CP $02                           ; 7C32: fe02
    JR C,$7C6C                       ; 7C34: 3836
    JR Z,$7C5C                       ; 7C36: 2824
    CP $03                           ; 7C38: fe03
    JR Z,$7C4C                       ; 7C3A: 2810
    LD IY,SPRITE_JUGADOR_G4_F1        ; 7C3C: fd21398c
    LD A,($8158)                     ; 7C40: 3a5881
    OR A                             ; 7C43: b7
    JR Z,$7CC4                       ; 7C44: 287e
    LD IY,SPRITE_JUGADOR_G4_F2        ; 7C46: fd21798c
    JR $7CC4                         ; 7C4A: 1878
    LD IY,SPRITE_JUGADOR_G3_F1        ; 7C4C: fd21b98b
    LD A,($8158)                     ; 7C50: 3a5881
    OR A                             ; 7C53: b7
    JR Z,$7CC4                       ; 7C54: 286e
    LD IY,SPRITE_JUGADOR_G3_F2        ; 7C56: fd21f98b
    JR $7CC4                         ; 7C5A: 1868
    LD IY,SPRITE_JUGADOR_G2_F1        ; 7C5C: fd21398b
    LD A,($8158)                     ; 7C60: 3a5881
    OR A                             ; 7C63: b7
    JR Z,$7CC4                       ; 7C64: 285e
    LD IY,SPRITE_JUGADOR_G2_F2        ; 7C66: fd21798b
    JR $7CC4                         ; 7C6A: 1858
    LD IY,SPRITE_JUGADOR_G1_F1        ; 7C6C: fd21b98a
    LD A,($8158)                     ; 7C70: 3a5881
    OR A                             ; 7C73: b7
    JR Z,$7CC4                       ; 7C74: 284e
    LD IY,SPRITE_JUGADOR_G1_F2        ; 7C76: fd21f98a
    JR $7CC4                         ; 7C7A: 1848
    LD A,(IX+4)                      ; 7C7C: dd7e04
    XOR $01                          ; 7C7F: ee01
    LD (IX+4),A                      ; 7C81: dd7704
    PUSH AF                          ; 7C84: f5
    LD A,($8159)                     ; 7C85: 3a5981
    CP $02                           ; 7C88: fe02
    JR C,$7CB9                       ; 7C8A: 382d
    JR Z,$7CAC                       ; 7C8C: 281e
    CP $03                           ; 7C8E: fe03
    JR Z,$7C9F                       ; 7C90: 280d
    POP AF                           ; 7C92: f1
    LD IY,SPRITE_MOMIA_G4_F1          ; 7C93: fd21398e
    JR Z,$7CC4                       ; 7C97: 282b
    LD IY,SPRITE_MOMIA_G4_F2          ; 7C99: fd21798e
    JR $7CC4                         ; 7C9D: 1825
    POP AF                           ; 7C9F: f1
    LD IY,SPRITE_MOMIA_G3_F1          ; 7CA0: fd21b98d
    JR Z,$7CC4                       ; 7CA4: 281e
    LD IY,SPRITE_MOMIA_G3_F2          ; 7CA6: fd21f98d
    JR $7CC4                         ; 7CAA: 1818
    POP AF                           ; 7CAC: f1
    LD IY,SPRITE_MOMIA_G2_F1          ; 7CAD: fd21398d
    JR Z,$7CC4                       ; 7CB1: 2811
    LD IY,SPRITE_MOMIA_G2_F2          ; 7CB3: fd21798d
    JR $7CC4                         ; 7CB7: 180b
    POP AF                           ; 7CB9: f1
    LD IY,SPRITE_MOMIA_G1_F1          ; 7CBA: fd21b98c
    JR Z,$7CC4                       ; 7CBE: 2804
    LD IY,SPRITE_MOMIA_G1_F2          ; 7CC0: fd21f98c
    PUSH DE                          ; 7CC4: d5
    LD B,$10                         ; 7CC5: 0610
    EX DE,HL                         ; 7CC7: eb
    LD ($8647),HL                    ; 7CC8: 224786
    PUSH BC                          ; 7CCB: c5
    CALL CASILLA_A_DIRECCION_PANTALLA ; 7CCC: cd927e
    LD B,$04                         ; 7CCF: 0604
    LD A,(IY+0)                      ; 7CD1: fd7e00
    INC IY                           ; 7CD4: fd23
    LD (HL),A                        ; 7CD6: 77
    INC HL                           ; 7CD7: 23
    DJNZ $7CD1                       ; 7CD8: 10f7
    LD HL,($8647)                    ; 7CDA: 2a4786
    INC H                            ; 7CDD: 24
    LD ($8647),HL                    ; 7CDE: 224786
    POP BC                           ; 7CE1: c1
    DJNZ $7CCB                       ; 7CE2: 10e7
    POP DE                           ; 7CE4: d1
    RET                              ; 7CE5: c9
DIBUJAR_CASILLA_MAPA:
    CP $02                           ; 7CE6: fe02
    JR C,$7D2E                       ; 7CE8: 3844
    JR Z,$7D28                       ; 7CEA: 283c
    CP $04                           ; 7CEC: fe04
    JR C,$7D22                       ; 7CEE: 3832
    JR Z,$7D1C                       ; 7CF0: 282a
    CP $06                           ; 7CF2: fe06
    JR C,$7D16                       ; 7CF4: 3820
    JR Z,$7D10                       ; 7CF6: 2818
    CP $08                           ; 7CF8: fe08
    JR C,$7D0A                       ; 7CFA: 380e
    JR Z,$7D04                       ; 7CFC: 2806
    LD IY,$8959                      ; 7CFE: fd215989
    JR $7D32                         ; 7D02: 182e
    LD IY,$8A89                      ; 7D04: fd21898a
    JR $7D32                         ; 7D08: 1828
    LD IY,$8AA9                      ; 7D0A: fd21a98a
    JR $7D32                         ; 7D0E: 1822
    LD IY,$8A69                      ; 7D10: fd21698a
    JR $7D32                         ; 7D14: 181c
    LD IY,$8A79                      ; 7D16: fd21798a
    JR $7D32                         ; 7D1A: 1816
    LD IY,$8A19                      ; 7D1C: fd21198a
    JR $7D32                         ; 7D20: 1810
    LD IY,$89F9                      ; 7D22: fd21f989
    JR $7D32                         ; 7D26: 180a
    LD IY,$89E9                      ; 7D28: fd21e989
    JR $7D32                         ; 7D2C: 1804
    LD IY,$89D9                      ; 7D2E: fd21d989
    LD A,$08                         ; 7D32: 3e08
    LD ($7CC6),A                     ; 7D34: 32c67c
    LD A,$02                         ; 7D37: 3e02
    LD ($7CD0),A                     ; 7D39: 32d07c
    JR $7CC4                         ; 7D3C: 1886
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
    SBC HL,DE                        ; 7D6B: ed52
    JR C,$7D71                       ; 7D6D: 3802
    JR $7D6B                         ; 7D6F: 18fa
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
    ADD HL,HL                        ; 7D7E: 29
    JR NC,$7D82                      ; 7D7F: 3001
    ADD HL,DE                        ; 7D81: 19
    DJNZ $7D7E                       ; 7D82: 10fa
    RET                              ; 7D84: c9
DIBUJAR_TRAMO_MARCO_1:
    LD ($8645),HL                    ; 7D85: 224586
    CALL RELLENAR_MARCO_SOLIDO       ; 7D88: cded7d
    LD HL,($8645)                    ; 7D8B: 2a4586
    LD BC,$0602                      ; 7D8E: 010206
    ADD HL,BC                        ; 7D91: 09
    LD ($8645),HL                    ; 7D92: 224586
    LD IY,TABLA_MARCO_1               ; 7D95: fd217d87
    CALL COPIAR_BLOQUE_A_LIENZO      ; 7D99: cd737e
    RET                              ; 7D9C: c9
DIBUJAR_TRAMO_MARCO_2:
    LD ($8645),HL                    ; 7D9D: 224586
    CALL RELLENAR_MARCO_SOLIDO       ; 7DA0: cded7d
    LD HL,($8645)                    ; 7DA3: 2a4586
    LD BC,$0602                      ; 7DA6: 010206
    ADD HL,BC                        ; 7DA9: 09
    LD ($8645),HL                    ; 7DAA: 224586
    LD IY,TABLA_MARCO_2               ; 7DAD: fd21c587
    CALL COPIAR_BLOQUE_A_LIENZO      ; 7DB1: cd737e
    RET                              ; 7DB4: c9
DIBUJAR_TRAMO_MARCO_3:
    LD ($8645),HL                    ; 7DB5: 224586
    CALL RELLENAR_MARCO_SOLIDO       ; 7DB8: cded7d
    LD HL,($8645)                    ; 7DBB: 2a4586
    LD BC,$0602                      ; 7DBE: 010206
    ADD HL,BC                        ; 7DC1: 09
    LD ($8645),HL                    ; 7DC2: 224586
    LD IY,TABLA_MARCO_3               ; 7DC5: fd210d88
    CALL COPIAR_BLOQUE_A_LIENZO      ; 7DC9: cd737e
    RET                              ; 7DCC: c9
DIBUJAR_TRAMO_MARCO_4:
    LD ($8645),HL                    ; 7DCD: 224586
    CALL RELLENAR_MARCO_MEDIO        ; 7DD0: cde57d
    LD HL,($8645)                    ; 7DD3: 2a4586
    LD BC,$0602                      ; 7DD6: 010206
    ADD HL,BC                        ; 7DD9: 09
    LD ($8645),HL                    ; 7DDA: 224586
    LD IY,TABLA_MARCO_4               ; 7DDD: fd215588
    CALL COPIAR_BLOQUE_A_LIENZO      ; 7DE1: cd737e
    RET                              ; 7DE4: c9
; ---- RELLENAR_MARCO_MEDIO / RELLENAR_MARCO_SOLIDO / RELLENAR_MARCO_VACIO /
; RELLENAR_MARCO_DIAGONAL_1..6 / RELLENAR_MARCO_DIAGONAL_BUCLE /
; PREPARAR_RELLENO_MASCARA_UNICA / RELLENAR_FILAS_MASCARA ----
; Cierra el hueco $7DE5-$7E72 (Sesion 7): son los destinos de las
; CALL $7DED/CALL $7DE5 de DIBUJAR_TRAMO_MARCO_1..4 (arriba), ahora
; ya nombrados. CORRIGE la hipotesis previa de FINDINGS.md/
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
; byte). Confianza MEDIA en el papel visual exacto: hipotesis de que
; rellenan una casilla/tramo del marco decorativo con un patron
; solido/vacio/a medias (las 3 primeras) o con una veta a rayas
; alternas de 24x10 bytes (las 6 diagonales) -- sin confirmar en
; emulador. RELLENAR_MARCO_MEDIO y RELLENAR_MARCO_SOLIDO son las
; unicas llamadas desde codigo ya conocido (DIBUJAR_TRAMO_MARCO_4 y
; DIBUJAR_TRAMO_MARCO_1/2/3); RELLENAR_MARCO_VACIO y las 6 variantes
; RELLENAR_MARCO_DIAGONAL_1..6 no tienen todavia un llamador conocido
; dentro de lo ya reconstruido -- pendiente localizarlo en uno de los
; huecos INCBIN restantes. Ver FINDINGS.md Sesion 7.
RELLENAR_MARCO_MEDIO:
    LD A,$0F                         ; 7DE5: 3e0f
    LD ($864A),A                     ; 7DE7: 324a86
    JP PREPARAR_RELLENO_MASCARA_UNICA ; 7DEA: c34f7e
RELLENAR_MARCO_SOLIDO:
    LD A,$FF                         ; 7DED: 3eff
    LD ($864A),A                     ; 7DEF: 324a86
    JP PREPARAR_RELLENO_MASCARA_UNICA ; 7DF2: c34f7e
RELLENAR_MARCO_VACIO:
    XOR A                            ; 7DF5: af
    LD ($864A),A                     ; 7DF6: 324a86
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
    LD ($864A),A                     ; 7E30: 324a86
    LD A,$0A                         ; 7E33: 3e0a
    LD ($8649),A                     ; 7E35: 324986
    LD ($8647),HL                    ; 7E38: 224786
    LD B,$18                         ; 7E3B: 0618
    PUSH BC                          ; 7E3D: c5
    LD B,$01                         ; 7E3E: 0601
    CALL RELLENAR_FILAS_MASCARA      ; 7E40: cd597e
    LD A,($864A)                     ; 7E43: 3a4a86
    XOR $0F                          ; 7E46: ee0f
    LD ($864A),A                     ; 7E48: 324a86
    POP BC                           ; 7E4B: c1
    DJNZ $7E3D                       ; 7E4C: 10ef
    RET                              ; 7E4E: c9
PREPARAR_RELLENO_MASCARA_UNICA:
    LD A,$0A                         ; 7E4F: 3e0a
    LD ($8649),A                     ; 7E51: 324986
    LD B,$18                         ; 7E54: 0618
    LD ($8647),HL                    ; 7E56: 224786
RELLENAR_FILAS_MASCARA:
    PUSH BC                          ; 7E59: c5
    CALL CASILLA_A_DIRECCION_PANTALLA ; 7E5A: cd927e
    LD A,($8649)                     ; 7E5D: 3a4986
    LD B,A                           ; 7E60: 47
    LD A,($864A)                     ; 7E61: 3a4a86
    LD (HL),A                        ; 7E64: 77
    INC HL                           ; 7E65: 23
    DJNZ $7E64                       ; 7E66: 10fc
    LD HL,($8647)                    ; 7E68: 2a4786
    INC H                            ; 7E6B: 24
    LD ($8647),HL                    ; 7E6C: 224786
    POP BC                           ; 7E6F: c1
    DJNZ RELLENAR_FILAS_MASCARA      ; 7E70: 10e7
    RET                              ; 7E72: c9

; ---- COPIAR_BLOQUE_A_LIENZO / CASILLA_A_DIRECCION_PANTALLA / BORRAR_BLOQUE_ESTADO / BORRAR_RECTANGULO_VENTANA / REPETIR_CARACTER ----
; hipotesis: copia un bloque de 6x12 bytes a un lienzo de trabajo (media);
; indexa la tabla de 200 direcciones de pantalla por fila (alta); borra
; 1182 bytes de estado en $8172 (alta); borra un rectangulo de la
; ventana de texto via el firmware (alta, confirma uso de TXT WIN
; ENABLE/TXT CLEAR WINDOW); repite un caracter N veces (alta). Ver
; FINDINGS.md Sesiones 3-5.
COPIAR_BLOQUE_A_LIENZO:
    LD B,$0C                         ; 7E73: 060c
    LD ($8647),HL                    ; 7E75: 224786
    PUSH BC                          ; 7E78: c5
    CALL CASILLA_A_DIRECCION_PANTALLA ; 7E79: cd927e
    LD B,$06                         ; 7E7C: 0606
    LD A,(IY+0)                      ; 7E7E: fd7e00
    INC IY                           ; 7E81: fd23
    LD (HL),A                        ; 7E83: 77
    INC HL                           ; 7E84: 23
    DJNZ $7E7E                       ; 7E85: 10f7
    LD HL,($8647)                    ; 7E87: 2a4786
    INC H                            ; 7E8A: 24
    LD ($8647),HL                    ; 7E8B: 224786
    POP BC                           ; 7E8E: c1
    DJNZ $7E78                       ; 7E8F: 10e7
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
    ADD IY,DE                        ; 7EC9: fd19
    DJNZ $7EC9                       ; 7ECB: 10fc
    POP DE                           ; 7ECD: d1
    LD A,E                           ; 7ECE: 7b
    INC A                            ; 7ECF: 3c
    SUB L                            ; 7ED0: 95
    LD B,A                           ; 7ED1: 47
    PUSH BC                          ; 7ED2: c5
    LD A,D                           ; 7ED3: 7a
    INC A                            ; 7ED4: 3c
    SUB H                            ; 7ED5: 94
    LD B,A                           ; 7ED6: 47
    LD A,$20                         ; 7ED7: 3e20
    PUSH IY                          ; 7ED9: fde5
    LD (IY+0),A                      ; 7EDB: fd7700
    INC IY                           ; 7EDE: fd23
    DJNZ $7EDB                       ; 7EE0: 10f9
    LD BC,$0028                      ; 7EE2: 012800
    POP IY                           ; 7EE5: fde1
    ADD IY,BC                        ; 7EE7: fd09
    POP BC                           ; 7EE9: c1
    DJNZ $7ED2                       ; 7EEA: 10e6
    POP HL                           ; 7EEC: e1
    CALL FIRM_TXT_WIN_ENABLE         ; 7EED: cd66bb
    CALL FIRM_TXT_CLEAR_WINDOW       ; 7EF0: cd6cbb
    RET                              ; 7EF3: c9
REPETIR_CARACTER:
    LD B,(HL)                        ; 7EF4: 46
    INC HL                           ; 7EF5: 23
    LD A,(HL)                        ; 7EF6: 7e
    CALL FIRM_TXT_OUTPUT             ; 7EF7: cd5abb
    DJNZ $7EF5                       ; 7EFA: 10f9
    RET                              ; 7EFC: c9
; ---- TEXTO_MENU_OPCIONES / FLAG_MUSICA_FONDO / FLAG_EFECTOS_SONIDO /
; ENVOLVENTE_AMPLITUD_1..3 / ENVOLVENTE_TONO_1..3 / TEXTO_HISTORIA_ATRACCION /
; TABLA_DESCONOCIDA_GAME_OVER / VARIABLES_INICIO_ENTIDADES / ARRAY_ENTIDADES /
; ESTADO_PARTIDA / TABLA_OFFSETS_DIAMANTE / VARIABLES_DIBUJO_MARCO /
; TABLA_PARAMETROS_TRANSICION_PUNTUACIONES / TEXTO_TABLA_PUNTUACIONES /
; TEXTO_MENU_PRINCIPAL / TABLA_POSICIONES_DECIMALES / TEXTO_COPYRIGHT_Y_HUD /
; TABLA_MARCO_1..4 / DATOS_MARCO_Y_TEXTO_CONTINUAR / TABLAS_SPRITE_CASILLA /
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
; las 4 tablas del marco decorativo -- offsets exactos de 72 bytes
; confirmados por las 4 LD IY,$87xx de DIBUJAR_TRAMO_MARCO_1..4 --,
; el bloque de estado que borra BORRAR_BLOQUE_ESTADO, el array de
; entidades de $816D, y el guion de sonido circular de $905C).
; Algunas tablas menores (offsets tipo "diamante" en $8611, parametros
; antes de HI-SCORE-TABLE, cola de bytes tras "GAME OVER", las
; ~29 tablas de sprite/casilla de $8919) quedan como bytes en bruto
; con hipotesis de confianza baja/media -- limites confirmados por
; los huecos de texto/tablas vecinas, contenido interno sin descifrar
; del todo. Ver FINDINGS.md Sesion 8.
TEXTO_MENU_OPCIONES:
    DB $4E,$0E,$01,$0F,$02,$0C,$1F,$0C,$03 ; 7EFD
    DB "OH MUMMY - OPTIONS"             ; 7F06
    DB $1F,$09,$07,$0F,$00             ; 7F18
    DB "SPEED OF GAME (1-5) ?"          ; 7F1D
    DB $1F,$0C,$08,$0F,$03             ; 7F32
    DB "(1 IS FASTEST)"                 ; 7F37
    DB $1F,$1F,$07,$8F,$08,$0F,$00,$35,$1F,$08,$0B ; 7F45
    DB "DIFFICULTY LEVEL (1-5) ?"       ; 7F50
    DB $1F,$0C,$0C,$0F,$03             ; 7F68
    DB "(1 IS HARDEST)"                 ; 7F6D
    DB $1F,$21,$0B,$8F,$08,$0F,$00,$1E,$1F,$08,$0F ; 7F7B
    DB "BACKGROUND MUSIC (Y-N) ? "      ; 7F86
    DB $8F,$08,$1B,$1F,$09,$13         ; 7F9F
    DB "SOUND EFFECTS (Y-N) ? "         ; 7FA5
    DB $8F,$08,$03                     ; 7FBB
    DB "YES"                            ; 7FBE
    DB $02,$4E,$4F                     ; 7FC1
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
    DB $FC,$FF,$24,$0E                               ; 8019
; Texto literal confirmado (attract mode / pantalla "periodico"):
; "STOP PRESS!! British Museum today announced successful excavation
; of ancient Egyptian pyramid. Leader of team given bonus for his
; efforts of 200 points. extra man for next dig. Press "C" or Fire
; Button to Continue" ... "GAME OVER".
TEXTO_HISTORIA_ATRACCION:
    DB $01,$0F,$02,$0C,$1F,$07,$05     ; 801D
    DB "!!  S T O P    P R E S S  !!#"  ; 8024
    DB $0F,$00,$1F,$07,$0A             ; 8041
    DB "British Museum today announced#" ; 8046
    DB $1F,$05,$0B                     ; 8065
    DB "successful excavation of ancient" ; 8068
    DB $14,$1F,$05,$0C                 ; 8088
    DB "Egyptian pyramid."              ; 808C
    DB $1A,$0F,$03,$1F,$07,$11         ; 809D
    DB "Leader of team given "          ; 80A3
    DB $09                             ; 80B8
    DB "bonus for"                      ; 80B9
    DB $1D,$1F,$05,$12                 ; 80C2
    DB "his efforts of 200 points."     ; 80C6
    DB $09                             ; 80E0
    DB "extra man"                      ; 80E1
    DB $10,$1F,$05,$12                 ; 80EA
    DB "for next dig.)"                 ; 80EE
    DB $0F,$02,$1F,$03,$17             ; 80FC
    DB "Press "                         ; 8101
    DB $22,$43,$22                     ; 8107
    DB " or Fire Button to Continue"    ; 810A
    DB $07,$0E,$01,$0F,$02,$1F,$0C,$0D ; 8125
    DB "GAME OVER"                      ; 812D
    DB $00,$00,$00,$00                 ; 8136
; Hipotesis baja: tabla de valores pequenos tras el texto GAME OVER,
; con progresiones aritmeticas visibles en varios tramos (+/-6, +/-14,
; +/-40 segun el tramo) -- posibles umbrales de puntuacion/bonus, sin
; ningun CALL/LD conocido que la referencie todavia.
TABLA_DESCONOCIDA_GAME_OVER:
    DB $18,$40,$68,$90,$B8,$04,$12,$20,$2E,$3C,$4A,$45,$48,$16,$4B,$47 ; 813A
    DB $49,$1E,$4A,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00 ; 814A
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
; Hipotesis baja-media: pares de bytes con patron ascendente/
; descendente de paso 6 (posibles offsets de pantalla en forma de
; diamante/piramide, byte alto $B8/$90/$A8), sin CALL/LD conocido
; que la referencie todavia.
TABLA_OFFSETS_DIAMANTE:
    DB $04,$B8,$4A,$B8,$0A,$B8,$44,$B8,$10,$B8,$3E,$B8,$16,$B8,$38,$B8 ; 8611
    DB $1C,$B8,$32,$B8,$22,$B8,$2C,$B8,$0A,$90,$44,$90,$10,$90,$3E,$90 ; 8621
    DB $16,$90,$38,$90,$1C,$90,$32,$90,$16,$A8,$38,$A8,$1C,$A8,$32,$A8 ; 8631
    DB $22,$A8,$2C,$A8                               ; 8641
; $8645 y $8647: variables HL usadas por DIBUJAR_TRAMO_MARCO_1..4
; ("LD ($8645),HL") y por COPIAR_BLOQUE_A_LIENZO/RELLENAR_FILAS_MASCARA
; ("LD ($8647),HL"). $8649/$864A: variables de 1 byte usadas por
; RELLENAR_FILAS_MASCARA (fila/mascara). Reserva de variable, el
; valor de fichero es irrelevante en tiempo de ejecucion.
VARIABLES_DIBUJO_MARCO:
    DB $00,$00,$00,$00,$00,$00                       ; 8645
; Hipotesis baja: pequena tabla de parametros justo antes de
; TEXTO_TABLA_PUNTUACIONES, con grupos cortos repetidos -- posible
; animacion/temporizado de la transicion a la pantalla de
; puntuaciones, sin descifrar.
TABLA_PARAMETROS_TRANSICION_PUNTUACIONES:
    DB $03,$04,$01,$02,$03,$04,$01,$02,$19,$1D,$18,$18,$1C,$00,$18,$18 ; 864B
    DB $1C,$01,$00,$00,$1C,$02,$0F,$0F,$1C,$03,$0B,$0B,$0E,$00,$04,$01 ; 865B
    DB $0F,$01,$08,$1D,$0B,$0B,$0E,$03,$0C,$0E,$02,$15,$0E,$00,$0F,$01 ; 866B
    DB $1F,$0E,$07                                   ; 867B
; Texto literal confirmado: "HI-SCORE-TABLE" + 5 rangos con su
; umbral de puntuacion en 16 bits little-endian intercalado --
; "Stupendous !"=2000, "Excellent ! "=1500, "Very Good ! "=1000,
; "Quite Good  "=500 (valores leidos directamente de los bytes,
; sin CALL que los consuma localizado todavia).
TEXTO_TABLA_PUNTUACIONES:
    DB "HI-SCORE-TABLE"                 ; 867E
    DB $C4,$09,$0F,$1F,$12,$0A         ; 868C
    DB "Stupendous !"                   ; 8692
    DB $D0,$07,$0F,$1F,$12,$0C         ; 869E
    DB "Excellent ! "                   ; 86A4
    DB $DC,$05,$0F,$1F,$12,$0E         ; 86B0
    DB "Very Good ! "                   ; 86B6
    DB $E8,$03,$0F,$1F,$12,$10         ; 86C2
    DB "Quite Good  "                   ; 86C8
    DB $F4,$01,$11,$1F,$12,$12         ; 86D4
    DB "Not Bad     "                   ; 86DA
    DB $0E,$03,$27                     ; 86E6
; Texto literal confirmado: "I-Instructions  O-Options  P-Play  ?"
; (coincide con MOVER_INDICADOR_MENU/ANIMAR_OPCION_MENU) y "Well
; done !!  Please enter your name" (pantalla de posicion en el
; ranking).
TEXTO_MENU_PRINCIPAL:
    DB $1F,$03,$19                     ; 86E9
    DB "I-Instructions  O-Options  P-Play  ?'" ; 86EC
    DB $1F,$03,$19                     ; 8711
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
; "SCORE"/"MEN". Confirmado por REPETIR_CARACTER: $6066 LD HL,$8653
; y $60A1 LD HL,$8740 leen (cuenta,caracter) de aqui dentro.
TEXTO_COPYRIGHT_Y_HUD:
    DB $23,$1F,$06,$02,$22             ; 8740
    DB "OH MUMMY"                       ; 8745
    DB $22,$20,$A4                     ; 874D
    DB " 1984 GEM SOFTWARE"             ; 8750
    DB $0E,$01,$18,$1D,$18,$18,$0E,$00,$0F,$02,$0C,$1F ; 8762
    DB $03,$01                         ; 876E
    DB "SCORE"                          ; 8770
    DB $1F,$17,$01                     ; 8775
    DB "MEN"                            ; 8778
    DB $0F,$03                         ; 877B
; Confirmado por DIBUJAR_TRAMO_MARCO_1: LD IY,$877D. 72 bytes exactos
; = lo que consume COPIAR_BLOQUE_A_LIENZO (12 filas x 6 bytes).
; Mascara/bitmap de un tramo del marco decorativo, sin decodificar
; a nivel de pixel.
TABLA_MARCO_1:
    DB $33,$FF,$FF,$FF,$CC,$77,$00,$FF,$FF,$00,$00,$33,$00,$00,$00,$01 ; 877D
    DB $08,$01,$00,$00,$00,$00,$07,$0E,$00,$00,$00,$00,$00,$00,$00,$00 ; 878D
    DB $00,$00,$00,$00,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F ; 879D
    DB $88,$00,$00,$00,$00,$11,$EE,$77,$FF,$FF,$EE,$77,$CC,$00,$00,$00 ; 87AD
    DB $00,$33,$EE,$77,$FF,$FF,$EE,$77               ; 87BD
; Confirmado por DIBUJAR_TRAMO_MARCO_2: LD IY,$87C5. 72 bytes exactos.
TABLA_MARCO_2:
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$CC,$77,$FF,$FF,$FF,$FF ; 87C5
    DB $88,$33,$FF,$FF,$FF,$FF,$11,$11,$00,$00,$00,$00,$33,$88,$00,$00 ; 87D5
    DB $00,$00,$33,$88,$CC,$11,$FF,$FF,$11,$11,$88,$00,$FF,$FF,$88,$33 ; 87E5
    DB $88,$88,$FF,$FF,$CC,$77,$AA,$AA,$FF,$FF,$FF,$FF,$BB,$EE,$FF,$FF ; 87F5
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF               ; 8805
; Confirmado por DIBUJAR_TRAMO_MARCO_3: LD IY,$880D. 72 bytes exactos.
TABLA_MARCO_3:
    DB $FF,$F8,$FF,$FF,$F1,$FF,$FF,$FA,$F7,$FE,$F5,$FF,$FF,$FA,$F7,$FE ; 880D
    DB $F5,$FF,$F9,$FA,$F8,$F1,$F5,$F9,$F6,$F2,$00,$00,$F4,$F6,$F7,$FA ; 881D
    DB $00,$00,$F5,$FE,$F7,$FA,$00,$00,$F5,$FE,$F6,$F2,$00,$00,$F4,$F6 ; 882D
    DB $F9,$FA,$F8,$F1,$F5,$F9,$FF,$FA,$F7,$FE,$F5,$FF,$FF,$FA,$F7,$FE ; 883D
    DB $F5,$FF,$FF,$F8,$FF,$FF,$F1,$FF               ; 884D
; Confirmado por DIBUJAR_TRAMO_MARCO_4: LD IY,$8855. 72 bytes exactos.
TABLA_MARCO_4:
    DB $0F,$00,$00,$00,$00,$0F,$0E,$03,$0F,$0F,$0C,$07,$0C,$0C,$C3,$CF ; 8855
    DB $03,$03,$09,$0F,$0F,$0F,$0F,$09,$00,$00,$00,$00,$00,$00,$30,$F0 ; 8865
    DB $F0,$F0,$F0,$C0,$08,$00,$00,$00,$00,$01,$09,$0F,$0F,$0F,$0F,$09 ; 8875
    DB $0C,$0C,$CC,$33,$03,$03,$0C,$0C,$CC,$33,$03,$03,$0E,$07,$0F,$0F ; 8885
    DB $0E,$07,$0E,$00,$00,$00,$00,$07               ; 8895
; Hipotesis baja-media: mezcla sin separar con precision -- mas bytes
; de mascara/grafico de estilo similar a las 4 tablas de marco de
; arriba, seguidos del texto literal confirmado '"C" TO CONTINUE'.
DATOS_MARCO_Y_TEXTO_CONTINUAR:
    DB $68,$1F,$0C,$0B,$0E,$00,$0F,$02,$88,$8C,$88,$88,$20,$20,$8C,$8C ; 889D
    DB $84,$84,$84,$8C,$8C,$84,$8C,$8C,$84,$84,$84,$08,$08,$08,$08,$08 ; 88AD
    DB $08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$0A,$8A ; 88BD
    DB $8A,$8A,$8F,$20,$20,$87,$87,$85,$8D,$85,$87,$87,$85,$87,$87,$85 ; 88CD
    DB $8F,$85,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08 ; 88DD
    DB $08,$08,$08,$08,$08,$0A,$82,$83,$82,$82,$20,$20,$81,$20,$81,$83 ; 88ED
    DB $81,$81,$20,$81,$81,$20,$81,$20,$81,$12,$1F,$0E,$11,$22,$43,$22 ; 88FD
    DB $20,$54,$4F,$20,$43,$4F,$4E,$54,$49,$4E,$55,$45 ; 890D
; Confirmado que empieza aqui: DIBUJAR_ENTIDAD hace LD IY,$8919
; ($7B57). Hipotesis media: ~20 tablas de sprite de 4x16 bytes
; (dispatcher de DIBUJAR_ENTIDAD, por tipo+direccion+fotograma) + 9
; tablas de casilla de 2x8 bytes (DIBUJAR_CASILLA_MAPA) -- limites de
; cada tabla individual sin desglosar todavia. Patron de bytes
; consistente con mascaras de pantalla CPC modo 1 (bloques solidos
; $00/$FF/$F0 alternando con datos variables).
TABLAS_SPRITE_CASILLA:
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 8919
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 8929
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 8939
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 8949
    DB $F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0 ; 8959
    DB $F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0 ; 8969
    DB $F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0 ; 8979
    DB $F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0 ; 8989
    DB $F0,$87,$F0,$F0,$F0,$87,$F0,$F0,$F0,$96,$F0,$F0,$F0,$96,$F0,$F0 ; 8999
    DB $F0,$F0,$F0,$F0,$F0,$96,$F0,$F0,$F0,$96,$F0,$F0,$F0,$96,$F0,$F0 ; 89A9
    DB $F0,$F0,$1E,$F0,$F0,$F0,$1E,$F0,$F0,$F0,$96,$F0,$F0,$F0,$96,$F0 ; 89B9
    DB $F0,$F0,$F0,$F0,$F0,$F0,$96,$F0,$F0,$F0,$96,$F0,$F0,$F0,$F0,$F0 ; 89C9
    DB $F0,$87,$F0,$87,$F0,$96,$F0,$96,$F0,$F0,$F0,$96,$F0,$96,$F0,$F0 ; 89D9
    DB $1E,$F0,$1E,$F0,$96,$F0,$96,$F0,$F0,$F0,$96,$F0,$96,$F0,$F0,$F0 ; 89E9
    DB $F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$96,$0F,$96,$0F,$F0,$C3 ; 89F9
    DB $F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0 ; 8A09
    DB $F0,$C3,$96,$0F,$96,$0F,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0 ; 8A19
    DB $F0,$F0,$F0,$F0,$F0,$96,$F0,$F0,$F0,$96,$F0,$F0,$F0,$F0,$F0,$F0 ; 8A29
    DB $F0,$96,$F0,$F0,$F0,$96,$F0,$F0,$F0,$87,$F0,$F0,$F0,$87,$F0,$F0 ; 8A39
    DB $F0,$F0,$F0,$F0,$F0,$F0,$96,$F0,$F0,$F0,$96,$F0,$F0,$F0,$F0,$F0 ; 8A49
    DB $F0,$F0,$96,$F0,$F0,$F0,$96,$F0,$F0,$F0,$1E,$F0,$F0,$F0,$1E,$F0 ; 8A59
    DB $F0,$F0,$F0,$96,$F0,$96,$F0,$F0,$F0,$96,$F0,$96,$F0,$87,$F0,$87 ; 8A69
    DB $F0,$F0,$96,$F0,$96,$F0,$F0,$F0,$96,$F0,$96,$F0,$1E,$F0,$1E,$F0 ; 8A79
    DB $F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$0F,$96,$0F,$96,$3C,$F0 ; 8A89
    DB $F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0 ; 8A99
    DB $3C,$F0,$0F,$96,$0F,$96,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0 ; 8AA9
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
    DB $F0,$F0,$F0,$F0,$F0,$F7,$FE,$F0,$F0,$FF,$FF,$F0,$F0,$7F,$EF,$F0 ; 8AB9
    DB $F0,$0C,$03,$F0,$F0,$86,$16,$78,$E0,$77,$CC,$70,$C0,$77,$CC,$70 ; 8AC9
    DB $C0,$77,$EE,$70,$C0,$77,$FF,$F0,$C3,$FE,$FF,$F0,$F1,$FE,$FF,$F0 ; 8AD9
    DB $E1,$1E,$FF,$F0,$F0,$1E,$EF,$F0,$F0,$F0,$0F,$F0,$F0,$F0,$1E,$F0 ; 8AE9
SPRITE_JUGADOR_G1_F2:
    DB $F0,$F0,$F0,$F0,$F0,$F7,$FE,$F0,$F0,$FF,$FF,$F0,$F0,$7F,$EF,$F0 ; 8AF9
    DB $F0,$0C,$03,$F0,$E1,$86,$16,$F0,$E0,$33,$EE,$70,$E0,$33,$EE,$30 ; 8B09
    DB $E0,$77,$EE,$30,$F0,$FF,$EE,$30,$F0,$FF,$F7,$3C,$F0,$FF,$F7,$F8 ; 8B19
    DB $F0,$FF,$87,$78,$F0,$7F,$87,$F0,$F0,$0F,$F0,$F0,$F0,$87,$F0,$F0 ; 8B29
SPRITE_JUGADOR_G2_F1:
    DB $F0,$F0,$F0,$F0,$F0,$F7,$FE,$F0,$F0,$FF,$FF,$FC,$F0,$EE,$25,$F0 ; 8B39
    DB $F0,$80,$0F,$3C,$F0,$E6,$2D,$F0,$F0,$11,$9E,$F0,$F0,$00,$FE,$F0 ; 8B49
    DB $F0,$88,$00,$3C,$F0,$CC,$00,$3C,$F1,$FF,$FB,$F0,$F3,$FF,$F7,$F8 ; 8B59
    DB $D3,$FE,$FF,$F8,$87,$FC,$F7,$FC,$C3,$78,$C3,$3C,$E1,$3C,$C3,$1E ; 8B69
SPRITE_JUGADOR_G2_F2:
    DB $F0,$F0,$F0,$F0,$F0,$F7,$FE,$F0,$F0,$FF,$FF,$FC,$F0,$EE,$25,$F0 ; 8B79
    DB $F0,$80,$0F,$3C,$F0,$E6,$2D,$F0,$F0,$11,$9E,$F0,$E0,$33,$FE,$F0 ; 8B89
    DB $E0,$00,$6F,$F0,$F0,$89,$2F,$F0,$F0,$FF,$7E,$F0,$F0,$F7,$FC,$F0 ; 8B99
    DB $F0,$F3,$FC,$F0,$F0,$F3,$FC,$F0,$F0,$C3,$3C,$F0,$F0,$C3,$1E,$F0 ; 8BA9
SPRITE_JUGADOR_G3_F1:
    DB $F0,$F0,$F0,$F0,$F0,$F7,$FE,$F0,$F0,$FF,$FF,$F0,$F0,$7F,$EF,$F0 ; 8BB9
    DB $F0,$7F,$EF,$F0,$F0,$97,$9E,$F0,$F0,$03,$2E,$70,$E0,$67,$6E,$30 ; 8BC9
    DB $E0,$77,$EE,$33,$E1,$FF,$EF,$30,$F0,$FF,$E7,$78,$F0,$FF,$F7,$F8 ; 8BD9
    DB $F0,$FF,$87,$78,$F0,$EF,$C3,$78,$F0,$0F,$F0,$F0,$F0,$1E,$F0,$F0 ; 8BE9
SPRITE_JUGADOR_G3_F2:
    DB $F0,$F0,$F0,$F0,$F0,$F7,$FE,$F0,$F0,$FF,$FF,$F0,$F0,$7F,$EF,$F0 ; 8BF9
    DB $F0,$7F,$EF,$F0,$F0,$97,$9E,$F0,$E0,$47,$0C,$F0,$C0,$67,$6E,$70 ; 8C09
    DB $C0,$77,$EE,$70,$C0,$7F,$FF,$78,$E1,$7E,$FF,$F0,$F1,$FE,$FF,$F0 ; 8C19
    DB $E1,$1E,$FF,$F0,$E1,$3C,$7F,$F0,$F0,$F0,$0F,$F0,$F0,$F0,$87,$F0 ; 8C29
SPRITE_JUGADOR_G4_F1:
    DB $F0,$F0,$F0,$F0,$F0,$F7,$FE,$F0,$F3,$FF,$FF,$F0,$F0,$4A,$77,$F0 ; 8C39
    DB $C3,$0F,$10,$F0,$F0,$4B,$76,$F0,$F0,$97,$88,$F0,$F0,$F7,$00,$F0 ; 8C49
    DB $C3,$00,$11,$F0,$C3,$00,$33,$F0,$F0,$FD,$FF,$F8,$F1,$FE,$FF,$FC ; 8C59
    DB $F1,$FF,$F7,$BC,$F3,$FE,$F3,$1E,$C3,$3C,$E1,$3C,$87,$3C,$C3,$78 ; 8C69
SPRITE_JUGADOR_G4_F2:
    DB $F0,$F0,$F0,$F0,$F0,$F7,$FE,$F0,$F3,$FF,$FF,$F0,$F0,$4A,$77,$F0 ; 8C79
    DB $C3,$0F,$10,$F0,$F0,$4B,$76,$F0,$F0,$97,$88,$F0,$F0,$F7,$CC,$70 ; 8C89
    DB $F0,$6F,$00,$70,$F0,$4F,$19,$F0,$F0,$E7,$FF,$F0,$F0,$F3,$FE,$F0 ; 8C99
    DB $F0,$F3,$FC,$F0,$F0,$F3,$FC,$F0,$F0,$C3,$3C,$F0,$F0,$87,$3C,$F0 ; 8CA9
SPRITE_MOMIA_G1_F1:
    DB $F0,$F0,$F0,$F0,$E0,$20,$40,$70,$E0,$40,$20,$70,$E0,$40,$20,$70 ; 8CB9
    DB $E0,$20,$40,$70,$E0,$00,$00,$F0,$F0,$00,$00,$F0,$F0,$00,$10,$F0 ; 8CC9
    DB $F0,$80,$30,$F0,$F0,$80,$30,$F0,$F0,$00,$30,$F0,$F0,$10,$10,$F0 ; 8CD9
    DB $E0,$10,$10,$F0,$E0,$30,$10,$F0,$F0,$F0,$00,$F0,$F0,$F0,$00,$F0 ; 8CE9
SPRITE_MOMIA_G1_F2:
    DB $F0,$F0,$F0,$F0,$E0,$20,$40,$70,$E0,$40,$20,$70,$E0,$40,$20,$70 ; 8CF9
    DB $E0,$20,$40,$70,$F0,$00,$00,$70,$F0,$00,$00,$F0,$F0,$80,$00,$F0 ; 8D09
    DB $F0,$C0,$10,$F0,$F0,$C0,$10,$F0,$F0,$C0,$00,$F0,$F0,$80,$80,$F0 ; 8D19
    DB $F0,$80,$80,$70,$F0,$80,$C0,$70,$F0,$00,$F0,$F0,$F0,$00,$F0,$F0 ; 8D29
SPRITE_MOMIA_G2_F1:
    DB $F0,$F0,$F0,$F0,$F0,$C0,$70,$F0,$F0,$80,$30,$F0,$F0,$80,$30,$F0 ; 8D39
    DB $F0,$C0,$30,$F0,$F0,$80,$70,$F0,$F0,$80,$00,$70,$F0,$A0,$00,$30 ; 8D49
    DB $F0,$80,$B0,$30,$F0,$80,$30,$F0,$F0,$80,$30,$F0,$F0,$00,$30,$F0 ; 8D59
    DB $F0,$10,$10,$F0,$E0,$30,$10,$F0,$E0,$30,$80,$F0,$E0,$10,$80,$70 ; 8D69
SPRITE_MOMIA_G2_F2:
    DB $F0,$F0,$F0,$F0,$F0,$C0,$70,$F0,$F0,$80,$30,$F0,$F0,$80,$30,$F0 ; 8D79
    DB $F0,$C0,$30,$F0,$F0,$80,$70,$F0,$F0,$80,$00,$F0,$F0,$A0,$00,$30 ; 8D89
    DB $F0,$80,$B0,$30,$F0,$80,$30,$F0,$F0,$80,$30,$F0,$F0,$80,$30,$F0 ; 8D99
    DB $F0,$80,$30,$F0,$F0,$80,$30,$F0,$F0,$80,$30,$F0,$F0,$80,$10,$F0 ; 8DA9
SPRITE_MOMIA_G3_F1:
    DB $F0,$F0,$F0,$F0,$F0,$E0,$70,$F0,$F0,$C0,$30,$F0,$F0,$C0,$30,$F0 ; 8DB9
    DB $F0,$C0,$30,$F0,$F0,$00,$10,$F0,$E0,$00,$00,$F0,$E0,$00,$00,$F0 ; 8DC9
    DB $C0,$40,$40,$70,$C0,$80,$20,$70,$F0,$00,$30,$F0,$F0,$10,$10,$F0 ; 8DD9
    DB $E0,$10,$10,$F0,$E0,$30,$10,$F0,$F0,$F0,$00,$F0,$F0,$F0,$00,$F0 ; 8DE9
SPRITE_MOMIA_G3_F2:
    DB $F0,$F0,$F0,$F0,$F0,$E0,$70,$F0,$F0,$C0,$30,$F0,$F0,$C0,$30,$F0 ; 8DF9
    DB $F0,$C0,$30,$F0,$F0,$80,$00,$F0,$F0,$00,$00,$70,$F0,$00,$00,$70 ; 8E09
    DB $E0,$20,$20,$30,$E0,$40,$10,$30,$F0,$C0,$00,$F0,$F0,$80,$80,$F0 ; 8E19
    DB $F0,$80,$80,$70,$F0,$80,$C0,$70,$F0,$00,$F0,$F0,$F0,$00,$F0,$F0 ; 8E29
SPRITE_MOMIA_G4_F1:
    DB $F0,$F0,$F0,$F0,$F0,$E0,$30,$F0,$F0,$C0,$10,$F0,$F0,$C0,$10,$F0 ; 8E39
    DB $F0,$C0,$30,$F0,$F0,$E0,$10,$F0,$E0,$00,$10,$F0,$C0,$00,$50,$F0 ; 8E49
    DB $C0,$D0,$10,$F0,$F0,$C0,$10,$F0,$F0,$C0,$10,$F0,$F0,$C0,$00,$F0 ; 8E59
    DB $F0,$80,$80,$F0,$F0,$80,$C0,$70,$F0,$10,$C0,$70,$E0,$10,$80,$70 ; 8E69
SPRITE_MOMIA_G4_F2:
    DB $F0,$F0,$F0,$F0,$F0,$E0,$30,$F0,$F0,$C0,$10,$F0,$F0,$C0,$10,$F0 ; 8E79
    DB $F0,$C0,$30,$F0,$F0,$E0,$10,$F0,$E0,$00,$10,$F0,$C0,$00,$50,$F0 ; 8E89
    DB $C0,$D0,$10,$F0,$F0,$C0,$10,$F0,$F0,$C0,$10,$F0,$F0,$C0,$10,$F0 ; 8E99
    DB $F0,$C0,$10,$F0,$F0,$C0,$10,$F0,$F0,$C0,$10,$F0,$F0,$80,$10,$F0 ; 8EA9
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
