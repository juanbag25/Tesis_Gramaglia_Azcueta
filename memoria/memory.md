# Memoria del proyecto

> Memoria viva para agentes y colaboradores. Registra el **estado actual**, los **aprendizajes** y lo que **sigue**. Actualizar cuando cambie el estado del proyecto o se aprenda algo relevante para otros.

## Propósito y contexto

Juan desarrolla una tesis de maestría centrada en un sistema de **plantillas inteligentes bilaterales** para **detección personalizada de anomalías de marcha en pacientes post-ACV**, con **feedback vibrotáctil en tiempo real** e **inferencia on-device (edge)**. El sistema detecta anomalías usando cálculos de **simetría inter-miembro** habilitados por la configuración bilateral, con enfoque de **personalización primero** en lugar de modelos poblacionales globales.

## Estado actual (2026-07-16)

- **Hardware definido:** Raspberry Pi Pico 2 W (RP2350, Cortex-M33 @150 MHz, 520 KB SRAM), 3 FSR + IMU 6-DOF (MPU-6050) por pie, motor vibrador PWM, muestreo 100 Hz. Unidad de cintura con Pico 2 W + MPU-6050.
- **Feature set consolidado:** 41 features en 8 bloques (A–H). Detalle en `docs/investigacion/features_anomaly_detection_stroke.md`.
- **Algoritmos candidatos:** Mahalanobis, Isolation Forest, autoencoder denso, LSTM autoencoder. Arquitectura jerárquica donde Mahalanobis es detector + sensor de drift.
- **Arquitectura informática definida (v1.0):** ver `docs/arquitectura/`. Todas las decisiones registradas en `docs/decisiones/bitacora_decisiones.md`.
- **Repo estructurado:** docs + src (scaffolding) + memoria. Sin código todavía.

## Decisiones de arquitectura tomadas (resumen)

1. Plantillas↔cintura: **WiFi, cintura = AP** (permanente).
2. Cintura↔host: **BLE desde la mínima** (firmware reusado en máxima).
3. Transporte: **UDP stream + TCP control** (GATT notif/writes en BLE).
4. Sync: **backbone de reloj** (timestamp+seq+beacon+drift) + emparejado por evento IC (refinamiento).
5. Features: **dual-mode** (captura/edge) + **cintura como hub**, definición compartida PC↔micro.
6. DB/hosting: **Supabase**; entrenamiento en worker aparte.
7. Modelo de datos: **Postgres + TimescaleDB + object storage**.
8. Retención: **tiered por fase** (+ crudo por anomalía).
9. Backend de reentrenamiento (máxima): **worker en la nube** (E/W); micro mantiene L.
10. Firmware: **C/C++ con Pico SDK**.
11. Ruteo de modelos: **clase declarada en el registry (L/E/W)**.
12. OTA: **pesos + firmware completo (A/B)**.

## Aprendizajes y principios

- **Personalización crítica:** one-class personalizado AUC≈0,967 vs. ~55 % de modelos globales (Toth et al.). Ancla toda la filosofía.
- **Economía de features:** sweet spot ~15–25 features; más agrega ruido (Chen plateauó en 18, Brasiliano en 9).
- **Features dinámicas/frecuencia > posicionales** para riesgo de caída (Herbers, AUC=0,91).
- **Sincronización:** el backbone de reloj hace el trabajo pesado (features de ventana/simultaneidad lo requieren); el emparejado por evento es refinamiento, no el mecanismo primario. Corrección importante registrada en ADR-004.
- **Modelos "muy sencillos" (probabilísticos) se reentrenan localmente en el micro dato a dato** (clase L) y no tocan el worker. El reparto exacto depende de qué modelos se prueben → registry declara la clase.
- **BLE desde la mínima es válido** porque el firmware del micro es agnóstico al central (laptop o celular): se reutiliza al 100 %.

## Qué sigue

- **Roadmap de implementación por fases** (próximo entregable, documento aparte).
- Ratificar cuestiones pendientes (registro vivo en `docs/cuestiones_pendientes.md`, CP-01 a CP-06).
- Subir el marco teórico a `docs/marco_teorico/`.
- Iniciar `src/` (firmware, worker, db, host).

## Recursos

- Arquitectura: `docs/arquitectura/Arquitectura_Sistema_Marcha.md`
- Decisiones: `docs/decisiones/bitacora_decisiones.md`
- Investigación: `docs/investigacion/`
- Marco teórico (a subir): documento de trabajo ~17.700 palabras, 11 bloques.
