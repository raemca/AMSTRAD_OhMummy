# Prompt para Claude — crear y mantener `recursos/flujo_detallado.html`

## Contexto

Proyecto: **Oh Mummy** para Amstrad CPC, versión de disco de 1984.

El proyecto reconstruye por ingeniería inversa el cargador BASIC y el motor Z80 a partir del binario original. La entrada real del motor es `$6000`, confirmada por `src/load_disk/mummy_bas.bas`. La fuente principal es `src/mummy1_body.asm`; el estado técnico y la evidencia histórica están en `FINDINGS.md`.

El proyecto ya tiene estas páginas relacionadas:

- `recursos/flujo_programa.html`: inventario de rutinas, datos y firmware.
- `recursos/flujo_secuencial.html`: orden secuencial conocido o hipotético desde la carga hasta la partida.
- `recursos/mapa_memoria.html`: regiones y subregiones de memoria.
- `recursos/sprites.html`, `recursos/graficos.html` y `recursos/portada.html`: recursos visuales.

Falta crear `recursos/flujo_detallado.html`, equivalente conceptual al flujo detallado de llamadas utilizado en el proyecto hermano de Mad Mix Game para Spectrum. La comparación sirve únicamente como referencia de estructura y usabilidad: **no copies nombres, direcciones, datos, colores semánticos ni conclusiones de Mad Mix Game**, porque es otro juego, otra plataforma y otro binario.

Consulta siempre las reglas globales en [`prompts/_base_reconstruccion.md`](../prompts/_base_reconstruccion.md).

## Objetivo

Crear `recursos/flujo_detallado.html` como una página HTML autocontenida e interactiva que muestre el flujo técnico real conocido del programa de Oh Mummy, principalmente:

1. El grafo de llamadas `CALL` entre rutinas identificadas.
2. Los puntos de entrada y las relaciones de control relevantes cuando puedan demostrarse.
3. La separación entre firmware CPC, rutinas internas, arranque, menú, sonido, renderizado, mapa, entidades, entrada y otros subsistemas que existan realmente.
4. El grado de certeza de cada nodo y relación: `confirmado`, `hipótesis` o `pendiente`.
5. La evidencia que respalda cada elemento: dirección, rango, etiqueta ASM, archivo, sesión de análisis y tipo de instrucción.
6. Las limitaciones del grafo, para no presentarlo como un flujo completo si todavía hay bloques sin reconstruir.

La página debe ser útil para seguir la ingeniería inversa sesión a sesión, no solo una ilustración estática.

## Investigación previa obligatoria

Antes de escribir el HTML:

1. Lee `FINDINGS.md` completo o, como mínimo, todas las secciones relacionadas con las sesiones que hayan cambiado el flujo.
2. Lee `src/mummy1_body.asm`, `src/main.asm` y `src/README.md`.
3. Lee `recursos/flujo_programa.html`, `recursos/flujo_secuencial.html` y `recursos/mapa_memoria.html` para conservar nombres, estados, direcciones y estilo documental coherentes.
4. Revisa el binario, el listado de ensamblado o las herramientas disponibles cuando hagan falta para distinguir llamadas reales de hipótesis.
5. No deduzcas una arista solo porque dos rutinas estén próximas en memoria o pertenezcan al mismo subsistema.

## Reglas de exactitud del grafo

### Aristas directas

- Representa una arista normal solo cuando exista una instrucción `CALL destino` demostrable.
- Representa `CALL cc,destino` como arista condicional y conserva la condición Z80 (`Z`, `NZ`, `C`, `NC`, `PE`, `PO`, `P`, `M`) sin convertirla en una explicación semántica no demostrada.
- Distingue las llamadas a firmware CPC (`$BBxx`, `$BCxx`, `$BDxx` y las que estén confirmadas por el manual) de las llamadas internas al motor.
- Si una llamada cae dentro de una zona aún incluida mediante `INCBIN`, no inventes el nombre de la rutina: usa dirección y estado pendiente, o exclúyela del grafo principal con una nota clara.

### Saltos y despachadores

- No mezcles automáticamente `CALL`, `JP`, `JR`, `RST` y saltos indirectos en una sola relación.
- Si un `JP` o `JR` es necesario para explicar la estructura de una rutina, muéstralo con otro estilo de línea y una leyenda explícita.
- Registra aparte los despachadores indirectos (`JP (HL)`, `JP (IX)`, `JP (IY)`, tablas de punteros, índices de sprites o tablas de datos). Deben aparecer como “flujo indirecto” o “despachador”, nunca como llamadas directas inventadas.
- Señala los puntos de entrada múltiples y los casos de caída directa (`fall-through`) cuando estén confirmados en el ASM.
- Si una relación no puede atribuirse a una rutina de origen fiable, omítela y explica la omisión en la sección de alcance.

### Estados y confianza

Cada nodo y cada relación deben tener un estado explícito:

- `confirmado`: bytes, llamada, dirección o uso demostrados directamente, o verificados contra el binario original.
- `hipotesis`: interpretación funcional razonable, pero no verificada por completo o no ejecutada en emulador.
- `pendiente`: zona detectada o posible relación todavía sin análisis suficiente.

No conviertas una etiqueta provisional en un hecho confirmado solo porque aparezca en `mummy1_body.asm`. Conserva la hipótesis y el nivel de confianza indicado por los comentarios y por `FINDINGS.md`.

## Contenido mínimo de la página

La página debe incluir:

1. Título: `Oh Mummy (Amsoft, 1984) -- flujo detallado de llamadas`.
2. Subtítulo con la relación con `flujo_programa.html`, el punto de entrada `$6000` y la fecha o sesión de la última actualización.
3. Un aviso de alcance que indique:
   - qué conjunto de nodos se representa;
   - qué tipos de relaciones se incluyen;
   - qué bloques están todavía pendientes, especialmente `$6401-$786B` si continúa pendiente;
   - qué flujo indirecto no puede reconstruirse como una arista directa;
   - que el grafo representa evidencia del binario, no una narración genérica del género arcade.
4. Leyenda visible para colores o estilos de:
   - arranque/cargador;
   - firmware CPC;
   - motor y control;
   - entidades, mapa y colisiones;
   - renderizado/gráficos;
   - sonido;
   - menú/HUD/entrada;
   - `confirmado`, `hipótesis`, `pendiente`;
   - `CALL` directo, llamada condicional, salto y flujo indirecto.
5. Controles interactivos:
   - zoom aumentar, reducir, restablecer y ajustar a ventana/ancho;
   - mostrar u ocultar subsistemas mediante casillas o filtros;
   - búsqueda por etiqueta, dirección, subsistema o estado;
   - tooltip o panel de detalle al pasar el ratón o seleccionar un nodo;
   - leyenda y controles utilizables también sin ratón cuando sea razonable.
6. El grafo principal del flujo, con nombres, direcciones y agrupación por subsistema.
7. Una tabla o panel de nodos con:
   - dirección inicial;
   - dirección final o tamaño si se conoce;
   - etiqueta;
   - subsistema;
   - estado;
   - confianza;
   - evidencia y sesión de origen.
8. Un panel de “relaciones no representadas como `CALL` directo” para tablas de despacho, `JP` indirectos, entradas alternativas y zonas pendientes.
9. Una sección de “pendientes para la siguiente sesión” derivada de `FINDINGS.md`, no inventada.
10. Pie con fuentes: `src/mummy1_body.asm`, `FINDINGS.md`, `recursos/flujo_programa.html` y `recursos/flujo_secuencial.html`.

## Implementación HTML

- Mantén la página autocontenida, sin depender de red ni de un CDN para funcionar localmente.
- Puedes reutilizar el lenguaje visual general de las páginas existentes, pero no copies contenido incorrecto de Mad Mix Game.
- Si usas Mermaid u otra representación generada, incluye una alternativa local o un mensaje claro cuando el motor no esté disponible; la página no debe quedar en blanco.
- Evita meter todo el grafo en una única masa ilegible. Usa agrupación, zoom, filtros y detalles bajo demanda.
- Si el grafo es demasiado grande, muestra un grafo principal reducido y permite consultar el inventario completo en la tabla.
- No uses direcciones, rutinas ni subsistemas que no puedan rastrearse a los archivos del proyecto.
- Usa codificación UTF-8 y conserva el idioma español de la documentación.

## Integración documental obligatoria

Al crear la página:

1. Añade una entrada cronológica en `FINDINGS.md` indicando:
   - que se ha creado `recursos/flujo_detallado.html`;
   - qué fuentes se usaron;
   - qué relaciones son directas y cuáles indirectas;
   - cuántos nodos/aristas se representan, si se puede contar de forma fiable;
   - qué zonas siguen fuera del grafo;
   - estado `confirmado / hipótesis / pendiente` de las conclusiones.
2. Actualiza `README.md` y `src/README.md` para incluir `recursos/flujo_detallado.html` dentro de la documentación del proyecto.
3. Si procede, actualiza `recursos/flujo_programa.html`, `recursos/flujo_secuencial.html` y `recursos/mapa_memoria.html` para que no contradigan al nuevo grafo.
4. Modifica `prompts/_base_reconstruccion.md` para añadir `recursos/flujo_detallado.html` a la lista de documentación que debe revisarse cuando cambie el flujo, las llamadas, los puntos de entrada, los despachadores o el estado de una rutina.
5. Añade una regla explícita a las instrucciones base: cada sesión que cambie el flujo debe actualizar el HTML detallado o dejar constancia de que no se ha visto afectado.
6. No marques la página como “completa” mientras queden relaciones o zonas relevantes sin analizar.

## Mantenimiento en sesiones posteriores

A partir de la creación de esta página, cada sesión de reconstrucción debe:

- Revisar si se han añadido, renombrado, dividido o reclasificado rutinas.
- Revisar si han aparecido nuevas llamadas `CALL`, llamadas condicionales, saltos relevantes o despachadores indirectos.
- Actualizar nodos, aristas, estados, rangos y textos de alcance afectados.
- Mantener las cifras de la interfaz sincronizadas con el contenido real.
- Añadir la sesión de origen y la evidencia de cada cambio relevante.
- Conservar como pendiente todo lo que siga dentro de un `INCBIN` o no tenga evidencia suficiente.
- Actualizar `FINDINGS.md` y los README cuando el cambio altere el estado global del proyecto.
- Si el flujo no cambia en una sesión, indicarlo explícitamente en la entrada de `FINDINGS.md`; no modificar la página por rutina.

## Verificación obligatoria

Después de crear o modificar cualquier archivo:

1. Ejecuta `py tools/build_all.py` y exige `0 diferencias` en los binarios.
2. Comprueba que el HTML se abre localmente sin errores JavaScript ni recursos externos obligatorios.
3. Verifica manualmente que:
   - el grafo no está vacío;
   - los nodos conocidos aparecen con sus direcciones correctas;
   - los filtros y el zoom funcionan;
   - la tabla conserva también nodos pendientes;
   - no se presenta como confirmado ningún flujo hipotético;
   - la página funciona en una ventana estrecha y en una ventana amplia.
4. Si existe una herramienta local de captura o navegador, úsala para revisar al menos la vista inicial y una vista filtrada.
5. Si falla la compilación, el HTML o la coherencia documental, corrige el problema antes de dar la tarea por terminada.

## Resultado esperado

Al terminar, el repositorio debe contener una página funcional en `recursos/flujo_detallado.html` y la documentación debe declarar que esa página es el artefacto vivo del flujo de llamadas de Oh Mummy. Las sesiones futuras deberán actualizarla siempre que cambie el conocimiento del flujo, manteniendo separadas las pruebas directas, las hipótesis y los huecos todavía pendientes.
