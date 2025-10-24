#========================
# Define variables
#========================
TESTNAME ?= tb
TB_NAME  ?= tb
RADIX    ?= hexadecimal
SEED     ?= 1
QUESTA_HOME ?= C:/intelFPGA_standard/24.1std/questa_fse

#========================
# Default target
#========================
all: build run

#========================
# Build
#========================
build:
	@echo ">>> Building design and testbench..."
	vlib work
	vmap work work
	vlog -sv -f compile.f -l compile.log
	@echo ">>> Compilation done!"

#========================
# Run simulation (console mode)
#========================
run:
	@echo ">>> Running simulation..."
	vsim -sv_seed $(SEED) -debugDB -l $(TESTNAME).log \
	     -voptargs=+acc -assertdebug -c $(TB_NAME) \
	     -do "log -r /*; run -all;"
	@echo ">>> Simulation completed!"

#========================
# Open waveform (GUI view)
#========================
wave:
	vsim -i -view vsim.wlf -do "add wave -r /*; radix -$(RADIX)"

#========================
# Run simulation with GUI
#========================
gui:
	vsim -sv_seed $(SEED) -debugDB -l $(TESTNAME).log \
	     -voptargs=+acc -assertdebug $(TB_NAME) \
	     -do "log -r /*; add wave -r /*; run -all;"

#========================
# Clean temporary files (Windows)
#========================
clean:
	-del /Q /F work >nul 2>&1
	-rmdir /S /Q work >nul 2>&1
	-del /Q /F vsim.dbg >nul 2>&1
	-del /Q /F *.ini >nul 2>&1
	-del /Q /F *.log >nul 2>&1
	-del /Q /F *.wlf >nul 2>&1
	-del /Q /F transcript >nul 2>&1
	@echo ">>> Clean done!"

#========================
# Help
#========================
help:
	@echo.
	@echo ************************************
	@echo ** make build : compile the design and testbench
	@echo ** make run   : run simulation in console mode
	@echo ** make gui   : run simulation in GUI mode
	@echo ** make wave  : open waveform viewer
	@echo ** make clean : remove temporary files
	@echo ************************************
