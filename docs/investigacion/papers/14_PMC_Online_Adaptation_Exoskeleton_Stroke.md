# Online Adaptation Framework Enables Personalization of Exoskeleton Assistance During Locomotion in Patients Affected by Stroke

**Autores:** Inseung Kang, Dean D. Molinaro, D. Park, D. Lee, P. Kunapuli, K. R. Herrin, Aaron J. Young (Georgia Tech)
**Revista:** IEEE Transactions on Robotics, 2025
**URLs:**
- IEEE Xplore: https://ieeexplore.ieee.org/document/11112638/
- PMC: https://pmc.ncbi.nlm.nih.gov/articles/PMC12435548/
- ResearchGate: https://www.researchgate.net/publication/394298090
**Publicado:** 2025

---

## Abstract

Robotic exoskeletons can transform mobility for individuals with lower-limb disabilities. However, their widespread adoption is limited by **controller degradation caused by varying gait dynamics across different users and environments**.

Here, the authors propose an **online adaptation framework** that leverages real-time data streams to continuously update the **user state estimator model**. This approach allows the exoskeleton to learn the **user-specific gait patterns**, effectively customizing the model for each new user.

Additionally, demonstrate a **sensor signal transformation technique** that enables **model transfer across different exoskeleton hardware** (from a research-grade exoskeleton to a commercial device).

## Resultados clave

Con **menos de un minuto de adaptación**, el framework mejoró:

- **Gait phase estimation** (que afecta directamente el timing de asistencia):
  - **+40.9%** en sujetos sanos
  - **+65.9% en sobrevivientes de stroke** (p < 0.05)

- **Torque profile error**: reducción del **32.7%** vs baseline (p < 0.05)

## Contribuciones técnicas

1. Framework de online adaptation que actualiza continuamente el modelo de estimación de estado del usuario
2. Transferencia de modelo entre hardware distinto (research-grade → comercial) mediante transformación de señales
3. Validación tanto en able-bodied como en pacientes con stroke
4. Tiempos de adaptación cortos (<1 min) — práctico para uso clínico

---

## Relevancia para tesis
**Fundamental para el componente de adaptación personalizada del sistema**:
- Demuestra que online adaptation es viable en tiempo real con poco tiempo (<1 min)
- Mejora dramática en pacientes patológicos (66% en stroke) — más útil donde más se necesita
- Aborda la portabilidad de modelos entre hardware (relevante si se cambia el dispositivo)
- Métricas claras: gait phase estimation accuracy y torque profile error
- Refuerza el caso para edge-AI con adaptación en línea
- Citar como precedente del enfoque "adaptación rápida per-user"
