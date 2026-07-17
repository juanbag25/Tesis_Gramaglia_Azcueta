# CLAUDE.md — Guía para agentes de IA

> Este archivo es el punto de entrada para **cualquier agente de IA** (o persona) que trabaje en este repositorio. Léelo completo antes de tocar nada. Su objetivo es dar **entendimiento total del proyecto** para que cualquiera pueda clonar el repo y ponerse a trabajar de inmediato.

## Qué es este proyecto (en una línea)

Sistema de **plantillas inteligentes bilaterales** para **detección personalizada de anomalías de marcha en pacientes post-ACV**, con **feedback vibrotáctil en tiempo real** e **inferencia en el borde (edge)**. Tesis de maestría (ITBA).

**Estado actual:** arquitectura definida (v1.0). Sin código todavía. Próximo paso: roadmap de implementación por fases.

## Orden de lectura recomendado (onboarding)

1. `docs/Anteproyecto_Tesis.pdf` — el anteproyecto oficial (problema, objetivos mínima/máxima, metodología). Define la tesis.
2. `docs/objetivos.md` — objetivos consolidados y filosofía.
3. `docs/arquitectura/Arquitectura_Sistema_Marcha.md` — **índice/overview** de la arquitectura; enlaza las **4 vistas** en `docs/arquitectura/vistas/` (1 sistema · 2 firmware · 3 datos-ml · 4 backend) y el `stack_tecnologico.md`. El detalle vive en las vistas.
4. `docs/decisiones/bitacora_decisiones.md` — por qué cada decisión, con opciones y pros/cons (ADRs).
5. `docs/investigacion/resumen_investigacion.md` + `features_anomaly_detection_stroke.md` + `docs/marco_teorico/marco_teorico_documento_de_trabajo.md` — la evidencia que fundamenta el diseño.
6. `memoria/memory.md` — estado vivo del proyecto y aprendizajes acumulados.
7. Los diagramas `.mermaid` en `docs/arquitectura/` (topología, base de datos, ciclo de vida de modelos).

**Regla de layering:** cada feature/algoritmo se **define una vez en la Vista 3** (datos/ML) y se **ejecuta en la Vista 2** (firmware) y en el worker. El detalle de cada faceta va en su vista, no en el maestro.

**Convención de specs:** cada ítem del backlog de investigación (ver `docs/arquitectura/vistas/3_analisis_features_y_algoritmos.md` §D) que se resuelve produce **(a) un ADR** en la bitácora y **(b) una spec de algoritmo** (guía de implementación concisa: definición, señales, parámetros, salida, referencias — NO código) en su vista: firmware en `vistas/2_specs_algoritmos_firmware.md`. La spec fija las decisiones de dominio; la mecánica de codificación queda para quien implementa.

## Resumen de la arquitectura (lo mínimo que un agente debe saber)

- **Hardware:** 2 plantillas (Raspberry Pi Pico 2 W + MPU-6050 + 3 FSR + motor vibrador PWM) + 1 unidad de cintura (Pico 2 W + MPU-6050). Muestreo **100 Hz**.
- **Topología:** plantillas ↔ cintura por **WiFi** (cintura = **Access Point**); cintura ↔ host por **BLE** (desde la mínima). La cintura es el **hub de fusión y decisión** (las plantillas calculan sus features por-pie).
- **Transporte:** canal rápido-tolerante (**UDP** / notificaciones GATT) para el stream + canal confiable (**TCP** / writes con ACK) para control y modelos.
- **Sincronización:** backbone de reloj (**timestamp + secuencia por muestra + beacon periódico + corrección de drift**), en capa de aplicación (portable WiFi↔BLE); emparejado de zancadas por evento (heel-strike/IC) como **refinamiento**.
- **Cómputo de features distribuido:** cada plantilla calcula sus features **por-pie** (en ambos modos); la cintura hace la **fusión bilateral** (simetría, double support desde eventos). Los modos difieren en qué se transmite/almacena — *captura* (features + **crudo continuo** → host, para dataset) y *edge* (features + eventos en vivo + **crudo por snippet ante anomalía**). **Única definición de features compartida** plantilla↔cintura↔worker.
- **Muestreo determinístico (100 Hz):** ADC disparado por hardware + DMA con **sobremuestreo (~1 kHz) y decimación** a 100 Hz (mejora SNR del FSR); IMU leído en el tick maestro; **timestamp + secuencia por muestra**; core dedicado a adquisición. Todo interno al RP2350, **sin componentes extra en el PCB**.
- **Persistencia:** **Supabase** (PostgreSQL + TimescaleDB + object storage + auth). Supabase **no entrena**; el entrenamiento corre en un worker (laptop en mínima, nube en máxima).
- **Modelos (taxonomía L/E/H/W):** cada modelo declara su clase en el registry (`inference_target ∈ {hub, host, worker}`).
  - **L (Local-Local):** infiere y reentrena en la cintura, dato a dato (Mahalanobis EMA, probabilísticos simples).
  - **E (Edge+Worker):** infiere en la cintura (int8), reentrena en el worker (autoencoder denso).
  - **H (Host):** infiere en el host (celular/laptop) en tiempo real cuando el modelo no entra en la cintura; reentrena en el worker.
  - **W (Worker-heavy):** infiere/reentrena en el worker, **batch/offline** (LSTM AE, Isolation Forest) — nunca en tiempo real.
  - **Inferencia en tiempo real (feedback): en `hub` o `host`, nunca en el worker/nube.** Mahalanobis también es **sensor de drift** que dispara el reentrenamiento de E/H/W.
- **Firmware:** **C/C++ con el Pico SDK** (no Arduino IDE).
- **OTA:** pesos + firmware completo, esquema **A/B** con checksum y rollback.

## Estructura del repositorio

```
tesis/
├── CLAUDE.md                  # este archivo — onboarding de agentes
├── README.md                  # descripción humana + setup
├── docs/
│   ├── objetivos.md
│   ├── cuestiones_pendientes.md  # registro vivo de cuestiones abiertas (única fuente de verdad)
│   ├── Anteproyecto_Tesis.pdf    # anteproyecto oficial (define la tesis)
│   ├── arquitectura/          # maestro (índice) + vistas/ (1 sistema · 2 firmware · 3 datos-ml · 4 backend) + stack_tecnologico.md + diagramas
│   ├── decisiones/            # bitácora de decisiones (ADRs) — alimenta el informe de tesis
│   ├── investigacion/         # bibliografía, features, pinout, resumen
│   └── marco_teorico/         # marco teórico (documento de trabajo)
├── src/                       # CÓDIGO — donde trabajan los agentes
│   ├── firmware/              # C/C++ Pico SDK
│   │   ├── insole/            # firmware de las plantillas
│   │   ├── waist/             # firmware de la cintura (hub)
│   │   └── shared/            # protocolo, definición de features, sync (compartido)
│   ├── host/                  # app de ingesta/puente (laptop → celular)
│   ├── worker/                # reentrenamiento (Python): laptop (mínima) / nube (máxima)
│   └── db/                    # esquema SQL / migraciones
└── memoria/
    ├── memory.md              # memoria viva del proyecto
    └── changelog.md           # registro cronológico de cambios
```

## Dónde trabaja cada agente

- **Firmware (C/C++ Pico SDK):** `src/firmware/`. `insole/` y `waist/` comparten código en `shared/` (definición de features, formato de paquetes, sync, protocolo OTA). La definición de features en `shared/` **debe coincidir** con la del worker (misma semántica, versionada).
- **App host / puente:** `src/host/`. Ingesta por BLE, buffer local, puente OTA, escritura a Supabase.
- **Worker de reentrenamiento (Python):** `src/worker/`. Entrena clases E/W, cuantiza a int8, publica modelos al registry.
- **Base de datos:** `src/db/`. Esquema Postgres + TimescaleDB (ver `schema.sql`) y migraciones. Estructura de la base documentada en `docs/arquitectura/` (§11 y `esquema_base_de_datos.mermaid`).

## Convenciones e invariantes (no romper sin un ADR nuevo)

- **Idioma de la documentación:** español (Argentina).
- **Cintura = AP** y **hub de fusión/decisión**: es un invariante del sistema (permanente mínima→máxima). Las plantillas calculan sus features por-pie; la cintura fusiona (simetría, double support), infiere y decide el feedback.
- **Definición de features única y compartida** PC↔micro, versionada por `feature_set_version`. Nunca dupliques fórmulas divergentes.
- **Sincronización a nivel de aplicación** (portable WiFi↔BLE): no la ates a un transporte.
- **El registry declara la clase de cada modelo** (L/E/W): no hardcodees el ruteo.
- **Personalización primero:** baseline por paciente; evita modelos poblacionales salvo justificación.
- **Datos de salud:** cifrado en tránsito/reposo, RLS por paciente, `external_code` anónimo; minimiza PII.

## Flujo de trabajo para agentes (definición de "hecho")

Al completar una tarea significativa:

1. **Cuestiones pendientes:** si detectás una cuestión abierta, duda de diseño o punto a ratificar, **agregala** a `docs/cuestiones_pendientes.md` (nuevo ID `CP-NN`). Cuando resuelvas una, **sacala de "Abiertas" y moverla a "Resueltas"** con la resolución, la fecha y el link al ADR/decisión. Ese archivo es la única fuente de verdad de lo pendiente.
2. **Si tomaste o cambiaste una decisión de arquitectura:** agregá/editá un ADR en `docs/decisiones/bitacora_decisiones.md`, y reflejá el cambio en el `Resumen de decisiones` de `docs/arquitectura/Arquitectura_Sistema_Marcha.md`.
3. **Registrá el cambio** en `memoria/changelog.md` (fecha, qué cambió, por qué).
4. **Actualizá `memoria/memory.md`** si cambió el estado del proyecto o aprendiste algo que otro agente debería saber.
5. **Mantené la coherencia** entre el código y los diagramas/spec. Si el código diverge de la arquitectura, actualizá la arquitectura o registrá una cuestión en `docs/cuestiones_pendientes.md`.
6. **No inventes hechos del mundo real** (precios, APIs, versiones): verificá antes de afirmar.

## Cuestiones pendientes

El registro vivo está en **`docs/cuestiones_pendientes.md`** (única fuente de verdad). Ahí se agregan las cuestiones abiertas y se sacan a medida que se resuelven (ver el flujo de trabajo, paso 1). Actualmente abiertas: CP-01, CP-03 a CP-12 (tercer FSR/GP28, dónde detectar el IC, rigor de seguridad, esquema de `feature_vectors`, proveedor del worker, lectura del IMU, modularidad de FSR/ADC, energía/batería, patrones de feedback, reconciliación anteproyecto/marco, modularidad de features). CP-02 (cintura-hub vs features-en-plantilla) quedó **resuelta** a favor de features distribuidas por-pie.

## Glosario rápido

- **AP / STA:** Access Point (crea la red) / Station (se une como cliente).
- **IC:** Initial Contact (contacto inicial del pie; usado como evento de segmentación de zancada).
- **Drift (reloj):** divergencia de relojes por diferencias de cristal; también "drift" de la marcha = cambio de patrón que dispara reentrenamiento.
- **L/E/W:** clases de modelo por dónde infieren/reentrenan (ver arriba).
- **OTA:** Over-The-Air (actualización inalámbrica de pesos/firmware).
- **Coexistencia:** WiFi y BLE compartiendo el mismo radio (CYW43439) por time-division.
- **Mínima / Máxima:** horizonte de entorno controlado (laptop) / uso diario (celular + nube).
