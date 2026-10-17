# Vista 4 — Backend y Aplicación

> **Nivel de abstracción:** todo lo que vive **fuera de los micros** — persistencia, worker de reentrenamiento, app host (ingesta + UI de control) y dashboard clínico. No entra en internals de firmware (Vista 2) ni en la definición de features/modelos (Vista 3).
>
> **Estado:** consolidada — aquí vive la **definición canónica** del backend y las aplicaciones. El maestro (§10–§12) mantiene una vista general breve y apunta acá; el mapa de entidades está en su §11.
>
> **Regla de layering:** los modelos se **definen** en la Vista 3 y el backend los **entrena, versiona y sirve**; el firmware (Vista 2) los ejecuta.

---

## 1. Persistencia — Supabase

**Plataforma gestionada** [ADR-006]: **PostgreSQL** + extensión **TimescaleDB** (series temporales) + **object storage** (crudo comprimido, artefactos de modelos, imágenes de firmware) + **auth** + **API REST/realtime autogenerada**. Elegida por mínima operación (sin sysadmin), Postgres real y extensible, y un camino de escalado limpio a la máxima con el reentrenamiento en un worker externo. **Supabase no entrena**: es el **sistema de registro** (sus Edge Functions sólo sirven como disparador liviano de jobs).

**Modelo de datos en tres capas** [ADR-007]:

| Capa | Qué guarda | Cómo |
|---|---|---|
| **Relacional** | Metadata: pacientes, dispositivos, sesiones, modelos, despliegues, jobs | Tablas Postgres |
| **Series (hypertables)** | Eventos de marcha, vectores de features, scores de anomalía | **TimescaleDB** (particionado por tiempo + compresión) |
| **Object storage** | Crudo continuo (Parquet), artefactos de modelos, imágenes de firmware | Blobs referenciados desde tablas (`storage_url` + `checksum`) |

> **Qué es el crudo que llega acá (ADR-042).** Señal de FSR + IMU a 100 Hz con el **AHRS ya aplicado en el micro**: `lin_accel` (sin gravedad), giro calibrado y **orientación** — y **ningún otro procesamiento**. El worker **consume y no re-procesa IMU**. La calibración es **irreversible por diseño**: no se persisten sus parámetros.

### 1.1 Tablas

**Metadata:** `patients` (con `external_code` anónimo + PII mínima), `devices` (rol `insole_left|insole_right|waist`, revisión de HW, versión de firmware), `sessions` (paciente, **fase** `exploratory`/`operational`/`edge`, `feature_set_version`, entorno, set de dispositivos, `host_type`, tiempos), `patient_access` (pertenencia user→patient→rol, base del RLS) y `feedback_config` (política de feedback per-paciente).
**Series (hypertables):** `gait_events` (IC/TO/MS por pie), `feature_vectors` (vector por zancada + `features_source`), `anomaly_scores` (score, umbral, flag, métrica de drift).
**Blobs:** `raw_blobs` (crudo continuo en Parquet) y `anomaly_raw_snippets` (crudo puntual retenido ante anomalía).
**Registry y ciclo de vida:** `models` (clase L/E/H/W, `inference_target`, `retrain_target`, versión, linaje, métricas, artefacto), `model_deployments` (qué corre en cada micro), `firmware_images` (OTA A/B), `retrain_jobs` (orquestación).

**DDL:** **`src/db/schema.sql`** es la **fuente única** del esquema (ADR-037) — incluye tablas, índices, RLS y políticas. El maestro §11 mantiene sólo el mapa de entidades y apunta ahí. Diagrama ER: `../esquema_base_de_datos.mermaid`.

### 1.2 `feature_vectors` — jsonb + columnas generadas [ADR-031, resuelve CP-05]

Una fila = **un vector de features por zancada** (con `time`, `session_id`, `patient_id`, `scope ∈ {left,right,bilateral}`, `feature_set_version`, **`features_source ∈ {device,offline}`**, `stride_id`), guardado en una columna **`features jsonb`**.

- **Por qué jsonb:** el feature set **aún cambia** y está versionado (ADR-021/ADR-029), y el volumen es bajo (~1 vector/s por pie) → la flexibilidad pesa y el rendimiento no. Además la fila **es** el vector, que es el uso primario (entrenar).
- **Columnas generadas `STORED` + índices** para las pocas features "calientes" que el dashboard grafica seguido; se escriben solas desde el jsonb (el flujo de ingesta no cambia).
- **Continuous aggregates** de Timescale para las series agregadas del dashboard.
- **Puerta de salida:** al congelarse el `feature_set_version` operativo se puede materializar una vista *wide*, si el perfilado lo pide. Descartadas como esquema base: columnas fijas (migración ante cada cambio del set) y *long/narrow* (complica el ML por el pivot).

### 1.3 Trazabilidad de la sesión

`sessions` registra la **fase** de captura (`exploratory` / `operational` / `edge` — ADR-005 rev c) y el **`feature_set_version`** vigente, de modo que cada dato sea reinterpretable. Además el **host declara su tipo** (`host_type ∈ {laptop, mobile}` + versión de app) al abrir la sesión: es **sólo trazabilidad del dataset**, no cambia el comportamiento de nada [ADR-034].

### 1.4 Retención tiered por fase [ADR-008]

- **Fase de dataset:** **crudo completo** (Parquet en storage) + features + eventos + scores + modelos → máxima trazabilidad para re-extraer features y reevaluar algoritmos.
- **Uso real (máxima):** features/eventos/scores continuos; el **crudo sólo alrededor de anomalías/drift** (snippet pedido al buffer circular de la plantilla). Evita del orden de **6,7 GB/mes/paciente** de crudo continuo conservando lo clínicamente interesante, y encaja con el sensor de drift de Mahalanobis.

> **Cómo sale ese número.** Con el paquete de **39 B** (ADR-042: orientación + `t_device` en `uint64`) a 100 Hz por dos plantillas son **7,8 KB/s**, o sea **~6,7 GB/mes** suponiendo **~8 h/día de uso** y **sin comprimir**; a 24 h/día serían ~20 GB, y Parquet comprime bastante por debajo de eso. El supuesto de las 8 h hay que declararlo: la cifra anterior (~4 GB) venía del paquete viejo de 29 B y tampoco lo decía, y la de ~6 GB (35 B) se había olvidado de los 4 B del `uint64`.

---

## 2. Seguridad y privacidad

**Postura de defensa en capas** para datos de salud. El **aislamiento** se resuelve con RLS estricto [ADR-032, resuelve CP-04 a nivel técnico].

- **Aislamiento por paciente (RLS):** **Row-Level Security habilitado en todas las tablas con `patient_id`**, con políticas que filtran por una **tabla de pertenencia `patient_access`** (`user_id`, `patient_id`, `role ∈ {owner, clinician, patient}`). La base misma filtra las filas: la app no puede pedir de más. En la **mínima** hay un solo usuario (investigador = `owner`) con acceso a los pacientes del estudio; en la **máxima** se suman filas `clinician`/`patient` **sin cambiar el esquema**.
- **Worker con `service_role`:** saltea RLS por diseño (corre en backend seguro, **nunca** en el cliente).
- **En tránsito:** WPA2 en el enlace plantillas↔cintura; **BLE LE Secure Connections** en cintura↔host; **HTTPS/TLS** hacia Supabase.
- **En reposo:** cifrado de base y object storage gestionado por la plataforma; artefactos validados por **checksum**.
- **Minimización:** **`external_code` anónimo** en lugar de PII directa; sólo se guardan año de nacimiento, sexo y lado afectado.
- **Reasignación de equipo:** al pasar la cintura a otro paciente hay que **borrar bonds + datos** (ligado a ADR-028; factory-reset → máxima).

> **Nivel formal pendiente (CP-18):** consentimiento informado, alcance de la anonimización, auditoría de accesos y ratificación del nivel de pairing (passkey fijo v1) dependen del **comité de ética**. El diseño técnico ya está; falta el requisito externo.

---

## 3. Worker de reentrenamiento [ADR-009]

Servicio de cómputo **separado de Supabase**. Entrena las clases **E/H/W** (la clase **L** se reentrena sola en la cintura y nunca lo toca).

- **Mínima:** la **laptop** es el worker. Corre los scripts de entrenamiento en Python sobre los datos capturados, produce artefactos, los sube a Supabase y los despliega al micro por OTA.
- **Máxima:** un **worker en la nube** (VPS / contenedor / instancia con GPU si hace falta) jala datos de Supabase, reentrena, escribe el artefacto, registra la versión y notifica al host, que ejecuta el despliegue. **Proveedor concreto: CP-06** (se decide al llegar a la máxima).
- **Orquestación:** un job en **`retrain_jobs`** se dispara por **drift** (Mahalanobis como sensor), **schedule** o **manual**; el worker lo toma, entrena, publica el modelo y actualiza el registry. La app observa el registry y ejecuta el OTA.
- **Cuantización:** TF/Keras → conversor TFLite/LiteRT con **PTQ int8** (representative dataset) → flatbuffer al registry [ADR-022]. El *representative dataset* sale de las **features del micro** (ADR-018).
- **Inferencia batch (clase W):** análisis, re-scoring histórico y reportes corren acá — **nunca** tiempo real [ADR-013].

---

## 4. App host / puente + UI de control [ADR-033, resuelve CP-15]

El **host** es el puente entre la cintura y la nube, **y** el lugar donde vive la UI de control del operador. La UI no es un panel de estado: es el **orquestador de la máquina de estados del sistema** — toda interacción con el equipo (abrir y cerrar sesión, elegir modo, calibrar, provisionar el modelo, disparar OTA) pasa por ella, y el micro nunca infiere nada [ADR-043 rev, ADR-034].

**Funciones:** ingesta por **BLE** (notificaciones GATT para el stream; writes con ACK para control), **buffer local** (tolera cortes de conectividad), escritura a Supabase (crudo a storage + features/eventos/scores a la DB), **puente OTA** (baja el artefacto del registry y lo empuja a la cintura) y **runtime de inferencia espejo** para los modelos de clase **H** (ADR-011 rev).

**UI de control (mínima):** **app local en Python** — el mismo proceso que hace la ingesta (`bleak`) sirve una **UI web** (FastAPI + página) en la propia laptop. Permite: elegir paciente, **abrir/cerrar sesión**, **cambiar el modo de las zapatillas** (captura exploratoria / operativa / edge), ver **estado** (conexión, muestras, batería) y **disparar OTA**. Un solo proceso y un solo lenguaje: el botón llama directo a la función que ya tiene la conexión BLE abierta.

**Máxima:** la UI pasa a una **app móvil nativa**. El firmware de la cintura **no cambia** (periférico BLE agnóstico al central — ADR-002/ADR-034); la app replica el mismo flujo.

> El **modo** de operación se manda como **comando explícito** por el canal confiable; el micro nunca lo infiere [ADR-034].

### 4.1 Ciclo de vida de la sesión [ADR-043 rev — definición canónica]

Una sesión no es "apretar grabar": es una **transacción de 8 fases** que la UI orquesta y que garantiza que el equipo está en condiciones antes de tomar un solo dato. **Diagrama:** `../pipeline_sesion.mermaid`.

| # | Fase | Qué ocurre | Duración | Qué muestra la UI |
|---|---|---|---|---|
| 0 | **Encendido** | Switch físico (ADR-035); plantillas → WiFi de la cintura; cintura → advertising BLE. **Arranca el reloj térmico del IMU** | seg | — |
| 1 | **Conexión** | La cintura reporta plantillas asociadas, baterías, firmware, **paciente + versión de modelo en flash**, temperatura de los 3 IMU y uptime | seg | Panel de estado + **barra de estabilización** |
| 2 | **Configuración** | Paciente, modo (`exploratory`/`operational`/`edge`) y `adaptation_enabled` | operador | Formulario; la barra sigue corriendo |
| 3 | **Provisioning** | Se baja de la DB la versión activa del modelo + `feedback_config` + set activo y **se escribe a flash** (slot A/B, checksum, estampado con `patient_id` + versión). Si el paciente cambió, se limpian los ring buffers de crudo | seg | "Preparando equipo para \<paciente\>" |
| 4 | **Gate térmico** | Espera el remanente, ya descontado lo consumido en 1-3 | resto | Botón de calibrar **deshabilitado** con el faltante a la vista |
| 5 | **Calibración** | Poses (postura → CP-31); bias de giro, offset de accel, alineación anatómica (SPEC-04) | decenas de seg | Instrucción de pose + **indicador en vivo de quieto/movimiento** |
| 6 | **Verificación** | Modelo en flash = paciente · calibración OK · dos plantillas conectadas · sync dentro de presupuesto · batería. **Sin esto no arranca** | instantáneo | Checklist; si falla, dice qué |
| 7 | **Sesión** | Fila en `sessions`; grabación/scoring según el modo; adaptación en RAM si está habilitada | la sesión | Panel en tiempo real |
| 8 | **Cierre** | Se sella `ended_at`; si hubo adaptación el micro sube el estado final y se versiona (N+1). **El flash no se toca** | seg | Confirmación + resumen |

**El warm-up corre en paralelo, no al final.** El reloj térmico arranca al **encender**, no al abrir la sesión, así que conexión, configuración y provisioning se consumen del mismo tiempo. Por eso la barra se muestra desde la fase 1: el operador tiene que entender que el reloj ya viene corriendo y que la app no lo hace esperar al final. **El gate se destraba por temperatura estable** del MPU-6050 (sensor integrado), no por temporizador — con temporizador fijo como respaldo. Entre sesiones seguidas sin apagar no vuelve a cerrarse. Cuánto tarda y con qué umbral: **CP-25**.

**Autoridad del modelo: la DB manda.** Lo que se flashea es **siempre** la última versión de la base; no hay reconciliación flash↔DB. El flash es una **copia de trabajo descartable** cuya única función es que un **reset a mitad de sesión** recargue el modelo sin depender del host. *Costo aceptado:* si la subida del cierre falla, esa sesión pierde su adaptación y la siguiente arranca de la versión anterior (ADR-043 rev; cierra **CP-24**). Bordes sin resolver —caída del enlace, cierre sucio, `ended_at` huérfano— en **CP-30**.

**Guardas contra el cruce de pacientes.** El artefacto en flash lleva `patient_id` + versión, y la cintura **se niega a scorear** si no coincide con la sesión abierta (fase 6). Del lado de la base, la FK compuesta `anomaly_scores (model_id, patient_id) → models (id, patient_id)` impide guardar un score de un paciente calculado con el modelo de otro.

### 4.2 Canal de estado (separado del stream)

El pipeline y el panel necesitan datos que no son muestras. Van por un canal propio, de baja frecuencia:

| Canal | Rate | Contenido |
|---|---|---|
| **Stream** | 100 Hz | Las muestras (Vista 1 §4) |
| **Estado** | cada 1-2 s | Batería, **temperatura de los 3 IMU**, **uptime**, contadores de pérdida de paquetes (derivados del `seq`), error de sincronización estimado |
| **A demanda** | — | Paciente + versión de modelo en flash — al conectar y **después de todo reset** |

Temperatura y uptime siguen viajando **con la sesión corriendo**: la temperatura se aleja del punto de calibración durante el uso (el pie calienta la plantilla), así que es una **señal de calidad del dato** que permite explicar después una sesión anómala; y una caída del uptime es cómo se detecta un reset silencioso. El paciente y la versión en flash, en cambio, no van en el stream.

Este canal es lo que alimenta el panel de monitoreo y **la evidencia con la que se validan** la coexistencia WiFi-AP + BLE y la precisión de sincronización (**CP-28**): hoy el sistema produce esos números —el `seq` existe explícitamente para detectar pérdidas— y ningún componente los consume.

### 4.3 Configuración de feedback per-paciente [ADR-027 / SPEC-09]

La política de feedback vibrotáctil es **parametrizable por paciente y vive en la DB**: `feedback_source` (qué detector alimenta la decisión), **umbrales de las 3 bandas** (leve/marcada/riesgo), **N de la ventana** de zancadas, intensidad, refractario e histéresis, y patrones habilitados. El host los **baja a la cintura**. Los valores son **empíricos** (se fijan con la calibración y el análisis — Vista 3 §5).

---

## 5. Dashboard clínico [ADR-033 — diferido a la máxima]

Aplicación **web de solo-lectura** sobre Supabase (con RLS), para el profesional. **No controla las zapatillas.**

**Contenido previsto:** evolución temporal de los parámetros de marcha, frecuencia de anomalías, **WBA/PSV** y regresión de riesgo de caída (Jung), **Z-scores por paciente**, heatmaps de presión plantar, y comparación con escalas clínicas (Berg, Fugl-Meyer, Barthel).

**Timing y tecnología:** **diferido a la máxima**; en la fase exploratoria alcanzan **notebooks** (mismo stack de análisis). La tecnología (**Streamlit/Dash** rápido vs **React + supabase-js** producto) **se decide entonces**.

---

## 6. OTA — lado backend [ADR-012]

El backend **publica y versiona**; el firmware **valida y conmuta** (mecánica en Vista 2 §8).

- El worker sube el artefacto a object storage y registra la fila en **`models`** (versión, linaje `parent_version`, métricas, `checksum`, `artifact_format`).
- El host observa el registry, **descarga** el artefacto y lo empuja por **BLE** a la cintura.
- El resultado del despliegue queda en **`model_deployments`** (`active` / `rolled_back`); las imágenes de firmware en **`firmware_images`**.
- **Respaldo.** Los modelos de clase **E/H/W** quedan respaldados como artefacto en el registry. Los de clase **L** no viajan por OTA: su estado adaptado se sube en el **check-in** de cada sesión y se versiona en la DB (§4.1, ADR-043 rev). En los dos casos **la DB es la fuente de verdad** y el flash del micro una copia de trabajo descartable: si un micro se rompe o se pierde, se recupera desde la DB.

---

## ADRs relevantes
ADR-006 (Supabase), ADR-007 (Postgres+Timescale+storage), ADR-008 (retención tiered), ADR-009 (worker de reentrenamiento), ADR-011 rev (ruteo model-agnostic / runtime espejo en el host), ADR-012 (OTA — lado backend), ADR-022 (cuantización int8), ADR-027 + SPEC-09 (config de feedback), ADR-031 (esquema de `feature_vectors`), ADR-032 (RLS y seguridad), ADR-033 (UI de control y dashboard), ADR-034 (`host_type` en la sesión), **ADR-043 rev** (ciclo de vida de la sesión, canal de estado, autoridad del modelo).

## Stack (resumen; detalle en `../stack_tecnologico.md`)
**Supabase** (Postgres + TimescaleDB + Storage + Auth) · **supabase-py** (worker y host) · **bleak** (BLE del host, mínima) · **FastAPI** (UI de control) · **TensorFlow/Keras + conversor TFLite/LiteRT** (worker) · scikit-learn, numpy/scipy/pandas · framework de dashboard **a definir** (máxima) · stack móvil **a definir** (máxima).

## Diagramas de esta vista
- `../esquema_base_de_datos.mermaid` — modelo entidad-relación.
- `../componentes_backend_app.mermaid` — componentes y flujos del backend/app.
- `../pipeline_sesion.mermaid` — **pipeline de una sesión**, de encendido a cierre (**nuevo** — ADR-043 rev).

## Pendiente de definir / investigar (backlog)
- **CP-06 — Proveedor del worker en la nube** (VPS / contenedor gestionado / instancia con GPU). Se decide al llegar a la máxima.
- **CP-18 — Ratificación del nivel de seguridad/ética** con el comité (consentimiento, anonimización, auditoría, nivel de pairing).
- **Framework del dashboard** y **stack de la app móvil** (ambos, máxima — ADR-033).
- **Salidas clínicas concretas:** dónde se computan WBA/PSV, el modelo de Jung, los Z-scores y los heatmaps (worker vs dashboard).
- **Herramienta de migraciones** de la DB (p. ej. Supabase migrations).
- **CP-20 — Columnas generadas `STORED`** sobre `features` (ADR-031): qué features se materializan depende de que se congele el `feature_set_version` y de qué grafique el dashboard (diferido a la máxima). *(El resto del esquema —RLS + `patient_access`, `sessions.host_type`, `feedback_config`, fases de captura— ya está escrito en `src/db/schema.sql`.)*
