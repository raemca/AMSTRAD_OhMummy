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
