# Vista 3 — Datos y Machine Learning

> **Nivel de abstracción:** *qué* se calcula y *qué* modelos se usan, independiente de *dónde* corre (eso es la Vista 2/4). Aquí vive la **definición canónica** de features y modelos, versionada y compartida (regla de layering: se **define aquí**, se **ejecuta** en el firmware —Vista 2— y en el worker).
>
> **Estado:** consolidada — aquí vive la **definición canónica** de features y modelos (datos/ML). El maestro (§7–§9) mantiene una vista general breve y apunta acá.
>
> **Documento satélite (detalle):** `3_analisis_features_y_algoritmos.md` — catálogo completo de features (Parte A), mecanismo de modularidad (Parte B, CP-12/ADR-021), tabla de algoritmos con clase/footprint/librería (Parte C) y **backlog de investigación** ordenado (Parte D). *(Relación análoga a `2_specs_algoritmos_firmware.md` con la Vista 2.)*

---

## 1. Definición de features (referencia)

El catálogo nominal es de **47 features en bloques A–I** (A espacio-temporales, B variabilidad, C fuerza/FSR, D simetría, E COP-ML 1D, F cinemática IMU, G smoothness/LDLJ, H frecuencia/entropía, **I tronco** desde el IMU de cintura, **#45-47, diferido** — ADR-040) — 38 originales (A–H) + 3 de tronco (I) + **4 agregadas tras la auditoría de alineación (ADR-029): single support, symmetry angle, avg zero-crossings y sway density (diferida)** + **2 agregadas con la adopción de mid-stance (ADR-038): push-off time ratio (#43) y propulsive impulse ratio (#44)**. El conteo *real* del vector es mayor: el bloque C se instancia **por FSR × sub-fase del apoyo** (carga/propulsión, ADR-038) y hay features de tronco; la **feature selection** (backlog #12) reduce al sweet spot **15-25**.

- **Placement por defecto:** casi todo es **per-pie (plantilla)**; lo **bilateral** (comparar ambos pies: simetría bloque D, double support) va en la **cintura**; el bloque **I (tronco)** corre en la **cintura** (IMU ~L4-L5).
- **Definición única y compartida** plantilla↔cintura↔worker, versionada por **`feature_set_version`** — invariante anti *train/serve skew* (ADR-018). El crudo histórico siempre puede re-procesarse con la misma semántica.
- **Set activo actual (ADR-023 + ADR-040).** Hay dos motivos distintos para tener una feature apagada:
  - **(a) Por hardware** — las de fuerza **medial-lateral**: bloque E completo (**#22-25** COP_ML + **#42** sway density) y **#18** (ratio M/L). Se prenden al sumar los FSR medial/lateral.
  - **(b) Por alcance** — el **bloque I completo (#45-47, tronco)**, diferido hasta resolver las decisiones metodológicas del IHR (SPEC-10). El hardware ya está: la cintura tiene su IMU y los eventos IC.

  En ambos casos quedan **definidas** y se **activan** con un `feature_set_version` nuevo, **sin reescritura**. El catálogo es una **biblioteca de features disponibles**; el **set activo** es lo que efectivamente se calcula, y no tiene por qué ser todo desde el día uno (ADR-040).

**Catálogo detallado (cálculo, entrada, placement, fase) → satélite Parte A.** Es la fuente humana canónica del catálogo hasta que exista el **archivo de datos declarativo** en `src/firmware/shared/` (ADR-021), que pasará a ser la fuente única implementada por firmware (C) y worker (Python).

### 1.1 Modularidad de features (CP-12 → ADR-021)

Todas las features **disponibles**, pero se **prenden/apagan** según el análisis de datos, sin reescribir firmware ni worker y manteniendo paridad. **Mecanismo:** catálogo declarativo (`features.toml` en `shared/` — ADR-054: `id/bloque/scope/inputs/deps/params/tolerancia/activo` + `feature_set_version`; el firmware compila una tabla de C generada desde ese archivo) + **set activo** versionado; prender/apagar = cambiar el set activo (config/OTA), no el código. **Codegen y C-único-bindeado descartados.** La *selección data-driven* de qué se prende es el backlog #12. **Detalle → satélite Parte B.**

---

## 2. Taxonomía de modelos y registry

La arquitectura es **agnóstica al modelo**: cada modelo declara su **clase** en el registry (tabla `models`), y el runtime rutea inferencia y reentrenamiento según esa declaración. El reparto exacto depende de qué modelos se prueben.

| Clase | Inferencia | Reentrena | Granularidad | Ejemplos candidatos | ¿OTA? |
|---|---|---|---|---|---|
| **L — Local-Local** | Cintura (hub) | **Cintura** | Dato a dato (online) | Mahalanobis (EMA de μ + Σ), z-score/EWMA, probabilísticos simples | No (se auto-actualiza) |
| **E — Edge + Worker** | Cintura (hub) | **Worker** | Periódico / async | Autoencoder denso int8, **Isolation Forest** | Sí (recibe pesos) |
| **H — Host** | **Host** (celular/laptop), tiempo real | **Worker** | Periódico / async | Modelos que no entran en la cintura pero sí en el host | Sí (al host) |
| **W — Worker-only (offline)** | **Worker** (batch, **no** tiempo real) | **Worker** | Batch | Análisis/reportes, re-scoring histórico | — |

**Ruteo model-agnostic (ADR-011 rev 2026-07-19).** La inferencia en tiempo real (la que dispara el feedback) corre en **`hub`** (preferido) o en **`host`** (fallback si el modelo no entra por footprint/latencia), **nunca en `worker`/nube** (latencia + conectividad). Cambiar `hub`→`host` es un **switch de config** (`inference_target`), **sin reescritura**, porque el decisor de feedback es **agnóstico al origen del score** y el host aloja un **runtime de inferencia espejo**. Campos del registry: `inference_target ∈ {hub, host, worker}`, `retrain_target ∈ {micro, worker}`, `granularity`. Sumar un modelo = declarar su clase.

- **Isolation Forest = clase E** (infiere en la cintura por recorrido de árboles; reentrena en el worker).
- **LSTM AE = E/H/W** según dónde entre (micro→host→offline; profiling en **#11**).
- La clase **W** queda para lo **estrictamente offline** (análisis/reportes, re-scoring).
- El anteproyecto **§6** mencionaba **SST-AD, SVR, Random Forest**: **descartados** (ADR-030, que cerró CP-11). Se adopta la lista del **§4.3** — Mahalanobis, Isolation Forest, AE denso, LSTM AE — más los candidatos declarables de ADR-029. *SST-AD no está definido en ninguna fuente del corpus; SVR/RF eran referencias bibliográficas, no elecciones.*

*(Esquema de la tabla `models` → `src/db/schema.sql` (ADR-037); mapa de entidades → maestro §11; definición canónica → Vista 4.)*

---

## 3. Mahalanobis: detector en vivo + sensor de drift

La distancia de Mahalanobis cumple **doble función**:

1. **Detector de clase L:** z-score multivariado con matriz de covarianza inversa y **umbral calibrado por chi-cuadrado** (percentil ~99 de la calibración). Es el **caballo de batalla del feedback en tiempo real** (<100 µs) y **lo primero a implementar**. Se adapta continuamente (EMA de μ, Σ) en el micro, sin tocar el worker.
2. **Sensor de drift:** cuando la distribución de la marcha se aleja del baseline, **dispara el reentrenamiento** de los modelos de clase E/H/W (en el worker). Los de clase L no necesitan disparo: se adaptan dato a dato.

---

## 4. Personalización

El baseline es **por paciente** (`patient_id` no nulo en el registry): se define en una **sesión de calibración** con marcha normal/estable del sujeto (§5), y todos los modelos personalizados se anclan a ese baseline. La evidencia sostiene la decisión (one-class **personalizado AUC≈0,97** vs. **~55 %** de un modelo global). **Personalización primero** es un principio del proyecto: se evitan modelos poblacionales salvo justificación.

---

## 5. Calibración / baseline por paciente

La calibración es, a la vez, el **entrenamiento inicial personalizado** y una **captura operativa** (ADR-005 rev c): el micro ya calcula sus features → *skew-free* por construcción.

- **Protocolo:** ~**100 zancadas** de marcha normal/estable del paciente. Las plantillas calculan features por-pie; la cintura fusiona bilateral. Se suben **features del micro + crudo continuo**.
- **Construcción del baseline:** ajuste inicial de **μ y Σ** (Mahalanobis) + baseline de los demás modelos; **umbral** = percentil (chi-cuadrado) de la calibración.
- **Calibraciones físicas (por hardware / por paciente):** curva **fuerza-resistencia por-FSR**; **alineación del frame del IMU** (estática "dejar quieto" + re-zero de giro en stance por FSR + alineación anatómica pie-plano — SPEC-04).
- **Recalibración:** disparada por **drift** (Mahalanobis) → reentrenamiento E/H/W en el worker.
- **Adaptación conmutable:** `sessions.adaptation_enabled` decide si la sesión adapta μ/Σ o corre **congelada** en la versión vigente. Congelada no produce versión nueva; adaptada produce **exactamente una**. Es lo que habilita la comparación pareada con y sin adaptación, y deja la trayectoria del baseline del paciente como serie consultable [ADR-043 rev].

**Diagrama:** `../calibracion_baseline.mermaid`.

---

## 6. Ciclo de vida de modelos

Nivel conceptual (dónde entrena, disparo, versionado). La **mecánica de despliegue** vive en otras vistas: **OTA A/B de pesos y firmware → Vista 2 §8**; **worker y persistencia → Vista 4 (maestro §10)**.

- **Dónde entrena:** clase **L en el micro** (dato a dato, nunca toca el worker); clases **E/H/W en el worker** = laptop en la mínima / nube en la máxima (jala datos de Supabase, reentrena, publica el artefacto y notifica al host, que despliega por OTA). **Supabase no entrena** (es el sistema de registro; sus Edge Functions sólo disparan jobs).
- **Disparo de reentrenamiento:** por **drift** (Mahalanobis), **schedule** (periódico) o **manual**; queda registrado en `retrain_jobs`.
- **Versionado / respaldo / rollback:** los modelos **E/H/W** se respaldan en la DB (fila en `models` + artefacto en object storage) con versión, métricas y linaje (`parent_version`), y la versión anterior queda como **last-known-good** para rollback. Los de clase **L** no viajan por OTA: su estado adaptado (μ, Σ) vive en **RAM durante la sesión**, se sube en el **check-in** y se versiona igual en `models` — una versión nueva por sesión adaptada, con `parent_version` = la de arranque. **La DB es la fuente de verdad en los dos casos**; el flash del micro es una copia de trabajo que se reescribe desde la DB al abrir cada sesión [ADR-043 rev; Vista 4 §4.1].

**Diagrama:** `../ciclo_de_vida_modelos.mermaid`.

---

## 7. Algoritmos (clase · placement · footprint · librería)

Resumen; **tabla detallada → satélite Parte C.**

| Algoritmo | Clase | Infiere | Reentrena | Librería (candidata) |
|---|---|---|---|---|
| **Mahalanobis** (+ sensor de drift) | **L** | cintura | cintura (EMA μ/Σ) | C propio / **CMSIS-DSP** (álgebra) |
| **Isolation Forest** | **E** | cintura (árboles en C) | worker | **scikit-learn** (train); tablas de splits on-device |
| **Autoencoder denso int8** | **E** | cintura (int8) | worker | **TF/Keras** + TFLite (int8) + **TFLite Micro** |
| **LSTM autoencoder** | **E/H/W** | según entre (profiling #11) | worker | TF/Keras + TFLite; ref. ejecutable en host |
| **One-Class SVM** *(candidato)* | **E/W** | worker (benchmark, no RT) | worker | scikit-learn |
| **GMM / z-score multivariado** *(candidato)* | **L/E** | cintura | cintura / worker | scikit-learn / CMSIS-DSP |
| **VAE** *(candidato)* | **E/H** | según entre | worker | TF/Keras + TFLite |

Footprints/latencias son **estimaciones del marco**, a **validar sobre firmware** en el backlog #11. La **sustitución OC-SVM→Mahalanobis** y los candidatos (GMM, VAE) se documentan en **ADR-029**; el registry es model-agnostic (ADR-011 rev), así que sumar candidatos = declarar su clase.

### 7.1 Estrategia progresiva de evaluación de algoritmos

Los algoritmos se evalúan **de a poco, escalando sólo si el anterior no alcanza** (pipeline del marco §6.3; economía de cómputo + personalización primero). Orden:

1. **Mahalanobis (L)** — baseline y primero a implementar: detector one-class en tiempo real + sensor de drift. Umbral por percentil (χ²) de la calibración.
2. **Isolation Forest (E)** — si Mahalanobis no separa anomalías con estructura no lineal simple.
3. **Autoencoder denso int8 (E)** — si hace falta capturar no-linealidades del vector de features; entra al micro por OTA.
4. **LSTM AE (E/H/W)** — si la dependencia temporal de la señal cruda aporta; ubicación por footprint (#11).

**Benchmark offline (worker):** **One-Class SVM** (mejor evidencia — Toth) y variantes (**GMM** multimodal, **VAE**) se corren en el worker para comparar contra el detector RT elegido, sin tiempo real. **Criterio para escalar:** subir de nivel sólo si el anterior no llega a la métrica objetivo. El detector RT ganador alimenta el feedback (`feedback_source`, ADR-027). Esta escalera alimenta el **roadmap de implementación**.

---

## ADRs relevantes
ADR-005 (features distribuidas + fases de captura), ADR-018 (paridad / anti skew), ADR-021 (catálogo declarativo + set activo), ADR-023 (set activo 2-FSR), ADR-011 rev (taxonomía/ruteo model-agnostic), ADR-013 (inferencia RT en hub/host), ADR-009 (backend de reentrenamiento), ADR-022 (framework de entrenamiento + cuantización int8), ADR-017 (módulo IMU / calibración), **ADR-042** (crudo post-AHRS: qué recibe el worker), **ADR-043 rev** (ciclo de vida, adaptación conmutable, autoridad del modelo), **ADR-053** (sobre de los artefactos), **ADR-054** (catálogo en TOML), **ADR-055** (crudo en Parquet: qué lee el worker).

## Stack (resumen; detalle en `../stack_tecnologico.md`)
numpy, scipy, **scikit-learn** (Isolation Forest, ajuste Mahalanobis), **TensorFlow/Keras** (autoencoders) + conversor **TFLite/LiteRT** (PTQ int8, representative dataset — ADR-022), pandas. *(`imufusion` ya no hace falta: el crudo llega post-AHRS y el worker no re-procesa IMU — ADR-042.)* El runtime on-device es de la Vista 2 (TFLite Micro + CMSIS-NN / CMSIS-DSP).

## Diagramas de esta vista
- `../ciclo_de_vida_modelos.mermaid` — entrenamiento → registro → OTA → inferencia → drift.
- `../calibracion_baseline.mermaid` — protocolo de calibración/baseline por paciente (**nuevo**).

## Pendiente de definir / investigar (backlog)
- **#11 — Validación de footprint/latencia** (requiere firmware; ver satélite Parte D): presupuestos de RAM/flash del RP2350 y latencias por etapa; confirma clase del LSTM AE (E/H/W) y el runtime `pico-tflmicro` en RP2350.
- **#12 — Selección de features** (data-driven; requiere dataset capturado): qué se **prende** del catálogo según el análisis (LASSO/SBS/Boruta → 15-25 features).
- **CP-20 — Columnas generadas** sobre `features` (ADR-031): qué features se materializan depende de congelar el `feature_set_version` (#12) y del dashboard (diferido). *(CP-05 —el esquema de `feature_vectors`— quedó **resuelta** por ADR-031: `jsonb`; ver Vista 4 §1.2.)*
