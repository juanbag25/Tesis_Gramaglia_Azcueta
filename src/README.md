# src/ — Código del proyecto

Acá viven las distintas aplicaciones del sistema. Cada subcarpeta es un componente con su propio README, y está pensada para que distintos agentes trabajen en paralelo sin pisarse.

| Carpeta | Componente | Stack |
|---|---|---|
| `firmware/` | Firmware de plantillas y cintura | C/C++ (Raspberry Pi Pico SDK) |
| `host/` | App de ingesta / puente (laptop → celular) | por definir (Python `bleak` en mínima) |
| `worker/` | Reentrenamiento de modelos | Python (numpy, scikit-learn, TensorFlow/Keras — ADR-022) |
| `db/` | Esquema, migraciones y tests de la base | SQL (Supabase sobre Postgres 17: particionado nativo + `pg_partman`; migraciones con la CLI de Supabase — ADR-044/045) |

## Reglas de oro

- **La definición de features es única y compartida** entre `firmware/shared/` y `worker/` (misma semántica, versionada por `feature_set_version`). No dupliques fórmulas divergentes.
- **La sincronización vive en la capa de aplicación** para ser portable entre WiFi (mínima) y BLE (máxima).
- **El registry de modelos declara la clase (L/E/H/W)**; el ruteo de inferencia/reentrenamiento se deriva de ahí, no se hardcodea.
- **El esquema de la base cambia sólo con una migración nueva** en `db/supabase/migrations/`; `db/schema.sql` es un snapshot generado (ADR-045).
- Antes de cambiar algo estructural, revisá `docs/arquitectura/` y registrá la decisión en `docs/decisiones/bitacora_decisiones.md`.

La arquitectura completa está en `docs/arquitectura/Arquitectura_Sistema_Marcha.md`.
