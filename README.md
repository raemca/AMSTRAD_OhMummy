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
**Sesión 1 — solo entorno.** Por ahora este repositorio contiene
únicamente el esqueleto del proyecto y las primeras herramientas de
lectura del `.dsk` (catálogo AMSDOS). Ni una sola rutina se ha
desensamblado todavía. Ver `FINDINGS.md` para el diario de
descubrimientos, que arranca documentando el propio disco.

Lo que sí sabemos del disco (`FISICO/Oh Mummy (1984)(Amsoft).dsk`,
194816 bytes, formato CPCEMU estándar, 40 pistas x 1 cara, formato de
datos 9x512, IDs de sector `C1`-`C9`) es su catálogo AMSDOS completo —
solo **2 ficheros**:

| Fichero | Bloques asignados | Cabecera AMSDOS |
|---|---|---|
| `MUMMY.BAS` | 3 (3072 bytes) | válida (checksum verificado) |
| `MUMMY1.BIN` | 14 (14336 bytes) | válida (checksum verificado) |

`MUMMY.BAS` es casi con toda seguridad el cargador (dibuja la
pantalla de título en BASIC y carga/lanza el motor real);
`MUMMY1.BIN` es previsiblemente el motor del juego en código máquina.
Los campos internos de la cabecera AMSDOS de 128 bytes (dirección de
carga, dirección de ejecución, tipo, longitud real) **aún no se han
decodificado** — el checksum confirma que la cabecera es válida, pero
su significado campo a campo se dejará para la primera sesión de
desensamblado, verificándolo contra el propio `MUMMY.BAS` en vez de
fiarse de una tabla de memoria (ver `FINDINGS.md`).

Compilar
--------
Todavía no hay nada que compilar — no existe fuente ensamblador aún.
Lo único ejecutable hoy son las herramientas de lectura del disco:

```
py tools/dsk_catalog.py
py tools/dsk_extract.py
```

El primer script lista el catálogo AMSDOS del `.dsk` de `FISICO/`. El
segundo extrae cada fichero tal cual a `FISICO/extraido/` (incluida su
cabecera cruda) y deja un log de la extracción.

Cuando exista fuente ensamblador, este apartado se actualizará con el
equivalente a `py tools/build_all.py` + generación del `.dsk`
reconstruido, verificado automáticamente byte a byte contra el
original (misma disciplina que los proyectos hermanos).

Estructura del repositorio
--------------------------
- `FISICO/` — el `.dsk` original y los ficheros extraídos de él
  (`extraido/`, catálogo AMSDOS, log de extracción; más adelante
  también el disassembly crudo). No se versiona (ver `.gitignore` y
  `AVISO-LEGAL.md`).
- `src/` — fuente ensamblador reconstruido (aún vacío) — ver
  `src/README.md`/`FINDINGS.md`.
- `src/build/` — binarios compilados (cuando exista `tools/build_all.py`).
- `src/data/` — recursos ya identificados y extraídos a fichero
  individual, incluidos en la fuente vía `INCBIN`: `img/sprites/`,
  `img/tiles/`, `img/logo/`, `img/marco_decorativo/`, `img/texto/`,
  `niveles/`, `sound/` — todos vacíos por ahora, se irán llenando a
  medida que avance el desensamblado.
- `src/load_disk/` — cargador de disco (equivalente Amstrad al
  `load_cas/` de los proyectos hermanos de cinta) — aún vacío.
- `build/` — entregable final (`.dsk` reconstruido), cuando exista.
- `tools/` — herramientas Python propias: `dsk_common.py` (lectura de
  imágenes `.dsk` CPCEMU y del catálogo AMSDOS), `dsk_catalog.py`
  (listar catálogo), `dsk_extract.py` (extraer ficheros crudos).
- `manuales/` — manuales técnicos de referencia, uno por subsistema,
  redactados al cerrar cada pieza (aún sin contenido).
- `recursos/` — páginas HTML autocontenidas (visores/inventarios):
  `mapa_memoria.html`, `graficos.html` (losetas), `sprites.html`,
  `portada.html` (pantalla de carga), `flujo_programa.html`
  (inventario de rutinas) y `flujo_secuencial.html` (orden de
  ejecución). Por ahora son plantillas sin datos — cada una lo dice
  explícitamente y se va rellenando sesión a sesión.
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
