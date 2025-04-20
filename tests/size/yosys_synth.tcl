# SPDX-License-Identifier: MIT

# Import yosys commands into TCL.
yosys -import

# Synthesize selected configuration to generic 6-input LUTs.
ghdl --std=08 -gCONFIG=$::env(CONFIG_CODE) -gDEBUG=false -gHART_ID=0 neorv32.neorv32_litex_core_complex
synth -flatten -lut 6 -top neorv32_litex_core_complex
# alternative for ASICs: flatten -noscopeinfo; synth; abc -g cmos2

# Extract LUT6 and FF usage into JSON file.
tee -o stats_$::env(CONFIG_NAME).txt stat
tee -q -o stats_$::env(CONFIG_NAME).json stat -json

set json_result [exec jq {
  {
    lut6: .modules["\\neorv32_litex_core_complex"].num_cells_by_type["$lut"],
    ff:   [.modules["\\neorv32_litex_core_complex"].num_cells_by_type 
            | with_entries(select(.key | startswith("$_DFF"))) 
            | .[]] | add
  }
} stats_$::env(CONFIG_NAME).json]

puts $json_result
set outfile [open "size_$::env(CONFIG_NAME).json" "w"]
puts $outfile $json_result
close $outfile
