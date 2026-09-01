"""Desensamblador Z80 mecanico (sin analisis de flujo): decodifica una
secuencia lineal de bytes instruccion a instruccion, en sintaxis
compatible con SjASMPlus. Cubre el juego de instrucciones completo
documentado (sin prefijo, $CB, $ED, $DD, $FD, $DDCB, $FDCB) usando la
descomposicion clasica de opcodes (x,y,z / p,q) -- ver z80.info
"Decoding Z80 opcodes" (Cristian Dinu).

No hace analisis semantico ni distingue codigo de datos: eso es
trabajo de las sesiones siguientes (ver FINDINGS.md). Cuando un byte
no forma una instruccion valida (o el propio flujo mecanico llega a
zona de datos), decode_one() devuelve None y quien llama debe tratar
ese byte como dato crudo (DB) y avanzar 1 byte.

Uso como libreria:
    from z80_disasm import decode_one
    longitud, texto = decode_one(datos, offset)  # o None si no es valido
"""

from __future__ import annotations

R = ["B", "C", "D", "E", "H", "L", "(HL)", "A"]
RP = ["BC", "DE", "HL", "SP"]
RP2 = ["BC", "DE", "HL", "AF"]
CC = ["NZ", "Z", "NC", "C", "PO", "PE", "P", "M"]
ALU = ["ADD A,", "ADC A,", "SUB ", "SBC A,", "AND ", "XOR ", "OR ", "CP "]
ROT = ["RLC", "RRC", "RL", "RR", "SLA", "SRA", "SLL", "SRL"]


def hx(v: int) -> str:
    return f"${v:02X}"


def hx16(v: int) -> str:
    return f"${v:04X}"


def decode_one(data: bytes, off: int, base_addr: int = 0, ix_iy: str | None = None):
    """Decodifica una instruccion empezando en data[off]. base_addr es
    la direccion Z80 real de data[0] (para que JR/DJNZ muestren la
    direccion de destino real, no un offset dentro del buffer).
    Devuelve (longitud_en_bytes, texto_asm) o None si off esta fuera
    de rango o los bytes no forman una instruccion valida conocida."""
    n = len(data)
    if off >= n:
        return None
    start = off
    op = data[off]
    off += 1

    if op == 0xCB:
        return _decode_cb(data, off, start, base_addr, ix_iy=None)
    if op == 0xED:
        return _decode_ed(data, off, start)
    if op == 0xDD or op == 0xFD:
        if off >= n:
            return None
        reg = "IX" if op == 0xDD else "IY"
        nxt = data[off]
        if nxt == 0xCB:
            return _decode_cb(data, off + 1, start, base_addr, ix_iy=reg)
        if nxt in (0xDD, 0xFD):
            return (off - start, f"DB {hx(op)}  ; prefijo {reg} duplicado, sin efecto")
        res = _decode_main(data, off + 1, start, base_addr, ix_iy=reg)
        return res

    return _decode_main(data, off, start, base_addr, ix_iy=None)


def _rr(idx: int, ix_iy: str | None) -> str:
    """Nombre de registro de 8 bits, sustituyendo H/L por IXh/IXl/IYh/IYl
    cuando hay prefijo activo (excepto para (HL) -> (IX+d), tratado aparte)."""
    if ix_iy and idx == 4:
        return ix_iy + "h"
    if ix_iy and idx == 5:
        return ix_iy + "l"
    return R[idx]


def _decode_main(data: bytes, off: int, start: int, base_addr: int, ix_iy: str | None):
    n = len(data)
    op = data[off - 1]
    x = op >> 6
    y = (op >> 3) & 7
    z = op & 7
    p = y >> 1
    q = y & 1

    def u8():
        nonlocal off
        if off >= n:
            raise IndexError
        v = data[off]
        off += 1
        return v

    def u16():
        nonlocal off
        if off + 1 >= n:
            raise IndexError
        v = data[off] | (data[off + 1] << 8)
        off += 2
        return v

    def disp():
        nonlocal off
        if off >= n:
            raise IndexError
        d = data[off]
        off += 1
        if d >= 128:
            d -= 256
        return d

    def rr8(idx):
        if idx == 6 and ix_iy:
            d = disp()
            sign = "+" if d >= 0 else "-"
            return f"({ix_iy}{sign}{abs(d)})"
        return _rr(idx, ix_iy)

    def rp_name(idx):
        if ix_iy and idx == 2:
            return ix_iy
        return RP[idx]

    try:
        text = None
        if op == 0x00:
            text = "NOP"
        elif op == 0x76:
            text = "HALT"
        elif x == 1:  # LD r,r'  (incluye HALT ya cubierto arriba)
            # Si un operando es (HL)/(IX+d), el OTRO registro es siempre
            # el real H/L (nunca IXh/IXl) -- no se pueden combinar en la
            # misma instruccion (quirk documentado del Z80).
            if z == 6 and y == 6:
                text = "HALT"
            elif y == 6:
                text = f"LD {rr8(y)},{_rr(z, None)}"
            elif z == 6:
                text = f"LD {_rr(y, None)},{rr8(z)}"
            else:
                text = f"LD {rr8(y)},{rr8(z)}"
        elif x == 0:
            if z == 0:
                if y == 0:
                    text = "NOP"
                elif y == 1:
                    text = "EX AF,AF'"
                elif y == 2:
                    d = disp()
                    text = f"DJNZ {hx16(base_addr + off + d)}"
                elif y == 3:
                    d = disp()
                    text = f"JR {hx16(base_addr + off + d)}"
                else:
                    d = disp()
                    text = f"JR {CC[y-4]},{hx16(base_addr + off + d)}"
            elif z == 1:
                if q == 0:
                    v = u16()
                    text = f"LD {rp_name(p)},{hx16(v)}"
                else:
                    text = f"ADD {rp_name(2) if ix_iy else 'HL'},{rp_name(p)}"
            elif z == 2:
                combos = {
                    0: "LD (BC),A", 1: "LD A,(BC)",
                    2: "LD (DE),A", 3: "LD A,(DE)",
                }
                if y in combos:
                    text = combos[y]
                elif y == 4:
                    v = u16()
                    text = f"LD ({hx16(v)}),{rp_name(2)}"
                elif y == 5:
                    v = u16()
                    text = f"LD {rp_name(2)},({hx16(v)})"
                elif y == 6:
                    v = u16()
                    text = f"LD ({hx16(v)}),A"
                elif y == 7:
                    v = u16()
                    text = f"LD A,({hx16(v)})"
            elif z == 3:
                text = f"{'INC' if q == 0 else 'DEC'} {rp_name(p)}"
            elif z == 4:
                text = f"INC {rr8(y)}"
            elif z == 5:
                text = f"DEC {rr8(y)}"
            elif z == 6:
                v = u8()
                text = f"LD {rr8(y)},{hx(v)}"
            elif z == 7:
                text = ["RLCA", "RRCA", "RLA", "RRA", "DAA", "CPL", "SCF", "CCF"][y]
        elif x == 2:  # ALU a,r
            text = f"{ALU[y]}{rr8(z)}"
        elif x == 3:
            if z == 0:
                text = f"RET {CC[y]}"
            elif z == 1:
                if q == 0:
                    text = f"POP {'AF' if p == 3 else rp_name(p)}"
                else:
                    if y == 1:
                        text = "RET"
                    elif y == 3:
                        text = f"EXX"
                    elif y == 5:
                        text = f"JP {rp_name(2)}" if ix_iy else "JP (HL)"
                        if ix_iy:
                            text = f"JP ({ix_iy})"
                    elif y == 7:
                        text = f"LD SP,{rp_name(2)}"
            elif z == 2:
                v = u16()
                text = f"JP {CC[y]},{hx16(v)}"
            elif z == 3:
                if y == 0:
                    v = u16()
                    text = f"JP {hx16(v)}"
                elif y == 1:
                    return None  # $CB, ya interceptado como prefijo antes de llegar aqui
                elif y == 2:
                    v = u8()
                    text = f"OUT ({hx(v)}),A"
                elif y == 3:
                    v = u8()
                    text = f"IN A,({hx(v)})"
                elif y == 4:
                    text = f"EX (SP),{rp_name(2)}"
                elif y == 5:
                    text = "EX DE,HL"
                elif y == 6:
                    text = "DI"
                elif y == 7:
                    text = "EI"
            elif z == 4:
                v = u16()
                text = f"CALL {CC[y]},{hx16(v)}"
            elif z == 5:
                if q == 0:
                    text = f"PUSH {'AF' if p == 3 else (rp_name(2) if p == 2 else RP2[p])}"
                else:
                    if y == 1:
                        v = u16()
                        text = f"CALL {hx16(v)}"
            elif z == 6:
                v = u8()
                text = f"{ALU[y]}{hx(v)}"
            elif z == 7:
                text = f"RST {hx(y*8)}"
        if text is None:
            return None
        return (off - start, text)
    except IndexError:
        return None


def _decode_cb(data: bytes, off: int, start: int, base_addr: int, ix_iy: str | None):
    n = len(data)
    d = None
    if ix_iy:
        if off >= n:
            return None
        d = data[off]
        off += 1
        if d >= 128:
            d -= 256
    if off >= n:
        return None
    op = data[off]
    off += 1
    x = op >> 6
    y = (op >> 3) & 7
    z = op & 7

    if ix_iy:
        sign = "+" if d >= 0 else "-"
        loc = f"({ix_iy}{sign}{abs(d)})"
    else:
        loc = R[z]

    if x == 0:
        text = f"{ROT[y]} {loc}"
    elif x == 1:
        text = f"BIT {y},{loc}"
    elif x == 2:
        text = f"RES {y},{loc}"
    else:
        text = f"SET {y},{loc}"
    if ix_iy and z != 6:
        text += f",{R[z]}"  # forma indocumentada LD r,(IX+d) tras op de bits
    return (off - start, text)


def _decode_ed(data: bytes, off: int, start: int):
    n = len(data)
    if off >= n:
        return None
    op = data[off]
    off += 1
    x = op >> 6
    y = (op >> 3) & 7
    z = op & 7
    p = y >> 1
    q = y & 1

    def u16():
        nonlocal off
        if off + 1 >= n:
            raise IndexError
        v = data[off] | (data[off + 1] << 8)
        off += 2
        return v

    try:
        text = None
        if x == 1:
            if z == 0:
                text = "IN (C)" if y == 6 else f"IN {R[y]},(C)"
            elif z == 1:
                text = "OUT (C),0" if y == 6 else f"OUT (C),{R[y]}"
            elif z == 2:
                text = f"{'ADC' if q else 'SBC'} HL,{RP[p]}"
            elif z == 3:
                v = u16()
                if q == 0:
                    text = f"LD ({hx16(v)}),{RP[p]}"
                else:
                    text = f"LD {RP[p]},({hx16(v)})"
            elif z == 4:
                text = "NEG"
            elif z == 5:
                text = "RETI" if y == 1 else "RETN"
            elif z == 6:
                text = f"IM {[0,0,1,2,0,0,1,2][y]}"
            elif z == 7:
                text = ["LD I,A", "LD R,A", "LD A,I", "LD A,R", "RRD", "RLD", "NOP", "NOP"][y]
        elif x == 2 and z <= 3 and y >= 4:
            names = [
                ["LDI", "CPI", "INI", "OUTI"],
                ["LDD", "CPD", "IND", "OUTD"],
                ["LDIR", "CPIR", "INIR", "OTIR"],
                ["LDDR", "CPDR", "INDR", "OTDR"],
            ]
            text = names[y - 4][z]
        if text is None:
            return None
        return (off - start, text)
    except IndexError:
        return None
