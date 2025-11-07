# NEUS25-MOM6-COBALT Setup Guide

## Overview

This guide walks through setting up and running the MOM6-COBALT regional ocean-biogeochemistry model for the Northeast US continental shelf.

## Prerequisites

- Linux/Unix environment with MPI
- Fortran compiler (Intel or GNU)
- NetCDF libraries
- ~2TB storage for inputs, ~5TB for outputs

## Workflow Overview

The general workflow is presented below.

### Setup and execution
```mermaid
flowchart LR
    A[1. Clone Repository] --> B[2. Build Executable]
    B --> C{MOM6 executable}
    C --> D[3. Create Work Directory]
    
    D --> E[4. Gather Input Data <br/> <br/>Static Files<br/>- Grid<br/>- Initial Conditions<br/>- Auxiliary Files <br/> <br/>Forcing Files<br/>- Atmosphere<br/>- Ocean BC<br/>- Rivers]

    E --> H[INPUT/]
    
    style C fill:#f9f,stroke:#333,stroke-width:4px
    style H fill:#afd,stroke:#333,stroke-width:2px
```

```mermaid
flowchart LR
    A[INPUT/] --> B[5. Edit Configuration <br/> <br/> Essential Files<br/>- input.nml<br/>- MOM_layout<br/>- MOM_input<br/>- MOM_override<br/>- diag_table<br/>- field_table<br/>- data_table]
    
    B --> D[6. Execute Model]
    D --> E[Output<br/>- NetCDF files<br/>- Restart files<br/>- Logs]
    
    E --> F{Continue Run?}
    F -->|Yes| G[Restart model]
    G --> D
    F -->|No| H[Simulation ended]
    
    style A fill:#afd,stroke:#333,stroke-width:2px
    style E fill:#9f9,stroke:#333,stroke-width:2px
```

Each step is documented below.

## Setup Process

### Step 1: Clone Repository

Get the MOM6 source code with the NEUS25 configuration:

```bash
git clone --recursive https://github.com/NOAA-GFDL/CEFI-regional-MOM6
cd CEFI-regional-MOM6
git checkout 214d998fba1776261df4af250d17663c272aa218
git submodule update --recursive
```

### Step 2: Build Executable

Compile MOM6 for your system. This step is system-specific and produces the `MOM6` executable.

📖 **[Compilation Guide](docs/compilation.md)** - Detailed build instructions  
🔗 **[GFDL Instructions](https://github.com/NOAA-GFDL/MOM6/wiki/Getting-Started)** - Official MOM6 build docs

### Step 3: Create Work Directory

Set up your simulation directory with the NEUS25 configuration:

```bash
# Copy the NEUS25 configuration
cp -r exps/NEUS25.COBALT /your/work/dir/

# Navigate to your working directory
cd /your/work/dir/NEUS25.COBALT/

# Link the compiled executable
ln -s /path/to/compiled/MOM6 .
```

Directory structure after setup:
```
NEUS25.COBALT/
├── MOM6 → (executable)
├── INPUT/              # Will contain forcing files
├── configs/            # Configuration files
├── input.nml          # Main control file
├── data_table         # Forcing file paths
├── diag_table         # Output configuration
└── field_table        # Tracer setup
```

### Step 4: Gather Input Data

Obtain all required input files and place them in the `INPUT/` directory:

1. **Static files** (one-time download)
   - Grid files (ocean_hgrid.nc, ocean_static.nc)
   - Initial conditions (T, S, biogeochemistry)
   - Auxiliary files (masks, tidal harmonics)
   - Download from Zenodo: [DOI]

2. **Forcing files** (time-varying, per simulation period)
   - Atmosphere: ERA5 fields
   - Ocean BC: GLORYS boundaries
   - Rivers: GloFAS discharge + nutrients
   - Generate using preprocessing tools or download pre-processed

📖 **[Input Files Guide](docs/input_files.md)** - Complete list and descriptions  
🔧 **[Preprocessing Tools](../tools/mom6_neus25_utils/README.md)** - Generate forcing from raw data

### Step 5: Edit Configuration

Configure the model for your simulation by editing these files:

#### Essential Files (must edit):

- **`input.nml`** - Set simulation timing:
- **`configs/MOM_input`** - Tune physics parameters
- **`configs/MOM_override`** - Override specific settings
- **`configs/MOM_layout`** - Match processor count:
- **`data_table`** - Update paths to your INPUT files
- **`diag_table`** - Modify output variables and frequencies
- **`field_table`** - Adjust tracer initialization


```bash
cp configs/MOM_layout.120 configs/MOM_layout  # For 120 cores
```


📖 **[Configuration Guide](docs/configuration.md)** - All configuration options explained

### Step 6: Execute Model

Run the model using one of these approaches:

**Test run** (interactive):
```bash
mpiexec -np 120 ./MOM6
```

**Production run** (HPC/SLURM):
```bash
sbatch --ntasks=120 mom.sub.x
```

The model will produce:
- NetCDF diagnostic files (as specified in `diag_table`)
- Restart files in `RESTART/` directory
- Log files for debugging

📖 **[Running Guide](docs/running.md)** - Run options, restart management, performance tips

## Quick Checklist

Before executing, verify:

- [ ] MOM6 executable is compiled and linked
- [ ] All files listed in `data_table` exist in `INPUT/`
- [ ] `configs/MOM_layout` matches your processor count
- [ ] `input.nml` has correct start date and duration
- [ ] Sufficient disk space for outputs (~5GB per simulated year)

## Output Files

The model produces:
- **NetCDF diagnostics** - Variables specified in `diag_table`
- **Restart files** - In `RESTART/` for continuing runs
- **Parameter documentation** - `MOM_parameter_doc.*` files
- **Log files** - Runtime information and errors

📖 **[Output Guide](docs/outputs.md)** - File formats, variables, post-processing

## Getting Help

- **Common issues**: See [Troubleshooting Guide](docs/troubleshooting.md)
- **Parameter details**: Check generated `MOM_parameter_doc.*` files
- **Model science**: [MOM6 Documentation](https://mom6.readthedocs.io)
- **This configuration**: [Open an issue](https://github.com/your-repo/issues)

## Next Steps

- For long simulations: See [SLURM Guide](docs/slurm_guide.md)
- For custom domains: See [Grid Generation](docs/grid_generation.md)
- For analysis: See [Post-processing Tools](docs/analysis.md)