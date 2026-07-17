# Vista 3 — Análisis de definición: Features y Algoritmos

> **Propósito.** Puente entre la bibliografía/marco teórico y la implementación. Enumera **qué hay que construir** (catálogo de features + algoritmos) y, a partir de eso, **qué hay que investigar y decidir** antes de construir. Es un documento de trabajo que alimenta el módulo de features (Vista 2) y el stack de ML.
>
> **Fuentes:** `docs/investigacion/features_anomaly_detection_stroke.md`, marco teórico (`docs/marco_teorico/…`), anteproyecto §4.
>
> **Regla de layering:** acá se **define** (fórmula, entrada, placement, prioridad); la **ejecución** vive en Vista 2 (firmware C) y en el worker (Python), desde una **única definición compartida** versionada por `feature_set_version`.

---

## Parte A — Catálogo de features

Convención de columnas: **Cálculo** (qué operación), **Entrada/Dependencia** (qué necesita), **Dónde** (plantilla = per-pie / cintura = bilateral), **Fase** (estrategia progresiva del marco: 1 mínimo → 4 refinamiento).

Placement por defecto: casi todo es **per-pie (plantilla)**; lo **bilateral** (comparar ambos pies) va en la **cintura**. El *double support* es bilateral aunque pertenezca al bloque A.

### Bloque A — Espacio-temporales *(prioridad máxima; evidencia más fuerte)*

| # | Feature | Cálculo | Entrada/Dependencia | Dónde | Fase |
|---|---|---|---|---|---|
| 1 | Stride time | Δt entre IC consecutivos del mismo pie | detección **IC** | plantilla | 1 |
| 2 | Stance time | Δt IC→TO | eventos **IC/TO** | plantilla | 1 |
| 3 | Swing time | Δt TO→IC | eventos IC/TO | plantilla | 1 |
| 4 | **Double support** | solapamiento de [IC,TO] de ambos pies | eventos de **ambos** pies (alineados por sync) | **cintura** | 1 |
| 5 | Cadence | 60/stride_time | eventos IC | plantilla | 1 |
| 6 | Stride length | integración doble de accel + **ZUPT** (reset en stance) | IMU accel + stance por **FSR** | plantilla | 1 |
| 7 | Stride speed | stride_length / stride_time | features 6 y 1 | plantilla | 1 |

### Bloque B — Variabilidad *(prioridad máxima)*

| # | Feature | Cálculo | Entrada/Dependencia | Dónde | Fase |
|---|---|---|---|---|---|
| 8-11 | CoV de stride / stance / swing / cadence | std/mean sobre **ventana ≥10 zancadas** | **buffer de N zancadas** de A | plantilla | 1 |

### Bloque C — Fuerza / FSR *(prioritario para ACV; push-off)*

| # | Feature | Cálculo | Entrada/Dependencia | Dónde | Fase |
|---|---|---|---|---|---|
| 12 | Peak force (por FSR) | max de la fuerza en la zancada | FSR | plantilla | 2 |
| 13 | Mean pressure (por FSR) | media en la zancada | FSR | plantilla | 2 |
| 14 | Pressure-Time Integral (por FSR) | ∫F dt | FSR | plantilla | 2 |
| 15 | Contact time (por región) | tiempo sobre umbral | FSR + umbral (calibración) | plantilla | 2 |
| 16 | Loading rate | pendiente máx de la curva de fuerza | FSR | plantilla | 2 |
| 17 | Time-to-peak | Δt IC→peak force | FSR + evento **IC** | plantilla | 2 |

*(Los del bloque C se instancian **por FSR** → con 3 FSR, el vector crece ×3. Relevante para el conteo real de features y para la modularidad.)*

### Bloque D — Simetría / ratio *(diferencial de ACV)*

| # | Feature | Cálculo | Entrada/Dependencia | Dónde | Fase |
|---|---|---|---|---|---|
| 18 | Ratio medial/lateral de peak force | FSR medial vs lateral del **mismo** pie | FSR (posición medial/lateral) | plantilla | 2 |
| 19 | Pressure progression ratio | distribución antero/posterior | FSR (posición ant/post) | plantilla | 2 |
| 20 | **Symmetry Index L/R** | \|X_L−X_R\| / (0.5·(X_L+X_R)) sobre feature por-pie | features por-pie de **ambos** pies | **cintura** | 2 |
| 21 | Force Symmetry Index (consecutivo) | zancada actual vs anterior del mismo pie | buffer per-pie | plantilla | 2 |

### Bloque E — COP medio-lateral 1D *(top para riesgo de caída)*

| # | Feature | Cálculo | Entrada/Dependencia | Dónde | Fase |
|---|---|---|---|---|---|
| 22 | COP_ML | Σ(Fᵢ·xᵢ)/Σ(Fᵢ) | FSR + **coordenadas xᵢ** (config) | plantilla | 3 |
| 23 | COP_ML range | max−min en la zancada | feature 22 | plantilla | 3 |
| 24 | COP_ML velocity | d/dt de 22 | feature 22 | plantilla | 3 |
| 25 | Zero-crossings de COP_ML velocity | conteo de cruces por cero | feature 24 | plantilla | 3 |

### Bloque F — IMU cinemáticos *(recomendados)*

| # | Feature | Cálculo | Entrada/Dependencia | Dónde | Fase |
|---|---|---|---|---|---|
| 26 | ROM de pitch | max−min pitch en la zancada | **orientación** (fusión IMU) | plantilla | 3 |
| 27 | ROM de roll | max−min roll (inversión/eversión) | orientación | plantilla | 3 |
| 28 | Foot pitch en heel-strike | pitch en el instante IC | orientación + **IC** | plantilla | 3 |
| 29 | Foot pitch en toe-off | pitch en el instante TO | orientación + **TO** | plantilla | 3 |
| 30 | Peak vertical accel en TO | max accel vertical cerca de TO | IMU accel + evento | plantilla | 3 |
| 31 | Mean angular velocity en swing | media \|ω\| en fase swing | IMU gyro + **fase swing** | plantilla | 3 |

### Bloque G — Smoothness / LDLJ *(top-9 Brasiliano; sólo en swing)*

| # | Feature | Cálculo | Entrada/Dependencia | Dónde | Fase |
|---|---|---|---|---|---|
| 32 | LDLJ de accel AP | −ln((t2−t1)·max‖a‖·∫\|a′\|²dt) **sólo en swing** | IMU accel + segmentación swing | plantilla | 3 |
| 33 | LDLJ de accel ML | idem en eje ML | idem | plantilla | 3 |
| 34 | LDLJ de velocidad angular | idem sobre ω (mejor SNR) | IMU gyro + swing | plantilla | 3 |

### Bloque H — Frecuencia / entropía *(opcionales; más caros)*

| # | Feature | Cálculo | Entrada/Dependencia | Dónde | Fase |
|---|---|---|---|---|---|
| 35 | Spectral entropy | entropía del espectro | **FFT** de ventana de accel | plantilla | 4 |
| 36 | Sample entropy | SampEn de ω | ventana (costo O(n²)) | plantilla | 4 |
| 37 | Dominant frequency | pico del espectro | **FFT** | plantilla | 4 |
| 38 | Power en bandas | energía en <0.5 / 0.5-2 / >2 Hz | **FFT/PSD** | plantilla | 4 |

### Bloque I — Tronco (IMU de cintura) *(oportunidad nueva; habilitada por la cintura)*

El marco teórico daba por perdidas las features de tronco/lower-back de Brasiliano (incl. el **IHR ML**, feature top-1 del set de 3 que llega a 90 %). **El IMU de la cintura (~L4-L5) las recupera.** Corren en la **cintura**.

| # | Feature | Cálculo | Entrada/Dependencia | Dónde | Fase |
|---|---|---|---|---|---|
| I1 | Improved Harmonic Ratio ML | armónicos pares/impares de accel ML del tronco | IMU cintura + segmentación de zancada | cintura | exploratoria |
| I2 | RMS de accel del tronco (AP/ML/V) | RMS por eje sobre la zancada | IMU cintura | cintura | exploratoria |
| I3 | LDLJ del tronco | LDLJ sobre accel del tronco | IMU cintura | cintura | exploratoria |

**Nota:** el conteo nominal del marco es ~41 features; con las instancias por-FSR (bloque C) y las de tronco, el vector real es mayor. La **feature selection** (LASSO/SBS/Boruta) reduce al sweet spot **15-25** — lo que refuerza la necesidad de modularidad (Parte B).

---

## Parte B — Módulo de features y modularidad (CP-12)

**Objetivo:** tener todas las features **disponibles** pero poder **prenderlas/apagarlas** según el análisis de datos, sin reescribir firmware ni worker, manteniendo paridad PC↔micro.

**Mecanismo propuesto — catálogo declarativo + set activo versionado:**

1. **Catálogo de features** (definición única, en `src/firmware/shared/`): cada feature declara `{ id, bloque, scope (foot|bilateral|trunk), inputs, fórmula/ref, params }`. Es la fuente de verdad que **implementan tanto el firmware (C) como el worker (Python)**.
2. **Set activo** = lista de `id` habilitados + `feature_set_version`. Prender/apagar una feature es **cambiar el set activo** (config), no el código. El set puede versionarse y, eventualmente, actualizarse por OTA/config sin reflashear.
3. **Dependencias declaradas:** cada feature lista sus prerequisitos (IC/TO, ZUPT, coords FSR, buffer N, FFT). Activar una feature activa su cadena de cómputo; desactivarlas todas apaga el cómputo asociado (ahorra CPU/energía).
4. **Contrato de paridad:** un set de **vectores de prueba** (entrada→salida esperada) que corren en C y en Python para garantizar que ambos dan el mismo valor por `feature_set_version`.
5. **En la DB:** `feature_vectors` guarda el vector + `feature_set_version` (ya está en el esquema); el set activo por sesión/paciente se registra en metadata.

**A investigar/decidir:** formato del catálogo (¿tabla/JSON/código generado?), cómo se genera el código C y Python desde una sola fuente (codegen vs. dos implementaciones + tests de paridad), y cómo se distribuye el set activo (config estática vs. OTA).

---

## Parte C — Algoritmos: clase, placement, footprint, librería

| Algoritmo | Clase | Infiere | Reentrena | Entrada | Footprint / Latencia (marco) | Librería (candidata) |
|---|---|---|---|---|---|---|
| **Mahalanobis** (+ **sensor de drift**) | **L** | cintura | cintura (EMA de μ, Σ) | vector de features/zancada | KB; **<100 µs**; umbral = percentil 99 de calibración | C propio / **CMSIS-DSP** (álgebra) |
| **Isolation Forest** | **W** | worker (offline) | worker (periódico, buffer circular) | vector de features | 50-100 árboles; decenas de KB; cientos de µs | **scikit-learn** (train); inferencia offline |
| **Autoencoder denso** | **E** | cintura (int8) | worker | vector de features (~25) | arq. 25-12-6-12-25; **10-50 KB**; ~ms | **PyTorch/TF** + **TFLite** (int8) + **TFLite Micro** |
| **LSTM autoencoder** | **W** (o **H**) | worker / host | worker | señal cruda ~100×8 canales | mayor footprint; **decenas de ms** | PyTorch/TF + TFLite; ref. ejecutable en host |

**Notas:**
- **Mahalanobis** es el caballo de batalla en tiempo real (clase L) **y** el disparador de reentrenamiento (drift). Es lo primero a implementar.
- **Autoencoder denso** es el caso E canónico (int8 al micro por OTA).
- **Isolation Forest** y **LSTM AE** quedan **worker/offline** (clase W); el LSTM podría subir a **host (H)** si se lo quiere en tiempo real y no entra en la cintura.
- El anteproyecto §6 menciona además **SST-AD, SVR, Random Forest**; el **registry es model-agnostic**, así que entran como candidatos declarando su clase. Conviene unificar la lista (CP-11).
- **Calibración/baseline (Vista 3):** ~100 zancadas de marcha normal → ajuste inicial de μ/Σ (Mahalanobis) y del baseline de los demás. Es el **entrenamiento inicial personalizado**.

---

## Parte D — Backlog de investigación (ordenado)

Lo que hay que investigar/decidir **antes** de implementar, en orden de dependencia:

1. **Detección de IC/TO** *(CP-03)* — método (umbral FSR + confirmación IMU, ventana de aceptación) y **dónde corre** (plantilla vs cintura). Es prerequisito de casi todo el bloque A y de la segmentación.
2. **Segmentación de fases** (stance/swing) desde IC/TO — necesaria para LDLJ (swing), mean ang. vel. (swing) y ZUPT (stance).
3. **Stride length / ZUPT** — variante (ZUPT simple vs MSDI / MFD-GED) y su costo.
4. **Buffer/ventana de zancadas** (≥10) — estructura y memoria para variabilidad (B) y símbolos consecutivos (21).
5. **Orientación (fusión IMU)** — cómo se obtiene pitch/roll (complementario/Madgwick/Mahony) para el bloque F.
6. **COP_ML** — parametrización de **coordenadas de FSR** (config) y su relación con la **modularidad** (CP-08/CP-12).
7. **FFT/DSP on-device** — para el bloque H (spectral entropy, dominant freq, PSD) y para la decimación; **CMSIS-DSP** vs propio.
8. **Runtime de inferencia int8** — **TFLite Micro** vs kernels propios; cómo corren Mahalanobis (C/CMSIS) e Isolation Forest.
9. **Catálogo de features compartido** (Parte B) — codegen vs. dos implementaciones + tests de paridad.
10. **Frameworks de entrenamiento** — PyTorch vs TensorFlow; pipeline de cuantización a int8.
11. **Validación de footprint/latencia** contra los objetivos del marco (feedback <50 ms, Mahalanobis <100 µs, AE ~ms).
12. **Selección de features** (data-driven, fase posterior) — qué se **prende** del catálogo según el análisis.

Cada ítem se resuelve con su mini-investigación → decisión → ADR → se refleja en la vista correspondiente y en el `stack_tecnologico.md`.
