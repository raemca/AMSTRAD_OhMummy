# Prompt de sesión — Oh Mummy, sesión 6

Reglas globales: ver [prompts/_base_reconstruccion.md](../prompts/_base_reconstruccion.md).

Objetivo:
Continuar la reconstrucción del código fuente del motor en [src/mummy1_body.asm](../src/mummy1_body.asm), priorizando la identificación de subrutinas, variables, bucles y etiquetas con semántica funcional, como lo haría el programador original.

Trabajo principal:
- Seguir desde el punto de entrada real y desde el siguiente bloque aún no resuelto del motor.
- Desensamblar solo lo necesario para avanzar la fuente real.
- Para cada bloque, asignar etiquetas semánticas claras y consistentes.
- Dar nombres funcionales a variables, búferes, punteros, tablas, contadores y bucles.
- Añadir comentarios didácticos que expliquen intención, flujo, entrada/salida y relación con el juego.
- No convertir datos en código sin evidencia; si es tabla o buffer, dejarlo claramente marcado como dato.
- No inventar nombres definitivos sin evidencia; si hace falta, usar nombres provisionales y dejar marca de hipótesis.

Prioridades:
1. Resolver las rutinas internas del motor que todavía estén sin etiqueta funcional.
2. Nombrar variables y áreas de memoria según su uso real en la lógica del juego.
3. Mejorar la legibilidad del ASM con comentarios y estructura por bloques.
4. Mantener la fuente reconstruida lo más cercana posible a la intención del autor original.

Documentación obligatoria en paralelo:
- Actualizar `FINDINGS.md`, `README.md`, `src/README.md` y los HTML relevantes de `recursos/` si cambia el estado del análisis.
- Mantener el inventario de rutinas, variables, etiquetas y rangos de memoria actualizado.

Verificación obligatoria tras cada cambio:
- Tras cualquier modificación del ASM o de los archivos relacionados, ejecutar `py tools/build_all.py`.
- Si la compilación falla o se detecta cualquier diferencia frente al binario original, la tarea no está terminada.
- La comprobación debe ser estricta: solo es válido el resultado que coincide byte a byte con el original.

Resultado esperado:
- ASM más legible y semánticamente etiquetado
- nuevas rutinas, variables y bucles nombrados funcionalmente
- comentarios didácticos en el código
- documentación actualizada en `.md` y `.html`
- verificación ejecutada con `py tools/build_all.py` y sin diferencias
- estado claro de lo confirmado, lo hipotético y lo pendiente

Importante:
La documentación, la reconstrucción del ASM y la verificación de integridad deben ir en paralelo. No dejarlo para el final.
