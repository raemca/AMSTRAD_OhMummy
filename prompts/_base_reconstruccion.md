# Reglas globales para todos los prompts de reconstrucción

1. Objetivo principal:
   - Reconstruir el código fuente del juego en ASM lo más cerca posible de la intención del programador original.
   - No limitarse a un análisis documental; el trabajo debe producir fuente legible, con etiquetas funcionales, comentarios y estructura de programa.

2. Regla de trabajo:
   - Empezar desde el punto de entrada real del binario.
   - Seguir la jerarquía de llamadas y no avanzar a ciegas por bloques sin contexto.
   - Identificar primero firmware, luego rutinas internas del propio binario, y después tablas/datos.

3. Reglas de nomenclatura:
   - Dar nombres funcionales y semánticos a rutinas, variables, labels y bucles.
   - Los nombres deben ser coherentes con la lógica del juego, como un programador original podría haberlos escrito.
   - Si la evidencia no es total, usar un nombre provisional con comentario de hipótesis y nivel de confianza.

4. Regla de verificación obligatoria tras cada cambio:
   - Tras cualquier modificación del ASM, documentación o archivos relacionados con la reconstrucción, ejecutar `py tools/build_all.py`.
   - La verificación debe comprobar que el binario generado es idéntico al original, byte a byte.
   - Si la compilación falla o aparece cualquier diferencia, no se considera válido el cambio; se debe corregir antes de continuar.
   - Se debe registrar el resultado de la validación en la documentación si cambia el estado del proyecto.
   - El criterio es objetivo: no vale “parece bien” ni “debería funcionar”; solo vale “0 diferencias”.

5. Reglas de documentación:
   - Actualizar en paralelo `FINDINGS.md`, `README.md`, `src/README.md` y los archivos HTML de `recursos/` cuando haya cambios relevantes.
   - Mantener la documentación alineada con la fuente ASM.
   - Diferenciar claramente entre confirmado, hipótesis y pendiente.
   - `recursos/flujo_detallado.html` (grafo real de llamadas `CALL`/`JP`/`JR` entre rutinas, con estado de confianza por nodo y por relación) debe revisarse siempre que cambien: el flujo de ejecución, las llamadas entre rutinas, los puntos de entrada, los despachadores (directos o indirectos) o el estado/confianza de una rutina ya nombrada.
   - Regla explícita de mantenimiento: cada sesión que modifique el flujo de llamadas debe actualizar `recursos/flujo_detallado.html` (nodos, aristas, estados, panel de relaciones indirectas y pendientes) o, si el cambio de la sesión no afecta al flujo, dejar constancia explícita de ello en la entrada correspondiente de `FINDINGS.md` — no se actualiza el HTML por rutina, solo cuando hay evidencia nueva que lo justifique.

6. Reglas de calidad del ASM:
   - No reescribir bloques ya verificados salvo que haya evidencia clara.
   - Añadir comentarios didácticos que expliquen intención, flujo y significado del bloque.
   - Separar bien código, datos y bucles.
   - Mantener el archivo legible y reutilizable como fuente de preservación.

7. Resultado esperado:
   - Fuente ASM reconstruida, semánticamente etiquetada y explicada.
   - Inventario de variables, funciones y etiquetas.
   - Verificación ejecutada y confirmada con `py tools/build_all.py`.
   - Documentación actualizada en `.md` y `.html`.
   - Estado claro de descubrimientos y pendientes.
