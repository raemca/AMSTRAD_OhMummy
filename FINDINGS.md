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
