# Vista 4 — Backend y Aplicación

> **Nivel de abstracción:** persistencia, servicios y aplicaciones fuera de los micros: base de datos, worker de reentrenamiento, app host y dashboard clínico.
>
> **Estado:** andamiaje. Detalle actual en el maestro (§11–§13).

## Alcance (qué vive en esta vista)

- **Persistencia — Supabase:** PostgreSQL + TimescaleDB + object storage + auth; esquema/DDL; **RLS por paciente**; retención tiered. → maestro §11, `../esquema_base_de_datos.mermaid`, `src/db/schema.sql`.
- **Worker de reentrenamiento:** orquestación de jobs (drift/schedule/manual); entrena E/H/W; cuantiza int8; publica al registry. Laptop (mínima) / nube (máxima). → maestro §12 (ADR-009).
- **App host / puente:** ingesta por BLE, buffer local, escritura a Supabase, puente OTA. Laptop (mínima) / móvil (máxima).
- **Dashboard clínico (objetivo de máxima, incluido desde el inicio):** evolución temporal de parámetros de marcha, frecuencia de anomalías, **WBA/PSV**, regresión de riesgo de Jung, **Z-scores por paciente**, heatmaps; comparación con escalas (Berg, Fugl-Meyer, Barthel). Capa web sobre Supabase con RLS.
- **Seguridad y privacidad:** cifrado en tránsito/reposo, RLS, `external_code` anónimo, consentimiento. → maestro §13.

**Diagramas de esta vista:** `../esquema_base_de_datos.mermaid` (ER) (+ un diagrama de componentes backend/app, a crear).

## ADRs relevantes
ADR-006 (Supabase), ADR-007 (Postgres+Timescale+storage), ADR-008 (retención tiered), ADR-009 (worker de reentrenamiento), ADR-012 (OTA — lado backend).

## Stack (resumen; detalle en `../stack_tecnologico.md`)
Supabase (Postgres + TimescaleDB + Storage + Auth), supabase-py (worker), bleak (host BLE, mínima), framework de dashboard (a definir), stack móvil (máxima, a definir).

## Pendiente de definir / investigar (backlog)
- **Framework del dashboard** (React + cliente Supabase vs Streamlit/Plotly Dash vs otro).
- **Stack de la app móvil** (máxima).
- **Proveedor del worker en la nube (CP-06).**
- **Salidas clínicas concretas:** cálculo de WBA/PSV, modelo de Jung, Z-scores, heatmaps — dónde se computan (worker vs dashboard).
- **Herramienta de migraciones** de la DB (p. ej. Supabase migrations) y políticas RLS concretas.
