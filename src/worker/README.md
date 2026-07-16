# worker/ — Reentrenamiento de modelos (Python)

Worker de cómputo que reentrena los modelos de **clase E y W** (los de clase L se reentrenan en el micro y no pasan por acá).

- **Mínima:** corre en la **laptop**.
- **Máxima:** corre en un **worker en la nube** (VPS/contenedor/instancia; GPU si el modelo lo requiere) — ver ADR-009.

## Flujo

1. Se dispara un job (por **drift** detectado por Mahalanobis, por **schedule**, o **manual**) — tabla `retrain_jobs`.
2. Jala datos del paciente desde Supabase (features / crudo según el modelo).
3. Reentrena (E: autoencoder denso int8; W: LSTM AE, Isolation Forest).
4. **Cuantiza a int8** (TFLite) cuando corresponde.
5. Sube el artefacto a object storage y **registra la versión + métricas** en la tabla `models`.
6. Notifica al host, que despliega al micro por OTA.

## Reglas

- La **definición de features debe coincidir** con `firmware/shared/` (misma `feature_set_version`).
- Todo modelo entrenado se **respalda en la base** (registry + artifact) para recuperación ante pérdida/rotura del micro.

## Dependencias previstas

- Python: numpy, scikit-learn, PyTorch o TensorFlow, TFLite (cuantización), cliente de Supabase, cliente de object storage.

> **Pendiente:** esqueleto del worker, definición del contrato de artefactos (formatos por clase de modelo).
