# db/ — Base de datos (Supabase sobre Postgres 17)

Esquema, migraciones y tests de la base. Plataforma: **Supabase** (Postgres 17 + object storage + auth) — ADR-006/007. Las series usan **particionado nativo** con `pg_partman` + `pg_cron` (ADR-044); TimescaleDB quedó descartado (deprecado en Supabase sobre Postgres 17).

## Contenido

- `schema.sql` — el esquema para **leer**. Hoy es el **diseño** (ADR-044, 046 y 047), escrito a mano por última vez. Cuando exista la base pasa a ser un **snapshot generado** desde las migraciones, sin las particiones hijas: **no se edita a mano** (ADR-045).
- `supabase/` *(todavía no existe)* — proyecto de la CLI de Supabase: `config.toml`, `migrations/`, `tests/` (pgTAP) y `seed.sql` (sólo datos sintéticos).
- `scripts/` *(todavía no existe)* — el script que regenera `schema.sql` desde la base local.

## Cómo cambia el esquema (ADR-045)

1. **Sólo con una migración nueva:** `supabase --workdir src/db migration new <nombre>` → `src/db/supabase/migrations/<timestamp>_<nombre>.sql`.
2. Se prueba local: `supabase --workdir src/db db reset` (aplica todas las migraciones desde cero + seed) y `supabase --workdir src/db test db` (pgTAP).
3. Se regenera `schema.sql` con el script y se commitean juntos.
4. **La aplica CI desde `master`** (GitHub Actions: base efímera → migraciones → pgTAP → chequeo del snapshot → `db push`). Nadie hace `db push` desde su computadora.

Reglas: una migración aplicada **no se edita** (se corrige con otra); la base remota **no se toca a mano**; una migración nueva tiene que quedar **después** de todas las ya aplicadas (si el `pull` trae una más nueva, se renombra la propia con un timestamp nuevo).

**Requisitos:** Docker y la CLI de Supabase.

## Diseño

- **Relacional:** `patients`, `devices`, `sessions`, `patient_access`, `models`, `model_deployments`, `firmware_images`, `retrain_jobs`, `feedback_config`.
- **Series (particionadas por mes de inicio de sesión — ADR-044):** `strides` (la zancada como entidad), `gait_events`, `feature_vectors`, `anomaly_scores`. Se identifican con los números que asigna el borde —`stride_seq` (plantilla) y `cycle_seq` (cintura)—, con FK reales e ingesta idempotente por *upsert* (ADR-046).
- **Object storage (referenciado):** `raw_blobs` (crudo continuo en Parquet), `anomaly_raw_snippets` (FK a su score), artefactos de modelos y firmware.

Diagrama ER en `docs/arquitectura/esquema_base_de_datos.mermaid`; definición conceptual en la Vista 4 (`docs/arquitectura/vistas/4_vista_backend_app.md`).

## Retención

Política **tiered** (ADR-008): en la fase de dataset se guarda el crudo completo; en uso real, features/eventos/scores + crudo sólo alrededor de anomalías. Las series no tienen retención automática; el archivo en frío de particiones viejas es **CP-32**.

## Seguridad (ADR-032 + ADR-047)

**Grants explícitos** por rol (`anon`: nada; `authenticated`: lee lo que la RLS le deja y no borra; `service_role`: todo), **RLS en todas las tablas expuestas**, particiones sin grants y con RLS, y la función de las políticas en el esquema `private` (fuera de la Data API). `external_code` anónimo en lugar de PII directa; cifrado en tránsito y en reposo.
