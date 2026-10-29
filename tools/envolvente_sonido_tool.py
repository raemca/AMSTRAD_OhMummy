"""Decodifica/codifica las 6 envolventes de sonido (`ENVOLVENTE_AMPLITUD_1/2/3`,
`ENVOLVENTE_TONO_1/2/3`, `$7FCA`-`$7FFF`) y los 3 efectos de sonido puntuales
(`SONIDO_PERDER_VIDA`, `SONIDO_TESORO`, `SONIDO_OBJETO_ENCONTRADO`, `$8000`-
`$801A`) de Oh Mummy -- a ficheros de texto editables por humanos y de vuelta
a binario EXACTO, con round-trip verificado byte a byte.

Mismo estilo y flujo que `guion_sonido_tool.py` (Sesion 23): funciones
`decodificar()`/`codificar()` por cada formato, con verificacion de
round-trip. Los 3 ficheros de efecto puntual reutilizan directamente
`decodificar_registro()`/`codificar_linea()` de `guion_sonido_tool.py`,
porque son el MISMO bloque `SOUND QUEUE` de 9 bytes que la musica (ver
FINDINGS.md Sesion 24).

Formato de las envolventes (fuente:
https://oldwiki.cpcwiki.eu/index.php/BIOS_Sound_Functions , funciones de
firmware `SOUND_SET_ENV` $BCBC / `SOUND_SET_ENT` $BCBF -- confirmado una
vez a mano sobre `envolvente_tono_3.bin` antes de escribir este modulo,
ver FINDINGS.md Sesion 25):

Envolvente de AMPLITUD (volumen):
    byte 0 (cabecera): bit7 = tipo (0=software, 1=hardware)
                       bits6-0 = numero de pasos de 3 bytes que siguen
    paso software (3 bytes): byte0 = repeticiones del paso ($01-$7F;
        se ha visto $00 en datos reales -- caso ESPECIAL/ambiguo, se
        documenta tal cual, no se descarta -- ver mas abajo)
                              byte1 = incremento de volumen con signo
                              byte2 = duracion de cada repeticion en
                                      centesimas de segundo ($01-$FF,
                                      $00 = 256)
    paso hardware (3 bytes): byte0 = forma de envolvente HW ($00-$0F) + $80
                              byte1 = frecuencia de envolvente, byte alto
                              byte2 = frecuencia de envolvente, byte bajo

Envolvente de TONO:
    byte 0 (cabecera): bit7 = tipo (0=software, 1=hardware)
                       bit6  = repetir (0=una vez, 1=repetir toda la envolvente)
                       bits5-0 = numero de pasos de 3 bytes
    paso software, modo RELATIVO (byte0 < $F0):
                              byte0 = repeticiones ($01-$EF)
                              byte1 = incremento de periodo con signo
                              byte2 = duracion en centesimas de segundo
    paso software, modo FRECUENCIA DIRECTA (byte0 >= $F0):
                              byte0 = $F0 + nibble alto del periodo (12 bits)
                              byte1 = byte bajo del periodo
                              byte2 = duracion en centesimas de segundo
    paso hardware: igual estructura que el paso hardware de amplitud
        (no se ha visto ningun caso real en los 6 ficheros -- los 6
        headers reales son $03,$03,$02,$05,$01,$02, todos con bit7=0).

Caso ESPECIAL "repeticiones=$00": en los 3 ficheros `envolvente_amplitud_*`
aparece en el PRIMER paso de los 3 (y en el ULTIMO paso de
`envolvente_amplitud_1`). El wiki documenta el rango como $01-$7F, asi
que $00 no esta definido alli. Este modulo lo preserva tal cual en el
texto editable (round-trip exacto) y lo marca como "ESPECIAL" en el
comentario; para la sintesis de audio (`envolvente_sonido_player.py`)
se trata como 1 repeticion (asuncion de renderizado, no del firmware).

Uso:
    python tools/envolvente_sonido_tool.py decodificar <origen.bin> [salida.txt]
    python tools/envolvente_sonido_tool.py codificar <entrada.txt> <salida.bin>
    python tools/envolvente_sonido_tool.py roundtrip <origen.bin>
    python tools/envolvente_sonido_tool.py roundtrip-todos
"""

from __future__ import annotations

import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIR_SONIDO = os.path.join(RAIZ, "src", "data", "sound")

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import guion_sonido_tool as gst  # noqa: E402  (reutilizado para los 3 "efecto")

# Direcciones reales en memoria (solo informativas, para la cabecera del .txt)
DIRECCIONES = {
    "envolvente_amplitud_1.bin": (0x7FCA, 10),
    "envolvente_amplitud_2.bin": (0x7FD4, 10),
    "envolvente_amplitud_3.bin": (0x7FDE, 7),
    "envolvente_tono_1.bin": (0x7FE5, 16),
    "envolvente_tono_2.bin": (0x7FF5, 4),
    "envolvente_tono_3.bin": (0x7FF9, 7),
    "sonido_perder_vida.bin": (0x8000, 9),
    "sonido_tesoro.bin": (0x8009, 9),
    "sonido_objeto_encontrado.bin": (0x8012, 9),
}

# Mapa efecto -> (ENV/ENT) -> ficheros de envolvente que referencia (solo
# informativo, para comentarios en el .txt del efecto; ver FINDINGS Sesion 24)
ENVOLVENTES_POR_EFECTO = {
    "sonido_perder_vida.bin": (1, "envolvente_amplitud_1.bin", "envolvente_tono_1.bin"),
    "sonido_tesoro.bin": (2, "envolvente_amplitud_2.bin", "envolvente_tono_2.bin"),
    "sonido_objeto_encontrado.bin": (3, "envolvente_amplitud_3.bin", "envolvente_tono_3.bin"),
}

TODOS_LOS_FICHEROS = list(DIRECCIONES.keys())


def tipo_de_fichero(nombre: str) -> str:
    base = os.path.basename(nombre).lower()
    if "amplitud" in base:
        return "amplitud"
    if "tono" in base:
        return "tono"
    if base.startswith("sonido_"):
        return "efecto"
    raise ValueError(f"no se reconoce el tipo de {nombre!r} (se esperaba 'amplitud', 'tono' o 'sonido_*')")


def _signed8(b: int) -> int:
    return b - 256 if b >= 128 else b


def _unsigned8(v: int) -> int:
    return v & 0xFF


# ============================================================
# Envolvente de AMPLITUD
# ============================================================

def decodificar_amplitud(datos: bytes, nombre: str = "") -> str:
    if len(datos) < 1:
        raise ValueError("fichero de envolvente de amplitud vacio")
    cabecera = datos[0]
    hw = bool(cabecera & 0x80)
    num_pasos = cabecera & 0x7F
    cuerpo = datos[1:]
    if len(cuerpo) != num_pasos * 3:
        raise ValueError(
            f"cabecera declara {num_pasos} pasos ({num_pasos * 3} bytes), "
            f"pero quedan {len(cuerpo)} bytes tras la cabecera"
        )

    lineas = [
        f"; {nombre or 'ENVOLVENTE DE AMPLITUD'} -- envolvente de volumen (SOUND_SET_ENV, firmware $BCBC)",
        "; Fuente del formato: https://oldwiki.cpcwiki.eu/index.php/BIOS_Sound_Functions",
        "; cabecera: tipo=software|hardware, pasos=numero de pasos de 3 bytes.",
        "; paso software: reps=repeticiones ($01-$7F; $00 visto en datos reales,",
        "; caso ESPECIAL/ambiguo, se preserva tal cual -- ver docstring del modulo),",
        "; incr=incremento de volumen con signo por repeticion, dur=duracion de",
        "; cada repeticion en centesimas de segundo (y su equivalente en segundos).",
        "; paso hardware: forma=forma de envolvente HW (0-15), frecuencia=frecuencia HW (0-65535).",
        f"cabecera tipo={'hardware' if hw else 'software'} pasos={num_pasos}  ; {cabecera:02X}",
    ]
    for i in range(num_pasos):
        b0, b1, b2 = cuerpo[i * 3], cuerpo[i * 3 + 1], cuerpo[i * 3 + 2]
        hexraw = f"{b0:02X} {b1:02X} {b2:02X}"
        if hw:
            forma = b0 & 0x7F
            freq = (b1 << 8) | b2
            lineas.append(f"paso {i + 1} tipo=hardware forma={forma} frecuencia={freq}  ; {hexraw}")
        else:
            reps = b0
            incr = _signed8(b1)
            dur_cs = 256 if b2 == 0 else b2
            nota = " (ESPECIAL: reps=0, fuera del rango $01-$7F documentado, significado sin confirmar)" if reps == 0 else ""
            signo = "+" if incr >= 0 else ""
            lineas.append(
                f"paso {i + 1} reps={reps} incr={signo}{incr} dur={dur_cs}cs({dur_cs / 100:.2f}s)"
                f"  ; {hexraw}{nota}"
            )
    return "\n".join(lineas) + "\n"


def codificar_amplitud(texto: str) -> bytes:
    lineas = [l.split(";", 1)[0].strip() for l in texto.splitlines()]
    lineas = [l for l in lineas if l]

    cab_lineas = [l for l in lineas if l.startswith("cabecera")]
    if len(cab_lineas) != 1:
        raise ValueError(f"se esperaba exactamente 1 linea 'cabecera', se encontraron {len(cab_lineas)}")
    campos_cab = dict(tok.split("=", 1) for tok in cab_lineas[0].split()[1:])
    hw = campos_cab["tipo"] == "hardware"
    num_pasos = int(campos_cab["pasos"])

    pasos_lineas = [l for l in lineas if l.startswith("paso")]
    if len(pasos_lineas) != num_pasos:
        raise ValueError(f"cabecera declara {num_pasos} pasos, se encontraron {len(pasos_lineas)} lineas 'paso'")

    datos = bytearray([(0x80 if hw else 0) | num_pasos])
    for linea in pasos_lineas:
        tokens = linea.split()[2:]  # se salta "paso" "N"
        campos = dict(tok.split("=", 1) for tok in tokens)
        if hw:
            forma = int(campos["forma"])
            freq = int(campos["frecuencia"])
            datos += bytes([0x80 | (forma & 0x7F), (freq >> 8) & 0xFF, freq & 0xFF])
        else:
            reps = int(campos["reps"])
            incr = int(campos["incr"])
            m = re.match(r"^(\d+)cs", campos["dur"])
            if not m:
                raise ValueError(f"campo dur invalido: {campos['dur']!r}")
            dur_cs = int(m.group(1))
            dur_raw = 0 if dur_cs == 256 else dur_cs
            datos += bytes([_unsigned8(reps), _unsigned8(incr), _unsigned8(dur_raw)])
    return bytes(datos)


# ============================================================
# Envolvente de TONO
# ============================================================

def decodificar_tono(datos: bytes, nombre: str = "") -> str:
    if len(datos) < 1:
        raise ValueError("fichero de envolvente de tono vacio")
    cabecera = datos[0]
    hw = bool(cabecera & 0x80)
    repetir = bool(cabecera & 0x40)
    num_pasos = cabecera & 0x3F
    cuerpo = datos[1:]
    if len(cuerpo) != num_pasos * 3:
        raise ValueError(
            f"cabecera declara {num_pasos} pasos ({num_pasos * 3} bytes), "
            f"pero quedan {len(cuerpo)} bytes tras la cabecera"
        )

    lineas = [
        f"; {nombre or 'ENVOLVENTE DE TONO'} -- envolvente de tono (SOUND_SET_ENT, firmware $BCBF)",
        "; Fuente del formato: https://oldwiki.cpcwiki.eu/index.php/BIOS_Sound_Functions",
        "; cabecera: tipo=software|hardware, repetir=SI|NO (repite toda la envolvente),",
        "; pasos=numero de pasos de 3 bytes.",
        "; paso software modo=relativo: reps=repeticiones ($01-$EF), incr=incremento",
        "; de PERIODO de tono con signo por repeticion, dur=duracion en cs.",
        "; paso software modo=directo: periodo=periodo de tono absoluto de 12 bits",
        "; (frecuencia_Hz=125000/periodo), dur=duracion en cs.",
        "; paso hardware: igual que en amplitud (forma/frecuencia) -- no visto en datos reales.",
        f"cabecera tipo={'hardware' if hw else 'software'} repetir={'SI' if repetir else 'NO'} pasos={num_pasos}"
        f"  ; {cabecera:02X}",
    ]
    for i in range(num_pasos):
        b0, b1, b2 = cuerpo[i * 3], cuerpo[i * 3 + 1], cuerpo[i * 3 + 2]
        hexraw = f"{b0:02X} {b1:02X} {b2:02X}"
        if hw:
            forma = b0 & 0x7F
            freq = (b1 << 8) | b2
            lineas.append(f"paso {i + 1} tipo=hardware forma={forma} frecuencia={freq}  ; {hexraw}")
        elif b0 >= 0xF0:
            nibble = b0 & 0x0F
            periodo = (nibble << 8) | b1
            dur = b2
            freq = gst.periodo_a_frecuencia(periodo)
            lineas.append(
                f"paso {i + 1} modo=directo periodo={periodo} freq={freq:.1f}Hz "
                f"dur={dur}cs({dur / 100:.2f}s)  ; {hexraw}"
            )
        else:
            reps = b0
            incr = _signed8(b1)
            dur = b2
            signo = "+" if incr >= 0 else ""
            lineas.append(
                f"paso {i + 1} modo=relativo reps={reps} incr={signo}{incr} "
                f"dur={dur}cs({dur / 100:.2f}s)  ; {hexraw}"
            )
    return "\n".join(lineas) + "\n"


def codificar_tono(texto: str) -> bytes:
    lineas = [l.split(";", 1)[0].strip() for l in texto.splitlines()]
    lineas = [l for l in lineas if l]

    cab_lineas = [l for l in lineas if l.startswith("cabecera")]
    if len(cab_lineas) != 1:
        raise ValueError(f"se esperaba exactamente 1 linea 'cabecera', se encontraron {len(cab_lineas)}")
    campos_cab = dict(tok.split("=", 1) for tok in cab_lineas[0].split()[1:])
    hw = campos_cab["tipo"] == "hardware"
    repetir = campos_cab["repetir"] == "SI"
    num_pasos = int(campos_cab["pasos"])

    pasos_lineas = [l for l in lineas if l.startswith("paso")]
    if len(pasos_lineas) != num_pasos:
        raise ValueError(f"cabecera declara {num_pasos} pasos, se encontraron {len(pasos_lineas)} lineas 'paso'")

    datos = bytearray([(0x80 if hw else 0) | (0x40 if repetir else 0) | num_pasos])
    for linea in pasos_lineas:
        tokens = linea.split()[2:]  # se salta "paso" "N"
        campos = dict(tok.split("=", 1) for tok in tokens)
        if hw:
            forma = int(campos["forma"])
            freq = int(campos["frecuencia"])
            datos += bytes([0x80 | (forma & 0x7F), (freq >> 8) & 0xFF, freq & 0xFF])
        elif campos.get("modo") == "directo":
            periodo = int(campos["periodo"])
            m = re.match(r"^(\d+)cs", campos["dur"])
            if not m:
                raise ValueError(f"campo dur invalido: {campos['dur']!r}")
            dur = int(m.group(1))
            nibble = (periodo >> 8) & 0x0F
            datos += bytes([0xF0 | nibble, periodo & 0xFF, dur & 0xFF])
        else:
            reps = int(campos["reps"])
            incr = int(campos["incr"])
            m = re.match(r"^(\d+)cs", campos["dur"])
            if not m:
                raise ValueError(f"campo dur invalido: {campos['dur']!r}")
            dur = int(m.group(1))
            datos += bytes([_unsigned8(reps), _unsigned8(incr), _unsigned8(dur)])
    return bytes(datos)


# ============================================================
# Efecto puntual (bloque SOUND QUEUE de 9 bytes, reutiliza guion_sonido_tool)
# ============================================================

def decodificar_efecto(datos: bytes, nombre: str = "") -> str:
    if len(datos) != gst.TAM_REGISTRO:
        raise ValueError(f"se esperaban {gst.TAM_REGISTRO} bytes, llegaron {len(datos)}")
    info = ENVOLVENTES_POR_EFECTO.get(nombre)
    lineas = [
        f"; {nombre or 'EFECTO DE SONIDO'} -- bloque SOUND QUEUE de 9 bytes (firmware CPC,",
        "; mismo formato que GUION_SONIDO_CIRCULAR -- ver guion_sonido_tool.py / FINDINGS",
        "; Sesion 23/24). frecuencia_Hz = 125000/periodo.",
    ]
    if info:
        num, fich_ampl, fich_tono = info
        lineas.append(
            f"; env={num} -> {fich_ampl} ; ent={num} -> {fich_tono} "
            "(referenciadas por numero, no por direccion -- ver FINDINGS Sesion 24)"
        )
    lineas.append(gst.decodificar_registro(0, datos))
    return "\n".join(lineas) + "\n"


def codificar_efecto(texto: str) -> bytes:
    for linea in texto.splitlines():
        sin_comentario = linea.split(";", 1)[0].strip()
        if sin_comentario:
            return gst.codificar_linea(linea)
    raise ValueError("no se encontro ninguna linea de datos (todo son comentarios/vacio)")


# ============================================================
# Despacho generico por tipo de fichero
# ============================================================

def decodificar(datos: bytes, nombre: str) -> str:
    tipo = tipo_de_fichero(nombre)
    if tipo == "amplitud":
        return decodificar_amplitud(datos, os.path.basename(nombre))
    if tipo == "tono":
        return decodificar_tono(datos, os.path.basename(nombre))
    return decodificar_efecto(datos, os.path.basename(nombre))


def codificar(texto: str, nombre: str) -> bytes:
    tipo = tipo_de_fichero(nombre)
    if tipo == "amplitud":
        return codificar_amplitud(texto)
    if tipo == "tono":
        return codificar_tono(texto)
    return codificar_efecto(texto)


# ============================================================
# CLI
# ============================================================

def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    modo = sys.argv[1]

    if modo == "decodificar":
        if len(sys.argv) < 3:
            raise SystemExit("Uso: python tools/envolvente_sonido_tool.py decodificar <origen.bin> [salida.txt]")
        origen = sys.argv[2]
        salida = sys.argv[3] if len(sys.argv) > 3 else None
        with open(origen, "rb") as f:
            datos = f.read()
        texto = decodificar(datos, origen)
        if salida:
            with open(salida, "w", encoding="utf-8") as f:
                f.write(texto)
            print(f"Escrito {salida}")
        else:
            print(texto)

    elif modo == "codificar":
        if len(sys.argv) < 4:
            raise SystemExit("Uso: python tools/envolvente_sonido_tool.py codificar <entrada.txt> <salida.bin>")
        entrada, salida = sys.argv[2], sys.argv[3]
        with open(entrada, "r", encoding="utf-8") as f:
            texto = f.read()
        datos = codificar(texto, salida if salida else entrada)
        with open(salida, "wb") as f:
            f.write(datos)
        print(f"Escrito {salida} ({len(datos)} bytes)")

    elif modo == "roundtrip":
        origen = sys.argv[2] if len(sys.argv) > 2 else None
        if not origen:
            raise SystemExit("Uso: python tools/envolvente_sonido_tool.py roundtrip <origen.bin>")
        with open(origen, "rb") as f:
            original = f.read()
        texto = decodificar(original, origen)
        reconstruido = codificar(texto, origen)
        if original == reconstruido:
            print(f"  [OK] {os.path.basename(origen)}: roundtrip {len(original)} bytes, 0 diferencias")
        else:
            diffs = [i for i in range(min(len(original), len(reconstruido))) if original[i] != reconstruido[i]]
            print(f"  [FALLO] {os.path.basename(origen)}: {len(diffs)} diferencias "
                  f"(original {len(original)}B, reconstruido {len(reconstruido)}B)")
            for i in diffs[:10]:
                print(f"      offset {i:#04x}: original={original[i]:#04x} reconstruido={reconstruido[i]:#04x}")
            raise SystemExit(1)

    elif modo == "roundtrip-todos":
        fallos = 0
        for nombre in TODOS_LOS_FICHEROS:
            ruta = os.path.join(DIR_SONIDO, nombre)
            with open(ruta, "rb") as f:
                original = f.read()
            texto = decodificar(original, ruta)
            reconstruido = codificar(texto, ruta)
            if original == reconstruido:
                print(f"  [OK] {nombre}: roundtrip {len(original)} bytes, 0 diferencias")
            else:
                diffs = sum(1 for a, b in zip(original, reconstruido) if a != b)
                print(f"  [FALLO] {nombre}: {diffs} diferencias")
                fallos += 1
        if fallos:
            raise SystemExit(1)

    else:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main()
