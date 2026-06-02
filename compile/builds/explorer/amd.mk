############
# Command Macros
FC = mpif90
CC = mpicc
CXX = mpicxx
LD = mpif90 $(MAIN_PROGRAM)

#######################
# Build target macros
#
# Macros that modify compiler flags used in the build.  Target
# macros are usually set on the call to make:
#
#    make REPRO=on NETCDF=3
#
# Most target macros are activated when their value is non-blank.
# Some have a single value that is checked.  Others will use the
# value of the macro in the compile command.

DEBUG =              # If non-blank, perform a debug build (Cannot be
                     # mixed with REPRO or TEST)

REPRO =              # If non-blank, perform a build that guarantees
                     # reproducibility from run to run.  Cannot be used
                     # with DEBUG or TEST

TEST  =              # If non-blank, use the compiler options defined in
                     # the FFLAGS_TEST and CFLAGS_TEST macros.  Cannot be
                     # used with REPRO or DEBUG

VERBOSE =            # If non-blank, add additional verbosity compiler
                     # options

OPENMP =             # If non-blank, compile with openmp enabled

NO_OVERRIDE_LIMITS = # If non-blank, do not use the -qoverride-limits
                     # compiler option.  Default behavior is to compile
                     # with -qoverride-limits.

NETCDF =             # If value is '3' and CPPDEFS contains
                     # '-Duse_netCDF', then the additional cpp macro
                     # '-Duse_LARGEFILE' is added to the CPPDEFS macro.

INCLUDES =           # A list of -I include directories to be added to
                     # the compile command.

SSE =                # Additional SIMD options. If blank, znver2 defaults
                     # are used via -march=znver2.

COVERAGE =           # Add the code coverage compile options.

# Need to use at least GNU Make version 3.81
need := 3.81
ok := $(filter $(need),$(firstword $(sort $(MAKE_VERSION) $(need))))
ifneq ($(need),$(ok))
$(error Need at least make version $(need).  Load module gmake/3.81)
endif

# REPRO, DEBUG and TEST need to be mutually exclusive of each other.
# Make sure the user hasn't supplied two at the same time
ifdef REPRO
ifneq ($(DEBUG),)
$(error Options REPRO and DEBUG cannot be used together)
else ifneq ($(TEST),)
$(error Options REPRO and TEST cannot be used together)
endif
else ifdef DEBUG
ifneq ($(TEST),)
$(error Options DEBUG and TEST cannot be used together)
endif
endif

# Required Preprocessor Macros
CPPDEFS += -Duse_netCDF
CPPDEFS += -DHAVE_SCHED_GETAFFINITY

# Fortran preprocessor flags
# nf-config and nc-config from $SOFTWARE_DIR provide correct paths
# Requires environment script to be sourced before building
FPPFLAGS := $(INCLUDES)
FPPFLAGS += $(shell nf-config --fflags)

# C preprocessor flags
CPPFLAGS := $(INCLUDES)
CPPFLAGS += $(shell nc-config --cflags)

# Base set of Fortran compiler flags
# -march=znver2          : target AMD Zen2 architecture
# -mtune=znver2          : tune instruction scheduling for Zen2
# -fdefault-real-8       : promote default REAL to 64-bit (required by MOM6)
# -fdefault-double-8     : promote default DOUBLE PRECISION to 64-bit
# -fcray-pointer         : enable Cray pointer extension (used in FMS)
# -ffree-line-length-none: no limit on free-form source line length
# -fno-range-check       : disable compile-time constant range checking
#                          (note: does not affect runtime -fbounds-check)
# -Waliasing             : warn about aliasing violations
FFLAGS := -march=znver2 -mtune=znver2 \
          -fdefault-real-8 -fdefault-double-8 \
          -fcray-pointer -ffree-line-length-none \
          -fno-range-check -Waliasing

# Flags based on performance target
FFLAGS_OPT   = -O3
FFLAGS_REPRO = -O2 -fbounds-check
FFLAGS_DEBUG = -O0 -g -W -fbounds-check -fbacktrace \
               -ffpe-trap=invalid,zero,overflow

# Additional build option flags
FFLAGS_OPENMP   = -fopenmp
FFLAGS_VERBOSE  = -v
FFLAGS_COVERAGE = --coverage

# Base set of C compiler flags
CFLAGS := -march=znver2 -mtune=znver2

# Flags based on performance target
CFLAGS_OPT   = -O2
CFLAGS_REPRO = -O2
CFLAGS_DEBUG = -O0 -g

# Additional build option flags
CFLAGS_OPENMP   = -fopenmp
CFLAGS_VERBOSE  = -v
CFLAGS_COVERAGE = --coverage

# Optional testing flags — match production by default
FFLAGS_TEST := $(FFLAGS_OPT)
CFLAGS_TEST := $(CFLAGS_OPT)

# Linking flags
LDFLAGS :=
LDFLAGS_OPENMP   = -fopenmp
LDFLAGS_VERBOSE  =
LDFLAGS_COVERAGE = --coverage

# Libraries
# MPI linking is handled automatically by the mpif90/mpicc wrappers
# NetCDF-Fortran and NetCDF-C flags come from nf-config/nc-config
LIBS =
LIBS += $(shell nf-config --flibs)
LIBS += $(shell nc-config --libs)

# Apply flags based on target macros
ifdef REPRO
CFLAGS += $(CFLAGS_REPRO)
FFLAGS += $(FFLAGS_REPRO)
else ifdef DEBUG
CFLAGS += $(CFLAGS_DEBUG)
FFLAGS += $(FFLAGS_DEBUG)
else ifdef TEST
CFLAGS += $(CFLAGS_TEST)
FFLAGS += $(FFLAGS_TEST)
else
CFLAGS += $(CFLAGS_OPT)
FFLAGS += $(FFLAGS_OPT)
endif

ifdef OPENMP
CFLAGS  += $(CFLAGS_OPENMP)
FFLAGS  += $(FFLAGS_OPENMP)
LDFLAGS += $(LDFLAGS_OPENMP)
endif

ifdef SSE
CFLAGS += $(SSE)
FFLAGS += $(SSE)
endif

ifdef VERBOSE
CFLAGS  += $(CFLAGS_VERBOSE)
FFLAGS  += $(FFLAGS_VERBOSE)
LDFLAGS += $(LDFLAGS_VERBOSE)
endif

ifeq ($(NETCDF),3)
  ifneq ($(findstring -Duse_netCDF,$(CPPDEFS)),)
    CPPDEFS += -Duse_LARGEFILE
  endif
endif

ifdef COVERAGE
CFLAGS  += $(CFLAGS_COVERAGE)
FFLAGS  += $(FFLAGS_COVERAGE)
LDFLAGS += $(LDFLAGS_COVERAGE)
endif

LDFLAGS += $(LIBS)

#---------------------------------------------------------------------------
# you should never need to change any lines below.

RM = rm -f
TMPFILES = .*.m *.B *.L *.i *.i90 *.l *.s *.mod *.opt

.SUFFIXES: .F .F90 .H .L .T .f .f90 .h .i .i90 .l .o .s .opt .x

.f.L:
	$(FC) $(FFLAGS) -c $*.f
.f.opt:
	$(FC) $(FFLAGS) -c $*.f
.f.l:
	$(FC) $(FFLAGS) -c $(LIST) $*.f
.f.T:
	$(FC) $(FFLAGS) -c $*.f
.f.o:
	$(FC) $(FFLAGS) -c $*.f
.f.s:
	$(FC) $(FFLAGS) -S $*.f
.f.x:
	$(FC) $(FFLAGS) -o $*.x $*.f *.o $(LDFLAGS)
.f90.L:
	$(FC) $(FFLAGS) -c $*.f90
.f90.opt:
	$(FC) $(FFLAGS) -c $*.f90
.f90.l:
	$(FC) $(FFLAGS) -c $(LIST) $*.f90
.f90.T:
	$(FC) $(FFLAGS) -c $*.f90
.f90.o:
	$(FC) $(FFLAGS) -c $*.f90
.f90.s:
	$(FC) $(FFLAGS) -c -S $*.f90
.f90.x:
	$(FC) $(FFLAGS) -o $*.x $*.f90 *.o $(LDFLAGS)
.F.L:
	$(FC) $(CPPDEFS) $(FPPFLAGS) $(FFLAGS) -c $*.F
.F.opt:
	$(FC) $(CPPDEFS) $(FPPFLAGS) $(FFLAGS) -c $*.F
.F.l:
	$(FC) $(CPPDEFS) $(FPPFLAGS) $(FFLAGS) -c $(LIST) $*.F
.F.T:
	$(FC) $(CPPDEFS) $(FPPFLAGS) $(FFLAGS) -c $*.F
.F.f:
	$(FC) $(CPPDEFS) $(FPPFLAGS) -E -P $*.F > $*.f
.F.i:
	$(FC) $(CPPDEFS) $(FPPFLAGS) -E $*.F > $*.i
.F.o:
	$(FC) $(CPPDEFS) $(FPPFLAGS) $(FFLAGS) -c $*.F
.F.s:
	$(FC) $(CPPDEFS) $(FPPFLAGS) $(FFLAGS) -c -S $*.F
.F.x:
	$(FC) $(CPPDEFS) $(FPPFLAGS) $(FFLAGS) -o $*.x $*.F *.o $(LDFLAGS)
.F90.L:
	$(FC) $(CPPDEFS) $(FPPFLAGS) $(FFLAGS) -c $*.F90
.F90.opt:
	$(FC) $(CPPDEFS) $(FPPFLAGS) $(FFLAGS) -c $*.F90
.F90.l:
	$(FC) $(CPPDEFS) $(FPPFLAGS) $(FFLAGS) -c $(LIST) $*.F90
.F90.T:
	$(FC) $(CPPDEFS) $(FPPFLAGS) $(FFLAGS) -c $*.F90
.F90.f90:
	$(FC) $(CPPDEFS) $(FPPFLAGS) -E -P $*.F90 > $*.f90
.F90.i90:
	$(FC) $(CPPDEFS) $(FPPFLAGS) -E $*.F90 > $*.i90
.F90.o:
	$(FC) $(CPPDEFS) $(FPPFLAGS) $(FFLAGS) -c $*.F90
.F90.s:
	$(FC) $(CPPDEFS) $(FPPFLAGS) $(FFLAGS) -c -S $*.F90
.F90.x:
	$(FC) $(CPPDEFS) $(FPPFLAGS) $(FFLAGS) -o $*.x $*.F90 *.o $(LDFLAGS)
