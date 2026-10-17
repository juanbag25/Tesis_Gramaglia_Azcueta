-- Esquema de la base — Sistema de plantillas inteligentes de marcha (post-ACV)
-- Plataforma: Supabase sobre Postgres 17 (ADR-006, ADR-044): series con particionado nativo +
-- pg_partman + pg_cron; object storage para el crudo y los artefactos; auth.
--
-- ESTADO DE ESTE ARCHIVO (ADR-045). Es la ULTIMA version escrita a mano: el diseno de
-- ADR-044 (particionado), ADR-046 (identidad de las series) y ADR-047 (grants y RLS).
-- Todavia no se corrio contra una base: se valida al crear la migracion base.
-- Cuando se cree la base, este contenido pasa a ser la migracion base
-- (src/db/supabase/migrations/<timestamp>_baseline.sql) y el esquema cambia SOLO con
-- migraciones nuevas. Desde ese momento este archivo es un snapshot GENERADO desde la base
-- que arman las migraciones (sin las particiones hijas): no se edita a mano.
--
-- Definicion conceptual del backend: docs/arquitectura/vistas/4_vista_backend_app.md.
-- Mapa de entidades: maestro §11. Diagrama ER: docs/arquitectura/esquema_base_de_datos.mermaid.
--
-- El crudo continuo (100 Hz) NO entra a la base: va como Parquet a object storage y se
-- referencia desde raw_blobs (ADR-008, ADR-042).

-- ============================================================
-- Extensiones y esquemas
-- ============================================================
create schema if not exists partman;
create extension if not exists pg_partman with schema partman;  -- particiones por adelantado (ADR-044)
create extension if not exists pg_cron;                         -- mantenimiento programado (ADR-044)

-- Esquema NO expuesto por la Data API: funciones auxiliares de las politicas (ADR-047).
create schema if not exists private;

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
  patient_id uuid not null references patients(id),
  mode text not null check (mode in ('exploratory','operational','edge')),
  feature_set_version text,
  environment text,                     -- 'lab','clinic','home'
  device_set jsonb,                     -- {left, right, waist device ids}
  host_type text check (host_type in ('laptop','mobile')),
  host_app_version text,
  -- adaptation_enabled: la adaptacion online (clase L) se prende/apaga POR SESION desde la UI
  -- (ADR-043 rev). false = corre congelada en la version vigente y el check-in NO produce version
  -- nueva; true = arranca en N y produce EXACTAMENTE UNA version nueva al cerrar (parent_version=N).
  -- Es lo que habilita la comparacion pareada con y sin adaptacion.
  adaptation_enabled boolean not null default true,
  -- started_at: inicio de la sesion (fase 7 del pipeline, ADR-043 rev). Cada fila de las series
  -- lo copia como session_started_at, que es la clave de particion (ADR-044): no cambia nunca.
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  notes text,
  -- Ancla de las FK compuestas de las series (ADR-046): una fila no puede declarar el paciente
  -- ni la fecha de otra sesion.
  constraint sessions_id_patient_start_uq unique (id, patient_id, started_at)
);

-- Pertenencia user -> patient -> rol: la base de toda la RLS (ADR-032).
-- Minima: un solo owner (el investigador). Maxima: se suman filas clinician/patient
-- SIN cambiar el esquema. El nivel formal (consentimiento, auditoria) es CP-18.
create table patient_access (
  user_id uuid not null,                        -- auth.users(id)
  patient_id uuid not null references patients(id) on delete cascade,
  role text not null check (role in ('owner','clinician','patient')),
  granted_at timestamptz default now(),
  primary key (user_id, patient_id)
);

-- ============================================================
-- Crudo (referenciado a object storage)
-- ============================================================
create table raw_blobs (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references sessions(id),
  device_id uuid references devices(id),
  storage_url text,                     -- object storage (Parquet)
  format text default 'parquet',
  start_time timestamptz,
  end_time timestamptz,
  n_samples bigint,
  checksum text
);

-- ============================================================
-- Registry de modelos (respaldo + ruteo L/E/H/W)
-- ============================================================
create table models (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid references patients(id),   -- null = modelo global: no produce scores (ADR-046)
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
  deployed_at timestamptz,
  -- Una version por (paciente, algoritmo): con una version nueva por sesion adaptada
  -- (ADR-043 rev) la colision deja de ser hipotetica.
  constraint models_patient_algo_version_uq unique (patient_id, algo, version),
  -- Ancla de la FK anomaly_scores (model_id, patient_id) -> models (id, patient_id):
  -- un score no puede calcularse con el modelo de OTRO paciente (ADR-043 rev, ADR-046).
  constraint models_id_patient_uq unique (id, patient_id)
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
-- Funcion de las politicas (ADR-047). Vive en private, fuera de la Data API, y devuelve los
-- pacientes del usuario. Las politicas la llaman como "patient_id in (select ...)": asi el
-- optimizador la evalua una vez por consulta y no una vez por fila (patron que recomienda
-- Supabase). Reemplaza a la vieja public.has_patient_access().
-- ============================================================
create or replace function private.accessible_patient_ids()
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select pa.patient_id
  from public.patient_access pa
  where pa.user_id = (select auth.uid());
$$;

-- ============================================================
-- Series temporales: particionado nativo (ADR-044) e identidad de borde (ADR-046)
-- ------------------------------------------------------------
-- Clave de particion: session_started_at = sessions.started_at, igual en todas las filas de la
-- sesion. La sesion nunca queda partida, reenviar datos no duplica (la clave no depende de la
-- hora corregida por la sincronizacion) y las FK entre series comparten el valor.
-- Regla de Postgres: toda PK/UNIQUE de una tabla particionada incluye la clave de particion.
--
-- Numeracion en el borde (los contadores arrancan en arm(), SPEC-11):
--   stride_seq : la plantilla, por pie, en cada IC (SPEC-01/02).
--   cycle_seq  : la cintura, al emparejar una zancada izquierda con una derecha (SPEC-05).
-- La ingesta es idempotente: el host escribe con upsert sobre estas claves (ADR-046).
--
-- Toda fila lleva patient_id + session_started_at, y la FK compuesta a sessions garantiza que
-- sean los de su sesion. La RLS filtra por patient_id sin join por fila (ADR-047).
-- ============================================================

-- Zancada = [IC(k), IC(k+1)) de un pie: la unidad alrededor de la que gira el sistema.
create table strides (
  session_id          uuid        not null,
  patient_id          uuid        not null,
  session_started_at  timestamptz not null,
  foot                text        not null check (foot in ('left','right')),
  stride_seq          int         not null,                -- lo asigna la plantilla
  device_id           uuid        references devices(id),  -- plantilla que la detecto
  started_at          timestamptz not null,                -- IC que la abre
  ended_at            timestamptz,                         -- IC siguiente (null hasta conocerlo)
  flags               text[]      not null default '{}',   -- p. ej. IC de baja confianza (SPEC-01/02)
  primary key (session_id, foot, stride_seq, session_started_at),
  foreign key (session_id, patient_id, session_started_at)
    references sessions (id, patient_id, started_at)
) partition by range (session_started_at);

-- Eventos de marcha: IC / MS / TO de cada zancada (ADR-038). MS y TO llevan el stride_seq de su IC.
create table gait_events (
  session_id          uuid        not null,
  patient_id          uuid        not null,
  session_started_at  timestamptz not null,
  foot                text        not null check (foot in ('left','right')),
  stride_seq          int         not null,
  type                text        not null check (type in ('IC','TO','MS')),
  time                timestamptz not null,                -- instante del evento
  confidence          real,
  flags               text[]      not null default '{}',   -- p. ej. 'no_crossover' en MS (ADR-038)
  primary key (session_id, foot, stride_seq, type, session_started_at),
  foreign key (session_id, foot, stride_seq, session_started_at)
    references strides (session_id, foot, stride_seq, session_started_at),
  foreign key (session_id, patient_id, session_started_at)
    references sessions (id, patient_id, started_at)
) partition by range (session_started_at);

-- Un vector por zancada (scope left/right) o por ciclo bilateral (scope bilateral):
-- unit_seq = stride_seq (por pie) o cycle_seq (bilateral). El bilateral guarda ademas el par de
-- zancadas que cerro el ciclo. features_source distingue el vector del micro del recalculado
-- off-device (ADR-036): en la fase operativa conviven los dos para la misma unidad.
create table feature_vectors (
  session_id          uuid        not null,
  patient_id          uuid        not null,
  session_started_at  timestamptz not null,
  scope               text        not null check (scope in ('left','right','bilateral')),
  unit_seq            int         not null,
  left_stride_seq     int,
  right_stride_seq    int,
  -- Columnas constantes: existen solo para que cada FK apunte a la zancada del pie correcto.
  left_foot           text        not null default 'left'  check (left_foot  = 'left'),
  right_foot          text        not null default 'right' check (right_foot = 'right'),
  features_source     text        not null check (features_source in ('device','offline')),
  feature_set_version text        not null,
  time                timestamptz not null,                -- cierre de la zancada o del ciclo
  features            jsonb       not null,                -- {feature: valor} (ADR-031)
  flags               text[]      not null default '{}',   -- features marcadas (SPEC-02)
  primary key (session_id, scope, unit_seq, features_source, feature_set_version, session_started_at),
  constraint feature_vectors_scope_ck check (
       (scope = 'left'      and left_stride_seq  = unit_seq and right_stride_seq is null)
    or (scope = 'right'     and right_stride_seq = unit_seq and left_stride_seq  is null)
    or (scope = 'bilateral' and left_stride_seq is not null and right_stride_seq is not null)
  ),
  -- Con MATCH SIMPLE (el default), una FK con alguna columna nula no se chequea: el vector de
  -- un pie solo verifica la zancada de ese pie; el bilateral verifica las dos.
  foreign key (session_id, left_foot, left_stride_seq, session_started_at)
    references strides (session_id, foot, stride_seq, session_started_at),
  foreign key (session_id, right_foot, right_stride_seq, session_started_at)
    references strides (session_id, foot, stride_seq, session_started_at),
  foreign key (session_id, patient_id, session_started_at)
    references sessions (id, patient_id, started_at)
) partition by range (session_started_at);

-- PENDIENTE (ADR-031 / CP-20): columnas generadas STORED + indices de expresion sobre
-- las features "calientes" del dashboard. No se pueden fijar todavia: dependen de que se
-- congele el feature_set_version y de que exista el dashboard (diferido a la maxima, ADR-033).

-- Un score por unidad evaluada y por modelo: se identifica igual que el vector que lo disparo
-- (scope + unit_seq), mas el modelo (ADR-046). La FK (model_id, patient_id) impide guardar el
-- score de un paciente calculado con el modelo de otro (ADR-043 rev); como patient_id es
-- obligatorio, un modelo global no puede dejar scores.
create table anomaly_scores (
  session_id          uuid        not null,
  patient_id          uuid        not null,
  session_started_at  timestamptz not null,
  model_id            uuid        not null,
  scope               text        not null check (scope in ('left','right','bilateral')),
  unit_seq            int         not null,
  time                timestamptz not null,
  window_strides      int,                                 -- N de la ventana evaluada (SPEC-05/09)
  score               double precision not null,
  threshold           double precision,
  is_anomaly          boolean,
  drift_metric        double precision,
  primary key (session_id, model_id, scope, unit_seq, session_started_at),
  foreign key (model_id, patient_id) references models (id, patient_id),
  foreign key (session_id, patient_id, session_started_at)
    references sessions (id, patient_id, started_at)
) partition by range (session_started_at);

-- Crudo puntual retenido ante anomalia (modo edge): FK real al score que lo pidio (ADR-046).
-- No se particiona: una fila por anomalia, volumen bajo.
create table anomaly_raw_snippets (
  id                  uuid primary key default gen_random_uuid(),
  session_id          uuid        not null,
  patient_id          uuid        not null,
  session_started_at  timestamptz not null,
  model_id            uuid        not null,
  scope               text        not null,
  unit_seq            int         not null,
  device_id           uuid        references devices(id),  -- plantilla de la que vino el crudo
  storage_url         text,
  start_time          timestamptz,
  end_time            timestamptz,
  foreign key (session_id, model_id, scope, unit_seq, session_started_at)
    references anomaly_scores (session_id, model_id, scope, unit_seq, session_started_at),
  foreign key (session_id, patient_id, session_started_at)
    references sessions (id, patient_id, started_at)
);

-- ============================================================
-- Indices (en las tablas particionadas se propagan solos a cada particion)
-- ============================================================
-- La RLS filtra por patient_id: tiene que encabezar un indice (ADR-047).
create index on strides              (patient_id, session_started_at);
create index on gait_events          (patient_id, session_started_at);
create index on feature_vectors      (patient_id, session_started_at);
create index on anomaly_scores       (patient_id, session_started_at);
create index on anomaly_raw_snippets (patient_id);
create index on sessions             (patient_id, started_at desc);
-- Pares de paridad device/offline de una sesion (ADR-036).
create index on feature_vectors      (session_id, features_source, time);

-- ============================================================
-- Particiones (ADR-044): pg_partman crea las mensuales por adelantado y una default.
-- ============================================================
select partman.create_parent(
  p_parent_table := 'public.strides',
  p_control      := 'session_started_at',
  p_type         := 'range',
  p_interval     := '1 month',
  p_premake      := 4
);
select partman.create_parent(
  p_parent_table := 'public.gait_events',
  p_control      := 'session_started_at',
  p_type         := 'range',
  p_interval     := '1 month',
  p_premake      := 4
);
select partman.create_parent(
  p_parent_table := 'public.feature_vectors',
  p_control      := 'session_started_at',
  p_type         := 'range',
  p_interval     := '1 month',
  p_premake      := 4
);
select partman.create_parent(
  p_parent_table := 'public.anomaly_scores',
  p_control      := 'session_started_at',
  p_type         := 'range',
  p_interval     := '1 month',
  p_premake      := 4
);

-- Cierra las particiones hijas (ADR-047): RLS habilitado y sin grants para los roles de la API.
-- Todo acceso pasa por la tabla madre, que es la que tiene las politicas: una particion nombrada
-- en forma directa se chequea sola. Corre despues de cada mantenimiento de pg_partman.
create or replace function private.secure_partitions()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  part regclass;
begin
  for part in
    select i.inhrelid::regclass
    from pg_catalog.pg_inherits i
    join pg_catalog.pg_class madre on madre.oid = i.inhparent
    join pg_catalog.pg_namespace n on n.oid = madre.relnamespace
    where n.nspname = 'public'
      and madre.relname in ('strides', 'gait_events', 'feature_vectors', 'anomaly_scores')
  loop
    execute format('alter table %s enable row level security', part);
    execute format('revoke all on table %s from anon, authenticated', part);
  end loop;
end;
$$;

-- ============================================================
-- Grants explicitos (ADR-047). Supabase ya no expone tablas nuevas por defecto: lo que no
-- tiene grant no existe para la Data API. Los grants deciden QUE TABLAS; la RLS, QUE FILAS.
--   anon          -> nada.
--   authenticated -> lo que escribe el host (JWT del investigador, ADR-032); no borra nada.
--   service_role  -> todo (el worker; saltea la RLS por diseno).
-- Sobre las tablas particionadas, el grant es sobre la madre: las particiones no lo heredan.
-- ============================================================
grant select, insert, update on
  patients, sessions, devices, models, model_deployments, feedback_config,
  strides, gait_events, feature_vectors, anomaly_scores
  to authenticated;
grant select, insert on raw_blobs, anomaly_raw_snippets, retrain_jobs to authenticated;
grant select on firmware_images, patient_access to authenticated;

grant select, insert, update, delete on
  patients, devices, sessions, patient_access, raw_blobs, anomaly_raw_snippets,
  models, model_deployments, firmware_images, retrain_jobs, feedback_config,
  strides, gait_events, feature_vectors, anomaly_scores
  to service_role;

revoke all on function private.accessible_patient_ids() from public, anon;
revoke all on function private.secure_partitions() from public, anon, authenticated;
grant usage on schema private to authenticated;
grant execute on function private.accessible_patient_ids() to authenticated;

-- ============================================================
-- RLS en TODAS las tablas expuestas (ADR-032 + ADR-047)
-- ============================================================
alter table patients             enable row level security;
alter table devices              enable row level security;
alter table sessions             enable row level security;
alter table patient_access       enable row level security;
alter table raw_blobs            enable row level security;
alter table anomaly_raw_snippets enable row level security;
alter table models               enable row level security;
alter table model_deployments    enable row level security;
alter table firmware_images      enable row level security;
alter table retrain_jobs         enable row level security;
alter table feedback_config      enable row level security;
alter table strides              enable row level security;
alter table gait_events          enable row level security;
alter table feature_vectors      enable row level security;
alter table anomaly_scores       enable row level security;

-- Datos de pacientes: filtro directo por patient_id (indexado).
create policy p_patients on patients
  for all to authenticated using (id in (select private.accessible_patient_ids()));

create policy p_sessions on sessions
  for all to authenticated using (patient_id in (select private.accessible_patient_ids()));

create policy p_feedback_config on feedback_config
  for all to authenticated using (patient_id in (select private.accessible_patient_ids()));

create policy p_retrain_jobs on retrain_jobs
  for all to authenticated using (patient_id in (select private.accessible_patient_ids()));

create policy p_strides on strides
  for all to authenticated using (patient_id in (select private.accessible_patient_ids()));

create policy p_gait_events on gait_events
  for all to authenticated using (patient_id in (select private.accessible_patient_ids()));

create policy p_feature_vectors on feature_vectors
  for all to authenticated using (patient_id in (select private.accessible_patient_ids()));

create policy p_anomaly_scores on anomaly_scores
  for all to authenticated using (patient_id in (select private.accessible_patient_ids()));

create policy p_anomaly_raw_snippets on anomaly_raw_snippets
  for all to authenticated using (patient_id in (select private.accessible_patient_ids()));

-- raw_blobs llega al paciente por la sesion, que ya filtra con su propia RLS.
create policy p_raw_blobs on raw_blobs
  for all to authenticated using (session_id in (select s.id from public.sessions s));

-- models: los globales (patient_id nulo) se leen; se escriben solo los de pacientes propios.
create policy p_models_read on models
  for select to authenticated
  using (patient_id is null or patient_id in (select private.accessible_patient_ids()));
create policy p_models_insert on models
  for insert to authenticated
  with check (patient_id in (select private.accessible_patient_ids()));
create policy p_models_update on models
  for update to authenticated
  using (patient_id in (select private.accessible_patient_ids()))
  with check (patient_id in (select private.accessible_patient_ids()));

-- Tablas sin datos de pacientes: igual con RLS, para que nada quede abierto por omision (ADR-047).
create policy p_devices on devices
  for all to authenticated using (true) with check (true);

create policy p_firmware_images on firmware_images     -- la escribe solo service_role (OTA)
  for select to authenticated using (true);

create policy p_model_deployments on model_deployments  -- models ya filtra con su propia RLS
  for all to authenticated using (model_id in (select m.id from public.models m));

-- Cada usuario ve sus propias concesiones; otorgarlas es tarea del service_role.
create policy p_patient_access on patient_access
  for select to authenticated using (user_id = (select auth.uid()));

-- Al reasignar la cintura a otro paciente se borran bonds + datos del equipo (ADR-028 / ADR-032);
-- el mecanismo en la minima es el check-out del pipeline de sesion (ADR-043 rev).

-- ============================================================
-- Mantenimiento diario (ADR-044): particiones nuevas y, despues, cerrarlas (ADR-047).
-- ============================================================
select private.secure_partitions();   -- cierra las que acaba de crear create_parent
select cron.schedule('partman-maintenance', '0 3 * * *', $$call partman.run_maintenance_proc()$$);
select cron.schedule('secure-partitions',   '30 3 * * *', $$select private.secure_partitions()$$);
