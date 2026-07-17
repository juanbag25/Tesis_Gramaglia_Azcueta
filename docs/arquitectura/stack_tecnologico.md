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
| Adquisición | `hardware_adc`, `hardware_dma`, `hardware_timer`, `hardware_pio` | ADC+DMA, pacing, timestamp | decidido (ADR-014) |
| WiFi | **lwIP** (vía Pico SDK) | UDP/TCP, AP/STA | decidido |
| BLE | **BTstack** (vía Pico SDK) | GATT servidor (uplink) | decidido |
| Inferencia int8 | **TFLite Micro** | AE denso / LSTM cuantizados | candidato |
| DSP | **CMSIS-DSP** o kernels propios | decimación, filtrado, Mahalanobis | a definir |
| IMU | driver I²C MPU-6050 | lectura accel+gyro | decidido (sensor) |
| RTOS | bare-metal vs **FreeRTOS** | scheduling de cores | a definir |

## Vista 3 — Datos y ML (Python)

| Componente | Librería / módulo | Propósito | Estado |
|---|---|---|---|
| Numérico | numpy, scipy, pandas | señales, features, datos | candidato |
| Clásicos | **scikit-learn** | Isolation Forest, ajuste Mahalanobis | candidato |
| Deep learning | **PyTorch** o **TensorFlow/Keras** | autoencoders (denso/LSTM) | a definir |
| Cuantización | **TFLite converter** | export int8 al micro | candidato |

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
