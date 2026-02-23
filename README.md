# Chlordecone Contamination Modeling & Simulation Platform

[![R](https://img.shields.io/badge/language-R-blue.svg)]()
[![Shiny](https://img.shields.io/badge/framework-Shiny-brightgreen.svg)]()
[![ODE Model](https://img.shields.io/badge/model-Non--autonomous%20ODE-purple.svg)]()
[![Reproducible](https://img.shields.io/badge/reproducibility-renv-brightgreen.svg)]()
[![Research Code](https://img.shields.io/badge/type-Research%20Code-orange.svg)]()
[![DOI](https://img.shields.io/badge/DOI-10.13140%2FRG.2.2.36238.01607-blue.svg)](https://doi.org/10.13140/RG.2.2.36238.01607)
[![Quick Start Guide](https://img.shields.io/badge/Documentation-Quick%20Start-5D3FD3?style=for-the-badge&logo=readthedocs&logoColor=white)](QUICKSTART.md)
[![License](https://img.shields.io/badge/license-MIT-green.svg)]()

---

## Repository Metadata

| Field | Information |
|-------|------------|
| Author | Geovany Batista Polo Laguerre |
| Project Type | Mathematical Modeling & Simulation |
| Language | R |
| Framework | Shiny Dashboard |
| Model Type | Non-autonomous compartmental ODE system |
| Focus | Seasonal forcing & periodic stability |
| Associated Preprint | https://doi.org/10.13140/RG.2.2.36238.01607 |
| Status | Research Prototype |
| Version | 1.0 |

---

## Project Overview

This repository contains:

- The numerical simulation code of a compartmental dynamical model for chlordecone contamination.
- An interactive Shiny application for exploring different modeling approaches.
- A research implementation accompanying the published preprint:

> **Laguerre, Geovany B. P. (2026)**  
> *Modélisation de l'exposition humaine au chlordécone.*  
> DOI: https://doi.org/10.13140/RG.2.2.36238.01607

The platform allows users to simulate environmental contamination dynamics, human exposure mechanisms, and intervention strategies under seasonal rainfall forcing.

---

## Mathematical Framework

The core system is defined as:

\[
\frac{dy}{dt} = f(t,y)
\]

with periodic rainfall forcing:

\[
R(t) = R_{\text{moy}}\left(1 + A \sin\left(\frac{2\pi t}{T}\right)\right)
\]

The model integrates:

- Agricultural soil contamination
- Environmental transport
- Bioaccumulation in food resources
- Human exposure classes
- Seasonal forcing
- Stability analysis

---

## Tools & Technologies

| Tool | Purpose |
|------|---------|
| R | Numerical computation |
| Shiny | Interactive interface |
| shinydashboard | Dashboard UI |
| deSolve | ODE solver |
| ggplot2 | Visualization |
| DT | Interactive tables |
| reshape2 | Data transformation |
| renv | Reproducible environment |

---

## Installation

### Install R (≥ 4.0)

Download from:
https://cran.r-project.org/

---

### Install Required Packages

```r
install.packages(c(
  "shiny",
  "shinydashboard",
  "deSolve",
  "ggplot2",
  "gridExtra",
  "DT",
  "reshape2"
))
```

If using reproducibility:

```r
install.packages("renv")
renv::restore()
```

---

## Running the Shiny Application

### From RStudio

1. Open `app.R`
2. Click **Run App**

### From R Console

```r
source("launch_app.R")
```

### From Terminal

```bash
.\launch.bat
```

---

## Application Modules

---

### Home

- Overview of the modeling framework
- Description of available models
- Usage instructions

---

### Base Compartmental Model

#### Structure
- Agricultural parcels (C)
- Aquatic environment (E)
- Food resource (F)
- Low burden population (H_S)
- High burden population (H_I)
- Rainfall forcing (R)

#### Adjustable Parameters
- Number of parcels
- Initial stocks
- Degradation rates (δ)
- Runoff rate (r₀)
- Rainfall amplification (α)
- Environmental transfers (μ_E, κ, μ_F)
- Exposure rate (β)
- Depuration rate (ρ)

#### Outputs
- Environmental contamination curves
- Resource contamination
- Population dynamics
- Prevalence of high burden

---

### Body Burden Extension B(t)

Adds a physiological biomarker:

\[
\frac{dB}{dt} = \gamma \frac{F}{H} - \mu_B B
\]

#### Additional Parameters
- γ : absorption coefficient
- μ_B : elimination rate
- B* : exposure threshold
- k : sigmoid steepness

#### Advantages
- Direct link with biomonitoring data
- Gradual transitions between exposure states
- Physiological realism

---

### Spatial Model (Multi-Basin)

- Multiple interconnected watersheds
- Parcel allocation to basins
- Inter-basin transfer (w)
- Basin-specific food resources

#### Applications
- Geographic targeting of interventions
- Priority basin identification
- Realistic hydrological transport

---

### Markov Chain (4 Exposure Classes)

Discrete exposure levels:

1. Null burden (B < 0.2 µg/L)
2. Low burden (0.2–0.5 µg/L)
3. Moderate burden (0.5–1.0 µg/L)
4. High burden (≥ 1.0 µg/L)

#### Features
- Progression via exposure (β_i·F)
- Regression via depuration (ρ_i)
- Population distribution across classes

#### Benefits
- Captures heterogeneity
- Residence time estimation
- Longitudinal calibration capability

---

### Policy Intervention Module

Simulates exposure reduction strategies:

- Hydraulic engineering (reduce r₀)
- Dietary awareness (reduce β)
- Gradual implementation via sigmoid φ(t)

#### Outputs
- Before/after comparison
- Impact on prevalence
- Environmental recovery curves

---

### Model Comparison

- Common parameter framework
- Visual prevalence comparison
- Structural uncertainty assessment

---

## Typical Workflow

1. Start with Base Model
2. Calibrate parameters
3. Extend with B(t) or Markov
4. Add spatial component if needed
5. Simulate interventions
6. Compare model outcomes

---

## Default Parameters (Illustrative)

| Parameter | Symbol | Default | Unit |
|-----------|--------|---------|------|
| Soil degradation | δ | 0.001 | day⁻¹ |
| Runoff | r₀ | 0.01 | day⁻¹ |
| Rain amplification | α | 0.8 | - |
| Env elimination | μ_E | 0.05 | day⁻¹ |
| Transfer E→F | κ | 0.03 | day⁻¹ |
| Resource renewal | μ_F | 0.02 | day⁻¹ |
| Exposure rate | β | 0.001 | day⁻¹·kg⁻¹ |
| Depuration | ρ | 0.005 | day⁻¹ |

*Values are indicative. Empirical calibration required.*

---

## Repository Structure

```
simulation-chlordecone/
│
├── app/                # Shiny application
├── data/               # Parameters
├── results/            # Outputs
├── docs/
├── renv.lock
├── README.md
└── LICENSE
```

---

## Scientific Contributions

This platform illustrates:

- Dissipative dynamics
- Seasonal periodic regimes
- Orbital stability
- Environmental-health coupling
- Numerical validation of theoretical results

---

## Scientific References

### Environmental & Epidemiology
- ANSES (2020). Études sur le chlordécone
- INVS - Études épidémiologiques KANNARI

### Compartmental Modeling
- Soetaert, K., Petzoldt, T., & Setzer, R. W. (2010). *Solving Differential Equations in R: Package deSolve*. Journal of Statistical Software, 33(9).
- Brauer, F., & Castillo-Chavez, C. (2012). *Mathematical Models in Population Biology and Epidemiology*. Springer.

### Environmental Modeling
- Mackay, D. (2001). *Multimedia Environmental Models*. CRC Press.

---

## Limitations

- Deterministic parameters
- No formal empirical validation
- No age structure
- IBM not implemented (computational cost)

---

## Future Extensions

- Bayesian calibration
- Global sensitivity analysis (Sobol)
- GIS coupling
- Optimal control module
- Stochastic extensions

---

## Citation

If used in academic work:

```
Laguerre, Geovany B. P. (2026).
Modélisation de l'exposition humaine au chlordécone.
DOI: 10.13140/RG.2.2.36238.01607
```

---

## Contact

Geovany Batista Polo Laguerre  
📧 lgeobatpo98@gmail.com  
🔗 https://github.com/Geobatpo07  

---

## License

CC0 1.0 Universal License

---

## Version History

### v1.0 (2026-01-22)
- Initial implementation
- 5 modeling approaches
- Shiny dashboard interface
- CSV export
- Model comparison module