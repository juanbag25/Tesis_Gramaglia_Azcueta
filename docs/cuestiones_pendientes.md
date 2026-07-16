# Cuestiones pendientes

> **Registro vivo** de cuestiones abiertas, dudas de diseño y puntos a ratificar del proyecto. Es la **única fuente de verdad** de lo que falta resolver; el resto de los documentos apuntan acá.
>
> **Cómo usarlo (agentes y humanos):**
> - Cuando surja una cuestión abierta, agregala a la tabla **Abiertas** con un ID nuevo (`CP-NN`), por qué importa, estado y referencia.
> - Cuando se resuelva, **sacala de Abiertas** y moverla a **Resueltas** con la resolución, la fecha y el link al ADR/decisión que la cerró.
> - Registrá el cambio en `memoria/changelog.md`. Si la resolución es una decisión de arquitectura, agregá/actualizá el ADR en `docs/decisiones/bitacora_decisiones.md`.
>
> Estados: `abierta` · `en análisis` · `bloqueada` · (al resolver, pasa a la sección Resueltas).

## Abiertas

| ID | Cuestión | Por qué importa | Estado | Referencia |
|---|---|---|---|---|
| CP-01 | **Tercer FSR en ADC2/GP28.** Confirmar la asignación del 3er FSR contra el PCB real. | Define el pinout y el firmware de muestreo de las plantillas. | abierta | `docs/investigacion/pinout_pico2.md`; Arq. §3 |
| CP-02 | **Cintura como hub de cómputo vs. features en cada plantilla.** ¿Las plantillas mandan crudo y la cintura calcula todo, o cada plantilla calcula sus features? | Afecta el reparto de firmware, el tráfico y la latencia; impacta el diseño de `firmware/insole` y `firmware/waist`. | abierta | ADR-005; Arq. §8 |
| CP-03 | **Dónde detectar el contacto inicial (IC).** En la plantilla (propio) o en la cintura (centralizado). | Impacta la robustez del emparejado de zancadas y el reparto de cómputo. | abierta | ADR-004; Arq. §7 |
| CP-04 | **Nivel de rigor de seguridad.** Qué exige el comité/ética de la tesis para datos de salud (cifrado, consentimiento, anonimización, auditoría). | Define la profundidad de la capa de seguridad y de la gobernanza de datos. | abierta | ADR-006; Arq. §13 |
| CP-05 | **Esquema de `feature_vectors`.** `jsonb` flexible vs. columnas fijas. | Trade-off rendimiento (columnas) vs. flexibilidad ante un feature set que aún cambia (`jsonb`). | abierta | ADR-007; `src/db/schema.sql` |
| CP-06 | **Proveedor concreto del worker en la nube.** VPS Hostinger / contenedor gestionado (Render/Railway/Fly) / instancia con GPU. | Define costo, ops y capacidad de cómputo del reentrenamiento en la máxima. | abierta (se decide al llegar a la máxima) | ADR-009; Arq. §12 |

## Resueltas

> *(Ninguna todavía.)* Formato al resolver:
>
> | ID | Cuestión | Resolución | Fecha | Referencia |
> |---|---|---|---|---|
> | CP-NN | … | Qué se decidió y por qué | AAAA-MM-DD | ADR-NNN / changelog |
