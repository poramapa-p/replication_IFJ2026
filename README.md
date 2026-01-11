README.txt

Replication Package for:
"Certainty Amid Uncertainty: Relationship between Macroeconomic Uncertainty and Individual Expectations"
Giulia Piccillo and Poramapa Poonpakdee

Reproducibility package assembled on: 2026-01-08

Authors and contact:
Giulia Piccillo      g.piccillo@maastrichtuniversity.nl
Poramapa Poonpakdee   poramapa.p@gmail.com

Computing environment:
Stata 17 SE on Windows 11
MATLAB R2021a
Python 3.11 (used for DensityEst.py)
Jupyter Notebook (for running Python scripts)

Software licenses:
Stata and MATLAB are proprietary software and require valid licenses.
Python and Jupyter Notebook are open-source.

Hardware and runtime:
The replication was run on a standard laptop.
Full replication (all scripts and figures) takes approximately 20 minutes.

Special hardware or setup:
No GPU, parallel computing, or special hardware is required.

Data availability:
The following datasets are included in this replication package:
    us_hh_202506.dta
    us_spf_est_202506.dta
    data_quarter_202506.dta
    data_month_202506.dta
    daily_epu_202506.dta

The following raw Excel files must be downloaded from public sources:
    New York Fed Survey of Consumer Expectations (SCE) microdata (2013–latest)
    Survey of Professional Forecasters (SPF) microdata
    See the URLs provided in Section 2.


This folder contains all data and code required to reproduce the empirical results in the manuscript.

----------------------------------------------------------------------
1. FILE STRUCTURE
----------------------------------------------------------------------

The replication package consists of Stata scripts, MATLAB scripts, Excel files, and Stata datasets.

A. Script files

Scripts are organized by numeric prefixes:

0_*
    These scripts import and combine the raw survey data from the original
    Excel files (SCE and SPF) and create the main Stata datasets.
    The original Excel files are not included in the package, but the
    resulting Stata datasets are included.

    Outputs (included in the replication package):
        us_hh_202506.dta
        us_spf_202506.dta

1_*
    These scripts compute the GBD-based subjective uncertainty measures
    for professional forecasters (SPF). They use us_spf_202506.dta together
    with the DensityEst.py code by Tao Wang 
    (https://github.com/iworld1991/DensitySurveyEstimation).

    Output (included in the replication package):
        us_spf_est_202506.dta


2_*
    These scripts run all regressions reported in the manuscript and appendices.

        2_households   Regressions for the households dataset
        2_spf          Regressions for the professional forecasters (SPF) dataset

    These scripts produce all regression tables (exported as CSV files in the output folder).


3_*
    Excel file that collects household regression coefficients of
    subjective uncertainty used to construct Figure 1.


4_*
    MATLAB scripts used to produce Figure 3.


----------------------------------------------------------------------
2. DATA FILES
----------------------------------------------------------------------


The main Stata datasets are:

us_hh_202506.dta
    Households dataset constructed by appending three waves of the
    New York Fed Survey of Consumer Expectations (SCE) microdata:

    2020–latest:
    https://www.newyorkfed.org/medialibrary/interactives/sce/sce/downloads/data/frbny-sce-public-microdata-latest.xlsx?sc_lang=en

    2017–2019:
    https://www.newyorkfed.org/medialibrary/interactives/sce/sce/downloads/data/frbny-sce-public-microdata-complete-17-19.xlsx?sc_lang=en

    2013–2016:
    https://www.newyorkfed.org/medialibrary/interactives/sce/sce/downloads/data/frbny-sce-public-microdata-complete-13-16.xlsx?sc_lang=en


us_spf_202506.dta
    Survey of Professional Forecasters (SPF) dataset constructed
    from the RGDP and PRGDP sheets of the historical SPF microdata:

    https://www.philadelphiafed.org/-/media/FRBP/Assets/Surveys-And-Data/survey-of-professional-forecasters/historical-data/SPFmicrodata.xlsx

us_spf_est_202506.dta
    Final SPF estimation dataset created by the 1_* scripts.
    This file includes the GBD subjective uncertainty measures.

data_quarter_202506.dta
    Quarterly macroeconomic dataset manually assembled by the authors
    from the following public sources:

    1. Economic Policy Uncertainty (EPU) index
       Source: https://www.policyuncertainty.com/media/US_Policy_Uncertainty_Data.xlsx
       Processing: monthly values averaged within each calendar quarter.

    2. Jurado et al. (JU) macroeconomic uncertainty index
       Source: https://www.sydneyludvigson.com/s/MacroFinanceUncertainty_202508Update.zip
       Processing: monthly values averaged within each calendar quarter.

    3. Real-time GDP growth (first, second, third, most recent releases)
       Source: Philadelphia Fed Real-Time Data Set
       https://www.philadelphiafed.org/-/media/FRBP/Assets/Surveys-And-Data/
       real-time-data/data-files/xlsx/routput_first_second_third.xlsx

    4. Forecaster disagreement (disagree_percent)
       Constructed from SPF microdata using the Stata scripts 1_disagreement_*.

    This file was assembled by combining the above series manually
    (copy-and-paste) in Excel and then saved as a Stata .dta file.


data_month_202506.dta
    Monthly macroeconomic dataset manually assembled by the authors
    from the following public sources:

    1. Economic Policy Uncertainty (EPU) index
       Source: https://www.policyuncertainty.com/media/US_Policy_Uncertainty_Data.xlsx

    2. Jurado et al. (JU) macroeconomic uncertainty index
       Source: https://www.sydneyludvigson.com/s/MacroFinanceUncertainty_202508Update.zip

    3. Real-time employment growth (first, second, third, most recent releases)
       Source: Philadelphia Fed Real-Time Data Set
       https://www.philadelphiafed.org/-/media/FRBP/Assets/Surveys-And-Data/
       real-time-data/data-files/xlsx/employ_pct_chg_first_second_third.xlsx

    This file was assembled by combining the above series manually
    (copy-and-paste) in Excel and then saved as a Stata .dta file.


daily_epu_202506.dta
    Daily Economic Policy Uncertainty (EPU) index.
    Source: https://www.policyuncertainty.com/media/All_Daily_Policy_Data.csv

    This file was downloaded as a CSV file and imported into Stata.


----------------------------------------------------------------------
3. RECOMMENDED RUN ORDER
----------------------------------------------------------------------

To reproduce all results from scratch:

Step 0
    Download the raw SCE and SPF Excel files from the links provided in
    Section 2 (Data Files). Then run all scripts starting with 0_* to
    generate the main Stata datasets:
        us_hh_202506.dta
        us_spf_202506.dta

Step 1
    Run all scripts starting with 1_* to compute 
    - Forecaster disagreement
    - the GBD-based subjective uncertainty measures for professional forecasters and generate us_spf_est_202506.dta

Step 2
    Run the regression scripts:
        2_households   for household results
        2_spf          for professional forecaster results

    These scripts generate all tables reported in the paper and appendices
    (exported as CSV files).

Step 3
    Use the 3_* Excel file to construct Figure 1.

Step 4
    Run the 4_* MATLAB scripts to generate Figure 3.


----------------------------------------------------------------------
4. SOFTWARE AND NOTES
----------------------------------------------------------------------

Some Stata scripts contain absolute file paths (for example,
C:\Users\...\OneDrive\...). These should be edited to match the local
file location before running.

The following Stata packages are required:
    reghdfe
    eststo
    esttab

----------------------------------------------------------------------
End of README.txt
