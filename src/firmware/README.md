# firmware/ — Firmware on-device (C/C++, Pico SDK)

Firmware para los tres micros (Raspberry Pi Pico 2 W, RP2350). **C/C++ con el Pico SDK** (no Arduino IDE) — ver ADR-010.

## Subcarpetas

- `insole/` — firmware de las **plantillas**: muestreo de IMU (I²C) + 3 FSR (ADC) a 100 Hz, detección de contacto inicial (IC) propio, timestamp+secuencia por muestra, WiFi STA hacia la cintura, control del motor vibrador (PWM), recepción de comandos de feedback.
- `waist/` — firmware de la **cintura (hub)**: WiFi AP para las plantillas, maestro de sincronización (beacon + drift), fusión bilateral, cálculo de features (modo edge), inferencia de modelos clase L/E (int8), sensor de drift, uplink BLE al host, gestión de OTA.
- `shared/` — código **compartido**: definición canónica de features (debe coincidir con `worker/`), formato de paquetes (stream/control), protocolo de sincronización, protocolo y bootloader OTA A/B.

## Responsabilidades por clase de modelo

- **Clase L:** inferencia + reentrenamiento **en el micro** (dato a dato). Ej.: Mahalanobis (media + inversa de covarianza actualizadas por EMA).
- **Clase E:** inferencia **en el micro** (TFLite Micro, int8); los pesos se reciben por OTA desde el worker.
- **Clase W:** no corre en el micro (inferencia/reentrenamiento en el worker).

## Bibliotecas / dependencias previstas

- Pico SDK (lwIP para WiFi, BTstack para BLE), TFLite Micro (inferencia int8), driver I²C para MPU-6050, ADC para FSR, PWM para el motor.

## Notas de hardware

- Pinout en `docs/investigacion/pinout_pico2.md` (3er FSR en ADC2/GP28, a confirmar contra el PCB).
- Coexistencia WiFi-AP + BLE en el CYW43439 (un solo radio): validar temprano (riesgo conocido).

> **Pendiente:** inicializar el proyecto CMake del Pico SDK y los esqueletos de `insole/`, `waist/`, `shared/`.
