# Vista 2 · Firmware — Colección de specs de algoritmos

> *(Este NO es el documento de la vista —ese es `2_vista_firmware.md`, el overview—. Este es la colección de guías de implementación que crece con el backlog.)*

> **Qué es esto.** Colección de **specs concisas de algoritmo** que sirven de **guía de implementación** para el agente/persona que escribe el firmware. Cada spec fija las **decisiones de dominio** (definición, señales, parámetros, robustez, salida) + referencias; **no** es código. La **mecánica de codificación** (cómo implementar un detector de picos, un filtro, etc.) queda a cargo de quien implementa.
>
> **Regla:** cada ítem del backlog de investigación (ver `3_analisis_features_y_algoritmos.md` §D) que produzca un algoritmo de firmware, deja aquí su spec + su ADR en la bitácora.

---

## SPEC-01 — Detección de eventos IC / TO (por pie)

**Decisión:** ADR-015. **Placement:** plantilla (per-pie). **Estado:** definido (a implementar).

**Objetivo.** Detectar en tiempo real, por pie, el **Initial Contact (IC)** y el **Toe-Off (TO)**, robusto a marcha patológica (drop foot, apoyo de antepié/plano). Es la **función núcleo** del firmware: su salida alimenta las features espacio-temporales, la segmentación de fases (stance/swing), el ZUPT, el refinamiento de sync y el timing del feedback.

**Entradas.** 3 FSR (fuerza calibrada, 100 Hz) + IMU (gyro + accel, 100 Hz), todos con `timestamp` (µs) + `seq`. La fuerza plantar total se define como `F_total = Σ FSRᵢ`.

**Definición robusta (clave para ACV).**
- **IC = onset de carga:** `F_total` cruza **hacia arriba** el umbral `F_on` — el primer instante de carga, **sin importar la región** (no "talón primero"). Cubre apoyo de antepié/plano y *drop foot*.
- **TO = fin de carga:** `F_total` cruza **hacia abajo** el umbral `F_off` y se mantiene por debajo.

**Robustez / anti-falsos.**
- **Histéresis:** `F_off < F_on` (evita rebotes alrededor del umbral).
- **Refractario:** tiempo mínimo entre eventos del mismo pie (`t_ref`, p. ej. ~200 ms) para no doble-disparar.
- **Confirmación IMU (ventana):** al detectar el cruce de FSR, buscar en `±W` (p. ej. ±50 ms) la **firma esperada en la velocidad angular sagital** del pie (pico característico en IC/TO). Si coincide → evento de **alta confianza**; si no → se **emite igual** con **baja confianza** (no descartar: en patología conviene no perder eventos).
- **Degradación con gracia:** si el IMU no confirma de forma sistemática (paciente/ď­sensor), operar en **FSR-solo**; la alineación fina se apoya en el backbone de sync (ADR-004).

**Latencia.** El **cruce de FSR emite el evento de inmediato** (sirve al feedback <50 ms); la confirmación IMU **anota confianza sin bloquear** la emisión.

**Salida.** Evento `{ tipo: IC|TO, t_evento (µs), pie, confianza }` → (1) buffer local (features + segmentación de fases + ZUPT) y (2) envío a la **cintura** (fusión bilateral / double support, refinamiento de sync, timing de feedback).

**Parámetros calibrables (por paciente, en la calibración/baseline).** `F_on`, `F_off` (derivados del peso corporal y de la curva fuerza-resistencia por-FSR), `W`, `t_ref`. Se versionan junto con el `feature_set_version`.

**Mecánica a implementar (para quien codifica).** Filtrado del FSR (la decimación de adquisición ya suaviza), detección de cruce con histéresis + refractario, detección de pico en la velocidad angular (umbral sobre |ω| o sobre su derivada) dentro de la ventana, buffer circular de eventos. Construido sobre CMSIS-DSP o kernels propios. No requiere librería específica de marcha.

**Referencias.** FSR como *ground truth* de contacto + confirmación IMU (marco teórico, línea ~268); detección robusta en hemipléjicos con 1 IMU (velocidad angular del pie, ~2 % de error de ciclo); fusión FSR+IMU >96 % de exactitud; IMU-solo menos preciso en el instante (RMSE ~50-61 ms vs ~14 ms MoCap). Ver ADR-015 para el detalle de la investigación.
