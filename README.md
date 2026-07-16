# Tesis — Plantillas inteligentes bilaterales para detección de anomalías de marcha post-ACV

Sistema wearable que detecta desviaciones **personalizadas** en la marcha de pacientes post-ACV mediante **dos plantillas instrumentadas** (FSR + IMU) y una **unidad de cintura**, con **feedback vibrotáctil en tiempo real** e **inferencia en el borde**. Proyecto de tesis de maestría (ITBA).

## Estado

- ✅ Objetivos y alcance definidos.
- ✅ Investigación previa consolidada (bibliografía, features, algoritmos).
- ✅ **Arquitectura informática definida (v1.0)** — ver `docs/arquitectura/`.
- ⏳ Roadmap de implementación por fases — próximo entregable.
- ⏳ Código — aún no iniciado (`src/`).

## Cómo empezar

1. Cloná el repositorio.
2. Leé **`CLAUDE.md`** (guía de onboarding; sirve tanto para agentes de IA como para personas).
3. Seguí el orden de lectura sugerido ahí: objetivos → arquitectura → decisiones → investigación.

Este repo está pensado para trabajar con **agentes de IA**: `CLAUDE.md` les da entendimiento total del proyecto y las reglas de trabajo.

## Estructura

| Carpeta | Contenido |
|---|---|
| `docs/objetivos.md` | Propósito, alcance (mínima/máxima), filosofía de diseño. |
| `docs/arquitectura/` | Especificación de la arquitectura (fuente de verdad) + diagramas Mermaid. |
| `docs/decisiones/` | Bitácora de decisiones (ADRs): cada elección con opciones, pros/cons y justificación. |
| `docs/investigacion/` | Bibliografía, feature set, pinout, resumen de investigación. |
| `docs/marco_teorico/` | Marco teórico (a subir). |
| `src/firmware/` | Firmware C/C++ (Pico SDK): `insole/`, `waist/`, `shared/`. |
| `src/host/` | App de ingesta/puente (laptop → celular). |
| `src/worker/` | Reentrenamiento de modelos (Python). |
| `src/db/` | Esquema SQL (Postgres + TimescaleDB) y migraciones. |
| `memoria/` | Memoria viva del proyecto (`memory.md`) y changelog. |

## Arquitectura en breve

Plantillas → **WiFi (cintura = AP)** → **Cintura (hub: sync, features, detección)** → **BLE** → Host (laptop/celular) → **Supabase** (Postgres + TimescaleDB + storage). Reentrenamiento en un **worker** (laptop en mínima, nube en máxima). Modelos clasificados **L/E/W** según dónde infieren/reentrenan; despliegue al micro por **OTA A/B**. Detalle completo en `docs/arquitectura/Arquitectura_Sistema_Marcha.md`.

## Documentar decisiones

Toda decisión de arquitectura se registra como **ADR** en `docs/decisiones/bitacora_decisiones.md` (con opciones y pros/cons) y se refleja en el changelog. Esta bitácora se va construyendo de a poco y es la base para **justificar las decisiones en el informe final** de la tesis.

## Requisitos (a completar cuando exista código)

- **Firmware:** Raspberry Pi Pico SDK (C/C++), toolchain ARM, TFLite Micro. *(instrucciones en `src/firmware/README.md`)*
- **Worker:** Python (numpy, scikit-learn, PyTorch/TensorFlow). *(en `src/worker/README.md`)*
- **Base de datos:** Supabase (PostgreSQL + TimescaleDB). *(en `src/db/README.md`)*

## Licencia

Por definir.
