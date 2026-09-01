"""Extrae cada fichero del catalogo AMSDOS de un .dsk a
FISICO/extraido/ -- una copia cruda tal cual esta en el disco
(incluida la cabecera AMSDOS de 128 bytes si la tiene, tal cual, sin
decodificar sus campos -- ver dsk_common.leer_cabecera_amsdos). Deja
tambien un log de la extraccion.

Uso:
    py tools/dsk_extract.py ["ruta/al.dsk"] ["directorio/salida"]
"""

from __future__ import annotations

import datetime
import glob
import os
import sys

from dsk_common import Disco, agrupar_por_fichero, leer_cabecera_amsdos


def localizar_dsk() -> str:
    candidatos = sorted(glob.glob("FISICO/*.dsk"))
    if not candidatos:
        raise SystemExit("No se encuentra ningun .dsk en FISICO/. Indica la ruta como argumento.")
    return candidatos[0]


def main() -> None:
    ruta = sys.argv[1] if len(sys.argv) > 1 else localizar_dsk()
    salida = sys.argv[2] if len(sys.argv) > 2 else "FISICO/extraido"
    os.makedirs(salida, exist_ok=True)

    with open(ruta, "rb") as f:
        datos = f.read()
    disco = Disco(datos)
    entradas = disco.catalogo()
    grupos = agrupar_por_fichero(entradas)

    log_lineas = [
        f"Extraccion de {ruta}",
        f"Fecha: {datetime.datetime.now().isoformat(timespec='seconds')}",
        f"Formato: {disco.info.firma[:16].decode('ascii', 'replace').strip()}, "
        f"{disco.info.num_pistas} pistas x {disco.info.num_caras} cara(s), "
        f"pista de {disco.info.tamano_pista} bytes",
        "",
    ]

    for (usuario, nombre, extension), entradas_fichero in sorted(grupos.items(), key=lambda kv: kv[1][0].indice):
        entradas_fichero = sorted(entradas_fichero, key=lambda e: e.numero_extent)
        contenido = disco.leer_fichero(entradas_fichero)
        nombre_fichero = f"{nombre}.{extension}" if extension else nombre

        ruta_cruda = os.path.join(salida, nombre_fichero)
        with open(ruta_cruda, "wb") as f:
            f.write(contenido)

        linea = f"{nombre_fichero}: {len(contenido)} bytes crudos (bloques asignados) -> {ruta_cruda}"

        cabecera = leer_cabecera_amsdos(contenido)
        if cabecera is not None:
            linea += f"; cabecera AMSDOS OK (checksum {cabecera.checksum:#06x}), campos sin decodificar aun"
        else:
            linea += "; sin cabecera AMSDOS valida, se deja tal cual"

        print(linea)
        log_lineas.append(linea)

    ruta_log = os.path.join(salida, "extraccion.log")
    with open(ruta_log, "w", encoding="utf-8") as f:
        f.write("\n".join(log_lineas) + "\n")
    print(f"\nLog escrito en {ruta_log}")


if __name__ == "__main__":
    main()
