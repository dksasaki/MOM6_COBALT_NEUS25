# MOM6-COBALT-NEUS25v1.0

**A High-Resolution Coupled Physical-Biogeochemical Model of the Northeastern US Continental Shelf**

## Overview

Regional configuration for the Northeast US shelf (30-50°N, 80-60°W) at ~1/25° horizontal resolution:
- **Ocean Model**: MOM6 with 75 vertical levels
- **Biogeochemistry**: COBALT with 40+ tracers (nutrients, carbon, plankton)
- **Sea Ice**: SIS2 dynamic-thermodynamic model
- **Period**: 1993-2019 (extensible)

## Repository Contents

```
├── exps/NEUS25.COBALT/       # Model configuration and runtime scripts
├── tools/mom6_neus25_utils/  # Preprocessing tools for forcing generation
└── README.md                 # This file
```

## Documentation

- **Model Setup & Running**: See `exps/NEUS25.COBALT/README.md`
- **Preprocessing Tools**: See `tools/mom6_neus25_utils/README.md`

## Workflow

1. **Generate forcing files** using tools in `tools/mom6_neus25_utils/`
2. **Place outputs** in `exps/NEUS25.COBALT/INPUT/`
3. **Run model** using configuration in `exps/NEUS25.COBALT/`

## Citation

[Paper title and DOI]

## License

LGPL-3.0