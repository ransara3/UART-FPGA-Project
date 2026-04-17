# 50 MHz clock constraint for DE0-Nano
create_clock -name {CLOCK_50} -period 20.000 -waveform {0.000 10.000} [get_ports {CLOCK_50}]

# Derive PLL clocks automatically (if any)
derive_pll_clocks

# Derive clock uncertainty
derive_clock_uncertainty
