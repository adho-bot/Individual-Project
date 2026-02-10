
# ---- Wave window 1: array_inst ----
set wcfg_array array_i
current_wave_config $wcfg_array
add_wave {{/KernelTest_tb/top_inst/array_inst}}
# Optional divider for readability

# ---- Wave window 2: ctrl_inst ----
set wcfg_ctrl ctrl_i
current_wave_config $wcfg_ctrl
add_wave {{/KernelTest_tb/top_inst/ctrl_inst}}

# Run the simulation (or use "run 1 us", etc.)
run -all

