-- Esquema de referencia — Sistema de plantillas inteligentes de marcha (post-ACV)
-- Plataforma: Supabase (PostgreSQL + TimescaleDB + object storage)
-- Ver docs/arquitectura/Arquitectura_Sistema_Marcha.md (§11) y esquema_base_de_datos.mermaid
-- Nota: el crudo continuo se guarda como Parquet en object storage y se referencia desde raw_blobs.

-- Extensiones (en Supabase, TimescaleDB puede requerir habilitacion)
-- create extension if not exists timescaledb;

-- ============================================================
-- Metadata relacional
-- ============================================================
create table patients (
  id uuid primary key default gen_random_uuid(),
  external_code text unique,            -- codigo anonimo, no PII directa
  birth_year int,
  sex text,
  affected_side text check (affected_side in ('left','right','none')),
  clinical_notes jsonb,
  created_at timestamptz default now()
);

create table devices (
  id uuid primary key default gen_random_uuid(),
  role text check (role in ('insole_left','insole_right','waist')),
  hw_revision text,
  firmware_version text,
  created_at timestamptz default now()
);

create table sessions (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid references patients(id),
  mode text check (mode in ('capture','edge')),
  feature_set_version text,
  environment text,                     -- 'lab','clinic','home'
  device_set jsonb,                     -- {left, right, waist device ids}
  started_at timestamptz,
  ended_at timestamptz,
  notes text
);

-- ============================================================
-- Crudo (referenciado a object storage)
-- ============================================================
create table raw_blobs (
  id uuid primary key default gen_random_uuid(),
  session_id uuid references sessions(id),
  device_id uuid references devices(id),
  storage_url text,                     -- object storage (Parquet)
  format text default 'parquet',
  start_time timestamptz,
  end_time timestamptz,
  n_samples bigint,
  checksum text
);

create table anomaly_raw_snippets (
  id uuid primary key default gen_random_uuid(),
  session_id uuid references sessions(id),
  device_id uuid references devices(id),
  score_id uuid,                        -- fk logica a anomaly_scores
  storage_url text,
  start_time timestamptz,
  end_time timestamptz
);

-- ============================================================
-- Registry de modelos (respaldo + ruteo L/E/W)
-- ============================================================
create table models (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid references patients(id),   -- null = modelo global
  algo text,                                 -- 'mahalanobis','dense_ae','lstm_ae','iforest'...
  class text check (class in ('L','E','H','W')),
  inference_target text check (inference_target in ('hub','host','worker')),
  retrain_target text check (retrain_target in ('micro','worker')),
  granularity text check (granularity in ('online','periodic','async')),
  version int,
  parent_version int,
  feature_set_version text,
  artifact_url text,                         -- object storage
  artifact_format text,                      -- 'tflite_int8','npz','json'
  checksum text,
  metrics jsonb,                             -- {auc, threshold, ...}
  status text check (status in ('active','shadow','archived','rolled_back')),
  created_at timestamptz default now(),
  deployed_at timestamptz
);

create table model_deployments (
  id uuid primary key default gen_random_uuid(),
  model_id uuid references models(id),
  device_id uuid references devices(id),
  deployed_at timestamptz default now(),
  status text check (status in ('active','rolled_back')),
  rolled_back_at timestamptz
);

create table firmware_images (
  id uuid primary key default gen_random_uuid(),
  version text,
  target_role text check (target_role in ('insole','waist')),
  storage_url text,
  checksum text,
  created_at timestamptz default now()
);

create table retrain_jobs (
  id uuid primary key default gen_random_uuid(),
  trigger text check (trigger in ('drift','schedule','manual')),
  patient_id uuid references patients(id),
  model_in uuid references models(id),
  model_out uuid references models(id),
  status text check (status in ('queued','running','done','failed')),
  worker text,
  started_at timestamptz,
  finished_at timestamptz,
  logs_url text
);

-- ============================================================
-- Series temporales (hypertables de TimescaleDB)
-- ============================================================
create table gait_events (
  time timestamptz not null,
  session_id uuid references sessions(id),
  device_id uuid references devices(id),
  foot text check (foot in ('left','right')),
  type text check (type in ('IC','TO')),   -- Initial Contact / Toe-Off
  confidence real
);
select create_hypertable('gait_events','time');

create table feature_vectors (
  time timestamptz not null,               -- fin de zancada/ventana
  session_id uuid references sessions(id),
  patient_id uuid references patients(id),
  scope text check (scope in ('left','right','bilateral')),
  feature_set_version text,
  features jsonb,                          -- {feature_name: value}
  stride_id bigint
);
select create_hypertable('feature_vectors','time');

create table anomaly_scores (
  time timestamptz not null,
  session_id uuid references sessions(id),
  patient_id uuid references patients(id),
  model_id uuid references models(id),
  score double precision,
  threshold double precision,
  is_anomaly boolean,
  drift_metric double precision
);
select create_hypertable('anomaly_scores','time');

-- ============================================================
-- Indices sugeridos
-- ============================================================
create index on feature_vectors (patient_id, time desc);
create index on anomaly_scores (patient_id, time desc);
create index on gait_events (session_id, time desc);
create index on models (patient_id, algo, version desc);
