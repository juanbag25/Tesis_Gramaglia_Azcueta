# Machine learning techniques for independent gait recovery prediction in acute anterior circulation ischemic stroke

**Revista:** Journal of NeuroEngineering and Rehabilitation, 2025
**DOI:** https://doi.org/10.1186/s12984-025-01548-5

**URLs:**
- Springer Open: https://jneuroengrehab.biomedcentral.com/articles/10.1186/s12984-025-01548-5
- PMC: https://pmc.ncbi.nlm.nih.gov/articles/PMC11786359/

**Publicado:** febrero 2025

---

## Abstract

**Objetivo:** Desarrollar y validar un modelo predictivo basado en machine learning para la **recuperación de la marcha** en pacientes con **stroke isquémico de circulación anterior aguda**.

**Métodos:**
- Entre mayo y noviembre de 2023, **237 pacientes** con stroke isquémico de circulación anterior aguda fueron enrolados
- Pacientes divididos aleatoriamente en sets de entrenamiento y validación en proporción **7:3**
- Se recolectaron **31 características médicas**
- **LASSO regression** (Least Absolute Shrinkage and Selection Operator) para screening de variables predictoras
- Modelos predictivos desarrollados con:
  - **Random Survival Forest (RSF)**
  - **COX regression**
- Modelo óptimo identificado en base a valores de **C-index**
- **SHAP (SHapley Additive exPlanations)** para interpretar el modelo RSF global y localmente

**Resultados:** Diez predictores identificados mediante LASSO, incluyendo:
- Edad
- Género
- Periventricular white matter hyperintensities (PVWMH)
- Montreal Cognitive Assessment (MoCA)
- National Institutes of Health Stroke Scale (NIHSS)
- (otros — ver paper completo)

---

## Relevancia para tesis
- Ejemplo de **modelo predictivo de recuperación funcional** que combina clinical data + ML
- Uso de LASSO para feature selection — útil para reducir dimensionalidad
- Random Survival Forest como modelo robusto para datos clínicos con time-to-event
- SHAP para interpretabilidad — buena práctica en ML clínico
- Sirve como referencia para predicción de outcomes en pacientes que usarían el dispositivo de la tesis
- Complementa la detección de anomalías con un módulo de pronóstico clínico
