# Oh Mummy (Amstrad CPC) — Reverse Engineering Project

*[Leer esto en español](README.md)*

*Reverse engineering, analysis and documentation: Rafael Eduardo Martín Candial (raemca@hotmail.com)*

Summary
-------
Sibling project to [`MSX/proyectos/madmixgame`](../../MSX/proyectos/madmixgame)
and [`SPECTRUM_MadMixGame`](../../../SPECTRUM_MadMixGame), applying the
same methodology to a different game: **Oh Mummy** (Amsoft, 1984), one
of the launch titles of the Amsoft catalogue for the **Amstrad CPC
464**. Same goal: byte-by-byte disassembly, reconstruction as
readable and verifiable assembler source, extraction and
documentation of resources (graphics, sound, levels), and custom
tooling to recompile the result and regenerate the original `.dsk`.

Scope
-----
Technical work: disassembly, resource extraction, conversion tooling
and documentation. It does not include or redistribute the original
disk dump (`.dsk`) nor copyrighted material without due
authorization. See `AVISO-LEGAL.md` (Spanish) for the full legal
notice.

Current status
---------------
**Session 8 — only ONE stretch of the engine is left unanalyzed
(`$6401`-`$786B`, 5227 bytes). Everything else is reconstructed**: 38
code routines (1681 bytes) and 35 data tables/text blocks (5257
bytes, including the game's actual text), firmware identified, full
`.dsk` regenerated from scratch. The disk's AMSDOS catalogue
(`FISICO/Oh Mummy (1984)(Amsoft).dsk`, 194816 bytes, standard CPCEMU
format, 40 tracks x 1 side, 9x512 data format, sector IDs `C1`-`C9`)
only has **2 files**:

| File | Allocated blocks | Status |
|---|---|---|
| `MUMMY.BAS` | 3 (3072 bytes) | **detokenized and byte-verified** — `src/load_disk/mummy_bas.bas` |
| `MUMMY1.BIN` | 14 (14336 bytes) | engine, loads at `$6000`; **`$6000`-`$6400` (1025 bytes) disassembled**, **`$786C`-`$7EFC` (1681 bytes) reconstructed as code**, **`$7EFD`-`$9385` (5257 bytes) reconstructed as data**, only `$6401`-`$786B` (5227 bytes) pending |

`MUMMY.BAS` is the loader: it hand-draws (with relative `PLOT`/`DRAW`)
the "AMSOFT" logo (191 strokes, now rendered in
`recursos/portada.html`), the "Oh Mummy" title with a particle effect,
the credit **"PRESENTS 1984 GEM SOFTWARE"** (the studio that developed
the game — see `AVISO-LEGAL.md`) and "LOADING......", then ends with
`MEMORY 15000:LOAD"!mummy1",&6000:CALL &6000` — that's where the
engine's confirmed load **and** execution address comes from (`$6000`),
verified against the BASIC itself rather than the AMSDOS header, which
turned out ambiguous.

The engine's first stretch (`$6000`-`$6400`) is disassembled and
byte-verified. The **12 firmware routines** it calls are identified
against the official CPC manual (named `EQU`s in
`src/mummy1_body.asm`: sound, text, screen management...).

Beyond that stretch, following the real call thread (not linearly),
**38 internal subroutines (1681 bytes, 12.7% of the engine) now have
real functional names and are reconstructed as compiled source code**,
forming one contiguous block `$786C`-`$7EFC` (merged in Session 7 by
closing the 142-byte gap between the Session 3 and Session 6 blocks).
Includes `GENERAR_ALEATORIO`/`MEZCLAR_ALEATORIO` (pseudo-random
generator seeded from the system clock), `ACTUALIZAR_SECUENCIA_SONIDO`
(steps through a **circular** sound-script table and queues sound via
firmware), `HAY_COLISION` (collision against other entities and
against the map), `ELEGIR_DIRECCION_HACIA_OBJETIVO` and
`CALCULAR_CASILLA_ADYACENTE` (grid-based movement),
`COLOCAR_ENTIDAD`/`INICIALIZAR_ENTIDADES`/`INICIALIZAR_UNA_ENTIDAD`
(possibly placing 6 enemies or collectibles), **`DIBUJAR_ENTIDAD`**
(429 bytes, a dispatcher picking one of ~20 4x16-byte sprite tables by
entity type, direction, and an animation frame) and `DIBUJAR_CASILLA_MAPA`
(the same for 9 2x8-byte tile tables), and — Session 7 —
`RELLENAR_MARCO_MEDIO`/`_SOLIDO`/`_VACIO` and
`RELLENAR_MARCO_DIAGONAL_1..6` (fill a 24x10-byte decorative-frame
tile with a constant mask, or with two masks alternated row by row via
self-modifying code; corrects an earlier hypothesis that called these
"AND/OR mask variants" — there is no actual AND/OR instruction in the
block). **All names are provisional** (each with its hypothesis and
confidence level in the code itself, see `FINDINGS.md`) — none
verified yet by running the game in an emulator.

Beyond the code, **Session 8** closed off the rest of the engine
(`$7EFD`-`$9385`, 5257 bytes) entirely, confirming it is **data, not
code** — no already-reconstructed `CALL`/`JP` lands inside it. That's
where the game's **actual text** lives: the options screen (speed,
difficulty, music and sound effects), the attract-mode "STOP PRESS"
newspaper screen (the Egyptian pyramid excavation), the HI-SCORE table
with its 5 ranks ("Stupendous", "Excellent"...) and score thresholds,
the main menu, and the real copyright string **`"OH MUMMY" (c) 1984
GEM SOFTWARE`** (confirms `AVISO-LEGAL.md`). Also the 6 sound
envelopes, the 4 decorative-frame tables (72 bytes each, boundaries
confirmed by the code that uses them), and the circular sound script
(90 9-byte records, running right up to the engine's last byte). Only
**one** stretch of the engine is still unanalyzed (`$6401`-`$786B`,
5227 bytes), included as-is via `INCBIN` — see `FINDINGS.md` for the
full call map, the per-routine/data confidence table, and the
methodology used.

Building
--------
```
py tools/build_all.py
py tools/dsk_build.py
```
(or, in VSCode, `Ctrl+Shift+B` — default task "Compilar todo + generar
dsk", see `.vscode/tasks.json`).

The first script assembles `src/main.asm` with SjASMPlus (engine into
`src/build/mummy1.bin`) and tokenizes `src/load_disk/mummy_bas.bas`
(into `src/build/mummy.bas`), verifying each byte-for-byte against
what was extracted from the original `.dsk`. The second **rebuilds
the full `.dsk` from scratch** (disk header, all 40 track headers,
AMSDOS catalogue, data area) — it doesn't copy the original except for
the ~1600 bytes that turned out to be non-reconstructible leftover
content (padding after each file's real content within its allocated
blocks, and the unidentified fields of the AMSDOS headers, see
`FINDINGS.md`) — then compares the result byte-for-byte against
`FISICO/Oh Mummy (1984)(Amsoft).dsk`: **as of today, 0 differences**.
The result lands in `build/ohmummy_reconstruido.dsk` (not
version-controlled, see `.gitignore`).

Read-only disk tools, separately:

```
py tools/dsk_catalog.py
py tools/dsk_extract.py
```

Repository structure
---------------------
- `FISICO/` — the original `.dsk` and the files extracted from it
  (`extraido/`, AMSDOS catalogue, extraction log; later also the raw
  disassembly). Not version-controlled (see `.gitignore` and
  `AVISO-LEGAL.md`).
- `src/` — reconstructed assembler source: `main.asm` (single build
  entry point), `mummy1_body.asm` (engine, `$6000` onward) — see
  `src/README.md`/`FINDINGS.md`.
- `src/build/` — compiled binaries (`py tools/build_all.py`, not
  version-controlled).
- `src/data/` — resources already identified and extracted to
  individual files, included in the source via `INCBIN`:
  `img/sprites/` (Session 8: the 16 `DIBUJAR_ENTIDAD` sprites —
  `sprite_jugador_*`/`sprite_momia_*`, 64 bytes each), `img/tiles/`,
  `img/logo/`, `img/marco_decorativo/`, `img/texto/`, `niveles/`,
  `sound/` (these still empty for now) and
  `mummy1_resto_sin_analizar.bin` (the 5227 still-undisassembled
  engine bytes, `$6401`-`$786B`) — promoted to real source as analysis
  progresses.
- `src/load_disk/` — disk loader (Amstrad equivalent of the sibling
  tape projects' `load_cas/`): `mummy_bas.bas`, the loader's BASIC
  detokenized into editable text.
- `build/` — final deliverable, `ohmummy_reconstruido.dsk`
  (`py tools/dsk_build.py`, not version-controlled).
- `tools/` — custom Python tooling: `dsk_common.py` (reading CPCEMU
  `.dsk` images and the AMSDOS catalogue), `dsk_catalog.py` (list
  catalogue), `dsk_extract.py` (extract raw files),
  `amsdos_basic_tool.py` (detokenize/tokenize Locomotive BASIC),
  `z80_disasm.py` (mechanical Z80 disassembler), `build_all.py`
  (build and verify each file separately), `dsk_build.py` (rebuild
  the full `.dsk` from scratch and verify it byte-for-byte against
  the original).
- `manuales/` — technical reference manuals, one per subsystem,
  written as each piece is closed out (no content yet).
- `recursos/` — self-contained HTML pages (viewers/inventories):
  `mapa_memoria.html` (confirmed regions + hypothesis sub-regions),
  `flujo_programa.html` (routine inventory, firmware + hypotheses),
  `flujo_detallado.html` (Session 9: the real call graph -- `CALL`/
  `JP`/`JR` relations between routines, confirmed/hypothesis/pending
  status per node and per edge, zoom, per-subsystem filters and
  search -- the living artifact of the call flow, updated session by
  session), `flujo_secuencial.html` (boot execution order) and
  `portada.html`
  (the "AMSOFT" logo now rendered from the BASIC's 191 real strokes)
  have real content since Session 3. `sprites.html` (Session 8:
  interactive explorer for `TABLAS_SPRITE_CASILLA` with adjustable
  width/height/CPC mode — the real format is not confirmed yet).
  `graficos.html` (tiles) is still empty — no tile graphics have been
  extracted yet. Also `ohmummy_referencia_binario.html`: a supporting
  document (provided
  by the author, not derived from the binary) with a generic
  hypothesis of what subsystems to expect in a 1984 CPC maze arcade
  game — orients the search, doesn't replace verification against the
  real bytes.
- `dump/` — memory/screen dumps from a real emulator, used as
  evidence when verifying findings (yet to be created).

Dependencies and environment
------------------------------
- [SjASMPlus](https://github.com/z00m128/sjasmplus) — the Z80
  assembler that will be used to recompile the reconstructed source,
  same choice as the sibling MSX and ZX Spectrum projects.
- Python 3 (`py` on Windows) — for the tools in `tools/`. No external
  dependencies, standard library only.
- An Amstrad CPC emulator (e.g. [CPCemu](http://www.cpc-emu.org/) or
  [RetroVirtualMachine](https://www.retrovirtualmachine.org/)),
  optional but recommended, to test the result and cross-check
  findings.
- A legally obtained copy of the original game (`.dsk`) if you want to
  verify the byte-for-byte comparison yourself — this repository does
  **not** include the original dump, see `AVISO-LEGAL.md`.

See also
--------
`AVISO-LEGAL.md` (Spanish) for ownership details, and `FINDINGS.md`
for the discovery log with the full technical detail of each session.
