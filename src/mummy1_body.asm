; Oh Mummy (Amsoft, 1984, Amstrad CPC) -- motor del juego (MUMMY1.BIN)
; Ingenieria inversa: Rafael Eduardo Martin Candial (raemca@hotmail.com)
; Ver ../FINDINGS.md para el diario de reconstruccion sesion a sesion.
;
; Direccion de carga real: $6000 -- confirmada en el propio cargador
; BASIC (src/load_disk/mummy_bas.bas, linea 570-580: LOAD"!mummy1",&6000
; : CALL &6000). Longitud real: 13190 bytes ($3386).
;
; Estado (Sesion 5): el bloque $6000-$6400 (1025 bytes) esta
; desensamblado y verificado -- reconstruccion MECANICA de primera
; pasada, sigue sin nombres semanticos (llamadas a $78xx/$7Dxx/$7Exx/
; $7Bxx sin resolver todavia en ese tramo concreto). Mas alla de
; $6400, siguiendo el hilo de llamadas real (no linealmente, ver
; prompts/sesion_03..05_*.md), se han identificado y RECONSTRUIDO con
; nombre funcional 18 rutinas (510 bytes) repartidas en 5 bloques
; contiguos -- cada una con su comentario de hipotesis y nivel de
; confianza, NINGUNA verificada en emulador todavia (nombres
; provisionales, no definitivos -- ver FINDINGS.md Sesiones 3-5). El
; resto (11655 bytes) sigue sin analizar, incluido tal cual con varios
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

    ORG $6000

; ---- Inicializacion de sonido: 3 envolventes (amplitud+tono), cada
; una definida por una tabla de datos aun sin extraer a fichero propio
; ($7FCA/$7FD4/$7FDE = envolventes de amplitud 1/2/3; $7FE5/$7FF5/$7FF9
; = envolventes de tono 1/2/3) ----
    CALL FIRM_SOUND_RESET         ; 6000: cda7bc
    LD A,$01                     ; 6003: 3e01
    LD HL,$7FCA                  ; 6005: 21ca7f
    CALL FIRM_SOUND_AMPL_ENV                   ; 6008: cdbcbc
    LD A,$01                     ; 600B: 3e01
    LD HL,$7FE5                  ; 600D: 21e57f
    CALL FIRM_SOUND_TONE_ENV                   ; 6010: cdbfbc
    LD A,$02                     ; 6013: 3e02
    LD HL,$7FD4                  ; 6015: 21d47f
    CALL FIRM_SOUND_AMPL_ENV                   ; 6018: cdbcbc
    LD A,$02                     ; 601B: 3e02
    LD HL,$7FF5                  ; 601D: 21f57f
    CALL FIRM_SOUND_TONE_ENV                   ; 6020: cdbfbc
    LD A,$03                     ; 6023: 3e03
    LD HL,$7FDE                  ; 6025: 21de7f
    CALL FIRM_SOUND_AMPL_ENV                   ; 6028: cdbcbc
    LD A,$03                     ; 602B: 3e03
    LD HL,$7FF9                  ; 602D: 21f97f
    CALL FIRM_SOUND_TONE_ENV                   ; 6030: cdbfbc
    LD HL,$905C                  ; 6033: 215c90
    LD ($905A),HL                ; 6036: 225a90
    CALL FIRM_KL_TIME_PLEASE                   ; 6039: cd0dbd
    LD ($8151),HL                ; 603C: 225181  ; hipotesis: semilla de aleatoriedad a partir del reloj del sistema
; $78D1 se llama decenas de veces en todo este bloque, siempre suelta
; entre otras llamadas -- hipotesis (ver FINDINGS.md Sesion 3): bombea
; una cola/guion de sonido (referencia $905A/$905C, avanza de 9 en 9
; bytes hasta $937D, y puede llamar a SOUND QUEUE del firmware). No
; renombrada todavia -- sin confirmar con evidencia mas fuerte.
    CALL $78D1                   ; 603F: cdd178
    CALL $78D1                   ; 6042: cdd178
    CALL $78D1                   ; 6045: cdd178
    CALL $78D1                   ; 6048: cdd178
; $7EAB: hipotesis "borrar bloque de estado" -- pone a 0 el byte $8172
; y lo propaga con LDIR (truco clasico de Z80: origen=destino-1) a lo
; largo de 1181 bytes mas ($8172-$85EE). Ver FINDINGS.md Sesion 3.
    CALL BORRAR_BLOQUE_ESTADO                   ; 604B: cdab7e
    CALL $78D1                   ; 604E: cdd178
    CALL $78D1                   ; 6051: cdd178
    LD A,$06                     ; 6054: 3e06
    LD ($8169),A                 ; 6056: 326981
    XOR A                        ; 6059: af
    LD ($816C),A                 ; 605A: 326c81
    LD ($8168),A                 ; 605D: 326881
    CALL $78D1                   ; 6060: cdd178
    CALL $78D1                   ; 6063: cdd178
; $7EF4: hipotesis "repetir un caracter N veces por FIRM_TXT_OUTPUT" --
; lee (HL)=contador, (HL+1)=caracter, y saca ese caracter "contador"
; veces sin avanzar mas el puntero (formato de datos de 2 bytes por
; llamada: cuenta+caracter). Encaja con dibujar tramos rectos de un
; marco/borde decorativo. Ver FINDINGS.md Sesion 3.
    LD HL,$8653                  ; 6066: 215386
    CALL REPETIR_CARACTER                   ; 6069: cdf47e
    CALL $78D1                   ; 606C: cdd178
    CALL $78D1                   ; 606F: cdd178
    CALL $78D1                   ; 6072: cdd178
    CALL $78D1                   ; 6075: cdd178
    LD IX,$8ECA                  ; 6078: dd21ca8e
    LD B,$C8                     ; 607C: 06c8
    LD DE,$0000                  ; 607E: 110000
; Bucle $607E-$6093: hipotesis "tabla de direcciones de pantalla por
; fila" -- 200 iteraciones (B=$C8), cada una calcula con el firmware
; FIRM_SCR_DOT_POSITION la direccion de pantalla de una fila y la
; guarda en una tabla de 400 bytes en $8ECA-$905A (200 entradas x 2
; bytes). Tecnica muy comun en juegos de CPC para acelerar el acceso
; a filas de pantalla. Ver FINDINGS.md Sesion 3.
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
    CALL $78D1                   ; 6095: cdd178
    CALL $78D1                   ; 6098: cdd178
    CALL $78D1                   ; 609B: cdd178
    CALL $78D1                   ; 609E: cdd178
    LD HL,$8740                  ; 60A1: 214087
    CALL REPETIR_CARACTER                   ; 60A4: cdf47e
    CALL $78D1                   ; 60A7: cdd178
    CALL $78D1                   ; 60AA: cdd178
; $7EB9, llamada 14 veces seguidas con pares HL/DE distintos: hipotesis
; "borrar un rectangulo de la ventana de texto" -- HL/DE parecen ser
; (fila,columna) de inicio y (ancho,alto) o esquina opuesta; recorre
; una tabla en $81D8 (con paso de 40 = $28 bytes por fila, el ancho de
; pantalla en modo texto) escribiendo espacios. Consistente con ir
; despejando varios paneles de HUD/marco antes de dibujarlos. Ver
; FINDINGS.md Sesion 3.
    LD HL,$0203                  ; 60AD: 210302
    LD DE,$2604                  ; 60B0: 110426
    CALL BORRAR_RECTANGULO_VENTANA                   ; 60B3: cdb97e
    CALL $78D1                   ; 60B6: cdd178
    LD HL,$0408                  ; 60B9: 210804
    LD DE,$2409                  ; 60BC: 110924
    CALL BORRAR_RECTANGULO_VENTANA                   ; 60BF: cdb97e
    CALL $78D1                   ; 60C2: cdd178
    LD HL,$040D                  ; 60C5: 210d04
    LD DE,$080E                  ; 60C8: 110e08
    CALL BORRAR_RECTANGULO_VENTANA                   ; 60CB: cdb97e
    CALL $78D1                   ; 60CE: cdd178
    LD HL,$0D0D                  ; 60D1: 210d0d
    LD DE,$1B0E                  ; 60D4: 110e1b
    CALL BORRAR_RECTANGULO_VENTANA                   ; 60D7: cdb97e
    CALL $78D1                   ; 60DA: cdd178
    LD HL,$200D                  ; 60DD: 210d20
    LD DE,$240E                  ; 60E0: 110e24
    CALL BORRAR_RECTANGULO_VENTANA                   ; 60E3: cdb97e
    CALL $78D1                   ; 60E6: cdd178
    LD HL,$0412                  ; 60E9: 211204
    LD DE,$2413                  ; 60EC: 111324
    CALL BORRAR_RECTANGULO_VENTANA                   ; 60EF: cdb97e
    CALL $78D1                   ; 60F2: cdd178
    LD HL,$0417                  ; 60F5: 211704
    LD DE,$2418                  ; 60F8: 111824
    CALL BORRAR_RECTANGULO_VENTANA                   ; 60FB: cdb97e
    CALL $78D1                   ; 60FE: cdd178
    LD HL,$0205                  ; 6101: 210502
    LD DE,$0318                  ; 6104: 111803
    CALL BORRAR_RECTANGULO_VENTANA                   ; 6107: cdb97e
    CALL $78D1                   ; 610A: cdd178
    LD HL,$0905                  ; 610D: 210509
    LD DE,$0A18                  ; 6110: 11180a
    CALL BORRAR_RECTANGULO_VENTANA                   ; 6113: cdb97e
    CALL $78D1                   ; 6116: cdd178
    LD HL,$1005                  ; 6119: 210510
    LD DE,$1107                  ; 611C: 110711
    CALL BORRAR_RECTANGULO_VENTANA                   ; 611F: cdb97e
    CALL $78D1                   ; 6122: cdd178
    LD HL,$1705                  ; 6125: 210517
    LD DE,$1807                  ; 6128: 110718
    CALL BORRAR_RECTANGULO_VENTANA                   ; 612B: cdb97e
    CALL $78D1                   ; 612E: cdd178
    LD HL,$1E05                  ; 6131: 21051e
    LD DE,$1F18                  ; 6134: 11181f
    CALL BORRAR_RECTANGULO_VENTANA                   ; 6137: cdb97e
    CALL $78D1                   ; 613A: cdd178
    LD HL,$2505                  ; 613D: 210525
    LD DE,$2618                  ; 6140: 111826
    CALL BORRAR_RECTANGULO_VENTANA                   ; 6143: cdb97e
    CALL $78D1                   ; 6146: cdd178
    LD HL,$1014                  ; 6149: 211410
    LD DE,$1116                  ; 614C: 111611
    CALL BORRAR_RECTANGULO_VENTANA                   ; 614F: cdb97e
    CALL $78D1                   ; 6152: cdd178
    LD HL,$1714                  ; 6155: 211417
    LD DE,$1816                  ; 6158: 111618
    CALL BORRAR_RECTANGULO_VENTANA                   ; 615B: cdb97e
    CALL $78D1                   ; 615E: cdd178
    LD HL,$0000                  ; 6161: 210000
    LD DE,$2718                  ; 6164: 111827
    CALL FIRM_TXT_WIN_ENABLE                   ; 6167: cd66bb
    CALL $78D1                   ; 616A: cdd178
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
    CALL $78D1                   ; 6179: cdd178
    LD HL,$2824                  ; 617C: 212428
    CALL DIBUJAR_TRAMO_MARCO_4                   ; 617F: cdcd7d
    LD HL,$2832                  ; 6182: 213228
    CALL $7E0E                   ; 6185: cd0e7e
    CALL $78D1                   ; 6188: cdd178
    LD HL,$2840                  ; 618B: 214028
    CALL DIBUJAR_TRAMO_MARCO_2                   ; 618E: cd9d7d
    LD HL,$5008                  ; 6191: 210850
    CALL $7E29                   ; 6194: cd297e
    CALL $78D1                   ; 6197: cdd178
    LD HL,$889D                  ; 619A: 219d88
    CALL REPETIR_CARACTER                   ; 619D: cdf47e
    LD HL,$5040                  ; 61A0: 214050
    CALL $7E29                   ; 61A3: cd297e
    CALL $78D1                   ; 61A6: cdd178
    LD HL,$7808                  ; 61A9: 210878
    CALL $7E29                   ; 61AC: cd297e
    LD HL,$8906                  ; 61AF: 210689
    CALL REPETIR_CARACTER                   ; 61B2: cdf47e
    CALL $78D1                   ; 61B5: cdd178
    LD HL,$7840                  ; 61B8: 214078
    CALL $7E29                   ; 61BB: cd297e
    LD HL,$A008                  ; 61BE: 2108a0
    CALL DIBUJAR_TRAMO_MARCO_4                   ; 61C1: cdcd7d
    CALL $78D1                   ; 61C4: cdd178
    LD HL,$A016                  ; 61C7: 2116a0
    CALL $7E17                   ; 61CA: cd177e
    LD HL,$A024                  ; 61CD: 2124a0
    CALL DIBUJAR_TRAMO_MARCO_3                   ; 61D0: cdb57d
    CALL $78D1                   ; 61D3: cdd178
    LD HL,$A032                  ; 61D6: 2132a0
    CALL $7E05                   ; 61D9: cd057e
    LD HL,$A040                  ; 61DC: 2140a0
    CALL DIBUJAR_TRAMO_MARCO_4                   ; 61DF: cdcd7d
    CALL $78D1                   ; 61E2: cdd178
    LD HL,$860F                  ; 61E5: 210f86
    LD ($8645),HL                ; 61E8: 224586
    CALL INICIALIZAR_ENTIDADES                   ; 61EB: cd4f79
    CALL $78D1                   ; 61EE: cdd178
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
    CALL $78D1                   ; 6223: cdd178
    CALL FIRM_KM_READ_CHAR                   ; 6226: cd09bb
    JR C,$6223                   ; 6229: 38f8
    LD HL,$866D                  ; 622B: 216d86
    CALL REPETIR_CARACTER                   ; 622E: cdf47e
    CALL BORRAR_BLOQUE_ESTADO                   ; 6231: cdab7e
    CALL $78D1                   ; 6234: cdd178
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
    CALL $78D1                   ; 625C: cdd178
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
    CALL $78D1                   ; 629B: cdd178
    LD HL,$2001                  ; 629E: 210120
    LD DE,$2116                  ; 62A1: 111621
    CALL BORRAR_RECTANGULO_VENTANA                   ; 62A4: cdb97e
    LD HL,$0801                  ; 62A7: 210108
    LD DE,$1F02                  ; 62AA: 11021f
    CALL BORRAR_RECTANGULO_VENTANA                   ; 62AD: cdb97e
    CALL $78D1                   ; 62B0: cdd178
    LD HL,$0815                  ; 62B3: 211508
    LD DE,$1F16                  ; 62B6: 11161f
    CALL BORRAR_RECTANGULO_VENTANA                   ; 62B9: cdb97e
    LD HL,$0000                  ; 62BC: 210000
    LD DE,$2718                  ; 62BF: 111827
    CALL FIRM_TXT_WIN_ENABLE                   ; 62C2: cd66bb
    LD HL,$8676                  ; 62C5: 217686
    CALL REPETIR_CARACTER                   ; 62C8: cdf47e
    CALL $78D1                   ; 62CB: cdd178
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
    CALL $78D1                   ; 62F2: cdd178
    LD HL,$0C0E                  ; 62F5: 210e0c
    CALL FIRM_TXT_SET_CURSOR                   ; 62F8: cd75bb
    LD HL,($86B0)                ; 62FB: 2ab086
    CALL $786C                   ; 62FE: cd6c78
    LD HL,$86B2                  ; 6301: 21b286
    CALL REPETIR_CARACTER                   ; 6304: cdf47e
    LD HL,$0C10                  ; 6307: 21100c
    CALL FIRM_TXT_SET_CURSOR                   ; 630A: cd75bb
    CALL $78D1                   ; 630D: cdd178
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
    CALL $78D1                   ; 633D: cdd178
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

; ---- Mas alla de $6400: 5 bloques reconstruidos (18 rutinas, 510
; bytes) intercalados con el resto sin analizar todavia (INCBIN con
; offset/longitud). Ver FINDINGS.md Sesiones 3-5 para el detalle y
; el nivel de confianza de cada hipotesis. ----

    INCBIN "data/mummy1_resto_sin_analizar.bin", 0, 5227  ; $6401-$786B, sin analizar todavia

; ---- IMPRIMIR_NUMERO_HL / ESPERAR_TECLA_2C / ANIMAR_OPCION_MENU ----
; hipotesis: imprimir HL como 4 digitos decimales (media-alta); esperar
; pulsacion+liberacion de la tecla $2C con antirrebote (alta); animar/
; temporizar la opcion de menu resaltada (baja). Ver FINDINGS.md Sesion 3.
IMPRIMIR_NUMERO_HL:
    LD B,$04                         ; 786C: 0604
    LD IY,$8736                      ; 786E: fd213687
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
    CALL FIRM_TXT_OUTPUT                       ; 7887: cd5abb
    DJNZ $7872                       ; 788A: 10e6
    LD A,$30                         ; 788C: 3e30
    ADD A,L                          ; 788E: 85
    CALL FIRM_TXT_OUTPUT                       ; 788F: cd5abb
    RET                              ; 7892: c9
ESPERAR_TECLA_2C:
    LD A,$2C                         ; 7893: 3e2c
    CALL FIRM_KM_TEST_KEY                       ; 7895: cd1ebb
    RET Z                            ; 7898: c8
    CALL $78D1                       ; 7899: cdd178
    LD A,$2C                         ; 789C: 3e2c
    CALL FIRM_KM_TEST_KEY                       ; 789E: cd1ebb
    JR NZ,$7899                      ; 78A1: 20f6
    CALL $78D1                       ; 78A3: cdd178
    CALL FIRM_KM_READ_CHAR                       ; 78A6: cd09bb
    JR C,$78A3                       ; 78A9: 38f8
    CALL $78D1                       ; 78AB: cdd178
    CALL FIRM_KM_READ_CHAR                       ; 78AE: cd09bb
    JR NC,$78AB                      ; 78B1: 30f8
    CALL FIRM_KM_CHAR_RETURN                       ; 78B3: cd0cbb
    RET                              ; 78B6: c9
ANIMAR_OPCION_MENU:
    PUSH BC                          ; 78B7: c5
    CALL $7996                       ; 78B8: cd9679
    CALL $78D1                       ; 78BB: cdd178
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
    INCBIN "data/mummy1_resto_sin_analizar.bin", 5328, 126  ; $78D1-$794E, sin analizar todavia

; ---- INICIALIZAR_ENTIDADES / INICIALIZAR_UNA_ENTIDAD ----
; hipotesis (media-alta): inicializa 6 registros de 5 bytes en $816D con
; 2 bytes de GENERAR_ALEATORIO + una posicion tomada de una tabla en
; $8645. Ver FINDINGS.md Sesion 4.
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
    LD IX,$816D                      ; 7963: dd216d81
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
    INCBIN "data/mummy1_resto_sin_analizar.bin", 5525, 255  ; $7996-$7A94, sin analizar todavia

; ---- CALCULAR_CASILLA_ADYACENTE ----
; hipotesis (alta): dada una direccion 0-3 en A, calcula la posicion de
; la celda adyacente en ($8164) (pasos de 8px en X / 2px en Y). Ver
; FINDINGS.md Sesion 5.
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
    INCBIN "data/mummy1_resto_sin_analizar.bin", 5813, 648  ; $7AB6-$7D3D, sin analizar todavia

; ---- CONSULTAR_CASILLA_MAPA / GENERAR_ALEATORIO / MEZCLAR_ALEATORIO / DIBUJAR_TRAMO_MARCO_1-4 ----
; hipotesis: acceso a una estructura en $8200, paso de fila 5 bytes,
; posible mapa del laberinto o subdivision (media); generador
; pseudoaleatorio sembrado con el reloj del sistema (alta); 4 rutinas
; que preparan una tabla de offset y llaman a COPIAR_BLOQUE_A_LIENZO
; para dibujar un tramo del marco decorativo (media). Ver FINDINGS.md
; Sesiones 3-5.
CONSULTAR_CASILLA_MAPA:
    PUSH DE                          ; 7D3E: d5
    LD HL,$8200                      ; 7D3F: 210082
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
    CALL $7DED                       ; 7D88: cded7d
    LD HL,($8645)                    ; 7D8B: 2a4586
    LD BC,$0602                      ; 7D8E: 010206
    ADD HL,BC                        ; 7D91: 09
    LD ($8645),HL                    ; 7D92: 224586
    LD IY,$877D                      ; 7D95: fd217d87
    CALL COPIAR_BLOQUE_A_LIENZO      ; 7D99: cd737e
    RET                              ; 7D9C: c9
DIBUJAR_TRAMO_MARCO_2:
    LD ($8645),HL                    ; 7D9D: 224586
    CALL $7DED                       ; 7DA0: cded7d
    LD HL,($8645)                    ; 7DA3: 2a4586
    LD BC,$0602                      ; 7DA6: 010206
    ADD HL,BC                        ; 7DA9: 09
    LD ($8645),HL                    ; 7DAA: 224586
    LD IY,$87C5                      ; 7DAD: fd21c587
    CALL COPIAR_BLOQUE_A_LIENZO      ; 7DB1: cd737e
    RET                              ; 7DB4: c9
DIBUJAR_TRAMO_MARCO_3:
    LD ($8645),HL                    ; 7DB5: 224586
    CALL $7DED                       ; 7DB8: cded7d
    LD HL,($8645)                    ; 7DBB: 2a4586
    LD BC,$0602                      ; 7DBE: 010206
    ADD HL,BC                        ; 7DC1: 09
    LD ($8645),HL                    ; 7DC2: 224586
    LD IY,$880D                      ; 7DC5: fd210d88
    CALL COPIAR_BLOQUE_A_LIENZO      ; 7DC9: cd737e
    RET                              ; 7DCC: c9
DIBUJAR_TRAMO_MARCO_4:
    LD ($8645),HL                    ; 7DCD: 224586
    CALL $7DE5                       ; 7DD0: cde57d
    LD HL,($8645)                    ; 7DD3: 2a4586
    LD BC,$0602                      ; 7DD6: 010206
    ADD HL,BC                        ; 7DD9: 09
    LD ($8645),HL                    ; 7DDA: 224586
    LD IY,$8855                      ; 7DDD: fd215588
    CALL COPIAR_BLOQUE_A_LIENZO      ; 7DE1: cd737e
    RET                              ; 7DE4: c9
    INCBIN "data/mummy1_resto_sin_analizar.bin", 6628, 142  ; $7DE5-$7E72, sin analizar todavia

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
    LD IX,$8ECA                      ; 7E94: dd21ca8e
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
    LD HL,$8172                      ; 7EAC: 217281
    LD (HL),A                        ; 7EAF: 77
    PUSH HL                          ; 7EB0: e5
    POP DE                           ; 7EB1: d1
    INC DE                           ; 7EB2: 13
    LD BC,$049D                      ; 7EB3: 019d04
    LDIR                             ; 7EB6: edb0
    RET                              ; 7EB8: c9
BORRAR_RECTANGULO_VENTANA:
    PUSH HL                          ; 7EB9: e5
    LD IY,$81D8                      ; 7EBA: fd21d881
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
    CALL FIRM_TXT_WIN_ENABLE                       ; 7EED: cd66bb
    CALL FIRM_TXT_CLEAR_WINDOW                       ; 7EF0: cd6cbb
    RET                              ; 7EF3: c9
REPETIR_CARACTER:
    LD B,(HL)                        ; 7EF4: 46
    INC HL                           ; 7EF5: 23
    LD A,(HL)                        ; 7EF6: 7e
    CALL FIRM_TXT_OUTPUT                       ; 7EF7: cd5abb
    DJNZ $7EF5                       ; 7EFA: 10f9
    RET                              ; 7EFC: c9
    INCBIN "data/mummy1_resto_sin_analizar.bin", 6908, 5257  ; $7EFD-$9385, sin analizar todavia
