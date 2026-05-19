# 4×4 Systolic Array — Verilog Implementation
## Matrix Multiplication C = A × B

---

## File Overview

| File | Purpose |
|------|---------|
| `pe_mac.v` | Single Processing Element (PE) with internal MAC |
| `systolic_4x4.v` | 4×4 grid of PEs wired as a systolic array |
| `tb_systolic_4x4.v` | Testbench: feeds staggered inputs, checks results |

---

## Architecture Diagram

```
        b_in[0]  b_in[1]  b_in[2]  b_in[3]
           ↓        ↓        ↓        ↓
a_in[0] → PE[0][0] → PE[0][1] → PE[0][2] → PE[0][3]
           ↓          ↓           ↓           ↓
a_in[1] → PE[1][0] → PE[1][1] → PE[1][2] → PE[1][3]
           ↓          ↓           ↓           ↓
a_in[2] → PE[2][0] → PE[2][1] → PE[2][2] → PE[2][3]
           ↓          ↓           ↓           ↓
a_in[3] → PE[3][0] → PE[3][1] → PE[3][2] → PE[3][3]

Each PE[i][j] accumulates C[i][j] = Σ A[i][k] * B[k][j]
```

---

## How to Run

```bash
# Install (Ubuntu/Debian)
sudo apt-get install iverilog gtkwave

# Compile all three files
iverilog -g2012 -o systolic_sim tb_systolic_4x4.v systolic_4x4.v pe_mac.v

# Run simulation
vvp systolic_sim

# View waveforms (optional)
gtkwave systolic_4x4.vcd
```

