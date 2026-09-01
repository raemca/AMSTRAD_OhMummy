"""Reconstruye el `.dsk` completo del juego a partir de las fuentes de
`src/` -- equivalente para este proyecto de lo que `gen_tzx_file.py`
hace en los proyectos hermanos (Spectrum/MSX) con el `.tzx`.

Construye el disco pieza a pieza (cabecera del disco, cabeceras de
pista, catalogo AMSDOS, area de datos) en vez de copiar el original,
salvo en dos tramos que NO son reconstruibles porque son contenido
sobrante de una version anterior del fichero en ese mismo sector
fisico (no forman parte del programa real, ver FINDINGS.md Sesion 7):
- El relleno tras el cuerpo real de `MUMMY.BAS` dentro de sus 3
  bloques (508 bytes) -- resultaron ser restos legibles de una
  versión previa de los mismos DATA de la portada.
- El relleno tras el cuerpo real de `MUMMY1.BIN` dentro de sus 14
  bloques (1018 bytes).
- Los ~90 bytes "sin campo conocido" de cada cabecera AMSDOS de 128
  bytes (ver FINDINGS.md Sesion 1-2) -- se copian del original igual
  que ya hace `amsdos_basic_tool.tokenizar()`.

Todo lo demas (cabecera del disco, cabeceras de las 40 pistas,
catalogo, relleno $E5 del disco vacio, y el contenido real de los dos
ficheros) se genera desde cero a partir de `src/main.asm` y
`src/load_disk/mummy_bas.bas`, y el resultado se compara byte a byte
contra el `.dsk` original.

Uso:
    py tools/dsk_build.py
"""

from __future__ import annotations

import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dsk_common import Disco, agrupar_por_fichero  # noqa: E402
from amsdos_basic_tool import tokenizar  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SJASMPLUS = os.environ.get(
    "SJASMPLUS",
    r"C:\Users\raemc\Documents\Programacion\MSX\compiladores\sjasmplus\sjasmplus.exe",
)

DISC_INFO_SIZE = 256
TRACK_INFO_SIZE = 256
SECTOR_SIZE = 512
SECTORES_POR_PISTA = 9
TAMANO_PISTA = TRACK_INFO_SIZE + SECTORES_POR_PISTA * SECTOR_SIZE  # 4864
NUM_PISTAS = 40
BLOCK_SIZE = 1024


def localizar_original() -> str:
    import glob

    candidatos = sorted(glob.glob(os.path.join(RAIZ, "FISICO", "*.dsk")))
    if not candidatos:
        raise SystemExit("No se encuentra el .dsk original en FISICO/")
    return candidatos[0]


def compilar_motor() -> bytes:
    src_dir = os.path.join(RAIZ, "src")
    build_dir = os.path.join(src_dir, "build")
    os.makedirs(build_dir, exist_ok=True)
    resultado = subprocess.run([SJASMPLUS, "main.asm"], cwd=src_dir, capture_output=True, text=True)
    if resultado.returncode != 0:
        print(resultado.stdout)
        print(resultado.stderr)
        raise SystemExit("SjASMPlus fallo")
    with open(os.path.join(build_dir, "mummy1.bin"), "rb") as f:
        return f.read()


def tokenizar_basic(cabecera_original: bytes) -> bytes:
    ruta_bas = os.path.join(RAIZ, "src", "load_disk", "mummy_bas.bas")
    with open(ruta_bas, "r", encoding="utf-8") as f:
        texto = f.read()
    return tokenizar(texto, cabecera_original)


def construir_cabecera_disco() -> bytes:
    """Disc-Information-Block de 256 bytes, formato CPCEMU estandar."""
    h = bytearray(256)
    firma = b"MV - CPCEMU / 16 May 97 18:37\x00    "
    h[0 : len(firma)] = firma
    h[0x30] = NUM_PISTAS
    h[0x31] = 1  # una cara
    h[0x32] = TAMANO_PISTA & 0xFF
    h[0x33] = (TAMANO_PISTA >> 8) & 0xFF
    return bytes(h)


def construir_cabecera_pista(num_pista: int) -> bytes:
    """Track-Information-Block de 256 bytes: formato "Data" de AMSDOS,
    9 sectores de 512 bytes con IDs $C1-$C9, gap#3=$4E, filler=$E5
    (mismos valores que el disco original -- son constantes estandar
    del formato, no datos especificos de este juego)."""
    h = bytearray(256)
    h[0:12] = b"Track-Info\r\n"
    h[0x10] = num_pista
    h[0x11] = 0  # cara
    h[0x14] = 2  # codigo de tamano de sector: 128<<2 = 512
    h[0x15] = SECTORES_POR_PISTA
    h[0x16] = 0x4E  # gap#3
    h[0x17] = 0xE5  # filler
    for i in range(SECTORES_POR_PISTA):
        off = 0x18 + i * 8
        h[off + 0] = num_pista  # C
        h[off + 1] = 0  # H
        h[off + 2] = 0xC1 + i  # R
        h[off + 3] = 2  # N
        # ST1, ST2, longitud real (0 = usar N) quedan a 0
    return bytes(h)


def construir_entrada_catalogo(usuario: int, nombre: str, extension: str, bloques: list[int], registros: int) -> bytes:
    e = bytearray(32)
    e[0] = usuario
    nom = (nombre + " " * 8)[:8].encode("ascii")
    ext = (extension + " " * 3)[:3].encode("ascii")
    e[1:9] = nom
    e[9:12] = ext
    e[12] = 0  # extent bajo
    e[15] = registros
    for i, b in enumerate(bloques[:16]):
        e[16 + i] = b
    return bytes(e)


def main() -> None:
    ruta_original = localizar_original()
    with open(ruta_original, "rb") as f:
        original = f.read()
    disco = Disco(original)
    entradas = disco.catalogo()
    grupos = agrupar_por_fichero(entradas)

    def fichero(nombre: str, ext: str):
        for (u, n, e), ents in grupos.items():
            if n == nombre and e == ext:
                return sorted(ents, key=lambda x: x.numero_extent)
        raise KeyError((nombre, ext))

    ent_bas = fichero("MUMMY", "BAS")
    ent_bin = fichero("MUMMY1", "BIN")
    bloques_bas = ent_bas[0].bloques
    bloques_bin = ent_bin[0].bloques
    registros_bas = ent_bas[0].registros
    registros_bin = ent_bin[0].registros

    contenido_original_bas = disco.leer_fichero(ent_bas)
    contenido_original_bin = disco.leer_fichero(ent_bin)
    cabecera_original_bas = contenido_original_bas[:128]
    cabecera_original_bin = contenido_original_bin[:128]

    print("Compilando el motor con SjASMPlus...")
    motor = compilar_motor()
    print(f"  motor: {len(motor)} bytes")

    print("Tokenizando el cargador BASIC...")
    bas_completo = tokenizar_basic(cabecera_original_bas)
    print(f"  cargador: {len(bas_completo)} bytes (cabecera + cuerpo)")

    # ---- Reconstruir el fichero MUMMY1.BIN completo: cabecera del
    # original (no reconstruible, ver docstring) + motor recompilado +
    # relleno del original (contenido sobrante no reconstruible) ----
    longitud_bin_real = 128 + len(motor)
    relleno_bin = contenido_original_bin[longitud_bin_real:]
    bin_completo = cabecera_original_bin + motor + relleno_bin

    # ---- MUMMY.BAS: cabecera+cuerpo ya generados por tokenizar(), +
    # relleno del original dentro de sus bloques asignados ----
    relleno_bas = contenido_original_bas[len(bas_completo):]
    bas_completo_con_relleno = bas_completo + relleno_bas

    if len(bas_completo_con_relleno) != len(contenido_original_bas):
        raise SystemExit(
            f"Tamano de MUMMY.BAS no cuadra: generado {len(bas_completo_con_relleno)}, "
            f"original {len(contenido_original_bas)}"
        )
    if len(bin_completo) != len(contenido_original_bin):
        raise SystemExit(
            f"Tamano de MUMMY1.BIN no cuadra: generado {len(bin_completo)}, "
            f"original {len(contenido_original_bin)}"
        )

    # ---- Construir el area de datos lineal completa (40 pistas x
    # 4608 bytes = 184320 bytes = 180 bloques) ----
    area = bytearray(b"\xE5" * (NUM_PISTAS * SECTORES_POR_PISTA * SECTOR_SIZE))

    # Directorio: bloques 0-1 (2048 bytes, 64 entradas de 32 bytes)
    directorio = bytearray(b"\xE5" * 2048)
    directorio[0:32] = construir_entrada_catalogo(0, "MUMMY", "BAS", bloques_bas, registros_bas)
    directorio[32:64] = construir_entrada_catalogo(0, "MUMMY1", "BIN", bloques_bin, registros_bin)
    area[0:2048] = directorio

    def escribir_bloques(datos: bytes, bloques: list[int]):
        pos = 0
        for b in bloques:
            area[b * BLOCK_SIZE : (b + 1) * BLOCK_SIZE] = datos[pos : pos + BLOCK_SIZE]
            pos += BLOCK_SIZE

    escribir_bloques(bas_completo_con_relleno, bloques_bas)
    escribir_bloques(bin_completo, bloques_bin)

    # ---- Volcar el area lineal a las 40 pistas y ensamblar el .dsk ----
    partes = [construir_cabecera_disco()]
    for pista in range(NUM_PISTAS):
        partes.append(construir_cabecera_pista(pista))
        inicio = pista * SECTORES_POR_PISTA * SECTOR_SIZE
        partes.append(bytes(area[inicio : inicio + SECTORES_POR_PISTA * SECTOR_SIZE]))
    dsk_generado = b"".join(partes)

    build_dir = os.path.join(RAIZ, "build")
    os.makedirs(build_dir, exist_ok=True)
    ruta_salida = os.path.join(build_dir, "ohmummy_reconstruido.dsk")
    with open(ruta_salida, "wb") as f:
        f.write(dsk_generado)

    print(f"\nEscrito {ruta_salida} ({len(dsk_generado)} bytes)")
    print(f"Original: {len(original)} bytes")

    if dsk_generado == original:
        print("\n[OK] 0 diferencias -- el .dsk reconstruido es identico byte a byte al original")
    else:
        n = min(len(dsk_generado), len(original))
        diffs = [i for i in range(n) if dsk_generado[i] != original[i]]
        print(f"\n[FALLO] {len(diffs)} bytes distintos de {n}")
        for i in diffs[:10]:
            print(f"    offset {i:#08x}: generado={dsk_generado[i]:#04x} original={original[i]:#04x}")
        sys.exit(1)


if __name__ == "__main__":
    main()
