# Quick Start Guide

# Shiny Application – Chlordecone Simulation

## Launch in 3 Steps

### Step 1: Open RStudio

Double-click the file app.R to open it in RStudio.

### Step 2: Install Dependencies (First Time Only)

In the R console, run:

```r
source("run.R")
```

OR install manually:

```r
install.packages(c("shiny", "shinydashboard", "deSolve",
                   "ggplot2", "gridExtra", "DT", "reshape2"))
```
### Step 3: Run the Application

Option A: Click the “Run App” button in the top-right corner of RStudio.

Option B: In the R console:

```r
shiny::runApp()
shiny::runApp()
```

## Application Navigation

### Main Menu (Left Sidebar)
* Home – Overview and instructions
* Base Model (6 compartments)
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

- Go to the “Intervention” tab
- Set t₀ = 5 years
- Reduce r₀ by 40%
- Reduce β by 40%
- Compare prevalence before and after

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

#### Modify Initial Conditions

```r
C0 <- rep(input$base_C0, input$base_n_parcelles)
E0 <- 50
F0 <- 10
```

#### Add New Plots

Use ggplot2 inside the output$..._plot section.


- Edit in app.R:
```r
C0 <- rep(input$base_C0, input$base_n_parcelles)
E0 <- 50
F0 <- 10
```

- Add New Plots

Use ggplot2 inside the `output$..._plot` section.

Change Forcing Period

Modify:

```r
T_periode <- 365
```

to simulate different cycles.

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