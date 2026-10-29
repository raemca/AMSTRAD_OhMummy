# Oh Mummy (Amstrad CPC) — Proyecto de Ingeniería Inversa

*[Read this in English](README.en.md)*

*Ingeniería inversa, análisis y documentación: Rafael Eduardo Martín Candial (raemca@hotmail.com)*

Resumen
-------
Proyecto hermano de [`MSX/proyectos/madmixgame`](../../MSX/proyectos/madmixgame)
y de [`SPECTRUM_MadMixGame`](../../../SPECTRUM_MadMixGame), aplicando la
misma metodología a un juego distinto: **Oh Mummy** (Amsoft, 1984),
uno de los títulos de lanzamiento del catálogo Amsoft para el
**Amstrad CPC 464**. Mismo objetivo: desensamblado byte a byte,
reconstrucción como fuente ensamblador legible y verificable,
extracción y documentación de recursos (gráficos, sonido, niveles), y
herramientas propias para recompilar el resultado y regenerar el
`.dsk` original.

Alcance
-------
Trabajo técnico: desensamblado, extracción de recursos, herramientas
de conversión y documentación. No incluye ni redistribuye el volcado
original del disco (`.dsk`) ni materiales con copyright sin la debida
autorización. Ver `AVISO-LEGAL.md` para el detalle completo.

Estado actual
-------------
**El motor está COMPLETAMENTE reconstruido desde la Sesión 14, sin
ningún hueco `INCBIN` de código pendiente**, y las Sesiones 15-25 han
llevado el trabajo más allá del código: **cero direcciones "mágicas"
en todo el motor** (las 227 instrucciones `CALL`/`JP`/`JR` con destino
literal quedan etiquetadas una a una, Sesiones 19-20), la identidad de
los 4 iconos de contenido de casilla queda **corregida** (sarcófago,
llave, pergamino y tesoro — hasta la Sesión 16 se creían parte del
"marco decorativo" del nivel, Sesión 17), y **todos los recursos
gráficos y de sonido ya identificados viven en fichero individual**,
extraídos programáticamente del binario y verificados byte a byte
(losetas de pisadas y sprites de icono, Sesiones 15/18; música de
fondo y los 3 efectos de sonido puntuales, con herramientas propias de
decodificación y reproducción, Sesiones 23-25). Firmware identificado,
`.dsk` completo regenerado desde cero. El catálogo AMSDOS del disco
(`FISICO/Oh Mummy (1984)(Amsoft).dsk`, 194816 bytes, formato CPCEMU
estándar, 40 pistas x 1 cara, formato de datos 9x512, IDs de sector
`C1`-`C9`) solo tiene **2 ficheros**:

| Fichero | Bloques asignados | Estado |
|---|---|---|
| `MUMMY.BAS` | 3 (3072 bytes) | **detokenizado y verificado byte a byte** — `src/load_disk/mummy_bas.bas` |
| `MUMMY1.BIN` | 14 (14336 bytes) | motor, carga en `$6000`; **`$6000`-`$6400` (1025 bytes) desensamblado**, **`$6401`-`$6528` (296 bytes) reconstruido como código (Sesión 12)**, **`$6529`-`$68B1` (905 bytes) reconstruido como código (Sesión 13)**, **`$68B2`-`$7862` (4017 bytes, pantalla de instrucciones + núcleo del bucle de juego) reconstruido como código/datos (Sesión 14)**, **`$7863`-`$786B` (9 bytes) reconstruido como código (Sesión 13)**, **`$786C`-`$7EFC` (1681 bytes) reconstruido como código**, **`$7EFD`-`$9385` (5257 bytes) reconstruido como datos** — **sin tramos pendientes** |

`MUMMY.BAS` es el cargador: dibuja a mano (con `PLOT`/`DRAW`
relativos) el logo "AMSOFT" (191 trazos, ya visibles en
`recursos/portada.html`), el título "Oh Mummy" con un efecto de
partículas, el crédito **"PRESENTS 1984 GEM SOFTWARE"** (el estudio
que desarrolló el juego — ver `AVISO-LEGAL.md`) y "LOADING......",
y termina con `MEMORY 15000:LOAD"!mummy1",&6000:CALL &6000` — de ahí
salen, confirmadas contra el propio BASIC (no contra la cabecera
AMSDOS, que resultó ambigua), la dirección de carga **y** de ejecución
del motor: `$6000`.

El primer tramo del motor (`$6000`-`$6400`) está desensamblado y
verificado byte a byte. Las **12 rutinas de firmware** que llama están
identificadas contra el manual oficial del CPC (`EQU` con nombre real
en `src/mummy1_body.asm`: gestión de sonido, texto, pantalla...).

Más allá de ese tramo, siguiendo el hilo real de llamadas (no
linealmente), **38 subrutinas internas (1681 bytes, el 12.7% del
motor) ya tienen nombre funcional real y están reconstruidas como
código fuente compilado**, formando un único bloque contiguo
`$786C`-`$7EFC` (fusionado en la Sesión 7 al cerrar el hueco de 142
bytes entre los bloques de las Sesiones 3 y 6). Incluye
`GENERAR_ALEATORIO`/`MEZCLAR_ALEATORIO`
(generador pseudoaleatorio sembrado con el reloj del sistema),
`ACTUALIZAR_SECUENCIA_SONIDO` (avanza una tabla **circular** de guion
de sonido y encola sonido con el firmware), `HAY_COLISION`
(colisión entre entidades y contra el mapa), `ELEGIR_DIRECCION_HACIA_OBJETIVO`
y `CALCULAR_CASILLA_ADYACENTE` (movimiento en rejilla),
`COLOCAR_ENTIDAD`/`INICIALIZAR_ENTIDADES`/`INICIALIZAR_UNA_ENTIDAD`
(posible colocación de 6 enemigos o coleccionables), **`DIBUJAR_ENTIDAD`**
(429 bytes, un dispatcher que selecciona una de ~20 tablas de sprite de
4x16 bytes según tipo de entidad, dirección y un fotograma de
animación), `DIBUJAR_CASILLA_MAPA` (lo mismo para 9 tablas de casillas
de 2x8 bytes), y — la Sesión 7 — `RELLENAR_MARCO_MEDIO`/`_SOLIDO`/`_VACIO`
y `RELLENAR_MARCO_DIAGONAL_1..6` (rellenan una casilla de 24x10 bytes
del marco decorativo con una máscara constante o con dos máscaras
alternadas fila a fila vía código automodificable; corrige una
hipótesis previa que las daba por "variantes de máscara AND/OR" — no
hay ninguna instrucción AND/OR real en el bloque). **Todos los nombres
son provisionales** (cada uno con su comentario de hipótesis y nivel de
confianza en el propio código, ver `FINDINGS.md`) — ninguno verificado
todavía ejecutando el juego en un emulador.

Más allá del código, la **Sesión 8** cerró por completo el resto del
motor (`$7EFD`-`$9385`, 5257 bytes) confirmando que es **dato, no
código** — ningún `CALL`/`JP` ya reconstruido aterriza ahí dentro. Ahí
vive el **texto real del juego**: la pantalla de opciones (velocidad,
dificultad, música y efectos de sonido), el "STOP PRESS" del modo
atracción (la excavación de la pirámide egipcia), la tabla HI-SCORE
con sus 5 rangos ("Stupendous", "Excellent"...) y umbrales de
puntuación, el menú principal, y el copyright real **`"OH MUMMY" (c)
1984 GEM SOFTWARE`** (confirma `AVISO-LEGAL.md`). También las 6
envolventes de sonido, las 4 tablas del marco decorativo (72 bytes
cada una, límites confirmados por el propio código que las usa), y el
guión de sonido circular (90 registros de 9 bytes, hasta el último
byte del motor). La **Sesión 12** promovió el primer tramo del último
hueco (`$6401`-`$6528`, 296 bytes): los dos puntos de entrada reales
tras la pantalla de "introducir nombre" (`FIN_INTRODUCIR_NOMBRE` y
`DESPACHAR_MENU_PRINCIPAL`, que lee P/I/O para jugar/instrucciones/
opciones) y la pantalla completa de opciones (`PANTALLA_OPCIONES`:
velocidad y dificultad de partida 1-5, música y efectos de sonido
Y/N).

La **Sesión 13** promovió dos tramos más, siguiendo el hilo desde el
punto de entrada `$6529` (tecla P/p): `INICIAR_PARTIDA`/`PREPARAR_NIVEL`
(arranque de partida y de cada nivel: vidas=5, puntuación=0),
`PREPARAR_TESOROS_NIVEL` (coloca 14 tesoros al azar con 4 valores
crecientes y un valor común repetido), `ACTUALIZAR_HUD_VIDAS` (dibuja
en el HUD tantos iconos de jugador como vidas queden),
`SELECCIONAR_DIAGONAL_MARCO_NIVEL` (encuentra un primer llamador de
`RELLENAR_MARCO_DIAGONAL_1..6` que quedaba pendiente desde la Sesión 7),
`COLOCAR_JUGADOR_INICIAL`, `BUCLE_PRINCIPAL_JUEGO` (el bucle de juego
por turnos, con 5 llamadas internas resueltas por la Sesión 14), y las
pantallas de fin de partida `PANTALLA_STOP_PRESS` (al completar los 6
niveles) y `PANTALLA_GAME_OVER`/`ACTUALIZAR_TABLA_PUNTUACIONES` (al
morir — confirma que solo este segundo camino inserta la puntuación en
la tabla HI-SCORE). Cierra además, por separado, el último tramo del
`INCBIN` original (`$7863`-`$786B`, `IMPRIMIR_PUNTUACION_HUD`).

La **Sesión 14** cierra el **último hueco `INCBIN` que quedaba en todo
el motor** (`$68B2`-`$7862`, 4017 bytes): `PANTALLA_INSTRUCCIONES` (la
pantalla de instrucciones real del juego, entrada `'I'` del menú, con
sus 23 párrafos de texto literal en inglés — historia, reglas del
tablero de 20 casillas, controles y niveles de dificultad) y, sobre
todo, las **5 llamadas del bucle de juego** que quedaban sin resolver
desde la Sesión 12: `PROCESAR_ENCUENTROS_ENTIDADES` (colisión con
tesoros/momias guardianas), `PROCESAR_MOVIMIENTO_JUGADOR` (lectura de
teclado/joystick y movimiento real del jugador — reutiliza la misma
lógica de `MOVER_INDICADOR_MENU`), `ACTUALIZAR_MARCO_TRAS_MOVIMIENTO`
(detecta el paso por una intersección de la rejilla y pinta el lado de
casilla recorrido), `COMPROBAR_SALIDA_NIVEL` (Llave + Momia Real
descubiertas → salida del nivel) y `ANIMAR_APARICION_MOMIA_GUARDIANA`
(anima la Momia Guardiana "cavando" para salir de su caja). Con esto,
**el motor completo (`$6000`-`$9385`) está reconstruido como fuente
ensamblador, sin ningún hueco `INCBIN` de código sin analizar** — ver
`FINDINGS.md` para el mapa de llamadas completo, la tabla de confianza
por rutina/dato, y la metodología usada.

Con el motor ya completo, las **Sesiones 15-18** extrajeron a fichero
individual los últimos gráficos que quedaban como `DB` inline: las 14
losetas de la familia de pisadas (Sesión 15, `src/data/img/tiles/`) y,
sobre todo, se corrigió una identidad equivocada desde la Sesión 3: las
4 tablas `TABLA_MARCO_1..4`/rutinas `DIBUJAR_TRAMO_MARCO_1..4`, dadas
por hechas como "tramos del marco decorativo del nivel" sin haber
verificado nunca su contenido a nivel de píxel, resultaron ser (Sesión
16, explorador parametrizable en `recursos/sprites.html`; Sesión 17,
identificación visual del usuario corroborada por el único llamador
real de cada rutina) los **4 iconos de contenido de casilla**:
sarcófago (Momia Real), llave, pergamino y tesoro. Renombradas a
`TABLA_ICONO_*`/`DIBUJAR_ICONO_*` y, ya confirmada su naturaleza de
sprite, a `SPRITE_ICONO_*` con extracción a fichero individual (Sesión
18, `src/data/img/sprites/`).

Las **Sesiones 19-20** revisaron todo el fichero buscando saltos
"mecánicos" que no tendría un fuente original: 29 bucles `DJNZ`/`JR`
internos y las 227 instrucciones `CALL`/`JP`/`JR` que saltaban a una
dirección `$XXXX` literal reciben etiqueta funcional, una a una, tras
leer el contexto real de cada destino — el barrido final confirma
**cero** direcciones literales de este tipo en todo
`src/mummy1_body.asm`, incluido el punto de entrada más citado del
fichero, `VOLCAR_SPRITE_A_PANTALLA` ($7CC4, 26+ llamadores). De paso se
corrigió una hipótesis dada por buena desde la Sesión 3:
`REPETIR_CARACTER` no repite un carácter fijo, imprime una secuencia de
bytes con longitud — renombrada `IMPRIMIR_BYTES_CON_LONGITUD`, con el
mecanismo verificado con aritmética exacta de direcciones contra los
rótulos reales de `PANTALLA_OPCIONES`.

La **Sesión 21** localizó la tabla oficial completa de códigos de
control del Text VDU del firmware (Appendix VII del manual del CPC) y
reescribió los bloques de texto mixto (control+ASCII) del juego —menú
de opciones, historia del modo atracción, tabla de puntuaciones, menú
principal, copyright— con 32 constantes `CTRL_TXT_*` con nombre, tal y
como las habría escrito el programador original, en vez de hexadecimal
en bruto. La **Sesión 22** localizó los llamadores reales de
`TABLA_OFFSETS_DIAMANTE`/`VARIABLES_DIBUJO_MARCO` (renombradas
`TABLA_POSICIONES_INICIALES_ENTIDADES` y descompuestas en 4 variables
individuales) y auditó 24 etiquetas que parecían "sin invocador
aparente" — casi todas sí lo tenían (por caída natural o por dirección
literal sin sustituir); resolvió también `TABLA_PARAMETROS_
TRANSICION_PUNTUACIONES` (nombre erróneo: no tiene nada que ver con la
tabla de puntuaciones, son datos de inicialización de paleta/modo de
pantalla con 2 llamadores reales) y pasó a decimal los literales
hexadecimales cuyo significado real es una cantidad de juego (vidas,
puntos, tamaños de tabla...).

Las **Sesiones 23-25** hicieron el mismo trabajo con el sonido. La
música de fondo (`GUION_SONIDO_CIRCULAR`, 90 registros de 9 bytes) se
decodificó campo a campo contra el formato `SOUND QUEUE` del firmware
CPC (Sesión 23) y los 3 efectos de sonido puntuales (perder una vida,
tesoro, objeto encontrado) resultaron usar exactamente el mismo
formato, combinado con las 6 envolventes de volumen/tono ya conocidas
desde la Sesión 3 (Sesión 24 — de paso corrige el límite real de
`ENVOLVENTE_TONO_3`, que llevaba mezclados esos 3 bloques). Los 9
ficheros (música + 6 envolventes + 3 efectos) quedan extraídos a
`src/data/sound/*.bin`, con su `.txt` editable (round-trip byte a byte
verificado) y su `.wav` de referencia, usando herramientas propias
nuevas (`tools/guion_sonido_tool.py`/`_player.py`,
`tools/envolvente_sonido_tool.py`/`_player.py`, Sesiones 23 y 25).
Algunos detalles de bajo nivel del formato (el significado exacto de
una duración negativa en `SOUND QUEUE`, o del bit "Rendezvous") quedan
como hipótesis razonada a partir de los datos, sin confirmar en
emulador — ver `FINDINGS.md` Sesiones 23-25 para el detalle completo.

Compilar
--------
```
py tools/build_all.py
py tools/dsk_build.py
```
(o, en VSCode, `Ctrl+Shift+B` — tarea por defecto "Compilar todo +
generar dsk", ver `.vscode/tasks.json`).

El primer script ensambla `src/main.asm` con SjASMPlus (motor en
`src/build/mummy1.bin`) y tokeniza `src/load_disk/mummy_bas.bas` (en
`src/build/mummy.bas`), verificando cada uno byte a byte contra lo
extraído del `.dsk` original. El segundo **reconstruye el `.dsk`
completo desde cero** (cabecera del disco, cabeceras de las 40 pistas,
catálogo AMSDOS, área de datos) — no copia el original salvo en los
~1600 bytes que resultaron ser contenido sobrante no reconstruible
(relleno tras el contenido real de cada fichero dentro de sus bloques,
y los campos sin identificar de las cabeceras AMSDOS, ver
`FINDINGS.md`) — y compara el resultado byte a byte contra
`FISICO/Oh Mummy (1984)(Amsoft).dsk`: **hoy, 0 diferencias**. El
resultado queda en `build/ohmummy_reconstruido.dsk` (no versionado,
ver `.gitignore`).

Herramientas de solo lectura del disco, por separado:

```
py tools/dsk_catalog.py
py tools/dsk_extract.py
```

Estructura del repositorio
--------------------------
- `FISICO/` — el `.dsk` original y los ficheros extraídos de él
  (`extraido/`, catálogo AMSDOS, log de extracción; más adelante
  también el disassembly crudo). No se versiona (ver `.gitignore` y
  `AVISO-LEGAL.md`).
- `src/` — fuente ensamblador reconstruido: `main.asm` (entrada única
  de compilación), `mummy1_body.asm` (motor, `$6000` en adelante) —
  ver `src/README.md`/`FINDINGS.md`.
- `src/build/` — binarios compilados (`py tools/build_all.py`, no se
  versiona).
- `src/data/` — recursos ya identificados y extraídos a fichero
  individual, incluidos en la fuente vía `INCBIN`: `img/sprites/`
  (Sesión 8: los 16 sprites de `DIBUJAR_ENTIDAD` — `sprite_jugador_*`/
  `sprite_momia_*`, 64 bytes cada uno; Sesión 18: + 4
  `sprite_icono_sarcofago`/`_llave`/`_pergamino`/`_tesoro`, los iconos
  de contenido de casilla cuya identidad corrige la Sesión 17) e
  `img/tiles/` (Sesión 15: las 14 losetas de la familia de pisadas).
  `img/logo/`, `img/marco_decorativo/`, `img/texto/`, `niveles/` siguen
  vacíos por ahora. `sound/guion_sonido_circular.bin` (Sesión 23: los 810 bytes
  de `GUION_SONIDO_CIRCULAR`, música de fondo, con su `.txt` gemelo
  editable y su `.wav` de referencia — ver `tools/guion_sonido_tool.py`
  más abajo). `sound/envolvente_amplitud_1/2/3.bin` y
  `sound/envolvente_tono_1/2/3.bin` (Sesión 25: las 6 envolventes de
  volumen/tono, con `.txt` editable y `.wav` de demo de su forma) y
  `sound/sonido_perder_vida.bin`/`sonido_tesoro.bin`/
  `sonido_objeto_encontrado.bin` (Sesión 25: los 3 efectos puntuales,
  mismo bloque `SOUND QUEUE` de 9 bytes que la música pero combinado
  con una envolvente, con `.txt` editable y `.wav` real — ver
  `tools/envolvente_sonido_tool.py` más abajo). `mummy1_resto_sin_analizar.bin` ya NO tiene ningun
  `INCBIN` que lo referencie desde la Sesión 14 (el motor entero está
  reconstruido como fuente) — se deja en el árbol como referencia
  histórica del binario en bruto.
- `src/load_disk/` — cargador de disco (equivalente Amstrad al
  `load_cas/` de los proyectos hermanos de cinta): `mummy_bas.bas`, el
  BASIC del cargador detokenizado a texto editable.
- `build/` — entregable final, `ohmummy_reconstruido.dsk`
  (`py tools/dsk_build.py`, no versionado).
- `tools/` — herramientas Python propias: `dsk_common.py` (lectura de
  imágenes `.dsk` CPCEMU y del catálogo AMSDOS), `dsk_catalog.py`
  (listar catálogo), `dsk_extract.py` (extraer ficheros crudos),
  `amsdos_basic_tool.py` (detokenizar/tokenizar Locomotive BASIC),
  `z80_disasm.py` (desensamblador Z80 mecánico), `build_all.py`
  (compilar y verificar cada fichero por separado), `dsk_build.py`
  (reconstruir el `.dsk` completo desde cero y verificarlo byte a
  byte contra el original), `guion_sonido_tool.py` (Sesión 23:
  decodificar/codificar `GUION_SONIDO_CIRCULAR` -- binario <-> texto
  editable por notas musicales, con round-trip byte a byte),
  `guion_sonido_player.py` (sintetiza esa tabla a un `.wav` para poder
  escucharla), `envolvente_sonido_tool.py` (Sesión 25: decodificar/
  codificar las 6 envolventes de amplitud/tono y los 3 efectos de
  sonido puntuales -- binario <-> texto editable, con round-trip byte
  a byte) y `envolvente_sonido_player.py` (Sesión 25: sintetiza un
  `.wav` de demo para cada envolvente suelta y el `.wav` real de cada
  efecto puntual, combinando el registro `SOUND QUEUE` con su
  envolvente de amplitud/tono).
- `manuales/` — manuales técnicos de referencia, uno por subsistema,
  redactados al cerrar cada pieza (aún sin contenido).
- `recursos/` — páginas HTML autocontenidas (visores/inventarios):
  `mapa_memoria.html` (regiones confirmadas + subregiones hipótesis),
  `flujo_programa.html` (inventario de rutinas, firmware + hipótesis),
  `flujo_detallado.html` (Sesión 9: grafo real de llamadas `CALL`/`JP`/
  `JR` entre rutinas, con estado confirmado/hipótesis/pendiente por
  nodo y por relación, zoom, filtros por subsistema y búsqueda — el
  artefacto vivo del flujo de llamadas, se actualiza sesión a sesión),
  `flujo_secuencial.html` (orden de ejecución del arranque) y
  `portada.html` (el logo "AMSOFT" ya renderizado a partir de los 191
  trazos reales del BASIC) tienen contenido real desde la Sesión 3.
  `sprites.html` (Sesión 8: explorador interactivo de
  `TABLAS_SPRITE_CASILLA` con ancho/alto/modo CPC ajustables; Sesión
  16/17/18: explorador parametrizable y hoja completa que confirmó la
  identidad de los 4 iconos de contenido de casilla y los 16 sprites de
  jugador/momia — de los 1457 bytes de `TABLAS_SPRITE_CASILLA`, solo
  quedan 17 bytes genuinamente sin identificar, ver Sesión 21).
  `graficos.html` sigue vacío (las losetas de pisadas ya extraídas en
  la Sesión 15 se documentan en `sprites.html`/`mapa_memoria.html`, no
  ahí). También `ohmummy_referencia_binario.html`: documento de apoyo
  (aportado por el autor, no derivado del binario) con la hipótesis
  genérica de qué subsistemas esperar en un arcade de laberinto de
  CPC de 1984 — orienta la búsqueda, no sustituye la verificación
  contra los bytes reales.
- `dump/` — volcados de memoria/pantalla de un emulador real, usados
  como evidencia al verificar hallazgos (aún por crear).

Dependencias y entorno
-----------------------
- [SjASMPlus](https://github.com/z00m128/sjasmplus) — ensamblador Z80
  que se usará para recompilar la fuente reconstruida, mismo elegido
  en los proyectos hermanos de MSX y ZX Spectrum.
- Python 3 (`py` en Windows) — para las herramientas de `tools/`. Sin
  dependencias externas, solo librería estándar.
- Un emulador de Amstrad CPC (p. ej.
  [CPCemu](http://www.cpc-emu.org/) o
  [RetroVirtualMachine](https://www.retrovirtualmachine.org/)),
  opcional pero recomendado, para probar el resultado y contrastar
  hallazgos.
- Una copia legalmente obtenida del juego original (`.dsk`) si quieres
  verificar tú mismo la comparación byte a byte — este repositorio
  **no incluye** el volcado original, ver `AVISO-LEGAL.md`.

Ver también
-----------
`AVISO-LEGAL.md` para de quién es cada cosa, y `FINDINGS.md` para el
diario de descubrimientos con el detalle técnico completo de cada
sesión.
