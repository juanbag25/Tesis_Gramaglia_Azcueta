# Vista 2 — Dispositivo / Firmware

> **Nivel de abstracción:** internals de los micros (C/C++, Pico SDK). Cómo cada dispositivo **adquiere, procesa y actúa** en tiempo real. Aquí vive la **ejecución** de los algoritmos; su **definición** canónica está en la Vista 3 (regla: se define en V3, se ejecuta en V2 + worker).
>
> **Estado:** andamiaje. Detalle actual en el maestro; se completa con el backlog de investigación.
>
> **Specs de algoritmos (guías de implementación):** `2_specs_algoritmos_firmware.md`. Definido: **SPEC-01 — detección de IC/TO** (ADR-015).

## Alcance (qué vive en esta vista)

- **Adquisición determinística (100 Hz):** ADC disparado por hardware + DMA, sobremuestreo ~1 kHz + decimación; IMU en tick maestro; timestamp+seq; core dedicado. → maestro §8.6 (ADR-014).
- **Detección de eventos IC/TO:** función núcleo del firmware (umbral FSR + confirmación IMU). Alimenta features, sync y timing de feedback.
- **Módulo de features por-pie (ejecución):** cálculo por zancada; **buffer ≥10 zancadas** para variabilidad; **stride length por ZUPT**; **COP_ML 1D** (con coordenadas de FSR como config); **LDLJ sólo en swing**.
- **Inferencia on-device:** clases L (Mahalanobis) y E (autoencoder int8) en la cintura; feedback en tiempo real.
- **Lógica de feedback:** severidad → patrón de vibración (≥3 patrones, config por paciente); PWM del motor.
- **Buffer circular de crudo** (para snippets ante anomalía) en cada plantilla.
- **OTA A/B** (pesos + firmware), bootloader, checksum, rollback. → maestro §10.2 (ADR-012).
- **Asignación de cores:** core 1 adquisición; core 0 radio + features/decisión (a confirmar).

**Diagrama de esta vista:** *(a crear — internals del firmware: pipeline de adquisición → features → inferencia → feedback).*

## ADRs relevantes
ADR-010 (C/C++ Pico SDK), ADR-014 (adquisición), ADR-012 (OTA), ADR-004 (sync — refinamiento por evento), ADR-005 (features distribuidas — ejecución).

## Stack (resumen; detalle en `../stack_tecnologico.md`)
Pico SDK (`hardware_adc/dma/timer/pio`), lwIP, BTstack, TFLite Micro (int8), CMSIS-DSP o kernels propios, driver I²C MPU-6050.

## Pendiente de definir / investigar (backlog)
- ✅ **CP-03 resuelto (ADR-015 / SPEC-01):** detección de IC/TO **en la plantilla**, fusión **FSR-primario + confirmación IMU**.
- **Stride length / ZUPT:** variante (ZUPT simple vs MSDI / MFD-GED).
- **Runtime de inferencia int8:** TFLite Micro vs kernels propios; cómo corren Mahalanobis / Isolation Forest en el micro.
- **DSP on-device:** decimación/filtrado con CMSIS-DSP vs propio.
- **Bare-metal vs RTOS** (ej. FreeRTOS) en el Pico; scheduling de los dos cores.
- **Módulo de features compartido** (C ↔ Python): mecanismo para garantizar paridad.
- **Patrones de feedback (CP-10):** diseño de los ≥3 patrones y la lógica de disparo.
