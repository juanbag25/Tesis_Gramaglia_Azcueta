# GAD: A Real-time Gait Anomaly Detection System with Online Adaptive Learning

**Autores:** Ming-Chang Lee, Jia-Chun Lin, Sokratis Katsikas
**Afiliación:** Department of Information Security and Communication Technology, Norwegian University of Science and Technology (NTNU), Gjøvik, Norway
**Publicado:** mayo 2024 (preprint)
**arXiv:** https://arxiv.org/abs/2405.09561
**PDF arXiv:** https://arxiv.org/pdf/2405.09561
**ResearchGate:** https://www.researchgate.net/publication/380635298
**Conference:** ICT Systems

---

## Abstract

Gait anomaly detection involves detecting deviations from a person's normal gait pattern. These deviations can indicate:
- **Health issues and medical conditions** (healthcare domain)
- **Fraudulent impersonation and unauthorized identity access** (security domain)

Many existing gait anomaly detection approaches require offline data preprocessing, offline model learning, and parameter setting — restricting their effectiveness in real-world scenarios.

This paper introduces **GAD, a real-time gait anomaly detection system**. GAD detects anomalies within an individual's **three-dimensional accelerometer readings** based on:
- **Dimensionality reduction**
- **Long Short-Term Memory (LSTM)** neural networks

## Funcionamiento del sistema

1. **Inicio:** GAD comienza recolectando un segmento de marcha del usuario y entrena un detector de anomalías para aprender el patrón de marcha "on the fly" (en vivo)
2. **Verificación del modelo:** se valida usando los pasos siguientes del usuario
3. **Operación:** si la verificación es exitosa, el detector se emplea para identificar anormalidades en lecturas posteriores cuando el usuario lo solicite
4. **Adaptación online:** el detector se **mantiene actualizado online** para adaptarse a cambios menores del patrón
5. **Retrain:** se reentrena si no provee predicción adecuada

## Métodos de captura del segmento de marcha
Se exploraron dos métodos para capturar segmentos de marcha:
- **Personalized method**: adaptado a la longitud de paso de cada individuo
- **Uniform method**: usando una longitud de paso fija

**Resultado:** GAD logra **mayor accuracy combinado con el método personalizado** en experimentos con dataset público de marcha.

---

## Relevancia para tesis
**Referencia directa para el algoritmo de detección de anomalías**:
- Arquitectura LSTM + reducción de dimensionalidad sobre acelerómetro 3D
- **Online learning sin preprocesamiento offline** — clave para wearables
- Validación per-user (cada usuario entrena su propio detector)
- Demuestra superioridad del enfoque personalizado vs genérico
- Aplicable tanto a salud como seguridad biométrica
- Útil para diseño del pipeline de ML on-edge en el sistema propuesto
