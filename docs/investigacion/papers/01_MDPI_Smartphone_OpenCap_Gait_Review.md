# Smartphone-Based Gait Analysis with OpenCap: A Narrative Review

**Autores:** Serena Cerfoglio, Jorge Lopes Storniolo, Edilson Fernando de Borba, Paolo Cavallari, Manuela Galli, Paolo Capodaglio, Veronica Cimolin

**Revista:** Biomechanics 2025, 5(4), 88
**DOI:** https://doi.org/10.3390/biomechanics5040088
**Publicado:** 3 noviembre 2025
**URL:** https://www.mdpi.com/2673-7078/5/4/88
**PDF:** https://www.mdpi.com/2673-7078/5/4/88/pdf?version=1762231442
**Licencia:** CC BY (Open Access)

---

## Abstract

**Background:** Gait analysis plays a key role in detecting and monitoring neurological, musculoskeletal, and orthopedic impairments. While marker-based motion capture (MoCap) systems are the gold standard, their cost and complexity limit routine use. Recent advances in computer vision have enabled markerless smartphone-based approaches. OpenCap, an open-source platform for 3D motion analysis, offers a potentially accessible alternative. This review summarizes current evidence on its accuracy, limitations, and clinical applicability in gait assessment.

**Methods:** A search was performed in major scientific databases to identify studies published from OpenCap's release in 2023 to June 2025. Articles were included if they applied OpenCap to human gait and reported quantitative biomechanical outcomes. Both validation and applied studies were considered, and findings were synthesized qualitatively.

**Results:** Nine studies were included. Validation research showed OpenCap achieved generally acceptable accuracy kinematics (RMSE 4–6°) in healthy gait, while increased errors were reported for pathological gait patterns. Applied studies confirmed feasibility in different clinical conditions, though trial-to-trial variability remained higher than MoCap, and test–retest reliability was moderate, with minimal detectable changes often exceeding 5°, limiting sensitivity to subtle clinical differences.

**Conclusions:** OpenCap is a promising, low-cost tool for gait screening, remote monitoring, and tele-rehabilitation. Its strengths lie in accessibility and feasibility outside laboratory settings, but limitations in multiplanar accuracy, pathological gait assessment, and kinetic estimation currently preclude its replacement of MoCap in advanced clinical applications. Further research should refine algorithms and standardize protocols to improve robustness and clinical utility.

**Keywords:** gait analysis; markerless motion capture; gait kinematics; motor assessment

---

## 1. Introduction (resumen)

Walking depends on the complex interplay between the central nervous system and the musculoskeletal system. Deviations from standard gait patterns are among the earliest signs of neurodegenerative disorders, musculoskeletal impairments, orthopaedic injuries, and age-related functional decline. Marker-based optoelectronic MoCap systems are considered the gold standard but their high cost, specialized equipment requirements, and time-consuming setup limit clinical use.

The growing demand for accessible movement-analysis tools has driven IMU-based systems (combining accelerometers, gyroscopes, and magnetometers) and consumer-grade RGB-depth cameras. Recent advances in deep-learning-based human pose estimation (OpenPose, HRNet) enable markerless capture from smartphone video. OpenCap is an open-source platform that estimates 3D human movement dynamics (kinematics and kinetics) using only iOS smartphone videos, with an OpenSim-based musculoskeletal model.

## 2. Methods

Literature search across PubMed, Scopus, IEEE Xplore, and Google Scholar from OpenCap's 2023 release through June 2025, using "OpenCap" AND ("gait" OR "walking" OR "gait analysis"). Peer-reviewed full-length research articles in English. 62 records identified, 9 finally included.

## 3. Key Findings

### Setup
- Dual-camera iOS device setup (iPhones/iPads)
- Devices at 30°–45° oblique angles, 1.5–3 m from subject, 1.3–1.5 m height
- Recording at 60 Hz, 720×1280 px (one study at 120 Hz)
- Checkerboard calibration

### Pipeline
Video pose estimation (HRNet/OpenPose) → 2D keypoints → 3D triangulation → anatomical marker prediction via LSTM networks → biomechanical modeling in OpenSim → inverse kinematics and dynamics

### Accuracy in healthy gait
- Joint kinematics RMSE: typically 4–6°, generally below 5° clinical threshold
- Mean absolute errors for joint angles around 4.5° (Uhlrich et al.)
- Joint moments errors <1.5% bodyweight×height
- GRF errors <7% of bodyweight
- Step length errors ~1.2 cm, cadence <3 steps/min
- Frontal plane (pelvic list, hip ab/adduction): lowest errors
- Sagittal plane: stable, slightly higher errors but with larger ROM (most robust clinically)
- Transverse plane: hip internal/external rotation least consistent

### Accuracy in pathological gait
- Errors systematically higher, frequently exceeding 5° threshold
- Largest deviations in crouch gait (knee flex/ext, ankle inv/eversion)
- Circumduction also elevated; equinus intermediate; knee OA lowest among pathological
- Likely due to pose-estimation algorithms trained predominantly on healthy gait

### Camera orientation
- Walking Toward Camera (WTC) more accurate than Walking Away from Camera (WAC) due to reduced occlusion
- Spatio-temporal parameters robust to orientation

### Reliability
- Inter-trial variability 6.6%–22% higher than marker-based
- Grand mean variability increase ~14% across all patterns
- Pelvis tilt and hip flexion contribute most to variability
- Need to average >10 gait cycles per side for reliable measures
- Test-retest: SEM ~2°, MDC ~6°
- Clothing affects results (street clothes increase variability)

### Kinetics
- Native OpenCap muscle-driven dynamic simulation
- Peng et al. used inverse dynamics workflow with foot-ground contact model, ρ > 0.9 for vertical and AP GRFs, ~0.88 for joint contact forces, RMSE < 0.5 BW

### Clinical applications
- Min et al. detected gait abnormalities in stroke, Parkinson's, cerebral palsy patients (reduced hip flexion during swing up to 10° below 35–40° normal range)

## 4. Discussion

OpenCap is a promising, low-cost, accessible alternative to MoCap for gait screening outside specialized labs. Acceptable accuracy in healthy gait (4–6° errors) consistent with 5° clinical threshold. Limitations:
- Reduced accuracy in pathological populations
- Sensitive to camera setup, participant orientation, environmental factors (occlusions, lighting, space)
- Lack of validated center-of-mass (CoM) estimation
- No studies in pediatric or geriatric populations specifically
- Algorithm bias toward healthy gait patterns

Future research should refine algorithms, standardize protocols, and validate across diverse populations to improve robustness and clinical utility.

## Relevancia para tesis
Revisión actualizada (nov 2025) sobre validación y uso clínico de OpenCap. Útil como referencia para:
- Estado del arte en gait analysis markerless basado en smartphones
- Comparación con marker-based MoCap como gold standard
- Límites de precisión en marcha patológica
- Justificación de alternativas accesibles para tele-rehabilitación y monitoreo remoto
