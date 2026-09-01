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
**Sesión 2 — compilación operativa, desensamblado empezado.** El
catálogo AMSDOS del disco (`FISICO/Oh Mummy (1984)(Amsoft).dsk`,
194816 bytes, formato CPCEMU estándar, 40 pistas x 1 cara, formato de
datos 9x512, IDs de sector `C1`-`C9`) solo tiene **2 ficheros**:

| Fichero | Bloques asignados | Estado |
|---|---|---|
| `MUMMY.BAS` | 3 (3072 bytes) | **detokenizado y verificado byte a byte** — `src/load_disk/mummy_bas.bas` |
| `MUMMY1.BIN` | 14 (14336 bytes) | motor, carga en `$6000`; **`$6000`-`$6400` (1025 bytes) desensamblado y verificado**, resto (12165 bytes) pendiente |

`MUMMY.BAS` es el cargador: dibuja a mano (con `PLOT`/`DRAW`
relativos) el logo "AMSOFT", el título "Oh Mummy" con un efecto de
partículas, el crédito **"PRESENTS 1984 GEM SOFTWARE"** (el estudio
que desarrolló el juego — ver `AVISO-LEGAL.md`) y "LOADING......",
y termina con `MEMORY 15000:LOAD"!mummy1",&6000:CALL &6000` — de ahí
salen, confirmadas contra el propio BASIC (no contra la cabecera
AMSDOS, que resultó ambigua), la dirección de carga **y** de ejecución
del motor: `$6000`. El primer tramo del motor ($6000-$6400) ya está
desensamblado a mano — llama repetidamente a rutinas fijas de la ROM
de firmware del CPC (`$BBxx`/`$BCxx`/`$BDxx`) y a subrutinas internas
propias sin identificar todavía; el resto (`$6401`-`$9385`) se incluye
tal cual con `INCBIN` mientras se va analizando sesión a sesión — ver
`FINDINGS.md` para el detalle completo y la metodología de
desensamblado mecánico usada.

Compilar
--------
```
py tools/build_all.py
```

Ensambla `src/main.asm` con SjASMPlus (motor en `src/build/mummy1.bin`)
y tokeniza `src/load_disk/mummy_bas.bas` (en `src/build/mummy.bas`), y
**verifica automáticamente los dos resultados byte a byte** contra lo
extraído del `.dsk` original — hoy mismo: **0 diferencias** en ambos.
Herramientas de solo lectura del disco, por separado:

```
py tools/dsk_catalog.py
py tools/dsk_extract.py
```

Pendiente: empaquetar el resultado de vuelta en un `.dsk` completo
(equivalente a `gen_tzx_file.py` de los proyectos hermanos) — de
momento la verificación es fichero a fichero, no disco completo.

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
  individual, incluidos en la fuente vía `INCBIN`: `img/sprites/`,
  `img/tiles/`, `img/logo/`, `img/marco_decorativo/`, `img/texto/`,
  `niveles/`, `sound/` (todos vacíos por ahora) y
  `mummy1_resto_sin_analizar.bin` (los 12165 bytes del motor todavía
  sin desensamblar, `$6401`-`$9385`) — se irán promoviendo a fuente
  real a medida que avance el análisis.
- `src/load_disk/` — cargador de disco (equivalente Amstrad al
  `load_cas/` de los proyectos hermanos de cinta): `mummy_bas.bas`, el
  BASIC del cargador detokenizado a texto editable.
- `build/` — entregable final (`.dsk` reconstruido), cuando exista.
- `tools/` — herramientas Python propias: `dsk_common.py` (lectura de
  imágenes `.dsk` CPCEMU y del catálogo AMSDOS), `dsk_catalog.py`
  (listar catálogo), `dsk_extract.py` (extraer ficheros crudos),
  `amsdos_basic_tool.py` (detokenizar/tokenizar Locomotive BASIC),
  `z80_disasm.py` (desensamblador Z80 mecánico), `build_all.py`
  (compilar todo y verificar byte a byte).
- `manuales/` — manuales técnicos de referencia, uno por subsistema,
  redactados al cerrar cada pieza (aún sin contenido).
- `recursos/` — páginas HTML autocontenidas (visores/inventarios):
  `mapa_memoria.html`, `graficos.html` (losetas), `sprites.html`,
  `portada.html` (pantalla de carga), `flujo_programa.html`
  (inventario de rutinas) y `flujo_secuencial.html` (orden de
  ejecución) — plantillas que se van rellenando sesión a sesión.
  También `ohmummy_referencia_binario.html`: documento de apoyo
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
