# Memoria del proyecto

> Snapshot vivo y **denso** para agentes. El detalle vive en los docs canónicos (se apunta a ellos, no se duplica). Actualizar al cambiar el estado.

## Qué es
Tesis de maestría (ITBA). Sistema de **plantillas inteligentes bilaterales** para **detección personalizada (one-class) de anomalías de marcha post-ACV**, con **feedback vibrotáctil** e **inferencia edge**. Filosofía: **personalización primero** + **simetría inter-miembro**. Autores: Azcueta Busco, Gramaglia. Tutores: Ramele, Papastylianou.

## Interacción con Juan (regla de trabajo)
**Explicar y consultar ANTES de decidir.** Ante cualquier decisión de diseño/arquitectura: exponer el problema, las **opciones con pros/cons** y una recomendación, y **esperar la confirmación de Juan** antes de escribir ADRs/specs o editar docs. (Registrado 2026-07-19: se tomó ADR-019/SPEC-07 sin consultar; Juan pidió no repetirlo.)

## Estado (2026-08-18)
- **Fase:** diseño detallado — arquitectura cerrada en 4 vistas; **backlog de specs #1–#10 hecho** (#11/#12 esperan código/datos). **Sin código aún.** **Las 4 vistas están consolidadas** (definición canónica en cada vista; el **maestro mantiene además la vista general completa** —duplicación buscada). **Sigue: roadmap de implementación e iniciar `src/`.** **Auditoría de consistencia (2026-08-18):** 14 conflictos + 7 huecos entre vistas, casi todos restos de decisiones ya superadas (tanda ADR-029→035 sin propagar al maestro/SPECs/DDL). **Resueltos:** el esquema (ADR-036/037) y mid-stance (ADR-038). **Pendientes de decisión:** §15 del maestro (9 filas faltantes), bloque I de tronco sin lugar en V2, restos de PyTorch y del objetivo derogado "<50 ms", y los "3 FSR" en mermaid/paquete.
- **Hardware:** 2 plantillas + 1 cintura, cada una **Pico 2 W (RP2350, M33 @150 MHz, 520 KB)** + **IMU MPU-6050** (6-DOF; el anteproyecto decía BMI270 → CP-11). Plantillas: **2 FSR hoy (punta+talón; 3º/4º medial-lateral a futuro, ADR-023; modular, soportar N)** + motor PWM. Muestreo **100 Hz**. Cintura = hub/AP; su IMU capta tronco (~L4-L5).
- **Feature set:** **47 features, bloques A–I** (ADR-029 sumó #39 single support, #40 symmetry angle, #41 avg zero-crossings, #42 sway density; **ADR-038** sumó #43 push-off time ratio y #44 propulsive impulse ratio; catálogo canónico en Vista 3). **Eventos: IC / TO / MS** — mid-stance adoptado (ADR-038) como **cruce de carga retropié→antepié**; parte el apoyo en **carga/propulsión** e instancia #12/#13/#14 del bloque C por sub-fase. Activo con 2 FSR. **Set activo actual = 2-FSR (punta/talón):** bloque E (COP_ML + #42 sway density) + #18 **OFF** hasta sumar FSR medial-lateral (ADR-023).
- **Algoritmos:** Mahalanobis (L + sensor de drift), Isolation Forest (E), AE denso int8 (E), LSTM AE (E/H/W). **Candidatos (ADR-029):** OC-SVM (E/W, benchmark offline), GMM/z-score, VAE. **Estrategia progresiva de evaluación** en Vista 3 §7.1 (Mahalanobis→IF→AE→LSTM, escalar sólo si no alcanza).

## Arquitectura — dónde está
- Índice/overview: `docs/arquitectura/Arquitectura_Sistema_Marcha.md`. **4 vistas** en `docs/arquitectura/vistas/` (1 sistema · 2 firmware · 3 datos-ml · 4 backend) + `stack_tecnologico.md`.
- **Consolidación: las 4 vistas están consolidadas** (V1 sistema · V2 firmware + satélite de specs · V3 datos/ML + satélite de análisis · V4 backend/app). El **maestro mantiene la vista general completa** (duplicación coherente y buscada).
- **Diagramas** (`docs/arquitectura/*.mermaid`): `diagrama_arquitectura`, `esquema_base_de_datos`, `ciclo_de_vida_modelos`, `adquisicion_dma_irq`, `calibracion_baseline` (baseline por paciente), **`componentes_backend_app` (nuevo — componentes/flujos del backend)**, `esquema_alimentacion` (cableado de potencia).
- **Decisiones (el *porqué*): `docs/decisiones/bitacora_decisiones.md` — ADR-000 a 038.**
- **Hardware / alimentación:** `docs/arquitectura/esquema_alimentacion.md` — guía de cableado (celda→VSYS, sensores desde 3V3, motor por NPN, VBUS libre) + **checklist consolidado de la próxima rev del PCB**.
- **Esquema de la base:** **`src/db/schema.sql` es la fuente única** (ADR-037) — incluye tablas, índices, RLS/`patient_access` y `feedback_config`. El maestro §11.3 es sólo el mapa de entidades. `sessions.mode` = `exploratory`/`operational`/`edge` y `feature_vectors.features_source` = `device`/`offline` (ADR-036).
- **Cuestiones abiertas: `docs/cuestiones_pendientes.md`.**
- **Regla de layering:** un feature/algoritmo se **define en Vista 3** y se **ejecuta en Vista 2 (firmware) + worker**, desde una **definición única compartida** (`feature_set_version`).
- **Convención:** cada ítem del backlog → **ADR + spec** (guía de implementación, no código). Specs firmware: `vistas/2_specs_algoritmos_firmware.md`.

## Decisiones clave (resumen; detalle en la bitácora)
- **Red/transporte:** plantillas↔cintura WiFi (cintura=AP), UDP stream + TCP control; cintura↔host **BLE desde la mínima**, GATT notif/writes. [ADR-001/002/003]
- **Sync:** backbone de reloj (timestamp+seq+beacon+drift) + emparejado por evento IC (refinamiento). [ADR-004]
- **Cómputo distribuido:** features **por-pie** en las plantillas; la cintura **fusiona** (simetría, double support), infiere y decide feedback. **Captura por fases (rev c):** *exploratoria* crudo-solo (features off-device) → *operativa* micro calcula features + crudo (skew-free + paridad sobre set nuevo) → *edge* features/scores live + crudo por anomalía. [ADR-005]
- **Modelos:** registry declara clase **L/E/H/W**; inferencia RT **micro→host, nunca en la nube** (switch por config `inference_target`, model-agnostic; host con runtime espejo); worker (laptop mínima / nube máxima) reentrena E/H/W; micro mantiene L. **IF es clase E** (infiere en cintura). **OTA** pesos+firmware A/B. [ADR-009/011 rev/012/013]
- **Feedback vibrotáctil:** **monitor + alerta** (no corrige); score designado (`feedback_source`, model-agnostic) sobre **ventana de zancadas** → anomalía sostenida → 3 bandas per-paciente → alerta escasa (3 ritmos, ambos pies); "riesgo" co-anclado a caída; timing event-locked. Modelo/ventana/umbrales empíricos. [ADR-027/SPEC-09]
- **Pairing (cintura↔host BLE, sin botón):** auto-advertise sin bond + **gesto: sacudir la cintura ~5 s con plantillas quietas** (multi-IMU); **passkey fijo impreso** (v1); **bond list multi-host N≈4** (LRU/forget), reconexión iniciada por el host (uno a la vez); clear-all/pantalla → máxima. [ADR-028; deps CP-04/CP-15]
- **Persistencia:** **Supabase** (Postgres + **TimescaleDB** + object storage + auth); retención **tiered** (+ crudo por anomalía). [ADR-006/007/008]
- **Firmware:** C/C++ Pico SDK, **bare-metal (sin RTOS)** [ADR-025]. **Cores (uniforme en los 3 micros): core 0 = radio, core 1 = procesamiento** (plantilla: core 1 = adquisición+eventos+features por-pie; cintura: core 1 = inferencia+fusión+IMU+decisión) [ADR-024 rev]. **Adquisición determinística:** ADC por HW + DMA, **sobremuestreo ~1 kHz → decimación a 100 Hz**; **IMU en tick maestro por DMA** (ODR alto + DLPF; DATA_READY fallback; FIFO descartada) [ADR-010/014/026].
- **Paridad (anti *train/serve skew*):** entrenar con las features **del micro** (de la **captura operativa**, no del crudo exploratorio) + **tests de paridad C↔Python en CI**. [ADR-018]

## Principios (no romper sin ADR)
- **Personalización primero** (global ~55 % vs personalizado ~97 %); **economía de features** (~15-25); dinámicas/frecuencia > posicionales para fallers.
- **Cintura = AP + hub de fusión** (invariante). **Definición de features única y compartida** (paridad garantizada). **Sync a nivel de aplicación** (portable WiFi↔BLE). Datos de salud: cifrado + RLS + `external_code` anónimo.

## Backlog de specs (`vistas/3_analisis_features_y_algoritmos.md` §D)
- **Hecho:** #1 IC/TO (ADR-015/SPEC-01) · #2 segmentación stance/swing (SPEC-02) · #3 ZUPT/stride length (ADR-016/SPEC-03) · #4 buffer de zancadas (SPEC-05) · #5 módulo IMU + calibración (ADR-017/SPEC-04; lib **Fusion**/`imufusion`) · #6 COP_ML/MLPI (SPEC-06) · #7 FFT/DSP on-device (ADR-019/SPEC-07; **CMSIS-DSP** f32, `arm_rfft_fast_f32`, bloque H) · #8 runtime de inferencia int8 (ADR-020/SPEC-08; **TFLM + CMSIS-NN** para NN; Mahalanobis en CMSIS-DSP, IF por árboles en C) · #9 catálogo de features compartido (ADR-021; catálogo declarativo + dos impl + tests de paridad) · #10 framework de entrenamiento + cuantización (ADR-022; **TF/Keras** + PTQ int8, QAT fallback). Transversal: paridad (ADR-018).
- **#11 y #12 a la fase de implementación:** #11 (footprint/latencia) valida sobre **firmware ya escrito** (no como spec pura; decidido 2026-07-21); #12 (selección de features) requiere **dataset capturado**.
- **Consolidación: terminada** (2026-07-21) — las **4 vistas** consolidadas, maestro intacto. **Sigue:** **roadmap de implementación** e iniciar `src/`.

## Cuestiones
- **Resueltas:** CP-02 (features distribuidas por-pie), CP-03 (IC en la plantilla), CP-12 (mecanismo de modularidad de features), CP-13 (fases de captura), **CP-07 (lectura del IMU: tick maestro + DMA — ADR-026)**, **CP-17 (RTOS bare-metal — ADR-025; rate IMU cintura 100 Hz+DMA, 50 Hz fallback #11 — ADR-026)**, **CP-10 (feedback: monitor+alerta por ventana, model-agnostic — ADR-027/SPEC-09)**, **CP-14 (pairing BLE sin botón: gesto en la cintura + passkey fijo + bond list multi-host — ADR-028)**.
- **Abiertas:** CP-01, CP-06, CP-08, CP-09, **CP-18** (ratificación seguridad/ética con el comité), **CP-20** (columnas generadas sobre `features` — depende de #12 y del dashboard) (ver `docs/cuestiones_pendientes.md`). *Casi todas dependen de hardware/PCB, del comité o de llegar a la máxima.* **Resueltas recientes:** CP-05 (`feature_vectors` = `jsonb` — ADR-031) · CP-04 (RLS estricto — ADR-032; formal → CP-18) · CP-15 (UI de control web-local; dashboard diferido — ADR-033) · CP-16 (micro agnóstico al host — ADR-034) · **CP-19** (encendido: **sin gestión de energía**, el switch es el on/off; wake-on-motion diferido a la máxima — ADR-035 rev). *(CP-15 interfaces mínima: UI de usuario + dashboard clínico web · CP-16 detección compu/celu y switch de pipeline.)*

## Recursos
`docs/Anteproyecto_Tesis.pdf` · `docs/marco_teorico/marco_teorico_documento_de_trabajo.md` · `docs/investigacion/` · cronología completa en `memoria/changelog.md`.
