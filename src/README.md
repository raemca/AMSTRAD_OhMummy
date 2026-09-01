# Oh Mummy — proyecto de reconstrucción (Amstrad CPC)

*Ingeniería inversa, análisis y documentación: Rafael Eduardo Martín Candial (raemca@hotmail.com)*

Reconstrucción por ingeniería inversa de la versión de disco (`.dsk`)
de *Oh Mummy* (Amsoft, 1984; desarrollado por **Gem Software**, ver
`../AVISO-LEGAL.md`). Ver `../FINDINGS.md` para el diario de
descubrimientos completo, sesión a sesión.

## Estado

**`MUMMY.BAS` (cargador) — reconstruido y verificado byte a byte.**
`load_disk/mummy_bas.bas` es el BASIC detokenizado a texto editable
con `tools/amsdos_basic_tool.py`; `py tools/build_all.py` lo vuelve a
tokenizar y compara contra el original — **0 diferencias** (2564
bytes, cabecera AMSDOS incluida). Dibuja a mano el logo "AMSOFT", el
título "Oh Mummy" (efecto de partículas vía `TEST()`), el crédito
"PRESENTS 1984 GEM SOFTWARE" y "LOADING......", y termina con
`MEMORY 15000:LOAD"!mummy1",&6000:CALL &6000` — de ahí sale la
dirección de carga y ejecución real del motor.

**`MUMMY1.BIN` (motor) — carga en `$6000`, longitud real 13190 bytes
($3386, hasta `$9385`).** Estado por tramos:

- **`$6000`-`$6400`** (1025 bytes): desensamblado a mano con
  `tools/z80_disasm.py`, en `mummy1_body.asm`. **Verificado**: al
  compilar con SjASMPlus reproduce exactamente los mismos bytes que el
  binario original en ese rango. Es una reconstrucción **mecánica**
  (primera pasada): llama repetidamente a rutinas fijas del firmware
  del CPC (`$BBxx`/`$BCxx`/`$BDxx`) y a subrutinas internas (`$78xx`,
  `$7Dxx`, `$7Exx`, `$7Bxx`) sin identificar todavía; nada tiene
  nombre semántico aún, ni se ha confirmado con certeza qué es cada
  cosa (ver "Pendiente" en `../FINDINGS.md`).
- **`$6401`-`$9385`** (12165 bytes): sin analizar. Incluido tal cual
  con `INCBIN "data/mummy1_resto_sin_analizar.bin"` en
  `mummy1_body.asm` para que la compilación reproduzca el binario
  completo byte a byte mientras se va desensamblando de verdad, sesión
  a sesión.

## Compilar y verificar

```
py tools/build_all.py
```

Ensambla `main.asm` con SjASMPlus → `build/mummy1.bin`, tokeniza
`load_disk/mummy_bas.bas` → `build/mummy.bas`, y compara ambos byte a
byte contra lo extraído del `.dsk` original
(`FISICO/extraido/MUMMY1.BIN` y `MUMMY.BAS`). Hoy: **0 diferencias en
los dos**.

## Estructura

- `main.asm` — punto de entrada único de compilación (`ORG $6000`,
  `INCLUDE mummy1_body.asm`, `SAVEBIN`).
- `mummy1_body.asm` — el motor: cabecera desensamblada a mano +
  `INCBIN` del resto sin analizar.
- `load_disk/mummy_bas.bas` — el cargador BASIC, detokenizado.
- `data/` — recursos ya identificados y extraídos a fichero individual
  (`img/`, `niveles/`, `sound/`, todos vacíos por ahora) y
  `mummy1_resto_sin_analizar.bin` (el tramo del motor pendiente).
- `build/` — binarios compilados (gitignored).

## Convenciones

- **Nombres descriptivos en español**, no inglés ni abreviaturas
  crípticas — ver `.github/CONTRIBUTING.md` para el detalle completo y
  la disciplina de verificación byte a byte. Todavía no aplica: el
  único tramo desensamblado (`$6000`-`$6400`) sigue sin nombres
  semánticos (reconstrucción mecánica de primera pasada).
- No se comparte nombrado con los proyectos hermanos de MSX/Spectrum:
  *Oh Mummy* no tiene relación de código con *Mad Mix Game* (juegos
  distintos, plataformas distintas) — solo coincide el género (laberinto/
  arcade). Los nombres se deciden por lo que la rutina hace en este
  binario concreto.
- Cuando un dato de la cabecera AMSDOS o del propio binario admite
  varias interpretaciones, se verifica contra el código que lo usa de
  verdad (p. ej. el `CALL &6000` de `mummy_bas.bas`) antes de darlo
  por bueno — no se confía en una tabla recordada de memoria sin
  contrastar (ver `../FINDINGS.md`, Sesión 1 y 2).
