"""Lista el catalogo AMSDOS de un .dsk (por defecto, el de FISICO/) y,
para cada fichero, decodifica su cabecera AMSDOS de 128 bytes si la
tiene (BASIC/binario), verificando el checksum.

Uso:
    py tools/dsk_catalog.py ["ruta/al.dsk"]
"""

from __future__ import annotations

import glob
import sys

from dsk_common import Disco, agrupar_por_fichero, leer_cabecera_amsdos


def localizar_dsk() -> str:
    candidatos = sorted(glob.glob("FISICO/*.dsk"))
    if not candidatos:
        raise SystemExit("No se encuentra ningun .dsk en FISICO/. Indica la ruta como argumento.")
    return candidatos[0]


def main() -> None:
    ruta = sys.argv[1] if len(sys.argv) > 1 else localizar_dsk()
    with open(ruta, "rb") as f:
        datos = f.read()

    disco = Disco(datos)
    info = disco.info
    print(f"Fichero: {ruta}")
    print(f"Firma: {info.firma[:16].decode('ascii', 'replace').strip()}")
    print(f"Pistas: {info.num_pistas}  Caras: {info.num_caras}  Tamano de pista: {info.tamano_pista} bytes")
    primera_pista = disco.pistas[0]
    ids = [f"{s.id_r:#04x}" for s in primera_pista]
    print(f"Sectores en pista 0: {len(primera_pista)} (tamano {len(primera_pista[0].datos)} bytes cada uno), IDs: {', '.join(ids)}")
    print()

    entradas = disco.catalogo()
    grupos = agrupar_por_fichero(entradas)
    print(f"Catalogo: {len(grupos)} fichero(s), {len(entradas)} entrada(s) de directorio")
    print()

    for (usuario, nombre, extension), entradas_fichero in sorted(grupos.items(), key=lambda kv: kv[1][0].indice):
        total_bloques = sum(len(e.bloques) for e in entradas_fichero)
        tamano_aprox = total_bloques * 1024
        flags = []
        if entradas_fichero[0].solo_lectura:
            flags.append("RO")
        if entradas_fichero[0].sistema:
            flags.append("SYS")
        flags_txt = f" [{','.join(flags)}]" if flags else ""
        print(f"  {usuario}:{nombre}.{extension}{flags_txt}  ~{tamano_aprox} bytes ({total_bloques} bloques, {len(entradas_fichero)} extent(s))")

        contenido = disco.leer_fichero(entradas_fichero)
        cabecera = leer_cabecera_amsdos(contenido)
        if cabecera is not None:
            print(f"      cabecera AMSDOS OK (checksum {cabecera.checksum:#06x}) -- 128 bytes, campos sin decodificar aun:")
            print(f"      {cabecera.dump_hex()}")
        else:
            print("      sin cabecera AMSDOS valida (fichero ASCII/CP-M plano, o checksum no cuadra)")
    print()
    print("Bloques 0 y 1 son el directorio; el area de datos AMSDOS empieza en el bloque 2.")


if __name__ == "__main__":
    main()
