# CLAUDE.md — Guía para agentes de IA

> Este archivo es el punto de entrada para **cualquier agente de IA** (o persona) que trabaje en este repositorio. Léelo completo antes de tocar nada. Su objetivo es dar **entendimiento total del proyecto** para que cualquiera pueda clonar el repo y ponerse a trabajar de inmediato.

## Qué es este proyecto (en una línea)

Sistema de **plantillas inteligentes bilaterales** para **detección personalizada de anomalías de marcha en pacientes post-ACV**, con **feedback vibrotáctil en tiempo real** e **inferencia en el borde (edge)**. Tesis de maestría (ITBA).

**Estado actual:** arquitectura definida (v1.0). Sin código todavía. Próximo paso: roadmap de implementación por fases.

## Orden de lectura recomendado (onboarding)

1. `docs/objetivos.md` — qué se quiere lograr y por qué (clínica, alcance mínima/máxima, filosofía).
2. `docs/arquitectura/Arquitectura_Sistema_Marcha.md` — la especificación técnica completa (**fuente de verdad** de la arquitectura).
3. `docs/decisiones/bitacora_decisiones.md` — por qué cada decisión, con opciones y pros/cons evaluados.
4. `docs/investigacion/resumen_investigacion.md` + `features_anomaly_detection_stroke.md` — la evidencia que fundamenta el diseño.
5. `memoria/memory.md` — estado vivo del proyecto y aprendizajes acumulados.
6. Los diagramas `.mermaid` en `docs/arquitectura/` (topología, base de datos, ciclo de vida de modelos).

## Resumen de la arquitectura (lo mínimo que un agente debe saber)

- **Hardware:** 2 plantillas (Raspberry Pi Pico 2 W + MPU-6050 + 3 FSR + motor vibrador PWM) + 1 unidad de cintura (Pico 2 W + MPU-6050). Muestreo **100 Hz**.
- **Topología:** plantillas ↔ cintura por **WiFi** (cintura = **Access Point**); cintura ↔ host por **BLE** (desde la mínima). La cintura es el **hub de cómputo**.
- **Transporte:** canal rápido-tolerante (**UDP** / notificaciones GATT) para el stream + canal confiable (**TCP** / writes con ACK) para control y modelos.
- **Sincronización:** backbone de reloj (**timestamp + secuencia por muestra + beacon periódico + corrección de drift**), en capa de aplicación (portable WiFi↔BLE); emparejado de zancadas por evento (heel-strike/IC) como **refinamiento**.
- **Dos modos de datos:** *captura* (crudo → host, para dataset/entrenamiento) y *edge* (features on-device, para uso real), con **una única definición de features compartida PC↔micro**.
- **Persistencia:** **Supabase** (PostgreSQL + TimescaleDB + object storage + auth). Supabase **no entrena**; el entrenamiento corre en un worker (laptop en mínima, nube en máxima).
- **Modelos (taxonomía L/E/W):** cada modelo declara su clase en el registry.
  - **L (Local-Local):** infiere y reentrena en el micro, dato a dato (Mahalanobis EMA, probabilísticos simples).
  - **E (Edge+Worker):** infiere en el micro (int8), reentrena en el worker (autoencoder denso).
  - **W (Worker-heavy):** infiere/reentrena en el worker (LSTM AE, Isolation Forest).
  - Mahalanobis también es **sensor de drift** que dispara el reentrenamiento de E/W.
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
│   ├── arquitectura/          # spec + diagramas (fuente de verdad de la arquitectura)
│   ├── decisiones/            # bitácora de decisiones (ADRs) — alimenta el informe de tesis
│   ├── investigacion/         # bibliografía, features, pinout, resumen
│   └── marco_teorico/         # marco teórico (a subir)
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
- **Cintura = AP** y **hub de cómputo**: es un invariante del sistema (permanente mínima→máxima).
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

El registro vivo está en **`docs/cuestiones_pendientes.md`** (única fuente de verdad). Ahí se agregan las cuestiones abiertas y se sacan a medida que se resuelven (ver el flujo de trabajo, paso 1). Actualmente abiertas: CP-01 a CP-06 (tercer FSR/GP28, cintura-como-hub vs features-en-plantilla, dónde detectar el IC, rigor de seguridad, esquema de `feature_vectors`, proveedor del worker).

## Glosario rápido

- **AP / STA:** Access Point (crea la red) / Station (se une como cliente).
- **IC:** Initial Contact (contacto inicial del pie; usado como evento de segmentación de zancada).
- **Drift (reloj):** divergencia de relojes por diferencias de cristal; también "drift" de la marcha = cambio de patrón que dispara reentrenamiento.
- **L/E/W:** clases de modelo por dónde infieren/reentrenan (ver arriba).
- **OTA:** Over-The-Air (actualización inalámbrica de pesos/firmware).
- **Coexistencia:** WiFi y BLE compartiendo el mismo radio (CYW43439) por time-division.
- **Mínima / Máxima:** horizonte de entorno controlado (laptop) / uso diario (celular + nube).
