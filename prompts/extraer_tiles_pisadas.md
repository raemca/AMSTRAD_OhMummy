# Prompt para Claude — extraer las losetas de pisadas a `src/data/img/tiles`

## Objetivo

Extraer las ocho losetas de pisadas de `MUMMY1.BIN` a un fichero dentro de:

```text
src/data/img/tiles/
```

El fichero debe ser un recurso de reconstrucción legible, trazable y verificable byte a byte. No basta con copiar una captura visual: los datos deben proceder de los bytes reales de `TABLAS_SPRITE_CASILLA` en `src/mummy1_body.asm`.

## Contexto técnico

`TABLAS_SPRITE_CASILLA` empieza en `$8919`.

Las ocho losetas lógicas de pisadas son sprites CPC Modo 1 de:

- 2 bytes por fila.
- 8 filas.
- 16 bytes por loseta.
- 8 losetas.
- 128 bytes útiles en total.

La correspondencia confirmada por `DIBUJAR_CASILLA_MAPA` es:

| Orden lógico | Valor de casilla | Dirección | Offset desde `$8919` | Interpretación visual actual |
|---:|---:|---:|---:|---|
| 1 | 1 | `$89D9` | +192 | pisada izquierda hacia arriba |
| 2 | 2 | `$89E9` | +208 | pisada derecha hacia arriba |
| 3 | 3 | `$89F9` | +224 | pisada izquierda hacia la derecha |
| 4 | 4 | `$8A19` | +256 | pisada derecha hacia la derecha |
| 5 | 5 | `$8A79` | +352 | pisada izquierda hacia abajo |
| 6 | 6 | `$8A69` | +336 | pisada derecha hacia abajo |
| 7 | 7 | `$8AA9` | +400 | pisada izquierda hacia la izquierda |
| 8 | 8 | `$8A89` | +368 | pisada derecha hacia la izquierda |

Los rangos de 16 bytes son:

```text
$89D9-$89E8
$89E9-$89F8
$89F9-$8A08
$8A19-$8A28
$8A69-$8A78
$8A79-$8A88
$8A89-$8A98
$8AA9-$8AB8
```

Las zonas `$8A09`, `$8A29`, `$8A49` y `$8A99` quedan fuera del fichero lógico compacto: son datos usados por otras ramas de escritura de `DIBUJAR_ENTIDAD` y no deben incluirse por error como parte de las ocho losetas de `DIBUJAR_CASILLA_MAPA`.

## Nombre y formato del fichero

Crea este fichero:

```text
src/data/img/tiles/tiles_pisadas.bin
```

Debe contener las 8 losetas en el orden lógico de la tabla anterior, sin cabeceras, sin metadatos y sin transformación de bits:

```text
LOSETA_MAPA_PISADA_1  ; 16 bytes de $89D9
LOSETA_MAPA_PISADA_2  ; 16 bytes de $89E9
LOSETA_MAPA_PISADA_3  ; 16 bytes de $89F9
LOSETA_MAPA_PISADA_4  ; 16 bytes de $8A19
LOSETA_MAPA_PISADA_5  ; 16 bytes de $8A79
LOSETA_MAPA_PISADA_6  ; 16 bytes de $8A69
LOSETA_MAPA_PISADA_7  ; 16 bytes de $8A89
LOSETA_MAPA_PISADA_8  ; 16 bytes de $8AA9
```

El tamaño esperado es exactamente **128 bytes**.

No reordenes las losetas por dirección física: el orden del fichero debe corresponder a los valores de casilla `1..8`, porque ese es el orden lógico del dispatcher.

## Integración con el ASM

Antes de sustituir nada en `src/mummy1_body.asm`, comprueba la distribución física real.

Las ocho losetas no son un tramo físico continuo: entre ellas hay bytes de otras variantes gráficas. Por tanto:

- No sustituyas sin más todo `$89D9-$8AB8` por un único `INCBIN` de 128 bytes.
- Eso desplazaría las direcciones posteriores y rompería el binario.
- Si integras `tiles_pisadas.bin` en el ASM, utiliza una estrategia que conserve exactamente las direcciones originales, por ejemplo:
  - `INCBIN` con offset y longitud para cada segmento, o
  - ocho `INCBIN` de 16 bytes tomando el bloque lógico correspondiente, junto con los bytes intercalados conservados aparte, o
  - mantener temporalmente los `DB` originales y usar el fichero como recurso extraído/documental si la integración limpia no es posible.
- No cambies ninguna etiqueta ni dirección sin una comparación byte a byte.
- No elimines `$8A09`, `$8A29`, `$8A49` ni `$8A99`: no pertenecen al fichero compacto de las ocho losetas.

La extracción del fichero y la integración en la fuente son dos operaciones distintas. Si integrar el fichero exige una reorganización compleja, prioriza conservar el binario y deja constancia explícita de por qué el fichero se mantiene como artefacto extraído independiente.

## Verificaciones obligatorias

1. Comprueba que cada grupo de 16 bytes del fichero coincide exactamente con los bytes del ASM en su dirección original.
2. Comprueba que el fichero tiene 128 bytes exactos.
3. Comprueba que los bytes se muestran correctamente en `recursos/sprites.html` con:
   - Modo 1.
   - Ancho 2.
   - Alto 8.
   - Salto 16.
4. Comprueba que no se incluye el desplazamiento visual experimental `$89E7`; la segunda loseta lógica empieza en `$89E9`.
5. Ejecuta:

```text
py tools/build_all.py
```

6. Exige `0 diferencias` para `mummy1.bin` y `mummy.bas`.
7. Si se modifica el ASM, verifica además que todas las etiquetas posteriores conservan sus direcciones originales.
8. Ejecuta `git diff --check`.

## Documentación obligatoria

Añade una entrada cronológica en `FINDINGS.md` indicando:

- que se ha creado `src/data/img/tiles/tiles_pisadas.bin`;
- su tamaño de 128 bytes;
- el orden lógico de las ocho losetas;
- las direcciones originales de cada bloque de 16 bytes;
- que el fichero es una extracción/reconstrucción del bloque gráfico y no una prueba de que el juego original tuviera ese fichero externo;
- si el ASM se ha integrado mediante `INCBIN` o si se conserva como `DB` por razones de distribución física;
- el resultado de `py tools/build_all.py`.

Actualiza `src/README.md` y `README.md` solo si el nuevo fichero pasa a formar parte de la estructura oficial de recursos. Actualiza `recursos/sprites.html` solo si sus textos o presets necesitan reflejar el nuevo fichero.

No modifiques `README.en.md` salvo que también mantengas sincronizada la documentación inglesa.

## Resultado esperado

Al terminar debe existir:

```text
src/data/img/tiles/tiles_pisadas.bin
```

con 128 bytes exactos, organizado en ocho losetas de 16 bytes, verificado contra las direcciones originales y documentado como recurso extraído de la reconstrucción.

La conclusión debe distinguir cuidadosamente entre:

- bytes confirmados del binario;
- organización lógica reconstruida para el fichero;
- interpretación visual de orientación y pie izquierdo/derecho;
- organización que pudo tener el fichero fuente original, que no puede demostrarse desde el binario final.
