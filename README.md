# Replication Package  
## *Certainty Amid Uncertainty: Relationship between Macroeconomic Uncertainty and Individual Expectations*  
**Giulia Piccillo & Poramapa Poonpakdee**

---

## Reproducibility Information

**Package assembled on:** 2026-01-08  

**Authors and contact**  
- Giulia Piccillo — g.piccillo@maastrichtuniversity.nl  
- Poramapa Poonpakdee — poramapa.p@gmail.com  

---

## Computing Environment

- **Stata 17 SE** (Windows 11)  
- **MATLAB R2021a**  
- **Python 3.11** (used for `DensityEst.py`)  
- **Jupyter Notebook** (for Python scripts)

**Software licenses**  
- Stata and MATLAB are proprietary and require valid licenses  
- Python and Jupyter Notebook are open-source  

---

## Hardware and Runtime

- Standard laptop  
- Full replication takes approximately **20 minutes**

**Special hardware**  
- No GPU or parallel computing required  

---

## Data Availability

The following datasets are included in this replication package:

- `us_hh_202506.dta`  
- `us_spf_est_202506.dta`  
- `data_quarter_202506.dta`  
- `data_month_202506.dta`  
- `daily_epu_202506.dta`  

The raw Excel files must be downloaded from public sources. See the URLs provided in Section 2.

---

# 1. File Structure

The replication package consists of **Stata scripts, MATLAB scripts, Excel files, and Stata datasets**.

## Script files

Scripts are organized by numeric prefixes.

### `0_*` — Data construction  
Import and combine raw SCE and SPF Excel files into Stata datasets.  
Raw Excel files are not included, but the generated Stata files are.

**Outputs (included in package)**  
- `us_hh_202506.dta`  
- `us_spf_202506.dta`  

---

### `1_*` — Subjective uncertainty construction  
Compute **GBD-based subjective uncertainty** for professional forecasters using:

- `us_spf_202506.dta`  
- Tao Wang’s `DensityEst.py`  
  https://github.com/iworld1991/DensitySurveyEstimation  

**Output**  
- `us_spf_est_202506.dta`  

---

### `2_*` — Regressions  
Run all regressions reported in the manuscript and appendices.

- `2_households` — household results  
- `2_spf` — professional forecaster results  

These scripts export all tables as CSV files in the `output` folder.

---

### `3_*` — Figure 1  
Excel file collecting household regression coefficients used to construct **Figure 1**.

---

### `4_*` — Figure 3  
MATLAB scripts used to produce **Figure 3**.

---

# 2. Data Files

## `us_hh_202506.dta`  
Households dataset constructed from three waves of the **New York Fed Survey of Consumer Expectations (SCE)**:

- 2020–latest  
  https://www.newyorkfed.org/medialibrary/interactives/sce/sce/downloads/data/frbny-sce-public-microdata-latest.xlsx  

- 2017–2019  
  https://www.newyorkfed.org/medialibrary/interactives/sce/sce/downloads/data/frbny-sce-public-microdata-complete-17-19.xlsx  

- 2013–2016  
  https://www.newyorkfed.org/medialibrary/interactives/sce/sce/downloads/data/frbny-sce-public-microdata-complete-13-16.xlsx  

---

## `us_spf_202506.dta`  
Survey of Professional Forecasters (SPF) microdata constructed from RGDP and PRGDP sheets:

https://www.philadelphiafed.org/-/media/FRBP/Assets/Surveys-And-Data/survey-of-professional-forecasters/historical-data/SPFmicrodata.xlsx  

---

## `us_spf_est_202506.dta`  
Final SPF estimation dataset including GBD subjective uncertainty measures.

---

## `data_quarter_202506.dta`  
Quarterly macroeconomic dataset manually assembled from:

1. **Economic Policy Uncertainty (EPU)**  
   https://www.policyuncertainty.com/media/US_Policy_Uncertainty_Data.xlsx  
   (monthly values averaged to quarterly)

2. **Jurado et al. uncertainty index**  
   https://www.sydneyludvigson.com/s/MacroFinanceUncertainty_202508Update.zip  
   (monthly values averaged to quarterly)

3. **Real-time GDP growth** (first, second, third, most recent)  
   https://www.philadelphiafed.org/-/media/FRBP/Assets/Surveys-And-Data/real-time-data/data-files/xlsx/routput_first_second_third.xlsx  

4. **Forecaster disagreement**  
   Constructed from SPF microdata using `1_disagreement_*` scripts  

These series were combined manually in Excel and saved as a Stata file.

---

## `data_month_202506.dta`  
Monthly macroeconomic dataset manually assembled from:

1. EPU index  
2. JU uncertainty index  
3. Real-time employment growth  
   https://www.philadelphiafed.org/-/media/FRBP/Assets/Surveys-And-Data/real-time-data/data-files/xlsx/employ_pct_chg_first_second_third.xlsx  

---

## `daily_epu_202506.dta`  
Daily EPU index  
https://www.policyuncertainty.com/media/All_Daily_Policy_Data.csv  

Downloaded as CSV and imported into Stata.

---

# 3. Recommended Run Order

**Step 0**  
Download raw SCE and SPF Excel files (Section 2).  
Run all `0_*` scripts to generate:
- `us_hh_202506.dta`
- `us_spf_202506.dta`

**Step 1**  
Run all `1_*` scripts to compute:
- forecaster disagreement  
- GBD-based subjective uncertainty  
→ `us_spf_est_202506.dta`

**Step 2**  
Run regression scripts:
- `2_households`
- `2_spf`

These generate all tables used in the paper and appendices.

**Step 3**  
Use `3_*` Excel file to construct **Figure 1**.

**Step 4**  
Run `4_*` MATLAB scripts to generate **Figure 3**.

---

# 4. Software Notes

Some Stata scripts contain absolute file paths (e.g. `C:\Users\...\OneDrive\...`).  
These must be edited to match your local directory structure.

Required Stata packages:
- `reghdfe`
- `eststo`
- `esttab`
