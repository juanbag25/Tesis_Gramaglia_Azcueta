# Descripción del proyecto

## Objetivo

Diseño e implementación de una plantilla instrumentada inalámbrica para la **detección personalizada de anomalías de marcha en tiempo real**, con feedback vibrotáctil inmediato y procesamiento íntegramente on-device. El sistema apunta a aplicaciones de rehabilitación post-stroke, prevención de caídas en adultos mayores y monitoreo domiciliario de marcha sin necesidad de visitas a un laboratorio especializado.

## Arquitectura de hardware

La plataforma se construye sobre un **Raspberry Pi Pico 2 W** (RP2350, microcontrolador dual ARM Cortex-M33 a 150 MHz con 520 KB de SRAM), que integra:

- Dos **FSRs (Force Sensitive Resistors)** ubicados bajo el antepié medial y lateral, acondicionados mediante divisor de tensión y leídos por los ADCs de 12 bits del microcontrolador (GP26 y GP27).
- Un **IMU 6 DOF** colocado en una cavidad bajo el arco del pie — posición óptima según Eskofier et al. (2020) para reconstruir la trayectoria del pie — y comunicado por I²C0 (GP20/GP21).
- Un **motor vibrador** controlado por PWM (GP18) a través de un transistor NPN con diodo flyback, para entregar feedback háptico modulable en intensidad.
- Comunicación inalámbrica WiFi/BLE integrada del Pico 2 W para sincronización opcional con smartphone y exportación de datos.

Toda la inferencia se ejecuta on-device, eliminando la latencia de cloud y preservando la privacidad del usuario.

## Pipeline de procesamiento

### 1. Adquisición y preprocesamiento

Las señales se muestrean sincronizadamente a 100 Hz. El IMU entrega aceleración 3D y velocidad angular 3D; los FSRs aportan dos canales de presión plantar. El preprocesamiento aplica un filtro Butterworth pasa-bajos de cuarto orden con frecuencia de corte de aproximadamente 20 Hz para eliminar ruido de alta frecuencia y artefactos de movimiento, normaliza las lecturas de los FSRs mediante la curva de calibración no lineal característica del sensor para convertir tensión a fuerza estimada, y compensa el drift inicial del giroscopio mediante un período de inicialización en reposo de tres segundos previo a cada sesión de uso, replicando el protocolo validado por Riglet et al. (2023).

### 2. Detección de eventos y segmentación por zancada

Cada ciclo de marcha se aísla aplicando detección de eventos sobre la señal del IMU. El heel-strike se identifica por el mínimo local en la velocidad angular sagital, y el toe-off por umbral cruzado en la magnitud de aceleración, siguiendo el enfoque MFD-GED de Shen et al. (2026). Para corregir el drift de orientación del giroscopio durante la fase de oscilación se aplica una variante de strap-down integration modificada (MSDI, Falbriard et al. 2020), más robusta que el ZUPT clásico cuando hay variaciones de velocidad o cambios de patrón de pisada. Cada zancada — típicamente entre 0.8 y 1.5 segundos — se convierte en la unidad fundamental de análisis para todo el pipeline posterior.

### 3. Extracción de features

De cada zancada segmentada se extrae un vector de aproximadamente 20-25 features que abarcan tres dominios complementarios: parámetros temporales (stride time, stance time, swing time, doble apoyo, cadencia instantánea); parámetros de fuerza plantar (pico de fuerza en cada FSR, integral de presión por fase, ratio medial/lateral, tiempo de contacto por región); y parámetros cinemáticos derivados del IMU (rango de movimiento de pitch y roll, orientación del pie en heel-strike y toe-off, aceleración pico en toe-off como proxy de push-off). Adicionalmente se calculan índices de simetría con la zancada contralateral, particularmente relevantes en marcha hemipléjica post-stroke según Kang (2025).

La decisión de trabajar a nivel de zancada — en lugar de ventanas de señal cruda — se fundamenta en dos consideraciones: la marcha es inherentemente cíclica y la unidad fisiológicamente significativa es el ciclo completo, y el vector reducido permite implementar algoritmos clásicos ligeros que caben holgadamente en los 520 KB de SRAM del RP2350.

### 4. Calibración inicial

Al iniciar uso por primera vez con un usuario, el sistema realiza una sesión de calibración de aproximadamente 100 zancadas de marcha normal en condiciones controladas (terreno plano, velocidad cómoda autoseleccionada). Con estas zancadas se entrenan los modelos personalizados que residirán en el dispositivo. Este enfoque per-paciente está respaldado por Matthews et al. (2018) en esclerosis múltiple, donde modelos personalizados superaron sustancialmente a modelos genéricos para predicción de velocidad de marcha en sujetos con mayor discapacidad.

### 5. Pipeline de algoritmos de detección de anomalías

El problema se formaliza como **one-class classification**: se entrena exclusivamente con marcha normal del usuario, y todo paso que se aleje significativamente del modelo aprendido se marca como anómalo. La estrategia experimental consiste en evaluar progresivamente cuatro algoritmos ordenados por complejidad creciente, midiendo en cada uno el trade-off entre precisión de detección, latencia de inferencia y huella de memoria en el RP2350.

**(a) Baseline — Distancia de Mahalanobis multivariada.** Sobre el vector de features se estima la media μ y la matriz de covarianza inversa Σ⁻¹ a partir de las zancadas de calibración. Para cada nueva zancada x se calcula D² = (x−μ)ᵀ Σ⁻¹ (x−μ), y se marca como anómala si D² supera un umbral fijado al percentil 99 de la distribución de calibración. Implementación trivial en C, ocupa pocos KB de memoria y opera en microsegundos. Sirve como piso interpretable contra el cual evaluar todo lo posterior. Asume unimodalidad gaussiana de los features normales, por lo que su limitación principal aparece cuando la marcha normal del usuario presenta varios modos (por ejemplo, caminar lento y caminar rápido coexistiendo).

**(b) Isolation Forest.** Conjunto de 50 a 100 árboles aleatorios entrenados offline en PC con las features de calibración y exportados al firmware como tablas compactas de splits binarios. La inferencia recorre los árboles y promedia la profundidad de aislamiento de la zancada de entrada para producir un anomaly score. Captura no-linealidades y combinaciones de features que Mahalanobis ignora, mantiene una huella ligera (decenas de KB) y permite umbralización por probabilidad calibrada.

**(c) Autoencoder denso shallow.** Red neuronal feedforward simétrica con arquitectura del tipo 20-12-6-12-20, entrenada offline mediante backpropagation para minimizar el error de reconstrucción del vector de features de marcha normal. Se despliega on-device mediante TensorFlow Lite for Microcontrollers con cuantización a int8 para reducir tamaño y acelerar inferencia. El score de anomalía es el error cuadrático medio entre input y reconstrucción. Captura correlaciones no-lineales más sutiles entre features y produce un score continuo bien condicionado para umbralización adaptativa.

**(d) LSTM autoencoder sobre señal cruda windoweada.** Variante de mayor complejidad que opera directamente sobre la ventana de un ciclo de marcha (aproximadamente 100 muestras × 8 canales) en lugar del vector de features extraído. Captura la dinámica temporal completa del ciclo, replicando la lógica de GAD (Lee et al., 2024) y EdgeSense (Kirubakaran et al., 2025). Requiere cuantización agresiva y evaluación cuidadosa de viabilidad temporal en el RP2350. Representa el techo de complejidad que se intentará alcanzar; si la latencia o el footprint resultan prohibitivos, queda como referencia ejecutable en el smartphone vinculado.

### 6. Adaptación online

Tras la calibración inicial, los parámetros del detector base (μ y Σ del Mahalanobis) se actualizan continuamente por exponential moving average sobre las zancadas clasificadas como normales, permitiendo personalización gradual sin reentrenar desde cero. Este enfoque sigue la lógica de online adaptation validada por Kang et al. (2025) en exoesqueletos para stroke, donde menos de un minuto de adaptación mejoró la estimación de fase de marcha en un 66% en sobrevivientes de stroke. Cuando la deriva acumulada de los parámetros supera un umbral configurable, se gatilla un reentrenamiento offline (vía smartphone o PC) de los detectores más complejos (b)–(d), preservando la capacidad de adaptarse a cambios de patrón a más largo plazo como recuperación funcional progresiva.

### 7. Feedback vibrotáctil

Cuando una zancada cruza el umbral de anomalía, se dispara un patrón de vibración específico mediante modulación PWM del motor vibrador. Siguiendo la evidencia de Sanchez-Morillo et al. (2025) — feedback basado en patrones supera al feedback de alerta simple en términos de utilidad percibida y aceptación para uso regular — y la advertencia de Iwata et al. (2019) sobre la carga cognitiva que el biofeedback puede imponer en adultos mayores durante tareas duales, se evaluarán patrones de intensidad y duración modulados según el tipo y severidad de anomalía detectada, calibrados para maximizar la información transmitida sin saturar al usuario durante uso prolongado.

## Estrategia de validación

La validación del sistema completo seguirá tres niveles complementarios.

A nivel **funcional**, se realizarán mediciones simultáneas con la plantilla y un sistema de referencia (motion capture óptico cuando esté disponible, GaitRite o cinta instrumentada en su defecto) en una cohorte de 25 a 30 sujetos sanos caminando en pista de 10 metros y treadmill a tres velocidades (lenta, autoseleccionada cómoda, y rápida). Las métricas estadísticas serán ICC para acuerdo absoluto, Bland-Altman para consistencia, y Pearson para correlación, con umbrales objetivo ICC > 0.90 para los parámetros espacio-temporales básicos (cadencia, stride time, stance time), replicando la metodología validada por Riglet et al. (2023) y Lim et al. (2025).

A nivel de **detección de anomalías**, se inducirán perturbaciones controladas en sujetos sanos — cambio de calzado, peso asimétrico de 1 kg en una pierna, simulación de foot drop con vendaje rígido, obstáculos en la pista — y se medirá sensibilidad, especificidad, y AUC-ROC de cada algoritmo del pipeline, comparando además la latencia de detección y el footprint de memoria en el RP2350.

A nivel de **piloto clínico**, en una etapa posterior, se evaluará el sistema en un pequeño subgrupo de pacientes con stroke leve a moderado, comparando las detecciones del dispositivo contra evaluación clínica supervisada por kinesiólogo y mediciones de balance estandarizadas (Berg Balance Scale, WBA y PSV del paper de Jung et al. 2017).

## Resultado esperado

Una plantilla instrumentada de bajo costo (menos de USD 100 en componentes), peso inferior a 100 gramos, autonomía superior a 8 horas, capaz de detectar anomalías de marcha personalizadas en tiempo real con latencia inferior a 50 ms desde la finalización de la zancada hasta el feedback vibrotáctil. El producto final constituye un proof of concept para validar la viabilidad técnica y clínica del enfoque, abriendo camino a futuras integraciones en rehabilitación domiciliaria, monitoreo deportivo y prevención de caídas en adultos mayores.

## Contribución original

Frente al estado del arte revisado, el aporte específico del proyecto se sitúa en la **combinación** de cuatro elementos que rara vez aparecen juntos en la literatura: hardware de bajo costo basado en microcontrolador comercial, detección de anomalías one-class personalizada y adaptativa, inferencia íntegramente edge sin dependencia de cloud, y feedback vibrotáctil cerrado en el mismo dispositivo. Trabajos previos típicamente abordan dos o tres de estos elementos pero raramente los cuatro de forma integrada en un único dispositivo wearable autónomo.
