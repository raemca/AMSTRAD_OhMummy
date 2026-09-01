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
**Session 1 — environment only.** For now this repository only
contains the project skeleton and the first tools to read the `.dsk`
(AMSDOS catalogue). Not a single routine has been disassembled yet.
See `FINDINGS.md` for the discovery log, which starts by documenting
the disk itself.

What we do know about the disk
(`FISICO/Oh Mummy (1984)(Amsoft).dsk`, 194816 bytes, standard CPCEMU
format, 40 tracks x 1 side, 9x512 data format, sector IDs `C1`-`C9`)
is its complete AMSDOS catalogue — only **2 files**:

| File | Allocated blocks | AMSDOS header |
|---|---|---|
| `MUMMY.BAS` | 3 (3072 bytes) | valid (checksum verified) |
| `MUMMY1.BIN` | 14 (14336 bytes) | valid (checksum verified) |

`MUMMY.BAS` is almost certainly the loader (draws the title screen in
BASIC and loads/launches the real engine); `MUMMY1.BIN` is expected to
be the game engine in machine code. The internal fields of the
128-byte AMSDOS header (load address, execution address, type, real
length) **have not been decoded yet** — the checksum confirms the
header is valid, but decoding each field's meaning is left for the
first disassembly session, cross-checked against `MUMMY.BAS` itself
rather than trusting a memory-recalled table (see `FINDINGS.md`).

Building
--------
There is nothing to build yet — no assembler source exists. The only
things runnable today are the disk-reading tools:

```
py tools/dsk_catalog.py
py tools/dsk_extract.py
```

The first script lists the AMSDOS catalogue of the `.dsk` in
`FISICO/`. The second extracts every file as-is to
`FISICO/extraido/` (including its raw header) and leaves an
extraction log.

Once assembler source exists, this section will be updated with the
equivalent of `py tools/build_all.py` plus regeneration of the
reconstructed `.dsk`, automatically verified byte-for-byte against the
original (same discipline as the sibling projects).

Repository structure
---------------------
- `FISICO/` — the original `.dsk` and the files extracted from it
  (`extraido/`, AMSDOS catalogue, extraction log; later also the raw
  disassembly). Not version-controlled (see `.gitignore` and
  `AVISO-LEGAL.md`).
- `src/` — reconstructed assembler source (still empty) — see
  `src/README.md`/`FINDINGS.md`.
- `src/build/` — compiled binaries (once `tools/build_all.py` exists).
- `src/data/` — resources already identified and extracted to
  individual files, included in the source via `INCBIN`:
  `img/sprites/`, `img/tiles/`, `img/logo/`, `img/marco_decorativo/`,
  `img/texto/`, `niveles/`, `sound/` — all empty for now, to be filled
  in as disassembly progresses.
- `src/load_disk/` — disk loader (Amstrad equivalent of the sibling
  tape projects' `load_cas/`) — still empty.
- `build/` — final deliverable (reconstructed `.dsk`), once it exists.
- `tools/` — custom Python tooling: `dsk_common.py` (reading CPCEMU
  `.dsk` images and the AMSDOS catalogue), `dsk_catalog.py` (list
  catalogue), `dsk_extract.py` (extract raw files).
- `manuales/` — technical reference manuals, one per subsystem,
  written as each piece is closed out (no content yet).
- `recursos/` — self-contained HTML pages (viewers/inventories):
  `mapa_memoria.html`, `graficos.html` (tiles), `sprites.html`,
  `portada.html` (loading screen), `flujo_programa.html` (routine
  inventory) and `flujo_secuencial.html` (execution order). For now
  they are data-free templates — each one says so explicitly — filled
  in progressively session by session.
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
