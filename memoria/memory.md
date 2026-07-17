# Memoria del proyecto

> Memoria viva para agentes y colaboradores. Registra el **estado actual**, los **aprendizajes** y lo que **sigue**. Actualizar cuando cambie el estado del proyecto o se aprenda algo relevante para otros.

## Propósito y contexto

Juan desarrolla una tesis de maestría centrada en un sistema de **plantillas inteligentes bilaterales** para **detección personalizada de anomalías de marcha en pacientes post-ACV**, con **feedback vibrotáctil en tiempo real** e **inferencia on-device (edge)**. El sistema detecta anomalías usando cálculos de **simetría inter-miembro** habilitados por la configuración bilateral, con enfoque de **personalización primero** en lugar de modelos poblacionales globales.

## Estado actual (2026-07-16)

- **Hardware definido:** Raspberry Pi Pico 2 W (RP2350, Cortex-M33 @150 MHz, 520 KB SRAM), **3 FSR (modular: soportar N)** + IMU 6-DOF **MPU-6050** (confirmado; el anteproyecto decía BMI270 → CP-11) por pie, motor vibrador PWM, muestreo 100 Hz. **Unidad de cintura** con Pico 2 W + MPU-6050 (hub + su IMU capta datos de tronco/lower-back).
- **Fuentes oficiales incorporadas:** `docs/Anteproyecto_Tesis.pdf` (autores: Azcueta Busco, Gramaglia; tutores: Ramele, Papastylianou) y el marco teórico real. La arquitectura fue revisada contra ambos y el núcleo coincide.
- **Feature set consolidado:** 41 features en 8 bloques (A–H). Detalle en `docs/investigacion/features_anomaly_detection_stroke.md`.
- **Algoritmos candidatos:** Mahalanobis, Isolation Forest, autoencoder denso, LSTM autoencoder. Arquitectura jerárquica donde Mahalanobis es detector + sensor de drift.
- **Arquitectura definida y reorganizada en 4 vistas** (`docs/arquitectura/vistas/`: 1 sistema · 2 firmware · 3 datos-ml · 4 backend) + `stack_tecnologico.md`; el maestro es índice/overview. Decisiones en `docs/decisiones/bitacora_decisiones.md` (**ADR-000 a 015**).
- **Convención de trabajo:** cada ítem del backlog → **ADR + spec de algoritmo** (guía de implementación, no código) en su vista. Análisis de features/algoritmos: `vistas/3_analisis_features_y_algoritmos.md`; specs de firmware: `vistas/2_specs_algoritmos_firmware.md`.
- **Repo estructurado:** docs (vistas + decisiones + investigación + marco teórico + anteproyecto) + src (scaffolding) + memoria. Sin código todavía.

## Decisiones de arquitectura tomadas (resumen)

1. Plantillas↔cintura: **WiFi, cintura = AP** (permanente).
2. Cintura↔host: **BLE desde la mínima** (firmware reusado en máxima).
3. Transporte: **UDP stream + TCP control** (GATT notif/writes en BLE).
4. Sync: **backbone de reloj** (timestamp+seq+beacon+drift) + emparejado por evento IC (refinamiento).
5. Features: **cómputo distribuido** — por-pie en cada plantilla; la cintura **fusiona** (simetría, double support). Definición compartida plantilla↔cintura↔worker (resuelve CP-02).
6. DB/hosting: **Supabase**; entrenamiento en worker aparte.
7. Modelo de datos: **Postgres + TimescaleDB + object storage**.
8. Retención: **tiered por fase** (+ crudo por anomalía).
9. Backend de reentrenamiento (máxima): **worker en la nube** (E/W); micro mantiene L.
10. Firmware: **C/C++ con Pico SDK**.
11. Ruteo de modelos: **clase declarada en el registry (L/E/H/W)**.
12. OTA: **pesos + firmware completo (A/B)**.
13. Inferencia en tiempo real: en **hub o host, nunca en el worker/nube** (clase H); el worker sólo batch/offline.
14. Muestreo determinístico: **ADC por hardware + DMA, sobremuestreo ~1 kHz → decimación a 100 Hz**; IMU en tick maestro.
15. Detección de eventos IC/TO: **fusión FSR + IMU, en la plantilla** (resuelve CP-03; ver SPEC-01).

## Aprendizajes y principios

- **Personalización crítica:** one-class personalizado AUC≈0,967 vs. ~55 % de modelos globales (Toth et al.). Ancla toda la filosofía.
- **Economía de features:** sweet spot ~15–25 features; más agrega ruido (Chen plateauó en 18, Brasiliano en 9).
- **Features dinámicas/frecuencia > posicionales** para riesgo de caída (Herbers, AUC=0,91).
- **Sincronización:** el backbone de reloj hace el trabajo pesado (features de ventana/simultaneidad lo requieren); el emparejado por evento es refinamiento, no el mecanismo primario. Corrección importante registrada en ADR-004.
- **Modelos "muy sencillos" (probabilísticos) se reentrenan localmente en el micro dato a dato** (clase L) y no tocan el worker. El reparto exacto depende de qué modelos se prueben → registry declara la clase.
- **BLE desde la mínima es válido** porque el firmware del micro es agnóstico al central (laptop o celular): se reutiliza al 100 %.

## Qué sigue

- **Backlog de investigación en curso** (`vistas/3_analisis_features_y_algoritmos.md` §D). Hecho: **#1 detección IC/TO** (ADR-015 / SPEC-01). Siguiente: #2 segmentación de fases → #3 ZUPT/stride length → #4 buffers → #5 orientación → …
- **Migración incremental** del contenido detallado del maestro a las 4 vistas.
- Ratificar cuestiones abiertas (`docs/cuestiones_pendientes.md`): CP-01, CP-04 a CP-12 (incl. CP-07). **Resueltas: CP-02, CP-03.**
- **Roadmap de implementación por fases** (documento aparte, más adelante).
- Iniciar `src/` (firmware, worker, db, host).

## Recursos

- Anteproyecto oficial: `docs/Anteproyecto_Tesis.pdf`
- Arquitectura (índice): `docs/arquitectura/Arquitectura_Sistema_Marcha.md` + **vistas** en `docs/arquitectura/vistas/` + `stack_tecnologico.md`
- Decisiones: `docs/decisiones/bitacora_decisiones.md` (ADR-000 a 015)
- Cuestiones pendientes: `docs/cuestiones_pendientes.md`
- Investigación: `docs/investigacion/`
- Marco teórico: `docs/marco_teorico/marco_teorico_documento_de_trabajo.md` (~17.700 palabras)
