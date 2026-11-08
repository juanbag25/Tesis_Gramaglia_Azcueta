# Informes completos de los cinco subagentes (2026-11-08)

> Copiados tal cual. Son la evidencia detrás del diagnóstico: cada hallazgo trae sus citas `archivo:línea`. Las severidades son las de cada subagente; el agente principal las reconcilió en el diagnóstico (`01_conversacion.md`). Abreviaturas usadas por los subagentes:
> SPEC/SPECS = `docs/arquitectura/vistas/2_specs_algoritmos_firmware.md` · SAT = `docs/arquitectura/vistas/3_analisis_features_y_algoritmos.md` · V1–V4 = las vistas en `docs/arquitectura/vistas/` · BIT = `docs/decisiones/bitacora_decisiones.md` · CPs/CP = `docs/cuestiones_pendientes.md` · CRONO/CRON = `docs/cronograma.md` · FEAT = `docs/investigacion/features_anomaly_detection_stroke.md` · MARCO = `docs/marco_teorico/marco_teorico_documento_de_trabajo.md` · SQL/SCHEMA/schema = `src/db/schema.sql` · PIPE = `docs/arquitectura/pipeline_sesion.mermaid` · CALIB = `docs/arquitectura/calibracion_baseline.mermaid` · FWREADME = `src/firmware/README.md` · PINOUT = `docs/investigacion/pinout_pico2.md` · ALIM = `docs/arquitectura/esquema_alimentacion.md`.

---

## Informe 1 — Contratos de interfaz y formatos (Fase 1)

Fue sólo lectura: no toqué ningún archivo. Qué hallazgo responde a cada pregunta: P1→H1/H2 · P2→H7 · P3→H4/H8 · P4→H3 · P5→H5 · P6→H6 · P7→sin dependencias ocultas (ver §3).

### 1. Hallazgos que bloquean o desvían

**H1 — `device_id` no tiene códigos y nada dice de qué pie es cada plantilla. Severidad: bloquea (la decisión es chica).**
- Qué dicen las fuentes:
  - Vista 1:90 da `[device_id | seq …]`, sin tipo ni valores.
  - ADR-050:1767 dice "el primer byte dice qué equipo es". ADR-048:1678 dice "`device_id` = la cintura".
  - El emparejado es "fijo/de fábrica" (Vista 1:77) y hay un solo build de plantilla (Vista 2:11), con `firmware_images.target_role` ∈ {insole, waist} (schema:210).
  - `hw_uid` identifica "la unidad conectada", es decir la cintura (ADR-059:2074). "Plantillas asociadas" (SPEC-11, specs:406) no trae ni `hw_uid` ni lado.
- Qué frena:
  - f1, formato de muestra y proto (16–22/11).
  - El simulador del host (cronograma:74).
  - El host, que no puede mapear `raw_blobs.device_id`, `sessions.device_set` ni `strides.foot`.
- Opciones:
  - (a) Flag de compilación por pie: son dos builds y choca con una imagen OTA única.
  - (b) El lado queda en flash; la plantilla lo declara en un saludo y la cintura lo reenvía al host con `hw_uid` y firmware.
  - (c) La cintura asigna el lado por `hw_uid` con una tabla que le baja el host desde `devices.role`.

**H2 — No está fijado en qué marco viaja `lin_accel`, ni la convención de los ángulos. Severidad: desvía (alto).**
- Qué dicen las fuentes:
  - SPEC-04 (specs:117) expone `lin_accel` "en frame sensor y frame mundo". La muestra (Vista 1:90, ADR-042:1356) no dice cuál de los dos viaja.
  - SPEC-03 paso 1 (specs:88) rota "del frame sensor al frame global".
  - #30, #32 y #33 (análisis:81, 88-89) piden ejes vertical, AP y ML.
  - Tampoco se fija el orden de Euler de pitch/roll/yaw, ni si la alineación anatómica (specs:125) queda aplicada al dato.
- Por qué importa:
  - Las escalas sí se delegaron (Vista 1:104, ADR-055:1946); el marco no es una escala.
  - Si el micro manda marco mundo y el worker aplica SPEC-03 tal como está, rota dos veces. Es el error silencioso que ADR-042 quería evitar.
  - El crudo es irreversible: hay que fijarlo antes del piloto y de M2.
- Qué frena: f2 (AHRS y calibración, 23/11–6/12) y el contrato de `shared/`.
- Opciones:
  - (a) Marco sensor, con o sin alineación anatómica, y la convención de Euler escrita en `shared/`.
  - (b) Marco mundo o anatómico, y SPEC-03 sin el paso 1 cuando lee crudo.

**H3 — La sincronización no tiene spec. Severidad: desvía.**
- Qué dicen las fuentes:
  - Vista 1:141 y el maestro:143 mandan "beacon en firmware, regresión de drift, formato del mensaje de referencia" a la Vista 2 §4.
  - La Vista 2 (l.63-67) sólo tiene los tres requisitos de ADR-061.
  - Los parámetros de SPEC-11 (specs:432) no incluyen nada de esto.
- Qué falta definir:
  - el período del beacon y la ventana de la regresión;
  - cómo se aplica la corrección (de golpe o gradual, y si `t_device` queda monótona);
  - qué manda la plantilla antes del primer ajuste;
  - cómo se calcula `sync_error_us`;
  - qué es "sync activa" en la fase 6 (Vista 4:142). CP-28 difiere sólo el umbral, y esto es de la mínima.
- Qué frena: f3, cintura con AP, UDP y sincronización (30/11–13/12).
- Opciones: una SPEC-12 corta con valores de arranque, o parámetros en SPEC-11 y `shared/` con un criterio mínimo de "activa" (por ejemplo, N beacons y una recta ajustada).

**H4 — No está definido cuándo corre el stream ni qué muestras son de la sesión. Severidad: desvía.**
- Qué dicen las fuentes:
  - SPEC-11 (specs:424) dice que en IDLE "muestrea para el panel si se lo piden", pero ningún comando lo pide (specs:412-420).
  - `arm()` (specs:418) "habilita el scoring": en exploratoria no hay scoring.
  - En la máquina de estados (specs:434), ARMED→RUNNING no tiene comando.
- Qué frena: f4 (BLE y comandos) y b2 (Parquet por sesión).
- Opciones:
  - (a) Stream sólo entre `arm()` y `close()`.
  - (b) Stream siempre prendido, y el host graba desde `arm()`.
  - (c) Un comando explícito para prenderlo y apagarlo.

**H5 — El registro de sincronización pisa el archivo del crudo. Severidad: desvía.**
- Qué dicen las fuentes:
  - La ruta `raw/{patient_id}/{session_id}/{equipo}/{tramo}.parquet` no lleva `kind` (ADR-055:1948, Vista 4:51, schema:131).
  - El registro va "por tramos, junto al crudo de esa plantilla" con `kind='sync'` (ADR-061:2130).
- Por qué importa:
  - El tramo N de muestras y el tramo N del registro dan el mismo nombre: con upsert, uno sobrescribe al otro.
  - Tampoco hay columnas definidas para el registro, que tiene dos tipos de fila: beacons recibidos y correcciones.
- Qué frena: b2.
- Opciones: poner `kind` en la ruta, y usar como columnas las del mensaje de ADR-061.

**H6 — `device_status` no puede guardar nada anterior a la sesión. Severidad: desvía.**
- Qué dicen las fuentes:
  - `device_status` tiene `session_id not null` y una FK a `sessions (id, patient_id, started_at)` (schema:454, 466).
  - La fila de la sesión recién se crea en la fase 7 (Vista 4:143, schema:91).
  - El canal de estado corre desde la fase 1 (Vista 4:137).
- Por qué importa: se pierden el warm-up y el gate térmico, y eso contradice "da datos para CP-25" (schema:451) y "lo que no se graba en el momento no se recupera" (Vista 4:175).
- Qué frena: b2.
- Opciones:
  - (a) Guardar sólo lo de la sesión y corregir el comentario.
  - (b) Bufferear lo previo y escribirlo bajo la sesión cuando se crea (cae en la misma partición).
  - (c) Cambiar el esquema.

**H7 — No está definido cuántas muestras van por datagrama UDP. Severidad: desvía (bajo).**
- Qué dicen las fuentes:
  - Vista 1:85 sólo dice "UDP con nº de secuencia + timestamp por muestra".
  - "Un mensaje por paquete" (ADR-050:1744) vale para protobuf, y la muestra no lo es (l.1759).
  - Para BLE sí se fijaron 4 muestras por notificación (ADR-051:1793).
- Por qué importa: 1 o 4 muestras por datagrama son 200 o 50 paquetes/s de WiFi. Es justo lo que mide la prueba de coexistencia de la fase 0 (cronograma:78, hito del 22/11).
- Opciones: 1, 4 o un parámetro, fijado antes del banco.

**H8 — Faltan mensajes para escribir `mensajes.proto`. Severidad: desvía (bajo).**
- Falta el heartbeat, que la mínima necesita (ADR-049:1704; esquema_alimentacion:172). No está en las tablas de canales (ADR-050:1747-1757, Vista 1:115-126).
- Su sentido, "cintura→plantillas", no basta para que la cintura detecte una plantilla caída.
- Falta el saludo de identidad de H1.
- El comando de feedback también falta, pero es del borde y está diferido.
- Lo demás está enumerado; lo que queda es mecánica (números de campo, códigos de error).

**Sólo doc (las reglas de fuente única los resuelven):**
- ADR-056:1979 dice que quién corrige la hora es "detalle de implementación", pero ADR-061:2120 y la Vista 2:67 fijan que corrige la plantilla.
- ADR-055:1949 da la terna sin `kind`; el esquema (schema:146) ya lo incluye.
- ADR-050 y ADR-051 no listan el registro de sincronización; la Vista 1:124 sí.
- La tabla de ADR-043 rev (l.1463, 1466) exige modelo y presupuesto de sync; la corrigen sus notas (l.1470/1472) y la Vista 4.
- La Vista 1:148 y la fase 7 del pipeline ponen la detección de eventos en la plantilla durante la captura. SPEC-11:417 y ADR-062:2164 la llevan a Python en la exploratoria.

**Cuestiones abiertas:** ninguna bloquea más de lo que dice el registro. CP-28 diferida deja sin criterio la "sync activa" (H3).

### 2. Descartados por menores o casos borde
- Escalas de los int16, rango del MPU-6050 y endianness o empaquetado del struct: delegados al implementar (Vista 1:104, ADR-026:779, ADR-058:2040). Hay que fijarlos antes de M2.
- Si la cabecera de fragmentación también va en `stream`: ADR-051:1800 la delega al código.
- Nombre del bucket y formato de `storage_url`: son parte de la tarea b1.
- DLE e intervalo de conexión BLE: son parámetros de banco.
- Los caudales viejos de ADR-002/003/008/041 son registro histórico.
- `arm(session_id)` en la fase 6 con la fila creada en la 7: lo resuelve un UUID generado por el host.
- `provision()` en exploratoria va con la lista vacía y sin `feedback_config`: alcanza con campos opcionales.
- Sin modelo no hay "paciente en flash": es inocuo.
- `raw_blobs` no tiene UPDATE, así que reenviar un tramo queda en "ignorar".
- Las filas se convierten a UTC con la recta provisoria: lo acepta ADR-056.
- `packets_lost` no dice de qué enlace cuenta.
- src/README.md:8 dice "por definir" para el host.

### 3. Verificado y en orden
- **Muestra:** 39 B (1+4+8+6+6+6+8). Orden y tipos iguales en todos los documentos vigentes; ninguno sigue con uint32, 2 slots o sin orientación. Los caudales de 3,9, 7,8 y 11,7 KB/s y las ~75 notificaciones/s coinciden en todos.
- **BLE:** las 5 características, Battery y Device Information, la prioridad, el MTU de 185/182 B y las notificaciones de 156 B coinciden entre ADR-051, las Vistas 1 y 4, el stack y los README.
- **Canales:** la tabla de ADR-050 coincide con la de la Vista 1 §4.
- **Hora:** la recta, el intercambio cada ~10 s, las columnas `clock_*` y `gait_events.t_device` coinciden entre ADR-056, el esquema, el ER, las Vistas 1 y 4 y el README del host.
- **Parquet:** columnas, metadatos, zstd, tramos de ~5 min y `chunk_index` coinciden con el esquema (salvo H5).
- **Canal de estado:** contenido y período de 1-2 s coherentes entre ADR-043 rev, Vista 2, Vista 4, SPEC-11, ADR-059, el esquema y la característica `estado`.
- **ADR-057:** lo respetan la Vista 4 (fases 3 y 6), SPEC-11, el pipeline y la Vista 2 §8. M1 no depende del OTA ni del sobre si la lista de modelos va vacía.

---

## Informe 2 — Esquema de la base (src/db/schema.sql)

Encontré cuatro hallazgos. Ninguno hace fallar la migración base. El primero es el que importa. El resto de lo pedido está en orden.

### 1. Hallazgos que bloquean o desvían la implementación

**H1. Nadie numera las zancadas, eventos y ciclos que detecta Python, y la base guarda una sola segmentación por sesión.** (*desvía* la Fase 2; *bloquea* sólo comparar los eventos del micro con los de Python, que es del demostrador opcional)
- **El esquema dice que numera el borde:** schema.sql:322 "Numeracion en el borde (… arm(), SPEC-11)", l.337 `stride_seq … -- lo asigna la plantilla`. ADR-046 (bitácora l.1584) y SPEC-05 (specs l.156) asignan `cycle_seq` a "un contador que arranca en arm()".
- **En la mínima detecta Python:**
  - ADR-005 rev c (l.226): en la exploratoria "se sube sólo crudo continuo".
  - SPEC-11 (specs l.417): "en la exploratoria los pasos se detectan en Python".
  - ADR-062 (l.2164) dice lo mismo.
  - El cronograma pasa las features del micro a trabajo futuro (l.70) y pone "eventos y features en Python" en la Fase 2 (l.80).
- **Contradicción entre documentos:** la Vista 1 §6 (1_vista_sistema.md:148) pone "Detección de eventos … y numeración de zancadas | Plantilla" también en captura. pipeline_sesion.mermaid:79 manda "eventos + features por-pie" en toda sesión.
- **El reproceso está previsto, pero no cabe:**
  - ADR-062 (l.2163) pide que "la sesión se pueda reprocesar".
  - El piloto ajusta los umbrales del detector y la pausa (cronograma l.80).
  - ADR-061 (l.2136) prevé resincronizar offline.
  - SPEC-01 (l.35) versiona `W, t_ref, h_ms` "junto con el feature_set_version". Pero las PK de `strides` (l.342) y `gait_events` (l.359) no llevan versión ni origen; sólo `feature_vectors` (l.386).
- **Por qué importa:** el worker de la Fase 2 tiene que inventar la numeración. Si reprocesa con upsert, la zancada (sesión, pie, k) pasa a ser otra zancada física, y los vectores y scores viejos siguen apuntándole sin que la FK lo note. Además, una segmentación del micro y una de Python no pueden convivir en la misma sesión.
- **Opciones:**
  - (a) Una sola segmentación por sesión: el worker numera de 0 por pie en orden de IC, fija una regla para `cycle_seq`, y reprocesar es borrar y reescribir con `service_role`. Se documenta en ADR-046 y Vista 4 §1.6.
  - (b) Sumar `origen` o `versión de segmentación` a las PK de `strides` y `gait_events` y a las FK de `feature_vectors`, antes de la migración base.
  - (c) No guardar en la base las series offline de la exploración. Choca con ADR-036.

**H2. No hay dónde registrar cuál es "la sesión de calibración" ni la tarea o anomalía inducida de cada sesión.** (*desvía*)
- **Lo que piden los ADR:** ADR-057 (l.2018) hace que el worker calcule la versión 1 "con las features de la sesión de calibración" y la guarde en `models.source_session_id` (schema l.171-173).
- **Lo que tiene el esquema:** `sessions` sólo tiene `mode`, `environment` y `notes`.
- **El modo no la identifica:** ADR-005 (l.227) y la Vista 3 §5 (3_vista_datos_ml.md:70) dicen que la calibración es una captura **operativa** con features del micro. Pero en la mínima esas features no existen (cronograma l.70), así que la sesión de calibración va como exploratoria.
- **La interfaz tampoco lo pide:** la fase 2 de la Vista 4 (l.138) pregunta sólo paciente, modo y `adaptation_enabled`.
- **Por qué importa:** la Fase 4 necesita las etiquetas de las anomalías inducidas (cronograma l.64 y l.82). Afecta a la UI mínima (b3) y al worker. CP-33 figura como "no bloquea el código" (cuestiones l.26), pero sí bloquea esta pieza.
- **Opciones:** una columna `sessions.purpose` más un jsonb de protocolo que se llena según CP-33; una convención en `notes`; o una tabla de tramos con su condición, si las anomalías se inducen dentro de una misma sesión.

**H3. Permiso de escritura sobre `raw_blobs`: el ADR y el esquema no coinciden.** (*desvía*, menor)
- **Lo que dice ADR-047** (l.1635): `authenticated` "inserta y actualiza … blobs … jobs manuales".
- **Lo que hace el esquema** (l.563): `grant select, insert on raw_blobs, …, retrain_jobs` a `authenticated`, sin `update`.
- **Por qué importa:** ADR-055 (l.1949) pide que volver a subir un tramo no duplique, y el host escribe "con upsert" (src/host/README.md:12). El upsert por defecto de supabase-py (`ON CONFLICT DO UPDATE`) va a fallar con *permission denied*. Con `DO NOTHING` queda la primera fila, con un checksum viejo si la primera subida salió incompleta. Afecta al host (b2).
- **Opciones:** dar `UPDATE` en `raw_blobs`, o declarar que el reenvío es `DO NOTHING` y corregir ADR-047.

**H4. Permisos por defecto en la base local y en CI.** (*a verificar*)
- El esquema da permisos pero nunca los revoca (l.550-570): asume el cambio de Supabase del 30/10/2026.
- Si la imagen de la CLI todavía trae los permisos por defecto viejos, `authenticated` conservaría `DELETE` y `anon` sus permisos, contra la matriz de ADR-047 y la prueba pgTAP (b).
- No lo pude confirmar: la consulta al changelog de Supabase falló por el límite de uso.
- Opción barata: `revoke all on all tables in schema public from anon, authenticated` antes de los grants.

*(Nota del agente principal: H4 no se pudo verificar y no se incluyó en el diagnóstico; la prueba pgTAP de ADR-047 lo detectaría al crear la base.)*

### 2. Checklist de cambios de esquema pedidos por los ADR
- **ADR-031** — `features jsonb` (l.384): presente. Columnas generadas: pendientes, ya registradas en CP-20.
- **ADR-032** — RLS por `patient_access` (l.119, 602-663): presente.
- **ADR-036** — `mode` de tres valores (l.71), `features_source` (l.381) e índice de paridad (l.482): presente.
- **ADR-043 rev** — `adaptation_enabled` (l.81), FK `(model_id, patient_id)` (l.424/181) y `unique (patient_id, algo, version)` (l.178): presente.
- **ADR-044** — cinco tablas particionadas por `session_started_at`, `create_parent` mensual con 4 por adelantado y partición default, `pg_cron` diario: presente.
- **ADR-046** — `strides`, `unit_seq`, FK reales, FK compuesta a `sessions` con su ancla (l.113), `flags`, `not null` y PK para el upsert: presente. Numeración de origen offline: **falta** (H1).
- **ADR-047** — grants, RLS en las 17 tablas, esquema `private`, `secure_partitions()`: **parcial** (H3, H4).
- **ADR-049** — `end_reason` (l.97) y `continues_session_id` (l.99): presente.
- **ADR-053** — `artifact_format` limitado a `envelope_v1` (l.167) y `checksum`: presente.
- **ADR-055** — `chunk_index`, unicidad por tramo y `device_id not null`: presente.
- **ADR-056** — `clock_*` (l.103-106) y `gait_events.t_device` (l.356): presente.
- **ADR-057** — sesiones sin modelo (`session_models` vacía, `feedback_config_id` nulo) y `source_session_id`: presente. Marca de la sesión de calibración: **falta** (H2).
- **ADR-059** — `create_patient()` sin INSERT directo (l.286, 562, 577), `feedback_source` como texto con una sola versión activa (l.240, 186), una config vigente por paciente (l.254), `session_models`, `feedback_config_id` con su FK (l.257), `device_status` y `hw_uid`: presente.
- **ADR-061** — `raw_blobs.kind` dentro de la unicidad: presente.
- **ADR-062** — `fsr_calibration` (l.90): presente.
- **ADR-063** — `cohort`, `affected_side`, el CHECK (l.43-49), los parámetros de `create_patient` y `reference_foot not null` (l.85): presente.
- **ADR-064** — `flags` en `strides` y `feature_vectors`: presente.
- **"Los arreglos del punto 4"** del cronograma (l.50): ya están en schema.sql desde e1f40f5. La frase quedó vieja.

### 3. Descartados por menores o casos borde
- "Cinco" tablas de series es correcto. Vista 4 l.20, maestro l.204 y componentes_backend_app.mermaid l.21 nombran sólo cuatro tipos, sin `device_status`: cosmético.
- Maestro §11 l.240 omite ADR-049/053/055/056/062/063 y la fila de `patients` no nombra `cohort`: sólo doc.
- `device_status` exige `session_id`, así que el warm-up previo a la fase 7 no se graba. El comentario "da datos para CP-25" (l.451) es parcial; CP-25 se mide en banco.
- La forma del JSON de `fsr_calibration` y el vocabulario de `flags` (salvo `no_crossover`) no están fijados: mecánica de implementación.
- `anomaly_raw_snippets` no tiene clave natural y su reenvío no es idempotente: es del modo edge, trabajo futuro.
- El índice de paridad no tiene `desc` como pide ADR-036: irrelevante.
- El snapshot con `db dump --schema public` no incluye `private`, la configuración de pg_partman ni los cron: mecánica del script.
- Nombres de los buckets: a criterio. La ruta y la regla de acceso ya están (ADR-055 l.1948).

### 4. Verificado y en orden
- **Tablas:** 17 en schema.sql, 17 en el ER y en la Vista 4 §1.1.
- **Postgres 17:** las PK de las tablas particionadas incluyen la clave de partición; las FK compuestas coinciden en tipos y apuntan a restricciones únicas exactas; el orden de creación es correcto (la FK diferida de `feedback_config` va después, y los índices se crean antes de `create_parent`); las palabras usadas como columnas (`time`, `type`, `class`, `trigger`) son no reservadas.
- **pg_partman / pg_cron:** `p_type := 'range'` coincide con el ejemplo de la documentación de Supabase (firma de 5.x). `CALL run_maintenance_proc()` desde `pg_cron` también coincide con la documentación.
- **RLS:** las funciones y columnas que usan las políticas existen; `for all` con `USING` sirve también de WITH CHECK; las particiones quedan cerradas.
- **Idempotencia:** las cinco series y `session_models` tienen clave natural.
- **Lo que escribe el host en la Fase 1:** pacientes, sesiones con sus columnas, `device_status`, registro de sincronización y referencias al Parquet tienen tablas, grants y políticas. La única excepción es H3.
- **Worker:** corre con `service_role`, que tiene todo y saltea la RLS.

---

## Informe 3 — Firmware de captura y ciclo de sesión

Hay cuatro hallazgos. El primero frena el arranque y hay que decidirlo antes de programar; los otros tres se pueden programar, pero quien lo haga puede implementar lo equivocado.

### 1. Hallazgos que bloquean o desvían

**H1 — No está decidido si en las capturas de la mínima el micro detecta eventos y numera zancadas. Severidad: bloquea.**
- **Fuentes que dicen que no:**
  - SPECS:417: "en la exploratoria los pasos se detectan en Python".
  - BIT:2164 (ADR-062): "En la parte central del cronograma los pasos se detectan en Python".
  - CRON:51 y :80: "eventos y features en Python".
  - La Fase 1-A (CRON:79) no incluye eventos.
- **Fuentes que suponen que sí, en cualquier modo:**
  - FWREADME:7 nombra eventos y `stride_seq` sin condición, y a las features sí les pone "en captura operativa y edge".
  - V2:13 y :57: "Cada IC abre una zancada y la numera".
  - V1:148: "Detección de eventos… y numeración de zancadas | Captura: Plantilla".
  - V4:70 y SCHEMA:337: `stride_seq` "lo asigna la plantilla".
  - SPECS:418: `arm()` reinicia los contadores.
  - PIPE:79-84: la fase 7 tiene eventos, features, inferencia y feedback sin distinguir modo.
- **La calibración como captura operativa:** V3:70-72 y CALIB:1,15,17 la tratan así, con features calculadas en el micro. Eso contradice CRON:70 (las features del micro son trabajo futuro) y BIT:2018 (ADR-057: "para los experimentos offline alcanzan las de Python").
- **Lo que no está escrito en ningún lado:** que las capturas de la tesis son `exploratory`, y quién numera las zancadas cuando los pasos salen de Python.
- **Qué frena:**
  - f2: si SPEC-01/02 va o no en el core 1.
  - f4: la característica `zancadas`, `set_step_thresholds` y los contadores.
  - b2 y el worker: quién escribe `strides` y `gait_events`.
- **Opciones:**
  - (a) Capturas en modo `exploratory`: el micro adquiere, aplica el AHRS y transmite; Python detecta y numera. Hay que corregir los documentos citados.
  - (b) El micro detecta y numera siempre y Python recalcula. Exige mandar los umbrales en todo modo y decidir cómo conviven dos juegos de zancadas, porque `strides` y `gait_events` no tienen columna de origen.
  - (c) Mixto: el micro detecta sólo el apoyo, para uso interno (ver H2), sin numerar.

**H2 — El re-zero del giro "en stance (detectado por FSR)" necesita umbrales que en la exploratoria no llegan al micro. Severidad: desvía.**
- **Qué dicen las fuentes:** SPECS:124 y BIT:500 (ADR-017) lo fijan, y CP:23 (CP-25) lo cuenta como mitigación del warm-up. Pero SPECS:417 manda `F_on`/`F_off` sólo en operativa y edge, y la cintura no tiene FSR (SPECS:110).
- **Por qué importa:** el crudo sale después del AHRS y la calibración no se guarda (SPECS:132). Lo que corra durante las capturas queda fijo en los datos.
- **Qué frena:** f2, y hay que cerrarlo antes de M2.
- **Opciones:** usar sólo la corrección de bias en runtime de Fusion, más el bias de la pose 1; mandar los umbrales siempre y correr un detector de apoyo mínimo; no corregir en runtime. En cualquier caso, definir qué hace la cintura.

**H3 — La salida del módulo IMU no tiene el marco ni la calibración definidos. Severidad: desvía.**
- **Marco de la aceleración:** la muestra lleva un solo `lin_accel` (V1:90). SPECS:117 lo expone "en frame sensor y frame mundo", y SPECS:88 (SPEC-03) supone que llega en marco sensor.
- **Lo que falta además:** la convención de los ángulos, y si la alineación anatómica (SPECS:125) se aplica igual a la orientación y a la aceleración. V1:104 sólo deja para la implementación "las escalas".
- **"Offset de accel (nivelado)":** aparece en SPECS:123, BIT:484 ("Z≈9,81"), PIPE:62-63 (también para la cintura) y V4:141. Choca con la pose 2, que según SPECS:126 da el "vector gravedad y alineación anatómica". Nivelar un sensor que está inclinado sobre el cuerpo mete esa inclinación en el offset, y como no se guarda, el worker no puede deshacerlo.
- **Qué frena:** el contrato de la muestra (f1) y f2, que firmware y host programan en paralelo.
- **Opciones:** fijar en `shared/` el marco de la aceleración, la convención de Euler y que la alineación se aplique a todas las salidas; reemplazar el offset nivelado por la dirección de la gravedad (una rotación), o por un offset de banco por placa medido en varias orientaciones.

**H4 — No está fijado el fondo de escala del MPU-6050. Severidad: desvía.**
- **Qué falta:** ningún documento lo fija. BIT:2051 pide revisar la saturación sólo de los FSR, y el piloto (CRON:80) sólo fija β.
- **Por qué importa:** si nadie lo configura, el sensor queda en ±2 g / ±250 °/s, que es su valor de arranque según el mapa de registros (a confirmar en el datasheet). Es esperable que el pie supere esos valores. Si el giro satura, también se arruina la orientación, y no tiene arreglo después. Las escalas int16 de la muestra dependen de este rango.
- **Qué frena:** el driver del IMU en f2.
- **Opción:** fijarlo ahora (por ejemplo ±8–16 g y ±1000–2000 °/s) y sumar al piloto un chequeo de saturación del IMU.

### 2. Lo que el micro tiene que hacer en la mínima (si se elige H1-a)
- **Plantillas:** FSR por ADC con DMA y decimación ×10; IMU por DMA en el tick de 100 Hz; `t_device` en uint64 y `seq` en cada muestra; AHRS y calibración en dos poses (bias, gravedad y alineación, promedio de cada FSR e indicador de quietud); WiFi como estación sin ahorro de energía; muestra de 39 B por UDP; con los beacons ajusta la recta, pasa `t_device` a la cuenta de la cintura y manda el registro por TCP; estado (VSYS, temperatura, uptime), heartbeat y comandos.
- **Cintura:** su IMU con la misma cadena y los FSR en cero; Access Point; beacon con la hora tomada justo antes del envío de lwIP; GATT con `stream`, `estado` y `control`, y pairing por passkey; máquina de estados de SPEC-11 con `provision([])`, `calibrate`, `arm` sin modelo y `close`; estado cada 1-2 s e intercambio de hora; ante un corte vuelve a IDLE.
- **Lo que no hace falta:** eventos, contadores, features, `set_step_thresholds`, ring buffer y `wipe`, inferencia, motor, OTA ni escritura de flash.
- **Dónde está dicho:** sale de CRON:79, SPEC-04, SPEC-11 y ADR-014/026/042/048/049/056/057/061/062. Lo único escrito explícitamente es SPECS:417 y BIT:2164; el resto lo inferí del cronograma.

### 3. Descartados por menores
- El período del beacon, la ventana de la regresión y el criterio de "sincronización activa" no tienen número. Son parámetros de implementación, y el registro de ADR-061 permite rehacer la sincronización.
- Heartbeat (ALIM:172): faltan el mensaje y los tiempos. En captura alcanza con el stream de 100 Hz.
- SPEC-11 no tiene comando para el stream en IDLE (SPECS:424) ni para pasar de ARMED a RUNNING.
- Gate térmico: BIT:1454 dice "que trackea el micro" y SPECS:430 "el micro no decide". CP-25 no frena el firmware, y el "2-3 min" de SPECS:123 ya está registrado en CP-25.
- VSYS en GP29 comparte el reloj SPI del CYW43 (PINOUT:18), así que hay que pausar el ADC de ADR-014 para leerlo.
- CP-09 deja abierta la "forma de medir batería" como tema de la máxima, pero la mínima la usa: canal de estado, fase 6 y corte por baja tensión. El corte, además, no está en la Fase 1.
- β: creo que Fusion tiene otros ajustes, como el rechazo de aceleración, que habría que congelar junto con β. No lo pude verificar.
- Pairing sin gesto ni multi-host: con dos laptops no está dicho si la cintura acepta un pairing nuevo; se resuelve reflasheando.
- `device_status.session_id` es not null, así que el warm-up no se guarda, aunque SCHEMA:451 diga que da datos para CP-25.
- El demostrador del borde necesitaría una sesión operativa propia después de M2 (BIT:2018).
- BIT:729 y :742 tienen un ejemplo viejo; sólo es documental.

### 4. Verificado y en orden
- **Adquisición:** ADR-014/026, V2 §2 y FWREADME coinciden. La configuración de registros queda para la implementación (BIT:779).
- **Muestra de 39 B:** coherente en todos los documentos.
- **Ciclo de sesión:** las fases 0-8 coinciden en ADR-043 rev, V4 §4.1, SPEC-11 y PIPE. El provisioning puede ir vacío (ADR-057), la fase 6 no exige nada diferido y los cortes coinciden (ADR-049, SPECS:428, `end_reason`).
- **Dos poses (ADR-062):** coherentes en SPECS:35/126/416 y V4:141. Las "100 zancadas" sólo quedan en documentos históricos.
- **Sincronización:** quién emite el beacon, dónde se toma la hora, quién corrige, qué se registra y qué llega al host es coherente en ADR-004/056/061 y V1 §5.
- **Pinout:** coherente en PINOUT, V1 §1, ALIM §4 y ADR-041. Nada del hardware actual frena la Fase 1 en banco.
- **Cores y bare-metal:** coherentes en ADR-024 rev, ADR-025, V2 §9 y FWREADME.
- **Motor:** no tiene función en la mínima (SPEC-11 regla 1, V1 §6, ADR-035).

---

## Informe 4 — Pendientes, huérfanos y coherencia global

Sólo lectura: no modifiqué nada. Lo de bleak lo verifiqué en su código fuente; el resto sale de los archivos del repo.

### 1. Las 13 cuestiones abiertas

| CP | Qué bloquea | ¿El registro lo dice bien? |
|---|---|---|
| 01 | Nada de las Fases 1 y 2 (los 2 FSR son fijos y la revisión del PCB es trabajo futuro). Lo del motor (ERM o LRA) sólo afecta al demostrador. | Sí, pero no refleja que el PCB pasó a trabajo futuro. |
| 06 | La máxima. | Sí. |
| 09 | La máxima (la autonomía se mira en el piloto). | Sí. |
| 18 | Las capturas con personas (Fase 3), y quizás el piloto (cronograma.md:173 lo deja como consulta). Si el comité pide auditoría de accesos, hará falta una migración más adelante. | Sí. |
| 20 | La máxima. | Sí. |
| 21 | Nada de la mínima. La captura no infiere, los experimentos son en Keras offline y el demostrador usa Mahalanobis, que "no necesita TFLite Micro" (cronograma.md:66). | **No**: cuestiones_pendientes.md:21 dice "primer ítem de banco al arrancar `src/`" (ver §3.2). |
| 22 | Nada: se decide con datos y en el dashboard. | Sí. |
| 25 | **No bloquea el código.** SPEC-11 (2_specs:430) dice "el host aplica el criterio de estabilidad… se ajusta sin reflashear", y Vista 4:146 agrega un temporizador de respaldo. Bloquea el protocolo (el tiempo muerto de cada sesión) y las capturas. Ojo: `device_status` exige `session_id` (schema.sql:454) y la sesión recién se crea en la fase 7, así que el sistema no graba el warm-up, aunque schema.sql:451 diga que "da datos para CP-25". La prueba de banco necesita un registro propio. | Sí, salvo esa promesa del esquema. |
| 28 | La máxima. La Fase 1 implementa el beacon, la recta y el registro (ADR-061) sin umbral numérico. | Sí. |
| 32 | La máxima. | Sí. |
| 33 | El firmware no; **el esquema y la UI de la Fase 1-B sí** (ver §2c). | **A medias**: "no bloquea el código" (l.26) vale sólo para el firmware. |
| 35 | La captura no. **La Fase 2 sí:** define el evento MS (`F_ante ≥ F_post`), y de él dependen #43, #44, las instancias por sub-fase de #12-14 y la marca `no_crossover`, que entra al baseline (ADR-064). También afecta #19 y #20/#40, y #44 a través de `F_total` (ADR-058:2042). Cierra el 22/11, a tiempo. Riesgo de la propuesta: si el FSR de punta carga poco con la persona parada, `carga − cero` es chico y la normalización amplifica el ruido y adelanta el cruce. Conviene mirarlo en banco antes de cerrarla. | Correcto, pero le falta decir que condiciona la Fase 2. |
| 37 | La Fase 4 (el AUC no depende del umbral). | Sí. |

### 2. Huérfanos que afectan la mínima

**a) Quién numera las zancadas en la mínima. Desvía (Fase 2 y migración base).**
- Lo que dicen los documentos: ADR-046:1583 "los contadores arrancan en `arm()`… `stride_seq` — la plantilla"; schema.sql:337 "lo asigna la plantilla"; Vista 1:148 pone la detección de eventos y la numeración "en la plantilla" también en captura.
- Lo que va a pasar: ADR-062:2164 y SPEC-11:417 dicen que en la exploratoria "los pasos se detectan en Python", y el cronograma no pone eventos en el firmware de la Fase 1.
- Lo que falta: quién escribe `strides`/`gait_events` (el worker), desde qué instante cuenta `stride_seq`, y una columna de origen en esas tablas (`feature_vectors` sí tiene `features_source`).
- Por qué importa: los vectores offline necesitan una FK a `strides`. Además, una sesión del demostrador con eventos del micro choca de PK con los eventos offline de esa misma sesión.

**b) Emparejamiento BLE de la mínima. Desvía (Fase 1, BLE).**
- cronograma.md:70 pasa "el gesto de emparejamiento y el multi-host" a trabajo futuro y deja sólo "el emparejamiento básico con passkey".
- ADR-028:819, Vista 2:115-117 y Vista 1:77 siguen describiendo el gesto y la lista de bonds como el mecanismo, sin ninguna nota.
- Sin el gesto, con sólo "auto-advertise sin bond", la cintura no puede aceptar un segundo host (las laptops de los dos autores) ni re-emparejarse si se pierde el bond.
- Falta definir cuándo acepta un emparejamiento nuevo: por ejemplo, con passkey siempre que no haya conexión, o borrando los bonds por comando o por USB. Toca CP-18.

**c) Etiquetas de la sesión para los experimentos. Desvía (Fase 1-B).**
- `sessions` sólo tiene `mode`, `environment` y `notes` (schema.sql:71-110), y la fase 2 de la UI pide paciente, modo y `adaptation_enabled` (Vista 4:138).
- No hay dónde marcar la tarea, la anomalía inducida (tipo y lado) ni la tanda de calibración. La Fase 4 lo necesita, y depende de CP-33 (protocolo, 20/11).
- Conviene fijarlo antes de la migración base (b1, hasta el 29/11).

### 3. Inconsistencias de estado y de decisiones
1. **El recorte de alcance del cronograma no llegó a los documentos que leen los implementadores. Desvía.**
   - **Adaptación online.** ADR-043:1397 dice que "tiene que existir en la mínima"; cronograma.md:70 la pasa a trabajo futuro. Consecuencia concreta: schema.sql:81 tiene `adaptation_enabled … default true`, y su comentario promete "exactamente una versión nueva al cerrar". Con eso, todas las sesiones de la tesis quedarían marcadas como adaptadas. Hay que pasar el default a `false` antes de la migración base.
   - **Modo de la calibración.** Vista 3:70/72, el satélite:159, calibracion_baseline.mermaid:15 y ADR-005:227 dicen que la calibración es una captura operativa con features del micro. En el alcance no hay features en el micro; sólo ADR-057:2018 admite las de Python. Quien programe la UI no va a saber qué `mode` lleva la sesión de calibración (tiene que ser `exploratory`).
   - **OTA.** Vista 2:90 dice "OTA completo desde el inicio" (también el maestro §9 y la regla de sellado de CLAUDE.md); cronograma.md:70 dice "no se sella ninguna plantilla; se programan por USB".
2. **CP-21 como alerta de arranque. Desvía.** CLAUDE.md:189 la marca como "la única que amerita alerta en el onboarding", el registro (l.21) la pone como primer ítem de banco, y README.md:71 y src/firmware/README.md:21 listan TFLM como dependencia. En cambio, cronograma.md:66 y memory.md:15 dicen que "sale del camino crítico", y el cronograma no agenda esa prueba. Riesgo: meter `pico-tflmicro` en el proyecto CMake de la tarea f1.
3. **Stack: bleak no hace Passkey Entry en Windows. Desvía.** ADR-028:826 dice que el usuario tipea el passkey "en la app", ADR-051:1802 exige enlace cifrado y autenticado, y el stack elige bleak (stack_tecnologico.md:48). En el código de bleak (`backends/winrt/client.py`, rama develop), `pair()` usa sólo `DevicePairingKinds.CONFIRM_ONLY`, con el comentario "Currently only supporting Just Works solutions". En Windows el passkey se va a tipear en el diálogo del sistema, no en la UI, salvo que se use WinRT directo. No bloquea si se acepta emparejar desde el sistema, pero hay que decirlo. El resto del stack de las Fases 1 y 2 está elegido y es coherente con los ADR: Pico SDK + lwIP + BTstack, nanopb, Fusion, protobuf, pyarrow, FastAPI. supabase-py y numpy/scipy/pandas/scikit-learn figuran como "candidato", lo que alcanza.
4. **Sólo doc.** README.md:14 y CP-33 (l.26) llaman "propuesta" al cronograma, que ya está confirmado (cronograma.md:3). SPEC-08:259 sigue diciendo "no está mergeado", sin el dato verificado del 2026-11-08. En la bitácora, el índice marca ADR-007 y ADR-037 como "revisada" y su línea de estado dice "aceptada"; tienen nota, así que no confunde. Los conteos coinciden en CLAUDE.md, README y memory: ADR-000 a 064, SPEC-01 a 11, 13 abiertas y 25 resueltas.

### 4. Descartados por menores o casos borde
- Cómo se fija `β` en el piloto: es un parámetro del piloto. Conviene que llegue por `provision` y no como constante de compilación.
- Escalas de los campos de la muestra: se fijan en el contrato al implementar (Vista 1:104, ADR-058), en la tarea f1.
- Período del beacon y ventana de la regresión: Vista 1 §5 remite a Vista 2 §4, que es escueta. Es mecánica.
- Leer VSYS por GP29, compartido con el CYW43, con el ADC corriendo libre: ya anotado en pinout_pico2.md:18.
- Cargar μ/Σ para el demostrador: sólo está diseñado sobre el OTA de ADR-052, que es futuro, y el demostrador es opcional.
- ADR-005:244 "Punto abierto… a ratificar": resto viejo, ya cerrado por CP-02.
- SPEC-04:123 "warm-up 2-3 min": lo cubre CP-25.
- "Check-out (fase 3)" en Vista 2 §7 y schema.sql:666: nombre viejo del provisioning.
- ADR-043:1454 "trackea el micro" contra SPEC-11:430 "el host aplica": compatibles a través del uptime.
- Heartbeat, supervision timeout y umbrales de batería y de pausa: parámetros ya declarados.
- supabase-py falta en la fila del host del stack (sí está en Vista 4 §Stack).

---

## Informe 5 — Features, eventos y análisis offline (Fase 2 y Fase 4)

Encontré 6 problemas. Sólo uno bloquea (H1: las capturas no tienen dónde registrar la condición inducida). Cuatro desvían la implementación y uno es de documentación.

### 1. Hallazgos que bloquean o desvían

**H1. Las capturas no tienen dónde registrar la condición inducida ni las tandas.** *Bloquea la fase 4. Hay que decidirlo antes de la fase 3, y toca código de la fase 1.*
- Para evaluar con anomalías inducidas (CRONO l.64 y l.81) hay que saber qué zancadas son normales y cuáles pertenecen a cada condición. `sessions` sólo tiene `environment` y `notes`, que es texto libre (SQL l.73 y l.110). Ni la Vista 4 ni la UI prevén una etiqueta de condición o de tramo.
- ADR-060 pide descartar "los giros y las primeras y últimas zancadas de cada tanda" (BIT l.2104). ADR-064 sólo marca el *arranque* (BIT l.2206): no hay regla para los giros ni para el fin de una tanda.
- CP-33 dice "no bloquea el código" (CPs l.26), pero esta parte del protocolo sí define campos de la migración base y de la UI.
- Opciones: una sesión por condición o tanda, con una columna estructurada en `sessions`; una tabla de segmentos que el operador marca desde la UI; detectar los giros offline (por ejemplo, con el giro vertical de la cintura) con un umbral que se fija en el piloto.

**H2. CP-35 no frena la fase 1, pero condiciona la fase 2.** *Desvía.*
- **Ceros distintos entre punta y talón:** con cuentas crudas, según cuál de los dos ceros sea mayor, `F_ante ≥ F_post` (SPEC l.22) puede dar MS = IC, o un cruce falso al descargar que esconde un `no_crossover`. Restar el cero de cada sensor es condición para que MS signifique algo, no un refinamiento.
- **El cero cambia de una sesión a otra** (cordones, deriva: BIT l.2149). Por eso #12–14 y #16 en cuentas crudas no se pueden comparar entre la sesión de calibración y las de prueba. "El baseline absorbe los sesgos constantes" (BIT l.2048) vale dentro de una sesión, no entre sesiones.
- **#44** usa la integral sobre `F_total`, que suma dos sensores, así que también depende de su sensibilidad relativa. No figura ni en CP-35 ni en la lista de BIT l.2047.
- **Recomendación (no la decido):** escribir la fase 2 con la normalización como paso parametrizable, aplicado antes de eventos y features (crudo, menos el cero, o `(cuentas−cero)/(carga−cero)`); registrar la variante elegida en los parámetros del `feature_set_version`; usar como mínimo "menos el cero"; elegir la variante con los datos del piloto y cerrarla antes de entrenar en la fase 4.
- **Dos avisos para quien decida:** dividir por la carga cambia lo que es MS (pasa a ser "el antepié supera la proporción que tenía parado", no "igual fuerza en los dos sensores"); si la punta casi no carga en la pose de parado, `carga−cero` es chico y amplifica el ruido.

**H3. MS no está definido para el apoyo de antepié o plano.** *Desvía la fase 2.*
- La regla de IC está pensada justamente para el apoyo de antepié y el *drop foot* (SPEC l.20).
- Si `F_ante ≥ F_post` ya se cumple en el IC, el "primer instante" de SPEC l.22 da MS = IC. Entonces la sub-fase de carga queda vacía (#16 y las instancias de carga de #12–14) y #43 y #44 dan 1.
- `no_crossover` describe el caso contrario: el paciente nunca pasa la carga al antepié (SPEC l.28).
- El *foot drop* simulado es candidato en CP-33, así que en el dataset no va a ser un caso raro.
- Opciones: exigir un cruce de verdad, desde abajo, y si no lo hay usar un flag propio (por ejemplo `forefoot_contact`) y dejar las features de sub-fase como no disponibles; o MS = IC, con flag y baja confianza.

**H4. Al catálogo le faltan definiciones para codificar en Python.** *Desvía la fase 2.*
- **LDLJ (#32–34, y también #47):** la fórmula `−ln((t2−t1)·max‖a‖·∫|a′|²dt)` (SAT l.88, FEAT l.191, SPEC l.380) no es adimensional. La forma para aceleración divide por el pico al cuadrado, y así la implementa scikit-digital-health. MARCO l.546 la atribuye a Brasiliano 2026: falta verificarla contra esa fuente. Para #34, "idem sobre ω" no dice qué forma usar.
- **Ejes y marcos de referencia:** el formato del paquete (V1 l.90) no dice en qué marco va `lin_accel` (SPEC l.117 ofrece el del sensor y el del mundo), ni la convención de los ángulos. Como el yaw deriva (SPEC l.136), hay que decidir si "AP/ML" (#32/#33) y "vertical" (#30) se miden en el marco del pie o según la dirección de marcha. Falta también el eje sagital del giro que usa la confirmación IMU (SPEC l.27). Esto tiene que quedar escrito en el contrato antes de M2, porque el crudo no se puede reprocesar.
- **Bloque H (#35–38 y #41):** SPEC lo calcula por ventana, "no per-zancada" (SPEC l.208 y l.221); FEAT l.196 dice "de cada zancada". `feature_vectors` sólo admite una zancada o un ciclo (SQL l.366). Falta la regla que asigna cada ventana a una zancada.
- **Features sin fórmula:** #19 sólo dice "distribución antero/posterior" (SAT l.57); MARCO l.509 sugiere usar integrales de presión. #21 no dice qué feature de fuerza compara. #20 y #40 no dicen sobre qué features por pie se calculan, ni si van por ciclo o "estabilizado sobre la ventana" (SPEC l.154). #15 necesita un umbral por región, pero ADR-062 sólo define umbrales sobre `F_total` (BIT l.2162).

**H5. En la fase 4, la entrada de los modelos y la selección de features no están cerradas.** *Desvía.*
- **Unidad de entrada:** SAT l.144 dice "vector de features/zancada"; SPEC l.156 puntúa por ciclo; SPEC l.388 habla de un "vector fusionado". La elección cambia las cuentas de *n* y *p* de ADR-060 (BIT l.2105).
- **La covarianza de Mahalanobis no se puede invertir** con el set activo completo, porque hay dependencias exactas: #1 = #2 + #3 (SAT l.21–23); #39 es el swing del otro pie (l.28); #5 = 60/#1 y #7 = #6/#1. Más zancadas no lo arregla: o la selección (#12) las saca, o hace falta *shrinkage*.
- **La selección es supervisada:** LASSO, SBS y Boruta (SAT l.178) necesitan etiquetas (ver H1) y una partición que no use las mismas anomalías con las que después se evalúa.
- **Zancadas de baja confianza:** las que tienen IC de baja confianza también quedan fuera de las ventanas (SPEC l.158; BIT l.2213). La confirmación IMU busca la firma de la marcha normal (SPEC l.27), así que una anomalía que la borre (por ejemplo, *drop foot*) se descarta sola. El modo "FSR-solo" (SPEC l.29) no tiene confianza definida.

**H6. Problemas de documentación y dependencias que no están dichas.** *Sólo doc.*
- **Numeración offline:** ADR-046 (BIT l.1583–1585) y SQL l.337 dicen que `stride_seq` "lo asigna la plantilla", pero en la mínima los eventos los detecta Python (BIT l.2164; SPEC l.417). Por implicación, numera Python, y el esquema lo admite. `strides` y `gait_events` no tienen una columna de origen, así que los eventos del micro y los offline no pueden convivir en una misma sesión. Eso sólo afecta al demostrador.
- **Modo de la sesión de calibración:** V3 l.70–72 y SQL l.65 la definen como captura operativa, con features del micro, que en la mínima no existen. ADR-057 ya admite features de Python para el análisis offline (BIT l.2018). Hay que alinear el texto para que el host no abra la calibración en modo `operational`.
- **Demostrador (opcional):** `provision()` usa el OTA (SPEC l.415), que es trabajo futuro (CRONO l.70). Además necesita una captura operativa propia (BIT l.2018). No está dicho cómo llegan μ y Σ a la cintura.

### 2. Set activo de la mínima
- No existe como lista explícita ni tiene un `feature_set_version` inicial: ADR-054 dice "Hoy hay uno: el perfil 2-FSR" sin dar el valor (BIT l.1915).
- Por exclusión (V3 l.17–21; SAT l.132; BIT l.1243): **ON:** #1–17, #19–21, #26–41, #43 y #44 (38 nominales, con #12–14 instanciadas por FSR × sub-fase). **OFF por hardware:** #18, #22–25 y #42. **OFF por alcance:** #45–47.
- BIT l.694 todavía pone el bloque I en ON; la nota de l.702 lo corrige.
- Ninguna feature activa necesita newtons, peso corporal ni un 3º o 4º FSR.

### 3. Descartados por menores o casos borde
- El ejemplo de BIT l.2162 usa sólo el talón (cosmético).
- Parámetros que se fijan con datos o en el piloto: W, t_ref, h_ms, la duración del "se mantiene por debajo", los porcentajes, el umbral de pausa, β, la ventana de #30, y `m` y `r`.
- SPEC-07 no lista #41.
- La cadencia es 60/stride_time; coincide con "cycles/min" de FEAT.
- El vocabulario literal de los flags y el escalado para IF, AE y OC-SVM son mecánica de codificación o hiperparámetros.
- El double support necesita el TO del otro pie del ciclo anterior (mecánica).

### 4. Verificado y en orden
- **Catálogo:** la numeración y los bloques coinciden entre V3, SAT, ADR-029/038/040 y las SPEC-02, 05, 07 y 10. FEAT reproduce #1–38 sin cambios y el total da 47.
- **SPEC-01 y ADR-062:** coherentes entre sí; no quedan umbrales derivados del peso ni de la curva fuerza–cuentas.
- **Reprocesamiento:** como el crudo y el cero/carga de cada sesión quedan guardados, todos los parámetros de eventos y emparejado se pueden ajustar offline. Lo único irreversible es β, y el piloto lo fija antes de M2.
- **Emparejado:** la regla de ADR-064 es la misma en SPEC-05, SPEC-09 y el esquema, y se puede implementar. `reference_foot` queda en la sesión, y un ciclo sin par no tiene fila bilateral.
- **Baseline y fase 4:** ~200 zancadas por pie, con sus exclusiones. CP-37 queda en la fase 4. Los modelos de la fase 4 coinciden con V3 §7.1.
- **Bloque I:** diferido sin bloquear nada, porque el crudo de la cintura se graba.

Fuentes externas sobre LDLJ: scikit-digital-health — DimensionlessJerk (https://scikit-digital-health.readthedocs.io/en/stable/ref/generated/skdh.features.DimensionlessJerk.html); Melendez-Calderón et al. 2021 (https://www.frontiersin.org/journals/bioengineering-and-biotechnology/articles/10.3389/fbioe.2020.558771/full) — no se pudo extraer la ecuación de la página.
