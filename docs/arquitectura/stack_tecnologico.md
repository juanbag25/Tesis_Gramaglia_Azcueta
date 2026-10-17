# Stack tecnológico

> **Documento transversal:** fuente única de verdad del mapeo **componente → librería/módulo → propósito**. Organizado por vista. También es el "qué necesito instalar para trabajar acá".
>
> **Reglas:**
> - Las elecciones significativas de librería son **decisiones** → cada una tiene su **ADR** en `../decisiones/bitacora_decisiones.md`.
> - **No se fijan versiones de memoria**: se verifican y anclan al implementar. Estado `decidido` = elegido; `candidato` = probable, a confirmar; `a definir` = sin decidir.
>
> **Estado:** al día con las 4 vistas consolidadas y con el backlog #1–#10 resuelto. Las filas marcadas `a definir` corresponden a la **máxima** (app móvil, dashboard) o a decisiones de implementación aún no tomadas.

## Vista 2 — Firmware (C/C++)

| Componente | Librería / módulo | Propósito | Estado |
|---|---|---|---|
| Base | Raspberry Pi **Pico SDK** (C/C++) | HAL, build (CMake), dual-core | decidido (ADR-010) |
| Adquisición | `hardware_adc`, `hardware_dma`, `hardware_timer`, `hardware_pio`, `hardware_i2c` | ADC+DMA (FSR), I²C+DMA (IMU), pacing, timestamp | decidido (ADR-014/026) |
| WiFi | **lwIP** (vía Pico SDK) | UDP/TCP, AP/STA | decidido |
| BLE | **BTstack** (vía Pico SDK) | GATT servidor (uplink) + Security Manager (pairing: Passkey Entry + bond list) | decidido (ADR-028) |
| Tabla GATT | archivo `.gatt` + `compile_gatt` de BTstack (CMake: `pico_btstack_make_gatt_header`) | servicio propio (`stream`, `zancadas`, `estado`, `control`, `ota`) + Battery y Device Information | decidido (ADR-051) |
| Mensajes | **nanopb** (C generado desde `mensajes.proto`, sin memoria dinámica) | serializar y versionar los mensajes que no son la muestra | decidido (ADR-050) |
| OTA | protocolo propio + **bootrom del RP2350** (particiones A/B, `explicit_buy`) + `pico_sha256` (SHA-256 por hardware) | transferir y conmutar modelos y firmware, con vuelta atrás | decidido (ADR-052) |
| Inferencia int8 (NN) | **TFLite Micro + CMSIS-NN** (`pico-tflmicro`) | ejecutar AE denso int8 (y LSTM si entra): intérprete TFLM + kernels int8 de ARM | decidido (ADR-020) |
| Catálogo de features + paridad | **`features.toml`** en `shared/` + tabla de C generada + impl C + espejo Python + **golden tests** en CI | definición única de features; anti train/serve skew | decidido (ADR-021, ADR-054) |
| DSP | **CMSIS-DSP** (float32) | FFT/PSD (bloque H), decimación/filtrado FIR, álgebra (Mahalanobis) | decidido (ADR-019) |
| IMU | driver I²C MPU-6050 | lectura accel+gyro (**tick maestro + DMA**; ODR alto + DLPF; DATA_READY fallback) | decidido (sensor; ADR-026) |
| Orientación / AHRS | **Fusion** (xioTechnologies, Madgwick) | orientación + accel lineal sin gravedad; bias de giro en runtime | decidido (ADR-017) |
| RTOS | **bare-metal** (Pico SDK, sin RTOS) | scheduling a mano: `multicore_launch_core1` + `queue_t`/FIFO + IRQs por-core | decidido (ADR-025) |

## Vista 3 — Datos y ML (Python)

| Componente | Librería / módulo | Propósito | Estado |
|---|---|---|---|
| Numérico | numpy, scipy, pandas | señales, features, datos | candidato |
| Clásicos | **scikit-learn** | Isolation Forest, ajuste Mahalanobis | candidato |
| Deep learning | **TensorFlow/Keras** | autoencoders (denso/LSTM) | decidido (ADR-022) |
| Cuantización | **conversor TFLite/LiteRT** (PTQ int8, representative dataset) | export int8 al micro; QAT como fallback | decidido (ADR-022) |
| Catálogo (lectura) | `tomllib` (biblioteca estándar, Python ≥ 3.11) | leer `features.toml` | decidido (ADR-054) |
| Crudo (lectura) | **pyarrow** | leer los tramos Parquet del crudo | decidido (ADR-055) |
| Orientación (paridad, condicional) | **`imufusion`** (Python) | **ya no hace falta para re-extraer features**: el crudo llega post-AHRS y el worker no re-procesa IMU (ADR-042) | no requerido (ADR-042) |

## Vista 4 — Backend y aplicación

| Componente | Librería / módulo | Propósito | Estado |
|---|---|---|---|
| DB / plataforma | **Supabase** (Postgres 17 + Storage + Auth) | persistencia, storage de modelos, auth/RLS | decidido (ADR-006/007/044) |
| Series particionadas | **`pg_partman`** + **`pg_cron`** (extensiones de Postgres en Supabase) | particiones mensuales creadas por adelantado; mantenimiento diario y cierre de particiones | decidido (ADR-044/047) |
| Worker ↔ DB | **supabase-py** | pull datos / push modelos | candidato |
| App host (mínima) | **bleak** (Python) | central BLE, ingesta | decidido (ADR-033) |
| Mensajes (host y worker) | **protobuf** (librería oficial de Python, código generado desde `mensajes.proto`) | leer y escribir los mensajes del equipo | decidido (ADR-050) |
| Crudo (escritura) | **pyarrow** (Parquet + zstd) | el host escribe el crudo por tramos | decidido (ADR-055) |
| UI de control (mínima) | **FastAPI** + página web servida por el mismo proceso de ingesta | elegir paciente, abrir/cerrar sesión, cambiar el modo, ver estado, disparar OTA | decidido (ADR-033) |
| App móvil (máxima) | *(a definir)* | ingesta + puente + OTA | a definir |
| Dashboard | *(a definir: React+Supabase / Streamlit / Plotly Dash)* | visualización clínica | a definir |
| Migraciones DB | **CLI de Supabase** (proyecto en `src/db/supabase/`, `--workdir src/db`) + **Docker** (base local) | migraciones versionadas, base local reproducible, snapshot `schema.sql`, `db push` desde CI | decidido (ADR-045) |
| Tests de base | **pgTAP** (`supabase test db`) | aislamiento entre pacientes, grants, RLS en tablas y particiones, integridad, idempotencia | decidido (ADR-045/047) |
| CI de la base | **GitHub Actions** | base efímera → migraciones → pgTAP → chequeo del snapshot → `db push` desde `master` | decidido (ADR-045) |

## Vista 1 — Sistema (transversal)
El transporte (lwIP/BTstack) y la sincronización (código propio de capa de aplicación) se implementan en el firmware (Vista 2). No hay librerías propias de esta vista: los contratos entre programas (ADR-050 a 056) usan las de las filas de arriba —nanopb y protobuf, el `.gatt` de BTstack, pyarrow y `tomllib`—.
