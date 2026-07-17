# Vista 1 — Sistema (general)

> **Nivel de abstracción:** alto. La "foto" del sistema: qué nodos hay, cómo se conectan y cómo fluyen los datos de punta a punta. No entra en internals de firmware ni en fórmulas de features (eso está en las Vistas 2 y 3).
>
> **Estado:** andamiaje. El contenido detallado vive hoy en el documento maestro (`../Arquitectura_Sistema_Marcha.md`, secciones indicadas) y migrará aquí de forma incremental.

## Alcance (qué vive en esta vista)

- **Nodos:** 2 plantillas + 1 unidad de cintura (hub) + host (laptop/celular) + worker (laptop/nube) + persistencia (Supabase).
- **Topología:** plantillas ↔ cintura por WiFi (cintura = AP); cintura ↔ host por BLE. → maestro §5.
- **Transporte:** canal rápido-tolerante + confiable (UDP/TCP en WiFi; GATT notif/writes en BLE). → maestro §6.
- **Sincronización (alto nivel):** backbone de reloj (timestamp+seq+beacon+drift). El detalle de implementación es de la Vista 2. → maestro §7.
- **Modos de operación:** captura vs edge (qué se transmite/almacena). → maestro §8.1.
- **Evolución mínima → máxima.** → maestro §14.

**Diagrama de esta vista:** `../diagrama_arquitectura.mermaid` (topología + flujos).

## ADRs relevantes
ADR-001 (topología), ADR-002 (uplink BLE), ADR-003 (transporte), ADR-004 (sincronización).

## Stack (resumen; detalle en `../stack_tecnologico.md`)
WiFi (lwIP), BLE (BTstack), sync de capa de aplicación (código propio).

## Pendiente de definir / investigar
- Provisioning de credenciales WiFi (sólo si se adopta red de infraestructura; hoy no requerido).
- Compresión de datos en transmisión (sólo si es necesario).
