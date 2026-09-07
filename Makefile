# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# SoCET Intro II Makefile - Alex Weyer, Miguel Isrrael Teran  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Project Directory
export PROJECT_ROOT := $(shell pwd)

export OPENLANE2_ROOT ?= $(HOME)/openlane2
export VOLARE_ROOT   ?= $(HOME)/.volare/volare
export PDK_VERSION   ?= 0fe599b2afb6708d281543108caf8310912f54af
export PDK_ROOT      ?= $(VOLARE_ROOT)/sky130/versions/$(PDK_VERSION)
export PDK           ?= sky130A
export PDK_PATH      ?= $(PDK_ROOT)/$(PDK)

export PATH := /home/shay/a/ece270/bin:$(PATH)
export LD_LIBRARY_PATH := /home/shay/a/ece270/lib:$(LD_LIBRARY_PATH)

# current project (for development)
PROJECT = stoplight_example

# "in-shell" (NanoHub) or "out-of-shell" otherwise
NIX_MODE := out-of-shell

YOSYS=yosys
NEXTPNR=nextpnr-ice40
SHELL=bash

MAP = verilog/gl/$(PROJECT)
TB	=  verilog/dv/$(PROJECT)
SRC = verilog/rtl/$(PROJECT)
BUILD = verilog/build/$(PROJECT)
WAVES = support/waves/$(PROJECT)

FPGA_TOP = fpga_top
FPGA_TOP_DIR = fpga/$(PROJECT)/fpga_top.sv
ICE   	= support/fpga/ice40hx8k.sv
UART	= support/fpga/uart*.v
PINMAP = support/fpga/pinmap.pcf
FPGA_TIMING_CELLS = support/fpga/*.v

DEVICE  = 8k
TIMEDEV = hx8k
FOOTPRINT = ct256

# PDK sky130A Standard Cell Libraries
LIBERTY := $(PDK_PATH)/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_100C_1v80.lib
VERILOG := $(PDK_PATH)/libs.ref/sky130_fd_sc_hd/verilog/primitives.v $(PDK_PATH)/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v

OPENLANE_RUN_TAG := $(shell date '+%y_%m_%d_%H_%M')

# Base OpenLane command
openlane_inner = \
	openlane \
	--run-tag $(OPENLANE_RUN_TAG) \
	$(PROJECT_ROOT)/openlane/$*/config.json

# Base KLayout command
klayout_inner = \
	klayout $(PROJECT_ROOT)/gds/$*.gds \
	-l $(PDK_PATH)/libs.tech/klayout/tech/$(PDK).lyp

ifeq ($(NIX_MODE),in-shell)
  openlane_cmd = $(openlane_inner)
  klayout_cmd  = $(klayout_inner)
else
  openlane_cmd = \
	nix-shell $(OPENLANE2_ROOT)/shell.nix --pure \
	--run "$(openlane_inner)"
  klayout_cmd = \
	nix-shell $(OPENLANE2_ROOT)/shell.nix --pure \
	--run "$(klayout_inner)"
endif

# Identify names of existing designs
designs := $(shell cd openlane 2>/dev/null && find * -maxdepth 0 -type d)

# ================================================
#               OpenLane Targets
# ================================================

# Note: these do not work on ECN environments

.PHONY: help
help:
	@cat "$(PROJECT_ROOT)/support/help.txt"

# List designs
.PHONY: list_designs
list_designs:
	@echo $(designs)

# Harden a Design with OpenLane 2
export OPENLANE_RUN_TAG = $(shell date '+%y_%m_%d_%H_%M')
.PHONY: $(designs)
$(designs) : % : $(PROJECT_ROOT)/openlane/%/config.json
	mkdir -p $(PROJECT_ROOT)/openlane/$*/runs/$(OPENLANE_RUN_TAG) 
	rm -rf $(PROJECT_ROOT)/openlane/$*/runs/$*
	ln -s $$(realpath $(PROJECT_ROOT)/openlane/$*/runs/$(OPENLANE_RUN_TAG)) openlane/$*/runs/$*
	$(openlane_cmd)
	@mkdir -p $(PROJECT_ROOT)/signoff/$*/
	@cp $(PROJECT_ROOT)/openlane/$*/runs/$*/final/*.csv $(PROJECT_ROOT)/signoff/$*/
	@cp $(PROJECT_ROOT)/openlane/$*/runs/$*/final/def/* $(PROJECT_ROOT)/def/$*.def
	@cp $(PROJECT_ROOT)/openlane/$*/runs/$*/final/sdc/* $(PROJECT_ROOT)/sdc/$*.sdc
	@cp $(PROJECT_ROOT)/openlane/$*/runs/$*/final/gds/* $(PROJECT_ROOT)/gds/$*.gds
	@cp $(PROJECT_ROOT)/openlane/$*/runs/$*/final/lef/* $(PROJECT_ROOT)/lef/$*.lef
	@cp $(PROJECT_ROOT)/openlane/$*/runs/$*/*magic-streamout/*.mag $(PROJECT_ROOT)/mag/$*.mag
	@cp $(PROJECT_ROOT)/openlane/$*/runs/$*/final/pnl/* $(PROJECT_ROOT)/verilog/gl/$*.v
	@cp $(PROJECT_ROOT)/openlane/$*/runs/$*/final/spice/* $(PROJECT_ROOT)/spi/lvs/$*.spice
	@cp $(PROJECT_ROOT)/openlane/$*/runs/$*/final/spef/nom/* $(PROJECT_ROOT)/spef/multicorner/$*.nom.spef
	@cp $(PROJECT_ROOT)/openlane/$*/runs/$*/final/spef/nom/* $(PROJECT_ROOT)/spef/$*.spef
	@cp $(PROJECT_ROOT)/openlane/$*/runs/$*/final/spef/min/* $(PROJECT_ROOT)/spef/multicorner/$*.min.spef
	@cp $(PROJECT_ROOT)/openlane/$*/runs/$*/final/spef/max/* $(PROJECT_ROOT)/spef/multicorner/$*.max.spef
	@cp $(PROJECT_ROOT)/openlane/$*/runs/$*/final/lib/nom*tt*/* $(PROJECT_ROOT)/lib/$*.lib
	@cp $(PROJECT_ROOT)/openlane/$*/runs/$*/resolved.json $(PROJECT_ROOT)/signoff/$*/
	@mkdir -p $(PROJECT_ROOT)/signoff/$*/openlane-signoff/timing-reports
	@cp $(PROJECT_ROOT)/openlane/$*/runs/$*/*magic-drc/reports/* $(PROJECT_ROOT)/signoff/$*/openlane-signoff/
	@cp $(PROJECT_ROOT)/openlane/$*/runs/$*/*netgen-lvs/reports/lvs.netgen.rpt $(PROJECT_ROOT)/signoff/$*/openlane-signoff/
	@cp $(PROJECT_ROOT)/openlane/$*/runs/$*/*netgen-lvs/reports/lvs.netgen.rpt $(PROJECT_ROOT)/signoff/$*/openlane-signoff/
	@cp $(PROJECT_ROOT)/openlane/$*/runs/$*/*netgen-lvs/netgen-lvs.log $(PROJECT_ROOT)/signoff/$*/openlane-signoff/
	@cp -r $(PROJECT_ROOT)/openlane/$*/runs/$*/*openroad-stapostpnr/summary.rpt $(PROJECT_ROOT)/signoff/$*/openlane-signoff/timing-reports
	@find $(PROJECT_ROOT)/openlane/$*/runs/$*/*openroad-stapostpnr/*/*.rpt -type 'f' -print0 | \
	xargs -0 -I {} sh -c '\
		file="{}"; \
		target_dir=$(PROJECT_ROOT)/signoff/$*/openlane-signoff/timing-reports/$$(basename $$(dirname $$file)); \
		mkdir -p $$target_dir; \
		cp $$file $$target_dir/;'

	@find $(PROJECT_ROOT)/openlane/$*/runs/$*/final/sdf -type 'f' -print0 | \
	xargs -0 -I {} sh -c '\
		file="{}"; \
		target_dir=$(PROJECT_ROOT)/signoff/$*/sdf/$$(basename $$(dirname $$file)); \
		mkdir -p $$target_dir; \
		cp $$file $$target_dir/$*.sdf;'

# Open GDSII of design in KLayout
.PHONY: gdsview_%_klayout
gdsview_%_klayout:
	@if echo "$(designs)" | grep -qw "$*"; then \
		if [ -f "$(PROJECT_ROOT)/gds/$*.gds" ]; then \
			echo "Opening GDSII layout of $* in KLayout..."; \
			$(klayout_cmd); \
		else \
			echo "Error: Design $* exists, but no GDSII file found"; \
			false; \
		fi; \
	else \
		echo "Error: Design $* does not exist"; \
		false; \
	fi

# Clean temporary files from previous OpenLane runs (i.e., "runs" folder)
.PHONY: clean_openlane
clean_openlane:
	@echo "Removing files of previous OpenLane runs of all designs...\n"
	@find openlane/*/ -maxdepth 1 -type d -name runs -exec rm -rf {} +
	@echo "Done!\n"

.PHONY: debug-nix
debug-nix:
	@echo "IN_NIX_SHELL = '$(IN_NIX_SHELL)'"
	@echo "NIX_MODE     = '$(NIX_MODE)'"
	@echo "openlane_cmd = $(openlane_cmd)"

# ================================================
#             Development targets
# ================================================

# Format a new design
.PHONY: setup_%
setup_%:
	@if echo "$(designs)" | grep -qw "$*"; then \
		echo "Design already exists!"; \
	else \
		mkdir -p "$(PROJECT_ROOT)/openlane/$*"; \
		touch "$(PROJECT_ROOT)/openlane/$*/config.json"; \
		cp "$(PROJECT_ROOT)/support/template/config.json" "$(PROJECT_ROOT)/openlane/$*/config.json"; \
		sed -i "s/sample_proj/$*/g" "$(PROJECT_ROOT)/openlane/$*/config.json"; \
		mkdir -p "$(PROJECT_ROOT)/verilog/rtl/$*"; \
		touch "$(PROJECT_ROOT)/verilog/rtl/$*/src1.sv"; \
		cp "$(PROJECT_ROOT)/support/template/example.sv" "$(PROJECT_ROOT)/verilog/rtl/$*/src1.sv"; \
		touch "$(PROJECT_ROOT)/verilog/rtl/$*/top.sv"; \
		cp "$(PROJECT_ROOT)/support/template/top.sv" "$(PROJECT_ROOT)/verilog/rtl/$*/top.sv"; \
		touch "$(PROJECT_ROOT)/verilog/rtl/$*/project.v"; \
		cp "$(PROJECT_ROOT)/support/template/project.v" "$(PROJECT_ROOT)/verilog/rtl/$*/project.v"; \
		sed -i "s/wrapper/$*/g" "$(PROJECT_ROOT)/verilog/rtl/$*/project.v"; \
		mkdir -p "$(PROJECT_ROOT)/support/waves/$*"; \
		mkdir -p "$(PROJECT_ROOT)/verilog/dv/$*"; \
		touch "$(PROJECT_ROOT)/verilog/dv/$*/src1_tb.sv"; \
		cp "$(PROJECT_ROOT)/support/template/src1_tb.sv" "$(PROJECT_ROOT)/verilog/dv/$*/src1_tb.sv"; \
		sed -i "s/<project>/$*/g" "$(PROJECT_ROOT)/verilog/dv/$*/src1_tb.sv"; \
		touch "$(PROJECT_ROOT)/verilog/dv/$*/top_tb.sv"; \
		cp "$(PROJECT_ROOT)/support/template/top_tb.sv" "$(PROJECT_ROOT)/verilog/dv/$*/top_tb.sv"; \
		sed -i "s/<project>/$*/g" "$(PROJECT_ROOT)/verilog/dv/$*/top_tb.sv"; \
		touch "$(PROJECT_ROOT)/verilog/dv/$*/fpga_top_tb.sv"; \
		cp "$(PROJECT_ROOT)/support/template/fpga_top_tb.sv" "$(PROJECT_ROOT)/verilog/dv/$*/fpga_top_tb.sv"; \
		sed -i "s/<project>/$*/g" "$(PROJECT_ROOT)/verilog/dv/$*/fpga_top_tb.sv"; \
		mkdir -p "$(PROJECT_ROOT)/fpga/$*"; \
		touch "$(PROJECT_ROOT)/fpga/$*/fpga_top.sv"; \
		cp "$(PROJECT_ROOT)/support/template/fpga_top.sv" "$(PROJECT_ROOT)/fpga/$*/fpga_top.sv"; \
		mkdir -p "$(PROJECT_ROOT)/docs/$*"; \
		touch "$(PROJECT_ROOT)/docs/$*/info.md"; \
		cp "$(PROJECT_ROOT)/support/template/info.md" "$(PROJECT_ROOT)/docs/$*/info.md"; \
		echo "Project setup successfully!"; \
	fi

# Setup sky130 PDK files
.PHONY: setup.pdk
setup.pdk:
	@python3 -m pip install --user --upgrade --no-cache-dir volare &&\
	mkdir -p pdks && \
	volare enable --pdk sky130 $(PDK_VERSION) &&\
	echo -e "\nPDK Setup Complete!\n"

# Thorough cleaning (remove all PDK files)
.PHONY: veryclean
veryclean: clean
	@rm -rf pdks &&\
	echo -e "PDK files removed!\n"

# Check environment (sky130A must be loaded)
.PHONY: check_env
check_env:
	@if [ -z "$$(ls -A $(PDK_ROOT) 2>/dev/null)" ]; then \
		echo -e "\nERROR: PDK not found! Have you run \"make setup.pdk\"?\n" >&2; exit 1; \
	else \
		echo -e "\nEnvironment setup correctly!\n"; \
	fi
# Source Compilation and simulation of Design
.PHONY: sim_%_src
sim_%_src: 
	@echo -e "Creating executable for source simulation...\n"
	@mkdir -p $(BUILD) && rm -rf $(BUILD)/*
	@iverilog -g2012 -o $(BUILD)/$*_tb -Y .sv -y $(SRC) $(TB)/$*_tb.sv
	@echo -e "\nSource Compilation complete!\n"
	@echo -e "Simulating source...\n"
	@vvp -l vvp_sim.log $(BUILD)/$*_tb
	@echo -e "\nSimulation complete!\n"
	@echo -e "\nOpening waveforms...\n"
	@if [ -f $(WAVES)/$*.gtkw ]; then \
		gtkwave $(WAVES)/$*.gtkw; \
	else \
		gtkwave $(WAVES)/$*.vcd; \
	fi

# Run synthesis on Design
.PHONY: syn_%
syn_%: check_env
	@echo -e "Synthesizing design...\n"
	@mkdir -p $(MAP)
	$(YOSYS) -d -p "read_verilog -sv -noblackbox $(SRC)/*; synth -top $*; dfflibmap -liberty $(LIBERTY); abc -liberty $(LIBERTY); clean; write_verilog -noattr -noexpr -nohex -nodec -defparam $(MAP)/$*.v" > $*.log
	@echo -e "\nSynthesis complete!\n"


# Compile and simulate synthesized design
.PHONY: sim_%_syn
sim_%_syn: syn_%
	@echo -e "Compiling synthesized design...\n"
	@mkdir -p $(BUILD) && rm -rf $(BUILD)/*
	@iverilog -g2012 -o $(BUILD)/$*_tb -DFUNCTIONAL -DUNIT_DELAY=#1 $(TB)/$*_tb.sv $(MAP)/$*.v $(VERILOG)
	@echo -e "\nCompilation complete!\n"
	@echo -e "Simulating synthesized design...\n\n"
	@vvp -l vvp_sim.log $(BUILD)/$*_tb
	@echo -e "\nSimulation complete!\n"
	@echo -e "\nOpening waveforms...\n"
	@if [ -f $(WAVES)/$*.gtkw ]; then \
		gtkwave $(WAVES)/$*.gtkw; \
	else \
		gtkwave $(WAVES)/$*.vcd; \
	fi

#Show the synthesied diagram
cells : $(ICE) $(SRC) $(FPGA_TOP_DIR) $(PINMAP)
	# lint with Verilator
	verilator --lint-only --top-module fpga_top -Werror-latch -y $(SRC) $(FPGA_TOP_DIR)
	# if build folder doesn't exist, create it
	mkdir -p $(BUILD)
	# synthesize using Yosys
	$(YOSYS) -p "read_verilog -sv -noblackbox $(ICE) $(UART) $(SRC)/* $(FPGA_TOP_DIR); synth -top fpga_top; show -format svg -viewer gimp"

#TODO: add cells_% target

# Lint Design and TB Only
.PHONY: vlint_%
vlint_%:
	@verilator --lint-only -Wall --timing -y $(SRC) $(SRC)/$*.sv $(TB)/$*_tb.sv
	@echo -e "\nNo linting errors found!\n"

# ================================================
#                  FPGA targets
# ================================================

# Check code and synthesize design into a JSON netlist
$(BUILD)/$(FPGA_TOP).json : $(ICE) $(SRC)/* $(FPGA_TOP_DIR) $(PINMAP)
	# lint with Verilator
	verilator --lint-only --top-module fpga_top -Werror-latch -y $(SRC) $(FPGA_TOP_DIR)
	# if build folder doesn't exist, create it
	mkdir -p $(BUILD)
	# synthesize using Yosys
# 	$(YOSYS) -p "read_verilog -sv -noblackbox $(ICE) $(UART) $(SRC)/*; synth_ice40 -top ice40hx8k -json $(BUILD)/$(FPGA_TOP).json"
	$(YOSYS) -p "read_verilog -sv -noblackbox $(ICE) $(UART) $(SRC)/* $(FPGA_TOP_DIR); \
    hierarchy -top ice40hx8k; \
    synth_ice40 -top ice40hx8k; \
    opt_clean -purge; clean -purge; \
    write_json -noscopeinfo $(BUILD)/$(FPGA_TOP).json" 


# Place and route design using nextpnr
$(BUILD)/$(FPGA_TOP).asc : $(BUILD)/$(FPGA_TOP).json
	# Place and route using nextpnr
	$(NEXTPNR) --hx8k --package ct256 --placer-heap-cell-placement-timeout 0 --pcf $(PINMAP) --asc $(BUILD)/$(FPGA_TOP).asc --json $(BUILD)/$(FPGA_TOP).json 2> >(sed -e 's/^.* 0 errors$$//' -e '/^Info:/d' -e '/^[ ]*$$/d' 1>&2)


# Convert to bitstream using IcePack
$(BUILD)/$(FPGA_TOP).bin : $(BUILD)/$(FPGA_TOP).asc
	# Convert to bitstream using IcePack
	icepack $(BUILD)/$(FPGA_TOP).asc $(BUILD)/$(FPGA_TOP).bin


# Perform timing analysis on FPGA design
fpga_time: $(BUILD)/$(FPGA_TOP).asc $(BUILD)/$(FPGA_TOP).json
	# Place and route using nextpnr (errors out here)
	$(NEXTPNR) --hx8k --package ct256 --placer-heap-cell-placement-timeout 0 --asc $(BUILD)/$(FPGA_TOP).asc --json $(BUILD)/$(FPGA_TOP).json 2> >(sed -e 's/^.* 0 errors$$//' -e '/^Info:/d' -e '/^[ ]*$$/d' 1>&2)
	icetime -tmd hx8k $(BUILD)/$(FPGA_TOP).asc


# Upload design to the FPGA's flash memory
flash: $(BUILD)/$(FPGA_TOP).bin
	# Program non-volatile flash memory with FPGA bitstream using iceprog
	iceprog $(BUILD)/$(FPGA_TOP).bin


# Upload design to the FPGA's non-volatile RAM
cram: $(BUILD)/$(FPGA_TOP).bin
	# Program volatile FPGA Configuration RAM (CRAM) with bitstream using iceprog
	iceprog -S $(BUILD)/$(FPGA_TOP).bin

#Show the synthesied diagram
fpga-cells : $(ICE) $(SRC) $(FPGA_TOP_DIR) $(PINMAP)
	# lint with Verilator
# 	verilator --lint-only --top-module fpga_top -Werror-latch -y $(SRC) $(FPGA_TOP_DIR)
	# if build folder doesn't exist, create it
	mkdir -p $(BUILD)
	# synthesize using Yosys
	$(YOSYS) -p "read_verilog -sv -noblackbox $(ICE) $(UART) $(SRC)/* $(FPGA_TOP_DIR); synth_ice40 -top fpga_top; show -format svg -viewer gimp"

# ================================================
#                 Other targets
# ================================================

# Clean temporary files
clean:
	rm -rf verilog/build/$(PROJECT) *.log support/waves/$(PROJECT)/*.vcd


# TODO: Add more targets for other tasks (maybe even more Caravel targets)
