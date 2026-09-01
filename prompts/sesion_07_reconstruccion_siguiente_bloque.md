# Prompt de sesión — Oh Mummy, sesión 7

Reglas globales: ver [prompts/_base_reconstruccion.md](../prompts/_base_reconstruccion.md).

Objetivo:
Continuar la reconstrucción del código del motor en [src/mummy1_body.asm](../src/mummy1_body.asm), avanzando desde el siguiente bloque sin cerrar y manteniendo el criterio principal: reconstruir la fuente original como si fuese el programa real, no quedarse en análisis documental.

Trabajo principal:
- Seguir desde el último punto confirmado del motor y desde el siguiente tramo aún pendiente.
- Desensamblar solo lo necesario para cerrar una rutina o un bloque lógico.
- Identificar y etiquetar variables, punteros, buffers, tablas, contadores, cliclos, condiciones y subrutinas con semántica funcional.
- Mantener el ASM legible y coherente con la lógica del juego.
- Añadir comentarios didácticos claros, con nivel de confianza y marca de hipótesis cuando no haya evidencia total.
- No convertir datos en código sin evidencia; si una zona es tabla o buffer, dejarla claramente marcada como dato.
- No dar por definitivo un nombre si sigue siendo provisional.

Prioridades:
1. Resolver el siguiente bloque no reconstruido del motor.
2. Completar etiquetas funcionales de rutinas y estructuras.
3. Mejorar la claridad del ASM sin romper la continuidad del código.
4. Mantener la reconstrucción cercana a la intención del programador original.
5. Mantener la documentación sincronizada con el código.

Documentación obligatoria en paralelo:
- Actualizar `FINDINGS.md`, `README.md`, `src/README.md` y los HTML relevantes de `recursos/` si cambia el estado del análisis.
- Registrar nuevas rutinas, hipotesis, confianza, estructuras y pendientes.
- Mantener un inventario claro de lo confirmado, provisional y sin cerrar.

Verificación obligatoria tras cada cambio:
- Tras cualquier modificación del ASM o de los archivos relacionados, ejecutar `py tools/build_all.py`.
- La verificación debe ser estricta: el binario generado debe coincidir byte a byte con el original.
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
