# CLAUDE.md — Guía para agentes de IA

> Este archivo es el punto de entrada para **cualquier agente de IA** (o persona) que trabaje en este repositorio. Léelo completo antes de tocar nada. Su objetivo es dar **entendimiento total del proyecto** para que cualquiera pueda clonar el repo y ponerse a trabajar de inmediato.

## Qué es este proyecto (en una línea)

Sistema de **plantillas inteligentes bilaterales** para **detección personalizada de anomalías de marcha en pacientes post-ACV**, con **feedback vibrotáctil en tiempo real** e **inferencia en el borde (edge)**. Tesis de maestría (ITBA).

**Estado actual:** arquitectura **cerrada** en 4 vistas consolidadas; **diseño detallado terminado**. Decisiones en **ADR-000 a 041**; specs de firmware **SPEC-01 a SPEC-10**. El backlog de investigación **#1–#10 está resuelto**; **#11** (footprint/latencia) y **#12** (selección de features) requieren firmware y dataset. El **esquema de la base está escrito** (`src/db/schema.sql`). **Firmware y worker todavía no existen.** Próximo paso: **roadmap de implementación por fases** e iniciar `src/`.

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
| **Esquema de la base** | `src/db/schema.sql` | El maestro §11 tiene sólo el mapa de entidades (ADR-037). |
| **Cuestiones abiertas** | `docs/cuestiones_pendientes.md` | Todo lo demás apunta ahí; nadie duplica el estado. |

## Resumen de la arquitectura (lo mínimo que un agente debe saber)

- **Hardware:** 2 plantillas (Raspberry Pi Pico 2 W + MPU-6050 + FSR + motor vibrador PWM) + 1 unidad de cintura (Pico 2 W + MPU-6050 a ~L4-L5). Muestreo **100 Hz**. **FSR: 2 hoy** (punta ADC0/GP26, talón ADC1/GP27); **máximo de diseño 4**, con medial y lateral en la próxima revisión del PCB — lo que **exige mux analógico**, porque GP29 mide VSYS y quedan sólo 3 ADC libres (**ADR-041**).
- **Topología:** plantillas ↔ cintura por **WiFi** (cintura = **Access Point**); cintura ↔ host por **BLE** (desde la mínima). La cintura es el **hub de fusión y decisión**. Los micros **nunca se conectan a WiFi de internet** (modelo tipo auriculares BLE).
- **Transporte:** canal rápido-tolerante (**UDP** / notificaciones GATT) para el stream + canal confiable (**TCP** / writes con ACK) para control y modelos. Paquete de muestra con **4 slots fijos de FSR** (ADR-041).
- **Sincronización:** backbone de reloj (**timestamp + secuencia por muestra + beacon periódico + corrección de drift**) en capa de aplicación. **Es el único mecanismo de sincronización:** el emparejado de zancadas por IC **usa** el reloj ya sincronizado, no lo sincroniza ni es un fallback.
- **Eventos de marcha: IC / TO / MS.** Mid-stance se detecta como el **cruce de carga retropié→antepié** (`F_ante ≥ F_post`), confirmado por pie-plano del IMU; si el paciente nunca transfiere carga se emite con flag `no_crossover`, **que es señal de anomalía, no error** (ADR-038 / SPEC-01).
- **Features: catálogo de 47** en bloques A–I, definición **única y compartida** plantilla↔cintura↔worker, versionada por `feature_set_version`. El **catálogo es una biblioteca de features disponibles, no una lista de obligaciones**; el **set activo** es lo que se calcula (ADR-040). Hoy están **OFF**: *por hardware*, el bloque E (#22-25, #42) y #18; *por alcance*, el bloque I de tronco (#45-47).
- **Cómputo distribuido:** cada plantilla calcula sus features **por-pie**; la cintura hace la **fusión bilateral** (simetría, double support) y las de tronco. **Captura por fases (ADR-005 rev c):** *exploratoria* = crudo-solo (features off-device); *operativa* = features del micro + crudo (entrena skew-free y valida paridad); *edge* = features/eventos/scores en vivo + crudo por snippet ante anomalía.
- **Muestreo determinístico (100 Hz):** ADC disparado por hardware + DMA con **sobremuestreo ~1 kHz y decimación ×10** (mejora el SNR del FSR); IMU leído en el **tick maestro por DMA**; timestamp + secuencia por muestra; core dedicado.
- **Persistencia:** **Supabase** (PostgreSQL + TimescaleDB + object storage + auth), con **RLS estricto por paciente** vía `patient_access`. Supabase **no entrena**; el entrenamiento corre en un worker (laptop en mínima, nube en máxima).
- **Modelos (taxonomía L/E/H/W):** cada modelo declara su clase en el registry (`inference_target ∈ {hub, host, worker}`). **L** infiere y reentrena en la cintura; **E** infiere en la cintura y reentrena en el worker; **H** infiere en el host; **W** es batch/offline. **La inferencia en tiempo real va en `hub` o `host`, nunca en el worker/nube** — cambiar `hub`→`host` es un switch de config, sin reescritura. Mahalanobis es además **sensor de drift**.
- **Feedback vibrotáctil:** **monitoreo y alerta, no corrección** (ADR-027). Score designado sobre una **ventana de zancadas** → anomalía sostenida → 3 bandas per-paciente → alerta escasa.
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
│   ├── db/schema.sql          # ESQUEMA — fuente única (ADR-037)
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
- **Base de datos:** `src/db/schema.sql` — **acá y sólo acá** se modifica el esquema.

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

> **Aviso operativo.** El mount de Windows ha devuelto **contenido desactualizado** en la primera lectura de archivos grandes (verificado el 2026-08-18 con `memory.md`, `changelog.md` y la Vista 4), y en 2026-07-16 **truncó escrituras**. Antes de trabajar sobre un archivo grande, verificá tamaño (`wc -c`) o hash; escribí y verificá por bash.

## Cuestiones pendientes

El registro vivo está en **`docs/cuestiones_pendientes.md`** (única fuente de verdad). **Abiertas al 2026-08-19 (8):**

| CP | Tema | Depende de |
|---|---|---|
| CP-01 | FSR y traza INT contra el PCB | la revisión de la placa |
| CP-06 | Proveedor concreto del worker en la nube | llegar a la máxima |
| CP-09 | Presupuesto de energía / batería | medición en banco |
| CP-18 | Ratificación de seguridad/ética | comité de ética de ITBA |
| CP-20 | Columnas generadas sobre `features` | congelar el feature set + dashboard |
| CP-21 | Port de `pico-tflmicro` a RP2350 | **prueba de banco — validar temprano** |
| CP-22 | Dónde se computan las salidas clínicas | tener dataset |
| CP-23 | Herramienta de migraciones de la base | **antes de la primera captura** |

**CP-21 es la única que puede voltear una decisión ya tomada** (ADR-020/SPEC-08): el port oficial no está mergeado para RP2350. Se descarta con una prueba de banco aislada, sin necesidad del firmware del proyecto.

## Glosario rápido

- **AP / STA:** Access Point (crea la red) / Station (se une como cliente).
- **IC / TO / MS:** Initial Contact / Toe-Off / Mid-Stance — los tres eventos de segmentación de la zancada.
- **Drift (reloj):** divergencia de relojes por diferencias de cristal; también "drift" de la marcha = cambio de patrón que dispara reentrenamiento.
- **L/E/H/W:** clases de modelo por dónde infieren/reentrenan (ver arriba).
- **OTA:** Over-The-Air (actualización inalámbrica de pesos/firmware).
- **Coexistencia:** WiFi y BLE compartiendo el mismo radio (CYW43439) por time-division.
- **Mínima / Máxima:** horizonte de entorno controlado (laptop) / uso diario (celular + nube).
- **Set activo:** subconjunto del catálogo de features que efectivamente se calcula, versionado por `feature_set_version`.
