# Prompt de sesión — Oh Mummy, sesión 5

Proyecto: Oh Mummy (Amstrad CPC 464). Archivo principal: `src/mummy1_body.asm`. Entrada real del binario: `$6000`.
El BASIC cargador confirma: `LOAD "!mummy1", &6000` y `CALL &6000`.
La sesión 4 ya ha continuado el análisis desde el punto de entrada. La zona `$6401-$9385` sigue sin análisis semántico completo.

Objetivo:
Identificar y documentar las rutinas del firmware CPC y las subrutinas internas del binario que se invocan desde `$6000`.

Tareas obligatorias:
1. Empezar en `$6000` y seguir cada `CALL`.
2. Diferenciar:
   - llamadas a firmware ROM (`$BBxx`, `$BCxx`, `$BDxx`)
   - llamadas a rutinas internas del binario (`$78xx`, `$7Dxx`, `$7Exx`, `$7Bxx`)
   - saltos locales
   - referencias a tablas, buffers o datos
3. Para cada rutina interna detectada, identificar su propósito probable y clasificarla como inicialización, render, control, texto, mapa, IA, colisiones, audio, puntuación o carga de recursos.
4. Mantener un mapa de flujo del programa y marcar si cada bloque parece código o dato.
5. No conviertas tablas o buffers en instrucciones sin evidencia clara.

Documentación obligatoria en paralelo:
- Actualiza `FINDINGS.md`, `README.md` y `src/README.md` si hay cambios relevantes.
- Revisa y actualiza los HTML de `recursos/` afectados: `flujo_programa.html`, `flujo_secuencial.html`, `graficos.html`, `sprites.html`, `portada.html`, `mapa_memoria.html`.
- Mantén un inventario progresivo de variables, funciones, etiquetas y rangos de memoria con nivel de confianza.

Reglas:
- No inventes nombres definitivos sin evidencia.
- Marca lo que está confirmado, hipotético y pendiente.
- La documentación debe ir en paralelo al análisis, no como tarea opcional final.
- Si no hay cambios relevantes, dilo explícitamente.

Resultado esperado:
- mapa de llamadas desde `$6000`
- lista de subrutinas internas detectadas
- clasificación funcional de cada bloque
- actualización de archivos `.md` y `.html`
- pendientes para la siguiente sesión

Trabaja con rigor, trazabilidad y documentación continua. La documentación es parte del trabajo, no una tarea opcional final.

