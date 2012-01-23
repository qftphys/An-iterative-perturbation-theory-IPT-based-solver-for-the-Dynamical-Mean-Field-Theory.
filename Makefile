HERE  =`pwd`
EXE=hmmpt_2dsquare
#ahmipt_zeroT_2dsquare
DIR=./drivers
DIREXE= $(HOME)/.bin

#########################################################################
include $(HOME)/lib/lib.mk
include $(HOME)/lib/libdmft.mk
#########################################################################


all: 	
	@echo " ........... compile: optimized ........... "
	$(FC) $(STD) $(DIR)/$(EXE).f90 -o $(DIREXE)/$(EXE) $(LIBDMFT) $(MODS) $(LIBS) 
	@echo " ...................... done .............................. "
	@echo ""
	@echo "created" $(DIREXE)/$(EXE)

opt: 	
	@echo " ........... compile: optimized ........... "
	$(FC) $(OPT) $(DIR)/$(EXE).f90 -o $(DIREXE)/$(EXE) $(LIBDMFT) $(MODS) $(LIBS)
	@echo " ...................... done .............................. "
	@echo ""
	@echo "created" $(DIREXE)/$(EXE)


debug: 	
	@echo " ........... compile : debug   ........... "
	$(FC) $(DEB) $(DIR)/$(EXE).f90 -o $(DIREXE)/$(EXE) $(LIBDMFT_DEB) $(MODS_DEB) $(LIBS_DEB) 
	@echo " ...................... done .............................. "
	@echo ""
	@echo "created" $(DIREXE)/$(EXE)


clean: 
	@echo 'removing *.mod *.o *~'
	@rm -f *.mod
	@rm -f *.o
	@rm -f *~
	@rm -vf $(DIREXE)/$(EXE)
