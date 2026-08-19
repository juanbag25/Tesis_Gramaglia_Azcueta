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
- **Uso real (máxima):** features/eventos/scores continuos; el **crudo sólo alrededor de anomalías/drift** (snippet pedido al buffer circular de la plantilla). Evita ~4 GB/mes/paciente de crudo continuo conservando lo clínicamente interesante, y encaja con el sensor de drift de Mahalanobis.

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

El **host** es el puente entre la cintura y la nube, **y** el lugar donde vive la UI de control del operador.

**Funciones:** ingesta por **BLE** (notificaciones GATT para el stream; writes con ACK para control), **buffer local** (tolera cortes de conectividad), escritura a Supabase (crudo a storage + features/eventos/scores a la DB), **puente OTA** (baja el artefacto del registry y lo empuja a la cintura) y **runtime de inferencia espejo** para los modelos de clase **H** (ADR-011 rev).

**UI de control (mínima):** **app local en Python** — el mismo proceso que hace la ingesta (`bleak`) sirve una **UI web** (FastAPI + página) en la propia laptop. Permite: elegir paciente, **abrir/cerrar sesión**, **cambiar el modo de las zapatillas** (captura exploratoria / operativa / edge), ver **estado** (conexión, muestras, batería) y **disparar OTA**. Un solo proceso y un solo lenguaje: el botón llama directo a la función que ya tiene la conexión BLE abierta.

**Máxima:** la UI pasa a una **app móvil nativa**. El firmware de la cintura **no cambia** (periférico BLE agnóstico al central — ADR-002/ADR-034); la app replica el mismo flujo.

> El **modo** de operación se manda como **comando explícito** por el canal confiable; el micro nunca lo infiere [ADR-034].

### 4.1 Configuración de feedback per-paciente [ADR-027 / SPEC-09]

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
- Todo modelo queda **respaldado**: si un micro se rompe o se pierde, se recupera desde la DB.

---

## ADRs relevantes
ADR-006 (Supabase), ADR-007 (Postgres+Timescale+storage), ADR-008 (retención tiered), ADR-009 (worker de reentrenamiento), ADR-011 rev (ruteo model-agnostic / runtime espejo en el host), ADR-012 (OTA — lado backend), ADR-022 (cuantización int8), ADR-027 + SPEC-09 (config de feedback), ADR-031 (esquema de `feature_vectors`), ADR-032 (RLS y seguridad), ADR-033 (UI de control y dashboard), ADR-034 (`host_type` en la sesión).

## Stack (resumen; detalle en `../stack_tecnologico.md`)
**Supabase** (Postgres + TimescaleDB + Storage + Auth) · **supabase-py** (worker y host) · **bleak** (BLE del host, mínima) · **FastAPI** (UI de control) · **TensorFlow/Keras + conversor TFLite/LiteRT** (worker) · scikit-learn, numpy/scipy/pandas · framework de dashboard **a definir** (máxima) · stack móvil **a definir** (máxima).

## Diagramas de esta vista
- `../esquema_base_de_datos.mermaid` — modelo entidad-relación.
- `../componentes_backend_app.mermaid` — componentes y flujos del backend/app (**nuevo**).

## Pendiente de definir / investigar (backlog)
- **CP-06 — Proveedor del worker en la nube** (VPS / contenedor gestionado / instancia con GPU). Se decide al llegar a la máxima.
- **CP-18 — Ratificación del nivel de seguridad/ética** con el comité (consentimiento, anonimización, auditoría, nivel de pairing).
- **Framework del dashboard** y **stack de la app móvil** (ambos, máxima — ADR-033).
- **Salidas clínicas concretas:** dónde se computan WBA/PSV, el modelo de Jung, los Z-scores y los heatmaps (worker vs dashboard).
- **Herramienta de migraciones** de la DB (p. ej. Supabase migrations).
- **CP-20 — Columnas generadas `STORED`** sobre `features` (ADR-031): qué features se materializan depende de que se congele el `feature_set_version` y de qué grafique el dashboard (diferido a la máxima). *(El resto del esquema —RLS + `patient_access`, `sessions.host_type`, `feedback_config`, fases de captura— ya está escrito en `src/db/schema.sql`.)*
