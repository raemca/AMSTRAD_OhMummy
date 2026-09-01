# Manuals

*[Leer esto en español](README.md)*

*Reverse engineering, analysis and documentation: Rafael Eduardo Martín Candial (raemca@hotmail.com)*

This folder is different from `../FINDINGS.md` (the chronological
findings log). That log documents **how each thing was discovered**,
in investigation order, with all the uncertainty and dead ends along
the way.

Here, instead, we will document **how each already-understood
subsystem works**, in an organized, pedagogical way — as if it were
the technical manual a programmer of the era would have left for a
new colleague. Two concrete goals:

1. **Training**: so a programmer joining the project (or doing similar
   reverse engineering elsewhere) can learn how each piece actually
   works without having to redo the whole investigation process.
2. **Preservation**: to leave a clear, readable record of how this
   piece of 8-bit software archaeology is built, beyond the
   reconstructed source code itself.

Each manual will assume the reader knows Z80 assembler and programming
in general, but will **not** assume anything specific about this
project or Amstrad CPC hardware — that will be explained from scratch
the first time it's needed.

## Index

*(No manuals yet — nothing has been disassembled. They will be added
here as each subsystem is closed out, following the same criteria as
the sibling MSX and ZX Spectrum *Mad Mix Game* projects: sound engine,
collision/AI engine, graphics subsystem, level format.)*
