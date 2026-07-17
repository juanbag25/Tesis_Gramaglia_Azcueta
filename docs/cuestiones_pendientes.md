# Cuestiones pendientes

> **Registro vivo** de cuestiones abiertas, dudas de diseño y puntos a ratificar del proyecto. Es la **única fuente de verdad** de lo que falta resolver; el resto de los documentos apuntan acá.
>
> **Cómo usarlo (agentes y humanos):**
> - Cuando surja una cuestión abierta, agregala a la tabla **Abiertas** con un ID nuevo (`CP-NN`), por qué importa, estado y referencia.
> - Cuando se resuelva, **sacala de Abiertas** y moverla a **Resueltas** con la resolución, la fecha y el link al ADR/decisión que la cerró.
> - Registrá el cambio en `memoria/changelog.md`. Si la resolución es una decisión de arquitectura, agregá/actualizá el ADR en `docs/decisiones/bitacora_decisiones.md`.
>
> Estados: `abierta` · `en análisis` · `bloqueada` · (al resolver, pasa a la sección Resueltas).

## Abiertas

| ID | Cuestión | Por qué importa | Estado | Referencia |
|---|---|---|---|---|
| CP-01 | **Tercer FSR en ADC2/GP28.** Confirmar la asignación del 3er FSR contra el PCB real. | Define el pinout y el firmware de muestreo de las plantillas. | abierta | `docs/investigacion/pinout_pico2.md`; Arq. §3 |
| CP-07 | **Estrategia de lectura del IMU.** Tick maestro de 100 Hz (default) vs. FIFO / DATA_READY del MPU-6050. | Espaciado uniforme por el reloj del IMU vs. simplicidad y un solo timestamp por tupla; DATA_READY sumaría un cable INT→GPIO en el PCB. | abierta | ADR-014; Arq. §8.6 |
| CP-04 | **Nivel de rigor de seguridad.** Qué exige el comité/ética de la tesis para datos de salud (cifrado, consentimiento, anonimización, auditoría). | Define la profundidad de la capa de seguridad y de la gobernanza de datos. | abierta | ADR-006; Arq. §13 |
| CP-05 | **Esquema de `feature_vectors`.** `jsonb` flexible vs. columnas fijas. | Trade-off rendimiento (columnas) vs. flexibilidad ante un feature set que aún cambia (`jsonb`). | abierta | ADR-007; `src/db/schema.sql` |
| CP-06 | **Proveedor concreto del worker en la nube.** VPS Hostinger / contenedor gestionado (Render/Railway/Fly) / instancia con GPU. | Define costo, ops y capacidad de cómputo del reentrenamiento en la máxima. | abierta (se decide al llegar a la máxima) | ADR-009; Arq. §12 |
| CP-08 | **Modularidad de FSR y límite de ADC.** Soportar N FSR configurable. En el Pico 2 W hay 3 ADC libres (GP29/ADC3 mide VSYS/batería); >3 FSR requiere mux analógico o ADC externo. | Escalabilidad del sensado plantar; en tensión con la medición de batería por ADC. | abierta | Arq. §3; Vista 2 |
| CP-09 | **Presupuesto de energía / batería.** Objetivo blando ≥8 h continuas; duty-cycling del radio; forma de medir batería. | Autonomía del wearable para uso diario (máxima). No es un gate duro. | abierta | Vista 2 |
| CP-10 | **Diseño de patrones de feedback.** ≥3 patrones (leve/marcada/riesgo) calibrables por paciente; lógica severidad→patrón; config en DB; feedback escaso. | UX clínica del biofeedback; evita carga cognitiva; requiere config por paciente. | abierta | Vista 2/4 |
| CP-11 | **Reconciliación anteproyecto/marco teórico.** El anteproyecto dice IMU **BMI270** y "plantilla autocontenida" (sin cintura); el marco no incluye la cintura. Alinear a MPU-6050 + cintura-hub y unificar la lista de algoritmos (§4.3 vs §6). | Coherencia entre los documentos oficiales y la arquitectura real. | abierta | `docs/Anteproyecto_Tesis.pdf`; marco teórico |
| CP-12 | **Modularidad de features.** Features disponibles siempre pero **activables/desactivables**; se eligen según el análisis de datos/algoritmos; versionado por `feature_set_version`. | Permite prender/apagar features sin reescribir firmware/worker; mantiene paridad. | abierta | Vista 3; ADR-005/011 |

## Resueltas

| ID | Cuestión | Resolución | Fecha | Referencia |
|---|---|---|---|---|
| CP-02 | Cintura como hub de cómputo vs. features en cada plantilla | **Distribuido:** cada plantilla calcula sus features por-pie + eventos; la cintura fusiona (simetría, double support), infiere y decide el feedback. Reparte cómputo y descarga la cintura. | 2026-07-16 | ADR-005; Arq. §8.1 |
| CP-03 | Dónde detectar el contacto inicial (IC) | **En la plantilla (per-pie):** fusión FSR-primario + confirmación IMU; el evento se envía a la cintura para fusión/sync/feedback. | 2026-07-16 | ADR-015; SPEC-01 (`vistas/2_specs_algoritmos_firmware.md`) |

> Formato: `| CP-NN | Cuestión | Resolución | AAAA-MM-DD | ADR-NNN / changelog |`
