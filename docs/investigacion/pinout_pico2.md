# Pinout — Smart Insole (Raspberry Pi Pico 2 W)

| GPIO  | Pin físico | Modo     | Conectado a                                   |
|-------|-----------:|----------|-----------------------------------------------|
| GP20  | 26         | I2C0 SDA | IMU                                           |
| GP21  | 27         | I2C0 SCL | IMU                                           |
| GP26  | 31         | ADC0     | FSR 1 (divisor de tensión)                    |
| GP27  | 32         | ADC1     | FSR 2 (divisor de tensión)                    |
| GP28  | 34         | ADC2     | FSR 3 (divisor de tensión) — *a confirmar en PCB* |
| GP18  | 24         | PWM      | Base de transistor NPN → motor vibrador       |

## Notas rápidas

- **IMU:** comunicación por **I²C0** (GP20/GP21). Verificar dirección del esclavo según modelo (MPU-6050 típicamente 0x68/0x69).
- **FSRs:** cada FSR forma un divisor con una resistencia fija; la salida del divisor va al ADC. Lectura → tensión → fuerza (curva no lineal del FSR).
- **Motor vibrador:** controlado por **PWM en GP18** que ataca la base del NPN. Cambiar duty cycle para modular intensidad. Recordar diodo flyback en paralelo al motor.
- **ADC de RP2350:** 12 bits, referencia 3.3 V (V_ref via ADC_VREF, pin 35).

> **Nota de arquitectura:** el pinout original documentaba 2 FSR (ADC0/ADC1). El diseño de arquitectura contempla **3 FSR por pie**; el tercero se asigna a **ADC2 = GP28 (pin 34)**. Confirmar contra el PCB real (punto abierto §17 del documento de arquitectura).
