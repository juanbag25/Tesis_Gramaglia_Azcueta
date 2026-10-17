# worker/ — Reentrenamiento de modelos (Python)

Worker de cómputo que entrena y reentrena los modelos de **clase E, H y W**. Los de **clase L** se adaptan en la cintura y su estado sube a la base en el check-in de cada sesión (ADR-043 rev). El worker **nunca infiere en tiempo real** (ADR-013).

- **Mínima:** corre en la **laptop**.
- **Máxima:** corre en la **nube** (proveedor: CP-06) — ADR-009.

## Flujo

1. Se dispara un job en `retrain_jobs`: por **drift** (Mahalanobis como sensor), por **schedule** o **manual**.
2. Trae los datos del paciente desde Supabase: las **features del micro** de la captura operativa (ADR-018) y, si hace falta, el crudo en Parquet. El crudo llega post-AHRS: el worker **no re-procesa IMU** (ADR-042).
3. Entrena: AE denso (E), Isolation Forest (E), LSTM AE (E/H/W según el footprint — backlog #11); benchmark offline con OC-SVM, GMM y VAE.
4. **Cuantiza a int8** con TF/Keras + conversor TFLite/LiteRT (PTQ con representative dataset — ADR-022).
5. Empaqueta el modelo en el **sobre** de ADR-053 (cabecera + contenido + SHA-256), lo sube a storage y **registra versión, métricas y huella** en `models`.
6. El host lo despliega a la cintura por OTA.

## Reglas

- La **definición de features coincide** con `firmware/shared/` (lee el mismo `features.toml` — ADR-054 — y la misma `feature_set_version`); la paridad se verifica con golden vectors en CI (ADR-018, ADR-021).
- Todo modelo se **respalda en la base** (registry + artefacto): la DB manda.
- Corre con `service_role`, que saltea la RLS por diseño y nunca va en un cliente (ADR-032, ADR-047).

## Dependencias previstas

numpy, scipy, pandas, **scikit-learn**, **TensorFlow/Keras** + conversor TFLite/LiteRT, **supabase-py**, **pyarrow** (crudo en Parquet por tramos — ADR-055). Las versiones se anclan al implementar.

> **Contratos definidos:** el formato de los artefactos es el sobre de ADR-053 (escritor en el worker, lector en C, test de paridad en CI) y el crudo se lee por tramos con la recta de hora de la sesión (ADR-055/056). **Pendiente:** el esqueleto del worker.
