# Features para detección de anomalías de marcha post-stroke con FSR + IMU

Síntesis de la literatura más relevante (2022-2026) sobre qué features han mostrado mejor rendimiento en la clasificación de marcha patológica vs marcha sana, con sensores compatibles con plantilla inteligente (FSR + IMU embebido en el pie).

---

## Estudio de referencia 1: Brasiliano et al. (2026), Scientific Reports

**Identificando features clave en pacientes con stroke con MIMUs y machine learning**
- N=85 pacientes stroke + N=97 controles sanos
- 5 MIMUs (frente, esternón, lower back, ambas tibias) a 128 Hz
- Sequential Backward Selection sobre 79 features iniciales
- Mejor performance: **SVM con 96.7% accuracy** (con los 9 features seleccionados)
- En clustering no supervisado (k-medoids con cosine distance): **90% accuracy con solo 3 features**

### Los 9 features que mejor discriminaron stroke vs sano

| # | Feature | Dominio | Sensor | Aplicable a plantilla? |
|---|---------|---------|--------|------------------------|
| 1 | **Improved Harmonic Ratio (IHR) ML** medido en lower back | Simetría | Lower back IMU | Parcial (con bilateral) |
| 2 | **CoV (Coefficient of Variation) de stance phase duration** | Variabilidad | Tibias IMU | ✅ Sí, totalmente |
| 3 | **Stride speed** | Espacio-temporal | Tibias IMU | ✅ Sí |
| 4 | **Swing phase duration** | Espacio-temporal | Tibias IMU | ✅ Sí |
| 5 | **Head LDLJ (Log Dimensionless Jerk) en ML** | Smoothness | Cabeza IMU | ❌ No (no hay sensor en cabeza) |
| 6 | **Head LDLJ en AP** | Smoothness | Cabeza IMU | ❌ No |
| 7 | **Coefficient of Attenuation (COA) lower back → head ML** | Estabilidad | LB + Head IMU | ❌ No |
| 8 | **Sternum LDLJ en AP** | Smoothness | Esternón IMU | ❌ No |
| 9 | **Head RMS de aceleración en AP** | Estabilidad | Cabeza IMU | ❌ No |

### Top 3 mínimo viable (90% accuracy en unsupervised clustering)
1. **Stride speed**
2. **CoV de stance phase duration**
3. **Improved Harmonic Ratio ML** (en lower back, en nuestro caso habría que aproximarlo desde el pie)

**Conclusión accionable:** Stride speed + CoV stance + algún índice de simetría son la columna vertebral mínima de cualquier sistema de detección de stroke.

---

## Estudio de referencia 2: Herbers et al. (2024), npj Parkinson's Disease

**Detección de PD fallers con monitoreo plantar inalámbrico**
- N=111 (44 PD + 67 controles), insoles con array de presión
- 6 tareas: 3 estáticas (quiet stance ojos abiertos, cerrados, un pie) + 3 activas (marcha, alcance funcional, agacharse)
- AUC 0.91 ± 0.08 para clasificar PD fallers vs PD non-fallers
- Modelo ganador: KNN

### Tres dominios de features del COP (Center of Pressure)
1. **Posicionales**: media, rango, desviación, ubicación lateral
2. **Dinámicos**: velocidad, aceleración, **zero crossings**, mean peak sway density
3. **Frecuencia**: PSD por bandas (<0.5 Hz, 0.5–2 Hz, >2 Hz), frecuencia media, energía total

Cada feature se calcula además en dos modos:
- **Promedio** (entre ambos pies)
- **Asimetría** (diferencia entre pies)

### Features clave para PD fallers vs PD non-fallers (9 features)
- 5 dinámicos + 4 frecuencia (NINGUNO posicional)
- 4 promedio + 5 asimétricos
- **Específicamente mencionados:**
  - Average zero crossing COP velocity ML y AP (más alto en fallers)
  - Energy content <0.5 Hz PSD ML
  - Total power ML
  - rms del radio de COP en quiet stance EO
  - Mean peak sway density en functional reach
  - Mean frequency ML en one foot stance
  - Asymmetric energy content 0.5–2 Hz ML en quiet stance EO
  - Asymmetric mean value ML en bending over

**Conclusión accionable para vos:** las features de frecuencia y dinámicas del COP discriminan mejor a los pacientes de riesgo de caída que las posicionales. Con 3-4 FSRs no se puede reconstruir el COP 2D completo, pero sí una aproximación 1D del componente medio-lateral (medial vs lateral), que es justamente la dirección más informativa según este paper.

---

## Estudio de referencia 3: Chen et al. (2022), Frontiers in Neuroinformatics

**Evaluación interpretable del estadío de recuperación de Brunnstrom (lower limb)**
- N=20 hemipléjicos + N=10 sanos
- 7 IMUs + 2 plantillas con presión plantar
- 18 features seleccionados por feature importance → **94.2% accuracy con KNN**
- Combinación específica: parámetros kinemáticos + presión plantar + espaciales

**Conclusión accionable:** confirma el umbral empírico — alrededor de 18 features bien elegidos son suficientes para llegar al techo de performance. Más features que eso suele agregar ruido.

---

## Estudio de referencia 4: Toth et al. (2024-2025), Sensors — Bioinformatics-Inspired IMU Stride Modeling

**Detección de fatiga con One-Class SVM personalizado**
- N=19 corredores con IMU lumbar
- Features: **spectral-entropy, sample entropy, frequency-domain descriptors**
- Hybrid AI con 1D-CNN

**Resultados clave (muy relevantes para tu enfoque):**
| Enfoque | Performance |
|---------|-------------|
| Modelo global LOPO (leave-one-participant-out) | Accuracy **55%** |
| Modelo supervisado personalizado por sujeto (Random Forest) | Accuracy **97.7%**, AUC 0.997 |
| **One-Class SVM con baseline solo non-fatigued (personalizado)** | **AUC 0.967** |

**Conclusión accionable críticamente importante para tu tesis:** este paper confirma empíricamente lo que ya habías intuido — los modelos globales fallan catastróficamente (55%) y los personalizados explotan en accuracy (97%+). El One-Class SVM personalizado con baseline normal es exactamente tu pipeline propuesto y funciona con AUC ~0.97 en problemas de marcha.

---

## Estudio de referencia 5: Nanayakkara et al. (2025), Springer MITA

**Caracterización de fases de marcha con plantilla a 5 Hz** (sampling muy bajo)
- 8 FSRs + IMU triaxial por pie
- N=14 sanos
- **Pressure-only features con SVM**: macro-F1 **0.915**
- **IMU-only**: significativamente peor a 5 Hz

**Conclusión accionable:** la presión es más informativa que el IMU para detectar fases de marcha, y a bajos sampling rates la presión es robusta mientras el IMU degrada. Para tu sistema, si tenés que priorizar features por costo computacional, primero exprimi las de FSR.

---

## Lista consolidada de features recomendados para tu plantilla (3-4 FSR + IMU bajo el arco)

Aprovechando lo que se puede calcular efectivamente con tu hardware, y priorizando por evidencia empírica de discriminación stroke vs sano:

### Bloque A — Espacio-temporales (PRIORITARIOS — evidencia más fuerte)
*Calculados a partir de la detección de eventos heel-strike/toe-off del IMU, validados por presión.*

1. **Stride time** (duración total del ciclo)
2. **Stance time** (% del ciclo en contacto)
3. **Swing time** (% del ciclo en vuelo)
4. **Double support time**
5. **Cadence** instantánea (cycles/min)
6. **Stride length estimada** (integración del IMU corregida por ZUPT)
7. **Velocidad estimada de la zancada**

→ De estos, **stride speed y swing duration** son top-9 de Brasiliano; **stance duration** sostiene la mejor feature de variabilidad.

### Bloque B — Variabilidad (PRIORITARIOS — evidencia muy fuerte)
*Calculados como CoV o SD sobre ventana de 10+ zancadas consecutivas.*

8. **CoV de stride time**
9. **CoV de stance time** ← top-3 de Brasiliano
10. **CoV de swing time**
11. **CoV de cadence**

→ La variabilidad es uno de los mejores marcadores de stroke porque captura la inconsistencia del patrón motor, característica de la marcha hemipléjica.

### Bloque C — Force / FSR magnitude (PRIORITARIOS — críticos para stroke)
*Calculados por sensor sobre cada zancada.*

12. **Peak force** por cada FSR
13. **Mean pressure** por cada FSR
14. **Pressure-Time Integral (PTI)** por cada FSR
15. **Contact time** por región (cuánto tiempo el sensor estuvo sobre umbral)
16. **Loading rate** (pendiente máxima de la curva de fuerza)
17. **Time-to-peak** desde heel-strike hasta peak force

→ Para stroke, **Kang 2025 (#20)** demostró que el push-off (peak force en metatarsianos) está sistemáticamente reducido en el lado parético.

### Bloque D — Ratio y asimetría (PRIORITARIOS — diferenciales para stroke)
*Lo que captura la asimetría característica de la marcha hemipléjica.*

18. **Ratio medial/lateral de peak force** (Ma 2017 — diseñó su sistema exactamente alrededor de esto)
19. **Pressure progression ratio**: distribución de peso anterior/posterior
20. **Symmetry Index entre zancadas izquierda/derecha** (si tenés bilateral): SI = |X_left - X_right| / (0.5 × (X_left + X_right))
21. **Force Symmetry Index entre zancadas consecutivas** (si tenés unilateral): comparar zancada actual con la anterior del mismo pie

### Bloque E — COP-derived 1D (RECOMENDADOS — adaptable con pocos FSRs)
*Aproximación del COP medio-lateral usando posición conocida de los FSRs como pesos.*

22. **COP_ML estimado** = Σ(force_i × x_i) / Σ(force_i), donde x_i es la coordenada medio-lateral de cada FSR
23. **COP_ML range** (excursión en una zancada)
24. **COP_ML velocity** (derivada temporal)
25. **Zero crossings de COP_ML velocity** ← feature top en Herbers 2024 para fallers

→ Con sólo 3-4 FSRs no se reconstruye un COP 2D completo, pero el componente medio-lateral 1D ya captura el déficit de control postural que más distingue a fallers.

### Bloque F — IMU cinemáticos (RECOMENDADOS)
*Del único IMU bajo el arco.*

26. **ROM (Range of Motion) de pitch** durante la zancada
27. **ROM de roll** durante la zancada (inversión/eversión — clave en stroke por foot inversion según Ma 2017)
28. **Foot orientation** (pitch) en heel-strike
29. **Foot orientation** (pitch) en toe-off
30. **Peak vertical acceleration** en toe-off (proxy de push-off)
31. **Mean angular velocity** en swing phase

### Bloque G — Smoothness / Jerk (RECOMENDADOS — top-9 Brasiliano)
*Log-Dimensionless Jerk del IMU del pie.*

32. **LDLJ de la aceleración del pie en AP** (anterior-posterior)
33. **LDLJ de la aceleración del pie en ML** (medio-lateral)
34. **LDLJ de la velocidad angular del pie** (alternativa que puede dar mejor SNR)

Fórmula:
```
LDLJ = −ln( (t2−t1)·max(||a(t)||) · ∫|a'(t)|² dt )
```
*Importante:* en Brasiliano se calculaba sobre IMUs de cabeza/esternón porque la cadena cinemática filtra y amplifica el jerk hacia arriba. Aplicado al pie, el LDLJ puede ser dominado por choques de heel-strike. Conviene calcularlo solo durante la fase de swing.

### Bloque H — Frecuencia / Entropía (OPCIONALES — para refinamiento)
*Sobre la ventana de aceleración de cada zancada.*

35. **Spectral entropy** de la aceleración del IMU
36. **Sample entropy** de la velocidad angular
37. **Dominant frequency** (≈ inversa del stride time)
38. **Power en bandas** <0.5 Hz, 0.5–2 Hz, >2 Hz de la aceleración

→ Estos sumaron evidencia en Toth 2024 (One-Class SVM personalizado, AUC 0.967) y Herbers 2024 (PSD bands para fallers).

---

## Recomendación operativa — Pipeline progresivo

Dado que estás haciendo one-class anomaly detection con calibración per-paciente, la estrategia eficiente es:

**Fase 1 — Vector mínimo (10 features)**
Bloques A (1-7) + B (8-11): puro espacio-temporal + variabilidad. Esto solo, con Mahalanobis personalizado, ya debería darte un baseline competitivo basado en Brasiliano y Chen.

**Fase 2 — Expansión con presión (sumar 10 features → 20 total)**
Agregar Bloque C (12-17) + Bloque D (18-21). Acá entra la información clave de stroke (push-off, asimetría, distribución medial/lateral). Es lo que distingue tu sistema de uno basado solo en IMU.

**Fase 3 — Refinamiento (sumar 7-9 features → ~28 total)**
Agregar Bloque E (COP-ML), Bloque F (cinemáticos IMU), Bloque G (LDLJ). Llegás cerca del techo de Chen 2022 (18 features → 94.2%) y Brasiliano 2026 (9 features → 96.7%).

**Fase 4 — Solo si las anteriores no alcanzan**
Bloque H (frecuencia / entropía). Más caro computacionalmente, sobre todo el FFT, pero opcional si la precisión lo justifica.

---

## Caveats importantes

1. **El paper de Brasiliano usa sensores en cabeza, esternón y lower back** — partes del cuerpo que vos no medís. Sus features de smoothness y stability superiores (LDLJ, COA, RMS del tronco/cabeza) **no son directamente replicables** con solo IMU en el pie. Lo más que se puede hacer es calcular LDLJ del IMU del pie como aproximación parcial, pero su valor discriminativo será probablemente menor.

2. **El paper de Herbers usa un array completo de FSRs en la plantilla** (no especifica cantidad pero permite trazar trayectoria COP 2D completa). Con 3-4 FSRs vos podés reconstruir el componente medio-lateral del COP de manera razonable pero no el AP. Aún así, el ML es el dominio donde las features de fallers son más informativas, así que sigue siendo útil.

3. **Personalización es prácticamente obligatoria.** Toth 2024 mostró 55% vs 97% (global vs personalizado). Esto no es un truco para ganar accuracy: en stroke la heterogeneidad inter-paciente es enorme, y un baseline poblacional probablemente no funcione.

4. **Cuidado con la "feature explosion".** Chen 2022 plateauó en 18 features y Brasiliano en 9. Más features que eso típicamente agrega ruido y degrada generalización. La feature selection (LASSO, SBS, Boruta) es esencial. Para un anomaly detector personalizado en edge, el sweet spot es probablemente **15-25 features**.

5. **Calibración inicial necesaria.** Toth 2024 requiere baseline non-fatigued del propio sujeto. En tu caso, eso se traduce en una sesión inicial de calibración con marcha normal del paciente sano (o del paciente en estado estable) para definir la "normalidad" personalizada.

---

## Referencias de los papers clave

| # | Autor / Año | Revista | Aporte específico |
|---|-------------|---------|-------------------|
| 1 | Brasiliano et al. 2026 | Sci Rep 16:8908 | Top 9 features stroke vs sano con MIMUs, 96.7% accuracy |
| 2 | Herbers et al. 2024 | NPJ Parkinsons Dis 10:67 | COP features para PD fallers, AUC 0.91 |
| 3 | Chen et al. 2022 | Front Neuroinform 16:1006494 | 18 features con IMU + insole para Brunnstrom, 94.2% |
| 4 | Toth et al. 2024 | Sensors PMC12845696 | One-Class SVM personalizado AUC 0.967 |
| 5 | Nanayakkara et al. 2025 | Springer MITA 2025 | FSR features superan IMU a 5 Hz, macro-F1 0.915 |
| 6 | Ulster (Chien) 2025 | IEEE BIBM 2025 | Smart insole stroke recognition SVM/KNN 0.88 |
| 7 | Pan et al. 2023 | IEEE Sensors J 23(11) | Insole + IMU para evaluación hemipléjica |

Estos siete papers, junto con los que ya tenés en la carpeta de bibliografía, son la base sólida para fundamentar tu elección de features en el marco teórico.
