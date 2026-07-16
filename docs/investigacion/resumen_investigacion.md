# Resumen de la investigación previa

> Síntesis de los hallazgos de los chats previos del proyecto (recopilación bibliográfica + análisis de features). Sirve como puerta de entrada rápida a la evidencia que fundamenta el diseño.

## Estado del marco teórico

Existe un **documento de trabajo del marco teórico** (~17.700 palabras, 11 bloques temáticos) redactado en un chat previo. Cubre: contexto clínico del ACV, estado del arte de medición de marcha, principios de sensado FSR/IMU, detección y segmentación de eventos, revisión de evidencia de features, algoritmos one-class de detección de anomalías, personalización y adaptación online, edge AI, biofeedback vibrotáctil, metodología de validación y posicionamiento respecto de trabajos previos.

> **Pendiente de subir:** ese documento (`marco_teorico_documento_de_trabajo.md`) no pudo copiarse automáticamente (vive en otra sesión). Juan puede subirlo a `docs/marco_teorico/`.

## Hallazgos clave (principios de diseño)

- **La personalización es crítica.** Un one-class SVM entrenado sólo con el baseline de marcha normal del individuo (Toth et al.) alcanzó AUC=0,967, superando ampliamente a los modelos globales (~55 % de accuracy). Esto ancla toda la filosofía de diseño.
- **La economía de features importa.** Brasiliano et al. lograron 90 % de accuracy con sólo 3 features (stride speed, CoV de stance duration, IHR medio-lateral). Tensión entre riqueza de features y restricciones de despliegue en edge. *Sweet spot*: ~15–25 features.
- **Las features dinámicas/de frecuencia superan a las posicionales** para clasificar riesgo de caída (Herbers et al., AUC=0,91). Los cruces por cero de la velocidad del COP medio-lateral son un indicador de *jitter* particularmente informativo.
- **La adaptación online es agnóstica al algoritmo.** Los cuatro algoritmos candidatos soportan adaptación online, difiriendo sólo en granularidad y costo:
  - **Mahalanobis:** actualiza zancada a zancada vía media móvil exponencial (EMA).
  - **Isolation Forest:** reentrena periódicamente sobre un buffer circular.
  - **Autoencoders (denso / LSTM):** reentrenan offline en hardware vinculado, con pesos cuantizados desplegados al firmware.
- **Distinciones métricas clave:** ICC (umbral >0,90 = concordancia excelente; penaliza el sesgo sistemático, a diferencia de Pearson r); AUC-ROC como métrica probabilística independiente de umbral; distancia de Mahalanobis como z-score multivariado con matriz de covarianza inversa y umbrales calibrados por chi-cuadrado.
- **La cuantización (int8) es ortogonal** a la elección de arquitectura del modelo — aplicable tanto a autoencoders densos (sobre vectores de ~25 features) como a LSTM autoencoders (sobre señal cruda en ventanas ~100 muestras × 8 canales).

## Algoritmos candidatos evaluados

Cuatro algoritmos de detección de anomalías fueron considerados: **distancia de Mahalanobis, Isolation Forest, autoencoder denso y LSTM autoencoder**. Se propuso una **arquitectura jerárquica complementaria** donde Mahalanobis cumple doble función: detector en tiempo real y **sensor de drift** que dispara el reentrenamiento de los modelos más pesados. Esta idea es la base de la **taxonomía L/E/W** definida en la arquitectura.

## Feature set consolidado

**41 features en 8 bloques (A–H):** A espacio-temporales, B variabilidad, C magnitud de fuerza FSR, D simetría inter-miembro, E COP-1D, F cinemática IMU, G smoothness (Log-Dimensionless Jerk), H frecuencia/entropía. Detalle completo y evidencia en `features_anomaly_detection_stroke.md`.

## Referencias ancla

- Brasiliano et al. (2026, *Sci Rep* 16:8908) — N=85 stroke, SVM, 96,7 %, clustering con 3 features.
- Herbers et al. (2024, *npj Parkinsons Dis* 10:67) — AUC=0,91 riesgo de caída, COP plantar + frecuencia.
- Chen et al. (2022, *Front Neuroinform* 16:1006494) — 94,2 %, KNN, 18 features IMU + presión plantar.
- Toth et al. (2024–2025, *Sensors* PMC12845696) — one-class SVM personalizado, AUC=0,967.

Índice completo de la bibliografía en `00_INDICE.md`.
