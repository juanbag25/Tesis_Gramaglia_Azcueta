# Bitácora de decisiones de arquitectura

> **Propósito.** Este archivo registra **cada decisión de arquitectura**, el contexto en que surgió, las **opciones evaluadas con sus pros y contras**, la decisión tomada y su justificación. Se construye de forma incremental a lo largo del proyecto. El objetivo final es **alimentar el informe de la tesis** y poder **justificar cada elección** con trazabilidad completa.
>
> **Formato:** cada entrada es un ADR (*Architecture Decision Record*). Estados posibles: `propuesta`, `aceptada`, `revisada`, `reemplazada`.
>
> **Cómo mantenerlo (para agentes y humanos):** al tomar una decisión nueva o cambiar una existente, agregar/editar un ADR aquí, actualizar el `Resumen de decisiones` del documento de arquitectura y registrar el cambio en `memoria/changelog.md`.

---

## Índice de decisiones

| ADR | Tema | Decisión | Estado |
|---|---|---|---|
| 000 | Contexto y filosofía | Personalización + bilateral + edge | aceptada |
| 001 | Topología plantillas↔cintura | WiFi, cintura como AP | aceptada |
| 002 | Uplink cintura↔host | BLE desde la mínima | aceptada |
| 003 | Transporte | UDP stream + TCP control (GATT notif/writes en BLE) | aceptada |
| 004 | Sincronización temporal | Backbone de reloj (timestamp+seq+beacon+drift) + emparejado por evento | aceptada |
| 005 | Cálculo de features | Dual-mode (captura/edge) + cintura como hub | aceptada |
| 006 | Hosting / base de datos | Supabase | aceptada |
| 007 | Modelo de datos | Postgres + TimescaleDB + object storage | aceptada |
| 008 | Retención de datos | Tiered por fase | aceptada |
| 009 | Backend de reentrenamiento (máxima) | Worker en la nube | aceptada |
| 010 | Firmware on-device | C/C++ con Pico SDK | aceptada |
| 011 | Ruteo de modelos | Clase declarada en el registry (L/E/W) | aceptada |
| 012 | OTA de modelos | Pesos + firmware completo (A/B) | aceptada |

---

## ADR-000 — Contexto y filosofía del sistema
**Estado:** aceptada

**Contexto.** Sistema de plantillas inteligentes bilaterales para detección personalizada de anomalías de marcha post-ACV, con feedback vibrotáctil y edge inference. Hardware: 2 plantillas (Pico 2 W + MPU-6050 + 3 FSR + motor PWM) y 1 unidad de cintura (Pico 2 W + MPU-6050), muestreo 100 Hz.

**Decisión / principios.**
- **Personalización primero:** baseline por paciente (one-class), no modelo poblacional.
- **Bilateral:** explotar la simetría inter-miembro como diferencial clínico.
- **Edge:** inferencia on-device por latencia y privacidad.
- **Dos horizontes:** mínima (entorno controlado, laptop) y máxima (uso diario, celular + nube), donde la mínima escala hacia la máxima sin reescrituras estructurales.

**Justificación.** Evidencia de la literatura: modelos personalizados AUC≈0,97 vs. ~55 % de los globales (Toth et al.). La heterogeneidad inter-paciente en ACV hace inviable un baseline poblacional.

---

## ADR-001 — Topología: enlace plantillas ↔ cintura
**Estado:** aceptada — **Decisión: WiFi, cintura como Access Point (AP)**

**Contexto.** Las dos plantillas deben enviar sus datos a la cintura, que los recibe simultáneamente y luego los reenvía al host. Se necesitaba definir cómo se conectan los tres micros (y, en la mínima, la laptop). Aclaración conceptual establecida: en WiFi un dispositivo es **AP** (crea y hostea la red, como un router) o **STA/estación** (se une a una red existente, como un cliente). El Pico 2 W (chip CYW43439) puede ser AP o STA; el modo **concurrente AP+STA** existe en el silicio pero su soporte en el SDK del Pico es inmaduro y frágil.

**Opciones evaluadas.**
- **A — Cintura = AP única.** Plantillas (STA) y laptop se conectan a la red que crea la cintura. *Pros:* topología estrella single-hop, autónoma y portátil, sin router, la fusión ocurre donde convergen los datos. *Contra:* el adaptador WiFi de la laptop queda ocupado en esa red → sin internet por ahí (se resolvía con 2ª vía o buffer local). *(Este contra desaparece al elegir BLE para el uplink — ver ADR-002.)*
- **B — Cintura AP + STA concurrente.** Cintura AP para las plantillas y a la vez cliente del WiFi de casa para llegar a la laptop. *Pros:* la laptop mantiene internet. *Contra:* el modo concurrente en el Pico es frágil.
- **C — Todos a un router externo.** Los 3 micros y la laptop a un WiFi de infraestructura. *Pros:* todos con internet. *Contra:* requiere *provisioning* de credenciales al Pico en cada lugar nuevo.

**Decisión.** El enlace plantillas↔cintura es **WiFi con la cintura como AP**. Este enlace es **permanente**: no cambia entre mínima y máxima (en la máxima sólo cambia el enlace cintura↔host).

**Justificación.** Single-hop star minimiza complejidad, no depende de infraestructura externa (funciona en cualquier lado) y coloca la fusión bilateral donde los datos ya coinciden. El rol de AP de la cintura es un invariante del sistema.

**Consecuencias.** La cintura es el hub natural de cómputo (ADR-005). El *provisioning* (opción C) queda documentado como extensión futura, no requerido para el alcance actual.

---

## ADR-002 — Uplink: enlace cintura ↔ host
**Estado:** aceptada — **Decisión: BLE desde la mínima**

**Contexto.** En la máxima, el host es un celular que se comunica con la cintura por Bluetooth (BLE). La pregunta fue si en la mínima conviene usar WiFi (más rápido de cablear) o ya BLE (más fiel al final). Criterio planteado por Juan: hacer BLE ahora sólo tiene sentido **si la infraestructura del lado del micro es la misma** mande a una laptop o a un celular.

**Dato técnico decisivo.** La infraestructura del micro **es la misma**: el Pico actúa como **periférico BLE (servidor GATT)** y es **agnóstico al central** que se conecta (laptop o celular). La definición de servicios/características y las notificaciones son idénticas; **lo único que cambia es el cliente** (app de laptop con `bleak` vs. app móvil), que se reescribe igual. Matiz: conviene diseñar desde el inicio a las **restricciones del celular** (MTU BLE ~185 B en iOS, límites de connection-interval) para no sobre-ajustar a la BLE más permisiva de una laptop.

**Opciones evaluadas.**
- **A — WiFi ahora, BLE en la máxima (abstraído).** *Pros:* camino más corto al dataset, sin coexistencia. *Contra:* el enlace WiFi cintura↔host es "de un solo uso" (se reemplaza por BLE); la coexistencia aparece recién en la máxima.
- **B — BLE desde la mínima.** *Pros:* el firmware BLE de la cintura se **reutiliza al 100 %** en la máxima; se enfrenta **temprano** la coexistencia WiFi-AP+BLE; el caudal (~5 KB/s) sobra para BLE. *Contra:* modelo de programación más limitado (GATT) y algo más lento a "primer dato".

**Decisión.** **BLE desde la mínima**, detrás de una interfaz de transporte que aísle el uplink.

**Justificación.** Como la infraestructura del micro es idéntica para laptop y celular, BLE-ahora no es trabajo tirado y de-riskea el mayor desafío técnico de la máxima (la coexistencia). El ancho de banda no es limitante.

**Consecuencias.** Beneficio colateral: al no ocupar el WiFi de la laptop, **la laptop conserva internet** para empujar datos a la base remota. La coexistencia WiFi-AP + BLE en el CYW43439 se asume como riesgo a validar temprano (ver Riesgos en el documento de arquitectura).

---

## ADR-003 — Transporte
**Estado:** aceptada — **Decisión: canal rápido-tolerante + canal confiable**

**Contexto.** El stream es de 100 Hz; además hay que transferir modelos/config con integridad.

**Opciones evaluadas (WiFi).**
- **UDP.** *Pros:* latencia mínima, sin handshake ni retransmisión; ideal para telemetría continua donde perder una muestra no importa (la próxima llega en 10 ms); soporta broadcast (útil para el beacon de sync). *Contra:* paquetes se pueden perder/duplicar/desordenar; requiere nº de secuencia + timestamp propios; malo para transferir archivos de modelo.
- **TCP.** *Pros:* entrega garantizada, en orden, con integridad; trivial para modelos y almacenamiento. *Contra:* *head-of-line blocking* — un paquete perdido frena todo lo posterior → picos de latencia justo en el peor momento del stream.

**Decisión.** **Híbrido:** **UDP para el stream** (con nº de secuencia + timestamp por muestra) + **TCP para control/modelos**. Sobre BLE, el mismo principio: **notificaciones GATT** (análogo a UDP) para el stream + **writes con ACK/indicaciones** (análogo a TCP) para control.

**Justificación.** Es el patrón estándar en robótica/telemetría: cada canal hace lo que sabe hacer. El ancho de banda del crudo (~3,6 KB/s de payload) es despreciable sobre WiFi.

**Consecuencias.** El nº de secuencia + timestamp por muestra habilita la sincronización (ADR-004) y la detección de pérdidas.

---

## ADR-004 — Sincronización temporal
**Estado:** aceptada — **Decisión: backbone de reloj (timestamp+seq+beacon+drift) + emparejado por evento (refinamiento)**

**Contexto.** La simetría inter-miembro exige relacionar ambos pies sobre una **misma línea de tiempo a nivel de muestra**. Muchas features se calculan sobre **ventanas deslizantes de la señal bilateral** o requieren **simultaneidad** (double support = ambos pies en contacto a la vez; COP-ML velocity y zero-crossings; LDLJ; entropías; PSD; variabilidad sobre 10+ zancadas). Problemas de reloj: **offset** (relojes que arrancan distinto) y **skew/drift** (cristales a ritmos algo distintos, ~±0,2 ms/min).

**Investigación de industria/literatura realizada.**
- **Protocolos clásicos de WSN (FTSP, RBS, TPSN):** dependen de timestamping a nivel MAC y acceso de bajo nivel que la mayoría de los IMU inalámbricos (y el stack del Pico) no exponen, y cuestan cómputo/batería. RBS (broadcast de referencia) es ideal para single-hop (nuestro caso); TPSN es para multi-hop (no lo necesitamos).
- **Sync a nivel de aplicación sobre BLE:** trabajos recientes logran alineación **sin hardware extra, portable entre fabricantes**, convirtiendo el delay aleatorio del connection-event en uno estable → **precisión ~20 µs**.
- **Beacon + corrección de drift por regresión lineal:** versión práctica y liviana usada en plataformas multi-IMU.
- **Alineación por señal/eventos:** por magnetómetro (sacudir los IMU juntos) o por eventos de marcha; hay métodos que toleran sampling variable, delay aleatorio y pérdida de paquetes.
- **Producto comparable (Moticon, plantillas bilaterales → celular por BLE):** las plantillas **se sincronizan entre sí y mantienen la sync durante toda la grabación**; exige usarlas de a pares. Dato honesto: plantillas bilaterales que mandan por WiFi muestran **offset izq/der perceptible** con alineación por sólo-llegada.

**Opciones evaluadas (fuerza del backbone de reloj).**
- **Solo arrival time.** La cintura alinea por llegada. *Pros:* lo más simple. *Contra:* offset izq/der medible (literatura), sin proteger paquetes demorados.
- **Timestamp propio + secuencia.** Alinea por instante de generación. *Pros:* un paquete demorado igual cae en su lugar; costo casi nulo. *Contra:* queda algo de drift no corregido.
- **Beacon + drift (elegida).** Timestamp+seq + beacon periódico de la cintura (estilo RBS / app-layer BLE) + corrección de drift por regresión. *Pros:* línea de tiempo común robusta, portable WiFi↔BLE (capa app), precisión de decenas de µs. *Contra:* más firmware.

**Capa de refinamiento: emparejado por evento (IC).** Sobre el backbone se emparejan zancadas por **contacto inicial (IC)** — el instante en que el pie empieza a cargar (umbral de FSR + pico de IMU), **no** un "talón primero" prolijo.

**Aclaración conceptual importante (corrección registrada).** Inicialmente se planteó que "para las features el emparejado por evento alcanza". **Es incorrecto:** el evento IC **no sincroniza relojes** — empareja *zancadas*. Las features de ventana y de simultaneidad (double support, COP dynamics, frecuencia/entropía, variabilidad multi-zancada) **necesitan el timeline a nivel de muestra** que da el backbone de reloj. Por lo tanto:
- El **backbone de reloj es el mecanismo primario** (hace el trabajo pesado).
- El **emparejado por evento es refinamiento**: sirve para la simetría *por zancada* (Symmetry Index) y como *cross-check* si el reloj driftea; **degrada con gracia** (si el IC no es fiable en un paciente, se cae a reloj solo). Cada pie se segmenta con su propia señal (un pie anómalo no ensucia al otro). Como el IC ya se detecta para las features espacio-temporales, reutilizarlo es **gratuito**.

**Sobre patología (duda planteada):** un IC anómalo (reducido, ausente, demorado, asimétrico) **es parte de la señal de anomalía** y se mide como feature. Usar el IC como marca temporal (sólo su índice) no entra en conflicto con medir su morfología como feature de detección — son usos distintos, sin circularidad.

**Decisión.** **Backbone fuerte (Beacon + drift) + emparejado por evento como refinamiento.**

**Justificación.** Es la opción "grado producto", alineada con Moticon y con los papers de sync app-layer BLE, y portable entre WiFi (mínima) y BLE (máxima). Cubre tanto las features de ventana/simultaneidad (por el reloj) como la simetría por zancada (por eventos).

**Fuentes de la investigación.**
- *Time Sync Wireless IMU for Gait* — IEEE Xplore 10302652.
- *Wireless Low-Latency Sync Body-Worn Multi-IMU* — arXiv 2509.06541.
- *Sync of Wearable IMUs via magnetometer* — arXiv 2107.03147.
- *App-Layer Time Sync & Data Alignment over BLE* — MDPI Sensors 23:3954.
- *Comparison of BLE sync/alignment methods* — PMC10007376.
- *TPSN* — ACM 10.1145/958491.958508.
- *Synchronized multi-unit IMU platform* — MDPI Electronics 9:1118.
- *Moticon SDKs & sync* — moticon.com/solutions-integrations.

---

## ADR-005 — Cálculo de features y hub de cómputo
**Estado:** aceptada — **Decisión: dual-mode (captura/edge) + cintura como hub, definición de features compartida**

**Contexto.** Se preguntó dónde se calculan las features. Juan eligió inicialmente "todo crudo → computadora", correcto para la **fase de entrenamiento/evaluación**. Pero los algoritmos de clase L/E corren en el micro, así que en algún momento hay que calcular features on-device.

**Opciones evaluadas (dónde se calculan features).**
- **Plantilla calcula, cintura fusiona.** Poco ancho de banda; más firmware distribuido.
- **Plantillas crudo → cintura calcula.** Más ancho de banda (irrelevante sobre WiFi); lógica centralizada, más fácil de depurar.
- **Todo crudo → computadora (elegida para captura).** Ideal para dataset/evaluación; no escala al uso real en el borde.

**Decisión.** **Dos modos con una única definición de features compartida** (misma fórmula en PC y micro, versionada por `feature_set_version`):
- **Modo captura:** plantillas → crudo → cintura → host → base. Para construir dataset y evaluar algoritmos.
- **Modo edge:** la **cintura calcula features + detección on-device** y emite features/scores (+ crudo puntual ante anomalías). Habilita el uso sin computadora (máxima) y las clases L/E.

**Cintura como hub de cómputo.** Como ambos flujos convergen en la cintura, ésta es el hub: recibe crudo de ambas plantillas, mantiene el timeline, detecta eventos, calcula features bilaterales, corre los detectores L/E y decide el feedback. Las plantillas quedan como sensores de alta calidad (simplifica su firmware). Carga liviana: features por zancada (~1 Hz de decisiones), inferencia int8 sobre ~25 features es mínima.

**Camino de feedback.** El detector corre en la cintura pero el motor está en las plantillas → el enlace plantillas↔cintura es **bidireccional** (datos arriba, comando de feedback abajo). La *política* de feedback es lógica de aplicación, fuera del alcance de infraestructura.

**Consecuencias.** Punto abierto: "cintura como hub" vs "features en cada plantilla" — a ratificar contra la carga real de firmware.

---

## ADR-006 — Hosting / base de datos
**Estado:** aceptada — **Decisión: Supabase**

**Contexto.** Los datos se guardan en una base **remota** (no en la computadora), organizados por paciente; los modelos también se respaldan. Aclaración: "backend" son tres roles — **acceso a datos (API)**, **ingesta** y **cómputo de entrenamiento**. Supabase provee la API y el store; **no** entrena modelos (eso corre en un worker separado: la laptop en la mínima, la nube en la máxima). Elegir Supabase **no ata** dónde se entrena (desacoplados).

**Opciones evaluadas.**
- **A — Supabase (elegida).** Postgres gestionado + object storage + API REST/realtime autogenerada + auth. *Pros:* mínimo DevOps, free tier, Postgres real y extensible (Timescale), API/auth listos, RLS por paciente. *Contra:* el free tier tiene límites; el reentrenamiento pesado corre afuera.
- **B — VPS self-managed (Hostinger/DO).** *Pros:* control total, costo fijo bajo. *Contra:* sos el sysadmin (updates, backups, seguridad).
- **C — Cloud mayor (AWS RDS + S3).** *Pros:* escala/servicios ilimitados. *Contra:* complejo, costo variable, overkill.
- **D — Firebase (Firestore + Storage).** *Pros:* cómodo para móvil, realtime. *Contra:* NoSQL documental — mal ajuste para series 100 Hz y consultas analíticas, factura por operación.

**Decisión.** **Supabase** como sistema de registro (DB + storage + API + auth); entrenamiento en worker aparte.

**Justificación.** Mejor relación esfuerzo/beneficio para una tesis: Postgres real, mínima operación, escalado limpio a la máxima.

---

## ADR-007 — Modelo de datos
**Estado:** aceptada — **Decisión: PostgreSQL + TimescaleDB + object storage**

**Contexto.** Datos heterogéneos: metadata (relacional, poco volumen), crudo 100 Hz (series, mucho volumen), features (medio), modelos (binarios).

**Opciones evaluadas.**
- **A — Postgres + TimescaleDB + object storage (elegida).** Relacional para metadata/features; hypertables de Timescale (particionado por tiempo + compresión) para series; blobs de modelos en object storage. *Pros:* un solo mundo SQL, performance/compresión para el crudo, escalable. *Contra:* una extensión más; storage es un segundo sistema (trivial).
- **B — Postgres puro (+ JSONB).** *Pros:* lo más simple. *Contra:* el crudo escala peor; se le activa Timescale después.
- **C — Políglota (InfluxDB + Postgres + S3).** *Pros:* best-in-class por tipo. *Contra:* tres sistemas que operar/sincronizar; se justifica sólo a gran escala.

**Decisión.** **Postgres + TimescaleDB + object storage.**

**Justificación.** Potente y ordenado sin salir de SQL; camino de migración natural desde Postgres puro si se quisiera empezar más simple.

---

## ADR-008 — Retención de datos
**Estado:** aceptada — **Decisión: tiered por fase (desde el inicio)**

**Contexto.** Estimaciones de volumen: ~5 KB/s → sesión de 30 min ≈ 9 MB crudo (comprimido 2–4 MB). El crudo **no es pesado** para una cohorte de investigación, pero en **uso diario continuo** llega a ~4 GB/mes/paciente — ese es el driver de costo.

**Opciones evaluadas.**
- **A — Guardar todo siempre.** *Pros:* máxima trazabilidad (re-extraer features, reevaluar algoritmos). *Contra:* costo y superficie de privacidad altos en uso diario.
- **B — Tiered por fase (elegida).** En dataset: crudo completo. En uso rutinario: sólo features/eventos/scores, y crudo **sólo alrededor de anomalías/drift** (buffer circular disparado). *Pros:* ahorro enorme conservando lo clínicamente interesante; mejor privacidad; encaja con el sensor de drift de Mahalanobis. *Contra:* no se pueden re-extraer features de los tramos normales.
- **C — Sólo derivados (nunca crudo remoto).** *Pros:* mínimo costo, máxima privacidad. *Contra:* cero re-extracción; demasiado limitante mientras se exploran features/algoritmos.

**Decisión.** **Tiered por fase desde el inicio** (crudo completo en dataset; features + crudo-por-anomalía en uso real).

**Justificación.** Balancea trazabilidad (donde importa) con costo/privacidad (en uso diario). Se apoya en la señal de drift que ya se calcula.

---

## ADR-009 — Backend de reentrenamiento (máxima)
**Estado:** aceptada — **Decisión: worker en la nube (para clases E/W); el micro mantiene la clase L**

**Contexto.** En la máxima la laptop se reemplaza por el celular. La duda: ¿el reentrenamiento corre local en el celular o en un servidor aparte? Tier 1 (clase L, ej. Mahalanobis EMA) **ya corre en el micro** y no necesita backend.

**Opciones evaluadas.**
- **A — Celular local (on-device).** *Pros:* offline, máxima privacidad, sin costo de servidor, loop de baja latencia. *Contra:* límites de CPU/batería — el LSTM es impráctico; difícil mantener en celulares dispares.
- **B — Worker en la nube (elegida).** *Pros:* cómputo sin límites (incluido el pesado), un solo codebase, sirve a todos los pacientes. *Contra:* costo/ops de servidor, requiere conectividad, el dato sale al server (mitigado: Supabase ya lo tiene).
- **C — Híbrido (liviano en celu, pesado en nube).** *Pros:* mapea 1:1 con los tiers. *Contra:* más ingeniería (dos caminos de entrenamiento).

**Decisión.** **Worker en la nube** como default para todo lo que "necesita computadora" (clases E/W); el micro conserva la clase L. Evolucionar a híbrido (C) si se quiere adaptación de clase E más rápida/offline en el celular.

**Justificación.** Cómputo sin límites para lo pesado, con lo simple resuelto localmente en el micro.

---

## ADR-010 — Firmware on-device
**Estado:** aceptada — **Decisión: C/C++ con el Pico SDK**

**Contexto.** Los 3 micros deben muestrear 9 canales a 100 Hz, detectar eventos + calcular features (edge), correr inferencia int8 (cintura), atacar el motor y manejar WiFi-AP/STA + BLE con coexistencia.

**Opciones evaluadas.**
- **C/C++ (Pico SDK) (elegida).** *Pros:* máximo rendimiento y control (dual-core, PIO, DMA, lwIP, BTstack, TFLite Micro para int8) — lo que pide ML on-device + coexistencia + 100 Hz duro. *Contra:* más esfuerzo de desarrollo.
- **Arduino-pico (C++).** *Pros:* ergonomía y librerías. *Contra:* menos control de bajo nivel; PIO/TFLite Micro requieren trabajo extra.
- **MicroPython → C/C++.** *Pros:* prototipado rápido. *Contra:* GC y velocidad ponen en riesgo el timing de 100 Hz y el ML on-device; implica reescritura.

**Decisión.** **C/C++ con el Pico SDK "posta"** (no Arduino IDE) desde el inicio.

**Justificación.** Es el único stack que sostiene cómodamente ML on-device + coexistencia + tiempo real duro sin peleas.

---

## ADR-011 — Ruteo de modelos (taxonomía L/E/W)
**Estado:** aceptada — **Decisión: cada modelo declara su clase en el registry (model-agnostic)**

**Contexto.** Advertencia de Juan: hay modelos probabilísticos **muy sencillos** que se reentrenan **dato a dato en el micro** y no deben ir al worker. El reparto depende de qué modelos se prueben, así que la arquitectura no debe hardcodearlos.

**Taxonomía adoptada (dos ejes: dónde infiere × dónde/con qué granularidad reentrena).**
| Clase | Inferencia | Reentrena | Granularidad | Ejemplos | ¿OTA? |
|---|---|---|---|---|---|
| **L — Local-Local** | Micro | Micro | Dato a dato | Mahalanobis EMA, z-score/EWMA, probabilísticos simples | No (se auto-actualiza) |
| **E — Edge+Worker** | Micro (int8) | Worker | Periódico/async | Autoencoder denso int8, LSTM chico | Sí |
| **W — Worker-heavy** | Worker (o micro si entra) | Worker | Periódico/async | LSTM AE grande, Isolation Forest | Sí |

**Opciones evaluadas.**
- **Registry declara la clase (elegida).** Cada fila de `models` declara `(class, inference_target, retrain_target, granularity)`; el runtime rutea solo. *Pros:* agnóstico al modelo — sumar un modelo = declarar su clase; los L reentrenan en el micro sin tocar el worker. *Contra:* un poco más de metadata.
- **Hardcodear candidatos.** *Pros:* simple hoy. *Contra:* cada modelo nuevo obliga a tocar la lógica de ruteo.

**Decisión.** **Clase declarada en el registry.** Mahalanobis además actúa como **sensor de drift** que dispara el reentrenamiento de E/W; los L no necesitan disparo.

**Justificación.** Robustez a la incertidumbre sobre qué algoritmos ganarán: la infra soporta todos los caminos de antemano.

---

## ADR-012 — OTA de modelos y firmware
**Estado:** aceptada — **Decisión: OTA de pesos + firmware completo, con esquema A/B**

**Contexto.** Cuando un modelo se reentrena fuera del micro, hay que enviarle los pesos nuevos; además conviene poder arreglar el firmware en equipos desplegados en casa del paciente. **OTA** = actualizar el micro sin cable, por BLE/WiFi.

**Opciones evaluadas.**
- **Weights-only + rollback A/B.** Sólo se envían los parámetros del modelo (Mahalanobis = media + inversa de covarianza; AE/LSTM = flatbuffer int8) a un slot, con checksum, cambio atómico y last-known-good. *Pros:* simple, de bajo riesgo (no brickea), cubre el reentrenamiento. *Contra:* no arregla bugs de firmware; si cambia la *arquitectura* del modelo, el código de inferencia también.
- **Weights + firmware OTA completo (elegida).** Suma un **bootloader A/B** que mantiene dos imágenes de firmware, arranca la nueva y revierte si no reporta OK. *Pros:* fix/inferencia remotos sin cable — imprescindible en casa del paciente. *Contra:* más complejo (bootloader robusto) y con riesgo de brickeo ante fallos de energía/bootloader; más flash.

**Decisión.** **OTA completo (pesos + firmware) con A/B desde el inicio**, mitigando el riesgo con A/B, checksum, watchdog y modo de recuperación.

**Justificación.** El uso desatendido en casa (máxima) hace que actualizar firmware por aire sea muy valioso; construirlo desde el inicio evita retrofits riesgosos. El respaldo de todo modelo en la base (registry + artifact) garantiza recuperación ante pérdida/rotura del micro.

---

## Puntos abiertos (a ratificar)

Se llevan en el registro vivo **`docs/cuestiones_pendientes.md`** (única fuente de verdad, IDs CP-01 a CP-06). Cuando una cuestión se resuelve mediante una decisión de arquitectura, se cierra allí y se agrega/actualiza el ADR correspondiente en esta bitácora.
