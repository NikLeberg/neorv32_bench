# SPDX-License-Identifier: MIT

# Exit with code 1 on error
onerror {quit -code 1}

# Exit with code 1 on break (gets triggered on assertion failure)
onbreak {quit -code 1}

# Run the testbench.
vsim -quiet -c [lreplace $argv 0 4]
run -all

quit -f
