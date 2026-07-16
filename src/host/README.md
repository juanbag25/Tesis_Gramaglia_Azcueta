# host/ — App de ingesta / puente

Cliente que se conecta a la cintura por **BLE** y actúa de puente hacia la persistencia y el reentrenamiento.

- **Mínima:** app en la **laptop** (Python, `bleak` como central BLE). Recibe el stream (notificaciones GATT), bufferea localmente, escribe crudo/features/scores a **Supabase**, y hace de puente para el **OTA** (baja el modelo del registry y lo empuja al micro por el canal de control).
- **Máxima:** app **móvil** (misma función de puente). El micro no cambia (periférico GATT agnóstico al central); sólo cambia esta app.

## Responsabilidades

- Descubrimiento y conexión BLE con la cintura (respetando MTU ~185 B y connection-intervals tipo iOS desde el diseño).
- Ingesta del stream + buffer local (tolerancia a caídas de conectividad).
- Escritura a Supabase (vía librería cliente / API REST).
- Puente OTA (pesos + firmware A/B) hacia el micro.

> **Pendiente:** definir stack de la app móvil para la máxima; esqueleto del cliente `bleak` para la mínima.
