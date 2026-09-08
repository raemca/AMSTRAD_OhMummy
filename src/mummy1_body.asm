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
    JR Z,REANUDAR_MENU_TRAS_NOMBRE ; 6344: 2826
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
    CALL REPETIR_CARACTER                   ; 636F: cdf47e
    LD B,$01                     ; 6372: 0601
    CALL ANIMAR_OPCION_MENU                   ; 6374: cdb778
    LD B,$02                     ; 6377: 0602
    CALL ANIMAR_OPCION_MENU                   ; 6379: cdb778
    LD A,($8168)                 ; 637C: 3a6881
    OR A                         ; 637F: b7
    JP Z,DESPACHAR_MENU_PRINCIPAL ; 6380: ca0464
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
; partida, ver mas abajo); I/i -> $68B2 (instrucciones, sin analizar
; todavia); O/o -> PANTALLA_OPCIONES. Sin coincidencia, vuelve a
; REANUDAR_MENU_TRAS_NOMBRE ($6372, dentro de ese bucle) a seguir
; animando y esperando tecla.
DESPACHAR_MENU_PRINCIPAL:
    CALL FIRM_KM_READ_CHAR           ; 6404: cd09bb
    JP NC,$6372                      ; 6407: d27263
    CP $50                           ; 640A: fe50  ; 'P'
    JP Z,$6529                       ; 640C: ca2965
    CP $70                           ; 640F: fe70  ; 'p'
    JP Z,$6529                       ; 6411: ca2965
    CP $49                           ; 6414: fe49  ; 'I'
    JP Z,$68B2                       ; 6416: cab268
    CP $69                           ; 6419: fe69  ; 'i'
    JP Z,$68B2                       ; 641B: cab268
    CP $4F                           ; 641E: fe4f  ; 'O'
    JP Z,PANTALLA_OPCIONES           ; 6420: ca2b64
    CP $6F                           ; 6423: fe6f  ; 'o'
    JP Z,PANTALLA_OPCIONES           ; 6425: ca2b64
    JP $6372                         ; 6428: c37263
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
; Los REPETIR_CARACTER(HL) de este tramo usan como argumento pares de
; bytes que caen DENTRO de TEXTO_MENU_OPCIONES/TEXTO_HISTORIA_ATRACCION
; (p.ej. $7EFD=[$4E,$0E], $7FBD=[$03,'Y']) -- NO imprimen el texto
; literal vecino (REPETIR_CARACTER repite un unico caracter, no recorre
; una cadena: confirmado leyendo su propio codigo, $7EF4-$7EFC). Son
; pares reutilizados a proposito como "contador+caracter" para algun
; adorno visual (posible separador o parpadeo), efecto exacto sin
; verificar en emulador -- confianza baja/media. La impresion real de
; los rotulos "OH MUMMY - OPTIONS"/"SPEED OF GAME..." etc. como texto
; queda sin localizar, pendiente de los tramos siguientes del INCBIN.
PANTALLA_OPCIONES:
    CALL FIRM_KM_READ_CHAR           ; 642B: cd09bb
    JR C,PANTALLA_OPCIONES           ; 642E: 38fb  ; vacia el buffer de teclado antes de dibujar
    LD HL,$7EFD                      ; 6430: 21fd7e  ; TEXTO_MENU_OPCIONES (titulo)
    CALL REPETIR_CARACTER            ; 6433: cdf47e
; -- "SPEED OF GAME (1-5) ?": lee un digito '1'-'5', lo eco a pantalla
; y calcula ($8153) = $0100 + digito*$00E0 --
    CALL ACTUALIZAR_SECUENCIA_SONIDO ; 6436: cdd178
    CALL FIRM_KM_READ_CHAR           ; 6439: cd09bb
    JR NC,$6436                      ; 643C: 30f8
    CP $31                           ; 643E: fe31  ; '1'
    JR C,$6436                       ; 6440: 38f4
    CP $36                           ; 6442: fe36  ; '6' (excluido)
    JR NC,$6436                      ; 6444: 30f0
    CALL FIRM_TXT_OUTPUT             ; 6446: cd5abb  ; eco del digito tecleado
    SUB $30                          ; 6449: d630   ; ASCII -> 1..5
    LD HL,$0100                      ; 644B: 210001
    LD DE,$00E0                      ; 644E: 11e000
    LD B,A                           ; 6451: 47
    ADD HL,DE                        ; 6452: 19
    DJNZ $6452                       ; 6453: 10fd
    LD ($8153),HL                    ; 6455: 225381  ; retardo de partida (ya usado por ANIMAR_OPCION_MENU)
; -- "DIFFICULTY LEVEL (1-5) ?": mismo patron, digito 1-5 -> ($8161) =
; $07F8 duplicado (digito) veces, byte alto --
    LD HL,$7F4C                      ; 6458: 214c7f  ; TEXTO_MENU_OPCIONES+$4F
    CALL REPETIR_CARACTER            ; 645B: cdf47e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ; 645E: cdd178
    CALL FIRM_KM_READ_CHAR           ; 6461: cd09bb
    JR NC,$645E                      ; 6464: 30f8
    CP $31                           ; 6466: fe31
    JR C,$645E                       ; 6468: 38f4
    CP $36                           ; 646A: fe36
    JR NC,$645E                      ; 646C: 30f0
    CALL FIRM_TXT_OUTPUT             ; 646E: cd5abb
    SUB $30                          ; 6471: d630
    LD B,A                           ; 6473: 47
    LD HL,$07F8                      ; 6474: 21f807
    ADD HL,HL                        ; 6477: 29
    DJNZ $6477                       ; 6478: 10fd
    LD A,H                           ; 647A: 7c
    LD ($8161),A                     ; 647B: 326181  ; limite de persecucion IA (ya usado por COLOCAR_ENTIDAD)
; -- "BACKGROUND MUSIC (Y-N) ?": tecla '+' -> 'Y' (y reinicia el guion
; de sonido circular), '.' -> 'N' --
    LD HL,$7F82                      ; 647E: 21827f  ; TEXTO_MENU_OPCIONES+$85
    CALL REPETIR_CARACTER            ; 6481: cdf47e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ; 6484: cdd178
    LD A,$2B                         ; 6487: 3e2b  ; '+'
    CALL FIRM_KM_TEST_KEY            ; 6489: cd1ebb
    JR NZ,$64AB                      ; 648C: 201d
    LD A,$2E                         ; 648E: 3e2e  ; '.'
    CALL FIRM_KM_TEST_KEY            ; 6490: cd1ebb
    JR Z,$6484                       ; 6493: 28ef
    LD A,$4E                         ; 6495: 3e4e  ; 'N'
    LD (FLAG_MUSICA_FONDO),A         ; 6497: 32c47f
    LD HL,$7FC1                      ; 649A: 21c17f  ; TEXTO_MENU_OPCIONES+$C4
    CALL REPETIR_CARACTER            ; 649D: cdf47e
    CALL FIRM_SOUND_RESET            ; 64A0: cda7bc
    LD HL,GUION_SONIDO_CIRCULAR      ; 64A3: 215c90
    LD (PUNTERO_GUION_SONIDO),HL     ; 64A6: 225a90
    JR $64C6                         ; 64A9: 181b
    LD A,(FLAG_MUSICA_FONDO)         ; 64AB: 3ac47f
    CP $4E                           ; 64AE: fe4e  ; 'N'
    JR NZ,$64BB                      ; 64B0: 2009
    CALL FIRM_SOUND_RESET            ; 64B2: cda7bc
    LD HL,GUION_SONIDO_CIRCULAR      ; 64B5: 215c90
    LD (PUNTERO_GUION_SONIDO),HL     ; 64B8: 225a90
    LD A,$59                         ; 64BB: 3e59  ; 'Y'
    LD (FLAG_MUSICA_FONDO),A         ; 64BD: 32c47f
    LD HL,$7FBD                      ; 64C0: 21bd7f  ; TEXTO_MENU_OPCIONES+$C0
    CALL REPETIR_CARACTER            ; 64C3: cdf47e
; -- "SOUND EFFECTS (Y-N) ?": mismo patron '+'/'.', sin reinicio de
; sonido (solo cambia el flag) --
    CALL ACTUALIZAR_SECUENCIA_SONIDO ; 64C6: cdd178
    LD A,$2B                         ; 64C9: 3e2b
    CALL FIRM_KM_TEST_KEY            ; 64CB: cd1ebb
    JR NZ,$64C6                      ; 64CE: 20f6
    LD A,$2E                         ; 64D0: 3e2e
    CALL FIRM_KM_TEST_KEY            ; 64D2: cd1ebb
    JR NZ,$64C6                      ; 64D5: 20ef
    CALL ACTUALIZAR_SECUENCIA_SONIDO ; 64D7: cdd178
    CALL FIRM_KM_READ_CHAR           ; 64DA: cd09bb
    JR C,$64D7                       ; 64DD: 38f8
    LD HL,$7FA1                      ; 64DF: 21a17f  ; TEXTO_MENU_OPCIONES+$A4
    CALL REPETIR_CARACTER            ; 64E2: cdf47e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ; 64E5: cdd178
    LD A,$2B                         ; 64E8: 3e2b
    CALL FIRM_KM_TEST_KEY            ; 64EA: cd1ebb
    JR NZ,$6503                      ; 64ED: 2014
    LD A,$2E                         ; 64EF: 3e2e
    CALL FIRM_KM_TEST_KEY            ; 64F1: cd1ebb
    JR Z,$64E5                       ; 64F4: 28ef
    LD A,$4E                         ; 64F6: 3e4e
    LD (FLAG_EFECTOS_SONIDO),A       ; 64F8: 32c57f
    LD HL,$7FC1                      ; 64FB: 21c17f
    CALL REPETIR_CARACTER            ; 64FE: cdf47e
    JR $650E                         ; 6501: 180b
    LD A,$59                         ; 6503: 3e59
    LD (FLAG_EFECTOS_SONIDO),A       ; 6505: 32c57f
    LD HL,$7FBD                      ; 6508: 21bd7f
    CALL REPETIR_CARACTER            ; 650B: cdf47e
; -- Confirmar con 'L' o Intro; cualquier otra tecla reinicia el bucle
; de esta ultima pregunta ($6514) --
    LD HL,$80FB                      ; 650E: 21fb80  ; TEXTO_HISTORIA_ATRACCION+$DE
    CALL REPETIR_CARACTER            ; 6511: cdf47e
    CALL ACTUALIZAR_SECUENCIA_SONIDO ; 6514: cdd178
    LD A,$4C                         ; 6517: 3e4c  ; 'L'
    CALL FIRM_KM_TEST_KEY            ; 6519: cd1ebb
    JP NZ,$6223                      ; 651C: c22362  ; vuelve al flujo de la cabecera (confirmar 1/2 jugadores)
    LD A,$3E                         ; 651F: 3e3e  ; Intro
    CALL FIRM_KM_TEST_KEY            ; 6521: cd1ebb
    JP NZ,$6223                      ; 6524: c22362
    JR $6514                         ; 6527: 18eb

; ---- $6529-$68B1 (905 bytes): segundo tramo promovido del INCBIN --
; Sesion 13. Arranca desde el punto de entrada real confirmado en la
; Sesion 12 ($6529, destino de los 2 "JP Z,$6529" de tecla P/p en
; DESPACHAR_MENU_PRINCIPAL) y sigue el hilo de llamadas/saltos hasta
; $68B1 (justo antes de la entrada 'I' de instrucciones en $68B2, que
; queda sin analizar -- ver el INCBIN mas abajo). Cubre: arranque de
; partida e inicio de cada nivel (INICIAR_PARTIDA/PREPARAR_NIVEL),
; colocacion aleatoria de tesoros (PREPARAR_TESOROS_NIVEL), HUD de
; vidas/puntuacion (ACTUALIZAR_HUD_VIDAS), limpieza de paneles
; (LIMPIAR_PANELES_NIVEL), el llamador de RELLENAR_MARCO_DIAGONAL_1..6
; que quedaba pendiente desde la Sesion 7/12
; (SELECCIONAR_DIAGONAL_MARCO_NIVEL), colocacion del jugador
; (COLOCAR_JUGADOR_INICIAL), el bucle principal de juego
; (BUCLE_PRINCIPAL_JUEGO, con 5 llamadas internas que siguen sin
; resolver: $7578, $77D1, $7637, $7566, $7513 -- caen dentro del hueco
; $68B2-$7862 que sigue sin analizar), y las pantallas de fin de
; partida (PANTALLA_STOP_PRESS/PANTALLA_GAME_OVER/
; ACTUALIZAR_TABLA_PUNTUACIONES). Ver FINDINGS.md Sesion 13 para el
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
    JR Z,$654C                        ; 6540: 280a
    LD A,($8161)                      ; 6542: 3a6181
    SRL A                             ; 6545: cb3f
    OR $03                            ; 6547: f603
    LD ($8161),A                      ; 6549: 326181

; BORRAR_BLOQUE_ESTADO limpia entidades/mapa/HUD; el bucle siguiente
; (DE=$00C8=200) es una pausa que bombea sonido -- mismo patron que
; otros retardos fijos del fichero.
    CALL BORRAR_BLOQUE_ESTADO         ; 654C: cdab7e
    LD DE,$00C8                       ; 654F: 11c800
    PUSH DE                           ; 6552: d5
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 6553: cdd178
    POP DE                            ; 6556: d1
    DEC DE                            ; 6557: 1b
    LD A,D                            ; 6558: 7a
    OR E                              ; 6559: b3
    JR NZ,$6552                       ; 655A: 20f6

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
    PUSH BC                           ; 65B1: c5
    PUSH AF                           ; 65B2: f5
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
    JR NZ,$65B3                       ; 65C5: 20ec
    POP AF                            ; 65C7: f1
    LD (HL),A                         ; 65C8: 77
    POP BC                            ; 65C9: c1
    CP $50                            ; 65CA: fe50
    JR Z,$65D0                        ; 65CC: 2802
    ADD A,$10                         ; 65CE: c610
    DJNZ $65B1                        ; 65D0: 10df
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
    CALL REPETIR_CARACTER             ; 65D8: cdf47e
    CALL IMPRIMIR_PUNTUACION_HUD      ; 65DB: cd6378
    LD A,$01                          ; 65DE: 3e01
    CALL FIRM_TXT_SET_PAPER           ; 65E0: cd96bb
    LD A,($816A)                      ; 65E3: 3a6a81
    LD B,A                            ; 65E6: 47
    LD A,$02                          ; 65E7: 3e02
    LD ($8157),A                      ; 65E9: 325781
    LD DE,$0034                       ; 65EC: 113400
    LD ($8155),DE                     ; 65EF: ed535581
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
    DJNZ $65F3                        ; 6611: 10e0

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
    JR C,$66A8                        ; 668A: 381c
    JR Z,$66A3                        ; 668C: 2815
    CP $04                            ; 668E: fe04
    JR C,$669E                        ; 6690: 380c
    JR Z,$6699                        ; 6692: 2805
    LD HL,RELLENAR_MARCO_DIAGONAL_3   ; 6694: 210e7e
    JR $66AB                          ; 6697: 1812
    LD HL,RELLENAR_MARCO_DIAGONAL_1   ; 6699: 21fc7d
    JR $66AB                          ; 669C: 180d
    LD HL,RELLENAR_MARCO_DIAGONAL_5   ; 669E: 21207e
    JR $66AB                          ; 66A1: 1808
    LD HL,RELLENAR_MARCO_DIAGONAL_4   ; 66A3: 21177e
    JR $66AB                          ; 66A6: 1803
    LD HL,RELLENAR_MARCO_DIAGONAL_6   ; 66A8: 21297e
    LD ($66BA),HL                     ; 66AB: 22ba66
    LD B,$04                          ; 66AE: 0604
    LD HL,$2808                       ; 66B0: 210828
    PUSH BC                           ; 66B3: c5
    PUSH HL                           ; 66B4: e5
    LD B,$05                          ; 66B5: 0605
    PUSH BC                           ; 66B7: c5
    PUSH HL                           ; 66B8: e5
    CALL RELLENAR_MARCO_DIAGONAL_6    ; 66B9: cd297e
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 66BC: cdd178
    POP HL                            ; 66BF: e1
    LD BC,$000E                       ; 66C0: 010e00
    ADD HL,BC                         ; 66C3: 09
    POP BC                            ; 66C4: c1
    DJNZ $66B7                        ; 66C5: 10f0
    POP HL                            ; 66C7: e1
    LD BC,$2800                       ; 66C8: 010028
    ADD HL,BC                         ; 66CB: 09
    POP BC                            ; 66CC: c1
    DJNZ $66B3                        ; 66CD: 10e4

; COLOCAR_JUGADOR_INICIAL ($66CF): fija el puntero de posiciones
; ($8645=$860F, la MISMA tabla que usa la demo de fondo del menu en
; $61E5) y llama a INICIALIZAR_ENTIDADES -- coloca tantas entidades
; (enemigos/coleccionables) como indique ($8169), que en PREPARAR_NIVEL
; se dejo sincronizado con el nivel actual (hipotesis media-alta: cada
; nivel introduce tantos enemigos como su numero). Despues dibuja al
; jugador ('A') en la posicion de salida fija $0820 con ($8157)=3.
; Confianza alta en la estructura; media en el papel exacto de
; ($8157)=3 (una de las 4 orientaciones/grupos de SPRITE_JUGADOR_Gx,
; sin resolver cual exactamente -- pendiente de sesiones anteriores).
COLOCAR_JUGADOR_INICIAL:
    LD HL,$860F                       ; 66CF: 210f86
    LD ($8645),HL                     ; 66D2: 224586
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
; y una secuencia de 4 llamadas SIN RESOLVER TODAVIA ($7578, $77D1,
; $7637, $7566 -- las mismas 4 que dejo pendientes la Sesion 12, caen
; dentro del hueco todavia sin analizar $68B2-$7862) que probablemente
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
    CALL $7578                        ; 66FA: cd7875
    JP C,PANTALLA_GAME_OVER           ; 66FD: dab367
    CALL $77D1                        ; 6700: cdd177
    CALL $7578                        ; 6703: cd7875
    JP C,PANTALLA_GAME_OVER           ; 6706: dab367
    CALL $7637                        ; 6709: cd3776
    CALL $7566                        ; 670C: cd6675
    CALL ESPERAR_TECLA_2C             ; 670F: cd9378
    LD A,($816D)                      ; 6712: 3a6d81
    OR A                              ; 6715: b7
    CALL NZ,$7513                     ; 6716: c41375
    LD B,$02                          ; 6719: 0602
    CALL ANIMAR_OPCION_MENU           ; 671B: cdb778
    CALL $7578                        ; 671E: cd7875
    JP C,PANTALLA_GAME_OVER           ; 6721: dab367
    CALL $77D1                        ; 6724: cdd177
    CALL $7578                        ; 6727: cd7875
    JP C,PANTALLA_GAME_OVER           ; 672A: dab367
    CALL $7637                        ; 672D: cd3776
    CALL $7566                        ; 6730: cd6675
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
    CALL REPETIR_CARACTER             ; 673F: cdf47e
    LD HL,$8040                       ; 6742: 214080
    CALL REPETIR_CARACTER             ; 6745: cdf47e
    LD HL,$8064                       ; 6748: 216480
    CALL REPETIR_CARACTER             ; 674B: cdf47e
    LD HL,$8088                       ; 674E: 218880
    CALL REPETIR_CARACTER             ; 6751: cdf47e
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 6754: cdd178
    LD HL,$809D                       ; 6757: 219d80
    CALL REPETIR_CARACTER             ; 675A: cdf47e
    LD A,$02                          ; 675D: 3e02
    CALL GENERAR_ALEATORIO            ; 675F: cd537d
    OR A                              ; 6762: b7
    JR Z,$677E                        ; 6763: 2819
    LD HL,($815A)                     ; 6765: 2a5a81
    LD BC,$00C8                       ; 6768: 01c800
    ADD HL,BC                         ; 676B: 09
    LD ($815A),HL                     ; 676C: 225a81
    LD HL,$80B8                       ; 676F: 21b880
    CALL REPETIR_CARACTER             ; 6772: cdf47e
    LD HL,$80C2                       ; 6775: 21c280
    CALL REPETIR_CARACTER             ; 6778: cdf47e
    JP $6795                          ; 677B: c39567
    LD A,($816A)                      ; 677E: 3a6a81
    CP $07                            ; 6781: fe07
    JR Z,$6765                        ; 6783: 28e0
    INC A                             ; 6785: 3c
    LD ($816A),A                      ; 6786: 326a81
    LD HL,$80E0                       ; 6789: 21e080
    CALL REPETIR_CARACTER             ; 678C: cdf47e
    LD HL,$80EA                       ; 678F: 21ea80
    CALL REPETIR_CARACTER             ; 6792: cdf47e
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 6795: cdd178
    LD HL,$80FB                       ; 6798: 21fb80
    CALL REPETIR_CARACTER             ; 679B: cdf47e
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 679E: cdd178
    LD A,$4C                          ; 67A1: 3e4c
    CALL FIRM_KM_TEST_KEY             ; 67A3: cd1ebb
    JP NZ,PREPARAR_NIVEL              ; 67A6: c23465
    LD A,$3E                          ; 67A9: 3e3e
    CALL FIRM_KM_TEST_KEY             ; 67AB: cd1ebb
    JP NZ,PREPARAR_NIVEL              ; 67AE: c23465
    JR $679E                          ; 67B1: 18eb

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
    CALL REPETIR_CARACTER             ; 67B6: cdf47e
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
    PUSH BC                           ; 67D9: c5
    PUSH HL                           ; 67DA: e5
    LD DE,$0400                       ; 67DB: 110004
    PUSH DE                           ; 67DE: d5
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 67DF: cdd178
    POP DE                            ; 67E2: d1
    DEC DE                            ; 67E3: 1b
    LD A,D                            ; 67E4: 7a
    OR E                              ; 67E5: b3
    JR NZ,$67DE                       ; 67E6: 20f6
    POP HL                            ; 67E8: e1
    LD A,(HL)                         ; 67E9: 7e
    INC HL                            ; 67EA: 23
    CALL FIRM_TXT_OUTPUT              ; 67EB: cd5abb
    LD A,$20                          ; 67EE: 3e20
    CALL FIRM_TXT_OUTPUT              ; 67F0: cd5abb
    POP BC                            ; 67F3: c1
    DJNZ $67D9                        ; 67F4: 10e3
    LD DE,$4000                       ; 67F6: 110040
    PUSH DE                           ; 67F9: d5
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 67FA: cdd178
    POP DE                            ; 67FD: d1
    DEC DE                            ; 67FE: 1b
    LD A,D                            ; 67FF: 7a
    OR E                              ; 6800: b3
    JR NZ,$67F9                       ; 6801: 20f6

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
    JP C,$6039                        ; 680D: da3960
    LD A,$01                          ; 6810: 3e01
    LD ($8168),A                      ; 6812: 326881
    LD DE,$0012                       ; 6815: 111200
    LD IX,$86D4                       ; 6818: dd21d486
    XOR A                             ; 681C: af
    LD B,$05                          ; 681D: 0605
    PUSH BC                           ; 681F: c5
    LD HL,($815A)                     ; 6820: 2a5a81
    LD C,(IX+0)                       ; 6823: dd4e00
    LD B,(IX+1)                       ; 6826: dd4601
    SBC HL,BC                         ; 6829: ed42
    POP BC                            ; 682B: c1
    JR Z,$683B                        ; 682C: 280d
    JR C,$683A                        ; 682E: 380a
    PUSH IX                           ; 6830: dde5
    POP HL                            ; 6832: e1
    SBC HL,DE                         ; 6833: ed52
    PUSH HL                           ; 6835: e5
    POP IX                            ; 6836: dde1
    DJNZ $681F                        ; 6838: 10e5
    INC B                             ; 683A: 04
    LD A,B                            ; 683B: 78
    ADD A,A                           ; 683C: 87
    ADD A,$08                         ; 683D: c608
    LD H,$12                          ; 683F: 2612
    LD L,A                            ; 6841: 6f
    LD ($7FC6),HL                     ; 6842: 22c67f
    LD HL,$86D4                       ; 6845: 21d486
    LD A,$05                          ; 6848: 3e05
    CP B                              ; 684A: b8
    JR Z,$6893                        ; 684B: 2846
    SUB B                             ; 684D: 90
    LD B,A                            ; 684E: 47
    PUSH BC                           ; 684F: c5
    CALL ACTUALIZAR_SECUENCIA_SONIDO  ; 6850: cdd178
    POP BC                            ; 6853: c1
    LD HL,$86C2                       ; 6854: 21c286
    LD DE,$86D4                       ; 6857: 11d486
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
    DJNZ $685A                        ; 686B: 10ed
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
    JP $6223                          ; 68AC: c32362

; TRAMPOLIN_TECLA_B ($68AF): destino de la comprobacion de la tecla
; 'B' al principio de BUCLE_PRINCIPAL_JUEGO -- ver comentario alli.
TRAMPOLIN_TECLA_B:
    JP INICIO_TURNO_JUGADOR1          ; 68AF: c3f566

; ---- $68B2-$7862 (4017 bytes): resto sin analizar todavia. Explorado
; mecanicamente en la Sesion 13 (sin promover a codigo fuente) -- es la
; entrada 'I' (instrucciones) desde DESPACHAR_MENU_PRINCIPAL. Estructura
; observada sin verificar con el mismo rigor que el resto de esta
; sesion: un despachador corto en $68B2-$69EAish que llama en cadena a
; $69D2 (posible "imprimir bloque de texto", recibe HL apuntando a un
; parrafo), $698A y $69AC (posiblemente separadores/paginas), y a
; $7D85/$7D9D (ya definidas mas abajo en RELLENAR_FILAS_MASCARA, sin
; resolver su papel aqui); a partir de $69EA y durante la mayor parte
; del tramo el contenido son bloques de TEXTO LITERAL (la pantalla de
; instrucciones del juego), apuntados por los HL de cada CALL $69D2.
; No se ha verificado byte a byte ni separado con precision donde acaba
; el codigo del despachador y donde empieza cada bloque de texto -- se
; deja completo como INCBIN, pendiente para la siguiente sesion. Ver
; FINDINGS.md Sesion 13.
    INCBIN "data/mummy1_resto_sin_analizar.bin", 1201, 4017  ; $68B2-$7862, sin analizar todavia

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
    JP Z,$7CC4                       ; 7B93: cac47c
    LD IY,LOSETA_PISADA_ESCRITURA_VALOR7 ; 7B96: fd21998a
    LD A,$07                         ; 7B9A: 3e07
    LD (HL),A                        ; 7B9C: 77
    ADD A,$19                        ; 7B9D: c619
    SBC HL,BC                        ; 7B9F: ed42
    LD (HL),A                        ; 7BA1: 77
    JP $7CC4                         ; 7BA2: c3c47c
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
    JP Z,$7CC4                       ; 7BC0: cac47c
    LD IY,LOSETA_PISADA_ESCRITURA_VALOR5 ; 7BC3: fd21498a
    LD A,$05                         ; 7BC7: 3e05
    LD (HL),A                        ; 7BC9: 77
    LD A,$20                         ; 7BCA: 3e20
    DEC HL                           ; 7BCC: 2b
    LD (HL),A                        ; 7BCD: 77
    JP $7CC4                         ; 7BCE: c3c47c
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
    JP Z,$7CC4                       ; 7BEF: cac47c
    LD IY,LOSETA_PISADA_ESCRITURA_VALOR4 ; 7BF2: fd21098a
    LD A,$04                         ; 7BF6: 3e04
    LD (HL),A                        ; 7BF8: 77
    ADD A,$1C                        ; 7BF9: c61c
    SBC HL,BC                        ; 7BFB: ed42
    LD (HL),A                        ; 7BFD: 77
    JP $7CC4                         ; 7BFE: c3c47c
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
    JP Z,$7CC4                       ; 7C1E: cac47c
    LD IY,LOSETA_PISADAS_VERTICAL_2   ; 7C21: fd21b989
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
; Despacho confirmado de las ocho losetas de pisadas: los valores de
; casilla 1..8 seleccionan, respectivamente, $89D9, $89E9, $89F9,
; $8A19, $8A79, $8A69, $8AA9 y $8A89. El orden de las dos variantes
; dentro de cada direccion queda demostrado por el valor escrito, pero
; "pie izquierdo/derecho" sigue siendo una interpretacion visual.
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
    LD IY,LOSETA_MAPA_PISADA_7        ; 7D04: fd21898a
    JR $7D32                         ; 7D08: 1828
    LD IY,LOSETA_MAPA_PISADA_8        ; 7D0A: fd21a98a
    JR $7D32                         ; 7D0E: 1822
    LD IY,LOSETA_MAPA_PISADA_5        ; 7D10: fd21698a
    JR $7D32                         ; 7D14: 181c
    LD IY,LOSETA_MAPA_PISADA_6        ; 7D16: fd21798a
    JR $7D32                         ; 7D1A: 1816
    LD IY,LOSETA_MAPA_PISADA_4        ; 7D1C: fd21198a
    JR $7D32                         ; 7D20: 1810
    LD IY,LOSETA_MAPA_PISADA_3        ; 7D22: fd21f989
    JR $7D32                         ; 7D26: 180a
    LD IY,LOSETA_MAPA_PISADA_2        ; 7D28: fd21e989
    JR $7D32                         ; 7D2C: 1804
    LD IY,LOSETA_MAPA_PISADA_1        ; 7D2E: fd21d989
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
    DB $F0,$87,$F0,$F0,$F0,$87,$F0,$F0,$F0,$96,$F0,$F0,$F0,$96,$F0,$F0 ; 8999
    DB $F0,$F0,$F0,$F0,$F0,$96,$F0,$F0,$F0,$96,$F0,$F0,$F0,$96,$F0,$F0 ; 89A9
LOSETA_PISADAS_VERTICAL_2:
    DB $F0,$F0,$1E,$F0,$F0,$F0,$1E,$F0,$F0,$F0,$96,$F0,$F0,$F0,$96,$F0 ; 89B9
    DB $F0,$F0,$F0,$F0,$F0,$F0,$96,$F0,$F0,$F0,$96,$F0,$F0,$F0,$F0,$F0 ; 89C9
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
    DB $F0,$87,$F0,$87,$F0,$96,$F0,$96,$F0,$F0,$F0,$96,$F0,$96,$F0,$F0 ; 89D9
LOSETA_MAPA_PISADA_2:
    DB $1E,$F0,$1E,$F0,$96,$F0,$96,$F0,$F0,$F0,$96,$F0,$96,$F0,$F0,$F0 ; 89E9
LOSETA_MAPA_PISADA_3:
    DB $F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$96,$0F,$96,$0F,$F0,$C3 ; 89F9
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
    DB $F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0 ; 8A09
LOSETA_MAPA_PISADA_4:
    DB $F0,$C3,$96,$0F,$96,$0F,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0 ; 8A19
; ---- LOSETA_PISADA_ESCRITURA_VALOR6 ---- Sesion 11: fotograma de
; escritura de 'T' para el valor de casilla 6 (rama ($8157)==3, primer
; fotograma, ver $7BA5). CONFIRMADO por el codigo que DIBUJAR_ENTIDAD
; lo vuelca como 4x8 (outer=8 fijado en $7BAB, inner=4 por defecto) --
; 32 bytes, $8A29-$8A48, sin solape con ninguna LOSETA_MAPA_PISADA_*.
; Confianza alta en estructura y geometria, sin confirmar identidad
; visual/orientacion. Ver FINDINGS.md Sesion 11.
LOSETA_PISADA_ESCRITURA_VALOR6:
    DB $F0,$F0,$F0,$F0,$F0,$96,$F0,$F0,$F0,$96,$F0,$F0,$F0,$F0,$F0,$F0 ; 8A29
    DB $F0,$96,$F0,$F0,$F0,$96,$F0,$F0,$F0,$87,$F0,$F0,$F0,$87,$F0,$F0 ; 8A39
; ---- LOSETA_PISADA_ESCRITURA_VALOR5 ---- Sesion 11: fotograma de
; escritura de 'T' para el valor de casilla 5 (rama ($8157)==3,
; segundo fotograma, alternado con LOSETA_PISADA_ESCRITURA_VALOR6 via
; el flag $8158, ver $7BC3). Misma geometria 4x8 (32 bytes,
; $8A49-$8A68), sin solape. Confianza alta en estructura y geometria,
; sin confirmar identidad visual/orientacion. Ver FINDINGS.md Sesion 11.
LOSETA_PISADA_ESCRITURA_VALOR5:
    DB $F0,$F0,$F0,$F0,$F0,$F0,$96,$F0,$F0,$F0,$96,$F0,$F0,$F0,$F0,$F0 ; 8A49
    DB $F0,$F0,$96,$F0,$F0,$F0,$96,$F0,$F0,$F0,$1E,$F0,$F0,$F0,$1E,$F0 ; 8A59
LOSETA_MAPA_PISADA_5:
    DB $F0,$F0,$F0,$96,$F0,$96,$F0,$F0,$F0,$96,$F0,$96,$F0,$87,$F0,$87 ; 8A69
LOSETA_MAPA_PISADA_6:
    DB $F0,$F0,$96,$F0,$96,$F0,$F0,$F0,$96,$F0,$96,$F0,$1E,$F0,$1E,$F0 ; 8A79
LOSETA_MAPA_PISADA_7:
    DB $F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$0F,$96,$0F,$96,$3C,$F0 ; 8A89
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
    DB $F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0 ; 8A99
LOSETA_MAPA_PISADA_8:
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
