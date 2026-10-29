"""Sintetizador en Python para los 9 ficheros de `src/data/sound/` que NO
son `GUION_SONIDO_CIRCULAR` (la musica, ya cubierta por
`guion_sonido_player.py`): las 6 envolventes sueltas (`envolvente_amplitud_
1/2/3.bin`, `envolvente_tono_1/2/3.bin`) y los 3 efectos puntuales
(`sonido_perder_vida.bin`, `sonido_tesoro.bin`, `sonido_objeto_
encontrado.bin`). Genera `.wav` -- igual que el otro reproductor, este
entorno no tiene salida de audio en vivo.

================================================================
1) Demo de una envolvente SUELTA (6 ficheros envolvente_*.bin)
================================================================
Una envolvente sola no "suena" sin una base de tono/volumen de
referencia (ver docstring de `envolvente_sonido_tool.py`). Para poder
ESCUCHAR LA FORMA de forma aislada, aqui se aplica:

    - Envolvente de AMPLITUD: tono de referencia constante A4 = 440 Hz
      (periodo=round(125000/440)=284) durante toda la curva de volumen.
      Eleccion arbitraria pero documentada: una nota central, reconocible,
      que no sesga la interpretacion de los datos del juego.
    - Envolvente de TONO: volumen de referencia constante = 10/15
      (moderado, audible sin distorsionar) durante todo el barrido de
      tono. El periodo INICIAL para los pasos "modo=relativo" que
      empiezan sin un paso "modo=directo" previo (caso de
      envolvente_tono_2) se fija tambien en 284 (A4), igual que la
      amplitud, por consistencia.
    - Cada demo se repite 3 veces consecutivas (REPETICIONES_DEMO) solo
      para que la forma se perciba mejor al escucharla -- NO es un dato
      real extraido del juego, se documenta aqui explicitamente.

====================================================================
2) Efectos puntuales REALES (3 ficheros sonido_*.bin) -- lo importante
====================================================================
Aqui SI se renderiza el sonido real: se combina el registro `SOUND
QUEUE` de 9 bytes (canal/env/ent/tono/vol/ruido/dur) con la envolvente
de amplitud Y la de tono que referencia por numero (ENV/ENT, ver tabla
FINDINGS.md Sesion 24). El volumen y/o el tono EVOLUCIONAN segun la
envolvente, no son estaticos.

HIPOTESIS DE RENDERIZADO (NO CONFIRMADA EN EMULADOR -- ver FINDINGS.md
Sesion 25 y la pendiente ya abierta en la Sesion 24):

    a) El campo "duracion" del registro SOUND QUEUE es NEGATIVO en los
       3 efectos (-6, 0, -4). La hipotesis de la Sesion 24, usada aqui
       tal cual pide el usuario, es "duracion negativa = repetir la
       envolvente -duracion veces". Se usa N = abs(dur) si dur < 0;
       para TESORO, dur=0 (no es negativo), y aqui se asume N=1 (una
       sola pasada) como caso por defecto -- esto es una asuncion
       ADICIONAL de este modulo, no la hipotesis original de la
       Sesion 24, que solo cubria el caso negativo.
    b) La envolvente de AMPLITUD y la de TONO se repiten CADA UNA por
       su cuenta N veces (no se sincronizan entre si): se expande cada
       envolvente a una secuencia de "unidades de 1cs" para una pasada,
       y esa secuencia se concatena N veces. Como ambas envolventes
       pueden tener duraciones de una pasada distintas, la mas CORTA se
       sostiene (mantiene su ultimo valor) hasta que la mas LARGA
       termine -- eleccion de implementacion razonable, tampoco
       confirmada.
    c) El valor de "reps=0" en un paso de amplitud (caso especial, ver
       `envolvente_sonido_tool.py`) se trata como reps=1 al expandir.
    d) El valor inicial de volumen para la envolvente de amplitud es el
       campo `vol` del propio registro SOUND QUEUE (0 en los 3 casos).
       El valor inicial de PERIODO para la envolvente de tono es el
       campo `nota`/periodo del propio registro SOUND QUEUE: esto
       importa solo para TESORO (periodo=100), cuya envolvente de tono
       (envolvente_tono_2) consta de UN SOLO paso "modo=relativo" (no
       trae su propio periodo base) -- para PERDER_VIDA y OBJETO_
       ENCONTRADO el periodo del registro es 0, pero sus envolventes de
       tono EMPIEZAN con un paso "modo=directo" que fija su propio
       periodo absoluto, asi que el 0 del registro no afecta al
       resultado.

Con estas asunciones, las duraciones resultantes son:
    SONIDO_PERDER_VIDA (N=6):        ~9.00 s  (dominada por la envolvente
        de tono, 5 pasos x 30cs x 6 = 900cs -- nota: esto es mucho mas
        largo que un "efecto" tipico de 1984; se documenta como posible
        señal de que la hipotesis no es exacta, sin resolverlo aqui)
    SONIDO_TESORO (N=1):             ~0.11 s
    SONIDO_OBJETO_ENCONTRADO (N=4):  ~0.44 s

Uso:
    python tools/envolvente_sonido_player.py demo-amplitud <origen.bin|txt> <salida.wav>
    python tools/envolvente_sonido_player.py demo-tono <origen.bin|txt> <salida.wav>
    python tools/envolvente_sonido_player.py render-efecto <efecto.bin|txt> <salida.wav>
    python tools/envolvente_sonido_player.py render-todos [dir_salida]
"""

from __future__ import annotations

import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIR_SONIDO = os.path.join(RAIZ, "src", "data", "sound")

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import guion_sonido_tool as gst  # noqa: E402
import guion_sonido_player as gsp  # noqa: E402
import envolvente_sonido_tool as est  # noqa: E402

FRECUENCIA_MUESTREO = gsp.FRECUENCIA_MUESTREO
AMPLITUD_MAXIMA = gsp.AMPLITUD_MAXIMA

PERIODO_REFERENCIA_A4 = round(125000.0 / 440.0)  # 284, usado como base/demo
VOLUMEN_REFERENCIA_DEMO = 10  # de 0-15, solo para demos de envolvente de tono
REPETICIONES_DEMO = 3  # solo para audibilidad del demo, NO es dato real


# ============================================================
# Expansion de envolventes a secuencias "1 unidad = 1 centesima de segundo"
# ============================================================

def expandir_amplitud_una_pasada(datos_env: bytes, vol_inicial: int) -> list:
    """Devuelve una lista de valores de volumen (0-15), un elemento por
    cada centesima de segundo, para UNA pasada completa de la
    envolvente de amplitud, partiendo de `vol_inicial`."""
    cabecera = datos_env[0]
    if cabecera & 0x80:
        raise ValueError("envolvente de amplitud de hardware: no soportada por el renderizador (no hay casos reales)")
    num_pasos = cabecera & 0x7F
    cuerpo = datos_env[1:]
    vol = vol_inicial
    arr = []
    for i in range(num_pasos):
        b0, b1, b2 = cuerpo[i * 3], cuerpo[i * 3 + 1], cuerpo[i * 3 + 2]
        reps = b0 if b0 > 0 else 1  # reps=0 (caso ESPECIAL): se asume 1 para renderizar
        incr = est._signed8(b1)
        dur_cs = 256 if b2 == 0 else b2
        for _ in range(reps):
            vol = max(0, min(15, vol + incr))
            arr.extend([vol] * dur_cs)
    return arr


def expandir_tono_una_pasada(datos_env: bytes, periodo_inicial: int) -> list:
    """Devuelve una lista de periodos de tono (0 = silencio), un elemento
    por cada centesima de segundo, para UNA pasada completa de la
    envolvente de tono, partiendo de `periodo_inicial` (solo relevante
    si el primer paso es "modo=relativo")."""
    cabecera = datos_env[0]
    if cabecera & 0x80:
        raise ValueError("envolvente de tono de hardware: no soportada por el renderizador (no hay casos reales)")
    num_pasos = cabecera & 0x3F
    cuerpo = datos_env[1:]
    periodo = periodo_inicial
    arr = []
    for i in range(num_pasos):
        b0, b1, b2 = cuerpo[i * 3], cuerpo[i * 3 + 1], cuerpo[i * 3 + 2]
        dur_cs = b2
        if b0 >= 0xF0:
            nibble = b0 & 0x0F
            periodo = (nibble << 8) | b1
            arr.extend([periodo] * dur_cs)
        else:
            reps = b0 if b0 > 0 else 1
            incr = est._signed8(b1)
            for _ in range(reps):
                periodo = max(1, min(4095, periodo + incr))
                arr.extend([periodo] * dur_cs)
    return arr


def _sintetizar(vol_arr: list, periodo_arr: list) -> list:
    """Combina un array de volumen (0-15) y uno de periodo (0=silencio,
    mismo largo), 1 elemento = 1cs, en una lista de muestras PCM float,
    manteniendo la fase de la onda cuadrada continua entre unidades."""
    assert len(vol_arr) == len(periodo_arr)
    muestras = []
    fase = 0.0
    muestras_por_cs = round(FRECUENCIA_MUESTREO / 100.0)
    for vol, periodo in zip(vol_arr, periodo_arr):
        freq = gst.periodo_a_frecuencia(periodo)
        amplitud = AMPLITUD_MAXIMA * gsp.volumen_a_amplitud(vol)
        bloque, fase = gsp.generar_onda_cuadrada(freq, amplitud, muestras_por_cs, fase)
        muestras.extend(bloque)
    return muestras


def _igualar_longitud(a: list, b: list) -> tuple:
    """Alarga el array mas corto repitiendo su ultimo valor, para que
    ambos (volumen/periodo) cubran la misma duracion total."""
    n = max(len(a), len(b))
    if len(a) < n:
        a = a + [a[-1]] * (n - len(a))
    if len(b) < n:
        b = b + [b[-1]] * (n - len(b))
    return a, b


# ============================================================
# 1) Demo de una envolvente suelta
# ============================================================

def demo_amplitud(datos_env: bytes) -> list:
    una_pasada = expandir_amplitud_una_pasada(datos_env, vol_inicial=0)
    vol_arr = una_pasada * REPETICIONES_DEMO
    periodo_arr = [PERIODO_REFERENCIA_A4] * len(vol_arr)
    return _sintetizar(vol_arr, periodo_arr)


def demo_tono(datos_env: bytes) -> list:
    una_pasada = expandir_tono_una_pasada(datos_env, periodo_inicial=PERIODO_REFERENCIA_A4)
    periodo_arr = una_pasada * REPETICIONES_DEMO
    vol_arr = [VOLUMEN_REFERENCIA_DEMO] * len(periodo_arr)
    return _sintetizar(vol_arr, periodo_arr)


# ============================================================
# 2) Efecto puntual real: registro SOUND QUEUE + envolventes
# ============================================================

def _cargar_envolvente(nombre_fichero: str) -> bytes:
    ruta = os.path.join(DIR_SONIDO, nombre_fichero)
    with open(ruta, "rb") as f:
        return f.read()


def render_efecto(registro9: bytes) -> list:
    if len(registro9) != 9:
        raise ValueError(f"se esperaban 9 bytes de registro SOUND QUEUE, llegaron {len(registro9)}")
    env = registro9[1]
    ent = registro9[2]
    periodo_registro = registro9[3] | ((registro9[4] & 0x0F) << 8)
    vol_registro = registro9[6]
    dur = registro9[7] | (registro9[8] << 8)
    if dur >= 32768:
        dur -= 65536

    if dur < 0:
        n = abs(dur)
    elif dur == 0:
        n = 1  # asuncion adicional de este modulo -- ver docstring
    else:
        # caso no esperado en los 3 efectos reales (todos tienen dur<=0 con env/ent!=0);
        # si aparece, se trata simplemente como "sin repeticion de envolvente, dur fija"
        n = 0

    if env == 0 and ent == 0:
        # sin envolvente: comportamiento identico a un registro normal de musica
        return gsp.renderizar_registro(registro9)

    nombre_ampl = f"envolvente_amplitud_{env}.bin" if env else None
    nombre_tono = f"envolvente_tono_{ent}.bin" if ent else None

    if nombre_ampl:
        datos_ampl = _cargar_envolvente(nombre_ampl)
        vol_una_pasada = expandir_amplitud_una_pasada(datos_ampl, vol_inicial=vol_registro)
        vol_arr = vol_una_pasada * max(n, 1)
    else:
        vol_arr = [vol_registro] * round(FRECUENCIA_MUESTREO / 100.0)

    if nombre_tono:
        datos_tono = _cargar_envolvente(nombre_tono)
        periodo_una_pasada = expandir_tono_una_pasada(datos_tono, periodo_inicial=periodo_registro)
        periodo_arr = periodo_una_pasada * max(n, 1)
    else:
        periodo_arr = [periodo_registro] * round(FRECUENCIA_MUESTREO / 100.0)

    vol_arr, periodo_arr = _igualar_longitud(vol_arr, periodo_arr)
    return _sintetizar(vol_arr, periodo_arr)


# ============================================================
# Carga de origen (.bin crudo o .txt editable) y CLI
# ============================================================

def _cargar_bytes(ruta: str, tipo_esperado: str) -> bytes:
    if ruta.lower().endswith(".txt"):
        with open(ruta, "r", encoding="utf-8") as f:
            texto = f.read()
        return est.codificar(texto, ruta)
    with open(ruta, "rb") as f:
        return f.read()


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    modo = sys.argv[1]

    if modo == "demo-amplitud":
        if len(sys.argv) < 4:
            raise SystemExit("Uso: python tools/envolvente_sonido_player.py demo-amplitud <origen.bin|txt> <salida.wav>")
        origen, salida = sys.argv[2], sys.argv[3]
        datos = _cargar_bytes(origen, "amplitud")
        muestras = demo_amplitud(datos)
        gsp.escribir_wav(salida, muestras)
        print(f"Escrito {salida}: {len(muestras)} muestras, {len(muestras) / FRECUENCIA_MUESTREO:.3f} s")

    elif modo == "demo-tono":
        if len(sys.argv) < 4:
            raise SystemExit("Uso: python tools/envolvente_sonido_player.py demo-tono <origen.bin|txt> <salida.wav>")
        origen, salida = sys.argv[2], sys.argv[3]
        datos = _cargar_bytes(origen, "tono")
        muestras = demo_tono(datos)
        gsp.escribir_wav(salida, muestras)
        print(f"Escrito {salida}: {len(muestras)} muestras, {len(muestras) / FRECUENCIA_MUESTREO:.3f} s")

    elif modo == "render-efecto":
        if len(sys.argv) < 4:
            raise SystemExit("Uso: python tools/envolvente_sonido_player.py render-efecto <efecto.bin|txt> <salida.wav>")
        origen, salida = sys.argv[2], sys.argv[3]
        datos = _cargar_bytes(origen, "efecto")
        muestras = render_efecto(datos)
        gsp.escribir_wav(salida, muestras)
        print(f"Escrito {salida}: {len(muestras)} muestras, {len(muestras) / FRECUENCIA_MUESTREO:.3f} s")

    elif modo == "render-todos":
        dir_salida = sys.argv[2] if len(sys.argv) > 2 else DIR_SONIDO
        os.makedirs(dir_salida, exist_ok=True)
        for nombre in ("envolvente_amplitud_1", "envolvente_amplitud_2", "envolvente_amplitud_3"):
            datos = _cargar_bytes(os.path.join(DIR_SONIDO, nombre + ".bin"), "amplitud")
            muestras = demo_amplitud(datos)
            ruta = os.path.join(dir_salida, nombre + ".wav")
            gsp.escribir_wav(ruta, muestras)
            print(f"Escrito {ruta}: {len(muestras) / FRECUENCIA_MUESTREO:.3f} s")
        for nombre in ("envolvente_tono_1", "envolvente_tono_2", "envolvente_tono_3"):
            datos = _cargar_bytes(os.path.join(DIR_SONIDO, nombre + ".bin"), "tono")
            muestras = demo_tono(datos)
            ruta = os.path.join(dir_salida, nombre + ".wav")
            gsp.escribir_wav(ruta, muestras)
            print(f"Escrito {ruta}: {len(muestras) / FRECUENCIA_MUESTREO:.3f} s")
        for nombre in ("sonido_perder_vida", "sonido_tesoro", "sonido_objeto_encontrado"):
            datos = _cargar_bytes(os.path.join(DIR_SONIDO, nombre + ".bin"), "efecto")
            muestras = render_efecto(datos)
            ruta = os.path.join(dir_salida, nombre + ".wav")
            gsp.escribir_wav(ruta, muestras)
            print(f"Escrito {ruta}: {len(muestras) / FRECUENCIA_MUESTREO:.3f} s")

    else:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main()
