# Prompt para Claude — verificar las direcciones de las losetas de pisadas

## Contexto

Proyecto: **Oh Mummy** para Amstrad CPC.

La tabla `TABLAS_SPRITE_CASILLA` empieza en `$8919` dentro de `MUMMY1.BIN`. El explorador visual `recursos/sprites.html` muestra el bloque en Modo 1 con losetas de `2 bytes x 8 filas`, 16 bytes por loseta.

El usuario ha revisado visualmente las ocho losetas de pisadas y propone esta correspondencia:

| Dirección | Offset desde `$8919` | Interpretación visual propuesta |
|---|---:|---|
| `$89D9` | `+192` | Pisada izquierda hacia arriba |
| `$89E9` | `+208` | Pisada derecha hacia arriba |
| `$8A69` | `+336` | Pisada derecha hacia abajo |
| `$8A79` | `+352` | Pisada izquierda hacia abajo |
| `$89F9` | `+224` | Pisada izquierda hacia la derecha |
| `$8A19` | `+256` | Pisada derecha hacia la derecha |
| `$8A89` | `+368` | Pisada derecha hacia la izquierda |
| `$8AA9` | `+400` | Pisada izquierda hacia la izquierda |

Esta tabla es una **hipótesis visual**. Debe verificarse contra el código fuente reconstruido y no aceptarse solo porque las imágenes parezcan correctas.

Consulta las reglas globales en `prompts/_base_reconstruccion.md`.

## Objetivo

Determinar si el código del juego permite confirmar la orientación y el pie de cada una de las ocho losetas, y dejar documentada únicamente la parte que tenga evidencia suficiente.

No des por demostrado que “izquierda/derecha” significa pie izquierdo/derecho sin averiguar cómo codifica el juego la dirección, el estado de animación y el orden de los pies. Puede que los nombres actuales de las etiquetas estén ordenados por valor de casilla y no por dirección.

## Investigación obligatoria

Lee y contrasta como mínimo:

1. `src/mummy1_body.asm` completo en las zonas relevantes.
2. La rutina `DIBUJAR_CASILLA_MAPA`, incluyendo el valor de la casilla que selecciona cada dirección `LD IY,...`.
3. La rama de `DIBUJAR_ENTIDAD` que escribe las pisadas o modifica las casillas del mapa, especialmente las decisiones basadas en `($8157)` y `($8158)`.
4. `CALCULAR_CASILLA_ADYACENTE` y cualquier rutina que produzca o actualice la dirección de movimiento.
5. Las etiquetas y comentarios de:
   - `LOSETA_MAPA_PISADA_1..8`
   - `LOSETA_PISADAS_VERTICAL_1/_2`
   - las zonas intermedias `$8A09`, `$8A29`, `$8A49` y `$8A99`
6. `FINDINGS.md`, especialmente las entradas sobre las Sesiones 8 y 10.
7. `recursos/sprites.html`, para comprobar que las direcciones y offsets del explorador coinciden con los bytes reales.

## Preguntas que debes resolver

Para cada una de las ocho direcciones propuestas:

1. ¿Qué valor de casilla del mapa provoca que `DIBUJAR_CASILLA_MAPA` seleccione la dirección correspondiente?
2. ¿Qué instrucciones escriben ese valor en el mapa?
3. ¿Qué valor tiene la variable de dirección en cada caso?
4. ¿Existe una convención demostrable para los valores de dirección, por ejemplo arriba, abajo, izquierda y derecha?
5. ¿Qué distingue los dos fotogramas de cada dirección?
6. ¿Puede demostrarse cuál representa el pie izquierdo y cuál el pie derecho, o solo que son dos variantes de pisada?
7. ¿La orientación visual de la imagen coincide con la dirección de movimiento o con la dirección desde la que se observa la casilla?
8. ¿Los saltos de tamaño de las ramas de `DIBUJAR_ENTIDAD` (`2x16`, `4x8`, etc.) cambian la interpretación de la loseta lógica de `2x8` usada por `DIBUJAR_CASILLA_MAPA`?
9. ¿La observación anterior de `$89E7` como posible pie derecho era un desplazamiento visual accidental respecto a la loseta lógica `$89E9`?

## Método de verificación

- Sigue los valores desde el registro o variable de dirección hasta la escritura de la casilla.
- Sigue después el valor almacenado desde `DIBUJAR_CASILLA_MAPA` hasta cada `LD IY`.
- Usa direcciones y bytes concretos del ASM como evidencia.
- Distingue siempre:
  - hecho confirmado por instrucciones o tablas;
  - interpretación geométrica confirmada por la imagen;
  - hipótesis sobre pie izquierdo/derecho o significado jugable.
- No infieras la orientación únicamente por simetría visual.
- No cambies el orden ni los nombres de las etiquetas todavía.
- No muevas ninguna dirección ni byte del ASM.
- Si el código no permite resolver algo, decláralo como pendiente y explica qué evidencia adicional haría falta.

## Verificación independiente de los bytes

Comprueba que cada dirección corresponde a 16 bytes reales de la tabla:

- `$89D9` a `$89E8`
- `$89E9` a `$89F8`
- `$89F9` a `$8A08`
- `$8A19` a `$8A28`
- `$8A69` a `$8A78`
- `$8A79` a `$8A88`
- `$8A89` a `$8A98`
- `$8AA9` a `$8AB8`

Contrasta estos rangos con el `DB` del ASM y con la representación de `recursos/sprites.html`. Ten en cuenta que `$8A09`, `$8A29`, `$8A49` y `$8A99` son zonas intermedias asociadas a otras ramas de escritura y no deben confundirse automáticamente con las ocho losetas de `DIBUJAR_CASILLA_MAPA`.

## Documentación que debes actualizar solo si procede

Si el código confirma la tabla completa o corrige parte de ella:

1. Añade una entrada cronológica en `FINDINGS.md` con:
   - la tabla final dirección/valor/dirección de memoria;
   - las instrucciones que la demuestran;
   - qué parte es visual y qué parte es semántica;
   - el nivel de confianza de cada conclusión;
   - las cuestiones que continúan pendientes.
2. Actualiza los comentarios de `src/mummy1_body.asm` para que no contradigan la evidencia.
3. Actualiza los nombres o notas de `recursos/sprites.html` solo cuando el cambio esté justificado por el código.
4. Si cambia el flujo o el despacho, revisa también `recursos/flujo_detallado.html` y `recursos/flujo_programa.html`.
5. No reescribas README ni documentación no afectada.

Si la verificación no es concluyente, documenta el resultado como hipótesis y no hagas cambios semánticos en el ASM.

## Verificación final

Después de cualquier modificación:

1. Ejecuta `py tools/build_all.py`.
2. Exige `0 diferencias` en `mummy1.bin` y `mummy.bas`.
3. Comprueba que no se han alterado bytes del motor.
4. Revisa que las ocho entradas del HTML siguen apuntando a las direcciones correctas.
5. Presenta un informe breve con:
   - tabla confirmada;
   - tabla todavía hipotética;
   - evidencia ASM usada;
   - archivos modificados;
   - resultado de compilación.

## Resultado esperado

No se busca forzar una confirmación. El resultado válido puede ser:

- confirmar las ocho orientaciones y, si hay evidencia, los pies izquierdo/derecho;
- confirmar solo las ocho losetas y sus valores/direcciones, dejando los pies como hipótesis;
- corregir alguna correspondencia si el código demuestra que la interpretación visual era incorrecta.

La prioridad es que la documentación refleje el comportamiento real del binario y mantenga separadas las pruebas directas de las interpretaciones visuales.
