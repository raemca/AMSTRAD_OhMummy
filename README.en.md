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
**The engine has been COMPLETELY reconstructed since Session 14, with
no remaining unanalyzed `INCBIN` code stretch**, and Sessions 15-25
took the work beyond the code itself: **zero "magic" literal addresses
left anywhere in the engine** (all 227 `CALL`/`JP`/`JR` instructions
with a literal target are individually labeled, Sessions 19-20), the
identity of the 4 box-content icons is **corrected** (sarcophagus,
key, scroll and treasure — through Session 16 these were believed to
be part of the level's "decorative frame", Session 17), and **every
already-identified graphics and sound resource now lives in its own
individual file**, programmatically extracted from the binary and
byte-verified (footprint tiles and icon sprites, Sessions 15/18;
background music and the 3 one-shot sound effects, with custom
decode/playback tooling, Sessions 23-25). Firmware identified, full
`.dsk` regenerated from scratch. The disk's
AMSDOS catalogue (`FISICO/Oh Mummy (1984)(Amsoft).dsk`, 194816 bytes,
standard CPCEMU format, 40 tracks x 1 side, 9x512 data format, sector
IDs `C1`-`C9`) only has **2 files**:

| File | Allocated blocks | Status |
|---|---|---|
| `MUMMY.BAS` | 3 (3072 bytes) | **detokenized and byte-verified** — `src/load_disk/mummy_bas.bas` |
| `MUMMY1.BIN` | 14 (14336 bytes) | engine, loads at `$6000`; **`$6000`-`$6400` (1025 bytes) disassembled**, **`$6401`-`$6528` (296 bytes) reconstructed as code (Session 12)**, **`$6529`-`$68B1` (905 bytes) reconstructed as code (Session 13)**, **`$68B2`-`$7862` (4017 bytes, instructions screen + game-loop core) reconstructed as code/data (Session 14)**, **`$7863`-`$786B` (9 bytes) reconstructed as code (Session 13)**, **`$786C`-`$7EFC` (1681 bytes) reconstructed as code**, **`$7EFD`-`$9385` (5257 bytes) reconstructed as data** — **no stretches left pending** |

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
(90 9-byte records, running right up to the engine's last byte).
**Session 12** promoted the first stretch of the last gap
(`$6401`-`$6528`, 296 bytes): the two real entry points reached after
the "enter your name" screen (`FIN_INTRODUCIR_NOMBRE` and
`DESPACHAR_MENU_PRINCIPAL`, which reads P/I/O for play/instructions/
options) and the full options screen (`PANTALLA_OPCIONES`: game speed
and difficulty 1-5, background music and sound effects Y/N).

**Session 13** promoted two more stretches, following the thread from
entry point `$6529` (key P/p): `INICIAR_PARTIDA`/`PREPARAR_NIVEL`
(starts a game and each level: lives=5, score=0),
`PREPARAR_TESOROS_NIVEL` (randomly places 14 treasures with 4
increasing values plus a repeated common value), `ACTUALIZAR_HUD_VIDAS`
(draws as many player icons in the HUD as lives remain),
`SELECCIONAR_DIAGONAL_MARCO_NIVEL` (finds a first caller of
`RELLENAR_MARCO_DIAGONAL_1..6` left pending since Session 7),
`COLOCAR_JUGADOR_INICIAL`, `BUCLE_PRINCIPAL_JUEGO` (the turn-based game
loop, with 5 internal calls resolved by Session 14), and the end-of-game
screens `PANTALLA_STOP_PRESS` (on completing all 6 levels) and
`PANTALLA_GAME_OVER`/`ACTUALIZAR_TABLA_PUNTUACIONES` (on dying —
confirms only this second path inserts the score into the HI-SCORE
table). It also separately closes the last stretch of the original
`INCBIN` (`$7863`-`$786B`, `IMPRIMIR_PUNTUACION_HUD`).

**Session 14** closes the **last `INCBIN` stretch left in the whole
engine** (`$68B2`-`$7862`, 4017 bytes): `PANTALLA_INSTRUCCIONES` (the
game's real instructions screen, menu entry `'I'`, with its 23
paragraphs of literal English text — story, the rules of the 20-box
grid, controls, and skill levels) and, above all, the **5 game-loop
calls** left unresolved since Session 12: `PROCESAR_ENCUENTROS_
ENTIDADES` (collision with treasure/Guardian Mummies),
`PROCESAR_MOVIMIENTO_JUGADOR` (keyboard/joystick input and the
player's actual movement — reuses the same logic as
`MOVER_INDICADOR_MENU`), `ACTUALIZAR_MARCO_TRAS_MOVIMIENTO` (detects
crossing a grid intersection and paints the box side just walked),
`COMPROBAR_SALIDA_NIVEL` (Key + Royal Mummy uncovered → level exit),
and `ANIMAR_APARICION_MOMIA_GUARDIANA` (animates the Guardian Mummy
"digging" its way out of its box). With this, **the whole engine
(`$6000`-`$9385`) is reconstructed as assembler source, with no
unanalyzed `INCBIN` code stretch left** — see `FINDINGS.md` for the
full call map, the per-routine/data confidence table, and the
methodology used.

With the engine complete, **Sessions 15-18** extracted the last
graphics that were still inline `DB` data to individual files: the 14
tiles of the footprint family (Session 15, `src/data/img/tiles/`)
and, more importantly, corrected a wrong identity that had stood since
Session 3: the 4 tables `TABLA_MARCO_1..4`/routines
`DIBUJAR_TRAMO_MARCO_1..4`, long assumed to draw "stretches of the
level's decorative frame" without ever having actually looked at their
pixel content, turned out (Session 16, a parametrized explorer added
to `recursos/sprites.html`; Session 17, the user's visual
identification corroborated by each routine's single real caller) to
be the **4 box-content icons**: sarcophagus (Royal Mummy), key, scroll
and treasure. Renamed to `TABLA_ICONO_*`/`DIBUJAR_ICONO_*` and, once
confirmed as sprite data, to `SPRITE_ICONO_*` with extraction to
individual files (Session 18, `src/data/img/sprites/`).

**Sessions 19-20** swept the whole file looking for the kind of
mechanical jump target an original source would never have: 29
internal `DJNZ`/`JR` loops and all 227 `CALL`/`JP`/`JR` instructions
that jumped to a literal `$XXXX` address received a functional label,
one by one, after reading the real context of each destination — the
final sweep confirms **zero** literal addresses of this kind left
anywhere in `src/mummy1_body.asm`, including the file's most-cited
entry point, `VOLCAR_SPRITE_A_PANTALLA` ($7CC4, 26+ callers). Along
the way, a hypothesis taken for granted since Session 3 was corrected:
`REPETIR_CARACTER` doesn't repeat a fixed character, it prints a
length-prefixed byte sequence — renamed `IMPRIMIR_BYTES_CON_LONGITUD`,
with the mechanism verified through exact address arithmetic against
`PANTALLA_OPCIONES`'s real on-screen labels.

**Session 21** located the firmware's complete official Text VDU
control-code table (Appendix VII of the CPC manual) and rewrote the
game's mixed text blocks (control codes + ASCII) — the options menu,
the attract-mode story, the score table, the main menu, the copyright
notice — with 32 named `CTRL_TXT_*` constants, the way the original
programmer would have written them, instead of raw hexadecimal.
**Session 22** located the real callers of
`TABLA_OFFSETS_DIAMANTE`/`VARIABLES_DIBUJO_MARCO` (renamed
`TABLA_POSICIONES_INICIALES_ENTIDADES`, decomposed into 4 individual
variables) and audited 24 labels that looked like they had "no
apparent caller" — almost all of them did (through natural fall-through
or an unreplaced literal address); it also resolved
`TABLA_PARAMETROS_TRANSICION_PUNTUACIONES` (a wrong name: it has
nothing to do with the score table, it's palette/screen-mode
initialization data with 2 real callers) and converted hexadecimal
literals whose real meaning is an in-game quantity (lives, points,
table sizes...) to decimal.

**Sessions 23-25** did the same work for sound. The background music
(`GUION_SONIDO_CIRCULAR`, 90 9-byte records) was decoded field by
field against the CPC firmware's `SOUND QUEUE` format (Session 23),
and the 3 one-shot sound effects (lose a life, treasure, item found)
turned out to use exactly the same format, combined with the 6
volume/tone envelopes already known since Session 3 (Session 24 —
which also corrects the real boundary of `ENVOLVENTE_TONO_3`, which
had those 3 blocks mixed into it). The 9 resulting files (music + 6
envelopes + 3 effects) are extracted to `src/data/sound/*.bin`, each
with an editable `.txt` twin (byte-exact round-trip verified) and a
reference `.wav`, using new custom tooling
(`tools/guion_sonido_tool.py`/`_player.py`,
`tools/envolvente_sonido_tool.py`/`_player.py`, Sessions 23 and 25).
Some low-level details of the format (the exact meaning of a negative
`SOUND QUEUE` duration, or of the "Rendezvous" bit) remain a
reasoned-from-the-data hypothesis, not confirmed in an emulator — see
`FINDINGS.md` Sessions 23-25 for the full detail.

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
  `sprite_jugador_*`/`sprite_momia_*`, 64 bytes each; Session 18: + 4
  `sprite_icono_sarcofago`/`_llave`/`_pergamino`/`_tesoro`, the
  box-content icons whose identity Session 17 corrected) and
  `img/tiles/` (Session 15: the 14 tiles of the footprint family).
  `img/logo/`, `img/marco_decorativo/`, `img/texto/`, `niveles/` are
  still empty for now. `sound/guion_sonido_circular.bin` (Session 23:
  the 810 bytes of `GUION_SONIDO_CIRCULAR`, the background music, with
  its twin editable `.txt` and reference `.wav` — see
  `tools/guion_sonido_tool.py` below). `sound/envolvente_amplitud_1/2/3.bin`
  and `sound/envolvente_tono_1/2/3.bin` (Session 25: the 6
  volume/tone envelopes, with editable `.txt` and a demo `.wav` of
  their shape) and `sound/sonido_perder_vida.bin`/`sonido_tesoro.bin`/
  `sonido_objeto_encontrado.bin` (Session 25: the 3 one-shot sound
  effects, the same 9-byte `SOUND QUEUE` block as the music but
  combined with an envelope, with editable `.txt` and a real `.wav` —
  see `tools/envolvente_sonido_tool.py` below).
  `mummy1_resto_sin_analizar.bin`
  is no longer referenced by any `INCBIN` as of Session 14 (the whole
  engine is now reconstructed as source) — left in the tree as a
  historical reference to the raw binary.
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
  the original), `guion_sonido_tool.py` (Session 23: decode/encode
  `GUION_SONIDO_CIRCULAR` — binary <-> editable text by musical note,
  with byte-exact round-trip), `guion_sonido_player.py` (synthesizes
  that table to a `.wav` so it can be listened to),
  `envolvente_sonido_tool.py` (Session 25: decode/encode the 6
  amplitude/tone envelopes and the 3 one-shot sound effects — binary
  <-> editable text, with byte-exact round-trip) and
  `envolvente_sonido_player.py` (Session 25: synthesizes a demo `.wav`
  for each standalone envelope and the real `.wav` of each one-shot
  effect, combining the `SOUND QUEUE` register with its
  amplitude/tone envelope).
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
  width/height/CPC mode; Sessions 16/17/18: parametrized explorer and
  full data sheet that confirmed the identity of the 4 box-content
  icons and the 16 player/mummy sprites — of `TABLAS_SPRITE_CASILLA`'s
  1457 bytes, only 17 remain genuinely unidentified, see Session 21).
  `graficos.html` is still empty (the footprint tiles extracted in
  Session 15 are documented in `sprites.html`/`mapa_memoria.html`
  instead). Also `ohmummy_referencia_binario.html`: a supporting
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
