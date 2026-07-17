# Documento de trabajo para el marco teórico

**Proyecto:** Sistema de plantilla inteligente bilateral con sensores FSR e IMU para detección personalizada de anomalías de marcha en pacientes post-stroke, con feedback vibrotáctil en tiempo real e inferencia íntegramente edge.

**Naturaleza del documento:** este es un texto de trabajo, deliberadamente exhaustivo y redundante. Recopila la totalidad de la información relevante sobre cada eje del marco teórico, con citas in-text de cada fuente. A partir de este documento se destilará posteriormente el marco teórico final del anteproyecto, descartando lo accesorio y comprimiendo lo esencial.

**Decisiones de diseño asumidas para este documento:**
- Plantilla **bilateral** (dos dispositivos, uno por pie), lo cual habilita el cálculo directo de índices de simetría inter-extremidad — un eje diferencial en marcha hemipléjica.
- Frecuencia de muestreo objetivo: **100 Hz** para ambos sensores. Es el valor consolidado en la literatura clínica de wearables para marcha: lo suficientemente alto para resolución temporal de eventos (heel-strike, toe-off) y para análisis espectral con bandas útiles hasta 50 Hz, sin imponer carga energética excesiva ni cuello de botella en transmisión inalámbrica. Brasiliano et al. (2026) trabajaron a 128 Hz, Riglet et al. (2023) a frecuencias comparables, Seo et al. (2020) a 100 Hz exactamente, y Nanayakkara et al. (2025) demostraron que bajar a 5 Hz degrada catastróficamente las features del IMU.

---

# Bloque 1 — Contexto clínico: stroke, marcha hemipléjica y necesidad de monitoreo

## 1.1 Epidemiología y carga global del stroke

El stroke o accidente cerebrovascular (ACV) es una enfermedad cerebrovascular caracterizada por la interrupción del aporte sanguíneo cerebral, ya sea por obstrucción arterial (stroke isquémico) o por ruptura vascular con sangrado intraparenquimatoso (stroke hemorrágico). Sus consecuencias funcionales incluyen muerte neuronal localizada y, en consecuencia, deterioro motor, sensorial, cognitivo y del lenguaje, dependiendo del territorio afectado.

A escala global, el stroke ocupa la tercera causa de muerte y la segunda causa de discapacidad permanente en adultos, según el informe sobre prevención y tratamiento del stroke de 2021 citado por Guo et al. (2023) [JMIR mHealth 11:e40416] en el contexto del diseño de su sistema de rehabilitación remota. Los mismos autores reportan que, sólo en China en 2020, la prevalencia estandarizada por edad en mayores de 40 años era de 2.61%, con una incidencia anual de 505.23 por 100.000 habitantes, lo que se traduce en aproximadamente 17.8 millones de pacientes en ese país. Estas cifras subrayan no sólo la magnitud individual del problema, sino su escala poblacional y la presión que genera sobre los sistemas de salud en términos de rehabilitación, dependencia y costos directos e indirectos.

El paper de Brasiliano et al. (2026) [Sci Rep 16:8908] amplía esta perspectiva citando el Heart Disease and Stroke Statistics Report 2024 de la American Heart Association: el stroke constituye un desafío global con implicancias sanitarias y socioeconómicas tanto para el individuo como para la sociedad en conjunto. Selves, Stoquart & Lejeune (2020) — referencia central de la literatura de rehabilitación post-stroke citada por Brasiliano — establecen que el deterioro de la marcha es uno de los factores que más afecta la participación social, la autonomía y la calidad de vida del paciente, motivo por el cual la rehabilitación de la marcha es uno de los aspectos cruciales del manejo post-stroke.

Aproximadamente el **80% de los sobrevivientes de stroke presenta hemiplejia** debido a la pérdida del control central sobre el sistema motor, según Qiu et al. (2018) citado por Chen et al. (2022) [Front Neuroinform 16:1006494]. Esta hemiplejía deriva en coordinación muscular anormal, alteraciones del tono muscular (pain, swelling, fatigue, coordination problems) y un patrón de marcha característico que se conoce como marcha hemipléjica.

## 1.2 Características biomecánicas de la marcha hemipléjica

La marcha post-stroke presenta un conjunto reconocible y consistente de alteraciones biomecánicas. Las más prominentes, según la caracterización integrada de varias fuentes, son:

**Disminución de la velocidad de marcha.** Es el signo más universal: prácticamente todos los pacientes con secuela motora caminan más lento que controles sanos de su edad. Kang (2025) [JMST 9(1):25-35] confirma esta caída global de velocidad en adultos mayores con stroke hemipléjico community-dwelling.

**Asimetría inter-extremidad.** Kang (2025) reporta que en su cohorte de N=16 adultos mayores con stroke (≥65 años), la **asimetría está confirmada en todas las variables de marcha excepto en stride time**. Es decir: step time, stance phase, swing phase, single y double support difieren entre lado parético y no parético, pero la duración total del ciclo (stride time) tiende a igualarse porque el ciclo es por definición sincrónico entre piernas. Esta observación es metodológicamente importante porque indica qué métricas conviene comparar bilateralmente y cuáles no.

**Déficit de propulsión (push-off).** Es uno de los hallazgos clínicos más característicos. Kang (2025) demuestra que el lado parético utiliza predominantemente las regiones laterales del pie (lateral midfoot, lateral forefoot) e **es incapaz de activar las regiones anteromediales** (toes, hallux, medial forefoot). El resultado funcional es un patrón sin propulsión efectiva: el push-off, que requiere flexión plantar potente en terminal stance, se ve drásticamente reducido. Este hallazgo replica lo observado por Sanghan, Leelasamran & Chatpun (2014) en hemipléjicos tailandeses con el sistema Pedar-X, donde las diferencias porcentuales de presión plantar entre grupos llegaron al 30 ± 12%.

**Inversión excesiva del pie afectado (foot inversion / varus deformity).** Ma, Zheng & Lee (2018) [Topics in Stroke Rehab 25(1):20-27] estudiaron específicamente esta deformidad flexible del retropie en N=8 pacientes con stroke, y diseñaron su sistema de biofeedback alrededor de este problema: el pie afectado se evierte poco y se invierte demasiado, lo cual reduce el área de contacto medial con el suelo, desestabiliza el balance en mid-stance y puede precipitar caídas.

**Aumento de la duración del doble apoyo y del stance phase.** Como compensación por la inestabilidad, los pacientes pasan más tiempo en contacto con el suelo con ambos pies simultáneamente, reduciendo el tiempo en single support sobre la pierna parética.

**Reducción del rango de movimiento articular.** Brasiliano et al. (2026) y la literatura de Frontiers Medical Technology (2022) coinciden en que existe reducción de la extensión de cadera en late stance, alteración del peak lateral pelvis displacement, flexión de rodilla reducida y, sobre todo, **disminuida plantarflexión del tobillo en toe-off**, lo que conecta directamente con el déficit de push-off mencionado arriba.

**Aumento de la variabilidad zancada-a-zancada.** Lo demuestra el coeficiente de variación del stance phase, identificado por Brasiliano et al. (2026) entre los tres features más discriminativos para distinguir stroke de control. La variabilidad refleja la pérdida de control fino del patrón motor, que normalmente es altamente reproducible.

## 1.3 Caídas post-stroke como problema clínico

Las caídas en pacientes con stroke son un evento centinela: cada caída aumenta el riesgo de fractura, hospitalización, dependencia y, en cohortes mayores, mortalidad. La intervención preventiva sobre el riesgo de caída tiene por lo tanto un valor clínico desproporcionadamente alto frente a su costo.

Jung et al. (2017) [Ann Rehabil Med 41(3):339-346] desarrollaron y validaron un modelo cuantitativo predictivo de caídas post-stroke utilizando el sistema Balance Master a los 3 meses post-stroke en N=71 pacientes (45 hombres, 45 con stroke isquémico). El modelo se construyó sobre dos parámetros derivables de plataformas de fuerza dual:

- **Weight Bearing Asymmetry (WBA):** asimetría en la distribución de peso entre extremidades. Su valor medio en la cohorte fue 17.18% ± 13.10%, considerablemente mayor que el de adultos sanos.
- **Postural Sway Velocity (PSV):** velocidad de oscilación postural medida en condiciones progresivamente más exigentes para el control postural. Los valores reportados fueron, en grados por segundo: 0.66 ± 0.37 ojos abiertos superficie firme, 0.89 ± 0.75 ojos cerrados superficie firme, 1.45 ± 1.09 ojos abiertos superficie blanda, y 3.10 ± 1.76 ojos cerrados superficie blanda (PSV_ECSS).

El modelo de regresión logística final fue:

> Riesgo de caída post-stroke = −2.848 + 1.878 × PSV_ECSS + 0.154 × (edad ≥ 65 ? 1 : 0)

Los dos predictores significativos resultaron ser el control postural deteriorado en condición ECSS y la edad mayor a 65 años. Este modelo es relevante para el presente proyecto por dos razones: (a) define qué parámetros biomecánicos son clínicamente significativos para evaluar riesgo de caída, y (b) ofrece un coeficiente cuantitativo concreto que el sistema instrumentado podría calcular y reportar como output clínico.

La relevancia se acentúa al considerar el trabajo de Herbers et al. (2024) [NPJ Parkinsons Dis 10:67], quienes demostraron que en pacientes con Parkinson (problemática análoga en términos de control postural), monitoreo plantar permitía clasificar fallers vs non-fallers con AUC = 0.91 ± 0.08, utilizando un conjunto de features derivadas del Center of Pressure (COP). Aunque la patología es distinta, las características de la inestabilidad postural y los marcadores plantares son transferibles al problema post-stroke.

## 1.4 Recuperación funcional, predictores y heterogeneidad inter-paciente

La recuperación post-stroke es altamente variable entre individuos. Un trabajo de 2025 publicado en Journal of NeuroEngineering and Rehabilitation [DOI 10.1186/s12984-025-01548-5] enroló N=237 pacientes con stroke isquémico de circulación anterior aguda y desarrolló un modelo predictivo de recuperación de la marcha basado en machine learning. Utilizando LASSO regression para feature selection sobre 31 características médicas iniciales, identificaron diez predictores significativos entre los cuales figuran edad, género, hiperintensidades periventriculares de sustancia blanca (PVWMH), Montreal Cognitive Assessment (MoCA), y National Institutes of Health Stroke Scale (NIHSS). El mejor modelo combinó Random Survival Forest con interpretabilidad SHAP.

Este trabajo es importante para el marco teórico por dos razones: (a) confirma la naturaleza multifactorial y heterogénea de la recuperación motora post-stroke, lo que justifica el enfoque per-paciente del presente proyecto, y (b) muestra que herramientas de aprendizaje automático con interpretabilidad clínica (SHAP) están ya validadas para predecir outcomes funcionales en stroke, lo que abre la puerta a integrar predicción de recuperación con detección de anomalías en futuras iteraciones del sistema.

## 1.5 Limitaciones de la rehabilitación tradicional y oportunidad del monitoreo domiciliario

La rehabilitación post-stroke tradicional se realiza en clínicas u hospitales, con sesiones supervisadas por kinesiólogos. Tiene tres limitaciones fundamentales:

1. **Cobertura temporal limitada.** El paciente recibe atención durante una o dos horas por sesión, varias veces por semana; el resto del tiempo no es monitorizado. La marcha en condiciones reales del hogar puede diferir sustancialmente de la marcha en clínica.

2. **Evaluación subjetiva.** Las escalas clínicas (Brunnstrom Recovery Stage, Fugl-Meyer Assessment, Berg Balance Scale, Barthel Index, Functional Ambulation Classification) dependen del observador. Chen et al. (2022) [Front Neuroinform 16:1006494] señalan que los resultados del método observacional dependen fuertemente del nivel de observación y experiencia del clínico, y que el proceso de evaluación impacta el confort del paciente y causa fatiga física y mental. La evaluación, por construcción, no puede ser continua ni en tiempo real.

3. **Carga logística para el paciente.** Pacientes con hemiplejia tienen dificultad para movilizarse, y el desplazamiento frecuente entre hogar y centro de rehabilitación constituye una barrera significativa de acceso. Chen et al. (2022) lo formulan en estos términos: las herramientas tradicionales "no permiten una evaluación inmediata ni feedback del problema de marcha, y obligan al paciente a viajar entre el hogar y el hospital con alta frecuencia, lo cual es una carga para pacientes que ya tienen dificultad para caminar".

Matthews et al. (2018) [Front Neurol 9:561] demostraron empíricamente, para una patología análoga en términos de cronicidad y dependencia funcional (esclerosis múltiple), que el monitoreo remoto domiciliario con un único acelerómetro Axivity AX3 durante 7 días podía proveer estimaciones de velocidad de marcha con R = 0.98 frente a referencia clínica, siempre y cuando se utilizaran modelos personalizados por paciente. La extrapolación al stroke es directa: el monitoreo domiciliario continuo con wearable es técnicamente factible y clínicamente significativo.

Guo et al. (2023) [JMIR mHealth 11:e40416] llevaron este principio a un ensayo controlado piloto aleatorizado (RCT) específico para stroke, con un sistema wearable de entrenamiento de rehabilitación remota basado en tareas de interacción humano-computadora, mostrando que el modelo sin supervisión médica directa puede ser seguro y efectivo. Este trabajo posiciona la tele-rehabilitación instrumentada como un paradigma viable y validado clínicamente.

---

# Bloque 2 — Análisis cuantitativo de marcha: estado del arte de las tecnologías de medición

## 2.1 El gold standard: motion capture óptico con marcadores reflexivos

El gold standard universalmente aceptado en biomecánica de marcha es el motion capture óptico con marcadores reflexivos pasivos (sistemas tipo Vicon, Qualisys, OptiTrack) combinado con plataformas de fuerza embebidas en el piso. Permite reconstruir la cinemática 3D completa del cuerpo (posiciones articulares, ángulos, velocidades) con precisión submilimétrica y, mediante dinámica inversa, calcular momentos articulares y fuerzas musculares estimadas. Es la referencia contra la cual se valida cualquier otra tecnología de medición de marcha.

Sus limitaciones, descritas exhaustivamente en la literatura, son: alto costo de equipamiento e instalación (decenas a cientos de miles de dólares); requerimiento de espacio dedicado con cámaras múltiples calibradas; necesidad de personal entrenado para colocar los marcadores, calibrar el sistema y procesar los datos; tiempo de setup significativo por sujeto (frecuentemente >30 minutos); imposibilidad de medir fuera del laboratorio en condiciones ecológicas; y limitación del volumen de captura a un área restringida. Cerfoglio et al. (2025) [Biomechanics 5(4):88] resumen estas limitaciones en el contexto de su revisión sobre alternativas markerless.

## 2.2 Alternativa markerless basada en smartphone: OpenCap y OpenSim

Cerfoglio et al. (2025) realizaron una revisión narrativa exhaustiva de la validación clínica de OpenCap, plataforma open-source desarrollada por la Universidad de Stanford que estima cinemática y cinética 3D usando solamente dos videos de smartphone iOS y un modelo musculoesquelético basado en OpenSim. El setup típico consiste en dos iPhones o iPads colocados en ángulos oblicuos (30°-45°) a 1.5-3 metros del sujeto, a 1.3-1.5 metros de altura, grabando a 60 Hz (uno de los nueve estudios revisados usaba 120 Hz) con calibración mediante checkerboard.

El pipeline es: estimación de pose 2D mediante HRNet u OpenPose → triangulación 3D → predicción de marcadores anatómicos vía LSTM → modelado biomecánico en OpenSim → cinemática y dinámica inversa.

Los hallazgos de validación, sintetizados a partir de los nueve estudios incluidos:

- En marcha sana, RMSE típico de 4-6° en cinemática articular, generalmente por debajo del umbral clínico de 5°. Errores medios absolutos de aproximadamente 4.5° (Uhlrich et al.).
- Errores en momentos articulares <1.5% del producto peso × estatura. Errores en fuerzas de reacción del suelo <7% del peso corporal.
- Errores en step length de aproximadamente 1.2 cm y en cadencia <3 pasos/min.
- Plano frontal (lista pélvica, ab/aducción de cadera): errores más bajos. Plano sagital: estable, errores ligeramente mayores pero con ROM más amplio, robusto clínicamente. Plano transverso (rotación interna/externa de cadera): el menos consistente.
- En marcha patológica, los errores son sistemáticamente mayores y frecuentemente exceden el umbral de 5°, con las mayores desviaciones en crouch gait y circumduction.
- La variabilidad intertrial es 6.6%-22% mayor que con marker-based, requiriendo promediar >10 ciclos de marcha por lado para obtener mediciones confiables. SEM ≈ 2°, MDC ≈ 6°.

Min et al. (2026) [Applied Sciences 16(3):1406] aplicaron OpenCap+OpenSim a N=4 pacientes pediátricos con trastornos neurológicos de marcha contra datos normativos de N=30 sanos, demostrando que el análisis individualizado mediante Z-scores por fase del ciclo, heatmaps por paciente y overlays cinemáticos puede detectar anormalidades clínicamente significativas en cada paciente individual, incluso cuando los análisis grupales con Statistical Parametric Mapping no muestran diferencias significativas (p ≥ 0.05). Encontraron desviaciones específicas como flexión excesiva de cadera y rodilla en swing, déficit de extensión de rodilla en mid-stance, extensión terminal de cadera reducida y plantarflexión disminuida en late stance, con varias desviaciones superando |2-5| SD del dataset normativo.

Estas conclusiones validan dos puntos clave para el marco teórico: el análisis individualizado tiene valor diagnóstico incluso en cohortes pequeñas y heterogéneas; y el smartphone como sustrato de medición es viable pero tiene techo de precisión en marcha patológica. Para el presente proyecto, OpenCap se posiciona como herramienta complementaria de referencia o validación en sesiones presenciales, pero no resuelve el monitoreo continuo domiciliario porque requiere setup activo de cámaras.

## 2.3 Alternativa de pasarela instrumentada: GaitRite

El sistema GaitRite es un segundo gold standard ampliamente usado en gait labs y clínicas, particularmente para parámetros espacio-temporales. Consiste en una pasarela instrumentada con miles de sensores de presión embebidos que registra automáticamente la trayectoria de cada pisada del sujeto durante el paso por la pasarela. Es el sistema más utilizado para validar smart insoles, como se observa en Lim et al. (2025) [PTRS 14(3):282-292], quienes lo emplean explícitamente como referencia.

Sus limitaciones frente a un wearable: cobertura espacial limitada a la longitud de la pasarela (típicamente 4-10 metros), imposibilidad de uso fuera de la clínica, y costo no trivial. Su ventaja: dado que mide directamente presión planta a piso sin necesidad de modelado, los parámetros espacio-temporales obtenidos son extremadamente confiables.

## 2.4 Wearables: la categoría disruptiva

Los wearables han emergido en la última década como la tercera vía, complementaria a los gold standards de laboratorio. Su propuesta de valor es: portabilidad, costo asequible, capacidad de recolección de datos en vida real fuera del laboratorio, capacidad de monitoreo continuo, y, en sistemas modernos, procesamiento on-device en tiempo real.

Las arquitecturas principales son:

**Wearables de muñeca o cintura.** Matthews et al. (2018) [Front Neurol 9:561] usaron un único Axivity AX3 (acelerómetro triaxial) en N=32 pacientes con esclerosis múltiple durante 7 días en el hogar, derivando velocidad de marcha con modelos personalizados (R = 0.98 vs referencia clínica). Demuestra que un wearable simple puede dar mediciones clínicas válidas cuando se entrena per-paciente.

**Wearables en tibia o muslo.** Brasiliano et al. (2026) usaron MIMUs (acelerómetro + giroscopio + magnetómetro) en tibias, esternón, lower back y frente; identificaron stride speed y CoV de stance como dos de los tres features que mejor discriminan stroke de sano. La posición tibial es estándar para detección robusta de eventos de marcha.

**Wearables en el pie o calzado (smart shoes / smart insoles).** Es la categoría en la que se enmarca el proyecto. Tiene la ventaja de la proximidad a la interfaz pie-piso, lo que la hace especialmente adecuada para medir simultáneamente presión plantar y cinemática del pie distal. Sus referentes principales son:

- **DSPro de Zhortech**, validada por Riglet et al. (2023) [Sensors 23(19):8155] en N=30 sanos contra motion capture. Resultados: ICC > 0.90 para cinco parámetros espacio-temporales clave (speed, cadence, stride length, stride time, stance time), con buena validez (r > 0.75) en swing time, ancho de zancada, doble apoyo, foot progression angle y plantar flexion. No validados: loading time en treadmill a velocidad lenta (ICC < 0.70), minimum toe clearance en overground (ICC < 0.50).

- **On-Foot Gait Lab** [ACS Applied Engineering Materials 2025, DOI 10.1021/acsaenm.5c00834] integra sensores piezocapacitivos electrospun (capa dieléctrica nanofibrosa de PVAc-grafeno) con IMU en plantillas comerciales modificadas. Es la combinación exacta del presente proyecto (presión + IMU bajo el pie con wireless), con foco en monitoreo domiciliario y Parkinson.

- **Smart insole genérica de Lim et al. (2025)** [PTRS 14(3):282-292], validada en N=25 sanos contra GaitRite. Stride time alcanzó ICC = 0.97 izquierdo y 0.90 derecho. Confirma que la categoría smart insole es clínicamente viable.

- **WI-SHOE** [CORDIS Project ID 605777], proyecto FP7 europeo (2014-2015, presupuesto €1.5M) que desarrolló un calzado wearable wireless con doble propósito (deporte + medicina, incluyendo stroke). Sirve como antecedente histórico del concepto.

## 2.5 Parámetros espacio-temporales de marcha clínicamente relevantes

A lo largo de las fuentes revisadas, un conjunto consolidado de parámetros espacio-temporales aparece como núcleo del análisis cuantitativo de marcha:

- **Velocidad de marcha** (gait speed): metros por segundo. Es probablemente el predictor pronóstico más universal en marcha clínica. Brasiliano et al. (2026) la incluye en su top-3 features.
- **Cadencia**: pasos o ciclos por minuto.
- **Stride length / step length**: longitud de zancada (ipsilateral, heel-strike a heel-strike del mismo pie) y de paso (contralateral, heel-strike a heel-strike de pies opuestos).
- **Stride time / step time**: duraciones correspondientes.
- **Stance phase duration**: tiempo en contacto con el suelo, expresado en segundos absolutos o como porcentaje del ciclo (típicamente 60-62% en sanos, frecuentemente prolongado en patológicos).
- **Swing phase duration**: tiempo en vuelo, complementario al stance (38-40% en sanos).
- **Double support time**: tiempo en que ambos pies contactan el suelo simultáneamente, una vez por ciclo en cada transición. Aumenta en patológicos por compensación de estabilidad.
- **Single support time**: tiempo en que sólo un pie contacta el suelo.
- **Foot progression angle**: ángulo del eje del pie respecto a la dirección de progresión, indicador de marcha en in/out toeing.
- **Symmetry indices**: cocientes o diferencias normalizadas entre lado izquierdo y derecho de cualquier parámetro temporal o espacial.
- **Coefficient of variation (CoV)**: variabilidad zancada-a-zancada de cualquier parámetro, calculada típicamente sobre ventanas de 10+ ciclos consecutivos.

Riglet et al. (2023) muestran que los cinco primeros (speed, cadence, stride length, stride time, stance time) son los más robustamente medibles con IMU embebido en plantilla, todos con ICC > 0.90. Lim et al. (2025) replican estos hallazgos con un dispositivo de arquitectura distinta. Esto consolida estos cinco como el núcleo mínimo no-negociable de cualquier sistema serio de smart insole.

---

# Bloque 3 — Sensórica: principios y fundamentos de FSR e IMU para marcha

## 3.1 Force Sensitive Resistors (FSR): principio, propiedades y limitaciones

Los FSR son sensores de presión resistivos polímericos cuyo principio físico es la variación de resistencia eléctrica en respuesta a la compresión. Una capa de polímero conductivo (típicamente carbón sobre matriz polimérica) se interpone entre dos electrodos. Cuando no hay presión, la resistencia es muy alta (megaohms); al aplicar presión, las partículas conductoras se aproximan, formando caminos conductivos y la resistencia cae a unidades o decenas de kΩ. La lectura se realiza típicamente con un divisor de tensión: el FSR se conecta en serie con una resistencia fija conocida, y el punto medio se lee por un convertidor analógico-digital (ADC) del microcontrolador.

Características relevantes:
- **No linealidad de la curva fuerza-resistencia**: la respuesta sigue una ley aproximadamente logarítmica, no lineal. Esto debe ser corregido por software mediante una curva de calibración específica por sensor.
- **Histéresis**: la respuesta al ciclo de carga y descarga difiere ligeramente, lo que introduce error en mediciones dinámicas.
- **Drift temporal**: bajo carga sostenida, la resistencia tiende a derivar lentamente.
- **Vida útil finita** en ciclos de carga.
- **Sensibilidad al área de aplicación**: una carga concentrada genera respuesta distinta a la misma carga distribuida.

El proyecto utiliza FSRs Interlink FSR 402, descriptos también por Nanayakkara et al. (2025) [Springer MITA 2025] en su plantilla de 8 sensores: 13 mm de diámetro, rango 0.5-150 N, tiempo de respuesta <3 ms. Estos parámetros son adecuados para captar las fuerzas pico de la marcha (típicamente 0.8-1.2 veces el peso corporal por pie en cada pisada).

## 3.2 Cantidad y posicionamiento de FSRs

La literatura presenta un rango muy amplio de configuraciones, desde 2 sensores hasta arrays densos de 22-32 sensores por plantilla.

- **Configuraciones de baja densidad (2-4 sensores):** se eligen estratégicamente para cubrir las regiones más informativas. Ma, Zheng & Lee (2018) usaron sensores en medial forefoot y lateral forefoot específicamente para captar el desbalance medial-lateral del antepié, eje de la inversión patológica del pie post-stroke. Pappas et al. (2001), referencia clásica citada por Nanayakkara et al. (2025), demostraron fiabilidad de detección de fases de marcha con sensores binarios en heel, primer metatarsiano, quinto metatarsiano y hallux.

- **Configuraciones de densidad intermedia (5-8 sensores):** Nanayakkara et al. (2025) usan 8 FSRs derivados de un mapeo de 30 zonas anatómicas, seleccionando las 8 ubicaciones óptimas mediante un sistema de coordenadas estandarizado. Seo et al. (2020) [JMIR Mhealth 8:e22208] en su estudio piloto con N=hemipléjicos post-stroke usan 8 sensores. Es una densidad razonable para reconstruir distribución plantar sin saturar el sistema.

- **Configuraciones de alta densidad (22-32 sensores):** Science Advances 2025 (DOI 10.1126/sciadv.adu1598) reporta 22 sensores con celdas solares como fuente de energía autónoma. Estos arrays permiten reconstrucción 2D completa de la trayectoria del Center of Pressure.

Para el presente proyecto, **la elección de 3-4 FSR bilaterales se justifica triplemente**:

1. **Cobertura biomecánica focalizada en lo crítico.** Kang (2025) demostró que en hemiplejía las anomalías plantares clave están en las regiones anteromediales (déficit de push-off) y en la distribución medial-lateral (foot inversion). Tres a cuatro sensores ubicados estratégicamente en (a) hallux/primer metatarsiano, (b) quinto metatarsiano, (c) talón, y opcionalmente (d) mediopié, cubren los marcadores patológicos esenciales.

2. **Restricciones de procesamiento on-edge.** Trabajar con vectores de baja dimensionalidad simplifica el preprocesamiento, reduce los ADC necesarios y libera ancho de banda en el microcontrolador. El RP2350 tiene cuatro ADCs disponibles.

3. **Precedente clínico exitoso.** Ma, Zheng & Lee (2018) lograron mejoras significativas en biomecánica de marcha hemipléjica con sistemas de muy baja densidad sensorial (esencialmente medial vs lateral forefoot), demostrando que la ecuación "más sensores = mejor desempeño clínico" no es universal y depende del problema target.

Es preciso aclarar que con 3-4 FSRs **no se puede reconstruir el Center of Pressure 2D completo**, pero sí una aproximación 1D del componente medio-lateral mediante una suma ponderada de los sensores según su coordenada lateral conocida. Esta aproximación es funcional porque, como muestra Herbers et al. (2024), la dirección medio-lateral es justamente la que concentra la información discriminativa de inestabilidad postural y riesgo de caída.

## 3.3 Sensores piezocapacitivos como alternativa moderna

El paper de ACS Applied Engineering Materials 2025 [DOI 10.1021/acsaenm.5c00834], "On-Foot Gait Lab", introduce una alternativa de sensórica de presión basada en nanofibras electrospun de PVAc-grafeno funcionando como capa dieléctrica de un sensor capacitivo. La variación de capacitancia al comprimirse la capa dieléctrica nanofibrosa es lineal en mayor rango que el FSR resistivo, menos sensible a drift, y mecánicamente más flexible. Combina estos sensores con IMU integrado en plantillas comerciales modificadas, comunicación wireless, y enfoque clínico en Parkinson y monitoreo domiciliario.

Para el marco teórico, esta referencia es relevante como **comparación de alternativas y posicionamiento de la elección de FSR**. La elección de FSR sobre piezocapacitivo se fundamenta en: madurez tecnológica, disponibilidad comercial (Interlink FSR 402 es un commodity de bajo costo), facilidad de integración con microcontroladores estándar (ADC), y experiencia previa en literatura clínica extensa. La piezocapacitiva es una vía futura de mejora tecnológica.

## 3.4 Inertial Measurement Units (IMU): definición y composición

Un IMU es un dispositivo de medición inercial que integra como mínimo un acelerómetro triaxial y un giroscopio triaxial, opcionalmente complementados por un magnetómetro triaxial (configuración 9-DOF o MIMU — magneto-inertial measurement unit). Brasiliano et al. (2026) usaron MIMUs OPAL de APDM Wearable Technologies con rangos de ±6g, ±1500°/s y ±6 Gauss a 128 Hz de sampling.

- **Acelerómetro:** mide aceleración lineal incluyendo la componente gravitatoria. En reposo, lee 1g en el eje vertical. Durante la marcha, los picos de aceleración pueden superar 5g en el momento del heel-strike.
- **Giroscopio:** mide velocidad angular sobre los tres ejes ortogonales. Durante swing, la velocidad angular del pie en el plano sagital alcanza cientos de grados por segundo.
- **Magnetómetro:** mide intensidad del campo magnético local; permite estimar orientación absoluta (heading) cuando se combina con los anteriores en algoritmos de fusión sensorial, pero es sensible a interferencias magnéticas (objetos ferromagnéticos cercanos).

La comunicación con el microcontrolador es típicamente por I²C (o SPI a tasas más altas), con direcciones de esclavo configurables.

## 3.5 Posicionamiento óptimo del IMU en el pie

Eskofier et al. (2020) [Sensors 20(19):5705] abordaron específicamente este problema en N=29 sujetos corredores con motion capture como ground truth. Compararon cuatro posiciones de IMU mounted en zapatilla de running (caña, lengüeta, lateral, integrado en suela bajo el arco) y evaluaron la precisión de seis parámetros espacio-temporales relacionados con running. Sus conclusiones, replicables al contexto de marcha:

- Los datos crudos del IMU difieren significativamente según la posición del sensor.
- La precisión de los parámetros derivados depende del posicionamiento.
- **La posición óptima es una cavidad en la suela del calzado, bajo el arco del pie.** Esta ubicación produce datos crudos más adecuados para reconstruir la trayectoria del pie durante la zancada porque minimiza el ruido por golpes laterales y la oscilación de partes blandas, manteniendo al sensor solidario con el segmento rígido del pie.

Esta recomendación es directamente aplicable al diseño del presente proyecto: el IMU se coloca en una cavidad bajo el arco mediante diseño mecánico apropiado de la plantilla.

## 3.6 El problema fundamental del drift en IMUs y su tratamiento

Cualquier IMU presenta drift acumulativo en la integración de sus señales para estimar posición u orientación. El error físico se compone de bias inicial, ruido térmico, sensibilidad cruzada entre ejes, e interferencias térmicas. La integración numérica de aceleración para obtener velocidad y luego posición amplifica catastróficamente estos errores: errores de pocos mg en aceleración resultan en derivas de metros tras unos segundos de integración.

Las soluciones algorítmicas convencionales son:

**Zero-Velocity Update (ZUPT).** Aprovecha el hecho de que durante la fase de stance, el pie está aproximadamente estacionario respecto al suelo. En esos instantes, se asume velocidad cero y se corrige el bias del giroscopio y acelerómetro recalibrando contra esta condición. ZUPT funciona razonablemente bien en marcha lenta o caminata, pero degrada en velocidades altas o en running donde la fase de stance es muy breve y no enteramente estática.

**Modified Strap-Down Integration (MSDI)**, propuesto y validado por Falbriard et al. (2020) [Front Bioeng Biotechnol 8:65]. Es una variante mejorada que incorpora la estimación de la aceleración del centro articular (Joint Center Acceleration, JCA) en un modelo de dos segmentos del pie (rearfoot y forefoot). En N=26 corredores a 8, 12 y 16 km/h validados contra motion capture óptico, MSDI logró precisión del orden de 0.4 ± 3.8° en mean stance y 2.0 ± 5.9° antes del initial contact, superando a ZUPT en running.

**MFD-GED (Multi-sensor Fusion with Dynamic Gait Event Detection)**, propuesto por Shen et al. (2026) [Front Bioeng Biotechnol 13:1714473]. Es un marco refinado de detección de eventos basado en fusión de features de aceleración y velocidad angular, validado en N=15 corredores sanos contra MoCap + plataformas de fuerza. Reportan concurrent validity con r = 0.743-0.991 y ICC = 0.741-0.990, con reducción significativa del bias temporal (de 0.057 s a 0.001 s en contact time, p < 0.01, Cohen's d = 1.62-2.20) y de peak vertical Ground Reaction Force (de −0.310 BW a 0.159 BW, p < 0.01, Cohen's d = 1.45).

Para el presente proyecto, la estrategia de compensación de drift será una combinación pragmática: ZUPT como mecanismo base, validado durante la fase de stance detectada por los FSRs (que aportan ground truth de contacto con el suelo); MSDI o MFD-GED como refinamiento si la marcha objetivo incluye velocidades altas o patrones atípicos.

## 3.7 Fusión sensorial FSR + IMU: complementariedad

La complementariedad entre FSR e IMU en el contexto de marcha es estructural:

- El **FSR mide la interfaz pie-piso**: cuándo se establece contacto, cuándo se pierde, cómo se distribuye la fuerza espacialmente. Es directo, robusto al drift, e informativamente denso durante la fase de stance.
- El **IMU mide la cinemática del pie**: cómo se mueve en el aire, qué orientación tiene en cada instante del ciclo, qué aceleraciones experimenta. Es directo durante swing, complementario durante stance.

La fusión sensorial explota esta complementariedad. Pan et al. (2023) [IEEE Sensors J 23(11):12008-12017] aplican exactamente esta combinación para evaluación de marcha hemipléjica, recolectando datos de ángulos articulares y de presión plantar de pacientes con stroke y sujetos sanos, y correlacionándolos con el score del Mini Balance Evaluation System (Mini-BES). El paper de ACS On-Foot Gait Lab (2025) replica la arquitectura. Nanayakkara et al. (2025) muestran que a sampling rate bajo (5 Hz), las features de FSR mantienen macro-F1 de 0.915 mientras que las del IMU degradan significativamente, demostrando que la presión es más informativa que el IMU para detección de fases de marcha en condiciones de bajo recurso computacional.

---

# Bloque 4 — Detección de eventos y segmentación del ciclo de marcha

## 4.1 El ciclo de marcha y sus fases

El ciclo de marcha humano se define convencionalmente desde el heel-strike de una pierna hasta el siguiente heel-strike de la misma pierna. Se divide en dos fases mayores y siete sub-fases:

- **Stance phase (60-62% del ciclo en marcha sana):**
  - Heel-strike o initial contact: el talón toca el suelo.
  - Foot-flat o loading response: toda la planta entra en contacto.
  - Mid-stance: el peso pasa sobre el pie de apoyo, la pierna contralateral está en swing.
  - Heel-off o terminal stance: el talón se levanta, inicia el push-off.
  - Pre-swing o toe-off: el pie deja el suelo.
- **Swing phase (38-40% del ciclo en marcha sana):**
  - Initial swing: el pie acelera hacia adelante.
  - Mid-swing: pico de elevación del pie.
  - Terminal swing: desaceleración previa al próximo heel-strike.

La unidad fundamental de análisis es la zancada (stride): el ciclo completo. Cada feature de marcha se calcula a nivel de zancada y luego se promedia, varía o agrega sobre múltiples zancadas. Como se mencionó, Cerfoglio et al. (2025) recomiendan promediar al menos 10 zancadas por lado para mediciones confiables.

## 4.2 Algoritmos clásicos de detección de eventos

La detección automática de eventos (especialmente heel-strike y toe-off) es el paso crítico que convierte una señal continua en una secuencia segmentada de zancadas analizables. Existen tres familias principales:

**Basados en presión plantar (FSR).** Son los más directos: el heel-strike se detecta cuando la fuerza en el sensor del talón cruza un umbral creciente; el toe-off cuando la fuerza en sensores anteriores cae por debajo de un umbral decreciente. Park et al. (2020) y Pappas et al. (2001), citados por Nanayakkara et al. (2025), son referencias clásicas. La fiabilidad es alta cuando hay sensores en talón y antepié; con sólo 3-4 FSRs estratégicamente ubicados, la detección sigue siendo robusta.

**Basados en velocidad angular del IMU.** El método estándar identifica heel-strike como el mínimo local en la velocidad angular sagital del pie posterior al pico de swing. Toe-off como el cruce por umbral creciente al inicio del swing. Es robusto en marcha sana pero degrada en patrones patológicos con variaciones marcadas de velocidad y geometría del pie.

**Métodos fusion / multi-sensor refinados.** MFD-GED de Shen et al. (2026) ya descripto, y métodos similares, fusionan acelerómetro y giroscopio para reducir falsos positivos y mejorar la precisión temporal de los eventos. En la implementación práctica del presente sistema, conviene cruzar la detección por FSR (ground truth de contacto) con la confirmación por IMU (cinemática del pie en torno al evento), aceptando el evento sólo cuando ambos canales coinciden dentro de una ventana temporal definida.

## 4.3 Segmentación bilateral y sincronización

En un sistema bilateral, cada plantilla detecta sus propios eventos independientemente. La sincronización temporal entre ambos dispositivos es esencial para calcular features de simetría inter-extremidad y de doble apoyo. Existen tres alternativas:

- **Sincronización por hardware** (un master genera reloj para slave): requiere cable entre plantillas, lo cual es operativamente engorroso.
- **Sincronización por radio** (BLE timestamps): suele tener jitter de decenas de milisegundos, suficiente para análisis offline pero problemático en aplicaciones de tiempo real con feedback inmediato.
- **Sincronización por evento conocido** (ej. un golpe sincronizado al inicio de la sesión, o handshake explícito): pragmática y suficiente para análisis de marcha donde la resolución temporal requerida está en el orden de 10-20 ms.

Para el presente proyecto la sincronización por evento explícito al inicio de cada sesión, con corrección de drift de relojes cada ~30 segundos vía intercambio BLE, es la opción más razonable.

---

# Bloque 5 — Features de marcha: estado del arte para detección de anomalías

Este es el bloque más extenso del documento, dada su centralidad para el proyecto. Se presenta primero el contexto teórico, luego la evidencia empírica organizada por estudios, y finalmente la lista consolidada de features recomendados para el sistema bilateral con 3-4 FSR + IMU.

## 5.1 Marco conceptual: ¿qué es un feature de marcha?

Un feature de marcha es una variable escalar (o, en algunos casos, vectorial) derivada de las señales crudas de los sensores que captura un aspecto biomecánico, temporal o de patrón del movimiento. La gran ventaja de trabajar con features extraídas — frente a alimentar directamente las señales crudas a los algoritmos de clasificación — es triple: reducción dramática de la dimensionalidad, interpretabilidad clínica (cada feature tiene significado biomecánico) y compatibilidad con algoritmos de machine learning clásicos ligeros, viables en hardware embebido.

Chen et al. (2022) [Front Neuroinform 16:1006494] enfatizan este punto explícitamente al describir su pipeline de selección de features para evaluación interpretable del estadío de Brunnstrom: el procedimiento de Sequential Backward Selection sobre features extraídas "no crea nuevas combinaciones (como Principal Component Analysis o Linear Discriminant Analysis); más bien, sólo conserva las features relevantes del dataset original, haciendo el procedimiento utilizable y los resultados interpretables en entornos clínicos".

Los features se agrupan convencionalmente en cinco dominios:

1. **Espacio-temporales:** velocidad, longitud, duraciones de fase.
2. **De variabilidad:** coeficiente de variación de los anteriores, calculado sobre múltiples ciclos.
3. **De simetría:** índices que comparan miembros izquierdo y derecho.
4. **De estabilidad y suavidad:** RMS, jerk, coefficient of attenuation, harmonic ratio.
5. **De frecuencia y entropía:** espectro de potencia por bandas, entropía espectral, sample entropy.

## 5.2 Evidencia empírica primaria: Brasiliano et al. (2026)

El estudio de Brasiliano, Orejel-Bustos, Belluscio, Cereatti, Della Croce, Trabassi, Salis, Tramontano, Buzzi, Vannozzi y Bergamini publicado en Scientific Reports volumen 16, artículo 8908 (DOI 10.1038/s41598-026-43666-7) constituye la referencia empírica más reciente y robusta sobre identificación de features discriminativos en marcha post-stroke. Por su importancia, se describe en profundidad.

**Diseño:** N=85 pacientes con stroke (45 hombres, 40 mujeres; edad 57 ± 16 años; masa 71 ± 12 kg; estatura 1.69 ± 0.09 m) más N=97 controles sanos (50 hombres, 47 mujeres; edad 48 ± 12 años; masa 70 ± 18 kg; estatura 1.67 ± 0.08 m), apareados por edad y sexo. Pacientes en fase subaguda o crónica, capaces de caminar sin asistencia (Functional Ambulation Classification ≥ 3). Excluidos: déficits cognitivos (MMSE > 4), neglect espacial severo, afasia severa, comorbilidades neurológicas/ortopédicas/cardíacas. Aprobación ética Santa Lucia CE/AG4/PROG.383-11.

**Setup experimental:** test de 10 metros (10-MWT) a velocidad autoseleccionada, mínimo 3 trials por sujeto. Cinco MIMUs sincronizadas (OPAL, APDM Wearable Technologies, Portland, USA) con acelerómetro, giroscopio y magnetómetro triaxiales, rangos ±6g, ±1500°/s, ±6 Gauss, sampling 128 Hz. Ubicaciones: frente (FH, sobre el hueso occipital cerca de la sutura lambdoidea), esternón (ST), lower back (LB, a nivel L4-L5), y ambas tibias laterales sobre los maléolos. Los autores justifican la configuración de 5 sensores como balance entre factibilidad clínica y capacidad de computar todos los dominios de features: los sensores tibiales son requeridos para segmentación de zancadas y features espacio-temporales y de simetría; lower back provee referencia trunk; esternón y cabeza habilitan medidas de upper body.

**Preprocesamiento:** alineación a frame anatómico (AP, ML, CC) durante la fase estática, filtrado pasa-bajos Butterworth de segundo orden con cutoffs 10 Hz para acelerómetro y 6 Hz para giroscopio.

**Eventos detectados:** desde velocidad angular ML de los sensores tibiales; velocidad y features espaciales calculados por integración forward-backward con complementary filter y zero-velocity update.

**Pipeline de features:** se calcularon 79 features iniciales organizados en dominios. Aquí están en detalle:

***Espacio-temporales (12 features iniciales):*** Stride frequency, stride speed, stride length, stride duration, stance speed, stance length, stance duration, swing speed, swing length, swing duration, double support duration, single support duration.

***Stability features (calculadas sobre cada zancada):*** Root Mean Square (RMS) de las señales de aceleración de LB, ST y FH. Definición: RMS = √(Σ x² / n) donde x son los valores de aceleración y n el número de muestras de la zancada. Coefficient of Attenuation (COA) calculado entre segmentos: LB→ST, LB→FH, ST→FH, según la fórmula COA = (1 − RMS_upper / RMS_lower) × 100. Mide cuánto se atenúa la oscilación entre dos puntos del cuerpo a medida que se asciende por la cadena cinemática.

***Symmetry features:*** Improved Harmonic Ratio (IHR) calculado de las señales de aceleración de LB, ST y FH sobre cada zancada. Fórmula: IHR_n = Σ P_i^I / Σ (P_i^I + P_i^E), donde P_i^I y P_i^E son la potencia de los n harmónicos intrínsecos y extrínsecos considerados. Symmetry Angle (SA), calculado sobre features espacio-temporales pareados izquierda-derecha: SA = ((45° − arctan(X_left / X_right)) / 90°) × 100.

***Smoothness features:*** Log-Dimensionless Jerk (LDLJ) de aceleración y velocidad angular de LB, ST y FH. Fórmula: LDLJ = −ln((t₂−t₁) · max(‖x(t)‖) · ∫|x′(t)|² dt). Mide la suavidad de la trayectoria penalizando los cambios bruscos.

***Variability features:*** Coefficient of Variation (CoV) de cada feature espacio-temporal, calculado sobre las zancadas del trial.

**Selección de features:** procedimiento multi-etapa:
1. Test de Shapiro-Wilk para distribución; según resultado, t-test o Mann-Whitney U para identificar features con diferencia significativa stroke vs sano. Pasaron 60 features.
2. Análisis de correlación de Pearson para eliminar multicolinealidad: para r > 0.5, se conservaba la feature con mayor número de correlaciones por encima del umbral (Fmaxr) y se descartaban las que correlacionaban con ella. Quedaron 20 features.
3. Sequential Backward Selection (SBS) iterativo sobre 10 splits aleatorios 70/30, evaluado con tres clasificadores (KNN, SVM, decision tree) tuneados con Bayesian optimization.

**Resultados de performance supervisada (test sets, media ± SD sobre 10 runs):**
| Clasificador | Accuracy | Recall | Precision | F1 |
|---|---|---|---|---|
| KNN | 88.1 ± 5.7% | 85.0 ± 4.7% | 89.4 ± 8.3% | 87.1 ± 6.0% |
| SVM | 89.8 ± 5.1% | 91.0 ± 5.7% | 87.8 ± 6.6% | 89.2 ± 5.3% |
| TREE | 81.2 ± 5.7% | 78.5 ± 9.1% | 82.1 ± 10.3% | 79.6 ± 5.5% |

Durante el SBS, los promedios de accuracy fueron: 94.1% ± 1.6% (KNN), **96.7% ± 2.1% (SVM)**, 89.1% ± 2.2% (TREE). SVM mostró el mejor balance, el highest recall (mejor identificación de patológicos) y mayor estabilidad inter-run.

**Las 9 features finalmente retenidas, en orden de ocurrencia en los SBS:**

1. **Improved Harmonic Ratio en dirección medio-lateral medido a nivel lower back** (dominio: simetría). Aplicabilidad al proyecto: parcial — habría que aproximar la simetría desde el pie con índices entre extremidades.

2. **Coefficient of Variation (CoV) de la duración del stance phase** (dominio: variabilidad). Aplicabilidad: directa con sensores tibiales o IMU del pie, totalmente computable.

3. **Stride speed** (dominio: espacio-temporal). Aplicabilidad: directa.

4. **Swing phase duration** (dominio: espacio-temporal). Aplicabilidad: directa.

5. **Head LDLJ de aceleración en dirección ML** (dominio: suavidad). Aplicabilidad: no — el proyecto no instrumenta la cabeza.

6. **Head LDLJ de aceleración en dirección AP** (dominio: suavidad). Aplicabilidad: no.

7. **Coefficient of attenuation entre lower back y cabeza en dirección ML** (dominio: estabilidad). Aplicabilidad: no.

8. **Sternum LDLJ de aceleración en dirección AP** (dominio: suavidad). Aplicabilidad: no.

9. **Head RMS de aceleración en dirección AP** (dominio: estabilidad). Aplicabilidad: no.

**Resultados unsupervised (k-medoids clustering con distancia coseno):** el clustering identifica correctamente la pertenencia a grupo stroke o sano. La mejor performance fue **90.2% ± 5.5% accuracy con sólo 3 features**: IHR ML en lower back, CoV de stance phase, y stride speed. Esta es probablemente la observación más útil del paper para el presente proyecto, porque demuestra que el problema de discriminación es inherentemente de baja dimensionalidad y que un pipeline minimalista, si elige bien sus features, puede ser efectivo.

**Discusión de los autores:** los resultados indican que la variabilidad de marcha (especialmente CoV de stance), la suavidad del tronco y la estabilidad del upper body caracterizan robustamente la disfunción post-stroke. Particularmente, el "head-movement smoothness emerged as a novel, discriminative feature". Esto último motiva trabajos futuros con sensorización aumentada, pero está fuera del alcance del presente proyecto.

**Limitación crítica para el presente proyecto:** **5 de las 9 features top de Brasiliano provienen de sensores en cabeza, esternón o lower back**, partes del cuerpo que el sistema propuesto no instrumenta. Las features de pie aprendidas en este paper son las de los sensores tibiales: stride speed, swing duration, CoV de stance, IHR (este último derivado del lower back, no del pie). Por lo tanto, **el sistema propuesto puede replicar de manera directa entre 3 y 5 de las 9 features clave**: stride speed, swing duration, CoV stance, más adaptaciones locales del LDLJ y del IHR/Symmetry Angle desde el pie. Esto exige adaptación metodológica explícita en el marco teórico y será tratado en la sección 5.7.

## 5.3 Evidencia empírica primaria: Herbers et al. (2024)

El estudio de Herbers, Zhang, Erdman y Johnson publicado en npj Parkinson's Disease volumen 10, artículo 67 (DOI 10.1038/s41531-024-00678-2) es la otra referencia central, esta vez para la clasificación de fallers vs non-fallers basada en monitoreo plantar con insoles. Aunque la patología es Parkinson, los marcadores plantares de inestabilidad postural y riesgo de caída son ampliamente transferibles al stroke porque ambos comparten el déficit central de control postural.

**Diseño:** N=111 participantes (44 con Parkinson, 67 controles). Monitoreo plantar con insoles inalámbricos durante seis tareas: tres estáticas (quiet stance ojos abiertos ambos pies, quiet stance ojos cerrados ambos pies, quiet stance ojos abiertos un pie) y tres activas (gait, functional reach, bending over). Las tareas se eligieron para muestrear distintos aspectos del control postural, incluyendo tareas con postural threat aumentado (ojos cerrados, base de apoyo reducida).

**Pipeline de features:** desde la pressure data se calculó el Center of Pressure (COP) en cada pie. Sobre el COP se generaron tres familias de features:

***Posicionales:*** posición media del COP, rango, desviación, ubicación lateral. Capturan dónde el sujeto pone el peso.

***Dinámicos:*** velocidad del COP, aceleración, **zero crossings de la velocidad del COP**, mean peak sway density. Capturan cómo se mueve el COP a lo largo del tiempo.

***Frecuencia:*** Power Spectral Density (PSD) en bandas <0.5 Hz, 0.5-2 Hz, >2 Hz; mean frequency; total energy. Capturan la composición espectral del movimiento del COP.

Cada feature se calculó en dos modos: **promedio** entre ambos pies, y **asimetría** (diferencia entre pies). El doble cálculo duplica el espacio de features pero captura información distinta: el promedio refleja la magnitud absoluta, la asimetría refleja la lateralización característica de muchas patologías.

**Clasificadores evaluados:** SVM, Random Forest, Logistic Regression, K-Nearest Neighbors, Gaussian Naive Bayes. F-statistic pre-filtering, forward sequential feature selection optimizando F1 por modelo, tuning de hiperparámetros, cinco-fold cross-validation. Análisis Shapley para feature importance.

**Resultados:**
- PD vs controles jóvenes: AUC 0.99 ± 0.00 con modelos entrenados en features estáticos + activos combinados; SVM, KNN y GNB lograron clasificación perfecta (100%) en cross-validation.
- PD vs controles age-matched: AUC 0.99 ± 0.01 con static+active, KNN el mejor modelo.
- **PD fallers vs PD non-fallers: AUC 0.91 ± 0.08, GNB el mejor modelo.** Este es el resultado más relevante para el presente proyecto. Con KNN específicamente lograron 91% accuracy, 93% precision, 80% recall.

**Hallazgos sobre tipos de tarea:** combinar features de tareas estáticas + activas mejoró significativamente la clasificación PD vs control. Para PD fallers vs non-fallers, las tareas activas y las estáticas con postural threat aumentado (ojos cerrados, un pie) fueron las más discriminativas.

**Las 9 features clave que distinguieron PD fallers de non-fallers** (intersección entre common features y top Shapley):

- 5 son features dinámicos, 4 son de frecuencia. **Ninguno es posicional.**
- 5 provienen de tareas estáticas (4 ojos cerrados, 1 un pie), 4 de tareas activas (3 gait, 1 bending over). Ninguno de quiet stance ojos abiertos ni de functional reach.
- 4 son features promedio entre pies, 5 son asimétricos. Esto subraya el valor de la información de asimetría inter-extremidad.
- Específicamente mencionados:
  - **Average zero crossing de COP velocity en ML y AP** (más alto en fallers; correlaciona con personas que caen en general según Maranesi et al. 2016, citado).
  - **Average energy content below 0.5 Hz PSD ML.**
  - **Total power ML.**
  - **rms del radio del COP** en quiet stance ojos abiertos (mayor en PD, con distribución más amplia).
  - **Mean peak sway density** en functional reach (mayor en PD, interpretado como reflejo de movimientos rígidos o lentos durante tareas activas).
  - **Mean frequency ML** en quiet stance one foot (decreased en PD, contraintuitivo, interpretado por los autores como que controles sanos pueden compensar con más sway antes de perder balance, mientras PD apoyan el pie no-soporte antes).
  - **Asymmetric energy content 0.5-2 Hz ML** en quiet stance ojos abiertos.
  - **Asymmetric mean value ML** en bending over.

**Interpretación clínica del paper:** las articulaciones del tobillo y cadera son los contribuyentes primarios al desplazamiento del COP en direcciones AP y ML respectivamente, durante el control postural. En PD, los torques articulares del tobillo están disminuidos, llevando a mecanismos compensatorios como aumento del torque de cadera. Esto se observa biomecánicamente en el feature de placement lateral de peso aumentado durante quiet stance y bending over.

**Limitación para el presente proyecto:** Herbers et al. usan un array completo de FSRs por plantilla, suficiente para reconstruir COP 2D. **Con 3-4 FSRs el COP 2D completo no es reconstruible, pero sí el componente ML 1D** mediante una suma ponderada por coordenadas conocidas de los sensores: COP_ML = Σ(F_i · x_i) / Σ(F_i), donde F_i es la fuerza del sensor i y x_i es su coordenada medio-lateral. Crucialmente, ML es justamente la dirección donde Herbers encontró la mayor concentración de features discriminativos para fallers, así que la limitación es menos grave de lo que parece a primera vista.

## 5.4 Evidencia empírica primaria: Chen et al. (2022)

El estudio de Chen, Hu, Zhang, Pan, Chen, Xie, Luo y Zhu publicado en Frontiers in Neuroinformatics volumen 16, artículo 1006494 (DOI 10.3389/fninf.2022.1006494) es la tercera referencia central. Aborda la evaluación interpretable del Brunnstrom Recovery Stage of the Lower Limb (BRS-L) en pacientes hemipléjicos.

**Diseño:** N=20 pacientes hemipléjicos (BRS-L III-V) + N=10 individuos sanos. Inclusión: hemiplejia unilateral en rehabilitación hospitalaria, edad 18-80, capacidad de caminar 10 metros con o sin asistencia. Exclusión: pacientes BRS-L I-II por inability to walk.

**Setup:** 7 IMUs en lower limb + 2 plantillas instrumentadas con presión plantar. Los IMUs se ubican en lumbar, ambos muslos, ambas pantorrillas, ambos pies (configuración estándar de gait lab portable). Las plantillas miden distribución plantar bilateral.

**Pipeline de features:** se extrajeron features de los datos de movimiento (IMUs) y de presión (plantillas). El paper menciona explícitamente que combinaron parámetros kinemáticos, parámetros de presión plantar y parámetros espaciales como pool inicial. Aplicaron feature selection basada en feature importance (típicamente Gini importance de Random Forest o equivalente) para mejorar la interpretabilidad. Varios modelos de ML evaluados sobre el dataset.

**Resultado principal:** **K-Nearest Neighbor con 18 features alcanzó 94.2% accuracy**. Este resultado consolida un hallazgo metodológico recurrente: alrededor de 18 features bien seleccionados constituyen el techo de performance para problemas de clasificación de marcha hemipléjica. Sumar más features no mejora y suele degradar por overfitting o ruido.

**Implicancia para el proyecto:** la región operativa óptima de dimensionalidad del vector de features está entre 15 y 25 valores. Configuraciones más pequeñas (3-9 features tipo Brasiliano top-3 o top-9) son efectivas para clasificación binaria simple. Configuraciones de 18-25 features cubren clasificación más granular como Brunnstrom de 6 estadíos.

## 5.5 Evidencia empírica primaria: Toth et al. (2024-2025)

El estudio publicado en Sensors (referencia PMC12845696) introduce un framework bioinformatics-inspired para detección de fatiga en running con un único IMU lumbar y One-Class SVM personalizado. Es críticamente relevante porque su pipeline algorítmico es esencialmente el que se propone para el presente proyecto: anomaly detection one-class con baseline personalizado.

**Diseño:** N=19 corredores recreativos completaron 400m en condiciones non-fatigued y fatigued. Un IMU lumbar, features de stride extraídas tras segmentación.

**Features:** spectral-entropy, sample entropy, frequency-domain descriptors, mixed-effects statistical modeling. Resultados de Mixed-Effects: efectos robustos y multidimensionales de la fatiga sobre features biomecánicos, con tamaños de efecto estandarizados grandes (Cohen's d hasta 1.35) y varianza única explicada por fatiga (partial R² hasta 0.31).

**Tres modelos comparados:**
1. **Global LOPO (leave-one-participant-out)** Random Forest entrenado sobre todos los sujetos excepto uno: **accuracy 55%**. Es decir, apenas mejor que azar. La conclusión inevitable es que la variabilidad inter-individual es tan grande que un modelo poblacional no generaliza.

2. **Personalized supervised Random Forest** entrenado per-sujeto: **accuracy 97.7%, AUC 0.997**. La diferencia frente al global es dramática (+42.7% absoluto en accuracy).

3. **One-Class SVM con baseline non-fatigued only personalizado**: **AUC 0.967**. Este es el setting más directamente análogo al pipeline propuesto en este proyecto: el clasificador se entrena solamente con marcha normal del propio sujeto y luego detecta deviation. La fatiga se trata como una anomalía respecto al baseline personal.

**Conclusión accionable crítica:** los modelos globales son inviables para detección personalizada de anomalías en marcha; los modelos personalizados son extremadamente efectivos; el enfoque one-class con baseline normal del propio sujeto es viable con AUC ~0.97. **Este resultado constituye la evidencia empírica más directa y reciente que respalda la viabilidad técnica del pipeline propuesto.**

## 5.6 Evidencia empírica primaria: Nanayakkara et al. (2025) y otros

**Nanayakkara, Herath, Sedigh Malekroodi, Madusanka, Yi y Lee** publicaron en Springer Multimedia Information Technology and Applications conference (MITA 2025) un trabajo titulado "Phase-Specific Gait Characterization and Plantar Load Progression Analysis Using Smart Insoles". Es directamente relevante por la arquitectura sensorial casi idéntica al proyecto.

**Setup:** smart insole custom con 8 FSRs Interlink FSR 402 (13mm, 0.5-150 N, <3ms response time) + IMU triaxial por pie, sampling deliberadamente bajo a 5 Hz para evaluar eficiencia energética. N=14 participantes sanos, 5 walking trials de 10m con video anotado como ground truth.

**Resultados clave:**
- **Features de presión-only con SVM**: macro-F1 = **0.915** para clasificación de gait phases.
- **Features de IMU-only**: significativamente peor a 5 Hz.

**Conclusión accionable:** a sampling rates muy bajos, los FSRs mantienen información discriminativa mientras el IMU degrada. Esto valida la decisión de no escatimar sampling rate en el IMU (recomendado 100 Hz para el presente proyecto) y refuerza el rol central de los FSRs en la determinación de fases de marcha.

**Chien et al. (2025)** publicaron en IEEE BIBM 2025 (Ulster University) "Assessing a Smart-Insole-Based System in Stroke Gait Pattern Recognition". Recolectaron datos de stroke survivors y controles sanos en Walk y Timed-Up-and-Go tasks. Hedges' g para cuantificar diferencias entre grupos. Múltiples ML models. **SVM y KNN alcanzaron accuracy de 0.88** para clasificación de los dos grupos. Es una corroboración independiente — aunque con setup distinto al de Brasiliano y al del presente proyecto — de que la categoría smart insole puede discriminar marcha post-stroke con accuracy clínicamente útil.

**Pan, Gao, Chen, Xie y Xie (2023)** publicaron en IEEE Sensors Journal volumen 23, número 11, páginas 12008-12017, "Evaluation of Hemiplegic Gait Based on Plantar Pressure and Inertial Sensors". Aplican exactamente la combinación FSR+IMU del presente proyecto a pacientes con stroke, correlacionando con el Mini Balance Evaluation System (Mini-BES) como referencia clínica. Es la confirmación directa de que la categoría tecnológica es validable contra escalas clínicas reconocidas.

**Seo, Shin, Park y Park (2020)** publicaron en JMIR mHealth and uHealth volumen 8, artículo e22208, "Clinometric Gait Analysis Using Smart Insoles in Patients With Hemiplegia After Stroke: Pilot Study". Cada plantilla equipada con 8 sensores de presión, acelerómetro triaxial y giroscopio, 100 Hz sampling. Este paper es importante por dos razones: confirma 100 Hz como sampling estándar en la categoría smart insole para stroke, y valida el uso clínico del Modified Barthel Index (MBI) como referencia funcional (más simple que FIM, sin fee de copyright, métricamente equivalente).

## 5.7 Lista consolidada de features recomendados para el proyecto

Sintetizando la evidencia anterior y adaptándola al hardware específico (plantilla bilateral con 3-4 FSR + 1 IMU bajo el arco por pie, sampling 100 Hz, RP2350 como procesador), se proponen los siguientes ocho bloques de features. La numeración se mantiene a lo largo del documento.

### Bloque A — Features espacio-temporales (prioritarios; máxima evidencia)

Calculados por zancada a partir de la segmentación validada por FSR e IMU.

1. **Stride time:** duración total del ciclo en segundos.
2. **Stance time:** duración de la fase de stance, en segundos absolutos y como porcentaje del ciclo.
3. **Swing time:** complementario al stance.
4. **Double support time:** tiempo de doble apoyo por ciclo.
5. **Single support time:** complementario al double support, por pierna.
6. **Cadence instantánea:** ciclos por minuto.
7. **Stride length:** estimada por integración doble de la aceleración con ZUPT.
8. **Velocidad estimada de zancada:** stride length / stride time.

Fuentes: Brasiliano et al. (2026) — stride speed top-3, swing duration top-9; Riglet et al. (2023) — los cinco temporales con ICC > 0.90; Lim et al. (2025) — stride time ICC 0.97 izq; Pan et al. (2023); Chen et al. (2022); Seo et al. (2020).

### Bloque B — Features de variabilidad (prioritarios; máxima evidencia)

Calculados como Coefficient of Variation o Standard Deviation sobre ventana móvil de 10+ zancadas consecutivas.

9. **CoV de stride time.**
10. **CoV de stance time.** *Top-3 de Brasiliano (2026) para discriminar stroke de sano.*
11. **CoV de swing time.**
12. **CoV de cadence.**

Fuentes: Brasiliano et al. (2026) — CoV de stance entre las 3 features que llevan a 90% accuracy en unsupervised clustering; Cerfoglio et al. (2025) — necesidad de promediar >10 ciclos para estabilidad; literatura general de variabilidad post-stroke.

### Bloque C — Features de fuerza plantar y magnitud por FSR (prioritarios; críticos para stroke)

Calculados por cada FSR sobre cada zancada.

13. **Peak force** por FSR: fuerza máxima durante la zancada, normalizada por peso corporal.
14. **Mean pressure** por FSR: presión media durante el contacto.
15. **Pressure-Time Integral (PTI)** por FSR: integral de la fuerza sobre el tiempo de contacto. Indicador del trabajo aplicado.
16. **Contact time** por región: tiempo que el sensor estuvo sobre umbral de contacto.
17. **Loading rate**: pendiente máxima de la curva de fuerza al inicio del apoyo, indicador del impacto.
18. **Time-to-peak**: tiempo desde heel-strike hasta peak force, indicador de la velocidad de progresión del peso.

Fuentes: Kang (2025) sobre regiones plantares y déficit de push-off; Ma et al. (2017) en stroke; Pan et al. (2023); Pappas et al. (2001) clásico sobre fases.

### Bloque D — Features de simetría inter-extremidad (prioritarios diferenciales para stroke)

Calculadas comparando lados izquierdo y derecho de una misma zancada, o usando el Symmetry Angle de Brasiliano et al. (2026).

19. **Symmetry Index (SI)** para cada feature espacio-temporal y de fuerza: SI = |X_left − X_right| / (0.5 × (X_left + X_right)). Aplicado a stance time, swing time, stride length, peak force, etc.
20. **Symmetry Angle (SA)** de Brasiliano: SA = ((45° − arctan(X_left / X_right)) / 90°) × 100. Equivalente al SI pero con propiedades estadísticas distintas (limitado a [−100, 100], simétrico).
21. **Ratio medial/lateral** de peak force, calculado por pie (lateralidad intra-pie). Captura la inversión patológica del pie. *Diseño original de Ma et al. (2017) basado exactamente en este ratio.*
22. **Pressure progression ratio anterior/posterior**: distribución relativa de la integral de presión entre regiones anteriores (push-off) y posteriores (heel-strike).
23. **Inter-stride Force Symmetry Index**: comparación de fuerza pico entre zancadas consecutivas del mismo pie (variabilidad temporal de magnitud, complementario a la variabilidad temporal de duración del Bloque B).

Fuentes: Ma et al. (2017) — ratio medial/lateral como driver del biofeedback; Kang (2025) — distribución entre regiones; Brasiliano et al. (2026) — Symmetry Angle; Sanghan et al. (2014).

### Bloque E — Features derivadas del Center of Pressure (recomendados; adaptables a 3-4 FSRs)

Aproximación 1D del COP medio-lateral por suma ponderada de FSRs según sus coordenadas conocidas: COP_ML(t) = Σ(F_i(t) · x_i) / Σ(F_i(t)).

24. **COP_ML range:** excursión total del COP medio-lateral durante la zancada.
25. **COP_ML velocity (mean y max):** derivada temporal del COP_ML, en magnitud y pico.
26. **Zero crossings de COP_ML velocity:** número de veces que la velocidad cruza el cero durante la zancada. *Feature top de Herbers et al. (2024) para distinguir fallers.*
27. **Mean peak sway density de COP_ML:** número de muestras consecutivas que el COP permanece dentro de una ventana de 3mm. Indicador de estabilidad postural.

Fuentes: Herbers et al. (2024) — zero crossings y mean peak sway density entre los 9 top features de PD fallers.

### Bloque F — Features cinemáticos del IMU del pie (recomendados)

Calculados sobre el IMU bajo el arco de cada pie.

28. **Range of Motion (ROM) de pitch:** rango angular sagital durante la zancada. Refleja la rotación del pie en plano vertical.
29. **ROM de roll:** rango angular frontal. *Clave en stroke por la inversión patológica documentada por Ma et al. (2017).*
30. **Foot orientation (pitch) en heel-strike:** ángulo del pie al instante del contacto.
31. **Foot orientation (pitch) en toe-off:** ángulo del pie al despegue, proxy del push-off (mayor plantarflexión = mejor push-off).
32. **Peak vertical acceleration en toe-off:** proxy directo de la fuerza de propulsión.
33. **Mean angular velocity en swing phase:** velocidad angular promedio del pie en vuelo, indicador de la fluidez del swing.

Fuentes: Eskofier et al. (2020); Falbriard et al. (2020); Kang (2025) sobre déficit de push-off.

### Bloque G — Features de suavidad: Log-Dimensionless Jerk (recomendados)

Calculado sobre las señales del IMU del pie, con la consideración importante de aplicarlos sobre la fase de swing para evitar la dominancia de los shocks de heel-strike.

34. **LDLJ de aceleración del pie en AP**, calculado sobre swing phase.
35. **LDLJ de aceleración del pie en ML**, calculado sobre swing phase.
36. **LDLJ de velocidad angular del pie**, alternativa que puede ofrecer mejor signal-to-noise ratio en algunos casos.

Fórmula: LDLJ = −ln((t₂ − t₁) · max(‖x(t)‖) · ∫|x′(t)|² dt), siguiendo a Brasiliano et al. (2026).

Caveat crucial: en Brasiliano el LDLJ se calculaba sobre IMUs de cabeza/esternón porque la cadena cinemática filtra y amplifica el jerk hacia arriba. Aplicado al pie distal, el LDLJ es naturalmente dominado por choques de heel-strike y picos abruptos del push-off, lo cual reduce su capacidad discriminativa. La adaptación recomendada es calcular el LDLJ exclusivamente en la fase de swing, donde el pie está en vuelo y la señal refleja la fluidez del control motor sin contaminación de impacto. Esta adaptación metodológica es propia del proyecto y debe ser justificada explícitamente en el marco teórico.

### Bloque H — Features de frecuencia y entropía (opcionales; refinamiento)

Calculados sobre la ventana de aceleración del IMU durante cada zancada o ventana móvil.

37. **Spectral entropy** de la aceleración del IMU: entropía de la distribución normalizada del espectro de potencia. Captura la complejidad espectral del movimiento.
38. **Sample entropy** o **approximate entropy** de la velocidad angular: complejidad temporal del patrón, mide cuán predecible es la señal.
39. **Dominant frequency** del espectro: aproximadamente la inversa del stride time, pero calculada por FFT.
40. **Power en bandas:** energía en <0.5 Hz, 0.5-2 Hz, >2 Hz. Bandas elegidas siguiendo Herbers et al. (2024).
41. **Average zero crossings de la aceleración**, calculado por eje.

Fuentes: Toth et al. (2024-2025) — spectral entropy, sample entropy y frequency-domain descriptors en pipeline One-Class SVM con AUC 0.967; Herbers et al. (2024) — PSD bands; Kirubakaran et al. (2025) — multi-modal sensor fusion con análisis frecuencial.

## 5.8 Estrategia operativa de implementación progresiva

Dado que el proyecto realiza one-class anomaly detection con calibración per-paciente, no es necesario ni eficiente implementar los 41 features de entrada. La estrategia recomendada es progresiva en cuatro fases:

**Fase 1 — Vector mínimo (12 features):** Bloques A y B completos. Cubre los espacio-temporales y la variabilidad. Esto sólo, combinado con distancia de Mahalanobis personalizada, debería dar un baseline competitivo en línea con las 3 features de Brasiliano que alcanzaron 90% accuracy en clustering no supervisado.

**Fase 2 — Expansión con presión (sumar 11 features → 23 total):** Bloques C y D. Acá entra la información específica de stroke (push-off, asimetría, distribución medial-lateral, lateralidad intra-pie). Es lo que distingue al sistema de uno basado solo en IMU.

**Fase 3 — Refinamiento cinemático y postural (sumar 11 features → ~34 total):** Bloques E, F y G. Llegada al techo de performance documentado: Chen (2022) con 18 features alcanzó 94.2%, Brasiliano (2026) con 9 features alcanzó 96.7%. Configuración intermedia.

**Fase 4 — Solo si las anteriores no alcanzan (sumar 5 features → 39 total):** Bloque H. Más costoso computacionalmente, en particular el cómputo de FFT y de entropies. Opcional según el balance final accuracy-vs-latencia en el RP2350.

La selección efectiva de features dentro de cada fase se realizará offline mediante técnicas estándar (LASSO, Sequential Backward Selection, Random Forest feature importance) sobre el dataset de calibración inicial, retenidos los que muestren máximo aporte discriminativo y mínima multicolinealidad.

---

# Bloque 6 — Detección de anomalías: algoritmos one-class y selección razonada

## 6.1 Formalización del problema one-class

La detección de anomalías de marcha en este proyecto se formaliza como un problema de **one-class classification** o **novelty detection**. La definición técnica: dado un conjunto de entrenamiento que contiene observaciones exclusivamente de una clase (en este caso, marcha "normal" del propio paciente), construir un modelo que, ante una nueva observación, determine si pertenece a esa clase (normal) o se desvía suficientemente de ella (anomalía).

La motivación de no plantear el problema como clasificación binaria supervisada (normal vs anómalo) es cuádruple:

1. **Disponibilidad asimétrica de datos:** se puede recolectar abundante marcha normal del paciente en un período de calibración, pero las anomalías son por construcción raras e impredecibles. No se conoce a priori el espectro de anomalías posibles.

2. **Generalización:** entrenar con anomalías específicas etiquetadas restringiría la detección a esos tipos exactos, perdiendo capacidad de identificar anomalías novedosas. Lee, Lin y Katsikas (2024) [arXiv:2405.09561] formularon explícitamente esta tensión en GAD, optando por el enfoque online adaptive para mantener generalización.

3. **Ética y operativa:** sería invasivo y poco ético inducir caídas o pasos peligrosos en pacientes para conseguir datos etiquetados de anomalías.

4. **Personalización:** la marcha normal varía enormemente entre individuos, especialmente en patológicos. Un anomaly detector personalizado captura la "normalidad" específica del sujeto, mientras que un clasificador binario poblacional sería degradado por la heterogeneidad inter-individual. Toth et al. (2024-2025) demostraron esto cuantitativamente: 55% vs 97.7% accuracy.

## 6.2 Familias de algoritmos one-class

Existen cuatro grandes familias de algoritmos pertinentes:

### Familia 1: Estadísticos / distancia paramétrica

Asumen una distribución (típicamente gaussiana) del vector de features de marcha normal y miden cuán improbable es una nueva observación bajo esa distribución.

- **Distancia de Mahalanobis multivariada:** dado vector medio μ y matriz de covarianza Σ estimados sobre la calibración, la distancia de una nueva observación x es D² = (x − μ)ᵀ Σ⁻¹ (x − μ). Si D² > umbral, anomalía. El umbral se fija típicamente al percentil 99 de la distribución de D² en calibración. Ventajas: implementación trivial en C, ocupa kilobytes, inferencia en microsegundos. Limitación principal: asume unimodalidad gaussiana. Si la marcha normal del paciente es multimodal (ej. velocidad lenta y velocidad rápida coexistiendo), falla.

- **Gaussian Mixture Models (GMM):** generaliza Mahalanobis a una mezcla de K gaussianas, ajustadas por Expectation-Maximization. Score: log-likelihood bajo el GMM. Sigue siendo liviano.

- **Z-score multivariado independiente:** asume independencia entre features. Más simple pero menos preciso que Mahalanobis cuando los features están correlacionados.

### Familia 2: Boundary / density based no paramétricos

No asumen distribución específica.

- **Isolation Forest:** construye árboles aleatorios particionando el espacio de features; observaciones anómalas son "fáciles de aislar" en pocos splits. Score: profundidad media de aislamiento sobre el bosque. Ventajas: maneja no-linealidades, muy eficiente (entrenamiento O(n log n)), inferencia rápida, footprint de decenas de KB. Limitación: peor en espacios de muy alta dimensionalidad sin feature selection previa.

- **Local Outlier Factor (LOF):** mide la densidad local de una observación respecto a sus k vecinos más cercanos. Score: razón entre la densidad local de la observación y la densidad de sus vecinos. Limitación crítica para edge: inferencia requiere acceso al training set completo, lo cual es prohibitivo en memoria limitada.

- **k-NN distance:** distancia al k-ésimo vecino más cercano del training set. Mismo problema de memoria que LOF.

### Familia 3: Boundary methods

Aprenden una superficie en el espacio de features que envuelve los datos normales.

- **One-Class Support Vector Machine (OC-SVM):** la referencia clásica, propuesta por Schölkopf et al. (2001). Aprende un hiperplano en el espacio de features (con kernel RBF típicamente) que separa los datos normales del origen con máximo margen. Limitación: el modelo retiene los support vectors, que pueden ser cientos para datasets de marcha, lo cual puede engordar la memoria.

- **Support Vector Data Description (SVDD):** variante de OC-SVM que aprende la hiperesfera mínima envolvente. Conceptualmente equivalente, propiedades estadísticas similares.

- **Toth et al. (2024-2025)** demuestran que OC-SVM personalizado con baseline non-fatigued alcanza **AUC 0.967** en detección de fatiga, validando empíricamente la familia para el problema de detección de anomalías de marcha.

### Familia 4: Reconstruction-based (deep learning)

Entrenan una red neuronal para reconstruir los datos normales; ante una entrada anómala, la reconstrucción es pobre y el error es alto.

- **Autoencoders densos:** estructura simétrica encoder-decoder con bottleneck. Score: MSE entre input y reconstrucción. Liviano, factible en edge con cuantización.

- **LSTM autoencoders:** procesan series temporales explícitamente. Lee, Lin y Katsikas (2024) [GAD] usan esta arquitectura sobre acelerómetro 3D, con online adaptive learning para mantener el modelo actualizado.

- **Variational Autoencoders (VAE):** versión probabilística que agrega regularización del espacio latente. Score: likelihood probabilístico bien definido. Kirubakaran et al. (2025) [EdgeSense Health, Zenodo 18074824] integran VAE con feature extraction CNN y temporal modeling con Transformer en arquitectura híbrida edge-native, logrando latencias de detección <20 ms en wearable con fusión multimodal de sensores.

- **1D CNN autoencoders:** alternativa más eficiente que LSTM cuando la longitud temporal de la ventana no es extensa.

## 6.3 Pipeline algorítmico propuesto para el proyecto

Considerando las restricciones del RP2350 (520 KB SRAM, ARM Cortex-M33 a 150 MHz), la cantidad de features (entre 12 y 41 según fase), y la necesidad de personalización per-paciente con adaptación online, el pipeline propuesto es de cuatro etapas, cada una más compleja que la anterior, a evaluar comparativamente:

**Algoritmo (a) — Baseline: Distancia de Mahalanobis personalizada.** Entrenamiento: estimar μ y Σ⁻¹ desde las features de calibración. Inferencia por zancada: D² = (x − μ)ᵀ Σ⁻¹ (x − μ). Umbral: percentil 99 de la calibración. Memoria: O(n²) donde n es número de features, típicamente kilobytes. Latencia: <100 µs en el RP2350.

**Algoritmo (b) — Isolation Forest entrenado offline.** Entrenamiento offline en PC con los features de calibración del paciente. Exportación al firmware como tablas compactas de splits binarios. Inferencia: recorrido de árboles. Memoria: decenas de KB para un bosque de 50-100 árboles con depth limitado. Latencia: cientos de microsegundos.

**Algoritmo (c) — Autoencoder denso shallow.** Arquitectura típica 25-12-6-12-25 (o similar adaptada al vector de features). Entrenamiento offline con backpropagation. Deployment con TensorFlow Lite for Microcontrollers y cuantización int8. Score: MSE de reconstrucción. Memoria: 10-50 KB del modelo cuantizado. Latencia: del orden de milisegundos.

**Algoritmo (d) — LSTM autoencoder sobre señal cruda windoweada.** Opera directamente sobre la ventana del ciclo (~100 muestras × 8 canales de FSR/IMU). Captura dinámica temporal completa. Inspirado en GAD de Lee et al. (2024) y EdgeSense de Kirubakaran et al. (2025). Requiere cuantización agresiva. Latencia: del orden de decenas de milisegundos. Es el techo de complejidad que se intentará; si no entra en el footprint del RP2350, queda como referencia ejecutable en smartphone vinculado.

La evaluación comparativa entre (a), (b), (c), y eventualmente (d) se realizará sobre los mismos datasets de calibración y de inducción controlada de anomalías, midiendo sensibilidad, especificidad, AUC-ROC, latencia y footprint de memoria. El objetivo no es elegir un único algoritmo sino determinar empíricamente la frontera de Pareto entre accuracy y costo computacional.

---

# Bloque 7 — Personalización y adaptación online

## 7.1 Limitaciones intrínsecas de los modelos genéricos en marcha patológica

La marcha humana es altamente variable entre individuos, y esta variabilidad se amplifica en poblaciones patológicas. En stroke específicamente, factores como el lado afectado, el grado de espasticidad, las estrategias compensatorias específicas de cada paciente, el grado de recuperación funcional, la edad, comorbilidades y uso de asistencias técnicas (bastones, AFOs) generan una heterogeneidad que es estadísticamente intratable con modelos poblacionales únicos.

Matthews et al. (2018) [Front Neurol 9:561] proporcionan la evidencia más directa de este punto. En su cohorte de N=32 pacientes con esclerosis múltiple monitoreados durante 7 días en el hogar con acelerómetro Axivity AX3, compararon dos estrategias de estimación de velocidad de marcha:

- **Modelo entrenado sobre voluntarios sanos**, aplicado luego a los pacientes: predijo gait speed pobremente para los pacientes más discapacitados. El modelo genérico no generalizaba a perfiles patológicos severos.

- **Modelos individualmente personalizados** generados mediante machine learning para cada paciente: mostraron alta accuracy independientemente del grado de discapacidad, alcanzando R = 0.98 frente a referencia clínica, p estadísticamente significativo. Adicionalmente, los modelos personalizados confirmaron que el T25FW clínico es fuertemente predictivo de la velocidad máxima sostenida en el hogar (R = 0.89).

Este resultado es importante porque demuestra dos cosas: (a) el monitoreo remoto con wearable es clínicamente válido pero requiere personalización, y (b) la personalización no es opcional ni un refinamiento marginal sino el factor que separa un sistema funcional de uno que falla.

Toth et al. (2024-2025) cuantifican el efecto en términos aún más dramáticos: en su estudio de fatiga en running, el modelo global LOPO alcanzó 55% accuracy (apenas mejor que azar para clasificación binaria balanceada), mientras que los modelos personalizados llegaron a 97.7% — una diferencia de 42.7 puntos porcentuales absolutos. La conclusión de los autores subraya que "fatigue develops, neuro[muscular changes are individual]" y que "modelos globales fallan catastróficamente y los personalizados explotan en accuracy".

## 7.2 Modelos personalizados per-paciente: implementación

La implementación práctica de un modelo personalizado requiere una sesión inicial de **calibración por paciente**. En esta sesión el sistema recolecta marcha "normal" del paciente (en el caso post-stroke, "normal" se entiende como la marcha basal estable del paciente, no como marcha sana ideal) en condiciones controladas: terreno plano, velocidad cómoda autoseleccionada, idealmente con kinesiólogo presente para validar que no hay eventos anómalos durante la calibración.

Toth et al. (2024-2025) requieren baseline non-fatigued del propio sujeto. En el presente proyecto, eso se traduce en una sesión de ~100 zancadas de marcha basal del paciente, posiblemente repartida en varios trials de 10-15 zancadas cada uno (caminata por pasillo, vuelta y caminata de regreso) para minimizar fatiga y mantener la naturalidad del paso.

Sobre estos datos de calibración se ajustan los parámetros del modelo elegido (μ y Σ del Mahalanobis, splits del Isolation Forest, pesos del autoencoder), generando un "perfil de normalidad" específico del paciente. Cualquier desviación significativa de este perfil en uso posterior se marca como anomalía.

## 7.3 Online learning y adaptación continua

El segundo nivel de personalización es la **adaptación online**, es decir, actualización continua del modelo durante el uso normal para acomodar:

- Drift natural del patrón motor con el tiempo (recuperación funcional progresiva, fatiga acumulada, etc.).
- Cambios sutiles del paciente (cambio de calzado, modificación leve de la AFO).
- Variaciones del entorno (terrenos distintos, calzado de diferente espesor).

Lee, Lin y Katsikas (2024) [GAD, arXiv:2405.09561] formulan explícitamente este principio. Su sistema GAD para detección de anomalías de marcha tiene una arquitectura LSTM con online adaptive learning sobre acelerómetro 3D. El flujo es: (1) capturar un segmento de marcha del usuario y entrenar el detector "on the fly"; (2) verificar el modelo con los pasos subsiguientes; (3) si la verificación es exitosa, usar el detector para identificar anomalías en lecturas posteriores; (4) mantener el detector actualizado online para adaptarse a cambios menores del patrón; (5) si las predicciones degradan, reentrenar. Crucialmente, demostraron que el **método personalizado de captura de segmentos de marcha** (adaptado a la longitud de paso de cada individuo) supera al método uniforme (longitud de paso fija) en accuracy.

Kang et al. (2025) [IEEE Trans Robotics, también PMC12435548] aplican un framework de online adaptation a exoesqueletos para asistencia de marcha en pacientes post-stroke. Aprovechan streams de datos en tiempo real para actualizar continuamente el modelo de estimación del estado del usuario, permitiendo que el exoesqueleto aprenda los patrones de marcha específicos del usuario. Sus resultados son extraordinariamente relevantes: **con menos de un minuto de adaptación**, el framework mejoró la gait phase estimation (que afecta el timing de asistencia) en **+40.9% en sujetos sanos y +65.9% en sobrevivientes de stroke (p < 0.05)**, y redujo el torque profile error en 32.7% vs baseline. Adicionalmente demostraron transferencia de modelos entre hardware (research-grade a comercial) mediante transformación de señales.

La implicación operacional para el presente proyecto: la adaptación online no es un lujo sino un mecanismo necesario, particularmente útil en stroke donde el paciente puede mostrar recuperación funcional sustancial en semanas o meses. La estrategia recomendada: **Exponential Moving Average (EMA)** sobre μ y Σ del Mahalanobis con las zancadas clasificadas como normales por el umbral actual. Cuando la deriva acumulada supere un umbral configurable, gatillar reentrenamiento offline (vía smartphone o PC vinculada) de los detectores más complejos (Isolation Forest, autoencoder).

## 7.4 Visión estratégica: edge personalization y learning on-chip

Beckerle y colegas (2021) [Front Neurorobot 15:750519] proporcionan una visión estratégica de la personalización en neuroprosthetics y dispositivos asistivos en su Perspective. Sus recomendaciones centrales son:

- La interfaz debe ser **modular y adaptable**, proveyendo asistencia donde es necesaria.
- La tecnología de procesamiento de datos debe permitir procesamiento en tiempo real considerando las variaciones de señal en el humano.
- Se deben desarrollar **modelos biomecánicos personalizados y técnicas de simulación** para predecir el movimiento asistido y la interacción usuario-dispositivo.
- Las ventajas de interfacear con cerebro, médula espinal y periferia deben explorarse.
- Los avances tecnológicos deben enfocarse en **learning on-chip** para mayor personalización.
- **Bajo consumo energético** para uso prolongado.
- **In-memory processing combinado con resistive random access memory (RRAM)** es una tecnología prometedora para personalización y eficiencia energética.

Aunque la visión de Beckerle apunta a hardware emergente más sofisticado que el RP2350 del presente proyecto, los principios subyacentes son directamente aplicables: el modelo de marcha debe vivir y aprender en el dispositivo, no en la nube.

---

# Bloque 8 — Edge AI: inferencia on-device y eficiencia computacional

## 8.1 El paradigma cloud-dependent y sus limitaciones

Los sistemas wearable tradicionales suelen operar como sensores remotos: recolectan datos, los envían vía BLE o WiFi a un smartphone o gateway, y desde ahí a un servicio en la nube donde residen los modelos de ML. El smartphone recibe alertas de regreso. Este paradigma tiene cuatro limitaciones críticas para una aplicación clínica de monitoreo y feedback:

1. **Latencia.** El round-trip dispositivo-cloud-dispositivo es del orden de cientos de milisegundos en la mejor de las condiciones, suficiente para arruinar cualquier biofeedback en tiempo real. Para que el biofeedback vibrotáctil sea efectivo, la latencia desde la detección de la anomalía hasta la vibración debe estar idealmente por debajo de 50 ms (Ma et al. 2017 lograron feedback "instantáneo" precisamente por procesamiento local).

2. **Conectividad.** Requiere disponibilidad continua de red, lo cual no se garantiza en uso domiciliario, especialmente en poblaciones de adultos mayores con conectividad limitada o variable.

3. **Privacidad.** Los datos de movimiento de un paciente con discapacidad son sensibles. Enviarlos a la nube introduce riesgos de exfiltración, requiere consentimientos legales más complejos, y se ve sujeto a regulaciones de datos sanitarios (HIPAA, GDPR, ley argentina 26529).

4. **Costo operacional.** Servicios en la nube tienen costos recurrentes que dificultan la escala económica del dispositivo.

## 8.2 El paradigma edge AI

Edge AI invierte el paradigma: los modelos de ML viven y se ejecutan dentro del dispositivo wearable. Kirubakaran et al. (2025) [EdgeSense Health, Zenodo 18074824] formalizan esta arquitectura como "edge-native" y reportan resultados altamente alineados con los objetivos del presente proyecto:

- Arquitectura híbrida: convolutional feature extraction (CNN) + Transformer-based temporal modeling + Variational Autoencoder (VAE) para anomaly scoring.
- Streams sincronizados de acelerómetro, giroscopio, ECG, PPG, SpO2 y temperatura de piel.
- Inferencia ejecutada directamente en microcontroladores wearable-class o embedded processors.
- **Latencias de detección <20 ms.**
- Alta accuracy en categorías de anomalías que incluyen gait perturbations y falls explícitamente.

Las ventajas que detallan: evitan latencia de cloud, fortalecen privacidad al minimizar data egress, y operan offline. Es el modelo arquitectónico de referencia para el presente proyecto.

## 8.3 Restricciones del hardware embebido

El procesador del proyecto es el Raspberry Pi Pico 2 W con chip RP2350: dual-core ARM Cortex-M33 a 150 MHz, 520 KB de SRAM, 4 MB de flash, conectividad WiFi y BLE integrada. Estas especificaciones imponen restricciones explícitas sobre los algoritmos que pueden correr en el dispositivo:

- **Memoria:** 520 KB SRAM es suficiente para modelos cuantizados de hasta ~100 KB sin comprometer el resto del firmware, ROS de stack y buffers de comunicación.
- **CPU:** sin FPU avanzada en el sentido de Cortex-M4F+, pero con FPU single-precision en M33. Operaciones en float32 son posibles pero costosas; cuantización a int8 es preferible para inferencia.
- **Consumo energético:** la batería del wearable debe sostener idealmente 8+ horas de uso continuo, lo que limita el budget energético por inferencia.

## 8.4 Técnicas de optimización para deployment edge

Las técnicas estándar para hacer caber un modelo de ML en hardware embebido son:

- **Cuantización a int8:** reduce el tamaño del modelo 4x y acelera la inferencia significativamente. TensorFlow Lite for Microcontrollers (TFLM) soporta cuantización nativamente. La pérdida de accuracy es típicamente <1% bien manejada.
- **Pruning:** eliminar pesos con magnitud despreciable, reduciendo la cantidad de operaciones.
- **Knowledge distillation:** entrenar un modelo pequeño ("student") para imitar a un modelo grande ("teacher"), preservando accuracy con footprint reducido.
- **Arquitecturas eficientes:** evitar capas costosas computacionalmente; en lugar de LSTM completos, considerar GRU o 1D convolutions con receptive fields adecuados.

Para el presente proyecto, los algoritmos del pipeline propuesto (Mahalanobis, Isolation Forest, autoencoder denso shallow) caben sin tensión en el RP2350. El LSTM autoencoder requeriría cuantización agresiva y será evaluado caso por caso.

---

# Bloque 9 — Biofeedback vibrotáctil

## 9.1 Fundamentos del biofeedback en marcha

El biofeedback es el principio terapéutico por el cual información biomecánica o fisiológica medida sobre el cuerpo se devuelve al usuario en tiempo real, aumentando su conciencia corporal y permitiéndole modificar conscientemente su comportamiento motor. En marcha post-stroke, el biofeedback puede acortar la curva de aprendizaje de patrones corregidos al hacer explícitos eventos que el paciente no percibe por sí mismo (por ejemplo, asimetría de carga).

Ma, Zheng y Lee (2018) [Topics in Stroke Rehabilitation 25(1):20-27] proporcionan la evidencia clínica más directa de la efectividad inmediata del biofeedback vibrotáctil en stroke. En su sistema, ocho pacientes con stroke hemipléjico con deformidad varus flexible del retropié del lado afectado fueron evaluados con y sin biofeedback en condiciones experimentales aleatorizadas. El sistema consistía en sensores de fuerza plantar en regiones medial y lateral del antepié, un vibrador (XY-B1027-DX), un módulo Bluetooth HC-05, sampling y transmisión a 10 Hz, peso total <70 gramos. La lógica de feedback fue por umbral simple: cuando la fuerza plantar en el antepié medial era menor que un umbral predefinido, el vibrador se activaba.

Los resultados clínicos:

- El biofeedback **redujo significativamente la inversión del pie afectado**.
- Aumentó el área de contacto pie-suelo en mid-stance.
- Aumentó la presión plantar medial en mid-foot del lado afectado, acercándose a los valores del lado sano.
- Redujo en el lado no afectado la flexión excesiva de rodilla y la abducción de cadera, sugiriendo un efecto sistémico de re-equilibrio bilateral, no sólo local.

La conclusión de los autores es directa: hay signos de mejora en las características de carga plantar y de marcha al usar biofeedback vibrotáctil instantáneo de fuerza plantar, y los resultados positivos respaldan el desarrollo de dispositivos wearable de biofeedback para mejorar la marcha en pacientes con stroke. Este paper es el precedente clínico directo del concepto del presente proyecto.

## 9.2 Modalidad vibrotáctil: ventajas frente a otras

Las modalidades de feedback posibles incluyen visual (display), auditivo (tono o voz), y vibrotáctil. La vibrotáctil tiene ventajas específicas en el contexto de marcha:

- **No satura los sentidos principales.** Durante la marcha el usuario necesita su visión para orientación y su audición para conciencia ambiental (tráfico, voces, etc.). El canal vibrotáctil está subutilizado y por tanto disponible.
- **Discreción.** Una vibración localizada sobre el pie es imperceptible para observadores externos, lo cual reduce la estigmatización del dispositivo en uso público.
- **Localización somatosensorial.** El feedback vibrotáctil sobre el sitio mismo del problema (el pie) tiene mayor inmediatez perceptual que un feedback abstracto en pantalla.
- **Implementación electrónica simple.** Un motor pancake o eccentric rotating mass (ERM) controlado por PWM es un componente de menos de 1 dólar y un transistor NPN como driver.

## 9.3 Lógica de disparo del feedback

La lógica más simple y la más extendida en la literatura es la de **umbral simple por feature**. Ma et al. (2017) la implementan: si la fuerza medial del antepié es menor que un umbral, vibrar. Es interpretable, ajustable por paciente y robusta.

Para el presente proyecto, la integración natural es: cuando el anomaly detector marca una zancada como anómala (D² > umbral en Mahalanobis, o score elevado en otros algoritmos), se dispara el feedback vibrotáctil. Esto traduce la inteligencia del modelo en una intervención física inmediata.

## 9.4 Diseño del patrón de vibración: pattern-based vs alert-based

Sanchez-Morillo y colaboradores (2025) [Technologies 13(12):588] estudiaron empíricamente este punto en su sistema modular que combina órtesis de pie inteligente, muleta instrumentada y app móvil. Realizaron un estudio de usabilidad con N=8 participantes evaluando distintos tipos de vibrotactile feedback entre la órtesis y la muleta. Sus hallazgos:

- **El feedback basado en patrones (pattern-based) fue calificado como más útil y adecuado para uso regular que las alertas simples.** Patrones de intensidad y duración modulados (ej. "tres pulsos cortos" para asimetría, "un pulso largo" para riesgo de caída) son más interpretables que un único pulso genérico.
- Los participantes reportaron **diferencias perceptuales claras** entre feedback entregado por órtesis vs muleta, lo que indica percepción dependiente del dispositivo y del sitio anatómico de la vibración.

La conclusión orientativa: la estrategia de feedback debe diseñarse cuidadosamente, no es una decisión secundaria al hardware. Para el presente proyecto, se propone diseñar al menos tres patrones distintivos: uno para anomalía leve (un pulso suave), uno para anomalía marcada (dos pulsos), y uno para riesgo de caída (un pulso largo de mayor intensidad). Los patrones deben ser calibrables por paciente para ajustar a sensibilidad individual.

## 9.5 Riesgo de carga cognitiva en adultos mayores

Iwata y colaboradores (2019) [Front Psychol 10:1008] proporcionan una advertencia esencial sobre el biofeedback en poblaciones senior. Su sistema vibrotáctil de presión plantar fue evaluado en N=10 adultos mayores sanos, específicamente con foco en el efecto sobre **carga cognitiva durante la marcha** (paradigma dual-task, esencial para evaluar la viabilidad en uso real). Resultados:

- En condición con biofeedback, los participantes **extendieron la longitud de zancada** (apoyada por mayor ángulo de tobillo en heel-strike y mayor presión plantar en toe-off).
- **Estos cambios cinemáticos no contribuyeron a mayor velocidad de marcha.**
- La **performance cognitiva (respuestas correctas en la tarea dual) disminuyó significativamente** en condición con biofeedback.

Es decir: el dispositivo modificó el patrón cinemático en la dirección deseada pero no la velocidad funcional, e impuso una carga cognitiva detectable. Los autores concluyen que estos datos preliminares son esenciales para diseñar dispositivos exitosos de aumentación sensorial, particularmente en poblaciones de adultos mayores.

Las implicaciones para el presente proyecto:

1. El feedback debe ser **escaso en frecuencia, no continuo**. Disparar sólo cuando la anomalía supera un umbral claro, no en cada paso.
2. La calibración inicial debe incluir **evaluación de la respuesta del paciente al feedback**, ajustando intensidad y patrón para minimizar incomodidad.
3. El sistema debe ser **evaluado en dual-task** antes de despliegue en uso real, replicando la metodología de Iwata.
4. **Modular la intensidad por tipo de anomalía**, con patrones bien diferenciados, para que el paciente pueda interpretar la información sin sobrecarga cognitiva.

---

# Bloque 10 — Validación y metodología de evaluación

## 10.1 Métricas estadísticas estándar para validación de wearables

La validación de cualquier dispositivo wearable contra un gold standard requiere métricas estadísticas específicas. Las consolidadas en la literatura de smart insoles son:

**Intraclass Correlation Coefficient (ICC):** mide la concordancia entre dos mediciones simultáneas del mismo parámetro con dos instrumentos. Va de 0 (sin acuerdo) a 1 (acuerdo perfecto). Umbrales convencionales de interpretación: ICC > 0.90 es excelente, 0.75-0.90 es bueno, 0.50-0.75 es moderado, <0.50 es pobre. Riglet et al. (2023) reportan ICC > 0.90 para speed, cadence, stride length, stride time y stance time en su validación de DSPro. Lim et al. (2025) reportan ICC = 0.97 para stride time izquierdo vs GaitRite. Estos valores son el benchmark al que el presente proyecto debe apuntar.

**Bland-Altman plots:** gráficos que muestran la diferencia entre dos mediciones simultáneas en función del promedio de ambas, junto con la media de la diferencia (bias) y los límites de acuerdo del 95% (media ± 1.96 × SD). Permiten visualizar tanto el sesgo sistemático como la variabilidad random. Tanto Riglet como Lim los emplean.

**Pearson r:** correlación lineal entre las dos mediciones, complementaria al ICC. Es menos rigurosa que ICC porque no penaliza desplazamientos sistemáticos, pero es interpretable y ampliamente reportada.

**Cohen's d:** tamaño de efecto estandarizado para diferencias entre dos condiciones. Valores convencionales: d ≈ 0.2 pequeño, 0.5 medio, 0.8 grande, >1.0 muy grande. Shen et al. (2026) reportan Cohen's d de 1.62-2.20 para mejoras en parámetros temporales de su MFD-GED.

**Spearman ρ:** alternativa no-paramétrica a Pearson, útil cuando las distribuciones no son gaussianas.

Estos cinco indicadores constituyen el kit estándar de validación. Cualquier paper de smart insole serio los reporta.

## 10.2 Métricas específicas para detección de anomalías

Cuando el sistema actúa como anomaly detector, las métricas relevantes son las de un clasificador binario:

- **Sensibilidad (recall):** proporción de anomalías reales correctamente detectadas. Crítica en contextos clínicos donde no detectar una anomalía es más costoso que un falso positivo.
- **Especificidad:** proporción de zancadas normales correctamente clasificadas como normales. Si es baja, el sistema dispara feedback frecuentemente sin razón, lo que erosiona la adherencia.
- **AUC-ROC:** área bajo la curva característica receptor-operador. Resume la performance del clasificador a lo largo de todos los umbrales posibles. Brasiliano (2026) no la reporta directamente porque hace clasificación supervisada multi-modelo, pero Herbers (2024) la usa como métrica principal (AUC 0.91 para PD fallers), y Toth (2024-2025) la usa para validar OC-SVM (AUC 0.967).
- **F1 score:** media armónica de precision y recall, útil cuando hay desbalance de clases.
- **Falsos positivos por hora de uso:** métrica operacional clínicamente significativa. Un sistema que dispara feedback erróneo más de unas pocas veces por hora será percibido como intrusivo y abandonado.

## 10.3 Protocolos de evaluación experimental

La literatura ha consolidado dos protocolos básicos de evaluación para smart insoles:

**Pista de 10 metros (overground 10-Meter Walk Test, 10-MWT):** el sujeto camina sobre una pasarela recta de 10 metros a velocidad autoseleccionada. Múltiples repeticiones (mínimo 3, idealmente más). Es el protocolo de Brasiliano et al. (2026), de Lim et al. (2025), y de la mayoría de los estudios clínicos. Tiene la ventaja de ser representativo de marcha real y de duración corta que permite ejecutarlo con pacientes frágiles.

**Treadmill multi-velocidad:** el sujeto camina sobre cinta a velocidades pre-fijadas, típicamente lenta, autoseleccionada cómoda y rápida. Permite control fino de variables experimentales y mayor número de zancadas por trial. Riglet et al. (2023) lo combinan con el protocolo overground para validación cruzada.

Para validación adecuada, los siguientes parámetros deben definirse a priori:
- Número mínimo de zancadas por trial: Cerfoglio et al. (2025) sugieren >10 ciclos para mediciones confiables.
- Número de trials por condición: 3 es el mínimo, 5 es preferible.
- Período de habituación al treadmill antes de la captura: típicamente 1-2 minutos.
- Período de inicialización estática para alineación de IMUs: 3 segundos como en Riglet.

## 10.4 Análisis individualizado en cohortes pequeñas

Cuando la cohorte de validación es necesariamente pequeña — como suele ocurrir en estudios piloto con pacientes con stroke — el análisis grupal con tests estadísticos clásicos (t-test, ANOVA) puede no detectar diferencias significativas por baja potencia, incluso cuando cada paciente individual muestra desviaciones biomecánicamente significativas.

Min et al. (2026) [Applied Sciences 16(3):1406] proponen un marco metodológico explícito para este escenario. Sobre N=4 pacientes pediátricos con trastornos neurológicos comparados contra N=30 sanos, calcularon Z-scores por fase del ciclo de marcha contra la distribución normativa, generaron heatmaps por paciente y overlays cinemáticos individualizados. Sus análisis grupales con Statistical Parametric Mapping no mostraron diferencias significativas (p ≥ 0.05), pero el análisis individualizado identificó anormalidades clínicamente significativas en cada paciente, con varias desviaciones superando |2-5| SD del dataset normativo.

La conclusión metodológica de Min: los smartphones-based markerless motion capture permiten evaluación de marcha individualizada y sensible incluso cuando los estadísticos grupales son no significativos, soportando el uso del sistema como "exploratory, decision-support framework" más que como outcome measure de tratamiento.

Para el presente proyecto, este marco es directamente aplicable a la fase clínica: cada paciente actuará como su propio control (baseline pre-tratamiento, evolución post-tratamiento), y el análisis se basará en evolución individual de Z-scores y desviaciones contra normativa, no en comparaciones grupales subdimensionadas.

## 10.5 Diseño del estudio piloto clínico

El modelo de RCT pilot trial está bien establecido para evaluar smart insoles y wearables de rehabilitación. Guo et al. (2023) [JMIR mHealth 11:e40416] ejecutaron exactamente este tipo de estudio en stroke con su sistema wearable de remote rehabilitation training (registro chino ChiCTR2200061310). El paper de Ma et al. (2017) corresponde a estudios registrados (ChiCTR-IPB-15006530 y HKCTR-1853), aunque con cohorte pequeña (N=8).

Para el presente proyecto se propone una estructura de validación de tres niveles:

**Nivel 1 — Funcional con sujetos sanos.** Cohorte de N=25-30 sujetos sanos siguiendo el tamaño muestral de Riglet (N=30) y Lim (N=25), caminando en pista de 10 metros y treadmill a tres velocidades, con el dispositivo y un gold standard simultáneo (motion capture óptico o GaitRite según disponibilidad). Outcomes: ICC > 0.90 para parámetros espacio-temporales básicos, Bland-Altman para acuerdo absoluto.

**Nivel 2 — Detección de anomalías con sujetos sanos.** En subset de la cohorte sana, inducir anomalías controladas: cambio de calzado, peso asimétrico de 1 kg en una pierna, simulación de foot drop con vendaje rígido, obstáculos en pista. Medir sensibilidad, especificidad y AUC-ROC de cada algoritmo del pipeline (Mahalanobis, Isolation Forest, autoencoder, eventualmente LSTM-AE), comparar latencia de detección y footprint de memoria en el RP2350.

**Nivel 3 — Piloto clínico con pacientes con stroke.** Cohorte de N=8-15 pacientes con stroke leve a moderado (Functional Ambulation Classification ≥ 3, comparable al criterio de Brasiliano), siguiendo el modelo de Ma (N=8) o Guo (RCT pilot). Comparar detecciones del dispositivo contra evaluación clínica supervisada por kinesiólogo, y contra escalas estandarizadas: Berg Balance Scale, Fugl-Meyer Assessment, Modified Barthel Index, y los parámetros WBA y PSV del modelo de Jung et al. (2017) para riesgo de caída. Aprobación ética obligatoria; registro del trial en plataforma reconocida (ANMAT en Argentina, ClinicalTrials.gov internacional).

---

# Bloque 11 — Antecedentes y trabajo relacionado: posicionamiento del proyecto

## 11.1 Antecedentes europeos y comerciales

**WI-SHOE (CORDIS Project ID 605777)** es el antecedente europeo histórico más relevante. Desarrollado entre 2014 y 2015 con presupuesto FP7-SME de €1.497.990,80, coordinado en Chipre, su objetivo fue un sistema de calzado wearable wireless para monitoreo en tiempo real de parámetros de marcha y energy expenditure, con doble aplicación deporte + medicina (incluyendo stroke). Aunque cerrado hace una década, su Results in Brief y la documentación CORDIS sirven como precedente del concepto y permiten posicionar el presente proyecto en una trayectoria histórica de desarrollos europeos similares.

**DSPro de Zhortech (Riglet et al. 2023)** es el dispositivo comercial con validación clínica robusta más cercano al concepto. Es una plantilla con IMU embebido, sin sensores FSR plantares, pero validada extensivamente para parámetros espacio-temporales contra motion capture. Funciona como benchmark comercial.

**On-Foot Gait Lab (ACS 2025)** es la referencia tecnológica más cercana al concepto del proyecto: plantilla flexible con sensores piezocapacitivos electrospun PVAc-grafeno + IMU + sistema wireless, foco en home-based gait monitoring para Parkinson. Las dos diferencias clave frente al presente proyecto: usa piezocapacitivos en lugar de FSR (innovación de materiales pero pérdida de madurez tecnológica), y no implementa biofeedback cerrado en el dispositivo.

**FeetMe Monitor** es otra referencia citada en Sanchez-Morillo et al. (2025), validada por Farid et al. (2021) en Topics in Stroke Rehabilitation como alternativa válida para evaluación de velocidad de marcha post-stroke.

**Sistema de Sanchez-Morillo et al. (2025)** [Technologies 13(12):588] es el más comparable conceptualmente al proyecto: combina órtesis de pie inteligente, muleta instrumentada y app móvil para biofeedback multimodal, con foco en estrategia de feedback (pattern-based vs alert-based). La diferencia: ese sistema apunta a más superficie de sensorización y a la complementariedad órtesis-muleta, mientras el presente proyecto se concentra en una plantilla bilateral autocontenida.

## 11.2 Identificación del gap y contribución original

Frente a este panorama, la contribución original del presente proyecto se ubica en la **combinación integrada** de cuatro elementos que rara vez aparecen juntos en una única referencia:

1. **Hardware de bajo costo** basado en microcontrolador comercial de propósito general (Raspberry Pi Pico 2 W, ~USD 7) con sensores commodity (FSR Interlink ~USD 5 cada uno, IMU MEMS de 6 DOF ~USD 5).

2. **Detección de anomalías one-class personalizada y adaptativa** con calibración inicial por paciente y actualización online de los parámetros del modelo durante uso.

3. **Inferencia íntegramente edge**, sin dependencia de cloud, con latencia objetivo <50 ms desde la finalización de la zancada hasta el feedback.

4. **Biofeedback vibrotáctil cerrado** en el mismo dispositivo, con patrones diferenciados por tipo de anomalía detectada, calibrados para minimizar carga cognitiva.

La revisión sistemática de la literatura desarrollada en este documento permite afirmar que los trabajos previos típicamente abordan dos o tres de estos elementos pero raramente los cuatro de forma integrada en un único dispositivo wearable autónomo. Ma et al. (2017) integra biofeedback cerrado pero con lógica simple por umbral, sin anomaly detection en sentido estricto ni adaptación personalizada. Lee et al. (2024) [GAD] aborda anomaly detection online adaptive con LSTM, pero no incluye plantilla bilateral ni biofeedback. Kirubakaran et al. (2025) [EdgeSense] arquitectura edge sofisticada multimodal, sin foco específico en stroke ni biofeedback. Sanchez-Morillo et al. (2025) sistema integrado con biofeedback, pero sin anomaly detection one-class personalizada.

El gap identificado y la contribución del proyecto se alinean además con la visión estratégica de Beckerle et al. (2021) sobre la necesidad de personalización modular, procesamiento en tiempo real considerando variaciones humanas, modelos biomecánicos personalizados, learning on-chip y bajo consumo energético — todos atributos del proyecto.

## 11.3 Limitaciones reconocidas y trabajo a futuro

Es importante para el marco teórico reconocer explícitamente las limitaciones del enfoque, lo cual fortalece la honestidad académica del trabajo y abre la puerta a la sección de trabajo futuro del anteproyecto.

- **Cohorte de validación clínica pequeña.** En el alcance del proyecto inicial, la validación con pacientes con stroke será necesariamente un piloto (N=8-15), insuficiente para conclusiones definitivas pero adecuado para proof of concept (como Ma 2017 con N=8). Validación en cohortes mayores es trabajo futuro.

- **Limitación de sensores frente a Brasiliano (2026).** Cinco de las nueve features más discriminativas de Brasiliano provienen de sensores en cabeza/tronco que el proyecto no instrumenta. El sistema deberá compensar esta limitación con la complementariedad de los FSRs (no presentes en Brasiliano) y con la mayor riqueza de las features locales del pie.

- **Heterogeneidad clínica.** El stroke no es una enfermedad homogénea; los pacientes en cohortes piloto variarán en lateralidad, severidad, tiempo desde el evento, comorbilidades. La personalización mitiga pero no elimina este desafío.

- **Drift de IMU y calibración a largo plazo.** La calibración inicial es estática; a largo plazo, la posición del IMU dentro de la plantilla puede sufrir microdesplazamientos. Estrategias de recalibración periódica deben ser parte del plan.

- **Adherencia y aceptación.** El éxito clínico depende del uso sostenido por parte del paciente. La evaluación de usabilidad y carga cognitiva del biofeedback es esencial, siguiendo a Iwata et al. (2019).

---

# Referencias

A continuación se listan las referencias citadas, organizadas por orden de relevancia para el proyecto. Cada entrada incluye DOI cuando corresponde y la información necesaria para localizar y citar formalmente.

## Referencias centrales (citadas extensivamente)

1. **Brasiliano, P., Orejel-Bustos, A. S., Belluscio, V., Cereatti, A., Della Croce, U., Trabassi, D., Salis, F., Tramontano, M., Buzzi, M. G., Vannozzi, G., & Bergamini, E.** (2026). Identifying key gait features in stroke patients using wearable inertial sensors and supervised and unsupervised machine learning. *Scientific Reports*, 16, 8908. DOI: 10.1038/s41598-026-43666-7.

2. **Herbers, C., Zhang, R., Erdman, A., & Johnson, M. D.** (2024). Distinguishing features of Parkinson's disease fallers based on wireless insole plantar pressure monitoring. *npj Parkinson's Disease*, 10(1), 67. DOI: 10.1038/s41531-024-00678-2.

3. **Chen, X., Hu, D., Zhang, R., Pan, Z., Chen, Y., Xie, L., Luo, J., & Zhu, Y.** (2022). Interpretable evaluation for the Brunnstrom recovery stage of the lower limb based on wearable sensors. *Frontiers in Neuroinformatics*, 16, 1006494. DOI: 10.3389/fninf.2022.1006494.

4. **Toth et al.** (2024-2025). Bioinformatics-Inspired IMU Stride Sequence Modeling for Fatigue Detection Using Spectral–Entropy Features and Hybrid AI in Performance Sports. *Sensors*. PMC ID: PMC12845696.

5. **Riglet, L., Nicol, F., Leonard, A., Eby, N., Claquesin, L., Orliac, B., Ornetti, P., Laroche, D., & Gueugnon, M.** (2023). The Use of Embedded IMU Insoles to Assess Gait Parameters: A Validation and Test-Retest Reliability Study. *Sensors*, 23(19), 8155. DOI: 10.3390/s23198155.

6. **Ma, C. Z.-H., Zheng, Y.-P., & Lee, W.-C. C.** (2018). Changes in gait and plantar foot loading upon using vibrotactile wearable biofeedback system in patients with stroke. *Topics in Stroke Rehabilitation*, 25(1), 20-27. DOI: 10.1080/10749357.2017.1380339.

7. **Lim, H., Shin, J., Park, S., Park, B., & Lee, W.** (2025). Exploring the Reliability and Validity of Smart Insoles in Gait Parameter Measurement: A Cross-sectional Study. *Physical Therapy Rehabilitation Science*, 14(3), 282-292. DOI: 10.14474/ptrs.2025.14.3.282.

8. **Kang, D.** (2025). The Analysis of Gait Variables and Plantar Pressure Patterns in Community-Dwelling Elderly Patients with Hemiplegic Stroke. *Journal of Musculoskeletal Science and Technology*, 9(1), 25-35. DOI: 10.29273/jmst.2025.9.1.25.

## Referencias técnicas (sensórica, algoritmos)

9. **Eskofier, B. M. et al.** (2020). Does the Position of Foot-Mounted IMU Sensors Influence the Accuracy of Spatio-Temporal Parameters in Endurance Running? *Sensors*, 20(19), 5705. DOI: 10.3390/s20195705.

10. **Falbriard, M., Meyer, F., Mariani, B., Millet, G. P., & Aminian, K.** (2020). Drift-Free Foot Orientation Estimation in Running Using Wearable IMU. *Frontiers in Bioengineering and Biotechnology*, 8, 65. DOI: 10.3389/fbioe.2020.00065.

11. **Shen, Y. et al.** (2026). Improved running gait parameter estimation from single foot-mounted IMU data based on refined event detection. *Frontiers in Bioengineering and Biotechnology*, 13, 1714473. DOI: 10.3389/fbioe.2025.1714473.

12. **Lee, M.-C., Lin, J.-C., & Katsikas, S.** (2024). GAD: A Real-time Gait Anomaly Detection System with Online Adaptive Learning. arXiv:2405.09561.

13. **Kirubakaran, A. M. et al.** (2025). Real-Time Anomaly Detection on Wearables using Edge AI. *International Journal of Engineering Research & Technology*, 14(11). DOI: 10.5281/zenodo.18074824.

14. **Kang, I., Molinaro, D. D., Park, D., Lee, D., Kunapuli, P., Herrin, K. R., & Young, A. J.** (2025). Online Adaptation Framework Enables Personalization of Exoskeleton Assistance During Locomotion in Patients Affected by Stroke. *IEEE Transactions on Robotics*. PMC: PMC12435548.

15. **Nanayakkara, T., Herath, H. M. K. K. M. B., Sedigh Malekroodi, H., Madusanka, N., Yi, M., & Lee, B.** (2025). Phase-Specific Gait Characterization and Plantar Load Progression Analysis Using Smart Insoles. *Multimedia Information Technology and Applications (MITA 2025)*. Springer CCIS 2675, 197-208. DOI: 10.1007/978-981-95-3141-7_18.

16. **Pan, Z., Gao, H., Chen, Y., Xie, Z., & Xie, L.** (2023). Evaluation of Hemiplegic Gait Based on Plantar Pressure and Inertial Sensors. *IEEE Sensors Journal*, 23(11), 12008-12017. DOI: 10.1109/JSEN.2023.3268669.

17. **Seo, M., Shin, M.-J., Park, T. S., & Park, J. H.** (2020). Clinometric Gait Analysis Using Smart Insoles in Patients With Hemiplegia After Stroke: Pilot Study. *JMIR mHealth and uHealth*, 8(9), e22208.

18. **Chien, Y.-H. et al.** (2025). Assessing a Smart-Insole-Based System in Stroke Gait Pattern Recognition. *2025 IEEE International Conference on Bioinformatics and Biomedicine (BIBM)*, 6543-6550.

## Referencias clínicas (stroke, MS, falls)

19. **Matthews, P. M. et al.** (2018). Remote Monitoring in the Home Validates Clinical Gait Measures for Multiple Sclerosis. *Frontiers in Neurology*, 9, 561. DOI: 10.3389/fneur.2018.00561.

20. **Jung, S. H. et al.** (2017). Prediction of Post-stroke Falls by Quantitative Assessment of Balance. *Annals of Rehabilitation Medicine*, 41(3), 339-346. DOI: 10.5535/arm.2017.41.3.339.

21. **Guo, L., Wang, J., Wu, Q., Li, X., Zhang, B., Zhou, L., & Xiong, D.** (2023). Clinical Study of a Wearable Remote Rehabilitation Training System for Patients With Stroke: Randomized Controlled Pilot Trial. *JMIR mHealth and uHealth*, 11, e40416. DOI: 10.2196/40416.

22. **(2025).** Machine learning techniques for independent gait recovery prediction in acute anterior circulation ischemic stroke. *Journal of NeuroEngineering and Rehabilitation*. DOI: 10.1186/s12984-025-01548-5. PMC: PMC11786359.

23. **Min, Y.-S. et al.** (2026). Individualized Gait Deviation Profiling Using Image-Based Markerless Motion Capture in Pediatric Neurological Disorders. *Applied Sciences*, 16(3), 1406. DOI: 10.3390/app16031406.

24. **Sanghan, S., Leelasamran, W., & Chatpun, S.** (2014). Imbalanced Gait Characteristics Based on Plantar Pressure Assessment in Patients with Hemiplegia. *Walailak Journal of Science and Technology*, 12(7). DOI: 10.14456/1087.

## Referencias de revisión, perspectiva y antecedentes

25. **Cerfoglio, S., Lopes Storniolo, J., de Borba, E. F., Cavallari, P., Galli, M., Capodaglio, P., & Cimolin, V.** (2025). Smartphone-Based Gait Analysis with OpenCap: A Narrative Review. *Biomechanics*, 5(4), 88. DOI: 10.3390/biomechanics5040088.

26. **Beckerle, P. et al.** (2021). Adaptation Strategies for Personalized Gait Neuroprosthetics. *Frontiers in Neurorobotics*, 15, 750519. DOI: 10.3389/fnbot.2021.750519.

27. **Sanchez-Morillo, D. et al.** (2025). Smart Device Development for Gait Monitoring: Multimodal Feedback in an Interactive Foot Orthosis, Walking Aid, and Mobile Application. *Technologies*, 13(12), 588. DOI: 10.3390/technologies13120588.

28. **Iwata, H. et al.** (2019). Using a Vibrotactile Biofeedback Device to Augment Foot Pressure During Walking in Healthy Older Adults: A Brief Report. *Frontiers in Psychology*, 10, 1008. DOI: 10.3389/fpsyg.2019.01008.

29. **(2025).** On-Foot Gait Lab: A Hybrid Wearable Sensor Platform for Spatiotemporal Gait Analysis Using Electrospun Piezocapacitive Insoles and IMUs. *ACS Applied Engineering Materials*. DOI: 10.1021/acsaenm.5c00834.

30. **CORDIS Project ID 605777.** (2014-2015). WI-SHOE: A novel Wireless, wearable Shoe-based system for real time monitoring of Energy Expenditure and Gait parameters for Sport and Medical Applications. FP7-SME programme.

## Referencias secundarias

31. **Selves, C., Stoquart, G., & Lejeune, T.** (2020). Gait rehabilitation after stroke: Review of the evidence of predictors, clinical outcomes and timing for interventions. *Acta Neurologica Belgica*, 120, 783-790. (citado por Brasiliano et al. 2026).

32. **Bertoli, M. et al.** Reference de Brasiliano et al. (2026) para las ecuaciones de cálculo de features espacio-temporales.

33. **Pappas, I. P. I., Popovic, M. R., Keller, T., Dietz, V., & Morari, M.** (2001). A reliable gait phase detection system. *IEEE Transactions on Neural Systems and Rehabilitation Engineering*, 9, 113-125. (referencia clásica para detección de fases con sensores binarios en el pie).

34. **World Health Organization.** (2020). Reporte global de mortalidad citado por Chen et al. (2022).

35. **Brunnstrom, S.** (1966). Motor testing procedures in hemiplegia: Based on sequential recovery stages. *Physical Therapy*, 46, 357-375.

36. **Maranesi et al.** (2016). Referencia sobre zero crossings COP en personas que caen, citada por Herbers et al. (2024).

37. **Boukhennoufa, I., Zhai, X., Utti, V., Jackson, J., & McDonald-Maier, K. D.** (2022). Wearable sensors and machine learning in post-stroke rehabilitation evaluation: A systematic review. *Biomedical Signal Processing and Control*, 71, 103197.

---

# Apéndice: notas para la elaboración del marco teórico final

Este documento de trabajo contiene aproximadamente 15 mil palabras de información sintética sobre el dominio. Para la elaboración del marco teórico final del anteproyecto se sugiere:

- **Conservar íntegramente** la estructura de bloques 1, 3, 5, 6, 8 y 9, que son los más críticos para la justificación del proyecto.
- **Comprimir significativamente** los bloques 2, 4, 7 y 10, manteniendo sólo lo esencial.
- **Convertir el bloque 11** en una sección final de "Antecedentes y contribución original" o repartirlo entre la introducción del marco y el cierre.
- **Recortar las descripciones detalladas de los métodos** de Brasiliano (2026) y Herbers (2024) a lo esencial, conservando los hallazgos numéricos clave (3 features → 90% accuracy; 9 features → 96.7% accuracy; 9 features para fallers; AUC 0.91; etc.).
- **Conservar el listado de features de la sección 5.7** como tabla en el marco teórico, posiblemente comprimida en bloques sin perder el detalle de las fuentes.
- **Recortar las técnicas de Edge AI** del bloque 8 que no son centrales para el proyecto (knowledge distillation, pruning) si el espacio aprieta.
- **Mantener obligatoriamente** la subsección 5.7 (lista consolidada de features) y la 7.3 (online learning) por ser los elementos diferenciales del proyecto.

La traducción del lenguaje pedagógico de este documento al lenguaje formal académico del marco teórico final requerirá: eliminación de redundancias intencionales, supresión de paréntesis explicativos, conversión de listas extensas en prosa más densa, y compresión de ejemplos al mínimo necesario.
