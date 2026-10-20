# Ethernet 10G Verification — Test Plan

Este documento define el plan inicial de verificación para los principales módulos Ethernet 10G de Taxi.

## Alcance

Se verificarán inicialmente los siguientes módulos:

```text
taxi_eth_mac_10g
taxi_eth_phy_10g
taxi_eth_mac_phy_10g
```

El objetivo de esta primera etapa es verificar el **datapath principal Ethernet 10G**.

Por ahora quedan fuera del alcance:

```text
PTP
PAUSE / LFC
PFC
estadísticas avanzadas
USXGMII
funciones opcionales de gearbox
```

---

# 1. `taxi_eth_mac_10g`

Interfaz principal:

```text
AXI Stream ↔ MAC ↔ XGMII
```

## MAC-TX-01 — Transmisión normal

**Estímulo**

Frame Ethernet válido por AXI Stream.

**Verificación**

```text
AXI
 ↓
MAC
 ↓
XGMII
```

Comprobar:

- datos transmitidos correctamente;
- framing XGMII válido;
- FCS correcto;
- ausencia de errores.

**Resultado esperado:** PASS si el frame recibido por XGMII corresponde al enviado por AXI.

---

## MAC-TX-02 — Padding

**Estímulo**

Frame menor al tamaño mínimo con:

```text
cfg_tx_pad_en = 1
```

**Verificación**

El MAC debe agregar padding hasta alcanzar el tamaño mínimo configurado.

Comprobar:

- datos originales sin modificar;
- padding agregado correctamente;
- FCS correcto.

---

## MAC-TX-03 — IFG

Transmitir dos frames consecutivos.

Comprobar que se respete:

```text
cfg_tx_ifg
```

entre ambas transmisiones.

---

## MAC-RX-01 — Recepción normal

**Estímulo**

Frame Ethernet válido por XGMII.

```text
XGMII
 ↓
MAC
 ↓
AXI Stream
```

**Resultado esperado**

El frame entregado por AXI debe coincidir con el frame recibido.

---

## MAC-RX-02 — FCS incorrecto

Inyectar un frame con FCS inválido.

**Resultado esperado**

El MAC debe detectar el error de FCS.

---

## MAC-RX-03 — Oversize

Enviar un frame mayor a:

```text
cfg_rx_max_pkt_len
```

**Resultado esperado**

El MAC debe detectar la condición de frame demasiado grande.

---

# 2. `taxi_eth_phy_10g`

Interfaz principal:

```text
XGMII ↔ PHY 10GBASE-R ↔ SERDES
```

## PHY-TX-01 — Data Block

Enviar ocho bytes de datos por XGMII.

**Resultado esperado**

Generación de un bloque 64B/66B válido:

```text
Sync Header = 01
```

---

## PHY-TX-02 — Start

Enviar una combinación XGMII que contenga:

```text
/S/
```

**Resultado esperado**

Generación del Control Block correspondiente a Start.

---

## PHY-TX-03 — Terminate

Enviar datos seguidos de:

```text
/T/
```

**Resultado esperado**

Generación correcta del Control Block de terminación.

---

## PHY-RX-01 — Decodificación

Inyectar bloques 64B/66B válidos desde SERDES.

**Resultado esperado**

Reconstrucción correcta de:

```text
XGMII RXD / RXC
```

---

## PHY-RX-02 — Block Lock

Enviar una secuencia continua de bloques válidos.

**Resultado esperado**

El receptor debe alcanzar:

```text
rx_block_lock = 1
```

---

## PHY-PRBS-01 — PRBS31

Habilitar:

```text
cfg_tx_prbs31_enable = 1
```

**Resultado esperado**

El tráfico normal debe ser reemplazado por el patrón PRBS31.

---

# 3. `taxi_eth_mac_phy_10g`

Interfaz principal:

```text
AXI Stream ↔ MAC ↔ PHY ↔ SERDES
```

## MP-TX-01 — Transmisión completa

Enviar un frame por AXI Stream.

**Resultado esperado**

El frame debe convertirse correctamente hasta una transmisión 10GBASE-R en SERDES.

---

## MP-RX-01 — Recepción completa

Inyectar una transmisión 10GBASE-R válida.

**Resultado esperado**

El frame original debe recuperarse por AXI Stream.

---

## MP-LOOP-01 — Loopback

Conectar:

```text
SERDES TX
    ↓
SERDES RX
```

Flujo:

```text
AXI TX
 ↓
MAC TX
 ↓
PHY TX
 ↓
SERDES TX
 ↓
SERDES RX
 ↓
PHY RX
 ↓
MAC RX
 ↓
AXI RX
```

**Resultado esperado**

```text
Frame TX == Frame RX
```

sin pérdida ni corrupción de datos.

---

# Prioridad de implementación

Primera etapa:

```text
1. MAC-TX-01
2. MAC-TX-02
3. MAC-RX-01
4. PHY-TX-01
5. PHY-RX-01
6. MP-TX-01
7. MP-RX-01
```

Después se agregarán:

```text
IFG
FCS inválido
oversize
block lock
bloques inválidos
PRBS31
loopback
```

---

# Estructura de verificación

Cada test seguirá conceptualmente:

```text
Test
 ↓
Driver
 ↓
DUT
 ↓
Monitor
 ↓
Checker / Scoreboard
 ↓
PASS / FAIL
```

La implementación se realizará inicialmente con **Cocotb**, reutilizando los drivers y monitors disponibles para AXI Stream, XGMII y 10GBASE-R/SERDES.
