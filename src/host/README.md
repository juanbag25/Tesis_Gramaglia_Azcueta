# host/ — App de ingesta / puente

Cliente que se conecta a la cintura por **BLE** y actúa de puente hacia la persistencia y el reentrenamiento.

- **Mínima:** app en la **laptop** (Python, `bleak` como central BLE). Recibe los datos por el servicio BLE de la cintura (ADR-051), bufferea localmente, escribe el crudo en Parquet por tramos (ADR-055) y las zancadas, eventos, features y scores a **Supabase** con la hora traducida a UTC (ADR-056), y hace de puente para el **OTA** (baja el artefacto del registry y lo empuja a la cintura por la característica `ota` — ADR-052).
- **Máxima:** app **móvil** (misma función de puente). El micro no cambia (periférico GATT agnóstico al central); sólo cambia esta app.

## Responsabilidades

- Descubrimiento y conexión BLE con la cintura (respetando MTU ~185 B y connection-intervals tipo iOS desde el diseño).
- Ingesta del stream + buffer local (tolerancia a caídas de conectividad).
- Escritura a Supabase (vía librería cliente / API REST), con *upsert* para que reenviar no duplique (ADR-046, ADR-055).
- Mensajes con el código de Python generado desde `mensajes.proto` (ADR-050).
- Traducción de la hora: intercambio con la cintura cada ~10 s y recta `t_device` → UTC por sesión, guardada en `sessions` (ADR-056).
- Puente OTA (pesos + firmware A/B) hacia el micro, con el protocolo de ADR-052.

> **Pendiente:** definir stack de la app móvil para la máxima; esqueleto del cliente `bleak` para la mínima.
