# Stack tecnológico

> **Documento transversal:** fuente única de verdad del mapeo **componente → librería/módulo → propósito**. Organizado por vista. También es el "qué necesito instalar para trabajar acá".
>
> **Reglas:**
> - Las elecciones significativas de librería son **decisiones** → cada una tiene su **ADR** en `../decisiones/bitacora_decisiones.md`.
> - **No se fijan versiones de memoria**: se verifican y anclan al implementar. Estado `decidido` = elegido; `candidato` = probable, a confirmar; `a definir` = sin decidir.
>
> **Estado:** andamiaje. Se completa a medida que avanza el backlog de investigación.

## Vista 2 — Firmware (C/C++)

| Componente | Librería / módulo | Propósito | Estado |
|---|---|---|---|
| Base | Raspberry Pi **Pico SDK** (C/C++) | HAL, build (CMake), dual-core | decidido (ADR-010) |
| Adquisición | `hardware_adc`, `hardware_dma`, `hardware_timer`, `hardware_pio`, `hardware_i2c` | ADC+DMA (FSR), I²C+DMA (IMU), pacing, timestamp | decidido (ADR-014/026) |
| WiFi | **lwIP** (vía Pico SDK) | UDP/TCP, AP/STA | decidido |
| BLE | **BTstack** (vía Pico SDK) | GATT servidor (uplink) + Security Manager (pairing: Passkey Entry + bond list) | decidido (ADR-028) |
| Inferencia int8 (NN) | **TFLite Micro + CMSIS-NN** (`pico-tflmicro`) | ejecutar AE denso int8 (y LSTM si entra): intérprete TFLM + kernels int8 de ARM | decidido (ADR-020) |
| Catálogo de features + paridad | data file (JSON/TOML) en `shared/` + impl C + espejo Python + **golden tests** en CI | definición única de features; anti train/serve skew | decidido (ADR-021) |
| DSP | **CMSIS-DSP** (float32) | FFT/PSD (bloque H), decimación/filtrado FIR, álgebra (Mahalanobis) | decidido (ADR-019) |
| IMU | driver I²C MPU-6050 | lectura accel+gyro (**tick maestro + DMA**; ODR alto + DLPF; DATA_READY fallback) | decidido (sensor; ADR-026) |
| Orientación / AHRS | **Fusion** (xioTechnologies, Madgwick) | orientación + accel lineal sin gravedad; bias de giro en runtime | candidato (ADR-017) |
| RTOS | **bare-metal** (Pico SDK, sin RTOS) | scheduling a mano: `multicore_launch_core1` + `queue_t`/FIFO + IRQs por-core | decidido (ADR-025) |

## Vista 3 — Datos y ML (Python)

| Componente | Librería / módulo | Propósito | Estado |
|---|---|---|---|
| Numérico | numpy, scipy, pandas | señales, features, datos | candidato |
| Clásicos | **scikit-learn** | Isolation Forest, ajuste Mahalanobis | candidato |
| Deep learning | **TensorFlow/Keras** | autoencoders (denso/LSTM) | decidido (ADR-022) |
| Cuantización | **conversor TFLite/LiteRT** (PTQ int8, representative dataset) | export int8 al micro; QAT como fallback | decidido (ADR-022) |
| Orientación (paridad, condicional) | **`imufusion`** (Python) | re-extraer features del IMU desde el **crudo** off-device (paridad con Fusion); **no** se usa en el camino edge | candidato (ADR-017) |

## Vista 4 — Backend y aplicación

| Componente | Librería / módulo | Propósito | Estado |
|---|---|---|---|
| DB / plataforma | **Supabase** (Postgres + TimescaleDB + Storage + Auth) | persistencia, storage de modelos, auth/RLS | decidido (ADR-006/007) |
| Worker ↔ DB | **supabase-py** | pull datos / push modelos | candidato |
| App host (mínima) | **bleak** (Python) | central BLE, ingesta | candidato |
| App móvil (máxima) | *(a definir)* | ingesta + puente + OTA | a definir |
| Dashboard | *(a definir: React+Supabase / Streamlit / Plotly Dash)* | visualización clínica | a definir |
| Migraciones DB | Supabase migrations o similar | versionado del esquema | a definir |

## Vista 1 — Sistema (transversal)
El transporte (lwIP/BTstack) y la sincronización (código propio de capa de aplicación) se implementan en el firmware (Vista 2). No hay librerías propias de esta vista.
