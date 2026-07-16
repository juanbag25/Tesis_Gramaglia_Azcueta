# Changelog

> Registro cronológico de cambios en el proyecto (arquitectura, docs, código, decisiones). Entrada más reciente arriba. Formato: fecha — qué cambió — por qué / referencia.

## 2026-07-16 — Registro de cuestiones pendientes separado

- **Nuevo archivo `docs/cuestiones_pendientes.md`**: registro vivo (única fuente de verdad) de cuestiones abiertas, con IDs CP-01 a CP-06 (migradas desde §17 de la arquitectura y "Puntos abiertos" de la bitácora).
- **`docs/arquitectura/Arquitectura_Sistema_Marcha.md` (§17)** y **`docs/decisiones/bitacora_decisiones.md`** ahora **apuntan** a ese registro en vez de listar los puntos.
- **`CLAUDE.md`** actualizado: nueva regla de flujo (paso 1) para que los agentes agreguen/saquen cuestiones en ese archivo, más su inclusión en la estructura del repo.

## 2026-07-16 — Estructuración del repositorio y arquitectura v1.0

- **Repositorio estructurado** por primera vez: `docs/`, `src/` (scaffolding), `memoria/`, `CLAUDE.md`, `README.md`.
- **Arquitectura informática v1.0 definida** y documentada en `docs/arquitectura/`:
  - `Arquitectura_Sistema_Marcha.md` (especificación completa, 17 secciones).
  - `diagrama_arquitectura.mermaid` (topología + flujos).
  - `esquema_base_de_datos.mermaid` (ER de Supabase).
  - `ciclo_de_vida_modelos.mermaid` (drift → reentrenamiento → OTA).
- **Bitácora de decisiones** creada (`docs/decisiones/bitacora_decisiones.md`) con 13 ADRs (000–012) documentando cada decisión, opciones evaluadas, pros/cons y justificación.
- **Investigación previa** incorporada a `docs/investigacion/`: índice bibliográfico, feature set (41 features), pinout, resumen.
- **Objetivos** consolidados en `docs/objetivos.md`.
- **Decisiones tomadas** (ver bitácora): topología WiFi/AP; uplink BLE desde la mínima; transporte UDP+TCP; sync backbone de reloj + evento; features dual-mode + cintura hub; Supabase; Postgres+TimescaleDB+object storage; retención tiered; worker en la nube (máxima); firmware C/C++ Pico SDK; ruteo de modelos por registry (L/E/W); OTA pesos+firmware A/B.

### Pendiente
- Roadmap de implementación por fases.
- Subir marco teórico a `docs/marco_teorico/`.
- Ratificar puntos abiertos (tercer FSR/GP28, cintura-hub vs plantilla, detección de IC, seguridad, `feature_vectors`, proveedor del worker).
- Iniciar código en `src/`.
