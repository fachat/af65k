# vhdl files
#FILES = src/* ../*.vhd
FILES = src/*.vhd

LIB65=af65002
LIB65DIR=af65002
LIB65FILES=../af65002/af65002pkg.vhd ../af65002/*.vhd 
LIB65DEP=$(LIB65DIR)/$(LIB65)-obj93.cf

VHDLEX = .vhd
 
# testbench
TESTBENCHPATH = ./${TESTBENCH}$(VHDLEX)
 
#GHDL CONFIG
GHDL_CMD = ghdl
#GHDL_FLAGS  = -fexplicit --ieee=synopsys --warn-no-vital-generic
GHDL_FLAGS  = -fexplicit --ieee=synopsys --warn-binding --warn-delayed-checks --warn-specs 
  
SIMDIR = simulation
# Simulation break condition
#GHDL_SIM_OPT = --assert-level=error
GHDL_SIM_OPT = --stop-time=40000ns
#GHDL_SIM_OPT = --stop-time=6804ns
#1599ns
#GHDL_SIM_OPT = --stop-time=600000ns 
#GHDL_SIM_OPT = --stop-time=6ns
 
WAVEFORM_VIEWER = gtkwave
   
all: $(LIB65DEP) compile run view
    
new :
	echo "Setting up project ${PROJECT}"
	mkdir src testbench simulation	

$(LIB65DEP) : $(LIB65FILES)
	$(GHDL_CMD) -a -g $(GHDL_FLAGS) --work=$(LIB65) --workdir=$(LIB65DIR) $(LIB65FILES)
 
compile :
ifeq ($(strip $(TESTBENCH)),)
		@echo "TESTBENCH not set. Use TESTBENCH=value to set it."
		@exit 2
endif                                                                                             
	mkdir -p simulation
	$(GHDL_CMD) -i $(GHDL_FLAGS) --workdir=$(LIB65DIR) --work=$(LIB65)
	$(GHDL_CMD) -i $(GHDL_FLAGS) -P$(LIB65DIR) --workdir=simulation --work=work $(TESTBENCHPATH) $(FILES) 
	$(GHDL_CMD) -m  $(GHDL_FLAGS) -P$(LIB65DIR) --workdir=simulation --work=work $(TESTBENCH) 
	@mv $(TESTBENCH) simulation/$(TESTBENCH)                                                                                
run :
	# @echo @$(SIMDIR)/$(TESTBENCH) $(GHDL_SIM_OPT) --vcdgz=$(SIMDIR)/$(TESTBENCH).vcdgz                                      
	# @$(SIMDIR)/$(TESTBENCH) $(GHDL_SIM_OPT) --vcdgz=$(SIMDIR)/$(TESTBENCH).vcdgz                                      
	@echo @$(SIMDIR)/$(TESTBENCH) $(GHDL_SIM_OPT) --wave=$(SIMDIR)/$(TESTBENCH).ghw                                      
	@$(SIMDIR)/$(TESTBENCH) $(GHDL_SIM_OPT) --wave=$(SIMDIR)/$(TESTBENCH).ghw                                      
		 				 				 	 
view :
	# gunzip --stdout $(SIMDIR)/$(TESTBENCH).vcdgz | $(WAVEFORM_VIEWER) --vcd $(TESTBENCH).sav  
	$(WAVEFORM_VIEWER) $(SIMDIR)/$(TESTBENCH).ghw $(TESTBENCH).sav 
 		 				 				 	 	 
clean :
	$(GHDL_CMD) --clean --workdir=simulation


smoke1:
	make all TESTBENCH=af65002_smoke1

