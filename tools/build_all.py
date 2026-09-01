"""Compila todo el proyecto y verifica el resultado byte a byte contra
el `.dsk` original.

- Ensambla `src/main.asm` con SjASMPlus -> `src/build/mummy1.bin`
  (motor, $6000-$9385) y lo compara contra el fichero real extraido
  del disco (`FISICO/extraido/MUMMY1.BIN`, sin los 128 bytes de
  cabecera AMSDOS).
- Tokeniza `src/load_disk/mummy_bas.bas` -> `src/build/mummy.bas` y lo
  compara contra `FISICO/extraido/MUMMY.BAS` (con cabecera incluida).

Requiere `py tools/dsk_extract.py` ya ejecutado (o lo ejecuta el
propio script si faltan los ficheros de FISICO/extraido/).

Uso:
    py tools/build_all.py
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SJASMPLUS = os.environ.get(
    "SJASMPLUS",
    r"C:\Users\raemc\Documents\Programacion\MSX\compiladores\sjasmplus\sjasmplus.exe",
)


def asegurar_extraido():
    ruta = os.path.join(RAIZ, "FISICO", "extraido", "MUMMY1.BIN")
    if not os.path.exists(ruta):
        print("FISICO/extraido/ no existe todavia -- ejecutando dsk_extract.py...")
        subprocess.run([sys.executable, os.path.join(RAIZ, "tools", "dsk_extract.py")], check=True, cwd=RAIZ)


def comparar(nombre: str, real: bytes, generado: bytes) -> bool:
    if real == generado:
        print(f"  [OK] {nombre}: {len(real)} bytes, 0 diferencias")
        return True
    n = min(len(real), len(generado))
    diffs = [i for i in range(n) if real[i] != generado[i]]
    print(f"  [FALLO] {nombre}: real={len(real)} bytes, generado={len(generado)} bytes, {len(diffs)} diferencias")
    for i in diffs[:5]:
        print(f"      offset {i:#06x}: real={real[i]:#04x} generado={generado[i]:#04x}")
    return False


def compilar_motor() -> bool:
    print("Ensamblando src/main.asm con SjASMPlus...")
    src_dir = os.path.join(RAIZ, "src")
    build_dir = os.path.join(src_dir, "build")
    os.makedirs(build_dir, exist_ok=True)
    resultado = subprocess.run(
        [SJASMPLUS, "main.asm"], cwd=src_dir, capture_output=True, text=True
    )
    print(resultado.stdout)
    if resultado.returncode != 0:
        print(resultado.stderr)
        print("  [FALLO] SjASMPlus devolvio un error")
        return False

    with open(os.path.join(build_dir, "mummy1.bin"), "rb") as f:
        generado = f.read()
    with open(os.path.join(RAIZ, "FISICO", "extraido", "MUMMY1.BIN"), "rb") as f:
        real = f.read()[128:128 + 13190]
    return comparar("src/build/mummy1.bin (motor, $6000-$9385)", real, generado)


def compilar_basic() -> bool:
    print("Tokenizando src/load_disk/mummy_bas.bas...")
    build_dir = os.path.join(RAIZ, "src", "build")
    os.makedirs(build_dir, exist_ok=True)
    salida = os.path.join(build_dir, "mummy.bas")
    referencia = os.path.join(RAIZ, "FISICO", "extraido", "MUMMY.BAS")
    resultado = subprocess.run(
        [
            sys.executable,
            os.path.join(RAIZ, "tools", "amsdos_basic_tool.py"),
            "tokenizar",
            os.path.join(RAIZ, "src", "load_disk", "mummy_bas.bas"),
            referencia,
            salida,
        ],
        capture_output=True, text=True,
    )
    print(resultado.stdout)
    if resultado.returncode != 0:
        print(resultado.stderr)
        print("  [FALLO] amsdos_basic_tool.py devolvio un error")
        return False

    with open(salida, "rb") as f:
        generado = f.read()
    with open(referencia, "rb") as f:
        real = f.read()[:len(generado)]
    return comparar("src/build/mummy.bas (cargador)", real, generado)


def main():
    if not os.path.exists(SJASMPLUS):
        raise SystemExit(
            f"No se encuentra SjASMPlus en {SJASMPLUS!r}. "
            "Define la variable de entorno SJASMPLUS con la ruta correcta."
        )
    asegurar_extraido()
    ok_motor = compilar_motor()
    ok_basic = compilar_basic()
    print()
    if ok_motor and ok_basic:
        print("Compilacion completa: todo coincide byte a byte con el original.")
    else:
        print("Compilacion con diferencias -- ver detalle arriba.")
        sys.exit(1)


if __name__ == "__main__":
    main()
