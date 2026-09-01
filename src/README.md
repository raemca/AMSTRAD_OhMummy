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
  binario original en ese rango. Las 12 rutinas de firmware que llama
  están identificadas y nombradas (`EQU`, ver Sesión 3 en
  `../FINDINGS.md`) y se llama a ellas por su nombre real en este
  tramo. Este tramo en sí sigue sin nombres semánticos propios
  (reconstrucción mecánica de primera pasada, solo llama a otras
  rutinas ya nombradas).
- **`$6401`-`$9385`** (12165 bytes originalmente): **26 subrutinas
  (1539 bytes, el 12.7% del motor) ya están reconstruidas con nombre
  funcional real**, formando un único bloque contiguo de 1401 bytes
  (`$78D1`-`$7DE4`, cerrado en la Sesión 6) más el bloque de la Sesión 3
  (`$7E73`-`$7EFC`) — `GENERAR_ALEATORIO`, `ACTUALIZAR_SECUENCIA_SONIDO`,
  `HAY_COLISION`, `DIBUJAR_ENTIDAD` (dispatcher de sprites)... (lista
  completa más abajo). **Todos los nombres son provisionales**, cada
  uno con su hipótesis y nivel de confianza en un comentario junto a
  la etiqueta — ninguno verificado ejecutando el juego en un emulador
  (ver `prompts/_base_reconstruccion.md`, reglas globales desde la
  Sesión 6). El resto (10626 bytes, en 5 huecos entre las rutinas ya
  reconstruidas) sigue sin analizar, incluido tal cual con varios
  `INCBIN "data/mummy1_resto_sin_analizar.bin", offset, longitud` —
  el offset/longitud de cada hueco se calcula automáticamente (no a
  mano) para que la compilación siga reproduciendo el binario completo
  byte a byte mientras se va desensamblando de verdad, sesión a
  sesión.

### Rutinas reconstruidas (nombres provisionales, Sesiones 3-6)

| Etiqueta | Subsistema | Confianza |
|---|---|---|
| `GENERAR_ALEATORIO` / `MEZCLAR_ALEATORIO` | Aleatoriedad — PRNG sembrado con el reloj del sistema | Alta |
| `ACTUALIZAR_SECUENCIA_SONIDO` | Sonido — avanza una tabla CIRCULAR de guion de sonido, encola sonido con el firmware | Alta |
| `CALCULAR_CASILLA_ADYACENTE` / `ELEGIR_DIRECCION_HACIA_OBJETIVO` | Movimiento — celda adyacente y elección de dirección hacia un objetivo | Alta / Media-alta |
| `HAY_COLISION` | Colisiones — entidad-entidad y accesibilidad del mapa (`$8200`, 42 bytes/entrada) | Alta |
| `CONSULTAR_CASILLA_MAPA` | Mapa — acceso a la estructura en `$8200` | Media |
| `INICIALIZAR_ENTIDADES` / `INICIALIZAR_UNA_ENTIDAD` / `COLOCAR_ENTIDAD` | Entidades — posible colocación de 6 enemigos/coleccionables evitando colisión | Media-alta / Media |
| `DIBUJAR_ENTIDAD` | Render — dispatcher de ~20 tablas de sprite 4x16 bytes por tipo+dirección+animación | Media-alta |
| `DIBUJAR_CASILLA_MAPA` | Render — dispatcher de 9 tablas de casilla 2x8 bytes | Media |
| `PREPARAR_DIBUJAR_ENTIDAD` | Render — prepara posición y cae en `DIBUJAR_ENTIDAD` | Media |
| `MOVER_INDICADOR_MENU` | Menú — borra/redibuja un indicador vía `DIBUJAR_ENTIDAD` | Media |
| `DIBUJAR_TRAMO_MARCO_1..4` / `COPIAR_BLOQUE_A_LIENZO` | Pantalla — marco decorativo (6 variantes de máscara) | Media |
| `CASILLA_A_DIRECCION_PANTALLA` | Pantalla — indexa la tabla de 200 direcciones de fila | Alta |
| `BORRAR_BLOQUE_ESTADO` | Arranque — borra 1182 bytes de estado en `$8172` | Alta |
| `BORRAR_RECTANGULO_VENTANA` | Pantalla/HUD — borra un rectángulo vía firmware | Alta |
| `REPETIR_CARACTER` | Texto/HUD — repite un carácter N veces vía firmware | Alta |
| `IMPRIMIR_NUMERO_HL` | HUD — imprime HL como 4 dígitos decimales (posible marcador) | Media-alta |
| `ESPERAR_TECLA_2C` | Entrada — espera una tecla con antirrebote | Alta |
| `ANIMAR_OPCION_MENU` | Menú — anima/temporiza la opción resaltada (1/2 jugadores) | Baja |

Ver `recursos/flujo_programa.html` para el inventario completo por
dirección y `../FINDINGS.md` (Sesiones 3-6) para la evidencia, el
nivel de confianza detallado, y el mapa de llamadas.

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
- `mummy1_body.asm` — el motor: cabecera desensamblada a mano
  (`$6000`-`$6400`) + 26 rutinas reconstruidas con nombre (1539 bytes,
  2 bloques) + `INCBIN` (con offset/longitud) del resto sin analizar.
- `load_disk/mummy_bas.bas` — el cargador BASIC, detokenizado.
- `data/` — recursos ya identificados y extraídos a fichero individual
  (`img/`, `niveles/`, `sound/`, todos vacíos por ahora) y
  `mummy1_resto_sin_analizar.bin` (el tramo del motor pendiente).
- `build/` — binarios compilados (gitignored).

## Convenciones

- **Nombres descriptivos en español**, no inglés ni abreviaturas
  crípticas — ver `.github/CONTRIBUTING.md` para el detalle completo y
  la disciplina de verificación byte a byte. Desde la Sesión 5, los
  nombres se asignan también de forma **provisional** cuando hay una
  hipótesis de función razonable (no solo cuando está confirmada al
  100%), siempre que quede constancia explícita, junto a la etiqueta,
  de que es provisional y de su nivel de confianza — no se retira esa
  marca hasta verificarlo con más seguridad (idealmente en emulador).
  El tramo `$6000`-`$6400` en sí sigue sin nombre propio (solo llama a
  otras rutinas ya nombradas).
- No se comparte nombrado con los proyectos hermanos de MSX/Spectrum:
  *Oh Mummy* no tiene relación de código con *Mad Mix Game* (juegos
  distintos, plataformas distintas) — solo coincide el género (laberinto/
  arcade). Los nombres se deciden por lo que la rutina hace en este
  binario concreto.
- Cuando un dato de la cabecera AMSDOS o del propio binario admite
  varias interpretaciones, se verifica contra el código que lo usa de
  verdad (p. ej. el `CALL &6000` de `mummy_bas.bas`) antes de darlo
  por bueno — no se confía en una tabla recordada de memoria sin
  contrastar (ver `../FINDINGS.md`, Sesiones 1-6).
