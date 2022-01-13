SHELL := /bin/bash
# run all lines of a recipe in a single invocation of the shell rather than each line being invoked separately
.ONESHELL:
# invoke recipes as if the shell had been passed the -e flag: the first failing command in a recipe will cause the recipe to fail immediately
.POSIX:

##### Constants #####
HPCC_DIR := official-hpcc
SRC_DIR := src
HPCC_MAKEFILE := $(HPCC_DIR)/Makefile
HPCC_MAKEFILE_INCLUDE := $(SRC_DIR)/Make.Linux
# The build is broken on Ubuntu 20: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=952067
# I downloaded a patch (version 1.5.0-2.1): https://launchpad.net/ubuntu/+source/hpcc/+index
# TODO: check if the official site or github repo offers the new fixed sources
HPCC_LIB := $(HPCC_DIR)/hpl/lib/Linux/libhpl.a
USR_LIB := /usr/lib/x86_64-linux-gnu
INCLUDE_DIRS := $(HPCC_DIR)/include $(HPCC_DIR)/hpl/include $(USR_LIB)/openmpi/include
INCLUDE_FLAGS := $(addprefix -I,$(INCLUDE_DIRS))
DEPS := $(USR_LIB)/libcblas.a $(USR_LIB)/libatlas.a $(USR_LIB)/openmpi/lib/libmpi.so -lm
#FIXME: the input file is fixed to 8GB, so the code can't support other sizes right now
INPUT_FILE := hpccmemf.txt
CFLAGS := -Wall -Werror -pedantic -O3
ifdef DEBUG
	CFLAGS += -g
endif

##### Targets #####
BINARIES := hpl lat_bw mpi_fft mpi_random_access mpi_random_access_lcg ptrans single_dgemm single_fft single_random_access single_random_access_lcg single_stream star_dgemm star_fft star_random_access star_random_access_lcg star_stream
TEST_TARGETS := $(addprefix test-,$(BINARIES))

##### Recipes #####
.PHONY: all test clean

all: $(BINARIES)

$(BINARIES): %: $(SRC_DIR)/%.c $(HPCC_LIB)
	gcc -o $@ $(CFLAGS) $(INCLUDE_FLAGS) $< $(HPCC_LIB) $(DEPS)

$(HPCC_LIB): $(HPCC_MAKEFILE) $(HPCC_MAKEFILE_INCLUDE) | openmpi atlas
	cp -f $(HPCC_MAKEFILE_INCLUDE) $(HPCC_DIR)/hpl/Make.Linux
	cd $(HPCC_DIR)
	# "git apply" will fail if invoked twice
	-git apply ../$(SRC_DIR)/fix_mpi_error.patch
	make -j arch=Linux

$(HPCC_MAKEFILE):
	git submodule update --init --progress

test: $(TEST_TARGETS)

$(TEST_TARGETS): test-%: %
	mpirun -np 1 $<

clean:
	rm -f $(BINARIES)
	rm -f hpccoutf.txt
	cd $(HPCC_DIR)
	# "git apply" will fail if invoked twice
	-git apply -R ../$(SRC_DIR)/fix_mpi_error.patch
	make arch=Linux clean

.PHONY: openmpi atlas
openmpi:
	sudo apt install -y libopenmpi-dev

atlas:
	sudo apt install -y libatlas-base-dev

# empty recipe to prevent make from remaking the makefile:
# https://www.gnu.org/software/make/manual/html_node/Remaking-Makefiles.html
makefile: ;

