"""Decodifica/codifica `GUION_SONIDO_CIRCULAR` -- la musica de fondo de
Oh Mummy (90 registros de 9 bytes, 810 bytes, `$905C`-`$9385`, el final
exacto del motor) -- a un fichero de texto editable por humanos y de
vuelta a binario EXACTO, con round-trip verificado byte a byte.

Mismo flujo de trabajo que `mmsnd_tool.py` del proyecto hermano
`MSX/proyectos/madmixgame` (disasm/asm/roundtrip), adaptado: aqui no
hay bytecode de comandos, es una tabla fija de parametros del
firmware de la CPC, asi que el "desensamblado" es decodificar cada
bloque de 9 bytes campo a campo.

Formato de un bloque de 9 bytes de `SOUND QUEUE` del firmware de la
CPC (fuente: https://oldwiki.cpcwiki.eu/index.php/BIOS_Sound_Functions,
confirmado ademas porque las 90 frecuencias resultantes son notas
reales de la escala temperada con <0.1% de error -- ver FINDINGS.md
Sesion 23):

    offset 0: canal/flags -- bits0-2 mascara canal A/B/C, bits3-5
              mascara "Rendezvous" A/B/C, bit6 Hold, bit7 Flush
    offset 1: ENV (envolvente de volumen activa, 0 = ninguna)
    offset 2: ENT (envolvente de tono activa, 0 = ninguna)
    offset 3: tono, byte bajo del periodo de 12 bits
    offset 4: tono, nibble bajo = 4 bits altos del periodo
              (periodo = byte3 + (byte4 AND $0F)*256)
    offset 5: ruido ($00 = sin ruido, $01-$1F = periodo de ruido)
    offset 6: volumen ($00-$0F)
    offset 7: duracion, byte bajo (centesimas de segundo)
    offset 8: duracion, byte alto (con signo -- high*256+low)

    frecuencia_Hz = 125000 / periodo   (periodo en pasos de 8us)

En `GUION_SONIDO_CIRCULAR` tal cual esta en el juego, ENV/ENT/ruido
son siempre 0 (no se usa ninguna envolvente de hardware ni ruido en
esta tabla) y el byte de canal solo toma 4 valores: $11 (canal A +
rendezvous B), $0A (canal B + rendezvous A), $02 (canal B solo) y $01
(canal A solo) -- Hold/Flush nunca se usan aqui.

Uso:
    python tools/guion_sonido_tool.py extraer [salida.bin]
    python tools/guion_sonido_tool.py decodificar <origen.bin|asm> <salida.txt>
    python tools/guion_sonido_tool.py codificar <entrada.txt> <salida.bin>
    python tools/guion_sonido_tool.py roundtrip <origen.bin|asm>
"""

from __future__ import annotations

import math
import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RUTA_BIN_FISICO = os.path.join(RAIZ, "FISICO", "extraido", "MUMMY1.BIN")
RUTA_ASM = os.path.join(RAIZ, "src", "mummy1_body.asm")
RUTA_BIN_EXTRAIDO = os.path.join(RAIZ, "src", "data", "sound", "guion_sonido_circular.bin")

BASE_CARGA = 0x6000          # direccion de carga del motor dentro del .BIN (tras los 128 bytes de cabecera AMSDOS)
CABECERA_AMSDOS = 128
DIR_INICIO = 0x905C          # GUION_SONIDO_CIRCULAR
DIR_FIN = 0x9385 + 1         # un byte despues de GUION_SONIDO_ULTIMO_REGISTRO (exclusivo)
NUM_REGISTROS = 90
TAM_REGISTRO = 9
TAM_TOTAL = NUM_REGISTROS * TAM_REGISTRO  # 810

assert DIR_FIN - DIR_INICIO == TAM_TOTAL

NOTAS = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
CANAL_LETRAS = ["A", "B", "C"]


# ============================================================
# Conversion periodo <-> nota musical
# ============================================================

def periodo_a_frecuencia(periodo: int) -> float:
    return 125000.0 / periodo if periodo else 0.0


def frecuencia_a_nota(freq: float) -> str:
    """Nombre de la nota mas cercana en notacion cientifica (A4=440Hz)."""
    if freq <= 0:
        return "SILENCIO"
    midi = round(12 * math.log2(freq / 440.0) + 69)
    nombre = NOTAS[midi % 12]
    octava = midi // 12 - 1
    return f"{nombre}{octava}"


def nota_a_frecuencia(nombre: str) -> float:
    m = re.match(r"^([A-G]#?)(-?\d+)$", nombre)
    if not m:
        raise ValueError(f"nombre de nota invalido: {nombre!r}")
    letra, octava = m.group(1), int(m.group(2))
    idx = NOTAS.index(letra)
    midi = (octava + 1) * 12 + idx
    return 440.0 * (2 ** ((midi - 69) / 12))


def nota_a_periodo(nombre: str) -> int:
    """Recalcula el periodo real a partir de la formula del firmware
    (125000/frecuencia), con redondeo al entero mas cercano -- se usa
    cuando el usuario edita el NOMBRE de una nota en el .txt."""
    freq = nota_a_frecuencia(nombre)
    periodo = round(125000.0 / freq)
    return max(1, min(4095, periodo))


# ============================================================
# Conversion mascara de canal <-> texto
# ============================================================

def mascara_a_letras(mascara: int) -> str:
    letras = "".join(l for i, l in enumerate(CANAL_LETRAS) if mascara & (1 << i))
    return letras if letras else "-"


def letras_a_mascara(texto: str) -> int:
    if texto in ("-", ""):
        return 0
    mascara = 0
    for ch in texto:
        mascara |= 1 << CANAL_LETRAS.index(ch)
    return mascara


# ============================================================
# Decodificar: bytes -> texto editable
# ============================================================

def decodificar_registro(idx: int, b: bytes) -> str:
    assert len(b) == TAM_REGISTRO
    canal_flags = b[0]
    canal_mask = canal_flags & 0x07
    sync_mask = (canal_flags >> 3) & 0x07
    hold = bool(canal_flags & 0x40)
    flush = bool(canal_flags & 0x80)
    env = b[1]
    ent = b[2]
    periodo = b[3] | ((b[4] & 0x0F) << 8)
    ruido = b[5]
    vol = b[6]
    dur = b[7] | (b[8] << 8)
    if dur >= 32768:
        dur -= 65536

    campos = [f"canal={mascara_a_letras(canal_mask)}"]
    if sync_mask:
        campos.append(f"sync={mascara_a_letras(sync_mask)}")
    if hold:
        campos.append("hold=SI")
    if flush:
        campos.append("flush=SI")
    if env:
        campos.append(f"env={env}")
    if ent:
        campos.append(f"ent={ent}")

    if periodo == 0:
        campos.append("nota=SILENCIO(0)")
    else:
        freq = periodo_a_frecuencia(periodo)
        nombre = frecuencia_a_nota(freq)
        campos.append(f"nota={nombre}({periodo})")

    campos.append(f"vol={vol}")
    campos.append(f"ruido={ruido}")
    if dur >= 0:
        campos.append(f"dur={dur}cs({dur / 100:.2f}s)")
    else:
        campos.append(f"dur={dur}cs(negativo, significado sin confirmar)")

    hexraw = " ".join(f"{x:02X}" for x in b)
    return f"{idx:03d} " + " ".join(campos) + f"  ; {hexraw}"


def decodificar(datos: bytes) -> str:
    if len(datos) != TAM_TOTAL:
        raise ValueError(f"se esperaban {TAM_TOTAL} bytes, llegaron {len(datos)}")
    lineas = [
        "; GUION_SONIDO_CIRCULAR -- musica de fondo de Oh Mummy",
        f"; {NUM_REGISTROS} registros x {TAM_REGISTRO} bytes = {TAM_TOTAL} bytes, "
        f"${DIR_INICIO:04X}-${DIR_FIN - 1:04X}",
        "; Formato de bloque SOUND QUEUE del firmware CPC (ver docstring de este",
        "; fichero / FINDINGS.md Sesion 23). frecuencia_Hz = 125000/periodo.",
        "; Edita 'nota=NOMBRE(periodo)': si cambias solo el NOMBRE (p.ej. C4 -> D4)",
        "; el periodo se recalcula con la formula; si dejas el numero entre",
        "; parentesis tal cual, se usa exacto (permite reconstruccion byte a byte).",
        "; vol=0-15, ruido=0 (sin ruido) o 1-31 (periodo de ruido), dur en centesimas",
        "; de segundo (con su equivalente en segundos entre parentesis).",
        "; canal/sync son mascaras A/B/C (letras concatenadas o '-' si ninguna);",
        "; hold/flush solo aparecen si estan activos; env/ent solo si no son 0.",
        "",
    ]
    for i in range(NUM_REGISTROS):
        bloque = datos[i * TAM_REGISTRO:(i + 1) * TAM_REGISTRO]
        lineas.append(decodificar_registro(i, bloque))
    return "\n".join(lineas) + "\n"


# ============================================================
# Codificar: texto editable -> bytes
# ============================================================

_RE_NOTA = re.compile(r"^(SILENCIO|[A-G]#?-?\d+)(?:\((-?\d+)\))?$")
_RE_DUR = re.compile(r"^(-?\d+)cs")


def parsear_nota(valor: str) -> int:
    m = _RE_NOTA.match(valor)
    if not m:
        raise ValueError(f"campo nota invalido: {valor!r}")
    nombre, periodo_txt = m.group(1), m.group(2)
    if nombre == "SILENCIO":
        return int(periodo_txt) if periodo_txt is not None else 0
    if periodo_txt is None:
        return nota_a_periodo(nombre)
    periodo_raw = int(periodo_txt)
    # si el periodo tal cual escrito sigue correspondiendo al mismo
    # nombre de nota, se usa exacto (round-trip); si no, el usuario
    # cambio el NOMBRE y hay que recalcular el periodo real
    freq = periodo_a_frecuencia(periodo_raw)
    nombre_calculado = frecuencia_a_nota(freq)
    if nombre_calculado == nombre:
        return periodo_raw
    return nota_a_periodo(nombre)


def codificar_linea(linea: str) -> bytes:
    linea = linea.split(";", 1)[0].strip()
    tokens = linea.split()
    if not tokens:
        raise ValueError("linea vacia tras quitar el comentario")
    tokens = tokens[1:]  # el primero es el indice de registro, informativo
    campos = {}
    for tok in tokens:
        clave, _, valor = tok.partition("=")
        campos[clave] = valor

    canal_mask = letras_a_mascara(campos.get("canal", "-"))
    sync_mask = letras_a_mascara(campos.get("sync", "-"))
    hold = campos.get("hold", "NO") == "SI"
    flush = campos.get("flush", "NO") == "SI"
    env = int(campos.get("env", "0"))
    ent = int(campos.get("ent", "0"))
    periodo = parsear_nota(campos["nota"])
    vol = int(campos["vol"])
    ruido = int(campos["ruido"])
    m_dur = _RE_DUR.match(campos["dur"])
    if not m_dur:
        raise ValueError(f"campo dur invalido: {campos['dur']!r}")
    dur = int(m_dur.group(1))

    canal_flags = canal_mask | (sync_mask << 3) | (0x40 if hold else 0) | (0x80 if flush else 0)
    dur_u16 = dur & 0xFFFF

    return bytes([
        canal_flags,
        env,
        ent,
        periodo & 0xFF,
        (periodo >> 8) & 0x0F,
        ruido,
        vol,
        dur_u16 & 0xFF,
        (dur_u16 >> 8) & 0xFF,
    ])


def codificar(texto: str) -> bytes:
    registros = []
    for linea in texto.splitlines():
        linea_sin_comentario = linea.split(";", 1)[0].strip()
        if not linea_sin_comentario:
            continue
        registros.append(codificar_linea(linea))
    datos = b"".join(registros)
    if len(datos) != TAM_TOTAL:
        raise ValueError(
            f"se generaron {len(datos)} bytes ({len(registros)} registros), "
            f"se esperaban {TAM_TOTAL} bytes ({NUM_REGISTROS} registros)"
        )
    return datos


# ============================================================
# Extraccion de los bytes reales (binario fisico / ASM)
# ============================================================

def extraer_de_fisico(ruta_bin: str = RUTA_BIN_FISICO) -> bytes:
    with open(ruta_bin, "rb") as f:
        datos = f.read()
    offset = CABECERA_AMSDOS + (DIR_INICIO - BASE_CARGA)
    return datos[offset:offset + TAM_TOTAL]


def extraer_de_asm(ruta_asm: str = RUTA_ASM) -> bytes:
    """Lee GUION_SONIDO_CIRCULAR desde el ASM -- soporta tanto el
    formato antiguo (90 lineas `DB $xx,...`) como el actual, ya
    extraido a fichero propio e incluido con `INCBIN "ruta",offset,len`
    (posiblemente partido en varios tramos, uno por cada etiqueta
    intermedia como GUION_SONIDO_ULTIMO_REGISTRO)."""
    with open(ruta_asm, "r", encoding="utf-8") as f:
        texto = f.read()
    inicio = texto.index("GUION_SONIDO_CIRCULAR:")
    resto = texto[inicio:]

    valores = bytearray()
    src_dir = os.path.dirname(ruta_asm)
    for linea in resto.splitlines():
        linea_sin_comentario = linea.split(";", 1)[0]
        m_incbin = re.match(r'\s*INCBIN\s+"([^"]+)"\s*(?:,\s*(\d+)\s*,\s*(\d+))?', linea_sin_comentario)
        if m_incbin:
            ruta_rel, off_txt, len_txt = m_incbin.groups()
            ruta_incbin = os.path.join(src_dir, ruta_rel)
            with open(ruta_incbin, "rb") as f:
                datos_incbin = f.read()
            if off_txt is not None:
                off, lon = int(off_txt), int(len_txt)
                valores.extend(datos_incbin[off:off + lon])
            else:
                valores.extend(datos_incbin)
            if len(valores) >= TAM_TOTAL:
                break
            continue
        if "DB " not in linea_sin_comentario:
            continue
        for hexb in re.findall(r"\$([0-9A-Fa-f]{2})", linea_sin_comentario):
            valores.append(int(hexb, 16))
        if len(valores) >= TAM_TOTAL:
            break
    if len(valores) < TAM_TOTAL:
        raise ValueError(f"solo se encontraron {len(valores)} bytes en el ASM, se esperaban {TAM_TOTAL}")
    return bytes(valores[:TAM_TOTAL])


def cargar_origen(ruta: str) -> bytes:
    """Carga los 810 bytes desde un .bin (binario crudo) o desde el .asm
    (busca y parsea los DB de GUION_SONIDO_CIRCULAR)."""
    if ruta.lower().endswith(".asm"):
        return extraer_de_asm(ruta)
    with open(ruta, "rb") as f:
        datos = f.read()
    if len(datos) == TAM_TOTAL:
        return datos
    if os.path.basename(ruta).upper() == "MUMMY1.BIN":
        offset = CABECERA_AMSDOS + (DIR_INICIO - BASE_CARGA)
        return datos[offset:offset + TAM_TOTAL]
    if len(datos) != TAM_TOTAL:
        raise ValueError(
            f"{ruta}: {len(datos)} bytes, no son los {TAM_TOTAL} bytes esperados "
            "de GUION_SONIDO_CIRCULAR (ni un MUMMY1.BIN completo)"
        )
    return datos


# ============================================================
# CLI
# ============================================================

def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    modo = sys.argv[1]

    if modo == "extraer":
        salida = sys.argv[2] if len(sys.argv) > 2 else RUTA_BIN_EXTRAIDO
        datos_fisico = extraer_de_fisico()
        datos_asm = extraer_de_asm()
        if datos_fisico != datos_asm:
            diffs = sum(1 for a, b in zip(datos_fisico, datos_asm) if a != b)
            print(f"  [AVISO] el binario fisico y el ASM difieren en {diffs} bytes")
        else:
            print(f"  [OK] binario fisico y ASM coinciden byte a byte ({len(datos_fisico)} bytes)")
        os.makedirs(os.path.dirname(salida), exist_ok=True)
        with open(salida, "wb") as f:
            f.write(datos_fisico)
        print(f"Escrito {salida} ({len(datos_fisico)} bytes)")

    elif modo == "decodificar":
        if len(sys.argv) < 3:
            raise SystemExit("Uso: python tools/guion_sonido_tool.py decodificar <origen.bin|asm> [salida.txt]")
        origen = sys.argv[2]
        salida = sys.argv[3] if len(sys.argv) > 3 else None
        datos = cargar_origen(origen)
        texto = decodificar(datos)
        if salida:
            with open(salida, "w", encoding="utf-8") as f:
                f.write(texto)
            print(f"Escrito {salida}")
        else:
            print(texto)

    elif modo == "codificar":
        if len(sys.argv) < 4:
            raise SystemExit("Uso: python tools/guion_sonido_tool.py codificar <entrada.txt> <salida.bin>")
        entrada, salida = sys.argv[2], sys.argv[3]
        with open(entrada, "r", encoding="utf-8") as f:
            texto = f.read()
        datos = codificar(texto)
        with open(salida, "wb") as f:
            f.write(datos)
        print(f"Escrito {salida} ({len(datos)} bytes)")

    elif modo == "roundtrip":
        origen = sys.argv[2] if len(sys.argv) > 2 else RUTA_BIN_FISICO
        original = cargar_origen(origen)
        texto = decodificar(original)
        reconstruido = codificar(texto)
        if original == reconstruido:
            print(f"  [OK] roundtrip: {len(original)} bytes, 0 diferencias")
        else:
            diffs = [i for i in range(len(original)) if original[i] != reconstruido[i]]
            print(f"  [FALLO] roundtrip: {len(diffs)} diferencias")
            for i in diffs[:10]:
                print(f"      offset {i:#05x}: original={original[i]:#04x} reconstruido={reconstruido[i]:#04x}")
            raise SystemExit(1)

    else:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main()
