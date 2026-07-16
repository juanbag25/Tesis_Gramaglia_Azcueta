# Objetivos del proyecto

> Documento de referencia sobre el propósito, alcance y filosofía del proyecto de tesis.
> Consolidado a partir de la investigación previa (chats de recopilación bibliográfica y de features) y de la definición de arquitectura.

## 1. Problema clínico

El accidente cerebrovascular (ACV) suele dejar secuelas en la marcha: **asimetría inter-miembro**, reducción del *push-off* del lado parético, variabilidad aumentada del patrón motor, alteración del control postural y mayor **riesgo de caídas**. El monitoreo tradicional (laboratorios de marcha, MoCap, GaitRite) es preciso pero caro, puntual y no acompaña al paciente en la vida diaria.

## 2. Objetivo general

Desarrollar un **sistema de plantillas inteligentes bilaterales** para la **detección personalizada de anomalías de marcha en pacientes post-ACV**, con **feedback vibrotáctil en tiempo real** e **inferencia en el borde (edge)**, capaz de funcionar tanto en un entorno controlado (fase de investigación) como en uso diario continuo (fase de implementación real).

## 3. Objetivos específicos

- Instrumentar el calzado con **FSR + IMU** por pie y una unidad de cintura para capturar la marcha a 100 Hz.
- Calcular **descriptores biomecánicos (features)** validados por la literatura, aprovechando la configuración **bilateral** para medir **simetría inter-miembro**.
- Detectar desviaciones respecto de la **marcha normal personalizada** del propio paciente (enfoque one-class / personalización primero).
- Entregar **feedback vibrotáctil** en tiempo real ante anomalías.
- Soportar **adaptación/reentrenamiento online** de los modelos, con distintos niveles de costo computacional (ver taxonomía L/E/W).
- Almacenar datos y modelos por paciente en una **base de datos remota**, con trazabilidad para reevaluar algoritmos.

## 4. Alcance: mínima y máxima

**Objetivo de mínima (entorno controlado).** Toda la infraestructura funciona con una laptop cerca capaz de captar los datos, almacenarlos y reentrenar los algoritmos. Las plantillas envían a la cintura; la cintura recibe ambos flujos preservando la marca temporal y reenvía a la laptop; la laptop persiste en una base remota y evalúa algoritmos de forma asincrónica; los modelos se despliegan al micro y se respaldan en la base.

**Objetivo de máxima (uso diario continuo).** La laptop se reemplaza por un **celular** (BLE con la cintura); el reentrenamiento pesado corre en un **backend en la nube**; persiste el guardado por paciente y el respaldo de modelos. Todo lo construido para la mínima **escala** hacia la máxima sin reescrituras estructurales.

## 5. Filosofía de diseño

- **Personalización primero.** Un baseline por paciente supera ampliamente a los modelos poblacionales (evidencia: one-class personalizado AUC≈0,97 vs. ~55 % de un modelo global). La heterogeneidad inter-paciente en ACV es enorme.
- **Bilateral.** La simetría inter-miembro es el diferencial clínico y se explota como familia de features.
- **Edge / on-device.** Inferencia en el micro por latencia y privacidad; la nube/host sólo para el reentrenamiento pesado y la persistencia.
- **Economía de features.** El *sweet spot* está en ~15–25 features bien elegidas; más features suele agregar ruido (Chen plateauó en 18, Brasiliano en 9).

## 6. Enfoque de algoritmos (3 niveles / taxonomía L-E-W)

- **Clase L (Local-Local):** inferencia y reentrenamiento en el micro, **dato a dato** (Mahalanobis con EMA, z-score/EWMA, probabilísticos simples). Mahalanobis además actúa como **sensor de drift**.
- **Clase E (Edge + Worker):** inferencia en el micro (int8), reentrenamiento en el worker (autoencoder denso cuantizado).
- **Clase W (Worker-heavy):** inferencia y/o reentrenamiento en el worker (LSTM autoencoder, Isolation Forest).

## 7. Validación (referencia)

- **ICC** (>0,90 = concordancia excelente) contra gold standard (MoCap/GaitRite).
- **AUC-ROC** como métrica probabilística independiente de umbral.
- Sesión de **calibración inicial** por paciente para definir la "normalidad" personalizada.

## 8. Referencias clave

- Brasiliano et al. (2026, *Sci Rep* 16:8908) — top features stroke vs sano, SVM 96,7 %.
- Herbers et al. (2024, *npj Parkinsons Dis* 10:67) — COP + frecuencia, AUC 0,91 fallers.
- Chen et al. (2022, *Front Neuroinform* 16:1006494) — 18 features IMU+insole, 94,2 %.
- Toth et al. (2024–2025, *Sensors* PMC12845696) — one-class SVM personalizado, AUC 0,967.

Ver `docs/investigacion/` para la bibliografía completa y el detalle de features.
