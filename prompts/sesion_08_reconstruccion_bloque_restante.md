# Prompt de sesión — Oh Mummy, sesión 8

Reglas globales: ver [prompts/_base_reconstruccion.md](../prompts/_base_reconstruccion.md).

Objetivo:
Continuar la reconstrucción del código del motor en [src/mummy1_body.asm](../src/mummy1_body.asm), atacando el siguiente bloque pendiente del motor tras el tramo ya restaurado en sesiones anteriores.

Bloque objetivo:
- Avanzar desde el punto de entrada real y desde el siguiente hueco no reconstruido del motor.
- Priorizar el tramo que sigue a la sección ya resuelta en la Sesión 7, especialmente el bloque restante de `INCBIN` y las rutinas internas que aún no tienen nombre funcional.
- Mantener el criterio de reconstrucción real: no limitarse a análisis, sino recuperar la fuente como si fuera el código original.

Trabajo principal:
- Desensamblar solo lo necesario para cerrar una subrutina o un bloque lógico.
- Identificar y etiquetar variables, punteros, buffers, tablas, contadores, bucles, condiciones y subrutinas con nombre semántico.
- Progresar a la siguiente capa de profundidad del motor sin romper la continuidad del código reconstruido.
- Añadir comentarios didácticos con grado de confianza y marca de hipótesis cuando no haya evidencia total.
- No convertir datos en código sin evidencia; si una zona es tabla o buffer, dejarla claramente marcada como dato.
- No dar por definitivo un nombre si sigue siendo provisional.

Prioridades:
1. Resolver el siguiente bloque no reconstruido del motor.
2. Promover nuevas rutinas internas a etiquetas con semántica funcional.
3. Nombrar variables y estructuras según su uso real en la lógica del juego.
4. Mejorar la legibilidad del ASM y mantener la fuente coherente.
5. Mantener documentación y código sincronizados.

Documentación obligatoria en paralelo:
- Actualizar `FINDINGS.md`, `README.md`, `src/README.md` y los HTML relevantes de `recursos/` si cambia el estado del análisis.
- Registrar nuevas rutinas, hipótesis, confianza, estructuras y pendientes.
- Mantener un inventario claro de lo confirmado, provisional y todavía sin cerrar.

Verificación obligatoria tras cada cambio:
- Tras cualquier modificación del ASM o de los archivos relacionados, ejecutar `py tools/build_all.py`.
- La comprobación debe ser estricta: el binario generado debe coincidir byte a byte con el original.
- Si la compilación falla o aparece cualquier diferencia, la tarea no está terminada; hay que corregirla antes de continuar.
- No vale “parece bien” ni “debería funcionar”: solo es válido el resultado con 0 diferencias.

Resultado esperado:
- nuevas subrutinas, variables y bucles nombrados funcionalmente
- etiquetas semánticas coherentes y comentarios útiles
- avance del ASM sin huecos ni bloques inconexos
- documentación actualizada en `.md` y `.html`
- verificación ejecutada con `py tools/build_all.py` y sin diferencias
- estado claro de lo confirmado, lo hipotético y lo pendiente

Importante:
La documentación, la reconstrucción del ASM y la verificación de integridad deben ir en paralelo. No dejarlo para el final.
