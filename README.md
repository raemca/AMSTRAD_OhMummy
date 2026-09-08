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
**Sesión 13 — solo queda UN tramo del motor sin analizar (`$68B2`-`$7862`,
4017 bytes). Todo lo demás está reconstruido**: firmware identificado,
`.dsk` completo regenerado desde cero. El catálogo AMSDOS del disco
(`FISICO/Oh Mummy (1984)(Amsoft).dsk`, 194816 bytes, formato CPCEMU
estándar, 40 pistas x 1 cara, formato de datos 9x512, IDs de sector
`C1`-`C9`) solo tiene **2 ficheros**:

| Fichero | Bloques asignados | Estado |
|---|---|---|
| `MUMMY.BAS` | 3 (3072 bytes) | **detokenizado y verificado byte a byte** — `src/load_disk/mummy_bas.bas` |
| `MUMMY1.BIN` | 14 (14336 bytes) | motor, carga en `$6000`; **`$6000`-`$6400` (1025 bytes) desensamblado**, **`$6401`-`$6528` (296 bytes) reconstruido como código (Sesión 12)**, **`$6529`-`$68B1` (905 bytes) reconstruido como código (Sesión 13)**, **`$7863`-`$786B` (9 bytes) reconstruido como código (Sesión 13)**, **`$786C`-`$7EFC` (1681 bytes) reconstruido como código**, **`$7EFD`-`$9385` (5257 bytes) reconstruido como datos**, solo `$68B2`-`$7862` (4017 bytes, pantalla de instrucciones) pendiente |

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
`SELECCIONAR_DIAGONAL_MARCO_NIVEL` (**resuelve** el llamador de
`RELLENAR_MARCO_DIAGONAL_1..6` que quedaba pendiente desde la Sesión 7),
`COLOCAR_JUGADOR_INICIAL`, `BUCLE_PRINCIPAL_JUEGO` (el bucle de juego
por turnos, con 5 llamadas internas todavía sin resolver), y las
pantallas de fin de partida `PANTALLA_STOP_PRESS` (al completar los 6
niveles) y `PANTALLA_GAME_OVER`/`ACTUALIZAR_TABLA_PUNTUACIONES` (al
morir — confirma que solo este segundo camino inserta la puntuación en
la tabla HI-SCORE). Cierra además, por separado, el último tramo del
`INCBIN` original (`$7863`-`$786B`, `IMPRIMIR_PUNTUACION_HUD`). Solo
queda **un** tramo sin analizar en todo el motor (`$68B2`-`$7862`, 4017
bytes — la pantalla de instrucciones, entrada `'I'` del menú), incluido
tal cual con `INCBIN` — ver `FINDINGS.md` para el mapa de llamadas
completo, la tabla de confianza por rutina/dato, y la metodología
usada.

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
  `sprite_momia_*`, 64 bytes cada uno), `img/tiles/`, `img/logo/`,
  `img/marco_decorativo/`, `img/texto/`, `niveles/`, `sound/` (estos
  vacíos por ahora) y `mummy1_resto_sin_analizar.bin` (los 4017 bytes
  del motor todavía sin desensamblar, `$68B2`-`$7862`) — se irán promoviendo a fuente
  real a medida que avance el análisis.
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
  byte contra el original).
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
  `TABLAS_SPRITE_CASILLA` con ancho/alto/modo CPC ajustables — el
  formato real todavía no está confirmado). `graficos.html` (losetas)
  sigue vacío — no se ha extraído ningún gráfico de tiles todavía. También
  `ohmummy_referencia_binario.html`: documento de apoyo
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
