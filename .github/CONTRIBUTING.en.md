# Contributing Guide

*[Leer esto en español](CONTRIBUTING.md)*

Thanks for your interest in contributing to this **reverse-engineering,
disassembly and Z80 assembly reconstruction** project for *Oh Mummy*
(Amsoft, 1984, Amstrad CPC, disk version)!

The goal of this repository is to translate the game's original binary
(disk, `.dsk`) into real Z80 source code, identifying and documenting
functions, variables and data blocks, always keeping a **1:1 reconstruction
(byte-matching)** against the original executable. Before anything else,
take a look at `README.md` and `src/README.md` (the project's architecture
and conventions) and `FINDINGS.md` (the findings diary, Spanish-only so
far) to understand how the work has been done up to now.

**Current status: environment only.** There is no assembler source or
extracted resources yet — only the `.dsk`-reading tools
(`tools/dsk_common.py`, `dsk_catalog.py`, `dsk_extract.py`). The
sections below describe the workflow planned for once disassembly
starts; until then, the most useful contributions are around those
tools and the documentation.

---

## 📌 Core Project Principles

1. **1:1 fidelity (byte-matching):** any change to the assembler
   instructions or data tables must keep generating a binary that is
   byte-for-byte identical to the original. Unless documented
   otherwise in `FINDINGS.md` (as happened with a real,
   platform-specific bug in the sibling MSX project), there are no
   exceptions.
2. **Clarity over interpretation:** no new code is added, and original
   routines are not "optimized". The goal is to translate and
   interpret exactly what the binary does, original bugs included if
   any.
3. **Step by step:** better to label/document a small, verified block
   than to submit a large change that hasn't been checked against the
   real binary.
4. **Descriptive names in Spanish:** following the convention already
   established in the sibling projects (MSX and ZX Spectrum versions
   of *Mad Mix Game*), descriptive names are used **in Spanish**, not
   English nor cryptic abbreviations — e.g. `MOTOR_ACTORES`,
   `CONSULTAR_TIPO_LOSETA`, not `ACTOR_ENGINE` or `lbl_8600`. Purely
   internal labels within a routine (jump targets with no identity of
   their own) use SjASMPlus's local-label mechanism with a leading dot
   (`.BUCLE_SEGMENTO`).
5. **Don't assume the meaning of a field/address without verifying
   it:** when something can be interpreted in more than one way (for
   example, the fields of a binary's AMSDOS header), it is documented
   as pending instead of stated from memory — it gets verified against
   the code that actually uses it (e.g. the BASIC loader) before being
   taken as fact. See `FINDINGS.md`.

---

## 🛠️ Working Environment and Tools

- **Assembler:** [SjASMPlus](https://github.com/z00m128/sjasmplus) on
  the PATH — the assembler planned for this project (same as the MSX
  and ZX Spectrum siblings), even though there is no source to compile
  yet.
- **Python 3** (`py` on Windows) — for the tools in `tools/`. No
  external dependencies, standard library only.
- **An Amstrad CPC emulator** (e.g. [CPCemu](http://www.cpc-emu.org/)
  or [RetroVirtualMachine](https://www.retrovirtualmachine.org/)),
  optional but recommended, to test the result and cross-check
  findings.
- **A legally obtained copy of the original game** (`.dsk`) if you
  want to verify the byte-for-byte comparison yourself — this
  repository does **not** include the original dump, see
  `AVISO-LEGAL.md`. Without it you can still contribute (documentation,
  tooling), just not verify the byte-match yourself.

---

## 🚀 Contribution Workflow

### 1. Set Up the Repository

1. **Fork** this repository on GitHub.
2. Clone it locally:

   ```bash
   git clone https://github.com/YOUR_USERNAME/AMSTRAD_OhMummy.git
   cd AMSTRAD_OhMummy
   ```

3. Create a descriptive branch:

   ```bash
   git checkout -b read-dsk-catalog
   ```

### 2. Run and Verify

For now, run the disk-reading tools:

```bash
py tools/dsk_catalog.py
py tools/dsk_extract.py
```

Once assembler source exists, this section will be expanded with the
full build (`py tools/build_all.py`) and the verified generation of
the reconstructed `.dsk` — the script should print "0 differences"
against `FISICO/Oh Mummy (1984)(Amsoft).dsk`. If your change is
comments/renaming only, the result must be **exactly the same** as
before your change.

### 3. Document the finding

If you identify or fix something (a label, a data block, a behavior),
add an entry to `FINDINGS.md` following the style already in use — a
`##`/`###` heading describing what was believed before, what was
discovered, and how it was verified. It's the project's chronological
log; history isn't rewritten, entries are appended.

---

## 📬 Submitting Pull Requests

1. Commit your changes with descriptive messages:

   ```bash
   git commit -m "Add AMSDOS header extraction and document the catalogue in FINDINGS.md"
   ```

2. Push your branch:

   ```bash
   git push origin read-dsk-catalog
   ```
3. Open a **Pull Request** against this repository's `main` branch.
4. In the PR description, state which files/labels the change affects
   and, if applicable, the result of the byte-for-byte verification
   (§2).

---

## 🐛 Reporting Bugs and Inconsistencies

If you find a misinterpreted section, data read as code, or a label
that no longer describes what its routine does, but aren't going to
fix it yourself:

1. Check there isn't already an open Issue about it.
2. Open a new Issue describing the problem.
3. Include the actual memory address and the technical justification —
   better yet if you can verify it live with an emulator or by
   comparing against the original binary.

---

Thanks for helping preserve and reverse-engineer this piece of early
Amstrad CPC software history!
