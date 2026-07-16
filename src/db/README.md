# db/ — Base de datos (PostgreSQL + TimescaleDB / Supabase)

Esquema y migraciones de la base. Plataforma: **Supabase** (Postgres gestionado + TimescaleDB + object storage + auth) — ver ADR-006/007.

## Contenido

- `schema.sql` — DDL de referencia (tablas relacionales + hypertables de Timescale). El crudo continuo va a **object storage** (Parquet) referenciado desde `raw_blobs`; sólo el crudo por anomalía y las series de features/scores/eventos van a hypertables.

## Diseño

- **Relacional:** `patients`, `devices`, `sessions`, `models`, `model_deployments`, `firmware_images`, `retrain_jobs`.
- **Hypertables (series):** `feature_vectors`, `anomaly_scores`, `gait_events`.
- **Object storage (referenciado):** `raw_blobs`, `anomaly_raw_snippets`, artefactos de modelos y firmware.

Diagrama ER en `docs/arquitectura/esquema_base_de_datos.mermaid`; descripción en §11 de la arquitectura.

## Retención

Política **tiered** (ADR-008): dataset guarda crudo completo; uso real guarda features/scores + crudo sólo alrededor de anomalías.

## Seguridad

Row-Level Security (RLS) por paciente; `external_code` anónimo en lugar de PII directa; cifrado en tránsito/reposo.

> **Pendiente:** convertir `schema.sql` en migraciones versionadas (p. ej. supabase migrations) y políticas RLS concretas.
