"""Reproductor/sintetizador en Python de `GUION_SONIDO_CIRCULAR` (la
musica de fondo de Oh Mummy): genera un `.wav` que se puede escuchar
con cualquier reproductor de Windows -- este entorno no tiene salida
de audio en vivo, asi que el flujo es "genera el fichero y escuchalo
tu".

Que es FIEL a la tabla real:
    - El periodo de tono exacto de cada registro -> frecuencia exacta
      (125000/periodo, formula real del firmware de la CPC).
    - El volumen relativo de cada registro (0-15, escalado linealmente
      a amplitud de la onda).
    - La duracion exacta de cada registro (centesimas de segundo).
    - Los silencios (volumen 0 o periodo 0) se reproducen como
      silencio real, no se omiten.
    - Que canal (A/B/C) esta activo en cada registro -- si en algun
      momento hay mas de un canal con nota sonando a la vez (no ocurre
      en esta tabla, que es monofonica por construccion: siempre un
      solo registro activo en cada instante), se mezclarian sumando
      las ondas.

Que es APROXIMADO (el AY-3-8912 real tiene matices que esto no
reproduce):
    - La onda real del AY es cuadrada pero con un escalonado de
      amplitud LOGARITMICO de 16 pasos (el oido humano percibe
      volumen de forma logaritmica); aqui se aproxima con una curva
      simple (ver `VOLUMEN_A_AMPLITUD`), no la tabla exacta del chip.
    - No hay generador de ruido (todos los registros de esta tabla
      tienen ruido=0, asi que no hace falta -- si se usara en otra
      tabla, aqui NO esta implementado).
    - No hay envolventes de hardware (ENV/ENT) -- tampoco se usan en
      esta tabla (siempre 0).
    - No se modela el "DAC glitch"/comportamiento exacto de las
      transiciones de la onda cuadrada real del chip, ni el filtrado
      analogico de la salida de audio real de la CPC.

Uso:
    python tools/guion_sonido_player.py render <origen.bin|asm|txt> <salida.wav>
    python tools/guion_sonido_player.py render-registro <origen> <indice> <salida.wav>
"""

from __future__ import annotations

import math
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import guion_sonido_tool as gst  # noqa: E402

FRECUENCIA_MUESTREO = 44100
AMPLITUD_MAXIMA = 12000  # de 32767, para dejar margen y evitar clipping al mezclar


def volumen_a_amplitud(vol: int) -> float:
    """Aproximacion de la curva de volumen logaritmica del AY-3-8912
    (0-15): 0 = silencio exacto, 15 = amplitud maxima. No es la tabla
    exacta del chip real (ver docstring del modulo)."""
    if vol <= 0:
        return 0.0
    return (2 ** (vol / 15 * math.log2(16)) - 1) / 15.0


def generar_onda_cuadrada(freq: float, amplitud: float, num_muestras: int, fase_inicial: float = 0.0) -> tuple:
    """Devuelve (lista_de_muestras, fase_final) para poder encadenar
    registros consecutivos sin que la onda "salte" de fase de forma
    audible como un clic adicional al ya esperado entre notas."""
    muestras = []
    fase = fase_inicial
    if freq > 0:
        incremento = freq / FRECUENCIA_MUESTREO
        for _ in range(num_muestras):
            muestras.append(amplitud if (fase % 1.0) < 0.5 else -amplitud)
            fase += incremento
    else:
        muestras = [0.0] * num_muestras
    return muestras, fase


def registro_a_bytes9(datos: bytes, i: int) -> bytes:
    return datos[i * gst.TAM_REGISTRO:(i + 1) * gst.TAM_REGISTRO]


def renderizar_registro(b: bytes) -> list:
    """Sintetiza un registro de 9 bytes -> lista de muestras float."""
    periodo = b[3] | ((b[4] & 0x0F) << 8)
    vol = b[6]
    dur = b[7] | (b[8] << 8)
    if dur >= 32768:
        dur -= 65536
    dur = max(dur, 0)  # duracion negativa: sin confirmar su significado, se trata como silencio (ver docstring)

    freq = gst.periodo_a_frecuencia(periodo)
    amplitud = AMPLITUD_MAXIMA * volumen_a_amplitud(vol)
    num_muestras = round(FRECUENCIA_MUESTREO * dur / 100.0)
    muestras, _ = generar_onda_cuadrada(freq, amplitud, num_muestras)
    return muestras


def renderizar(datos: bytes) -> list:
    if len(datos) != gst.TAM_TOTAL:
        raise ValueError(f"se esperaban {gst.TAM_TOTAL} bytes, llegaron {len(datos)}")
    muestras = []
    for i in range(gst.NUM_REGISTROS):
        muestras.extend(renderizar_registro(registro_a_bytes9(datos, i)))
    return muestras


def escribir_wav(ruta: str, muestras: list, frecuencia: int = FRECUENCIA_MUESTREO):
    os.makedirs(os.path.dirname(os.path.abspath(ruta)) or ".", exist_ok=True)
    pcm = bytearray()
    for m in muestras:
        v = max(-32767, min(32767, int(round(m))))
        pcm += struct.pack("<h", v)

    num_canales = 1
    bits_por_muestra = 16
    byte_rate = frecuencia * num_canales * bits_por_muestra // 8
    block_align = num_canales * bits_por_muestra // 8
    data_size = len(pcm)

    with open(ruta, "wb") as f:
        f.write(b"RIFF")
        f.write(struct.pack("<I", 36 + data_size))
        f.write(b"WAVE")
        f.write(b"fmt ")
        f.write(struct.pack("<IHHIIHH", 16, 1, num_canales, frecuencia, byte_rate, block_align, bits_por_muestra))
        f.write(b"data")
        f.write(struct.pack("<I", data_size))
        f.write(bytes(pcm))


def cargar_origen_cualquiera(ruta: str) -> bytes:
    if ruta.lower().endswith(".txt"):
        with open(ruta, "r", encoding="utf-8") as f:
            return gst.codificar(f.read())
    return gst.cargar_origen(ruta)


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    modo = sys.argv[1]

    if modo == "render":
        if len(sys.argv) < 4:
            raise SystemExit("Uso: python tools/guion_sonido_player.py render <origen.bin|asm|txt> <salida.wav>")
        origen, salida = sys.argv[2], sys.argv[3]
        datos = cargar_origen_cualquiera(origen)
        muestras = renderizar(datos)
        escribir_wav(salida, muestras)
        duracion_s = len(muestras) / FRECUENCIA_MUESTREO
        print(f"Escrito {salida}: {len(muestras)} muestras, {duracion_s:.2f} s a {FRECUENCIA_MUESTREO} Hz")

    elif modo == "render-registro":
        if len(sys.argv) < 5:
            raise SystemExit("Uso: python tools/guion_sonido_player.py render-registro <origen> <indice> <salida.wav>")
        origen, indice, salida = sys.argv[2], int(sys.argv[3]), sys.argv[4]
        datos = cargar_origen_cualquiera(origen)
        muestras = renderizar_registro(registro_a_bytes9(datos, indice))
        escribir_wav(salida, muestras)
        print(f"Escrito {salida}: registro {indice}, {len(muestras)} muestras, {len(muestras) / FRECUENCIA_MUESTREO:.3f} s")

    else:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main()
