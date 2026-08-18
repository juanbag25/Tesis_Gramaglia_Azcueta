# Informe de alineación — Features y algoritmos vs. marco teórico e investigación

> **Propósito.** Verificar que el catálogo de features (Vista 3, bloques A–I) y los algoritmos (Mahalanobis, Isolation Forest, AE denso int8, LSTM AE + taxonomía L/E/H/W) se alinean con lo que respaldan el **marco teórico**, el **documento de features**, el **anteproyecto** y los **22 papers** de la investigación.
> **Método.** Revisión por 5 subagentes (marco teórico · doc de features + anteproyecto · papers 01–07 · 08–14 · 15–22), cada uno auditando su fuente contra el catálogo. Fecha: 2026-07-21.
> **Estado.** Informe de hallazgos — **no** se editó ningún doc de arquitectura. Las acciones esperan decisión.

---

## 0. Veredicto

El **núcleo está sólidamente alineado y es trazable**: los bloques A (espacio-temporales), B (variabilidad), C (fuerza/FSR), D (simetría), F (IMU cinemáticos) y G (LDLJ), los **4 algoritmos** y la **filosofía** (personalización primero, economía de features 15–25, one-class, simetría inter-miembro) están respaldados por el marco y trazables a las fuentes. El marco ordena los algoritmos en el mismo pipeline de 4 etapas que el catálogo.

Aparece **una discrepancia estructural** (la cintura y el bloque I de tronco no existen en el marco ni en el anteproyecto — es el corazón de CP-11), un puñado de **features candidatas a agregar** con respaldo real, algunas **features débiles o mal priorizadas**, un **hueco de algoritmo** (el One-Class SVM que ancla la evidencia no está en el stack), varias **inconsistencias de conteo/nomenclatura**, y varias **advertencias de validez** relevantes para la fase de captura.

---

## 1. Lo que está sólidamente alineado

- **Features A–G.** El catálogo A–H reproduce **verbatim** las 38 features del `features_anomaly_detection_stroke.md` (misma numeración y semántica en los ítems 1–38). El marco las respalda por bloque y las prioriza:
  - **A/B** = "prioritarios, máxima evidencia"; **CoV de stance** entra en el top-3 de Brasiliano (k-medoids, **90,2 % con 3 features**).
  - **C** = "críticos para stroke" (push-off, carga plantar).
  - **D** = diferencial de ACV (simetría/lateralidad).
  - **F/G** = "recomendados"; **LDLJ sólo en swing** coincide en marco y catálogo; **ROM de roll** marcado "clave en stroke".
- **Algoritmos.** Los 4 del catálogo son exactamente el pipeline del marco (§6.3) y del anteproyecto §4.3: Mahalanobis (baseline + **sensor de drift** por EMA), Isolation Forest (offline→firmware), **AE denso int8** ("TFLite Micro + cuantización int8", literal), **LSTM AE** como E/H/W ("si no entra en el RP2350, referencia ejecutable en smartphone").
- **Filosofía.** Personalización primero con respaldo empírico fuerte y múltiple: **Toth** (one-class personalizado AUC 0,967; RF personalizado **97,7 % vs 55 %** global), **Matthews** (R=0,98 sólo con modelos individualizados), **pediátrico** (SPM grupal no significativo, perfil individual detecta a todos), **Kang** (adaptación online <1 min, **+65,9 % en ACV**). Economía de features 15–25 anclada en Chen (18 features→94,2 %) y en el "punto óptimo 15–25" del marco. Reentrenamiento por drift (Mahalanobis local; IF/AE en worker) respaldado por el marco §7.3.

---

## 2. Discrepancia estructural central: la cintura y el bloque I no están en el marco ni en el anteproyecto

Es el hallazgo más importante y atraviesa todo.

- **El marco teórico describe un sistema solo-plantilla** (dos dispositivos, uno por pie, peer-to-peer por BLE); las features bilaterales (double support, simetría) se obtienen por **sincronización entre plantillas**, no por un hub. El tronco aparece **explícitamente "fuera de alcance"** ("el proyecto no instrumenta la cabeza/tronco").
- **El anteproyecto también es foot-only:** "zapatilla inteligente bilateral", IMU **BMI270 dual, uno por pie, bajo el arco**; **ninguna mención de cintura**.
- **La arquitectura (Vista 3) agregó la cintura-hub + el bloque I de tronco** (I1 Improved Harmonic Ratio ML, I2 RMS de accel de tronco, I3 LDLJ de tronco).

**La paradoja — y por qué el bloque I es una buena decisión, no un invento:** el marco identifica el **IHR ML de lower-back como el feature top-1** del set de 3 que llega a 90 % (Brasiliano), y **lamenta no poder medirlo** con hardware solo-plantilla (hasta planeaba "aproximarlo desde el pie"). El IMU de cintura (~L4-L5) lo mide **directamente**. Es decir: el bloque I **recupera las features más discriminativas que el marco daba por perdidas** — es una mejor realización de la intención de la fuente. I2/I3 mapean a las features de esternón/lower-back de Brasiliano.

**Conclusión:** el bloque I y la cintura están **bien fundados por la evidencia**, pero el **marco y el anteproyecto no están actualizados** a esa decisión (que ya se tomó en CP-02/ADR-005). Esto es exactamente **CP-11** (reconciliación) y su límite: el marco declara una "limitación de sensores frente a Brasiliano" que la cintura **ya resolvió** y que debería reescribirse como resuelta.

---

## 3. Features candidatas a AGREGAR (con respaldo en las fuentes)

| Candidata | Bloque | Fuente | Respaldo |
|---|---|---|---|
| **Single support time** | A | marco §5.7 (ítem 5) | El marco lo lista como espacio-temporal propio; el catálogo sólo tiene double support. |
| **Symmetry Angle (SA)** | D | marco (Brasiliano) | Distinto del Symmetry Index; el marco lo distingue por propiedades estadísticas (acotado, simétrico). |
| **Mean peak sway density de COP_ML** | E | marco (Herbers) | **Top feature de Herbers**; el bloque E tiene velocity/range/zero-cross pero no sway density. |
| **Contact area (área de contacto)** | C | papers 10 y 20 (ACV) | Aparece en dos estudios plantares de ACV; el bloque C no la incluye. |
| **Foot progression angle** | F | paper 11 (validado en insole IMU) | Toe-in/out en plano transverso, validado ICC en plantilla; no explícito en F. |
| **Mid-stance (MS) como evento** | (segmentación) | paper 06 | Tercer evento además de HS/TO; útil para segmentar presión/COP. |
| **Average zero-crossings de la aceleración** | H | marco §5.7 (ítem 41) | Distinto de los zero-crossings de COP; el marco lo separa. |
| **Stride/step width** | A/D | paper 11 | Validado en plantilla; relevante a balance/simetría. |

*Nota:* "single support", "symmetry angle", "sway density" y "avg zero-crossings accel" son features que el propio **marco** enumera y que **no pasaron al catálogo** — son las que explican por qué la numeración 1-41 del marco no coincide con la del catálogo (§6).

**Salida clínica candidata (no es feature, es output):** el **modelo logístico de fall-risk** de Post-stroke Falls (paper 17), con Weight-Bearing Asymmetry + Postural Sway Velocity, encaja con el anclaje "riesgo = asimetría/sway" de ADR-027. Caveat en §8.

---

## 4. Features del catálogo débiles o mal priorizadas

- **COP_ML posicional puro (#22):** el menos respaldado del bloque E. Herbers halló que **"ninguno de los top es posicional"**; el marco reconstruye el COP alrededor de features **dinámicas** (velocity, zero-crossings) y reemplaza la posición media por **sway density**. Revisar si conviene degradar #22 o reemplazarlo por sway density.
- **Bloque H (frecuencia/entropía):** no desaconsejado, pero el marco lo degrada a **"opcional, Fase 4, sólo si las anteriores no alcanzan"** por costo de FFT/entropías en el RP2350. El catálogo lo lista como bloque más, sin esa señal de prioridad. (Coherente con SPEC-07/ADR-019, que ya lo tratan como bloque de bajo duty; vale reflejar la prioridad en el catálogo.)
- **Bloque F/E:** respaldados, pero evidencia mayormente de **running en sanos** (Eskofier, Falbriard), no stroke-específica → prioridad de segundo/tercer nivel, como ya indica la columna "Fase".

---

## 5. Algoritmos: alineación y el hueco del One-Class SVM

- **Los 4 algoritmos del catálogo están alineados** con el anteproyecto §4.3 y el marco §6.3. **LSTM AE** tiene el precedente más directo (paper 12 GAD: LSTM + adaptación online + retrain por drift + one-class per-user con ventaneo por zancada).
- **Hueco notable — One-Class SVM:** el algoritmo que **ancla toda la evidencia empírica** de la tesis es el **OC-SVM personalizado de Toth (AUC 0,967)**, descrito en el doc de features como *"exactamente tu pipeline propuesto"*. Pero el **OC-SVM no está en el stack elegido**: se sustituyó por Mahalanobis como detector one-class liviano (defendible: <100 µs en edge, se auto-adapta). **La sustitución es razonable pero no está explicitada en ningún doc.** Opciones: (a) documentar el porqué de OC-SVM→Mahalanobis, y/o (b) sumar OC-SVM como candidato clase E/W (el registry es model-agnostic).
- **Alternativas más pesadas (contexto, no acción):** EdgeSense (paper 16) usa **VAE** y CNN+Transformer on-device (<20 ms) — más pesado que la clase Pico; respalda la rama AE, no las opciones ligeras. GAD usa LSTM sobre señal cruda + reducción de dimensionalidad (enfoque end-to-end vs. features hand-crafted; el tier LSTM/W lo acomoda).
- **Respaldo desigual en papers:** LSTM sí (12); **Mahalanobis (L), Isolation Forest (E) y AE denso int8 no tienen respaldo directo en los papers** (el marco los desarrolla; el paper 04 da el análogo Z-score/SD del Mahalanobis). No es un problema — es que su justificación vive en el marco, no en el set de papers.

---

## 6. Inconsistencias de conteo y nomenclatura (coherencia)

- **"41 features / 8 bloques (A–H)" no cuadra.** La fuente (`features_anomaly_detection_stroke.md`) tiene **38 features en 8 bloques (A–H)**. El catálogo tiene **41 en 9 bloques (A–I)** = 38 + 3 del bloque I. Las formas auto-consistentes son **38/8 (A–H)** (fuente) **o 41/9 (A–I)** (catálogo). El par "41 / 8 bloques" (que aparece en `resumen_investigacion.md`, en `memory.md` y en el maestro §8.4) es **incorrecto** — arrastra el bloque I en el número pero no en la etiqueta de bloques.
- **Numeración 1-41 no intercambiable** entre marco y catálogo: al no llevar single support / symmetry angle / sway density al catálogo y sí el bloque I, los índices quedan corridos (p. ej. "peak force" es #13 en el marco y #12 en el catálogo).
- **Umbral de Mahalanobis:** catálogo dice **"chi-cuadrado"**; el marco fija **"percentil 99 empírico de D² en calibración"**. Reconciliables (χ² es la nula de D² bajo gaussianidad), pero conviene unificar la redacción.
- **Taxonomía:** `resumen_investigacion.md` dice **"L/E/W"** (3 clases); el catálogo usa **"L/E/H/W"** (4, agrega H=host). El resumen precede a la clase H (ADR-013) → actualizar.

---

## 7. Reconciliación con el anteproyecto (CP-11) — confirmada

1. **IMU:** anteproyecto **BMI270** (dual, uno por pie, bajo el arco) vs arquitectura **MPU-6050 + IMU de cintura** (no presupuestado en el anteproyecto). Misma clase funcional (6-DOF MEMS); impacto en energía (CP-09).
2. **Topología:** anteproyecto **"plantilla autocontenida" foot-only** vs **insoles + cintura-hub**. Decidido en CP-02/ADR-005, pero el anteproyecto (y el marco) no lo reflejan. Habilita el bloque I (§2).
3. **Algoritmos:** el anteproyecto es **internamente incoherente** — §4.3 lista Mahalanobis/IF/AE/LSTM (coincide con el catálogo), pero **§6 menciona "Autoencoders, SST-AD, SVR, Random Forest"** (no coincide). **SST-AD no está definido en ninguna fuente del corpus**; SVR/Random Forest aparecen sólo como referencias bibliográficas, no como detectores elegidos. La clase de Isolation Forest ya se reconcilió a **E** (ADR-011 rev).
4. **Extra — feedback:** el anteproyecto tiene una tensión interna edge (§4.3) vs "alerta accionada desde el backend" (§5.3), ya resuelta on-device por CP-10/ADR-027.

---

## 8. Advertencias de validez (para la fase de captura y validación, no son desalineación del catálogo)

Estas no cambian el catálogo, pero conviene registrarlas porque condicionan la validación empírica:

- **Validez de plantillas a baja velocidad (paper 11):** **loading-time no validado a velocidad lenta** (ICC<0,70) y toe clearance no fiable. Como el ACV camina lento, las features de carga del **bloque C** (loading rate, time-to-peak) podrían degradarse **justo en la población objetivo**.
- **Validación de plantillas (paper 21) sólo cubre temporales y en sanos:** fuerza/presión (C) y simetría (D) **no** validadas contra gold-standard, ni en marcha patológica.
- **Stride time no es asimétrico en ACV (paper 20):** usar stride time como feature de **simetría** sería mal discriminador; la asimetría vive en stance/swing/support y en fuerza/presión/contacto (M/L y AP).
- **Papers de IMU (03, 06, 07) validados en running de sanos:** la detección de eventos **HS/TO** y la corrección de drift deben **re-tunearse y re-validarse en marcha hemipléjica** (foot-flat, sin heel-strike, arrastre).
- **ZUPT vs MSDI (07):** MSDI supera a ZUPT en running; ZUPT es correcto para marcha, pero en gait muy lento/arrastrado la premisa de velocidad-cero se debilita → conviene monitorear la calidad del ZUPT y prever **MSDI como fallback** (coincide con lo que ya anota SPEC-03).
- **Posición del IMU (paper 03):** óptimo empírico **bajo el arco/mediopié** — verificar el emplazamiento en la plantilla.
- **Feedback (papers 09, 10):** los precedentes más cercanos son **correctivos**, no monitoreo+alerta; transfieren hardware/features (C y D: ratio M/L, lado sano como referencia), no el objetivo. **No hay precedente para el esquema de 3 bandas** (Ma usa un único umbral). El vibrotáctil sube la carga cognitiva (paper 09) → **justifica el feedback escaso**, pero exige validarlo en dual-task.
- **Muestreo:** el precedente clínico de Ma (paper 10) usa **10 Hz** (suficiente para fuerza, insuficiente para IMU) — no tomarlo como referencia (la tesis ya va a 100 Hz).

---

## 9. Recomendaciones priorizadas

1. **Reconciliar CP-11 (alta):** actualizar marco + anteproyecto (o registrar como addendum) a la arquitectura real: cintura-hub, MPU-6050 + IMU de cintura, bloque I, y unificar la lista de algoritmos (§4.3, descartar §6/SST-AD-SVR-RF o justificarlos). Reescribir la "limitación de sensores" del marco como resuelta por el bloque I.
2. **Corregir el conteo/nomenclatura (baja, mecánica):** "41 / 9 bloques (A–I)" en `resumen_investigacion.md`, `memory.md` y maestro §8.4; taxonomía L/E/H/W en el resumen; unificar la redacción del umbral (χ² / percentil 99).
3. **Evaluar features candidatas (media):** decidir cuáles de la tabla §3 se suman al catálogo (mínimo: single support, symmetry angle, sway density, contact area; foot progression angle si el IMU lo permite). Cada una versionada por `feature_set_version`; encaja con la modularidad (ADR-021).
4. **Revisar features débiles (media):** COP_ML posicional (#22) → posible reemplazo/degradado a sway density; reflejar la prioridad "Fase 4 / opcional" del bloque H en el catálogo.
5. **Algoritmos (media):** documentar la sustitución OC-SVM→Mahalanobis (y/o sumar OC-SVM como candidato E/W); registrar VAE como alternativa de la rama AE.
6. **Anexar las advertencias de validez (§8) al plan de captura/validación** (fase de dataset), para no descubrirlas con los datos ya tomados.

---

## Fuentes
- `docs/marco_teorico/marco_teorico_documento_de_trabajo.md`
- `docs/investigacion/features_anomaly_detection_stroke.md` · `resumen_investigacion.md` · `00_INDICE.md`
- `docs/Anteproyecto_Tesis.pdf` (§4.2, §4.3, §5.3, §6, §8)
- `docs/investigacion/papers/01–21` (paper 22 IEEE — no accesible). Referencias clave: 03 (posición IMU), 04 (personalización pediátrica), 06 (eventos/ZUPT), 07 (orientación drift-free), 08 (Matthews personalización), 10 (Ma, FSR+vibrotáctil ACV), 11 (Riglet, validación insole IMU), 12 (GAD, LSTM realtime), 16 (EdgeSense, VAE edge), 17 (fall-risk WBA/PSV), 20 (plantar ACV), 21 (validación vs GaitRite).
