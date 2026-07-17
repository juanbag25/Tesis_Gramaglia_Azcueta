# Drift-Free Foot Orientation Estimation in Running Using Wearable IMU

**Autores:** Mathieu Falbriard, Frédéric Meyer, Benoît Mariani, Grégoire P. Millet, Kamiar Aminian
**Afiliaciones:** EPFL Lausanne, University of Lausanne, Gait Up S.A., Switzerland
**Revista:** Frontiers in Bioengineering and Biotechnology, vol. 8, 65
**DOI:** https://doi.org/10.3389/fbioe.2020.00065
**Tipo:** Methods
**Publicado:** 13 febrero 2020
**URL:** https://www.frontiersin.org/journals/bioengineering-and-biotechnology/articles/10.3389/fbioe.2020.00065/full
**PDF:** https://www.frontiersin.org/journals/bioengineering-and-biotechnology/articles/10.3389/fbioe.2020.00065/pdf
**PMC:** https://pmc.ncbi.nlm.nih.gov/articles/PMC7031162/
**Licencia:** CC BY 4.0 (Open Access)

---

## Abstract

This study aimed to introduce and validate a new method to estimate and correct the orientation drift measured from foot-worn inertial sensors. A **modified strap-down integration (MSDI)** was proposed to decrease the orientation drift, which, in turn, was further compensated by estimation of the **joint center acceleration (JCA) of a two-segment model of the foot**.

This method was designed to fit the different foot strike patterns observed in running and was validated against an optical motion-tracking system during level treadmill running at 8, 12, and 16 km/h. Sagittal and frontal plane angles from inertial sensors and motion tracking were compared at different moments of the ground contact phase.

**Resultados (N=26):**
- Foot orientation at mean stance: accuracy (inter-trial median ± IQR) of **0.4 ± 3.8°** and precision of **3.0 ± 1.8°**
- Foot orientation shortly before initial contact (IC): accuracy of **2.0 ± 5.9°** and precision of **1.6 ± 1.1°**
- **More accurate than commonly used zero-velocity update (ZUPT) methods** derived from gait analysis but not explicitly designed for running

**Población:** 26 voluntarios (9 mujeres, 17 hombres, edad 29 ± 6 años, peso 70 ± 10 kg, altura 174 ± 8 cm, corriendo 2.1 ± 1.0 h/semana, 11 afiliados a club de running)

**Keywords:** running, inertial measurement units, validation study, orientation, drift, angles, foot strike

---

## Relevancia para tesis
- **Crítico para procesamiento del IMU**: aborda el problema del drift de orientación (issue fundamental en sensores inerciales)
- Propone MSDI como alternativa al ZUPT clásico, especialmente útil para velocidades altas o patrones de pisada distintos
- Modelo de dos segmentos del pie (joint center acceleration)
- Validación cuantitativa rigurosa vs MoCap óptico
- Citar en sección de algoritmos de fusión sensorial y compensación de drift
