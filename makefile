SHELL := /bin/bash
# run all lines of a recipe in a single invocation of the shell rather than each line being invoked separately
.ONESHELL:
# invoke recipes as if the shell had been passed the -e flag: the first failing command in a recipe will cause the recipe to fail immediately
.POSIX:

##### Constants #####

ROOT_DIR := $(PWD)
OFFICIAL_HPCC := official-hpcc
SRC_DIR := $(ROOT_DIR)/src
# The build is broken on Ubuntu 20: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=952067
# I downloaded a patch (version 1.5.0-2.1): https://launchpad.net/ubuntu/+source/hpcc/+index
# TODO: check if the official site or github repo offers the new fixed sources
PATCH := $(SRC_DIR)/fix_mpi_error.patch
USR_LIB := /usr/lib/x86_64-linux-gnu
INCLUDE_DIRS := $(OFFICIAL_HPCC)/include $(OFFICIAL_HPCC)/hpl/include $(USR_LIB)/openmpi/include
INCLUDE_FLAGS := $(addprefix -I,$(INCLUDE_DIRS))
DEPS := $(USR_LIB)/libcblas.a $(USR_LIB)/libatlas.a $(USR_LIB)/openmpi/lib/libmpi.so -lm
#FIXME: the input file is fixed to 1GB currently
INPUT_FILE := hpccmemf.txt
CFLAGS := -Wall -Werror -pedantic -O3
ifdef DEBUG
	CFLAGS += -g
endif

##### Targets #####

HPCC_MAKEFILE := $(OFFICIAL_HPCC)/Makefile
HPCC_MAKEFILE_INCLUDE := $(SRC_DIR)/Make.Linux
PATCH_WAS_APPLIED := $(ROOT_DIR)/patch_was_applied.txt
HPCC_LIB := $(OFFICIAL_HPCC)/hpl/lib/Linux/libhpl.a
BINARIES := hpl lat_bw mpi_fft mpi_random_access mpi_random_access_lcg ptrans single_dgemm single_fft single_random_access single_random_access_lcg single_stream star_dgemm star_fft star_random_access star_random_access_lcg star_stream
TEST_TARGETS := $(addprefix test-,$(BINARIES))

##### Recipes #####
.PHONY: all test clean unpatch

all: $(BINARIES)

$(BINARIES): %: $(SRC_DIR)/%.c $(HPCC_LIB)
	gcc -o $@ $(CFLAGS) $(INCLUDE_FLAGS) $< $(HPCC_LIB) $(DEPS)

$(HPCC_LIB): $(PATCH_WAS_APPLIED) $(HPCC_MAKEFILE_INCLUDE) | openmpi atlas
	cp -f $(HPCC_MAKEFILE_INCLUDE) $(OFFICIAL_HPCC)/hpl/Make.Linux
	cd $(OFFICIAL_HPCC)
	make -j arch=Linux

$(PATCH_WAS_APPLIED): $(HPCC_MAKEFILE)
	cd $(OFFICIAL_HPCC)
	git apply $(PATCH)
	# "git apply" will fail if invoked twice, so we use a flag
	touch $@

$(HPCC_MAKEFILE):
	git submodule update --init --progress $(OFFICIAL_HPCC)

test: $(TEST_TARGETS)

$(TEST_TARGETS): test-%: %
	mpirun -np 1 $<

clean:
	rm -f $(BINARIES)
	rm -f hpccoutf.txt
	cd $(OFFICIAL_HPCC)
	make arch=Linux clean

unpatch:
	# the following command will fail if invoked twice
	git apply -R $(PATCH)
	rm -f $(PATCH_WAS_APPLIED)

.PHONY: openmpi atlas
openmpi:
	sudo apt install -y libopenmpi-dev

atlas:
	sudo apt install -y libatlas-base-dev

# empty recipe to prevent make from remaking the makefile:
# https://www.gnu.org/software/make/manual/html_node/Remaking-Makefiles.html
makefile: ;

