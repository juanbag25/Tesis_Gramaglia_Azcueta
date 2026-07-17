# Improved running gait parameter estimation from single foot-mounted IMU data based on refined event detection

**Autor principal:** Yanfei Shen (AI Sports Engineering Lab, Beijing Sport University, China) y col.
**Revista:** Frontiers in Bioengineering and Biotechnology, vol. 13
**DOI:** https://doi.org/10.3389/fbioe.2025.1714473
**Tipo:** Methods
**Publicado:** 13 enero 2026
**URL:** https://www.frontiersin.org/journals/bioengineering-and-biotechnology/articles/10.3389/fbioe.2025.1714473/full
**PDF:** https://www.frontiersin.org/journals/bioengineering-and-biotechnology/articles/10.3389/fbioe.2025.1714473/pdf
**Licencia:** Open Access (Frontiers)

---

## Abstract

**Background:** Inertial measurement units (IMUs) enable portable gait monitoring, yet their accuracy relies on precise event detection. Conventional algorithms using raw signal peaks often fail during running due to speed variations and diverse foot-strike patterns. Adaptive detection strategies are required for high precision running gait analysis.

**Methods:** This study proposes **MFD-GED (multi-sensor fusion with dynamic gait event detection)**, a refined method for accurate running gait analysis via a single foot-mounted IMU. To enhance event detection, the framework:
- Fuses acceleration- and angular-velocity features
- Employs a parametric strategy to identify initial contact (IC), terminal contact (TC) and mid-stance (MS)
- Computes a comprehensive set of gait parameters

Data from **15 healthy male runners (age: 24.1 ± 1.1 years)** performing 10-m running trials. Benchmarked against a conventional angular-velocity-based gait-segmentation algorithm (AVGS) and validated using laboratory reference (LAB) comprising optical motion-capture and force-plate system. Pearson's r, ICC, and Bland-Altman analysis used for concurrent validity; paired t-tests and Cohen's d for performance improvement.

**Results:**
- MFD-GED method: high concurrent validity vs LAB (r = 0.743–0.991; ICC = 0.741–0.990)
- Compared to AVGS, systematic bias **reduced for spatial parameters** (p > 0.05):
  - Stride velocity: −0.023 m/s vs. −0.012 m/s
  - Stride length: 0.018 m vs. 0.009 m
- **Temporal parameter bias significantly decreased** (p < 0.01; Cohen's d = 1.62–2.20):
  - Contact time: 0.057 s vs. 0.001 s
  - Flight time: −0.063 s vs. −0.003 s
- **Peak vGRF bias** decreased from −0.310 BW to 0.159 BW (p < 0.01; Cohen's d = 1.45)
- Error standard deviations reduced across all metrics

**Conclusion:** This study validates an IMU framework improving running gait detection. Through sensor fusion, MFD-GED enables high-fidelity parameter estimation. While lab-validated for healthy young males, findings affirm its potential for future gait monitoring tasks.

**Keywords:** validation, inertial measurement units, gait event detection, running gait analysis, zero-velocity update

---

## Relevancia para tesis
- Aporta algoritmo concreto (MFD-GED) para detección robusta de eventos de marcha/carrera
- Validación contra gold standard (MoCap + force plates)
- Métricas estadísticas claras (ICC, Bland-Altman, Cohen's d) — modelo a replicar en validación propia
- Concepto de **zero-velocity update (ZUPT)** y fusión de aceleración+gyro
- Útil para sección de algoritmos de procesamiento on-device
