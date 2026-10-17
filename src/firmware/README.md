# firmware/ — Firmware on-device (C/C++, Pico SDK)

Firmware para los tres micros (Raspberry Pi Pico 2 W, RP2350). **C/C++ con el Pico SDK**, bare-metal (ADR-010, ADR-025). Reparto de cores uniforme en los tres: **core 0 = radio, core 1 = procesamiento** (ADR-024 rev).

## Subcarpetas

- `insole/` — **plantillas**: adquisición determinística a 100 Hz (FSR por ADC + DMA con sobremuestreo y decimación; IMU MPU-6050 leído en el tick maestro por DMA — ADR-014/026), AHRS en el micro (el crudo sale post-AHRS — ADR-042), detección de eventos **IC/TO/MS** y numeración de zancadas (`stride_seq` — SPEC-01/02, ADR-046), features **por-pie** en captura operativa y edge (ADR-005 rev c), ring buffer de crudo y motor PWM.
- `waist/` — **cintura (hub)**: WiFi AP para las plantillas, maestro de sincronización (beacon + drift — ADR-004), fusión bilateral y numeración de ciclos (`cycle_seq`), inferencia de clases L/E (SPEC-08), decisión de feedback (SPEC-09), uplink BLE al host (servicio de ADR-051, definido en un `.gatt`; pairing ADR-028), ciclo de vida de la sesión (SPEC-11) y OTA A/B sobre el bootrom del RP2350 (ADR-052).
- `shared/` — **código compartido**: catálogo `features.toml` y su tabla de C generada (ADR-021/054), formato de la muestra, `mensajes.proto` (nanopb — ADR-050), sincronización, protocolo OTA (ADR-052) y cargador del sobre de los artefactos (ADR-053).

**Guías de implementación:** `docs/arquitectura/vistas/2_specs_algoritmos_firmware.md` (SPEC-01 a SPEC-11). Overview: Vista 2.

## Clases de modelo que corren acá (ADR-011 rev)

- **L:** infiere y se adapta en la cintura (Mahalanobis); el estado adaptado vive en RAM y sube en el check-in de la sesión (ADR-043 rev).
- **E:** infiere en la cintura —AE denso int8 con TFLite Micro + CMSIS-NN; Isolation Forest recorriendo árboles en C—, reentrena el worker y llega por OTA.
- **H / W:** no corren en el micro (host en tiempo real / worker offline).

## Dependencias previstas

Pico SDK (lwIP, BTstack, `pico_sha256`), **nanopb**, **CMSIS-DSP**, **TFLite Micro + CMSIS-NN** (`pico-tflmicro`: validar en RP2350 — CP-21), **Fusion** (AHRS). Las versiones se anclan al implementar (`docs/arquitectura/stack_tecnologico.md`).

## Notas de hardware

- **2 FSR hoy** (punta ADC0/GP26, talón ADC1/GP27); máximo de diseño 4, con mux en la próxima revisión del PCB (ADR-041). Pinout: `docs/investigacion/pinout_pico2.md`.
- Coexistencia WiFi-AP + BLE en el CYW43439 (un solo radio): validar temprano.
- Antes de sellar una plantilla el OTA tiene que estar probado: al cerrarla se pierde el acceso al BOOTSEL.

> **Contratos definidos** (ADR-050 a 056; tabla en la Vista 1 §4): mensajes, tabla GATT, protocolo OTA, sobre de los artefactos, catálogo y base de tiempo (`t_device` = cuenta de la cintura). **Pendiente:** inicializar el proyecto CMake del Pico SDK con los esqueletos de `insole/`, `waist/` y `shared/`, y verificar en el datasheet del RP2350 el arranque "a prueba" del bootrom antes de implementar el OTA de firmware.
