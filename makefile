# The commands in a recipe are passed to a single invocation of the Bash shell.
SHELL := /bin/bash
# run all lines of a recipe in a single invocation of the shell rather than each line being invoked separately
.ONESHELL:
# invoke recipes as if the shell had been passed the -e flag: the first failing command in a recipe will cause the recipe to fail immediately
.POSIX:

##### Constants #####
HPCC_DIR := hpcc
SRC_DIR := src
BUILD_DIR := build
HPCC_MAKEFILE := $(HPCC_DIR)/Makefile
MAKE_INCLUDE := $(BUILD_DIR)/hpl/Make.Linux
# The build is broken on Ubuntu 20: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=952067
# I downloaded a patch (version 1.5.0-2.1): https://launchpad.net/ubuntu/+source/hpcc/+index
# TODO: check if the official site or github repo offers the new fixed sources
HPCC_LIB := $(BUILD_DIR)/hpl/lib/Linux/libhpl.a
USR_LIB := /usr/lib/x86_64-linux-gnu
INCLUDE_DIRS := $(BUILD_DIR)/include $(BUILD_DIR)/hpl/include $(USR_LIB)/openmpi/include
INCLUDE_FLAGS := $(addprefix -I,$(INCLUDE_DIRS))
CFLAGS := -Wall -Werror -pedantic -O3
DEPS := $(USR_LIB)/libcblas.a $(USR_LIB)/libatlas.a $(USR_LIB)/openmpi/lib/libmpi.so -lm
#FIXME: the input file is fixed to 8GB, so the code can't support other sizes right now
INPUT_FILE := hpccmemf.txt

##### Targets #####
BINARIES := hpl lat_bw mpi_fft mpi_random_access mpi_random_access_lcg ptrans single_dgemm single_fft single_random_access single_random_access_lcg single_stream star_dgemm star_fft star_random_access star_random_access_lcg star_stream
TEST_TARGETS := $(addprefix test-,$(BINARIES))

##### Recipes #####
.PHONY: all test clean

all: $(BINARIES)

$(BINARIES): %: $(SRC_DIR)/%.c $(HPCC_LIB)
	gcc -o $@ $(CFLAGS) $(INCLUDE_FLAGS) $< $(HPCC_LIB) $(DEPS)

$(HPCC_LIB): $(MAKE_INCLUDE) | openmpi atlas
	cd $(BUILD_DIR)
	git apply ../$(SRC_DIR)/fix_mpi_error.patch
	make -j arch=Linux

$(MAKE_INCLUDE): $(HPCC_MAKEFILE)
	cp -rf $(HPCC_DIR) $(BUILD_DIR)
	cp -f $(SRC_DIR)/Make.Linux $@

$(HPCC_MAKEFILE):
	git submodule update --init --progress

test: $(TEST_TARGETS)

$(TEST_TARGETS): test-%: %
	mpirun -np 1 $<

clean:
	rm -rf $(BUILD_DIR) $(BINARIES)

.PHONY: openmpi atlas
openmpi:
	sudo apt install -y libopenmpi-dev

atlas:
	sudo apt install -y libatlas-base-dev

# empty recipe to prevent make from remaking the makefile:
# https://www.gnu.org/software/make/manual/html_node/Remaking-Makefiles.html
makefile: ;

