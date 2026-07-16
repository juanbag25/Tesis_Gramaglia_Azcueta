# src/ — Código del proyecto

Acá viven las distintas aplicaciones del sistema. Cada subcarpeta es un componente con su propio README, y está pensada para que distintos agentes trabajen en paralelo sin pisarse.

| Carpeta | Componente | Stack |
|---|---|---|
| `firmware/` | Firmware de plantillas y cintura | C/C++ (Raspberry Pi Pico SDK) |
| `host/` | App de ingesta / puente (laptop → celular) | por definir (Python `bleak` en mínima) |
| `worker/` | Reentrenamiento de modelos | Python (numpy, scikit-learn, PyTorch/TF) |
| `db/` | Esquema y migraciones de la base | SQL (PostgreSQL + TimescaleDB / Supabase) |

## Reglas de oro

- **La definición de features es única y compartida** entre `firmware/shared/` y `worker/` (misma semántica, versionada por `feature_set_version`). No dupliques fórmulas divergentes.
- **La sincronización vive en la capa de aplicación** para ser portable entre WiFi (mínima) y BLE (máxima).
- **El registry de modelos declara la clase (L/E/W)**; el ruteo de inferencia/reentrenamiento se deriva de ahí, no se hardcodea.
- Antes de cambiar algo estructural, revisá `docs/arquitectura/` y registrá la decisión en `docs/decisiones/bitacora_decisiones.md`.

La arquitectura completa está en `docs/arquitectura/Arquitectura_Sistema_Marcha.md`.
