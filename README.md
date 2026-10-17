# Tesis — Plantillas inteligentes bilaterales para detección de anomalías de marcha post-ACV

Sistema wearable que detecta desviaciones **personalizadas** en la marcha de pacientes post-ACV mediante **dos plantillas instrumentadas** (FSR + IMU) y una **unidad de cintura**, con **feedback vibrotáctil en tiempo real** e **inferencia en el borde**. Proyecto de tesis de maestría (ITBA).

## Estado

- ✅ Objetivos y alcance definidos; **anteproyecto** y **marco teórico** incorporados.
- ✅ Investigación previa consolidada (bibliografía, catálogo de features, algoritmos).
- ✅ **Arquitectura cerrada**, en **4 vistas consolidadas** (`docs/arquitectura/vistas/`). El maestro es **índice + overview**, no duplica el detalle de las vistas (ADR-039).
- ✅ **Diseño detallado terminado** — **ADR-000 a 047** en la bitácora, **SPEC-01 a SPEC-11** de algoritmos de firmware. El backlog de investigación **#1 a #10 está resuelto**; **#11** (footprint/latencia) y **#12** (selección de features) esperan firmware y dataset.
- ✅ **Esquema de la base diseñado** — Postgres 17 con **series particionadas** + `pg_partman` (ADR-044), **migraciones versionadas** con la CLI de Supabase y CI (ADR-045), **la zancada como entidad** con FK reales e ingesta idempotente (ADR-046) y **grants explícitos + RLS en todas las tablas** (ADR-047). El diseño está en `src/db/schema.sql`; se crea como migraciones al implementar la base.
- 🔄 **Hardware en banco** — 2 FSR conectados (punta + talón); la próxima revisión del PCB suma medial y lateral con mux (ADR-041) y el cargador de corriente limitada. Checklist en `docs/arquitectura/esquema_alimentacion.md` §7.
- ⏳ **Roadmap de implementación por fases** — próximo paso.
- ⏳ **Firmware y worker** — aún no iniciados (`src/firmware/`, `src/host/`, `src/worker/`).

**Cuestiones abiertas (12):** ver `docs/cuestiones_pendientes.md`, que es la **única fuente de verdad** — este archivo no duplica la lista. Ninguna bloquea el diseño. **CP-21** (`pico-tflmicro` en RP2350) es la única que puede voltear una decisión ya tomada. Y hay una fecha límite: la base tiene que **existir como migraciones antes de la primera captura** (ADR-045).

## Cómo empezar

1. Cloná el repositorio.
2. Leé **`CLAUDE.md`** (guía de onboarding; sirve tanto para agentes de IA como para personas).
3. Seguí el orden de lectura sugerido ahí: anteproyecto → objetivos → arquitectura (índice + vistas) → decisiones → investigación.

Este repo está pensado para trabajar con **agentes de IA**: `CLAUDE.md` les da entendimiento total del proyecto y las reglas de trabajo.

## Estructura

| Carpeta / archivo | Contenido |
|---|---|
| `docs/objetivos.md` | Propósito, alcance (mínima/máxima), filosofía de diseño. |
| `docs/Anteproyecto_Tesis.pdf` | Anteproyecto oficial de la tesis (problema, objetivos, metodología). |
| `docs/arquitectura/` | Maestro (**índice + overview**) + **4 vistas** (`vistas/`: sistema, firmware, datos-ml, backend) + `stack_tecnologico.md` + `esquema_alimentacion.md` + diagramas Mermaid. |
| `docs/arquitectura/vistas/2_specs_algoritmos_firmware.md` | **SPEC-01 a SPEC-11**: guías de implementación de cada algoritmo de firmware. |
| `docs/decisiones/bitacora_decisiones.md` | **Bitácora de ADRs con su índice** — cada elección con opciones, pros/cons y justificación. Es la **única lista de decisiones** del proyecto. |
| `docs/cuestiones_pendientes.md` | Registro vivo de cuestiones abiertas (única fuente de verdad). |
| `docs/investigacion/` | Bibliografía (22 papers), catálogo de features, pinout, informe de alineación y **documentos de fundamento** (ver `00_INDICE.md`). |
| `docs/marco_teorico/` | Marco teórico (documento de trabajo). |
| `src/db/` | **Base de datos:** `supabase/` (migraciones y tests, cuando exista la base) + `schema.sql`, el esquema para leer (ADR-045). |
| `src/firmware/` | Firmware C/C++ (Pico SDK): `insole/`, `waist/`, `shared/`. |
| `src/host/` | App de ingesta/puente + UI de control (laptop → celular). |
| `src/worker/` | Reentrenamiento de modelos (Python). |
| `memoria/` | Memoria viva del proyecto (`memory.md`) y `changelog.md`. |

## Arquitectura en breve

Tres micros **Raspberry Pi Pico 2 W** a 100 Hz. Las **plantillas** (IMU MPU-6050 + FSR + motor vibrador) detectan sus eventos **IC/TO/MS** y calculan sus **features por-pie**; la **cintura** es el hub: AP WiFi, maestro de sincronización, **fusión bilateral**, inferencia y decisión de feedback.

Plantillas → **WiFi (cintura = AP; UDP stream + TCP control)** → **Cintura** → **BLE (GATT)** → Host (laptop en mínima, celular en máxima) → **Supabase** (PostgresDB + storage, con RLS por paciente). El reentrenamiento corre en un **worker** (laptop / nube). Los modelos declaran su clase **L/E/H/W** en el registry; la **inferencia en tiempo real va en el hub o en el host, nunca en la nube**, y el despliegue al micro es por **OTA A/B**.

**Detección:** one-class **personalizada por paciente** (baseline propio, no modelo poblacional). Catálogo de **47 features** en bloques A–I; el **set activo** actual es el perfil 2-FSR. **Feedback:** monitoreo y alerta por ventana de zancadas, no corrección.

Detalle completo en `docs/arquitectura/Arquitectura_Sistema_Marcha.md` y las cuatro vistas.

## Cómo se documenta

Toda decisión de arquitectura se registra como **ADR** en `docs/decisiones/bitacora_decisiones.md`, con sus opciones y su justificación, más una fila en el índice del mismo archivo. Esa bitácora es la base para **justificar cada elección en el informe final** de la tesis. Cada ítem del backlog produce además una **spec de algoritmo** en `vistas/2_specs_algoritmos_firmware.md`.

**Regla de fuente única** (ADR-037 / ADR-039), que vale también para quien lea:

| Para saber… | Ir a… |
|---|---|
| Qué se decidió y por qué | El índice de la bitácora, y el ADR correspondiente |
| Cómo funciona un dominio en detalle | La **vista** que le corresponde — **ante discrepancia con el maestro, manda la vista** |
| El esquema exacto de la base | `src/db/schema.sql` (para leer; se cambia sólo por migraciones — ADR-045) |
| Qué falta resolver | `docs/cuestiones_pendientes.md` |
| Qué pasó y cuándo | `memoria/changelog.md` |

## Requisitos (a completar cuando exista código)

- **Firmware:** Raspberry Pi Pico SDK (C/C++), toolchain ARM, **CMSIS-DSP**, **TFLite Micro + CMSIS-NN** (`pico-tflmicro` — ver CP-21), **Fusion** (AHRS), **BTstack**, **lwIP**. *(instrucciones en `src/firmware/README.md`)*
- **Worker:** Python — numpy, scipy, pandas, **scikit-learn**, **TensorFlow/Keras** + conversor TFLite/LiteRT (PTQ int8). *(en `src/worker/README.md`)*
- **Host:** Python — `bleak` (BLE) + **FastAPI** (UI de control).
- **Base de datos:** Supabase sobre **Postgres 17**, con `pg_partman` + `pg_cron` (ADR-044). Para trabajar: **Docker** + la **CLI de Supabase** (migraciones, base local y tests pgTAP — ADR-045). *(en `src/db/README.md`)*

Las versiones exactas no se fijan de memoria: se anclan al implementar (regla de `stack_tecnologico.md`).

## Licencia

Por definir.
