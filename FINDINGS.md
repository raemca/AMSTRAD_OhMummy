# FINDINGS — diario de descubrimientos (Amstrad CPC)

*Ingeniería inversa, análisis y documentación: Rafael Eduardo Martín Candial (raemca@hotmail.com)*

Diario cronológico, en el mismo espíritu que `FINDINGS.md` de los
proyectos hermanos de MSX (`MSX/proyectos/madmixgame`) y ZX Spectrum
(`SPECTRUM_MadMixGame`): aquí se documenta CÓMO se descubrió cada
cosa, sesión a sesión.

## Sesión 1 — 2026-09-01: entorno del proyecto y catálogo del `.dsk`

### Punto de partida

El directorio de este proyecto se reutilizó a partir del esqueleto de
`SPECTRUM_MadMixGame` (misma metodología, distinto juego y
plataforma): se retiraron todos los ficheros específicos de *Mad Mix
Game* (fuente Z80, sprites/tiles/niveles/sonido de esa reconstrucción,
documentación) manteniendo la estructura de carpetas como base —
`manuales/`, `recursos/`, `src/`, `tools/`, `build/`, `dump/`. Se
sustituyó `src/load_cas/` (cargador de cinta) por `src/load_disk/`
(cargador de disco), acorde a que Amstrad CPC usa unidad de disco, no
cinta, en este volcado concreto.

Se colocó en `FISICO/` el volcado original:
`Oh Mummy (1984)(Amsoft).dsk` (194816 bytes).

### Formato del `.dsk`

Cabecera "Disk-Information-Block" estándar de CPCEMU (no extendido,
firma `MV - CPCEMU / 16 May 97 18:37`):

- 40 pistas, 1 cara, tamaño de pista uniforme: 4864 bytes.
- 256 bytes de cabecera de disco + 40 × 4864 = 194816 bytes → cuadra
  exacto con el tamaño del fichero.
- Cada "Track-Info" (256 bytes) describe 9 sectores de 512 bytes, con
  IDs de sector `$C1`-`$C9` — es el formato **"Data"** habitual de
  AMSDOS de doble densidad, no el "System" (que usaría IDs `$41`-`$49`
  y reservaría las 2 primeras pistas para el sistema).

Herramienta propia: `tools/dsk_common.py` (parseo genérico de
Disk-Info + Track-Info + sectores, formato estándar únicamente — el
extendido no está implementado porque no hace falta con este volcado).

### Catálogo AMSDOS

El directorio AMSDOS vive en los 2 primeros bloques (1 bloque = 1024
bytes = 2 sectores) del área de datos, es decir, los 4 primeros
sectores de la pista 0 en orden de ID (`$C1`-`$C4`) → 2048 bytes = 64
entradas de 32 bytes. Solo 2 entradas no están marcadas como borradas
(`$E5`):

| Entrada | Usuario | Nombre | Bloques asignados | Tamaño (bloques × 1024) |
|---|---|---|---|---|
| 0 | 0 | `MUMMY.BAS` | `2,3,4` (3 bloques) | 3072 bytes |
| 1 | 0 | `MUMMY1.BIN` | `5..18` (14 bloques) | 14336 bytes |

Ningún fichero usa más de un extent (32 bytes de entrada de
directorio cubren hasta 16 KB por extent; ambos ficheros caben en uno
solo). El área de datos AMSDOS empieza en el bloque 2 (bloques 0 y 1
son el propio directorio).

Herramienta propia: `tools/dsk_catalog.py` — lista el catálogo y, para
cada fichero, valida su cabecera AMSDOS. Salida completa reproducible
ejecutando `py tools/dsk_catalog.py`.

### Cabeceras AMSDOS de 128 bytes

Ambos ficheros (`MUMMY.BAS`, `MUMMY1.BIN`) empiezan con una cabecera
AMSDOS de 128 bytes cuyo checksum (suma de los bytes 0-66 en módulo
65536, almacenada en los bytes 67-68 en little-endian) **valida
correctamente** en los dos casos:

- `MUMMY.BAS`: checksum `0x0465`.
- `MUMMY1.BIN`: checksum `0x04b6`.

Esto confirma que ambas cabeceras están intactas (no corruptas), y de
paso valida que `tools/dsk_common.py` está leyendo bien los bloques
del disco (el checksum solo cuadra si los 67 bytes están en el orden
correcto).

**Deliberadamente NO se ha decodificado el significado de los demás
campos de la cabecera** (tipo de fichero, dirección de carga,
dirección de ejecución, longitud real) — un primer intento manual
usando la tabla de offsets que recordaba de otros proyectos (`$12-13`
dirección de carga, `$15-16` longitud, `$17-18` dirección de
ejecución) dio valores que no cuadraban entre sí para ningún fichero
(p. ej. una "longitud lógica" mayor que el espacio total asignado en
bloques), lo que indica que esa tabla recordada de memoria no es
fiable sin verificarla contra una fuente primaria o, mejor,
directamente contra el propio disco. En vez de arriesgarme a dejar
escrito un dato incorrecto, `dsk_common.leer_cabecera_amsdos()` de
momento solo expone lo que el checksum permite dar por hecho sin
ambigüedad (usuario, nombre, extensión, y los 128 bytes crudos) — ver
el docstring de `CabeceraAmsdos` en `tools/dsk_common.py`.

**Pendiente para la próxima sesión** (ya con foco en desensamblado):
detokenizar `MUMMY.BAS` (BASIC tokenizado de Locomotive BASIC) para
encontrar la línea que hace el `LOAD`/`CALL` real de `MUMMY1.BIN` —
eso dará la dirección de carga y de ejecución reales por la vía
fiable (el propio código que las usa), en vez de fiarse de la tabla de
offsets de la cabecera. Un vistazo rápido al contenido de
`MUMMY.BAS` (sin detokenizar todavía, solo cadenas ASCII visibles)
muestra que buena parte del programa dibuja a mano, con listas de
coordenadas relativas, el título "Oh Mummy" y probablemente el logo
"AMSOFT" en pantalla — es decir, es la pantalla de carga en BASIC,
como se esperaba.

### Extracción

`tools/dsk_extract.py` vuelca cada fichero del catálogo, tal cual
(con su cabecera de 128 bytes incluida, sin decodificar), a
`FISICO/extraido/`, y deja `FISICO/extraido/extraccion.log` con el
resultado. `FISICO/` completo está en `.gitignore` (material con
copyright, ver `AVISO-LEGAL.md`), así que esto se reproduce localmente
con `py tools/dsk_extract.py`, no se versiona.

### Plantillas de `recursos/`

Se crearon las 6 páginas HTML previstas (`mapa_memoria.html`,
`graficos.html`, `sprites.html`, `portada.html`,
`flujo_programa.html`, `flujo_secuencial.html`), con el mismo lenguaje
visual que las de los proyectos hermanos (autocontenidas, sin red,
tema claro/oscuro automático) pero **sin ningún dato real todavía** —
cada una lo indica explícitamente y expone un array JS vacío
(`TILES`, `SPRITES`, `TRAZOS`, `RUTINAS`, `REGIONS`) listo para
rellenarse a medida que avancen las próximas sesiones, en vez de
reconstruir de golpe las versiones completas (20-77 KB) de *Mad Mix
Game*, que además usan un formato gráfico (bitmap monocromo ULA) que
no aplica tal cual al Amstrad CPC. `flujo_secuencial.html` sí lleva ya
6 fases de contenido, marcadas cada una con su nivel de confianza real
(confirmado por catálogo / hipótesis sin verificar / pendiente) — es
la única página con algo más que el esqueleto, porque ya sabíamos algo
concreto que decir tras esta sesión.

### Nota sobre el repositorio git

Este directorio reutiliza el historial git de `SPECTRUM_MadMixGame`
(mismo `.git`, historial compartido con ese otro proyecto). El remoto
`origin` se ha repuntado a `github.com/raemca/AMSTRAD_OhMummy.git`
(repositorio propio para Oh Mummy — es un juego distinto, sin relación
de código con *Mad Mix Game*). **Pendiente**: crear ese repositorio en
GitHub si todavía no existe (no se ha hecho desde aquí, no hay `gh`
disponible en el entorno) antes del primer `git push`.

### Pendiente para próximas sesiones

- Detokenizar `MUMMY.BAS` con una herramienta propia (equivalente a
  `zxbasic_tool.py` del proyecto de Spectrum, adaptada al dialecto y
  tabla de tokens de Locomotive BASIC del Amstrad CPC, distinta de la
  del Spectrum).
- A partir de ahí, confirmar dirección de carga y de ejecución reales
  de `MUMMY1.BIN`.
- Primer desensamblado mecánico de `MUMMY1.BIN` (herramienta por
  decidir — el proyecto de Spectrum usó `Z80Dasm.exe`; a confirmar que
  sirve igual para código Z80 puro de CPC, que no tiene las
  peculiaridades de mapeo de I/O del Spectrum pero sí las suyas
  propias del gate array y el CRTC).
- Repointar o crear el remoto git definitivo para este proyecto.

## Sesión 2 — 2026-09-01: detokenizado del BASIC, primer desensamblado y compilación operativa

### Fuentes técnicas consultadas

La sesión 1 dejó pendiente la tabla de tokens de Locomotive BASIC y el
significado exacto de los campos de la cabecera AMSDOS (un primer
intento de memoria dio resultados inconsistentes, ver Sesión 1). Esta
vez se ha ido a fuentes primarias en vez de reconstruir de memoria:

- Tabla completa de tokens de Locomotive BASIC (sin prefijo `$80-$FE`
  y con prefijo `$FF`):
  [cpctech.cpcwiki.de/docs/bastech.html](https://cpctech.cpcwiki.de/docs/bastech.html)
  (mirror estático de la documentación técnica de CPCWiki — el propio
  `cpcwiki.eu` devuelve 403 a peticiones automatizadas).
- Formato de la cabecera AMSDOS de 128 bytes:
  [cpctech.cpcwiki.de/docs/allhead.html](https://cpctech.cpcwiki.de/docs/allhead.html)
  y, para el campo problemático de la referencia a variable dentro de
  una línea tokenizada (marcador de tipo + puntero + nombre), el
  desensamblado real de la ROM de BASIC 1.1 en
  [github.com/Bread80/Amstrad-CPC-BASIC-Source](https://github.com/Bread80/Amstrad-CPC-BASIC-Source)
  (fichero `Detokenising.asm`) — la única fuente que realmente
  documenta ese mecanismo byte a byte, en vez de solo el formato de
  fichero.
- Cada dato tomado de estas fuentes se ha verificado además contra los
  bytes reales de `MUMMY.BAS` (ver más abajo) antes de darlo por
  bueno — no se ha confiado en ninguna fuente, ni siquiera primaria,
  sin contrastarla.

### Cabecera AMSDOS de 128 bytes: campos confirmados

Contrastando varias fuentes contra los bytes reales de `MUMMY.BAS` y
`MUMMY1.BIN` (con la validación del checksum, bytes 0-66, como ancla),
se confirman estos campos (offsets decimales):

| Offset | Campo | Verificación |
|---|---|---|
| 18 | Tipo de fichero (0=BASIC, 2=Binario) | `MUMMY.BAS`→0, `MUMMY1.BIN`→2, coincide con la extensión |
| 21-22 | Dirección de carga (16 bits LE) | `MUMMY.BAS`→`$0170` (la dirección canónica de carga de BASIC en el CPC); `MUMMY1.BIN`→`$6000`, coincide EXACTO con `LOAD"!mummy1",&6000` del propio cargador (ver abajo) |
| 24-25 | Longitud real (16 bits LE) | Coincide en los dos ficheros con la copia redundante de 64-65 |
| 64-65 | Longitud real (copia redundante) | Ídem |
| 67-68 | Checksum (suma bytes 0-66, mod 65536, LE) | Valida en los dos ficheros |

El resto de la cabecera (byte 0, bytes 97-126 con fragmentos de texto
como `'show down` en `MUMMY.BAS`...) es contenido no inicializado del
buffer de la herramienta que grabó el disco — **no se decodifica
como campo con significado**, y al reconstruir el `.bas` se lleva sin
tocar desde la cabecera original (ver `tools/amsdos_basic_tool.py`,
`tokenizar()`): no tiene sentido "regenerar" basura de memoria, solo
reproducirla tal cual para el byte-matching.

El campo "dirección de ejecución" (offset 26-27 según
`allhead.html`) resultó ser **`$0000` en los dos ficheros** — es
decir, AMSDOS no lo usa aquí; el `CALL &6000` real vive en el propio
BASIC, no en la cabecera. Buen recordatorio de por qué este proyecto
verifica contra el código antes de dar un campo por bueno.

### `tools/amsdos_basic_tool.py` — detokenizador/tokenizador de Locomotive BASIC

Herramienta propia (dialecto y tokens distintos de los del ZX
Spectrum, no es una adaptación de `zxbasic_tool.py` del proyecto
hermano). Formato de línea confirmado contra `MUMMY.BAS`: longitud
total (2 bytes) + número de línea (2 bytes) + tokens + `$00`.

Hallazgos del propio proceso de verificación (cada uno confirmado
contra bytes reales, no asumido):

- **Referencia a variable** (marcadores `$02`-`$0D`): marcador de tipo
  (1 byte) + puntero caché (2 bytes, siempre `$0000` en el fichero tal
  como se guarda) + nombre literal, último carácter con el bit 7
  puesto como terminador. Marcadores `$02`/`$03`/`$04` llevan sufijo
  explícito (`%`/`$`/`!`) derivado del propio marcador con
  `(marcador XOR $27) AND $FD`; marcadores `$0B`-`$0D` (tipo implícito
  vía `DEFINT`/`DEFREAL`/`DEFSTR`) no llevan sufijo. Verificado
  reconstruyendo `title$` byte a byte contra `MUMMY.BAS` real.
- **Números en expresiones**: dígitos 0-9 → token único (`$0E`-`$16`);
  10-255 → marcador `$19` + 1 byte; 256-65535 → marcador `$1A` + 2
  bytes LE. El token `$18` ("constante 10", según la documentación) no
  lo usa nunca el tokenizador real para el valor 10 — se comprobó que
  `MUMMY.BAS` codifica el 10 de `SPEED INK 40,10` con `$19,$0A`, no
  con `$18`.
- **`DATA`/`REM`/`'`**: el resto de la línea es texto literal, sin
  tokenizar — incluye el caso de `DEFINT`/`DEFREAL`/`DEFSTR`, cuyo
  argumento (rango de letras, p. ej. `a-z`) también es literal hasta
  el siguiente `:` o fin de línea (no hasta fin de línea completo,
  a diferencia de `REM`/`DATA`).
- **`GOTO`/`GOSUB`/`THEN`/`RESTORE`** seguidos de un número: ese número
  usa el token dedicado `$1E` (número de línea, 2 bytes) en vez de la
  codificación genérica — pero solo si el número aparece inmediatamente
  después (con espacios de por medio); si el siguiente elemento no es
  un número (p. ej. `THEN PLOT ...`), es una instrucción normal.

**Verificación**: `detokenizar(MUMMY.BAS)` → texto editable
(`src/load_disk/mummy_bas.bas`) → `tokenizar(...)` reproduce los 2564
bytes originales (cabecera de 128 + cuerpo de 2436) **0 diferencias**.
Cada uno de los puntos de arriba se descubrió precisamente porque el
primer intento de tokenizar NO reproducía el original — el
round-trip byte a byte fue el propio método de verificación, no una
comprobación posterior.

### El cargador, detokenizado: qué dice de verdad

`src/load_disk/mummy_bas.bas` (58 líneas). Resumen del flujo: dibuja
el logo "AMSOFT" letra a letra con `DRAWR`/`MOVER` relativos leídos de
tablas `DATA` (líneas 260-550, una `REM "X"` por letra), dibuja
"Oh Mummy" y le aplica un efecto de partículas (usa `TEST()` para leer
qué píxeles quedaron pintados por el `PRINT` del título y los vuelve a
`PLOT`ear desplazados), imprime **"PRESENTS"**, luego
`CHR$(164);" 1984  GEM SOFTWARE"` (ver `AVISO-LEGAL.md` — primera
confirmación de la autoría real del juego, tomada del propio binario,
no de una fuente externa) e "LOADING ......", y termina:

```
560 MEMORY 15000
570 LOAD"!mummy1",&6000
580 CALL &6000
```

Esto confirma, desde el propio código (no desde la cabecera AMSDOS,
que resultó ambigua — ver arriba), que **`MUMMY1.BIN` carga en `$6000`
y su punto de entrada es exactamente `$6000`** (el `CALL` salta al
primer byte del fichero cargado).

### `tools/z80_disasm.py` — desensamblador Z80 mecánico

Desensamblador propio, sin analizador de flujo, basado en la
descomposición clásica de opcodes Z80 en `x,y,z`/`p,q` (la misma que
usan la mayoría de desensambladores Z80 modernos). Cubre el juego de
instrucciones completo: sin prefijo, `$CB`, `$ED`, `$DD`, `$FD`,
`$DDCB`/`$FDCB`.

Dos bugs encontrados y corregidos durante la propia verificación
(round-trip contra SjASMPlus, ver más abajo):

1. Al decodificar una instrucción con prefijo `$DD`/`$FD`, el offset
   pasado a `_decode_main` apuntaba todavía AL byte de opcode real en
   vez de justo después — hacía que el propio prefijo se decodificara
   como si fuera el opcode, produciendo `None` (instrucción inválida)
   para casi cualquier instrucción indexada. Corregido incrementando
   el offset antes de la llamada recursiva.
2. **Quirk documentado del Z80**: en una instrucción `LD r,r'` donde
   uno de los dos operandos es `(HL)`/`(IX+d)` (registro 6), el OTRO
   operando usa siempre el H/L real, nunca `IXh`/`IXl`/`IYh`/`IYl` —
   no se pueden combinar indexado y semirregistro indocumentado en la
   misma instrucción. El desensamblador inicial no distinguía este
   caso y generaba operandos inválidos (`LD (IX+0),IXl` en vez de
   `LD (IX+0),L`).

### Primer desensamblado real de `MUMMY1.BIN`: `$6000`-`$6400`

Un barrido mecánico completo de los 13190 bytes del motor no genera
NINGÚN hueco (0 bytes sin decodificar) — lo cual **no significa que
todo sea código real**: el espacio de opcodes Z80 es tan denso que casi
cualquier secuencia de bytes (incluidos datos: tablas, gráficos,
niveles) se "decodifica" en alguna instrucción sintácticamente válida
aunque no tenga sentido semántico. Por eso esta sesión NO se ha
tratado el bloque completo como código de golpe (habría sido
"desensamblado falso", justo lo que este proyecto evita — ver
`AVISO-LEGAL.md`/`.github/CONTRIBUTING.md`): se ha desensamblado a
mano, inspeccionado instrucción a instrucción, solo el primer tramo
(`$6000`-`$6400`, 1025 bytes) — hasta un punto de corte limpio (límite
de instrucción), no hasta donde "se acababa el código real" (eso
todavía no se sabe).

Lo que se ve en ese tramo (sin nombres semánticos todavía, es
reconstrucción mecánica — ver `.github/CONTRIBUTING.md` sobre no dar
nombres sin verificar):

- Llamadas repetidas a direcciones fijas `$BB09`, `$BB1E`, `$BB5A`,
  `$BB66`, `$BB6C`, `$BB75`, `$BB96`, `$BC1D`, `$BCA7`, `$BCBC`,
  `$BCBF`, `$BD0D` — caen en el rango `$BB00-$BFFF` del "fixed
  jumpblock" del firmware del CPC (rutinas de sistema en direcciones
  fijas, técnica estándar en juegos de la época en vez de usar
  `RST`/vectores indirectos). Sin identificar todavía cuál es cada
  una — haría falta la lista oficial de direcciones del firmware
  (pendiente para una próxima sesión).
- Llamadas repetidas a `$78D1` (aparece decenas de veces, muy
  probablemente una espera de VBL/sincronismo de vídeo o similar, dado
  el patrón de uso entre bloques) y a otras direcciones internas
  (`$786C`, `$7893`, `$78B7`, `$78F7`, `$794F`, `$7B39`, `$7D85`,
  `$7D9D`, `$7DB5`, `$7DCD`, `$7DFC`, `$7E05`, `$7E0E`, `$7E17`,
  `$7E29`, `$7EAB`, `$7EB9`, `$7EF4`) — todas dentro del propio
  `MUMMY1.BIN` (rango `$6000`-`$9385`), en la zona todavía sin
  desensamblar. Sin identificar qué hace cada una.
- Un tramo final ($6217-$63FE aprox.) con el patrón `CALL $BB09` +
  `JR C,...` repetido, comparaciones `CP $0D` (Enter) y `CP $7F`
  (Delete/Backspace), y escritura carácter a carácter en un buffer
  (`LD (HL),A:INC HL` sobre una dirección guardada en `$7FC8`) —
  **hipótesis sin confirmar**: podría ser una pantalla de introducción
  de texto (nombre del jugador o similar), consistente con
  `ohmummy_referencia_binario.html` (HUD/nombre de jugador), pero
  NO se da por confirmado sin más contexto (qué pasa antes/después,
  dónde se usa el buffer).

### Compilación operativa: `tools/build_all.py`

`src/main.asm` (`INCLUDE mummy1_body.asm` + `SAVEBIN`) ensambla con
SjASMPlus sin errores. `mummy1_body.asm` = el tramo desensamblado a
mano (`$6000`-`$6400`) + `INCBIN "data/mummy1_resto_sin_analizar.bin"`
(los 12165 bytes restantes, extraídos tal cual del binario real, sin
analizar). Resultado:

```
[OK] src/build/mummy1.bin (motor, $6000-$9385): 13190 bytes, 0 diferencias
[OK] src/build/mummy.bas (cargador): 2564 bytes, 0 diferencias
```

Ambos ficheros reconstruidos coinciden byte a byte con lo extraído del
`.dsk` original. El motor es una reconstrucción HÍBRIDA a día de hoy
(cabecera desensamblada de verdad + cola sin analizar vía `INCBIN`) —
igual que empezaron los proyectos hermanos, promoviendo tramos de
`INCBIN` a fuente real sesión a sesión. **Todavía no hay** empaquetado
de vuelta a `.dsk` completo (eso comparará contra el `.dsk` entero,
no fichero a fichero) — pendiente.

### Pendiente para próximas sesiones

- Identificar las direcciones del firmware CPC llamadas (`$BBxx`/
  `$BCxx`/`$BDxx`) contra la lista oficial del "fixed jumpblock" y
  ponerles nombre (`EQU`).
- Seguir desensamblando a mano desde `$6401` en adelante, promoviendo
  tramos de `mummy1_resto_sin_analizar.bin` a código real en
  `mummy1_body.asm` (o a datos identificados en `src/data/` cuando
  corresponda — losetas, sprites, niveles, sonido).
- Confirmar o descartar la hipótesis de pantalla de introducción de
  texto en `$6217`-`$63FE`.
- Empaquetador `.dsk` completo (equivalente a `gen_tzx_file.py`),
  verificado byte a byte contra `FISICO/Oh Mummy (1984)(Amsoft).dsk`
  entero.
- Rellenar las plantillas de `recursos/` con datos reales a medida que
  haya algo que mostrar.

## Sesión 3 — 2026-09-01: análisis por llamadas desde `$6000`, identificación del firmware y primeras hipótesis semánticas

Sesión guiada por un prompt propio (`prompts/sesion_03_desensamblado_6000.md`):
analizar el bloque `$6000`-`$6400` ya verificado como una función
principal, clasificar cada `CALL`, y desensamblar/documentar las
rutinas internas que llama — sin avanzar linealmente por
`$6401`-`$9385` a ciegas.

### Fuentes técnicas consultadas

- Tabla oficial completa del "fixed jumpblock" del firmware
  (direcciones `$BB00`-`$BD5D`): *AMSTRAD CPC464/664/6128 FIRMWARE*,
  sección 14.1, vía
  [cpctech.cpcwiki.de/docs/manual/s968se14.pdf](https://cpctech.cpcwiki.de/docs/manual/s968se14.pdf)
  (el PDF no es legible directamente por la herramienta de scraping —
  hubo que descargarlo y leerlo con el lector de PDF local). Es la
  lista **oficial y completa**, no una reconstrucción de memoria.
- Intento de identificar los códigos de tecla usados en `$6217`
  (`$3E`) y `$7893` (`$2C`): la tabla de la librería CPCtelera
  ([lronaldo.github.io](https://lronaldo.github.io/cpctelera/files/keyboard/keyboard-h.html))
  da "Key_C"/"Key_H" para esos valores, pero es la numeración propia
  de esa librería (`cpct_keyID`), **no necesariamente la misma
  numeración que usa `KM TEST KEY`** del firmware real (que sigue la
  fórmula `linea*8+bit` de la matriz de teclado). Como no se pudo
  confirmar que ambas numeraciones coincidan, **no se identifica
  ninguna tecla concreta todavía** — queda pendiente contrastar contra
  la tabla oficial de la sección 3 del firmware (`s968se03.pdf`).

### Rutinas de firmware identificadas (confirmadas, tabla oficial)

Las 12 direcciones de firmware llamadas desde `$6000`-`$6400` están
ahora nombradas con `EQU` en `mummy1_body.asm`:

| Dirección | Nombre oficial | Qué hace |
|---|---|---|
| `$BB09` | KM READ CHAR | Test si hay carácter de teclado disponible |
| `$BB1E` | KM TEST KEY | Test si una tecla concreta está pulsada |
| `$BB5A` | TXT OUTPUT | Sacar carácter/código de control al Text VDU |
| `$BB66` | TXT WIN ENABLE | Fijar tamaño de la ventana de texto actual |
| `$BB6C` | TXT CLEAR WINDOW | Borrar la ventana de texto actual |
| `$BB75` | TXT SET CURSOR | Fijar posición del cursor de texto |
| `$BB96` | TXT SET PAPER | Fijar tinta de fondo para texto |
| `$BC1D` | SCR DOT POSITION | Convertir coordenadas base a dirección de pantalla |
| `$BCA7` | SOUND RESET | Reset del gestor de sonido |
| `$BCBC` | SOUND AMPL ENVELOPE | Definir una envolvente de amplitud |
| `$BCBF` | SOUND TONE ENVELOPE | Definir una envolvente de tono |
| `$BD0D` | KL TIME PLEASE | Leer el contador de tiempo transcurrido |

(`$BCAA` SOUND QUEUE también aparece, pero dentro de `$78D1`, fuera
del tramo compilado — ver más abajo.)

### Mapa de llamadas desde `$6000` (primer nivel)

```
$6000 (entrada real)
 ├─ FIRM_SOUND_RESET ($BCA7)
 ├─ FIRM_SOUND_AMPL_ENV / FIRM_SOUND_TONE_ENV ($BCBC/$BCBF) x3   -- 3 envolventes
 ├─ FIRM_KL_TIME_PLEASE ($BD0D)                                  -- hipotesis: semilla aleatoria
 ├─ $78D1   (docenas de veces, intercalada en todo el bloque)    -- hipotesis: bombeo de sonido
 ├─ $7EAB                                                        -- hipotesis: borrar bloque $8172+1181b
 ├─ $7EF4   (x varias)                                           -- hipotesis: repetir caracter N veces
 ├─ FIRM_SCR_DOT_POSITION ($BC1D), en bucle x200                 -- tabla de direcciones de fila, $8ECA-$905A
 ├─ $7EB9   (x14, con pares HL/DE distintos)                     -- hipotesis: borrar rectangulo de ventana
 ├─ FIRM_TXT_WIN_ENABLE ($BB66)                                  -- fijar ventana 40x25 completa
 ├─ $7D85 / $7D9D / $7DB5 / $7DCD                                -- hipotesis: dibujar marco decorativo
 │   └─ (cada una) $7DED o $7DE5 -> $7E73 -> uno de:
 │        $7DFC / $7E05 / $7E0E / $7E17 / $7E20 / $7E29          -- 6 variantes de mascara AND/OR
 │        └─ $7E30 (comun) -> $7E59 -> $7E92
 ├─ $794F -> $795B (bucle x6, contador en $8169)                 -- sin resolver
 └─ $6201-$6221: bucle de menu
     ├─ FIRM_KM_READ_CHAR ($BB09)
     ├─ $78B7 -> $7996, $78D1                                    -- hipotesis: animar/temporizar opcion
     ├─ $78F7 -> $7B39                                           -- hipotesis: posicionar indicador de opcion
     ├─ $7893 -> $78D1, FIRM_KM_READ_CHAR                        -- hipotesis: esperar tecla (con antirrebote)
     └─ FIRM_KM_TEST_KEY ($BB1E)                                 -- hipotesis: tecla de confirmar
```

### Hipótesis por subrutina interna (ninguna verificada en emulador — solo por patrón de código)

| Dirección | Hipótesis | Confianza | Evidencia |
|---|---|---|---|
| `$78D1` | Bombea una cola/guión de sonido | Media | Referencia puntero `$905A`↔`$905C`..`$937D` (paso de 9 bytes), llama `SOUND QUEUE` condicionalmente |
| `$7EAB` | Borra (a 0) un bloque de 1182 bytes en `$8172` | Alta | `LD (HL),0` + `LDIR` con origen=destino-1, patrón estándar de relleno |
| `$7EF4` | Repite un carácter N veces vía `TXT OUTPUT` | Alta | `B=(HL)` cuenta, `A=(HL+1)` carácter, bucle sin avanzar el puntero de lectura |
| `$7EB9` | Borra un rectángulo de una tabla en `$81D8` (paso 40 bytes/fila) | Media-alta | Doble bucle escribiendo `$20` (espacio), paso de fila = ancho de pantalla en modo texto |
| `$7D85`/`$7D9D`/`$7DB5`/`$7DCD` | Dibujan tramos del marco decorativo | Media | Cada una fija una tabla de offset distinta y llama a una rutina común (`$7E73`) que usa máscaras AND/OR |
| `$7DFC`/`$7E05`/`$7E0E`/`$7E17`/`$7E20`/`$7E29` | 6 variantes de patrón de relleno (máscara+valor) para el marco | Media | Cada entrada carga un par de bytes distinto y cae a un tronco común (`$7E30`) |
| `$786C` | Imprime un número de 16 bits (HL) en 4 dígitos decimales vía `TXT OUTPUT` | Media-alta | Bucle de 4 dígitos, resta repetida contra tabla de valor posicional, `+$30` (ASCII) antes de imprimir — patrón clásico de HUD/marcador |
| `$7893` | Espera una tecla concreta, con antirrebote (pulsación + liberación) | Alta | `KM READ CHAR`/bombeo de sonido intercalados, `KM CHAR RETURN` al final |
| `$78B7` | Anima o temporiza la opción de menú resaltada | Baja | Cuenta atrás en `$8153`, ajusta `B` con tope en `$15`=21 |
| `$78F7` | Posiciona un indicador según la opción de menú activa | Baja | Compara `$8155` contra `$1A`/`$34`, llama `$7B39` con `A=$54` |
| `$7B39` | Dibuja/actualiza el indicador de selección de menú | Baja | Ramifica por el carácter en `A` (`$20`,`$54`,`$41`,`$4F`...), usa tablas `$8919`/`$8959`/`$8A89`... |
| `$794F` | Repite `$795B` 6 veces (contador en `$8169`) | Baja | Sin más contexto todavía |

### Separación código/datos observada

- **Datos identificados dentro del rango `$6000`-`$6400`** (no se han
  extraído a fichero todavía, son referencias hacia fuera del tramo
  compilado): tablas de envolvente de sonido en `$7FCA`/`$7FD4`/
  `$7FDE` (amplitud) y `$7FE5`/`$7FF5`/`$7FF9` (tono); tabla de 400
  bytes de direcciones de pantalla por fila, construida en tiempo de
  ejecución en `$8ECA`-`$905A` (no es un dato estático del binario,
  se genera al arrancar).
- **Datos dentro de las subrutinas exploradas** (aún en
  `mummy1_resto_sin_analizar.bin`, sin extraer): la tabla de 4 valores
  de 16 bits en `$8736`+ que usa `$786C` (posicional para conversión
  decimal); las tablas de offset de `$877D`/`$87C5`/`$880D`/`$8855`
  que usa el dibujado del marco; las tablas `$8919`/`$8959`/`$8A89`+
  que usa `$7B39`.
- **Ningún hueco sin decodificar** en el barrido mecánico completo
  (ver Sesión 2) — se reitera que esto no prueba que todo sea código
  real, solo que el espacio de opcodes Z80 es denso.

### Cambios en `mummy1_body.asm`

- Bloque de `EQU` para las 12 rutinas de firmware identificadas,
  sustituyendo las direcciones literales por nombres en todo el
  fichero (41 sustituciones).
- Comentarios explicativos junto a los patrones identificados
  (envolventes de sonido, tabla de direcciones de pantalla, borrado de
  bloque, repetición de carácter, borrado de rectángulos, marco
  decorativo, menú de selección) — cada uno citando esta sección de
  `FINDINGS.md` y marcado explícitamente como hipótesis sin verificar
  en emulador cuando la confianza no es alta.
- **Ninguna subrutina interna nueva se ha promovido a código
  compilado todavía** — siguen dentro de
  `data/mummy1_resto_sin_analizar.bin` vía `INCBIN`. Promoverlas
  exigiría desensamblarlas y verificarlas con el mismo rigor que el
  tramo `$6000`-`$6400` (ver Sesión 2), que no ha dado tiempo a
  completar para las ~19 rutinas exploradas esta sesión.
- **Verificado**: `py tools/build_all.py` sigue dando 0 diferencias en
  ambos ficheros tras estos cambios (los `EQU` y comentarios no alteran
  ni un byte del binario compilado).

### Pendiente para próximas sesiones

- Desensamblar y verificar (promover a fuente compilada real) las
  subrutinas de mayor confianza primero: `$7EAB`, `$7EF4`, `$7EB9`,
  `$786C` — son las que tienen hipótesis más sólidas.
- Extraer a fichero individual las tablas de datos ya localizadas
  (envolventes de sonido `$7FCA`-`$7FFE`, tabla posicional de
  `$786C` en `$8736`+, tablas de offset del marco en `$877D`+).
- Resolver la numeración real de teclas del firmware (`KM TEST KEY`)
  contra la sección 3 del manual oficial (`s968se03.pdf`) para poder
  confirmar o descartar la hipótesis del menú de selección y las
  teclas `$2C`/`$3E`.
- Seguir el hilo de llamadas más allá de `$6400` de la misma forma
  (por subrutina, no linealmente) — en particular `$7E73`, `$7E92`,
  `$7996`, `$7B39` y sus propias llamadas internas, que esta sesión
  solo ha esbozado.
- La hipótesis de pantalla de introducción de texto en
  `$6217`-`$63FE` (Sesión 2) sigue sin confirmar.

### Pase complementario: documentación (mismo día, `prompts/sesion_03_complementaria_documentacion.md`)

Sesión dedicada exclusivamente a propagar los hallazgos de arriba al
resto de la documentación del proyecto (sin desensamblar nada nuevo):

- `README.md`/`README.en.md`: "Estado actual" actualizado a Sesión 3
  (firmware identificado, subsistemas con hipótesis).
- `src/README.md`: nueva sección "Subsistemas con hipótesis" con el
  resumen por area (sonido, pantalla/HUD, marco decorativo, menú).
- `recursos/flujo_programa.html`: las 12 rutinas de firmware
  (`estado: "ok"`) y las ~19 internas con hipótesis (`estado:
  "pendiente"`, nivel de confianza en la columna de notas).
- `recursos/flujo_secuencial.html`: fases reescritas con el detalle
  real de Sesión 2-3 — 5 fases pasan a `"confirmado"` (antes eran
  hipótesis o no existían: dibujado de la portada, carga del motor,
  envolventes de sonido, tabla de direcciones de pantalla), 3 quedan
  como `"hipotesis"` con su justificación.
- `recursos/mapa_memoria.html`: 3 regiones confirmadas (BASIC, cabecera
  del motor, resto sin analizar) en la barra principal, más una
  segunda tabla nueva de 9 "subregiones" (hipótesis localizadas por
  referencia, sin verificar) que no forman parte de la barra para no
  mezclar lo confirmado con lo hipotético visualmente.
- `recursos/portada.html`: el logo "AMSOFT" completo (191 trazos) ya
  se renderiza de verdad, calculado a partir de las coordenadas
  relativas reales de `mummy_bas.bas` (dato de Sesión 2 que no se
  había volcado aquí todavía).
- `recursos/graficos.html` y `recursos/sprites.html`: **sin cambios,
  deliberadamente** — ninguna sesión ha extraído todavía un gráfico de
  tiles o sprites en bruto (el marco decorativo se construye por
  código con máscaras AND/OR y tablas de offset, no es un recurso de
  bitmap); no hay nada que mostrar en estas dos páginas sin inventar
  contenido.

Todos los ficheros HTML tocados se comprobaron con un script de
balanceo de llaves/paréntesis antes de darlos por buenos (mismo método
que en la Sesión 1).

## Sesión 4 — 2026-09-01: sigue el hilo de llamadas más allá de `$6400` — posible generador de entidades aleatorias

Sesión guiada por `prompts/sesion_04_desensamblado_continuacion.md`:
continuar el análisis por llamadas desde `$6000` (no linealmente),
profundizando en las subrutinas que la Sesión 3 solo había esbozado.

### Intento de resolver los códigos de tecla `$2C`/`$3E` — sin éxito

Se intentó localizar la tabla oficial de numeración de teclas del
firmware (referenciada como "Appendix I" en la sección 3 del manual,
que sí se pudo leer completa vía
[cpctech.cpcwiki.de/docs/manual/s968se03.pdf](https://cpctech.cpcwiki.de/docs/manual/s968se03.pdf)).
El propio Apéndice I no está disponible en ningún espejo accesible
probado (`s968ap01.pdf` da 404; `cpcwiki.eu` bloquea las peticiones
automatizadas con 403; `docs/keyboard.html` del mismo sitio documenta
la matriz de escaneo pero no la numeración de teclas del firmware). Se
descarta explícitamente usar la tabla de la librería CPCtelera (ya
señalado en Sesión 3 que usa su propia numeración, no confirmada igual
a la del firmware). **Sigue pendiente** — no se identifica ninguna
tecla concreta.

### Rutinas nuevas exploradas (desensambladas hasta su `RET`)

| Dirección | Qué hace | Hipótesis | Confianza |
|---|---|---|---|
| `$7E92` | Indexa la tabla de 200 direcciones de pantalla por fila (`$8ECA`, ver Sesión 3) por fila+columna y sinal como direccion de pantalla en HL | Función auxiliar "coordenada (fila,columna) → dirección de pantalla", usa la tabla que en Sesión 3 solo se sabía que se *construía* | **Alta** (confirma y precisa la hipótesis de Sesión 3) |
| `$7E73` | Bucle de 12 "filas", cada una copia 6 bytes desde una tabla (`IY`) a pantalla/buffer y avanza con `INC H` (paso de 256, no el paso real de pantalla del CPC) | Dibuja un bloque gráfico de 6x12 bytes desde una tabla — el paso `INC H` sugiere que no escribe a la VRAM real directamente sino a un lienzo de trabajo en RAM con stride de 256 bytes (patrón ya visto en los proyectos hermanos) | Media |
| `$7D53` | Lee semilla de 16 bits en `$8151` (la misma que se sembró con `KL TIME PLEASE` al arrancar, Sesión 3), la transforma con `$7D78`, y hace un "módulo" por resta repetida contra `$0101`, actualizando la semilla | **Generador de números pseudoaleatorios** (congruencial/aditivo clásico de 8 bits) | **Alta** |
| `$7A10` | Recorre el array de 6 registros de 5 bytes en `$816D` (ver `$7996`/`$795B`) comparando la posición de cada uno contra `D,E` con margenes de ±8 (eje X) y ±2 (eje Y), contando coincidencias en `$8610` | Comprobación de proximidad/colisión entre una posición candidata y las entidades ya colocadas | Media-alta |
| `$7996` | Por cada registro de `$816D` (si está activo): guarda su posición, llama a `$7A10` dos veces (posición y posición+1 en X) y, si hay colisión, salta a `$7AF2`; si no, llama a `$7D53` (dado de nuevo) y en un caso concreto llama a `$7B39` con `A=$4F` ('O') | Coloca/valida la posición de una entidad, evitando solapes -- usa el generador aleatorio y el chequeo de proximidad de arriba | Media |
| `$795B` | Incrementa el contador `$816C`, usa dos llamadas a `$7D53` (dado, +1) para rellenar los bytes 0-1 de un registro nuevo en `$816D`, y copia 2 bytes de una tabla de posiciones (`$8645`, indexada por `contador*2`) a los bytes 2-3 | Inicializa un registro/entidad nuevo con atributos "aleatorios" (¿tipo, dirección?) y una posición tomada de una tabla de puntos válidos | Media-alta |

### Hipótesis de conjunto: generador de entidades al arrancar

Encadenando lo de arriba con lo ya sabido de la Sesión 3 (`$794F`
llama a `$795B` 6 veces, con el contador `$8169`/`$816C` puesto a 6 al
arrancar en `$6054`/`$623B`): la evidencia apunta a que el motor
**inicializa 6 "entidades"** (registros de 5 bytes en `$816D`-`$8196`)
en el arranque, cada una con posición tomada de una tabla de puntos
candidatos (`$8645`, que cambia de tabla según la pantalla — vista
apuntando a `$860F`/`$8637`/`$6828` en distintos momentos) y un par de
bytes "aleatorios" adicionales generados con el PRNG sembrado por el
reloj del sistema. Es coherente con la expectativa genérica de
`ohmummy_referencia_binario.html` ("colocación de... premios y
enemigos") y con que 6 sea el número de momias/enemigos o
coleccionables del laberinto — **pero esto NO está confirmado**: no
se ha llegado a ver qué campo decide "cuántas entidades son enemigos"
frente a "objetos", ni se ha ejecutado nada en un emulador para
comprobarlo. Ninguna de las direcciones de esta sección se ha
renombrado en `mummy1_body.asm` todavía.

### Separación código/datos (actualización)

Confirmado (no solo referenciado) que existe un array de registros de
5 bytes en `$816D`+ (al menos 6 registros = 30 bytes, `$816D`-`$818A`)
— cada registro: byte 0-1 (datos del PRNG, sin decodificar su
significado), byte 2-3 (posición X,Y probablemente), byte 4 sin
usar/observar todavía. Este array no estaba en la lista de
subregiones de la Sesión 3 (se solapa con el bloque `$8172`+ que se
creía "borrado a 0 y sin más" — hay que revisar esa hipótesis: `$816D`
cae ANTES de `$8172`, así que no hay conflicto, pero conviene
verificarlo con más cuidado en la próxima sesión).

### Documentación actualizada en esta sesión

- `README.md`/`README.en.md`: estado a Sesión 4, mención del generador
  de entidades.
- `src/README.md`: subsistema nuevo listado.
- `recursos/flujo_programa.html`: 6 rutinas nuevas añadidas al
  inventario (`$7E92`, `$7E73`, `$7D53`, `$7A10`, `$7996`, `$795B`).
- `recursos/mapa_memoria.html`: nueva subregión `$816D`-`$818A`
  (array de entidades).
- `recursos/flujo_secuencial.html`: nueva fase "generador de entidades
  aleatorias" entre la construcción del marco y el menú.
- `recursos/graficos.html`/`sprites.html`/`portada.html`: **sin
  cambios** — nada de lo descubierto esta sesión es un recurso gráfico
  extraíble (son rutinas de posicionamiento/aleatoriedad, no bitmaps).

### Pendiente para próximas sesiones

- Confirmar el significado exacto de los registros de `$816D` (qué es
  cada byte) y de dónde sale la tabla de posiciones candidatas en
  `$8645` (parece cambiar de tabla según contexto — localizar cada una).
- Desensamblar `$7D78` (la transformación usada por el PRNG), `$7A95`
  y `$7AB6`/`$7AF2` (los destinos condicionales de `$7996`).
- Seguir intentando resolver la numeración de teclas del firmware
  (Apéndice I) por otra vía -- quizas un volcado de la ROM real en vez
  del manual escaneado.
- Retomar la lista de subrutinas de alta confianza de la Sesión 3
  (`$7EAB`, `$7EF4`, `$7EB9`, `$786C`) para promoverlas a código
  compilado real (con `INCBIN` partido alrededor) si el hilo de
  llamadas lo justifica.

## Sesión 5 — 2026-09-01: posible IA de persecución y mapa del laberinto

Sesión guiada por `prompts/sesion_05_firmware_y_rutinas_internas.md` —
continúa el hilo de llamadas pendiente de la Sesión 4 (`$7D78`,
`$7A95`, `$7AB6`, `$7AF2`).

### Rutinas nuevas exploradas

| Dirección | Qué hace | Hipótesis | Confianza |
|---|---|---|---|
| `$7D78` | Duplica HL 8 veces, sumando DE cuando la duplicación genera acarreo | Función de mezcla/dispersión del generador pseudoaleatorio de `$7D53` (no es una multiplicación de propósito general: no prueba bits de un multiplicador, prueba el acarreo interno) | Alta (refuerza la hipótesis de PRNG de la Sesión 4) |
| `$7A95` | Según un valor 0-3 en `A`, suma o resta 8 a la coordenada alta (`H`) o 2 a la baja (`L`) de una posición en `($8164)` | Calcular la posición de la celda adyacente en una direccion dada (pasos de rejilla 8/2, iguales a los margenes de colision de `$7A10`) | **Alta** |
| `$7AB6` | Compara una posición candidata `($8164)` contra una posición de referencia `($8155)/($8156)` eje a eje, codifica el signo de cada diferencia como una dirección (mismo esquema 1-4 que `$7A95`), y usa `$7D53` (aleatorio) para decidir aleatoriamente cuál de los dos ejes va primero | **Elegir dirección hacia un objetivo, con desempate aleatorio de eje** -- patrón clásico de IA de persecución en rejilla (tipo "fantasma" de laberinto) | Media-alta |
| `$7AF2` | Según la dirección en `($8159)`, calcula la posición adyacente (mismos pasos 8/2) y llama a `$7D3E` + `$7CE6` con el valor leído en esa celda | Comprobar qué hay en la casilla adyacente en una dirección dada, antes de moverse -- posible chequeo de colisión/transitabilidad | Media |
| `$7D3E` | `LD HL,$8200`; indexa por `(columna/2) + fila*5` | Acceso a una estructura en `$8200` con paso de fila de 5 bytes -- hipótesis: **mapa del laberinto o una subdivisión de él** (dimensión exacta sin confirmar: 5 bytes/fila es estrecho para un laberinto completo, podría ser una zona/pantalla, no el nivel entero) | Media (estructura sí, tamaño real no) |
| `$7CE6` | Segun el valor de `A` (en pasos de 2: 0,2,4,6,8...) selecciona una de varias tablas via `IY` (`$8959`, `$8A69`, `$8A89`, `$8AA9`, mas que no se llegaron a capturar) | Dispatcher: elegir una tabla de sprite/animación segun un valor de tipo de celda o entidad -- desensamblado parcial, no se alcanzó su `RET` | Baja-media (funcion parcial) |

### Hipótesis de conjunto (revisada)

La cadena `$7996` (valida/coloca una entidad) → `$7A10` (colisión con
otras entidades, pasos 8/2) → `$7AB6` (elegir dirección hacia un
objetivo con desempate aleatorio) → `$7A95`/`$7AF2` (mover un paso en
una dirección y comprobar la celda destino via `$7D3E`+`$7CE6`) encaja
de forma consistente con un **algoritmo de movimiento/persecución en
rejilla** — el tipo de lógica esperable en la IA de un enemigo que
persigue al jugador por un laberinto (ver
`ohmummy_referencia_binario.html`, "IA de enemigos: patrones de
desplazamiento, detección de perseguir"). Esto **no está confirmado**:
no se ha visto todavía el bucle de juego principal que llamaría a esto
fotograma a fotograma, ni se ha ejecutado nada en un emulador. Es
plausible que estas mismas rutinas de bajo nivel (calcular celda
adyacente, comprobar qué hay en ella) se reutilicen tanto para la
inicialización de entidades (Sesión 4) como para su movimiento en el
bucle de juego real -- de ahí que aparezcan ya en el arranque.

### Separación código/datos (actualización)

- `$8200`+: hipótesis de estructura de mapa/nivel, paso de fila de 5
  bytes -- sin extraer a fichero, sin confirmar sus dimensiones reales
  ni si es el laberinto completo o una subdivisión.
- Las tablas `$8959`/`$8A69`/`$8A89`/`$8AA9` (vistas ya de pasada en
  Sesión 3 como "tablas del indicador de menú") podrían en realidad
  ser tablas de sprite/animación de propósito más general,
  seleccionadas por `$7CE6` según un valor de tipo -- revisar esa
  hipótesis de Sesión 3, puede que estuviera incompleta.

### Documentación actualizada en esta sesión

- `README.md`/`README.en.md`: estado a Sesión 5, mención de la
  hipótesis de IA de persecución.
- `src/README.md`: subsistema "movimiento/IA (hipótesis)" añadido.
- `recursos/flujo_programa.html`: 6 rutinas nuevas.
- `recursos/mapa_memoria.html`: nueva subregión `$8200`+ (mapa/nivel,
  hipótesis).
- `recursos/flujo_secuencial.html`: sin cambios de fase -- lo
  descubierto esta sesión son rutinas de apoyo (cálculo de posición,
  comprobación de celda) usadas DESDE la fase de "generador de
  entidades" ya documentada en Sesión 4, no una fase nueva del
  arranque.
- `recursos/graficos.html`/`sprites.html`/`portada.html`: **sin
  cambios** -- las tablas de sprite localizadas (`$8959`+) no se han
  extraído ni decodificado como gráfico todavía, solo se sabe que
  existen y dónde.

### Pendiente para próximas sesiones

- Terminar de desensamblar `$7CE6` (no se alcanzó su `RET`) y mapear
  las tablas completas que selecciona.
- Confirmar las dimensiones reales de la estructura en `$8200`
  (¿cuántas filas? ¿es el laberinto completo?).
- Buscar el bucle de juego principal (frame a frame) que llame a esta
  cadena de movimiento/colisión de forma repetida -- sería la
  confirmación más fuerte de la hipótesis de IA de persecución.
- Seguir sin resolver: numeración de teclas del firmware (`$2C`/`$3E`).
- Seguir pendiente: promover a código compilado real las subrutinas de
  mayor confianza (`$7EAB`, `$7EF4`, `$7EB9`, `$786C`, `$7E92`, `$7D78`,
  `$7A95`).

## Sesión 5 (continuación) — 2026-09-01: reconstrucción del código fuente con nombres funcionales

El prompt de la Sesión 5 se actualizó a mitad de proyecto para pedir
explícitamente lo que las sesiones 3-4 dejaban para más adelante: no
solo documentar hipótesis en comentarios, sino **reescribir
`src/mummy1_body.asm` con etiquetas funcionales reales**, compiladas y
verificadas, para las rutinas ya entendidas con confianza suficiente
(regla explícita del prompt: "si no puedes garantizar un nombre
definitivo, usa un nombre provisional funcional con comentario de
hipótesis y nivel de confianza" — es decir, nombrar SÍ, pero dejando
constancia de que es provisional).

### Trabajo previo: completar el desensamblado de 3 rutinas a medias

Antes de poder promoverlas a código compilado hacía falta su `RET`
completo (Sesiones 3-4 las habían dejado a medias):

- `$7EB9` (borrado de rectángulo): se completó hasta `$7EF3` — termina
  llamando a `FIRM_TXT_WIN_ENABLE`/`FIRM_TXT_CLEAR_WINDOW`, lo que
  **sube su confianza a alta** (ya no es solo "parece borrar un
  rectángulo", usa literalmente las rutinas de firmware de ventana de
  texto).
- `$7A10` (chequeo de colisión, Sesión 4): se completó más allá de su
  primer `RET` condicional — tiene una segunda mitad (`$7A64`+) que
  vuelve a indexar la estructura de `$8200` con la MISMA fórmula que
  `$7D3E` (confirma que es la misma estructura de mapa, usada tanto
  para movimiento como para colisión). No se ha llegado a su `RET`
  final — sigue sin promover.
- El resto de rutinas a medias (`$7996`, `$78F7`, `$7AB6`, `$7AF2`,
  `$7B39`, `$7CE6`) se quedan como estaban, documentadas por hipótesis
  pero sin código compilado — no había tiempo de completarlas todas
  con el mismo rigor.

### Herramienta: generación automática del `INCBIN` partido

En vez de editar a mano los offsets de cada fragmento `INCBIN`
(propenso a errores de 1 byte), se escribió un script puntual
(basado en `tools/z80_disasm.py`) que:

1. Toma una lista de rangos `(inicio, fin)` a promover, cada uno ya
   verificado como una secuencia contigua de instrucciones completas
   terminada en `RET`.
2. Vuelca cada rango como código real, sustituyendo las direcciones
   literales de llamadas a firmware y a OTRAS rutinas ya promovidas
   por su nombre de etiqueta (verificado con una lista de
   correspondencias, no a ciegas).
3. Rellena los huecos entre rangos con
   `INCBIN "fichero", offset, longitud` (offset relativo al principio
   de `data/mummy1_resto_sin_analizar.bin`, que empieza en `$6401`).
4. Comprueba que la suma de bytes (código + huecos) cuadra exactamente
   con los 12165 bytes esperados antes de escribir nada.

Este mismo patrón (generar el `INCBIN` partido con una herramienta en
vez de a mano) se reutilizará en sesiones futuras según se vayan
entendiendo más tramos.

### 18 rutinas promovidas a código fuente real (510 bytes, 5 bloques)

Todas compiladas con SjASMPlus y verificadas **0 diferencias** contra
el binario original tras el cambio. Nombres, todos provisionales
(marcados así en el propio código, con su hipótesis y confianza):

| Etiqueta | Dirección | Hipótesis | Confianza |
|---|---|---|---|
| `IMPRIMIR_NUMERO_HL` | `$786C` | Imprime HL como 4 dígitos decimales vía `FIRM_TXT_OUTPUT` | Media-alta |
| `ESPERAR_TECLA_2C` | `$7893` | Espera pulsación+liberación de la tecla `$2C`, con antirrebote | Alta |
| `ANIMAR_OPCION_MENU` | `$78B7` | Anima/temporiza la opción de menú resaltada | Baja |
| `INICIALIZAR_ENTIDADES` | `$794F` | Llama 6 veces a `INICIALIZAR_UNA_ENTIDAD` | Media-alta |
| `INICIALIZAR_UNA_ENTIDAD` | `$795B` | Rellena un registro de `$816D` con 2 bytes de `GENERAR_ALEATORIO` + posición de una tabla en `$8645` | Media-alta |
| `CALCULAR_CASILLA_ADYACENTE` | `$7A95` | Calcula la celda adyacente en una dirección 0-3 (pasos 8px/2px) | Alta |
| `CONSULTAR_CASILLA_MAPA` | `$7D3E` | Indexa la estructura de `$8200` (paso de fila 5 bytes) | Media |
| `GENERAR_ALEATORIO` | `$7D53` | Generador pseudoaleatorio sembrado con el reloj del sistema | Alta |
| `MEZCLAR_ALEATORIO` | `$7D78` | Función de mezcla interna de `GENERAR_ALEATORIO` | Alta |
| `DIBUJAR_TRAMO_MARCO_1..4` | `$7D85`/`$7D9D`/`$7DB5`/`$7DCD` | Preparan una tabla de offset y llaman a `COPIAR_BLOQUE_A_LIENZO` para dibujar un tramo del marco decorativo | Media |
| `COPIAR_BLOQUE_A_LIENZO` | `$7E73` | Copia un bloque de 6x12 bytes a un lienzo de trabajo | Media |
| `CASILLA_A_DIRECCION_PANTALLA` | `$7E92` | Indexa la tabla de 200 direcciones de pantalla por fila | Alta |
| `BORRAR_BLOQUE_ESTADO` | `$7EAB` | Borra 1182 bytes de estado en `$8172` | Alta |
| `BORRAR_RECTANGULO_VENTANA` | `$7EB9` | Borra un rectángulo de la ventana de texto (usa firmware) | **Alta** (subida esta sesión) |
| `REPETIR_CARACTER` | `$7EF4` | Repite un carácter N veces vía `FIRM_TXT_OUTPUT` | Alta |

También se añadió `FIRM_KM_CHAR_RETURN` (`$BB0C`) a la tabla de `EQU`
de firmware (usada por `ESPERAR_TECLA_2C`).

El bloque `$6000`-`$6400` (cabecera del motor) se actualizó para
llamar a estas rutinas por su nombre en vez de por dirección literal
allí donde corresponde (`BORRAR_BLOQUE_ESTADO`, `REPETIR_CARACTER`,
`BORRAR_RECTANGULO_VENTANA`, los 4 `DIBUJAR_TRAMO_MARCO_*`,
`INICIALIZAR_ENTIDADES`, `ESPERAR_TECLA_2C`, `ANIMAR_OPCION_MENU` — 48
sustituciones). `$78D1` (la rutina más llamada de todas, hipótesis de
bombeo de sonido) sigue sin promover — no se completó su
desensamblado esta sesión.

### Documentación actualizada en esta sesión

- `README.md`/`README.en.md` y `src/README.md`: estado actualizado —
  18 rutinas con nombre real, 510 de los 12165 bytes restantes ya
  reconstruidos.
- `recursos/flujo_programa.html`: las 18 rutinas pasan de `nombre: "?"`
  a su nombre real, y de `estado: "pendiente"` a `"ok"` marcado como
  "nombre provisional, no verificado en emulador" en las notas (no se
  puede usar el badge "completo" sin matizarlo).
- `recursos/mapa_memoria.html`: sin cambios de región (las rutinas
  promovidas ya estaban documentadas como subregiones; ahora tienen
  nombre de etiqueta en vez de solo dirección).
- `recursos/flujo_secuencial.html`, `graficos.html`, `sprites.html`,
  `portada.html`: sin cambios — esta sesión fue de reconstrucción de
  código y nombrado, no de hallazgos nuevos de flujo o gráficos.

### Pendiente para próximas sesiones

- Completar el desensamblado de `$78D1`, `$7996`, `$78F7`, `$7AB6`,
  `$7AF2`, `$7B39`, `$7CE6`, y la segunda mitad de `$7A10`, para poder
  promoverlas también.
- Seguir reduciendo los tramos `INCBIN` restantes (11655 bytes en 6
  huecos) sesión a sesión con el mismo método (completar
  desensamblado -> verificar hasta `RET` -> generar `INCBIN` partido
  -> compilar -> comprobar 0 diferencias).
- Cuando una hipótesis se confirme con más seguridad (idealmente
  contra ejecución real en emulador), quitar la marca de "provisional"
  del nombre y de los comentarios.

## Sesión 6 — 2026-09-01: cierre del tramo $78D1-$7DE4 — 8 rutinas nuevas, todo el bloque queda contiguo

Sesión guiada por `prompts/sesion_06_reconstruccion_fuente.md` y
`prompts/_base_reconstruccion.md` (reglas globales, comunes a partir
de ahora a todas las sesiones de reconstrucción). Objetivo: seguir
completando `src/mummy1_body.asm` con etiquetas semánticas partiendo
del siguiente bloque sin resolver.

### Completar las 8 rutinas que quedaban a medias

Las sesiones 3-5 habían dejado varias rutinas centrales del hilo de
llamadas desensambladas solo parcialmente (cortadas por el límite de
instrucciones de cada exploración, no por falta de interés). Esta
sesión se completaron todas hasta su `RET` real:

- **`$78D1`** (la rutina más llamada de todo el bloque `$6000`-`$6400`,
  decenas de veces): tiene DOS salidas. La normal avanza el puntero
  `$905A` 9 bytes; la que se toma cuando el puntero llega exactamente
  a `$937D` lo **reinicia a `$905C`** — confirma sin ambigüedad que
  `$905C`-`$937D` es una **tabla circular** (un guion de sonido que se
  repite en bucle), no una tabla lineal como se sospechaba. Sube de
  confianza media a alta.
- **`$78F7`**: completa — borra un indicador (carácter `'T'`) en una
  posición y dibuja otro (`'A'`) en la posición vecina (±8 en fila),
  usando `DIBUJAR_ENTIDAD` (ver abajo). Confirma la hipótesis de
  "mover un indicador de menú".
- **`$7996`**: completa — recorre el array de entidades de `$816D`,
  comprueba colisión en dos casillas con `HAY_COLISION`, y si ambas
  están libres coloca la entidad; si no, dibuja igualmente (llamando
  directamente a la cadena de dibujado).
- **`$7A10`** (`HAY_COLISION`): la segunda mitad, antes sin completar,
  resulta comprobar **dos bytes de estado por casilla** en la
  estructura de `$8200` (en los offsets 40 y 41 de una entrada de 42
  bytes) — es decir, `HAY_COLISION` comprueba solapamiento con otras
  entidades **y** accesibilidad del propio mapa en la misma llamada.
- **`$7AB6`** (`ELEGIR_DIRECCION_HACIA_OBJETIVO`): completa, confirma
  la hipótesis de Sesión 5 sin cambios de fondo.
- **`$7AF2`**: resultó no tener `RET` propio — **cae directamente**
  (sin salto) en `$7B39`. Son en realidad una sola unidad lógica con
  dos puntos de entrada (uno por `CALL` directo a `$7B39`, otro
  ejecutando desde `$7AF2`) — patrón ya visto en el tramo del marco
  decorativo (Sesión 3).
- **`$7B39`** (`DIBUJAR_ENTIDAD`): con 429 bytes, es la rutina más
  grande desensamblada hasta ahora. Es un **dispatcher de sprites**:
  según el tipo de entidad (carácter `' '`/`'T'`/`'A'`/`'O'`),
  dirección, y un bit de animación de 2 fotogramas (guardado en el
  5º byte de cada entidad de `$816D`, hasta ahora sin uso conocido),
  selecciona una de unas 20 tablas de sprite de 4x16 bytes y la vuelca
  a pantalla con el mismo patrón que `COPIAR_BLOQUE_A_LIENZO`
  (usando `CASILLA_A_DIRECCION_PANTALLA`). Es, con diferencia, la
  evidencia más fuerte hasta ahora de dónde vive el dibujado de
  personajes (jugador/momias) del juego.
- **`$7CE6`** (`DIBUJAR_CASILLA_MAPA`): completa — selecciona una de 9
  tablas según el valor de una casilla del mapa y dibuja un sprite más
  pequeño (2x8 bytes) con el mismo patrón, cayendo directamente (sin
  `RET`) en `CONSULTAR_CASILLA_MAPA` (`$7D3E`, ya conocida).

### Todo el tramo `$78D1`-`$7DE4` es un único bloque contiguo

Al completar estas 8 rutinas se descubrió que **no hay ningún hueco**
entre ellas ni entre ellas y las 13 rutinas ya reconstruidas en
sesiones anteriores (`$786C`-`$78D1`, `$794F`-`$795B`, `$7A95`,
`$7D3E`-`$7DE4`): los `RET`/caídas encajan exactamente con el inicio
de la siguiente rutina en TODOS los casos, verificado byte a byte con
`z80_disasm.py` antes de dar nada por bueno. Resultado: **1401 bytes
seguidos** (`$786C`-`$7DE4`), 21 rutinas, reconstruidos como un único
bloque de código fuente real. Sumado al bloque ya existente de la
Sesión 3 (`COPIAR_BLOQUE_A_LIENZO` y las otras 4 rutinas de
`$7E73`-`$7EFC`), el total asciende a **26 rutinas, 1539 bytes**
(el 12.7% del motor completo) reconstruidos con nombre funcional real,
todos verificados byte a byte contra el binario original.

### 8 rutinas nuevas (nombres provisionales, con hipótesis y confianza en el propio código)

| Etiqueta | Dirección | Hipótesis | Confianza |
|---|---|---|---|
| `ACTUALIZAR_SECUENCIA_SONIDO` | `$78D1` | Avanza una tabla CIRCULAR de guion de sonido (`$905C`-`$937D`), encola sonido vía `FIRM_SOUND_QUEUE` cuando toca | **Alta** (subida esta sesión) |
| `MOVER_INDICADOR_MENU` | `$78F7` | Borra y redibuja un indicador de menú (vía `DIBUJAR_ENTIDAD`) | Media |
| `COLOCAR_ENTIDAD` | `$7996` | Intenta colocar una entidad evitando colisión en dos casillas; si falla, dibuja igual | Media |
| `HAY_COLISION` | `$7A10` | Colisión entidad-entidad + accesibilidad del mapa (2 bytes de estado por casilla) | **Alta** (subida esta sesión) |
| `PREPARAR_DIBUJAR_ENTIDAD` | `$7AF2` | Prepara posición/casillas y cae en `DIBUJAR_ENTIDAD` (mismo bloque lógico) | Media |
| `DIBUJAR_ENTIDAD` | `$7B39` | Dispatcher de ~20 tablas de sprite 4x16 bytes por tipo+dirección+animación | Media-alta |
| `DIBUJAR_CASILLA_MAPA` | `$7CE6` | Dispatcher de 9 tablas de sprite 2x8 bytes por valor de casilla del mapa | Media |

También se añadió `FIRM_SOUND_QUEUE` (`$BCAA`) a la tabla de `EQU` de
firmware.

### Cambios en el inventario de datos

- Se refina la hipótesis de la estructura en `$8200`: cada entrada
  parece ocupar **42 bytes** (no solo el byte inicial usado por
  `CONSULTAR_CASILLA_MAPA`/`DIBUJAR_CASILLA_MAPA`) — los offsets 40/41
  de cada entrada guardan el estado que comprueba `HAY_COLISION`.
  Pendiente confirmar qué hay en los otros 40 bytes.
- El 5º byte de cada entidad de `$816D` (antes "sin uso observado")
  ahora tiene hipótesis: bit de animación de 2 fotogramas, alternado
  por `DIBUJAR_ENTIDAD`.

### Documentación actualizada en esta sesión

- `README.md`/`README.en.md` y `src/README.md`: estado a Sesión 6 —
  26 rutinas / 1539 bytes reconstruidos.
- `recursos/flujo_programa.html`: las 8 rutinas nuevas pasan a
  `estado: "reconstruida"` con su nombre real.
- `recursos/mapa_memoria.html`: subregión de `$8200` actualizada con
  la hipótesis de 42 bytes/entrada; subregión de `$816D` actualizada
  con la hipótesis del 5º byte.
- `recursos/flujo_secuencial.html`, `graficos.html`, `sprites.html`,
  `portada.html`: sin cambios — nada gráfico nuevo que extraer todavía
  (las tablas de sprite de `DIBUJAR_ENTIDAD`/`DIBUJAR_CASILLA_MAPA`
  siguen dentro de la zona `INCBIN`, sin extraer a fichero).

### Pendiente para próximas sesiones

- Extraer a fichero las ~29 tablas de sprite que seleccionan
  `DIBUJAR_ENTIDAD` y `DIBUJAR_CASILLA_MAPA` (candidatas a
  `src/data/img/sprites/` y `src/data/img/tiles/` en cuanto se
  entienda mejor su formato) en vez de dejarlas dentro del `INCBIN`.
  Esto sería el primer contenido real de `recursos/sprites.html`/
  `graficos.html`.
- Confirmar los 40 bytes restantes de cada entrada de 42 bytes en
  `$8200`.
- Seguir el siguiente bloque no resuelto: `$7DE5`-`$7E72` (142 bytes,
  incluye `$7DED`/`$7DE5`, llamados desde los 4 `DIBUJAR_TRAMO_MARCO_*`
  pero nunca desensamblados).
- Numeración de teclas del firmware (`$2C`/`$3E`) sigue sin resolver.
- El bucle de juego principal (frame a frame) sigue sin localizar.

## Sesión 7 — 2026-09-01: reconstrucción completa del `.dsk` — `tools/dsk_build.py`

A petición directa del usuario ("la compilación del proyecto debe
funcionar como el proyecto de Spectrum"): hasta ahora `build_all.py`
solo verificaba los dos ficheros por separado contra lo extraído del
disco (ver Sesión 2), sin empaquetar el resultado de vuelta en un
`.dsk` completo — a diferencia de los proyectos hermanos, que sí
regeneran su entregable final (`.tzx`/`.dsk`) desde cero. Esta sesión
cierra esa carencia.

### Investigación del formato antes de escribir nada

Antes de generar un solo byte se inspeccionó el `.dsk` original campo
a campo para separar lo **reconstruible** (estructura del formato,
metadatos del catálogo — deterministas, se pueden volver a calcular)
de lo que **no lo es** (contenido sobrante de sectores reutilizados):

- El área de disco no usada (bloques 19-179, 164864 bytes) es
  uniformemente `$E5` — el byte de relleno estándar de un disco
  formateado y vacío. Igual las 62 entradas de catálogo sin usar.
  **Totalmente reconstruible.**
- El relleno tras el contenido real de `MUMMY.BAS` dentro de sus 3
  bloques asignados (508 bytes) **no es basura aleatoria**: contiene
  texto ASCII reconocible de las mismas listas `DATA` del logo
  "AMSOFT" que ya se habían detokenizado en la Sesión 2 (p. ej.
  `"1,7,0,2,0,2,1,-7,0,2,2,2..."`), y fragmentos de tokens BASIC
  reconocibles. Es decir: son restos legibles de una **versión
  anterior del mismo fichero**, grabada antes en ese mismo sector
  físico y no borrada al sobrescribirse con la versión final (AMSDOS,
  como CP/M, no borra los sectores al truncar un fichero, solo dejan
  de estar "reclamados"). Una pequeña ventana arqueológica al proceso
  de desarrollo del juego, pero **no forma parte del programa real** —
  no se reconstruye, se copia del original documentando por qué.
- El relleno tras `MUMMY1.BIN` (1018 bytes) es del mismo tipo:
  contenido variado no relacionado con el programa actual, tampoco
  reconstruible.
- Las cabeceras AMSDOS de 128 bytes: los campos con significado
  conocido (Sesión 1-2: tipo, dirección de carga, longitud, checksum)
  se recalculan; el resto (~90 bytes sin campo identificado) se copia
  del original, igual que ya hacía `amsdos_basic_tool.tokenizar()`
  desde la Sesión 2.
- Formato de cabecera de pista confirmado byte a byte: gap#3=`$4E`,
  filler=`$E5` (mismo valor que el relleno del disco vacío — no es
  casualidad, es el valor estándar AMSDOS), IDs de sector `$C1`-`$C9`,
  y el campo `C` (pista) de cada descriptor de sector coincide con el
  número de pista real — se confirmó comparando las pistas 0, 1 y 39.

### `tools/dsk_build.py`

Reconstruye el `.dsk` **desde cero** (no copia el original salvo los
~1600 bytes documentados arriba):

1. Compila el motor (`sjasmplus main.asm`) y tokeniza el cargador
   (`amsdos_basic_tool.tokenizar`) — reutilizando exactamente lo que
   ya hacía `build_all.py`.
2. Construye la cabecera de disco (256 bytes) y las 40 cabeceras de
   pista (256 bytes cada una) campo a campo, con los valores del
   formato "Data" de AMSDOS confirmados arriba.
3. Construye el catálogo (2 entradas reales + 62 marcadas como
   borradas `$E5`), leyendo del `.dsk` original solo los metadatos ya
   conocidos y verificados en sesiones anteriores (usuario, nombre,
   bloques asignados, número de registros) — no inventa nada nuevo,
   reutiliza hechos ya confirmados.
4. Coloca el cargador y el motor reconstruidos en sus bloques
   correspondientes, con el relleno no reconstruible documentado
   copiado del original.
5. Compara el resultado byte a byte contra
   `FISICO/Oh Mummy (1984)(Amsoft).dsk`.

**Resultado: 0 diferencias a la primera ejecución** (194816 bytes) —
confirma de un tirón que el desensamblado del motor (Sesión 2),
la tokenización del BASIC (Sesión 2) y la comprensión del formato
`.dsk`/AMSDOS (Sesión 1 y esta) son todas correctas simultáneamente.

### Documentación actualizada en esta sesión

- `README.md`/`README.en.md` y `src/README.md`: sección "Compilar"
  actualizada con el nuevo paso `py tools/dsk_build.py` y el resultado
  final en `build/ohmummy_reconstruido.dsk`.
- `.vscode/tasks.json`: nueva tarea "Generar dsk" y tarea compuesta
  "Compilar todo + generar dsk" (ahora la tarea por defecto de
  `Ctrl+Shift+B`, igual que en los proyectos hermanos).
- `recursos/*.html`: sin cambios — esta sesión fue de infraestructura
  de compilación, no de nuevos hallazgos semánticos sobre el motor.

### Pendiente para próximas sesiones

- Seguir el trabajo de desensamblado donde lo dejó la Sesión 6
  (bloque `$7DE5`-`$7E72`, numeración de teclas, bucle de juego
  principal).
- Documentar el hallazgo arqueológico del relleno de `MUMMY.BAS`
  (versión anterior del logo "AMSOFT") con más detalle si se llega a
  detokenizar ese fragmento completo — podría revelar diferencias
  entre un borrador y la versión final del cargador.

## Sesión 7 (continuación 1) — 2026-09-01: `recursos/mapa_memoria.html` — la barra no cuadraba con las direcciones reales

A petición del usuario ("la grafica horizontal no esta actualizada y
lo que hay parece no cuadrar con las direcciones de memoria"): la
barra usaba `display:flex` y solo el ANCHO de cada región de
`REGIONS`, sin ninguna noción de posición — los segmentos se
yuxtaponían en el orden del array, así que cualquier hueco de
direcciones no cubierto por una entrada simplemente desaparecía
visualmente (el hueco de ~22K bytes entre `MUMMY.BAS` y `$6000`
colapsaba a cero ancho, y el motor aparecía pegado justo después del
cargador BASIC en vez de a mitad de la barra). Además `REGIONS` solo
cubría una fracción del espacio de direcciones — no reflejaba las 26
rutinas ya reconstruidas en las Sesiones 3-6.

Corregido a semejanza de los proyectos hermanos de Spectrum/MSX:

- `REGIONS` ahora cubre las **65536 direcciones completas** sin
  huecos (cada entrada empieza donde termina la anterior).
- La barra posiciona cada segmento por dirección real
  (`left`/`width` absolutos calculados como `direccion / 0x10000`),
  no por orden secuencial de un `display:flex`.
- Nueva categoría `"reconstruida"` (mismo nombre y color que ya usa
  `flujo_programa.html`) para los dos bloques de las Sesiones 3-6
  (`$786C`-`$7DE4`, `$7E73`-`$7EFC`): verificados byte a byte pero con
  nombres todavía hipótesis, distintos del código mecánico ya
  nombrado con firmware.
- Nueva categoría `"sistema"` para distinguir la RAM/ROM/BASIC/
  pantalla del CPC fuera del alcance de este proyecto de las zonas
  `"unknown"` que sí son parte de `MUMMY1.BIN` pero siguen sin
  analizar.
- Regla de direcciones cada `$1000` bajo la barra (antes solo 5
  marcas fijas).

Cambio solo de documentación/visualización, sin impacto en el ASM —
no requiere `py tools/build_all.py`.

## Sesión 7 (continuación 2) — 2026-09-01: cerrado el hueco `$7DE5`-`$7E72` — 12 rutinas nuevas, el bloque `$786C`-`$7EFC` queda contiguo (1681 bytes)

Siguiendo el hilo de llamadas real (regla base: no avanzar a ciegas):
`DIBUJAR_TRAMO_MARCO_1/2/3` llaman a `$7DED` y `DIBUJAR_TRAMO_MARCO_4`
a `$7DE5` — ambos dentro del único hueco de 142 bytes que quedaba
entre los dos bloques ya reconstruidos. Desensamblado completo con
`tools/z80_disasm.py` (sin fallos de decodificación en las 142 bytes)
y reconstruido en `src/mummy1_body.asm`.

### Hallazgo: 12 rutinas nuevas, y una hipótesis previa corregida

**Corrección importante**: `flujo_programa.html` (Sesión 5/6) etiquetaba
las entradas en `$7DFC`-`$7E29` como "variantes de máscara AND/OR". El
desensamblado real muestra que **no hay ninguna instrucción AND ni OR
en todo el bloque** — es una hipótesis anterior sin evidencia directa,
ahora corregida con el código real delante.

Lo que hay de verdad:

- `RELLENAR_MARCO_MEDIO` (`$7DE5`, máscara `$0F`), `RELLENAR_MARCO_SOLIDO`
  (`$7DED`, máscara `$FF`) y `RELLENAR_MARCO_VACIO` (`$7DF5`, máscara
  `$00`): cada una fija un byte de máscara constante en `$864A` y salta
  a `PREPARAR_RELLENO_MASCARA_UNICA`, que rellena un bloque de 24 filas
  x 10 bytes (reutilizando `CASILLA_A_DIRECCION_PANTALLA` fila a fila
  vía `RELLENAR_FILAS_MASCARA`) con ESE byte repetido — sin AND/OR,
  solo `LD (HL),A` en bucle. Confianza alta en la estructura; media en
  el papel visual exacto (hipótesis: relleno sólido/vacío/a medias de
  una casilla del marco decorativo).
- `RELLENAR_MARCO_DIAGONAL_1`..`_6` (`$7DFC`-`$7E2E`): cada una hace lo
  mismo pero con un truco de **código automodificable** — parchea en
  caliente el byte inmediato de la instrucción `XOR $0F` situada en
  `$7E47` (dentro de `RELLENAR_MARCO_DIAGONAL_BUCLE`) con un segundo
  valor de máscara, y fija un primer valor en `$864A`. El bucle
  resultante dibuja 24 filas ALTERNANDO entre la máscara inicial y su
  XOR contra el valor parcheado (una fila con cada una, alternando),
  dando un patrón "a rayas"/veteado en vez de sólido. Confianza alta en
  la estructura (compilado, 0 diferencias); media en el papel visual
  (hipótesis: variantes de veta diagonal para las esquinas del marco).
- `RELLENAR_MARCO_DIAGONAL_BUCLE` (`$7E30`) y `PREPARAR_RELLENO_MASCARA_UNICA`
  (`$7E4F`) son los dos preparadores compartidos; `RELLENAR_FILAS_MASCARA`
  (`$7E59`) es el bucle de bajo nivel que ambos usan (también se llama a
  sí mismo como subrutina con `B=1` para dibujar una sola fila desde el
  bucle diagonal).

Solo `RELLENAR_MARCO_MEDIO` y `RELLENAR_MARCO_SOLIDO` tienen un
llamador conocido dentro de lo ya reconstruido (`DIBUJAR_TRAMO_MARCO_4`
y `DIBUJAR_TRAMO_MARCO_1/2/3`, actualizados para llamarlas por nombre).
`RELLENAR_MARCO_VACIO` y las 6 variantes diagonales no tienen todavía
un llamador conocido — probablemente están en uno de los dos huecos
`INCBIN` que quedan (`$6401`-`$786B` o `$7EFD`-`$9385`).

### Resultado

El bloque reconstruido `$786C`-`$7DE4` (Sesión 6) + este hueco cerrado
+ el bloque `$7E73`-`$7EFC` (Sesión 3) quedan **fusionados en un único
tramo contiguo `$786C`-`$7EFC` (1681 bytes, 38 rutinas)**, el 12.7% del
motor. Verificado con `py tools/build_all.py` (0 diferencias, 13190
bytes) y `py tools/dsk_build.py` (0 diferencias, 194816 bytes).

Quedan 2 huecos `INCBIN` sin analizar: `$6401`-`$786B` (5227 bytes) y
`$7EFD`-`$9385` (5257 bytes) — 10484 bytes en total.

### Documentación actualizada en esta sesión

- `FINDINGS.md` (esta entrada), `README.md`/`README.en.md`/
  `src/README.md` (cifras actualizadas: 38 rutinas, 1681 bytes, un
  único bloque contiguo), `recursos/flujo_programa.html` (12 filas
  nuevas) y `recursos/mapa_memoria.html` (los 3 segmentos del tramo
  `$786C`-`$7EFD` fusionados en uno solo, ya no hay hueco `unknown`
  entre ellos).

### Pendiente para próximas sesiones

- Los dos huecos `INCBIN` restantes (`$6401`-`$786B`, `$7EFD`-`$9385`).
- Localizar el llamador de `RELLENAR_MARCO_VACIO` y de las 6 variantes
  `RELLENAR_MARCO_DIAGONAL_*`.
- Numeración de teclas de firmware para `$2C`/`$3E` (pendiente desde
  Sesión 4/5).
- Bucle principal de juego, todavía sin localizar.

## Sesión 8 — 2026-09-01: cerrado el último hueco `INCBIN` del tramo `$7EFD`-`$9385` — es dato, no código, y contiene el texto real del juego

Siguiendo la prioridad explícita del prompt de sesión ("priorizar el
tramo que sigue a la sección ya resuelta en la Sesión 7"): el hueco
`$7EFD`-`$9385` (5257 bytes, el resto del motor tras el bloque de
código de la Sesión 7). Antes de tocar nada se comprobó que ningún
`CALL`/`JP` del código ya reconstruido aterriza ahí dentro (regla
base: no convertir datos en código sin evidencia) — y en efecto, tras
un volcado hexadecimal completo y contrastarlo bloque a bloque contra
las instrucciones que ya referencian direcciones concretas de esta
zona, se confirma que **todo el hueco es dato**, no código: texto
literal del juego, tablas de sonido/gráficos, y bloques de estado que
se limpian en el arranque.

### El hallazgo: texto real del juego, legible sin ambigüedad

Leyendo los bytes directamente (sin necesidad de descifrar ningún
código de control) aparecen, en orden:

- **`TEXTO_MENU_OPCIONES`** (`$7EFD`-`$7FC3`): la pantalla de opciones
  — "OH MUMMY - OPTIONS", "SPEED OF GAME (1-5) ?", "(1 IS FASTEST)",
  "DIFFICULTY LEVEL (1-5) ?", "(1 IS HARDEST)", "BACKGROUND MUSIC
  (Y-N) ?", "SOUND EFFECTS (Y-N) ?", "YES", "NO". Los dos bytes justo
  después ("YY") no son parte del texto: son **`FLAG_MUSICA_FONDO`**
  (`$7FC4`) y **`FLAG_EFECTOS_SONIDO`** (`$7FC5`), un truco clásico de
  ahorro de memoria de 8 bits — el flag se guarda como el propio
  carácter ASCII 'Y'/'N' que ya se necesita para redibujar la
  respuesta en pantalla. Confirmado para `FLAG_MUSICA_FONDO`:
  `ACTUALIZAR_SECUENCIA_SONIDO` hace `LD A,($7FC4):CP $59` (compara
  contra 'Y') antes de encolar sonido — de ahí sale también la
  condición exacta bajo la que esa rutina llama a `FIRM_SOUND_QUEUE`.
- **`TEXTO_HISTORIA_ATRACCION`** (`$801D`-`$8139`): la pantalla de
  "periódico" del modo atracción — *"STOP PRESS!! British Museum
  today announced successful excavation of ancient Egyptian pyramid.
  Leader of team given bonus for his efforts of 200 points. extra man
  for next dig. Press "C" or Fire Button to Continue"* — seguido de
  **"GAME OVER"**.
- **`TEXTO_TABLA_PUNTUACIONES`** (`$867E`-`$86E8`): "HI-SCORE-TABLE"
  más 5 rangos con su umbral de puntuación en 16 bits little-endian
  intercalado, leído directamente de los bytes: "Stupendous !"=2000,
  "Excellent ! "=1500, "Very Good ! "=1000, "Quite Good  "=500, "Not
  Bad     " (sin umbral visible, probablemente el rango por defecto).
- **`TEXTO_MENU_PRINCIPAL`** (`$86E9`-`$8737`): "I-Instructions
  O-Options  P-Play  ?" (encaja con `MOVER_INDICADOR_MENU`/
  `ANIMAR_OPCION_MENU`, ya reconstruidas) y "Well done !!  Please
  enter your name" (pantalla de entrada de nombre para el ranking).
- **`TEXTO_COPYRIGHT_Y_HUD`** (`$8740`-`$877C`): el copyright real del
  juego, **`"OH MUMMY" (c) 1984 GEM SOFTWARE`** — confirma
  directamente lo que decía `AVISO-LEGAL.md` a partir del crédito de
  `mummy_bas.bas` (Sesión 2) — y las etiquetas de HUD "SCORE"/"MEN".
- **`DATOS_MARCO_Y_TEXTO_CONTINUAR`** (`$889D`-`$8918`): termina con
  `'"C" TO CONTINUE'`.

### Tablas con límites confirmados por el código ya reconstruido

- **`ENVOLVENTE_AMPLITUD_1..3`** / **`ENVOLVENTE_TONO_1..3`**
  (`$7FCA`-`$801C`): las 6 definiciones de envolvente de sonido que ya
  se sabía (Sesión 3) que cargaba el arranque — direcciones exactas
  confirmadas porque el propio arranque hace `LD HL,$7FCA`/`$7FD4`/
  `$7FDE`/`$7FE5`/`$7FF5`/`$7FF9` antes de cada `CALL
  FIRM_SOUND_AMPL_ENV`/`FIRM_SOUND_TONE_ENV`. Formato variable (las
  amplitudes miden 10/10/7 bytes, los tonos 16/4/36) — coherente con
  el formato real de envolvente del firmware CPC (cabecera de nº de
  pasos + N tripletas).
- **`TABLA_MARCO_1..4`** (`$877D`-`$889C`, 72 bytes cada una): las 4
  tablas del marco decorativo. Límite exacto confirmado por
  aritmética: `DIBUJAR_TRAMO_MARCO_2` fija IY en `$87C5`, exactamente
  72 bytes después de `$877D` (`DIBUJAR_TRAMO_MARCO_1`) — y lo mismo
  para las 4, coincidiendo exacto con los 12x6 bytes que consume
  `COPIAR_BLOQUE_A_LIENZO`. Contenido: máscaras/bitmap con patrones
  típicos de pantalla CPC modo 1 (`$FF`/`$00`/`$CC`/`$33`/`$AA`...),
  sin decodificar a nivel de píxel.
- **`ARRAY_ENTIDADES`** (`$816D`-`$818A`, 30 bytes, todo cero) /
  **`ESTADO_PARTIDA`** / **`VENTANA_TEXTO_HUD`** / **`MAPA_CASILLAS`**
  (`$818B`-`$860F`, todo cero): confirmado que `BORRAR_BLOQUE_ESTADO`
  limpia exactamente desde `ARRAY_ENTIDADES+5` (`$8172`) hasta el
  último byte de `MAPA_CASILLAS` (`$860F`), 1182 bytes. El arranque
  también confirma variables sueltas justo antes del array:
  `CONTADOR_ENTIDADES` (`$8169`, puesto a 6 — encaja con la hipótesis
  "6 enemigos/coleccionables" de sesiones anteriores) y dos flags de 1
  byte puestos a 0. `VENTANA_TEXTO_HUD` y `MAPA_CASILLAS` mantienen
  las hipótesis previas (Sesiones 3-6) de "buffer de texto" y
  "estructura de mapa" respectivamente, aunque el hueco real entre
  ambas direcciones (40 bytes) es más pequeño de lo que sugería la
  hipótesis original de `VENTANA_TEXTO_HUD` (~1000 bytes) — posible
  solapamiento de uso entre menús y partida, sin confirmar.
- **`TABLA_DIRECCIONES_PANTALLA`** (`$8ECA`-`$9059`, 400 bytes, todo
  cero) / **`PUNTERO_GUION_SONIDO`** (`$905A`-`$905B`): confirmado que
  el arranque rellena la tabla en tiempo de ejecución (bucle de 200
  iteraciones con `FIRM_SCR_DOT_POSITION`, ya documentado desde la
  Sesión 3) — el fichero la tiene a 0 porque nunca se lee antes de que
  ese bucle la rellene. Los últimos 2 bytes de ese rango resultaron
  ser en realidad una variable aparte: el puntero de
  `GUION_SONIDO_CIRCULAR`.
- **`GUION_SONIDO_CIRCULAR`** (`$905C`-`$9385`, 810 bytes = **90
  registros de 9 bytes exactos**, llena el hueco justo hasta el último
  byte del motor): confirma y cierra del todo la hipótesis "tabla
  circular de guion de sonido" de la Sesión 6. `GUION_SONIDO_ULTIMO_REGISTRO`
  (`$937D`) es el registro nº90, el umbral exacto que usa
  `ACTUALIZAR_SECUENCIA_SONIDO` (`LD DE,$937D`) para saber cuándo
  volver a `GUION_SONIDO_CIRCULAR`. 9 bytes por registro encaja con el
  formato extendido de `SOUND QUEUE` del firmware (estado+tono+
  volumen/envolvente+duración+envolventes), sin desglosar campo a
  campo todavía.
- **`TABLA_POSICIONES_DECIMALES`** (`$8738`-`$873F`, 4 valores de 16
  bits: `10000,1000,100,10`): **corrige** la hipótesis previa de
  `mapa_memoria.html` (que databa esta tabla en `$8736`) — esos 2
  bytes son en realidad el final del texto "na**me**" de
  `TEXTO_MENU_PRINCIPAL`; `IMPRIMIR_NUMERO_HL` hace `LD IY,$8736` pero
  incrementa IY dos veces antes de la primera lectura real (en
  `$8738`), así que la tabla en sí no empieza donde decía la hipótesis
  vieja. Confirma que la rutina imprime HL como un número de hasta 5
  cifras decimales (4 restas repetidas + el resto final), no 4 como se
  dijo antes.

### Sin descifrar del todo (bytes en bruto, con hipótesis)

`TABLA_DESCONOCIDA_GAME_OVER` (tras el texto "GAME OVER", con
progresiones aritméticas visibles), `TABLA_OFFSETS_DIAMANTE` (pares
byte-alto `$B8`/`$90`/`$A8` con patrón ascendente/descendente),
`TABLA_PARAMETROS_TRANSICION_PUNTUACIONES` (justo antes de
"HI-SCORE-TABLE"), y `TABLAS_SPRITE_CASILLA` (`$8919`-`$8EC9`, 1457
bytes — confirmado que empieza justo donde `DIBUJAR_ENTIDAD` fija
`IY`, con patrones de bytes consistentes con máscaras de pantalla CPC
modo 1, pero sin desglosar las ~29 tablas individuales de sprite/
casilla todavía). Todas quedan documentadas en el ASM con su
hipótesis y nivel de confianza, no como `INCBIN` anónimo.

### Verificación

`py tools/build_all.py` y `py tools/dsk_build.py`: **0 diferencias**
en los tres (motor 13190 bytes, cargador 2564 bytes, `.dsk` completo
194816 bytes) — cada uno de los 35 nuevos bloques de datos (`DB`/`DW`/
`DEFS`), y cada `LD`/`CALL` renombrado a la nueva etiqueta simbólica
(incluidas expresiones con aritmética de etiqueta como
`TABLA_POSICIONES_DECIMALES-2`, `ARRAY_ENTIDADES+5` y
`TABLA_PARAMETROS_TRANSICION_PUNTUACIONES+8`), se verificó además con
un script independiente que reconstruye los bytes a partir del propio
texto ASM y los compara contra el binario original antes de tocar
`mummy1_body.asm`.

### Documentación actualizada en esta sesión

`FINDINGS.md` (esta entrada), `README.md`/`README.en.md`/
`src/README.md` (el motor ya no tiene ningún tramo de código sin
analizar más allá del bloque `$6401`-`$786B`; el resto del motor está
reconstruido como código o como dato con nombre), `recursos/
flujo_programa.html` (sin cambios de rutinas de código esta sesión —
todo lo nuevo es dato) y `recursos/mapa_memoria.html` (la región
`$7EFD`-`$9385`, antes "sin analizar", pasa a una nueva categoría
`"dato"` con el detalle de las 35 tablas/textos nuevas).

### Pendiente para próximas sesiones

- El único hueco `INCBIN` que queda: `$6401`-`$786B` (5227 bytes).
- Descifrar las ~29 tablas individuales dentro de `TABLAS_SPRITE_CASILLA`
  (límites de cada tabla de sprite/casilla, actualmente un solo bloque).
- `TABLA_DESCONOCIDA_GAME_OVER`, `TABLA_OFFSETS_DIAMANTE` y
  `TABLA_PARAMETROS_TRANSICION_PUNTUACIONES`: localizar el código que
  las lee (ninguna tiene todavía un `CALL`/`LD` conocido).
- Localizar el llamador de `RELLENAR_MARCO_VACIO` y de las 6 variantes
  `RELLENAR_MARCO_DIAGONAL_*` (pendiente desde la Sesión 7).
- Numeración de teclas de firmware para `$2C`/`$3E` (pendiente desde
  Sesión 4/5).
- Bucle principal de juego, todavía sin localizar.

## Sesión 8 (continuación) — 2026-09-01: `recursos/sprites.html` — explorador interactivo de `TABLAS_SPRITE_CASILLA`

A petición del usuario: convertir `sprites.html` (plantilla vacía
desde la Sesión 1) en una herramienta real para ir acotando el formato
de `TABLAS_SPRITE_CASILLA` (`$8919`-`$8EC9`, 1457 bytes, localizada
esta misma sesión) — todavía no se sabe con certeza el modo de
pantalla del CPC, ni el ancho/alto real de cada sprite, ni dónde
empieza cada tabla individual dentro del bloque.

La página incrusta los 1457 bytes tal cual (verificado byte a byte
contra `src/mummy1_body.asm` con un script de comparación antes de
publicar el fichero) y los decodifica en el navegador con la
codificación de bits **real** del hardware CPC para los 3 modos de
pantalla (Modo 0: 2 píxeles/byte, 4 bits/píxel; Modo 1: 4 píxeles/byte,
2 bits/píxel; Modo 2: 8 píxeles/byte, 1 bit/píxel — el reparto de bits
de cada modo es el documentado en el firmware, no inventado). Controles
editables: modo, ancho en bytes/fila, alto en filas, offset inicial,
salto entre sprites (por si hay padding entre tablas), cantidad a
mostrar, zoom y paleta (la paleta de color SÍ es inventada — el binario
no guarda qué tinta va con cada índice de píxel). Dos botones de preset
cargan la hipótesis de trabajo de las Sesiones 3-6 (Modo 1, ~20
sprites de personaje de 4x16 bytes = 16x16 píxeles, seguidos de 9
casillas de mapa de 2x8 bytes = 8x8 píxeles).

Comprobación rápida en Python (fuera de la página, solo para validar
el decodificador antes de publicarlo): con Modo 1 y 4x16 bytes, la
mayoría de los sprites muestran un fondo uniforme de índice 2 (byte
$F0, ya visto en Sesión 8 como relleno del marco decorativo) con un
puñado de píxeles de otro índice formando una silueta pequeña — patrón
compatible con un personaje/glifo simple de 16x16, aunque **ninguna
combinación de parámetros está confirmada todavía** (ni contra una
captura real del juego en emulador, ni contra ninguna otra evidencia
independiente). Sin impacto en `mummy1_body.asm` — no requiere
`py tools/build_all.py`.

### Pendiente

- Confirmar el modo de pantalla y las dimensiones reales de sprite
  contrastando contra una captura de pantalla del juego en emulador
  (pendiente desde sesiones anteriores, ver "Numeración de teclas" y
  otros pendientes de arriba).
- Una vez confirmado el formato, extraer los sprites individuales a
  `src/data/img/sprites/*.spr` y sustituir el placeholder de esta
  página por el array `SPRITES` ya poblado.

## Sesión 8 (continuación 2) — 2026-09-01: `DIBUJAR_ENTIDAD` no es un array lineal — despacho por tipo con 16 sprites confirmados (`SPRITE_JUGADOR_*` / `SPRITE_MOMIA_*`)

Usando el explorador de `recursos/sprites.html` (Modo 1, 4x16 bytes,
salto 64, offset 0) el usuario detectó un efecto muy concreto: cada
sprite mostrado aparecía "partido" verticalmente — la mitad inferior
de una figura y la mitad superior de la siguiente, encadenadas todas
igual, con 6 sprites iniciales sin forma reconocible, luego 8 con
pinta de personaje jugable, luego 8 con pinta de enemigo (momia), y
de nuevo ruido al final.

Verificado matemáticamente (Python, misma decodificación Modo 1 que la
página): desplazando el offset en ±32 bytes (la mitad exacta de un
sprite de 64 bytes) el "corte" desaparece y las figuras salen
completas y coherentes de arriba abajo. Pero la causa real no es un
simple desajuste de offset: **revisando el código real de
`DIBUJAR_ENTIDAD` se confirma que la región no se recorre linealmente
en absoluto** — es una tabla de despacho por el carácter de tipo de
entidad (registro A al entrar):

- `' '` (`$20`) → `IY=$8959` (un solo sprite).
- `'T'` (`$54`) → sub-despacho en `($8157)` con anchos/altos que
  cambian según la rama (32 o 64 bytes) — sin nombrar todavía, pendiente.
- `'A'` (`$41`) → sub-despacho en `($8157)` (`<2`/`==2`/`==3`/`>=4`)
  hacia 4 pares `(IY, IY+64)` — 8 sprites de 64 bytes, **perfectamente
  contiguos**: `$8AB9`-`$8CB8`.
- `'O'` (`$4F`) → mismo patrón con `($8159)`, otros 8 sprites de 64
  bytes, **contiguos e inmediatamente después de los de `'A'`**:
  `$8CB9`-`$8EB8`.
- Cualquier otro carácter (caso por defecto/fallthrough) → `IY=$8919`
  (`TABLAS_SPRITE_CASILLA`, el principio de todo el bloque).

Los 16 sprites de `'A'`/`'O'` quedan nombrados en `mummy1_body.asm`:
`SPRITE_JUGADOR_G1_F1`..`SPRITE_JUGADOR_G4_F2` (`$8AB9`-`$8CB8`) y
`SPRITE_MOMIA_G1_F1`..`SPRITE_MOMIA_G4_F2` (`$8CB9`-`$8EB8`) — G1-G4
son los 4 grupos de dirección que distingue el `CP`/`JR` (`<2`, `==2`,
`==3`, `>=4`; no se sabe todavía a qué dirección compás corresponde
cada uno), F1/F2 los 2 fotogramas de animación que alterna un flag
(`XOR $01`). **Confianza alta en la estructura** (16 sprites de 64
bytes exactos, contiguos, confirmados por 16 instrucciones `LD IY,`
reales) y **media en la identidad visual** ("jugador"/"momia" es la
lectura del usuario probando el explorador con estos offsets exactos,
no confirmada contra una captura de pantalla real).

**Confirmado de forma independiente por el usuario** probando
`recursos/sprites.html` con Modo 1, ancho 4, alto 16, offset inicial
416, salto 64: identifica visualmente 8 sprites del jugador y 8 del
zombie/momia, con el primero en `$8AB9` y el último en `$8E79` —
coincide exactamente, byte a byte de dirección, con lo derivado del
código de `DIBUJAR_ENTIDAD` arriba. Refuerza la confianza en la
estructura (ya era alta) y sube la de la identidad visual de "media"
a "media-alta" (sigue sin verificarse contra una captura de pantalla
real del juego en emulador, pero ahora hay dos fuentes independientes
-- código y ojo humano -- de acuerdo).

Esto explica por qué escanear linealmente con salto fijo de 64 bytes
desde el offset 0 (como hacía el preset inicial de `sprites.html`)
producía basura en algunos tramos y figuras "medio bien" en otros: la
región mezcla sprites de 64 bytes con casillas de 16 bytes y huecos de
tamaño variable en un orden que **no es secuencial** — el offset ±32
que "arreglaba" el corte era una coincidencia de alineación dentro del
tramo `'A'`/`'O'` (que sí es contiguo), no una propiedad general de
todo el bloque.

### `recursos/sprites.html` actualizado

Los botones de preset ahora saltan directo a las direcciones
confirmadas (`$8AB9` para `SPRITE_JUGADOR_G1_F1`, `$8CB9` para
`SPRITE_MOMIA_G1_F1`, `$8959` para la única casilla suelta también
confirmada) en vez de escanear a ciegas desde el offset 0.

### Verificación

`py tools/build_all.py` y `py tools/dsk_build.py`: **0 diferencias**
— los 16 nuevos labels y las 16 llamadas `LD IY,` renombradas
compilan a los mismos bytes exactos.

### Pendiente

- Nombrar el resto de `TABLAS_SPRITE_CASILLA`: la rama `'T'` (anchos
  variables, con efectos secundarios de escritura en el mapa — posible
  "rastro" de excavación, sin confirmar), el caso por defecto/`' '`, y
  las 9 direcciones de `DIBUJAR_CASILLA_MAPA` (`$8959`, `$89D9`,
  `$89E9`, `$89F9`, `$8A19`, `$8A69`, `$8A79`, `$8A89`, `$8AA9` — no
  son contiguas, mezcladas con las tablas de `'T'`).
- Confirmar contra una captura de pantalla real en emulador si `'A'`
  es de verdad el jugador y `'O'` la momia (o al revés), y qué grupo
  (G1-G4) corresponde a qué dirección real.
- Investigar si `'T'` es el rastro/trayecto de excavación del jugador
  (encaja con el tema del juego y con las escrituras a mapa vistas en
  su código) — hipótesis nueva, sin evidencia todavía más allá de la
  coincidencia temática.

## Sesión 8 (continuación 3) — 2026-09-01: los 16 sprites confirmados, extraídos a `src/data/img/sprites/*.spr`

Paso siguiente natural tras confirmar `SPRITE_JUGADOR_G1_F1`..`G4_F2` y
`SPRITE_MOMIA_G1_F1`..`G4_F2`: se extraen los 16 sprites (64 bytes cada
uno) a ficheros individuales (`sprite_jugador_g1_f1.spr` ..
`sprite_momia_g4_f2.spr`) y se sustituye cada bloque `DB` en
`mummy1_body.asm` por `INCBIN "data/img/sprites/<nombre>.spr"`,
manteniendo las 16 etiquetas. Verificado con `py tools/build_all.py` y
`py tools/dsk_build.py`: **0 diferencias** — cada fichero reproduce
exactamente los mismos 64 bytes que tenía el `DB` que sustituye.

`recursos/sprites.html` gana una sección **"Sprites confirmados"**
(galería fija con los 16, coloreados por hipótesis jugador/momia) y
una **segunda sección dedicada** a la parte de `TABLAS_SPRITE_CASILLA`
que sigue sin identificar (offset 0-415, antes de `$8AB9`): un
explorador independiente del general, con 10 botones que saltan
directo a cada dirección ya conocida por el código (`$8919` por
defecto de `DIBUJAR_ENTIDAD`, `$8959` y las 8 restantes de
`DIBUJAR_CASILLA_MAPA`) — no contiguas entre sí, por eso son botones
sueltos en vez de un preset con salto fijo. Ambos exploradores
(general y dedicado) comparten el mismo motor de lectura/decodificado
(refactorizado a una fábrica `makeExplorer(prefijo, ...)` para no
duplicar código ni mezclar el estado de los dos paneles).

### Verificación

`py tools/build_all.py` y `py tools/dsk_build.py`: **0 diferencias**.

### Pendiente

- Usar el nuevo explorador dedicado para ir nombrando lo que hay entre
  las 9 direcciones de casilla conocidas y en la rama `'T'`/por
  defecto de `DIBUJAR_ENTIDAD`.
- Extraer a fichero también las casillas de `DIBUJAR_CASILLA_MAPA` en
  cuanto se decida su formato definitivo (2x8 confirmado por el código
  que las usa, contenido visual sin confirmar todavía).

## Sesión 8 (continuación 4) — 2026-09-01: `LOSETA_PISADAS_VERTICAL_1`/`_2` — primer sprite nombrado de la rama `'T'`

Usando el nuevo explorador dedicado a `TABLAS_SPRITE_CASILLA`, el
usuario identifica en offset 124 (Modo 1, ancho 4, alto 16, salto 64,
dirección `$8995`) una loseta que dibuja en el suelo pisadas en
vertical.

Contrastado contra el código: `$8995` en sí no es un punto de entrada
real — cae 4 bytes antes del primer punto de entrada confirmado de la
rama `'T'` de `DIBUJAR_ENTIDAD` (`$7B65`, la que aún no tenía ningún
sprite nombrado). Cuando `($8157) < 2`, esa rama salta a **`$8999`**
(fija el contador de filas a 8 mediante código automodificable sobre
`$7CC6`, ancho por defecto 4 → 32 bytes, 16x8 px) y alterna con
**`$89B9`** (mismo tamaño, seleccionado por el flag `$8158`) —
perfectamente contiguos entre sí (`$8999`-`$89D8`). La vista de 64
bytes que encontró el usuario (offset 124 = `$8999` menos 4 bytes)
junta visualmente ambas mitades de 32 bytes en una sola imagen de
4x16, que es donde se aprecia el patrón de puntos alternos como
pisadas verticales — aunque el juego en sí dibuja cada mitad por
separado (una u otra según el flag de animación, nunca las dos a la
vez).

Encaja además con una hipótesis ya apuntada en esta misma sesión: esa
misma rama `'T'` escribe `$01`/`$02` en dos celdas del mapa devueltas
por `CONSULTAR_CASILLA_MAPA` justo antes de dibujar — coherente con
marcar una casilla como "cavada"/con huella al pasar el jugador por
ella. Nombrados en `mummy1_body.asm`: `LOSETA_PISADAS_VERTICAL_1`
(`$8999`) y `LOSETA_PISADAS_VERTICAL_2` (`$89B9`), y renombrados los 2
`LD IY,` que las usan. Confianza alta en la estructura (32 bytes
exactos, contiguos, confirmados por el código), media-alta en la
identidad visual (coincide con la hipótesis temática de rastro de
excavación, pero sin confirmar en emulador).

### Verificación

`py tools/build_all.py` y `py tools/dsk_build.py`: **0 diferencias**.

`recursos/sprites.html`: nuevo botón "CONFIRMADO: LOSETA_PISADAS_VERTICAL"
en el explorador dedicado, que reproduce exactamente la vista que usó
el usuario para encontrarla (offset 124, 4x16, salto 64).

### Pendiente

- El resto de la rama `'T'` (`($8157)==2`→`$89F9`/`$8A09` 2x16;
  `==3`→`$8A29`/`$8A49` 4x8; por defecto→`$8A89`/`$8A99` 2x16) sigue
  sin nombrar — mismo patrón de escritura en el mapa, probablemente
  las otras 3 orientaciones de la misma "pisada" (horizontal y
  diagonales, o las 4 direcciones del tablero).

## Sesión 8 (continuación 5) — 2026-09-01: `LOSETA_MAPA_PISADA_1`..`_8` — las 8 casillas de pisadas de `DIBUJAR_CASILLA_MAPA`, patrón V-V-H-H-V-V-H-H confirmado

El usuario, con el explorador dedicado (Modo 1, 2x8, offset 192 =
`$89D9`, salto 16), identifica 8 sprites consecutivos que corresponden
a "cada uno de los pasos": los dos primeros en vertical, los dos
siguientes horizontales, los dos siguientes verticales y los dos
últimos horizontales.

Verificado pixel a pixel con un script independiente (misma
decodificación Modo 1 de la página): coincide exacto,
`$89D9`/`$89E9`=V (imágenes en espejo horizontal entre sí),
`$89F9`/`$8A19`=H (mitad inferior/mitad superior que encajan entre
sí), `$8A69`/`$8A79`=V (espejo, igual que el primer par pero con
trazo distinto), `$8A89`/`$8AA9`=H (igual patrón que el segundo par).

Contrastado contra `DIBUJAR_CASILLA_MAPA` ($7CE6): son exactamente los
8 destinos (de los 9 totales, el noveno es `$8959` para el valor por
defecto) que despacha según el valor de casilla leído del mapa —
`$89D9`→valor 0/1, `$89E9`→2, `$89F9`→3, `$8A19`→4, `$8A69`→6,
`$8A79`→5, `$8A89`→8, `$8AA9`→7. Dos de ellos (`$89F9` y `$8A89`)
coinciden byte a byte con sprites que la rama `'T'` de
`DIBUJAR_ENTIDAD` ya dibuja en directo para esos mismos valores (3 y
8) — la misma casilla se pinta al momento de "pisarla" y se vuelve a
leer después para redibujar el suelo con la marca ya asentada.

Esto **cierra el círculo completo del mecanismo de pisadas**: la rama
`'T'` escribe un valor 1-8 en la celda del mapa que acaba de pisar el
jugador (según la dirección de movimiento — `($8157)`), y
`DIBUJAR_CASILLA_MAPA` usa ese mismo valor para elegir cuál de las 8
losetas dibujar cuando esa celda del suelo se tenga que redibujar más
tarde. Los 4 pares (valores 1/2, 3/4, 5/6, 7/8) son las 4 direcciones
del tablero, cada una con 2 variantes (probablemente pie izquierdo/pie
derecho, o la casilla vista desde delante/detrás).

Nombrados en `mummy1_body.asm`: `LOSETA_MAPA_PISADA_1`..`_8` (por
orden de dirección, no por valor de casilla — ver la tabla de arriba
para la correspondencia exacta) y renombrados los 10 `LD IY,` que las
usan (8 en `DIBUJAR_CASILLA_MAPA` + 2 en `DIBUJAR_ENTIDAD` para los
casos compartidos). Confianza alta en la estructura, media-alta en la
identidad (confirmado por lectura de código + inspección de píxeles,
sin verificar todavía contra una captura de pantalla real).

### Verificación

`py tools/build_all.py` y `py tools/dsk_build.py`: **0 diferencias**.

`recursos/sprites.html`: los 8 botones de casilla del explorador
dedicado ahora muestran el nombre confirmado y su orientación V/H, más
un botón nuevo que carga las 8 juntas de un golpe (la vista exacta que
usó el usuario para el hallazgo).

### Pendiente

- Nombrar las 4 direcciones de escritura de `'T'` que todavía no
  coinciden con ninguna `LOSETA_MAPA_PISADA_*` (`$8A09` valor 4,
  `$8A29`/`$8A49` valores 6/5, `$8A99` valor 7) — mismos sprites en
  esencia, pero el tamaño con el que los escribe `'T'` (2x16 o 4x8,
  según la rama) no coincide con el 2x8 que lee
  `DIBUJAR_CASILLA_MAPA`, sin explicar todavía esa discrepancia de
  tamaño.
- Confirmar qué valor de casilla corresponde a qué dirección real
  (arriba/abajo/izquierda/derecha) y qué distingue las 2 variantes de
  cada par (pie/vista).

## Sesión 10 — 2026-09-07: observación visual de la loseta de pisada en `$89E7`

Durante la comparación del explorador `recursos/sprites.html` con una
ejecución del emulador, se observó una loseta vertical que parece
corresponder al **pie derecho** usando estos parámetros: anchura de 2
bytes por fila, altura de 8 filas, offset inicial 206 desde
`TABLAS_SPRITE_CASILLA` (`$8919`), desplazamiento vertical 0 y salto de
16 bytes. El offset 206 corresponde a `$89E7`.

Este hallazgo queda registrado como **observación visual provisional**.
El código reconstruido de `DIBUJAR_CASILLA_MAPA` sigue teniendo
`$89E9` como destino de `LOSETA_MAPA_PISADA_2`, offset 208, por lo que no
se mueve todavía la etiqueta del ASM. La diferencia de dos bytes debe
resolverse contrastando la captura del emulador y la alineación real de
la imagen: `$89E7` puede ser un inicio visual útil para el sprite, pero
no necesariamente el límite lógico de los 16 bytes que lee la rutina.

`recursos/sprites.html` incorpora el preset `OBSERVACION EMULADOR:
pie derecho (candidato, $89E7)` para reproducir exactamente la vista.

## Sesión 10 (continuación) — verificación del despacho y de la dirección

La revisión del código fuente confirma la correspondencia semántica de
las ocho losetas que se observó visualmente. `DIBUJAR_CASILLA_MAPA`
selecciona estas direcciones según el valor de la casilla:

| Valor de casilla | Loseta | Offset | Lectura visual propuesta |
|---:|---|---:|---|
| 1 | `$89D9` | +192 | izquierda hacia arriba |
| 2 | `$89E9` | +208 | derecha hacia arriba |
| 3 | `$89F9` | +224 | izquierda hacia la derecha |
| 4 | `$8A19` | +256 | derecha hacia la derecha |
| 5 | `$8A79` | +352 | izquierda hacia abajo |
| 6 | `$8A69` | +336 | derecha hacia abajo |
| 7 | `$8AA9` | +400 | izquierda hacia la izquierda |
| 8 | `$8A89` | +368 | derecha hacia la izquierda |

La parte confirmada por el ASM es el valor, la dirección de memoria y
el bloque de 16 bytes seleccionado. La rama `'T'` de `DIBUJAR_ENTIDAD`
escribe los pares de valores en el mapa: `1/2` en `$7C0F-$7C2B`,
`3/4` en `$7BDD-$7BFD`, `5/6` en `$7BA5-$7BCE` y `7/8` en
`$7B73-$7BA2`. En cada par, `$8158` se alterna con `XOR $01`, por lo
que el código confirma dos variantes consecutivas de pisada, pero no
las llama pie izquierdo o derecho.

La convención numérica de movimiento también queda confirmada por
`CALCULAR_CASILLA_ADYACENTE` (`$7A95-$7AB5`) y
`ELEGIR_DIRECCION_HACIA_OBJETIVO` (`$7AB6-$7AF1`): `1` modifica la
coordenada alta con `-8`, `2` modifica la baja con `+2`, `3` modifica
la alta con `+8` y `4` modifica la baja con `-2`. El código no nombra
qué eje corresponde a arriba/abajo o izquierda/derecha en la pantalla,
por lo que la lectura geométrica de la tabla sigue dependiendo de la
comparación visual con el emulador.

Los rangos de 16 bytes de las ocho losetas están alineados y no
incluyen `$89E7`; por tanto, `$89E7` queda confirmado como un
desplazamiento visual de dos bytes respecto a la loseta lógica
`$89E9`, no como una nueva loseta ni como un nuevo límite de tabla.

### Conclusiones

- **Confirmado:** las ocho direcciones y sus valores de casilla.
- **Confirmado:** cada pareja se alterna mediante `$8158` y se escribe
  en el mapa desde la rama `'T'`.
- **Hipótesis visual:** la orientación arriba/abajo/izquierda/derecha
  propuesta por el usuario, pendiente de fijar contra la geometría de
  coordenadas del emulador.
- **No demostrado:** qué variante es exactamente el pie izquierdo o el
  pie derecho. El ASM solo demuestra que son dos variantes alternadas.

No se han movido bytes ni renombrado etiquetas del ASM por esta
verificación.

## Sesión 10 (continuación 2) — visor de las variantes intercaladas de `'T'`

Para poder inspeccionar visualmente los datos que quedan entre las ocho
losetas lógicas de `DIBUJAR_CASILLA_MAPA`, `recursos/sprites.html`
incorpora cuatro presets nuevos. Las dimensiones no son una suposición
visual: proceden de los parches que `DIBUJAR_ENTIDAD` hace sobre el
bucle común de volcado:

| Dirección | Valor escrito por `'T'` | Geometría usada al volcar |
|---|---:|---|
| `$8A09` | 4 | 2x16 |
| `$8A29` | 6 | 4x8 |
| `$8A49` | 5 | 4x8 |
| `$8A99` | 7 | 2x16 |

Estas variantes deben compararse con el emulador como imágenes
independientes. El hecho de que estén intercaladas físicamente junto a
`LOSETA_MAPA_PISADA_3..8` no las convierte en nuevas losetas del
dispatcher `DIBUJAR_CASILLA_MAPA`: son los gráficos que la rama `'T'`
selecciona mientras escribe valores en las celdas del mapa. La
identidad exacta de cada pie y su orientación jugable siguen pendientes
de confirmación visual.

El visor conserva además una vista del bloque físico completo
`$8919-$8AB8` (416 bytes) como 26 celdas consecutivas de 2x8 bytes.
Esta vista permite comprobar visualmente si los datos parecen una hoja
de tiles organizada, sin afirmar que todas las regiones se rendericen
con esa misma geometría durante la ejecución: las variantes `$8A09`,
`$8A29`, `$8A49` y `$8A99` se interpretan con sus dimensiones de 2x16
o 4x8 cuando las selecciona la rama `'T'`.

La hoja interpretada muestra **vistas**, no una partición exclusiva del
bloque: `$8A09` como `2x16` ocupa `$8A09-$8A28` y por tanto se solapa
con la vista `2x8` de `$8A19`; de forma análoga, `$8A99` como `2x16`
ocupa `$8A99-$8AB8` y se solapa con `$8AA9`. Esto explica por qué una
misma secuencia de bytes puede parecer un tile distinto según el punto
de entrada y la geometría que aplica el bucle de volcado.

### Pendiente

- Confirmar si `$89E7` es el inicio real de la loseta o un desplazamiento
  visual de la loseta lógica `$89E9`.
- Determinar si la identificación como pie derecho puede demostrarse
  desde la dirección de movimiento y el estado de animación, o si sigue
  siendo solo una interpretación visual.

## Sesión 9 — 2026-09-07: `recursos/flujo_detallado.html` — grafo real de llamadas, y una corrección de las Sesiones 6-7

Sesión de documentación pura (guiada por
`prompts/crear_y_mantener_flujo_detallado.md`): no se ha desensamblado
ningún byte nuevo del motor. El objetivo era crear el equivalente
conceptual, para Oh Mummy, del "flujo detallado de llamadas" que ya
existe en el proyecto hermano de Mad Mix Game — sin copiar nombres,
direcciones ni conclusiones de ese otro juego, solo la idea de tener
un grafo interactivo y no solo una tabla plana.

### Fuentes revisadas antes de escribir nada

`FINDINGS.md` completo (todas las sesiones 1-8, no solo un resumen),
`src/mummy1_body.asm` completo (1897 líneas), `src/main.asm`,
`src/README.md`, `README.md`, `recursos/flujo_programa.html`,
`recursos/flujo_secuencial.html` y `recursos/mapa_memoria.html`. Cada
`CALL`/`JP`/`JR` que aparece en el grafo se extrajo con una búsqueda
exhaustiva línea a línea sobre `mummy1_body.asm` (incluidas las
llamadas por dirección literal como `CALL $786C`/`CALL $7B39`/
`CALL $7DFC`, que el bloque `$6000`-`$6400` sigue usando porque nunca
se renombró tras nombrarse las rutinas destino en sesiones
posteriores) — no se ha dado por buena ninguna arista solo porque
`FINDINGS.md` la describiera en prosa.

### Corrección: 5 de las 6 variantes `RELLENAR_MARCO_DIAGONAL_*` SÍ tienen llamador conocido

`FINDINGS.md` Sesión 7 y `recursos/flujo_programa.html` afirmaban que
`RELLENAR_MARCO_DIAGONAL_1..6` (junto con `RELLENAR_MARCO_VACIO`) no
tenían "llamador conocido todavía". Repasando **todas** las
instrucciones `CALL`/`JP` de `mummy1_body.asm` (no solo las del bloque
ya reconstruido con nombres, sino también las del bloque mecánico
`$6000`-`$6400`) se confirma que el propio arranque **sí** llama a 5
de las 6 variantes por dirección literal, sin usar la etiqueta:
`CALL $7DFC` (`$6176`) → `RELLENAR_MARCO_DIAGONAL_1`, `CALL $7E05`
(`$61D9`) → `_2`, `CALL $7E0E` (`$6185`) → `_3`, `CALL $7E17`
(`$61CA`) → `_4`, `CALL $7E29` (x4: `$6194`/`$61A3`/`$61AC`/`$61BB`)
→ `_6`. La búsqueda de "llamador conocido" de la Sesión 7 solo miró
dentro del código ya reconstruido con nombres y pasó por alto que el
bloque `$6000`-`$6400` (reconstruido desde la Sesión 2, nunca
renombrado en esos puntos de llamada) ya las estaba llamando. Quedan
genuinamente **sin llamador conocido** solo `RELLENAR_MARCO_DIAGONAL_5`
(`$7E20`) y `RELLENAR_MARCO_VACIO` (`$7DF5`) — verificado que ninguna
instrucción de todo el fichero referencia esas dos direcciones ni sus
etiquetas. Corregido en `recursos/flujo_programa.html` (las 5 notas
correspondientes) y reflejado en `recursos/flujo_detallado.html`.

### Precisión: `DIBUJAR_CASILLA_MAPA` no cae en `CONSULTAR_CASILLA_MAPA`

`FINDINGS.md` Sesión 6 resume que `DIBUJAR_CASILLA_MAPA` "cae
directamente (sin `RET`) en `CONSULTAR_CASILLA_MAPA` (`$7D3E`)".
Verificando de nuevo el disassembly para el grafo: **todas** las
ramas de `DIBUJAR_CASILLA_MAPA` terminan en `JR $7CC4` (`$7D3C`),
una dirección que cae dentro de `DIBUJAR_ENTIDAD` (el bucle común de
volcado a pantalla), no en `CONSULTAR_CASILLA_MAPA` — que sí empieza
2 bytes después (`$7D3E`) pero nunca se alcanza por caída, solo por
`CALL` explícito desde otras rutinas. Es decir: hay un `JR` real (no
un fall-through) y su destino real es distinto del que resume la
prosa de la Sesión 6 — probablemente una confusión con la adyacencia
física de las direcciones en el fichero. No se reescribe el texto de
la Sesión 6 (no se reescribe historia ya cerrada), pero
`recursos/flujo_detallado.html` documenta el flujo verificado y esta
entrada dejа constancia del porqué difieren.

### Grafo publicado

`recursos/flujo_detallado.html`: 66 nodos (3 de arranque/cargador, 14
de firmware CPC, 2 de aleatoriedad/control, 7 de entidades-mapa-
colisiones, 21 de renderizado, 1 de sonido, 6 de menú/HUD/entrada, 1
que representa el hueco pendiente `$6401`-`$786B`, y 11 nodos de
datos agrupados en una capa opcional oculta por defecto), 82 aristas
de control (`CALL`/`CALL cc`/`JP`/`JP cc`/`JR`/caída sin `RET`,
verificadas una a una) y 15 aristas de acceso a dato (capa aparte,
nunca mezcladas con las de control). Ningún nodo de código se marca
como "confirmado": todas las 38 rutinas internas y el bloque
`$6000`-`$6400` siguen en "hipótesis" salvo su estructura mecánica
(bytes/compilación), tal como ya constaba en `FINDINGS.md` — esta
sesión no promueve ninguna hipótesis a hecho. Se documenta
explícitamente que **no existe ningún `JP (HL)`/`JP (IX)`/`JP (IY)`
confirmado** en el código reconstruido: los "dispatchers"
(`DIBUJAR_ENTIDAD`, `DIBUJAR_CASILLA_MAPA`) seleccionan tabla de datos
con cadenas `CP`/`JR`/`JP` a etiquetas fijas, no con saltos
indirectos — se marca así para no inventar "flujo indirecto" que no
está en el binario. El hueco `$6401`-`$786B` se representa como un
único nodo "pendiente" sin desglosar en subrutinas inventadas.

### Verificación

`python tools/build_all.py`: **0 diferencias** (motor 13190 bytes,
cargador 2564 bytes) — esta sesión solo tocó HTML/Markdown, ningún
byte del ASM. La página se abrió con Microsoft Edge en modo headless
(`--dump-dom`) para comprobar que el grafo no queda vacío: 66 nodos
renderizados, 11 ocultos por defecto (capa de datos), 82 aristas de
control dibujadas, tablas de nodos/relaciones indirectas pobladas
(67 y 13 filas con cabecera incluida) y ningún error de JavaScript en
consola.

### Documentación actualizada en esta sesión

`recursos/flujo_detallado.html` (nuevo), `recursos/flujo_programa.html`
(corrección de las 5 notas de `RELLENAR_MARCO_DIAGONAL_*`, aviso en la
nota superior), `README.md` y `src/README.md` (referencia a la nueva
página), `prompts/_base_reconstruccion.md` (añadida
`recursos/flujo_detallado.html` a la lista de documentación a revisar
y una regla explícita de mantenimiento por sesión). No se ha
modificado `recursos/flujo_secuencial.html` ni `recursos/mapa_memoria.html`
— se revisaron y no contienen ninguna afirmación que contradiga este
grafo.

### Pendiente para próximas sesiones

Todo lo que ya constaba pendiente en la Sesión 8 (hueco
`$6401`-`$786B`, resto de la rama `'T'` de `DIBUJAR_ENTIDAD`, los 40
bytes restantes de cada entrada de `MAPA_CASILLAS`, numeración de
teclas del firmware, bucle principal de juego, confirmación en
emulador de sprites/modo de pantalla) sigue pendiente — ver también la
sección "Pendientes para la siguiente sesión" de
`recursos/flujo_detallado.html`, que reproduce esta misma lista. A
partir de ahora, cada sesión que cambie el flujo de llamadas debe
actualizar `recursos/flujo_detallado.html` o dejar constancia explícita
de que no se ha visto afectado (regla añadida a
`prompts/_base_reconstruccion.md`).

## Sesión 11 — 2026-09-08: se nombran las 4 losetas de escritura de `'T'` que quedaban pendientes — mecanismo de dos capas confirmado

Sesión motivada por una pregunta del usuario tras revisar
`recursos/sprites.html`: había observado que, además de las 8 losetas
de 2x8 de `LOSETA_MAPA_PISADA_1..8`, conviven en la misma zona otras 6
losetas — 4 de 4x8 y 2 de 2x16 — más las 2 losetas iniciales de 4x16 de
un solo color (`$8919`/`$8959`). Hipótesis planteada: las de 4x8/2x16
las usa el código para pintar la huella nueva al pisar, y las 8 de 2x8
las usa para redibujar una huella ya existente cuando otro actor pasa
por encima.

### Verificación (releído `mummy1_body.asm` línea a línea, sin fiarse de la prosa de sesiones anteriores)

Confirmado: existe un único bucle de volcado a pantalla, compartido
por `DIBUJAR_ENTIDAD` y `DIBUJAR_CASILLA_MAPA`, en `$7CC4`. Su alto
(`B` de filas, operando de la instrucción en `$7CC5`, dirección
`$7CC6`) y su ancho (`B` de bytes/fila, operando de `$7CCF`, dirección
`$7CD0`) se fijan por **código automodificable** antes de cada salto a
`$7CC4` — de ahí que la misma rutina pueda volcar 4x16 (por defecto,
sprites de jugador/momia), 2x8 (`DIBUJAR_CASILLA_MAPA`, fija siempre
outer=8/inner=2 en `$7D32`/`$7D37`) o las geometrías variables de la
rama `'T'`.

La hipótesis del usuario se confirma, con un matiz importante que ya
apuntaba `FINDINGS.md` Sesión 8 (continuación 5) sin haberlo resuelto
del todo: la rama `'T'` de `DIBUJAR_ENTIDAD` (`$7B65`) escribe, para
cada una de las 4 direcciones de `($8157)`, un par de valores 1-8 en el
mapa (vía `CONSULTAR_CASILLA_MAPA`) y pinta en el momento un sprite con
geometría variable; `DIBUJAR_CASILLA_MAPA` usa después ese mismo valor
para elegir una de las 8 `LOSETA_MAPA_PISADA_*`, siempre en 2x8. En 2
de las 4 direcciones, el sprite que pinta `'T'` **son los mismos bytes**
que la loseta de redibujado (`$89F9`=`LOSETA_MAPA_PISADA_3`,
`$8A89`=`LOSETA_MAPA_PISADA_7`, ya nombrados en Sesión 8). En las otras
2 direcciones, `'T'` usa un sprite **propio y distinto**, hasta ahora
sin nombrar:

| Dirección | Rama | Valor escrito | Geometría confirmada | Etiqueta nueva |
|---|---|---:|---|---|
| `$8A09` | `($8157)==2`, 2º fotograma (`$7BF2`) | 4 | 2x16 (outer=16 por defecto, inner=2 de `$7BD7`) | `LOSETA_PISADA_ESCRITURA_VALOR4` |
| `$8A29` | `($8157)==3`, 1er fotograma (`$7BA5`) | 6 | 4x8 (outer=8 de `$7BAB`, inner=4 por defecto) | `LOSETA_PISADA_ESCRITURA_VALOR6` |
| `$8A49` | `($8157)==3`, 2º fotograma (`$7BC3`) | 5 | 4x8 (misma rama, outer=8 persiste) | `LOSETA_PISADA_ESCRITURA_VALOR5` |
| `$8A99` | `($8157)>=4`, 2º fotograma (`$7B96`) | 7 | 2x16 (outer=16 por defecto, inner=2 de `$7B77`) | `LOSETA_PISADA_ESCRITURA_VALOR7` |

Los valores/geometrías ya constaban en la tabla de la Sesión 10
(continuación 2); esta sesión los verifica de nuevo directamente sobre
el ASM (no se copian sin más) y les da etiqueta real, actualizando los
4 `LD IY,$8Axx` que las referenciaban por dirección literal.

`$8A09` (2x16, 32 bytes, `$8A09`-`$8A28`) **solapa** con los 16 bytes
de `LOSETA_MAPA_PISADA_4` (`$8A19`-`$8A28`): son bytes distintos solo
en `$8A09`-`$8A18`. Lo mismo ocurre entre `$8A99` (2x16,
`$8A99`-`$8AB8`) y `LOSETA_MAPA_PISADA_8` (`$8AA9`-`$8AB8`). Ya lo
señalaba la Sesión 10 (continuación 2); queda ahora documentado junto
a las propias etiquetas en `mummy1_body.asm`. `$8A29`/`$8A49` (4x8,
32 bytes cada uno) no solapan con ninguna `LOSETA_MAPA_PISADA_*`.

Las 2 losetas de 4x16 de un único color que preguntaba el usuario
(`$8919`, todo `$00`, y `$8959`, todo `$F0`) ya estaban identificadas
desde la Sesión 8 (continuación 2): son el sprite por defecto de
`DIBUJAR_ENTIDAD` para un tipo de entidad no reconocido y el del
carácter `' '` respectivamente — este último es también el destino por
defecto de `DIBUJAR_CASILLA_MAPA` para valores de casilla fuera de
1-8. Forman parte del mismo mecanismo de dos capas (loseta "sin
huella"), no son un caso nuevo.

**Lo que sigue sin confirmarse**: la orientación real de cada una de
las 4 direcciones (arriba/abajo/izquierda/derecha) y la identidad
visual de las 4 losetas recién nombradas contra una captura de
emulador — igual que el resto de losetas de pisada, están confirmadas
en estructura y despacho, no en identidad visual verificada fuera del
propio código y la inspección de píxeles.

### Cambios en `mummy1_body.asm`

4 etiquetas nuevas (`LOSETA_PISADA_ESCRITURA_VALOR4/_5/_6/_7`) con
comentario de estructura/geometría/solape y nivel de confianza junto a
cada una; 4 `LD IY,` renombrados de dirección literal a etiqueta;
actualizado el comentario de cabecera de `DIBUJAR_ENTIDAD` que decía
"pendiente de nombrar". Ningún byte del binario cambia.

### Verificación

`python tools/build_all.py`: **0 diferencias** (motor 13190 bytes,
cargador 2564 bytes) — verificado antes y después de escribir esta
entrada.

### Pendiente para próximas sesiones

Sigue todo lo ya pendiente (hueco `$6401`-`$786B`, orientación real
arriba/abajo/izquierda/derecha de las 4 direcciones de `'T'`,
confirmación en emulador de todas las losetas de pisada, numeración de
teclas del firmware, bucle principal de juego). Actualizado
`recursos/flujo_programa.html` con las 4 etiquetas nuevas; no se ha
tocado `recursos/flujo_detallado.html` en su grafo de llamadas (las 4
etiquetas nuevas son datos, no rutinas, y ya estaban representadas como
acceso a dato desde `DIBUJAR_ENTIDAD`) más allá de refrescar la fecha
de última actualización.

## Sesión 12 — 2026-09-08: primer tramo real del último hueco (`$6401`-`$6528`, 296 bytes) — entrada tras el nombre, despachador P/I/O y pantalla de opciones

Ataca por primera vez el único `INCBIN` que quedaba en todo el motor
(`$6401`-`$786B`, 5227 bytes). Metodología: arrancar desde los dos
puntos de entrada reales ya localizados (no avanzar linealmente a
ciegas) — `$6401` (caída natural desde la cabecera cuando SÍ se
escribió un nombre) y `$6404` (`JP Z` desde `$6380` cuando NO se
escribió) — y desensamblar con `tools/z80_disasm.py` como ayuda de
lectura, verificando cada hipótesis contra código y datos ya
reconstruidos en sesiones anteriores antes de darla por buena.

### Los dos puntos de entrada convergen

`$6401` resulta ser un simple `JP $636C` (3 bytes) hacia una dirección
que YA estaba en la cabecera desensamblada ($6000-$6400, verificada
desde la Sesión 6) pero sin nombre propio. Comprobado con cuidado que
$636C **nunca se alcanza por caída natural** desde arriba: la
instrucción justo anterior en $636A es un `JR` incondicional que
siempre se la salta. Solo se llega ahí por 2 saltos: `JR Z,$636C` en
$6344 (dentro del propio bucle de tecleo del nombre) y, desde ahora, el
nuevo `JP $636C` en $6401. Es decir: $636C es un punto de entrada real,
no relleno — se le da nombre (`REANUDAR_MENU_TRAS_NOMBRE`) sin tocar
ni un byte de la cabecera ya verificada (solo se añade la etiqueta;
0 diferencias antes y después). Ese código redibuja algo en `$86E8`,
anima los indicadores de menú (B=1/B=2) y, en cuanto `($8168)=0`, cae
en `$6404` — así que ambos caminos confirmados en el enunciado de la
tarea convergen exactamente donde se esperaba.

### `DESPACHAR_MENU_PRINCIPAL` ($6404): P/I/O

Lee un carácter y compara contra `'P'/'p'` → `$6529` (jugar),
`'I'/'i'` → `$68B2` (instrucciones), `'O'/'o'` → `PANTALLA_OPCIONES`
($642B); cualquier otra tecla vuelve al bucle de la cabecera. Encaja
exactamente con el menú principal ya confirmado como texto literal en
`TEXTO_MENU_PRINCIPAL` (Sesión 8) — confianza alta.

### `PANTALLA_OPCIONES` ($642B-$6528): la pantalla "OH MUMMY - OPTIONS"

Resuelve genuinamente 4 preguntas de `TEXTO_MENU_OPCIONES` ($7EFD,
Sesión 8), en el mismo orden en que aparecen en el texto, y con
resultados que **cuadran numéricamente** con el enunciado de cada
pregunta:

- `"SPEED OF GAME (1-5) ?" (1 IS FASTEST)`: lee un dígito '1'-'5' y
  calcula `($8153) = $0100 + dígito*$00E0` (480..1376). `($8153)` ya
  era conocida desde la Sesión 6 como el contador que consume
  `ANIMAR_OPCION_MENU` con `DEC DE`/`JR NZ` — a mayor dígito, mayor
  retardo, cuadra con "1 = más rápido". Confianza alta.
- `"DIFFICULTY LEVEL (1-5) ?" (1 IS HARDEST)`: lee un dígito y calcula
  `($8161)` duplicando `$07F8` "dígito" veces y tomando el byte alto
  (15/31/63/127/255 para dígito 1..5). `($8161)` ya se usaba en
  `COLOCAR_ENTIDAD` (bloque `$786C`-`$7EFC`, Sesión 6) como límite de
  `GENERAR_ALEATORIO` para decidir si un enemigo persigue al jugador —
  a mayor `($8161)`, menos probable el 0 exacto, menos persecución;
  cuadra exactamente con "1 = más difícil". Confianza alta.
- `"BACKGROUND MUSIC (Y-N) ?"`: tecla `'+'`/`'.'` alterna
  `FLAG_MUSICA_FONDO` (`$7FC4`, ya nombrada y usada por
  `ACTUALIZAR_SECUENCIA_SONIDO`) entre `'Y'`/`'N'`, reiniciando el
  guion de sonido circular al activarla. Confianza alta.
- `"SOUND EFFECTS (Y-N) ?"`: mismo patrón sobre `FLAG_EFECTOS_SONIDO`
  (`$7FC5`). **Resuelve un pendiente explícito de la Sesión 8**
  ("hipótesis media: simetría con FLAG_MUSICA_FONDO, sin CALL que la
  lea todavía localizado") — ahora se localiza el punto donde se
  ESCRIBE; el código que la LEE sigue sin localizar, así que sube a
  confianza alta en su papel de flag pero sigue pendiente el consumidor.

Confirma con Intro o `'L'` y salta a `$6223` (dentro de la cabecera,
flujo de confirmar 1/2 jugadores).

### Un hallazgo que corrige una lectura ingenua de `REPETIR_CARACTER`

Los 6 `CALL REPETIR_CARACTER` de este tramo usan como argumento `HL`
apuntando DENTRO de `TEXTO_MENU_OPCIONES`/`TEXTO_HISTORIA_ATRACCION`
(p. ej. `$7EFD`, `$7F4C`, `$7FBD`, `$80FB`). Antes de escribir esto se
comprobó de nuevo, leyendo el propio código de `REPETIR_CARACTER`
(`$7EF4`-`$7EFC`), que la rutina **repite un único carácter fijo B
veces** (`LD B,(HL):INC HL:LD A,(HL):CALL FIRM_TXT_OUTPUT:DJNZ` al
`LD A,(HL)`, sin volver a incrementar `HL`) — NO recorre ni imprime una
cadena. Por tanto estas llamadas NO imprimen los rótulos "OH MUMMY -
OPTIONS"/"SPEED OF GAME..." como texto legible: reutilizan como
"contador+carácter" un par de bytes que, por coincidencia de layout,
caen dentro de esas tablas de texto (p. ej. `$7FBD`→cuenta=3,
carácter=`'Y'`). Se deja documentado con confianza baja/media sobre el
efecto visual exacto (probable adorno/parpadeo) — la impresión real de
los rótulos como texto queda sin localizar, pendiente en el resto del
`INCBIN`.

### Exploración (sin promover a fuente) más allá de `$6528`

Para decidir el punto de corte se desensambló mecánicamente, sin
comprometerlo a `mummy1_body.asm`, hasta bastante más allá ($6529-
$68B2, no verificado con el mismo rigor). Deja pistas concretas para
la siguiente sesión, todas con dirección exacta:

- `$6529`: arranque de partida — inicializa contadores (`($816A)=5`,
  `($815A)=0` puntuación probable, `($815C)`=nivel, `($8169)`=0),
  limpia el array de entidades vía `BORRAR_BLOQUE_ESTADO`, y en
  `$6685`-`$66A8` **resuelve un pendiente explícito de la Sesión 7**:
  localiza por fin al llamador de `RELLENAR_MARCO_DIAGONAL_1..6` — un
  despacho por `($815C)` (nivel) que parchea con código
  automodificable el operando de un `CALL $7E29` en `$66BA`, eligiendo
  una de 5 variantes (falta `RELLENAR_MARCO_DIAGONAL_2`) según el
  nivel actual. Sin promover todavía — falta verificar el resto del
  bloque (colocación aleatoria de hasta 14 elementos en `$81D6`
  evitando colisión, `$65AD`-`$65D2`, posible generación del
  laberinto/pirámide) con el mismo rigor que el resto de esta sesión.
- `$66ED`-`$6736`: posible bucle principal de juego (llama en orden a
  `$7578`, `$77D1`, `$7637`, `$7566`, `ESPERAR_TECLA_2C`, para cada
  jugador con B=1 y B=2) — ninguna de esas 4 direcciones intermedias
  está todavía resuelta.
- `$6739`-`$68AC`: pantalla de "GAME OVER" — imprime varios fragmentos
  de `TEXTO_HISTORIA_ATRACCION` (Sesión 8) en el orden exacto del
  texto ($801B/$8040/$8064/$8088/$809D/$80B8/$80C2/$80E0/$80EA/$80FB/
  $8125), y en `$6803`-$68AB` compara la puntuación en `($815A)` contra
  una tabla de puntuaciones altas de 12-18 bytes por registro en
  `$86D4`, desplazándola con `LDIR` si hay una nueva entrada — probable
  gestión de la tabla HI-SCORE ya confirmada como dato en la Sesión 8.
- `$68B2`: entrada `'I'` (instrucciones) desde `DESPACHAR_MENU_PRINCIPAL`,
  sin explorar todavía.

### Verificación

`python tools/build_all.py`: **0 diferencias** (motor 13190 bytes,
cargador 2564 bytes), verificado antes y después de cada cambio (tras
añadir la etiqueta en la cabecera, tras sustituir el `INCBIN`, y de
nuevo al cerrar la sesión).

### Cambios en `mummy1_body.asm`

- Etiqueta añadida (sin cambiar bytes) en la cabecera: `$636C` →
  `REANUDAR_MENU_TRAS_NOMBRE`; los 2 saltos que apuntaban ahí por
  dirección literal (`$6344`, `$6380`) pasan a usar el nombre
  simbólico (`$6380` además pasa a `DESPACHAR_MENU_PRINCIPAL`).
- `INCBIN "data/mummy1_resto_sin_analizar.bin", 0, 5227` sustituido por
  296 bytes de código fuente real (`FIN_INTRODUCIR_NOMBRE`,
  `DESPACHAR_MENU_PRINCIPAL`, `PANTALLA_OPCIONES`) + `INCBIN
  "data/mummy1_resto_sin_analizar.bin", 296, 4931` para el resto
  (`$6529`-`$786B`).

### Documentación actualizada

`README.md`, `README.en.md`, `src/README.md` (cifras del tramo
pendiente actualizadas a 4931 bytes / `$6529`-`$786B`, tabla de
rutinas de la Sesión 12 añadida en `src/README.md`),
`recursos/flujo_programa.html` (3 entradas nuevas) y
`recursos/flujo_detallado.html` (2 nodos de código nuevos —
`DESPACHAR_MENU_PRINCIPAL`/`PANTALLA_OPCIONES` — y las aristas hacia
`$6529`/`$68B2` marcadas como pendientes, según la regla de
mantenimiento de `prompts/_base_reconstruccion.md`).

### Pendiente para la siguiente sesión

**Punto de entrada real desde el que continuar: `$6529`** (arranque de
partida), justo donde termina el nuevo `INCBIN`. Ya hay pistas
concretas (ver arriba) para no tener que redescubrirlas: la resolución
del llamador de `RELLENAR_MARCO_DIAGONAL_1..6` en `$6685`, la
colocación aleatoria de 14 elementos en `$81D6` (`$65AD`-`$65D2`,
posible generación de pirámide/laberinto — sin verificar todavía), el
posible bucle principal de juego en `$66ED`-`$6736` (con 4 llamadas
internas sin resolver: `$7578`, `$77D1`, `$7637`, `$7566`), la pantalla
de "GAME OVER"/HI-SCORE en `$6739`-`$68AC`, y la entrada `'I'` de
instrucciones en `$68B2`. Sigue también todo lo pendiente de sesiones
anteriores (orientación de las 4 direcciones de `'T'`, confirmación en
emulador, numeración de teclas del firmware).

## Sesión 13 — 2026-09-09: arranque de partida, bucle de juego y fin de partida (`$6529`-`$68B1` + `$7863`-`$786B`, 914 bytes) — resuelve el llamador de `RELLENAR_MARCO_DIAGONAL_1..6`

Ataca el hueco más grande que quedaba (`$6529`-`$786B`, 4931 bytes),
siguiendo la metodología obligatoria: arranca desde el punto de
entrada real ya confirmado (`$6529`, destino de los 2 `JP Z,$6529` de
tecla P/p en `DESPACHAR_MENU_PRINCIPAL`) y sigue el hilo de
llamadas/saltos sin avanzar linealmente a ciegas. Se verificaron todas
las pistas dejadas por la Sesión 12 leyendo el disassembly real antes
de nombrar nada (ver más abajo, confirmado/descartado/pendiente para
cada una).

### Metodología de esta sesión

Se generó un desensamblado mecánico auxiliar (script propio sobre
`tools/z80_disasm.py` como librería, sin comprometerlo al repositorio)
para leer instrucción a instrucción desde `$6529` de forma continua,
sin saltos, hasta confirmar el punto de corte natural (`$68B1`, justo
antes de la entrada `'I'` de instrucciones en `$68B2`). Cada hipótesis
semántica se contrastó contra código y datos **ya reconstruidos** en
sesiones anteriores (variables `$8155`/`$8157`/`$8158`/`$8161`/`$8169`
ya usadas por `DIBUJAR_ENTIDAD`/`COLOCAR_ENTIDAD`/`INICIALIZAR_UNA_ENTIDAD`,
la tabla HI-SCORE en `$86C2`-`$8749` ya leída por el código de
cabecera en `$6310`-`$6325`, etc.) antes de darla por buena.

### `INICIAR_PARTIDA` (`$6529`) / `PREPARAR_NIVEL` (`$6534`)

`INICIAR_PARTIDA` es la única vez en todo el tramo que se fijan
vidas=5 (`$816A`) y puntuación=0 (`$815A`); cae en `PREPARAR_NIVEL`,
que reinicia el nivel (`$815C`) a 0 y es también el destino de las 2
`JP NZ,$6534` de `PANTALLA_STOP_PRESS` (teclas L/Intro tras completar
los 6 niveles). Hallazgo a documentar con honestidad: esa reentrada
**no** toca vidas ni puntuación — solo el nivel. No se ha encontrado
ningún otro punto en el tramo que las reinicie, así que ese es el
comportamiento real tal cual está compilado (confianza alta en la
estructura, media en que sea intencional). Si la puntuación no es 0 al
entrar en `PREPARAR_NIVEL` (solo posible por esa reentrada), se reduce
a la mitad aproximadamente el límite de persecución de la IA
(`$8161`, `SRL A:OR $03`) — partidas sucesivas se vuelven más
difíciles (hipótesis media-alta).

### `PREPARAR_TESOROS_NIVEL` (`$6585`): confirma la pista de "colocación aleatoria de 14 elementos" de la Sesión 12

Rellena de `$60` (marcador "vacío") las 25 casillas `$81DE`-`$81F6`,
fuerza a 0 seis celdas fijas (offsets `IY`+13/14/20/21/27/28 de
`$81D6` — hipótesis media: paredes/columnas fijas del diamante
central), y coloca 14 "tesoros" en casillas libres elegidas al azar
(`GENERAR_ALEATORIO(26)+8`, reintenta si la celda no está a `$60`). El
valor escrito sube de `$10` en `$10` (`$10,$20,$30,$40`) y a partir de
`$50` se queda fijo para el resto de colocaciones — confirmado leyendo
el propio bucle (`CP $50:JR Z,salta-incremento`). Interpretación
(confianza media-alta): 4 tesoros de valor creciente + 10 tesoros
"comunes" del valor más alto. Sin confirmar en emulador el efecto
visual/de puntuación exacto.

### `ACTUALIZAR_HUD_VIDAS` (`$65D5`): confirma `$816A` como contador de vidas

Llama a `IMPRIMIR_PUNTUACION_HUD` (cierra el tramo `$7863`-`$786B`,
ver más abajo) y después dibuja tantos iconos de jugador ('A') como
vidas queden en `$816A`, avanzando la posición de pantalla de 4 en 4 y
alternando el fotograma. Es la evidencia que sube `$816A` a confianza
alta como "contador de vidas visible en el HUD": se inicializa a 5 en
`INICIAR_PARTIDA` y puede subir hasta un tope de 7 como premio
aleatorio en `PANTALLA_STOP_PRESS` (ver más abajo). **Importante,
documentado con honestidad**: no se ha localizado en este tramo ningún
punto que lo DECREMENTE — su consumo real al ser atrapado por una
momia, si existe, cae dentro de alguna de las 4 llamadas todavía sin
resolver del bucle principal. Confianza media (no alta) en que sea
literalmente el clásico contador de "vidas restantes".

### `SELECCIONAR_DIAGONAL_MARCO_NIVEL` (`$6685`): RESUELVE el pendiente explícito de la Sesión 7/12

Según el nivel actual (`$815C`) elige una de 5 variantes de
`RELLENAR_MARCO_DIAGONAL_1..6` (nivel 0/1→`_6`, 2→`_4`, 3→`_5`,
4→`_1`, ≥5→`_3`) y parchea con código automodificable el operando de
`CALL $7E29` en `$66B9` (los 2 bytes en `$66BA`) antes de ejecutarlo.
`RELLENAR_MARCO_DIAGONAL_2` **sigue sin usarse** en ningún punto de
este tramo — confirma la sospecha que ya dejaba apuntada la Sesión 12.
El bucle anidado B=4 (paso `HL+=$2800`) × B=5 (paso `HL+=$000E`)
dibuja una rejilla de 4×5=20 bloques diagonales — probable borde
decorativo de la pirámide de ese nivel. Confianza alta en la
estructura (verificada byte a byte, cuadra exacto con la pista de la
Sesión 12); media en el papel visual exacto.

### `BUCLE_PRINCIPAL_JUEGO` (`$66ED`): confirma la pista de la Sesión 12, con hallazgos nuevos

Empieza comprobando la tecla `'B'` — **hallazgo**: ambas ramas
(pulsada o no) confluyen en el mismo destino (`TRAMPOLIN_TECLA_B` →
`INICIO_TURNO_JUGADOR1`), sin efecto funcional observable (confianza
alta en la estructura, baja en su propósito — posible resto de una
funcionalidad no terminada). Para cada jugador (B=1, luego B=2):
`ANIMAR_OPCION_MENU` y una secuencia de 4 llamadas que **siguen sin
resolver** (`$7578`, `$77D1`, `$7637`, `$7566` — las mismas 4 de la
Sesión 12, confirmado que caen dentro del hueco `$68B2`-`$7862` que
sigue sin analizar), 2 de las cuales comprueban el acarreo
(`JP C,PANTALLA_GAME_OVER`) tras `CALL $7578` — hipótesis alta de que
el acarreo señaliza "jugador atrapado por una momia". Tras ambos
turnos, si no quedan coleccionables (`($816D)=0`, primer byte de la
entidad #1) llama a `$7513` (también sin resolver — hipótesis media:
avance de nivel).

### `PANTALLA_STOP_PRESS` (`$6739`) vs `PANTALLA_GAME_OVER`/`ACTUALIZAR_TABLA_PUNTUACIONES` (`$67B3`/`$6803`): resuelve y matiza la pista de "GAME OVER/HI-SCORE" de la Sesión 12

Son dos pantallas de fin de partida **completamente separadas**, sin
código compartido:

- `PANTALLA_STOP_PRESS` se alcanza solo al completar los 6 niveles
  (`JP Z` desde `PREPARAR_NIVEL`). Imprime la noticia "STOP PRESS...
  excavation of ancient Egyptian pyramid" y sortea entre 200 puntos de
  bonus o una vida extra (tope 7). Termina esperando L/Intro y salta
  DIRECTAMENTE a `PREPARAR_NIVEL`.
- `PANTALLA_GAME_OVER` se alcanza solo por las 4 `JP C` del bucle
  principal (muerte). Imprime "GAME OVER" letra a letra con pausa
  dramática y entra automáticamente (sin preguntar nada) en
  `ACTUALIZAR_TABLA_PUNTUACIONES`.

**Hallazgo importante, verificado byte a byte y no una hipótesis**: el
camino de "ganar" (`PANTALLA_STOP_PRESS`) **no pasa nunca** por
`ACTUALIZAR_TABLA_PUNTUACIONES` — solo "morir" consulta/actualiza la
tabla HI-SCORE en este tramo. Es una asimetría real del juego
compilado.

`ACTUALIZAR_TABLA_PUNTUACIONES` compara la puntuación contra la última
entrada de la tabla HI-SCORE (`$86C2`-`$8749`, 5 entradas de 18 bytes,
ya confirmada por el código de cabecera `$6310`-`$6325` que la lee
para mostrarla). Si no la supera, `JP C,$6039` — dentro de la cabecera
ya reconstruida, vuelve al modo atracción sin pedir nombre. Si la
supera: activa `($8168)=1` (el flag que `REANUDAR_MENU_TRAS_NOMBRE`
usa para saber si hay que teclear nombre, Sesión 12), calcula el rango
1-5, desplaza las entradas peores con `LDIR`, escribe la puntuación +
11 espacios en el hueco liberado, y `JP $6223` (también dentro de la
cabecera ya reconstruida). Cierra así, con evidencia directa, el
mecanismo de inserción en la tabla HI-SCORE que quedaba solo
parcialmente entendido desde la Sesión 8/12.

### `$7863`-`$786B` (9 bytes): cierra el último tramo del `INCBIN` original

`IMPRIMIR_PUNTUACION_HUD`: posiciona el cursor y cae, sin ningún salto
de por medio, en `IMPRIMIR_NUMERO_HL` (`$786C`, ya reconstruida desde
antes de la Sesión 12) — confirmado que las 3 instrucciones enlazan
exactamente con el primer byte de esa rutina. Localizada porque
`ACTUALIZAR_HUD_VIDAS` la llama con `CALL $7863`. Se promueve por
separado, dejando un `INCBIN` intermedio (`$68B2`-`$7862`) para el
tramo todavía sin analizar.

### Pistas de la Sesión 12: confirmado / descartado / pendiente

- **Llamador de `RELLENAR_MARCO_DIAGONAL_1..6` en `$6685`-`$66A8`**:
  **CONFIRMADO** con precisión — ver `SELECCIONAR_DIAGONAL_MARCO_NIVEL`
  arriba, incluida la confirmación de que `_2` sigue sin usarse.
- **Colocación aleatoria de 14 elementos en `$81D6`, código en
  `$65AD`-`$65D2`**: **CONFIRMADO** — ver `PREPARAR_TESOROS_NIVEL`
  arriba, con el detalle nuevo de los 4 valores crecientes + 10
  comunes.
- **Bucle principal de juego en `$66ED`-`$6736`, con 4 llamadas sin
  resolver a `$7578`, `$77D1`, `$7637`, `$7566`**: **CONFIRMADA la
  estructura** (`BUCLE_PRINCIPAL_JUEGO`), pero las 4 llamadas **SIGUEN
  SIN RESOLVER** — confirmado que caen dentro del hueco `$68B2`-`$7862`
  todavía pendiente (no se pudieron seguir esta sesión: la Sesión 12
  las suponía "probablemente dentro del hueco a analizar", lo cual se
  confirma literalmente).
- **Pantalla GAME OVER/HI-SCORE en `$6739`-`$68AC`**: **CONFIRMADA y
  matizada** — en realidad son DOS pantallas distintas
  (`PANTALLA_STOP_PRESS` y `PANTALLA_GAME_OVER`) con la asimetría del
  hi-score descrita arriba, no una sola pantalla combinada como
  sugería la redacción de la pista.
- **Entrada `'I'` de instrucciones en `$68B2`**: explorada
  mecánicamente esta sesión (ver más abajo) pero **NO promovida** —
  queda pendiente para la siguiente sesión.

### Exploración (sin promover a fuente) del hueco restante `$68B2`-`$7862`

Desensamblado mecánico sin comprometer al repositorio, con mucho menos
rigor que el resto de esta sesión (no se verificó byte a byte el
límite exacto entre código y datos). Estructura observada: un
despachador corto en `$68B2` que llama en cadena a `$69D2` (hipótesis:
"imprimir bloque de texto", recibe `HL` apuntando a un párrafo),
`$698A` y `$69AC` (hipótesis: separadores/páginas), y a `$7D85`/`$7D9D`
(ya definidas en `RELLENAR_FILAS_MASCARA`, sin resolver su papel
aquí). A partir de aproximadamente `$69EA` y durante la mayor parte
del tramo el contenido son bloques de **texto literal** (la pantalla
de instrucciones del juego), apuntados por los `HL` de cada
`CALL $69D2` — confirmado por lectura directa de varios fragmentos
(texto legible mezclado con códigos de control, mismo patrón que
`TEXTO_MENU_OPCIONES`/`TEXTO_HISTORIA_ATRACCION` de la Sesión 8). No
se ha separado con precisión dónde acaba el código del despachador y
dónde empieza cada bloque de texto — se deja completo como `INCBIN`,
pendiente para la siguiente sesión.

### Cambios en `mummy1_body.asm`

`INCBIN "data/mummy1_resto_sin_analizar.bin", 296, 4931` (`$6529`-`$786B`)
sustituido por: 905 bytes de código fuente real (`INICIAR_PARTIDA`,
`PREPARAR_NIVEL`, `PREPARAR_TESOROS_NIVEL`, `ACTUALIZAR_HUD_VIDAS`,
`LIMPIAR_PANELES_NIVEL`, `SELECCIONAR_DIAGONAL_MARCO_NIVEL`,
`COLOCAR_JUGADOR_INICIAL`, `BUCLE_PRINCIPAL_JUEGO`,
`INICIO_TURNO_JUGADOR1`, `PANTALLA_STOP_PRESS`, `PANTALLA_GAME_OVER`,
`ACTUALIZAR_TABLA_PUNTUACIONES`, `TRAMPOLIN_TECLA_B`) + `INCBIN
"data/mummy1_resto_sin_analizar.bin", 1201, 4017` para `$68B2`-`$7862`
+ 9 bytes de código fuente real (`IMPRIMIR_PUNTUACION_HUD`) para
`$7863`-`$786B`. Ningún byte del binario cambia.

### Verificación

`python tools/build_all.py`: **0 diferencias** (motor 13190 bytes,
cargador 2564 bytes) — verificado tras sustituir el `INCBIN` y de
nuevo al cerrar la sesión.

### Documentación actualizada

`README.md`, `README.en.md`, `src/README.md` (cifras del tramo
pendiente actualizadas a 4017 bytes / `$68B2`-`$7862`, tabla de
rutinas de la Sesión 13 añadida en `src/README.md`),
`recursos/flujo_programa.html` (entradas nuevas de esta sesión),
`recursos/flujo_detallado.html` (nodos y aristas nuevos, según la
regla de mantenimiento de `prompts/_base_reconstruccion.md`) y
`recursos/mapa_memoria.html` (divide el segmento "sin analizar
todavía" en el punto donde termina el nuevo tramo, `$68B1`/`$68B2`,
más el hueco final resuelto en `$786B`/`$786C`).

### Pendiente para la siguiente sesión

**Punto de entrada real desde el que continuar: `$68B2`** (entrada
`'I'` de instrucciones desde `DESPACHAR_MENU_PRINCIPAL`), único hueco
que queda en todo el motor (`$68B2`-`$7862`, 4017 bytes). Pistas
concretas dejadas para no perder tiempo redescubriéndolas: el
despachador de texto en `$68B2`-`$69EAish` (`$69D2`/`$698A`/`$69AC`),
el papel de `$7D85`/`$7D9D` en ese contexto, y el límite exacto entre
código y las tablas de texto de la pantalla de instrucciones. También
siguen pendientes, ahora confirmado que caen dentro de este mismo
hueco: las 5 llamadas sin resolver del bucle principal (`$7578`,
`$77D1`, `$7637`, `$7566`, `$7513`). Sigue también todo lo pendiente
de sesiones anteriores (orientación de las 4 direcciones de `'T'`,
confirmación en emulador, numeración de teclas del firmware, consumo
real de `$816A` como vidas).

## Sesión 14 — 2026-09-10: cierre del último hueco del motor (`$68B2`-`$7862`, 4017 bytes) — pantalla de instrucciones, mecánica de "pintar casillas" y núcleo de movimiento del jugador

Ataca el último hueco `INCBIN` que quedaba en todo el motor
(`$68B2`-`$7862`, 4017 bytes), siguiendo la metodología obligatoria:
arranca desde los 6 puntos de entrada reales ya confirmados por código
reconstruido (`$68B2` desde `DESPACHAR_MENU_PRINCIPAL`, y las 5
llamadas de `BUCLE_PRINCIPAL_JUEGO`/`INICIO_TURNO_JUGADOR1`: `$7578`,
`$77D1`, `$7637`, `$7566`, `$7513` condicional), priorizando estas 5
últimas como pedía el prompt de la sesión. **Resultado: el hueco
completo se cierra en esta sesión** — no queda ningún `INCBIN` de
código sin analizar en `mummy1_body.asm`.

### Metodología de esta sesión

Se generó un desensamblado mecánico auxiliar (script Python propio
sobre `tools/z80_disasm.py` como librería, sin comprometerlo al
repositorio) para leer instrucción a instrucción desde `$7513` y desde
`$68B2` de forma continua. La decodificación fue limpia y sin
interrupciones en TODO el tramo `$7513`-`$7862` (350 bytes) — ninguna
secuencia de bytes decodificada como "basura"/dato disfrazado de
código, y los 5 puntos de entrada conocidos coinciden EXACTAMENTE con
límites de instrucción — confirmación fuerte de que es código real de
principio a fin. Cada hipótesis semántica se contrastó contra código y
datos ya reconstruidos (`ARRAY_ENTIDADES`, `CASILLA_A_DIRECCION_PANTALLA`,
`CONSULTAR_CASILLA_MAPA`, `RELLENAR_MARCO_DIAGONAL_1..6`,
`DIBUJAR_TRAMO_MARCO_1..4`, `MOVER_INDICADOR_MENU`, `HAY_COLISION`,
`CALCULAR_CASILLA_ADYACENTE`, los sprites `SPRITE_MOMIA_G1_F1..`) antes
de darla por buena.

### Primer tramo: `PANTALLA_INSTRUCCIONES` (`$68B2`-`$69EA`, 313 bytes) — CONFIRMA la hipótesis mecánica de la Sesión 13

La Sesión 13 había explorado este despachador mecánicamente sin
promoverlo. Esta sesión lo verifica instrucción a instrucción y lo
promueve completo: `PANTALLA_INSTRUCCIONES` dibuja dos tramos del
marco decorativo (`DIBUJAR_TRAMO_MARCO_1`/`_2`) y llama en cadena a
`IMPRIMIR_PARRAFO_INSTRUCCIONES` (antes `$69D2`) para los 23 párrafos
de texto (`TEXTO_INSTR_01..23`, ver más abajo), con
`LIMPIAR_VENTANA_INSTRUCCIONES` (antes `$698A`) y
`ESPERAR_CONTINUAR_INSTRUCCIONES` (antes `$69AC`, espera `'C'`/botón de
fuego, reutilizando el mismo texto "Press C or Fire Button to
Continue" de la pantalla de GAME OVER en `$80FB`) entre grupos de
párrafos. `RESTAURAR_VENTANA_TEXTO_COMPLETA` (antes `$699C`) devuelve
la ventana de texto a pantalla completa. Confianza alta en toda la
estructura.

### Segundo tramo: 23 bloques de texto literal (`TEXTO_INSTR_01..23`, `$69EB`-`$7512`, 2856 bytes) — ACOTA CON EXACTITUD la hipótesis de la Sesión 13

La Sesión 13 dijo "a partir de `$69EA`, mayormente texto literal" sin
verificarlo byte a byte. Esta sesión lo confirma con precisión total:
son **23 bloques contiguos** (sin huecos ni relleno entre ellos —
verificado programáticamente leyendo el byte de longitud de cada
bloque y comprobando que el siguiente empieza exactamente donde acaba
el anterior) con formato `[1 byte de longitud][texto]`, el mismo
formato que consume `IMPRIMIR_PARRAFO_INSTRUCCIONES`. El bloque 23
(`TEXTO_INSTR_23`) termina **exactamente** en `$7512`, el byte justo
antes de `$7513` — el primer punto de entrada real del bucle de juego.
Es decir, el límite entre "despachador de instrucciones" y "bucle de
juego" cae exactamente en la frontera entre datos y código, sin solape
ni relleno: confirmación muy fuerte de que ambas reconstrucciones
(Sesión 13 corregida + esta sesión) son correctas. El texto es el
manual real de "OH MUMMY" en inglés (escenario, reglas del tablero de
20 casillas, controles, niveles de dificultad, despedida).

### Tercer tramo: `$7513`-`$7862` (350 bytes) — el núcleo del bucle de juego, las 5 llamadas prioritarias

**Corrección a la hipótesis "todo texto" de la Sesión 13**: este tramo
final (350 bytes) es código real de principio a fin, no texto. Las 5
llamadas pendientes desde `BUCLE_PRINCIPAL_JUEGO` quedan resueltas:

- **`ANIMAR_APARICION_MOMIA_GUARDIANA`** (`$7513`, llamada condicional
  `CALL NZ,$7513` cuando `($816D)<>0`): decrementa un contador iniciado
  en 31 y, en llamadas alternas, copia 4 bytes del sprite
  `SPRITE_MOMIA_G1_F1` (`$8CB9`) a la casilla de pantalla apuntada por
  la nueva variable `VARIABLE_CASILLA_APARICION_MOMIA` (`$8136`) —
  efecto de "la Momia Guardiana emergiendo poco a poco", coherente con
  `TEXTO_INSTR_12` ("it will dig its way out"). Al llegar a 0, limpia
  la casilla del mapa y genera una entidad de reemplazo. Confianza
  media-alta.
- **`COMPROBAR_SALIDA_NIVEL`** (`$7566`): si `($8170)` (Momia Real) Y
  `($816F)` (Llave) están ambos activos y la columna del jugador es
  `$08`, aborta el turno saltando a `$654C` (un punto medio de
  `PREPARAR_NIVEL`, justo antes de su `CALL BORRAR_BLOQUE_ESTADO`) —
  coherente con `TEXTO_INSTR_15` ("When the boxes holding the Key and
  the Royal Mummy have been uncovered, you will be able to leave the
  level"). Confianza media-alta.
- **`PROCESAR_ENCUENTROS_ENTIDADES`** (`$7578`, la que arma el acarreo
  de "`JP C,PANTALLA_GAME_OVER`"): recorre `ARRAY_ENTIDADES` comparando
  posiciones con tolerancia; según el flag `($816E)` distingue
  "recogida de coleccionable" (refresca puntuación) de "atrapado por
  Momia Guardiana" (resta una vida, y si llegan a 0 devuelve acarreo).
  Confianza alta en estructura, media-alta en el papel de cada rama.
- **`ACTUALIZAR_MARCO_TRAS_MOVIMIENTO`** (`$7637`): valida que la nueva
  posición del jugador caiga en una intersección real de la rejilla
  (`CPIR` contra `TABLA_FILAS_VALIDAS_CASILLAS`/`TABLA_COLUMNAS_VALIDAS_
  CASILLAS`, ver corrección de datos más abajo) y llama a
  `CALCULAR_TRAMO_MARCO_DESDE_CONTENIDO` (`$76EC`) para despachar según
  el contenido del lado de casilla recorrido: `MARCO_CONTENIDO_
  MOMIA_REAL`/`_LLAVE`/`_MOMIA_GUARDIANA`/`_PERGAMINO`/`_TESORO`, o por
  defecto (nivel actual) una de `RELLENAR_MARCO_DIAGONAL_1/3/4/5/6` —
  **`RELLENAR_MARCO_DIAGONAL_2` queda SIN NINGÚN llamador incluso tras
  cerrar el motor entero: hallazgo confirmado, no un pendiente**.
  Confianza alta en la estructura; media-alta en la correspondencia
  exacta de cada flag con Llave/Pergamino/Momia Real/Momia Guardiana
  (apoyada por 3 coincidencias cruzadas con el texto de instrucciones,
  ver comentario en el fuente).
- **`PROCESAR_MOVIMIENTO_JUGADOR`** (`$77D1`): lee 8 códigos de tecla
  de firmware (`TABLA_TECLAS_DIRECCION`, 2 por dirección — hipótesis
  alta: uno de teclado y uno de joystick, coherente con
  `TEXTO_INSTR_20` "either a Joystick, or the Keyboard"), reordena la
  prioridad de direcciones según la orientación actual del jugador, y
  mueve al jugador saltando a mitad de `MOVER_INDICADOR_MENU` — **se
  confirma que esa rutina (nombrada en la Sesión 6 pensando solo en el
  cursor del menú) es la MISMA lógica de "avanzar 8 píxeles" reutilizada
  también durante la partida real**. Confianza alta en estructura.

Juntas, estas rutinas implementan el núcleo del mecanismo de juego
tipo "Amidar" (pintar los lados de las casillas del tablero de 20
casillas al recorrerlas) que faltaba por descubrir en todo el motor.

### Corrección de datos ya declarados: `TABLA_DESCONOCIDA_GAME_OVER` (`$813A`-`$8159`) no son umbrales de puntuación

Localizados sus 3 llamadores reales dentro de `ACTUALIZAR_MARCO_TRAS_
MOVIMIENTO`/`PROCESAR_MOVIMIENTO_JUGADOR`. Se corrige la hipótesis de
sesiones anteriores ("progresiones aritméticas, posibles umbrales de
puntuación"): son en realidad **`TABLA_FILAS_VALIDAS_CASILLAS`** (5
bytes, paso `$28`), **`TABLA_COLUMNAS_VALIDAS_CASILLAS`** (6 bytes,
paso `$0E` — `(5-1)×(6-1) = 20`, coincide exactamente con "twenty
boxes" de `TEXTO_INSTR_08`) y **`TABLA_TECLAS_DIRECCION`** (8 bytes,
códigos de tecla de firmware). El resto de la zona (`$814D`-`$8159`)
ya se correspondía con variables conocidas (`$814D`/`$814F` buffer de
`PROCESAR_MOVIMIENTO_JUGADOR`, `$8151` semilla de `GENERAR_ALEATORIO`).
Ningún byte del binario cambia — solo comentarios y 3 etiquetas nuevas
sobre datos ya declarados.

### Cambios en `mummy1_body.asm`

`INCBIN "data/mummy1_resto_sin_analizar.bin", 1201, 4017` (`$68B2`-`$7862`)
sustituido por 4017 bytes de código fuente real:
`PANTALLA_INSTRUCCIONES`, `IMPRIMIR_PARRAFO_INSTRUCCIONES`,
`LIMPIAR_VENTANA_INSTRUCCIONES`, `RESTAURAR_VENTANA_TEXTO_COMPLETA`,
`ESPERAR_CONTINUAR_INSTRUCCIONES` (313 bytes), 23 bloques
`TEXTO_INSTR_01..23` (2856 bytes de datos), y
`ANIMAR_APARICION_MOMIA_GUARDIANA`, `COMPROBAR_SALIDA_NIVEL`,
`PROCESAR_ENCUENTROS_ENTIDADES`, `ACTUALIZAR_MARCO_TRAS_MOVIMIENTO`,
`CALCULAR_TRAMO_MARCO_DESDE_CONTENIDO`, `MARCO_CONTENIDO_PERGAMINO`,
`MARCO_CONTENIDO_LLAVE`, `MARCO_CONTENIDO_MOMIA_REAL`,
`MARCO_CONTENIDO_MOMIA_GUARDIANA`, `MARCO_CONTENIDO_TESORO`,
`PROCESAR_MOVIMIENTO_JUGADOR` (350 bytes de código). Se añade
`FIRM_TXT_SET_PEN EQU $BB90` a la tabla de firmware. Se actualizan los
comentarios de `BUCLE_PRINCIPAL_JUEGO` y de las cabeceras de sección
que referenciaban el hueco como "sin analizar". El fichero
`src/data/mummy1_resto_sin_analizar.bin` queda sin ningún `INCBIN` que
lo referencie (se deja en el árbol por si resulta útil como referencia
histórica; no se borra en esta sesión). Ningún byte del binario
generado cambia.

### Verificación

`python tools/build_all.py`: **0 diferencias** (motor 13190 bytes,
cargador 2564 bytes) — verificado repetidamente tras cada cambio,
incluida la corrección de un error propio (`JP $654C` se había resuelto
incorrectamente como `JP BORRAR_BLOQUE_ESTADO`, una dirección
distinta — `$654C` es un punto intermedio de `PREPARAR_NIVEL`, no la
propia rutina, que vive en `$7EAB`).

### Documentación actualizada

`README.md`, `README.en.md`, `src/README.md` (el motor queda descrito
como **completamente reconstruido**, sin huecos `INCBIN` pendientes;
tabla de rutinas de la Sesión 14 añadida en `src/README.md`),
`recursos/flujo_programa.html`, `recursos/flujo_detallado.html` (nodos
y aristas nuevos de esta sesión, según la regla de mantenimiento de
`prompts/_base_reconstruccion.md`) y `recursos/mapa_memoria.html`
(elimina el último segmento "sin analizar todavía": todo el motor
`$6000`-`$9385` queda marcado como reconstruido).

### Pendiente para la siguiente sesión

**No queda ningún hueco `INCBIN` de código en el motor.** Lo que queda
es refinar hipótesis ya con estructura confirmada pero confianza media
en el detalle exacto, todo con dirección concreta para no perder
tiempo:

- Confirmar en emulador la correspondencia exacta flag↔objeto
  (`$816E`=Pergamino, `$816F`=Llave, `$8170`=Momia Real — apoyada por
  cruces con el texto pero no observada visualmente).
- La fórmula de escalado B→HL en `CALCULAR_TRAMO_MARCO_DESDE_CONTENIDO`
  (`$76EC`-`$770B`) no se ha resuelto algebraicamente, solo transcrito.
- El mapeo exacto de los 8 bytes de `TABLA_TECLAS_DIRECCION`
  (`$8145`-`$814C`) a teclas/joystick físicos concretos.
- Si `COMPROBAR_SALIDA_NIVEL` incrementa realmente `$815C` (nivel) en
  algún punto del camino hacia `$654C`/`PREPARAR_NIVEL`, o si el avance
  de nivel ocurre por otro mecanismo no visto en este tramo.
- Todo lo pendiente de sesiones anteriores que sigue sin tocar
  (orientación de las 4 direcciones de `'T'`, confirmación general en
  emulador, numeración de teclas del firmware).

## Sesión 15 — 2026-09-10: las 14 losetas de pisadas, extraídas a `src/data/img/tiles/*.spr`

A petición del usuario, se extraen a ficheros individuales las 14
losetas de la familia de pisadas que hasta ahora vivían como `DB`
inline en `mummy1_body.asm` (Sesiones 8/11): `LOSETA_PISADAS_
VERTICAL_1`/`_2`, `LOSETA_MAPA_PISADA_1`..`_8` y `LOSETA_PISADA_
ESCRITURA_VALOR4`/`_5`/`_6`/`_7`. Mismo tratamiento que ya recibieron
`SPRITE_JUGADOR_*`/`SPRITE_MOMIA_*` en la Sesión 8 (continuación 3) —
cierra de hecho un pendiente explícito que había quedado abierto desde
esa sesión ("extraer a fichero también las casillas de
`DIBUJAR_CASILLA_MAPA` en cuanto se decida su formato definitivo").

### Método

Para no arriesgar un error de transcripción, los 14 bloques no se
copiaron a mano desde el `DB` del ASM: se extrajeron programáticamente
de `FISICO/extraido/MUMMY1.BIN` (saltando los 128 bytes de cabecera
AMSDOS) usando las direcciones y longitudes ya confirmadas por el
código (`DIBUJAR_ENTIDAD`/`DIBUJAR_CASILLA_MAPA`, Sesiones 8 y 11), y
el resultado se contrastó byte a byte contra los `DB` que sustituían
antes de tocar el ASM. Los 14 bloques son exactamente contiguos y sin
solapes en el binario: `$8999`-`$8AB8` (288 bytes), aunque en tiempo de
ejecución algunos se leen con geometrías que sí se solapan entre sí
(ver Sesión 11: `LOSETA_PISADA_ESCRITURA_VALOR4`/`_7` comparten sus
últimos 16 bytes con `LOSETA_MAPA_PISADA_4`/`_8` cuando `DIBUJAR_
ENTIDAD` los lee como 2x16) — eso no afecta a la extracción en sí,
cada etiqueta sigue siendo dueña de bytes físicos propios y no
solapados en el fichero fuente.

Ficheros nuevos en `src/data/img/tiles/` (nombre en minúsculas, mismo
patrón que `src/data/img/sprites/`):

```
loseta_pisadas_vertical_1.spr (32B)   loseta_pisadas_vertical_2.spr (32B)
loseta_mapa_pisada_1.spr (16B)        loseta_mapa_pisada_2.spr (16B)
loseta_mapa_pisada_3.spr (16B)        loseta_mapa_pisada_4.spr (16B)
loseta_mapa_pisada_5.spr (16B)        loseta_mapa_pisada_6.spr (16B)
loseta_mapa_pisada_7.spr (16B)        loseta_mapa_pisada_8.spr (16B)
loseta_pisada_escritura_valor4.spr (16B)
loseta_pisada_escritura_valor5.spr (32B)
loseta_pisada_escritura_valor6.spr (32B)
loseta_pisada_escritura_valor7.spr (16B)
```

Cada bloque `DB` correspondiente en `mummy1_body.asm` se sustituyó por
`INCBIN "data/img/tiles/<nombre>.spr"` bajo la misma etiqueta,
conservando exactamente la dirección y el contenido originales.

### Verificación

`python tools/build_all.py` → **0 diferencias** (motor 13190 bytes,
cargador 2564 bytes). `python tools/dsk_build.py` → **0 diferencias**
en el `.dsk` completo reconstruido (194816 bytes). Ningún byte del
binario cambia; solo cambia dónde vive el dato fuente.

### Pendiente

Sin cambios respecto a la Sesión 14 — esta sesión es una extracción de
recursos, no desensamblado nuevo. Sigue pendiente decidir si
`recursos/sprites.html` pasa a leer estos ficheros en vez de mantener
los bytes copiados inline en su JS (por ahora sigue con su copia
propia, ya verificada pixel a pixel contra el usuario en sesiones
anteriores; no se ha tocado para no arriesgar esa verificación ya
hecha).

## Sesión 16 — 2026-09-10: explorador parametrizable para `TABLA_MARCO_1..4` / `DATOS_MARCO_Y_TEXTO_CONTINUAR`

A petición del usuario (revisando `src/mummy1_body.asm` desde
`TABLA_MARCO_1`, línea ~3486): estas 4 tablas de 72 bytes
(`$877D`-`$8895`) y el bloque mixto `DATOS_MARCO_Y_TEXTO_CONTINUAR`
(`$889D`-`$8918`) están confirmadas como el origen de datos de
`DIBUJAR_TRAMO_MARCO_1..4` (Sesión 6: cada una la vuelca
`COPIAR_BLOQUE_A_LIENZO` como 12 filas x 6 bytes), pero **nunca se
había decodificado su contenido a nivel de píxel** — la hipótesis
"marco decorativo" viene de quién las llama, no de haber visto la
imagen resultante. El usuario planteó la hipótesis de que podrían ser
en realidad tablas de sprite.

Se añade un tercer explorador interactivo a `recursos/sprites.html`
(mismo motor `makeExplorer` ya usado por los otros dos, ahora
parametrizado para aceptar un banco de bytes y una dirección base
propios en vez de depender siempre de `TABLAS_SPRITE_CASILLA`), con
control total de modo gráfico, ancho, alto, offset, desplazamiento
vertical, salto, cantidad y paleta — para que el usuario pueda probar
en vivo distintas interpretaciones hasta encontrar (o descartar) una
lectura como sprite. Los 412 bytes del panel (`$877D`-`$8918`) se
extrajeron directamente de `FISICO/extraido/MUMMY1.BIN` (no
transcritos a mano desde el `DB` del ASM) para evitar errores de
transcripción; se contrastaron contra los `DB` ya presentes en
`mummy1_body.asm` antes de darlos por buenos. El valor por defecto del
panel (ancho 6, alto 12) reproduce la única geometría ya confirmada
por el código; los presets saltan a cada tabla individual, a las 4
juntas, al bloque mixto de texto+gráfico, y a un barrido en tiras de
72 bytes — pero ningún ancho/alto salvo el 6x12 está confirmado, todo
lo demás queda como exploración abierta para el usuario.

Este panel no toca ni añade hipótesis de identidad: no se ha decidido
todavía si el contenido es sprite, máscara pura, o ninguna de las dos.

### Verificación

`python tools/build_all.py` → **0 diferencias** (no se tocó ningún
byte del ASM ni del binario, solo `recursos/sprites.html`). Página
comprobada con Microsoft Edge en modo headless (`--dump-dom`): los
tres exploradores renderizan sin errores de JavaScript (86 `<canvas>`
en total: 24+26+4+16+16, coincide con los valores por defecto de cada
panel más las galerías fijas).

### Pendiente

Que el usuario use el nuevo panel para decidir si `TABLA_MARCO_1..4`/
`DATOS_MARCO_Y_TEXTO_CONTINUAR` tienen una lectura visual con sentido
bajo alguna combinación de parámetros distinta de 6x12 — si la
encuentra, habrá que reconciliarla con la geometría 6x12 ya confirmada
por el código (podrían coexistir: el código puede volcar los bytes con
una geometría de pantalla distinta de como se organizó el dato en
origen).

## Sesión 17 — 2026-09-10: `TABLA_MARCO_1..4`/`DIBUJAR_TRAMO_MARCO_1..4` eran los iconos de contenido de casilla, no el marco decorativo del nivel

Usando el panel parametrizable añadido en la Sesión 16, el usuario
identifica visualmente las 4 tablas de 72 bytes (geometría 6x12
confirmada por el código): `TABLA_MARCO_1` = un sarcófago,
`TABLA_MARCO_2` = una llave, `TABLA_MARCO_3` = un pergamino,
`TABLA_MARCO_4` = un tesoro.

### Corroboración independiente por código

Contrastando contra `mummy1_body.asm`, cada una de las 4 rutinas
`DIBUJAR_TRAMO_MARCO_1..4` tiene **un único llamador**, y ese llamador
ya tenía nombre desde la Sesión 14:

| Rutina (antes) | Único llamador | Contenido de casilla (Sesión 14) | Identidad visual (usuario) |
|---|---|---|---|
| `DIBUJAR_TRAMO_MARCO_1` | `MARCO_CONTENIDO_MOMIA_REAL` | Momia Real (+50 puntos) | **Sarcófago** |
| `DIBUJAR_TRAMO_MARCO_2` | `MARCO_CONTENIDO_LLAVE` | Llave | **Llave** |
| `DIBUJAR_TRAMO_MARCO_3` | `MARCO_CONTENIDO_PERGAMINO` | Pergamino | **Pergamino** |
| `DIBUJAR_TRAMO_MARCO_4` | `MARCO_CONTENIDO_TESORO` | Tesoro (+5 puntos) | **Tesoro** |

Las 4 correspondencias encajan exactas y sin ambigüedad (incluida la
temáticamente obvia "Momia Real → sarcófago"): dos fuentes
independientes (inspección visual del usuario e ingeniería inversa del
código) coinciden dígito a dígito. Esto **cierra** la pregunta que el
usuario había hecho días atrás sobre las 20 casillas del tablero: el
contenido de cada casilla al descubrirla se representa con uno de
estos 4 iconos (más la Momia Guardiana, que no dibuja icono — emerge
con su propio sprite, `ANIMAR_APARICION_MOMIA_GUARDIANA`).

### Corrección de la hipótesis de la Sesión 3

Desde la Sesión 3, `DIBUJAR_TRAMO_MARCO_1..4`/`TABLA_MARCO_1..4`
llevaban la hipótesis "dibujan tramos del marco decorativo del
nivel" — nunca verificada a nivel de píxel, solo asumida por el
nombre `MARCO` en el código. Era **incorrecta**: no tiene relación
con el marco/borde decorativo del tablero. Renombradas:

- `TABLA_MARCO_1..4` → `TABLA_ICONO_SARCOFAGO`/`_LLAVE`/`_PERGAMINO`/`_TESORO`.
- `DIBUJAR_TRAMO_MARCO_1..4` → `DIBUJAR_ICONO_SARCOFAGO`/`_LLAVE`/`_PERGAMINO`/`_TESORO`.

`RELLENAR_MARCO_MEDIO`/`_SOLIDO`/`_VACIO`/`_DIAGONAL_1..6` **no** se
renombran: siguen siendo una rutina distinta y genuinamente separada
(rellenan el fondo/backdrop de 24x10 bytes sobre el que se dibuja
después el icono de 12x6, vía `COPIAR_BLOQUE_A_LIENZO`) — su nombre
actual ("marco" como "fondo/backdrop", no como "borde decorativo") no
queda contradicho por este hallazgo, solo se precisa su papel real en
los comentarios.

### Cambios

- `src/mummy1_body.asm`: 8 etiquetas renombradas (4 `TABLA_MARCO_*` +
  4 `DIBUJAR_TRAMO_MARCO_*`), comentarios actualizados junto a cada
  tabla y en la cabecera del bloque de datos, comentario de
  `RELLENAR_MARCO_*` precisado (ya no dice "marco decorativo del
  nivel").
- `recursos/flujo_programa.html`: las 4 filas correspondientes pasan a
  `subsistema: "contenido de casilla (confirmado)"`; las filas de
  `RELLENAR_MARCO_*` pasan a `"fondo de icono de casilla (hipotesis)"`.
- `recursos/flujo_detallado.html`: los 4 nodos pasan a
  `estado: "confirmado"`, `confianza: "alta"`; nota de alcance y pie
  actualizados con la fecha de esta sesión.

### Verificación

`python tools/build_all.py` → **0 diferencias** (solo se renombraron
etiquetas y comentarios, ningún byte del binario cambia). Las 3
páginas HTML tocadas se comprobaron con Microsoft Edge en modo
headless (`--dump-dom`): renderizan sin errores de JavaScript.

### Pendiente

Nada nuevo que desensamblar — esta sesión es una corrección de
identidad sobre código ya reconstruido. Sigue pendiente confirmar en
emulador el patrón exacto de fondo (sólido/vacío/diagonal) que
acompaña a cada icono, y la orientación jugable de las 4 direcciones
de `'T'` (pendiente desde sesiones anteriores, sin relación con este
hallazgo).

## Sesión 18 — 2026-09-10: `TABLA_ICONO_*` → `SPRITE_ICONO_*`, extraídos a `src/data/img/sprites/*.spr`

A petición del usuario: ya que la Sesión 17 confirmó que
`TABLA_ICONO_SARCOFAGO`/`_LLAVE`/`_PERGAMINO`/`_TESORO` son sprites
(los iconos de contenido de casilla), no tablas genéricas, se
renombran con el prefijo `SPRITE_` (coherente con
`SPRITE_JUGADOR_*`/`SPRITE_MOMIA_*`) y se extraen a ficheros
individuales en `src/data/img/sprites/` — mismo tratamiento que
recibieron esos 16 sprites en la Sesión 8 y las 14 losetas de pisadas
en la Sesión 15.

Los 4 bloques de 72 bytes se extrajeron programáticamente de
`FISICO/extraido/MUMMY1.BIN` (no transcritos a mano) y se
contrastaron contra los `DB` que sustituían antes de tocar el ASM:

```
sprite_icono_sarcofago.spr (72B, $877D)   sprite_icono_llave.spr (72B, $87C5)
sprite_icono_pergamino.spr (72B, $880D)   sprite_icono_tesoro.spr (72B, $8855)
```

En `mummy1_body.asm`: `TABLA_ICONO_SARCOFAGO`→`SPRITE_ICONO_SARCOFAGO`
(e igual para `_LLAVE`/`_PERGAMINO`/`_TESORO`), cada bloque `DB`
sustituido por `INCBIN "data/img/sprites/<nombre>.spr"` bajo la misma
etiqueta y dirección. `DIBUJAR_ICONO_*` (renombradas en la Sesión 17)
no cambian de nombre, solo las referencias `LD IY,` a las tablas.
Sincronizados `recursos/flujo_programa.html`, `recursos/
flujo_detallado.html` y el panel dedicado de `recursos/sprites.html`
(título, texto explicativo y presets actualizados para reflejar la
identidad ya confirmada, en vez de presentarlo como exploración
abierta).

### Verificación

`python tools/build_all.py` → **0 diferencias** (motor 13190 bytes,
cargador 2564 bytes). `python tools/dsk_build.py` → **0 diferencias**
en el `.dsk` completo reconstruido. Ningún byte del binario cambia.
Las 3 páginas HTML tocadas se comprobaron con Microsoft Edge en modo
headless (`--dump-dom`): renderizan sin errores de JavaScript.

### Pendiente

Igual que la Sesión 17: confirmar en emulador el patrón de fondo
exacto tras cada icono, y decidir si `DATOS_MARCO_Y_TEXTO_CONTINUAR`
(el bloque mixto texto+gráfico que sigue a `SPRITE_ICONO_TESORO`)
también extrae a fichero en cuanto se entienda su formato.

## Sesión 19 — 2026-09-12: 29 bucles `DJNZ`/`JR` con dirección literal reciben etiqueta, y una corrección importante en `REPETIR_CARACTER`

A petición del usuario: el ASM reconstruido tenía 29 bucles internos
(`DJNZ $XXXX`) que saltaban a una dirección literal en vez de a una
etiqueta con nombre funcional -- estilo mecánico, no el que tendría
un fuente original. Se revisó el contexto de cada uno (qué hace el
cuerpo del bucle, en qué rutina vive) y se le dio nombre. Lista
completa (rutina → etiqueta del bucle):

| Rutina | Etiqueta nueva del bucle |
|---|---|
| (cabecera $6000-$6400) | `BUCLE_CALCULAR_DIRECCIONES_PANTALLA` (200 filas → `TABLA_DIRECCIONES_PANTALLA`) |
| `PANTALLA_OPCIONES` | `BUCLE_ESCALAR_RETARDO_PARTIDA`, `BUCLE_ESCALAR_LIMITE_DIFICULTAD` |
| `PREPARAR_TESOROS_NIVEL` | `BUCLE_COLOCAR_TESOROS_NIVEL` |
| `ACTUALIZAR_HUD_VIDAS` | `BUCLE_DIBUJAR_ICONOS_VIDAS` |
| `SELECCIONAR_DIAGONAL_MARCO_NIVEL` | `BUCLE_DIBUJAR_FONDO_FILA` / `BUCLE_DIBUJAR_FONDO_COLUMNA` (anidados: 4 filas x 5 columnas = 20 casillas -- confirma mecánicamente la rejilla 5x4 del tablero) |
| `PANTALLA_GAME_OVER` | `BUCLE_IMPRIMIR_GAME_OVER` |
| `ACTUALIZAR_TABLA_PUNTUACIONES` | `BUCLE_CALCULAR_RANGO_PUNTUACION`, `BUCLE_DESPLAZAR_TABLA_PUNTUACIONES` |
| `ANIMAR_APARICION_MOMIA_GUARDIANA` | `BUCLE_COPIAR_SPRITE_MOMIA_GUARDIANA` |
| `PROCESAR_MOVIMIENTO_JUGADOR` | `BUCLE_LEER_TECLAS_DIRECCION`, `BUCLE_INTENTAR_MOVER_JUGADOR` |
| `IMPRIMIR_NUMERO_HL` | `BUCLE_CALCULAR_DIGITO_DECIMAL` |
| `INICIALIZAR_ENTIDADES` / `INICIALIZAR_UNA_ENTIDAD` / `COLOCAR_ENTIDAD` | `BUCLE_INICIALIZAR_ENTIDADES`, `BUCLE_AVANZAR_ENTIDAD_NUEVA`, `BUCLE_AVANZAR_ENTIDAD_COLOCAR` |
| `HAY_COLISION` | `BUCLE_COMPROBAR_COLISION_ENTIDADES` |
| `DIBUJAR_ENTIDAD` (bucle común de volcado) | `BUCLE_COPIAR_FILAS_SPRITE` / `BUCLE_COPIAR_FILA_SPRITE` |
| `MEZCLAR_ALEATORIO` | `BUCLE_MEZCLAR_BITS_ALEATORIOS` |
| `RELLENAR_MARCO_DIAGONAL_BUCLE` / `RELLENAR_FILAS_MASCARA` | `BUCLE_ALTERNAR_MASCARA_DIAGONAL`, `BUCLE_ESCRIBIR_MASCARA_FILA` |
| `COPIAR_BLOQUE_A_LIENZO` | `BUCLE_COPIAR_FILAS_BLOQUE` / `BUCLE_COPIAR_BYTES_FILA` |
| `BORRAR_RECTANGULO_VENTANA` | `BUCLE_LOCALIZAR_FILA_VENTANA`, `BUCLE_BORRAR_FILAS_VENTANA` / `BUCLE_BORRAR_FILA_VENTANA` |
| `REPETIR_CARACTER` | `BUCLE_IMPRIMIR_BYTE` (nombre neutro -- ver corrección abajo) |

Antes de nombrar cada uno se comprobó con `grep` que la dirección
destino no tuviera más referencias que su propio `DJNZ` (solo `$607E`
aparecía también en un comentario de rango, sin riesgo). Al colocar la
etiqueta, dos casos exigieron corregir la posición tras un primer
intento fallido -- **el propio `python tools/build_all.py` lo detectó
con precisión de byte** (offsets exactos `0x0094` y `0x188B`, ambos
resueltos comparando el desplazamiento relativo real del `DJNZ` contra
el generado): la etiqueta debe ir exactamente en la instrucción a la
que salta el `DJNZ`, no en la línea "donde parece empezar la lógica
del bucle" -- en `BUCLE_CALCULAR_DIRECCIONES_PANTALLA` el bucle
arranca en `LD DE,$0000` (no en `LD H,D`, una instrucción después), y
en `BUCLE_CALCULAR_DIGITO_DECIMAL` arranca en el primer `INC IY` (no
en `XOR A`, tres instrucciones después) -- el `DJNZ` re-ejecuta
también el incremento de `IY` en cada dígito, no solo la resta.

### Hallazgo importante: `REPETIR_CARACTER` probablemente NO repite un carácter fijo

Al examinar el bucle de `REPETIR_CARACTER` ($7EF4-$7EFC) para ponerle
nombre, la secuencia real de instrucciones es:

```
REPETIR_CARACTER:
    LD B,(HL)      ; B = primer byte (contador)
BUCLE_IMPRIMIR_BYTE:
    INC HL         ; avanza el puntero -- EN CADA vuelta, no solo la primera
    LD A,(HL)      ; lee el byte en la nueva posicion
    CALL FIRM_TXT_OUTPUT
    DJNZ BUCLE_IMPRIMIR_BYTE
```

El `DJNZ` salta a `INC HL`, no a `LD A,(HL)`: **`HL` avanza una
posición en cada iteración**, incluida la primera. Con `B` iteraciones
esto imprime los `B` bytes que siguen al contador (`HL+1`..`HL+B`),
uno detrás de otro -- es decir, un **formato "longitud + bytes",
imprimiendo una secuencia de bytes distintos**, no "repite el mismo
carácter en `HL+1` un total de `B` veces".

Esto **contradice** la hipótesis dada por confirmada desde la Sesión 3
("formato: cuenta+caracter", repetida y reforzada en la Sesión 12:
"REPETIR_CARACTER repite un unico caracter, no recorre una cadena:
confirmado leyendo su propio codigo, $7EF4-$7EFC" -- una lectura que,
revisada ahora byte a byte, no se sostiene: el propio código muestra
justo lo contrario). Es coherente además con cómo se usa en la
práctica: por ejemplo `PANTALLA_OPCIONES` la llama con
`HL=TEXTO_MENU_OPCIONES` ($7EFD, primer byte `$4E`=78) para imprimir
el título "OH MUMMY - OPTIONS" -- tiene mucho más sentido como "imprime
78 bytes seguidos" (mezcla de códigos de control VDU tipo `$0E`/`$1F`
y texto ASCII, todo alimentado byte a byte a `FIRM_TXT_OUTPUT`, que sí
interpreta valores bajos como códigos de control) que como "repite 78
veces el carácter que sigue al título".

**No se ha renombrado `REPETIR_CARACTER` en esta sesión** (son ~20
puntos de llamada y varios comentarios de sesiones anteriores que
asumen la semántica antigua; corregirlo con el mismo rigor que el
resto del proyecto es una tarea aparte, no un efecto secundario de
etiquetar bucles). El bucle interno se nombró con un término neutro
(`BUCLE_IMPRIMIR_BYTE`) que no afirma ninguna de las dos hipótesis.
**Pendiente decidir y ejecutar**: renombrar `REPETIR_CARACTER` (candidato:
`IMPRIMIR_BYTES_CON_LONGITUD` o similar) y revisar/corregir los
comentarios de las sesiones que asumieron "repite un carácter" en cada
uno de sus puntos de llamada.

### Verificación

`python tools/build_all.py` → **0 diferencias** (motor 13190 bytes,
cargador 2564 bytes) tras corregir los 2 desplazamientos mal
colocados. `python tools/dsk_build.py` → **0 diferencias** en el `.dsk`
completo. Ningún byte del binario cambia; solo se añaden etiquetas.

### Pendiente

- Decidir el nombre definitivo de `REPETIR_CARACTER` y propagar la
  corrección a todos sus comentarios de sitio de llamada. **Resuelto
  en la continuación de esta misma sesión, ver abajo.**
- El punto de entrada compartido `$7CC4` (llegada de casi todas las
  ramas de `DIBUJAR_ENTIDAD`) sigue sin etiqueta propia -- no es un
  bucle `DJNZ`, quedó fuera del alcance de esta sesión.
- Todo lo demás pendiente de sesiones anteriores sigue igual.

## Sesión 19 (continuación) — 2026-09-12: `REPETIR_CARACTER` → `IMPRIMIR_BYTES_CON_LONGITUD`, y el mecanismo real de impresión de rótulos en `PANTALLA_OPCIONES` queda resuelto

A petición del usuario, se ejecuta la corrección que quedó pendiente
en la continuación anterior: renombrar `REPETIR_CARACTER` y propagar
la semántica correcta (imprime una secuencia de bytes con longitud, no
repite un carácter fijo) a todos sus puntos de llamada y a la
documentación.

### Cambios

- `src/mummy1_body.asm`: `REPETIR_CARACTER` → `IMPRIMIR_BYTES_CON_LONGITUD`
  en las ~37 ocurrencias (definición + todos los `CALL`). Reescrito el
  comentario de la rutina (junto a `$7EF4`) explicando el mecanismo
  real. Corregidos los 3 bloques de comentarios que afirmaban
  explícitamente la hipótesis antigua: el primer punto de llamada
  histórico ($6066, Sesión 3), el bloque de `PANTALLA_OPCIONES`
  (Sesión 12) y la nota de `TEXTO_COPYRIGHT_Y_HUD`.
- `recursos/flujo_programa.html`, `recursos/flujo_detallado.html`,
  `recursos/mapa_memoria.html`, `src/README.md`: sincronizados con el
  nombre y la semántica nuevos. De paso se corrigió en `src/README.md`
  una referencia a `DIBUJAR_TRAMO_MARCO_1..4` que se había quedado sin
  actualizar desde la Sesión 17.

### Verificación adicional que resuelve un pendiente de la Sesión 12

Al corregir el comentario de `PANTALLA_OPCIONES` se verificó con
aritmética exacta sobre los bytes reales de `TEXTO_MENU_OPCIONES`
(no solo releyendo el bucle) que los 6 `IMPRIMIR_BYTES_CON_LONGITUD`
de esa pantalla **sí imprimen los rótulos reales**:

- `HL=$7EFD` (longitud `$4E`=78) imprime "OH MUMMY - OPTIONS" con sus
  códigos de control, y termina **exacto** en `$7F4C` -- la dirección
  de la siguiente llamada.
- `HL=$7F4C` (longitud `$35`=53) imprime "SPEED OF GAME (1-5) ?" y
  termina **exacto** en `$7F82` -- la siguiente llamada.
- `HL=$7FBD` (byte de longitud `$03`, reutilizado desde dentro de otro
  bloque de datos) imprime literalmente **"YES"**.
- `HL=$7FC1` (longitud `$02`) imprime literalmente **"NO"**.

Esto cierra el pendiente que la Sesión 12 había dejado abierto ("la
impresión real de los rótulos... queda sin localizar"): sí está
localizada, es exactamente este mecanismo.

### Hallazgo colateral: `DATOS_MARCO_Y_TEXTO_CONTINUAR` tampoco es gráfico

La cabecera del motor llama `IMPRIMIR_BYTES_CON_LONGITUD` dos veces
con `HL=$889D` y `HL=$8906` (dentro de `DATOS_MARCO_Y_TEXTO_CONTINUAR`,
$6170 y $61B2). La hipótesis previa ("mezcla de máscara/gráfico sin
separar con precisión, similar a las tablas de icono") queda
descartada: es otro bloque longitud+bytes -- `HL=$889D` (longitud
`$68`=104) termina **exacto** en `$8906`, la siguiente llamada real,
confirmando de nuevo el mecanismo con aritmética exacta. Se corrigió
el comentario de esa etiqueta; no se ha renombrado ni decodificado el
contenido byte a byte todavía (sigue siendo una tarea aparte).

### Verificación

`python tools/build_all.py` → **0 diferencias** (motor 13190 bytes,
cargador 2564 bytes) -- solo cambian nombres y comentarios, ningún
byte del binario. `python tools/dsk_build.py` → **0 diferencias** en
el `.dsk` completo. Las 3 páginas HTML tocadas renderizan sin errores
(comprobado con Microsoft Edge headless).

### Pendiente

- Decodificar byte a byte los códigos de control VDU usados dentro de
  `TEXTO_MENU_OPCIONES`/`DATOS_MARCO_Y_TEXTO_CONTINUAR` (posición de
  cursor, tinta...) -- se sabe que se imprimen, no qué hace cada uno.
- Decidir si `DATOS_MARCO_Y_TEXTO_CONTINUAR` merece un nombre propio
  ahora que se sabe que no es gráfico.
- El punto de entrada compartido `$7CC4` sigue sin etiqueta propia.
- Todo lo demás pendiente de sesiones anteriores sigue igual.

## Sesión 19 (continuación 2) — 2026-09-12: 83 direcciones literales más reciben etiqueta (cabecera + `$6401`-`$786B`)

A petición del usuario ("hay otros saltos y llamadas que apuntan a
direcciones hardcodeadas... es necesario sustituir todas esas
llamadas"), se extiende el trabajo de nombrado de la Sesión 19 (que
solo cubrió los bucles `DJNZ`) a **todas** las instrucciones
`CALL`/`JP`/`JR` que saltan a una dirección `$XXXX` literal. Un
análisis programático (script Python que cruza cada dirección de
salto contra las etiquetas ya definidas) encontró **227** instrucciones
de este tipo en todo el fichero, repartidas en:

- **21 instrucciones** que ya apuntaban a una dirección con etiqueta
  existente (p.ej. `CALL $7DFC` cuando `RELLENAR_MARCO_DIAGONAL_1` ya
  vive ahí) -- sustitución mecánica sin riesgo, hecha con un script.
- **7 direcciones** sin etiquetar dentro de la cabecera `$6000`-`$6400`
  (arranque/menú/nombre) -- nombradas a mano por Claude, leyendo el
  contexto de cada una: `REINICIAR_MODO_ATRACCION` ($6039, destino de
  `JP C` desde `ACTUALIZAR_TABLA_PUNTUACIONES` cuando la puntuación no
  entra en la tabla -- resiembra el aleatorio y vuelve al modo
  atracción sin pedir nombre), `BUCLE_SELECCIONAR_JUGADORES` ($6201),
  `PREPARAR_ENTRADA_NOMBRE` ($6223, punto de convergencia real: 1/2
  jugadores confirmado, "L"/Intro tras STOP PRESS/GAME OVER, y tras
  insertar una puntuación nueva), `ESPERAR_PRIMERA_TECLA_NOMBRE`
  ($6365), `BUCLE_LEER_NOMBRE` ($6372), `BORRAR_CARACTER_NOMBRE`
  ($63C4), `CONFIRMAR_NOMBRE_JUGADOR` ($63F3).
- **55 direcciones** en `$6401`-`$786B` (`PANTALLA_OPCIONES`,
  `INICIAR_PARTIDA`/`PREPARAR_NIVEL`/`PREPARAR_TESOROS_NIVEL`,
  `ACTUALIZAR_HUD_VIDAS`, `SELECCIONAR_DIAGONAL_MARCO_NIVEL`,
  `BUCLE_PRINCIPAL_JUEGO`, `PANTALLA_STOP_PRESS`/`PANTALLA_GAME_OVER`,
  `ACTUALIZAR_TABLA_PUNTUACIONES`, `PROCESAR_ENCUENTROS_ENTIDADES`,
  `ACTUALIZAR_MARCO_TRAS_MOVIMIENTO`, `CALCULAR_TRAMO_MARCO_DESDE_
  CONTENIDO`, `MARCO_CONTENIDO_MOMIA_GUARDIANA`,
  `PROCESAR_MOVIMIENTO_JUGADOR`) -- delegadas a un agente en segundo
  plano con la misma metodología, ver tabla completa de nombres más
  abajo.
- **65 direcciones** en `$786C`-fin del fichero -- ver la entrada de
  Sesión 20 justo después de esta, incluye el hallazgo destacado
  `VOLCAR_SPRITE_A_PANTALLA` ($7CC4).

### Metodología (idéntica en las tres partes)

Para cada dirección sin etiquetar: leer el contexto real (rama
alternativa de una comparación `CP`/`JR`, o punto de convergencia de
varias ramas) antes de nombrar; colocar la etiqueta EXACTAMENTE en la
instrucción de destino (verificable por la dirección hex del
comentario `; XXXX:` de esa misma línea, no "donde parece empezar la
lógica" -- el error más costoso de la primera mitad de la Sesión 19);
verificar `python tools/build_all.py` tras cada grupo pequeño; cuando
varias referencias apuntan a la misma dirección, un único script
mecánico propaga el nombre a todas de golpe.

### Etiquetas nuevas del tramo `$6401`-`$786B`

| Rutina | Etiquetas nuevas |
|---|---|
| `PANTALLA_OPCIONES` | `BUCLE_LEER_VELOCIDAD_PARTIDA`, `BUCLE_LEER_NIVEL_DIFICULTAD`, `BUCLE_LEER_MUSICA_FONDO`, `ACTIVAR_MUSICA_FONDO`, `FIJAR_MUSICA_FONDO_SI`, `ESPERAR_LIBERAR_TECLAS_MUSICA`, `ESPERAR_TECLA_TRAS_MUSICA`, `BUCLE_LEER_EFECTOS_SONIDO`, `FIJAR_EFECTOS_SONIDO_SI`, `MOSTRAR_CONFIRMACION_OPCIONES`, `BUCLE_CONFIRMAR_SALIDA_OPCIONES` |
| `INICIAR_PARTIDA`/`PREPARAR_NIVEL`/`PREPARAR_TESOROS_NIVEL` | `LIMPIAR_ESTADO_NIVEL`, `BUCLE_RETARDO_PREPARAR_NIVEL`, `BUSCAR_CASILLA_TESORO_LIBRE`, `CONTINUAR_BUCLE_TESOROS` |
| `SELECCIONAR_DIAGONAL_MARCO_NIVEL` | `SELECCIONAR_VARIANTE_MARCO_1`, `SELECCIONAR_VARIANTE_MARCO_5`, `SELECCIONAR_VARIANTE_MARCO_4`, `SELECCIONAR_VARIANTE_MARCO_6`, `PARCHEAR_LLAMADA_MARCO_DIAGONAL` |
| `PANTALLA_STOP_PRESS`/`PANTALLA_GAME_OVER` | `DAR_BONUS_PUNTOS_STOP_PRESS`, `COMPROBAR_VIDA_EXTRA_STOP_PRESS`, `MOSTRAR_CONFIRMACION_STOP_PRESS`, `BUCLE_CONFIRMAR_STOP_PRESS`, `BUCLE_RETARDO_LETRA_GAME_OVER`, `BUCLE_RETARDO_FINAL_GAME_OVER` |
| `ACTUALIZAR_TABLA_PUNTUACIONES` | `COMPLETAR_RANGO_PUNTUACION`, `FIJAR_RANGO_PUNTUACION`, `ESCRIBIR_PUNTUACION_EN_TABLA` |
| `PROCESAR_ENCUENTROS_ENTIDADES` | `COMPROBAR_COLUMNA_ENCUENTRO`, `PROCESAR_ENCUENTRO_CONFIRMADO` |
| `ACTUALIZAR_MARCO_TRAS_MOVIMIENTO` | `CALCULAR_LADO_MARCO_ORIENTACION_3/_2/_01`, `SUMAR_LADO_MARCO`, `MARCAR_LADO_MARCO_PAR`, `COMPROBAR_LADO_MARCO_IX`, `COMPROBAR_LADO_MARCO_IY` |
| `CALCULAR_TRAMO_MARCO_DESDE_CONTENIDO` | `BUCLE_DIVIDIR_INDICE_TRAMO_MARCO`, `RESTAURAR_RESTO_TRAMO_MARCO`, `DESPACHAR_DIAGONAL_NIVEL_4/_3/_2/_01` |
| `MARCO_CONTENIDO_MOMIA_GUARDIANA` | `APARICION_MOMIA_DESPLAZAMIENTO_A/_B/_C`, `APLICAR_DESPLAZAMIENTO_APARICION_MOMIA` |
| `PROCESAR_MOVIMIENTO_JUGADOR` | `MARCAR_TECLA_DIRECCION_PULSADA`, `CONTINUAR_BUCLE_TECLAS_DIRECCION`, `REORDENAR_PRIORIDAD_ORIENTACION_3/_2/_01`, `GUARDAR_PRIORIDAD_DIRECCION`, `CONTINUAR_INTENTO_MOVER_JUGADOR` |

De paso se corrigió una referencia larga que apuntaba a este tramo
desde más adelante en el fichero: `COMPROBAR_SALIDA_NIVEL` hacía
`JP $654C` (dirección literal) en vez de `JP LIMPIAR_ESTADO_NIVEL`.

### Verificación

`python tools/build_all.py` → **0 diferencias** en cada tanda,
confirmado también de forma independiente por Claude tras cada agente
(motor 13190 bytes, cargador 2564 bytes). Ningún byte del binario
cambia en las tres partes de esta sesión.

### `recursos/flujo_detallado.html`

No requiere cambios: igual que se razona en la entrada de Sesión 20,
sustituir direcciones literales por nombres de etiqueta no altera el
flujo de llamadas, los estados ni la confianza de ninguna rutina.

## Sesión 20 — 2026-09-12: últimas 65 direcciones literales (`$786C`-fin) reciben etiqueta -- incluye `VOLCAR_SPRITE_A_PANTALLA` ($7CC4, el punto de entrada más citado de todo el fichero)

Continuación directa del trabajo de nombrado de saltos de la Sesión 19
(que cubrió los bucles `DJNZ`) y de una sesión intermedia que cerró
las direcciones de `$6401`-`$786B`. Esta sesión cubre el resto del
fichero: desde `IMPRIMIR_NUMERO_HL` ($786C) hasta el final
(`MEZCLAR_ALEATORIO`, $7D84) -- todas las rutinas de entidades, mapa
y aleatoriedad. Se localizaron 65 direcciones únicas sin etiquetar
(111 referencias `CALL`/`JP`/`JR` en total). Tras esta sesión, un
barrido completo del fichero (no solo del rango) confirma **cero**
instrucciones `CALL`/`JP`/`JR` que salten a una dirección `$XXXX`
literal en todo `src/mummy1_body.asm`.

### El caso destacado: `$7CC4` → `VOLCAR_SPRITE_A_PANTALLA`

Con 26 referencias directas (27 si se cuenta el propio `JP` de
`DIBUJAR_ENTIDAD` a través de su rama por defecto, ya con nombre desde
antes), es la dirección más citada del fichero con diferencia. Es el
bucle común de volcado a pantalla (`PUSH DE` / `LD B,$10` / copia 16
filas de 4 bytes desde `IY` vía `CASILLA_A_DIRECCION_PANTALLA`) al que
caen, con `JP`/`JR` (a veces condicional `Z`), prácticamente todas las
ramas del gran despachador de `DIBUJAR_ENTIDAD` (por tipo `' '`/`T`/
`A`/`O`, dirección y fotograma de animación) y también la única salida
de `DIBUJAR_CASILLA_MAPA`. Nombre elegido: `VOLCAR_SPRITE_A_PANTALLA`
(deja pendiente de la Sesión 19: "el punto de entrada compartido
`$7CC4`... sigue sin etiqueta propia").

### Resto de etiquetas nuevas, agrupadas por rutina

| Rutina | Etiquetas nuevas |
|---|---|
| `IMPRIMIR_NUMERO_HL` | `BUCLE_RESTAR_PESO_DECIMAL`, `RESTAURAR_RESTO_DECIMAL` |
| `ESPERAR_TECLA_2C` | `BUCLE_ESPERAR_TECLA_2C_LIBERADA`, `BUCLE_ESPERAR_CARACTER_TECLADO`, `BUCLE_VACIAR_BUFER_TECLADO` |
| `ANIMAR_OPCION_MENU` | `BUCLE_DECREMENTAR_RETARDO_MENU` |
| `ACTUALIZAR_SECUENCIA_SONIDO` | `REINICIAR_GUION_SONIDO` |
| `MOVER_INDICADOR_MENU` | `COMPROBAR_LIMITE_INFERIOR_INDICADOR`, `GUARDAR_DIRECCION_INDICADOR`, `MOVER_INDICADOR_8PX` (entrada reutilizada, ya citada en un comentario de la Sesión 13), `INDICADOR_AVANZAR_FILA`, `INDICADOR_RETROCEDER_COLUMNA`, `INDICADOR_AVANZAR_COLUMNA`, `GUARDAR_COLUMNA_INDICADOR`, `GUARDAR_FILA_INDICADOR`, `REDIBUJAR_INDICADOR_MENU` |
| `COLOCAR_ENTIDAD` | `GUARDAR_PUNTERO_ENTIDAD_COLOCAR`, `OBTENER_POSICION_ACTUAL_ENTIDAD`, `INCREMENTAR_POSICION_ENTIDAD`, `NORMALIZAR_POSICION_ENTIDAD` |
| `HAY_COLISION` | `COMPROBAR_COLISION_EJE_Y`, `CONTAR_ENTIDAD_EN_COLISION`, `SIGUIENTE_ENTIDAD_COLISION`, `COMPROBAR_ACCESIBILIDAD_CASILLA` (entrada reutilizada, ya citada en un comentario de la Sesión 13) |
| `CALCULAR_CASILLA_ADYACENTE` | `CALCULAR_CASILLA_ADYACENTE_DESDE_HL` (entrada reutilizada, ya citada en un comentario de la Sesión 13), `SUMAR_FILA_ADYACENTE`, `SUMAR_COLUMNA_ADYACENTE`, `RESTAR_FILA_ADYACENTE`, `DEVOLVER_CASILLA_ADYACENTE` |
| `ELEGIR_DIRECCION_HACIA_OBJETIVO` | `DIRECCION_X_NEGATIVA`, `GUARDAR_DIRECCION_EJE_X`, `DIRECCION_Y_NEGATIVA`, `GUARDAR_DIRECCION_EJE_Y`, `GUARDAR_DIRECCION_ELEGIDA` |
| `PREPARAR_DIBUJAR_ENTIDAD` | `DESPLAZAR_FILA_CASILLA_ANTERIOR`, `REDIBUJAR_CASILLA_FILA_ACTUAL`, `REDIBUJAR_CASILLA_FILA_SIGUIENTE`, `GUARDAR_NUEVA_POSICION_ENTIDAD` |
| `DIBUJAR_ENTIDAD` (despachador) | `DIBUJAR_ENTIDAD_CARACTER_ESPACIO`, `DIBUJAR_ENTIDAD_LETRA_T`, `DIBUJAR_LETRA_T_PISADA_VERTICAL`, `DIBUJAR_LETRA_T_PISADA_3`, `DIBUJAR_LETRA_T_PISADA_6` (nombradas por la tabla `IY` que cargan, no por una dirección de movimiento sin confirmar), `DIBUJAR_ENTIDAD_LETRA_A`, `DIBUJAR_LETRA_A_GRUPO_1/2/3`, `DIBUJAR_ENTIDAD_LETRA_O`, `DIBUJAR_LETRA_O_GRUPO_1/2/3`, y `VOLCAR_SPRITE_A_PANTALLA` (ver arriba) |
| `DIBUJAR_CASILLA_MAPA` | `DIBUJAR_CASILLA_PISADA_1`..`_8` (una por cada rama del despachador en cascada `CP`/`JR C`/`JR Z`), `CONFIGURAR_VOLCADO_CASILLA_MAPA` (epílogo común antes de caer en `VOLCAR_SPRITE_A_PANTALLA`) |
| `GENERAR_ALEATORIO` | `BUCLE_REDUCIR_MODULO_ALEATORIO`, `RESTAURAR_RESTO_ALEATORIO` |
| `MEZCLAR_ALEATORIO` | `CONTINUAR_MEZCLAR_BIT_ALEATORIO` |

Además, 4 `CALL $7CE6` sueltos (dentro de una rutina de HUD anterior a
`$786C`, con comentario ya presente "entrada intermedia en
DIBUJAR_CASILLA_MAPA") se sustituyeron mecánicamente por
`CALL DIBUJAR_CASILLA_MAPA`: la etiqueta ya existía en esa dirección,
pero el script de análisis no la detectaba porque hay 5 líneas de
comentario de bloque entre la etiqueta y la primera instrucción real
-- limitación conocida del script, no un hueco real.

Metodología idéntica a la Sesión 19: para cada dirección se leyó el
contexto (rama `CP`/`JR` alternativa, o punto de convergencia de
varias ramas) antes de nombrar, la etiqueta se colocó exactamente en
la instrucción de destino (verificado por la dirección hex del
comentario `; XXXX:`), y se usó el script de sustitución mecánica para
propagar cada nombre a todas sus referencias de golpe. Verificación
con `python tools/build_all.py` tras cada grupo pequeño de etiquetas
(nunca se acumularon más de ~10 sin compilar), sin ningún
desplazamiento mal colocado esta vez.

### Verificación final

`python tools/build_all.py` → **0 diferencias** (motor 13190 bytes,
cargador 2564 bytes) -- solo se añaden etiquetas y se sustituyen
direcciones literales por nombres; ningún byte del binario cambia.
Barrido final por regex confirma 0 instrucciones `CALL`/`JP`/`JR
$XXXX` en todo `src/mummy1_body.asm`.

### Sobre `recursos/flujo_detallado.html`

No requiere cambios: esta sesión no altera el flujo de ejecución, las
llamadas entre rutinas, los puntos de entrada ni el estado/confianza
de ninguna rutina -- solo sustituye direcciones literales por nombres
de etiqueta ya deducibles del propio grafo existente (p. ej. el nodo
que recibía flechas hacia "`$7CC4`" ahora las recibe hacia
"`VOLCAR_SPRITE_A_PANTALLA`", sin cambiar aristas ni confianza).

### Pendiente

- Ninguna dirección literal sin etiquetar queda en todo el fichero
  (objetivo del "nombrado de saltos" iniciado en la Sesión 19,
  completado).
- El resto de pendientes de sesiones anteriores (decodificar códigos
  VDU de `TEXTO_MENU_OPCIONES`, nombrar `DATOS_MARCO_Y_TEXTO_CONTINUAR`,
  confirmar semántica de direcciones 0-4 en `MOVER_INDICADOR_MENU`/
  `CALCULAR_CASILLA_ADYACENTE`/`ELEGIR_DIRECCION_HACIA_OBJETIVO` contra
  el emulador) sigue igual -- los nombres nuevos de esta sesión evitan
  deliberadamente afirmar semánticas de dirección (arriba/abajo/
  izquierda/derecha) no verificadas, describiendo en su lugar la
  operación de código real (columna/fila, tabla `IY` cargada).

## Sesión 21 — 2026-09-12: repaso de `TABLAS_SPRITE_CASILLA` y `DATOS_MARCO_Y_TEXTO_CONTINUAR` en `recursos/sprites.html` -- solo quedan 17 bytes genuinamente sin identificar

El usuario preguntó qué contienen estas dos etiquetas y si parecen
sprites. Repaso de lo ya confirmado en sesiones anteriores (sin
desensamblar nada nuevo):

- **`TABLAS_SPRITE_CASILLA`** ($8919-$8EC9, 1457 bytes) no es "un
  sprite": es la región donde viven, contiguos entre sí, los 2 rellenos
  por defecto de `DIBUJAR_ENTIDAD` (Sesión 8, 64 bytes cada uno, todo
  `$00`/todo `$F0`), las 12 losetas de pisadas (Sesión 8/11/15,
  extraídas a `src/data/img/tiles/`) y los 16 sprites de jugador/momia
  (Sesión 8, extraídos a `src/data/img/sprites/`). De los 1457 bytes,
  **solo quedan 17 sin identificar**: el tramo final, offset 1440
  (`$8EB9`-`$8EC9`), justo entre `SPRITE_MOMIA_G4_F2` y
  `TABLA_DIRECCIONES_PANTALLA`. Nunca referenciado por ningún
  `LD IY`/`HL`/`DE` conocido en el código ya reconstruido.
- **`DATOS_MARCO_Y_TEXTO_CONTINUAR`** ($889D-$8918, 124 bytes) **no es
  gráfico** -- esto ya se había resuelto en la Sesión 19 con
  aritmética exacta de direcciones: son 2 llamadas a
  `IMPRIMIR_BYTES_CON_LONGITUD` (texto + códigos de control VDU,
  terminando en el literal `"C" TO CONTINUE"`), no un mapa de bits.

### Cambios en `recursos/sprites.html`

- El panel dedicado (`g`) se actualiza: título y texto explicativo ya
  no dicen "todavía no tiene composición clara" para todo el rango
  0-415 (obsoleto desde hace varias sesiones) -- ahora explican qué
  está confirmado y señalan que el offset máximo útil es 1456. Nuevo
  botón **"SIN IDENTIFICAR: cola de 17 bytes ($8EB9...)"** que salta
  directo a esos 17 bytes (los datos ya estaban cargados en
  `SPRITE_DATA_HEX` desde la Sesión 8, solo faltaba un acceso directo).
- El panel de `SPRITE_ICONO_*`/`DATOS_MARCO_Y_TEXTO_CONTINUAR` (`h`,
  Sesión 16) actualiza su texto y el botón de
  `DATOS_MARCO_Y_TEXTO_CONTINUAR` para dejar claro que NO es sprite,
  citando la Sesión 19, en vez de presentarlo como pendiente de
  explorar.

### Verificación

No se tocó `src/mummy1_body.asm` (solo HTML), así que
`python tools/build_all.py` no aplica un cambio nuevo pero se
comprobó que sigue en 0 diferencias. Página verificada con Microsoft
Edge en modo headless: renderiza sin errores, 86 `<canvas>` (sin
cambios respecto a antes, el nuevo botón no altera la vista por
defecto).

### Pendiente

- Que el usuario use el nuevo botón para decidir si los 17 bytes de
  `$8EB9` tienen sentido visual como sprite bajo alguna combinación de
  parámetros, o si son basura/relleno sin usar.
- Todo lo demás pendiente de sesiones anteriores sigue igual.

## Sesión 21 (continuación) — 2026-09-12: reescritura de los bloques de texto con códigos de control como los habría escrito el programador original

Tras localizar la tabla oficial completa de códigos de control del
Text VDU (`AMSTRAD CPC464/664/6128 FIRMWARE`, **Appendix VII**,
`cpctech.cpcwiki.de/docs/manual/s968ap07.pdf` — hasta ahora no
localizada en sesiones anteriores, que sólo tenían el jumpblock de la
sección 14.1), el usuario pidió reescribir los bloques de texto mixto
(control+ASCII) tal y como los habría escrito el programador original:
constantes con nombre para los códigos de control (0-31) en vez de
hexadecimal en bruto, y cadenas entre comillas para el texto.

### Constantes `CTRL_TXT_*` añadidas

32 `EQU` nuevas justo después del bloque `FIRM_*` existente (antes de
`ORG $6000`), una por cada código 0-31 de la tabla oficial, con su
número de parámetros documentado en el comentario (los parámetros son
bytes de **datos**, no más códigos, aunque su valor sea <$20 -- error
fácil de cometer al decodificar a mano). Ejemplos:
`CTRL_TXT_FIJAR_PAPEL`=14 (1 param), `CTRL_TXT_FIJAR_TINTA`=15 (1
param), `CTRL_TXT_POSICIONAR_CURSOR`=31 (2 param, columna+fila),
`CTRL_TXT_BORRAR_VENTANA`=12 (0 param).

### Mapeo de puntos de entrada reales (previo a tocar ningún byte)

Antes de reescribir nada se localizaron con `Grep` TODOS los `CALL
IMPRIMIR_BYTES_CON_LONGITUD` reales del fichero y su `LD HL` previo,
para no asumir estructura no verificada. Esto reveló dos correcciones
importantes a hipótesis previas:

- **`TEXTO_TABLA_PUNTUACIONES`/`TEXTO_MENU_PRINCIPAL`** SÍ tienen
  llamadores reales (9 puntos de entrada, `$866D`-`$8710`, dentro de
  `BUCLE_SELECCIONAR_JUGADORES`) -- la nota de sesiones anteriores
  ("sin CALL que los consuma localizado todavía") quedaba obsoleta.
  Los últimos 2 bytes de lo que se documentaba como
  `TABLA_PARAMETROS_TRANSICION_PUNTUACIONES` (`$866D`/`$866C` en
  adelante) resultaron ser en realidad el arranque de esta secuencia
  de impresión, no parte de esa tabla de hipótesis -- se recorta su
  límite y se crea `COLA_TEXTO_PRE_PUNTUACIONES` para la cola real.
- **Límite de `ENVOLVENTE_TONO_3`/inicio de `TEXTO_HISTORIA_ATRACCION`
  corregido 2 bytes antes**: el CALL real de `PANTALLA_STOP_PRESS`
  ($673C) usa `LD HL,$801B`, no `$801D` como sugería la etiqueta
  existente -- los bytes `$24,$0E` que se agrupaban como cola de la
  envolvente de sonido pertenecen en realidad al inicio del bloque de
  texto (longitud=$24=36 + primer código de control=$0E). Sólo cambia
  dónde se traza el límite entre los dos bloques; ningún byte del
  fichero cambia.
- Cada bloque de texto (`TEXTO_MENU_OPCIONES`, `TEXTO_HISTORIA_
  ATRACCION`, `TEXTO_TABLA_PUNTUACIONES`, `TEXTO_MENU_PRINCIPAL`,
  `TEXTO_COPYRIGHT_Y_HUD`, `DATOS_MARCO_Y_TEXTO_CONTINUAR`) resultó ser
  varias tiradas `longitud+datos` INDEPENDIENTES concatenadas, no una
  única tirada continua -- confirmado por los puntos de entrada reales
  encontrados (6, 10, 9, 2 y 2 respectivamente). En `TEXTO_TABLA_
  PUNTUACIONES` los pares de 2 bytes intercalados entre tiradas
  (`$C4,$09`, `$D0,$07`...) son valores de 16 bits leídos por
  `IMPRIMIR_NUMERO_HL` (umbrales de puntuación), ajenos a la secuencia
  de impresión de texto -- se documentan aparte, no como códigos de
  control.
- En `TEXTO_HISTORIA_ATRACCION`, el byte `$29` (ASCII `)`) en `$80FB`
  no se imprime nunca como carácter: es la longitud de la tirada
  siguiente ("Press... Continue"). El texto realmente mostrado en
  pantalla es `"...for next dig."` sin paréntesis de cierre -- se
  verificó leyendo los bytes en crudo del binario (sin paréntesis de
  apertura tampoco en ningún punto de la secuencia), corrigiendo la
  paráfrasis con paréntesis del comentario de sesiones anteriores.

### Herramienta usada

Para evitar transcribir/contar bytes a mano (fuente de errores, ver
más abajo), se escribió un decodificador Python de un solo uso
(`decode_text.py`/`decode_chain.py`/`decode_entries.py`, en el
directorio de scratch de la sesión, no forman parte del repositorio)
que lee los bytes reales de `FISICO/extraido/MUMMY1.BIN` en cada
punto de entrada confirmado, aplica la tabla `CTRL_TXT_*` con su
número de parámetros exacto, y separa automáticamente ASCII imprimible
(entre comillas) de gráficos de bloque $80-$FF (en hexadecimal). Su
salida se verificó primero letra a letra contra los `DB` ya existentes
antes de pegarla en el fuente.

### Errores cometidos y corregidos en el proceso (autocríticos)

- Al reescribir `TEXTO_HISTORIA_ATRACCION` mantuve la etiqueta en su
  posición original (2 bytes tarde, ver arriba) mientras escribía
  contenido nuevo asumiendo que empezaba 2 bytes antes -- esto duplicó
  2 bytes (`$24,$0E`) y desplazó todas las direcciones siguientes.
  Detectado inmediato por `tools/build_all.py` (diferencias en
  cascada, delta constante +2 en offsets muy anteriores al bloque
  editado -- síntoma característico de un bloque con longitud
  incorrecta en vez de un typo de contenido). Diagnosticado comparando
  bytes reales vs generados directamente con Python en la dirección
  exacta, no adivinando.
- Al "corregir" el primer síntoma añadí de vuelta el paréntesis de
  cierre en "for next dig." pensando que faltaba -- error en sentido
  contrario (empeoró el delta de +2 a +3). Revertido tras releer los
  bytes crudos del binario, que demuestran que el paréntesis nunca se
  imprime.
- Al compactar 19 `CTRL_TXT_CURSOR_IZQUIERDA` consecutivos (dos veces,
  en `DATOS_MARCO_Y_TEXTO_CONTINUAR`) en listas separadas por comas,
  cometí un error de conteo manual (15 y 17 en vez de 19) -- corregido
  generando la lista con Python (`','.join([...]*19)`) en vez de
  contar a mano.

### Verificación

- `python tools/build_all.py`: **0 diferencias** tras cada uno de los
  6 bloques reescritos (verificado incremental, uno a uno, no al
  final).
- `python tools/dsk_build.py`: **0 diferencias**, `.dsk` reconstruido
  idéntico byte a byte.

### Pendiente

- Repasar si `recursos/flujo_programa.html`/`flujo_detallado.html`
  necesitan actualización (no debería, es relabeling puro de datos, no
  cambia el grafo de llamadas ni rutinas).
- El resto de bytes de baja confianza sin decodificar en estos bloques
  (gráficos de bloque $80-$FF del "marco", offsets tipo diamante, etc.)
  sigue igual -- fuera del alcance de esta sesión (sólo texto+códigos
  de control).

## Sesión 21 (continuación 3) — 2026-09-12: `recursos/sprites.html` -- hoja completa de `TABLAS_SPRITE_CASILLA` y `TABLA_BASE`/`TABLA_ESPACIO` como etiquetas reales

El usuario preguntó si `TABLAS_SPRITE_CASILLA` son sprites (se le
explicó que es solo la etiqueta que marca el inicio de la región, no
un sprite en sí) y pidió una sección al final de `recursos/sprites.html`
que la renderizase de un tirón. Al revisarla, el usuario notó que los
dos primeros bloques (64 bytes todo `$00`, 64 bytes todo `$F0`) son
simples rellenos y preguntó si el programador original los habría
escrito como una lista de 64 `DB` sueltos.

### Cambio en `src/mummy1_body.asm`

Los dos bloques de relleno de `TABLAS_SPRITE_CASILLA` (antes 8 líneas
de `DB` con 16 bytes idénticos cada una) se reescriben como `DEFS`
con byte de relleno -- la misma convención ya usada en este fichero
para `ARRAY_ENTIDADES`/`ESTADO_PARTIDA`/`VENTANA_TEXTO_HUD`/
`MAPA_CASILLAS`/`RELLENO_TRAS_ESTADO`/`TABLA_DIRECCIONES_PANTALLA`
(todas ellas bloques de un único byte repetido, aunque hasta ahora
solo se había usado para rellenos de `$00`; `DEFS` de SjASMPlus admite
un segundo parámetro para el byte de relleno, `DEFS 64,$F0`). Se les da
además nombre propio, `TABLA_BASE` y `TABLA_ESPACIO`, que ya se usaban
como descripción en los HTML pero no existían como etiqueta real en el
`.asm`:

```
TABLA_BASE:
    DEFS 64, $00 ; 8919 -- relleno de "entidad no reconocida" en DIBUJAR_ENTIDAD
TABLA_ESPACIO:
    DEFS 64, $F0 ; 8959 -- relleno de ' ' en DIBUJAR_ENTIDAD / valor fuera de 1-8 en DIBUJAR_CASILLA_MAPA
```

### Cambios en `recursos/sprites.html`

Nueva sección **"TABLAS_SPRITE_CASILLA completa, de un tirón
($8919-$8EC9)"** al final de la página, antes del `<footer>`: renderiza
los 33 tramos del bloque en orden (2 rellenos + 14 losetas + 16
sprites de jugador/momia + los 17 bytes finales sin identificar),
reutilizando `BLOQUE_MIXTO`/`SPRITES_CONFIRMADOS` ya existentes en el
script. Incluye una nota explicando qué es y qué no es
`TABLAS_SPRITE_CASILLA`.

### Verificación

- `python tools/build_all.py`: **0 diferencias** tras el cambio a
  `DEFS`.
- `recursos/sprites.html` verificada con Microsoft Edge en modo
  headless usando una URL `file://` absoluta (una ruta relativa sin
  esquema hizo que Edge la interpretase como un nombre de host y
  fallase con `DNS_PROBE_POSSIBLE`, sin ejecutar el `<script>` --
  detectado porque el recuento de `<canvas>` generados por JS daba 0).
  Con `file://` y `--virtual-time-budget`, los 33 tiles nuevos
  renderizan con su etiqueta correcta y sin errores de JS.

### Pendiente

- Los 17 bytes finales sin identificar siguen igual -- fuera del
  alcance de esta sesión.

## Sesión 22 — 2026-09-12: `TABLA_OFFSETS_DIAMANTE` y `VARIABLES_DIBUJO_MARCO` -- localizados sus llamadores reales y descompuestos en variables individuales

El usuario notó que estas dos etiquetas no tenían ningún `CALL`/`LD`
conocido que las referenciara ("lo que no tiene sentido") y pidió
analizar los datos para descomponerlos en variables reales y
organizarlos con las etiquetas que de verdad se usan en sus
invocaciones.

### Investigación

Un `Grep` de las direcciones internas de `TABLA_OFFSETS_DIAMANTE`
($8611-$8644) localizó `LD HL,$8637` en `$632E`, dentro de la
secuencia de arranque de partida real (tras `BUCLE_SELECCIONAR_
JUGADORES`). Esa instrucción va seguida de `LD ($8645),HL` y `CALL
INICIALIZAR_ENTIDADES` -- la misma pareja de instrucciones aparece
también en `$61E5` (demo de fondo del menú, con `HL=$860F`) y en
`COLOCAR_JUGADOR_INICIAL` ($66CF, también con `HL=$860F`). Leyendo
`INICIALIZAR_UNA_ENTIDAD` ($7987, `LD DE,($8645)` + índice de entidad
x2 + `ADD HL,DE` + lectura de una palabra de 16 bits) queda demostrado
que `($8645)` es un puntero BASE a una tabla de posiciones, y que
`TABLA_OFFSETS_DIAMANTE` es exactamente esa tabla: 26 palabras de 16
bits que son direcciones de pantalla CPC válidas (byte alto `$B8`/
`$90`/`$A8`), leídas para colocar la posición inicial de cada entidad
(enemigo/coleccionable). El puntero base `$860F` = `TABLA_..-2` expone
las palabras 0-5 (demo y cada nivel real); `$8637` = `TABLA_..+38`
expone las palabras 20-25 (una sola vez, al empezar partida real).

Un `Grep` completo de `$8645`/`$8647`/`$8649`/`$864A` (las 4 variables
de `VARIABLES_DIBUJO_MARCO`) reveló que se usan en **muchos más sitios**
de los que documentaba el comentario existente (que solo mencionaba
`DIBUJAR_ICONO_*`): `$8645` se usa TAMBIÉN como el puntero de
`INICIALIZAR_UNA_ENTIDAD` de arriba; `$8647` se usa en
`VOLCAR_SPRITE_A_PANTALLA`/`RELLENAR_FILAS_MASCARA`/
`COPIAR_BLOQUE_A_LIENZO` (puntero de fila de pantalla, mismo papel
coherente en las 3); `$8649` se usa TAMBIÉN como contador de caracteres
del nombre del jugador en `BUCLE_LEER_NOMBRE` (sin relación con su uso
en `RELLENAR_MARCO_*`); `$864A` se usa solo en la familia
`RELLENAR_MARCO_*` (byte de relleno actual). Es decir: 6 bytes de RAM
escasa, reciclados deliberadamente por varias rutinas sin relación
entre sí (nunca coinciden en tiempo de ejecución) -- patrón habitual en
juegos de 8 bits de la época.

### Cambios en `src/mummy1_body.asm`

- `TABLA_OFFSETS_DIAMANTE` → **`TABLA_POSICIONES_INICIALES_ENTIDADES`**
  (mismos 52 bytes, comentario reescrito con la evidencia).
- Las dos referencias literales `LD HL,$860F`/`LD HL,$8637` pasan a
  `LD HL,TABLA_POSICIONES_INICIALES_ENTIDADES-2` / `+38` (aritmética de
  etiqueta, mismo patrón ya usado en el fichero para
  `TABLA_PARAMETROS_TRANSICION_PUNTUACIONES+8`).
- `VARIABLES_DIBUJO_MARCO` se descompone en 4 etiquetas propias:
  `VARIABLE_TEMPORAL_HL_1` ($8645, dos papeles sin relación --
  documentados ambos), `PUNTERO_FILA_PANTALLA_BLIT` ($8647, un único
  papel coherente en 3 rutinas), `VARIABLE_TEMPORAL_A_1` ($8649, dos
  papeles sin relación) y `MASCARA_RELLENO_ACTUAL` ($864A, un único
  papel). Los nombres "temporal" son deliberados: forzar un nombre
  específico habría sido incorrecto en, como mínimo, uno de sus usos.
- Las 39 instrucciones `LD (dir),reg`/`LD reg,(dir)` que usaban estas 4
  direcciones en crudo se sustituyen por las etiquetas nuevas
  (reemplazo mecánico con un script Python, para evitar errores de
  transcripción manual en un volumen tan alto de sustituciones).

### Verificación

- `python tools/build_all.py`: **0 diferencias**.
- `python tools/dsk_build.py`: **0 diferencias**.
- Barrido final confirmando que no queda ninguna dirección literal
  ($8645/$8647/$8649/$864A/$860F/$8637) fuera de los comentarios
  explicativos.

### Cambios en `recursos/*.html`

`recursos/mapa_memoria.html` y `recursos/flujo_detallado.html`
actualizados: entradas renombradas, estado pasado de "pendiente"/"sin
CALL conocido" a "confirmado", y el `pendiente` genérico de
`flujo_detallado.html` que mencionaba `TABLA_OFFSETS_DIAMANTE` corregido
para reflejar que ya está resuelta. Ambos verificados con Microsoft
Edge en modo headless (URL `file://`), sin errores de JS.

### Pendiente

- `TABLA_PARAMETROS_TRANSICION_PUNTUACIONES` (justo antes de
  `TABLA_POSICIONES_INICIALES_ENTIDADES`) sigue sin llamador conocido.
- El reparto exacto demo/nivel/partida real entre los dos punteros base
  de `TABLA_POSICIONES_INICIALES_ENTIDADES` es confianza media-alta,
  no verificado en emulador.
