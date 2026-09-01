"""Lectura de imagenes .dsk (formato CPCEMU, no extendido) y del
sistema de ficheros AMSDOS que contienen.

Formato de referencia: "Disk-Info-Block" + "Track-Info-Block" x N,
tal como lo define CPCEMU / documenta CPCWiki. Este modulo solo
soporta el formato "estandar" (todas las pistas del mismo tamano) --
es el que usa el volcado de Oh Mummy en FISICO/. El formato
"extended" (tabla de tamanos de pista por separado) no esta
implementado porque no hace falta todavia.
"""

from __future__ import annotations

import dataclasses

DISC_INFO_SIZE = 256
TRACK_INFO_HEADER_SIZE = 256
SECTOR_SIZE_BASE = 128  # tamano = SECTOR_SIZE_BASE << N
DIR_ENTRY_SIZE = 32
DIR_ENTRIES = 64
BLOCK_SIZE = 1024
DELETED_MARKER = 0xE5


class FormatoNoSoportado(Exception):
    pass


@dataclasses.dataclass
class DiscInfo:
    firma: bytes
    num_pistas: int
    num_caras: int
    tamano_pista: int  # solo formato estandar


@dataclasses.dataclass
class Sector:
    pista: int
    cara: int
    id_c: int
    id_h: int
    id_r: int
    id_n: int
    datos: bytes


@dataclasses.dataclass
class EntradaCatalogo:
    indice: int  # posicion (0-63) dentro del catalogo
    usuario: int
    nombre: str
    extension: str
    solo_lectura: bool
    sistema: bool
    numero_extent: int
    registros: int  # registros de 128 bytes usados en este extent
    bloques: list[int]


class Disco:
    def __init__(self, datos: bytes):
        self.datos = datos
        self.info = self._leer_disc_info()
        self.pistas: list[list[Sector]] = [
            self._leer_pista(t) for t in range(self.info.num_pistas)
        ]

    def _leer_disc_info(self) -> DiscInfo:
        cab = self.datos[:DISC_INFO_SIZE]
        firma = cab[:16]
        if firma.startswith(b"EXTENDED"):
            raise FormatoNoSoportado(
                "Formato DSK extendido no soportado por esta herramienta"
            )
        if not firma.startswith(b"MV - CPC"):
            raise FormatoNoSoportado(f"Cabecera desconocida: {firma!r}")
        num_pistas = cab[0x30]
        num_caras = cab[0x31]
        tamano_pista = int.from_bytes(cab[0x32:0x34], "little")
        return DiscInfo(firma, num_pistas, num_caras, tamano_pista)

    def _leer_pista(self, indice_pista: int) -> list[Sector]:
        off_pista = DISC_INFO_SIZE + indice_pista * self.info.tamano_pista
        cab = self.datos[off_pista : off_pista + TRACK_INFO_HEADER_SIZE]
        if not cab.startswith(b"Track-Info"):
            raise FormatoNoSoportado(
                f"Track-Info ausente en pista {indice_pista} (offset {off_pista:#x})"
            )
        pista_num = cab[0x10]
        cara_num = cab[0x11]
        tam_sector_cod = cab[0x14]
        num_sectores = cab[0x15]
        tam_sector = SECTOR_SIZE_BASE << tam_sector_cod

        off_datos = off_pista + TRACK_INFO_HEADER_SIZE
        sectores = []
        for i in range(num_sectores):
            e = cab[0x18 + i * 8 : 0x18 + i * 8 + 8]
            c, h, r, n = e[0], e[1], e[2], e[3]
            inicio = off_datos + i * tam_sector
            datos = self.datos[inicio : inicio + tam_sector]
            sectores.append(Sector(pista_num, cara_num, c, h, r, n, datos))
        return sectores

    def area_datos_lineal(self) -> bytes:
        """Concatena los sectores de todas las pistas en el orden en que
        aparecen en el fichero .dsk -- es el espacio de direccionamiento
        que usan los numeros de bloque AMSDOS (bloque = 1024 bytes)."""
        trozos = []
        for sectores in self.pistas:
            for s in sectores:
                trozos.append(s.datos)
        return b"".join(trozos)

    def catalogo(self) -> list[EntradaCatalogo]:
        area = self.area_datos_lineal()
        dir_bytes = area[: (DIR_ENTRIES * DIR_ENTRY_SIZE)]
        entradas = []
        for i in range(DIR_ENTRIES):
            e = dir_bytes[i * DIR_ENTRY_SIZE : (i + 1) * DIR_ENTRY_SIZE]
            if e[0] == DELETED_MARKER:
                continue
            usuario = e[0]
            nombre = bytes(b & 0x7F for b in e[1:9]).decode("ascii", "replace").rstrip()
            ext_raw = e[9:12]
            extension = bytes(b & 0x7F for b in ext_raw).decode("ascii", "replace").rstrip()
            solo_lectura = bool(ext_raw[0] & 0x80)
            sistema = bool(ext_raw[1] & 0x80)
            extent = e[12] + (e[14] << 5)
            registros = e[15]
            bloques = [b for b in e[16:32] if b != 0]
            entradas.append(
                EntradaCatalogo(
                    i, usuario, nombre, extension, solo_lectura, sistema,
                    extent, registros, bloques,
                )
            )
        return entradas

    def leer_fichero(self, entradas_fichero: list[EntradaCatalogo]) -> bytes:
        """Reconstruye el contenido de un fichero a partir de todos sus
        extents (entradas de catalogo con el mismo nombre), en orden."""
        area = self.area_datos_lineal()
        entradas_fichero = sorted(entradas_fichero, key=lambda e: e.numero_extent)
        out = bytearray()
        for entrada in entradas_fichero:
            for bloque in entrada.bloques:
                out += area[bloque * BLOCK_SIZE : (bloque + 1) * BLOCK_SIZE]
        return bytes(out)


def agrupar_por_fichero(entradas: list[EntradaCatalogo]) -> dict[tuple[int, str, str], list[EntradaCatalogo]]:
    grupos: dict[tuple[int, str, str], list[EntradaCatalogo]] = {}
    for e in entradas:
        clave = (e.usuario, e.nombre, e.extension)
        grupos.setdefault(clave, []).append(e)
    return grupos


@dataclasses.dataclass
class CabeceraAmsdos:
    """Solo expone lo que el checksum permite dar por hecho sin
    ambiguedad: que hay cabecera (128 bytes) y que su contenido no esta
    corrupto. El significado de cada campo del cuerpo de la cabecera
    (tipo, direccion de carga, direccion de ejecucion, longitud...)
    varia segun la fuente consultada y NO se decodifica aqui todavia
    -- se deja para la fase de desensamblado semantico, verificandolo
    contra el propio MUMMY.BAS (que hace el LOAD/CALL real) en vez de
    fiarse de una tabla de memoria. Ver FINDINGS.md."""

    usuario: int
    nombre: str
    extension: str
    checksum: int
    crudos: bytes  # los 128 bytes de la cabecera, tal cual

    def dump_hex(self) -> str:
        return self.crudos.hex()


def leer_cabecera_amsdos(datos: bytes) -> CabeceraAmsdos | None:
    """Decodifica los primeros 128 bytes de un fichero AMSDOS como
    cabecera, si el checksum (suma de los bytes 0-66 en modulo 65536,
    almacenada en 67-68 LE) valida. Devuelve None si no hay cabecera
    (algunos ficheros ASCII se guardan sin ella)."""
    if len(datos) < 69:
        return None
    h = datos[:128] if len(datos) >= 128 else datos
    if len(h) < 69:
        return None
    checksum_calc = sum(h[0:67]) % 65536
    checksum_alm = h[67] | (h[68] << 8)
    if checksum_calc != checksum_alm:
        return None
    nombre = bytes(b & 0x7F for b in h[1:9]).decode("ascii", "replace").rstrip()
    extension = bytes(b & 0x7F for b in h[9:12]).decode("ascii", "replace").rstrip()
    return CabeceraAmsdos(
        usuario=h[0],
        nombre=nombre,
        extension=extension,
        checksum=checksum_calc,
        crudos=bytes(h),
    )
