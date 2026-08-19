# Fundamento matemático: de la DFT al Improved Harmonic Ratio

> **Qué es este documento.** El desarrollo matemático completo detrás de la feature **#45 (IHR ML)** del bloque I, y en general de todo lo que el sistema hace con la FFT (también aplica al **bloque H**, SPEC-07). Está escrito para poder responder, con demostración y no con analogía, tres preguntas concretas:
>
> 1. ¿Por qué el bin *k* de la FFT **es** el armónico *k* de la zancada?
> 2. ¿Por qué los armónicos **pares** e **impares** separan la simetría de la marcha, y por qué esa asignación **no depende del paciente**?
> 3. ¿Qué se rompe exactamente si la ventana está mal cortada?
>
> **Punto de partida asumido:** que la transformada de Fourier toma una ventana de N muestras en el dominio del tiempo y devuelve una representación en el dominio de la frecuencia. Nada más.
>
> **Documentos relacionados:** ADR-040 (decisión y apéndice en llano) · SPEC-10 (guía de implementación) · SPEC-07 (FFT/DSP on-device, bloque H) · `ihr_armonicos_explicacion.html` (figura de apoyo).

---

## Resumen en una página

| Pregunta | Respuesta corta |
|---|---|
| ¿Qué es un bin? | El resultado de correlacionar la señal contra **una onda de prueba**. El bin *k* usa la onda que completa **exactamente *k* ciclos dentro de la ventana**. |
| ¿En qué unidad está *k*? | **Ciclos por ventana**, no hertz. Los Hz son una etiqueta posterior: $f_k = k / T_\text{ventana}$. |
| ¿Por qué sólo enteros? | Porque las ondas con un número entero de ciclos por ventana son **ortogonales entre sí** (§3). Una onda no entera contaminaría a las demás y ningún bin sería interpretable. Además, con N muestras sólo se pueden obtener N números independientes. |
| ¿Por qué bin *k* = armónico *k* de la zancada? | Porque se **elige** que la ventana sea exactamente una zancada. Entonces "ciclos por ventana" = "ciclos por zancada", que es la definición de armónico de la zancada. Es una tautología una vez elegido el corte (§6). |
| ¿Por qué pares/impares separan simetría? | Es un **teorema** sobre simetría de media onda (§7): si la segunda mitad de la ventana repite la primera, los coeficientes impares son **exactamente cero**; si la segunda mitad es la primera cambiada de signo, se anulan los **pares**. No hay ajuste empírico. |
| ¿Qué se rompe con una ventana mal cortada? | El fundamento cae **entre** bins. Como no existe un vector de base para esa frecuencia, la energía se expresa como combinación de todos los bins (*leakage*, §5) — y cae sobre armónicos de la paridad equivocada, que es exactamente lo que el IHR interpreta como asimetría. |
| ¿Se le aplica una ventana de Hann? | **No** (§9.2). Con la ventana enganchada al período no hay leakage que mitigar, y una Hann **movería energía entre bins vecinos, que son de paridad opuesta** — corrompería justo la magnitud que se mide. |

---

## 1. El problema, planteado

Tenés N muestras de una señal, tomadas a intervalos regulares: $x[0], x[1], \dots, x[N-1]$. En nuestro caso, la aceleración medio-lateral del tronco durante una zancada.

La idea de Fourier es escribir esa señal como **suma de ondas simples**. En el caso continuo e infinito eso involucra una integral sobre todas las frecuencias posibles. Pero acá el caso es **discreto y finito**: N números de entrada. Y eso cambia la pregunta de forma decisiva.

Con N números de entrada sólo se pueden producir **N números independientes** de salida. Así que la pregunta no es "¿qué frecuencias hay?" sino algo mucho más acotado:

> **¿Cuáles son las N ondas específicas que se usan como base, y por qué esas?**

Todo el resto sale de responder eso bien.

---

## 2. La DFT, leída pieza por pieza

La transformada discreta de Fourier es:

$$X[k] \;=\; \sum_{n=0}^{N-1} x[n]\, e^{-j 2\pi k n / N}, \qquad k = 0, 1, \dots, N-1$$

Leída de derecha a izquierda:

**El factor $e^{-j2\pi kn/N}$ es la onda de prueba.** Por la identidad de Euler, $e^{j\theta} = \cos\theta + j\sin\theta$, así que ese factor es un coseno y un seno al mismo tiempo. Usar los dos juntos es lo que permite capturar **amplitud y fase** en un solo número complejo: si la señal está desfasada respecto del coseno, la parte del seno lo recoge.

**La suma $\sum_n x[n]\cdot(\text{onda})$ es una correlación.** Multiplicar punto a punto y sumar es exactamente la operación "¿cuánto se parecen estas dos señales?". Si suben y bajan juntas, los productos son mayormente positivos y la suma es grande. Si no tienen relación, los productos se cancelan entre positivos y negativos y la suma tiende a cero.

**Y $k$ es lo que nos interesa.** Mirá el exponente cuando $n$ recorre toda la ventana, de $0$ a $N-1$:

$$\frac{2\pi k n}{N}\Big|_{n=0} = 0 \qquad\longrightarrow\qquad \frac{2\pi k n}{N}\Big|_{n=N-1} = 2\pi k\,\frac{N-1}{N} \;\approx\; 2\pi k$$

La fase recorre $2\pi k$ radianes a lo largo de la ventana. Es decir:

> **La onda de prueba del bin $k$ completa exactamente $k$ ciclos dentro de la ventana.**

Eso **es la definición de $k$**. No es una interpretación ni una consecuencia: está escrito en la fórmula.

### 2.1 La unidad de $k$ es "ciclos por ventana"

Notá que en todo lo anterior **no aparecieron los hertz**. La DFT no sabe nada de segundos: sólo sabe contar cuántas veces entra una onda en la ventana que le diste.

Los Hz aparecen después, como una etiqueta que uno le pone si quiere. Si la ventana contiene $N$ muestras tomadas a frecuencia de muestreo $f_s$, entonces dura $T_\text{ventana} = N/f_s$ segundos, y

$$f_k \;=\; k\,\frac{f_s}{N} \;=\; \frac{k}{T_\text{ventana}}$$

Ejemplo con nuestros números: una zancada de 1,20 s remuestreada a $N=256$ puntos. El bin 1 corresponde a $1/1{,}20 = 0{,}833$ Hz. El bin 2, a 1,667 Hz.

El **mismo paciente caminando más rápido**, zancada de 1,00 s, mismos 256 puntos: el bin 1 ahora es 1,0 Hz.

**Frecuencias absolutas distintas, mismo bin.** Porque en los dos casos es "un ciclo por zancada". Volveremos sobre esto en §6: es la propiedad que hace que todo el método funcione.

### 2.2 Cuántos bins son útiles

Para una señal real (que es nuestro caso), los bins de $k=N/2+1$ a $N-1$ son los conjugados de los primeros: $X[N-k] = \overline{X[k]}$. No aportan información nueva. Los bins útiles van de $k=0$ a $k=N/2$.

- $k=0$ es la **componente continua** (el promedio de la señal). Nótese que **0 es par** — importa para el IHR, ver §9.4.
- $k=N/2$ es la frecuencia de Nyquist: la onda más rápida representable, un ciclo cada dos muestras.

Con $N=256$: 129 bins útiles. Como el IHR sólo usa los primeros 10 o 20 armónicos, sobra por mucho.

---

## 3. Por qué exactamente esas ondas: ortogonalidad

Acá está el corazón del asunto. La pregunta era: ¿por qué las ondas de prueba son las de 0, 1, 2, 3… ciclos por ventana, y no cualquier frecuencia intermedia?

### 3.1 La propiedad

Definamos, para abreviar, $W_N = e^{-j2\pi/N}$. Las ondas de base son $W_N^{kn}$ para $k=0,\dots,N-1$. La propiedad clave es:

$$\sum_{n=0}^{N-1} e^{\,j 2\pi k n / N}\; e^{-j 2\pi m n / N} \;=\; \sum_{n=0}^{N-1} e^{\,j 2\pi (k-m) n / N} \;=\; \begin{cases} N & \text{si } k = m \\[4pt] 0 & \text{si } k \neq m \end{cases}$$

En palabras: **si correlacionás dos ondas de base distintas, el resultado es exactamente cero.** Son mutuamente ciegas.

### 3.2 Demostración

Es una suma geométrica. Llamemos $r = e^{j2\pi(k-m)/N}$.

**Caso $k=m$:** entonces $r = e^{0} = 1$, y la suma es $\sum_{n=0}^{N-1} 1 = N$.

**Caso $k \neq m$:** entonces $r \neq 1$ (porque $k-m$ es un entero entre $-(N-1)$ y $N-1$, distinto de cero, así que $2\pi(k-m)/N$ no es múltiplo de $2\pi$). Aplicamos la fórmula de la suma geométrica:

$$\sum_{n=0}^{N-1} r^n \;=\; \frac{1 - r^N}{1 - r}$$

Y ahora la clave:

$$r^N \;=\; \left(e^{\,j2\pi(k-m)/N}\right)^N \;=\; e^{\,j2\pi(k-m)} \;=\; 1$$

porque $k-m$ es **entero** y $e^{j2\pi \cdot \text{entero}} = 1$. Entonces el numerador es $1 - 1 = 0$, el denominador no es cero, y la suma vale **exactamente 0**. $\blacksquare$

### 3.3 Qué significa geométricamente

Los términos $r^n$ son N vectores unitarios en el plano complejo, espaciados un ángulo constante $2\pi(k-m)/N$. Al recorrer $n=0,\dots,N-1$ dan exactamente $(k-m)$ vueltas completas a la circunferencia, repartidos uniformemente. **Vectores repartidos de forma uniforme alrededor del círculo suman cero** — por la misma razón por la que las N raíces N-ésimas de la unidad suman cero.

Y ahí está el detalle que importa: eso pasa **porque $k-m$ es entero**. Si la onda de prueba tuviera, digamos, 1,5 ciclos por ventana, los vectores no cerrarían el círculo un número entero de veces, no se repartirían uniformemente, y la suma **no** daría cero.

### 3.4 Las dos consecuencias

**Primera: cada bin mide sólo lo suyo.** Si la señal es una suma de componentes de base, $x[n] = \sum_m c_m\, e^{j2\pi m n/N}$, entonces al correlacionar contra la onda $k$ todos los términos con $m \neq k$ se anulan y queda $X[k] = N c_k$. La medición es **limpia**: el bin 2 no recoge nada de energía que pertenezca al bin 1 o al 3.

Esta es la razón profunda por la que el conjunto de ondas enteras no es una convención sino la **única familia posible**. Si se agregara una onda de prueba de 1,5 ciclos, no sería ortogonal a las de 1 y 2 ciclos: su resultado sería una mezcla, y las tres mediciones se contaminarían entre sí. Ningún bin sería interpretable.

**Segunda: la transformada es invertible.** La ortogonalidad garantiza que las N ondas de base forman una **base ortogonal** del espacio de señales de largo N. Nada se pierde: existe la transformada inversa

$$x[n] \;=\; \frac{1}{N}\sum_{k=0}^{N-1} X[k]\, e^{\,j2\pi k n/N}$$

que reconstruye la señal original exactamente.

---

## 4. Amplitud, potencia y conservación de la energía

$X[k]$ es un número complejo. Sus dos partes tienen significado físico:

- $|X[k]|$ — la **amplitud** de esa componente en la señal.
- $\arg X[k]$ — su **fase**, o sea en qué punto del ciclo empieza.

Para el IHR sólo interesa la magnitud. Se define la **potencia** del armónico $k$:

$$P[k] \;=\; |X[k]|^2$$

### 4.1 Parseval: por qué se puede hablar de "fracción de la energía"

El teorema de Parseval para la DFT dice:

$$\sum_{n=0}^{N-1} |x[n]|^2 \;=\; \frac{1}{N}\sum_{k=0}^{N-1} |X[k]|^2$$

La energía total de la señal en el tiempo es igual (salvo el factor $1/N$) a la suma de las potencias de todos los bins. **La transformada no crea ni destruye energía: la reparte entre los armónicos.**

Esto es lo que le da sentido físico al IHR. Cuando se calcula

$$\text{IHR} \;=\; \frac{\sum P[\text{intrínsecos}]}{\sum P[\text{intrínsecos}] + \sum P[\text{extrínsecos}]}$$

se está midiendo una **fracción real de la energía de la señal**, no un cociente arbitrario entre dos números. Y por eso está acotado entre 0 y 1, y por eso es interpretable.

---

## 5. Periodicidad implícita y *spectral leakage*

### 5.1 La DFT supone que la señal se repite

Esto casi nunca se dice explícitamente y es la fuente de casi todos los malentendidos con la FFT.

La base $\{e^{j2\pi kn/N}\}$ está formada íntegramente por ondas **periódicas con período N**. Cualquier combinación de ellas también lo es. Entonces, cuando la DFT representa tu señal como combinación de esas ondas, está representando implícitamente una señal **periódica de período N**: la ventana repetida infinitamente, pegada consigo misma.

Dicho de otro modo: la DFT no ve "N muestras aisladas", ve "un loop de N muestras". Y los únicos ladrillos disponibles son los que se pueden pegar consigo mismos sin salto en la costura — que es exactamente la condición "número entero de ciclos por ventana".

### 5.2 Qué pasa si la señal no encaja

Supongamos que la señal contiene una componente cuya frecuencia real corresponde a $k_0$ ciclos por ventana, con $k_0$ **no entero**. Por ejemplo, cortaste 1,4 zancadas en vez de 1: el ritmo de la zancada es $k_0 = 1{,}4$ ciclos por ventana.

No existe ningún bin para 1,4. La DFT tiene que expresar esa componente como combinación de los bins que sí tiene, y el resultado es:

$$\left|\sum_{n=0}^{N-1} e^{\,j2\pi k_0 n/N} e^{-j2\pi k n/N}\right| \;=\; \left| \frac{\sin\big(\pi (k_0 - k)\big)}{\sin\big(\pi (k_0 - k)/N\big)} \right|$$

Esto se conoce como el **núcleo de Dirichlet**. Vale la pena mirarlo con cuidado:

- Si $k_0$ **es** entero, entonces para cualquier $k \neq k_0$ el numerador $\sin(\pi(k_0-k))$ es $\sin$ de un múltiplo entero de $\pi$, o sea **cero**. Toda la energía cae en un único bin. Esto es la ortogonalidad de §3, escrita de otra forma.
- Si $k_0$ **no** es entero, el numerador nunca se anula, y **todos los bins reciben algo**. La energía se desparrama con colas que decaen aproximadamente como $1/|k_0 - k|$.

El peor caso es $k_0 = k + 0{,}5$, justo entre dos bins: la energía se reparte de manera masiva entre los vecinos y las colas alcanzan a todo el espectro.

### 5.3 Por qué esto es letal para el IHR (y no para otras features)

Para una feature como "frecuencia dominante" o "potencia en la banda 0,5–2 Hz" (bloque H), el leakage es una molestia: ensancha los picos y contamina un poco las bandas.

Para el **IHR es letal**, y por una razón específica: **los bins vecinos son de paridad opuesta**. La energía que se derrama del bin 3 va principalmente a los bins 2 y 4 — que están en el conjunto contrario. O sea: el leakage **transfiere energía del conjunto intrínseco al extrínseco**, que es literalmente la cantidad que el IHR mide.

Un IC mal detectado no degrada el IHR: lo **falsea en la dirección de la asimetría**. Se lee asimetría donde no la hay.

De ahí la exigencia de SPEC-10 de descartar o marcar las zancadas cuyo IC vino con baja confianza. No es una precaución de higiene: es la condición de validez de la medición.

---

## 6. La solución: hacer que la ventana **sea** el período

La técnica habitual para mitigar el leakage es aplicar una **función de ventana** (Hann, Hamming, Blackman) que suaviza los bordes para que la señal "cierre". Es lo que hace SPEC-07 para el bloque H, que trabaja con una ventana deslizante de 256 muestras no enganchada a nada.

Pero para el bloque I se puede hacer algo mejor, y es la idea central del método:

> **En vez de mitigar el desajuste entre la ventana y el período, se elimina: se corta la ventana de modo que sea exactamente un período.**

Eso es posible porque el sistema **ya sabe dónde empieza y termina cada zancada**: las plantillas detectan el evento IC (SPEC-01) y la cintura los tiene sobre el timeline común (ADR-004).

### 6.1 El procedimiento

1. **Cortar** el segmento de aceleración de tronco entre $IC(n)$ e $IC(n+1)$. Ese segmento *es* una zancada, por definición del evento.
2. **Remuestrear** a un largo fijo $N$ (recomendado 256, potencia de 2 para `arm_rfft_fast_f32`). Cada zancada dura distinto: 1,20 s son 120 muestras a 100 Hz, 1,35 s son 135. La FFT necesita siempre el mismo N.
3. **Transformar** ese segmento.

### 6.2 Por qué el bin $k$ resulta ser el armónico $k$ de la zancada

Ahora es inmediato. Por §2, el bin $k$ es la onda que entra $k$ veces **en la ventana**. Por construcción, la ventana **es** una zancada. Entonces el bin $k$ es la onda que entra $k$ veces **en la zancada** — que es la definición del $k$-ésimo armónico de la zancada.

**No es un resultado, es una tautología** — una vez que se eligió el corte. Toda la dificultad del problema se trasladó a detectar bien el IC, y esa parte ya está resuelta (SPEC-01).

### 6.3 El remuestreo como cambio de variable

Vale la pena ver qué es realmente el paso 2. Remuestrear cada zancada a $N$ puntos fijos es un **cambio de variable independiente**: de tiempo $t$ (en segundos) a **fase del ciclo de marcha** $\tau \in [0,1)$ (en fracción de zancada).

$$\tau = \frac{t - t_{IC(n)}}{t_{IC(n+1)} - t_{IC(n)}}$$

En la variable $\tau$, toda zancada dura exactamente 1, sin importar la cadencia. Por eso el índice del bin queda **independiente de la velocidad de marcha**: el bin 1 es siempre "un ciclo por zancada", camine el paciente rápido o lento.

Es la misma normalización que usa toda la biomecánica cuando grafica "% del ciclo de marcha" en el eje horizontal en vez de segundos.

**Costo de esta operación:** el remuestreo es una interpolación, y toda interpolación es un filtrado suave. Con interpolación lineal se atenúan levemente los armónicos altos; con cúbica, menos. Como el IHR usa los primeros 10-20 armónicos de 128 disponibles, el efecto es chico — pero es un parámetro a fijar y verificar (SPEC-10), sobre todo porque en marcha hemipléjica la duración de zancada varía mucho más que en marcha sana.

---

## 7. La simetría par/impar, demostrada

Ahora la parte que responde la pregunta de por qué pares e impares separan la simetría, y por qué esa asignación no se calibra por paciente.

Sea $N$ **par** (256 lo es). Comparemos cada muestra con la que está media ventana después: $x[n]$ contra $x[n + N/2]$.

### 7.1 El resultado general

Partimos la suma de la DFT en dos mitades:

$$X[k] = \sum_{n=0}^{N/2-1} x[n]\, e^{-j2\pi kn/N} \;+\; \sum_{n=N/2}^{N-1} x[n]\, e^{-j2\pi kn/N}$$

En la segunda sustituimos $n = m + N/2$, con $m = 0,\dots,N/2-1$:

$$e^{-j2\pi k(m + N/2)/N} \;=\; e^{-j2\pi km/N}\cdot e^{-j\pi k} \;=\; e^{-j2\pi km/N}\cdot(-1)^k$$

**Este es el punto de giro de todo el argumento:** el desfasaje de media ventana introduce un factor $(-1)^k$. **Vale $+1$ si $k$ es par y $-1$ si $k$ es impar.** Toda la distinción par/impar sale de acá.

Entonces:

$$X[k] = \sum_{m=0}^{N/2-1}\Big( x[m] + (-1)^k\, x[m + N/2] \Big) e^{-j2\pi km/N}$$

### 7.2 Caso A — la segunda mitad **repite** la primera

Es el caso de la aceleración **vertical** y **antero-posterior** en marcha perfectamente simétrica: subís y bajás una vez por paso, y como los dos pasos son idénticos, la segunda mitad de la zancada reproduce la primera.

$$x[m + N/2] = x[m] \qquad \Longrightarrow \qquad X[k] = \big(1 + (-1)^k\big)\sum_{m=0}^{N/2-1} x[m]\, e^{-j2\pi km/N}$$

$$1 + (-1)^k = \begin{cases} 2 & k \text{ par} \\ 0 & k \text{ impar} \end{cases}$$

> **Los coeficientes impares son exactamente cero.** Toda la energía vive en los armónicos **pares**.

### 7.3 Caso B — la segunda mitad es la primera **cambiada de signo**

Es el caso de la aceleración **medio-lateral**: el tronco se desplaza hacia un lado cuando se carga una pierna, y hacia el otro cuando se carga la contraria. En marcha simétrica, la segunda mitad es la imagen espejada de la primera.

$$x[m + N/2] = -x[m] \qquad \Longrightarrow \qquad X[k] = \big(1 - (-1)^k\big)\sum_{m=0}^{N/2-1} x[m]\, e^{-j2\pi km/N}$$

$$1 - (-1)^k = \begin{cases} 0 & k \text{ par} \\ 2 & k \text{ impar} \end{cases}$$

> **Los coeficientes pares son exactamente cero.** Toda la energía vive en los armónicos **impares**.

### 7.4 La tabla, ahora con demostración detrás

| Eje | Relación en marcha simétrica | Se anulan | **Intrínsecos** | **Extrínsecos** |
|---|---|---|---|---|
| Vertical | $x[m+N/2] = x[m]$ | los impares | **pares** | impares |
| Antero-posterior | $x[m+N/2] = x[m]$ | los impares | **pares** | impares |
| **Medio-lateral** | $x[m+N/2] = -x[m]$ | los pares | **impares** | pares |

**"Intrínseco" no significa "par".** Significa *el conjunto que sobrevive cuando la marcha es simétrica*, y cuál es ese conjunto depende de **qué simetría tiene el movimiento de ese eje** — repetición o antisimetría. En vertical y AP son los pares; en medio-lateral, los impares.

### 7.5 Por qué no depende del paciente

Los resultados de §7.2 y §7.3 son **identidades algebraicas**. No hay ningún parámetro ajustable, ningún umbral, ninguna estimación. Se cumplen para cualquier señal que satisfaga la hipótesis de simetría, sea de quien sea.

Lo único que cambia de paciente a paciente es **cuánto se aparta la señal real de esa hipótesis**. La marcha hemipléjica no cumple $x[m+N/2] = \pm x[m]$: un paso es distinto del otro. Y esa diferencia —descomponiendo la señal en su parte simétrica y su parte antisimétrica— es exactamente lo que aparece en los coeficientes que "deberían" ser cero.

$$\underbrace{\text{energía en los extrínsecos}}_{\text{lo que no debería estar}} \;=\; \text{medida de la asimetría entre los dos pasos}$$

**La asignación es un teorema; la medición es la fuga.** Esa es la respuesta completa.

### 7.6 Por qué el eje ML y no el vertical

Brasiliano et al. (2026) encuentran el **IHR medio-lateral** como la feature más discriminativa, no la vertical ni la antero-posterior. La razón se lee en la tabla de §7.4.

En vertical y AP, la señal simétrica ya se repite dos veces por zancada: el patrón "normal" ocupa los armónicos pares y una asimetría tiene que abrirse paso contra una señal fuerte que vive en el mismo régimen. En **medio-lateral**, en cambio, la zancada completa —y no el paso— es el ritmo fundamental: la señal simétrica es antisimétrica de media ventana, y cualquier diferencia entre las piernas aparece en un conjunto de armónicos que **debería estar vacío**. La relación señal-ruido del contraste es estructuralmente mejor.

Sumado a que el tronco a la altura de L4-L5 está cerca del centro de masa —y por lo tanto integra el efecto de todo el cuerpo—, el IHR ML resume la asimetría global de la marcha en un solo número, con un solo sensor.

---

## 8. El Improved Harmonic Ratio

### 8.1 El HR clásico y su problema

La formulación original (Menz, Lord & Fitzpatrick, 2003) es un cociente directo:

$$HR_\text{clásico} = \frac{\sum_{k \in \text{intrínsecos}} A_k}{\sum_{k \in \text{extrínsecos}} A_k}$$

con $A_k = |X[k]|$. Tiene dos defectos prácticos: **no está acotado** (si el denominador tiende a cero, el cociente se va a infinito) y su distribución es fuertemente asimétrica, lo que complica cualquier tratamiento estadístico posterior.

### 8.2 La forma normalizada

La variante *improved* —que es la que registra el marco teórico del proyecto— normaliza contra el total:

$$\boxed{\;IHR_n \;=\; \frac{\sum_{i} P_i^{I}}{\sum_{i} \left( P_i^{I} + P_i^{E}\right)}\;}$$

donde $P^{I}$ y $P^{E}$ son las potencias de los armónicos intrínsecos y extrínsecos, sumadas hasta el armónico $n$.

Propiedades:

- **Acotado en $[0,1]$**, por construcción, y sin singularidades.
- **Interpretable directamente**: por Parseval (§4.1), es la **fracción de la energía de la señal que está donde corresponde**.
- $IHR \to 1$: marcha perfectamente simétrica. $IHR$ bajo: mucha energía en los armónicos equivocados, o sea asimetría.

> **A verificar contra la fuente antes de implementar.** La lógica par/impar de §7 es la base estándar del harmonic ratio y está demostrada acá. Pero **qué armónicos entran exactamente en cada conjunto en la variante concreta que usa Brasiliano et al. (2026)** —y si suman amplitudes o potencias— debe leerse del paper y citarse. Es un chequeo de una tarde y evita reportar un número que no sea comparable con la fuente.

---

## 9. Consecuencias prácticas para la implementación

Todo lo anterior aterriza en decisiones concretas. Esta sección es el puente hacia SPEC-10.

### 9.1 La calidad del IC es una condición de validez, no una preferencia

Por §5.3: un IC impreciso hace que la ventana no sea un período exacto, el leakage transfiere energía **entre conjuntos de paridad opuesta**, y el IHR reporta asimetría espuria.

**Regla:** descartar (o marcar) toda zancada cuyos IC de borde vengan con baja confianza desde SPEC-01. Las features #46 y #47 (RMS y LDLJ de tronco) **no** tienen esta sensibilidad: no dependen de que la ventana sea un período exacto.

### 9.2 No aplicar función de ventana (Hann) al segmento de zancada

Esto es contraintuitivo si uno viene de SPEC-07, donde la ventana de Hann es obligatoria. La diferencia es que allá la ventana deslizante **no** está enganchada al período de la señal, así que hay leakage que mitigar.

Acá pasa lo contrario, y aplicar una Hann sería **activamente dañino**. La transformada de una ventana de Hann tiene su lóbulo principal repartido en tres bins con pesos $(-\tfrac14, \tfrac12, -\tfrac14)$ en $k-1$, $k$, $k+1$. Es decir: enventanar convoluciona el espectro y **derrama la energía de cada armónico hacia sus dos vecinos**.

Y los vecinos de un bin son de **paridad opuesta**. O sea que una Hann movería sistemáticamente energía del conjunto intrínseco al extrínseco, sesgando el IHR hacia 0,5 en todos los sujetos.

**Regla: ventana rectangular** (sin taper) sobre el segmento enganchado a la zancada. Verificar numéricamente al implementar, con una señal sintética de IHR conocido.

### 9.3 Elección de $N$ (largo del remuestreo)

Recomendado **256**: potencia de dos para `arm_rfft_fast_f32` (SPEC-07 / ADR-019), da 129 bins útiles —sobradísimo para 10 o 20 armónicos— y el costo es despreciable (SPEC-07 midió <0,5 % de duty a ~1 Hz de cadencia).

El límite inferior lo pone la cantidad de muestras reales: una zancada de 1,0 s a 100 Hz son 100 muestras. Remuestrear 100 → 256 **no crea información**; sólo interpola. Los armónicos por encima del 50 son artefacto de la interpolación. Como usamos los primeros 10-20, no hay problema — pero conviene tenerlo escrito para que nadie lea significado en los bins altos.

### 9.4 Quitar la componente continua

El bin $k=0$ es el promedio de la señal, y **0 es par**. Si la aceleración de tronco tiene un offset (residuo de gravedad mal compensada, sesgo del sensor), ese offset entra íntegro al conjunto par e infla artificialmente el numerador en vertical/AP, o el denominador en ML.

**Regla: restar la media del segmento antes de transformar.** SPEC-04 ya entrega aceleración lineal sin gravedad, pero el residuo por zancada no es exactamente cero.

### 9.5 Cuántos armónicos sumar

La suma se corta en el armónico $n$ (la literatura usa 10 o 20). Es un parámetro **fijo para todos los pacientes**, así que no rompe la comparabilidad interna del sistema — pero un IHR calculado con $n=10$ **no es comparable** con uno publicado con $n=20$. Documentarlo junto al `feature_set_version`.

### 9.6 La velocidad de marcha es un confusor

El harmonic ratio disminuye con la velocidad incluso en sujetos sanos. Un paciente que camina más lento un día tendrá un IHR menor por un motivo que **no es** un empeoramiento de su patrón.

Como `stride_speed` (#7) ya está en el catálogo, la mitigación natural es **registrar la velocidad junto al IHR** y condicionar el baseline por rango de velocidad, o al menos tratarla como covariable en el análisis.

### 9.7 Lo que la personalización ya resuelve

El sistema es **one-class personalizado**: el baseline se construye con la calibración del propio paciente (~100 zancadas). Todo lo que sea **constante para ese paciente** —colocación del cinturón, altura, el $n$ elegido, un sesgo sistemático del método de remuestreo— se absorbe en el baseline y desaparece del score.

Lo único que **no** se absorbe es lo que varía **dentro** del mismo paciente entre sesiones. De la lista de arriba, eso es esencialmente la velocidad (§9.6).

---

## 10. Cómo verificar que está bien implementado

Las identidades de §7 dan tests exactos, sin necesidad de datos reales. Sirven como *golden vectors* para los tests de paridad C↔Python del CI (ADR-018 / ADR-021):

| Test | Señal sintética | IHR esperado (eje ML) |
|---|---|---|
| Simetría perfecta | $x[n] = \sin(2\pi n/N)$ (1 ciclo por ventana) | **1,00** — toda la energía en el armónico 1, impar |
| Antisimetría rota | $x[n] = \sin(2\pi \cdot 2n/N)$ (2 ciclos) | **0,00** — toda la energía en el armónico 2, par |
| Mezcla conocida | $\sin(2\pi n/N) + \tfrac{1}{2}\sin(2\pi\cdot 2n/N)$ | $\dfrac{1}{1 + 0{,}25} = \mathbf{0{,}80}$ (en potencias) |
| Invariancia a la cadencia | la misma forma, remuestreada desde 100 y desde 140 muestras | el mismo IHR (dentro de la tolerancia del remuestreo) |
| Sensibilidad al corte | la señal simétrica, cortada un 10 % larga | IHR **claramente menor** — reproduce el leakage de §5.3 |

El último es el más importante: confirma que el pipeline es sensible a la calidad del IC en la dirección prevista, y permite cuantificar cuánta imprecisión de corte es tolerable antes de descartar la zancada (§9.1).

---

## Referencias

**Del proyecto:**
`docs/decisiones/bitacora_decisiones.md` — **ADR-040** (decisión sobre el bloque I + apéndice conceptual en llano), ADR-019 (CMSIS-DSP), ADR-021 (catálogo y `feature_set_version`), ADR-018 (paridad), ADR-004 (sincronización y timeline común), ADR-030 (el bloque I recupera lo que el marco daba por perdido).
`docs/arquitectura/vistas/2_specs_algoritmos_firmware.md` — **SPEC-10** (implementación del bloque I), SPEC-01 (detección de IC y confianza), SPEC-04 (módulo IMU), SPEC-07 (FFT/PSD on-device, bloque H).
`docs/investigacion/ihr_armonicos_explicacion.html` — figura de apoyo (armónicos en las dos mitades de la zancada, espectros comparados).
`docs/marco_teorico/marco_teorico_documento_de_trabajo.md` — §"Symmetry features" (fórmula del IHR) y §5.2 (Brasiliano).

**Externas:**
Brasiliano et al. (2026), *Scientific Reports* 16:8908 — IHR ML en lower back como feature top-1; 90,2 % ± 5,5 % de accuracy con 3 features en clustering no supervisado.
Menz, Lord & Fitzpatrick (2003) — formulación original del harmonic ratio aplicada a aceleración de tronco.
Oppenheim & Schafer, *Discrete-Time Signal Processing* — DFT, ortogonalidad, Parseval, leakage y funciones de ventana.

---

*Documento de fundamento. Si algo de acá contradice a SPEC-10, manda SPEC-10 (es la guía de implementación) y hay que corregir este documento.*
