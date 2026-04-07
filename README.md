# Replication Package

## Paper
**Certainty Amid Uncertainty: Relationship between Macroeconomic Uncertainty and Individual Expectations**  
Giulia Piccillo and Poramapa Poonpakdee  

Reproducibility package assembled on: 2026-01-08

---

## Authors and Contact

- Giulia Piccillo — g.piccillo@maastrichtuniversity.nl  
- Poramapa Poonpakdee — poramapa.p@gmail.com  

---

## Computing Environment

- Stata 17 SE (Windows 11)
- MATLAB R2021a
- Python 3.11 (for `DensityEst.py`)
- Jupyter Notebook

---

## Software Licenses

- Stata and MATLAB require valid licenses  
- Python and Jupyter Notebook are open-source  

---

## Hardware and Runtime

- Replication was run on a standard laptop  
- Full replication takes approximately **20 minutes**

---

## Special Requirements

- No GPU, parallel computing, or special hardware required  

---

## Data Availability

Due to file size limitations, some processed datasets are hosted externally.

The main processed dataset required to reproduce the results is available at:  
https://doi.org/10.5281/zenodo.19449956

Please download the dataset and place it in the `/data` directory before running the replication scripts. All scripts are written assuming this file path. Alternatively, users can modify file paths to match their local setup.

The following datasets are included in this repository:

- `us_hh_202506.dta`
- `us_spf_est_202506.dta`
- `data_quarter_202506.dta`
- `data_month_202506.dta`
- `daily_epu_202506.dta`

---

## Overview

This repository contains all data and code required to reproduce the empirical results in the manuscript.

---

# 1. File Structure

The replication package consists of **Stata scripts, MATLAB scripts, Excel files, and datasets**.

## A. Script Files

Scripts are organized by numeric prefixes:

### `0_*`
- Import and combine raw survey data (SCE and SPF)
- Generate main datasets  

Outputs:
- `us_hh_202506.dta`
- `us_spf_202506.dta`

---

### `1_*`
- Compute GBD-based subjective uncertainty measures for SPF
- Uses:
  - `us_spf_202506.dta`
  - External code: https://github.com/iworld1991/DensitySurveyEstimation  

Output:
- `us_spf_est_202506.dta`

---

### `2_*`
- Run all regressions in the paper and appendix  

Subfolders:
- `2_households` → household regressions  
- `2_spf` → SPF regressions  

Outputs:
- Regression tables (CSV format, saved in `/output`)

---

### `3_*`
- Excel file used to construct **Figure 1**

---

### `4_*`
- MATLAB scripts used to produce **Figure 3**

---

# 2. Data Files

## Main Datasets

### `us_hh_202506.dta`
Household dataset constructed from NY Fed Survey of Consumer Expectations (SCE):

- 2020–latest  
  https://www.newyorkfed.org/medialibrary/interactives/sce/sce/downloads/data/frbny-sce-public-microdata-latest.xlsx  

- 2017–2019  
  https://www.newyorkfed.org/medialibrary/interactives/sce/sce/downloads/data/frbny-sce-public-microdata-complete-17-19.xlsx  

- 2013–2016  
  https://www.newyorkfed.org/medialibrary/interactives/sce/sce/downloads/data/frbny-sce-public-microdata-complete-13-16.xlsx  

---

### `us_spf_202506.dta`
Survey of Professional Forecasters (SPF) dataset:

https://www.philadelphiafed.org/-/media/FRBP/Assets/Surveys-And-Data/survey-of-professional-forecasters/historical-data/SPFmicrodata.xlsx  

---

### `us_spf_est_202506.dta`
Final SPF dataset including GBD subjective uncertainty measures.

---

### `data_quarter_202506.dta`
Quarterly macro dataset constructed from:

1. Economic Policy Uncertainty (EPU)  
   https://www.policyuncertainty.com/media/US_Policy_Uncertainty_Data.xlsx  

2. Jurado et al. uncertainty index  
   https://www.sydneyludvigson.com/s/MacroFinanceUncertainty_202508Update.zip  

3. Real-time GDP data (Philadelphia Fed)  

4. Forecaster disagreement (constructed from SPF)

---

### `data_month_202506.dta`
Monthly macro dataset constructed from:

- EPU index  
- Jurado uncertainty index  
- Real-time employment data (Philadelphia Fed)

---

### `daily_epu_202506.dta`
Daily EPU index:  
https://www.policyuncertainty.com/media/All_Daily_Policy_Data.csv  

---

# 3. Recommended Run Order

### Step 0 (Optional – Data Assembly)
Download raw SCE and SPF Excel files, then run:
- all `0_*` scripts  
This step assembles the raw data from the original public sources (SCE and SPF Excel files) and constructs the main datasets:

- `us_hh_202506.dta`
- `us_spf_202506.dta`

**Note:**
- This step is not required to reproduce the results in the paper.
- The processed datasets are already included in the repository.
- The assembled data may reflect updates beyond the sample used in the manuscript.
- Users can skip this step and proceed directly to Step 1.

---

### Step 1
Run all `1_*` scripts to compute:
- forecaster disagreement  
- GBD uncertainty measures  

---

### Step 2
Run regression scripts:
- `2_households`
- `2_spf`

Outputs:
- All tables (CSV format)

---

### Step 3
Use `3_*` Excel file to construct **Figure 1**

---

### Step 4
Run `4_*` MATLAB scripts to generate **Figure 3**

---

# 4. Software Notes

- Some scripts contain **absolute file paths**  
  → must be edited before running  

### Required Stata packages:
- `reghdfe`
- `eststo`
- `esttab`

---

# Reproducibility Statement

The numerical results in this manuscript were successfully reproduced by **CASCaD on 4 February 2026**.

---

# End of README
