# Oh Mummy — proyecto de reconstrucción (Amstrad CPC)

*Ingeniería inversa, análisis y documentación: Rafael Eduardo Martín Candial (raemca@hotmail.com)*

Reconstrucción por ingeniería inversa de la versión de disco (`.dsk`)
de *Oh Mummy* (Amsoft, 1984). Ver `../FINDINGS.md` para el diario de
descubrimientos completo, sesión a sesión.

## Estado

**Nada desensamblado todavía.** Esta sesión solo ha montado el entorno
del proyecto y las herramientas de lectura del `.dsk`. Lo único que se
sabe con certeza a día de hoy es el catálogo AMSDOS del disco (ver
`../FISICO/extraido/extraccion.log` tras ejecutar
`py tools/dsk_extract.py`):

| Fichero AMSDOS | Bloques | Cabecera de 128 bytes |
|---|---|---|
| `MUMMY.BAS` | 3 (3072 bytes) | válida (checksum verificado) |
| `MUMMY1.BIN` | 14 (14336 bytes) | válida (checksum verificado) |

Hipótesis de trabajo, aún sin confirmar: `MUMMY.BAS` es el cargador
(BASIC tokenizado que dibuja la pantalla de título y arranca el
motor), `MUMMY1.BIN` es el motor del juego en código máquina. Los
campos de la cabecera AMSDOS (dirección de carga, dirección de
ejecución, tipo, longitud real) no se han decodificado — el checksum
confirma que la cabecera no está corrupta, pero su significado
campo a campo se verificará contra el propio `MUMMY.BAS` (que hace el
`LOAD`/`CALL` real) en la primera sesión de desensamblado, en vez de
darlo por hecho de memoria. Ver `../FINDINGS.md`.

## Estructura prevista (por analogía con los proyectos hermanos)

Esta carpeta seguirá la misma organización que
[`MSX/proyectos/madmixgame`](../../../MSX/proyectos/madmixgame) y
[`SPECTRUM_MadMixGame`](../../../../SPECTRUM_MadMixGame) a medida que
avance el trabajo:

- `main.asm` — punto de entrada único de compilación (cuando exista).
- `*_body.asm` — un fichero por bloque de código reconstruido, cada
  uno a su dirección real de ejecución.
- `load_disk/` — cargador de disco: el `MUMMY.BAS` detokenizado a
  texto editable, y el análisis del mecanismo real de carga del
  binario (equivalente al `load_cas/` de los proyectos de cinta).
- `data/img/` — gráficos ya identificados y extraídos a fichero
  individual (`sprites/`, `tiles/`, `logo/`, `marco_decorativo/`,
  `texto/`), incluidos en la fuente vía `INCBIN`.
- `data/niveles/` — datos de los niveles del laberinto.
- `data/sound/` — datos de música y efectos.
- `build/` — binarios compilados (gitignored).

## Convenciones

- **Nombres descriptivos en español**, no inglés ni abreviaturas
  crípticas — ver `.github/CONTRIBUTING.md` para el detalle completo y
  la disciplina de verificación byte a byte.
- Cuando una rutina resulte equivalente a una ya resuelta en los
  proyectos hermanos (MSX/Spectrum de *Mad Mix Game*), eso sería pura
  coincidencia de mecánica de juego (Pac-Man-like) y no un mismo
  origen de código — no se comparte nombrado automáticamente entre
  proyectos de juegos distintos. Los nombres se deciden por lo que la
  rutina hace en este binario concreto.
