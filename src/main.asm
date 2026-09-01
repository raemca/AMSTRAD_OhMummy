; Oh Mummy (Amsoft, 1984, Amstrad CPC) -- punto de entrada unico de
; compilacion. Ensamblar con SjASMPlus (ver ../tools/build_all.py).
; Ver FINDINGS.md para el diario de reconstruccion sesion a sesion.

    DEVICE NOSLOT64K

    INCLUDE "mummy1_body.asm"

    SAVEBIN "build/mummy1.bin", $6000, $3386
