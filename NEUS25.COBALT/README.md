# NEUS25-MOM6-COBALT Setup and Usage Guide

## Repository Setup

### Clone the repository with submodules
```bash
git clone --recursive https://github.com/NOAA-GFDL/CEFI-regional-MOM6
```

### Navigate to the repository
```bash
cd CEFI-regional-MOM6
```

### Checkout the specific commit
```bash
git checkout 75c45e8a1965fe03332e574d106c35dda5887e64

```

### Update submodules to match the commit
```bash
git submodule update --recursive
```

### compilation
The compilation is system dependent, so I'll not get in details here.

---

## NEUS25 SLURM Job Script Documentation

### Overview
`mom.sub.x` is a SLURM batch script for running the CEFI-regional-MOM6 ocean model. It handles job sequencing, restart management, and file organization for long  simulations that require multiple sequential runs.

### SLURM Configuration
```bash
#SBATCH -J NWA25_NEUS_bp          # Job name
#SBATCH --error=NWA25_NEUS.err    # Error output file
#SBATCH --output=NWA25_NEUS.out   # Standard output file
#SBATCH --time=08:00:00           # Maximum runtime (8 hours)
#SBATCH --partition=short         # SLURM partition
#SBATCH --mem=32G                 # Memory allocation
#SBATCH --constrain=ib            # InfiniBand constraint
```

### Key Variables
- `ntasks`: Number of MPI tasks from SLURM environment
- `njobs`: Total number of sequential jobs (set to 400)
- `thisjob`: Current job number in the sequence
- `month_dt`: Time interval in months per job (read from `input.nml` coupler_nml section, accepts 1-12 months)
- `thisyear`: Calculated year for current simulation period

### Workflow

#### 1. Environment Setup
- Sources Intel environment (`intel.env`)
- Creates necessary directories: `RESTART`, `outputs_raw`, `restarts_raw`, `logs`
- Sets up MOM6 layout configuration based on task count

#### 2. Job Tracking
- Reads `jobscompleted` file to determine current job number
- Increments job counter for current run
- Modifies `input.nml` configuration:
  - Job #1: Cold start (`input_filename = 'n'`)
  - Jobs #2+: Restart from previous run (`input_filename = 'r'`)

#### 3. Time Management
- Reads time interval from `input.nml` in the `&coupler_nml` section (`months` parameter)
- Supports intervals from 1-12 months per job iteration
- Calculates simulation year based on job number and time interval
- Updates data table and MOM override files with current year
- Formula: `thisyear = yearbeg + ((thisjob-1) * month_dt) / 12`

**Example**: With `months = 3` in input.nml, each job runs 3 months of simulation time

#### 4. Model Execution
Runs MOM6 using MPI:
```bash
mpiexec -np $ntasks --mca pml_base_verbose 10 ./mom6
```

#### 5. Post-Run Processing
The script checks run status and takes appropriate action:

##### Successful Run
- Moves NetCDF output files to `outputs_raw/`
- Archives restart files to `restarts_raw/`
- Moves restart data to `INPUT/` for next job
- Creates log archive in `logs/`
- Updates `jobscompleted` file
- Submits next job if under total job limit

##### Failed Start (Resource Issues)
- Detects MPI startup failures
- Automatically resubmits the same job

##### Model Crash
- Exits with error code if model execution fails

### File Organization

#### Input Files
- `input.nml`: Main configuration file containing coupler settings and time intervals
  - `&coupler_nml` section specifies `months` parameter (1-12 months per job)
  - `current_date` sets the starting simulation date
- `data_table.template`: Template for forcing data
- `configs/MOM_override.template`: Model parameter overrides
- `configs/MOM_layout.$ntasks`: Processor layout configuration

#### Output Files
- `outputs_raw/*.nc`: Model output NetCDF files
- `restarts_raw/restarts.$thisjob`: Archived restart files
- `logs/logs.tar.$thisjob`: Compressed log files
- `jobscompleted`: Job tracking file

### Usage
Submit the first job:
```bash
sbatch --ntasks=<N> mom.sub.x
```

The script will automatically chain subsequent jobs until reaching the `njobs` limit (400).

### Key Features
- **Automatic job chaining**: Submits next job upon successful completion
- **Restart management**: Seamlessly transitions between cold start and restart modes
- **Error handling**: Detects and responds to common failure modes
- **File archiving**: Organizes outputs, restarts, and logs systematically
- **Year progression**: Automatically advances simulation time for each job

### Notes
- Script reads the `months` parameter from `&coupler_nml` section in `input.nml`
- Each job iteration can simulate 1-12 months of model time (configured via `months` parameter)
- Year progression calculation assumes monthly intervals when advancing simulation time
- Designed for long climate simulations requiring multiple sequential runs
- Uses InfiniBand for high-performance MPI communication when available
- Includes verbose MPI output for debugging connectivity issues
