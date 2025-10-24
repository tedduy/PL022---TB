#========================
# Define variables
#========================
TESTNAME ?= tb
TB_NAME  ?= tb
RADIX    ?= hexadecimal
SEED     ?= 1
#QUESTA_HOME ?= E:/FPT/QUESTA
#UVM_HOME ?= $(QUESTA_HOME)/verilog_src/uvm_1_1d/src
QUESTA_HOME ?= C:/intelFPGA_standard/24.1std/questa_fse
UVM_HOME ?= $(QUESTA_HOME)/uvm-1.1d/src
UVM_LIB ?= uvm_lib
#========================
# Default target
#========================

all: build run

#========================
# Build
#========================
build:
	@echo "UVM_HOME: $(UVM_HOME)"
	
	
	vlib $(UVM_LIB)
	vmap $(UVM_LIB) $(UVM_LIB)
	vlog -sv +incdir+"$(UVM_HOME)" -work $(UVM_LIB) "$(UVM_HOME)/uvm_pkg.sv"
	vlib work
	vmap work work
	vlog -sv  +incdir+$(UVM_HOME) -f compile.f -l compile.log 


#========================
# Run simulation
#========================
run:
	
	vsim -L $(UVM_LIB) -sv_seed $(SEED) -debugDB -l $(TESTNAME).log -voptargs=+acc -assertdebug -c $(TB_NAME) -do "log -r /*;run -all;" +$(TESTNAME)

#========================
# Open waveform
#========================
wave:
	vsim -L uvm -i  -view vsim.wlf -do "add wave vsim:/$(TB_NAME)/*; radix -$(RADIX)"

#========================
# Run simulation with GUI
#========================
gui:
	vsim -sv_seed $(SEED) -debugDB -l $(TESTNAME).log -voptargs=+acc -assertdebug $(TB_NAME) -do "log -r /*;add wave -r /*;run -all;" +$(TESTNAME)
# Clean (Windows)
#========================
#-del /Q /F *.ini >nul 2>&1
clean:
	-del /Q /F work >nul 2>&1
	-rmdir /S /Q work >nul 2>&1
	-del /Q /F vsim.dbg >nul 2>&1
	-del /Q /F *.ini >nul 2>&1
	-del /Q /F *.log >nul 2>&1
	-del /Q /F *.wlf >nul 2>&1
	-del /Q /F transcript >nul 2>&1

#========================
# Help
#========================
help:
	@echo.
	@echo ************************************
	@echo ** make build : compile the design and testbench
	@echo ** make run   : run simulation
	@echo ** make all   : compile and run simulation
	@echo ** make wave  : open waveform
	@echo ** make clean : clean all compiled data
	@echo ************************************