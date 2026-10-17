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
| 39 | Single support time *(agregada 2026-07-21, ADR-029)* | Δt en que **sólo un pie** contacta (= swing time contralateral); su asimetría es informativa | eventos IC/TO de **ambos** pies | **cintura** | 1 |
| 43 | **Push-off time ratio** *(agregada 2026-08-18, ADR-038)* | `(t_TO − t_MS)/(t_TO − t_IC)` — fracción del apoyo dedicada a la **propulsión**. Adimensional (comparable entre velocidades); su asimetría L/R es el candidato fuerte | eventos **IC/TO/MS** | plantilla | 1 |

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

*(Instanciación del bloque C — **ADR-038**: **#12, #13 y #14 se instancian por FSR × sub-fase del apoyo** (carga `[IC,MS]` / propulsión `[MS,TO]`, SPEC-02) → con 2 FSR, cada una da 4 instancias; con 4 FSR, 8. **#15** (contact time por región) no se parte; **#16** (loading rate) queda con **dominio explícito** en la sub-fase de carga; **#17** (time-to-peak) sigue medido desde IC. Relevante para el conteo real del vector y para la modularidad — la instanciación no crea entradas nuevas de catálogo.)*

### Bloque D — Simetría / ratio *(diferencial de ACV)*

| # | Feature | Cálculo | Entrada/Dependencia | Dónde | Fase |
|---|---|---|---|---|---|
| 18 | Ratio medial/lateral de peak force *(DIFERIDO — 2-FSR OFF; ADR-023)* | FSR medial vs lateral del **mismo** pie | FSR (posición medial/lateral) | plantilla | 2 |
| 19 | Pressure progression ratio | distribución antero/posterior (**espacial**: qué sensor carga) | FSR (posición ant/post) | plantilla | 2 |
| 44 | **Propulsive impulse ratio** *(agregada 2026-08-18, ADR-038)* | `PTI[MS,TO] / PTI[IC,TO]` sobre `F_total` — qué fracción del impulso total ocurre en la fase propulsiva (**temporal**: cuándo carga). Complementa a #19, no la duplica | FSR + evento **MS** | plantilla | 2 |
| 20 | **Symmetry Index L/R** | \|X_L−X_R\| / (0.5·(X_L+X_R)) sobre feature por-pie | features por-pie de **ambos** pies | **cintura** | 2 |
| 21 | Force Symmetry Index (consecutivo) | zancada actual vs anterior del mismo pie | buffer per-pie | plantilla | 2 |
| 40 | **Symmetry Angle (SA)** *(agregada 2026-07-21, ADR-029)* | (45°−arctan(X_L/X_R))/90°·100 sobre una feature por-pie; acotada [−100,100], mejor comportamiento estadístico que el SI (#20) | features por-pie de **ambos** pies | **cintura** | 2 |

### Bloque E — COP medio-lateral 1D *(top para riesgo de caída)* — **DIFERIDO (set activo 2-FSR OFF): requiere FSR medial-lateral; ADR-023**

| # | Feature | Cálculo | Entrada/Dependencia | Dónde | Fase |
|---|---|---|---|---|---|
| 22 | COP_ML | Σ(Fᵢ·xᵢ)/Σ(Fᵢ) | FSR + **coordenadas xᵢ** (config) | plantilla | 3 |
| 23 | COP_ML range | max−min en la zancada | feature 22 | plantilla | 3 |
| 24 | COP_ML velocity | d/dt de 22 | feature 22 | plantilla | 3 |
| 25 | Zero-crossings de COP_ML velocity | conteo de cruces por cero | feature 24 | plantilla | 3 |
| 42 | Mean peak sway density de COP_ML *(agregada 2026-07-21, ADR-029; **DIFERIDA** con el bloque E — requiere FSR M/L)* | muestras consecutivas del COP dentro de una ventana estrecha (~3 mm); **top feature de Herbers** | feature 22 (COP_ML) | plantilla | 3 |

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
| 41 | Average zero-crossings de la aceleración *(agregada 2026-07-21, ADR-029)* | conteo medio de cruces por cero de la accel en la ventana (distinto de los zero-crossings del COP, #25) | ventana de accel | plantilla | 4 |

### Bloque I — Tronco (IMU de cintura) — **DIFERIDO (OFF en el set activo; ADR-040)**

El marco teórico daba por perdidas las features de tronco/lower-back de Brasiliano (incl. el **IHR ML**, feature top-1 del set de 3 que llega a 90 %). **El IMU de la cintura (~L4-L5) las recupera.** Corren en la **cintura** (core 1, junto con la fusión bilateral).

> **Estado: definidas, ubicadas y diferidas (ADR-040).** El bloque queda **OFF en el set activo**: se prende con un `feature_set_version` nuevo, sin reescritura. No es una limitación de hardware —la cintura ya tiene su IMU y los eventos IC— sino una decisión de **alcance**: el IHR carga tres decisiones metodológicas (N de armónicos, método de remuestreo, la velocidad como confusor) que se resuelven mejor mirando espectros reales. **SPEC-10** deja todas las recomendaciones escritas, y el **apéndice conceptual de ADR-040** explica el mecanismo completo.

| # | Feature | Cálculo | Entrada/Dependencia | Dónde | Fase |
|---|---|---|---|---|---|
| 45 | **Improved Harmonic Ratio ML** *(ex-I1; renumerada 2026-08-18, ADR-040)* | `Σ P(intrínsecos) / Σ P(intrínsecos+extrínsecos)` sobre el espectro de la accel ML del tronco, por zancada. **En ML los intrínsecos son los armónicos impares** (en vertical y AP, los pares) — la asignación es fija, no depende del paciente. Ventana = una zancada remuestreada a largo fijo → el bin *k* **es** el armónico *k* | IMU cintura + **eventos IC** (segmentación de zancada) + FFT | cintura | exploratoria |
| 46 | **RMS de accel del tronco** (AP/ML/V) *(ex-I2)* | RMS por eje sobre la zancada | IMU cintura | cintura | exploratoria |
| 47 | **LDLJ del tronco** *(ex-I3)* | LDLJ sobre accel del tronco, **zancada completa** (a diferencia del bloque G, que va sólo en swing: en el tronco la cadena cinemática ya filtra los impactos) | IMU cintura | cintura | exploratoria |

**Nota (conteo):** el catálogo nominal es de **47 features (bloques A–I)** — 38 originales (A–H) + 3 de tronco (I, renumeradas #45-47 por ADR-040) + **4 agregadas el 2026-07-21 (ADR-029)** (#39 single support, #40 symmetry angle, #41 avg zero-crossings, #42 sway density —diferida—) + **2 agregadas el 2026-08-18 (ADR-038)**: #43 push-off time ratio, #44 propulsive impulse ratio. Con las instancias por-FSR **× sub-fase** (bloque C) y por-eje (tronco), el vector real es mayor. La **feature selection** (LASSO/SBS/Boruta) reduce al sweet spot **15-25** — lo que refuerza la necesidad de modularidad (Parte B).

> **Evento de segmentación — mid-stance (MS).** Tercer evento además de IC/TO (ADR-029 lo propuso; **ADR-038 lo adopta y lo especifica**). Detección en **SPEC-01** (cruce de carga retropié→antepié, `F_ante ≥ F_post`, confirmado por pie-plano del IMU); parte el apoyo en **carga `[IC,MS]`** y **propulsión `[MS,TO]`** en **SPEC-02**. **No es una feature**: es un evento del que dependen #43, #44 y la instanciación por sub-fase del bloque C. Activo con el hardware de **2 FSR** (ADR-023). Si el paciente no transfiere carga, el evento se emite con flag `no_crossover` — que es señal de anomalía, no error.

---

## Parte B — Módulo de features y modularidad (CP-12)

**Objetivo:** tener todas las features **disponibles** pero poder **prenderlas/apagarlas** según el análisis de datos, sin reescribir firmware ni worker, manteniendo paridad PC↔micro.

**Mecanismo propuesto — catálogo declarativo + set activo versionado:**

1. **Catálogo de features** (definición única, en `src/firmware/shared/`): cada feature declara `{ id, bloque, scope (foot|bilateral|trunk), inputs, fórmula/ref, params }`. Es la fuente de verdad que **implementan tanto el firmware (C) como el worker (Python)**.
2. **Set activo** = lista de `id` habilitados + `feature_set_version`. Prender/apagar una feature es **cambiar el set activo** (config), no el código. El set puede versionarse y, eventualmente, actualizarse por OTA/config sin reflashear.
3. **Dependencias declaradas:** cada feature lista sus prerequisitos (IC/TO, ZUPT, coords FSR, buffer N, FFT). Activar una feature activa su cadena de cómputo; desactivarlas todas apaga el cómputo asociado (ahorra CPU/energía).
4. **Contrato de paridad (ADR-018 + ADR-021, anti *train/serve skew*):** el invariante "definición única" se **garantiza**, no se asume. (a) **Tests de paridad (golden vectors)** en CI: entrada→salida esperada corrida en C (firmware) y Python (worker), match con **tolerancia por-feature**, gate atado a `feature_set_version`. (b) **Los modelos desplegables se entrenan con las features del micro**, guardadas en la **captura operativa** (post-congelamiento; ADR-005 rev c) → skew-free por construcción; la paridad se valida sobre ese set operativo nuevo, **no** sobre el crudo exploratorio. La re-extracción off-device (fase exploratoria) es para prototipar/seleccionar features, que deben pasar los tests de paridad antes de promoverse. (c) **Disciplina numérica:** cuidar fixed-point/int8 vs float y transcendentales (FFT/entropía, LDLJ).
5. **En la DB:** `feature_vectors` guarda el vector + `feature_set_version` (ya está en el esquema); el set activo por sesión/paciente se registra en metadata.

> **Set activo actual (ADR-023 + ADR-040).** Está **OFF**: **(a) por hardware** — las features de fuerza **medial-lateral**: bloque E completo (#22-25 COP_ML + #42 sway density) y #18 (ratio M/L), que se prenden al sumar los FSR medial/lateral; **(b) por alcance** — el **bloque I completo (#45-47, tronco)**, que se prende cuando se resuelvan las decisiones metodológicas de SPEC-10. En ambos casos quedan **definidas** en el catálogo y se activan con un `feature_set_version` nuevo, **sin reescritura**. El resto funciona con punta+talón: bloque C (instanciado por FSR × sub-fase, ADR-038) y #19. Los primeros modelos se entrenan con este set activo.
>
> **Principio (ADR-040).** El catálogo es una **biblioteca de features disponibles**, no una lista de obligaciones. El **set activo** es lo que efectivamente se calcula, y no tiene por qué ser todo desde el día uno.

**Resuelto (ADR-021):** el catálogo es un **archivo de datos declarativo** en `src/firmware/shared/` —**TOML** (`features.toml`), con una tabla de C generada para el firmware (ADR-054)— (metadata: id/bloque/scope/inputs/deps/params/tolerancia/activo + `feature_set_version`); **dos implementaciones** (C firmware / Python worker) reconciliadas por **tests de paridad** (codegen y C-único-bindeado **descartados**); el set activo se distribuye por **config/OTA**. La *selección* data-driven de qué features se prenden sigue en el backlog (#12).

---

## Parte C — Algoritmos: clase, placement, footprint, librería

| Algoritmo | Clase | Infiere | Reentrena | Entrada | Footprint / Latencia (estimación; valida #11) | Librería (candidata) |
|---|---|---|---|---|---|---|
| **Mahalanobis** (+ **sensor de drift**) | **L** | cintura | cintura (EMA de μ, Σ) | vector de features/zancada | KB; **<100 µs**; umbral = percentil 99 de calibración | C propio / **CMSIS-DSP** (álgebra) |
| **Isolation Forest** | **E** | cintura (árboles en C) | worker (periódico, buffer circular) | vector de features | 50-100 árboles; decenas de KB; cientos de µs | **scikit-learn** (train); inferencia on-device (tablas de splits) |
| **Autoencoder denso** | **E** | cintura (int8) | worker | vector de features (~25) | arq. 25-12-6-12-25; **10-50 KB**; ~ms | **TF/Keras** + **TFLite/LiteRT** (PTQ int8) + **TFLite Micro** (ADR-022) |
| **LSTM autoencoder** | **E/H/W** | según entre (#11) | worker | señal cruda ~100×8 canales | mayor footprint; **decenas de ms** | TF/Keras + TFLite/LiteRT; ref. ejecutable en host |
| **One-Class SVM** *(candidato, ADR-029)* | **E/W** | worker (benchmark; **no** RT) | worker | vector de features | kernel RBF; costoso en int8 | **scikit-learn** |
| **GMM / z-score multivariado** *(candidato, ADR-029)* | **L/E** | cintura | cintura / worker | vector de features | KB; generaliza Mahalanobis (multimodal) | scikit-learn / CMSIS-DSP |
| **VAE (autoencoder variacional)** *(candidato, ADR-029)* | **E/H** | según entre | worker | vector de features / crudo | similar al AE denso + muestreo latente | TF/Keras + TFLite |

**Notas:**
- **Mahalanobis** es el caballo de batalla en tiempo real (clase L) **y** el disparador de reentrenamiento (drift). Es lo primero a implementar.
- **Autoencoder denso** es el caso E canónico (int8 al micro por OTA).
- **Isolation Forest** es **clase E**: infiere **en la cintura** (recorrido de árboles como tablas de splits), reentrena en el worker. El **LSTM AE** es **E/H/W** según dónde entre (micro→host→offline; profiling #11). La clase **W** queda para lo estrictamente no-tiempo-real (análisis/re-scoring). *(ADR-011 rev 2026-07-19.)*
- El anteproyecto **§6** mencionaba **SST-AD, SVR, Random Forest**: **descartados por ADR-030** al cerrar CP-11. Se adopta la lista del **§4.3** (coincide con este stack) más los candidatos de ADR-029. *SST-AD no está definido en ninguna fuente del corpus; SVR/RF eran referencias bibliográficas, no elecciones.* El registry sigue siendo model-agnostic: sumar un candidato es declarar su clase.
- **Sustitución OC-SVM → Mahalanobis (ADR-029):** el **One-Class SVM personalizado** es el que ancla la evidencia (Toth, AUC 0,967, "exactamente el pipeline"), pero el **detector one-class en tiempo real es Mahalanobis** por costo/latencia edge (<100 µs, auto-adaptación dato a dato). El OC-SVM queda como **candidato E/W = benchmark offline** (worker, no RT). **GMM/z-score** (multimodal) y **VAE** (rama AE) entran como candidatos declarables de baja prioridad; **CNN+Transformer** (EdgeSense) se descarta por footprint.
- **Fuera del stack de detección (ADR-029):** **Random Survival Forest / COX / SHAP** (pronóstico de recuperación con variables clínicas) son otra tarea → módulo aparte a futuro; **LASSO** es **selección de features** → backlog #12.
- **Calibración/baseline (Vista 3):** ~100 zancadas de marcha normal → ajuste inicial de μ/Σ (Mahalanobis) y del baseline de los demás. Es el **entrenamiento inicial personalizado** y, a la vez, una **captura operativa** (el micro ya calcula sus features → skew-free; ADR-005 rev c).

---

## Parte D — Backlog de investigación (ordenado)

Backlog ordenado por dependencia. **#1–#10 resueltos** (cada uno con su ADR/SPEC). **#11 y #12 quedan para la fase de implementación:** #11 valida sobre **firmware ya escrito** y #12 sobre un **dataset ya capturado** — no son "specificables" sin código/datos.

1. **Detección de IC/TO** *(resuelto → ADR-015 / SPEC-01; CP-03)* — fusión umbral FSR + confirmación IMU, en la plantilla (per-pie). Prerequisito del bloque A y de la segmentación.
2. **Segmentación de fases** (stance/swing) *(resuelto → SPEC-02)* — deriva de IC/TO; alimenta LDLJ (swing), mean ang. vel. (swing) y ZUPT (stance).
3. **Stride length / ZUPT** *(resuelto → ADR-016 / SPEC-03)* — doble integración + ZUPT por stance del FSR; ZUPT simple como base, EKF/MSDI futuro.
4. **Buffer/ventana de zancadas** (≥10) *(resuelto → SPEC-05)* — ring buffer per-pie + bilateral; CoV incremental (Welford); flag de warm-up.
5. **Orientación (fusión IMU)** *(resuelto → ADR-017 / SPEC-04)* — Madgwick vía **Fusion** (C) / `imufusion` (Python); desbloquea ZUPT y el bloque F.
6. **COP_ML** *(resuelto → SPEC-06; **diferido** en el set 2-FSR por ADR-023)* — coordenadas de FSR (config) + línea media/ancho (calibración); requiere FSR medial-lateral.
7. **FFT/DSP on-device** *(resuelto → ADR-019 / SPEC-07: **CMSIS-DSP** float32, `arm_rfft_fast_f32`, ventana Hann N=256)* — bloque H (spectral entropy, dominant freq, power en bandas) + filtros/decimación FIR + álgebra (Mahalanobis).
8. **Runtime de inferencia int8** *(resuelto → ADR-020 / SPEC-08: **TFLite Micro + CMSIS-NN** para las NN int8; Mahalanobis en CMSIS-DSP; Isolation Forest por árboles en C)* — ejecución de los modelos on-device.
9. **Catálogo de features compartido** (Parte B) *(resuelto → ADR-021: catálogo declarativo + set activo + dos implementaciones con tests de paridad; codegen/C-único descartados; CP-12)*.
10. **Frameworks de entrenamiento** *(resuelto → ADR-022: **TensorFlow/Keras** + **PTQ int8** con representative dataset, QAT fallback)* — pipeline de cuantización a int8 hacia el runtime del #8.
11. **Validación de footprint/latencia** *(requiere firmware — fase de implementación)* — presupuestos de **RAM/flash del RP2350** y **latencias por etapa** (Mahalanobis <100 µs; AE denso ~ms; inferencia por-zancada holgada dentro del presupuesto de ~1 Hz de decisiones). **El feedback es terminal/event-locked (ADR-027), no un lazo cerrado <50 ms** → el criterio no es una latencia de bucle sino que la decisión por-zancada entre con margen. Confirma además: reparto de cores de la plantilla (ADR-024 rev), rate del IMU de cintura 100 vs 50 Hz (ADR-026), clase del LSTM AE (E/H/W) y viabilidad de `pico-tflmicro` en RP2350 (ADR-020).
12. **Selección de features** *(data-driven; requiere dataset capturado)* — qué se **prende** del catálogo según el análisis (LASSO/SBS/Boruta → 15-25 features).

Cada ítem se resuelve con su mini-investigación → decisión → ADR/SPEC → se refleja en la vista correspondiente y en el `stack_tecnologico.md`.
