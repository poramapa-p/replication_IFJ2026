/**********************************************************************
Replication package: Build core Stata datasets from raw Excel files

What this do-file does
1) Imports NY Fed SCE microdata Excel files (2013–2016, 2017–2019, 2020–latest),
   saves intermediate .dta files, appends them, standardizes varnames to lower,
   and saves us_hh_202506.dta.

2) Imports SPF historical microdata (PRGDP + RGDP sheets), saves intermediates,
   merges, standardizes varnames to lower, and saves us_spf_202506.dta.

Notes for replication
- Update the ROOT paths below to match your local folder structure.
- Requires Stata 16+ for rename *, lower (Stata 17 is fine).
**********************************************************************/

clear all
set more off

/**********************
* 0) User paths
**********************/
* Root folder for your replication package (edit this)
global ROOT    "C:\Users\copyl\OneDrive\MU\paper1"

* Raw Excel folder (edit if different)
global RAWXL   "${ROOT}\updated excel"

* Output data folder (edit if different)
global DATA    "${ROOT}\data"

/* Create output folder if it does not exist (safe if it already exists) */
cap mkdir "${DATA}"


/**********************************************************************
* 1) HOUSEHOLDS (NY Fed SCE): import -> save intermediates -> append
**********************************************************************/
* ---- Input Excel files
global SCE_LATEST "${RAWXL}\frbny-sce-public-microdata-latest_062025.xlsx"
global SCE_17_19  "${RAWXL}\FRBNY-SCE-Public-Microdata-Complete-17-19_062025.xlsx"
global SCE_13_16  "${RAWXL}\FRBNY-SCE-Public-Microdata-Complete-13-16_062025.xlsx"

* ---- Intermediate .dta outputs
global HH_LATEST_DTA "${DATA}\us_hh_latest.dta"
global HH_2019_DTA   "${DATA}\us_hh_2019.dta"
global HH_2016_DTA   "${DATA}\us_hh_2016.dta"

* ---- Final output
global HH_FINAL_DTA  "${DATA}\us_hh_202506.dta"

* Import and save each wave
clear
import excel "${SCE_LATEST}", firstrow clear
rename *, lower
save "${HH_LATEST_DTA}", replace

clear
import excel "${SCE_17_19}", firstrow clear
rename *, lower
save "${HH_2019_DTA}", replace

clear
import excel "${SCE_13_16}", firstrow clear
rename *, lower
save "${HH_2016_DTA}", replace

* Append waves (latest + 17-19 + 13-16)
use "${HH_LATEST_DTA}", clear
append using "${HH_2019_DTA}"
append using "${HH_2016_DTA}"

* (Optional) You can enforce a consistent type for key IDs here if needed:
* destring userid, replace force

save "${HH_FINAL_DTA}", replace


/**********************************************************************
* 2) SPF: import PRGDP and RGDP sheets -> merge -> save
**********************************************************************/
* ---- Input Excel
global SPF_XLSX "${RAWXL}\SPFmicrodata_062025.xlsx"

* ---- Intermediate outputs
global SPF_PRGDP_DTA "${DATA}\us_spf_prgdp.dta"
global SPF_RGDP_DTA  "${DATA}\us_spf_rgdp.dta"

* ---- Final output
global SPF_FINAL_DTA "${DATA}\us_spf_202506.dta"

* Import PRGDP sheet
clear
import excel "${SPF_XLSX}", sheet("PRGDP") firstrow clear
rename *, lower
save "${SPF_PRGDP_DTA}", replace

* Import RGDP sheet
clear
import excel "${SPF_XLSX}", sheet("RGDP") firstrow clear
rename *, lower
save "${SPF_RGDP_DTA}", replace

* Merge PRGDP + RGDP
use "${SPF_PRGDP_DTA}", clear
merge 1:1 year quarter id using "${SPF_RGDP_DTA}"
drop _merge

save "${SPF_FINAL_DTA}", replace


