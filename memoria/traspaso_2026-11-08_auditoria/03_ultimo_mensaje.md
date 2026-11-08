# Último mensaje del agente a Tobías (mostrar tal cual)

> Contexto: Tobías había citado partes del diagnóstico (puntos 1 a 4) y pidió: *"Todo lo que te pedí que expliques, lo más breve posible pero que se entienda lo más posible."* Esta fue la respuesta.

---

## 1. Quién detecta los pasos

Durante una captura, alguien tiene que mirar la señal de los FSR y marcar "acá el pie tocó el piso" (IC) y "acá se levantó" (TO), y numerar las zancadas: 1, 2, 3…

Hay dos lugares donde se puede hacer:
- **En el micro, en vivo**, mientras se camina.
- **En Python, después**, en la computadora, sobre el crudo grabado.

Para la tesis se decidió lo segundo: el micro sólo graba y manda. Pero el README del firmware, la Vista 2 y el esquema de la base siguen diciendo que lo hace la plantilla. Quien programe el firmware puede ponerse a escribir un detector de pasos que no hace falta.

Esta decisión afecta tres cosas:
- **La base.** Cada zancada se identifica como "sesión + pie + número". Si después del piloto se ajustan los umbrales y se vuelve a correr Python, la numeración cambia: la zancada 57 pasa a ser otro paso. Hace falta una regla, por ejemplo: reprocesar es borrar la sesión y volver a escribirla.
- **La calibración.** Los documentos dicen que en la calibración el micro calcula features, y en la tesis no las va a calcular. La calibración tiene que ser una captura como las demás.
- **La corrección del giróscopo.** El giróscopo se va corriendo de a poco. El truco para corregirlo es ponerlo en cero cada vez que el pie está apoyado y quieto, y eso lo detecta el FSR. Si el micro no detecta pasos, no puede usar el truco. Y lo que el micro le hace al IMU queda grabado en el dato: después no se puede rehacer.

**Recomendación:** escribir que en la tesis el micro sólo adquiere y manda, que Python detecta y numera, y que el giróscopo se corrige con lo que ya trae Fusion.

## 2. Cómo saber qué es cada sesión

En los experimentos se graba a voluntarios sanos caminando normal y después con anomalías inducidas (peso de un lado, *foot drop* simulado…). Después hay que preguntarle al modelo: "¿marcás como raras las zancadas anómalas y no las normales?". Para poder evaluar esa respuesta, cada zancada tiene que tener una etiqueta: "calibración", "normal", "*foot drop* derecho"…

Hoy la base no tiene un campo para eso: sólo hay un `notes` de texto libre. Las etiquetas terminarían escritas a mano y con errores.

**Recomendación:** cada condición se graba como una sesión aparte, y la sesión lleva un campo "para qué es" con sus detalles. Hay que definirlo junto con el protocolo (20/11), porque el protocolo es el que dice qué condiciones va a haber.

## 3. Qué dato del IMU viaja

**Marco.** El IMU mide la aceleración en sus propios ejes, los del chip. Como el pie gira, el "x del chip" a veces apunta hacia adelante y a veces hacia abajo. Para tener aceleración "hacia adelante" o "vertical", hay que rotarla a ejes fijos. La muestra tiene lugar para una sola versión, y ningún documento dice cuál viaja. Si el micro la manda ya rotada y Python la vuelve a rotar, el dato sale mal y nadie se da cuenta. Pasa lo mismo con los ángulos: hay que dejar escrito cómo se calculan.

**Offset nivelado.** Quieto, el acelerómetro mide la gravedad: 9,81 hacia abajo. La calibración que está escrita dice: "si en z no da 9,81, la diferencia es error del sensor, se resta". Eso funciona sólo si el sensor está perfectamente horizontal. El de la cintura queda inclinado sobre la espalda baja, así que parte de la gravedad cae en otro eje. La calibración "corregiría" esa parte como si fuera error, y quedaría una aceleración falsa para siempre. La pose de parado está para medir esa inclinación, no para borrarla. Y como la calibración no se guarda, el error no se puede deshacer.

## 4. El emparejamiento Bluetooth

**Para qué se empareja.** La cintura habla con la laptop por Bluetooth. La primera vez se emparejan: intercambian una clave secreta para cifrar lo que viaja, porque son datos de salud. Después se recuerdan, como los auriculares que se reconectan solos. Ese recuerdo se llama *bond*.

**El passkey.** Es un número impreso en la cintura que se tipea en la laptop al emparejar, para confirmar que es tu cintura y no otro equipo. Emparejar sin número se llama *Just Works*: también cifra, pero alguien cerca podría colarse justo en ese momento. ADR-028 lo descartó.

**El problema con bleak.** bleak es la librería de Python que usa el host para hablar Bluetooth. En Windows sólo sabe emparejar sin número, así que el número no se puede pedir desde la app de control. La salida es emparejar una vez desde Configuración → Bluetooth de Windows, que sí pide el número, y después la app se conecta sola. No es grave: sólo cambia el paso de emparejar.

**El gesto.** Los auriculares tienen un botón para "aceptar un equipo nuevo"; la cintura no tiene botones. El diseño era este: acepta un emparejamiento sólo si nunca se emparejó, y para emparejar otra vez se la sacude 5 segundos. Con el gesto pasado a trabajo futuro:
- Si se empareja primero la laptop de Juan, la de Tobías ya no puede emparejarse.
- Si Windows "olvida" la cintura, la cintura sigue creyendo que está emparejada y rechaza el pedido nuevo.

**Recomendación:** que la cintura acepte un emparejamiento nuevo siempre que no esté conectada a nada. El número impreso sigue protegiendo.

---

## Pregunta que quedó abierta

**¿Registro las cuatro decisiones como cuestiones pendientes?**

- **Sí, registralas** (recomendada)
- **Empezá por la 1**
