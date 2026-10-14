# Quick Start Guide

# Shiny Application – Chlordecone Simulation

## Launch in 3 Steps

### Step 1: Open RStudio

Open the repository folder, then open the file `app/app.R`.

### Step 2: Install Dependencies (First Time Only)

In the R console (working directory = repository root), run:

```r
source("app/run.R")
```

This installs the missing packages and starts the application. To get the exact versions of the project, use `renv::restore()` instead.

OR install manually:

```r
install.packages(c("shiny", "shinydashboard", "deSolve",
                   "ggplot2", "gridExtra", "reshape2"))
```
### Step 3: Run the Application

Option A: Click the “Run App” button in the top-right corner of RStudio.

Option B: In the R console (repository root):

```r
shiny::runApp("app")
```

Option C: From a terminal, `Rscript app/run.R` (repository root), double-click `app\launch.bat` on Windows, or run `./app/launch.sh` on Linux/macOS.

## Application Navigation

### Main Menu (Left Sidebar)
* Home – Overview and instructions
* Base Model (parcels, environment, food resource, two population classes)
* Body Burden Variable B(t) – Extension with biomarker
* Spatialization – Multi-watershed model
* Markov Chain – 4 exposure classes

* Intervention – Public policy simulations

* Comparison – Multi-model comparison

* About – Information and references

## Example Usage: Base Model
1. Click “Base Model” in the menu
2. Adjust Parameters (Left Panel)

    * Number of parcels: 3
    * Initial stock: 1000 kg
    * Degradation rate: 0.001 day⁻¹ (half-life ≈ 2 years)
    * Runoff rate: 0.01 day⁻¹
    * Rainfall amplification: 0.8
    * Simulation duration: 20 years

3. Click “Simulate”
4. Explore Results (Right Panel)

    * Plot 1: Parcel contamination (log scale)

    * Plot 2: Environment and food resource

    * Plot 3: Population dynamics (H_S, H_I)

    * Plot 4: High burden prevalence (%)

5. Download Results (Optional)
Click “Download Results” to export a CSV file.

## Suggested Scenarios

### Scenario 1: Impact of Degradation

- Vary δ from 0.0005 to 0.002
- Observe effects on decay of C and final prevalence

### Scenario 2: Role of Rainfall

- Vary α from 0 (no effect) to 2 (strong effect)
- Compare seasonal fluctuations of E and F

### Scenario 3: Intervention Efficiency

- Select **Long persistence** in the sidebar (“Environmental scenario”): with the default **Preprint** scenario the contamination disappears within a few years, so an intervention has little to act on
- Go to the “Intervention” tab (initial prevalence 20 %, start at t₀ = 0, reductions of 40 % on r₀ and β)
- Compare the curves with and without intervention; the subtitle gives the relative reduction after 5 years
- Optionally increase the resource turnover µF

### Scenario 3b: Environmental Scenarios

- Compare **Preprint** (δ = 0.001, r₀ = 0.01: soil half-life of about 2 months) and **Long persistence** (δ = 5·10⁻⁵, r₀ = 4·10⁻⁵: half-life of about 20 years)
- The selector sets δ, r₀ and γ in every tab

### Scenario 4: Model Comparison

- Go to the “Comparison” tab
- Run the comparative simulation
- Analyze prediction differences

## Practical Advice

### Recommended Practices

- Start with default parameters
- Modify one parameter at a time
- Use 10–20 years duration to observe long-term dynamics
- Download results for deeper analysis

### Avoid

- Physically impossible parameters (negative values)
- Very long durations (>50 years) without justification
- Extreme parameter values without calibration

### If Problems Occur

1. Ensure all required packages are installed
2. Restart the R session (Session → Restart R)
3. Check error messages in the console
4. Review [README.md](README.md) for details

## Interpretation of Results

### High Burden Prevalence

- < 5%: Low exposure
- 5–15%: Moderate exposure
- \>= 15%: Concerning exposure

### Parcel Contamination (C)

- Follows exponential decay
- Slope depends on δ (degradation) and r₀ (runoff)

### Environmental Dynamics (E)

- Initial accumulation phase
- Quasi-equilibrium phase
- Seasonal oscillations due to R(t)

### Exposed Population (H_I)

- Progressive increase (cumulative effect)

- May stabilize if F stabilizes

### Advanced Customization

The code is split in three parts:

| File | Role |
|------|------|
| `app/app.R` | Interface and server (initial conditions are in the `*_results` reactives) |
| `app/R/models.R` | ODE models |
| `app/R/simulation.R` | Default parameters (`params_defaut`), solver, prevalence |
| `app/R/plots.R` | ggplot2 figures |

#### Modify Initial Conditions

In `app/app.R`, in the relevant `*_results` reactive:

```r
y0 <- c(rep(input$base_C0, n), 50, 10, input$base_H0 * 0.98, input$base_H0 * 0.02)
#                               E0  F0
```

#### Add New Plots

Add a `ggplot` to the list returned by the relevant `plots_*` function in `app/R/plots.R`.

#### Change Forcing Period

In `app/R/simulation.R`, in `params_defaut`:

```r
T_periode = 365
```

to simulate different cycles.

#### Run the Tests

```bash
Rscript tests/smoke.R
Rscript tests/test_simulation.R
```

## Going Further

- Calibration with Real Data
- Collect empirical data (soil, biota, biomarkers)
- Define objective function (model-data distance)
- Optimize (optim, GA, DEoptim)

## Sensitivity Analysis
```r
library(sensitivity)
```

Apply Morris or Sobol methods.

## Export for Publications

```r
ggsave("figure.pdf", width = 10, height = 6, dpi = 300)
```

## Contact and Support

- Questions: lgeobatpo98@gmail.com
- Bug reports: Open a GitHub issue
- Documentation: See [README.md](README.md)

Version: 1.0

Date: January 2026

Author: Geovany LAGUERRE