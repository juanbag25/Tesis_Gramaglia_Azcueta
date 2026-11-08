# Pinout — Smart Insole (Raspberry Pi Pico 2 W)

| GPIO  | Pin físico | Modo     | Conectado a                                   |
|-------|-----------:|----------|-----------------------------------------------|
| GP20  | 26         | I2C0 SDA | IMU                                           |
| GP21  | 27         | I2C0 SCL | IMU                                           |
| GP26  | 31         | ADC0     | FSR 1 — punta (divisor de tensión)            |
| GP27  | 32         | ADC1     | FSR 2 — talón (divisor de tensión)            |
| GP28  | 34         | ADC2     | FSR 3 — medial o lateral (divisor) — *próxima rev del PCB; el 4º, por mux (ADR-041)* |
| GP18  | 24         | PWM      | Base de transistor NPN → motor vibrador       |

## Notas rápidas

- **IMU:** comunicación por **I²C0** (GP20/GP21). Verificar dirección del esclavo según modelo (MPU-6050 típicamente 0x68/0x69). La traza **INT → GPIO libre** se rutea en la próxima rev del PCB, para el fallback DATA_READY (ADR-026).
- **FSRs:** cada FSR forma un divisor con una resistencia fija; la salida del divisor va al ADC. Lectura → tensión → cuentas del ADC. Por ahora no se pasa a fuerza: no se mide la curva (no lineal) de cada sensor y se trabaja en cuentas (ADR-058).
- **Motor vibrador:** controlado por **PWM en GP18** que ataca la base del NPN. El duty fija la intensidad base; los patrones de feedback se distinguen por **ritmo**, no por intensidad fina (ADR-027). Recordar diodo flyback en paralelo al motor.
- **ADC de RP2350:** 12 bits, referencia 3.3 V (V_ref via ADC_VREF, pin 35).
- **GP29 / ADC3:** no sale al header; mide **VSYS/3** (la tensión de la celda), que usa el corte por baja tensión de ADR-035. En el Pico 2 W esa línea se comparte con el reloj del SPI del chip de radio (CYW43439), así que leer VSYS hay que coordinarlo con el driver de la radio. Verificar en el datasheet al implementar.

> **Nota de arquitectura:** hoy hay **2 FSR conectados** (punta y talón — ADR-023). El máximo de diseño es **4** (ADR-041): el 3º va a **ADC2/GP28** y el 4º **exige un mux analógico**, porque GP29/ADC3 está ocupado midiendo VSYS. Confirmar contra el PCB al modificarlo (**CP-01**).
