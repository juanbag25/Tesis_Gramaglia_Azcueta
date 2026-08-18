-- Esquema de la base — Sistema de plantillas inteligentes de marcha (post-ACV)
-- Plataforma: Supabase (PostgreSQL + TimescaleDB + object storage)
--
-- FUENTE UNICA DE VERDAD DEL ESQUEMA (ADR-037).
-- El maestro (docs/arquitectura/Arquitectura_Sistema_Marcha.md §11.3) ya no duplica el DDL:
-- mantiene la tabla de entidades y apunta aca. La vista canonica del backend es
-- docs/arquitectura/vistas/4_vista_backend_app.md; el ER en esquema_base_de_datos.mermaid.
--
-- Nota: el crudo continuo se guarda como Parquet en object storage y se referencia desde raw_blobs.

-- Extensiones (en Supabase, TimescaleDB puede requerir habilitacion)
-- create extension if not exists timescaledb;

-- ============================================================
-- Metadata relacional
-- ============================================================
create table patients (
  id uuid primary key default gen_random_uuid(),
  external_code text unique,            -- codigo anonimo, no PII directa (ADR-032)
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

-- Fases de captura (ADR-005 rev c):
--   exploratory  = crudo-solo; las features se calculan off-device (Python).
--   operational  = el micro calcula features + se sube crudo (incluye calibracion/baseline).
--   edge         = uso real: features/eventos/scores en vivo + crudo por snippet ante anomalia.
-- host_type es SOLO trazabilidad del dataset: el micro es agnostico al tipo de central (ADR-034).
create table sessions (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid references patients(id),
  mode text check (mode in ('exploratory','operational','edge')),
  feature_set_version text,
  environment text,                     -- 'lab','clinic','home'
  device_set jsonb,                     -- {left, right, waist device ids}
  host_type text check (host_type in ('laptop','mobile')),
  host_app_version text,
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
-- Registry de modelos (respaldo + ruteo L/E/H/W)
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
-- Configuracion de feedback vibrotactil, por paciente (ADR-027 / SPEC-09)
-- Los valores son empiricos: se fijan con la calibracion y el analisis.
-- El host baja esta config a la cintura por el canal confiable.
-- ============================================================
create table feedback_config (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references patients(id),
  feedback_source uuid references models(id),   -- que detector alimenta la decision (model-agnostic)
  window_strides int,                           -- N de la ventana de zancadas (SPEC-05)
  threshold_mild double precision,              -- T1 banda leve
  threshold_marked double precision,            -- T2 banda marcada
  threshold_risk double precision,              -- T3 banda riesgo (co-anclada a caida)
  intensity_pct int check (intensity_pct between 0 and 100),
  refractory_s int,                             -- alerta escasa: tiempo minimo entre avisos
  hysteresis double precision,
  patterns_enabled jsonb,                       -- {mild:true, marked:true, risk:true}
  active boolean default true,
  created_at timestamptz default now()
);

-- ============================================================
-- Series temporales (hypertables de TimescaleDB)
-- ============================================================
create table gait_events (
  time timestamptz not null,
  session_id uuid references sessions(id),
  device_id uuid references devices(id),
  foot text check (foot in ('left','right')),
  type text check (type in ('IC','TO','MS')),  -- Initial Contact / Toe-Off / Mid-Stance (ADR-038)
  confidence real
);
select create_hypertable('gait_events','time');

-- features_source distingue el vector calculado por el micro del recalculado off-device
-- (ADR-036). En la fase operativa conviven ambos para la MISMA zancada: el del micro
-- entrena skew-free (ADR-018) y el offline valida la paridad.
create table feature_vectors (
  time timestamptz not null,               -- fin de zancada/ventana
  session_id uuid references sessions(id),
  patient_id uuid references patients(id),
  scope text check (scope in ('left','right','bilateral')),
  feature_set_version text,
  features_source text check (features_source in ('device','offline')),
  features jsonb,                          -- {feature_name: value}
  stride_id bigint
);
select create_hypertable('feature_vectors','time');

-- PENDIENTE (ADR-031 / CP-20): columnas generadas STORED + indices de expresion sobre
-- las features "calientes" del dashboard. No se pueden fijar todavia: dependen de que se
-- congele el feature_set_version y de que exista el dashboard (diferido a la maxima, ADR-033).

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
create index on feature_vectors (session_id, features_source, time desc);
create index on anomaly_scores (patient_id, time desc);
create index on gait_events (session_id, time desc);
create index on models (patient_id, algo, version desc);

-- ============================================================
-- Seguridad: RLS estricto por paciente (ADR-032, resuelve CP-04 a nivel tecnico)
-- ------------------------------------------------------------
-- La pertenencia vive en patient_access (user -> patient -> rol). La base misma filtra
-- las filas: la app no puede pedir de mas. El worker corre con service_role, que saltea
-- RLS por diseno (backend seguro, nunca en el cliente).
-- Minima: un solo owner (el investigador). Maxima: se suman filas clinician/patient
-- SIN cambiar el esquema. El nivel formal (consentimiento, auditoria) es CP-18.
-- ============================================================
create table patient_access (
  user_id uuid not null,                        -- auth.users(id)
  patient_id uuid not null references patients(id) on delete cascade,
  role text not null check (role in ('owner','clinician','patient')),
  granted_at timestamptz default now(),
  primary key (user_id, patient_id)
);

create or replace function has_patient_access(p uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from patient_access pa
    where pa.patient_id = p and pa.user_id = auth.uid()
  );
$$;

alter table patients            enable row level security;
alter table sessions            enable row level security;
alter table models              enable row level security;
alter table retrain_jobs        enable row level security;
alter table feedback_config     enable row level security;
alter table feature_vectors     enable row level security;
alter table anomaly_scores      enable row level security;
alter table raw_blobs           enable row level security;
alter table anomaly_raw_snippets enable row level security;
alter table gait_events         enable row level security;
alter table patient_access      enable row level security;

-- Tablas con patient_id directo
create policy p_patients on patients
  for all to authenticated using (has_patient_access(id));

create policy p_sessions on sessions
  for all to authenticated using (has_patient_access(patient_id));

create policy p_feature_vectors on feature_vectors
  for all to authenticated using (has_patient_access(patient_id));

create policy p_anomaly_scores on anomaly_scores
  for all to authenticated using (has_patient_access(patient_id));

create policy p_retrain_jobs on retrain_jobs
  for all to authenticated using (has_patient_access(patient_id));

create policy p_feedback_config on feedback_config
  for all to authenticated using (has_patient_access(patient_id));

-- models: patient_id null = modelo global (visible a cualquier usuario autenticado)
create policy p_models on models
  for all to authenticated using (patient_id is null or has_patient_access(patient_id));

-- Tablas que llegan al paciente por la sesion
create policy p_raw_blobs on raw_blobs
  for all to authenticated using (exists (
    select 1 from sessions s where s.id = raw_blobs.session_id and has_patient_access(s.patient_id)));

create policy p_anomaly_raw_snippets on anomaly_raw_snippets
  for all to authenticated using (exists (
    select 1 from sessions s where s.id = anomaly_raw_snippets.session_id and has_patient_access(s.patient_id)));

create policy p_gait_events on gait_events
  for all to authenticated using (exists (
    select 1 from sessions s where s.id = gait_events.session_id and has_patient_access(s.patient_id)));

-- Cada usuario ve sus propias concesiones; otorgarlas es tarea del service_role.
create policy p_patient_access on patient_access
  for select to authenticated using (user_id = auth.uid());

-- devices, model_deployments y firmware_images no contienen datos de salud del paciente:
-- quedan sin RLS a proposito. Al reasignar la cintura a otro paciente hay que borrar
-- bonds + datos (ADR-028 / ADR-032).
