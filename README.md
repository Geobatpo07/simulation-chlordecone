# Chlordecone Contamination Modeling & Simulation Platform

[![R](https://img.shields.io/badge/language-R-blue.svg)]()
[![Shiny](https://img.shields.io/badge/framework-Shiny-brightgreen.svg)]()
[![ODE Model](https://img.shields.io/badge/model-Non--autonomous%20ODE-purple.svg)]()
[![Reproducible](https://img.shields.io/badge/reproducibility-renv-brightgreen.svg)]()
[![Research Code](https://img.shields.io/badge/type-Research%20Code-orange.svg)]()
[![DOI](https://img.shields.io/badge/DOI-10.13140%2FRG.2.2.36238.01607-blue.svg)](https://doi.org/10.13140/RG.2.2.36238.01607)
[![Quick Start Guide](https://img.shields.io/badge/Documentation-Quick%20Start-5D3FD3?style=for-the-badge&logo=readthedocs&logoColor=white)](QUICKSTART.md)
[![License: CC0 1.0](https://img.shields.io/badge/license-CC0%201.0-lightgrey.svg)](https://creativecommons.org/publicdomain/zero/1.0/)

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
| Version | 1.1 |

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

$$
\frac{dy}{dt} = f(t,y)
$$

with periodic rainfall forcing:

$$
R(t) = R_{\text{moy}}\left(1 + A \sin\left(\frac{2\pi t}{T}\right)\right)
$$

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
  "reshape2"
))
```

To get exactly the package versions of the project (recommended, also used by the CI):

```r
install.packages("renv")
renv::restore()
```

---

## Running the Shiny Application

### From RStudio

1. Open `app/app.R`
2. Click **Run App**

### From R Console (repository root)

```r
source("app/run.R")   # installs missing packages, then starts the app
# or simply
shiny::runApp("app")
```

### From Terminal

```bash
Rscript app/run.R     # from the repository root
```

On Windows, `app\launch.bat` also works (double-click). On Linux, macOS or Git Bash, use `./app/launch.sh`. Both find `Rscript` in the `PATH` or in the usual install locations.

`app/run.R` locates the app folder by itself, so it can be started from any directory.

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
- Agricultural parcels ($C$)
- Aquatic environment ($E$)
- Food resource ($F$)
- Low burden population ($H_S$)
- High burden population ($H_I$)
- Rainfall forcing ($R$)

#### Adjustable Parameters
- Number of parcels (1 to 7, as in the preprint)
- Initial stocks
- Degradation rates ($\delta$)
- Runoff rate ($r_0$)
- Rainfall amplification ($\alpha$)
- Environmental transfers ($\mu_E$, $\kappa$, $\mu_F$)
- Exposure rate ($\beta$)
- Depuration rate ($\rho$)

#### Outputs
- Environmental contamination curves
- Resource contamination
- Population dynamics
- Prevalence of high burden

---

### Body Burden Extension B(t)

Adds a physiological biomarker:

$$
\frac{dB}{dt} = \gamma \frac{F}{H} - \mu_B B
$$

(form of the preprint, §9.1; $F/H$ is the per-capita availability of contaminated resource)

#### Additional Parameters
- $\gamma$ : absorption coefficient ($\mu g \cdot L^{-1} \cdot kg^{-1} \cdot pers.$), default 2.5
- $k_{trans}$ : S↔I transition speed (day⁻¹). Implementation choice of the app, not in the preprint, which writes $H_I = H \cdot p_i(B)$ directly (§9.2.2)
- $\mu_B$ : elimination rate
- $B^*$ : exposure threshold
- $k$ : sigmoid steepness

#### Advantages
- Direct link with biomonitoring data
- Gradual transitions between exposure states
- Physiological realism

---

### Spatial Model (Multi-Basin)

- Multiple interconnected watersheds
- Parcel allocation to basins
- Inter-basin transfer ($w$)
- Basin-specific food resources

#### Applications
- Geographic targeting of interventions
- Priority basin identification
- Realistic hydrological transport

---

### Markov Chain (4 Exposure Classes)

Discrete exposure levels:

1. Null burden (B < 0.2 $\mu g/L$)
2. Low burden (0.2–0.5 $\mu g/L$)
3. Moderate burden (0.5–1.0 $\mu g/L$)
4. High burden (≥ 1.0 $\mu g/L$)

#### Features
- Progression via exposure ($\beta_i\cdot F$)
- Regression via depuration ($\rho_1, \rho_2, \rho_3$, free parameters as in preprint §10.3.2; defaults 0.0025, 0.0035, 0.005 day⁻¹)
- Population distribution across classes

#### Benefits
- Captures heterogeneity
- Residence time estimation
- Longitudinal calibration capability

---

### Policy Intervention Module

Simulates exposure reduction strategies:

- Hydraulic engineering (reduce $r_0$)
- Dietary awareness (reduce $\beta$)
- Forced resource turnover (increase $\mu_F$, e.g. fishing ban)
- Gradual implementation via sigmoid $\varphi(t)$

#### Outputs
- Comparison with a reference scenario without intervention (same parameters)
- Relative prevalence reduction at 5 years, to compare with the objective of preprint §8.2.1 (initial $H_I/H$ of 20 %, adjustable)
- Impact on prevalence
- Environmental recovery curves

---

### Sensitivity Analysis

Effect of 9 parameters ($\delta$, $r_0$, $\alpha$, $\mu_E$, $\kappa$, $\mu_F$, $\beta$, $\rho$, $F_{max}$) of the base model on three outputs: maximum prevalence, prevalence at 5 years and peak of the food resource $F$.

- **Local (one at a time)**: each parameter is multiplied by 0.5 then 2 (tornado diagram) and the elasticity is computed at $\pm 10\ \%$.
- **Global (Sobol)**: the 9 parameters vary together between half and double of their reference value (log-uniform); first-order ($S_1$) and total ($S_T$) indices with 95 % bootstrap intervals.

The reference values follow the selected environmental scenario. Results and interpretation: [docs/sensibilite.md](docs/sensibilite.md). For large samples, use the parallel script:

```bash
Rscript scripts/sensibilite.R preprint,persist 1024 20 20 8   # scenarios, N, years, initial prevalence (%), cores
```

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
| Soil degradation | $\delta$ | 0.001 | day⁻¹ |
| Runoff | $r_0$ | 0.01 | day⁻¹ |
| Rain amplification | $\alpha$ | 0.8 | - |
| Env elimination | $\mu_E$ | 0.05 | day⁻¹ |
| Transfer E→F | $\kappa$ | 0.03 | day⁻¹ |
| Resource renewal | $\mu_F$ | 0.02 | day⁻¹ |
| Exposure rate | $\beta$ | 0.001 | day⁻¹·kg⁻¹ |
| Depuration | $\rho$ | 0.005 | day⁻¹ |

*Values are indicative. Empirical calibration required.*

---

## Repository Structure

```
simulation-chlordecone/
│
├── app/
│   ├── app.R           # Interface (UI) and server
│   └── R/              # Loaded automatically by Shiny
│       ├── models.R        # ODE models (no Shiny dependency)
│       ├── simulation.R    # Parameters, solver, prevalence, comparison, intervention
│       ├── sensibilite.R   # Sensitivity analysis (one-at-a-time and Sobol)
│       └── plots.R         # ggplot2 figures
├── scripts/
│   └── sensibilite.R       # Parallel sensitivity analysis, writes CSV files in results/
├── tests/
│   ├── smoke.R             # Models: finite solutions, demography, mass conservation
│   ├── test_simulation.R   # Column names, prevalence, comparison, intervention
│   └── test_sensibilite.R  # Sobol estimator validated on the Ishigami function, elasticities
├── docs/
│   ├── dette.md             # Flaws of the preprint, to correct in a later version
│   └── corrections_math.md  # Mathematical corrections applied in the code
├── .github/workflows/  # CI/CD (tests, then deployment to shinyapps.io)
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
- Sensitivity analysis of the other models (the base model is done: see [docs/sensibilite.md](docs/sensibilite.md))
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

This project is released under the **Creative Commons CC0 1.0 Universal License**.

You may copy, modify, distribute and perform the work, even for commercial purposes, all without asking permission.

Full legal text:
https://creativecommons.org/publicdomain/zero/1.0/

---

## Environmental Scenarios

The sidebar selector sets $\delta$ and $r_0$ in every tab:

| Scenario | $\delta$ (day⁻¹) | $r_0$ (day⁻¹) | Behavior |
|----------|------------------|---------------|----------|
| Preprint (default) | 0.001 | 0.01 | Soil half-life of about 2 months; transient exposure peak, then elimination (as in the preprint's theorems) |
| Long persistence | 5e-5 | 4e-5 | Soil half-life of about 20 years; exposure persists for decades |

Neither $r_0$ nor the rainfall parameters are given in the preprint, so the long persistence values are illustrative. The selector also sets $\gamma$ (2.5 for the preprint scenario, 60 for long persistence), so that $B(t)$ approaches $B^*$ at the exposure level of each scenario.

With an initial prevalence of 20 % and the default intervention ($-40\ \%$ on $r_0$ and $\beta$, immediate start), the long persistence scenario with 3 parcels gives about 13 % at 5 years versus 29 % without intervention (relative reduction of about 54 %), consistent with the objective of §8.2.1 (halving exposure in 5 years). The preprint scenario does not reproduce it: exposure saturates at $F_{max}$ and the contamination disappears within a few years, whatever the intervention.

---

## Continuous Deployment

[`.github/workflows/deploy-shinyapps.yml`](.github/workflows/deploy-shinyapps.yml) runs on every push to `main` that touches `app/`, `renv.lock` or `tests/`:

1. **test**: restores the `renv` library and runs `Rscript tests/smoke.R` (finite solutions, demographic equilibrium, mass conservation in the spatial model) and `Rscript tests/test_simulation.R` (column names, prevalence, model comparison, intervention reference). Also runs on pull requests.
2. **deploy**: if the tests pass, deploys `app/app.R` and `app/R/` to shinyapps.io with `rsconnect` (app name `chlordecone-simulation-app`).

Required repository secrets (Settings → Secrets and variables → Actions): `SHINYAPPS_NAME`, `SHINYAPPS_TOKEN`, `SHINYAPPS_SECRET` (from shinyapps.io → Account → Tokens). A manual run is available from the Actions tab.

---

## Version History

### v1.1 (2026-10-14)

**Corrections**
- Model comparison: the prevalence was computed from the wrong columns (columns are now named, no positional indexing).
- Spatial model: the inter-basin transfer was overwritten and mass was lost.
- Demographic equilibrium $\Lambda_H = H_0 d_H$ (the population no longer drifts towards 255,500).

**Fidelity to the preprint** (details in [docs/corrections_math.md](docs/corrections_math.md))
- $B(t)$ follows the preprint form $\gamma F/H - \mu_B B$, with an explicit relaxation speed $k_{trans}$ towards $H\,p(B)$.
- Markov $\rho_i$ as free parameters; up to 7 parcels.
- Intervention: reference scenario without intervention, action on $\mu_F$, initial prevalence of 20 %, relative reduction at 5 years.
- Environmental scenarios: preprint (soil half-life of 59 days) and long persistence (20 years).

**New**
- Sensitivity analysis of the base model (one at a time and Sobol): tab, parallel script, results in [docs/sensibilite.md](docs/sensibilite.md).

**Engineering**
- Code split into `app/R/` (models, simulation, plots, sensitivity).
- Tests: `tests/smoke.R`, `tests/test_simulation.R`, `tests/test_sensibilite.R`.
- CI/CD (GitHub Actions): tests, then deployment to shinyapps.io; `renv.lock` updated.
- Launch scripts: `run.R` works from any folder, `launch.bat` and `launch.sh`; `launch_app.R` removed (duplicate of `run.R`).
- The unused DT dependency is removed.

**Documentation**
- Flaws of the preprint: [docs/dette.md](docs/dette.md).
- README and QUICKSTART updated.

### v1.0 (2026-01-22)
- Initial implementation
- 5 modeling approaches
- Shiny dashboard interface
- CSV export
- Model comparison module
