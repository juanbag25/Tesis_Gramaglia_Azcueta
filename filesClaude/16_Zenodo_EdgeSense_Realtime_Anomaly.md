# Real-Time Anomaly Detection on Wearables using Edge AI

**Autores:** Aswathnarayan Muthukrishnan Kirubakaran, Lokesh Butra, Suhas Malempati, Akash Kumar Agarwal, Sumit Saha, Abhirup Mazumder
**Afiliación:** Northeastern University
**Revista:** IJERT (International Journal of Engineering Research & Technology), Vol. 14, Issue 11
**Publicado:** 28 noviembre 2025
**DOI Zenodo:** https://doi.org/10.5281/zenodo.18074824
**URL Zenodo:** https://zenodo.org/records/18074824
**PDF (open access):** https://zenodo.org/records/18074824/files/real-time-anomaly-detection-on-wearables-using-edge-ai-IJERTV14IS110345.pdf
**URL IJERT:** https://www.ijert.org/real-time-anomaly-detection-on-wearables-using-edge-ai

---

## Abstract

Los dispositivos wearable se usan crecientemente para monitoreo continuo de señales fisiológicas y movimiento humano; sin embargo, los sistemas existentes a menudo dependen de:
- Analytics dependiente de la nube
- Umbrales de sensor único
- Workflows de inferencia con delay

Estas limitaciones reducen su utilidad en emergencias en tiempo real.

Este paper introduce **EdgeSense Health**, una arquitectura **edge-native** para detección de baja latencia de anomalías fisiológicas y de movilidad usando **fusión multimodal de sensores**.

## Arquitectura

El framework integra streams sincronizados de:
- **Acelerómetro**
- **Giroscopio**
- **ECG**
- **PPG**
- **SpO2**
- **Temperatura de piel**

Con un pipeline ligero de deep learning que combina:
- **Convolutional feature extraction** (CNN)
- **Transformer-based temporal modeling**
- **Variational Autoencoder (VAE)** para anomaly scoring

## Operación en tiempo real
- La inferencia se ejecuta **directamente en microcontroladores wearable-class o embedded processors**
- **Evita la latencia de cloud**
- **Fortalece la privacidad** al minimizar data egress

## Evaluación del prototipo

Validación con eventos controlados:
- Stressors fisiológicos
- Eventos de temblor
- Perturbaciones de marcha (gait perturbations)
- Caídas (falls)
- Simulaciones de hypoxia

**Resultados:**
- **Latencias de detección < 20 ms**
- Alta accuracy en todas las categorías de anomalías

## Index Terms
Edge AI, sensor fusion, anomaly detection, multi-modal wearables, physiological monitoring

---

## Relevancia para tesis
**Referencia muy reciente (nov 2025) directamente alineada con el proyecto**:
- Demuestra viabilidad de detección de anomalías **on-device** con latencias <20 ms
- Arquitectura híbrida CNN + Transformer + VAE — modelo a considerar
- Fusión multimodal (IMU + biopotenciales) — útil si se expande el sistema
- **Justifica el enfoque edge-AI vs cloud** (latencia y privacidad)
- Incluye explícitamente **gait perturbations** y **falls** en la evaluación
- 306 kB de PDF accesible directo desde Zenodo (open access)
