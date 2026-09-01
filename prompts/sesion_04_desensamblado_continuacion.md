# Prompt de sesión — Oh Mummy, sesión 4

Proyecto: Oh Mummy (Amstrad CPC 464).
Archivo principal: `src/mummy1_body.asm`.
Entrada real del binario: `$6000`.
El cargador BASIC confirma la carga real: `LOAD "!mummy1", &6000` y `CALL &6000`.
La sesión 2 dejó el bloque `$6000-$6400` desensamblado y verificado.
La sesión 3 ya ha documentado el avance del proyecto.
La zona `$6401-$9385` sigue sin análisis semántico completo y debe tratarse con disciplina.

Objetivo de esta sesión:
Continuar el desensamblado desde `$6000`, siguiendo el flujo de llamadas internas del propio binario, no avanzando linealmente a ciegas.

Tareas obligatorias:
1. Empezar desde `$6000` y analizar cada `CALL`.
2. Diferenciar:
   - llamadas a ROM del CPC (`$BBxx`, `$BCxx`, `$BDxx`)
   - llamadas a rutinas internas del binario (`$78xx`, `$7Dxx`, `$7Exx`, `$7Bxx`)
   - saltos locales
   - referencias a tablas, buffers o datos
3. Para cada rutina interna identificada, documentar:
   - dirección
   - propósito probable
   - entrada/salida asumida
   - tipo funcional: inicialización, render, control, mapa, texto, audio, IA, colisiones, puntuación, carga de recursos, etc.
4. Mantener un mapa de flujo del programa a medida que avances.
5. No conviertas datos en código sin evidencia clara.
6. No avances por `$6401-$9385` sin contexto: primero sigue el hilo de llamadas que parte de `$6000`.

Documentación obligatoria en paralelo (sin excepciones):
- Actualizar `FINDINGS.md` con hallazgos, hipótesis y pendientes.
- Actualizar `README.md` y `src/README.md` si cambia el estado del proyecto.
- Revisar y actualizar los HTML de `recursos/` afectados por el avance: `flujo_programa.html`, `flujo_secuencial.html`, `graficos.html`, `sprites.html`, `portada.html`, `mapa_memoria.html`.
- Mantener un inventario de variables, funciones, etiquetas y rangos de memoria con nivel de confianza.

En los HTML de recursos debes reflejar, cuando proceda:
- zonas de memoria identificadas
- direcciones o rangos relevantes
- funciones o bloques probables
- sprites, gráficos o componentes visuales detectados
- evolución del flujo del programa
- estado: confirmado / hipótesis / pendiente

Reglas:
- No inventes nombres definitivos sin evidencia.
- Usa nombres provisionales claros y descriptivos cuando haga falta.
- Marca claramente lo que está confirmado, lo que es hipótesis y lo que sigue pendiente.
- La documentación debe mantenerse alineada con el estado real del análisis, no quedar desfasada.
- Si no hay progreso relevante en un archivo, dilo explícitamente.

Resultado esperado:
- Mapa de llamadas principal desde `$6000`
- Lista de subrutinas internas detectadas y su propósito probable
- Clasificación funcional de los bloques identificados
- Resumen de avances del motor
- Actualización correcta de archivos `.md` y `.html`
- Pendientes para la siguiente sesión

Trabaja con rigor, trazabilidad y documentación continua. La documentación es parte del trabajo, no una tarea opcional final.

