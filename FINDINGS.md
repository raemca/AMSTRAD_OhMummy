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
