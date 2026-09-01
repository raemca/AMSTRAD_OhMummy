# Guía de Contribución (CONTRIBUTING)

*[Read this in English](CONTRIBUTING.en.md)*

¡Gracias por tu interés en contribuir a este proyecto de **ingeniería inversa,
desensamblado y reconstrucción en ensamblador Z80** de *Oh Mummy* (Amsoft,
1984, Amstrad CPC, versión de disco)!

El objetivo del repositorio es traducir el binario original del juego
(disco, `.dsk`) a código fuente Z80 real, identificando y documentando
funciones, variables y bloques de datos, manteniendo siempre una
**reconstrucción 1:1 (byte-matching)** frente al ejecutable original.
Antes de nada, échale un vistazo a `README.md` y `src/README.md` (la
arquitectura y las convenciones del proyecto) y a `FINDINGS.md` (el diario
de hallazgos) para entender cómo se ha trabajado hasta ahora.

**Estado actual: solo entorno.** Todavía no hay fuente ensamblador ni
recursos extraídos — únicamente las herramientas de lectura del `.dsk`
(`tools/dsk_common.py`, `dsk_catalog.py`, `dsk_extract.py`). Las
secciones de abajo describen el flujo de trabajo previsto para cuando
arranque el desensamblado; hasta entonces, las contribuciones más
útiles son sobre esas herramientas y la documentación.

---

## 📌 Principios Fundamentales del Proyecto

1. **Fidelidad 1:1 (byte-matching):** cualquier cambio en las instrucciones
   ensamblador o en las tablas de datos deberá seguir generando un binario
   idéntico, byte a byte, al original. Salvo que se documente lo contrario
   en `FINDINGS.md` (como ocurrió con un bug real específico de plataforma
   en el proyecto hermano de MSX), no hay excepciones.
2. **Claridad sobre interpretación:** no se añade código nuevo ni se
   "optimizan" rutinas originales. El objetivo es traducir e interpretar
   exactamente lo que el binario hace, bugs originales incluidos si los hay.
3. **Paso a paso:** mejor etiquetar/documentar un bloque pequeño y verificado
   que enviar un cambio grande sin comprobar contra el binario real.
4. **Nombres descriptivos en español:** siguiendo la convención ya
   establecida en los proyectos hermanos (MSX y ZX Spectrum de *Mad Mix
   Game*), se usan nombres descriptivos **en español**, no inglés ni
   abreviaturas crípticas — por ejemplo `MOTOR_ACTORES`,
   `CONSULTAR_TIPO_LOSETA`, no `ACTOR_ENGINE` ni `lbl_8600`. Las etiquetas
   puramente internas de una rutina (marcas de salto sin entidad propia)
   usan el mecanismo de etiquetas locales de SjASMPlus con punto inicial
   (`.BUCLE_SEGMENTO`).
5. **No dar por hecho el significado de un campo/dirección sin
   verificarlo:** cuando algo pueda interpretarse de varias formas
   (por ejemplo, los campos de la cabecera AMSDOS de un binario), se
   deja documentado como pendiente en vez de afirmarlo de memoria —
   se verifica contra el propio código que lo usa (p. ej. el cargador
   BASIC) antes de darlo por bueno. Ver `FINDINGS.md`.

---

## 🛠️ Entorno de Trabajo y Herramientas

- **Ensamblador:** [SjASMPlus](https://github.com/z00m128/sjasmplus) en el
  PATH — es el ensamblador previsto para este proyecto (mismo que los
  hermanos de MSX y ZX Spectrum), aunque todavía no hay fuente que compilar.
- **Python 3** (`py` en Windows) — para las herramientas de `tools/`. Sin
  dependencias externas, solo librería estándar.
- **Un emulador de Amstrad CPC** (p. ej. [CPCemu](http://www.cpc-emu.org/)
  o [RetroVirtualMachine](https://www.retrovirtualmachine.org/)), opcional
  pero recomendado, para probar el resultado y contrastar hallazgos.
- **Una copia legalmente obtenida del juego original** (`.dsk`) si quieres
  verificar tú mismo la comparación byte a byte — este repositorio **no
  incluye** el volcado original, ver `AVISO-LEGAL.md`. Sin ella puedes
  seguir contribuyendo (documentación, herramientas), pero no podrás
  comprobar el byte-match tú mismo.

---

## 🚀 Flujo de Trabajo para Contribuir

### 1. Preparar el Repositorio

1. Haz un **fork** de este repositorio en GitHub.
2. Clónalo localmente:

   ```bash
   git clone https://github.com/TU_USUARIO/AMSTRAD_OhMummy.git
   cd AMSTRAD_OhMummy
   ```

3. Crea una rama descriptiva:

   ```bash
   git checkout -b leer-catalogo-dsk
   ```

### 2. Ejecutar y Verificar

Hoy por hoy, ejecutar las herramientas de lectura del disco:

```bash
py tools/dsk_catalog.py
py tools/dsk_extract.py
```

Cuando exista fuente ensamblador, esta sección se ampliará con la
compilación completa (`py tools/build_all.py`) y la generación
verificada del `.dsk` reconstruido — el script deberá imprimir "0
diferencias" contra `FISICO/Oh Mummy (1984)(Amsoft).dsk`. Si tu cambio
es solo renombrado/comentarios, el resultado debe ser **exactamente el
mismo** que antes de tu cambio.

### 3. Documentar el hallazgo

Si identificas o corriges algo (una etiqueta, un bloque de datos, un
comportamiento), añade una entrada en `FINDINGS.md` siguiendo el estilo ya
usado — un encabezado `##`/`###` describiendo qué se creía antes, qué se
descubrió y cómo se verificó. Es el diario cronológico del proyecto; no se
reescribe el historial, se añade encima.

---

## 📬 Envío de Pull Requests

1. Haz commit de tus cambios con mensajes descriptivos:

   ```bash
   git commit -m "Anade extraccion de cabecera AMSDOS y documenta el catalogo en FINDINGS.md"
   ```

2. Sube tu rama:

   ```bash
   git push origin leer-catalogo-dsk
   ```
3. Abre una **Pull Request** contra la rama `main` de este repositorio.
4. En la descripción de la PR, indica qué ficheros/etiquetas afecta el
   cambio y, si aplica, el resultado de la verificación byte a byte (§2).

---

## 🐛 Reporte de Errores e Inconsistencias

Si encuentras una sección mal interpretada, datos leídos como código, o una
etiqueta que ya no describe lo que hace su rutina, pero no vas a corregirlo
tú mismo:

1. Comprueba que no exista ya un Issue abierto sobre lo mismo.
2. Abre un nuevo Issue describiendo el problema.
3. Incluye la dirección de memoria real y la justificación técnica —si puedes
   verificarlo en vivo con un emulador o comparando contra el binario
   original, mejor.

---

¡Gracias por colaborar en la preservación e ingeniería inversa de este trozo
de la historia temprana del software para Amstrad CPC!
