"""Detokeniza y (re)tokeniza programas de Locomotive BASIC (Amstrad
CPC) guardados en AMSDOS -- el dialecto y la tabla de tokens son
DISTINTOS de los del ZX Spectrum, así que esta herramienta es propia,
no una adaptación de `zxbasic_tool.py` del proyecto hermano.

Formato de una linea tokenizada en memoria (confirmado contra
MUMMY.BAS real, ver FINDINGS.md):
    offset 0-1: longitud total de la linea (estos 2 bytes incluidos)
    offset 2-3: numero de linea (16 bits LE)
    offset 4..: tokens
    ultimo byte: $00 (fin de linea)
Fin de programa: una "linea" de longitud $0000.

Tabla de tokens (single-byte $80-$FE y prefijo $FF) verificada contra
la documentacion tecnica de Locomotive BASIC (cpctech.cpcwiki.de/docs/bastech.html).

Uso:
    py tools/amsdos_basic_tool.py detokenizar <fichero.bas> [salida.txt]
    py tools/amsdos_basic_tool.py tokenizar <fichero.txt> <cabecera_referencia.bas> <salida.bas>
"""

from __future__ import annotations

import sys

# ============================================================
# Tabla de tokens sin prefijo ($80-$FE)
# ============================================================
TOKENS = {
    0x80: "AFTER", 0x81: "AUTO", 0x82: "BORDER", 0x83: "CALL", 0x84: "CAT",
    0x85: "CHAIN", 0x86: "CLEAR", 0x87: "CLG", 0x88: "CLOSEIN", 0x89: "CLOSEOUT",
    0x8A: "CLS", 0x8B: "CONT", 0x8C: "DATA", 0x8D: "DEF", 0x8E: "DEFINT",
    0x8F: "DEFREAL", 0x90: "DEFSTR", 0x91: "DEG", 0x92: "DELETE", 0x93: "DIM",
    0x94: "DRAW", 0x95: "DRAWR", 0x96: "EDIT", 0x97: "ELSE", 0x98: "END",
    0x99: "ENT", 0x9A: "ENV", 0x9B: "ERASE", 0x9C: "ERROR", 0x9D: "EVERY",
    0x9E: "FOR", 0x9F: "GOSUB", 0xA0: "GOTO", 0xA1: "IF", 0xA2: "INK",
    0xA3: "INPUT", 0xA4: "KEY", 0xA5: "LET", 0xA6: "LINE", 0xA7: "LIST",
    0xA8: "LOAD", 0xA9: "LOCATE", 0xAA: "MEMORY", 0xAB: "MERGE", 0xAC: "MID$",
    0xAD: "MODE", 0xAE: "MOVE", 0xAF: "MOVER", 0xB0: "NEXT", 0xB1: "NEW",
    0xB2: "ON", 0xB3: "ON BREAK", 0xB4: "ON ERROR GOTO", 0xB5: "SQ",
    0xB6: "OPENIN", 0xB7: "OPENOUT", 0xB8: "ORIGIN", 0xB9: "OUT", 0xBA: "PAPER",
    0xBB: "PEN", 0xBC: "PLOT", 0xBD: "PLOTR", 0xBE: "POKE", 0xBF: "PRINT",
    0xC0: "'", 0xC1: "RAD", 0xC2: "RANDOMIZE", 0xC3: "READ", 0xC4: "RELEASE",
    0xC5: "REM", 0xC6: "RENUM", 0xC7: "RESTORE", 0xC8: "RESUME", 0xC9: "RETURN",
    0xCA: "RUN", 0xCB: "SAVE", 0xCC: "SOUND", 0xCD: "SPEED", 0xCE: "STOP",
    0xCF: "SYMBOL", 0xD0: "TAG", 0xD1: "TAGOFF", 0xD2: "TROFF", 0xD3: "TRON",
    0xD4: "WAIT", 0xD5: "WEND", 0xD6: "WHILE", 0xD7: "WIDTH", 0xD8: "WINDOW",
    0xD9: "WRITE", 0xDA: "ZONE", 0xDB: "DI", 0xDC: "EI", 0xDD: "FILL",
    0xDE: "GRAPHICS", 0xDF: "MASK", 0xE0: "FRAME", 0xE1: "CURSOR", 0xE3: "ERL",
    0xE4: "FN", 0xE5: "SPC", 0xE6: "STEP", 0xE7: "SWAP", 0xEA: "TAB",
    0xEB: "THEN", 0xEC: "TO", 0xED: "USING", 0xEE: ">", 0xEF: "=",
    0xF0: ">=", 0xF1: "<", 0xF2: "<>", 0xF3: "<=", 0xF4: "+", 0xF5: "-",
    0xF6: "*", 0xF7: "/", 0xF8: "^", 0xF9: "\\", 0xFA: "AND", 0xFB: "MOD",
    0xFC: "OR", 0xFD: "XOR", 0xFE: "NOT",
}

# ============================================================
# Tabla de tokens con prefijo $FF
# ============================================================
TOKENS_FF = {
    0x00: "ABS", 0x01: "ASC", 0x02: "ATN", 0x03: "CHR$", 0x04: "CINT",
    0x05: "COS", 0x06: "CREAL", 0x07: "EXP", 0x08: "FIX", 0x09: "FRE",
    0x0A: "INKEY", 0x0B: "INP", 0x0C: "INT", 0x0D: "JOY", 0x0E: "LEN",
    0x0F: "LOG", 0x10: "LOG10", 0x11: "LOWER$", 0x12: "PEEK", 0x13: "REMAIN",
    0x14: "SGN", 0x15: "SIN", 0x16: "SPACE$", 0x17: "SQ", 0x18: "SQR",
    0x19: "STR$", 0x1A: "TAN", 0x1B: "UNT", 0x1C: "UPPER$", 0x1D: "VAL",
    0x40: "EOF", 0x41: "ERR", 0x42: "HIMEM", 0x43: "INKEY$", 0x44: "PI",
    0x45: "RND", 0x46: "TIME", 0x47: "XPOS", 0x48: "YPOS", 0x49: "DERR",
    0x71: "BIN$", 0x72: "DEC$", 0x73: "HEX$", 0x74: "INSTR", 0x75: "LEFT$",
    0x76: "MAX", 0x77: "MIN", 0x78: "POS", 0x79: "RIGHT$", 0x7A: "ROUND",
    0x7B: "STRING$", 0x7C: "TEST", 0x7D: "TESTR", 0x7E: "COPYCHR$", 0x7F: "VPOS",
}

DIGIT_TOKENS = {0x0E + i: str(i) for i in range(10)}  # $0E-$17 -> "0".."9"
DIGIT_TOKENS[0x18] = "10"  # $18 -> "10"

# Referencia de variable ($02-$0D): marcador de tipo + puntero cache de
# 2 bytes (siempre $0000 en el fuente tal como se guarda, se rellena
# en tiempo de ejecucion) + nombre, ultimo caracter con el bit 7
# puesto (terminador). $02-$0A llevan sufijo de tipo explicito en el
# LIST, derivado del propio marcador con (marcador XOR $27) AND $FD;
# $0B-$0D (tipo implicito via DEFINT/DEFREAL/DEFSTR) no llevan sufijo.
# Verificado byte a byte contra ROM de BASIC 1.1 (Bread80, Detokenising.asm)
# y contra MUMMY.BAS real -- ver FINDINGS.md.
VAR_MARKER_MIN = 0x02
VAR_MARKER_MAX_SIN_SUFIJO = 0x0D
VAR_MARKER_SIN_SUFIJO_DESDE = 0x0B


def leer_cabecera_amsdos_simple(datos: bytes):
    """Devuelve (tiene_cabecera, longitud_real, direccion_carga) sin
    asumir mas de lo verificado (ver FINDINGS.md Sesion 2): offset 18
    = tipo de fichero, offset 21-22 = direccion de carga, offset 24-25
    = longitud real (verificada porque coincide con la copia
    redundante de offset 64-65), checksum de bytes 0-66 en offset
    67-68."""
    if len(datos) < 128:
        return False, len(datos), None
    h = datos[:128]
    checksum_calc = sum(h[0:67]) % 65536
    checksum_alm = h[67] | (h[68] << 8)
    if checksum_calc != checksum_alm:
        return False, len(datos) - 128, None
    longitud = h[24] | (h[25] << 8)
    carga = h[21] | (h[22] << 8)
    return True, longitud, carga


def detokenize_line(content: bytes) -> str:
    out = []
    i = 0
    n = len(content)
    modo_crudo = False  # tras REM / ' : el resto de la linea es texto literal
    while i < n:
        b = content[i]
        if modo_crudo:
            out.append(chr(b))
            i += 1
            continue
        if b == 0x01:
            out.append(":")
            i += 1
        elif VAR_MARKER_MIN <= b <= VAR_MARKER_MAX_SIN_SUFIJO:
            marcador = b
            i += 3  # marcador + puntero cache de 2 bytes
            nombre = []
            while i < n:
                c = content[i]
                i += 1
                if c & 0x80:
                    nombre.append(chr(c & 0x7F))
                    break
                nombre.append(chr(c))
            if marcador < VAR_MARKER_SIN_SUFIJO_DESDE:
                nombre.append(chr((marcador ^ 0x27) & 0xFD))
            out.append("".join(nombre))
        elif b == 0x22:
            # cadena entre comillas: copiar literal hasta la comilla de cierre o fin de linea
            out.append('"')
            i += 1
            while i < n and content[i] != 0x22:
                out.append(chr(content[i]))
                i += 1
            if i < n:
                out.append('"')
                i += 1
        elif b in DIGIT_TOKENS:
            out.append(DIGIT_TOKENS[b])
            i += 1
        elif b == 0x19:  # entero de 8 bits
            out.append(str(content[i + 1]))
            i += 2
        elif b == 0x1A:  # entero de 16 bits decimal
            out.append(str(content[i + 1] | (content[i + 2] << 8)))
            i += 3
        elif b == 0x1B:  # entero de 16 bits binario
            val = content[i + 1] | (content[i + 2] << 8)
            out.append("&X" + format(val, "016b"))
            i += 3
        elif b == 0x1C:  # entero de 16 bits hexadecimal
            val = content[i + 1] | (content[i + 2] << 8)
            out.append("&" + format(val, "X"))
            i += 3
        elif b == 0x1D:  # puntero de memoria a linea (cache interna), no se imprime
            i += 3
        elif b == 0x1E:  # numero de linea de 16 bits (destino de GOTO/GOSUB/THEN)
            out.append(str(content[i + 1] | (content[i + 2] << 8)))
            i += 3
        elif b == 0x1F:  # valor de coma flotante, 5 bytes -- sin decodificar todavia
            out.append("<FLOAT:" + content[i + 1 : i + 6].hex() + ">")
            i += 6
        elif b == 0xC5 or b == 0xC0 or b == 0x8C:  # REM, ' o DATA: resto de la linea literal
            out.append(TOKENS[b])
            i += 1
            modo_crudo = True
        elif b in TOKENS:
            out.append(TOKENS[b])
            i += 1
        elif b == 0xFF:
            b2 = content[i + 1]
            out.append(TOKENS_FF.get(b2, f"<FF{b2:02X}?>"))
            i += 2
        elif 0x20 <= b <= 0x7E:
            out.append(chr(b))
            i += 1
        else:
            out.append(f"<{b:02X}?>")
            i += 1
    return "".join(out)


def detokenizar(datos: bytes) -> str:
    tiene_cab, longitud, carga = leer_cabecera_amsdos_simple(datos)
    body = datos[128:128 + longitud] if tiene_cab else datos
    lineas_txt = []
    pos = 0
    while pos + 4 <= len(body):
        linelen = body[pos] | (body[pos + 1] << 8)
        if linelen == 0:
            break
        lineno = body[pos + 2] | (body[pos + 3] << 8)
        content = body[pos + 4 : pos + linelen]
        # quitar terminador $00 final si esta incluido en content
        if content.endswith(b"\x00"):
            content = content[:-1]
        lineas_txt.append(f"{lineno} {detokenize_line(content)}")
        pos += linelen
    resto = len(body) - pos
    if resto:
        lineas_txt.append(f"; {resto} bytes sobrantes tras la ultima linea (fin de programa / relleno)")
    return "\n".join(lineas_txt) + "\n"


# ============================================================
# TOKENIZAR (camino inverso) -- reconstruye los bytes tokenizados a
# partir del texto editable que genera detokenizar(). No es un
# tokenizador general de Locomotive BASIC (no hace falta): asume el
# formato de salida de este mismo script (mayusculas = palabra clave,
# minusculas = nombre de variable, DATA/REM/' -> resto de la linea
# literal) -- ver docstring del modulo.
# ============================================================
KEYWORD_TO_TOKEN = sorted(TOKENS.items(), key=lambda kv: -len(kv[1]))
KEYWORD_TO_TOKEN_FF = sorted(TOKENS_FF.items(), key=lambda kv: -len(kv[1]))
OPERADORES = sorted(
    [(v, k) for k, v in TOKENS.items() if v not in ("AND", "MOD", "OR", "XOR", "NOT", "TO", "STEP", "THEN", "USING")],
    key=lambda kv: -len(kv[0]),
)
SUFIJO_A_MARCADOR = {"%": 0x02, "$": 0x03, "!": 0x04}
MARCADOR_IMPLICITO_ENTERO = 0x0B


def tokenize_line(texto: str) -> bytes:
    out = bytearray()
    i = 0
    n = len(texto)
    modo_crudo = False
    siguiente_numero_es_linea = False  # tras GOTO/GOSUB/THEN/RESTORE: token $1E, no el generico
    while i < n:
        c = texto[i]
        if modo_crudo:
            out.append(ord(c))
            i += 1
            continue
        if siguiente_numero_es_linea and c != " " and not c.isdigit():
            siguiente_numero_es_linea = False  # THEN/GOTO/GOSUB/RESTORE no iba seguido de numero de linea
        if c == ":":
            out.append(0x01)
            i += 1
        elif c == '"':
            out.append(0x22)
            i += 1
            while i < n and texto[i] != '"':
                out.append(ord(texto[i]))
                i += 1
            if i < n:
                out.append(0x22)
                i += 1
        elif c.isupper():
            # palabra clave: probar coincidencia mas larga primero
            candidatos = [(kw, tok) for tok, kw in TOKENS.items() if texto.startswith(kw, i)]
            candidatos.sort(key=lambda kv: -len(kv[0]))
            if not candidatos:
                cand_ff = [(kw, tok) for tok, kw in TOKENS_FF.items() if texto.startswith(kw, i)]
                cand_ff.sort(key=lambda kv: -len(kv[0]))
                if not cand_ff:
                    raise ValueError(f"palabra clave desconocida en posicion {i}: {texto[i:i+15]!r}")
                kw, tok = cand_ff[0]
                out.append(0xFF)
                out.append(tok)
                i += len(kw)
            else:
                kw, tok = candidatos[0]
                out.append(tok)
                i += len(kw)
                if tok in (0xC5, 0xC0, 0x8C):  # REM, ', DATA: resto literal
                    modo_crudo = True
                elif tok in (0x8E, 0x8F, 0x90):  # DEFINT/DEFREAL/DEFSTR: rango de letras literal hasta ":" o fin
                    while i < n and texto[i] != ":":
                        out.append(ord(texto[i]))
                        i += 1
                elif tok in (0xA0, 0x9F, 0xEB, 0xC7):  # GOTO/GOSUB/THEN/RESTORE: puede seguir un numero de linea
                    siguiente_numero_es_linea = True
        elif c.islower():
            j = i
            while j < n and (texto[j].islower() or texto[j].isdigit()):
                j += 1
            nombre = texto[i:j]
            sufijo = texto[j] if j < n and texto[j] in SUFIJO_A_MARCADOR else None
            marcador = SUFIJO_A_MARCADOR[sufijo] if sufijo else MARCADOR_IMPLICITO_ENTERO
            out.append(marcador)
            out += b"\x00\x00"  # puntero cache, vacio en el fuente guardado
            for k, ch in enumerate(nombre):
                b = ord(ch)
                if k == len(nombre) - 1:
                    b |= 0x80
                out.append(b)
            i = j + (1 if sufijo else 0)
        elif c == "&":
            if texto[i + 1] == "X":
                val = int(texto[i + 2 : i + 18], 2)
                out.append(0x1B)
                out += val.to_bytes(2, "little")
                i += 18
            else:
                j = i + 1
                while j < n and texto[j] in "0123456789ABCDEF":
                    j += 1
                val = int(texto[i + 1 : j], 16)
                out.append(0x1C)
                out += val.to_bytes(2, "little")
                i = j
        elif c.isdigit():
            j = i
            while j < n and texto[j].isdigit():
                j += 1
            val = int(texto[i:j])
            if siguiente_numero_es_linea:
                out.append(0x1E)
                out += val.to_bytes(2, "little")
                siguiente_numero_es_linea = False
            elif val <= 9:
                out.append(0x0E + val)
            elif val <= 255:
                out.append(0x19)
                out.append(val)
            else:
                out.append(0x1A)
                out += val.to_bytes(2, "little")
            i = j
        else:
            match = next(((op, tok) for op, tok in OPERADORES if texto.startswith(op, i)), None)
            if match:
                op, tok = match
                out.append(tok)
                i += len(op)
                if tok == 0xC0:  # ' (equivalente a REM): resto literal
                    modo_crudo = True
            else:
                out.append(ord(c))
                i += 1
    return bytes(out)


def tokenizar(texto: str, cabecera_original: bytes) -> bytes:
    body = bytearray()
    for linea in texto.splitlines():
        linea = linea.rstrip("\n")
        if not linea.strip() or linea.lstrip().startswith(";"):
            continue
        lineno_str, _, contenido = linea.partition(" ")
        lineno = int(lineno_str)
        tokens = tokenize_line(contenido) + b"\x00"
        linelen = 4 + len(tokens)
        body += linelen.to_bytes(2, "little")
        body += lineno.to_bytes(2, "little")
        body += tokens
    body += b"\x00\x00"  # fin de programa

    h = bytearray(cabecera_original[:128])
    longitud = len(body)
    h[24] = longitud & 0xFF
    h[25] = (longitud >> 8) & 0xFF
    h[64] = longitud & 0xFF
    h[65] = (longitud >> 8) & 0xFF
    checksum = sum(h[0:67]) % 65536
    h[67] = checksum & 0xFF
    h[68] = (checksum >> 8) & 0xFF
    return bytes(h) + bytes(body)


def main():
    if len(sys.argv) < 3 or sys.argv[1] not in ("detokenizar", "tokenizar"):
        raise SystemExit(__doc__)
    modo = sys.argv[1]
    if modo == "detokenizar":
        entrada = sys.argv[2]
        salida = sys.argv[3] if len(sys.argv) > 3 else None
        with open(entrada, "rb") as f:
            datos = f.read()
        tiene_cab, longitud, carga = leer_cabecera_amsdos_simple(datos)
        texto = detokenizar(datos)
        if tiene_cab:
            print(f"Cabecera AMSDOS OK: longitud real={longitud} bytes, direccion de carga=${carga:04X}")
        if salida:
            with open(salida, "w", encoding="utf-8") as f:
                f.write(texto)
            print(f"Escrito {salida}")
        else:
            print(texto)
    else:
        if len(sys.argv) < 5:
            raise SystemExit(
                "Uso: py tools/amsdos_basic_tool.py tokenizar <fichero.txt> <cabecera_referencia.bas> <salida.bas>"
            )
        entrada, ref, salida = sys.argv[2], sys.argv[3], sys.argv[4]
        with open(entrada, "r", encoding="utf-8") as f:
            texto = f.read()
        with open(ref, "rb") as f:
            cabecera_original = f.read()[:128]
        datos = tokenizar(texto, cabecera_original)
        with open(salida, "wb") as f:
            f.write(datos)
        print(f"Escrito {salida} ({len(datos)} bytes)")


if __name__ == "__main__":
    main()
