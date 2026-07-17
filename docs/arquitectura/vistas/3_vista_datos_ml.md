# Vista 3 — Datos y Machine Learning

> **Nivel de abstracción:** *qué* se calcula y *qué* modelos se usan, independiente de *dónde* corre (eso es la Vista 2/4). Aquí vive la **definición canónica** de features y algoritmos, versionada y compartida (regla: se define aquí, se ejecuta en firmware y worker).
>
> **Estado:** andamiaje. Detalle actual en el maestro y en `docs/investigacion/`.
>
> **Análisis de definición:** `3_analisis_features_y_algoritmos.md` — catálogo de features (cálculo, entrada, placement, fase), mecanismo de modularidad (CP-12), clasificación de algoritmos y **backlog de investigación** ordenado.

## Alcance (qué vive en esta vista)

- **Catálogo de features (41, bloques A–H):** definición canónica, fórmulas, parámetros y **placement por defecto** (por-pie en plantilla / bilateral en cintura). → `docs/investigacion/features_anomaly_detection_stroke.md`.
- **Versionado y modularidad de features:** `feature_set_version`; mecanismo de **activar/desactivar** features (disponibles siempre, se eligen según el análisis) — **CP-12**.
- **Cálculo por feature:** qué algoritmo/entrada necesita cada una (evento IC, ventana de N zancadas, COP con coordenadas FSR, ZUPT, FFT, etc.).
- **Taxonomía de modelos (L/E/H/W) + registry:** clase, `inference_target`, `retrain_target`, granularidad. → maestro §9 (ADR-011, ADR-013).
- **Calibración / baseline por paciente:** protocolo de ~100 zancadas de marcha normal → construcción del modelo de normalidad personalizado (es el **entrenamiento inicial**). Curva fuerza-resistencia por-FSR; alineación de frame del IMU.
- **Entrenamiento / reentrenamiento / drift:** Mahalanobis como sensor de drift que dispara E/H/W. → maestro §10.
- **Ciclo de vida de modelos.** → `../ciclo_de_vida_modelos.mermaid`.

**Diagramas de esta vista:** `../ciclo_de_vida_modelos.mermaid` (+ un flujo de calibración/baseline, a crear).

## ADRs relevantes
ADR-005 (features — definición compartida), ADR-011 (taxonomía/registry), ADR-013 (inferencia RT), ADR-009 (backend de reentrenamiento).

## Stack (resumen; detalle en `../stack_tecnologico.md`)
numpy, scipy, scikit-learn (Isolation Forest, ajuste Mahalanobis), PyTorch o TensorFlow/Keras (autoencoders), conversor TFLite (int8), pandas.

## Pendiente de definir / investigar (backlog)
- **Catálogo de features definitivo:** para cada feature, algoritmo de cálculo, entrada y placement. Base para el firmware (Vista 2) y el worker.
- **Modularidad de features (CP-12):** cómo se declaran, activan/desactivan y versionan (config + `feature_set_version`).
- **Clasificación de cada algoritmo** (L/E/H/W) y dónde entrena/infiere cada uno; librerías por algoritmo.
- **Protocolo de calibración/baseline:** nº de zancadas, trials, criterios de aceptación, recalibración.
- **Stride length / ZUPT** (compartido con Vista 2): método definitivo.
