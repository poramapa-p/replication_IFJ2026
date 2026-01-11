/**********************************************************************
  Reproducibility script
  Purpose:
    - Construct professional forecasters' disagreement measure
      (cross-sectional SD of mean_direct in each quarter)
  Notes:
    - Update the global paths below to your local folder structure
**********************************************************************/

clear all
set more off
version 17

*-----------------------------*
* 0) Paths (EDIT THESE)
*-----------------------------*
global DATA   "C:\Users\copyl\OneDrive\MU\paper1\Replication\data"
global OUT    "C:\Users\copyl\OneDrive\MU\paper1\Replication\output"

* Create output folder if it does not exist
cap mkdir "${OUT}"

*-----------------------------*
* 1) Load data
*-----------------------------*
use "${DATA}\us_spf_202506.dta", clear

* Panel structure
xtset id date

*-----------------------------*
* 2) Construct mean forecast (direct) and disagreement
*-----------------------------*
* Mean direct forecast (percent)
gen mean_direct = (rgdpb/rgdpa - 1) * 100

* Disagreement = cross-sectional SD across forecasters per quarter (date)
collapse (sd) disagree_percent = mean_direct, by(date)

