# Changelog

> Registro cronológico de cambios en el proyecto (arquitectura, docs, código, decisiones). Entrada más reciente arriba. Formato: fecha — qué cambió — por qué / referencia.

## 2026-07-16 — Backlog #1: detección de eventos IC/TO (ADR-015, resuelve CP-03)

- **Decisión (ADR-015):** detección de IC/TO por **fusión FSR-primario + confirmación IMU**, corriendo **en la plantilla (per-pie)**; el evento se envía a la cintura para fusión bilateral, sync y feedback. Basado en investigación (FSR ground-truth de contacto + IMU robusto en hemipléjicos; fusión >96 %). **Resuelve CP-03.**
- Definición robusta a patología: **IC = onset de carga de cualquier región** (no "talón primero"); **TO = fin de carga**; histéresis + refractario + confirmación IMU en ventana.
- **Convención de trabajo establecida:** cada ítem del backlog produce (a) un **ADR** y (b) una **spec de algoritmo** (guía de implementación, no código) en la vista correspondiente. Nueva colección: `docs/arquitectura/vistas/2_specs_algoritmos_firmware.md` → **SPEC-01**.

## 2026-07-16 — Análisis de definición: features y algoritmos (Vista 3)

- Nuevo `docs/arquitectura/vistas/3_analisis_features_y_algoritmos.md`: **catálogo de las ~41 features** (bloques A–H) con cálculo/entrada/placement/fase por feature; **bloque I nuevo** (features de tronco del IMU de cintura, recuperan las lower-back de Brasiliano); **mecanismo de modularidad** de features (catálogo declarativo + set activo versionado, CP-12); **clasificación de algoritmos** (L/E/H/W + footprint/latencia + librería); y **backlog de investigación ordenado** (12 ítems, arranca por IC/TO → segmentación → ZUPT → buffers → …). Referenciado desde `3_vista_datos_ml.md`.

## 2026-07-16 — Reorganización en vistas + anteproyecto + revisión vs fuentes

- **Anteproyecto oficial** incorporado (`docs/Anteproyecto_Tesis.pdf`) y **marco teórico real** en `docs/marco_teorico/marco_teorico_documento_de_trabajo.md`. Revisión de la arquitectura contra ambos: el núcleo (100 Hz, RP2350, one-class personalizado, taxonomía de modelos, edge, Mahalanobis drift-sensor) **coincide**; se detectaron discrepancias y vacíos (ver abajo).
- **Andamiaje de documentación en 4 vistas** (organización tipo C4/4+1): `docs/arquitectura/vistas/` (1 sistema · 2 firmware · 3 datos-ml · 4 backend) + `stack_tecnologico.md` transversal. El maestro pasa a ser **índice/overview** (nueva §0). Regla de layering: se **define en Vista 3**, se **ejecuta en Vista 2** + worker. Migración de contenido: incremental.
- **Hardware confirmado:** IMU **MPU-6050** (el anteproyecto decía BMI270 — a reconciliar, CP-11); **3 FSR por pie pero modular** (soportar N); la **cintura entra** (justificada por topología estrella + simetría + IMU de tronco que recupera features lower-back que el marco daba por perdidas).
- **Objetivos de rendimiento (aspiracionales, no gates):** feedback <50 ms, inferencia <20 ms, sync 10-20 ms.
- **Nuevas cuestiones CP-08 a CP-12:** modularidad FSR/ADC, energía/batería (≥8 h blando), patrones de feedback, reconciliación anteproyecto/marco, modularidad de features.
- **Descartado por ahora:** sincronización con gold-standard/MoCap para validación.
- Actualizados: `CLAUDE.md` (estructura + orden de lectura + regla de layering), maestro (§0), `cuestiones_pendientes.md`.

## 2026-07-16 — Features distribuidas + adquisición determinística

- **Cómputo de features distribuido** (revisión de **ADR-005**, **resuelve CP-02**): cada plantilla calcula sus features **por-pie** + eventos; la cintura hace la **fusión bilateral** (simetría, double support desde eventos), infiere y decide el feedback. Descarga a la cintura y baja el tráfico en edge. La cintura pasa de "hub de cómputo" a **hub de fusión y decisión**.
- **Adquisición determinística a 100 Hz** (nuevo **ADR-014**): ADC disparado por hardware + DMA con **sobremuestreo (~1 kHz) y decimación** a 100 Hz (mejora SNR del FSR √10); IMU en el tick maestro; timestamp+seq por muestra; core dedicado. **Sin componentes extra en el PCB.** Se investigó el estándar de industria (timer/HW-trigger + DMA, no flag por software).
- **Nueva CP-07**: estrategia de lectura del IMU (tick maestro vs FIFO/DATA_READY).
- Actualizados: Arq. §8.1/§8.2/§8.5 + nueva §8.6, §15; bitácora (ADR-005 rev, ADR-014, índice); `docs/cuestiones_pendientes.md` (CP-02→resuelta, +CP-07); `CLAUDE.md`; diagramas `ciclo_de_vida_modelos.mermaid` y `diagrama_arquitectura.mermaid`.

## 2026-07-16 — Revisión de arquitectura: inferencia en tiempo real y cálculo de features

- **Nueva clase de modelo H (Host)** e **inferencia en tiempo real en `hub` o `host`, nunca en el worker/nube** (nuevo **ADR-013**). El worker sólo infiere batch/offline (eval, re-scoring, reportes). `inference_target` pasa de `{micro, worker}` a **`{hub, host, worker}`**; `class` suma `H`.
- **Cálculo de features en la cintura en AMBOS modos** (revisión de **ADR-005**), por simetría de cómputo captura↔edge; el crudo se sigue almacenando (captura: continuo; edge: snippet por anomalía) para re-extracción off-device.
- Actualizados: Arq. §8 (8.1, nueva 8.5 tabla "dónde corre cada operación"), §9 (taxonomía), §11 (DDL `models`); `src/db/schema.sql`; bitácora (ADR-005, ADR-011→L/E/H/W, ADR-013); `CLAUDE.md`; **`ciclo_de_vida_modelos.mermaid`** (ahora muestra crudo en captura + snippet por anomalía + inferencia de clase H).
- **Pendiente de redibujar:** `diagrama_arquitectura.mermaid` (afinar etiquetas de crudo captura/edge + host inference), a bundlear con la decisión de muestreo.

## 2026-07-16 — Registro de cuestiones pendientes separado

- **Nuevo archivo `docs/cuestiones_pendientes.md`**: registro vivo (única fuente de verdad) de cuestiones abiertas, con IDs CP-01 a CP-06 (migradas desde §17 de la arquitectura y "Puntos abiertos" de la bitácora).
- **`docs/arquitectura/Arquitectura_Sistema_Marcha.md` (§17)** y **`docs/decisiones/bitacora_decisiones.md`** ahora **apuntan** a ese registro en vez de listar los puntos.
- **`CLAUDE.md`** actualizado: nueva regla de flujo (paso 1) para que los agentes agreguen/saquen cuestiones en ese archivo, más su inclusión en la estructura del repo.

## 2026-07-16 — Estructuración del repositorio y arquitectura v1.0

- **Repositorio estructurado** por primera vez: `docs/`, `src/` (scaffolding), `memoria/`, `CLAUDE.md`, `README.md`.
- **Arquitectura informática v1.0 definida** y documentada en `docs/arquitectura/`:
  - `Arquitectura_Sistema_Marcha.md` (especificación completa, 17 secciones).
  - `diagrama_arquitectura.mermaid` (topología + flujos).
  - `esquema_base_de_datos.mermaid` (ER de Supabase).
  - `ciclo_de_vida_modelos.mermaid` (drift → reentrenamiento → OTA).
- **Bitácora de decisiones** creada (`docs/decisiones/bitacora_decisiones.md`) con 13 ADRs (000–012) documentando cada decisión, opciones evaluadas, pros/cons y justificación.
- **Investigación previa** incorporada a `docs/investigacion/`: índice bibliográfico, feature set (41 features), pinout, resumen.
- **Objetivos** consolidados en `docs/objetivos.md`.
- **Decisiones tomadas** (ver bitácora): topología WiFi/AP; uplink BLE desde la mínima; transporte UDP+TCP; sync backbone de reloj + evento; features dual-mode + cintura hub; Supabase; Postgres+TimescaleDB+object storage; retención tiered; worker en la nube (máxima); firmware C/C++ Pico SDK; ruteo de modelos por registry (L/E/W); OTA pesos+firmware A/B.

### Pendiente
- Roadmap de implementación por fases.
- Subir marco teórico a `docs/marco_teorico/`.
- Ratificar puntos abiertos (tercer FSR/GP28, cintura-hub vs plantilla, detección de IC, seguridad, `feature_vectors`, proveedor del worker).
- Iniciar código en `src/`.
