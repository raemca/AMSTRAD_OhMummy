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
**Session 3 — firmware identified, first semantic hypotheses for the
engine.** The disk's AMSDOS catalogue (`FISICO/Oh Mummy
(1984)(Amsoft).dsk`, 194816 bytes, standard CPCEMU format, 40 tracks x
1 side, 9x512 data format, sector IDs `C1`-`C9`) only has **2 files**:

| File | Allocated blocks | Status |
|---|---|---|
| `MUMMY.BAS` | 3 (3072 bytes) | **detokenized and byte-verified** — `src/load_disk/mummy_bas.bas` |
| `MUMMY1.BIN` | 14 (14336 bytes) | engine, loads at `$6000`; **`$6000`-`$6400` (1025 bytes) disassembled and verified**, rest (12165 bytes) pending |

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
`src/mummy1_body.asm`: sound, text, screen management...). The
**~19 internal subroutines** it calls (outside the compiled stretch,
in the `INCBIN` zone) are disassembled down to their `RET` and each
has a first function hypothesis with a confidence level — sound
initialization, clearing state blocks, a 200-entry screen row address
table, clearing HUD rectangles, drawing the decorative frame (6 mask
variants), a possible score-printing routine (4 decimal digits), and a
1/2-player selection menu — none verified in an emulator yet. The rest
(`$6401`-`$9385`) is still included as-is via `INCBIN` while it gets
analyzed session by session — see `FINDINGS.md` for the full call map,
the per-routine confidence table, and the methodology used.

Building
--------
```
py tools/build_all.py
```

Assembles `src/main.asm` with SjASMPlus (engine into
`src/build/mummy1.bin`) and tokenizes `src/load_disk/mummy_bas.bas`
(into `src/build/mummy.bas`), and **automatically verifies both
results byte-for-byte** against what was extracted from the original
`.dsk` — as of today: **0 differences** in both. Read-only disk tools,
separately:

```
py tools/dsk_catalog.py
py tools/dsk_extract.py
```

Pending: packaging the result back into a full `.dsk` (equivalent to
the sibling projects' `gen_tzx_file.py`) — for now verification is
per-file, not whole-disk.

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
  `img/sprites/`, `img/tiles/`, `img/logo/`, `img/marco_decorativo/`,
  `img/texto/`, `niveles/`, `sound/` (all empty for now) and
  `mummy1_resto_sin_analizar.bin` (the 12165 still-undisassembled
  engine bytes, `$6401`-`$9385`) — promoted to real source as analysis
  progresses.
- `src/load_disk/` — disk loader (Amstrad equivalent of the sibling
  tape projects' `load_cas/`): `mummy_bas.bas`, the loader's BASIC
  detokenized into editable text.
- `build/` — final deliverable (reconstructed `.dsk`), once it exists.
- `tools/` — custom Python tooling: `dsk_common.py` (reading CPCEMU
  `.dsk` images and the AMSDOS catalogue), `dsk_catalog.py` (list
  catalogue), `dsk_extract.py` (extract raw files),
  `amsdos_basic_tool.py` (detokenize/tokenize Locomotive BASIC),
  `z80_disasm.py` (mechanical Z80 disassembler), `build_all.py`
  (build everything and verify byte-for-byte).
- `manuales/` — technical reference manuals, one per subsystem,
  written as each piece is closed out (no content yet).
- `recursos/` — self-contained HTML pages (viewers/inventories):
  `mapa_memoria.html` (confirmed regions + hypothesis sub-regions),
  `flujo_programa.html` (routine inventory, firmware + hypotheses),
  `flujo_secuencial.html` (boot execution order) and `portada.html`
  (the "AMSOFT" logo now rendered from the BASIC's 191 real strokes)
  have real content since Session 3. `graficos.html` (tiles) and
  `sprites.html` are still empty — no tile/sprite graphics have been
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
