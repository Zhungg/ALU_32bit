# ALU32 DFT netlist import into Innovus Stylus Common UI

if {![info exists ::env(PROJ_ROOT)]} {
    error "PROJ_ROOT is not set. Source flow_config.sh before launching Innovus."
}

set root $::env(PROJ_ROOT)

# Specify design top and power/ground nets
set init_top_cell $::env(DESIGN)
set_db init_power_nets {VDD}
set_db init_ground_nets {VSS}

# Load timing constraints, libraries and RC corners
read_mmmc scripts/mmmc.tcl

# Load technology LEF first, followed by standard-cell LEF
read_physical -lef [list \
    $::env(LEF_TECH) \
    $::env(LEF_MACRO)]

# Use the netlist with scan cells inserted
read_netlist [file join \
    $root synthesis dft_run outputs alu_top_syn_dft.v]

# Initialize the design
init_design

puts "ALU32_IMPORT_INITIALIZATION_COMPLETED"
