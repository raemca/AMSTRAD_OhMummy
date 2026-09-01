# Aviso legal y de atribución

*Ingeniería inversa, análisis y documentación: Rafael Eduardo Martín Candial (raemca@hotmail.com)*

## De quién es cada cosa

**El juego no es nuestro.** *Oh Mummy* se publicó para **Amstrad CPC**
en 1984 bajo el sello **Amsoft** (la marca de software propia de
Amstrad, que distribuía tanto títulos propios como de terceros en el
catálogo de lanzamiento del CPC 464). **La autoría concreta del juego
—programador, gráficos, música— no se ha confirmado todavía**: no se
da por buena ninguna atribución hasta verificarla en el propio binario
(pantalla de créditos, si la hay, o cadenas de texto identificables) o
en fuentes documentales fiables. La propiedad intelectual del juego
original — código, gráficos, sonido y diseño — sigue siendo de
Amsoft/Amstrad, de las personas que lo crearon, o de quien haya
heredado esos derechos a día de hoy.

**Lo que sí es nuestro** son las herramientas de este repositorio, los
comentarios del código fuente reconstruido, el análisis y la
documentación (`FINDINGS.md`, `README.md` y los recursos HTML que los
acompañen). Eso se publica bajo la licencia que conste en `LICENSE`.

## Qué contiene este repositorio

Este proyecto **no tiene acceso al código fuente original** de *Oh
Mummy* — no se conserva, o al menos no ha llegado a este trabajo. Lo
que hay en `src/` será una **reconstrucción por ingeniería inversa**:
desensamblado byte a byte del binario original de disco (`.dsk`),
reescrito como fuente ensamblador (`SjASMPlus`) legible, con etiquetas
descriptivas y comentarios que expliquen qué hace cada rutina y por
qué — y, cuando sea posible, **verificado recompilando y comparando el
resultado byte a byte contra el binario original** (misma disciplina
que los proyectos hermanos de MSX y ZX Spectrum). Se acompañará de las
herramientas (`tools/`) que permitan recompilar esa fuente y
regenerar el `.dsk`.

Este repositorio **no incluye** el volcado original del disco (`.dsk`)
tal como se extrajo del soporte físico, ni herramientas de terceros
usadas durante el análisis (desensambladores, ensambladores). Lo que
se distribuye es la fuente reconstruida, los datos del juego ya
identificados y documentados, y las herramientas propias para
generarlos — no una copia del producto original.

## Si eres uno de los autores, Amsoft/Amstrad, o su sucesor en derechos

Si trabajaste en *Oh Mummy*, o representas a Amsoft, Amstrad, o a
quien haya heredado sus derechos, y prefieres que este material no
esté publicado, **dilo y se retira sin discusión**. Cualquier
requerimiento legal, de quien corresponda, será atendido. La intención
de este trabajo es la contraria a perjudicar: es dejar constancia de
cómo estaba hecho un juego que forma parte de la historia temprana del
software para Amstrad CPC, con fines educativos y de preservación de
ese legado, antes de que se pierda del todo.

## Sobre los créditos

Si se localiza una pantalla de créditos o cadenas de autoría dentro
del binario, los nombres se transcribirán tal cual aparezcan,
incluyendo posibles erratas originales — no de fuentes externas. No se
afirmará ninguna identidad civil real detrás de un pseudónimo sin
confirmación.
