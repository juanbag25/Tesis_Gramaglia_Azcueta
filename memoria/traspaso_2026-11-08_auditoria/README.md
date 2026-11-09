# Traspaso: auditoría previa a programar (2026-11-08)

> **Obsoleto (2026-11-08, Juan). No seguir las instrucciones de abajo.** El diagnóstico partía del cronograma, que Juan descartó junto con todo lo que se había decidido por él. Los cuatro puntos quedaron así: (1) la plantilla detecta los eventos y numera las zancadas en toda captura, como decidieron ADR-015 y ADR-046; (2) descartado; (3) ya estaba decidido en ADR-042; (4) ADR-028 tal cual, con el gesto. La carpeta queda sólo como registro.

> **Para qué existe esta carpeta.** Tobías tuvo en su computadora una conversación con un agente (Claude) en la que cinco subagentes auditaron el repo para responder *"¿queda alguna cuestión pendiente o inconsistencia que impida empezar a programar?"*. Esta carpeta guarda esa conversación y los informes, para que **otro agente, en otra computadora, retome exactamente donde quedó**. Es temporal: cuando los hallazgos se registren en `docs/cuestiones_pendientes.md` (o se decidan en ADRs), la carpeta se puede borrar.

## Qué tenés que hacer (agente que retoma)

1. **Leé, en este orden:**
   1. `01_conversacion.md`: la conversación completa, con los mensajes de Tobías y las respuestas del agente.
   2. `02_informes_subagentes.md`: los cinco informes completos de los subagentes (contratos, base, firmware, pendientes y features). Es el respaldo con las citas `archivo:línea`.
   3. `03_ultimo_mensaje.md`: el **último mensaje** que el agente le dio a Tobías, más la pregunta que quedó abierta.
2. **No rehagas la auditoría.** Los hallazgos ya se verificaron contra las fuentes (el agente original releyó cada cita). Si dudás de alguno, verificalo puntual, no de cero.
3. **Mostrale a Tobías el contenido de `03_ultimo_mensaje.md` tal cual**, sin resumirlo ni reescribirlo: él lo quiere leer exactamente como quedó. Después repetí la pregunta pendiente y esperá su respuesta.
4. **Seguí con lo que él elija.** Las dos opciones que quedaron:
   - **"Sí, registralas"** → agregar las cuatro decisiones (y, si él quiere, las chicas de f1) como cuestiones nuevas en `docs/cuestiones_pendientes.md` (siguiente `CP-NN` libre después del pull), con su referencia a las fuentes, más la entrada en `memoria/changelog.md`.
   - **"Empezá por la 1"** → discutir la decisión 1 (qué hace el micro en las capturas y quién numera las zancadas): problema, opciones con pros y contras, recomendación, y **esperar el OK** antes de escribir un ADR.

## Reglas que siguen valiendo

- Seguí `CLAUDE.md` completo; en particular la **regla de interacción**: explicar y consultar **antes** de decidir. Ninguna de estas decisiones está tomada: son propuestas.
- **Explicá simple.** Tobías pidió explícitamente que las explicaciones sean lo más breves posible pero que se entiendan, con contexto (ver el último mensaje: ese es el tono).
- Nada del repo se modificó en esa conversación, salvo esta carpeta.
- Tobías programa con **otro agente**; en estas sesiones de documentación y diseño no hace falta proponer toolchain ni pasos de programación.

## Resumen en una línea

Nada impide empezar el 16/11 y ninguna de las 13 CP abiertas frena la Fase 1. Pero el recorte de alcance del cronograma (8/11) no llegó a los documentos que lee quien programa, y quedan cuatro decisiones para las dos primeras semanas: (1) qué hace el micro en las capturas y quién numera las zancadas; (2) dónde se marca qué es cada sesión para los experimentos; (3) qué dato del IMU viaja en la muestra; (4) el emparejamiento Bluetooth sin gesto.
