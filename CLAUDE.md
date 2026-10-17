# CLAUDE.md — Guía para agentes de IA

> Este archivo es el punto de entrada para **cualquier agente de IA** (o persona) que trabaje en este repositorio. Léelo completo antes de tocar nada. Su objetivo es dar **entendimiento total del proyecto** para que cualquiera pueda clonar el repo y ponerse a trabajar de inmediato.

> **Antes de editar cualquier archivo**, hacé el arranque de [Git y sincronización entre computadoras](#git-y-sincronización-entre-computadoras): la tesis se trabaja desde dos computadoras y editar sobre una copia vieja genera conflictos.

## Qué es este proyecto (en una línea)

Sistema de **plantillas inteligentes bilaterales** para **detección personalizada de anomalías de marcha en pacientes post-ACV**, con **feedback vibrotáctil en tiempo real** e **inferencia en el borde (edge)**. Tesis de maestría (ITBA).

**Estado actual:** arquitectura **cerrada** en 4 vistas consolidadas; **diseño detallado terminado**. Decisiones en **ADR-000 a 047**; specs de firmware **SPEC-01 a SPEC-11**. El backlog de investigación **#1–#10 está resuelto**; **#11** (footprint/latencia) y **#12** (selección de features) requieren firmware y dataset. El **esquema de la base está diseñado** (`src/db/schema.sql`: Postgres 17 con series particionadas, zancada como entidad, grants explícitos — ADR-044 a 047) y se crea como **migraciones** al implementar la base (ADR-045). **Firmware, worker y base todavía no existen.** Próximo paso: **roadmap de implementación por fases** e iniciar `src/`.

## Orden de lectura recomendado (onboarding)

1. `docs/Anteproyecto_Tesis.pdf` — el anteproyecto oficial (problema, objetivos mínima/máxima, metodología). Define la tesis.
2. `docs/objetivos.md` — objetivos consolidados y filosofía.
3. `docs/arquitectura/Arquitectura_Sistema_Marcha.md` — **índice + overview** del sistema. Da la foto completa en una lectura y enlaza las **4 vistas** en `docs/arquitectura/vistas/` (1 sistema · 2 firmware · 3 datos-ml · 4 backend), donde vive el detalle.
4. `docs/decisiones/bitacora_decisiones.md` — por qué cada decisión, con opciones y pros/cons (ADRs). **Tiene índice al inicio.**
5. `docs/investigacion/resumen_investigacion.md` + `features_anomaly_detection_stroke.md` + `docs/marco_teorico/marco_teorico_documento_de_trabajo.md` — la evidencia que fundamenta el diseño.
6. `memoria/memory.md` — estado vivo del proyecto y aprendizajes acumulados.
7. Los diagramas `.mermaid` en `docs/arquitectura/` y `esquema_alimentacion.md` (hardware y checklist del PCB).

**Regla de layering:** cada feature/algoritmo se **define una vez en la Vista 3** (datos/ML) y se **ejecuta en la Vista 2** (firmware) y en el worker. El detalle de cada faceta va en su vista, no en el maestro.

**Convención de specs:** cada ítem del backlog (ver `vistas/3_analisis_features_y_algoritmos.md` §D) que se resuelve produce **(a) un ADR** en la bitácora y **(b) una spec de algoritmo** (definición, señales, parámetros, salida, referencias — NO código) en `vistas/2_specs_algoritmos_firmware.md`. La spec fija las decisiones de dominio; la mecánica de codificación queda para quien implementa.

## Fuentes únicas — ante discrepancia, quién manda

Tres reglas de fuente única, todas producto de la auditoría de consistencia del 2026-08-18:

| Tema | Fuente única | Regla |
|---|---|---|
| **Detalle de cada dominio** | Las **4 vistas** | Si el maestro y una vista discrepan, **manda la vista** (ADR-039). El maestro es overview + puntero, no una segunda copia. |
| **Decisiones** | `bitacora_decisiones.md` **y su índice** | El maestro **ya no** mantiene un "Resumen de decisiones" (ADR-039). |
| **Esquema de la base** | La cadena de **migraciones** (`src/db/supabase/migrations/`) | Se cambia **sólo** con una migración nueva; `src/db/schema.sql` es el snapshot para leerlo, **generado**, no se edita a mano (ADR-045, revisa ADR-037). Mientras la base no exista, `schema.sql` es el diseño. El maestro §11 tiene sólo el mapa de entidades. |
| **Cuestiones abiertas** | `docs/cuestiones_pendientes.md` | Todo lo demás apunta ahí; nadie duplica el estado. |

## Resumen de la arquitectura (lo mínimo que un agente debe saber)

- **Hardware:** 2 plantillas (Raspberry Pi Pico 2 W + MPU-6050 + FSR + motor vibrador PWM) + 1 unidad de cintura (Pico 2 W + MPU-6050 a ~L4-L5). Muestreo **100 Hz**. **FSR: 2 hoy** (punta ADC0/GP26, talón ADC1/GP27); **máximo de diseño 4**, con medial y lateral en la próxima revisión del PCB — lo que **exige mux analógico**, porque GP29 mide VSYS y quedan sólo 3 ADC libres (**ADR-041**).
- **Topología:** plantillas ↔ cintura por **WiFi** (cintura = **Access Point**); cintura ↔ host por **BLE** (desde la mínima). La cintura es el **hub de fusión y decisión**. Los micros **nunca se conectan a WiFi de internet** (modelo tipo auriculares BLE).
- **Transporte:** canal rápido-tolerante (**UDP** / notificaciones GATT) para el stream + canal confiable (**TCP** / writes con ACK) para control y modelos. Paquete de muestra (39 B) con **4 slots fijos de FSR** (ADR-041) y el IMU **post-AHRS** — `lin_accel` sin gravedad + giro + **orientación** (pitch/roll/yaw) — más `t_device` en **uint64** (ADR-042; en uint32 daba la vuelta a los 71,6 min).
- **Sincronización:** backbone de reloj (**timestamp + secuencia por muestra + beacon periódico + corrección de drift**) en capa de aplicación. **Es el único mecanismo de sincronización:** el emparejado de zancadas por IC **usa** el reloj ya sincronizado, no lo sincroniza ni es un fallback.
- **Eventos de marcha: IC / TO / MS.** Mid-stance se detecta como el **cruce de carga retropié→antepié** (`F_ante ≥ F_post`), confirmado por pie-plano del IMU; si el paciente nunca transfiere carga se emite con flag `no_crossover`, **que es señal de anomalía, no error** (ADR-038 / SPEC-01).
- **Features: catálogo de 47** en bloques A–I, definición **única y compartida** plantilla↔cintura↔worker, versionada por `feature_set_version`. El **catálogo es una biblioteca de features disponibles, no una lista de obligaciones**; el **set activo** es lo que se calcula (ADR-040). Hoy están **OFF**: *por hardware*, el bloque E (#22-25, #42) y #18; *por alcance*, el bloque I de tronco (#45-47).
- **Cómputo distribuido:** cada plantilla calcula sus features **por-pie**; la cintura hace la **fusión bilateral** (simetría, double support) y las de tronco. **Qué es "crudo" (ADR-042):** señal de FSR + IMU a 100 Hz con el **AHRS ya aplicado en el micro** (aceleración lineal sin gravedad + orientación) y **ningún otro procesamiento**; el worker consume y **no re-procesa IMU**. La calibración es **irreversible por diseño**. **Captura por fases (ADR-005 rev c):** *exploratoria* = crudo-solo (features off-device); *operativa* = features del micro + crudo (entrena skew-free y valida paridad); *edge* = features/eventos/scores en vivo + crudo por snippet ante anomalía.
- **Muestreo determinístico (100 Hz):** ADC disparado por hardware + DMA con **sobremuestreo ~1 kHz y decimación ×10** (mejora el SNR del FSR); IMU leído en el **tick maestro por DMA**; timestamp + secuencia por muestra; core dedicado.
- **Persistencia:** **Supabase** (Postgres 17 + object storage + auth), con las series **particionadas por mes de inicio de sesión** (particionado nativo + `pg_partman`/`pg_cron` — ADR-044; TimescaleDB quedó descartado), **RLS estricto por paciente** vía `patient_access` y **grants explícitos**: nada se expone por la Data API por defecto (ADR-047). El esquema cambia sólo por **migraciones** que aplica CI (ADR-045). Supabase **no entrena**; el entrenamiento corre en un worker (laptop en mínima, nube en máxima).
- **Identidad de las series (ADR-046):** la **zancada es una entidad** (`strides`). La plantilla numera sus zancadas (`stride_seq`, por pie) y la cintura los ciclos bilaterales (`cycle_seq`), desde `arm()`; eventos, vectores y scores se identifican con esos números, con **FK reales** e **ingesta idempotente** (upsert).
- **Modelos (taxonomía L/E/H/W):** cada modelo declara su clase en el registry (`inference_target ∈ {hub, host, worker}`). **L** infiere y reentrena en la cintura, con el estado adaptado en **RAM** durante la sesión: sube a la base en el **check-in** y se re-flashea desde la base al abrir la siguiente — **la DB manda**, el flash es copia de trabajo (ADR-043 rev); **E** infiere en la cintura y reentrena en el worker; **H** infiere en el host; **W** es batch/offline. **La inferencia en tiempo real va en `hub` o `host`, nunca en el worker/nube** — cambiar `hub`→`host` es un switch de config, sin reescritura. Mahalanobis es además **sensor de drift**.
- **Feedback vibrotáctil:** **monitoreo y alerta, no corrección** (ADR-027). Score designado sobre una **ventana de zancadas** → anomalía sostenida → 3 bandas per-paciente → alerta escasa.
- **La sesión es una transacción orquestada por la interfaz (ADR-043 rev):** encendido → conexión → configuración → *provisioning* (baja el modelo de la DB y lo flashea, estampado con `patient_id`) → **gate térmico** (el warm-up del IMU corre en paralelo al setup; se destraba por **temperatura estable**, no por reloj) → calibración → **verificación** (sin ella no arranca) → sesión → **check-in**. La adaptación online se **prende y apaga por sesión** (`adaptation_enabled`). Diagrama: `docs/arquitectura/pipeline_sesion.mermaid`.
- **Firmware:** **C/C++ con el Pico SDK** (no Arduino IDE), **bare-metal**. Reparto uniforme: **core 0 = radio, core 1 = procesamiento** en los tres micros.
- **OTA:** pesos + firmware completo, esquema **A/B** con checksum y rollback. **Al sellar una plantilla se pierde el BOOTSEL → el OTA tiene que estar probado antes.**

## Estructura del repositorio

```
tesis/
├── CLAUDE.md                  # este archivo — onboarding de agentes
├── README.md                  # descripción humana + setup
├── docs/
│   ├── objetivos.md
│   ├── cuestiones_pendientes.md  # registro vivo de cuestiones abiertas (única fuente de verdad)
│   ├── Anteproyecto_Tesis.pdf    # anteproyecto oficial (define la tesis)
│   ├── arquitectura/          # maestro (índice+overview) + vistas/ + stack_tecnologico.md
│   │   ├── vistas/            # 1 sistema · 2 firmware (+ specs) · 3 datos-ml (+ análisis) · 4 backend
│   │   ├── esquema_alimentacion.md   # hardware, cableado y checklist del PCB
│   │   └── *.mermaid          # topología, ER, ciclo de modelos, adquisición, calibración, alimentación
│   ├── decisiones/            # bitácora de ADRs + índice — única lista de decisiones
│   ├── investigacion/         # bibliografía (22 papers), features, pinout, fundamentos
│   └── marco_teorico/         # marco teórico (documento de trabajo)
├── src/
│   ├── db/                    # supabase/ (migraciones + tests pgTAP) + schema.sql (snapshot) — ADR-045
│   ├── firmware/              # C/C++ Pico SDK: insole/ · waist/ · shared/
│   ├── host/                  # app de ingesta/puente + UI de control (bleak + FastAPI)
│   └── worker/                # reentrenamiento (Python)
└── memoria/
    ├── memory.md              # memoria viva del proyecto
    └── changelog.md           # registro cronológico de cambios
```

## Dónde trabaja cada agente

- **Firmware (C/C++ Pico SDK):** `src/firmware/`. `insole/` y `waist/` comparten código en `shared/` (definición de features, formato de paquetes, sync, protocolo OTA). La definición de features en `shared/` **debe coincidir** con la del worker (misma semántica, versionada).
- **App host / puente:** `src/host/`. Ingesta por BLE, buffer local, puente OTA, UI de control (FastAPI), escritura a Supabase, runtime espejo para modelos de clase H.
- **Worker de reentrenamiento (Python):** `src/worker/`. Entrena clases E/H/W, cuantiza a int8 (TF/Keras + PTQ), publica modelos al registry.
- **Base de datos:** `src/db/`. El esquema se modifica **sólo con una migración nueva** en `src/db/supabase/migrations/` (CLI de Supabase con `--workdir src/db`); una migración aplicada no se edita y la base remota no se toca a mano. `schema.sql` es un **snapshot generado**: no se edita a mano (ADR-045). *Mientras la base no exista, `schema.sql` es el diseño y es lo que se edita.*

## Convenciones e invariantes (no romper sin un ADR nuevo)

- **Idioma de la documentación:** español (Argentina).
- **Cintura = AP** y **hub de fusión/decisión**: invariante permanente (mínima→máxima).
- **Definición de features única y compartida**, versionada por `feature_set_version`. La paridad se **garantiza** con tests C↔Python en CI y entrenando con las features del micro (ADR-018, anti *train/serve skew*).
- **Sincronización a nivel de aplicación** (portable WiFi↔BLE): no la ates a un transporte. **El IC no sincroniza relojes.**
- **El registry declara la clase de cada modelo** (L/E/H/W): no hardcodees el ruteo. **Tiempo real nunca en el worker.**
- **Personalización primero:** baseline por paciente; evita modelos poblacionales salvo justificación.
- **Datos de salud:** cifrado en tránsito/reposo, **RLS por paciente** (`patient_access`), `external_code` anónimo; minimiza PII.

## Flujo de trabajo para agentes (definición de "hecho")

> **Regla de interacción (con Juan) — explicar y consultar ANTES de decidir.** Ante cualquier decisión de diseño/arquitectura, primero exponé el problema, las **opciones con pros/cons** y una recomendación, y **esperá la confirmación de Juan** antes de escribir ADRs/specs o editar docs con una decisión ya tomada. No avances a la escritura sin ese OK. (Registrado 2026-07-19, tras tomar ADR-019/SPEC-07 sin consultar.)
>
> **Y explicá de verdad.** Si Juan pregunta qué es algo, la respuesta va **desde cero y con contexto**, no una definición de una línea. Cuando la explicación tenga valor durable, dejala escrita: **apéndice conceptual "en llano" al final del ADR** (ver ADR-019, 020, 022, 027, 028, 038, 040), o un documento de fundamento en `docs/investigacion/` si necesita desarrollo matemático (ver `fundamento_dft_ihr.md`).

Al completar una tarea significativa:

1. **Cuestiones pendientes:** si detectás una cuestión abierta, duda de diseño o punto a ratificar, **agregala** a `docs/cuestiones_pendientes.md` (nuevo ID `CP-NN`). Cuando resuelvas una, **sacala de "Abiertas" y moverla a "Resueltas"** con la resolución, la fecha y el link al ADR. Ese archivo es la única fuente de verdad de lo pendiente.
2. **Si tomaste o cambiaste una decisión de arquitectura:** agregá/editá un ADR en `docs/decisiones/bitacora_decisiones.md` **y su fila en el índice del mismo archivo**. Con eso alcanza: el maestro **ya no mantiene una segunda lista de decisiones** (ADR-039). Actualizá el maestro sólo si cambió la *foto general* del sistema, no por cada ADR.
3. **Registrá el cambio** en `memoria/changelog.md` (fecha, qué cambió, por qué).
4. **Actualizá `memoria/memory.md`** si cambió el estado del proyecto o aprendiste algo que otro agente debería saber.
5. **Mantené la coherencia** entre el código y los diagramas/specs. Si el código diverge de la arquitectura, actualizá la arquitectura o registrá una cuestión.
6. **No inventes hechos del mundo real** (precios, APIs, versiones): verificá antes de afirmar. Si una fórmula o un método viene de un paper, **decí explícitamente qué falta verificar contra la fuente**.
7. **Cerrá con el paquete de commit** (sección *Git*, §3): el commit y el push los hace el autor, no vos.

> **Aviso operativo.** El mount de Windows ha devuelto **contenido desactualizado** en la primera lectura de archivos grandes (verificado el 2026-08-18 con `memory.md`, `changelog.md` y la Vista 4), y en 2026-07-16 **truncó escrituras**. Antes de trabajar sobre un archivo grande, verificá tamaño (`wc -c`) o hash; escribí y verificá por bash.

## Git y sincronización entre computadoras

La tesis se trabaja desde **dos computadoras** —la de Juan y la de Tobías—, cada una con sus agentes. La prioridad es que **`origin/master` tenga siempre la última versión**: un cambio sin pushear es un cambio que el otro autor no ve, y su agente va a trabajar sobre una copia vieja. Hay una sola rama, `master`; no se abren ramas.

**Quién hace qué.** Los commits y los push los hacen **los autores**, con la cuenta de git configurada en su computadora. El agente edita archivos, lee el estado del repo y deja el commit **listo para ejecutar**.

- **El agente puede** (sólo lectura): `git --no-optional-locks status -sb`, `git diff`, `git log`, `git show`, `git grep`, `git config user.name`. El `--no-optional-locks` evita que `status` escriba el índice.
- **El agente nunca:** hace `push`; corre comandos que escriben en `.git/` (`add`, `commit`, `pull`, `fetch`, `stash`, `checkout`, `switch`, `merge`, `rebase`, `reset`, `tag`); cambia `user.name`/`user.email`, credenciales o remotos; borra nada dentro de `.git/`.

**Por qué ni siquiera `commit`:** desde la VM que ve el repo a través del mount de Windows (ver *Aviso operativo* arriba), git puede crear archivos pero no borrarlos, así que cada `commit`, `pull` o `stash` deja un `.lock` huérfano en `.git/` y el próximo comando del autor falla con `File exists`. Pasó el 2026-08-18/19: quedaron `index.lock`, `HEAD.lock.*` y `master.lock.*` sueltos. *Única excepción:* si el autor **pide** el commit en esa sesión **y** el agente corre git nativo en la computadora (no a través de un mount), puede hacer `git add <archivos>` + `git commit` con la identidad ya configurada. El push sigue siendo del autor.

### 1. Arranque — antes de editar

1. Mirá el estado con `git --no-optional-locks status -sb`, y de quién es la computadora con `git config user.name`.
2. Si quedaron **cambios sin commitear o commits sin pushear** de una sesión anterior, se suben primero: armá el paquete de cierre (§3) para esos cambios antes de empezar lo nuevo.
3. Pedile al autor que traiga lo último con `git pull --rebase`, y **esperá a que lo confirme**. Leer podés antes; editar, no.
4. **Verificación:** `git --no-optional-locks status -sb` arranca con `## master...origin/master` **sin** `[ahead N]` ni `[behind N]`, y no lista archivos modificados. Si no da eso, no se empieza.

### 2. Durante — que los cambios de dos computadoras se puedan juntar

- **Tocá sólo las líneas que cambian.** Nada de reformatear, re-envolver párrafos, reordenar secciones ni cambiar finales de línea: un diff gigante choca con cualquier cambio del otro lado y esconde el cambio real.
- **IDs nuevos (`ADR-NNN`, `CP-NN`, `SPEC-NN`):** el siguiente libre del archivo **después del pull del arranque**. Si igual chocan con uno del otro autor, se arregla al integrar (§4).
- **Nada de archivos temporales en el repo** (pruebas de escritura, `.bak`, copias): trabajá en un directorio fuera del repo. Si se te escapó uno, borralo o avisá.
- **Archivos calientes** —los que tocan casi todas las sesiones—: `memoria/changelog.md`, `memoria/memory.md`, `docs/decisiones/bitacora_decisiones.md`, `docs/cuestiones_pendientes.md` y el *Estado actual* de `CLAUDE.md` y `README.md`. Ahí van a aparecer los conflictos.

### 3. Cierre — el paquete de commit

Al terminar la tarea (o antes de que el autor se vaya, aunque quede a medias), entregale:

1. **La lista de archivos que tocaste**, uno por uno. Nunca `git add -A` ni `git add .`: suben archivos ajenos o temporales.
2. **El mensaje**, con la convención del repo: `tipo(alcance): resumen` en español (`docs:`, `docs(arquitectura):`, `feat(firmware):`, `fix(worker):`…) y un cuerpo con el porqué.
3. **Los comandos, completos y listos para copiar.** Los `<…>` de abajo los reemplazás vos con lo de los puntos 1 y 2; al autor le llegan sin huecos:
   ```
   git add <archivo_1> <archivo_2> …
   git commit -m "<tipo(alcance): resumen>" -m "<cuerpo: qué cambió y por qué>"
   git pull --rebase
   git push
   ```
4. **Que pushee hoy.** Un commit sin push no le sirve al otro autor.
5. **Verificación**, después del push: `git --no-optional-locks status -sb` muestra `## master...origin/master` sin `[ahead N]`, y `git log -1 --format="%an — %s"` muestra el nombre del autor y el mensaje.

### 4. Si el `pull --rebase` da conflicto

El autor ve `CONFLICT (content): Merge conflict in <archivo>`. Vos resolvés **editando el archivo** (sacando los `<<<<<<<` / `=======` / `>>>>>>>`); el autor cierra con `git add <archivo>` y `git rebase --continue`. **Nunca se descarta un lado entero** (`--ours` / `--theirs`): cada lado es trabajo de un autor.

| Archivo | Cómo se resuelve |
|---|---|
| `memoria/changelog.md` | Quedan **las dos entradas**, la más reciente arriba. |
| Bitácora, cuestiones o specs con **el mismo número en los dos lados** | **Lo que ya está en `origin` conserva su número**; el cambio local pasa al siguiente libre y se actualizan **todas** sus referencias en el repo (buscalas con `git grep -n` y el ID duplicado). |
| `memoria/memory.md`, *Estado actual* de `CLAUDE.md`/`README.md` | Se combinan los dos hechos. Si se contradicen, **decide el autor**, no vos. |
| `src/db/supabase/migrations/` | Quedan **las dos** migraciones. Se aplican en el orden de sus nombres, así que si la local tiene un timestamp **anterior** a una que ya se aplicó en la base remota, se renombra con un timestamp nuevo antes de pushear. `schema.sql` no se resuelve a mano: se regenera (ADR-045). |
| Cualquier otro | Se combina a mano; ante la duda, preguntá. |

**Verificación:** `git grep -n -e "^<<<<<<< " -e "^>>>>>>> "` no devuelve nada y, si renumeraste, cada mención del número duplicado apunta al ADR/CP que ya estaba en `origin`. Después se sigue con el cierre (§3) desde `git push`.

### 5. Locks huérfanos en `.git/`

**Síntoma:** `fatal: Unable to create '…/.git/index.lock': File exists`, o `warning: ignoring broken ref refs/heads/master.lock…`. El agente no los borra (regla de arriba): le avisa al autor. Con **ningún programa usando git abierto** (VS Code, GitHub Desktop, otra terminal), desde la raíz del repo:

- Windows (PowerShell): `Get-ChildItem .git -Recurse -Force -Filter "*.lock*" | Remove-Item -Force`
- macOS / Linux: `find .git -name "*.lock*" -delete`

**Verificación:** `git status` ya no muestra `ignoring broken ref`, y el comando que fallaba pasa.

## Cuestiones pendientes

El registro vivo está en **`docs/cuestiones_pendientes.md`** — **única fuente de verdad, y este archivo no la duplica**. Al 2026-10-17 hay **14 abiertas** y **20 resueltas**. Copiar la lista acá fue justamente lo que la desactualizó antes: vale la misma regla que ADR-037 (esquema) y ADR-039 (decisiones) — *una sola fuente, varios consumidores*.

**La única que amerita alerta en el onboarding:** **CP-21** (port de `pico-tflmicro` a RP2350) es la **única cuestión abierta que puede voltear una decisión ya tomada** (ADR-020/SPEC-08): el port oficial no está mergeado para RP2350. Se descarta con una prueba de banco aislada, sin necesidad del firmware del proyecto, y conviene hacerla **antes** de escribir firmware que dependa de SPEC-08.

**Con fecha límite propia:** la base tiene que **existir como migraciones antes de la primera captura** (ADR-045), porque después los cambios de esquema dejan de ser gratis. Está diseñada (ADR-044 a 047; CP-23, CP-26 y CP-29 se resolvieron el 2026-10-17) pero todavía no creada.

## Glosario rápido

- **AP / STA:** Access Point (crea la red) / Station (se une como cliente).
- **IC / TO / MS:** Initial Contact / Toe-Off / Mid-Stance — los tres eventos de segmentación de la zancada.
- **Drift (reloj):** divergencia de relojes por diferencias de cristal; también "drift" de la marcha = cambio de patrón que dispara reentrenamiento.
- **L/E/H/W:** clases de modelo por dónde infieren/reentrenan (ver arriba).
- **OTA:** Over-The-Air (actualización inalámbrica de pesos/firmware).
- **Coexistencia:** WiFi y BLE compartiendo el mismo radio (CYW43439) por time-division.
- **Mínima / Máxima:** horizonte de entorno controlado (laptop) / uso diario (celular + nube).
- **Set activo:** subconjunto del catálogo de features que efectivamente se calcula, versionado por `feature_set_version`.
