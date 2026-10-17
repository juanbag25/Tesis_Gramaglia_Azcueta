# Bitácora de decisiones de arquitectura

> **Propósito.** Este archivo registra **cada decisión de arquitectura**, el contexto en que surgió, las **opciones evaluadas con sus pros y contras**, la decisión tomada y su justificación. Se construye de forma incremental a lo largo del proyecto. El objetivo final es **alimentar el informe de la tesis** y poder **justificar cada elección** con trazabilidad completa.
>
> **Formato:** cada entrada es un ADR (*Architecture Decision Record*). Estados posibles: `propuesta`, `aceptada`, `revisada`, `reemplazada`.
>
> **Cómo mantenerlo (para agentes y humanos):** al tomar una decisión nueva o cambiar una existente, agregar/editar un ADR aquí **y su fila en el índice**, y registrar el cambio en `memoria/changelog.md`. *(El "Resumen de decisiones" del documento de arquitectura ya no existe: lo eliminó ADR-039.)*

---

## Índice de decisiones

| ADR | Tema | Decisión | Estado |
|---|---|---|---|
| 000 | Contexto y filosofía | Personalización + bilateral + edge | aceptada |
| 001 | Topología plantillas↔cintura | WiFi, cintura como AP | aceptada |
| 002 | Uplink cintura↔host | BLE desde la mínima | aceptada |
| 003 | Transporte | UDP stream + TCP control (GATT notif/writes en BLE) | aceptada |
| 004 | Sincronización temporal | Backbone de reloj (timestamp+seq+beacon+drift) + emparejado por evento | aceptada |
| 005 | Cálculo de features | Distribuido: por-pie en plantillas, fusión bilateral en cintura; captura por fases | aceptada (rev. 2026-07-19) |
| 006 | Hosting / base de datos | Supabase | aceptada |
| 007 | Modelo de datos | Postgres + TimescaleDB + object storage — **capa de series revisada por ADR-044** (particionado nativo + `pg_partman`) | revisada (ADR-044) |
| 008 | Retención de datos | Tiered por fase | aceptada |
| 009 | Backend de reentrenamiento (máxima) | Worker en la nube | aceptada |
| 010 | Firmware on-device | C/C++ con Pico SDK | aceptada |
| 011 | Ruteo de modelos | Clase declarada en el registry (L/E/H/W); ruteo de inferencia micro→host model-agnostic | aceptada (rev. 2026-07-19) |
| 012 | OTA de modelos | Pesos + firmware completo (A/B) | aceptada |
| 013 | Inferencia en tiempo real | En `hub` o `host`; nunca en el worker/nube | aceptada |
| 014 | Adquisición / muestreo | ADC HW-paced + DMA, sobremuestreo 1 kHz → decimación a 100 Hz; IMU en tick maestro | aceptada |
| 015 | Detección de eventos IC/TO | Fusión FSR + IMU; en la plantilla (per-pie); resuelve CP-03 | aceptada |
| 016 | Largo de zancada (stride length) | Doble integración + ZUPT (stance por FSR), por zancada; EKF/MSDI futuro | aceptada |
| 017 | Módulo IMU (orientación/gravedad/calibración) | Módulo compartido; Fusion/Madgwick (C+Python); calibración estática + re-zero en stance | aceptada |
| 018 | Paridad de features PC↔micro | Tests de paridad en CI + entrenar con features del micro (de captura operativa) + tolerancias (anti train/serve skew) | aceptada (acl. 2026-07-19) |
| 019 | DSP on-device (FFT/PSD) | CMSIS-DSP (float32); `arm_rfft_fast_f32`; resuelve la fila DSP del stack | aceptada |
| 020 | Runtime de inferencia int8 | TFLite Micro + CMSIS-NN (NN on-device); Mahalanobis en CMSIS-DSP; IF por árboles en C | aceptada |
| 021 | Catálogo de features + paridad | Catálogo declarativo (data file) + dos implementaciones (C/Python) + tests de paridad; codegen/C-único descartados | aceptada |
| 022 | Framework de entrenamiento + cuantización | TensorFlow/Keras; PTQ int8 (representative dataset), QAT fallback | aceptada |
| 023 | Alcance inicial de features (2 FSR) | Hardware con 2 FSR (punta+talón); COP_ML (bloque E) y #18 M/L diferidas: definidas pero desactivadas en el set activo | aceptada |
| 024 | Asignación de cores por dispositivo | **Rev 2026-07-20 — reparto uniforme:** core 0 = radio, core 1 = procesamiento (los 3 micros). Plantilla: core 1 = adquisición+eventos+features por-pie / core 0 = WiFi-STA+TX+motor. Cintura: core 1 = inferencia+fusión+IMU+decisión / core 0 = radio (AP+BLE) | aceptada (rev) |
| 025 | Modelo de ejecución del firmware | Bare-metal (Pico SDK, sin RTOS) en ambos firmwares; FreeRTOS evaluado y no adoptado | aceptada |
| 026 | Muestreo y lectura del IMU | Tick maestro (polling 100 Hz) + lectura por DMA; ODR alto + DLPF (sobremuestreo anti-alias); un timestamp por tupla. DATA_READY = fallback (traza en próximo PCB); FIFO descartada. Cintura 100 Hz + DMA (50 Hz fallback #11) | aceptada |
| 027 | Feedback vibrotáctil | Monitor+alerta (no corrige); score designado (`feedback_source`, model-agnostic) evaluado sobre ventana de zancadas → anomalía sostenida → 3 bandas per-paciente → alerta escasa; ambos pies; "riesgo" co-anclado a caída. Modelo/ventana/umbrales empíricos | aceptada |
| 028 | Emparejamiento BLE del wearable (sin botón) | Cintura↔host BLE; auto-advertise sin bond + gesto (sacudir la cintura ~5 s con plantillas quietas); passkey fijo impreso (v1); bond list multi-host N≈4 (LRU/forget); reconexión iniciada por el host, una a la vez. Clear-all y pantalla → máxima. Deps CP-04/CP-15 | aceptada |
| 029 | Ajustes de catálogo y algoritmos (auditoría de alineación) | +4 features (single support, symmetry angle, avg zero-crossings, sway density diferida) + evento mid-stance; candidatos OC-SVM (E/W, benchmark), GMM, VAE; sustitución OC-SVM→Mahalanobis documentada; estrategia progresiva de evaluación | aceptada |
| 030 | Reconciliación anteproyecto/marco con la arquitectura (CP-11) | Registra el delta documental: solo-plantilla→cintura-hub, BMI270→MPU-6050+IMU de cintura, bloque I, algoritmos §4.3 (no §6). El anteproyecto no se modifica (histórico); cierra CP-11. Motivo del MPU-6050: disponibilidad + presupuesto (posible upgrade de IMU a futuro); energía → CP-09 | aceptada |
| 031 | Esquema de `feature_vectors` (CP-05) | **jsonb** (una fila = un vector + `feature_set_version`) + **columnas generadas/índices** para las features calientes del dashboard; puerta de salida a *wide* al congelar el set. Flexible mientras el set cambia; volumen bajo. Cierra CP-05. **Punto 3 (continuous aggregates) reemplazado por ADR-044** | aceptada (pto. 3 reemplazado) |
| 032 | Seguridad y aislamiento de datos (CP-04) | **RLS estricto por paciente** en todas las tablas con `patient_id` + tabla de pertenencia `patient_access` (user→patient→rol); worker con service-role; cifrado tránsito/reposo; `external_code` anónimo + PII mínima; borrado al reasignar. Cierra CP-04 a nivel técnico; nivel formal → comité (CP-18) | aceptada |
| 033 | Interfaces: UI de control + dashboard (CP-15) | **(a) UI de control** = app local Python + UI web (FastAPI sobre el host `bleak`): paciente, sesión, modo de las zapatillas, estado, OTA; máxima → app móvil. **(b) Dashboard clínico** = web solo-lectura sobre Supabase (RLS), **diferido a la máxima** (exploración = notebooks). Cierra CP-15 | aceptada |
| 034 | Switch mínima↔máxima: el micro no detecta el host (CP-16) | **Micro agnóstico al tipo de central** (confirma §2.3): el **flujo lo determina el host** (laptop→worker local / celu→worker nube). El **modo** (exploratoria/operativa/edge) es un **comando explícito**, nunca inferido. El host **declara su tipo** en la metadata de la sesión (trazabilidad, no comportamiento). Cierra CP-16 | aceptada |
| 035 | Encendido/apagado sin botón (CP-19) | **Rev 2026-07-21 — sin gestión de energía en la mínima:** el **switch físico es el encendido/apagado** y todo queda despierto mientras esté encendido (~10 h > objetivo de 8 h, así que dormir no hace falta). **Wake-on-motion y WiFi power-save quedan documentados como opciones para la máxima**, no para la placa nueva: los umbrales de movimiento son poco confiables en marcha hemipléjica y el auto-sleep **hace perder los primeros pasos** tras estar sentado (dato clínicamente valioso). Traza INT del IMU: se mantiene por el DATA_READY de ADR-026, ya **no crítica**. Cierra CP-19 | aceptada (rev) |
| 036 | Fase de captura y origen de las features en el esquema | `sessions.mode` pasa a **tres** valores (`exploratory`/`operational`/`edge`, ADR-005 rev c) y `feature_vectors` suma **`features_source`** (`device`/`offline`): en la fase operativa conviven el vector del micro y el recalculado off-device para la misma zancada, y la paridad (ADR-018) necesita distinguirlos | aceptada |
| 037 | Fuente única del esquema de la base | **`src/db/schema.sql` manda**; el maestro §11.3 deja de duplicar el DDL y pasa a mapa de entidades + puntero. Las dos copias ya habían divergido. Aplica la regla de layering del repo (se define una vez). **Revisada por ADR-045:** la fuente pasa a ser la cadena de migraciones y `schema.sql` un snapshot generado | revisada (ADR-045) |
| 038 | Mid-stance: adopción y partición del apoyo | **Se adopta MS completo.** Detección en la plantilla por **cruce de carga retropié→antepié** (`F_ante ≥ F_post`, confirmado por pie-plano del IMU; flag `no_crossover` = anomalía). Parte el apoyo en **carga**/**propulsión**, instancia #12/#13/#14 por sub-fase y suma **#43** push-off time ratio y **#44** propulsive impulse ratio (catálogo 45→47). Activo con 2 FSR. Cierra la contradicción ADR-029 ↔ SPEC-02 | aceptada |
| 039 | El maestro deja de duplicar las vistas | `Arquitectura_Sistema_Marcha.md` pasa a **índice + overview**: cada sección que replicaba una vista queda en 1-2 párrafos + puntero, y el **§15 "Resumen de decisiones" se reemplaza por un puntero al índice de esta bitácora**. Motivo: **9 de los 14 conflictos** de la auditoría vivían en el maestro, y dos de ellos contradecían invariantes (modelos pesados al worker; IC como fallback de sync). Mismo criterio que ADR-037. 579 → ~300 líneas | aceptada |
| 040 | Bloque I (tronco): definido y ubicado, diferido | I1/I2/I3 → **#45/#46/#47**; el cómputo de tronco se asigna al **core 1 de la cintura** (V2), pero el bloque queda **OFF en el set activo** — se prende cambiando el `feature_set_version`. **SPEC-10** deja las recomendaciones. Principio explicitado por Juan: el catálogo es una **biblioteca de features disponibles**, no una lista de obligaciones. Incluye **apéndice conceptual** (armónicos, cómo se fija el fundamental con la ventana, por qué la asignación par/impar no depende del paciente) | aceptada |
| 041 | Alcance de FSR: hasta 4 (CP-08) | **Máximo de diseño = 4 FSR** por plantilla; la mínima sigue con **2** (punta+talón). El 3º entra en ADC2/GP28 y el **4º obliga a mux analógico**: con GP29 midiendo VSYS quedan sólo 3 ADC libres, y sacrificar VSYS choca con el corte por baja tensión de ADR-035. **Formato de paquete fijado en 4 slots** (400 B/s extra, despreciable) para no versionar el protocolo con hardware sellado. Cierra CP-08 | aceptada |
| 042 | Definición de "crudo" y frontera del IMU | **Crudo = post-AHRS**: `lin_accel` + ω calibrada + `pitch/roll/yaw` + FSR, a 100 Hz. El AHRS corre en el micro; el worker **consume y no re-procesa IMU**. Paquete 29→35 B (+orientación, ~7 KB/s); **39 B / ~7,8 KB/s** sumando `t_device` en `uint64` (punto 6, cierra CP-27). Congela Madgwick/`β` para lo ya capturado (riesgo aceptado). **Corrige SPEC-03** (elimina el "quitar gravedad", que si no metía ~4,9 m de error por zancada) | aceptada |
| 043 | Ciclo de vida de la sesión (multi-paciente + clase L) | La sesión es una **transacción comandada por la interfaz**: check-out del estado L → provisioning → calibración → **gate READY** → running → check-in. **`adaptation_enabled` por sesión** (una versión nueva por sesión adaptada; habilita la comparación con/sin adaptación). Guardas: estampa de `patient_id` en flash + FK compuesta en la base. **Cierra la contradicción del respaldo de clase L**. **Rev:** pipeline de 8 fases, **gate térmico por temperatura del IMU** (el warm-up corre en paralelo al setup), **la DB manda** sobre el flash (copia descartable) y **canal de estado** separado del stream. Cierra CP-24; abre CP-25/CP-31 | aceptada (rev) |
| 044 | Series temporales sin TimescaleDB (CP-26) | **Particionado nativo** de Postgres 17 + `pg_partman` (particiones mensuales creadas por adelantado) + `pg_cron` (mantenimiento diario). Clave de partición = **inicio de la sesión** (la sesión queda entera en una partición, el reenvío no duplica, las FK entre series comparten el valor). Timescale estaba deprecado en Supabase y su edición Apache no tenía continuous aggregates ni compresión. Revisa ADR-007 (capa de series) y reemplaza el punto 3 de ADR-031. Cierra CP-26; abre CP-32 | aceptada |
| 045 | Migraciones versionadas (CP-23) | **CLI de Supabase** en `src/db/supabase/`; cada cambio es una migración nueva que **aplica CI desde `master`**, después de probarla en una base efímera (pgTAP). `schema.sql` pasa a ser un **snapshot generado** (sin las particiones hijas). Una migración aplicada no se edita; la base remota no se toca a mano. Revisa ADR-037. Cierra CP-23 | aceptada |
| 046 | Identidad de las series (CP-29) | **La zancada es una entidad** (`strides`) numerada en el borde: `stride_seq` (plantilla, por pie) y `cycle_seq` (cintura, ciclo bilateral), desde `arm()`. Eventos, vectores y scores se identifican con esos números y se vinculan con **FK reales**; toda fila lleva `patient_id` e inicio de sesión garantizados por una FK a `sessions`. **Ingesta idempotente** (upsert). Suma `flags`. Cierra CP-29 | aceptada |
| 047 | Exposición por la Data API | **Grants explícitos** por rol (`anon`: nada; `authenticated`: no borra; `service_role`: todo), **RLS en todas las tablas expuestas**, particiones sin grants y con RLS, funciones de las políticas en `private` y **suite pgTAP en CI**. Supabase dejó de exponer tablas nuevas por defecto (30/05/2026 y 30/10/2026). Extiende ADR-032 | aceptada |

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
- El **emparejado de zancadas usa el reloj ya sincronizado** — **no** es un mecanismo de sincronización ni un *cross-check* del drift (de eso se encarga el backbone). Sirve para la simetría *por zancada* (Symmetry Index): sobre el timeline común, los tiempos de IC de cada pie asocian la zancada izq↔der. Con los relojes sincronizados (beacon) se emparejan las zancadas; el IC no sincroniza nada. Cada pie se segmenta con su propia señal (un pie anómalo no ensucia al otro). Como el IC ya se detecta para las features espacio-temporales, reutilizarlo es **gratuito**.

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

## ADR-005 — Cálculo de features (distribuido), fases de captura y rol de la cintura
**Estado:** aceptada (rev. 2026-07-19) — **Decisión: features por-pie en las plantillas, fusión bilateral en la cintura; definición compartida; captura por fases (exploratoria crudo-solo / operativa con features del micro)**

**Contexto.** Se preguntó dónde se calculan las features. Juan eligió inicialmente "todo crudo → computadora", correcto para la **fase de entrenamiento/evaluación**. Pero los algoritmos de clase L/E corren en el micro, así que en algún momento hay que calcular features on-device.

**Opciones evaluadas (dónde se calculan features).**
- **Plantilla calcula, cintura fusiona.** Poco ancho de banda; más firmware distribuido.
- **Plantillas crudo → cintura calcula.** Más ancho de banda (irrelevante sobre WiFi); lógica centralizada, más fácil de depurar.
- **Todo crudo → computadora (elegida para captura).** Ideal para dataset/evaluación; no escala al uso real en el borde.

**Decisión.** **Cómputo de features distribuido**, con una **única definición de features compartida** (misma fórmula en plantilla, cintura y worker, versionada por `feature_set_version`):
- **Cada plantilla** calcula sus **features por-pie** (bloques A/B/C/E/F/G/H) y detecta sus eventos IC/TO.
- **La cintura** hace la **fusión bilateral** (simetría bloque D; double support desde eventos alineados), corre el detector y decide el feedback.

**Dónde se calculan las features depende de la fase (rev. c).** El modo captura **no es único**: se distinguen dos sub-fases con propósitos distintos.
- **Captura exploratoria** (investigación, one-time): se sube **sólo crudo continuo** → host/DB. Las features se calculan **off-device (Python)** para hacer ingeniería/selección de features y barrer tamaños de ventana y algoritmos. El micro **no** calcula features acá (a lo sumo, pruebas de banco de factibilidad). Salida: un `feature_set_version` congelado.
- **Captura operativa** (post-congelamiento; incluye la **calibración/baseline por paciente**): el micro **sí** calcula sus features por-pie + **crudo continuo**. Ese dataset nuevo entrena los modelos desplegables **skew-free** y valida la **paridad** (ADR-018) sobre su propio crudo, **sin reprocesar el crudo exploratorio**.
- **Edge** (uso real): el micro calcula features + eventos en vivo; **crudo sólo por snippet ante anomalía**, buffereado en cada plantilla.

O sea: "el micro calcula sus features por-pie" aplica a **operativa y edge**, no a la exploratoria. Lo que las plantillas transmiten/almacenan cambia por fase; la **definición** de cada feature es única y compartida en todas.

**Justificación (rev c).** Calcular features en el micro **antes** de la exploración es prematuro: aún no están definidos qué features, qué ventanas ni qué algoritmos usar, y el crudo exploratorio ya es el "seguro" para re-extraer con cualquier definición off-device. La garantía skew-free y la paridad **no requieren** tocar el crudo exploratorio: salen de una **captura operativa nueva**, que además el sistema hace igual en cada paciente (calibración/baseline). Se conserva el reparto de cómputo distribuido y la descarga de la cintura (features en vez de crudo en edge); la fusión bilateral usa features por-pie + eventos alineados por sync (ADR-004), sin crudo co-localizado. **Resuelve CP-02; el criterio de fases queda en CP-13.**

> **Historial de revisión.**
> - *v1 (inicial):* el modo captura calculaba features off-device (PC) desde el crudo.
> - *rev. 2026-07-16 (a):* features on-device en la cintura en ambos modos, por simetría de cómputo captura↔edge.
> - *rev. 2026-07-16 (b):* cómputo **distribuido** — features por-pie en cada plantilla, fusión bilateral en la cintura (resuelve CP-02, reparte carga).
> - *rev. 2026-07-19 (c):* **captura por fases** — *exploratoria* (crudo-solo, features off-device para explorar/seleccionar) vs *operativa* (micro calcula features + crudo, para entrenar skew-free y validar paridad). Se descarta calcular features en el micro en la fase exploratoria y reprocesar el crudo exploratorio; paridad/skew-free se validan sobre un set operativo nuevo (CP-13). Recupera el espíritu de v1 para la fase temprana sin perder la simetría de cómputo en la operativa. La re-extracción off-device desde el crudo sigue disponible como capacidad de análisis.

**Cintura como hub de fusión.** La información de ambos pies converge en la cintura: recibe **features por-pie + eventos** (o crudo, en captura), mantiene el timeline, calcula las **features bilaterales** (simetría, double support desde eventos), corre los detectores L/E (o delega en el host, clase H) y decide el feedback. Las plantillas dejan de ser sensores "tontos": calcular sus features por-pie reparte el cómputo y descarga a la cintura. Carga liviana: features por zancada (~1 Hz de decisiones), inferencia int8 sobre ~25 features mínima.

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

> **Revisada por ADR-044 (2026-10-17).** La capa de series deja TimescaleDB —deprecado en Supabase sobre Postgres 17, y en su edición Apache sin compresión ni continuous aggregates— y pasa a particionado nativo + `pg_partman`. Las tres capas (relacional, series, object storage) se mantienen.

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

**Contexto.** Estimaciones de volumen: ~5 KB/s → sesión de 30 min ≈ 9 MB crudo (comprimido 2–4 MB). El crudo **no es pesado** para una cohorte de investigación, pero en **uso diario continuo** llega a ~4 GB/mes/paciente — ese es el driver de costo. *(Actualización 2026-08-22: la cifra correspondía al paquete de 29 B y no declaraba supuesto. Con el paquete de 35 B de **ADR-042** son ~**7 KB/s** → **~6 GB/mes** suponiendo ~8 h/día sin comprimir, ~18 GB a 24 h/día. El argumento de la decisión no cambia; el número vive ahora en Vista 4 §1.4 con sus supuestos escritos.)* *(Corrección 2026-10-11: esa cuenta omitía los 4 B de `t_device` en `uint64` — ADR-042 punto 6. Con el paquete real de **39 B** son ~**7,8 KB/s** → **~6,7 GB/mes** a ~8 h/día, ~20 GB a 24 h/día.)*

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

## ADR-011 — Ruteo de modelos (taxonomía L/E/H/W)
**Estado:** aceptada (rev. 2026-07-19) — **Decisión: cada modelo declara su clase en el registry (model-agnostic); inferencia micro→host con fallback por config; reentrenamiento en el worker salvo los detectores de drift (clase L)**

**Contexto.** Advertencia de Juan: hay modelos probabilísticos **muy sencillos** que se reentrenan **dato a dato en el micro** y no deben ir al worker. El reparto depende de qué modelos se prueben, así que la arquitectura no debe hardcodearlos.

**Taxonomía adoptada (dos ejes: dónde infiere × dónde/con qué granularidad reentrena).** La ubicación de la inferencia en tiempo real se detalla en **ADR-013**.
| Clase | Inferencia | Reentrena | Granularidad | Ejemplos | ¿OTA? |
|---|---|---|---|---|---|
| **L — Local-Local** | Cintura (hub) | Cintura | Dato a dato | Mahalanobis EMA, z-score/EWMA, probabilísticos simples | No (se auto-actualiza) |
| **E — Edge+Worker** | Cintura (hub) | Worker | Periódico/async | Autoencoder denso int8, **Isolation Forest** | Sí |
| **H — Host** | Host (celular/laptop), tiempo real | Worker | Periódico/async | Modelos que **no entran** en la cintura pero sí en el host | Sí |
| **W — Worker-only (offline)** | Worker (batch/offline, **no** tiempo real) | Worker | Batch | Análisis/reportes, re-scoring histórico; modelos que no entran ni en el host en tiempo real | — |

Campos del registry: `inference_target ∈ {hub, host, worker}`, `retrain_target ∈ {micro, worker}`.

**Opciones evaluadas.**
- **Registry declara la clase (elegida).** Cada fila de `models` declara `(class, inference_target, retrain_target, granularity)`; el runtime rutea solo. *Pros:* agnóstico al modelo — sumar un modelo = declarar su clase; los L reentrenan en el micro sin tocar el worker. *Contra:* un poco más de metadata.
- **Hardcodear candidatos.** *Pros:* simple hoy. *Contra:* cada modelo nuevo obliga a tocar la lógica de ruteo.

**Decisión.** **Clase declarada en el registry.** Mahalanobis además actúa como **sensor de drift** que dispara el reentrenamiento de E/W; los L no necesitan disparo.

**Justificación.** Robustez a la incertidumbre sobre qué algoritmos ganarán: la infra soporta todos los caminos de antemano.

**Principio de ruteo (rev. 2026-07-19, model-agnostic).** La **inferencia en tiempo real** corre en el **micro (hub) siempre que entre**; si no entra, pasa al **host** (celular/laptop) para responder casi en tiempo real; **nunca** en el worker/nube. Vale para **cualquier modelo** (Isolation Forest y los que se prueben a futuro), no sólo los actuales. El **`inference_target` del registry** decide dónde corre: cambiarlo `hub`→`host` es un **switch de config, sin reescritura**, porque el **decisor de feedback es agnóstico al origen del score**. Consecuencia de infra: el **host debe alojar un runtime de inferencia espejo** del micro (para recibir un modelo que se cae de la cintura por footprint/latencia). El **reentrenamiento** siempre corre en el **worker** (compu en la mínima / nube en la máxima), disparado por el drift de Mahalanobis u otro flag; **excepto** los modelos triviales que detectan ese drift (clase L, p. ej. Mahalanobis), que se mantienen y reentrenan en el micro.

**Reclasificación (rev. 2026-07-19).** **Isolation Forest pasa de W → E** (su inferencia —recorrido de árboles— es liviana, entra en el micro; reentrena en el worker). La clase **W** queda reservada para lo **estrictamente offline** (análisis/reportes, re-scoring histórico, o modelos que no entran ni en el host en tiempo real). El **LSTM AE** deja de estar fijo en W: es **E** si entra en el micro, **H** si no entra pero sí en el host, **W** sólo si es puramente offline (lo decide el profiling, #11). Reconcilia la parte de IF de **CP-11** y queda coherente con `descripcion_proyecto.md`.

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

## ADR-013 — Ubicación de la inferencia en tiempo real
**Estado:** aceptada — **Decisión: en `hub` (preferido) o `host` (fallback); nunca en el worker/nube**

**Contexto.** ¿Dónde corre la inferencia que dispara el feedback? El feedback vibrotáctil necesita **baja latencia** y operación **offline**. Se planteó (a) si el worker puede inferir en tiempo real y (b) qué pasa si un modelo es demasiado pesado para el Pico de la cintura.

**Opciones evaluadas.**
- **Cintura (hub).** *Pros:* latencia mínima, offline. *Contra:* compute limitado (int8, modelos chicos).
- **Host (celular/laptop).** *Pros:* más compute, sigue siendo "casi-edge". *Contra:* suma un round-trip micro↔host por BLE (~decenas de ms, aceptable para marcha porque los eventos están a cientos de ms); requiere el host presente; en la máxima el modelo debe entrar en el **celular** (más débil que una laptop).
- **Worker/nube.** *Pros:* máximo compute. *Contra:* latencia + dependencia de conectividad → **no apto** para feedback en tiempo real.

**Decisión.** La inferencia en tiempo real corre en **`hub`** (preferido) o **`host`** (fallback si el modelo no entra en la cintura). **El worker nunca está en el lazo de feedback**; sólo infiere **batch/offline** (evaluación de algoritmos, re-scoring histórico, reportes). Se agrega la **clase H** y el valor **`host`** a `inference_target ∈ {hub, host, worker}`.

**Justificación.** Preserva la baja latencia y la operación offline del feedback, y provee un **escalón intermedio de cómputo** (host) sin ir a la nube.

**Consecuencias.** Un modelo pesado que se quiera para tiempo real: cuantizarlo para la cintura (→ E) o correrlo en el host (→ H); si tampoco entra en el host del escenario objetivo, queda como análisis batch (→ W). La clase H depende de que el modelo entre en el celular para funcionar en la máxima. **El switch `hub`↔`host` es un cambio de `inference_target` en el registry (model-agnostic, sin reescritura); el decisor de feedback es agnóstico al origen del score, y el host mantiene un runtime de inferencia espejo (ver ADR-011 rev 2026-07-19).**

---

## ADR-014 — Adquisición determinística (muestreo exacto a 100 Hz)
**Estado:** aceptada — **Decisión: ADC disparado por hardware + DMA con sobremuestreo y decimación; IMU en el tick maestro**

**Contexto.** Hay que garantizar un muestreo **exacto y periódico** a 100 Hz pese a la actividad del radio. El jitter arruina las features de derivada/espectro (COP velocity, jerk, PSD) y ensucia la sincronización. Un `sleep()` o un timer que "levanta un flag" para que el loop lea introducen **jitter de software** (latencia de interrupción, scheduling, radio).

**Investigación (industria).** El estándar es **timer/periférico de hardware que dispara la conversión del ADC + DMA que la almacena, sin CPU en el lazo de tiempo** (STM32 y equivalentes; el RP2350 lo soporta con su ADC free-running + FIFO/DREQ + DMA). Los ISR de timer/flag quedan sujetos a scheduling → timing variable. Todo esto es **interno al chip; no requiere componentes extra en el PCB**. Fuentes: STM32 timer-triggered ADC+DMA (blogs Shawal Mbalire / EmbeddedExpert), Deterministic Timer–DMA (MDPI Electronics 15:1830), foro/artículos RP2040-RP2350 ADC+DMA (iosoft, Raspberry Pi forums), MPU-6050 polling vs interrupt y uso de FIFO.

**Opciones evaluadas — FSR (ADC).**
- **ADC free-running + DMA con sobremuestreo 1 kHz → decimación ×10 a 100 Hz (elegida).** *Pros:* muestreo hardware sin CPU (jitter ~ns); el promedio **baja el ruido del FSR** (√10 ≈ 3,2×); buffer diminuto (~120 B) y el 1 kHz se decima al vuelo y se descarta (no se almacena ni transmite). *Contra:* 10× conversiones del ADC (0,6 % de duty) — despreciable.
- **Trigger exacto a 100 Hz por PWM/timer interno.** Evita las 10× conversiones, pero sin la mejora de SNR y algo más enredado.
- **Timer-ISR que lee el ADC.** Simple, pero reintroduce jitter de software y es sensible al radio.

**Opciones evaluadas — IMU (MPU-6050).**
- **Lectura en el tick maestro de 100 Hz (elegida por defecto).** Un solo timestamp por tupla FSR+IMU; IMU a ODR alto + DLPF para lectura fresca. Sin cambios de PCB.
- **FIFO / DATA_READY del IMU.** Espaciado uniforme por el reloj interno del IMU; DATA_READY suma un cable INT→GPIO. Diferido a **CP-07**.

**Decisión.** **FSR:** ADC free-running a ~1 kHz + DMA a buffer + **decimación (promedio ×10) a 100 Hz**. **IMU:** lectura en el tick maestro de 100 Hz. **Común:** timestamp real (timer µs) + nº de secuencia por muestra; **core dedicado** a adquisición; buffer DMA para no perder ante el radio. Todo por firmware, **sin componentes extra en el PCB**.

**Justificación.** Jitter en el orden de ns (hardware), CPU/RAM despreciables (~120 B, ~3.000 sumas/s) y **mejora de SNR** gratis por el promediado. Complementa ADR-004: adquisición = periodicidad **intra**-dispositivo; beacon + drift = alineación **entre** dispositivos.

**Consecuencias.** El crudo sobremuestreado **no** se almacena ni transmite (sólo el 100 Hz decimado). No requiere cambios de PCB, salvo —opcional y futuro— el pin DATA_READY del IMU si se adopta esa lectura (CP-07).

---

## ADR-015 — Detección de eventos de marcha (IC/TO)
**Estado:** aceptada — **Decisión: fusión FSR-primario + confirmación IMU; detección en la plantilla (per-pie). Resuelve CP-03.**

**Contexto.** La detección de IC/TO es prerequisito de casi todo (features espacio-temporales, segmentación stance/swing, ZUPT, refinamiento de sync, timing de feedback). Corre en tiempo real y debe ser robusta a marcha post-ACV (drop foot, apoyo de antepié/plano). CP-03 preguntaba **dónde** corre (plantilla vs cintura).

**Investigación (literatura/industria).**
- **FSR/presión:** el cruce de umbral de fuerza plantar da el **instante de contacto directo** (ground truth), baja latencia; usado en embebidos en tiempo real.
- **IMU (velocidad angular del pie):** detecta IC/FC; validado en sanos y **hemipléjicos** (~2 % de error de ciclo, robusto), pero IMU-solo es menos preciso en el instante (RMSE ~50-61 ms vs ~14 ms MoCap).
- **Fusión FSR+IMU:** **>96 %** de exactitud; además la fase stance por FSR alimenta el **ZUPT**.
- Fuentes: FSR insole phase detection; Sensors 16:1634; foot angular kinematics (ScienceDirect S0021929021006369); detección robusta en hemipléjicos con 1 IMU; fusión inercial + film-presión (arXiv 1810.09757); impacto de ubicación del IMU (PMC8227677).

**Opciones — método.**
- **FSR-solo (umbral).** Simple y rápido, pero pierde robustez ante ruido/ambigüedad.
- **IMU-solo.** Robusto en patología pero menos preciso en el instante exacto.
- **Fusión FSR-primario + confirmación IMU (elegida).** El FSR da el timing (trigger rápido) y el IMU confirma (rechaza falsos); >96 %. Coincide con el marco teórico.

**Opciones — placement (CP-03).**
- **Plantilla per-pie (elegida).** Cada plantilla tiene su FSR+IMU → detecta local, baja latencia, distribuye cómputo, menos tráfico; envía el evento a la cintura. Coherente con ADR-005.
- **Cintura centralizada.** Requeriría mandar crudo de ambos pies; contradice las features distribuidas.

**Decisión.** **Fusión FSR-primario + confirmación IMU**, detección **en la plantilla (per-pie)**; el evento `{tipo, timestamp, pie, confianza}` se envía a la cintura para fusión bilateral, sync y feedback. Definición robusta: **IC = onset de carga de cualquier región; TO = fin de carga**, con histéresis + refractario. Detalle de implementación: **SPEC-01** en `../vistas/2_specs_algoritmos_firmware.md`.

**Justificación.** Máxima robustez (>96 %) y tolerancia a la patología (onset-de-cualquier-región + confirmación IMU), baja latencia (FSR emite, IMU anota sin bloquear) y reutiliza la fase stance para el ZUPT.

**Consecuencias.** Resuelve **CP-03** (plantilla). Umbrales/ventana son **parámetros calibrables por paciente** (calibración/baseline). La confirmación IMU **degrada a FSR-solo** si no es fiable, para no perder eventos.

---

## ADR-016 — Estimación de largo de zancada (stride length)
**Estado:** aceptada — **Decisión: doble integración de la aceleración (frame global) + ZUPT disparado por FSR, por zancada; ZUPT simple como base, EKF/MSDI como refinamiento futuro.**

**Contexto.** Stride length (y de ahí stride speed) son features del bloque A. Del IMU del pie se obtienen por **integración doble** de la aceleración, que **driftea**; el ZUPT corrige aprovechando que el pie está quieto en *stance*. Depende de la **orientación** del pie (para remover gravedad) → backlog #5.

**Investigación (literatura).**
- Doble integración de la accel en **frame global** (rotada + gravedad removida) entre *stances* → velocidad → desplazamiento.
- **ZUPT:** en *stance* la velocidad es ~0 → de-drift lineal por zancada. **Alta validez en marcha** (degrada en running, no aplica).
- **Precisión:** stride length ~**−6 % a +3 %**; depende de sampling/rango y, sobre todo, de la **correcta detección del stance**.
- **Ventaja propia:** el *stance* lo da el **FSR** (robusto, ground truth) en lugar de un detector IMU-only — el factor crítico queda cubierto por SPEC-01/02.
- Fuentes: Frontiers Bioeng 2025 (params por IMU + eventos refinados); PLOS One (validez ZUPT); Sci Rep s41598-021-81009-w (péndulo invertido, tibia); review ZUPT-aided pedestrian nav; stance-phase detection para ZUPT.

**Opciones.**
- **ZUPT simple por zancada (elegida).** Integrar entre *stances* + de-drift lineal de la velocidad + integrar a desplazamiento. Liviano, embebido-feasible, adecuado a marcha lenta.
- **ZUPT-aided EKF / INS (MSDI, MFD-GED).** Filtro de Kalman fusionando orientación + ZUPT; más preciso y para trayectoria completa, pero más pesado. **Refinamiento futuro.**
- **Modelo de péndulo invertido (IMU en tibia).** Descartado: nuestro IMU va en el **pie**.

**Decisión.** **Doble integración + ZUPT simple**, con *stance* por **FSR**, calculado **por zancada**. EKF/MSDI queda como refinamiento futuro si la precisión no alcanza (sin magnetómetro en el MPU-6050 → preferir métodos *magnetometer-free*). Detalle: **SPEC-03**.

**Dependencia.** Requiere la **orientación del pie** (remover gravedad) → **backlog #5** pasa a ser prerequisito de la implementación real.

**Justificación.** ZUPT es el estándar para IMU en el pie y tiene alta validez en marcha lenta (nuestro caso); el FSR aporta el *stance* robusto, que es el factor crítico; "simple" es embebido-feasible en el Pico.

**Consecuencias.** Define las features 6 (stride length) y 7 (stride speed) del bloque A. Precisión esperada del orden de pocos %; validar en la calibración. El salto a EKF, si se persigue, abrirá su propia cuestión/ADR.

---

## ADR-017 — Módulo de procesamiento de IMU (orientación, gravedad, calibración)
**Estado:** aceptada — **Decisión: módulo IMU compartido reutilizable; orientación por Madgwick vía la librería open-source Fusion (C) + `imufusion` (Python); calibración estática + re-zero de giro en *stance* + alineación anatómica.**

**Contexto.** Varias features usan el IMU (foot pitch en IC/TO, ROM, LDLJ, vel. angular) y el ZUPT (ADR-016), y **todas** necesitan **orientación** y **aceleración lineal sin gravedad**. Conviene un **módulo reutilizable** que las provea, en vez de que cada feature re-implemente. Además el MPU-6050 requiere **calibración** (bias/offset, sensibles a temperatura) y **alineación anatómica** (el sensor está en orientación arbitraria dentro de la plantilla).

**Investigación (literatura/industria).**
- **Calibración:** bias de giro por promedio estático ("dejar quieto"); offset de accel nivelado (Z≈9,81); la **temperatura corre el bias** → warm-up 2-3 min + lugar sin vibración; el bias no es constante. El **FSR** habilita **re-zero del giro en runtime durante el *stance*** (foot still).
- **Orientación:** complementario / **Madgwick** / Mahony. En **6-DOF sin magnetómetro** el *yaw* driftea, pero roll/pitch (referencia de gravedad por accel) están **bien condicionados** → suficiente para nuestras features y para el *gravity removal*.
- **Librería:** **Fusion (xioTechnologies)** = Madgwick embebido en **C**, 6-DOF, con **corrección de bias de giro en runtime + comp. de temperatura**; y **`imufusion`** (Python) → **paridad firmware↔worker** con el mismo algoritmo.
- **Alineación sensor-segmento:** anatómica (pose conocida, ej. pie-plano) o funcional; existen métodos **calibration-free** por ciclo de marcha.
- Fuentes: calibración MPU6050 (offsets estáticos); comparación de filtros (MDPI Sensors 25:5161); Fusion (github.com/xioTechnologies/Fusion); calibration-free gait (PMC8599134); sensor-to-segment (PMC10098809).

**Opciones — orientación.**
- **Adoptar Fusion/Madgwick (elegida).** Probada, embebida, **C + Python (paridad)**, bias runtime, menos código. *Contra:* dependencia (permisiva, vendorizable — verificar licencia).
- Complementario propio. Más simple, pero sin la paridad ni el bias-runtime listos.
- EKF/INS. Más preciso pero más pesado; innecesario para roll/pitch + gravedad.

**Opciones — alineación anatómica.**
- **Pose estática pie-plano (elegida).** Simple; alinea el vertical con la gravedad.
- Funcional (movimiento de calibración). 
- **Calibration-free** (por ciclo de marcha). Refinamiento futuro.

**Decisión.** **Módulo IMU compartido** que expone accel calibrado, orientación (quaternion/pitch/roll), **aceleración lineal sin gravedad** y vel. angular; orientación con **Fusion (C) / `imufusion` (Python)**; **calibración**: estática "dejar quieto" (bias giro + offset accel, post warm-up) + **re-zero de giro en *stance* (FSR)** + **alineación anatómica pie-plano** en la sesión. Detalle: **SPEC-04**.

**Justificación.** Reutilización (un solo lugar para orientación/gravedad), **paridad firmware↔worker** por usar la misma lib en C y Python, menos código propio, y aprovecha el FSR para el bias en runtime. **Desbloquea el ZUPT (ADR-016).**

**Consecuencias.** La **calibración del IMU** se integra a la sesión de **calibración/baseline** (Vista 3). Verificar licencia de Fusion al vendorizar. Sin magnetómetro, el *yaw* absoluto no es fiable (no afecta gravity removal ni roll/pitch). *Calibration-free* queda como refinamiento futuro. **`imufusion` en el worker es condicional:** sólo para re-extraer features del IMU desde el **crudo** off-device (dataset/experimentación); en el reentrenamiento *edge* el worker consume features ya computadas y no lo usa.

---

## ADR-018 — Paridad de features PC↔micro (evitar *train/serve skew*)
**Estado:** aceptada — **Decisión: estrategia de paridad por capas — tests de paridad en CI + entrenar con features del micro + disciplina numérica.**

**Contexto.** Las features de entrenamiento a veces se calculan en Python (worker, desde crudo) y la inferencia usa features calculadas en C (micro). Si difieren aunque sea un poco → **train/serve skew**: el modelo ve una distribución distinta a la que aprendió y se degrada. "Deberían ser iguales" no basta; hay que **garantizarlo**.

**Investigación.** El *train/serve skew* es un problema conocido; mitigaciones estándar: **código compartido / feature store** (paridad por construcción; Feast/Tecton), **tests de paridad sobre vectores fijos + round-trip en CI**, y **monitoreo** de features de alta importancia. Sutileza numérica: IEEE 754 hace deterministas las ops básicas, pero **funciones de librería** (sin, sqrt, exp, FFT) y el **fixed-point/int8 del micro vs float del PC** pueden divergir → tolerancias + cuidado. Fuentes: dswok (train/serve skew), Google Vertex AI (monitoreo), Confluent (eliminación), Nubank (guía), jvns (punto flotante).

**Decisión (estrategia por capas).**
1. **Tests de paridad (golden vectors) en CI:** input→output esperado corrido en **C (firmware)** y **Python (worker)**; match element-wise con **tolerancia por-feature**; **gate** atado a `feature_set_version`.
2. **Política de entrenamiento (aclarada 2026-07-19):** los modelos desplegables se entrenan con las **features computadas por el micro**, guardadas en la **captura operativa** (post-congelamiento del set; incluye la calibración/baseline por paciente — ADR-005 rev c) → **skew-free por construcción**. La **paridad se valida sobre ese set operativo nuevo** (micro-C vs re-extracción Python del mismo crudo), **sin reprocesar el crudo de la captura exploratoria**. La captura exploratoria es crudo-solo y sus features off-device (path `imufusion`) sirven para **prototipar/seleccionar**; una feature nueva **debe pasar los tests de paridad** en una captura operativa antes de promoverse a producción.
3. **Disciplina numérica:** tolerancias explícitas; cuidado con fixed-point/int8 vs float y con el bloque H (FFT/entropía) y LDLJ; fijar la implementación de transcendentales si hace falta.
4. **Refuerzo futuro:** monitoreo round-trip sobre vectores reales. *(El C-compartido bindeado y el codegen desde una definición única se evaluaron y **descartaron** en **ADR-021**; la escalación ante drift es disciplina numérica + tolerancias, no cambiar de mecanismo.)*

**Justificación.** Convierte el invariante "definición de features única y compartida" de una **aspiración** en una **garantía verificable** (gate de CI), y elige la política más segura (entrenar con lo que se infiere).

**Consecuencias.** Ningún modelo de producción se entrena con features laptop-only sin verificar. La paridad es un **gate de CI** y se ancla a la **captura operativa** (ADR-005 rev c), no a la exploratoria. El catálogo de features (CP-12) incorpora **tolerancias por-feature**. Refuerza CP-12/CP-13 y el módulo compartido (`src/firmware/shared/`).

---

## ADR-019 — DSP on-device: FFT/PSD y librería (bloque H)
**Estado:** aceptada — **Decisión: CMSIS-DSP (float32) como backbone de DSP; `arm_rfft_fast_f32` para la FFT real; ventana Hann deslizante; bandas fijas. Resuelve la fila "DSP" del stack.**

**Contexto.** El **bloque H** (frecuencia/entropía: spectral entropy, dominant frequency, power en bandas; + sample entropy, que **no** usa FFT) necesita **FFT/PSD on-device**. Además, SPEC-01/03/06 y Mahalanobis (clase L) referían "sobre CMSIS-DSP o kernels propios" sin decidir. Hay que fijar la **librería DSP** y la parametrización del análisis espectral, cuidando la **paridad C↔Python** (ADR-018): el bloque H es el caso más delicado de paridad (FFT + fixed/float + transcendentales).

**Hardware.** El RP2350 monta **2× Cortex-M33 @150 MHz con FPU de precisión simple (FPv5-SP) por hardware** (suma/mult/div/sqrt en HW) **+ extensión DSP/SIMD** (MAC 16/32-bit en 1 ciclo, SIMD 8/16-bit). Tiene silicio para FFT en float rápido, sin emulación.

**Opciones evaluadas.**
- **A — CMSIS-DSP (float32) (elegida).** Librería de ARM optimizada para Cortex-M (probada en M0/M4/M7/**M33**/M55), hand-tuned con SIMD/FPU. Provee `arm_rfft_fast_f32` (FFT real recomendada) + `arm_cmplx_mag_f32` (magnitud→PSD), estadística, álgebra (para Mahalanobis) y **FIR decimation**. Integra con el Pico SDK como subdirectorio (`-mcpu=cortex-m33 -mfpu=fpv5-sp-d16 -mfloat-abi=hard -DARM_MATH_CM33=1`). *Pros:* código probado y rápido (~2× vs C genérico), cubre FFT+filtros+álgebra en **una** dependencia, reutilizable por SPEC-01/03/06 y Mahalanobis. *Contra:* dependencia externa (Apache-2.0, permisiva/vendorizable); f32 vs f64 del worker → tolerancias de paridad.
- **B — Kernels propios (FFT a mano).** *Pros:* control total, sin dependencia. *Contra:* reinventar una FFT bien testeada es caro y propenso a errores; difícil igualar el tuning SIMD/FPU de ARM; nada que ganar.
- **C — FFT en fixed-point (q15/q31).** ~5× más rápida en MCU **sin** FPU (M0+); en el M33 **con** FPU la ventaja se diluye y complica paridad y rango dinámico. Se reserva como **fallback** si el profiling lo exige.

**Decisión.** **CMSIS-DSP en float32** como backbone de DSP del firmware: `arm_rfft_fast_f32` para la FFT real del bloque H, más su uso transversal (filtros/decimación FIR, álgebra de Mahalanobis, estadística). Fixed-point q15 sólo como fallback.

**Parametrización del análisis espectral (bloque H).**
- **Señal:** PSD de la **aceleración** (eje vertical/AP o magnitud de `lin_accel`, a fijar en exploración), con **ventana Hann** (reduce *leakage*).
- **Ventana deslizante multi-zancada** (no per-zancada): el bloque H necesita resolución en frecuencia → corre sobre **N muestras potencia de 2**. A 100 Hz: **N=256 (2,56 s, Δf≈0,39 Hz) por defecto** — resuelve bien la banda **<0,5 Hz**; N=128 (1,28 s, Δf≈0,78 Hz) queda grueso para esa banda; N=512 (5,12 s, Δf≈0,20 Hz) da más resolución a costa de responsividad.
- **Bandas fijas** (del marco): **<0,5 / 0,5–2 / >2 Hz**. `dominant_frequency` = argmax del espectro (sin DC); `spectral_entropy` = entropía de Shannon del espectro normalizado; `power en bandas` = Σ PSD por banda.
- **Sample entropy** (feature 36): sobre `ω`, **O(n²)**, **sin FFT** → ventana corta (acotar N por costo).

**Costo (factibilidad).** Referencia conservadora en **RP2040 (Cortex-M0+ @133 MHz, sin FPU)**: FFT real f32 + magnitud tarda **~2,0 ms (N=128)** y **~4,3 ms (N=256)**; q15 ~5× más rápido. En el **M33 con FPU** el f32 es sustancialmente más rápido. Como el bloque H se evalúa a lo sumo ~1 Hz (por zancada/ventana), aun el peor caso (~4 ms) es **<0,5 % de duty** → holgado. **No** es camino crítico de latencia (el feedback usa Mahalanobis <100 µs, no el bloque H).

**Paridad (ADR-018).** Caso más sensible del catálogo: (a) **calcular en float32 de ambos lados** (numpy/scipy pueden operar en `float32`); (b) **misma ventana (Hann) y misma normalización de PSD**; (c) **tolerancias por-feature más laxas** para el bloque H que para A-G; (d) `dominant_frequency`/`spectral_entropy` son relativamente robustas (argmax / distribución normalizada), `power en bandas` es sensible a escala → fijar convención de normalización. Estas features entran a producción **sólo tras pasar los tests de paridad** (captura operativa, ADR-005 rev c).

**Justificación.** El M33 tiene FPU+DSP para FFT en float sin penalización relevante; CMSIS-DSP es el estándar probado, cubre FFT+filtros+álgebra en una dependencia y se reutiliza en las specs previas y en Mahalanobis; el costo es despreciable a la cadencia del bloque H; fixed-point queda de reserva.

**Consecuencias.** Fija la fila **DSP** del `stack_tecnologico` (CMSIS-DSP, `decidido`). Resuelve la ambigüedad "CMSIS-DSP o kernels propios" de SPEC-01/03/06 → **CMSIS-DSP**. Detalle de implementación: **SPEC-07**. El bloque H sigue siendo **fase 4/opcional**: su inclusión final depende de la feature selection (CP-12); la ventana N es un parámetro a barrer en la exploración. Verificar licencia (Apache-2.0) al vendorizar.

**Fuentes.**
- RP2350 datasheet (Cortex-M33: FPv5-SP FPU + DSP) — datasheets.raspberrypi.com/rp2350; *RP2350* (Wikipedia); *Arm Cortex-M33 Processor Datasheet* (ARM).
- *CMSIS-DSP: Overview* (soporta M33; `arm_rfft_fast_f32` recomendada) — arm-software.github.io/CMSIS-DSP.
- *Benchmarking CMSIS-DSP on Raspberry Pi Pico* (tabla de tiempos FFT f32/f64/q15/q31 en RP2040/M0+) — github.com/jptrainor/cmsis-sandbox.
- Integración CMSIS-DSP + pico-sdk en RP2350 (flags de compilación) — foros Raspberry Pi; ArduCMSIS-DSP (Hackster).
- *Computing FFT with PowerQuad and CMSIS-DSP* (tiempos de `arm_rfft_fast_f32` @150 MHz en Cortex-M) — NXP AN12383.

**Nota conceptual (en lenguaje llano).** Glosario de los términos de este ADR, para entender la decisión sin background de DSP/embebido.

- **Frecuencias y por qué la FFT.** La aceleración del pie en el tiempo es una onda, como un sonido. Algunas features del bloque H no miran *cuánto* acelera el pie sino *con qué ritmos* oscila (lento vs. rápido). Igual que un acorde de guitarra es la suma de varias notas, la señal es la suma de varias frecuencias. La **FFT (Fast Fourier Transform)** es la herramienta que descompone el "acorde" en sus "notas": dice cuánta energía hay en cada frecuencia. De ahí salen la frecuencia dominante, la entropía espectral y la potencia por bandas.
- **Ventana N=256 / Hann.** La FFT trabaja sobre un **pedazo** de N muestras, no sobre la señal infinita. A 100 Hz, N=256 = 2,56 s. Cuanto más largo el pedazo, mejor se distinguen frecuencias parecidas (más "resolución"): 256 alcanza para resolver la banda <0,5 Hz; 128 queda grueso. **Hann** es un suavizado de los bordes del pedazo (un *fade in/out*) para que el corte abrupto no invente frecuencias falsas.
- **float32 vs fixed-point q15.** Dos formas de representar números con decimales en el micro. **float32** ("punto flotante"): como notación científica, la coma "flota"; flexible y preciso. **fixed-point q15** ("punto fijo"): enteros con la coma en un lugar fijo; un truco para ir más rápido en chips lentos, a costa de precisión. Elegimos float32; q15 queda de reserva.
- **FPU (FPv5-SP) / "sin emulación".** La **FPU** (Floating-Point Unit) es una "calculadora de decimales" en el hardware del chip. Con FPU, las cuentas float son rápidas y directas; sin FPU, el chip las **simula** con muchos pasos (emulación) → lento. El RP2350 **sí tiene** FPU (modelo FPv5-SP), por eso usar float no cuesta caro y el fixed-point deja de ser necesario.
- **DSP / SIMD.** Instrucciones extra del procesador pensadas para señales: hacen varias operaciones de una sola vez (SIMD = "una instrucción, varios datos"). Aceleran FFT y filtros. El Cortex-M33 del RP2350 las trae.
- **CMSIS-DSP (la librería) y `arm_rfft_fast_f32`.** **CMSIS-DSP** es una **librería** (código ya hecho y probado por ARM) de funciones de señales; el equivalente en el micro a numpy/scipy en la PC. Se **vendoriza** (se copia su código al build del firmware), se compila para el M33 (flags `-mcpu=cortex-m33 -mfpu=fpv5-sp-d16 …`) y se **llama** desde nuestro código; queda horneada dentro del programa que se graba en el chip (corre on-device, sin internet). `arm_rfft_fast_f32` es su función de **FFT real en float32** (el análogo de `numpy.fft.rfft`). "**Kernels propios**" habría sido programar la FFT a mano: más trabajo y riesgo, sin ganancia.
- **Costo / duty cycle / camino crítico.** La FFT tarda ~4,3 ms en el peor caso (N=256 en un chip sin FPU); en el M33 con FPU, menos. Como se calcula ~1 vez por segundo, el procesador queda ocupado <0,5 % del tiempo (**duty cycle** = fracción de tiempo ocupado). El **camino crítico** es lo que tiene que ser instantáneo: el feedback vibratorio, que lo maneja **Mahalanobis** (<100 µs). La FFT va por un carril aparte y más lento, así que **no** retrasa la vibración → su costo no importa.

---

## ADR-020 — Runtime de inferencia on-device (int8)
**Estado:** aceptada — **Decisión: TFLite Micro (TFLM) + CMSIS-NN (vía `pico-tflmicro`) para las redes neuronales int8 en la cintura; Mahalanobis en CMSIS-DSP; Isolation Forest por recorrido de árboles en C.**

**Contexto.** La clase **E** (autoencoder denso int8) **infiere on-device** en la cintura (ADR-011/013). Hay que definir **con qué software se ejecuta una red neuronal int8** en el Cortex-M33. Es una decisión de **inferencia**, distinta del **reentrenamiento** (worker, ADR-009/011). Debe encajar con el **pipeline de cuantización ya elegido** (TFLite converter → int8, stack Vista 3) y con el **OTA de flatbuffers int8** (ADR-012), y cuidar la **paridad train↔serve** (ADR-018): el int8 que se entrena debe ser el que se ejecuta.

**Alcance — dónde infiere cada modelo.** El principio (ADR-013) es **inferir on-device siempre que entre**; al host sólo si no entra; a la nube nunca en tiempo real. Este runtime es **sólo para las redes neuronales**:
- **Mahalanobis (L):** álgebra lineal → **C + CMSIS-DSP**, no usa NN runtime.
- **Autoencoder denso int8 (E):** **red neuronal** → este runtime (TFLM + CMSIS-NN).
- **Isolation Forest:** inferencia liviana (recorrido de árboles como tablas de splits) → **on-device en C** (clase E, ADR-011 rev); no es NN → no usa este runtime.
- **LSTM AE:** red neuronal más pesada (ventana cruda ~100×8) → correría por este runtime **si entra** en tiempo real en el M33; si no, host (H) u offline (W). A confirmar por profiling (#11).

**Opciones evaluadas.**
- **A — TFLM + CMSIS-NN (elegida).** `pico-tflmicro` (port de TFLM mantenido por Raspberry Pi) empaqueta CMSIS-NN (kernels int8 de ARM con SIMD en M33). *Pros:* calza con el pipeline TFLite→int8 y con el OTA de flatbuffers (ADR-012); **paridad automática** (TFLM sigue la spec de cuantización de TFLite → el int8 entrenado = el ejecutado); footprint chico (intérprete ~2 KB + modelo ~10-50 KB); CMSIS-NN acelera 2,6-5,4×; escala al LSTM si algún día entra. *Contra:* el port **RP2350 de `pico-tflmicro` no está mergeado** oficialmente (hay patch/fork comunitario; proyectos reales ya corren TFLM en RP2350 vía CMSIS-NN → riesgo acotado, a validar temprano); el intérprete general agrega algo de overhead vs un kernel a medida.
- **B — Kernels propios int8 (a mano).** *Pros:* footprint mínimo, cero dependencias. *Contra:* nos hacemos cargo de toda la cuantización y de mantenerla **bit-consistente con el TFLite converter** (riesgo de paridad); no escala; reinventar infra probada.
- **C — CMSIS-NN directo (sin el intérprete TFLM).** *Pros:* kernels probados de ARM, más liviano que TFLM, corre en M33 hoy (no depende del port sin mergear). *Contra:* cableamos el grafo de capas y los parámetros de cuantización a mano.

**Decisión.** **TFLM + CMSIS-NN** (vía `pico-tflmicro`) para las NN int8 on-device. **C (CMSIS-NN directo)** queda como **fallback** documentado si el port RP2350 o el peso de TFLM molestan (el AE denso es chico → C sería viable). **B** descartada (riesgo de paridad sin ganancia sobre C).

**Justificación.** Es la opción **coherente con decisiones ya tomadas**: el OTA (ADR-012) ya asume flatbuffers int8, el pipeline de cuantización ya es TFLite, y TFLM da la paridad train↔serve "gratis" (mismo estándar de cuantización que el converter). El M33 tiene SIMD/DSP que CMSIS-NN explota; el footprint es chico. El único riesgo real (port RP2350) está acotado y tiene fallback.

**Consecuencias.** **TFLite Micro** pasa de `candidato` a `decidido` en el stack (Vista 2) y **CMSIS-NN** entra como su backend de kernels. Refuerza ADR-018 (paridad) y encaja con ADR-012 (OTA de flatbuffers). **Riesgo a validar temprano:** el port de `pico-tflmicro` a RP2350 (llevar el patch/fork o portarlo). La clase de Isolation Forest quedó **reconciliada** (W→E) en ADR-011 rev 2026-07-19 (parte de CP-11). Detalle de implementación: **SPEC-08**.

**Fuentes.**
- `pico-tflmicro` (port de TFLM para Pico, mantenido por Raspberry Pi; incluye CMSIS-NN) — github.com/raspberrypi/pico-tflmicro; estado del soporte RP2350 (issues/PR abiertos) — github.com/raspberrypi/pico-tflmicro/issues/18.
- *CMSIS-NN* (kernels de NN int8 para Cortex-M; SIMD en M4/M7/M33/M55; 2,6-5,4×) — arm-software.github.io/CMSIS_6 (NN); paper *CMSIS-NN* (arXiv 1801.06601).
- *TensorFlow Lite Micro* (intérprete ~2 KB; footprint de modelos) — tensorflow/tflite-micro (memory_footprint).
- TFLM en RP2350 vía CMSIS-NN en producción (voz en RPi Pico 2 / Moonshine Micro) — hackster.io/petewarden.

**Nota conceptual (en lenguaje llano).** Glosario de este ADR, para entender la decisión sin background de ML embebido.

- **El problema.** Entrenamos el modelo en la PC, pero para dar feedback en vivo hay que **ejecutarlo en el chip** (inferir = correr el modelo ya entrenado para sacar un score). Este ADR elige **con qué software** se ejecuta la red neuronal en el micro. Es distinto de **entrenar/reentrenar** (eso pasa en el worker).
- **TinyML.** El campo/práctica de correr modelos de ML en microcontroladores (no en PC/nube). No es una librería, es el "para qué".
- **TFLite Micro (TFLM), el "intérprete".** Una librería de Google que es un **reproductor de modelos** en el micro: le das el modelo entrenado (un archivo) y lo ejecuta **capa por capa**. Es el primo chico de TensorFlow: TensorFlow entrena en la PC; TFLM sólo **infiere** en el micro.
- **CMSIS-NN.** La librería de ARM con los **kernels** (rutinas de cuenta pesada) de redes neuronales optimizados para Cortex-M en **int8**. Es lo mismo que CMSIS-DSP (ADR-019) pero para redes: usa el SIMD del M33 para hacer muchas multiplicaciones a la vez.
- **pico-tflmicro.** El **paquete ya armado** de TFLM para la familia Pico (lo mantiene Raspberry Pi), con CMSIS-NN adentro.
- **int8.** El modelo se **cuantiza**: sus números pasan de decimales (float32) a **enteros de 8 bits**. Ocupa ~4× menos y corre más rápido, con una pérdida de precisión chica. Es el formato natural para microcontroladores.
- **Analogía.** El modelo entrenado es una **partitura** (las notas = los pesos); **TFLM es el director** que la lee y la toca capa por capa; **CMSIS-NN son los músicos afinados para nuestro chip** que tocan cada parte rápido; **pico-tflmicro es la banda ya montada** sobre el RP2350. La opción C sería usar los músicos sin director (dirigís vos a mano); la B, fabricar también los músicos.
- **Por qué lo elegimos.** Porque ya habíamos decidido **cuantizar con TFLite** y mandar el modelo por **OTA como archivo flatbuffer**; TFLM usa exactamente ese formato y esa forma de cuantizar, así que **el modelo que entrenás es idéntico al que corre** (evita el *train/serve skew* del ADR-018), viaja limpio por OTA (ADR-012) y aprovecha el hardware del M33 vía CMSIS-NN, con muy poca memoria. Hacerlo a mano (B) daría lo mismo con más riesgo de paridad; el punto medio (C) queda de reserva por si el port a RP2350 molesta.

---

## ADR-021 — Catálogo de features compartido y mecanismo de paridad
**Estado:** aceptada — **Decisión: catálogo declarativo (data file) en `src/firmware/shared/` + dos implementaciones (C firmware / Python worker) reconciliadas por tests de paridad (golden vectors) con tolerancia por-feature. Codegen y C-único-bindeado descartados.**

**Contexto.** ADR-018 fijó la **estrategia anti train/serve skew**; el backlog #9 (y CP-12) pide concretar **el catálogo de features** y resolver "**codegen vs dos implementaciones + tests**". La definición de features es **única y compartida** PC↔micro (invariante), versionada por `feature_set_version`; falta decidir **cómo se mantiene esa unicidad** y **qué formato** tiene el catálogo.

**Opciones evaluadas.**
- **A — Dos implementaciones + tests de paridad (elegida).** C (firmware) y Python (worker, exploración/validación) por separado; **golden vectors en CI** (input→output esperado en ambos) con **tolerancia por-feature**, gate por `feature_set_version`. *Pros:* cada lado idiomático y óptimo (C con CMSIS-DSP/fixed-point; Python con numpy/scipy); encaja con el fasado (exploración = Python-first, ADR-005 rev c); y como el training de producción usa **las features del micro** (ADR-018 pto 2), la paridad exacta es un **guard/monitor**, no una dependencia dura. *Contra:* dos fuentes → la paridad se **testea** (no se garantiza por construcción); hay que mantener el golden test de cada feature.
- **B — C único compilado para ambos, bindeado a Python (ctypes/CFFI).** *Pros:* paridad por construcción. *Contra:* build más complejo, C portable obligado, y **se pierde el prototipado rápido en Python** en la exploración. **Descartada** (decisión de Juan: no interesa, ni como escalación).
- **C — Codegen desde una spec única.** *Pros:* una sola fuente. *Contra:* construir el generador es ingeniería pesada; las features complejas (LDLJ, FFT, SampEn) no entran en un DSL simple; **overkill para una tesis**. Descartada.

**Decisión.** **A + catálogo declarativo.** Codegen y C-único **descartados** (este último, explícitamente, ni como escalación).

**Catálogo (estructura).** Un **archivo de datos declarativo** (JSON/TOML) en `src/firmware/shared/` es la **fuente de verdad de metadata**: por feature `{ id, bloque, scope (foot|bilateral|trunk), inputs, dependencias, params, tolerancia, activo }` + el **set activo** + `feature_set_version`. Lo consumen el **firmware (C)** y el **worker (Python)** —cada uno implementa la **matemática** de la feature— y la **DB** (guarda `feature_set_version` con cada `feature_vectors`). Prender/apagar una feature = cambiar el **set activo** (config), no el código; el set puede distribuirse por config/OTA.

**Paridad (cómo se garantiza).** **Golden vectors en CI**: entrada fija → salida esperada corrida en C y en Python, match element-wise con **tolerancia por-feature**, **gate** atado a `feature_set_version`. Una feature nueva **no se promueve** a producción sin pasar el test. **Escalación si una feature no pasa** (sin recurrir a B/C): (1) **alinear la implementación** (mismo orden de operaciones, misma semántica); (2) **disciplina numérica** (fixed-point/int8 vs float; fijar la implementación de transcendentales — FFT/entropía, LDLJ); (3) **tolerancia por-feature** explícita si el drift es acotado y aceptable; (4) en último caso, **excluir la feature** (la feature selection puede prescindir de ella). Refuerzo continuo: **monitoreo round-trip** sobre vectores reales.

**Justificación.** Cada lado queda idiomático y óptimo; encaja con el fasado (exploración Python-first) y con ADR-018 pto 2 (el training usa las features del micro → la paridad es un guard, no una dependencia dura); evita la sobre-ingeniería de un codegen o de un binding C↔Python para una tesis.

**Consecuencias.** **Refina ADR-018** (su punto 4: se **descartan** el C-compartido y el codegen como escalación; quedan disciplina numérica + tolerancias + monitoreo round-trip). **Resuelve CP-12** (mecanismo de modularidad: catálogo declarativo + set activo versionado; la *selección* data-driven de qué se prende sigue en el backlog #12). Ubicación: `src/firmware/shared/` (catálogo + definición en C) + espejo en el worker (Python) + tests de paridad en CI. Detalle: **Vista 3, Parte B**.

**Fuentes.**
- Golden/round-trip parity tests con tolerancia + eliminación de train/serve skew — dswok (train/serve skew); Nubank (guía); Confluent (eliminación).
- Feature store de fuente única (Feast/Tecton) — referencia de la opción codegen (descartada).
- Bindings C↔Python (ctypes/CFFI) — referencia de la opción B (descartada).

---

## ADR-022 — Framework de entrenamiento y cuantización (worker)
**Estado:** aceptada — **Decisión: TensorFlow/Keras para entrenar los modelos neuronales; cuantización a int8 por PTQ (post-training) con representative dataset; QAT como fallback.**

**Contexto.** El backlog #10 define el lado del **worker**: con qué framework se entrenan los modelos **neuronales** (autoencoder denso; LSTM si se persigue) y cómo se cuantizan a **int8** para correr en la cintura. Debe encajar con el **runtime del #8** (TFLite Micro / LiteRT for Microcontrollers, ADR-020) y con el **OTA de flatbuffers** (ADR-012).

**Alcance.** Sólo modelos **neuronales**. Mahalanobis (numpy + CMSIS-DSP) e Isolation Forest (**scikit-learn** para entrenar; árboles en C para inferir) **no** usan TF.

**Opciones — framework.**
- **A — TensorFlow/Keras (elegida).** *Pros:* Juan lo maneja; **integración directa** con el conversor TFLite/LiteRT y con TFLite Micro (una sola cadena TF→conversor→runtime, sin puentes); el conversor soporta full-integer int8 out-of-the-box. *Contra:* —.
- **B — PyTorch.** *Pros:* popular, ergonómico. *Contra:* para llegar a TFLite Micro requiere un **export extra** (ONNX→TF, o conversores de terceros), más piezas que pueden fallar; sin ventaja para este caso.

**Opciones — cuantización.**
- **PTQ (post-training quantization) (elegida).** Entrenar en float32 y cuantizar **después** a int8 con un **representative dataset** (muestra de vectores de features reales) para calibrar los rangos de las activaciones. *Pros:* simple, sin reentrenar, sin tocar el training. *Contra:* el modelo no "aprendió" a convivir con el redondeo → puede perder algo de precisión.
- **QAT (quantization-aware training) — fallback.** Simular el int8 **durante** el entrenamiento (fake-quant) para que el modelo se adapte. *Pros:* recupera precisión. *Contra:* más costoso (modificar el grafo, reentrenar). Se usa **sólo si** PTQ degrada la detección más de lo aceptable.

**Decisión.** **TensorFlow/Keras + PTQ int8** con representative dataset; **QAT como fallback** medido. Estrategia: cuantizar con PTQ, comparar el int8 vs float en validación (AUC / distribución del error de reconstrucción / umbral); escalar a QAT sólo si la caída no es aceptable.

**Pipeline.** TF/Keras entrena (float32) → **conversor TFLite/LiteRT** (full-integer int8: `TFLITE_BUILTINS_INT8`, `inference_input/output_type = int8` para el M33 integer-only; representative dataset de la **captura operativa/calibración**) → **flatbuffer int8** → **OTA** (ADR-012) → **TFLite Micro** (ADR-020) en la cintura.

**Naming (verificado).** TensorFlow Lite se renombró **LiteRT** (sep. 2024); **TFLite Micro = "LiteRT for Microcontrollers"** (mismo runtime del #8; cambió el paquete, no el código). Las **versiones exactas** de TF/LiteRT se fijan al implementar (regla del `stack_tecnologico`).

**Justificación.** Coherencia end-to-end con el #8 (una sola cadena TF→conversor→TFLite Micro, sin export intermedio); familiaridad del equipo; PTQ alcanza para un AE denso/shallow (score robusto = error de reconstrucción) y es lo barato-primero, con QAT reservado y medido. El representative dataset sale de las **features del micro** (coherente con ADR-018 / ADR-005 rev c).

**Consecuencias.** Fija el stack de la **Vista 3**: Deep learning → **TensorFlow/Keras** (`decidido`); Cuantización → **PTQ int8** (`decidido`). El mismo framework cubre el **LSTM** si se persigue. La calidad post-cuantización se **valida** (parte del profiling #11).

**Fuentes.**
- *Post-training integer quantization* (full-int8, representative dataset, input/output int8) — LiteRT / Google AI Edge.
- *TensorFlow Lite is now LiteRT* (rename sep. 2024) — Google Developers Blog.
- *LiteRT for Microcontrollers* (ex-TFLite Micro) — Google AI Edge.

**Nota conceptual (en lenguaje llano).** Qué es cuantizar y la diferencia PTQ/QAT, sin background de ML.

- **Cuantizar = pasar el modelo de float32 a int8.** Los números del modelo (los **pesos**, lo aprendido, y las **activaciones**, los valores intermedios) normalmente son decimales de alta precisión (float32). El micro corre mucho más rápido y ocupa ~4× menos si son **enteros de 8 bits** (int8). Cuantizar es esa traducción. Como un int8 tiene **sólo 256 valores**, es como **redondear todo a una grilla de 256 escalones**: el truco es ponerlos donde importan para perder lo menos posible.
- **El rango y el "representative dataset".** Para mapear hay que elegir, por tensor, un **rango [min, max]** del mundo real y repartir ahí los 256 escalones. Los **pesos** ya se conocen al terminar de entrenar; las **activaciones** dependen de **qué datos entren**, así que no se saben de antemano. Por eso se pasa un **representative dataset** —un puñado de entradas reales (en nuestro caso, features de la calibración/captura operativa)— **sólo para medir** esos rangos y calibrar los escalones. **No es entrenar** ni necesita etiquetas.
- **PTQ (post-training).** Entrenás normal en float y **cuantizás al final** (con el representative dataset para calibrar). Simple y rápido, pero el modelo **nunca aprendió** a convivir con el redondeo → puede perder algo de precisión. *Analogía:* escribís un ensayo con detalle y **después** lo comprimís a un telegrama de 256 palabras — se pierde algún matiz.
- **QAT (quantization-aware training).** Metés el redondeo **durante** el entrenamiento (fake-quant: simula el int8 en la pasada hacia adelante, pero aprende en float), así el modelo **ajusta sus pesos para aguantar** la compresión. Mejor precisión, más laburo. *Analogía:* escribís el ensayo **sabiendo** que será un telegrama, y elegís palabras que sobrevivan.
- **Por qué PTQ acá.** El AE es **chico y denso** y el score es un **error de reconstrucción** (robusto), así que PTQ suele alcanzar. La regla es **probar barato y medir**: cuantizás con PTQ, comparás int8 vs float; si la caída es aceptable, va PTQ; si no, escalás a QAT.
- **int8 de punta a punta.** Como el M33 es **integer-only**, se ponen también **entrada y salida en int8**, para que no quede ninguna operación en float que el micro tenga que emular.

---

## ADR-023 — Alcance inicial de features por hardware (2 FSR: punta + talón)
**Estado:** aceptada — **Decisión: el hardware actual monta 2 FSR (punta + talón, eje antero-posterior). Los primeros modelos se entrenan con un set activo "2-FSR" que excluye las features que requieren separación medial-lateral (bloque E — COP_ML — y feature 18). Todas quedan definidas en el catálogo pero desactivadas; se activan al sumar FSR mediales/laterales, sin reescritura.**

**Contexto.** La placa actual tiene **2 FSR conectados**: ADC0/GP26 (**punta**) y ADC1/GP27 (**talón**) — cobertura **antero-posterior**. Los FSR **medial/lateral** (para COP_ML y ratio M/L) se agregan en una **etapa posterior** con otra disposición (ADC2/GP28 + otro). Con sólo punta+talón, las features de **fuerza medio-lateral / COP no tienen sentido** (no hay resolución medial-lateral). Se aprovecha la modularidad de **ADR-021** (features definidas siempre, activables por config) para no frenar el avance esperando la placa final.

**Decisión.**
- **Set activo "2-FSR (punta/talón)"** — perfil del hardware actual, versionado por `feature_set_version`:
  - **ON:** bloque A (espacio-temporales), B (variabilidad), **C** (fuerza por-FSR, instanciado a **punta** y **talón**), D-parcial (**#19 progression AP** — punta vs talón ✓; **#20/#21 simetría** ✓), F/G/H (IMU), I (tronco).
  - **OFF (diferidas — requieren FSR medial-lateral):** **bloque E completo (#22-25: COP_ML + range + velocity + zero-crossings)** y **#18 (ratio medial/lateral de peak force)**.
- Las features diferidas quedan **definidas en el catálogo** (Vista 3) pero **desactivadas** en el set activo. **Activación futura** = agregar los FSR medial/lateral → nuevo `feature_set_version` con esas features ON, **sin tocar el código** (firmware ni worker).
- **Los primeros modelos** (Mahalanobis, Isolation Forest, autoencoder) se entrenan y despliegan **con el set activo 2-FSR**.

**Justificación.** (1) No bloquea el desarrollo por esperar la placa final; (2) evita meter en los modelos features **degeneradas/sin sentido** (un COP_ML con 2 puntos antero-posteriores) que ensuciarían el baseline; (3) la modularidad de ADR-021 permite **prender las features ML en caliente** cuando llegue el hardware, sin retrabajo ni re-flasheo estructural; (4) IC/TO (SPEC-01, `F_total = Σ FSR`), stride length/ZUPT (SPEC-03) y el bloque C siguen funcionando con punta+talón.

**Consecuencias.**
- **Canales por pie hoy: 8** (accel 3 + gyro 3 + 2 FSR); el formato de paquete reserva slots para **N FSR** (CP-08).
- **SPEC-06 (COP_ML):** marcada **diferida** (requiere FSR medial-lateral).
- **Catálogo (Vista 3):** cada feature declara su **requerimiento de FSR/posición**; el set activo 2-FSR aplica el filtro.
- Actualiza **CP-01** (hoy 2 FSR punta/talón; ML a futuro) y es instancia concreta de **CP-08** (modularidad de FSR).
- Al agregar los FSR ML: `feature_set_version` nuevo, se re-calibra el baseline por-paciente con las features nuevas activas y se re-evalúan los modelos.

---

## ADR-024 — Asignación de cores por dispositivo (plantilla vs cintura)
**Estado:** aceptada — **rev 2026-07-20.** **Decisión (revisada): reparto uniforme — en los tres micros el core 0 aloja el radio y el core 1 el procesamiento. Plantilla: core 0 = WiFi-STA + TX + motor, core 1 = adquisición (100 Hz determinística) + eventos (IC/TO) + features por-pie. Cintura: core 0 = radio (WiFi-AP + BLE, coexistencia), core 1 = inferencia + fusión bilateral + IMU + decisión.** *(Originalmente la plantilla aislaba la adquisición —core 1 = adquisición sola, core 0 = WiFi-STA + features + TX + motor—; la revisión la alinea al mismo principio que la cintura: aislar el radio. Ver Revisión abajo.)*

**Contexto.** El RP2350 tiene **2 núcleos** (Cortex-M33). Los dos firmwares tienen **cuellos de botella distintos**: la **plantilla** es *acquisition-bound* (100 Hz duro; radio simple **WiFi-STA**; **no infiere**); la **cintura** es *radio-coexistencia + inferencia* (**WiFi-AP + BLE** simultáneos; inferencia pesada; adquisición liviana — sólo su IMU de tronco, sin FSR). Correcciones de Juan: las plantillas **no tienen BLE ni coexistencia** (sólo WiFi-STA) y **no infieren**; la inferencia toda vive en la cintura.

**Opciones (eje: qué recurso se aísla en su propio núcleo).**
- **Aislar la adquisición** (un core dedicado al muestreo). Ideal donde el cuello es el 100 Hz duro.
- **Aislar el radio** (un core dedicado al radio). Ideal donde el cuello es la coexistencia + hay cómputo pesado que separar.
- **Todo en un core** (el otro ocioso). Descartado: el radio mete jitter en el muestreo.
- **Swap (radio en core 1).** Pelea con el SDK (`cyw43_arch`/lwIP asumen core 0). Descartado.

**Decisión (A para la plantilla, B para la cintura).**
- **Plantilla → aislar el radio (rev 2026-07-20):** **core 0 = WiFi-STA + TX + motor**, **core 1 = adquisición + eventos (IC/TO) + features por-pie**. Se agrupa el *pipeline de sensado* (adquisición → eventos → features por-pie) en un núcleo y se aísla el WiFi en el otro. *(Reparto original: core 1 = adquisición sola, core 0 = WiFi-STA + features + TX + motor — ver Revisión.)*
- **Cintura → aislar el radio:** **core 0 = radio** (WiFi-AP + BLE coexistencia, donde el SDK lo pone y es *timing-sensitive*), **core 1 = inferencia + fusión + IMU + decisión**. La inferencia (lo pesado) tiene su núcleo **lejos del radio**; la adquisición de la cintura es liviana y no necesita un core dedicado.

**Justificación.** Cada dispositivo aísla **su** recurso crítico: la plantilla protege el **muestreo 100 Hz**; la cintura protege la **coexistencia del radio** y le da a la **inferencia** su propio núcleo. La coexistencia WiFi-AP+BLE (riesgo maestro §16) es **sólo de la cintura**. Poner el radio en el core 0 evita pelear con la convención del SDK.

**Consecuencias / pendientes.**
- **RTOS** y **rate del IMU de la cintura** (CP-17): **resueltos** — RTOS **bare-metal** en ambos (**ADR-025**); rate de la cintura **100 Hz + DMA**, con 50 Hz como fallback validable en #11 (**ADR-026**).
- **Comunicación entre cores:** FIFO de hardware (`multicore_fifo_*`) / `queue_t` con spinlocks (Pico SDK) o colas de FreeRTOS.
- Se corrige **Vista 2 §9** al modelo por-dispositivo.

**Revisión (2026-07-20) — la plantilla también aísla el radio → reparto uniforme.**
Originalmente la plantilla aislaba la **adquisición** (core dedicado al muestreo) por temor a que el **cálculo de features** fuera demasiado pesado para compartir núcleo con el 100 Hz. Al dimensionarlo, esa premisa no se sostiene: las **features por-pie** son livianas — el grueso (FFT del bloque H, entropías, LDLJ) es una **ráfaga de pocos ms ~1 vez por zancada (~1 Hz)**, y lo único por-muestra (el AHRS/Madgwick) cuesta µs en el M33 con FPU. Además, con **adquisición por DMA + IRQ** (ADR-014/026) el muestreo se autoprotege: la IRQ del tick preempta cualquier ráfaga de features y la muestra entra a horario igual.

El **verdadero** inquilino de latencia impredecible es el **WiFi** (driver CYW43), no las features. Por eso conviene **aislar el radio** —no la adquisición— también en la plantilla, agrupando el **pipeline de sensado (adquisición → eventos IC/TO → features por-pie)** en el core 1 y dejando el WiFi solo en el core 0. Beneficios: (a) muestreo y features quedan lejos del WiFi; (b) **data locality** — el crudo a 100 Hz no cruza de core; en edge cruzan sólo los resultados (~1 Hz); (c) queda un **invariante uniforme en los tres micros: core 0 = radio, core 1 = procesamiento**, que simplifica el código compartido. El cambio respecto del reparto original es **mínimo**: mover el cálculo de features del core 0 al core 1 (la radio ya estaba en el core 0).

**Aclaración (anti-confusión).** "features por-pie" = las que sólo necesitan la señal de *ese* pie (bloques A/B/C/E/F/G/H). Las **features bilaterales** (simetría — bloque D — y double support) **no** se calculan en la plantilla: se calculan en la **cintura** a partir de las features por-pie + eventos de ambos pies (ADR-005; maestro §8.1). La revisión no toca eso.

**Salvedad honesta.** La simetría es de **rol**, no de **carga**: el core 0 de la cintura además sostiene la coexistencia WiFi-AP+BLE (más pesado) y su core 1 además infiere. El reparto exacto se **confirma con el profiling (#11)**; si algún caso apretara, hay palancas (mover features, bajar el rate del IMU de cintura a 50 Hz).

**Nota conceptual — cómo se gestionan los dos núcleos a nivel código.**
- **Bare-metal (Pico SDK).** `main()` corre en el **core 0**; el core 1 queda ocioso hasta lanzarlo con **`multicore_launch_core1(entry)`** (le pasás la función que va a correr). Cada core corre su loop. **Datos entre cores:** **FIFO de hardware** (`multicore_fifo_push/pop`, 32 bits, señales chicas) o **`queue_t`** (`queue_add/remove_blocking`, thread/core-safe vía **spinlocks**) para buffers. **IRQs por-core:** la de ADC/DMA se habilita en el core de adquisición; las del radio en el otro. El `cyw43_arch` (WiFi/BLE) se inicializa en el core 0. Ej. plantilla: `core1_entry()` = loop de muestreo que empuja a una `queue_t`; `main()` (core 0) = WiFi-STA + saca de la cola → features → TX + motor; al arrancar, `multicore_launch_core1(core1_entry)`.
- **FreeRTOS-SMP.** Creás **tareas** (`xTaskCreate`) con **prioridad**; el scheduler las reparte entre los dos cores; para fijar una tarea a un núcleo, **core affinity** (`vTaskCoreAffinitySet`). Comunicación por colas/semáforos. Más ordenado con mucha concurrencia (cintura).
- **En una línea:** este ADR decide **qué** corre en cada core; **cómo** se implementa (bare-metal `multicore_launch` vs tareas FreeRTOS) es el RTOS de **CP-17**.

---

## ADR-025 — Modelo de ejecución del firmware: bare-metal (sin RTOS)
**Estado:** aceptada — **Decisión: bare-metal (Pico SDK, sin RTOS) en ambos firmwares (plantilla y cintura). FreeRTOS evaluado y no adoptado.**

**Contexto.** ADR-024 fijó la asignación de cores por dispositivo y dejó pendiente (CP-17) el **modelo de ejecución**: bare-metal vs FreeRTOS. **Bare-metal** = super-loop + IRQs + DMA, coordinado a mano con las primitivas multinúcleo del SDK. **FreeRTOS(-SMP)** = tareas con prioridad y un scheduler que reparte entre los dos cores.

**Opciones.**
- **Bare-metal (elegida).** *Pros:* máximo control y **mínimo overhead** (sin scheduler comiendo CPU/RAM); determinismo total; footprint mínimo; nada de OS que aprender/debuggear; encaja con el diseño **DMA + loop de adquisición**; comunicación entre cores con `multicore_launch_core1` + `queue_t`/FIFO/spinlocks e IRQs por-core (ver ADR-024). *Contra:* la coordinación se escribe **a mano**; en la **cintura** (radio-coexistencia + inferencia + OTA concurrentes) hay que ordenar el trabajo sin un scheduler — requiere más disciplina.
- **FreeRTOS(-SMP).** *Pros:* tareas + prioridades + preempción, cómodo con mucha concurrencia; port oficial para el Pico. *Contra:* overhead (CPU/RAM), dependencia y complejidad (stacks, prioridad-inversión), sobredimensionado para la plantilla. **No adoptada.**

**Decisión.** **Bare-metal en las dos** (plantilla y cintura). La concurrencia de la cintura (radio en core 0; inferencia + fusión + IMU + decisión en core 1) se maneja **a mano** con las primitivas multinúcleo del SDK + IRQs por-core; la decisión/feedback corre a ~1 Hz (por zancada), holgado para un super-loop.

**Justificación.** El sistema está construido sobre **DMA + un loop de adquisición determinístico** y cómputo de baja frecuencia (~1 Hz de decisiones); un super-loop con IRQs alcanza sin el peso ni la complejidad de un RTOS. Máximo control y menor footprint, coherente con el 100 Hz duro (ADR-014) y la separación de cores (ADR-024).

**Consecuencias.** Resuelve la parte de **RTOS de CP-17** (queda abierto sólo el **rate del IMU de la cintura**). Fija la fila RTOS del `stack_tecnologico` (bare-metal, `decidido`). Si la concurrencia de la cintura resultara inmanejable a mano (a ver con el profiling #11), FreeRTOS queda como opción a reconsiderar — pero no es el plan. Detalle de las primitivas multinúcleo: **nota conceptual de ADR-024**.

---

## ADR-026 — Estrategia de muestreo y lectura del IMU (tick maestro + DMA)
**Estado:** aceptada — **Decisión: leer el IMU en el tick maestro de 100 Hz (polling) con transferencia por DMA, corriendo el IMU con ODR interno alto (~1 kHz) + DLPF activo (sobremuestreo anti-alias). Un timestamp por tupla FSR+IMU. DATA_READY = fallback (requiere traza INT→GPIO en el PCB). FIFO descartada. Aplica a las tres unidades; la cintura muestrea a 100 Hz + DMA, con 50 Hz reservado como fallback validable en #11.**

**Contexto.** Cierra **CP-07** (cómo lee el IMU la plantilla) y la parte abierta de **CP-17** (rate del IMU de la cintura). Complementa **ADR-014** (adquisición determinística): ADR-014 fijó el FSR (ADC free-running + DMA + decimación a 100 Hz) y dejó la lectura del IMU en el tick maestro con la alternativa FIFO/DATA_READY a definir. El MPU-6050 ofrece tres formas de sacar las muestras (polling, DATA_READY por INT, FIFO) que difieren en timestamp, alineación con el FSR y necesidad de PCB.

**Opciones.**
- **A — Tick maestro (polling a 100 Hz) + DMA (elegida).** El mismo timer de hardware que pasea la adquisición dispara la lectura I²C; el DMA mueve los bytes; se lee accel+gyro junto con el FSR decimado → **un solo timestamp por tupla**. *Pros:* máxima simplicidad; timestamp único por tupla → fusión FSR+IMU y backbone de sync limpios; **no toca el PCB**; lectura pisada por el timer (jitter ~µs); con DMA el costo de CPU ≈ 0. *Contra:* IMU y poll son asíncronos → hay que **correr el IMU a ODR alto (~1 kHz) + DLPF** y pollear a 100 Hz (sobremuestreo + banda limitada <50 Hz evita aliasing y *beating*). Queda una latencia muestra→lectura acotada (≤1 período del IMU, ~1 ms) + group delay del DLPF, **casi constante** → no deforma derivadas/PSD (sólo corre el timing absoluto, que el sync maneja).
- **B — DATA_READY (interrupción del IMU) — fallback.** El IMU asierta su pin INT al haber muestra nueva; se lee (por DMA) en la ISR y se timestampea ahí. *Pros:* mejor fidelidad temporal; espaciado uniforme por el reloj del IMU. *Contra:* **suma un cable INT→GPIO → cambio de PCB** (hoy no ruteado); más IRQs. **Queda como fallback** si el profiling (#11) mostrara que la latencia/jitter de A ensucia las features de derivada/PSD.
- **C — FIFO — descartada.** El IMU acumula en su FIFO de 1024 B y se drena por lotes. *Pros:* espaciado uniforme; sin pérdidas; menos overhead por muestra. *Contra:* **peor encaje con la filosofía de sync** — los timestamps de la FIFO se *infieren* del reloj del IMU (otro time base) y hay que anclarlos al timer del RP2350 y al FSR; se pierde el "un timestamp por tupla"; gestión de overflow. **Descartada.**

**Decisión.** **A (tick maestro + DMA)** en las tres unidades, con el IMU a **ODR alto + DLPF**. **B (DATA_READY)** como fallback, con la **traza INT→GPIO ruteada en la próxima rev del PCB** (aunque no se use) para que habilitarlo sea sólo firmware — coordinar con CP-01/CP-08. **Cintura: 100 Hz uniforme + DMA**; **50 Hz** reservado como fallback validable en #11 (las features de tronco son de baja frecuencia, así que no se pierde señal). La lectura por DMA es clave en la cintura, donde el IMU **comparte el core 1 con la inferencia** (ADR-024 rev): el DMA + la IRQ hacen que la llegada de muestras no compita con la inferencia bloqueante.

**Justificación.** A preserva el **timestamp único por tupla** (base del sync y de la fusión) y **no requiere tocar el PCB**; para marcha —señal de baja frecuencia— el DLPF controla el aliasing de sobra; y con DMA el muestreo casi no cuesta CPU. Uniformar a 100 Hz en las tres unidades mantiene el mismo código de features y las mismas ventanas (paridad, ADR-018). B se reserva por si hiciera falta fidelidad temporal extra; C se descarta por chocar con el modelo de sincronización.

**Consecuencias.** Cierra **CP-07** y la parte abierta de **CP-17**. Añade un requisito al PCB: **rutear la traza INT→GPIO del IMU** en la próxima revisión (habilita el fallback B sin otra vuelta de placa) → nota en **CP-01/CP-08**. Fija en el firmware: IMU a ODR alto + DLPF, lectura I²C por DMA en el tick de 100 Hz. Detalle de implementación (registros del MPU-6050, config del DLPF/SMPLRT_DIV, canal DMA de I²C) → se ancla en la **SPEC-04** (módulo IMU) al implementar.

**Apéndice conceptual (en llano).**
- **Tick maestro / polling.** Un timer de hardware hace *tic* 100 veces por segundo; en cada *tic* el firmware le pregunta al IMU "¿tu valor ahora?" y lo anota junto al FSR (un solo timestamp). "Pollear" = preguntar de a ratos.
- **Los dos relojes y el *beating*.** El IMU produce muestras con **su** reloj; vos leés con **el tuyo**. Si ambos van a 100 Hz y se corren, a veces leés la muestra vieja (duplicás) o te salteás una. Se evita haciendo que el IMU produzca **mucho más rápido** (~1 kHz) con su filtro (DLPF) prendido: siempre hay dato fresco esperando y tomás el último. (Analogía: alguien anota la temperatura 1000 veces/seg; vos copiás 100 veces/seg lo que haya — nunca la pizarra en blanco, y el número tiene ≤1 ms de viejo.)
- **DLPF (Digital Low-Pass Filter).** Filtro interno del IMU que limita la banda a <50 Hz → al leer a 100 Hz no hay aliasing.
- **DMA (Direct Memory Access).** Un circuito ayudante que mueve los bytes del IMU a la RAM **sin la CPU**; la CPU sólo lo arma y sigue con lo suyo. Resuelve el *transporte*, no el *procesamiento*.
- **Interrupción (IRQ).** Aunque la CPU esté ocupada infiriendo (bloqueante), un timer por hardware la **preempta** un instante para capturar la muestra a horario y vuelve. Por eso, en la cintura, IMU (core 1) e inferencia conviven: **la IRQ garantiza el *cuándo*, el DMA lo hace casi gratis**.

---

## ADR-027 — Diseño del feedback vibrotáctil (monitoreo + alerta por ventana)
**Estado:** aceptada — **Decisión: el feedback es un monitor de anomalía + alerta, NO un corrector de marcha. Consume un score designado (`feedback_source` en el registry, model-agnostic — Mahalanobis/AE/IF/ensemble) evaluado sobre una ventana de zancadas recientes; ante una anomalía sostenida y confiable emite una alerta escasa (con refractario) en una de 3 bandas de severidad (leve/marcada/riesgo) por umbrales per-paciente, con "riesgo" co-anclado a indicadores de caída (asimetría/sway). Entrega: 3 patrones por ritmo en el motor PWM, ambos pies, calibrados por paciente. Modelo designado, largo de ventana, agregación y umbrales = empíricos (análisis exploratorio).**

**Contexto.** Resuelve **CP-10**. El detector corre en la cintura y el motor en las plantillas (ADR-005; Vista 2 §6). Faltaba definir *qué* dispara el feedback, *cuándo*, con *qué* patrones y a partir de *qué* score. Evidencia (papers de la investigación): **patrones > alertas simples** (Sanchez-Morillo 2025); **la carga cognitiva del biofeedback es real y daña** en dual-task → feedback escaso (Iwata 2019); **umbral + inmediato funciona** clínicamente (Ma 2018), pero su propósito era *corregir* fuerza plantar, no el nuestro; **riesgo de caída = asimetría de carga + sway** (Jung 2017).

**Decisiones (sub-decisiones y por qué).**
- **Propósito: monitorear y advertir, no corregir.** El sistema detecta que la marcha viene anómala y **avisa**; qué hace el paciente (corregir, descansar, ignorar) es su decisión. Coherente con el título de la tesis (*detección* de anomalías). De los papers de biofeedback se toma **cómo entregar** el aviso, no el objetivo de corregir.
- **Timing: por ventana, no por zancada (event-locked/terminal, no concurrente).** El detector no juzga la última zancada aislada — evalúa un **tramo reciente** (últimas N zancadas / ~decenas de segundos) y decide si hay anomalía **sostenida**. Se prioriza **eficacia** (certeza, pocos falsos positivos): una anomalía real persiste varias zancadas seguidas. **Concurrente descartado** (mid-zancada): además de más carga cognitiva y dependencia, el score es **por-zancada** (existe recién al cerrar la zancada) → el feedback basado en el detector es **naturalmente terminal**. Un concurrente real necesitaría un disparador aparte sobre la señal cruda (tipo Ma) — opción futura, no v1.
- **Fuente model-agnostic.** El feedback consume un **score designado** (`feedback_source` en el registry); **qué detector** lo produce —Mahalanobis, autoencoder, Isolation Forest o un **ensemble**— es swappeable **sin tocar la lógica de feedback** (decisor agnóstico al origen del score, ADR-011 rev). Default razonable = **Mahalanobis** (siempre corriendo como sensor de drift, clase L, <100 µs), reemplazable. **Cuál gana = empírico** (exploratorio; distintos modelos cazan anomalías distintas).
- **Severidad: 3 bandas por umbral per-paciente.** El score (sobre la ventana) se corta en **normal / leve / marcada / riesgo** con **3 umbrales calibrados sobre el baseline del paciente** (percentiles / chi-cuadrado). Extiende el umbral único del detector Mahalanobis a 3 niveles graduados.
- **"Riesgo" co-anclado a caída.** El nivel más alto escala también por **indicadores clínicos interpretables** (asimetría/sway → Jung), no sólo por score grande.
- **Localización: ambos pies (v1).** No se localiza *qué pie* se desvía (evita un problema de detección extra). Ambas plantillas vibran el mismo patrón. Palanca futura: detectores por-pie (las features por-pie ya existen → no es algoritmo nuevo, pero suma modelos/config).
- **Entrega: 3 patrones por ritmo (no por intensidad fina).** El motor es un **ERM por PWM** (GP18) → discrimina bien **ritmos** (uno/dos/largo) y **ubicación**, mal la intensidad fina. Leve = 1 pulso corto; marcada = 2 pulsos; riesgo = pulso largo/triple. *(Si el motor real fuera un LRA con driver, se podrían usar patrones más crispados — a confirmar, como CP-01.)*
- **Escasez.** Histéresis (sostenido, no una zancada suelta) + **período refractario** (cooldown) + **fading** opcional (bajar la frecuencia a medida que el paciente mejora — evita dependencia).

**Justificación.** Encaja con lo ya decidido (model-agnostic, ADR-011 rev; usa el buffer de zancadas de SPEC-05; corre en la cintura, ADR-005/013). La ventana prioriza eficacia (menos falsos positivos) y la escasez prioriza usabilidad (menos carga cognitiva, Iwata). El propósito "monitorear+advertir" es honesto con el alcance de la tesis y con lo que el hardware simple puede sostener.

**Consecuencias.** Nuevo campo **`feedback_source`** en el registry/config. **Config per-paciente en la DB** (feedback_source, umbrales T1/T2/T3, N de ventana, intensidad, patrones habilitados, refractario) → detalle en **Vista 4**. Detalle de patrones y lógica → **SPEC-09**. **Empírico diferido** (exploratorio, ligado a #12 y al protocolo de calibración): qué modelo, largo de ventana, agregación (persistencia vs features ventaneadas) y valores de umbral. **Seguridad (CP-04):** validar que el patrón "riesgo" **no sobresalte/desestabilice**. Cierra **CP-10**.

**Apéndice conceptual (en llano).**
- **Monitor vs corrector.** No le decimos al paciente *cómo* caminar en cada paso; le avisamos que su marcha viene rara. Detección + alerta, no entrenamiento paso a paso.
- **Ventana vs zancada.** En vez de reaccionar a una zancada suelta (que puede ser un tropiezo casual = falso positivo), el algoritmo mira un **tramo** de varias zancadas: si la rareza **se sostiene**, recién ahí avisa. Más certeza, menos falsas alarmas.
- **Concurrente vs event-locked.** Concurrente = te avisa *mientras* das el paso (corrección en vivo). Event-locked/terminal = te avisa *después* de evaluar el tramo. Elegimos el segundo (menos carga mental, mejor aprendizaje, y es lo natural porque el score existe recién al cerrar la zancada).
- **Model-agnostic (`feedback_source`).** La lógica de feedback pide "un número de rareza"; de qué algoritmo sale ese número es una perilla configurable — se elige con datos cuál anda mejor (o una combinación).
- **Bandas por umbral per-paciente.** El "normal" de cada uno es distinto; las 3 líneas (leve/marcada/riesgo) se dibujan sobre el rareza-metro **de ese paciente**, calibrado con su marcha estable.

---

## ADR-028 — Emparejamiento BLE del wearable (sin botón físico)
**Estado:** aceptada — **Decisión: el pairing user-facing es cintura↔host (BLE); plantilla↔cintura es de fábrica. La cintura entra en pairing por auto-advertise cuando no tiene bond (primer uso) + un gesto sin botón: sacudir la cintura de forma marcada ~5 s mientras las plantillas están quietas (re-emparejar/agregar host), con ventana temporal. Autenticación v1 = passkey fijo impreso (LE Secure Connections, Passkey Entry). Bond list multi-host (N≈4, configurable), reconexión iniciada por el host (una conexión a la vez, primero en llegar), evicción LRU o forget explícito. "Borrar todo"/factory-reset y una eventual pantalla (passkey por sesión) → máxima. Dependencias: CP-04 (nivel de seguridad), CP-15 (UX de la app).**

**Contexto.** Resuelve **CP-14** a nivel mecanismo. Los micros son tipo **auriculares BLE** (nunca WiFi de internet; Vista 1 §3.3): la cintura es periférico GATT y el host (laptop/celu) es central. El micro **no tiene botón ni pantalla**, pero **sí IMU en los tres** y la cintura es el **hub de fusión** (ve los tres IMU en una línea de tiempo común). **BTstack** provee Security Manager con **LE Secure Connections** (Just Works / Passkey Entry / Numeric Comparison / OOB).

**Decisiones (sub-decisiones y por qué).**
- **Qué se empareja.** *Plantilla↔cintura*: **de fábrica** (WiFi, credenciales grabadas por set; re-pair = operación de servicio). *Cintura↔host (BLE)*: es el pairing user-facing y lo que resuelve este ADR.
- **Entrar en pairing (el "botón" que no hay).** **Auto-advertise cuando no tiene bond** (primer uso, estilo auriculares recién sacados de la caja) + **gesto por IMU**: la cintura entra en pairing si su IMU detecta una **sacudida marcada y sostenida ~5 s** *y* **las dos plantillas están quietas** en esa ventana (condición **multi-IMU** que evita falsos disparos por bailar / marcar el paso con el pie — si los pies se mueven, no dispara; si se sacude una zapatilla, la cintura está quieta, no dispara). Aprovecha que la cintura ya ve los tres IMU (hub). Requiere plantillas **encendidas + conectadas** (lo están, por el WiFi de fábrica). **Ventana temporal** de pairing tras el gesto (seguridad + energía). *Alternativa no elegida:* trigger por **cargador** (necesita sensado de carga — CP-08/09).
- **Autenticar sin pantalla/teclado.** **v1 = passkey fijo impreso** en la etiqueta de la unidad; el usuario lo tipea en la app (Passkey Entry con LE Secure Connections → protección MITM). **Just Works descartado** (sin MITM, son datos de salud). **Numeric Comparison / passkey en display descartados** (no hay pantalla). **OOB por QR** queda como opción futura; un **passkey por sesión con pantalla** en la cintura, para **máxima**. El passkey estático es más débil que uno por sesión (si fotografían la etiqueta, lo tienen) → aceptable en v1, se registra en CP-04.
- **Bond list (multi-host).** La cintura **recuerda N≈4 hosts** (configurable) — p. ej. laptop de la clínica + celu del paciente — para no re-emparejar al cambiar de contexto. Al llenarse: **evicción LRU** (borra el más viejo) o **forget explícito**. La cantidad de bonds se fija en BTstack al build (`le_device_db`).
- **Conexión / arbitraje.** La cintura **advertisa**; el **host (central) inicia** la conexión y se reconecta solo con las llaves guardadas (sin passkey). **Una conexión a la vez**: si dos hosts conocidos están presentes y buscando, **gana el primero que inicia**; mientras está conectada, la cintura **deja de advertisar como conectable** → el otro no entra hasta que el primero se desconecte. **Cambiar de host** = el conectado suelta (cerrar app / desconectar) y el otro entra. **Preferir** un host (p. ej. la clínica) = advertising dirigido o lógica de la app (CP-15).
- **Diferido a máxima.** **"Borrar todo" / factory-reset** (privacidad: al reasignar la cintura a otro paciente hay que borrar bonds + datos → requisito de CP-04) y **pantalla** en la cintura (passkey por sesión / numeric comparison).

**Justificación.** Sin botón ni pantalla, el **gesto IMU + la condición multi-IMU** dan un disparador intencional y robusto **reusando hardware**; el **passkey fijo** da MITM decente con LE Secure Connections para v1; el **bond list multi-host** evita re-emparejar entre clínica y casa; y el modelo **"un host a la vez, el host inicia"** es el de BLE estándar (tipo auriculares), simple y predecible. BTstack soporta todo el camino.

**Consecuencias.** Firmware de la cintura: **BTstack SM con Passkey Entry (passkey fijo)**; advertising connectable **cuando no hay bond** y **tras el gesto** (con ventana); **bond storage** (`le_device_db`) con **N configurable**; **detección del gesto** (cintura sacudida + plantillas quietas) con los IMU ya presentes. **Manufactura:** passkey impreso en la etiqueta (único por unidad). **Dependencias abiertas:** **CP-04** (ratifica el nivel de seguridad; requisito de borrar bonds+datos al reasignar), **CP-15** (UX de pairing y gestión de bonds en la app), **máxima** (clear-all, pantalla, OOB). **Cierra CP-14** a nivel mecanismo.

**Apéndice conceptual (en llano).**
- **Periférico vs central.** La cintura es el **periférico**: "advertisa" (emite *acá estoy*). El host (laptop/celu) es el **central**: escanea y **arranca** la conexión. El periférico **no elige** con quién conectarse; el central inicia.
- **Pairing vs bonding.** *Pairing* = el intercambio seguro de la **primera vez** (donde entra el passkey). *Bonding* = **guardar las llaves** (LTK) para reconectarse después **sin repetir** el passkey. Un "bond" = una relación segura guardada con un host puntual.
- **El gesto sin botón.** No hay botón, pero hay IMU en los tres micros. **Sacudir la cintura fuerte ~5 s** = "quiero emparejar". Para que **no** dispare por accidente (bailar, marcar el paso), se exige además que **las plantillas estén quietas**: cintura moviéndose + pies quietos = intención clara. La cintura ya ve los tres IMU (es el hub), así que la condición sale gratis.
- **Passkey fijo.** La cintura no tiene pantalla para mostrar un número, así que el número va **impreso en la etiqueta**; el usuario lo tipea en la app. Con LE Secure Connections eso protege contra el "hombre en el medio". Es **estático** (más débil que uno por sesión) → v1; la pantalla futura lo mejora.
- **Bond list / multi-host.** La cintura **recuerda hasta N hosts** (clínica + casa) y no hay que re-emparejar cada vez.
- **Conexión y desconexión con uno o más dispositivos.**
  - Con **un** host conocido cerca: la cintura advertisa y el host **se reconecta solo** con las llaves guardadas (sin passkey).
  - Con **dos** conocidos cerca y las dos apps buscando: **gana el que inicia primero**; la cintura queda ocupada con ese y **deja de advertisar como conectable**, así el otro **no puede entrar** hasta que el primero se desconecte. **Una conexión a la vez.**
  - **Cambiar** de host: el que está conectado **suelta** (cerrás la app / "desconectar"), la cintura vuelve a advertisar y el otro entra. Es igual que unos **auriculares Bluetooth normales (no multipoint)**.
  - **Preferir** uno (p. ej. la clínica) = **advertising dirigido** a ese host primero, o lógica de la app.
- **Olvidar.** Si el bond list se **llena**, se borra el **más viejo** (LRU) o se pide un **forget explícito**. **Borrar todo** (reset de fábrica) queda para más adelante (máxima).

---

## ADR-029 — Ajustes de catálogo de features y de algoritmos tras la auditoría de alineación
**Estado:** aceptada — **Decisión: se extiende el catálogo con 4 features y un evento de segmentación, se suman 3 algoritmos candidatos al registry (OC-SVM, GMM, VAE), se documenta la sustitución OC-SVM→Mahalanobis y se fija una estrategia progresiva de evaluación de algoritmos. Todo trazable a la auditoría de alineación con el marco teórico y la investigación.**

**Contexto.** Se auditó (2026-07-21) la alineación del catálogo de features (Vista 3) y del stack de algoritmos contra el marco teórico, el documento de features, el anteproyecto y los 22 papers (informe: `docs/investigacion/alineacion_features_algoritmos.md`). El núcleo resultó fuertemente alineado (bloques A–G, los 4 algoritmos, la filosofía), pero se detectaron features que el marco enumera y no estaban en el catálogo, algoritmos con evidencia ausentes del stack (sobre todo el **One-Class SVM**, que ancla la evidencia de Toth) y la falta de una estrategia escrita de evaluación progresiva.

**Decisiones.**
- **Features agregadas** (Vista 3 Parte A; versionadas por `feature_set_version`, ADR-021):
  - **#39 Single support time** (bloque A, cintura) — activa; se deriva de los eventos IC/TO (= swing contralateral); su asimetría es informativa.
  - **#40 Symmetry Angle** (bloque D, cintura) — activa; complementa el Symmetry Index (#20) con mejor comportamiento estadístico (acotado [−100,100]).
  - **#41 Average zero-crossings de la aceleración** (bloque H, plantilla) — activa, prioridad Fase 4 (opcional, como el resto de H).
  - **#42 Mean peak sway density del COP_ML** (bloque E, plantilla) — **definida pero diferida** (requiere FSR medial-lateral, junto con el bloque E; ADR-023); top feature de Herbers.
  - **Mid-stance (MS)** — agregado como **evento de segmentación** (no feature), complementa IC/TO (SPEC-01/02); habilita segmentar presión/COP intra-stance.
- **Features diferidas/descartadas por hardware** (no entran al set activo): *contact area* (requiere matriz de presión; 2 FSR discretos no miden área — descartada con el hardware actual), *foot progression angle* (requiere yaw absoluto y el MPU-6050 no tiene magnetómetro — diferida), *stride/step width* (requiere referencia medio-lateral común entre IMUs — diferida).
- **Algoritmos candidatos sumados al registry** (model-agnostic, ADR-011 rev; declarables sin reescritura):
  - **One-Class SVM — clase E/W:** benchmark de referencia en el worker (offline), por ser el de mejor evidencia (Toth, OC-SVM personalizado AUC 0,967). **No** corre en tiempo real.
  - **GMM / z-score multivariado — clase L/E:** generalización multimodal de Mahalanobis; baja prioridad.
  - **VAE — clase E/H:** variante de la rama autoencoder; baja prioridad. (CNN+Transformer de EdgeSense descartado por footprint en el Pico.)
- **Sustitución OC-SVM → Mahalanobis (documentada):** el detector one-class de **tiempo real es Mahalanobis** (no OC-SVM) por costo/latencia edge (<100 µs, auto-adaptación dato a dato). El OC-SVM queda como benchmark offline. El feedback sigue consumiendo `feedback_source` (ADR-027), agnóstico al detector ganador.
- **Fuera del stack de detección:** Random Survival Forest, COX y SHAP (pronóstico de recuperación con variables clínicas) son otra tarea → módulo aparte a futuro; **LASSO** es método de selección de features → backlog #12; **SST-AD/SVR/RF** del anteproyecto §6 → se dirimen en CP-11 (SST-AD no está definido en ninguna fuente del corpus).
- **Estrategia progresiva de evaluación** (Vista 3 §7.1): evaluar de a poco, escalando sólo si el anterior no alcanza — Mahalanobis (baseline) → Isolation Forest → AE denso int8 → LSTM AE, con OC-SVM/GMM/VAE como benchmark offline. Coherente con el pipeline del marco §6.3 y con la economía de cómputo; alimenta el roadmap de implementación.

**Justificación.** Las features nuevas son las que el propio marco enumera y reducen la brecha con la evidencia sin costo estructural (encajan en la modularidad, ADR-021). Las diferidas/descartadas lo son por límites reales del hardware. Sumar OC-SVM/GMM/VAE como candidatos declarativos no cuesta (registry model-agnostic) y preserva el detector RT barato dejando un benchmark fuerte para la fase de datos. La estrategia progresiva evita sobre-ingeniería y ordena el roadmap.

**Consecuencias.** El catálogo pasa de **41 a 45 features nominales** (bloques A–I). Vista 3 (vista consolidada + satélite) actualizadas. El **maestro §8.4** y **`resumen_investigacion.md`** quedan con el conteo/taxonomía viejos (pendiente de sync — el maestro se mantiene intacto por decisión de Juan). Las **advertencias de validez** del informe (validez de plantillas a baja velocidad; validación running→stroke de los eventos IC/TO; stride time no asimétrico en ACV → no usarlo como feature de simetría; feedback correctivo vs monitoreo) se anexan al **plan de captura/validación** (fase de dataset). No cambia ninguna decisión previa; extiende catálogo y registry.

**Referencia.** `docs/investigacion/alineacion_features_algoritmos.md` (informe de auditoría).

---

## ADR-030 — Reconciliación del anteproyecto y el marco teórico con la arquitectura
**Estado:** aceptada — **Decisión: se registra el *delta* documental entre los documentos fuente (anteproyecto oficial + marco teórico) y la arquitectura real, con su justificación por ADR. Es una reconciliación de coherencia, no una decisión de diseño nueva: las decisiones ya estaban tomadas en ADRs previos. El anteproyecto NO se modifica (documento ya presentado); el marco teórico recibe una nota-puntero a este ADR. Cierra CP-11.**

**Contexto.** El anteproyecto (`docs/Anteproyecto_Tesis.pdf`) y el marco teórico se escribieron al inicio del proyecto y describen un sistema **anterior** a varias decisiones de arquitectura. La **auditoría de alineación** (2026-07-21, `docs/investigacion/alineacion_features_algoritmos.md`) confirmó las divergencias exactas. **CP-11** pedía reconciliarlas. Esta reconciliación es **documental**: sirve para la coherencia de la memoria de tesis (justificar por qué la arquitectura final difiere del anteproyecto) y para el onboarding; no bloquea el código.

**Delta registrado (lo que decían las fuentes → lo que es → por qué).**
1. **Topología: "plantilla autocontenida" / solo-plantilla → insoles + cintura-hub.** Ni el anteproyecto ni el marco incluyen la unidad de cintura. Resuelto por **ADR-001/ADR-005** (cintura = AP + hub de fusión bilateral; CP-02): reparte cómputo, hace la fusión bilateral donde convergen los datos y capta el tronco (~L4-L5).
2. **IMU: BMI270 (anteproyecto: dual, uno por pie, bajo el arco) → MPU-6050 + IMU de cintura.** Cambio de part-number (ambos 6-DOF MEMS) + un IMU adicional en la cintura no presupuestado. **El motivo del cambio a MPU-6050 es disponibilidad actual + presupuesto** (ratificado por Juan); en una **próxima iteración de hardware** podría actualizarse a un IMU superior (p. ej. el BMI270 original). Su **impacto en el presupuesto de energía** (el MPU-6050 consume más que el BMI270, de ultra-bajo consumo) se sigue en **CP-09**.
3. **Bloque I de tronco:** no está en las fuentes; lo agregó la arquitectura (habilitado por la cintura). **Recupera el Improved Harmonic Ratio ML** —feature top-1 del set de 3 de Brasiliano— que el marco **daba por perdido** por no instrumentar el tronco. **ADR-029.** → La "limitación de sensores frente a Brasiliano" que el marco declara **queda resuelta** y debería anotarse así.
4. **Algoritmos:** el anteproyecto **§4.3** (Mahalanobis, Isolation Forest, AE denso, LSTM AE) **coincide** con el stack; el **§6** ("Autoencoders, SST-AD, SVR, Random Forest") **no**. Se adopta §4.3 (más candidatos declarables de ADR-029); **§6 se descarta** (SST-AD no está definido en ninguna fuente del corpus; SVR/RF eran referencias bibliográficas, no elecciones). La clase de Isolation Forest ya se reconcilió a **E** (ADR-011 rev).
5. **Feedback:** tensión interna del anteproyecto **edge** (§4.3) vs **"alerta accionada desde el backend"** (§5.3); resuelto **on-device** (la cintura decide) por **ADR-027 / CP-10**.

**Decisión.** Adoptar la arquitectura real (ADRs) como vigente y dejar registrado el delta de arriba. El **anteproyecto permanece como documento histórico** (no se toca: fue presentado). El **marco teórico** (documento de trabajo) recibe una **nota-puntero** al inicio que remite a este ADR-030 para el estado actual. **CP-11 → resuelta** (reconciliación documental). Deriva a otras cuestiones: el motivo/energía del cambio BMI270→MPU-6050 → **CP-09** (y ratificación pendiente del part-number).

**Justificación.** Las decisiones ya estaban tomadas y trazadas en ADRs; lo que faltaba era hacerlas visibles desde los documentos fuente para la memoria de tesis. Registrarlo ahora aprovecha que la auditoría dejó las divergencias identificadas (barato hoy, caro de reconstruir después). No se reescriben los documentos oficiales: se registra el delta y se apunta a él.

**Consecuencias.** CP-11 pasa a Resueltas (ref. ADR-030). El anteproyecto no cambia. El marco teórico gana una nota-puntero (sujeta a OK). **Motivo del MPU-6050 (ratificado):** disponibilidad + presupuesto; posible upgrade de IMU en una iteración futura. Su costo energético (mayor que el BMI270) se sigue en **CP-09**. No cambia ninguna decisión previa.

**Referencia.** `docs/investigacion/alineacion_features_algoritmos.md`; ADR-001/005/011 rev/027/029; CP-02/CP-09/CP-10.

---

## ADR-031 — Esquema de `feature_vectors`: jsonb + columnas generadas (resuelve CP-05)
**Estado:** aceptada — **Decisión: el vector de features por zancada se guarda como `jsonb` (una fila = un vector, con su `feature_set_version`); las pocas features "calientes" del dashboard se exponen con columnas generadas / índices de expresión; se deja la puerta de salida a un esquema *wide* (columnas fijas) para cuando el `feature_set_version` operativo se congele, si el perfilado lo justifica.**

> **Punto 3 reemplazado por ADR-044 (2026-10-17).** Los continuous aggregates nunca estuvieron disponibles en Supabase (edición Apache de Timescale). Las series agregadas del dashboard se resuelven con vistas materializadas o tablas de resumen refrescadas por `pg_cron`, cuando exista el dashboard.

**Contexto.** La tabla `feature_vectors` (hypertable de TimescaleDB, maestro §11.3) guarda un vector de ~15-25 features por zancada/scope. **CP-05** pedía definir cómo se guarda ese vector: `jsonb` flexible vs. columnas fijas. Dos hechos del proyecto mandan la decisión: (1) el **feature set aún cambia y está versionado** (`feature_set_version`, ADR-021; fase exploratoria; ADR-029 acaba de sumar 4 features), (2) el **volumen es bajo** (~1 vector/s por pie). Y hay **dos consumidores con patrones opuestos**: el worker de ML (quiere el vector completo por fila) y el dashboard clínico (quiere una feature a lo largo del tiempo).

**Opciones evaluadas.**
- **A — `jsonb` (elegida).** Una fila = un vector `{feature: valor}` + `feature_set_version`. *Pros:* flexible sin migraciones ante el set cambiante; la fila **es** el vector (natural para ML: traer el jsonb y expandir); ya está en el DDL. *Contras:* consulta por-feature más verbosa (`(features->>'x')::float`) y compresión de Timescale subóptima sobre jsonb → se mitigan con columnas generadas/índices.
- **B — Long / narrow.** Una fila por `(time, scope, feature_name, value)`. *Pros:* dashboard trivial y eficiente (`WHERE feature_name=…`), compresión óptima, flexible. *Contras:* el ML necesita **pivot** para reconstruir el vector; N× más filas; dispersa el "vector por zancada"; `feature_set_version` redundante por fila.
- **C — Columnas fijas (*wide*).** Una columna por feature. *Pros:* óptimo en storage/consulta/compresión y type-safe **si el set está congelado**. *Contras:* rígido — **migración (`ALTER TABLE`) por cada cambio** del set; con 45+ features y set activo 15-25 la tabla queda ancha y esparsa. Mal encaje con la fase exploratoria.

**Decisión.** **A reforzada:**
1. **`features jsonb`** como esquema primario (una fila = un vector con su `feature_set_version`).
2. **Columnas generadas `STORED`** derivadas del jsonb + índices para las features que el dashboard grafica seguido (p. ej. cadencia, score de anomalía, WBA/PSV cuando existan), **sin cambiar el flujo de escritura** (se sigue insertando sólo el jsonb; Postgres mantiene la columna).
3. **Continuous aggregates** de TimescaleDB para las series agregadas del dashboard (p. ej. promedio por sesión), cuando haga falta.
4. **Puerta de salida:** al congelarse el `feature_set_version` operativo, se puede materializar una vista/tabla *wide* para ML/dashboard si el perfilado lo pide — **sin rediseñar ahora**.

**Justificación.** La flexibilidad pesa (set cambiante + versionado + fase exploratoria) y el volumen no justifica optimizar por rendimiento (a ~1 Hz, las tres opciones sobran). `jsonb` conserva la **semántica de vector** (uso primario en la mínima = ML) y encaja con `feature_set_version`; sus contras de consulta se resuelven con columnas generadas puntuales. Se descarta *wide* como base ahora por rigidez; *long* se reserva como alternativa si el dashboard pasa a ser el consumidor dominante.

**Consecuencias.** El DDL del maestro §11.3 ya usa `features jsonb` → **no cambia ninguna decisión previa**: se confirma y se extiende con columnas generadas/índices. Se documenta en la **Vista 4**; el futuro `src/db/schema.sql` implementará `jsonb` + columnas generadas + hypertable + índices. **Cierra CP-05.** Ejemplo de columna generada para una feature caliente:
```sql
alter table feature_vectors
  add column cadence numeric generated always as ((features->>'cadence')::numeric) stored;
create index on feature_vectors (cadence);
```

**Apéndice conceptual (en llano).** *jsonb* = un tipo de columna que guarda una estructura JSON (pares clave-valor) en **binario** (parseado una vez al insertar), lo que permite consultarla e indexarla rápido — a diferencia del tipo `json`, que guarda el texto crudo. El vector de una zancada va entero en esa columna: **una fila = un paso**. Para sacar una sola feature se "abre el sobre" con `features->>'nombre'` y se castea a número. Una *columna generada* es una columna que **se calcula sola** desde el jsonb (no se escribe a mano): sirve para que las 3-4 features que el médico mira seguido salgan tan rápido como si fueran columnas normales, sin perder la flexibilidad del jsonb para el resto.

**Referencia.** ADR-007 (modelo de datos), ADR-021 (`feature_set_version`), CP-05; maestro §11.3.

---

## ADR-032 — Seguridad y aislamiento de datos: RLS estricto por paciente (resuelve CP-04 a nivel técnico)
**Estado:** aceptada — **Decisión: aislamiento de datos por paciente con RLS estricto de Supabase en todas las tablas con `patient_id`, mediante una tabla de pertenencia `patient_access` (user→patient→rol); el worker usa `service_role` (saltea RLS, sólo backend); + capa de seguridad (cifrado en tránsito/reposo, `external_code` anónimo + PII mínima, borrado de bonds+datos al reasignar la cintura). El nivel formal (consentimiento, anonimización, auditoría, passkey de ADR-028) queda sujeto al comité de ética → CP-18.**

**Contexto.** Datos de salud en Supabase (ADR-006/007). **CP-04** pedía definir el nivel de rigor de seguridad. Tiene **dos capas**: la **técnica** (esta decisión) y la **ratificación del comité de ética de ITBA** (externa → CP-18). §13 del maestro ya esbozaba la capa de seguridad; acá se concreta el **modelo de RLS**.

**Opciones evaluadas (aislamiento).**
- **A — RLS estricto por paciente desde el inicio + tabla de pertenencia (elegida).** *Pros:* aislamiento real ya en la mínima (barato en Postgres); la máxima (clínico+paciente) escala **sin reescritura**; coherente con mínima→máxima. *Contra:* definir políticas + tabla de acceso desde ya.
- **B — RLS simple ahora (un dueño), multi-rol en la máxima.** *Pros:* arranca más rápido. *Contra:* introducir el modelo de acceso al escalar (rompe "sin reescrituras").
- **C — Máximo rigor desde el inicio** (A + auditoría de accesos + cifrado a nivel de aplicación). *Pros:* postura más defensiva. *Contra:* overkill para una tesis salvo exigencia del comité.

**Decisión — A.**
- **RLS habilitado en todas las tablas con `patient_id`** (patients, sessions, feature_vectors, gait_events, anomaly_scores, models, model_deployments, retrain_jobs, raw_blobs, anomaly_raw_snippets), con políticas SELECT/INSERT/UPDATE/DELETE por pertenencia.
- **Tabla de pertenencia `patient_access`** (`user_id`, `patient_id`, `role ∈ {owner, clinician, patient}`); las políticas filtran por `exists (select 1 from patient_access where user_id = auth.uid() and patient_id = <fila>.patient_id)`.
- **Worker con `service_role`** (saltea RLS; sólo backend seguro, nunca en el cliente). Ingesta del host: mínima con el JWT del investigador (owner) o service-role; máxima con el token del paciente/dispositivo.
- **Mínima:** un usuario (investigador = owner) con acceso a todos los pacientes del estudio. **Máxima:** se suman filas clinician/patient **sin cambiar el esquema**.
- **Resto de la capa (confirma §13):** TLS/HTTPS a Supabase, BLE LE Secure Connections, WPA2 en el WiFi privado; cifrado en reposo por la plataforma; **`external_code` anónimo + PII mínima** (birth_year/sex/affected_side, sin nombre); retención tiered (ADR-008); **borrado de bonds + datos al reasignar la cintura** a otro paciente (ligado a ADR-028; factory-reset → máxima).

**Justificación.** RLS es el mecanismo estándar de Supabase para datos de salud multi-tenant; ponerlo desde el inicio es barato y evita reescribir al escalar. La tabla de pertenencia desacopla "quién accede a quién" de las tablas de datos y soporta owner/clinician/patient con la misma política.

**Consecuencias.** **CP-04 → resuelta a nivel técnico**; **CP-18 (nueva)** rastrea la ratificación del comité de ética (consentimiento, anonimización, auditoría, nivel de pairing). El futuro `src/db/schema.sql` implementará `enable row level security` + las políticas + `patient_access`. Se documenta en la **Vista 4** (seguridad). El maestro §13 no se toca (mantiene el overview).

**Apéndice conceptual (en llano).** *RLS* = la base filtra las filas por usuario, no la app. *service-role* = una llave de backend que ve todo (para el worker, que corre en servidor seguro). *Tabla de pertenencia* = la lista de "quién puede ver a qué paciente". Ejemplo de política:
```sql
alter table feature_vectors enable row level security;
create policy "acceso por paciente" on feature_vectors for select
  using (exists (select 1 from patient_access pa
                 where pa.user_id = auth.uid() and pa.patient_id = feature_vectors.patient_id));
```

**Referencia.** ADR-006/007/008/028; maestro §13; CP-04; CP-18.

---

## ADR-033 — Interfaces: UI de control (web local Python) y dashboard clínico (resuelve CP-15)
**Estado:** aceptada — **Decisión: dos UIs separadas por rol y necesidad técnica. (a) UI de control/operador = app local en Python + UI web (FastAPI sobre el host de ingesta `bleak`); en la máxima → app móvil nativa (mismo firmware BLE, replica el flujo). (b) Dashboard clínico = web de solo-lectura sobre Supabase (RLS), diferido a la máxima (en la exploración alcanzan notebooks); tecnología a decidir entonces.**

**Contexto.** **CP-15** pedía definir las interfaces (UI de usuario + dashboard clínico): alcance, tecnología y datos. Son **dos UIs con usuarios y necesidades opuestas**: la de **control** habla con la cintura por **BLE** (arranca captura, cambia modo) y registra la sesión; el **dashboard** sólo **lee de Supabase**. El host de ingesta ya es Python con `bleak` (stack Vista 4).

**Opciones evaluadas (UI de control).**
- **A — App local Python + UI web (FastAPI) (elegida).** *Pros:* un solo proceso/stack (BLE + ingesta + UI); el control llama directo a las funciones BLE (sin puente entre "UI" y "quien habla BLE"); el diseño (pantalla de comandos) se traslada a la app móvil de la máxima. *Contra:* algo más de trabajo que un notebook.
- **B — GUI de escritorio Python (PyQt/Tkinter).** *Pros:* un binario. *Contra:* no se reaprovecha hacia móvil (se rehace).
- **C — CLI/notebook.** *Pros:* rapidísimo para la instancia cero. *Contra:* provisional, no es UI usable por otro.

**Decisión.**
- **(a) UI de control = app local Python + UI web.** El host de ingesta (Python/`bleak`) expone una **UI web** (FastAPI + página) que: elige paciente (Supabase), **abre/cierra sesión** (modo captura exploratoria/operativa/edge), manda el **comando de modo a la cintura** (BLE control → propagado a las plantillas por WiFi), muestra **estado** (conexión/muestras/batería) y dispara **OTA**. **En la máxima → app móvil nativa** (BLE nativo); el firmware de la cintura no cambia (periférico agnóstico), la app **replica el mismo flujo/diseño**. *(Para arrancar la instancia cero puede apoyarse en notebook/CLI y montar la UI web encima, reusando las mismas funciones de control.)*
- **(b) Dashboard clínico = web de solo-lectura sobre Supabase (RLS).** Evolución de marcha, frecuencia de anomalías, WBA/PSV, riesgo de Jung, Z-scores, heatmaps por paciente; comparación con escalas (Berg, Fugl-Meyer, Barthel). **Diferido a la máxima**; en la exploración se usan **notebooks** (mismo stack de análisis). Tecnología (**Streamlit** rápido / **React** producto) **a decidir en la máxima** (backlog Vista 4). No controla las zapatillas.

**Justificación.** Separar por rol (operador vs médico) y por necesidad técnica (BLE local vs web de solo-lectura). La UI de control web-local reutiliza el host de ingesta y su diseño **escala a la app móvil sin tocar el firmware**. El dashboard no es crítico en la instancia cero (notebooks alcanzan), así que se difiere sin bloquear nada.

**Consecuencias.** **CP-15 → resuelta.** La UI de control se implementa junto al host (`src/host/`). El dashboard clínico y la app móvil quedan en el **backlog de la Vista 4** (tecnología a decidir en la máxima). El control de modos que la UI dispara ya está en la arquitectura (Vista 1 §6, canal de control); RLS (ADR-032) aísla lo que el dashboard leerá. Se documenta en la Vista 4; el maestro no se toca.

**Referencia.** ADR-006 (Supabase), ADR-002 (BLE), ADR-005 (fases de captura), ADR-032 (RLS); Vista 1 §6; Vista 4; CP-15.

---

## ADR-034 — Switch mínima↔máxima: el micro es agnóstico al tipo de host (resuelve CP-16)
**Estado:** aceptada — **Decisión: el micro NO detecta si está conectado a una computadora o a un celular. El pipeline lo determina el host (laptop → worker local; celular → worker en la nube). El modo de operación (captura exploratoria / operativa / edge) es un comando explícito por el canal de control, nunca una inferencia. El host declara su tipo en la metadata de la sesión, sólo para trazabilidad del dataset.**

**Contexto.** **CP-16** preguntaba si el micro puede/debe detectar el tipo de central BLE para switchear pipelines automáticamente, o si el flujo lo determina simplemente qué host se conecta. El **principio rector §2.3** ya establecía que "la infraestructura del lado del micro es la misma mande a una laptop o a un celular; el micro es un periférico BLE (servidor GATT) agnóstico al tipo de central" (ADR-002). CP-16 es, en el fondo, la ratificación de ese invariante.

**Análisis.** La pregunta decisiva no es *si el micro puede* detectarlo, sino *qué haría distinto si lo supiera*: **nada**. Muestrea a 100 Hz igual, calcula features igual, notifica por GATT igual, recibe OTA igual. Lo que cambia entre mínima y máxima es **dónde corre el worker** y **qué hace el host con los datos** — enteramente del lado del host (ADR-009). Técnicamente la detección sería posible por **heurísticas** (MTU negociado, restricciones de connection-interval típicas de iOS, o leer el `Appearance`/Device Name del central si expone un servidor GATT), pero son **frágiles, dependientes de plataforma y sin propósito**.

**Opciones evaluadas.**
- **A — Micro agnóstico; el host determina el flujo (elegida, con la variante de declaración).** *Pros:* preserva el invariante §2.3 y la reutilización 100 % del firmware de la cintura; sin heurísticas frágiles; cada host implementa su propio pipeline. *Contra:* ninguno relevante (el micro no necesita esa información).
- **B — Detección por heurísticas en el micro** (MTU, connection params, Appearance). *Pros:* switch "automático". *Contra:* frágil y dependiente de plataforma; acopla el firmware al tipo de central (rompe §2.3); resuelve un problema inexistente.
- **C — Handshake explícito que cambia el comportamiento del micro.** *Pros:* determinista. *Contra:* mete lógica de pipeline en el borde sin necesidad.

**Decisión — A + declaración del host (variante elegida por Juan).**
1. **El micro es agnóstico:** no infiere ni recibe el tipo de host como parámetro de comportamiento. Firmware idéntico en mínima y máxima.
2. **El flujo lo determina el host:** laptop → ingesta + worker local; celular → ingesta + puente, worker en la nube. Punto de variación aislado tras las interfaces de transporte y despliegue (maestro §14).
3. **Modo ≠ tipo de host:** el modo de operación (exploratoria / operativa / edge) se fija por **comando explícito** desde la UI de control (ADR-033) por el canal confiable. Es lo único que el micro necesita saber, y se lo dicen.
4. **El host declara su tipo en la metadata de la sesión** (`sessions.host_type ∈ {laptop, mobile}` + versión de la app): **trazabilidad del dataset** (saber con qué setup se capturó cada sesión), **sin efecto sobre el comportamiento** del micro ni del pipeline.

**Justificación.** Mantiene el invariante que hace que la mínima escale a la máxima sin reescrituras, evita heurísticas BLE frágiles, y aun así deja registro de con qué host se capturó cada sesión — útil para el análisis y para la memoria de tesis.

**Consecuencias.** **Cierra CP-16.** El esquema de `sessions` suma `host_type` (+ versión de app); lo escribe el host al abrir la sesión (Vista 4 / ADR-031/032). Sin cambios en el firmware ni en el protocolo. Se refleja en Vista 1 §7 y Vista 4.

**Referencia.** ADR-002 (uplink BLE), ADR-009 (worker), ADR-033 (UI de control), maestro §2.3 y §14; CP-16.

---

## ADR-035 — Encendido/apagado sin botón (resuelve CP-19)
**Estado:** aceptada — **rev. 2026-07-21** — **Decisión (rev): en la mínima NO hay gestión de energía. El switch físico es el encendido/apagado y todo permanece despierto mientras esté encendido; la autonomía alcanza sin dormir (~10 h contra un objetivo de ≥8 h). No se agrega corte de potencia por hardware. El wake-on-motion (dormant + interrupción del IMU) y el WiFi power-save quedan documentados como opciones para la máxima, no como parte del diseño de la placa nueva.**

> **Nota de revisión.** La versión original de este ADR (misma fecha) fijaba **soft-off + wake-on-motion** como objetivo, con el switch solo como arreglo de la Fase 1. Se revisó **a planteo de Juan**: para capturar dataset, la **robustez vale más que la autonomía** — y la autonomía no hace falta. Los argumentos de la revisión están en "Por qué se revisó", abajo. Lo que **no** cambió: no hay corte por hardware, y la alimentación es celda → VSYS (`esquema_alimentacion.md`).

**Contexto.** Los micros **no tienen botón** y la batería va **soldada permanentemente** (premisa de producto, coherente con ADR-028: el IMU es el "botón"). **CP-19** pedía definir si el encendido/apagado se resuelve por firmware o exige modificar el circuito. Dos hechos empíricos ordenaron la decisión:

1. **Medición de referencia:** en Pico 2 W se alcanza **<800 µA en DORMANT** apagando el CYW43 (que domina el consumo). Con la celda de **1000 mAh** eso da **>50 días** de reposo. El corte por hardware (3V3_EN + latch) llevaría a algunos meses más: **optimiza un problema inexistente**. El consumo que sí importa es el **activo** (CP-09).
2. **Hallazgo de banco (Juan):** con el cableado original (celda → módulo → boost 5 V → VBUS), el equipo **no arrancaba al conectar la batería** y **se apagaba solo** al quitar el USB — el boost del módulo arranca deshabilitado y corta por baja carga. Eso hacía **imposible** el dormant. **Alimentar VSYS directo desde la celda** (ver `esquema_alimentacion.md`) es lo que **habilita** este ADR.

**Opciones evaluadas.**
- **A — Sin gestión de energía; el switch es el encendido/apagado (ELEGIDA en la rev).** *Pros:* cero complejidad; **no se pierde ningún paso**; no depende de umbrales de movimiento ni de la traza INT; la autonomía alcanza (~10 h vs ≥8 h). *Contra:* en uso diario domiciliario (máxima) se queda corta.
- **B — Soft-off + wake-on-motion** (elegida en la versión original). *Pros:* máximo ahorro (dormant ~800 µA → >50 días); UX natural en calzado. *Contra:* **umbrales poco confiables en marcha hemipléjica**; **pierde los primeros pasos** tras el reposo; coordinación de wake entre unidades; depende de la traza INT.
- **C — La cintura manda, con WiFi power-save.** Plantillas **asociadas** durmiendo entre *beacons*, despertadas por tráfico del hub. *Pros:* coordinado desde el hub; sin traza INT; ahorro intermedio. *Contra:* mucho menos ahorro que el dormant (la radio sigue escuchando) y complejidad de configuración del CYW43.
- **D — Corte por hardware (transistor sobre 3V3_EN / load switch).** *Pros:* ~10× menos reposo. *Contra:* si se corta el rail el micro **no puede despertarse solo** → exige IMU en rail siempre-vivo + latch + fuente de wake externa. Más componentes por un beneficio que no se necesita.
- **E — Botón de encendido de cara al usuario.** *Contra:* contradice la premisa sin-botón (ADR-028) e **impracticable en la plantilla** (fina, sellada, bajo el peso del cuerpo, con impactos).

**Decisión (rev) — A: sin gestión de energía en la mínima.**

- **El switch físico es el encendido y el apagado.** Mientras esté cerrado, las tres unidades están **despiertas y operando**: no hay dormant, ni auto-sleep, ni wake por movimiento. Apagar = abrir el switch.
- **La autonomía alcanza sin dormir:** ~**10 h** a 100 mA con 1000 mAh alimentando VSYS directo, contra el objetivo blando de **≥8 h** (CP-09). **El dormant resolvía un problema que en la mínima no existe.**
- **Placa actual (ahora):** cableado **puenteado** (celda → VSYS, sensores desde 3V3, VBUS libre) + **switch físico en las tres placas**.
- **Próxima rev del PCB:** se mantiene el criterio **diferenciado por unidad** para el corte, porque las restricciones mecánicas no son las mismas — **cintura** con slide switch en serie con el positivo (+ pulsador de reset sobre RUN, opcional, para depuración); **plantilla sin actuador mecánico en el camino de potencia** (es fina, sellada, va bajo el peso del cuerpo y recibe impactos en cada paso; un reed switch, además, **rebotaría**), con corte de servicio por **JST/header accesible** al abrir la carcasa.
- **Traza INT del IMU → GPIO:** se mantiene en el checklist del PCB por el **fallback DATA_READY** (ADR-026) y para dejar la puerta abierta, pero **deja de ser crítica**.
- **Diferido a la máxima (documentado, no implementado):** **wake-on-motion** (opción B) y **WiFi power-save** (opción C). Se evalúan cuando el uso diario domiciliario lo exija.
- **Heartbeat cintura→plantillas:** útil, pero **para salud del enlace** (detectar una plantilla caída o sin batería), **no** para gestión de energía. Función aparte.

**Por qué se revisó (planteo de Juan).**
1. **Los umbrales de movimiento son poco confiables en la población objetivo.** Un umbral calibrado para movimiento normal puede no dispararse con un paciente hemipléjico que arrastra el pie y se mueve lento y débil: se apoyaría el encendido del sistema en la señal más incierta justo donde más importa.
2. **El auto-sleep hace perder los primeros pasos.** Si todo durmió mientras el paciente estaba sentado, al levantarse hay que despertar tres micros y **re-asociar el WiFi** — y la transición sentado-a-parado y los primeros pasos son de lo más valioso clínicamente. Perderlos por ahorrar energía es un mal negocio.
3. **Despertar por radio no ahorra energía.** Para que una plantilla *reciba* una orden de la cintura, su radio tiene que estar encendida y escuchando — y el CYW43 **es** el consumo dominante. Además, **re-asociarse en WiFi es lento y caro** (mucho más que reconectar BLE), así que duty-ciclar el enlace se come lo que ahorró.
4. **La autonomía no lo exige.** Con ~10 h contra 8 h de objetivo, la gestión de energía sería complejidad sin beneficio en esta etapa.

**Justificación.** Para **capturar dataset**, la **robustez y la integridad de los datos valen más que la autonomía** — y la autonomía ya está cubierta. Se elige el esquema con menos partes móviles y sin modos de falla silenciosos (una sesión fragmentada o unos primeros pasos perdidos son daños difíciles de detectar a posteriori). El ahorro de energía se reintroduce recién cuando el caso de uso (máxima) lo justifique.

**Consecuencias.** **Cierra CP-19.** El equipo se enciende y apaga **a mano**; no hay gestión de energía automática en la mínima. Se **simplifica el diseño de la placa nueva** (el wake-on-motion sale del alcance) y quedan **sin efecto** los pendientes de firmware asociados — auto-sleep dependiente del modo, indicador de encendido por pulso del motor, y secuencia de wake cintura↔plantillas —; se reactivarían si se adopta alguna de las opciones de la máxima (B o C). **Se mantiene, y gana importancia, el corte por baja tensión en firmware** (leer VSYS por el ADC y apagar ordenadamente antes de que actúe el PCM): sin dormant, un equipo que quede encendido consume hasta agotar la celda. El resto del **checklist de la rev del PCB** (`esquema_alimentacion.md` §7) no cambia — FSR medial/lateral (CP-01/CP-08), cargador de corriente limitada, alojamiento de la celda. **Nota:** al sellar la plantilla se pierde el acceso físico al BOOTSEL → el **OTA (ADR-012) debe estar probado antes de sellar la primera unidad**. El presupuesto de energía real sigue en **CP-09**.

**Referencia.** `docs/arquitectura/esquema_alimentacion.md`; ADR-026 (DATA_READY/INT), ADR-028 (sin botón, gesto por IMU), ADR-012 (OTA), ADR-014 (SNR); CP-01, CP-08, CP-09, CP-18.

---

## ADR-036 — Registro de la fase de captura y del origen de las features en el esquema
**Estado:** aceptada (2026-08-18) — **Decisión: `sessions.mode` pasa a tres valores (`exploratory` / `operational` / `edge`), reflejando las fases de ADR-005 rev c; y `feature_vectors` suma `features_source ∈ {device, offline}` para distinguir, fila por fila, el vector calculado por el micro del recalculado off-device.**

**Contexto.** ADR-005 rev c partió la captura en **dos fases con propósitos distintos** (exploratoria = crudo-solo, features off-device; operativa = el micro calcula features + se sube crudo), pero el esquema seguía con el enum anterior `mode in ('capture','edge')`. Detectado en la **auditoría de consistencia entre vistas del 2026-08-18**: la Vista 4 documentaba tres fases y el DDL sólo admitía dos.

**Análisis.** Al escribir el cambio apareció un requisito que el modo a nivel sesión **no cubre**. En la fase **operativa**, para una **misma zancada** van a existir **dos vectores de features**: el que calculó el micro —que es el que entrena los modelos desplegables, *skew-free* por construcción (ADR-018)— y el que se recalcula en Python desde el crudo de esa misma sesión para **validar la paridad**. Si ambos entran a `feature_vectors` sin discriminante, no hay forma de (a) filtrar el set de entrenamiento correcto ni (b) armar los pares para el test de paridad. El origen es un atributo **del vector**, no de la sesión.

**Opciones evaluadas.**
- **A — Tres valores en `mode` + `features_source` por fila (elegida).** *Pros:* mapea 1:1 con ADR-005 rev c; resuelve el caso de paridad, que es donde el modo por sí solo se queda corto; el discriminante queda donde ocurre la ambigüedad. *Contra:* una columna más en la hypertable (costo despreciable: ~1 vector/s por pie).
- **B — Sólo tres valores en `mode`.** *Pros:* cambio mínimo. *Contra:* deja sin resolver la convivencia de los dos vectores en la fase operativa; la garantía de ADR-018 quedaría dependiendo de convenciones fuera de la base.
- **C — `mode in ('capture','edge')` + `capture_phase` aparte.** *Pros:* conserva la distinción de alto nivel captura-vs-edge, que es la que ve el firmware. *Contra:* dos campos que hay que mantener coherentes entre sí (estado redundante, combinaciones inválidas posibles) y consultas más incómodas; la distinción que preserva ya la da el enum de tres valores.

**Decisión.**
1. `sessions.mode text check (mode in ('exploratory','operational','edge'))`.
2. `feature_vectors.features_source text check (features_source in ('device','offline'))` — `device` = calculado por el micro; `offline` = re-extraído en Python desde el crudo.
3. Índice `(session_id, features_source, time desc)` para armar los pares de paridad sin escanear la hypertable.

**Justificación.** Las tres fases no son matices de una misma cosa: cambian **qué transmite el micro**, **quién calcula las features** y **para qué sirve el dato**. Registrarlas es lo que hace que un dataset sea reinterpretable a posteriori. Y el `features_source` es lo que convierte la paridad (ADR-018) de una convención en algo verificable con una consulta.

**Consecuencias.** Cambia el DDL (`src/db/schema.sql`) y el mapa de entidades del maestro §11.3; se refleja en la Vista 4 (§1.1, §1.2, §1.3). **No requiere migración**: todavía no hay datos capturados — a partir de la primera captura sí (la herramienta de migraciones sigue pendiente en la Vista 4). El **firmware no cambia**: el modo ya se manda como comando explícito por el canal de control (ADR-034), sólo se amplía el vocabulario. El nombre en inglés mantiene la convención del resto del esquema.

**Referencia.** ADR-005 rev c (fases de captura), ADR-018 (paridad / anti train-serve skew), ADR-031 (`feature_vectors` en jsonb), ADR-034 (`host_type`), ADR-021 (`feature_set_version`); Vista 4 §1.

---

## ADR-037 — El esquema de la base tiene una sola fuente: `src/db/schema.sql`
**Estado:** aceptada (2026-08-18) — **Decisión: `src/db/schema.sql` es la fuente única de verdad del esquema. El maestro §11.3 deja de duplicar el DDL y pasa a mantener sólo el mapa de entidades con un puntero al archivo.**

> **Revisada por ADR-045 (2026-10-17).** La fuente única pasa a ser la **cadena de migraciones** (`src/db/supabase/migrations/`); `schema.sql` queda como snapshot generado para leer el esquema. Se conserva el principio: una fuente, varios consumidores.

**Contexto.** El DDL estaba escrito **dos veces**: en el maestro §11.3 ("DDL de referencia", 145 líneas) y en `src/db/schema.sql` (163 líneas). La **auditoría de consistencia del 2026-08-18** encontró que las dos copias **ya habían divergido** por su cuenta — distinto orden de tablas, comentarios distintos, acentos removidos en una — sin que nadie lo notara, y que ambas arrastraban los mismos huecos (RLS, `host_type`, config de feedback, fases de captura).

**Análisis.** Es exactamente la clase de problema que el repo ya resuelve para las features con la **regla de layering**: *se define una vez, se ejecuta en varios lados*. Una segunda copia sin mecanismo que la sincronice no es documentación redundante, es una **fuente de verdad en competencia**: ante una diferencia, nada dice cuál gana. Y el costo se paga en cada cambio de esquema, que a partir de ahora van a ser varios.

**Opciones evaluadas.**
- **A — `schema.sql` manda; el maestro describe (elegida).** *Pros:* el archivo que se ejecuta contra la base es el que manda; aplica la regla de layering ya vigente; el maestro conserva su rol de índice/overview sin cargar con detalle que envejece. *Contra:* el maestro deja de ser lectura autocontenida para el esquema (mitigado con la tabla de entidades).
- **B — El maestro manda; `schema.sql` derivado.** *Pros:* conserva el documento completo. *Contra:* pone al archivo de código a depender de un documento; el `.sql` es el que se corre, y sería el que puede quedar desactualizado justo cuando importa.
- **C — Mantener ambas + test de CI que compare.** *Pros:* detecta la divergencia. *Contra:* agrega infraestructura para un problema que se resuelve **no duplicando**; además todavía no hay CI (los tests de paridad de ADR-021 tampoco existen).
- **D — Dejarlo como está.** *Contra:* ya divergieron sin que nada lo detectara; con el esquema a punto de cambiar, el problema empeora.

**Decisión.** `src/db/schema.sql` contiene tablas, índices, hypertables, RLS y políticas. El maestro §11.3 pasa a **"Esquema — entidades"**: tabla de `capa | tabla | qué guarda` + puntero. La **Vista 4** sigue siendo la definición canónica *conceptual* del backend (qué guarda cada cosa y por qué); el `.sql` es la definición *ejecutable*.

**Justificación.** Coherente con cómo el proyecto ya trata las features y los modelos: una definición, varios consumidores. Deja el maestro en el rol que ADR-000/§0 le asignaron —índice y overview— en vez de segunda copia de todo.

**Consecuencias.** El maestro pierde ~150 líneas de DDL y gana una tabla de entidades. Toda modificación futura del esquema entra **sólo** por `src/db/schema.sql`; el maestro y la Vista 4 se actualizan si cambia el *mapa* (una tabla nueva, un cambio de propósito), no si cambia una columna. Refuerza la necesidad de la **herramienta de migraciones** (pendiente en la Vista 4): con una sola fuente, el historial del esquema pasa a ser el historial de ese archivo más sus migraciones.

**Referencia.** ADR-006/007 (Supabase, modelo de datos), ADR-031 (jsonb), ADR-032 (RLS), ADR-036 (fases y origen de features); maestro §0 (regla de layering) y §11.3; Vista 4 §1.

---

## ADR-038 — Adopción de mid-stance (MS) como evento de segmentación y partición del apoyo
**Estado:** aceptada (2026-08-18) — **Decisión: se adopta MS por completo. Se detecta en la plantilla como el cruce de carga retropié→antepié (SPEC-01), parte el apoyo en carga `[IC,MS]` y propulsión `[MS,TO]` (SPEC-02), instancia las features #12/#13/#14 del bloque C por sub-fase, y suma dos features nuevas: #43 push-off time ratio y #44 propulsive impulse ratio.**

**Contexto.** **ADR-029** (21/07) agregó mid-stance como *"evento de segmentación (no feature), complementa IC/TO (SPEC-01/02)"*, pero **SPEC-02 nunca se actualizó**: seguía listando mid-stance entre las *"sub-fases opcionales (diferidas) — no las requiere el feature set actual"*, y `gait_events.type` sólo admitía `IC`/`TO`. La **auditoría de consistencia del 2026-08-18** lo levantó como contradicción directa entre la Vista 3 y la SPEC. Había que dirimirla en un sentido o en el otro.

**Análisis.** El argumento a favor de diferirlo era que el consumidor que ADR-029 mencionaba —segmentar el **COP** intra-apoyo— pertenece al **bloque E**, que está **apagado** hasta tener los FSR medial/lateral (ADR-023). Pero al revisarlo apareció que ese no es el único consumidor, ni el más importante:

1. **Con los 2 FSR actuales (punta + talón) MS ya es detectable**, y de forma robusta: el instante en que las dos curvas de fuerza se cruzan. No depende del hardware pendiente.
2. **El déficit de push-off es el hallazgo más característico de la marcha post-ACV** en la propia bibliografía del proyecto: Kang (2025, paper #20) muestra que el lado parético **no logra activar las regiones anteromediales** y que el peak force en metatarsianos está sistemáticamente reducido; Sanghan et al. (2014) reportan diferencias de presión plantar del 30 ± 12 %; el marco teórico lo llama *"uno de los hallazgos clínicos más característicos"*.
3. Hoy las features del bloque C se calculan **sobre el apoyo completo, como un solo número**. La firma típica del lado parético —apoya, se queda en el talón y despega sin empujar— **se promedia y se pierde** en esa agregación. Partido en dos, es directamente visible.

O sea: el evento que parecía bloqueado por hardware es, en realidad, el que da acceso barato al marcador clínico central del cuadro, con el hardware que ya está en la mesa.

**Opciones evaluadas — alcance.**
- **A — Adoptar completo (elegida).** Detección en SPEC-01 + sub-fases en SPEC-02 + `'MS'` en el esquema + features que lo consumen. *Pros:* captura el déficit de propulsión desde la primera captura; activo con 2 FSR; deja el bloque E listo para cuando prenda. *Contra:* trabajo de firmware adicional en el detector; hay que definir features nuevas antes de tener datos.
- **B — Sólo catálogo y esquema.** Agregar `'MS'` al enum y registrarlo en V3 sin escribir detección ni features. *Pros:* cierra la contradicción a costo cero. *Contra:* deja el evento como declaración sin uso; alguien tiene que volver igual.
- **C — Diferirlo con el bloque E.** Marcar MS como "definido pero diferido", igual que #42. *Pros:* cero trabajo. *Contra:* posterga el marcador clínico más característico por una dependencia (FSR M/L) que **no es real** para este uso.

**Opciones evaluadas — definición del evento.**
- **A' — Cruce de carga `F_ante ≥ F_post` (elegida).** *Pros:* el FSR lo entrega robusto; es el instante **funcionalmente** relevante para la propulsión; mantiene la arquitectura de SPEC-01 (FSR primario + confirmación IMU). *Contra:* no es el mid-stance **cinemático** clásico.
- **B' — Cinemático por IMU** (tibia vertical / cruce por cero de ω sagital en pie plano). *Pros:* es la definición de Perry. *Contra:* invierte la jerarquía de SPEC-01 (el IMU es menos preciso en el instante: RMSE ~50-61 ms vs ~14 ms); y en marcha hemipléjica el pie plano puede no darse limpio.
- **C' — Geométrico (50 % del stance).** *Pros:* trivial. *Contra:* no es un evento, es una división arbitraria; no aporta información.

Se elige **A' con B' como confirmación**: el cruce de carga dispara, el pie-plano del IMU anota confianza. La **divergencia entre ambos** queda registrada como candidata de feature a futuro.

**Decisión.**
1. **SPEC-01** detecta **MS** = primer instante en `[IC, TO]` con `F_ante ≥ F_post` (banda muerta `h_ms`, una vez por apoyo), confirmado por el pie-plano del IMU dentro de `±W`. **Si no hay cruce** (el paciente nunca transfiere carga), se emite en el **máximo de `F_ante/F_post`** con baja confianza y flag **`no_crossover`** — *que es señal de anomalía, no error*.
2. **SPEC-02** parte el apoyo en **carga `[IC, MS]`** y **propulsión `[MS, TO]`**.
3. **Bloque C:** **#12, #13 y #14** se instancian **por FSR × sub-fase**. **#15** no se parte; **#16** (loading rate) queda con dominio explícito en la carga; **#17** sigue medido desde IC. Es **instanciación**, no entradas nuevas de catálogo — el mismo mecanismo que el bloque C ya usa por-FSR.
4. **Dos features nuevas** (catálogo 45 → **47**): **#43 push-off time ratio** = `(t_TO−t_MS)/(t_TO−t_IC)`, bloque A, per-pie, adimensional; y **#44 propulsive impulse ratio** = `PTI[MS,TO]/PTI[IC,TO]` sobre `F_total`, bloque D, per-pie. #44 es la contraparte **temporal** de #19 (que es **espacial**): no se duplican.
5. **Esquema:** `gait_events.type ∈ {IC, TO, MS}`.

**Justificación.** Se adopta la definición de carga porque es la que el hardware entrega bien y la que apunta al fenómeno clínico; se elige el alcance completo porque el costo marginal (un cruce con histéresis dentro de un detector que ya existe) es chico frente a lo que habilita. Las dos features nuevas son **adimensionales**, lo que las hace comparables entre velocidades de marcha y entre pacientes — deseable para un baseline personalizado. Y todo esto queda **activo en el perfil 2-FSR**, sin esperar la rev del PCB.

**Consecuencias.** Cambian SPEC-01 y SPEC-02, la Vista 2 §3, la Vista 3 (Parte A: bloques A/C/D + nota de conteo) y el esquema (`src/db/schema.sql`, `gait_events`). El catálogo pasa a **47** entradas nominales; el vector real crece más por la instanciación del bloque C. Las features que dependen de MS declaran esa dependencia en el catálogo (ADR-021), así que un MS de baja confianza las apaga sin tocar el resto. **Cierra la contradicción ADR-029 ↔ SPEC-02.** Se suman parámetros calibrables (`h_ms`, mapeo FSR→región) al `feature_set_version`. La validación de la detección de MS en marcha hemipléjica real queda para la fase de captura, junto con la de IC/TO (advertencia ya registrada en el informe de alineación).


---

### Apéndice conceptual (en llano) — qué es mid-stance y por qué el cruce de carga

*Registrado a pedido de Juan.*

**1. Las dos fases del ciclo.** Cada pie alterna entre **apoyo** (está en el piso) y **balanceo** (está en el aire). El sistema ya detectaba los dos bordes del apoyo: **IC** (*initial contact*, el pie toca) y **TO** (*toe-off*, el pie despega).

```
IC ─────────────── APOYO ─────────────── TO ────── BALANCEO ────── IC
│                                        │                          │
el pie toca                        la punta despega            vuelve a tocar
```

**2. Qué es mid-stance.** Es el punto medio de ese apoyo: el instante en que **el peso del cuerpo pasa por encima del pie apoyado**. La otra pierna va cruzando por el aire y el sujeto está parado sobre un solo pie, con el centro de masa justo arriba. En términos de carga, es el momento en que **el peso termina de trasladarse del talón al antepié**.

```
IC ──── el talón carga ──── [MS] ──── el antepié carga ──── TO
        ↑                    ↑                      ↑
   apoyás el talón     el peso pasa arriba     empujás con la punta
```

**3. Por qué se detecta con los 2 FSR que ya hay.** Hay un sensor en el talón y otro en la punta. Al principio del apoyo el del talón lee alto y el de la punta bajo; al final es al revés. **En algún momento las dos curvas se cruzan** — y ese cruce es una marca limpia y robusta, sin sensores nuevos y sin depender de la IMU.

**4. Para qué sirve.** Hasta ahora las features de presión (bloque C: peak force, integral presión-tiempo, loading rate) se calculaban **sobre todo el apoyo, como un solo número**. Con mid-stance se pueden calcular **por mitades**: cuánto cargó en la primera mitad (aceptación del peso) contra la segunda (propulsión).

Y eso es específicamente relevante en marcha post-ACV. El problema típico del lado parético **no es que no apoye**, sino que **no logra transferir el peso al antepié**: apoya, se queda en el talón y despega sin empujar. Con un solo número por apoyo, esa firma **se promedia y se pierde**. Partida en dos, salta a la vista. Es el **déficit de push-off**, que la bibliografía del proyecto identifica como uno de los hallazgos más característicos del cuadro (Kang 2025 — paper #20; Sanghan et al. 2014; marco teórico §"déficit de propulsión").

**5. La honestidad terminológica.** En la literatura clásica (Perry), *mid-stance* es un evento **cinemático**: la tibia queda vertical sobre el pie apoyado. Lo que esta spec detecta es el **cruce de carga**, que en marcha sana cae cerca de ese instante pero en marcha hemipléjica **puede divergir** —y suele hacerlo tarde, o no ocurrir—. Se eligió la definición de carga porque (a) es la que el FSR entrega de forma robusta, (b) es el instante funcionalmente relevante para la propulsión, y (c) mantiene la arquitectura de detección de SPEC-01 (FSR primario + confirmación IMU, que es más preciso en el instante: RMSE ~14 ms contra ~50-61 ms del IMU solo). La confirmación por pie-plano del IMU ancla el evento al mid-stance cinemático cuando ambos coinciden, y **la divergencia entre ambos es informativa** — queda anotada como candidata de feature.

**6. El caso en que no hay cruce.** Si el paciente **nunca transfiere la carga**, las dos curvas no se cruzan nunca. En vez de tratarlo como una falla de detección, se emite MS en el máximo del cociente `F_ante/F_post` con baja confianza y **flag `no_crossover`** — *que es señal de anomalía, no error*. Es el mismo criterio que SPEC-01 ya aplicaba a IC/TO: en patología conviene no perder eventos.

**Referencia.** ADR-029 (propuesta original de MS), ADR-015 (IC/TO), ADR-023 (set activo 2-FSR), ADR-021 (catálogo y dependencias), ADR-038 → SPEC-01 / SPEC-02; Kang (2025, paper #20), Sanghan et al. (2014), Ma, Zheng & Lee (2018); marco teórico (fases del ciclo, líneas ~252-253; déficit de propulsión, línea ~35).

---

## ADR-039 — El maestro deja de duplicar las vistas: pasa a índice + overview
**Estado:** aceptada (2026-08-18) — **Decisión: `Arquitectura_Sistema_Marcha.md` conserva la foto completa del sistema pero deja de replicar el detalle de las cuatro vistas. Cada sección que duplicaba una vista queda en uno o dos párrafos + puntero, y el "Resumen de decisiones" (§15) se reemplaza por un puntero al índice de la bitácora.**

**Contexto.** El 21/07, al consolidar las vistas, se decidió que el maestro **mantuviera la vista general completa**, aceptando la duplicación como "coherente y buscada". La **auditoría de consistencia del 2026-08-18** midió el resultado de esa decisión: de los **14 conflictos** encontrados entre documentos, **9 vivían en el maestro**.

**Evidencia (lo que estaba mal, y por qué importa).**

| Sección | Decía | Debía decir |
|---|---|---|
| §8.4 | "41 features en 8 bloques" | 47 en A–I (ADR-029/038) |
| §8.5 | IC/TO "plantilla **o cintura** (CP-03)" | En la plantilla — CP-03 cerrada por ADR-015 |
| §9.2, §10.1, §12 | "clase E/W" | E/**H**/W — falta la clase H de ADR-013 |
| §10.1 | "sklearn/**PyTorch**" | TF/Keras — ADR-022 descartó PyTorch |
| §16 | "modelos pesados en **clase W (worker)**" | Clase **H (host)**; el worker nunca infiere en tiempo real |
| §16 | "**fallback a emparejado por IC**" ante fallo de sync | El IC no sincroniza ni compensa drift (ADR-004) |
| §3 | "ver §12, Riesgos" | §16 (§12 era el worker) |
| §9.1 | "profiling §16" | Backlog #11 |
| §13 | RLS genérico, "propuesta para revisión" | ADR-032: `patient_access`, `service_role`, CP-18 |
| §15 | Terminaba en ADR-028 | Faltaban **10 filas** (ADR-029 a 038) |
| §17 | "CP-01 a CP-12" | CP-01 a CP-21 |

Las **dos filas de §16** son el caso grave: no estaban desactualizadas, **contradecían invariantes decididos**. Un lector que confiara en ese cuadro de riesgos mandaría los modelos pesados al worker y usaría el IC como red de seguridad del reloj — las dos cosas que el proyecto decidió explícitamente **no** hacer.

**Análisis.** El mecanismo es idéntico al del DDL duplicado (ADR-037): dos copias, nada que las sincronice, y la que no se usa a diario se pudre. Pero acá con un agravante de escala — el DDL eran 150 líneas en un archivo; esto eran **diez secciones** que hay que recordar tocar en cada decisión. El flujo de trabajo de `CLAUDE.md` incluso lo pedía por escrito ("reflejá el cambio en el Resumen de decisiones"), y aun así **se saltó en las últimas diez decisiones seguidas**. Cuando una regla de proceso falla diez veces consecutivas, el problema no es la disciplina: es que la estructura pide algo que no se sostiene.

Y el caso de §15 es especialmente claro: **la bitácora ya tiene su propio índice** con tema, decisión y estado de cada ADR — la misma información, mantenida en el mismo archivo donde se escribe la decisión, y por lo tanto siempre al día.

**Opciones evaluadas.**
- **A — Índice + overview corto (elegida).** Cada sección duplicada queda en uno o dos párrafos que dan la foto y apuntan a la vista; se sacan tablas y detalle. §15 → puntero al índice de la bitácora. §16 (Riesgos) y §17 (Cuestiones) se conservan y se corrigen: son **transversales**, no duplican ninguna vista. *Pros:* una sola fuente por tema; el maestro sigue sirviendo para entender el sistema de punta a punta en una lectura; las decisiones futuras se escriben en un solo lugar. *Contra:* deja de ser autocontenido para el detalle — hay que abrir la vista.
- **B — Completar y mantener las dos copias.** *Pros:* lectura autocontenida completa; era la decisión del 21/07. *Contra:* el registro empírico muestra que no se sostiene — diez decisiones seguidas sin propagar; y el costo se paga en cada ADR nuevo, para siempre.
- **C — Arreglar sólo los nueve conflictos puntuales.** *Pros:* lo más rápido hoy. *Contra:* no toca la causa; vuelve a pasar en la próxima tanda.

**Decisión.** Opción A. Estructura resultante (§0 a §16): §1–§2 alcance y resumen (transversales) · §3–§13 **overview + puntero** por dominio · §11 mapa de entidades de la base (apunta a `schema.sql`, ADR-037) · **§14 Decisiones = puntero al índice de la bitácora** · §15 Riesgos · §16 Cuestiones abiertas. El documento pasa de **579 a ~300 líneas**. Se agrega en §0 la regla de desempate: **si una sección del maestro y una vista discrepan, manda la vista**.

**Justificación.** Es la misma regla que el proyecto ya aplica a las features ("se define una vez en la Vista 3, se ejecuta en la Vista 2 y el worker") y al esquema de la base (ADR-037). El maestro recupera el rol que su propio §0 le asignaba desde el principio —**índice y overview**— en vez de ser una segunda copia de todo. La duplicación no se elimina por prolijidad: se elimina porque **generó nueve incoherencias en un mes**, dos de ellas capaces de inducir a construir lo contrario de lo decidido.

**Consecuencias.** El maestro pierde ~155 líneas. Se corrigen de paso los nueve conflictos (los que sobrevivían en secciones que ahora se reescriben desaparecen solos; §15/§16 —hoy Riesgos y Cuestiones— se corrigieron explícitamente). **Cambia la numeración de secciones**, así que se actualizaron las referencias cruzadas de las cuatro vistas. El paso 2 del flujo de trabajo de `CLAUDE.md` —"reflejá el cambio en el Resumen de decisiones del maestro"— **queda sin objeto**: escribir el ADR en la bitácora (con su fila de índice) es ahora suficiente. Las cuestiones abiertas se listan en §16 como **instantánea con fecha**, no como registro paralelo.

**Referencia.** ADR-037 (fuente única del esquema, mismo criterio), ADR-000/§0 (rol del maestro), ADR-004, ADR-011 rev, ADR-013, ADR-015, ADR-022, ADR-029, ADR-032, ADR-038; auditoría de consistencia 2026-08-18; `CLAUDE.md` (flujo de trabajo).

---

## ADR-040 — Bloque I (tronco): definido y ubicado, pero diferido en el set activo
**Estado:** aceptada (2026-08-18) — **Decisión: las tres features de tronco se renumeran a #45/#46/#47, se ubican formalmente como cómputo de la cintura en la Vista 2, y quedan definidas y disponibles pero OFF en el set activo. Se prenden cambiando el `feature_set_version`, sin tocar código. SPEC-10 deja las recomendaciones de implementación para cuando se prendan.**

**Contexto.** La auditoría de consistencia del 2026-08-18 encontró que el **bloque I no existía en la Vista 2**: la Vista 3 define tres features de tronco que corren en la cintura (I1 Improved Harmonic Ratio ML, I2 RMS de aceleración de tronco, I3 LDLJ de tronco), pero la vista de firmware no las menciona ni una vez —el core 1 de la cintura tenía asignado "inferencia + fusión bilateral + IMU + decisión"— y no había SPEC para ninguna. Era una ruptura de la regla de layering: algo definido en V3 que nadie ejecuta en V2.

El peso del hueco: según **ADR-030**, el bloque I es la **justificación principal de que la cintura exista como nodo**. El marco teórico daba por perdidas las features de tronco de Brasiliano porque el diseño original era solo-plantilla, y hasta planeaba *"aproximar la simetría desde el pie"*; el IMU de cintura a ~L4-L5 las mide directo. El **IHR ML es la feature top-1** del set de tres que llega a 90,2 % de accuracy en clustering no supervisado.

**Principio que apareció en la discusión (aporte de Juan).** *"Quizá no todos los features los vaya a usar desde el día uno. Lo dejamos disponible para más adelante si es necesario."* Esto no es una excepción para el bloque I: es la **lectura correcta de qué es el catálogo**. El catálogo es una **biblioteca de features disponibles**, no una lista de obligaciones; el **set activo** es lo que efectivamente se calcula. Esa separación ya existía como mecanismo (**ADR-021**) y ya se había usado dos veces (bloque E y #18 apagados por hardware — ADR-023; #42 diferida — ADR-029). Lo nuevo acá es que se apaga algo **por decisión de alcance**, no por falta de hardware — y el mecanismo lo soporta igual.

**Opciones evaluadas.**
- **A — SPEC completa y feature activa desde el día uno.** *Pros:* la feature más discriminativa disponible desde la primera captura. *Contra:* obliga a fijar ahora tres decisiones metodológicas (N de armónicos, método de remuestreo, tratamiento de la velocidad) que se resuelven mucho mejor mirando espectros reales; y suma carga de firmware antes de saber si hace falta.
- **B — Definido, ubicado y diferido, con SPEC de recomendaciones (elegida).** *Pros:* cierra la ruptura de layering **hoy** (la cintura tiene el rol asignado y las features tienen número); deja escrito todo lo aprendido para que prender la feature más adelante sea leer una spec y cambiar el `feature_set_version`, no volver a investigar; no compromete decisiones metodológicas sin datos. *Contra:* la feature top-1 de la evidencia no entra en los primeros modelos.
- **C — Marcarlas exploratorias y no tocar la Vista 2.** *Pros:* cero trabajo. *Contra:* deja la ruptura de layering abierta y el nodo cintura sin justificación ejecutada en ninguna vista — que es exactamente el hallazgo de la auditoría.

**Decisión.**
1. **Renumeración:** `I1 → #45` (IHR ML), `I2 → #46` (RMS de tronco), `I3 → #47` (LDLJ de tronco). El catálogo queda con numeración uniforme #1–#47, condición para el archivo declarativo de ADR-021.
2. **Ubicación (Vista 2):** el cómputo de las features de tronco se asigna explícitamente al **core 1 de la cintura**, junto con la fusión bilateral. La cintura ya tiene todo lo que hace falta: su propio IMU y los eventos IC de ambas plantillas sobre el timeline común (ADR-004).
3. **Set activo:** el **bloque I completo queda OFF**, igual que el bloque E. Se prende con un `feature_set_version` nuevo, sin reescritura.
4. **SPEC-10** recoge las recomendaciones de implementación —incluido lo que hay que verificar contra la fuente antes de codificar— para que prender el bloque no exija rehacer la investigación.

**Justificación.** La feature es valiosa y barata de computar (una FFT por zancada, <0,5 % de duty según SPEC-07), pero **no es barata de definir bien**: depende de tres elecciones metodológicas cuyo efecto sólo se ve con datos de un paciente real, y de una dependencia dura con la calidad de la detección de IC (ver apéndice). Diferirla no pierde nada mientras quede **escrita**; activarla más tarde cuesta un cambio de config. Lo que sí se cierra ahora es el hueco estructural: que el nodo cintura tenga en la Vista 2 el rol que la Vista 3 le atribuye.

**Consecuencias.** Cambian Vista 2 (§3 y §9), Vista 3 (Parte A del satélite: renumeración y set activo; §1 de la vista), y se agrega **SPEC-10**. El **catálogo sigue en 47** features nominales; el **set activo 2-FSR** ahora excluye bloque E (#22-25, #42), #18 **y bloque I (#45-47)**. Cierra el hueco B1 de la auditoría. **No agrega carga de firmware** en la primera iteración.

---

### Apéndice conceptual (en llano) — armónicos, IHR y por qué la separación no depende del paciente

*Registrado a pedido de Juan, que preguntó cómo se separan los armónicos intrínsecos de los extrínsecos y si eso varía de paciente a paciente.*

> **Desarrollo matemático completo → `docs/investigacion/fundamento_dft_ihr.md`.** Este apéndice da la intuición; ese documento da la formulación de la DFT, la demostración de la ortogonalidad, el teorema de simetría de media onda que fundamenta la separación par/impar, el análisis del leakage, y las consecuencias prácticas para el firmware. **Figura de apoyo:** `docs/investigacion/ihr_armonicos_explicacion.html`.

**1. Qué es un armónico.** Cualquier señal que se repite con período **T** puede escribirse como suma de ondas cuyas frecuencias son múltiplos enteros de **f₀ = 1/T**. Esos múltiplos son los armónicos. Dicho de la forma más útil acá: **el armónico N es una onda que entra exactamente N veces en el período**. El armónico 1 hace un ciclo; el 2, dos ciclos; el 3, tres.

**2. Cómo se sabe cuál es el fundamental — no se busca en el espectro, se impone con la ventana.** Esta es la pregunta clave y tiene una respuesta que simplifica todo el problema.

El camino ingenuo sería hacer una FFT de un tramo largo de marcha, buscar el pico más alto y llamarlo "frecuencia de zancada". Es frágil: en marcha hemipléjica la cadencia varía mucho, el pico se ensancha, y es fácil confundir la frecuencia de **paso** (2f₀) con la de **zancada** (f₀) — que es justamente la distinción de la que depende todo el método.

No hace falta, porque **el sistema ya sabe dónde empieza y termina cada zancada**: las plantillas envían los eventos **IC** y la cintura los tiene sobre el timeline común (ADR-004). Entonces:

1. Se corta el segmento de aceleración de tronco entre `IC(n)` e `IC(n+1)`. Ese segmento **es** una zancada, por definición del evento.
2. Se **remuestrea** a un número fijo de muestras (p. ej. 256), porque cada zancada dura distinto.
3. Se le hace la FFT a ese segmento.

**Por qué el bin *k* resulta ser el armónico *k*.** La FFT **no mide Hz**. Sus funciones base son `e^(−j2πkn/N)` con `n = 0…N−1`: cuando `n` recorre la ventana entera, la fase va de 0 a ≈2πk, o sea que **el bin `k` es la onda que completa exactamente `k` ciclos dentro de la ventana**. La unidad nativa de la FFT es *ciclos por ventana*, no ciclos por segundo. Los Hz aparecen después, dividiendo: `f_k = k / T_ventana`.

De ahí sale todo:

- Si la **ventana es una zancada**, entonces *ciclos por ventana* = *ciclos por zancada*. Y "k ciclos por zancada" es, literalmente, la definición del armónico k de la zancada. **Bin k = armónico k** es una tautología una vez que la ventana se eligió bien.
- Y el índice del bin queda **independiente de la frecuencia absoluta**. Zancada de 1,2 s → bin 1 = 0,833 Hz. El mismo paciente más rápido, zancada de 1,0 s → bin 1 = 1,0 Hz. Distintos Hz, **mismo bin**, porque en ambos casos es "un ciclo por zancada". El remuestreo a largo fijo es, en el fondo, un **cambio de variable de tiempo a porcentaje del ciclo de marcha**.

**Por qué la ventana tiene que cerrar.** La FFT asume implícitamente que la señal se repite indefinidamente con período igual a la ventana: construye la señal como suma de ondas que **cierran exactamente en los bordes**. Una onda con un número no entero de ciclos no cerraría — habría un salto en la costura. Por eso los únicos "ladrillos" disponibles son los que entran un número entero de veces.

> **Consecuencia de diseño (importante).** El IHR depende **críticamente** de la detección de IC. Si un IC llega mal, la zancada se corta mal, la ventana deja de ser un período exacto y el fundamental cae **entre** bins: como no existe un bin para "1,4 ciclos por ventana", la FFT lo arma sumando muchos bins vecinos y la energía se desparrama (*spectral leakage*) — **cayendo sobre los armónicos equivocados, que es exactamente lo que el IHR interpreta como asimetría**. Se lee asimetría donde no la hay. Por eso SPEC-10 exige descartar o marcar las zancadas cuyo IC vino con baja confianza (SPEC-01). Es una dependencia dura, no cosmética. Por la misma razón se **remuestrea** en vez de rellenar con ceros: el zero-padding alarga la ventana sin alargar el período de la señal, así que rompe la propiedad "una ventana = un período".

**3. Por qué pares e impares, y por qué la asignación no depende del paciente.** Una zancada contiene **dos pasos**, uno con cada pierna. La pregunta que ordena todo es: *¿qué hace cada armónico en la segunda mitad de la zancada, comparado con la primera?*

- Un armónico **par** entra un número entero de veces en **media** zancada. Cuando arranca la segunda mitad, arranca igual que la primera → **repite**.
- Un armónico **impar** deja medio ciclo colgando. Cuando arranca la segunda mitad, viene **dado vuelta** (cambiado de signo).

Formalmente: el armónico *n* evaluado en `t + T/2` queda desfasado en `πn`. Si *n* es par, el desfasaje es múltiplo de 2π → mismo valor. Si es impar, es múltiplo impar de π → signo opuesto.

Ahora, qué hace el tronco en una marcha **perfectamente simétrica**:

| Eje | Movimiento | En la 2ª mitad de la zancada… | Armónicos que hacen eso | **Intrínsecos** | **Extrínsecos** |
|---|---|---|---|---|---|
| Vertical | subís y bajás **una vez por paso** | **repite** la 1ª | pares | **pares** | impares |
| Antero-posterior | frenás y acelerás **una vez por paso** | **repite** la 1ª | pares | **pares** | impares |
| **Medio-lateral** | te inclinás a un lado y después al otro: **una vez por zancada** | es el **espejo** de la 1ª | impares | **impares** | pares |

**"Intrínseco" = el grupo que le corresponde a ese eje** si la marcha fuera perfectamente simétrica. **"Extrínseco" = el otro.** No es una propiedad de los números pares o impares en abstracto: es cuál grupo corresponde según lo que ese eje hace al caminar. Por eso en ML es al revés que en vertical y AP — y por eso hay que decir siempre *respecto de qué eje*.

**La respuesta a la pregunta de Juan:** la asignación **no se detecta y no depende del paciente**. Es una consecuencia matemática de que una zancada tiene dos pasos, igual para todo el mundo — sano, hemipléjico, alto, bajo. Es como medir cuán afinado está un instrumento: no se decide cuáles son los armónicos de un La según el instrumento (son 440, 880, 1320 Hz); lo que se mide es cuánto se desvía cada instrumento de esa serie. Acá igual: la serie está fija, y lo que varía de paciente a paciente es **cuánta energía se fuga a donde no debería**. **Esa fuga es la medición.**

**4. Por qué el eje ML y no el vertical.** Brasiliano encuentra el **IHR ML** como top-1, no el vertical. La razón se ve en la tabla: en ML la zancada completa —y no el paso— es el ritmo fundamental, así que una diferencia entre las dos piernas aparece de forma **directa** en vez de quedar enmascarada dentro de un patrón que ya se repite dos veces. Sumado a que el tronco a ~L4-L5 está cerca del centro de masa, el IHR ML **integra la asimetría de todo el cuerpo en un solo número, con un solo sensor**.

**5. Qué sí depende de decisiones (y son las que difiere esta ADR).**
- **Cuántos armónicos se suman (N).** La suma no llega a infinito: se corta en el armónico N (la literatura suele usar 10 o 20). Cambiar N cambia el valor. Se fija **una vez para todos los pacientes**, así que no rompe la comparabilidad interna — pero hay que documentarlo, porque un IHR con N=10 no es comparable con uno de otro trabajo que usó N=20.
- **El método de remuestreo.** Cada zancada dura distinto (1,20 s / 1,35 s / 1,18 s → 120 / 135 / 118 muestras a 100 Hz). Hay que llevarlas a un largo fijo. Y acá está el motivo real para querer datos antes: en marcha hemipléjica la duración de zancada **varía mucho más** que en marcha sana — tanto que el **CoV de stance es una de las tres features top de Brasiliano**, o sea que la variabilidad por sí sola discrimina. Con esa variabilidad, el remuestreo puede introducir artefactos que no aparecen en sujetos sanos.
- **La velocidad de marcha como confusor.** El HR cae con la velocidad incluso en gente sana. Si el paciente camina más lento un día, el IHR baja por un motivo que **no** es un empeoramiento del patrón. Como `stride speed` (#7) ya está en el catálogo, se puede condicionar.

**6. Por qué la personalización amortigua casi todo eso.** El sistema es **one-class personalizado** (ADR-000, ADR-011): no necesita un "IHR normal" absoluto contra el cual comparar. Mide la distribución del IHR **de ese paciente** en su calibración y detecta desvíos de **su propio** baseline. Todo lo que sea constante para ese paciente —cómo le queda el cinturón, su altura, el N elegido, incluso un sesgo del método de remuestreo— se absorbe en el baseline y desaparece. Lo único que **no** se absorbe es lo que varía dentro del mismo paciente: la velocidad (punto 5).

**7. Lo que hay que verificar contra la fuente antes de implementar.** La fórmula que registra el marco teórico —`IHR_n = Σ P_i^I / Σ (P_i^I + P_i^E)`— es la forma **normalizada y acotada** entre 0 y 1; el HR clásico es un cociente par/impar sin acotar, que se porta mal numéricamente (puede irse a infinito cuando el denominador tiende a cero). La lógica par/impar de este apéndice es la base estándar del harmonic ratio, pero **qué armónicos entran exactamente en cada conjunto en la variante *Improved* debe leerse de Brasiliano et al. (2026) y citarse**, no asumirse.

**Referencia.** ADR-021 (catálogo declarativo y set activo — el mecanismo que permite diferir), ADR-023 (precedente: apagar features por hardware), ADR-029 (bloque I y precedente de #42 diferida), ADR-030 (el bloque I como justificación de la cintura), ADR-004 (timeline común que provee los IC), ADR-019/SPEC-07 (CMSIS-DSP y costo de la FFT), SPEC-01 (confianza del IC), SPEC-10 (recomendaciones); Brasiliano et al. (2026) *Sci Rep* 16:8908; marco teórico §5.2 y §"Symmetry features"; `docs/investigacion/ihr_armonicos_explicacion.html`.

---

## ADR-041 — Alcance de FSR: hasta 4 en la placa nueva (con mux); 2 en la mínima
**Estado:** aceptada (2026-08-19) — **Decisión: el diseño contempla un máximo de 4 FSR por plantilla. La placa actual sigue con 2 (punta + talón). El 3º y 4º (medial y lateral) entran en la próxima revisión del PCB, lo que obliga a un mux analógico. El formato de paquete se fija en 4 slots desde ya.**

**Contexto.** **CP-08** preguntaba cuántos FSR soportar y dónde estaba el límite. El checklist de la próxima revisión del PCB (`esquema_alimentacion.md` §7, ítem 2) lo marcaba como *"decidir ahora"*, porque cambia el ruteo de la placa. Y la **auditoría de consistencia del 2026-08-18** encontró el síntoma documental: el formato de paquete de la Vista 1 estaba fijo en `fsr1 fsr2 fsr3` mientras el texto contiguo prometía "reserva slots para **N** FSR", y los diagramas mermaid decían `IMU+3FSR` cuando el hardware real tiene 2.

**El límite duro.** El Pico 2 W expone cuatro entradas ADC: **GP26 (ADC0), GP27 (ADC1), GP28 (ADC2)** y **GP29 (ADC3)**. GP29 está cableada en la placa a la medición de **VSYS**, o sea la tensión de la celda. Quedan por lo tanto **3 canales libres**.

Hoy se usan dos: **punta (ADC0)** y **talón (ADC1)** — ambos sobre el eje antero-posterior. Queda uno.

**Por qué 3 FSR no alcanzan para lo que se quiere medir.** El bloque E (COP_ML, SPEC-06) necesita separación en el eje **medial-lateral**, y punta y talón están los dos sobre la línea media. Con un tercer sensor lateral se obtienen dos coordenadas M/L distintas y un COP_ML **crudo pero calculable**. Con **medial y lateral** se obtiene el COP_ML que efectivamente usa la literatura, y además se habilita la **#18 (ratio medial/lateral de peak force)**, que es una feature de asimetría intra-pie ligada a la **inversión del pie parético** (Ma, Zheng & Lee 2018) — uno de los hallazgos característicos del cuadro.

**Opciones evaluadas.**
- **A — Hasta 4 FSR, con mux analógico (elegida).** *Pros:* COP_ML propio + #18 habilitada; cubre el bloque E completo. *Contra:* exige un componente nuevo en la placa (mux o ADC externo) y un tiempo de establecimiento por conmutación que la secuencia de adquisición tiene que respetar.
- **B — 3 FSR, sin componentes nuevos.** *Pros:* entra en los ADC libres sin tocar nada; COP_ML crudo suficiente para *evaluar* si el bloque E aporta. *Contra:* deja #18 apagada de forma permanente y el COP_ML queda con una geometría pobre — se arriesga a descartar el bloque E por una medición mala, no porque la feature no sirva.
- **C — 4 FSR sacrificando GP29/VSYS.** *Pros:* cuatro canales sin mux. *Contra:* se pierde la medición de batería — y **ADR-035 rev** justamente elevó la importancia del **corte por baja tensión en firmware** (sin gestión de energía, un equipo encendido consume hasta agotar la celda). Cambiar un problema de seguridad por uno de ruteo es mal negocio. **Descartada.**
- **D — Formato de paquete con N variable** (campo de conteo + array). *Pros:* no compromete el máximo. *Contra:* complica el parsing en la cintura y en el worker para resolver algo que ya se puede decidir; el ahorro de banda es despreciable (ver abajo).

**Decisión.**
1. **Máximo de diseño: 4 FSR por plantilla.** Set activo actual: **2** (punta ADC0/GP26, talón ADC1/GP27) — sin cambios, **ADR-023 sigue vigente**.
2. **Próxima revisión del PCB:** se suman **medial y lateral**. Uno va a **ADC2/GP28**; el cuarto exige **mux analógico** (o ADC externo). Deja de ser una opción a evaluar: es **requisito firme** de esa revisión.
3. **Formato de paquete: 4 slots fijos** de FSR (`fsr1..fsr4`, uint16), con los no poblados en cero. El **set activo del catálogo** (ADR-021) dice cuáles son válidos; el protocolo no cambia al sumar hardware. **Costo:** 4 bytes extra por muestra a 100 Hz = **400 B/s por pie**, frente a un caudal total de ~5 KB/s. Despreciable, y evita versionar el protocolo a mitad de camino.
4. **Cierra CP-08** en cuanto al **cuántos y dónde está el límite**. La validación del *timing* de la adquisición multiplexada (tiempo de establecimiento del mux dentro del presupuesto de ADR-014: sobremuestreo ~1 kHz + decimación ×10) queda para el **backlog #11**, sobre firmware y placa reales.

**Justificación.** La razón de fondo para no quedarse en 3 es de método: con una geometría de sensores pobre, un resultado negativo del bloque E sería **ambiguo** —no se sabría si la feature no sirve o si la medición era mala— y ese es el peor tipo de resultado para una tesis. El costo de la decisión es un componente y algo de ruteo, en una placa que **hay que rediseñar igual** por el cargador de corriente limitada (prioridad de seguridad, CP-09) y el alojamiento de la celda. Fijar el paquete en 4 slots ahora cuesta 400 B/s y ahorra una migración de protocolo con hardware ya sellado — y conviene recordar que **al sellar la plantilla se pierde el BOOTSEL**, así que los cambios posteriores dependen del OTA.

**Consecuencias.** **CP-08 → Resuelta.** Cambian: Vista 1 §1 (mermaid a 2 FSR reales) y §4 (formato de paquete a 4 slots), maestro §3 y §4 (ídem), `esquema_alimentacion.md` §7 ítem 2 (de "decidir si" a "sumar mux"), CP-01 (nota del pinout). **No cambia el set activo:** las features de fuerza medial-lateral (bloque E #22-25, #42 y #18) siguen **OFF** hasta que exista el hardware — ADR-023 y ADR-040 sin cambios. El **firmware de adquisición** tendrá que secuenciar el mux; se especifica cuando se escriba, con el ADR-014 como marco.

**Referencia.** CP-08, CP-01, CP-09; ADR-023 (set activo 2-FSR), ADR-014 (adquisición determinística), ADR-035 rev (corte por baja tensión → GP29 ocupado), ADR-021 (set activo y modularidad), ADR-040 (features apagadas por alcance vs por hardware), SPEC-06 (COP_ML), ADR-029 (#42); `esquema_alimentacion.md` §7; Ma, Zheng & Lee (2018) sobre inversión del pie parético.

---

## ADR-042 — Definición de "crudo" y frontera del procesamiento del IMU
**Estado:** aceptada (2026-08-22) — **Decisión: el "crudo" que se transmite y persiste es la salida del módulo IMU *después* del AHRS — aceleración lineal sin gravedad + velocidad angular calibrada + orientación (pitch/roll/yaw) — más los FSR. El micro corre la cadena completa; el worker consume y no re-procesa IMU.**

**Contexto.** La palabra **"crudo"** se usa en ADR-005 rev c (fase exploratoria = "crudo-solo"), ADR-008 (retención tiered), Vista 4 §1.4 y el diagrama `ciclo_de_vida_modelos.mermaid`, y **no está definida en ninguno de ellos**. La ambigüedad quedó expuesta en la revisión del 2026-08-22.

SPEC-04 define el módulo IMU como una cadena de cuatro pasos — `driver I²C → calibración → Fusion AHRS (Madgwick) → gravity removal` — y afirma que el worker usa `imufusion` *"para re-extraer features del IMU desde el crudo off-device… ahí debe reproducir exactamente lo que hace Fusion (C) en el micro"*. Esa frase **sólo tiene sentido si el crudo almacenado es anterior al AHRS**, una frontera que nunca se declaró. El formato de paquete de la Vista 1 §4 (`ax ay az gx gy gz`) es coherente con esa lectura: transporta los 6 canales del sensor y ninguna orientación.

**Dato técnico decisivo.** La gravedad **no se puede remover con un offset fijo tomado al inicio**. El acelerómetro mide la gravedad repartida entre sus tres ejes según la orientación del sensor; en la marcha el pie rota decenas de grados por paso, así que un vector restado una sola vez deja un residuo de hasta varios g — del mismo orden que las aceleraciones reales del pie, que quedan tapadas. Remover la gravedad exige conocer la orientación **en cada muestra**, que es lo que calcula Madgwick (paso 3). De ahí se sigue la simetría del problema: **una vez removida la gravedad, la orientación no se puede reconstruir desde el dato guardado**, porque integrar el giro solo derivaría sin la referencia gravitatoria que corregía ese drift. La elección de frontera determina, entonces, qué tiene que viajar en el paquete.

**Opciones evaluadas.**
- **A — Crudo pre-AHRS (salida del paso 2): accel + giro calibrados, con gravedad.** *Pros:* el AHRS y su parámetro `β` quedan **revisables sobre los datos ya capturados** — se podría comparar Madgwick contra Mahony o EKF (las tres alternativas que ADR-017 evaluó) sin recapturar; paquete más chico (29 B). *Contra:* el worker debe correr Madgwick y **coincidir con el micro sobre un filtro con estado e historia**, no sobre una fórmula cerrada — una superficie de paridad (ADR-018) mucho más frágil que la de una feature; y obliga a declarar dónde empieza el worker, o se aplica la calibración dos veces.
- **B — Crudo post-AHRS (elegida): `lin_accel` + giro + orientación.** *Pros:* el worker **consume y calcula features**, sin re-procesar IMU ni arrastrar el estado del filtro; desaparece toda la clase de errores por doble aplicación; la paridad de ADR-018 se acota a las features, que es donde importa. *Contra:* **congela Madgwick y su `β`** para los datos ya capturados — cambiar de filtro exige recapturar; +6 B por muestra.
- **C — Ambos (pre-AHRS + orientación).** *Pros:* reversibilidad total. *Contra:* 41 B por muestra y dato redundante, para una reversibilidad que no está en el alcance actual. **Descartada.**

**Decisión.**
1. **Definición canónica de crudo:** `[lin_accel XYZ | ω XYZ calibrada | pitch roll yaw | FSR ×4]` a **100 Hz**, con la calibración y el AHRS ya aplicados en el micro y **ningún otro procesamiento**. Ésta es la definición que rige en ADR-005 rev c, ADR-008 y Vista 4 §1.4.
2. **El AHRS corre en el micro.** El worker consume el crudo y **no re-procesa IMU**. `imufusion` deja de ser necesario para re-extraer features del IMU; la cláusula condicional de SPEC-04 se acota en consecuencia.
3. **Formato de paquete:** se suman `pitch roll yaw` como 3× int16. **29 → 35 B por muestra**, ~**7 KB/s** entre las dos plantillas (contra ~5,8 actuales). Mismo orden de costo que los 4 slots de FSR de ADR-041, absorbible por BLE.
4. **SPEC-03 se corrige:** su paso 2 (*"quitar gravedad: restar `g` en el frame global"*) **se elimina**; el paso 1 (rotar al frame global con la orientación) se mantiene.
5. **La calibración es irreversible por diseño.** No se persisten parámetros de calibración: no habría cómo re-aplicarlos y guardarlos sólo crearía la tentación de hacerlo.
6. **`t_device` pasa a `uint64` (µs) — cierra CP-27.** En `uint32` el contador da la vuelta a los **71,6 min**, y ADR-035 deja el equipo despierto ~10 h (~8 vueltas por encendido): eso desordena el emparejado entre pies y rompe la regresión de drift de ADR-004. Con 8 B no da la vuelta en 584.000 años; el `seq` sigue en `uint32` (497 días a 100 Hz). Son +4 B por muestra: sumados al punto 3, el paquete pasa de **29 a 39 B** (~**7,8 KB/s** entre las dos plantillas). *(Punto agregado el 2026-10-11: se decidió en la misma revisión del 2026-08-22 y quedó en Vista 1 §4 y en el changelog, pero no se había escrito acá.)*

**Justificación.** La fase exploratoria calcula features off-device, así que el crudo tiene que alcanzar para **todo el catálogo**: el bloque F depende de la orientación (#26-29), el G de `lin_accel` y `ω` (#32-34), el H de ventanas de ambos (#35-38, #41) y SPEC-03 de las dos cosas. Con los 9 canales, todo se computa **igual en la plantilla y en el worker**, que es la propiedad que se buscaba.

Entre A y B el intercambio es *reversibilidad del filtro* contra *simplicidad y robustez de la paridad*. Se elige B porque la paridad train/serve (ADR-018) es un invariante del proyecto y la clase de error que evita es silenciosa: un worker que aplica una corrección ya aplicada no falla, produce números plausibles y distintos. La contrapartida —recapturar si se cambia el filtro— es un costo acotado y visible, y ADR-017 ya eligió Madgwick con argumento.

**Consecuencias.** El **riesgo aceptado** queda explícito: si el análisis de los primeros datos de marcha hemipléjica indica que `β` está mal calibrado para el caso, **los datos ya capturados no se pueden reprocesar con otro filtro**. Mitigación: fijar `β` con una captura piloto corta antes de la captura formal.

Cambian: **Vista 1 §1** (canales por pie: 8 → 11) y **§4** (formato de paquete), **SPEC-03** (elimina el paso 2), **SPEC-04** (frontera del worker; `imufusion` ya no re-extrae features de IMU), **Vista 4 §1.4** y **ADR-005 rev c** (qué significa "crudo"), maestro §3-§4. **No cambia** el set activo ni el catálogo.

**Nota de implementación.** SPEC-03 tal como está escrita hoy resta `g` sobre un dato al que ya se le quitó, dejando un sesgo constante de −9,81 m/s² que se **integra dos veces**: sobre una zancada de ~1 s son ~4,9 m de desplazamiento espurio contra un `stride_length` real de ~1 m. El error es cinco veces la señal e inutiliza #6 y #7 (stride length y speed), dos features del top-3 de Brasiliano. La corrección del punto 4 no es cosmética.

**Referencia.** SPEC-04 (módulo IMU), SPEC-03 (ZUPT/stride length), ADR-017 (orientación y calibración), ADR-016 (stride length), ADR-005 rev c (fases de captura), ADR-008 (retención), ADR-018 (paridad), ADR-041 (precedente de costo de paquete), Vista 1 §4, Vista 3 (catálogo, bloques F/G/H).

**Apéndice conceptual — por qué la gravedad no se saca una sola vez.** El acelerómetro no mide "aceleración del pie": mide **fuerza específica**, que incluye la gravedad. Quieto y plano, lee ~9,81 m/s² repartidos entre sus ejes según cómo esté montado el sensor. Si el pie rota 30°, ese mismo 9,81 se reparte distinto: restar el vector medido al inicio deja un residuo que puede llegar a varios g. Como las aceleraciones reales del pie en marcha son de ese mismo orden, el residuo no es una corrección menor — es del tamaño de la señal.

Por eso el AHRS es indispensable: estima la orientación instantánea combinando el giróscopo (rápido y preciso a corto plazo, pero derivante) con el acelerómetro (ruidoso pero con una referencia absoluta de vertical, la gravedad). Con esa orientación se sabe hacia dónde apunta el abajo en cada muestra y se resta la gravedad correctamente.

La consecuencia es el punto que decidió este ADR: **la operación no es invertible**. Guardado el dato sin gravedad, ya no queda la referencia de vertical que permitiría recalcular la orientación; el giróscopo solo, integrado, deriva sin nada que lo corrija. Por eso `pitch/roll/yaw` tienen que viajar en el paquete y no se pueden "recuperar después".

---

## ADR-043 — Ciclo de vida de la sesión: check-out/check-in del estado local, adaptación conmutable y gate de arranque
**Estado:** aceptada (2026-08-22, **rev. 2026-08-22** — pipeline completo, gate térmico y autoridad del modelo) — **Decisión: la sesión es una transacción explícita comandada por la interfaz. Al abrirla, si el paciente cambió, el micro sube su estado de clase L y el host lo versiona antes de bajar el modelo nuevo. La adaptación online es conmutable por sesión (`adaptation_enabled`). Ninguna sesión arranca sin pasar un gate que verifica la correspondencia modelo↔paciente.**

**Contexto.** Tres problemas convergentes, detectados en la revisión del 2026-08-22.

**(1) La clase L no tenía respaldo posible.** Vista 3 §2 declara que los modelos L *"se auto-actualizan"* y no usan OTA, y §6 que la clase L *"nunca toca el worker"*. Pero Vista 3 §6 y Vista 4 §6 afirman las dos que **todo** modelo se respalda en la DB y *"si un micro se rompe o se pierde, se recupera desde la DB"*. Es falso exactamente para la clase L: existe un camino de bajada (Vista 2 §8 lista *"Mahalanobis = μ + Σ⁻¹"* como artefacto OTA a un slot de flash) pero **ningún camino de subida**. Lo que hay en la base es el baseline inicial; el μ/Σ adaptado vive sólo en el micro.

**(2) La taxonomía tenía un eje de menos.** ADR-011 define las clases sobre *"dos ejes: dónde infiere × dónde/con qué granularidad reentrena"*. Falta un tercero: **dónde vive la copia autoritativa del estado**. Para E/H/W es invisible, porque el worker siempre tiene la copia buena y el OTA la re-empuja. **L es la única clase donde el micro es el único poseedor**, y es justo donde nadie se hizo la pregunta. La columna *"¿OTA? No"* refuerza la ilusión de lazo cerrado.

**(3) En la mínima, las plantillas rotan entre pacientes.** Un solo par para N pacientes del estudio es el caso normal, no la excepción. Sobre reasignación el repositorio tenía **una sola línea** —*"al reasignar la cintura a otro paciente hay que borrar bonds + datos"* (ADR-032, ADR-028, Vista 4 §2)— que es un requisito de privacidad **sin mecanismo**, y el factory-reset que lo implementaría está diferido a la máxima. De ahí salen tres fallas concretas:
- **El par A/B se contamina.** ADR-012 y SPEC-08 definen los dos slots para **rollback de versión**. Si el cambio de paciente usa el mismo OTA, tras cargar a B el slot *last-known-good* contiene el modelo de **A**: un rollback carga el baseline de otra persona.
- **Nada impide abrir una sesión con el modelo anterior cargado.** `sessions` tiene `patient_id` y `device_set`; `model_deployments` tiene `(model_id, device_id)`; **nada los ata**. Y `anomaly_scores` guarda `patient_id` y `model_id` sin restricción de que concuerden — la base acepta scores de B calculados contra el baseline de A, y el feedback dispararía con los umbrales de A (`feedback_config` es per-paciente y lo baja el host).
- **El ring buffer de crudo** de cada plantilla (Vista 2 §7) queda con marcha del paciente anterior, que es exactamente lo que "borrar datos al reasignar" pide.

**Requisito adicional (Juan, 2026-08-22).** La adaptación online **tiene que existir en la mínima**, pero debe poder **apagarse desde la interfaz**: hay que poder correr el modelo sin adaptación para comparar.

**Opciones evaluadas — dónde vive el estado de clase L.**
- **A — Check-out / check-in (elegida).** Abrir sesión es una transacción: el micro sube su estado adaptado → el host lo versiona en la DB → recién entonces baja el modelo del paciente nuevo y se limpian los buffers. *Pros:* la subida se vuelve **obligatoria por construcción**, no un backup opcional que se puede olvidar; resuelve persistencia, respaldo, cambio de paciente y borrado de datos con un solo mecanismo. *Contra:* exige conectividad al abrir sesión (en la mínima la laptop está presente por diseño — ADR-033) y que el micro reporte qué paciente tiene cargado.
- **B — Multi-slot: K modelos residentes en flash por paciente.** *Pros:* cambio instantáneo sin red, cómodo para rotar pacientes en una tarde; el estado es chico (~2,6 KB por paciente). *Contra:* choca de frente con el requisito de borrar datos al reasignar (ADR-032) y con CP-18; **no elimina la subida** —se pierde la adaptación igual al desalojar— y complica todavía más la semántica del par A/B. **Descartada.**
- **C — Estado autoritativo en el host; el micro tiene una copia de trabajo.** *Pros:* hace explícito el tercer eje y hay precedente (el host ya aloja un runtime espejo para clase H, ADR-011 rev). *Contra:* ata la clase L a la presencia continua del host; en la máxima el celular se aleja y hay que volver a estado en RAM + resincronización, o sea A por otro camino.
- **D — Sin adaptación online en la mínima** (L se comporta como E: congelada por sesión, reentrenada por el worker entre sesiones). *Pros:* elimina el problema entero de esta etapa. *Contra:* renuncia a la adaptación online como resultado de la mínima. **Descartada por requisito** (ver arriba), pero sobrevive como el caso `adaptation_enabled = false`.

**Decisión.**

**1 — La sesión es una transacción comandada por la interfaz**, con esta secuencia:

| # | Estado | Qué ocurre |
|---|---|---|
| 1 | `IDLE` | Equipo encendido, host conectado, sin sesión. El micro no scorea ni graba. |
| 2 | `PATIENT_SELECTED` | La app compara el paciente elegido contra el que la cintura **reporta** tener cargado. |
| 3 | `CHECK_OUT` *(condicional)* | Sólo si difieren: el micro sube su estado de clase L → el host lo versiona en la DB → se limpian los ring buffers de las dos plantillas. |
| 4 | `PROVISIONING` | El host baja: modelo del paciente nuevo (estampado), `feedback_config`, `feature_set_version` / set activo y `adaptation_enabled`. |
| 5 | `SENSOR_CALIBRATION` | Calibración estática del IMU (ADR-017 / SPEC-04). |
| 6 | `READY` **(gate)** | Verifica: el modelo cargado corresponde al paciente de la sesión, la calibración cerró, la sincronización está establecida y las dos plantillas están conectadas. **Sin este paso no se arranca.** |
| 7 | `RUNNING` | En el modo de ADR-005 rev c: `exploratory` / `operational` / `edge`. |
| 8 | `CHECK_IN` | Al cerrar: si hubo adaptación, el micro sube el estado final y el host lo versiona; se sella `ended_at`. |

Los pasos 3, 4, 6 y 8 no existían. El 5 existía como decisión (ADR-017) pero no como paso del flujo.

**2 — `adaptation_enabled` es un atributo de la sesión**, comandado por la interfaz como el modo (ADR-034: comando explícito, nunca inferido).
- `false` → la sesión corre **congelada** en la versión N; el check-in no produce versión nueva.
- `true` → arranca en N y produce **exactamente una** versión nueva al check-in, con `parent_version = N`.

El versionado por sesión da dos cosas: la **comparación pareada** con y sin adaptación —que es la evidencia de que la adaptación online aporta algo, una afirmación central del proyecto— y la **trayectoria del baseline** del paciente a lo largo del tratamiento, que es un resultado clínico, no un log.

**3 — Dos guardas contra el cruce de pacientes.**
- **Firmware:** todo artefacto de modelo en flash lleva `patient_id` + versión en su cabecera, y la cintura **se niega a scorear** si el paciente del modelo cargado no coincide con el de la sesión abierta. Resuelve la contaminación del par A/B y el arranque con modelo ajeno.
- **Base:** FK compuesta `anomaly_scores (model_id, patient_id) → models (id, patient_id)` — con `patient_id` nulo (modelos globales) el enforcement no aplica, que es el comportamiento correcto. Y `unique (patient_id, algo, version)` en `models`, hoy ausente y cada vez más necesario con una versión nueva por sesión.
  > **Precisión de ADR-046 (2026-10-17):** con `anomaly_scores.patient_id` obligatorio, esta FK se aplica siempre: un score persistido es siempre de un modelo **del mismo paciente**, y un modelo global no puede producirlos. Coherente con ADR-000 (personalización primero).

**4 — El check-out es también el borrado.** La limpieza de los ring buffers de crudo en el paso 3 le da mecanismo, en la mínima, al requisito de ADR-032 que hasta ahora sólo estaba enunciado.

**Justificación.** La opción A convierte el paso frágil —"acordate de subir el estado antes de cambiar de paciente"— en un paso **obligatorio de una transacción**: si no se ejecuta, la sesión no abre. Es la única de las cuatro que resuelve los tres problemas con un solo mecanismo, y lo hace apoyándose en algo que ya estaba decidido (ADR-033: la UI abre y cierra sesión; ADR-034: el modo es un comando explícito) en vez de inventar infraestructura.

El gate del paso 6 merece énfasis aparte: es lo que impide **grabar los datos de un paciente contra el baseline de otro** y disparar feedback con umbrales ajenos. En un dispositivo que va sobre pacientes, ése es el modo de falla más caro del sistema, y hoy nada lo impide.

**Consecuencias.** **Queda cerrada la contradicción del respaldo de clase L** — resuelta de fondo, no acotada: Vista 3 §6 y Vista 4 §6 dejan de mentir porque ahora existe el camino de subida.

Cambian: **Vista 4** (sección nueva con la definición canónica del ciclo de vida — es la vista dueña de la app y la UI; §4 pasa de párrafo a orquestador; §6 corrige el respaldo), **Vista 3 §6** (respaldo de clase L; y de paso la clase **H** que falta en *"clase E/W en el worker"*, incoherente con §2, §3 y Vista 4 §3), **Vista 1 §6** (la tabla de operaciones suma la adaptación), **Vista 2 §7 y §8** (limpieza de buffers en check-out; estampa de `patient_id` en el slot). **`src/db/schema.sql`:** `sessions.adaptation_enabled boolean`, la FK compuesta y el índice único. **SPEC-11** especifica la parte del firmware: qué expone el micro, cómo rechaza el scoring y cómo sube el estado.

**Lo que este ADR NO resuelve.** El check-in cubre el cambio de paciente, **no el apagado diario**. ADR-035 estableció que el switch físico es el encendido/apagado; si el estado adaptado vive sólo en RAM, se pierde en cada apagado y la adaptación de la clase L nunca acumula nada. Ninguna vista, ADR ni spec dice hoy dónde vive ese estado entre encendidos → **CP-24**. Tampoco resuelve el choque entre el warm-up de 2-3 min que pide ADR-017 y el flujo de inicio de sesión → **CP-25**.

**Referencia.** ADR-011 rev (taxonomía L/E/H/W), ADR-012 (OTA A/B), ADR-013 (ubicación de la inferencia), ADR-032 (RLS y borrado al reasignar), ADR-028 (pairing y factory-reset diferido), ADR-033 (UI de control), ADR-034 (el modo es comando explícito), ADR-035 (encendido/apagado), ADR-017 (calibración), ADR-005 rev c (fases de captura), SPEC-08 (runtime de inferencia), Vista 2 §7-§8, Vista 3 §2/§3/§6, Vista 4 §2/§3/§4/§6, `src/db/schema.sql`. Cuestiones abiertas derivadas: CP-24, CP-25.


### Revisión 2026-08-22 — pipeline de arranque, gate térmico y autoridad del modelo

La secuencia de 8 estados de arriba se detalla acá; el diagrama vive en `../arquitectura/pipeline_sesion.mermaid` y la definición canónica en la **Vista 4**.

**El warm-up del IMU corre en paralelo, no al final.** ADR-017 pide calibración estática "post warm-up"; la literatura de MEMS es más exigente que los 2-3 min de SPEC-04 (5-10 min en guías de calibración de fábrica, 10-15 min para que el offset del giro pase de frío a régimen, 1-30 min según modelo — CP-25). Ese reloj arranca **al encender el equipo**, no al abrir la sesión, así que conexión, selección de paciente y provisioning **se consumen del mismo tiempo**. La UI muestra la barra de estabilización desde que se conecta, y **sólo el botón de calibrar** queda bloqueado hasta que cierra.

**El gate es por temperatura, no por reloj.** El MPU-6050 tiene sensor de temperatura integrado: la cintura reporta la de los tres IMU y el gate se abre cuando **se estabilizó** (derivada por debajo de umbral), con temporizador fijo como respaldo. Sustituye un número heredado de la literatura por una medición del equipo real. Entre sesiones seguidas sin apagar, el gate no vuelve a cerrarse: la condición es "estable desde el último encendido", que trackea el micro.

**Fases del pipeline.**

| # | Fase | Qué ocurre | Duración |
|---|---|---|---|
| 0 | Encendido | Switch físico; plantillas → WiFi de la cintura; cintura → advertising BLE. **Arranca el reloj térmico.** | seg |
| 1 | Conexión | La cintura reporta plantillas asociadas, baterías, firmware, **paciente + versión de modelo en flash**, temperatura de los 3 IMU y uptime | seg |
| 2 | Configuración | Paciente, modo (`exploratory`/`operational`/`edge`) y `adaptation_enabled` | operador |
| 3 | Provisioning | Se baja de la DB la versión activa del modelo + `feedback_config` + set activo, y **se escribe a flash** (slot A/B, checksum, estampado con `patient_id` + versión). Si el paciente cambió, además se limpian los ring buffers de crudo de las dos plantillas | seg |
| 4 | Gate térmico | Espera el remanente, ya descontado lo consumido en 1-3 | resto |
| 5 | Calibración | Poses (postura → CP-31); bias de giro, offset de accel, alineación anatómica | decenas de seg |
| 6 | Verificación | Modelo en flash = paciente de la sesión · calibración OK · dos plantillas conectadas · sincronización dentro de presupuesto · batería suficiente. **Sin esto no arranca** | instantáneo |
| 7 | Sesión | Fila en `sessions`; grabación/scoring según el modo; adaptación en RAM si está habilitada | la sesión |
| 8 | Cierre | Se sella `ended_at`; si hubo adaptación el micro sube el estado final y el host lo versiona (N+1). **El flash no se toca** | seg |

**Autoridad del modelo: la DB manda.** Lo que se flashea es **siempre** la última versión de la base; no hay reconciliación. El flash es una **copia de trabajo descartable** y la DB es la única fuente de verdad del modelo — mismo criterio que ADR-037 para el esquema y ADR-039 para las decisiones.

*Costo aceptado:* si la subida del cierre falla, **esa sesión pierde su adaptación**; la siguiente flashea la versión anterior y sigue desde ahí. La pérdida está acotada a una sesión y no queda ambigüedad sobre cuál versión es la buena. El caso es angosto —la subida ocurre al cerrar, cuando el host está conectado por definición— y los escenarios reales (batería agotada, cuelgue) pierden la sesión de todos modos.

*Por qué se flashea igual, si siempre se vuelve a bajar:* para que **un reset a mitad de sesión** (watchdog, brownout) recargue el modelo sin depender del host y la sesión continúe. Es su única justificación, y conviene que esté escrita.

**Canal de estado, separado del stream.** El pipeline necesita datos que no son muestras:

| Canal | Rate | Contenido |
|---|---|---|
| **Stream** | 100 Hz | Las muestras (Vista 1 §4) |
| **Estado** | 1-2 s | Batería, **temperatura de los 3 IMU**, **uptime**, contadores de pérdida de paquetes (derivados del `seq`), error de sincronización estimado |
| **A demanda** | — | Paciente + versión de modelo en flash (al conectar, y **después de todo reset**) |

Temperatura y uptime siguen viajando **con la sesión corriendo**, por dos motivos: la temperatura se aleja del punto de calibración durante el uso (el pie calienta la plantilla) y es una **señal de calidad del dato** que permite explicar después una sesión anómala; y el uptime es cómo se detecta un reset silencioso. El paciente y la versión en flash, en cambio, **no** van en el stream: se piden al conectar y tras un reset.

Este canal es además el que alimenta el panel de monitoreo y el que provee la evidencia para validar la coexistencia WiFi-AP + BLE y la precisión de sincronización (CP-28) — hoy el sistema genera esos números y nadie los consume.

**Consecuencias adicionales de esta revisión.** **CP-24 → Resuelta.** El estado de clase L vive en RAM durante la sesión, se sube a la DB en el check-in y se re-flashea desde la DB en la siguiente: el apagado diario deja de perder aprendizaje sin necesidad de escrituras periódicas a flash. Se agregan: `pipeline_sesion.mermaid`, la sección de ciclo de vida y el canal de estado en la **Vista 4**, y el reporte de temperatura/uptime/versión en la **Vista 2**. **CP-25** queda actualizada con los valores de la literatura y el gate por temperatura; **CP-31** (postura de calibración) alimenta la fase 5.

---

## ADR-044 — Series temporales sin TimescaleDB: particionado nativo de Postgres + `pg_partman` (resuelve CP-26)
**Estado:** aceptada (2026-10-17) — **Decisión: las tablas de series dejan TimescaleDB y pasan a particionado declarativo nativo de Postgres —rango mensual sobre la fecha de inicio de la sesión—, con `pg_partman` creando las particiones por adelantado y `pg_cron` corriendo el mantenimiento diario. El proyecto de Supabase se crea en Postgres 17. Revisa la capa de series de ADR-007 y reemplaza el punto 3 de ADR-031.**

**Contexto.** ADR-007 eligió *Postgres + TimescaleDB + object storage*, y `schema.sql` creaba tres *hypertables* (`gait_events`, `feature_vectors`, `anomaly_scores`). Tres hechos, verificados el 2026-10-11 contra la documentación de Supabase y de Tiger Data (la empresa de Timescale), dejaron esa elección sin piso:

1. **Supabase deprecó la extensión.** En Postgres 17 no está; en Postgres 15 sigue andando, pero hay que borrarla antes de subir a 17. La ruta oficial que documenta Supabase es **particionado nativo administrado por `pg_partman`**, con una guía de migración: renombrar la hypertable, crear la tabla particionada, copiar los datos por tandas en una ventana de mantenimiento y recién ahí borrar la vieja.
2. **Supabase sólo trae la edición Apache 2 de Timescale**, y lo que es exclusivo de la edición Community no está disponible. Según la tabla de ediciones de Tiger Data, eso incluye **continuous aggregates, compresión (columnstore), políticas de retención y jobs programados**. O sea: la compresión que ADR-007 contaba como ventaja y los continuous aggregates del punto 3 de ADR-031 **nunca estuvieron disponibles** en esta plataforma. Lo único que Timescale nos daba era el **particionado por tiempo**, que Postgres hace de forma nativa desde la versión 10.
3. **Fecha límite.** Hoy cambiar el esquema es gratis porque no hay datos; con datos, es la migración del punto 1.

**Volumen a soportar.** El crudo a 100 Hz **no** entra a la base (Parquet en storage — ADR-008, ADR-042). Lo que entra son filas por zancada. Con el supuesto de la Vista 4 §1.4 (~8 h/día) y zancadas de ~1,1 s, un paciente produce del orden de **300.000 filas por día** entre zancadas, eventos, vectores y scores. Es una **cota superior** (nadie camina 8 h seguidas), pero con 20 pacientes en uso diario serían ~190 millones de filas por mes. Para la tesis alcanza cualquier opción; para la máxima, particionar deja de ser opcional.

**Opciones evaluadas.**
- **A — Particionado nativo + `pg_partman` + `pg_cron` (elegida).** *Pros:* es la ruta oficial de Supabase; el particionado es Postgres estándar —`pg_partman` sólo automatiza la creación de particiones: si un día faltara, las existentes siguen funcionando—; una consulta por rango de fechas abre sólo las particiones que toca; archivar o borrar es soltar particiones enteras; y habilita **FK reales hacia tablas particionadas** (Postgres ≥ 12), que es lo que necesita ADR-046. *Contras:* se pierde `time_bucket()` (se reemplaza por `date_bin()`/`date_trunc()`) y los continuous aggregates (que no teníamos); el mantenimiento de las particiones pasa a ser responsabilidad nuestra; toda PK o clave única tiene que incluir la columna de partición.
- **B — Quedarse en Postgres 15 con Timescale.** *Pros:* anda hoy, sin rediseño. *Contras:* es un callejón sin salida —antes de subir a 17 hay que migrar igual, pero con datos— y en Supabase es la edición Apache: se paga el costo de la extensión sin sus extras.
- **C — Una base de series aparte (Tiger Cloud, Timescale completo).** *Pros:* continuous aggregates y compresión columnar. *Contras:* dos bases —auth y RLS duplicadas, sin joins entre series y sesiones/pacientes, dos backups—; se justifica con volúmenes muy por encima de los nuestros. Queda como puerta de salida: nuestras tablas son Postgres estándar.
- **D — Tablas comunes, sin particionar.** *Pros:* lo más simple; alcanza para la tesis. *Contras:* particionar después una tabla grande es la migración con datos del punto 1; el requisito de escalar a la máxima la descarta.

**Decisión.**
1. **Proyecto de Supabase en Postgres 17**, sin `timescaledb`.
2. **Tablas de series particionadas:** `strides` (nueva — ADR-046), `gait_events`, `feature_vectors` y `anomaly_scores`. El resto del esquema (metadata, registry, blobs) sigue en tablas comunes: su volumen es bajo.
3. **Clave de partición: `session_started_at`**, una copia de `sessions.started_at` que llevan todas las filas de la sesión, con **rango mensual**. Se eligió el inicio de la sesión, y no la hora de cada dato, por tres motivos:
   - una sesión **nunca queda partida** entre dos particiones: se archiva o se borra entera;
   - **reenviar datos no duplica**: la clave no depende de la hora corregida por la sincronización, que cambia si se recalcula el drift (ADR-004);
   - las **FK entre tablas de series** usan el mismo valor en las dos puntas (ADR-046).

   La hora de cada dato sigue guardada como columna (`time`, `started_at`).
4. **`pg_partman`** (en el esquema `partman`) crea las particiones mensuales por adelantado (`p_interval := '1 month'`, `p_premake := 4`) más una partición *default*. **`pg_cron`** corre cada día `partman.run_maintenance_proc()` y, a continuación, la rutina que cierra las particiones nuevas (ADR-047).
5. **Sin retención automática por ahora.** Las series se conservan; el crudo sigue la retención *tiered* de ADR-008, que vive en storage. El archivo en frío de particiones viejas queda para la máxima → **CP-32**.
6. **Series agregadas del dashboard:** vistas materializadas o tablas de resumen refrescadas por `pg_cron`. Se decide cuando exista el dashboard (máxima — ADR-033), junto con CP-20 y CP-22. **Reemplaza el punto 3 de ADR-031.**

**Justificación.** En Supabase, Timescale sólo aportaba el particionado, y el particionado ya es Postgres. La opción estándar saca del camino crítico una extensión deprecada justo antes de la primera captura, y de paso destraba la integridad referencial que pedía CP-29: con particionado nativo, una FK hacia la serie es una FK común de Postgres.

**Consecuencias.** **Cierra CP-26** y abre **CP-32**. **ADR-007** queda revisada en su capa de series (las tres capas se mantienen) y el **punto 3 de ADR-031** queda reemplazado. Cambian: `src/db/schema.sql`, la Vista 4 (§1, §1.1, §1.2 y la nueva §1.5), la Vista 1 §2, el maestro (§3, §10, §11), `stack_tecnologico.md` y los diagramas que decían TimescaleDB. **Al crear la base:** confirmar que `pg_partman` y `pg_cron` están disponibles en el proyecto (la documentación de Supabase los publica; se verifica con una consulta a `pg_available_extensions`).

**Apéndice conceptual (en llano).** *Particionar* es partir una tabla gigante en pedazos que Postgres maneja como si fueran una sola: una tabla por mes en lugar de una tabla infinita, como tener un cuaderno por mes en vez de un cuaderno sin fin. Para buscar "las últimas cuatro semanas", Postgres abre uno o dos cuadernos en lugar de hojear todo; para tirar 2025, tira cuadernos enteros sin leerlos. Eso es lo que hacían las *hypertables* de Timescale, y es lo que Postgres hace solo desde la versión 10. Lo que faltaba es alguien que **prepare el cuaderno del mes que viene antes de que empiece el mes**: eso es `pg_partman`, y `pg_cron` es el despertador que lo llama todos los días. El cuaderno de cada fila se elige por el **día en que empezó la sesión**, no por la hora del dato: así una sesión que cruza la medianoche queda entera en un solo cuaderno, y si mañana se recalcula la sincronización y la hora de un evento se corre unos milisegundos, la fila no cambia de lugar.

**Referencia.** ADR-006 (Supabase), ADR-007 (modelo de datos), ADR-008 (retención), ADR-031 (`feature_vectors`), ADR-033 (dashboard), ADR-046 (identidad de las series), ADR-047 (particiones cerradas); CP-26, CP-32, CP-20, CP-22; Vista 4 §1. Fuentes: [Supabase — timescaledb](https://supabase.com/docs/guides/database/extensions/timescaledb) · [Supabase — migrar de TimescaleDB a pg_partman](https://supabase.com/docs/guides/database/migrating-to-pg-partman) · [Supabase — pg_partman](https://supabase.com/docs/guides/database/extensions/pg_partman) · [Tiger Data — ediciones de TimescaleDB](https://www.tigerdata.com/docs/about/latest/timescaledb-editions) · [PostgreSQL 12.2 — FK hacia tablas particionadas](https://www.postgresql.org/docs/release/12.2/).

---

## ADR-045 — Migraciones versionadas con la CLI de Supabase; `schema.sql` pasa a ser un snapshot generado (resuelve CP-23; revisa ADR-037)
**Estado:** aceptada (2026-10-17) — **Decisión: el esquema evoluciona sólo por migraciones versionadas —archivos SQL con timestamp en `src/db/supabase/migrations/`—, administradas con la CLI de Supabase y aplicadas a la base remota por CI desde `master`. `src/db/schema.sql` deja de editarse a mano: pasa a ser el snapshot del esquema vigente, regenerado desde la base que arman las migraciones. La fuente única de ADR-037 pasa a ser la cadena de migraciones.**

**Contexto.** CP-23 pedía cómo versionar los cambios del esquema. Hoy `schema.sql` es una **foto** de cómo tiene que quedar la base. Mientras la base está vacía alcanza: se borra todo y se crea de nuevo. Con datos de pacientes, no: cada cambio —una columna, un índice, una tabla— tiene que aplicarse como un **paso** sobre la base existente, sin perder nada y en el mismo orden en todas las copias, la de cada computadora y la de la nube. ADR-037 ya lo anticipaba (*"el historial del esquema pasa a ser el historial de ese archivo más sus migraciones"*) y lo dejó pendiente. Hay además un dato propio del proyecto: se trabaja desde **dos computadoras**, y la documentación de Supabase advierte que dos `db push` concurrentes desde máquinas distintas chocan.

**Opciones evaluadas.**
- **A — Migraciones versionadas con la CLI de Supabase (elegida).** *Pros:* es la herramienta nativa de la plataforma e integra todo lo que hace falta: base local reproducible (Docker), `db reset` (aplica todas las migraciones desde cero), `db push` (aplica en la nube sólo las pendientes y las registra en `supabase_migrations.schema_migrations`), `test db` (pgTAP) y `db dump`. Las migraciones son SQL plano. Es el patrón estándar de la industria, el mismo de Rails, Django o Flyway. *Contras:* exige Docker y la CLI en las dos computadoras, y disciplina: no se edita una migración aplicada ni se toca la base remota a mano.
- **B — Esquema declarativo de Supabase (`pg-delta`).** *Pros:* se edita un solo archivo y la CLI genera la migración por diferencia. *Contras:* la documentación lo marca como **experimental** y **deja afuera los objetos administrados por extensiones, como las particiones de `pg_partman`**: justo las tablas centrales de ADR-044.
- **C — sqitch / Flyway / Liquibase.** *Pros:* maduras e independientes de la base. *Contras:* duplican lo que la CLI de Supabase ya trae integrado (base local, tests, dump): una segunda cadena de herramientas sin ganancia.
- **D — Scripts numerados a mano.** *Pros:* cero herramientas. *Contras:* hay que llevar a mano qué se aplicó y dónde; no hay base local reproducible; frágil con dos computadoras.

**Decisión.**
1. **El proyecto de Supabase vive en `src/db/supabase/`** (`supabase init` con `--workdir src/db`; todos los comandos con `--workdir src/db`). Contiene `config.toml`, `migrations/`, `tests/` (pgTAP) y `seed.sql`, con **datos sintéticos únicamente**, nunca de pacientes reales.
2. **Cada cambio es una migración nueva:** `migrations/<AAAAMMDDHHMMSS>_<nombre>.sql` (`supabase migration new`). Tres reglas:
   - **una migración aplicada no se edita**: si algo quedó mal, se corrige con otra migración;
   - **nadie toca la base remota a mano**, ni desde el editor SQL ni desde el panel: lo que no está en una migración no existe;
   - **las migraciones las aplica CI desde `master`**, nunca una persona con `db push` desde su computadora.
3. **`src/db/schema.sql` es un snapshot generado, de sólo lectura.** Lo produce un script del repo (`src/db/scripts/`) que corre `supabase db dump --local --schema public` sobre la base armada por las migraciones y **excluye las particiones hijas**, cuyos nombres dependen de la fecha: si no, el snapshot cambiaría cada mes sin que nadie toque el esquema. Lleva un encabezado "GENERADO — no editar". Sigue siendo **el** lugar donde se lee el esquema; lo que cambia es que ya no es donde se escribe.
4. **CI (GitHub Actions), en cada push:** `supabase start` → `db reset` (todas las migraciones desde cero + seed) → `test db` (la suite mínima de ADR-047) → regenera el snapshot y **falla si difiere** del commiteado → si es `master` y todo pasó, `db push` al proyecto remoto. La base efímera de CI es el ensayo de cada migración antes de tocar datos reales.
5. **Regla para dos computadoras** (va a `CLAUDE.md` §4): las migraciones se aplican en el orden de sus nombres, así que una migración nueva tiene que quedar **después de todas las ya aplicadas en la base remota**. Si después del `pull --rebase` la local tiene un timestamp anterior a una ya aplicada, se renombra con un timestamp nuevo antes de pushear.
6. **Transición.** Esta decisión se toma antes de que la base exista. `schema.sql` recibe ahora **su última edición a mano** (el diseño de ADR-044, 046 y 047). El día que se cree la base —primer paso de la fase de base del roadmap—, ese contenido pasa a ser la migración base (`…_baseline.sql`) y desde ahí rige el punto 3.

**Justificación.** Las migraciones son a la base lo que los commits son al código: el historial de cambios, no sólo el estado final. Es la práctica estándar, y la herramienta nativa de la plataforma la trae integrada de punta a punta. La alternativa declarativa sería más cómoda, pero hoy deja afuera exactamente las tablas particionadas. Y se conserva el espíritu de ADR-037 —una fuente, varios consumidores—: la fuente pasa a ser la cadena de migraciones, y el snapshot, el ER y la Vista 4 son consumidores.

**Consecuencias.** **Cierra CP-23.** **ADR-037 queda revisada.** Cambian: `CLAUDE.md` (fuentes únicas, dónde trabaja cada agente, estructura del repo y §4 de conflictos), `README.md`, `src/db/README.md`, la Vista 4 (§1.1 y la nueva §1.7), el maestro (§10, §11) y `stack_tecnologico.md`. **Requisito operativo:** Docker y la CLI de Supabase en las dos computadoras (verificado el 2026-10-17 en la de Juan: Docker sí, la CLI todavía no). **Queda por hacer** en la fase de base del roadmap: `supabase init`, la migración base, la suite pgTAP, el script del snapshot y el workflow de CI.

**Apéndice conceptual (en llano).** Una *migración* es un archivo SQL con **un** cambio, numerado por fecha y hora. La base guarda la lista de las migraciones que ya aplicó; cuando llega una nueva, aplica sólo esa. Por eso **nunca se edita una migración ya aplicada**: la base no se entera del cambio —ya la tiene anotada como hecha— y las copias quedan distintas sin que nada avise. Si algo quedó mal, se escribe otra migración que lo corrija, igual que con un commit. El *snapshot* es la foto que se saca **después** de aplicar todas las migraciones: sirve para leer de un vistazo cómo es la base hoy, pero no se toca, porque se regenera solo. Y la base efímera de CI nace vacía, recibe todas las migraciones en orden, corre los tests y se tira: si una migración rompe algo, rompe ahí y no sobre los datos de los pacientes.

**Referencia.** ADR-037 (fuente única del esquema), ADR-036 (que dejó la herramienta pendiente), ADR-044 (particionado), ADR-046 (identidad de las series), ADR-047 (suite de tests); CP-23; Vista 4 §1. Fuentes: [Supabase — migraciones](https://supabase.com/docs/guides/deployment/database-migrations) · [Supabase — esquemas declarativos](https://supabase.com/docs/guides/local-development/declarative-database-schemas) · [Supabase — testing con pgTAP](https://supabase.com/docs/guides/local-development/testing/overview) · [Supabase CLI — db dump](https://supabase.com/docs/reference/cli/supabase-db-dump).

---

## ADR-046 — Identidad de las series: la zancada como entidad, numerada en el borde, con FK reales (resuelve CP-29)
**Estado:** aceptada (2026-10-17) — **Decisión: la zancada pasa a ser una entidad de la base (`strides`), identificada por `(session_id, foot, stride_seq)` con el número que le asigna la plantilla; el ciclo bilateral se identifica por `cycle_seq`, que asigna la cintura. Eventos, vectores y scores se identifican a partir de esos números y se vinculan con FK reales; toda fila de las series lleva `patient_id` y `session_started_at`, garantizados por una FK compuesta a `sessions`. La ingesta es idempotente.**

**Contexto.** CP-29 registraba dos huecos de integridad en `schema.sql`:
- **`anomaly_scores` no tenía identidad** —ni PK ni `id`—, así que `anomaly_raw_snippets.score_id` era una *"fk lógica"*: nada garantizaba que el snippet apuntara a un score existente.
- **La zancada no existía como entidad**, aunque es la unidad alrededor de la que gira todo el sistema: las features son por zancada, los eventos la segmentan y los scores se evalúan sobre ventanas de zancadas. `feature_vectors.stride_id` no tenía contraparte en ninguna tabla y **ninguna spec decía quién numera las zancadas**. No había forma de reconstruir qué IC/MS/TO produjeron un vector, que es justo el cruce que hace falta para validar SPEC-01/02 contra el dataset.

Al bajar el diseño aparecieron dos cosas más: SPEC-01 emite eventos **con `flags`** (`no_crossover`, baja confianza) y SPEC-02 emite features **marcadas**, pero la base no tenía dónde guardarlos; y la RLS de `gait_events` llegaba al paciente con un join a `sessions` **por fila**.

**Opciones evaluadas.**
- **A — Zancada como entidad, numerada en el borde, con FK reales (elegida).** *Pros:* la integridad la garantiza la base, no una convención; la **ingesta es idempotente** —reenviar un lote después de un corte no duplica filas, porque la clave viaja con el dato—, que es lo que pide un sistema con buffers, cortes de BLE y subidas en el check-in; trazabilidad completa evento → zancada → vector → score. *Contras:* el firmware tiene que numerar zancadas y ciclos (cambio chico en SPEC-01/02/05/11); las claves llevan la columna de partición (ADR-044); y un vector que apunta a dos zancadas de pies distintos necesita dos columnas constantes para sus FK.
- **B — Agregar `stride_seq` donde falta, sin FK.** *Pros:* mínimo. *Contras:* la integridad sigue siendo una convención, y el hueco del snippet queda sin resolver.
- **C — Identificadores generados por la base (uuid o *identity*).** *Pros:* lo habitual en aplicaciones web. *Contras:* los datos nacen en el borde antes de llegar a la base; un id asignado al insertar **rompe la idempotencia** (el mismo dato reenviado recibe otro id) y obliga a un ida y vuelta para vincular los hijos.

**Decisión.**
1. **Numeración en el borde.** Todos los contadores arrancan en `arm()` (SPEC-11):
   - **`stride_seq`** — la plantilla, por pie. Cada IC abre la zancada siguiente; el MS y el TO de ese apoyo llevan el número de su IC (SPEC-01/02).
   - **`cycle_seq`** — la cintura, al emparejar una zancada izquierda con una derecha por IC, sobre el reloj ya sincronizado (SPEC-05, ADR-004).
2. **Identidades en la base.** Todas llevan además `session_started_at`, la clave de partición (ADR-044):

   | Entidad | Tabla | Identidad |
   |---|---|---|
   | Zancada | `strides` (nueva) | `(session_id, foot, stride_seq)` |
   | Evento | `gait_events` | la zancada + `type` (IC/MS/TO) |
   | Vector de features | `feature_vectors` | `(session_id, scope, unit_seq, features_source, feature_set_version)`: `unit_seq` es el `stride_seq` (vector por pie) o el `cycle_seq` (bilateral); el bilateral guarda además el par `left_stride_seq`/`right_stride_seq` que cerró el ciclo |
   | Score | `anomaly_scores` | `(session_id, model_id, scope, unit_seq)`: la misma unidad que el vector que lo disparó |
   | Snippet de crudo | `anomaly_raw_snippets` | conserva su `id`; FK al score que lo pidió |
3. **FK reales:** evento → zancada; vector → su zancada o sus dos zancadas; snippet → score; score → modelo del mismo paciente (ADR-043, se mantiene); y **toda fila de las series → `sessions (id, patient_id, started_at)`**. Esta última garantiza que el `patient_id` y la fecha copiados en cada fila sean los de su sesión: una fila no puede declarar el paciente de otra.
4. **`patient_id` en cada fila de las series**, para que la RLS filtre por una columna indexada en lugar de hacer un join por fila (ADR-047).
5. **`flags text[]`** en zancadas, eventos y vectores: guarda lo que emiten SPEC-01/02. El vocabulario lo definen las specs.
6. **Ingesta idempotente:** el host escribe con *upsert* sobre estas claves. Reenviar un lote no duplica nada.
7. `sessions.patient_id` y `sessions.started_at` pasan a **`not null`**, y `sessions` suma `unique (id, patient_id, started_at)`, que es el ancla de las FK compuestas.

**Justificación.** La zancada es la unidad del sistema; darle identidad **donde nace** es lo que hace posibles a la vez la integridad y la idempotencia. Que el número lo asigne el dispositivo y no la base es lo habitual en pipelines de IoT y de eventos, donde el dato se produce antes de que la base lo vea. Y la clave de partición de ADR-044 hace trivial la columna extra que exigen las FK hacia tablas particionadas: vale lo mismo en todas las filas de la sesión.

**Consecuencias.** **Cierra CP-29.** Cambian: `src/db/schema.sql` (tabla nueva `strides`; `gait_events`, `feature_vectors`, `anomaly_scores` y `anomaly_raw_snippets` rediseñadas), el ER, la Vista 4 (§1.1, §1.2 y la nueva §1.6), el maestro §11, **SPEC-01** (el evento sale con `stride_seq`), **SPEC-02** (definición de la zancada y su número), **SPEC-05** (buffer indexado por `stride_seq`; `cycle_seq` en la cintura), **SPEC-11** (`arm()` reinicia los contadores), la Vista 2 §3 y la Vista 1 §4 (los mensajes llevan los números).

Dos efectos a tener presentes:
- **CP-30:** si después de un reset se retoma **la misma sesión**, los contadores no pueden volver a cero —pisarían zancadas ya guardadas—: `arm()` tendría que recibir el próximo número. Queda anotado en CP-30.
- **Modelos globales:** con `anomaly_scores.patient_id` obligatorio, la FK `(model_id, patient_id) → models (id, patient_id)` de ADR-043 se aplica siempre, así que **un score persistido es siempre de un modelo del mismo paciente**; un modelo global (`patient_id` nulo) no puede producirlos. Es coherente con ADR-000 (personalización primero), pero corrige lo que decía ADR-043: que con modelos globales la FK no se aplicaba. Si algún día un modelo poblacional justificado tuviera que dejar scores, se revisa esta FK.

**Apéndice conceptual (en llano).** Funciona como las facturas de un comercio: el número lo imprime el comercio en el momento de la venta, no el banco cuando la deposita. Si el depósito falla y se reintenta, la factura 1234 sigue siendo la 1234, y el banco se da cuenta de que ya la tiene. Acá el comercio es la plantilla (numera zancadas) o la cintura (numera ciclos), y el banco es la base: si el host reenvía un lote después de un corte de BLE, cada fila llega con su número y la base la reconoce en lugar de duplicarla. Eso es la *idempotencia*. Una *FK* (clave foránea) es la base negándose a guardar una fila huérfana: un vector de features que dice ser de la zancada 57 del pie izquierdo no entra si esa zancada no existe, y un snippet de crudo no entra si el score que lo pidió no está.

**Referencia.** ADR-004 (sincronización), ADR-015 y ADR-038 (eventos), ADR-018 y ADR-036 (paridad y `features_source`), ADR-043 rev (FK al modelo del paciente; ciclo de vida), ADR-044 (clave de partición), ADR-047 (RLS); SPEC-01, SPEC-02, SPEC-05, SPEC-11; CP-29, CP-30. Fuente: [PostgreSQL 12.2 — FK hacia tablas particionadas](https://www.postgresql.org/docs/release/12.2/).

---

## ADR-047 — Exposición por la Data API: grants explícitos, RLS en todas las tablas y particiones cerradas (extiende ADR-032)
**Estado:** aceptada (2026-10-17) — **Decisión: ninguna tabla es accesible por la Data API sin un `GRANT` explícito; `anon` no tiene acceso a nada; RLS habilitado en todas las tablas expuestas, también en las que no tienen datos de pacientes; las particiones hijas quedan sin grants y con RLS; las funciones de las políticas viven en un esquema `private`, fuera de la API; y una suite mínima de tests pgTAP verifica todo esto en CI, en cada push.**

**Contexto.** Cuatro hechos:
1. **Supabase cambió su default.** Antes, toda tabla nueva en `public` recibía automáticamente `SELECT`, `INSERT`, `UPDATE` y `DELETE` para `anon`, `authenticated` y `service_role`. Desde el **30/05/2026** los proyectos nuevos ya no, y desde el **30/10/2026** el cambio llega a todos: una tabla sin `GRANT` explícito no existe para la Data API. El host y el worker usan `supabase-py`, que pasa por esa API, y `schema.sql` no tenía ni un `GRANT`: la primera escritura del host hubiera fallado con *permission denied*.
2. **Cada partición es una tabla de verdad.** Según la documentación de Postgres sobre herencia —el mecanismo sobre el que está construido el particionado—, al consultar la tabla madre se chequean sus permisos y se aplican sus políticas; una tabla hija nombrada directamente se chequea **sola**, y las políticas de la madre no corren. Para la herencia está documentado; para las particiones se verifica con un test (punto 5).
3. **`has_patient_access()` vivía en `public` con `security definer`**, o sea invocable desde afuera por la API. Supabase recomienda dejar las funciones auxiliares en un esquema no expuesto y envolver las llamadas de las políticas en `select`, para que el optimizador las evalúe **una vez por consulta** y no una vez por fila.
4. **`devices`, `model_deployments` y `firmware_images` no tenían RLS** (*"no contienen datos de salud"*). Con los grants automáticos de antes, cualquier usuario autenticado podía **escribir en `firmware_images`**, que es de donde sale la imagen que viaja por OTA a los micros.

**Opciones evaluadas.**
- **A — Grants explícitos por rol y por tabla + RLS en todas las tablas expuestas + particiones cerradas + tests (elegida).** *Pros:* defensa en capas —el grant decide **qué tablas**, la RLS **qué filas**, y los tests lo verifican—; la seguridad de los datos de salud no depende de un default de la plataforma, que además acaba de cambiar. *Contras:* hay que mantener la matriz de grants con cada tabla nueva (la suite de tests lo hace visible).
- **B — Volver a la exposición automática** (los *default privileges* del panel, o su equivalente en la CLI). *Pros:* cero trabajo. *Contras:* exposición por defecto: una tabla nueva queda alcanzable antes de que alguien piense su RLS.
- **C — Todo en un esquema privado, expuesto sólo por vistas o funciones** (un esquema `api`, como sugiere Supabase para auditar la superficie). *Pros:* superficie mínima y explícita. *Contras:* una capa de vistas o funciones sobre cada tabla, para dos clientes que son nuestros (host y worker). Queda como evolución para la máxima, cuando haya app móvil y dashboard con usuarios externos.

**Decisión.**
1. **Matriz de grants** (Data API):

   | Rol | Acceso |
   |---|---|
   | `anon` | **nada** |
   | `authenticated` | lee lo que la RLS le deja ver; inserta y actualiza lo que escribe el host (pacientes, sesiones, dispositivos, series, blobs, modelos en el check-in, despliegues, config de feedback, jobs manuales); **no borra nada**; `firmware_images` y `patient_access`, sólo lectura |
   | `service_role` | todo (el worker; saltea la RLS por diseño — ADR-032) |

   Borrar queda para `service_role`: es raro, es sensible y nunca lo hace el cliente.
2. **RLS en todas las tablas expuestas**, incluidas `devices`, `model_deployments` y `firmware_images`. Las tablas con datos de pacientes filtran con `patient_id in (select private.accessible_patient_ids())`; las demás tienen políticas propias (`firmware_images`: sólo lectura; `model_deployments`: los despliegues de modelos que el usuario puede ver).
3. **Funciones de las políticas en `private`**, un esquema no expuesto: `private.accessible_patient_ids()` reemplaza a `public.has_patient_access()`. Es `security definer`, con `search_path` vacío, y sólo `authenticated` puede ejecutarla.
4. **Particiones cerradas:** sin grants para `anon` ni `authenticated`, y con RLS habilitado y sin políticas, así que sólo `service_role` y el dueño llegan a ellas directo. Todo acceso pasa por la tabla madre. Una rutina, `private.secure_partitions()`, las cierra después de cada mantenimiento de `pg_partman` (ADR-044).
5. **Suite mínima de pgTAP en CI** (ADR-045):
   - (a) un usuario con acceso al paciente A no ve ni escribe datos del paciente B, en ninguna tabla;
   - (b) `anon` no puede leer nada;
   - (c) toda tabla de `public`, madres y particiones, tiene RLS habilitado;
   - (d) ninguna partición tiene grants para `anon` ni `authenticated`, y nombrarla directamente falla;
   - (e) un vector sin su zancada, o un score con el modelo de otro paciente, son rechazados (ADR-046);
   - (f) reenviar el mismo lote no duplica filas (ADR-046).
6. **Datos de prueba sintéticos:** `seed.sql` y los tests nunca usan datos reales de pacientes.

**Justificación.** El grant y la RLS son dos llaves distintas y hacen falta las dos: el grant decide si un rol puede tocar una tabla; la RLS, qué filas ve. Para datos de salud, la regla tiene que estar escrita en el esquema y verificada por un test, no depender de un default que la plataforma puede cambiar —y que acaba de cambiar—.

**Consecuencias.** **Extiende ADR-032**, que fijó la RLS por paciente: la lleva a todas las tablas expuestas y precisa los grants. La ingesta del host sigue siendo con el JWT del investigador (`owner` — ADR-032). Cambian: `src/db/schema.sql` (grants, políticas, esquema `private` y rutina de particiones), la Vista 4 §2 y el maestro §12. El **nivel formal** (consentimiento, auditoría, nivel de pairing) sigue en **CP-18**.

**Apéndice conceptual (en llano).** Hay dos puertas. La primera es el **grant**: dice si un rol puede siquiera entrar a una tabla. La segunda es la **RLS**: una vez adentro, la base le muestra a cada usuario sólo las filas de sus pacientes. Supabase solía dejar la primera puerta abierta para toda tabla nueva y confiar en la segunda; ahora la deja cerrada y hay que abrirla a mano, tabla por tabla, que es lo que hace la matriz. Las particiones son el caso fino: cada mes es una tabla aparte, y si alguien pudiera abrir la del mes directamente, la segunda puerta —que está puesta en la tabla madre— no correría. Por eso las particiones quedan sin grant y con RLS propia, y un test lo verifica en cada push.

**Referencia.** ADR-032 (RLS por paciente), ADR-033 (UI y dashboard), ADR-044 (particiones), ADR-045 (CI), ADR-046 (integridad); CP-18; Vista 4 §2. Fuentes: [Supabase — cambio en la exposición de tablas](https://supabase.com/changelog/45329-breaking-change-tables-not-exposed-to-data-and-graphql-api-automatically) · [Supabase — Hardening the Data API](https://supabase.com/docs/guides/api/hardening-data-api) · [Supabase — Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security) · [PostgreSQL — herencia](https://www.postgresql.org/docs/current/ddl-inherit.html).

---

## Puntos abiertos (a ratificar)

Se llevan en el registro vivo **`docs/cuestiones_pendientes.md`** (única fuente de verdad). Cuando una cuestión se resuelve mediante una decisión de arquitectura, se cierra allí y se agrega/actualiza el ADR correspondiente en esta bitácora.
