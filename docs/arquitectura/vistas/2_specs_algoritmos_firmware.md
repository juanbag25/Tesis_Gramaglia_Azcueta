# Vista 2 · Firmware — Colección de specs de algoritmos

> *(Este NO es el documento de la vista —ese es `2_vista_firmware.md`, el overview—. Este es la colección de guías de implementación que crece con el backlog.)*

> **Qué es esto.** Colección de **specs concisas de algoritmo** que sirven de **guía de implementación** para el agente/persona que escribe el firmware. Cada spec fija las **decisiones de dominio** (definición, señales, parámetros, robustez, salida) + referencias; **no** es código. La **mecánica de codificación** (cómo implementar un detector de picos, un filtro, etc.) queda a cargo de quien implementa.
>
> **Regla:** cada ítem del backlog de investigación (ver `3_analisis_features_y_algoritmos.md` §D) que produzca un algoritmo de firmware, deja aquí su spec + su ADR en la bitácora.

---

## SPEC-01 — Detección de eventos IC / TO / MS (por pie)

**Decisión:** ADR-015 (IC/TO) · **ADR-038 (MS)**. **Placement:** plantilla (per-pie). **Estado:** definido (a implementar).

**Objetivo.** Detectar en tiempo real, por pie, el **Initial Contact (IC)**, el **Toe-Off (TO)** y el **Mid-Stance (MS)**, robusto a marcha patológica (drop foot, apoyo de antepié/plano, ausencia de transferencia de carga). Es la **función núcleo** del firmware: su salida alimenta las features espacio-temporales, la segmentación de fases (stance/swing y sub-fases del apoyo), el ZUPT, el refinamiento de sync y el timing del feedback.

**Entradas.** FSR (fuerza calibrada, 100 Hz) + IMU (gyro + accel, 100 Hz), todos con `timestamp` (µs) + `seq`. Hoy hay **2 FSR: punta (`F_ante`) y talón (`F_post`)** — ADR-023; el número es configurable (CP-08). Se definen `F_total = Σ FSRᵢ`, y `F_ante` / `F_post` como la suma de los FSR asignados a antepié y retropié en el catálogo (con 2 FSR, uno cada uno).

**Definición robusta (clave para ACV).**
- **IC = onset de carga:** `F_total` cruza **hacia arriba** el umbral `F_on` — el primer instante de carga, **sin importar la región** (no "talón primero"). Cubre apoyo de antepié/plano y *drop foot*.
- **TO = fin de carga:** `F_total` cruza **hacia abajo** el umbral `F_off` y se mantiene por debajo.
- **MS = transferencia de carga retropié→antepié:** primer instante dentro de `[IC, TO]` en que `F_ante ≥ F_post` (cruce de las dos curvas). Es una definición **de carga**, no cinemática: marca el momento funcional en que el peso pasa al antepié, que es el que importa para el déficit de propulsión (ver *Nota sobre la definición*).

**Robustez / anti-falsos.**
- **Histéresis:** `F_off < F_on` (evita rebotes alrededor del umbral). Para MS, banda `±h_ms` alrededor del cruce, para no disparar con oscilaciones cerca de la igualdad.
- **Refractario:** tiempo mínimo entre eventos del mismo pie (`t_ref`, p. ej. ~200 ms) para no doble-disparar. MS se emite **una sola vez por apoyo** (el primer cruce válido).
- **Confirmación IMU (ventana):** al detectar el cruce de FSR, buscar en `±W` (p. ej. ±50 ms) la **firma esperada en la velocidad angular sagital** del pie (pico característico en IC/TO; **cruce por cero / mínimo de |ω| — pie plano —** en MS). Si coincide → evento de **alta confianza**; si no → se **emite igual** con **baja confianza** (no descartar: en patología conviene no perder eventos).
- **MS sin cruce (caso patológico esperado):** si el paciente **nunca transfiere la carga al antepié**, las curvas no se cruzan. En ese caso se emite MS en el instante de **máximo del cociente `F_ante/F_post`** dentro del apoyo, con **baja confianza** y **flag `no_crossover`**. Ese flag **no es un error: es señal de anomalía** (déficit de propulsión) y se propaga a la cintura como tal.
- **Degradación con gracia:** si el IMU no confirma de forma sistemática (paciente/sensor), operar en **FSR-solo**; la alineación fina se apoya en el backbone de sync (ADR-004).

**Latencia.** El **cruce de FSR emite el evento de inmediato**; la confirmación IMU **anota confianza sin bloquear** la emisión. **Criterio:** el evento tiene que estar disponible dentro de la **misma zancada**, porque lo consumen el ZUPT (SPEC-03), el buffer de zancadas (SPEC-05) y la fusión bilateral de la cintura. *No* es una latencia de lazo cerrado: ADR-027 derogó el objetivo "<50 ms" al hacer el feedback **terminal por ventana**.

**Salida.** Evento `{ tipo: IC|TO|MS, t_evento (µs), pie, confianza, flags }` → (1) buffer local (features + segmentación de fases + ZUPT) y (2) envío a la **cintura** (fusión bilateral / double support, refinamiento de sync, timing de feedback). Persistido en `gait_events.type ∈ {IC,TO,MS}`.

**Parámetros calibrables (por paciente, en la calibración/baseline).** `F_on`, `F_off` (derivados del peso corporal y de la curva fuerza-resistencia por-FSR), `W`, `t_ref`, `h_ms`, y el mapeo **FSR → región** (antepié / retropié), que sale de la config de posiciones del catálogo. Se versionan junto con el `feature_set_version`.

**Nota sobre la definición de MS (honestidad terminológica).** En la literatura clásica (Perry), *mid-stance* es un evento **cinemático**: la tibia queda vertical sobre el pie apoyado. Lo que detecta esta spec es el **cruce de carga** retropié→antepié, que en marcha sana cae cerca de ese instante pero en marcha hemipléjica **puede divergir** —y suele hacerlo tarde, o no ocurrir. Se elige la definición de carga porque (a) es la que el FSR entrega de forma robusta, (b) es el instante funcionalmente relevante para el déficit de push-off, y (c) mantiene la misma arquitectura de detección que IC/TO (FSR primario + confirmación IMU). La confirmación por pie-plano del IMU ancla el evento al mid-stance cinemático cuando ambos coinciden; la **divergencia entre ambos es informativa** y queda como candidata de feature a futuro.

**Mecánica a implementar (para quien codifica).** Filtrado del FSR (la decimación de adquisición ya suaviza), detección de cruce con histéresis + refractario, comparación continua `F_ante` vs `F_post` dentro del apoyo con banda muerta, detección de pico/cruce por cero en la velocidad angular dentro de la ventana, buffer circular de eventos. Construido sobre CMSIS-DSP o kernels propios. No requiere librería específica de marcha.

**Referencias.** FSR como *ground truth* de contacto + confirmación IMU (marco teórico, línea ~268); detección robusta en hemipléjicos con 1 IMU (velocidad angular del pie, ~2 % de error de ciclo); fusión FSR+IMU >96 % de exactitud; IMU-solo menos preciso en el instante (RMSE ~50-61 ms vs ~14 ms MoCap). Para MS: fases del ciclo (marco teórico, líneas ~252-253); **déficit de push-off en el lado parético — Kang 2025 (paper #20)** y Sanghan et al. (2014); inestabilidad de balance en mid-stance por inversión del pie — Ma, Zheng & Lee (2018). Ver ADR-015 y ADR-038 para el detalle.

---

## SPEC-02 — Segmentación de fases (stance / swing) y sub-fases del apoyo

**Deriva de:** SPEC-01 / ADR-015 (stance/swing) · **ADR-038** (sub-fases del apoyo). **Placement:** plantilla (per-pie). **Estado:** definido.

**Objetivo.** Etiquetar cada muestra, por pie, como **stance** o **swing**, y **partir el apoyo en dos sub-fases** a partir del evento MS, para alimentar las features que dependen de fase.

**Definición (directa de los eventos).**
- **Stance** = intervalo `[IC, TO]` (pie en contacto).
- **Swing** = intervalo `[TO, IC_siguiente]` (pie en vuelo).
- **Sub-fases del apoyo (ADR-038):**
  - **Carga** = `[IC, MS]` — aceptación del peso (*weight acceptance*).
  - **Propulsión** = `[MS, TO]` — empuje / push-off.
- Referencia de proporción esperada (marcha típica): stance ~60-62 %, swing ~38-40 % del ciclo — útil como *sanity check*, no como regla.

**Quién la consume.**
- **ZUPT / stride length** (SPEC-03): corre durante **stance** (sin cambios: usa el apoyo completo).
- **LDLJ** y **mean angular velocity**: se calculan sólo en **swing**.
- **Bloque C, features #12/#13/#14** (peak force, mean pressure, PTI): se **instancian por FSR × sub-fase** (carga / propulsión) — ADR-038. Es el mismo mecanismo de instanciación que ya usa el bloque C por-FSR.
- **#16 loading rate** queda con **dominio explícito** en la sub-fase de **carga**; **#17 time-to-peak** sigue medido desde IC (sin cambios).
- **#43 (push-off time ratio)** y **#44 (propulsive impulse ratio)**: derivan directamente de MS — ver Vista 3, Parte A.
- **Double support** (feature bilateral): solapamiento de la fase stance de **ambos** pies → se computa en la **cintura**, a partir de los eventos alineados (no necesita el crudo de ambos pies).

**Salida.** Fase actual por-pie + límites de fase y de sub-fase (timestamps), al módulo de features y al ZUPT.

**Degradación.** Si MS llega con `no_crossover` o baja confianza (SPEC-01), las features que dependen de la sub-fase se emiten **marcadas**; el mecanismo de dependencias del catálogo (ADR-021) permite apagarlas sin tocar el resto. Las de stance completo no se ven afectadas.

**Sub-fases no adoptadas.** *loading response* / *terminal stance* / *pre-swing* (Perry) — exigirían más eventos (heel-off, contacto contralateral) que el feature set actual no pide. Se agregan sólo si alguna feature futura las requiere.

---

## SPEC-03 — Largo de zancada (stride length) por ZUPT

**Decisión:** ADR-016. **Placement:** plantilla (per-pie). **Estado:** definido. **Depende de:** orientación del pie (backlog #5) + fase *stance* (SPEC-01/02).

**Objetivo.** Estimar, por pie y por zancada, el **largo de zancada** (y de ahí la **velocidad de zancada**) integrando la aceleración del IMU, con el drift corregido por **ZUPT** disparado por el *stance* del FSR.

**Entradas.** accel + gyro (100 Hz), **orientación del pie** (backlog #5), **fase stance** (SPEC-02).

**Algoritmo (por zancada).**
1. **Frame global:** con la orientación del pie, rotar la aceleración del frame sensor al frame global.
2. **Quitar gravedad:** restar `g` en el frame global → aceleración lineal.
3. **1ª integración:** integrar la aceleración lineal → velocidad, sobre el intervalo de la zancada (entre *stances*).
4. **ZUPT (de-drift):** como la velocidad debe ser ~0 en *stance*, repartir la deriva acumulada linealmente en la zancada para forzar v=0 al inicio/fin del apoyo.
5. **2ª integración:** integrar la velocidad corregida → desplazamiento; **stride length** = magnitud del desplazamiento horizontal de la zancada.
6. **stride speed** = stride length / stride time.

**Robustez.** El *stance* lo da el **FSR** (ground truth) → más robusto que los detectores IMU-only; el ZUPT es ideal en **marcha lenta** (stance con v≈0 claro). Precisión esperada del orden de pocos %.

**Parámetros calibrables.** Umbral de *stance* (del FSR, ya en SPEC-01), ventana de integración (por zancada).

**Salida.** `stride_length`, `stride_speed` por zancada → features bloque A (6, 7).

**Refinamiento futuro.** EKF/INS *ZUPT-aided* o **MSDI/MFD-GED** para más precisión/trayectoria. Sin magnetómetro (MPU-6050 6-DOF) → preferir métodos *magnetometer-free*.

**Mecánica a implementar.** Integradores, de-drift lineal, gestión de frames (usa la orientación de #5), disparo por fase *stance*. Sobre CMSIS-DSP o kernels propios; sin librería específica.

---

## SPEC-04 — Módulo de procesamiento de IMU (reutilizable)

**Decisión:** ADR-017. **Placement:** cada dispositivo con IMU (plantillas + cintura). **Estado:** definido. **Ubicación de código:** `src/firmware/shared/` (C) + espejo en el worker (`imufusion`, Python).

**Objetivo.** Capa reutilizable que entrega la señal del IMU **limpia y lista** para todas las features y el ZUPT, para que **nadie re-implemente** orientación ni remoción de gravedad.

**Expone (API conceptual).**
- `accel_cal`, `gyro_cal` — bias/offset corregidos.
- **Orientación** — quaternion + euler (pitch, roll [, yaw]).
- **`lin_accel`** — aceleración **lineal sin gravedad**, en frame sensor y frame mundo.
- `ang_vel` — velocidad angular calibrada.

**Interno.** driver I²C (MPU-6050) → calibración → **Fusion AHRS (Madgwick, 6-DOF)** → *gravity removal*.

**Calibración.**
- **Estática** ("dejar quieto", post warm-up 2-3 min, sin vibración): bias de giro (promedio), offset de accel (nivelado).
- **Runtime:** re-zero del bias de giro durante el ***stance*** (detectado por FSR) → reduce deriva; sinérgico con el ZUPT.
- **Anatómica:** pose **pie-plano** en la sesión → alinea el vertical con la gravedad (roll/pitch anatómicos); heading por dirección de marcha (opcional).

**Consumidores.** ZUPT/stride length (SPEC-03), foot pitch en IC/TO, ROM pitch/roll, LDLJ, mean angular velocity (bloques F/G).

**Paridad (condicional).** `imufusion` (Python) se usa en el worker **sólo para re-extraer features del IMU desde el crudo off-device** (fase de dataset/experimentación): ahí debe reproducir exactamente lo que hace **Fusion (C)** en el micro. En el reentrenamiento *edge* normal el worker consume **features ya computadas** por el micro y **no** necesita imufusion.

**Parámetros calibrables.** offsets/bias por dispositivo; `β` de Madgwick; alineación anatómica por sesión.

**Nota 6-DOF.** Sin magnetómetro el *yaw* absoluto no es observable (driftea); no afecta *gravity removal* ni roll/pitch. Features que dependan de heading absoluto deben acotarse por eventos/ZUPT.

**Mecánica a implementar.** Vendorizar **Fusion** (verificar licencia), rutina de calibración estática, hook de re-zero en *stance*, exposición de la API. La calibración se integra a la sesión de **calibración/baseline** (Vista 3).

---

## SPEC-05 — Buffer de zancadas (ventana para variabilidad y simetría)

**Deriva de:** definición directa (sin ADR). **Placement:** plantilla (per-pie) + cintura (bilateral). **Estado:** definido.

**Objetivo.** Mantener un buffer de las **últimas N zancadas** de features por-pie, para las features que necesitan una **ventana multi-zancada**.

**Qué se buffea.** El **vector de features por-zancada** (o los escalares necesarios: stride/stance/swing time, cadence, …). **No** crudo.

**Estructura.** **Ring buffer** (circular) de tamaño **N configurable** (default ≥10; típico 10-20). Una entrada **por zancada** (~1 Hz), al cierre de cada zancada.

**Dónde.**
- **Plantilla (per-pie):** buffer de las features por-pie → **variabilidad** (bloque B: CoV de stride/stance/swing/cadence) y **Force Symmetry Index consecutivo** (feature 21).
- **Cintura (bilateral):** buffer de features por-pie de **ambos** pies → **Symmetry Index** (feature 20) estabilizado sobre la ventana.

**Ventana.** Deslizante de N zancadas (estándar para CoV; coincide con el marco "≥10 zancadas"). *Alternativa:* EWMA (menos memoria, adaptación continua) — no elegida por ahora (la ventana fija es más interpretable para CoV).

**Warm-up.** Hasta llenar N zancadas, las features de variabilidad **no son válidas** (baja confianza). La sesión de calibración (~100 zancadas) llena de sobra.

**Memoria.** Mínima (N × pocos floats por pie).

**Parámetro calibrable.** N (versionado con `feature_set_version`).

**Mecánica a implementar.** Ring buffer; **cálculo incremental de media/desvío (Welford)** para CoV eficiente y numéricamente estable; flag de warm-up.

---

## SPEC-06 — COP_ML (centro de presión medio-lateral 1D) y derivadas

**Deriva de:** definición + investigación (MLPI). **Placement:** plantilla (per-pie). **Estado:** definido, **DIFERIDO** (set activo 2-FSR OFF: el COP_ML requiere FSR **medial-lateral**; el hardware actual tiene punta+talón. Se activa al sumar los FSR ML — **ADR-023**).

**Objetivo.** Estimar el **componente medio-lateral del centro de presión** por pie (aproximación 1D, factible con 3-4 FSR) y sus dinámicas — features de balance/riesgo de caída (bloque E).

**Fórmula.** `COP_ML = Σ(Fᵢ·xᵢ) / Σ(Fᵢ)`, con `Fᵢ` la fuerza del FSR *i* y `xᵢ` su **coordenada medio-lateral**.

**Marco de coordenadas.** Fijo a la plantilla (**x = ML, y = AP**), tomado del **CAD/PCB**. Las posiciones de los sensores salen de ahí.

**Referencia (MLPI).** El COP_ML se reporta como **Medial-Lateral Pressure Index**: distancia perpendicular del COP a la **línea media del pie** (centroide del talón → 2º dedo), **normalizada por el ancho del pie**. Signo: **+ lateral, − medial**.

**Dos piezas de configuración (importante).**
- **Posiciones de FSR (`xᵢ`):** del CAD, en mm, en el marco de la plantilla; **constante por revisión de hardware** → van en la **config de modularidad de FSR** (CP-08/CP-12). El módulo de features consume ese arreglo de posiciones.
- **Línea media + ancho de pie:** dependen del paciente → **parámetros por-paciente** que se fijan en la **calibración/baseline** (Vista 3).

**Features derivadas (bloque E, 22-25).** COP_ML (MLPI), **COP_ML range** (excursión en la zancada), **COP_ML velocity** (derivada), **zero-crossings de la velocidad** (top de fallers, Herbers).

**Nota sobre el origen.** Las **dinámicas** (range, velocity, zero-crossings de la velocidad) son **independientes del origen** → robustas aun sin una línea media perfecta. El **valor absoluto** (MLPI) sí requiere la línea media + ancho (per-paciente).

**Parámetros calibrables.** posiciones FSR (por hardware); línea media + ancho de pie (por paciente).

**Mecánica a implementar.** Suma ponderada, derivada temporal, contador de cruces por cero; sobre CMSIS-DSP o kernels propios.

**Referencias.** Formulaciones de COP + marco de coordenadas de la plantilla (MDPI Sensors 21:1450); MLPI = distancia a la línea media normalizada por ancho (J Foot Ankle Res s13047-021-00493-5); normalización por tamaño de pie; modelo individual de COP con insoles low-cost (PMC5855500).

---

## SPEC-07 — FFT / PSD on-device y features del bloque H (frecuencia/entropía)

**Decisión:** ADR-019. **Placement:** plantilla (per-pie); cintura si se activan features espectrales de tronco (bloque I). **Estado:** definido (a implementar). **Depende de:** módulo IMU (SPEC-04, para `lin_accel`) + buffer de muestras (ventana). **Prioridad:** baja (bloque H = fase 4 / opcional).

**Objetivo.** Proveer el **análisis espectral on-device** (FFT real + PSD) y calcular las features del **bloque H**: spectral entropy (35), dominant frequency (37), power en bandas (38); + **sample entropy** (36, sin FFT). Su inclusión final depende de la feature selection (CP-12).

**Librería.** **CMSIS-DSP (float32)**: `arm_rfft_fast_f32` (FFT real) + `arm_cmplx_mag_f32` (magnitud → PSD). Misma librería para filtros/decimación FIR y álgebra (Mahalanobis). Fixed-point q15 sólo como fallback (ADR-019).

**Señal de entrada.** Aceleración (eje vertical/AP o \|`lin_accel`\| del módulo IMU, SPEC-04); el eje/definición se fija en la exploración. **Ventana Hann** antes de la FFT (reduce *leakage*).

**Ventana (clave — es multi-zancada, no per-zancada).** El bloque H necesita resolución en frecuencia → corre sobre una **ventana deslizante de N muestras potencia de 2**, no sobre una sola zancada. A 100 Hz:
- **N=256 (2,56 s, Δf≈0,39 Hz) — default.** Resuelve la banda **<0,5 Hz**.
- N=128 (1,28 s, Δf≈0,78 Hz): más responsivo, pero grueso para <0,5 Hz.
- N=512 (5,12 s, Δf≈0,20 Hz): más resolución, menos responsivo.

Solapamiento (hop) configurable (p. ej. 50 %). **N y hop versionados con `feature_set_version`.**

**Features.**
- **Dominant frequency (37):** frecuencia del pico de la PSD (`argmax`, excluyendo DC).
- **Spectral entropy (35):** entropía de Shannon de la PSD **normalizada** como distribución: `−Σ pᵢ·log pᵢ` (opcional: normalizar por `log N`).
- **Power en bandas (38):** Σ PSD en **<0,5 / 0,5–2 / >2 Hz**; fijar convención de normalización (p. ej. fracción de potencia total).
- **Sample entropy (36):** sobre la velocidad angular `ω`, **O(n²)** (sin FFT); parámetros `m` (longitud de patrón) y `r` (tolerancia, p. ej. 0,2·σ); ventana corta (acotar N por costo).

**Salida.** Features del bloque H por ventana → se integran al vector de features vigente (o se reportan por ventana).

**Costo / factibilidad.** Peor caso conservador (M0+ sin FPU, RP2040): ~2,0 ms (N=128) / ~4,3 ms (N=256) por FFT+magnitud; en el M33 **con FPU**, bastante menos. A ~1 Hz de cadencia → <0,5 % de duty. **No** es camino crítico (el feedback lo maneja Mahalanobis <100 µs).

**Paridad (ADR-018).** Caso más sensible del catálogo: calcular en **float32 de ambos lados**, misma ventana (Hann) y misma normalización de PSD; **tolerancias por-feature más laxas** para el bloque H. `dominant_frequency`/`spectral_entropy` robustas; `power en bandas` sensible a escala. Promoción a producción **sólo tras tests de paridad** sobre captura operativa.

**Parámetros calibrables / a explorar.** eje de accel, N y hop de ventana, bandas (fijas por marco pero revisables), `m`/`r` de SampEn. Se barren en la fase exploratoria (crudo-solo) y se congelan con el `feature_set_version`.

**Mecánica a implementar.** Buffer deslizante de N; ventana Hann (tabla precomputada); `arm_rfft_fast_f32` → `arm_cmplx_mag_f32` → PSD; normalización; sumas por banda; argmax; entropía (log en float). SampEn aparte (doble loop con corte temprano). Todo sobre **CMSIS-DSP**.

**Referencias.** Definiciones del bloque H (`docs/investigacion/features_anomaly_detection_stroke.md`); RP2350 M33 FPU+DSP (datasheet RPi); `arm_rfft_fast_f32` (CMSIS-DSP, ARM); benchmark FFT en Pico (cmsis-sandbox). Detalle de la decisión: **ADR-019**.

---

## SPEC-08 — Runtime de inferencia on-device (ejecución de modelos int8)

**Decisión:** ADR-020. **Placement:** cintura (hub). **Estado:** definido (a implementar). **Depende de:** modelo entrenado + cuantizado (worker, #10); OTA (ADR-012).

**Objetivo.** Ejecutar los modelos de detección **en la cintura en tiempo real**, con el runtime adecuado por tipo de modelo. Es **inferencia**, no reentrenamiento (eso es del worker, ADR-009/011).

**Mapa de ejecución (qué corre con qué).**
- **Mahalanobis (L):** `D² = (x−μ)ᵀ Σ⁻¹ (x−μ)` en **C + CMSIS-DSP** (matriz-vector). <100 µs. Caballo de batalla del feedback y sensor de drift.
- **Autoencoder denso int8 (E):** **TFLM + CMSIS-NN**. El intérprete TFLM ejecuta el flatbuffer; CMSIS-NN hace las capas densas int8.
- **Isolation Forest:** recorrido de árboles (tablas de splits) en **C** — no es NN, no usa TFLM (clase E: infiere en cintura, reentrena en worker; ADR-011 rev).
- **LSTM AE:** **TFLM** si entra en tiempo real en el M33; si no, host (H) u offline (W) — profiling (#11).

**Flujo del AE denso (clase E).**
1. Entrenamiento + cuantización en el worker: **TensorFlow/Keras** → **conversor TFLite/LiteRT (PTQ int8, representative dataset)** → **flatbuffer int8** (ADR-022).
2. **OTA** del flatbuffer a la cintura (ADR-012, esquema A/B con checksum/rollback).
3. En la cintura: TFLM carga el flatbuffer en una **tensor arena** (bloque de RAM reservado) y, por zancada, corre `interpreter.invoke()`; CMSIS-NN acelera las capas.
4. Score de anomalía = error de reconstrucción (MSE input vs. output); umbral por percentil de calibración.

**Footprint / latencia.** Intérprete TFLM ~2 KB + modelo AE ~10-50 KB (int8, ~4× menor que float); CMSIS-NN 2,6-5,4× vs C genérico; inferencia del AE ~ms, a ~1 Hz (por zancada) → holgado. El feedback duro lo sostiene Mahalanobis (<100 µs); el AE es una capa de detección adicional, no el lazo más rápido.

**Paridad train↔serve (ADR-018).** TFLM sigue la **spec de cuantización de TFLite**, así que el int8 que produce el converter es el que ejecuta el micro → paridad por construcción.

**OTA (ADR-012).** El modelo viaja como **flatbuffer int8** a un slot A/B con checksum y rollback. Cambiar de modelo = OTA de un flatbuffer nuevo (no reflashear firmware, salvo que cambie el runtime).

**Riesgo / fallback.** El port **RP2350 de `pico-tflmicro` no está mergeado** → validar temprano (llevar patch/fork o portar). Fallback: **CMSIS-NN directo** (sin intérprete) para el AE denso (ADR-020).

**Parámetros.** Arquitectura del AE (p. ej. 25-12-6-12-25), esquema de cuantización int8, tamaño de tensor arena — se fijan en el entrenamiento (#10) y se versionan con el modelo en el registry.

**Mecánica a implementar.** Integrar `pico-tflmicro` (con CMSIS-NN) al build del firmware de la cintura; reservar la tensor arena; cargar el flatbuffer (flash / OTA); loop de `invoke()` por zancada; wiring del score al decisor de feedback. Mahalanobis (CMSIS-DSP) e IF (árboles en C) van aparte.

**Referencias.** `pico-tflmicro` (Raspberry Pi); CMSIS-NN (ARM; arXiv 1801.06601); TFLite Micro (footprint); ADR-011/013 (taxonomía/ubicación de inferencia), ADR-012 (OTA), ADR-018 (paridad). Detalle de la decisión: **ADR-020**.

---

## SPEC-09 — Patrones de feedback vibrotáctil y lógica de disparo

**Decisión:** ADR-027. **Placement:** decisión en la cintura (hub) → comando a la plantilla; ejecución del patrón en la plantilla (PWM). **Estado:** definido (a implementar; valores empíricos). **Depende de:** score de `feedback_source` (SPEC-08), buffer de zancadas (SPEC-05), features de simetría/sway (Vista 3).

**Objetivo.** Convertir la detección de anomalía **sostenida** en una **alerta vibrotáctil escasa y graduada**. Es **monitoreo + aviso**, no corrección (ADR-027).

**Entrada.**
- **Score de feedback** = salida del detector designado (`feedback_source`), model-agnostic (SPEC-08).
- **Ventana** de las últimas **N zancadas** (del ring buffer, SPEC-05).
- **Indicadores de caída** para "riesgo": asimetría de carga (WBA) / sway (features de tronco, bloque I).

**Lógica (en la cintura, por zancada nueva).**
1. **Evaluar la ventana:** agregación del score sobre las últimas N zancadas — por *persistencia* (X de las últimas Y sobre umbral) o por *score ventaneado* (features de variabilidad/simetría sobre N zancadas). Cuál, y N, = empírico.
2. **Mapear a banda** por umbrales per-paciente: `normal < T1 ≤ leve < T2 ≤ marcada < T3 ≤ riesgo`. El nivel "riesgo" también se dispara si los **indicadores de caída** cruzan su umbral clínico.
3. **Filtrar (escasez):** **histéresis** (anomalía sostenida, no una zancada aislada) + **refractario** (no repetir dentro de un cooldown) + **fading** opcional.
4. **Emitir comando** a las plantillas: `(nivel, ambos pies)`. La plantilla reproduce el patrón en su PWM.

**Patrones (ERM por PWM — ritmo, no intensidad fina).**

| Banda | Patrón | Intención |
|---|---|---|
| Leve | 1 pulso corto | recordatorio suave |
| Marcada | 2 pulsos | desviación clara |
| Riesgo | pulso largo / triple insistente | patrón asociado a caída |

**Parámetros (per-paciente, en DB → Vista 4).** `feedback_source`; **N** (ventana); **T1/T2/T3** (umbrales de banda, del baseline); regla de agregación/persistencia; **intensidad** (duty PWM, perceptible+cómoda); **refractario** (cooldown); patrones habilitados; umbral de los indicadores de caída.

**Calibración.** Intensidad perceptible+cómoda por paciente (la percepción depende del montaje — Sanchez-Morillo); umbrales de banda desde la distribución de scores del **baseline** (~100 zancadas de marcha estable).

**Hardware.** Motor **ERM** vía PWM+NPN (GP18, con diodo flyback). Sin gradación fina de intensidad (usar ritmo). A confirmar si el motor real es un **LRA** (patrones más crispados con driver).

**Empírico (exploratorio).** Modelo designado, N de ventana, regla de agregación, valores de umbral e intensidad — se fijan con datos (ligado a #12 y al protocolo de calibración).

**Seguridad (CP-04).** Validar que el patrón "riesgo" no sobresalte ni desestabilice.

**Referencias.** ADR-027 (decisión); ADR-011 rev (score agnóstico); SPEC-05 (buffer de zancadas); SPEC-08 (score); papers 02 (patrones>alertas), 09 (carga cognitiva), 10 (Ma), 17 (Jung, caída).

## SPEC-10 — Features de tronco (bloque I): IHR ML, RMS y LDLJ

**Decisión:** ADR-040. **Placement:** **cintura** (core 1). **Estado:** **definido — DIFERIDO** (bloque OFF en el set activo; se prende con un `feature_set_version` nuevo, sin reescritura).

> **Esta spec es una guía para cuando se prenda el bloque, no un encargo inmediato.** Recoge lo investigado para que activarlo sea leer esto y cambiar la config, en vez de rehacer el análisis.
>
> **Fundamento:** la explicación en llano está en el **apéndice de ADR-040**; el **desarrollo matemático completo** (DFT, ortogonalidad, teorema de simetría de media onda, leakage, y los tests de verificación) está en **`docs/investigacion/fundamento_dft_ihr.md`**. Varias reglas de esta spec —no aplicar ventana de Hann, restar la media, descartar zancadas con IC dudoso— **se justifican ahí**, no acá.

**Objetivo.** Calcular, por zancada y en la cintura, tres descriptores del movimiento del tronco a partir del IMU ubicado a ~L4-L5: **#45 Improved Harmonic Ratio ML**, **#46 RMS de aceleración de tronco** (AP/ML/V) y **#47 LDLJ de tronco**.

**Entradas.** Aceleración triaxial del IMU de cintura a 100 Hz (calibrada y con gravedad removida — SPEC-04) + **eventos IC de ambas plantillas**, ya alineados sobre el timeline común (ADR-004). La cintura tiene todo esto sin pedir nada nuevo.

---

### Segmentación (común a las tres)

Cada feature se calcula **por zancada**, sobre el segmento entre `IC(n)` e `IC(n+1)` del **mismo pie de referencia** (fijar cuál en la config y mantenerlo: cambiar de pie de referencia cambia la fase, no el valor del IHR, pero sí la comparabilidad de las series).

**Dependencia dura con la calidad del IC.** Si `IC(n)` o `IC(n+1)` vienen con **baja confianza** (SPEC-01), el segmento no es una zancada exacta: la ventana deja de ser un período y la energía se desparrama entre bins (*spectral leakage*), lo que **se lee como asimetría aunque no la haya**. **Recomendación: descartar la zancada** para #45, o emitirla marcada, y dejar la elección como parámetro. #46 y #47 son mucho menos sensibles (no dependen de que la ventana sea un período exacto).

---

### #45 — Improved Harmonic Ratio ML

**Cálculo.**
1. Cortar el segmento de aceleración **ML** entre dos IC consecutivos.
2. **Remuestrear a un número fijo de muestras** (recomendado: potencia de 2, p. ej. **256**, para el `arm_rfft_fast_f32` de CMSIS-DSP — SPEC-07). **No usar zero-padding**: rompe la propiedad "una ventana = un período", que es lo que hace que el bin *k* sea el armónico *k*.
3. FFT real → potencia por bin. **Por construcción, el bin *k* es el armónico *k*** — no hay que estimar la frecuencia fundamental ni buscar picos.
4. `IHR = Σ P(intrínsecos) / Σ P(intrínsecos + extrínsecos)`, sumando hasta el armónico **N**.

**Asignación intrínseco / extrínseco — por eje, fija, no depende del paciente:**

| Eje | Intrínsecos | Extrínsecos |
|---|---|---|
| **Medio-lateral (ML)** | armónicos **impares** | pares |
| Vertical y antero-posterior | armónicos **pares** | impares |

**Por qué esa asignación y no otra:** es un **teorema** sobre simetría de media onda, no un ajuste empírico — demostrado en `fundamento_dft_ihr.md` §7. En marcha simétrica, el desfasaje de media ventana introduce un factor $(-1)^k$ que anula exactamente un conjunto de coeficientes.

**Reglas que salen del fundamento (§9 de ese documento):**
- **Ventana rectangular, SIN Hann.** Contraintuitivo viniendo de SPEC-07, pero acá la ventana ya está enganchada al período: una Hann derramaría energía a los bins vecinos, **que son de paridad opuesta**, sesgando el IHR hacia 0,5.
- **Restar la media** del segmento antes de transformar: el bin 0 es par y un offset residual lo contamina.
- **Los bins altos son artefacto** del remuestreo (100 muestras reales → 256 interpoladas): usar sólo los primeros 10-20 armónicos, nunca leer significado más arriba.

**A verificar antes de implementar:** la variante *Improved* de Brasiliano et al. (2026) — confirmar contra el paper qué armónicos entran exactamente en cada conjunto y citarlo. La regla par/impar de arriba es la base estándar del harmonic ratio; la forma acotada de la fórmula (`Σ P^I / Σ(P^I + P^E)`, entre 0 y 1) es la que registra el marco teórico.

**Parámetros a fijar (versionados con `feature_set_version`).**

| Parámetro | Recomendación | Nota |
|---|---|---|
| `N_armonicos` | 10 o 20 | Fijo para todos los pacientes. Valores con distinto N **no son comparables entre trabajos** — documentarlo. |
| `L_remuestreo` | 256 muestras | Potencia de 2 por el FFT. Verificar que no distorsione con cadencias muy variables. |
| Método de remuestreo | interpolación lineal o cúbica | **Decidir con datos:** en marcha hemipléjica la duración de zancada varía mucho más que en sana (el CoV de stance es top-3 de Brasiliano), así que conviene medir el efecto antes de fijarlo. |
| Pie de referencia | fijo por sesión | Cambiarlo rompe la comparabilidad de la serie. |
| Política ante IC de baja confianza | descartar la zancada | Ver arriba. |

**Confusor conocido — velocidad de marcha.** El HR baja con la velocidad **incluso en sujetos sanos**. Si el paciente camina más lento un día, el IHR cae por un motivo que no es empeoramiento del patrón. `stride_speed` (#7) ya está en el catálogo → **recomendación: registrar la velocidad junto al IHR y condicionar el baseline por rango de velocidad**, o al menos dejarlo documentado como covariable en el análisis.

**Lo que la personalización ya resuelve.** El sistema es one-class personalizado: el baseline se construye con la calibración del propio paciente, así que todo lo constante para él —colocación del cinturón, altura, el `N` elegido, un sesgo del remuestreo— se absorbe y desaparece. Lo único que no se absorbe es lo que varía **dentro** del paciente, o sea la velocidad.

---

### #46 — RMS de aceleración de tronco (AP / ML / V)

**Cálculo.** RMS por eje sobre el segmento de zancada, con la aceleración lineal (sin gravedad, SPEC-04). Tres valores por zancada.

**Sin incógnitas metodológicas.** No requiere remuestreo ni FFT, y tolera un IC impreciso. Es la más barata de las tres.

**Nota:** normalizar o no por la velocidad de marcha es una decisión de análisis, no de firmware — el RMS crece con la velocidad. Recomendación: **emitir el valor crudo** y dejar la normalización al worker, que tiene la velocidad de la misma zancada.

---

### #47 — LDLJ de tronco

**Cálculo.** Misma fórmula que el bloque G (SPEC de referencia: features #32-34): `LDLJ = −ln((t₂−t₁) · max‖a‖ · ∫|a′|² dt)`, aplicada a la aceleración de tronco sobre la zancada.

**Diferencia clave con el LDLJ del pie.** En el pie, el LDLJ se calcula **sólo en swing** para evitar la contaminación de los impactos de heel-strike y push-off (adaptación propia del proyecto, documentada en el marco teórico). **En el tronco eso no hace falta**: la cadena cinemática filtra los impactos, y es precisamente por eso que Brasiliano lo mide en tronco y esternón. **Se calcula sobre la zancada completa.**

---

**Costo de cómputo.** Una FFT de 256 puntos por zancada (~1 Hz) más dos cálculos triviales. Con CMSIS-DSP en el M33 con FPU, **<0,5 % de duty cycle** (medido en SPEC-07). El cómputo **no es el motivo para diferirlo** — el motivo son las decisiones metodológicas de #45.

**Salida.** Tres features por zancada al vector de la cintura, con `scope = bilateral` (son del tronco, no de un pie). Se suman al vector fusionado antes de la inferencia.

**Referencias.** ADR-040 (decisión + apéndice conceptual completo); Brasiliano et al. (2026) *Sci Rep* 16:8908 — IHR ML top-1 del set de 3 que llega a 90,2 % en clustering no supervisado; ADR-030 (el bloque I recupera lo que el marco daba por perdido); SPEC-01 (confianza del IC), SPEC-04 (IMU y gravedad), SPEC-07 (FFT con CMSIS-DSP), ADR-021 (set activo); `docs/investigacion/ihr_armonicos_explicacion.html`.

---

