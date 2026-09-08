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
- **`$6401`-`$6528`** (296 bytes, Sesión 12): reconstruido como código
  — los dos puntos de entrada reales tras la pantalla de "introducir
  nombre" (`FIN_INTRODUCIR_NOMBRE` por caída natural,
  `DESPACHAR_MENU_PRINCIPAL` por el `JP Z` de la cabecera cuando no se
  tecleó nombre) y `PANTALLA_OPCIONES` (pantalla completa de opciones:
  velocidad/dificultad de partida 1-5, música y efectos de sonido
  Y/N).
- **`$6529`-`$68B1`** (905 bytes, Sesión 13): reconstruido como código
  — arranque de partida/nivel (`INICIAR_PARTIDA`/`PREPARAR_NIVEL`),
  colocación de tesoros (`PREPARAR_TESOROS_NIVEL`), HUD de vidas
  (`ACTUALIZAR_HUD_VIDAS`), el llamador de `RELLENAR_MARCO_DIAGONAL_1..6`
  que quedaba pendiente desde la Sesión 7
  (`SELECCIONAR_DIAGONAL_MARCO_NIVEL`), el bucle de juego
  (`BUCLE_PRINCIPAL_JUEGO`), y las pantallas de fin de partida
  (`PANTALLA_STOP_PRESS`/`PANTALLA_GAME_OVER`/
  `ACTUALIZAR_TABLA_PUNTUACIONES`).
- **`$68B2`-`$7862`** (4017 bytes): el único tramo del motor que
  sigue sin analizar (pantalla de instrucciones, entrada `'I'` del
  menú), incluido tal cual con
  `INCBIN "data/mummy1_resto_sin_analizar.bin", 1201, 4017`.
- **`$7863`-`$786B`** (9 bytes, Sesión 13): reconstruido como código —
  `IMPRIMIR_PUNTUACION_HUD`, cierra el último tramo del `INCBIN`
  original, cae directamente en `IMPRIMIR_NUMERO_HL` (`$786C`).
- **`$786C`-`$7EFC`** (1681 bytes, el 12.7% del motor): **38
  subrutinas de código ya reconstruidas con nombre funcional real**,
  en un único bloque contiguo (cerrado en la Sesión 7) —
  `GENERAR_ALEATORIO`, `ACTUALIZAR_SECUENCIA_SONIDO`, `HAY_COLISION`,
  `DIBUJAR_ENTIDAD` (dispatcher de sprites),
  `RELLENAR_MARCO_DIAGONAL_1..6`... (lista completa más abajo).
- **`$7EFD`-`$9385`** (5257 bytes, el resto del motor hasta el
  final): **cerrado por completo en la Sesión 8** como **dato, no
  código** (ningún `CALL`/`JP` ya reconstruido aterriza ahí dentro) —
  35 tablas/textos con nombre, incluyendo el **texto real del juego**
  (menú de opciones, la pantalla "STOP PRESS" del modo atracción, la
  tabla HI-SCORE con sus 5 rangos y umbrales, el menú principal, y el
  copyright `"OH MUMMY" (c) 1984 GEM SOFTWARE`), las 6 envolventes de
  sonido, las 4 tablas del marco decorativo, el guión de sonido
  circular (90 registros de 9 bytes) y varios bloques de estado de
  partida que se limpian en el arranque. Ver `FINDINGS.md` Sesión 8
  para el desglose completo.

**Todos los nombres son provisionales**, cada uno con su hipótesis y
nivel de confianza en un comentario junto a la etiqueta — ninguno
verificado ejecutando el juego en un emulador (ver
`prompts/_base_reconstruccion.md`, reglas globales desde la Sesión 6).
El offset/longitud del único `INCBIN` que queda se calcula
automáticamente (no a mano) para que la compilación siga reproduciendo
el binario completo byte a byte mientras se va desensamblando de
verdad, sesión a sesión.

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
| `RELLENAR_MARCO_MEDIO` / `RELLENAR_MARCO_SOLIDO` / `RELLENAR_MARCO_VACIO` | Marco decorativo — rellena una casilla de 24x10 bytes con una máscara constante ($0F/$FF/$00) | Media |
| `RELLENAR_MARCO_DIAGONAL_1..6` / `RELLENAR_MARCO_DIAGONAL_BUCLE` | Marco decorativo — rellena alternando dos máscaras fila a fila vía código automodificable (Sesión 7: corrige la hipótesis previa "AND/OR", no hay AND ni OR en el bloque) | Media |
| `PREPARAR_RELLENO_MASCARA_UNICA` / `RELLENAR_FILAS_MASCARA` | Marco decorativo — preparadores compartidos del relleno de máscara, reutilizan `CASILLA_A_DIRECCION_PANTALLA` | Alta |

### Rutinas reconstruidas — Sesión 12 (`$6401`-`$6528`)

| Etiqueta | Subsistema | Confianza |
|---|---|---|
| `FIN_INTRODUCIR_NOMBRE` | Menú — entrada por caída natural tras confirmar el nombre con Intro, redirige a `REANUDAR_MENU_TRAS_NOMBRE` | Alta |
| `REANUDAR_MENU_TRAS_NOMBRE` (etiqueta añadida en la cabecera, `$636C`) | Menú — redibuja y decide si seguir tecleando el nombre o pasar al despachador principal | Alta en el flujo, media en el rol visual de `$86E8` |
| `DESPACHAR_MENU_PRINCIPAL` | Menú — lee P/I/O para Play/Instructions/Options | Alta |
| `PANTALLA_OPCIONES` | Menú — velocidad y dificultad de partida (1-5), música y efectos de sonido (Y/N), confirmar con L/Intro | Alta en estructura y variables, baja/media en el efecto visual exacto de los `REPETIR_CARACTER` |

### Rutinas reconstruidas — Sesión 13 (`$6529`-`$68B1` y `$7863`-`$786B`)

| Etiqueta | Subsistema | Confianza |
|---|---|---|
| `INICIAR_PARTIDA` | Partida — entrada real de tecla P/p: vidas=5, puntuación=0 | Alta |
| `PREPARAR_NIVEL` | Partida — reentrada tras completar el juego (L/Intro); nivel=0, ajusta dificultad si hay puntuación previa | Alta en estructura, media en la interpretación de que vidas/puntuación no se reinician a propósito |
| `PREPARAR_TESOROS_NIVEL` | Nivel — coloca 14 tesoros al azar (4 valores crecientes + 10 del valor común) evitando casillas ocupadas | Alta en estructura, media-alta en la interpretación de los valores |
| `ACTUALIZAR_HUD_VIDAS` | HUD — refresca puntuación e imprime un icono de jugador por cada vida restante | Alta |
| `LIMPIAR_PANELES_NIVEL` | Pantalla/HUD — despeja 9 paneles antes de dibujar el nivel | Alta |
| `SELECCIONAR_DIAGONAL_MARCO_NIVEL` | Marco decorativo — **resuelve** el llamador de `RELLENAR_MARCO_DIAGONAL_1..6` (pendiente desde Sesión 7): elige variante según nivel y parchea el operando de un `CALL` automodificado | Alta en estructura, media en el efecto visual |
| `COLOCAR_JUGADOR_INICIAL` | Entidades — coloca enemigos/coleccionables del nivel y dibuja al jugador en su posición de salida | Alta en estructura, media en el detalle de `($8157)` |
| `BUCLE_PRINCIPAL_JUEGO` / `INICIO_TURNO_JUGADOR1` / `TRAMPOLIN_TECLA_B` | Juego — bucle de turnos por jugador; 5 llamadas internas (`$7578`/`$77D1`/`$7637`/`$7566`/`$7513`) siguen sin resolver | Alta en estructura, media en el papel de cada llamada sin resolver |
| `PANTALLA_STOP_PRESS` | Fin de partida — pantalla de "ganar" (completar los 6 niveles): bonus de 200 puntos o vida extra (tope 7); NO consulta la tabla HI-SCORE | Alta |
| `PANTALLA_GAME_OVER` / `ACTUALIZAR_TABLA_PUNTUACIONES` | Fin de partida — pantalla de "morir": título animado + inserción/consulta de la tabla HI-SCORE de 5 entradas | Alta |
| `IMPRIMIR_PUNTUACION_HUD` | HUD — posiciona el cursor y cae en `IMPRIMIR_NUMERO_HL` con la puntuación | Alta |

Ver `recursos/flujo_programa.html` para el inventario completo por
dirección, `recursos/flujo_detallado.html` (Sesión 9) para el **grafo
real de llamadas** (`CALL`/`CALL cc`/`JP`/`JP cc`/`JR`/caídas sin
`RET`, cada una verificada contra el ASM, con panel dedicado a lo que
NO es una llamada directa) y `../FINDINGS.md` (Sesiones 3-9) para la
evidencia y el nivel de confianza detallado. `recursos/flujo_detallado.html`
es el artefacto vivo del flujo de llamadas del proyecto: cada sesión
que cambie una llamada, un punto de entrada, un despachador o el
estado de una rutina debe actualizarlo (o dejar constancia de que no
le afecta), según `prompts/_base_reconstruccion.md`.

## Compilar y verificar

```
py tools/build_all.py
py tools/dsk_build.py
```

El primero ensambla `main.asm` con SjASMPlus → `build/mummy1.bin`,
tokeniza `load_disk/mummy_bas.bas` → `build/mummy.bas`, y compara
ambos byte a byte contra lo extraído del `.dsk` original
(`FISICO/extraido/MUMMY1.BIN` y `MUMMY.BAS`). El segundo reconstruye
el **`.dsk` completo desde cero** (no copia el original salvo ~1600
bytes de contenido sobrante no reconstruible, ver `../FINDINGS.md`
Sesión 7) en `../build/ohmummy_reconstruido.dsk`. Hoy: **0 diferencias
en los tres** (los dos ficheros por separado y el disco completo).

## Estructura

- `main.asm` — punto de entrada único de compilación (`ORG $6000`,
  `INCLUDE mummy1_body.asm`, `SAVEBIN`).
- `mummy1_body.asm` — el motor: cabecera desensamblada a mano
  (`$6000`-`$6400`) + `FIN_INTRODUCIR_NOMBRE`/`DESPACHAR_MENU_PRINCIPAL`/
  `PANTALLA_OPCIONES` (296 bytes, Sesión 12) + `INICIAR_PARTIDA` y el
  resto del arranque/bucle/fin de partida (914 bytes, Sesión 13) +
  rutinas reconstruidas con nombre (Sesiones 3-8) + `INCBIN` (con
  offset/longitud) del resto sin analizar (`$68B2`-`$7862`, 4017
  bytes).
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
