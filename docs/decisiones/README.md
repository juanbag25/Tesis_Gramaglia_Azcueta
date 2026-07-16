# docs/decisiones/

Registro de decisiones de arquitectura del proyecto.

- **`bitacora_decisiones.md`** — la bitácora principal, en formato **ADR** (*Architecture Decision Record*). Cada entrada documenta una decisión: contexto, **opciones evaluadas con pros y contras**, la elección tomada y su justificación.

## Para qué sirve

Este registro se construye **de a poco** a lo largo del proyecto y tiene un doble propósito:

1. Que cualquier agente o persona entienda **por qué** el sistema es como es (no sólo qué es).
2. Servir de material base para **redactar y justificar las decisiones en el informe final de la tesis**.

## Cómo agregar una decisión

Al tomar o cambiar una decisión de arquitectura:

1. Agregá un nuevo ADR (numeración correlativa) o marcá el anterior como `revisada`/`reemplazada`.
2. Incluí: contexto, opciones con pros/cons, decisión, justificación y consecuencias.
3. Reflejá el cambio en el `Resumen de decisiones` de `docs/arquitectura/Arquitectura_Sistema_Marcha.md`.
4. Registrá el cambio en `memoria/changelog.md`.
