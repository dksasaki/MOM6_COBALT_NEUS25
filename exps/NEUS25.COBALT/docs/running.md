# MOM6-COBALT-NEUS25 Running Guide

## Overview

This guide covers running MOM6-COBALT model after compilation and configuration setup. We provide two approaches: automated job chaining with `mom.sub.x` (SLURM-based) and direct execution. Notice that SLURM-based is system-dependent.

## Prerequisites

Before running:
- [ ] MOM6 executable compiled and linked in working directory
- [ ] All input files in `INPUT/` directory
- [ ] All configuration files are ready


## Method 1: Using mom.sub.x (SLURM Job Chaining)

The `mom.sub.x` script automates long simulations by breaking them into sequential jobs that fit within queue time limits.


### Setup

1. **Configure job parameters** in `mom.sub.x` header:
```bash
#SBATCH -J NEUS25_run            # Job name
#SBATCH --time=08:00:00          # Wall time per job
#SBATCH --ntasks=256             # Number of cores
#SBATCH --mem=32G                # Memory per node
#SBATCH --partition=compute      # Queue name
```

2. **Set run duration** in `input.nml`:
```fortran
&coupler_nml
  months = 3                     ! Months per job
  current_date = 1993,1,1,0,0,0  ! Start date (no need to change when restarting)
/
```

3. **Configure job sequencing** in `mom.sub.x`:
```bash
njobs=400                        ! Total number of jobs
```

**Important**: A file named `jobscompleted` tracks completed iterations. This file controls restart sequencing - each line represents a completed job number. When restarting after interruption, ensure this file reflects the correct number of completed jobs. Avoid changing the `months` parameter mid-simulation as `mom.sub.x` assumes consistent job durations.



### Running

Submit the first job:
```bash
sbatch --ntasks=256 mom.sub.x
```


The script will:
- Run the model for specified duration
- fill .template files `configs/MOM_override.template` and  `data_table.template`
- Archive outputs to `outputs_raw/`
- Save restarts to `restarts_raw/restarts.{job#}`
- Automatically submit the next job
- Continue until `njobs` is reached
- `mom.sub.x` assumes a `configs/MOM_layout.$ntasks` exists and points to the correct mask_table in input.



## Method 2: Direct Execution (Interactive/Manual)

For short tests, debugging, or systems without SLURM.

### Single Run

Set your environment (system-specific) - it should use the same .env file used to compile your mom6 executable. If `conda` environment is active, exit it, as it may link the wrong `$PATH` to fortran compilers.

```
source intel.env
```

### Manual Job Management

For longer runs without automatic chaining:

```bash
# Initial run (cold start)
echo "Starting year 1993"

thisyear=1993

# rewriting YEAR in templates
cat data_table.template | sed -e "s/<YEAR>/$thisyear/g" > data_table
cat configs/MOM_override.template | sed -e "s/<YEAR>/$thisyear/g" > configs/MOM_override

# Ensure cold start in input.nml
# Set: input_filename = 'n'

# For restart (year 1994)
# Set: input_filename = 'r' in input.nml

mpiexec -np 256 ./MOM6

```
