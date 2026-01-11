/**********************************************************************
  US Professional Forecasters (SPF) — Reproducibility script
  Purpose:
    - Construct forecaster expectation + subjective uncertainty measures
    - Apply consistent sample/format flags
    - Produce SPF tables/figures (Tables 1–2, 6; Appendix A/B tables; Fig 8a)

  Notes:
    - Requires: reghdfe, estout (eststo/esttab)
    - Pattern follows the household script structure :contentReference[oaicite:0]{index=0}
    - Update the global paths below to your local folder structure
**********************************************************************/

clear all
set more off

*-----------------------------*
* 0) Paths (EDIT THESE)
*-----------------------------*
global DATA   "C:\Users\copyl\OneDrive\MU\paper1\Replication\data"
global OUT    "C:\Users\copyl\OneDrive\MU\paper1\Replication\output"

use "${DATA}\us_spf_est_202506.dta", clear

/**********************************************************************
  1) Merge macro data + dates
**********************************************************************/

* Merge quarterly macro series (includes epu/ju + survey timing vars)
merge m:1 year quarter using "${DATA}\data_quarter_202506.dta", ///
    keepusing(epu ju date first_l covid) nogen

drop if year < 1992

* Quarter date index already available as "date" (quarterly)
format date %tq

* Panel id/date
xtset id date

/**********************************************************************
  2) Key variables: point forecast + uncertainty indices
**********************************************************************/

gen lnepu = ln(epu)
gen lnju  = ln(ju)

* Real-time mean (provided) -> annualized/percent
gen mean_direct = (rgdpb/rgdpa - 1) * 100

* Cross-sectional disagreement within quarter
bysort date: egen disagree = sd(mean_direct)
gen lndis = ln(disagree)

* Daily EPU controls (if present in data)
capture confirm variable daily_epu
if _rc==0 {
    gen ln_daily_epu      = ln(daily_epu)
    gen ln_daily_epu_ma30 = ln(daily_epu_ma30)
}

/**********************************************************************
  3) Survey format & bin availability
  - Pre-2009Q2: bins 11–20
  - 2009Q2–2019Q4: bins 12–22 with midpoints +/- 6.45..3.55
  - 2020Q2+: bins 12–22 with wider midpoints (17.45..-13.55)
**********************************************************************/

gen bin_count = 0
forvalues i = 11/20 {
    replace bin_count = bin_count + 1 if prgdp`i' > 0 & !missing(prgdp`i') & date <= yq(2009,1)
}
forvalues i = 12/22 {
    replace bin_count = bin_count + 1 if prgdp`i' > 0 & !missing(prgdp`i') & date > yq(2009,1)
}

gen three_bin = (bin_count <= 3) if !missing(bin_count)

gen survey_format = 0
replace survey_format = 1 if date > yq(2009,1)
replace survey_format = 2 if date > yq(2020,1)

/**********************************************************************
  4) Subjective uncertainty measures (direct / MAM / EPRS )
**********************************************************************/

*-----------------------------*
* 4.1 Direct SD around point forecast (mean_direct)
*-----------------------------*
gen sd_direct = (((mean_direct - 6.45)^2*prgdp11+(mean_direct - 5.45)^2*prgdp12+(mean_direct - 4.45)^2*prgdp13+(mean_direct - 3.45)^2*prgdp14 ///
+(mean_direct - 2.45)^2*prgdp15+(mean_direct - 1.45)^2*prgdp16+(mean_direct - 0.45)^2*prgdp17+(mean_direct +0.55)^2*prgdp18 ///
+(mean_direct +1.55)^2*prgdp19+(mean_direct +2.55)^2*prgdp20)/100)^0.5

replace sd_direct = (((mean_direct - 6.45)^2*prgdp12+(mean_direct - 5.45)^2*prgdp13+(mean_direct - 4.45)^2*prgdp14+(mean_direct - 3.45)^2*prgdp15 ///
+(mean_direct - 2.45)^2*prgdp16+(mean_direct - 1.45)^2*prgdp17+(mean_direct - 0.45)^2*prgdp18+(mean_direct +0.55)^2*prgdp19 ///
+(mean_direct +1.55)^2*prgdp20+(mean_direct +2.55)^2*prgdp21+(mean_direct +3.55)^2*prgdp22)/100)^0.5 if date > yq(2009,1)

replace sd_direct = (((mean_direct - 17.45)^2*prgdp12+(mean_direct - 12.95)^2*prgdp13+(mean_direct - 8.45)^2*prgdp14+(mean_direct - 5.45)^2*prgdp15 ///
+(mean_direct - 3.2)^2*prgdp16+(mean_direct - 1.95)^2*prgdp17+(mean_direct - 0.7)^2*prgdp18+(mean_direct +1.55)^2*prgdp19 ///
+(mean_direct +4.55)^2*prgdp20+(mean_direct +9.05)^2*prgdp21+(mean_direct +13.55)^2*prgdp22)/100)^0.5 if date > yq(2020,1)

*-----------------------------*
* 4.2 MAM mean (bin-center weighted mean)
*-----------------------------*
gen mean_mam = (6.45*prgdp11+5.45*prgdp12+4.45*prgdp13+3.45*prgdp14 ///
+2.45*prgdp15+1.45*prgdp16+0.45*prgdp17-0.55*prgdp18 ///
-1.55*prgdp19-2.55*prgdp20)/100

replace mean_mam = (6.45*prgdp12+5.45*prgdp13+4.45*prgdp14+3.45*prgdp15 ///
+2.45*prgdp16+1.45*prgdp17+0.45*prgdp18-0.55*prgdp19 ///
-1.55*prgdp20-2.55*prgdp21-3.55*prgdp22)/100 if date > yq(2009,1)

replace mean_mam = (17.45*prgdp12+12.95*prgdp13+8.45*prgdp14+5.45*prgdp15 ///
+3.2*prgdp16+1.95*prgdp17+0.7*prgdp18-1.55*prgdp19 ///
-4.55*prgdp20-9.05*prgdp21-13.55*prgdp22)/100 if date > yq(2020,1)

*-----------------------------*
* 4.3 MAM SD (around mean_mam)
*-----------------------------*
gen sd_mam = (((mean_mam - 6.45)^2*prgdp11+(mean_mam - 5.45)^2*prgdp12+(mean_mam - 4.45)^2*prgdp13+(mean_mam - 3.45)^2*prgdp14 ///
+(mean_mam - 2.45)^2*prgdp15+(mean_mam - 1.45)^2*prgdp16+(mean_mam - 0.45)^2*prgdp17+(mean_mam +0.55)^2*prgdp18 ///
+(mean_mam +1.55)^2*prgdp19+(mean_mam +2.55)^2*prgdp20)/100)^0.5

replace sd_mam = (((mean_mam - 6.45)^2*prgdp12+(mean_mam - 5.45)^2*prgdp13+(mean_mam - 4.45)^2*prgdp14+(mean_mam - 3.45)^2*prgdp15 ///
+(mean_mam - 2.45)^2*prgdp16+(mean_mam - 1.45)^2*prgdp17+(mean_mam - 0.45)^2*prgdp18+(mean_mam +0.55)^2*prgdp19 ///
+(mean_mam +1.55)^2*prgdp20+(mean_mam +2.55)^2*prgdp21+(mean_mam +3.55)^2*prgdp22)/100)^0.5 if date > yq(2009,1)

replace sd_mam = (((mean_mam - 17.45)^2*prgdp12+(mean_mam - 12.95)^2*prgdp13+(mean_mam - 8.45)^2*prgdp14+(mean_mam - 5.45)^2*prgdp15 ///
+(mean_mam - 3.2)^2*prgdp16+(mean_mam - 1.95)^2*prgdp17+(mean_mam - 0.7)^2*prgdp18+(mean_mam +1.55)^2*prgdp19 ///
+(mean_mam +4.55)^2*prgdp20+(mean_mam +9.05)^2*prgdp21+(mean_mam +13.55)^2*prgdp22)/100)^0.5 if date > yq(2020,1)

*-----------------------------*
* 4.4 EPRS-style uncertainty: sum p(1-p)
*-----------------------------*
gen sd_eprs = (prgdp11*(100-prgdp11)+prgdp12*(100-prgdp12)+prgdp13*(100-prgdp13)+prgdp14*(100-prgdp14) ///
+prgdp15*(100-prgdp15)+prgdp16*(100-prgdp16)+prgdp17*(100-prgdp17)+prgdp18*(100-prgdp18) ///
+prgdp19*(100-prgdp19)+prgdp20*(100-prgdp20))/100

replace sd_eprs = (prgdp12*(100-prgdp12)+prgdp13*(100-prgdp13)+prgdp14*(100-prgdp14)+prgdp15*(100-prgdp15) ///
+prgdp16*(100-prgdp16)+prgdp17*(100-prgdp17)+prgdp18*(100-prgdp18)+prgdp19*(100-prgdp19) ///
+prgdp20*(100-prgdp20)+prgdp21*(100-prgdp21)+prgdp22*(100-prgdp22))/100 if date > yq(2009,1)


/**********************************************************************
  5) Bounds + span (same sectioning as household script)
**********************************************************************/

gen lower_bound  = .
gen upper_bound = .

* Endpoints by survey format (as in your final code)
replace upper_bound = 6.45   if prgdp11 > 0 & !missing(prgdp11) & date>=yq(1992,1) & date<=yq(2009,1)
replace lower_bound  = -2.55  if prgdp20 > 0 & !missing(prgdp20) & date>=yq(1992,1) & date<=yq(2009,1)

replace upper_bound = 6.45   if prgdp12 > 0 & !missing(prgdp12) & date>=yq(2009,2) & date<=yq(2020,1)
replace lower_bound  = -3.55  if prgdp22 > 0 & !missing(prgdp22) & date>=yq(2009,2) & date<=yq(2020,1)

replace upper_bound = 17.45  if prgdp12 > 0 & !missing(prgdp12) & date>=yq(2020,2)
replace lower_bound  = -13.55 if prgdp22 > 0 & !missing(prgdp22) & date>=yq(2020,2)

* Fill interior lower/upper by scanning bins
local mid1 5.45 4.45 3.45 2.45 1.45 0.45 -0.55 -1.55 -2.55
local mid2 6.45 5.45 4.45 3.45 2.45 1.45 0.45 -0.55 -1.55 -2.55 -3.55
local mid3 17.45 12.95 8.45 5.45 3.2 1.95 0.7 -1.55 -4.55 -9.05 -13.55

local r = 12
foreach i of local mid1 {
    replace lower_bound  = `i' if prgdp`r'>0 & !missing(prgdp`r') & date>=yq(1992,1) & date<=yq(2009,1)
    replace upper_bound = `i' if prgdp`r'>0 & !missing(prgdp`r') & missing(upper_bound)     & date>=yq(1992,1) & date<=yq(2009,1)
    local r = `r'+1
}

local r = 13
foreach i of local mid2 {
    replace lower_bound  = `i' if prgdp`r'>0 & !missing(prgdp`r') & date>=yq(2009,2) & date<=yq(2020,1)
    replace upper_bound = `i' if prgdp`r'>0 & !missing(prgdp`r') & missing(upper_bound)     & date>=yq(2009,2) & date<=yq(2020,1)
    local r = `r'+1
}

local r = 13
foreach i of local mid3 {
    replace lower_bound  = `i' if prgdp`r'>0 & !missing(prgdp`r') & date>=yq(2020,2)
    replace upper_bound = `i' if prgdp`r'>0 & !missing(prgdp`r') & missing(upper_bound)     & date>=yq(2020,2)
    local r = `r'+1
}

gen span = upper_bound - lower_bound
replace upper_bound = . if span<0 | bin_count==0
replace lower_bound  = . if span<0 | bin_count==0
replace span = . if span<0 | bin_count==0

/**********************************************************************
  6) Final trims (match household "cleaning" section style)
**********************************************************************/

replace sd_mam    = . if sd_mam<=0
replace sd_direct = . if sd_direct<=0

* If your data has GBD mean/sd stored as mean/sd/std:
capture confirm variable std
if _rc==0 {
    rename std  sd_gbd
    rename mean mean_gbd
    replace sd_gbd = . if sd_gbd<=0
}

/**********************************************************************
  7) Main-text SPF tables (same section header pattern)
**********************************************************************/

*========================
* Table 1 (SPF) Columns 1-3
*========================
xtset id date
eststo clear
eststo: reghdfe mean_direct L.mean_direct lnepu first_l i.quarter i.year i.survey_format covid, vce(cluster id date) ab(id)
eststo: reghdfe mean_direct L.mean_direct lnju  first_l i.quarter i.year i.survey_format covid, vce(cluster id date) ab(id)
eststo: reghdfe mean_direct L.mean_direct lndis first_l i.quarter i.year i.survey_format covid, vce(cluster id date) ab(id)

esttab using "${OUT}\spf_table1.csv", replace ///
    star(* 0.10 ** 0.05 *** 0.01) se ///
    drop(*.year *.quarter covid 0.survey_format) nogap ///
    order(lnepu lnju lndis first_l L.mean_direct 1.survey_format 2.survey_format _cons) ///
    varlabels( ///
        lnepu "Log Economic Policy Uncertainty index" ///
        lnju  "Log Jurado et al. index" ///
        lndis "Log Forecasters disagreement" ///
        first_l "Lagged real-time GDP growth" ///
        L.mean_direct "Lagged dependent variable" ///
        1.survey_format "Survey between 2009Q2-2019Q4" ///
        2.survey_format "Survey since 2020Q1" ///
        _cons "Constant") ///
    stats(N N_clust1 r2_a, fmt(0 0 2) labels("Number of observations" "Number of individuals" "Adjusted R-squared"))

*========================
* Table 2 (SPF) Columns 1-3
*========================
xtset id date
eststo clear
eststo: reghdfe sd_mam L.sd_mam lnepu first_l i.quarter i.year i.survey_format covid, vce(cluster id date) ab(id)
eststo: reghdfe sd_mam L.sd_mam lnju  first_l i.quarter i.year i.survey_format covid, vce(cluster id date) ab(id)
eststo: reghdfe sd_mam L.sd_mam lndis first_l i.quarter i.year i.survey_format covid, vce(cluster id date) ab(id)

esttab using "${OUT}\spf_table2.csv", replace ///
    star(* 0.10 ** 0.05 *** 0.01) se ///
    drop(*.year *.quarter covid 0.survey_format) nogap ///
    order(lnepu lnju lndis first_l L.sd_mam 1.survey_format 2.survey_format _cons) ///
    varlabels( ///
        lnepu "Log Economic Policy Uncertainty index" ///
        lnju  "Log Jurado et al. index" ///
        lndis "Log Forecasters disagreement" ///
        first_l "Lagged real-time GDP growth" ///
        L.sd_mam "Lagged dependent variable" ///
        1.survey_format "Survey between 2009Q2-2019Q4" ///
        2.survey_format "Survey since 2020Q1" ///
        _cons "Constant") ///
    stats(N N_clust1 r2_a, fmt(0 0 2) labels("Number of observations" "Number of individuals" "Adjusted R-squared"))

*========================
* Table 6 (SPF): lower/upper/span regressions
*========================
xtset id date
eststo clear

* Lower bound
eststo: reghdfe lower_bound  L.lower_bound  lnepu first_l i.quarter i.year i.survey_format covid, vce(cluster id date) ab(id)
eststo: reghdfe lower_bound  L.lower_bound  lnju  first_l i.quarter i.year i.survey_format covid, vce(cluster id date) ab(id)
eststo: reghdfe lower_bound  L.lower_bound  lndis first_l i.quarter i.year i.survey_format covid, vce(cluster id date) ab(id)

* Upper bound
eststo: reghdfe upper_bound L.upper_bound lnepu first_l i.quarter i.year i.survey_format covid, vce(cluster id date) ab(id)
eststo: reghdfe upper_bound L.upper_bound lnju  first_l i.quarter i.year i.survey_format covid, vce(cluster id date) ab(id)
eststo: reghdfe upper_bound L.upper_bound lndis first_l i.quarter i.year i.survey_format covid, vce(cluster id date) ab(id)

* Span
eststo: reghdfe span L.span lnepu first_l i.quarter i.year i.survey_format covid, vce(cluster id date) ab(id)
eststo: reghdfe span L.span lnju  first_l i.quarter i.year i.survey_format covid, vce(cluster id) ab(id)
eststo: reghdfe span L.span lndis first_l i.quarter i.year i.survey_format covid, vce(cluster id date) ab(id)

esttab using "${OUT}\spf_table6.csv", replace ///
    star(* 0.10 ** 0.05 *** 0.01) se ///
    drop(*.year *.quarter covid 0.survey_format) nogap ///
    order(lnepu lnju lndis first_l L.lower_bound 1.survey_format 2.survey_format _cons) ///
    varlabels( ///
        lnepu "Log Economic Policy Uncertainty index" ///
        lnju  "Log Jurado et al. index" ///
        lndis "Log Forecasters disagreement" ///
        first_l "Lagged real-time GDP growth" ///
        L.lower_bound "Lagged dependent variable" ///
        1.survey_format "Survey between 2009Q2-2019Q4" ///
        2.survey_format "Survey since 2020Q1" ///
        _cons "Constant") ///
    stats(N N_clust1 r2_a, fmt(0 0 2) labels("Number of observations" "Number of individuals" "Adjusted R-squared"))

/**********************************************************************
  Appendix A
**********************************************************************/

* Table 8-style summary (adjust varlist to what exists in SPF file)
xtsum mean_direct mean_mam mean_gbd sd_mam sd_gbd lower_bound upper_bound span

* Figure 8(a)
preserve
collapse (mean) mean_direct sd_mam, by(date)
twoway ///
    (line mean_direct date, yaxis(1) lcolor(navy) lwidth(medthick)) ///
    (line sd_mam     date, yaxis(2) lcolor(forest_green) lwidth(medthick) lpattern(shortdash)) ///
    , ///
    xline(`=yq(2009,1)' `=yq(2020,1)', lpattern(dash) lcolor(gs8) lwidth(medthin)) ///
    xtitle("Date") ///
    ylabel(, angle(horizontal) grid) ///
    ylabel(, axis(2) angle(horizontal)) ///
    ytitle("Mean expectations (%)") ///
    ytitle("Subjective uncertainty (%)", axis(2)) ///
    legend(order(1 "Mean expectations provided respondents" 2 "Subjective uncertainty (MAM)") ///
           pos(6) ring(0) col(1) region(lstyle(none))) ///
    plotregion(margin(small)) graphregion(color(white)) ///
    scheme(s2color)
restore

preserve
collapse (sd) mean_direct, by(date)
restore

/**********************************************************************
 Appendix B.1
**********************************************************************/
*========================
* Table 9
*========================
xtset id date
eststo clear
* Panel A Columns 1-9
eststo: reghdfe mean_direct l.mean_direct lnepu i.quarter i.year i.survey_format covid , vce(cluster id date) 
eststo: reghdfe mean_direct l.mean_direct lnepu first_l i.quarter i.year i.survey_format covid , vce(cluster id date)
eststo: reghdfe mean_direct l.mean_direct lnepu first_l i.quarter i.year i.survey_format covid , vce(cluster id date) ab(id)
eststo: reghdfe mean_direct l.mean_direct lnju i.quarter i.year i.survey_format covid , vce(cluster id date) 
eststo: reghdfe mean_direct l.mean_direct lnju first_l i.quarter i.year i.survey_format covid , vce(cluster id date)
eststo: reghdfe mean_direct l.mean_direct lnju first_l i.quarter i.year i.survey_format covid , vce(cluster id date) ab(id)
eststo: reghdfe mean_direct l.mean_direct lndis i.quarter i.year i.survey_format covid , vce(cluster id date) 
eststo: reghdfe mean_direct l.mean_direct lndis first_l i.quarter i.year i.survey_format covid , vce(cluster id date)
eststo: reghdfe mean_direct l.mean_direct lndis first_l i.quarter i.year i.survey_format covid , vce(cluster id date) ab(id)

* Panel A Columns 10-18
eststo: reghdfe mean_mam l.mean_mam lnepu i.quarter i.year  i.survey_format covid , vce(cluster id date) 
eststo: reghdfe mean_mam l.mean_mam lnepu first_l i.quarter i.year i.survey_format  covid , vce(cluster id date)
eststo: reghdfe mean_mam l.mean_mam lnepu first_l i.quarter i.year  i.survey_format covid , vce(cluster id date) ab(id)
eststo: reghdfe mean_mam l.mean_mam lnju i.quarter i.year  i.survey_format covid , vce(cluster id date) 
eststo: reghdfe mean_mam l.mean_mam lnju first_l i.quarter i.year i.survey_format  covid , vce(cluster id date)
eststo: reghdfe mean_mam l.mean_mam lnju first_l i.quarter i.year  i.survey_format covid , vce(cluster id date) ab(id)
eststo: reghdfe mean_mam l.mean_mam lndis i.quarter i.year  i.survey_format  covid , vce(cluster id date) 
eststo: reghdfe mean_mam l.mean_mam lndis first_l i.quarter i.year  i.survey_format covid , vce(cluster id date)
eststo: reghdfe mean_mam l.mean_mam lndis first_l i.quarter i.year  i.survey_format covid , vce(cluster id date) ab(id)

* Panel B Columns 1-9
eststo: reghdfe mean_gbd l.mean_gbd lnepu i.quarter i.year  i.survey_format covid , vce(cluster id date) 
eststo: reghdfe mean_gbd l.mean_gbd lnepu first_l i.quarter i.year i.survey_format  covid , vce(cluster id date)
eststo: reghdfe mean_gbd l.mean_gbd lnepu first_l i.quarter i.year  i.survey_format covid , vce(cluster id date) ab(id)
eststo: reghdfe mean_gbd l.mean_gbd lnju i.quarter i.year  i.survey_format covid , vce(cluster id date) 
eststo: reghdfe mean_gbd l.mean_gbd lnju first_l i.quarter i.year i.survey_format  covid , vce(cluster id date)
eststo: reghdfe mean_gbd l.mean_gbd lnju first_l i.quarter i.year  i.survey_format covid , vce(cluster id date) ab(id)
eststo: reghdfe mean_gbd l.mean_gbd lndis i.quarter i.year  i.survey_format  covid , vce(cluster id date) 
eststo: reghdfe mean_gbd l.mean_gbd lndis first_l i.quarter i.year  i.survey_format covid , vce(cluster id date)
eststo: reghdfe mean_gbd l.mean_gbd lndis first_l i.quarter i.year  i.survey_format covid , vce(cluster id date) ab(id)
esttab using "${OUT}\spf_table9.csv", replace ///
    star(* 0.10 ** 0.05 *** 0.01) ///
   se ///
    drop(*.year *.quarter covid 0.survey_format) nogap ///
    order(lnepu lnju lndis first_l ///
          L.mean_direct L.mean_gbd L.mean_mam 1.survey_format 2.survey_format _cons) ///
	    varlabels( ///
        lnepu     "Log EPU" ///
        lnju      "Log JU" ///
        lndis     "Log Disagreement" ///
        first_l   "Lagged real-time GDP growth" ///
        L.emp1    "Lagged real-time employment rate" ///
        0.employ  "Being unemployed" ///
        L.mean_direct "Lagged dependent variable" ///
		1.survey_format "Survey between 2009Q2-2019Q4" ///
		2.survey_format "Survey since 2020Q1" ///
		_cons "Constant") ///
    stats(N N_clust1 r2_a, fmt(0 0 2) labels("Number of observations" "Number of individuals" "Adjusted R-squared"))
	
/**********************************************************************
 Appendix B.2
**********************************************************************/
*========================
* Table 11
*========================	

xtset id date
eststo clear
* Columns 1-9
eststo: reghdfe sd_mam l.sd_mam lnepu i.quarter i.year  i.survey_format covid , vce(cluster id date) 
eststo: reghdfe sd_mam l.sd_mam lnepu first_l i.quarter i.year i.survey_format  covid , vce(cluster id date)
eststo: reghdfe sd_mam l.sd_mam lnepu first_l i.quarter i.year  i.survey_format covid , vce(cluster id date) ab(id)
eststo: reghdfe sd_mam l.sd_mam lnju i.quarter i.year  i.survey_format covid , vce(cluster id date) 
eststo: reghdfe sd_mam l.sd_mam lnju first_l i.quarter i.year i.survey_format  covid , vce(cluster id date)
eststo: reghdfe sd_mam l.sd_mam lnju first_l i.quarter i.year  i.survey_format covid , vce(cluster id date) ab(id)
eststo: reghdfe sd_mam l.sd_mam lndis i.quarter i.year  i.survey_format  covid ,vce(cluster id date) 
eststo: reghdfe sd_mam l.sd_mam lndis first_l i.quarter i.year  i.survey_format covid , vce(cluster id date)
eststo: reghdfe sd_mam l.sd_mam lndis first_l i.quarter i.year  i.survey_format covid , vce(cluster id date) ab(id)

* Columns 10-18
eststo: reghdfe sd_gbd l.sd_gbd lnepu i.quarter i.year i.survey_format  covid ,vce(cluster id date) 
eststo: reghdfe sd_gbd l.sd_gbd lnepu first_l i.quarter i.year i.survey_format  covid , vce(cluster id date)
eststo: reghdfe sd_gbd l.sd_gbd lnepu first_l i.quarter i.year  i.survey_format  covid , vce(cluster id date) ab(id)
eststo: reghdfe sd_gbd l.sd_gbd lnju i.quarter i.year  i.survey_format  covid , vce(cluster id date) 
eststo: reghdfe sd_gbd l.sd_gbd lnju first_l i.quarter i.year i.survey_format   covid , vce(cluster id date)
eststo: reghdfe sd_gbd l.sd_gbd lnju first_l i.quarter i.year i.survey_format  covid , vce(cluster id date) ab(id)
eststo: reghdfe sd_gbd l.sd_gbd lndis i.quarter i.year i.survey_format  covid ,vce(cluster id date) 
eststo: reghdfe sd_gbd l.sd_gbd lndis first_l i.quarter i.year i.survey_format  covid , vce(cluster id date)
eststo: reghdfe sd_gbd l.sd_gbd lndis first_l i.quarter i.year i.survey_format   covid , vce(cluster id date) ab(id)
esttab using "${OUT}\spf_table11.csv", replace ///
    star(* 0.10 ** 0.05 *** 0.01) ///
   se ///
    drop(*.year *.quarter covid 0.survey_format) nogap ///
    order(lnepu lnju lndis first_l ///
          L.sd_mam 1.survey_format 2.survey_format _cons) ///
	    varlabels( ///
        lnepu     "Log EPU" ///
        lnju      "Log JU" ///
        lndis     "Log Disagreement" ///
        first_l   "Lagged real-time GDP growth" ///
        L.emp1    "Lagged real-time employment rate" ///
        0.employ  "Being unemployed" ///
        L.mean_direct "Lagged dependent variable" ///
		1.survey_format "Survey between 2009Q2-2019Q4" ///
		2.survey_format "Survey since 2020Q1" ///
		_cons "Constant") ///
    stats(N N_clust1 r2_a, fmt(0 0 2) labels("Number of observations" "Number of individuals" "Adjusted R-squared"))

*========================
* Table 13
*========================	

xtset id date
eststo clear
* Columns 1-9
eststo: reghdfe sd_mam l.sd_mam lnepu i.quarter i.year  i.survey_format covid if year>2012, vce(cluster id date) 
eststo: reghdfe sd_mam l.sd_mam lnepu first_l i.quarter i.year i.survey_format  covid if year>2012 , vce(cluster id date)
eststo: reghdfe sd_mam l.sd_mam lnepu first_l i.quarter i.year  i.survey_format covid if year>2012 , vce(cluster id date) ab(id)
eststo: reghdfe sd_mam l.sd_mam lnju i.quarter i.year  i.survey_format covid if year>2012 , vce(cluster id date) 
eststo: reghdfe sd_mam l.sd_mam lnju first_l i.quarter i.year i.survey_format  covid if year>2012 , vce(cluster id date)
eststo: reghdfe sd_mam l.sd_mam lnju first_l i.quarter i.year  i.survey_format covid if year>2012 , vce(cluster id date) ab(id)
eststo: reghdfe sd_mam l.sd_mam lndis i.quarter i.year  i.survey_format  covid if year>2012 ,vce(cluster id date) 
eststo: reghdfe sd_mam l.sd_mam lndis first_l i.quarter i.year  i.survey_format covid if year>2012 , vce(cluster id date)
eststo: reghdfe sd_mam l.sd_mam lndis first_l i.quarter i.year  i.survey_format covid if year>2012 , vce(cluster id date) ab(id)

* Columns 10-18
eststo: reghdfe sd_gbd l.sd_gbd lnepu i.quarter i.year i.survey_format  covid if year>2012 ,vce(cluster id date) 
eststo: reghdfe sd_gbd l.sd_gbd lnepu first_l i.quarter i.year i.survey_format  covid if year>2012 , vce(cluster id date)
eststo: reghdfe sd_gbd l.sd_gbd lnepu first_l i.quarter i.year  i.survey_format  covid if year>2012 , vce(cluster id date) ab(id)
eststo: reghdfe sd_gbd l.sd_gbd lnju i.quarter i.year  i.survey_format  covid if year>2012 , vce(cluster id date) 
eststo: reghdfe sd_gbd l.sd_gbd lnju first_l i.quarter i.year i.survey_format   covid if year>2012 , vce(cluster id date)
eststo: reghdfe sd_gbd l.sd_gbd lnju first_l i.quarter i.year i.survey_format  covid if year>2012 , vce(cluster id date) ab(id)
eststo: reghdfe sd_gbd l.sd_gbd lndis i.quarter i.year i.survey_format  covid if year>2012 ,vce(cluster id date) 
eststo: reghdfe sd_gbd l.sd_gbd lndis first_l i.quarter i.year i.survey_format  covid if year>2012 , vce(cluster id )
eststo: reghdfe sd_gbd l.sd_gbd lndis first_l i.quarter i.year i.survey_format   covid if year>2012 , vce(cluster id date) ab(id)
esttab using "${OUT}\spf_table13.csv", replace ///
    star(* 0.10 ** 0.05 *** 0.01) ///
   se ///
    drop(*.year *.quarter covid 1.survey_format ) nogap ///
    order(lnepu lnju lndis first_l ///
          L.sd_mam 2.survey_format _cons) ///
	    varlabels( ///
        lnepu     "Log EPU" ///
        lnju      "Log JU" ///
        lndis     "Log Disagreement" ///
        first_l   "Lagged real-time GDP growth" ///
        L.emp1    "Lagged real-time employment rate" ///
        0.employ  "Being unemployed" ///
        L.mean_direct "Lagged dependent variable" ///
		1.survey_format "Survey between 2009Q2-2019Q4" ///
		2.survey_format "Survey since 2020Q1" ///
		_cons "Constant") ///
    stats(N N_clust1 r2_a, fmt(0 0 2) labels("Number of observations" "Number of individuals" "Adjusted R-squared"))
	


/**********************************************************************
 Appendix B.4
**********************************************************************/
*========================
* Table 19
*========================	
xtset id date
eststo clear
* Panel A Columns 1-9
eststo: reghdfe  lower_bound l.lower_bound lnepu i.quarter i.year  i.survey_format covid , vce(cluster id date) 
eststo: reghdfe  lower_bound l.lower_bound lnepu first_l i.quarter i.year i.survey_format  covid , vce(cluster id date)
eststo: reghdfe  lower_bound l.lower_bound lnepu first_l i.quarter i.year  i.survey_format covid , vce(cluster id date) ab(id)
eststo: reghdfe  lower_bound l.lower_bound lnju i.quarter i.year  i.survey_format covid ,vce(cluster id date) 
eststo: reghdfe  lower_bound l.lower_bound lnju first_l i.quarter i.year i.survey_format  covid , vce(cluster id date)
eststo: reghdfe  lower_bound l.lower_bound lnju first_l i.quarter i.year  i.survey_format covid , vce(cluster id date) ab(id)
eststo: reghdfe  lower_bound l.lower_bound lndis i.quarter i.year  i.survey_format  covid , vce(cluster id date) 
eststo: reghdfe  lower_bound l.lower_bound lndis first_l i.quarter i.year  i.survey_format covid , vce(cluster id date)
eststo: reghdfe  lower_bound l.lower_bound lndis first_l i.quarter i.year  i.survey_format covid , vce(cluster id date) ab(id)

* Panel A Columns 10-18
eststo: reghdfe upper_bound l.upper_bound lnepu i.quarter i.year i.survey_format  covid , vce(cluster id date) 
eststo: reghdfe upper_bound l.upper_bound lnepu first_l i.quarter i.year i.survey_format  covid , vce(cluster id date)
eststo: reghdfe upper_bound l.upper_bound lnepu first_l i.quarter i.year  i.survey_format  covid , vce(cluster id date) ab(id)
eststo: reghdfe upper_bound l.upper_bound lnju i.quarter i.year  i.survey_format  covid , vce(cluster id date) 
eststo: reghdfe upper_bound l.upper_bound lnju first_l i.quarter i.year i.survey_format   covid , vce(cluster id date)
eststo: reghdfe upper_bound l.upper_bound lnju first_l i.quarter i.year i.survey_format  covid , vce(cluster id date) ab(id)
eststo: reghdfe upper_bound l.upper_bound lndis i.quarter i.year i.survey_format  covid , vce(cluster id date) 
eststo: reghdfe upper_bound l.upper_bound lndis first_l i.quarter i.year i.survey_format  covid , vce(cluster id date)
eststo: reghdfe upper_bound l.upper_bound lndis first_l i.quarter i.year i.survey_format   covid , vce(cluster id date) ab(id)

* Panel B Columns 1-9
eststo: reghdfe span l.span lnepu i.quarter i.year i.survey_format  covid, vce(cluster id) 
eststo: reghdfe span l.span lnepu first_l i.quarter i.year i.survey_format  covid , vce(cluster id date)
eststo: reghdfe span l.span lnepu first_l i.quarter i.year  i.survey_format  covid , vce(cluster id date) ab(id)
eststo: reghdfe span l.span lnju i.quarter i.year  i.survey_format  covid ,vce(cluster id) 
eststo: reghdfe span l.span lnju first_l i.quarter i.year i.survey_format   covid , vce(cluster id)
eststo: reghdfe span l.span lnju first_l i.quarter i.year i.survey_format  covid , vce(cluster id) ab(id)
eststo: reghdfe span l.span lndis i.quarter i.year i.survey_format  covid , vce(cluster id date) 
eststo: reghdfe span l.span lndis first_l i.quarter i.year i.survey_format  covid , vce(cluster id date)
eststo: reghdfe span l.span lndis first_l i.quarter i.year i.survey_format   covid , vce(cluster id date) ab(id)
esttab using "${OUT}\spf_table19.csv", replace ///
    star(* 0.10 ** 0.05 *** 0.01) ///
   se ///
    drop(*.year *.quarter covid 1.survey_format ) nogap ///
    order(lnepu lnju lndis first_l ///
          L.lower_bound 1.survey_format 2.survey_format _cons) ///
	    varlabels( ///
        lnepu     "Log EPU" ///
        lnju      "Log JU" ///
        lndis     "Log Disagreement" ///
        first_l   "Lagged real-time GDP growth" ///
        L.emp1    "Lagged real-time employment rate" ///
        0.employ  "Being unemployed" ///
        L.lower_bound "Lagged dependent variable" ///
		1.survey_format "Survey between 2009Q2-2019Q4" ///
		2.survey_format "Survey since 2020Q1" ///
		_cons "Constant") ///
    stats(N N_clust1 r2_a, fmt(0 0 2) labels("Number of observations" "Number of individuals" "Adjusted R-squared"))