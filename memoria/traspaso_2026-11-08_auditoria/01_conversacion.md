# Conversación completa (2026-11-08, computadora de Tobías)

> Mensajes de Tobías tal cual. Respuestas del agente tal cual; las llamadas a herramientas se resumen entre corchetes.

---

## Mensaje 1 — Tobías

> Queda alguna cuestión pendiente o inconsistencia que impida comenzar con la implementación del código, si es algo menor o muy tirado de los pelos, es decir que es un edge case que no es común, no lo consideres como cuestión pendiente. Revisá el repo las cuestiones pendientes y las decisiones. Utilizá subagentes para hacer la investigación extensiva.

## Respuesta del agente (trabajo)

[El agente verificó `git status` (limpio, al día con `origin/master`), leyó `docs/cuestiones_pendientes.md` y `docs/cronograma.md` y el índice de la bitácora, y lanzó **cinco subagentes en paralelo, sólo lectura**, cada uno con un frente:]

1. **Contratos de interfaz:** muestra de 39 B, UDP/BLE, `mensajes.proto`, base de tiempo, Parquet, canal de estado.
2. **Base de datos:** `schema.sql` contra los ADR (checklist de cambios), validez en Postgres 17, idempotencia, quién numera zancadas offline.
3. **Firmware de captura y ciclo de sesión:** qué hace el micro en la mínima, pipeline de sesión, adquisición, AHRS, sincronización, pinout, cores.
4. **Pendientes y coherencia global:** las 13 CP abiertas, puntos abiertos huérfanos, estado de la bitácora, stack.
5. **Features y análisis offline:** catálogo de 47, eventos en Python, CP-35, emparejado, modelos de la Fase 4.

Criterio común que se les dio: reportar sólo lo que impida o desvíe empezar a programar; nada menor, cosmético, caso borde raro, parámetro que el diseño ya manda al piloto, ni mecánica de codificación.

Mensaje intermedio del agente: *"Lancé cinco subagentes en paralelo, cada uno con un frente… Cuando terminen, voy a revisar en los documentos cada hallazgo que digan que bloquea antes de pasártelo."*

[Los cinco subagentes se cortaron por un límite de uso.]

## Mensaje 2 — Tobías

> continue

## Respuesta del agente (trabajo)

[Retomó los cinco subagentes desde donde habían quedado. Llegaron los cinco informes (completos en `02_informes_subagentes.md`). El agente verificó contra las fuentes cada hallazgo que iba a reportar: releyó las líneas citadas de SPEC-01/04/05/11, Vistas 1–4, `schema.sql`, ADR-017/028/043/046/047/057/060/062/064, el README del firmware, y comprobó en el código fuente de bleak (`bleak/backends/winrt/client.py`, rama develop) que `pair()` sólo usa `DevicePairingKinds.CONFIRM_ONLY`. Guardó una nota en su memoria local (sólo en la compu de Tobías) y respondió:]

---

**No, nada impide empezar el 16/11.** Ninguna de las 13 cuestiones abiertas frena la Fase 1.

Los cinco subagentes se toparon, por separado, con la misma contradicción. Viene de algo de fondo: el recorte de alcance confirmado el 8/11 en el cronograma no llegó a los documentos que va a leer quien programe. El README del firmware, las Vistas 1, 2 y 3 y los comentarios de `schema.sql` siguen describiendo la mínima anterior: eventos y features en el micro, calibración operativa, OTA desde el principio, adaptación online y el gesto de emparejamiento. De ahí salen casi todos los hallazgos. Revisé en los documentos cada uno de los que siguen. Hay cuatro decisiones para las dos primeras semanas, cada una antes de una tarea concreta.

### Para decidir en las dos primeras semanas

#### 1. Qué hace el micro en las capturas y quién numera las zancadas
*Antes de f2 (23/11) y de la migración base (29/11).*

- **Lo que dicen los documentos:** el README del firmware (`src/firmware/README.md:7`), la Vista 2 (`2_vista_firmware.md:13`), la Vista 1 §6 (`1_vista_sistema.md:148`), `schema.sql:337` y ADR-046 ponen la detección de IC/TO/MS y la numeración de zancadas en la plantilla, en todas las capturas.
- **Lo que va a pasar:** SPEC-11 (`2_specs_algoritmos_firmware.md:417`) y ADR-062 dicen que en la captura exploratoria los pasos se detectan en Python. En la mínima todas las capturas son exploratorias, porque las features del micro pasaron a trabajo futuro, pero eso no está escrito en ningún lado.

Qué depende de esta decisión:
- **El firmware de M1:** si SPEC-01/02 corre en el core 1, y con ella la característica `zancadas`, `set_step_thresholds` y los contadores.
- **La base:** las claves de `strides` y `gait_events` no tienen origen ni versión. Si se reprocesa después del piloto, como pide ADR-062, se renumeran zancadas sobre las mismas claves.
- **La calibración:** la Vista 3 §5 (`3_vista_datos_ml.md:70`) la trata como captura operativa con features del micro, que no van a existir. Tiene que ser exploratoria (ADR-057 ya acepta las features de Python).
- **El re-zero del giro durante el apoyo (SPEC-04):** lo detecta el FSR, pero los umbrales sólo le llegan al micro en operativa o en edge. El crudo sale post-AHRS y no se puede reprocesar, así que lo que corra durante la captura queda en los datos.

Opciones:
- **(a)** Capturas exploratorias. El micro adquiere, aplica el AHRS y transmite; Python detecta y numera. Reprocesar es borrar las series de la sesión y volver a escribirlas. El giro se corrige con el bias en runtime de Fusion más el de la pose 1.
- **(b)** El micro detecta y numera siempre, y Python recalcula. Es más firmware antes de M1 y obliga a agregar una columna de origen a las claves.
- **(c)** El micro detecta sólo el apoyo, para el re-zero, sin numerar.

**Recomiendo (a):** es lo que el cronograma ya supone y reduce el firmware de M1.

#### 2. Dónde se registra qué es cada sesión, para los experimentos
*Junto con el protocolo (CP-33, 20/11), antes de la migración base y de la UI.*

`sessions` sólo tiene `mode`, `environment` y `notes` (`schema.sql:71`), y la UI (`4_vista_backend_app.md:138`) no pide más que eso. No hay dónde marcar:
- cuál es la sesión de calibración (ADR-057 la necesita para `source_session_id`);
- la tarea;
- la anomalía inducida, con su tipo y lado;
- las tandas, de las que ADR-060 pide descartar giros y extremos.

Sin esas marcas, la Fase 4 no puede separar las zancadas normales de las de cada condición. El registro dice que CP-33 "no bloquea el código": vale para el firmware, no para el esquema ni la UI.

**Recomiendo** una sesión por condición o tanda, con una columna estructurada en `sessions` (por ejemplo, `purpose` + un jsonb con los campos del protocolo). Encaja con la sesión como transacción y no suma tablas. La alternativa es una tabla de tramos marcados desde la UI.

#### 3. El contrato del IMU en la muestra
*En f1/f2, antes del piloto, porque el crudo no se puede reprocesar.* Son tres huecos en el contrato de `shared/`:

- **Marco y ángulos.** La muestra lleva un solo `lin_accel` (`1_vista_sistema.md:90`).
  - SPEC-04 lo expone en marco sensor y en marco mundo (`2_specs_algoritmos_firmware.md:117`), y SPEC-03 supone que llega en marco sensor (l.88).
  - Falta fijar cuál de los dos viaja, la convención de Euler y si se aplica la alineación anatómica.
  - Si el micro manda marco mundo, el worker lo rota dos veces.
- **El "offset de accel nivelado".** SPEC-04 (l.123) y ADR-017 fuerzan Z≈9,81, pero la pose 2 sirve para medir la dirección de la gravedad.
  - Si se nivela un sensor inclinado (la cintura en L4-L5, la plantilla sobre el drop del zapato), la inclinación queda metida en el offset.
  - La calibración no se guarda (l.132), así que después no hay cómo deshacerlo.
- **Fondo de escala del MPU-6050.** No lo fija ningún documento.
  - El valor de arranque (±2 g, ±250 °/s) satura con el pie en marcha, y de él dependen las escalas int16.
  - Conviene fijarlo (por ejemplo, ±16 g y ±2000 °/s) y agregar al piloto un chequeo de saturación.

#### 4. Emparejamiento BLE en la mínima
*Antes de f4 (7/12).*

- **Sin gesto no hay re-emparejamiento.** El cronograma pasa a trabajo futuro el gesto y el multi-host, pero ADR-028 (bitácora l.825) y las Vistas 1 y 2 siguen usando el gesto como única forma de entrar en pairing cuando ya hay un bond. No está definido cómo acepta la cintura una segunda laptop (son dos autores) ni qué pasa si se pierde un bond. El "borrar todo" también quedó para la máxima.
- **El passkey no se puede tipear en la app.** Revisé el código de bleak para Windows: `pair()` sólo usa `CONFIRM_ONLY`, con el comentario *"Currently only supporting Just Works solutions"*. ADR-028 descarta justamente Just Works, así que el passkey se va a tipear en el diálogo del sistema operativo.
- **Opciones:** aceptar un emparejamiento con passkey cuando no hay ninguna conexión activa, guardar un bond por laptop, o borrar los bonds con un comando por USB.

#### Además, tres decisiones chicas para f1 (16–22/11)
- **Qué plantilla es cuál.** `device_id` no tiene códigos y hay un solo firmware de plantilla. Sin eso, el host no puede completar `device_set` ni `strides.foot`.
- **Cuándo corre el stream.** SPEC-11 no tiene un comando que lo prenda, ni para pasar de `ARMED` a `RUNNING`. Por ejemplo, que corra sólo entre `arm()` y `close()`.
- **Muestras por datagrama UDP.** 1 o 4 muestras por datagrama son 200 o 50 paquetes/s de WiFi. Es justo lo que tiene que medir la prueba de coexistencia del 22/11.

### Lo que puede esperar a la Fase 2 (19/12) o a la Fase 4
- **CP-35 condiciona la Fase 2.** Con cuentas crudas, el cruce de MS depende del cero de cada sensor, que cambia de una sesión a otra. Como mínimo hay que restar el cero. Ya está agendada para el 22/11.
- **MS con apoyo de antepié.** Si el contacto arranca por el antepié, SPEC-01 da MS = IC y la sub-fase de carga queda vacía. Con *foot drop* simulado en el protocolo, no va a ser un caso raro.
- **Fórmulas del catálogo.**
  - El LDLJ de #32–34 (`3_analisis_features_y_algoritmos.md:88`) no es adimensional: multiplica por el pico, cuando la forma estándar divide por el pico al cuadrado. Hay que verificarlo contra Brasiliano y contra Melendez-Calderón (2021).
  - El bloque H se calcula por ventana, pero `feature_vectors` sólo admite zancada o ciclo.
  - A #19, #21 y #20/#40 les falta la fórmula exacta.
- **Fase 4.**
  - Las zancadas con IC de baja confianza quedan fuera de las ventanas, y la confirmación por IMU busca la firma de la marcha normal. Una anomalía inducida puede, entonces, excluirse sola del scoring.
  - Con todo el set activo, la covarianza de Mahalanobis es singular, porque #1 = #2 + #3.

### Las 13 cuestiones abiertas

| CP | Qué frena |
|---|---|
| 18 | Las capturas con personas |
| 33 | El esquema y la UI de la Fase 1 (punto 2); el firmware no |
| 35 | La Fase 2; la captura no |
| 25 | El protocolo y las capturas; el código no, porque el criterio lo aplica el host y se ajusta sin reflashear |
| 37 | La Fase 4 |
| 01, 21, 22 | Nada de la mínima. CLAUDE.md exagera la alerta de CP-21: el demostrador no usa TFLite Micro |
| 06, 09, 20, 28, 32 | La máxima |

### Correcciones de una línea (no son cuestiones pendientes)
- La ruta del Parquet (`schema.sql:131`) no lleva `kind`, así que el tramo N del registro de sincronización pisa al tramo N de las muestras.
- `raw_blobs` no le da UPDATE a `authenticated` (`schema.sql:563`), mientras ADR-047 dice que sí. El upsert del host va a fallar.
- `adaptation_enabled` tiene `default true` (`schema.sql:81`), aunque la adaptación quedó fuera de alcance.
- `device_status` exige una sesión, así que el warm-up anterior no se graba.
- La Vista 2 dice "OTA completo desde el inicio" (`2_vista_firmware.md:90`).

Dejé afuera, por menores o por ser parámetros de implementación, el período del beacon, el mensaje de heartbeat, la lectura de VSYS y lo que el diseño ya deja para el piloto.

No modifiqué el repo. Siguiendo la regla de consultar antes de decidir, ninguna de estas decisiones se escribe como ADR sin el OK de ustedes. Guardé un resumen en la memoria, por si esta sesión se corta antes de registrarlas.

*(Recuadro de cierre de la app: "Terminó la auditoría con cinco agentes: nada impide arrancar el 16/11, pero el recorte de alcance del cronograma no llegó a los documentos y quedan cuatro decisiones para las dos primeras semanas. No edité el repo; los hallazgos todavía no están registrados como cuestiones pendientes." Pregunta: **¿Registro las cuatro decisiones como cuestiones pendientes?** — botones "Sí, registralas" / "Empezá por la 1".)*

---

## Mensaje 3 — Tobías

Citó partes de la respuesta anterior y pidió explicarlas:
- Punto 1 completo → *"Explicame todo esto de forma más sencilla y con más contexto."*
- Punto 2 completo → *"esto también explicalo más simple y con más contexto."*
- Punto 3 (marco y ángulos; offset nivelado) → *"esto también, explicalo más sencillo, más simple y dándome más contexto."*
- La parte del passkey y bleak → *"Esto no sé que es."*
- La parte del gesto y el re-emparejamiento → *"esto tampoco lo entiendo"*
- Punto 4 completo → *"Volvé a explicarlo pero más sencillo y con más contexto"*

> Todo lo que te pedí que expliques se lo más breve posible pero que se entienda lo más posible.

## Respuesta del agente

**Es el último mensaje: está tal cual en `03_ultimo_mensaje.md`.**

---

## Mensaje 4 — Tobías

> Subí todo lo que encontraron los subagentes y todo nuestro chat a una carpeta con un readme al repo, commitealo y pushealo directo, tiene que tener un readme, el unico motivo de esto es que otro agente pueda adquirir el contexto y retomar exactamente en este último mensaje que dejamos y me lo pueda dar para que yo lo lea tal cuál desde la otra compu con otro claude. en el readme tiene que estar que es lo que tiene que hacer el otro agente. Después de pushearlo decime que le digo al otro agente para que retomemos la conversación.

[El agente creó esta carpeta, la commiteó y la pusheó.]
