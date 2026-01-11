/**********************************************************************
  US Households (SCE) — Reproducibility script
  Purpose:
    - Construct household expectation + uncertainty measures
    - Apply sample cleaning rules used in the manuscript
    - Produce household tables/figures (Tables 1–6, 7, 10, 12, 14–17, 19; Fig 8b)

  Notes:
    - Requires: reghdfe, estout (eststo/esttab)
    - Update the global paths below to your local folder structure
**********************************************************************/

clear all
set more off

*-----------------------------*
* 0) Paths (EDIT THESE)
*-----------------------------*
global DATA   "C:\Users\copyl\OneDrive\MU\paper1\Replication\data"
global OUT    "C:\Users\copyl\OneDrive\MU\paper1\Replication\output"

use "${DATA}\us_hh_202506.dta", clear

/**********************************************************************
  1) Time variables (panel index)
  - Your household panel is monthly; you use year/month fixed effects.
  - You also merge quarterly macro series (year/quarter) and daily EPU (survey_date).
**********************************************************************/

* Original "date" is YYYYMM numeric -> convert to Stata monthly date
gen year  = floor(date/100)
gen month = mod(date,100)

gen mdate = ym(year, month)
format mdate %tm
drop date
rename mdate date
order date, first

* survey_date is daily date (%td). Keep for daily EPU merge.
format survey_date %td
gen quarter = quarter(survey_date)

* Panel identifier used in regressions
drop if missing(userid)

/**********************************************************************
  2) Merge macro data (monthly / quarterly / daily)
  - Quarterly: disagree measures + first_l
  - Monthly: epu, ju, vix, emp1, geopo + shocks (some may be used elsewhere)
  - Daily: daily_epu and MA30 for Table 5 / Table 17 (daily EPU regressions)
**********************************************************************/

merge m:1 year quarter using "${DATA}\data_quarter_202506.dta", ///
    keepusing(disagree_percent first_l) nogen

merge m:1 year month using "${DATA}\data_month_202506.dta", ///
    keepusing(epu ju emp1) nogen

merge m:1 survey_date using "${DATA}\daily_epu_202506.dta", ///
    keepusing(daily_epu daily_epu_ma30) nogen

/**********************************************************************
  3) Key demographics / controls used in tables
  - employ: unemployment indicator (your regressions use 0.employ)
  - job_length: tenure proxy (Table 3/4/15/16 splits at <5 vs >=5)
  - gender + age1: Appendix Table 7 panel B
  - _EDU_CAT: education splits (Table 3/4/15/16)
  - _NUM_CAT: numeracy splits (Table 14)
**********************************************************************/

* Gender / Age (constant within userid; you collapse by mean)
bysort userid: egen gender = mean(q33)
bysort userid: egen age1   = mean(q32)

* Employment: you define employ = q10_1 + q10_2
gen employ = q10_1 + q10_2

* Job tenure (used for split job_length <5 vs ==5 in your code)
bysort userid: egen job_length = mean(q37)

* Rename expectations variables from survey
rename q23v2part2 mean_direct     // point forecast (%)
rename q24_mean   mean_gbd        // GBD mean (provided in data)
gen    sd_gbd = sqrt(q24_va)      // GBD sd from variance

* COVID dummy (used as control in many tables)
gen covid = (year > 2019) & (year <= 2022)

/**********************************************************************
  4) Log transforms of uncertainty indices
  - Used as main regressors in Tables 1/2/4/6/10/12/14/16/19
**********************************************************************/

gen lnepu  = ln(epu)
gen lnju   = ln(ju)
gen lndis  = ln(disagree_percent)

* Daily EPU regressors (Tables 5 and 17)
gen ln_daily_epu        = ln(daily_epu)
gen ln_daily_epu_ma30   = ln(daily_epu_ma30)

/**********************************************************************
  5) Histogram-based moments (MAM) + alternative uncertainty measures
  - mean_mam, sd_mam are core in main text
  - Lower, Upper-bound forecasts and span
  - sd_eprs (entropy-style)
  - mode_count + all_equal implement your "10% everywhere" / shape restrictions
**********************************************************************/

* Count how many bins are non-zero
gen bin_count = 0
forvalues i = 1/10 {
    replace bin_count = bin_count + 1 if q24_bin`i' > 0 & !missing(q24_bin`i')
}

egen sum_bin = rowtotal(q24_bin1-q24_bin10)

* MAM mean and sd (only when probabilities sum to 100)
gen mean_mam = (14*q24_bin1 +10*q24_bin2 +6*q24_bin3 +3*q24_bin4 +1*q24_bin5 ///
               -1*q24_bin6 -3*q24_bin7 -6*q24_bin8 -10*q24_bin9 -14*q24_bin10)/100 ///
               if sum_bin==100

gen sd_mam = (((mean_mam - 14)^2*q24_bin1 +(mean_mam - 10)^2*q24_bin2 +(mean_mam - 6)^2*q24_bin3 ///
             +(mean_mam - 3)^2*q24_bin4 +(mean_mam - 1)^2*q24_bin5 +(mean_mam + 1)^2*q24_bin6 ///
             +(mean_mam + 3)^2*q24_bin7 +(mean_mam + 6)^2*q24_bin8 +(mean_mam +10)^2*q24_bin9 ///
             +(mean_mam +14)^2*q24_bin10)/100)^0.5 if sum_bin==100

* Median (MAM-style, using cumulative probability >=50)
gen cum = 0
gen median_mam = .
local bins    q24_bin1 q24_bin2 q24_bin3 q24_bin4 q24_bin5 q24_bin6 q24_bin7 q24_bin8 q24_bin9 q24_bin10
local centers 14 10 6 3 1 -1 -3 -6 -10 -14
quietly {
    forvalues i = 1/10 {
        local b : word `i' of `bins'
        local c : word `i' of `centers'
        replace cum = cum + `b' if missing(median_mam)
        replace median_mam = `c' if cum >= 50 & missing(median_mam)
    }
}
drop cum
replace median_mam = . if sum_bin!=100

* Mode (first bin attaining max probability)
gen mode_mam = .
forvalues i = 1/10 {
    local b : word `i' of `bins'
    local c : word `i' of `centers'
    gen flag`i' = (`b' == max(q24_bin1,q24_bin2,q24_bin3,q24_bin4,q24_bin5,q24_bin6,q24_bin7,q24_bin8,q24_bin9,q24_bin10)) ///
                  & !missing(`b')
    replace mode_mam = `c' if flag`i'==1 & missing(mode_mam)
    drop flag`i'
}
replace mode_mam = . if sum_bin!=100

* EPRS-style uncertainty (Krüger & Pavlova style): sum p(1-p)
gen sd_eprs = (q24_bin1*(100-q24_bin1) + q24_bin2*(100-q24_bin2) + q24_bin3*(100-q24_bin3) + ///
               q24_bin4*(100-q24_bin4) + q24_bin5*(100-q24_bin5) + q24_bin6*(100-q24_bin6) + ///
               q24_bin7*(100-q24_bin7) + q24_bin8*(100-q24_bin8) + q24_bin9*(100-q24_bin9) + ///
               q24_bin10*(100-q24_bin10))/100 if sum_bin==100

			   
			  
* Lower / uppder bounds
gen lower_bound = .
gen upper_bound  = .

local bins q24_bin1 q24_bin2 q24_bin3 q24_bin4 q24_bin5 q24_bin6 q24_bin7 q24_bin8 q24_bin9 q24_bin10
local centers 14 10 6 3 1 -1 -3 -6 -10 -14

quietly {
    forval i = 1/10 {
        local j = 11 - `i'   // Loop from 10 to 1
        local b : word `j' of `bins'
        local c : word `j' of `centers'

        replace lower_bound = `c' if missing(lower_bound) & `b' > 0 & !missing(`b')
    }
}

quietly {
    forval i = 1/10 {
        local b : word `i' of `bins'
        local c : word `i' of `centers'

        replace upper_bound = `c' if missing(upper_bound) & `b' > 0 & !missing(`b')
    }
}

* Double check Lower/upper bounds
gen high = .
gen low = .

* First and last bins
replace high = 14   if q24_bin1 > 0 & !missing(q24_bin1)
replace low  = -14  if q24_bin10 > 0 & !missing(q24_bin10)

* Intermediate bins for high
forvalues i = 2/9 {
    capture confirm variable q24_bin`i'
    if _rc == 0 {
        local prev = `i' - 1
        if `i' <= 3 {
            replace high = 14 - ((`i' - 1) * 4) if q24_bin`i' > 0 & q24_bin`prev' == 0 & missing(high)
        }
        else if `i' < 8 {
            replace high = 3 - ((`i' - 4) * 2) if q24_bin`i' > 0 & q24_bin`prev' == 0 & missing(high)
        }
        else {
            replace high = -6 - ((`i' - 8) * 4) if q24_bin`i' > 0 & q24_bin`prev' == 0 & missing(high)
        }
    }
}

* Intermediate bins for low
forvalues i = 9(-1)2 {
    local next = `i' + 1
    if `i' >= 8 {
        replace low = -6 - ((`i' - 8) * 4) if q24_bin`i' > 0 & q24_bin`next' == 0 & missing(low)
    }
    else if `i' > 3 {
        replace low = 3 - ((`i' - 4) * 2) if q24_bin`i' > 0 & q24_bin`next' == 0 & missing(low)
    }
    else {
        replace low = 14 - ((`i' - 1) * 4) if q24_bin`i' > 0 & q24_bin`next' == 0 & missing(low)
    }
}

replace lower_bound = low if missing(lower_bound)
replace upper_bound = high if missing(upper_bound)

* Span
gen span = upper_bound - lower_bound
replace span = . if span < 0


* "All bins equal" flag (captures the 10% everywhere pattern)
gen all_equal = 1
foreach b in `bins' {
    quietly replace all_equal = 0 if `b' != q24_bin1
}

* Count number of peaks (your "mode_count==0" screen)
gen mode_count = 0
quietly {
    forvalues i = 1/`=_N' {
        if !missing(q24_bin1[`i']) {
            matrix bins = ( ///
                q24_bin1[`i'], q24_bin2[`i'], q24_bin3[`i'], q24_bin4[`i'], q24_bin5[`i'], ///
                q24_bin6[`i'], q24_bin7[`i'], q24_bin8[`i'], q24_bin9[`i'], q24_bin10[`i'] ///
            )

            local modes = 0

            forvalues j = 1/10 {
                if `j' == 1 {
                    local center = bins[1,`j']
                    local after  = bins[1,`=`j'+1']
                    if (`center' > `after') {
                        local modes = `modes' + 1
                    }
                }
                else if `j' == 10 {
                    local center = bins[1,`j']
                    local before = bins[1,`=`j'-1']
                    if (`center' > `before') {
                        local modes = `modes' + 1
                    }
                }
                else {
                    local before = bins[1,`=`j'-1']
                    local center = bins[1,`j']
                    local after  = bins[1,`=`j'+1']

                    if (`center' > `before') & (`center' > `after') {						
                        local modes = `modes' + 1						
                    }
                }
            }

            replace mode_count = `modes' in `i'
        }
    }
}


quietly {
    forvalues i = 1/`=_N' {
        if !missing(q24_bin1[`i']) & mode_count[`i']==0 {
            matrix bins = ( ///
                q24_bin1[`i'], q24_bin2[`i'], q24_bin3[`i'], q24_bin4[`i'], q24_bin5[`i'], ///
                q24_bin6[`i'], q24_bin7[`i'], q24_bin8[`i'], q24_bin9[`i'], q24_bin10[`i'] ///
            )

            local modes = 0

            forvalues j = 2/9 {

                    local before = bins[1,`=`j'-1']
                    local center = bins[1,`j']
                    local after  = bins[1,`=`j'+1']

                    if (`center' >= `before') & (`center' > `after') {						
                        local modes = `modes' + 1						
                    }
            }

            replace mode_count = `modes' in `i'
        }
    }
}


quietly {
    forvalues i = 1/`=_N' {
        if !missing(q24_bin1[`i']) & mode_count[`i']==0  {
            matrix bins = ( ///
                q24_bin1[`i'], q24_bin2[`i'], q24_bin3[`i'], q24_bin4[`i'], q24_bin5[`i'], ///
                q24_bin6[`i'], q24_bin7[`i'], q24_bin8[`i'], q24_bin9[`i'], q24_bin10[`i'] ///
            )

            local modes = 0

            forvalues j = 2/9 {

                    local before = bins[1,`=`j'-1']
                    local center = bins[1,`j']
                    local after  = bins[1,`=`j'+1']

                    if (`center' > `before') & (`center' >= `after') {						
                        local modes = `modes' + 1						
                    }
            }

            replace mode_count = `modes' in `i'
        }
    }
}



/**********************************************************************
  6) Sample trimming rules used in Appendix A.1 (household cleaning)
  From the manuscript:
    - Drop mean_direct in top/bottom 5th percentile within each year
    - Drop responses that allocate 10% to every bin (all_equal==1)
    - Drop cases with problematic histogram shape (mode_count==0)
    - For subjective uncertainty: drop "constant reported uncertainty" across the series
**********************************************************************/

* Mean expectation outliers by year (5th–95th percentile)
gen mean_direct_outlier =.
forvalue y=2013(1)2025{
centile mean_direct if year==`y', centile(5 95)
replace mean_direct_outlier = 0 if mean_direct<r(c_2)&mean_direct>r(c_1)&!missing(mean_direct)&year==`y'
replace mean_direct_outlier = 1 if missing(mean_direct_outlier)&!missing(mean_direct)&year==`y'
}


foreach v in sd_mam sd_gbd sd_eprs mean_direct mean_mam mean_gbd span {
    bysort userid: egen  `v'_sd = sd(`v') if sum_bin == 100&!missing(`v')
    gen `v'_is_constant = (`v'_sd == 0)
}

foreach v in sd_mam sd_gbd sd_eprs mean_direct mean_mam mode_mam mean_gbd mode_count median_mam {
    replace `v' = . if sum_bin != 100 | mean_direct_outlier == 1 | mode_count==0 | all_equal == 1
}


foreach v in sd_mam sd_gbd sd_eprs {
    replace `v' = . if `v'_is_constant ==1&`v'==0
}

foreach v in span upper_bound lower_bound{
    replace `v' = . if sum_bin != 100 | mean_direct_outlier == 1 | mode_count==0 | all_equal == 1
}



/**********************************************************************
  7) Main-text household tables
**********************************************************************/

*========================
* Table 1 (households) Columns 4-6
*========================
xtset userid date
eststo clear
eststo: reghdfe mean_direct L.mean_direct lnepu 0.employ L.emp1 first_l i.year i.month covid, ///
    vce(cluster userid date) absorb(userid)
eststo: reghdfe mean_direct L.mean_direct lnju  0.employ L.emp1 first_l i.year i.month covid, ///
    vce(cluster userid date) absorb(userid)
eststo: reghdfe mean_direct L.mean_direct lndis 0.employ L.emp1 first_l i.year i.month covid, ///
    vce(cluster userid date) absorb(userid)

esttab using "${OUT}\hh_table1.csv", replace ///
    star(* 0.10 ** 0.05 *** 0.01) se ///
    drop(*.year *.month covid) nogap ///
    order(lnepu lnju lndis first_l L.emp1 0.employ L.mean_direct _cons) ///
    varlabels(lnepu "Log Economic Policy Uncertainty index" ///
              lnju  "Log Jurado et al. index" ///
              lndis "Log Forecasters disagreement" ///
              first_l "Lagged real-time GDP growth" ///
              L.emp1   "Lagged real-time employment rate" ///
              0.employ "Being unemployed" ///
              L.mean_direct "Lagged dependent variable" ///
              _cons "Constant") ///
    stats(N N_clust1 r2_a, fmt(0 0 2) labels("Number of observations" "Number of individuals" "Adjusted R-squared"))

*========================
* Table 2 (households) Columns 4-6
*========================
xtset userid date
eststo clear
eststo: reghdfe sd_mam L.sd_mam lnepu 0.employ L.emp1 first_l i.year i.month covid, ///
    vce(cluster userid date) absorb(userid)
eststo: reghdfe sd_mam L.sd_mam lnju  0.employ L.emp1 first_l i.year i.month covid, ///
    vce(cluster userid date) absorb(userid)
eststo: reghdfe sd_mam L.sd_mam lndis 0.employ L.emp1 first_l i.year i.month covid, ///
    vce(cluster userid date) absorb(userid)

esttab using "${OUT}\hh_table2.csv", replace ///
    star(* 0.10 ** 0.05 *** 0.01) se ///
    drop(*.year *.month covid) nogap ///
    order(lnepu lnju lndis first_l L.emp1 0.employ L.sd_mam _cons) ///
    varlabels(lnepu "Log Economic Policy Uncertainty index" ///
              lnju  "Log Jurado et al. index" ///
              lndis "Log Forecasters disagreement" ///
              first_l "Lagged real-time GDP growth" ///
              L.emp1   "Lagged real-time employment rate" ///
              0.employ "Being unemployed" ///
              L.sd_mam "Lagged dependent variable" ///
              _cons "Constant") ///
    stats(N N_clust1 r2_a, fmt(0 0 2) labels("Number of observations" "Number of individuals" "Adjusted R-squared"))

*========================
* Table 3: summary stats of subjective uncertainty (MAM) by tenure and education
*========================
sum sd_mam if job_length<5
sum sd_mam if job_length==5
sum sd_mam if _EDU_CAT!="College"
sum sd_mam if _EDU_CAT=="College"

*========================
* Table 4: sd_mam regressions split by tenure and education
*========================
xtset userid date
eststo clear
* Panel A: tenure
eststo: reghdfe sd_mam L.sd_mam lnepu 0.employ L.emp1 first_l i.year i.month covid if job_length<5, ///
    vce(cluster userid date) absorb(userid)
eststo: reghdfe sd_mam L.sd_mam lnju  0.employ L.emp1 first_l i.year i.month covid if job_length<5, ///
    vce(cluster userid date) absorb(userid)
eststo: reghdfe sd_mam L.sd_mam lndis 0.employ L.emp1 first_l i.year i.month covid if job_length<5, ///
    vce(cluster userid date) absorb(userid)

eststo: reghdfe sd_mam L.sd_mam lnepu 0.employ L.emp1 first_l i.year i.month covid if job_length==5, ///
    vce(cluster userid date) absorb(userid)
eststo: reghdfe sd_mam L.sd_mam lnju  0.employ L.emp1 first_l i.year i.month covid if job_length==5, ///
    vce(cluster userid date) absorb(userid)
eststo: reghdfe sd_mam L.sd_mam lndis 0.employ L.emp1 first_l i.year i.month covid if job_length==5, ///
    vce(cluster userid date) absorb(userid)

* Panel B: education
eststo: reghdfe sd_mam L.sd_mam lnepu 0.employ L.emp1 first_l i.year i.month covid if _EDU_CAT!="College", ///
    vce(cluster userid date) absorb(userid)
eststo: reghdfe sd_mam L.sd_mam lnju  0.employ L.emp1 first_l i.year i.month covid if _EDU_CAT!="College", ///
    vce(cluster userid date) absorb(userid)
eststo: reghdfe sd_mam L.sd_mam lndis 0.employ L.emp1 first_l i.year i.month covid if _EDU_CAT!="College", ///
    vce(cluster userid date) absorb(userid)

eststo: reghdfe sd_mam L.sd_mam lnepu 0.employ L.emp1 first_l i.year i.month covid if _EDU_CAT=="College", ///
    vce(cluster userid date) absorb(userid)
eststo: reghdfe sd_mam L.sd_mam lnju  0.employ L.emp1 first_l i.year i.month covid if _EDU_CAT=="College", ///
    vce(cluster userid date) absorb(userid)
eststo: reghdfe sd_mam L.sd_mam lndis 0.employ L.emp1 first_l i.year i.month covid if _EDU_CAT=="College", ///
    vce(cluster userid date) absorb(userid)

esttab using "${OUT}\hh_table4.csv", replace ///
    star(* 0.10 ** 0.05 *** 0.01) se ///
    drop(*.year *.month covid) nogap ///
    order(lnepu lnju lndis first_l L.emp1 0.employ L.sd_mam _cons) ///
    varlabels(lnepu "Log Economic Policy Uncertainty index" ///
              lnju  "Log Jurado et al. index" ///
              lndis "Log Forecasters disagreement" ///
              first_l "Lagged real-time GDP growth" ///
              L.emp1   "Lagged real-time employment rate" ///
              0.employ "Being unemployed" ///
              L.sd_mam "Lagged dependent variable" ///
              _cons "Constant") ///
    stats(N N_clust1 r2_a, fmt(0 0 2) labels("Number of observations" "Number of individuals" "Adjusted R-squared"))

*========================
* Table 5: daily EPU regressions
*========================
xtset userid date
eststo clear
eststo: reghdfe mean_direct ln_daily_epu 0.employ L.emp1 first_l L.mean_direct i.year i.month covid, ///
    vce(cluster userid date) 
eststo: reghdfe mean_direct L.mean_direct ln_daily_epu 0.employ L.emp1 first_l i.year i.month covid, ///
    vce(cluster userid date) absorb(userid)
eststo: reghdfe mean_direct L.mean_direct ln_daily_epu ln_daily_epu_ma30 0.employ L.emp1 first_l i.year i.month covid, ///
    vce(cluster userid date) absorb(userid)

eststo: reghdfe sd_mam ln_daily_epu 0.employ L.emp1 first_l L.sd_mam i.year i.month covid, ///
    vce(cluster userid date) 
eststo: reghdfe sd_mam L.sd_mam ln_daily_epu 0.employ L.emp1 first_l i.year i.month covid, ///
    vce(cluster userid date) absorb(userid)
eststo: reghdfe sd_mam L.sd_mam ln_daily_epu ln_daily_epu_ma30 0.employ L.emp1 first_l i.year i.month covid, ///
    vce(cluster userid date) absorb(userid)

esttab using "${OUT}\hh_table5.csv", replace ///
    star(* 0.10 ** 0.05 *** 0.01) se ///
    drop(*.year *.month covid) nogap ///
    order(ln_daily_epu ln_daily_epu_ma30 first_l L.emp1 0.employ L.mean_direct L.sd_mam _cons) ///
    varlabels(ln_daily_epu "Log Daily Economic Policy Uncertainty" ///
              ln_daily_epu_ma30 "Average daily EPU (past 30 days)" ///
              first_l "Lagged real-time GDP growth" ///
              L.emp1   "Lagged real-time employment rate" ///
              0.employ "Being unemployed" ///
              L.mean_direct "Lagged dependent variable" ///
              L.sd_mam "Lagged dependent variable" ///
              _cons "Constant") ///
    stats(N N_clust1 r2_a, fmt(0 0 2) labels("Number of observations" "Number of individuals" "Adjusted R-squared"))

*========================
* Table 6 (households): Lower bound/Upper bound/span regressions
*========================
xtset userid date
eststo clear
* Lower bound
eststo: reghdfe lower_bound L.lower_bound lnepu 0.employ L.emp1 first_l i.year i.month covid, vce(cluster userid date) absorb(userid)
eststo: reghdfe lower_bound L.lower_bound lnju  0.employ L.emp1 first_l i.year i.month covid, vce(cluster userid date) absorb(userid)
eststo: reghdfe lower_bound L.lower_bound lndis 0.employ L.emp1 first_l i.year i.month covid, vce(cluster userid date) absorb(userid)
* Upper bound
eststo: reghdfe upper_bound  L.upper_bound  lnepu 0.employ L.emp1 first_l i.year i.month covid, vce(cluster userid date) absorb(userid)
eststo: reghdfe upper_bound  L.upper_bound  lnju  0.employ L.emp1 first_l i.year i.month covid, vce(cluster userid date) absorb(userid)
eststo: reghdfe upper_bound  L.upper_bound  lndis 0.employ L.emp1 first_l i.year i.month covid, vce(cluster userid date) absorb(userid)
* span
eststo: reghdfe span       L.span       lnepu 0.employ L.emp1 first_l i.year i.month covid, vce(cluster userid date) absorb(userid)
eststo: reghdfe span       L.span       lnju  0.employ L.emp1 first_l i.year i.month covid, vce(cluster userid date) absorb(userid)
eststo: reghdfe span       L.span       lndis 0.employ L.emp1 first_l i.year i.month covid, vce(cluster userid date) absorb(userid)

esttab using "${OUT}\hh_table6.csv", replace ///
    star(* 0.10 ** 0.05 *** 0.01) se ///
    drop(*.year *.month covid) nogap ///
    order(lnepu lnju lndis first_l L.emp1 0.employ l.lower_bound l.upper_bound l.span _cons) ///
	    varlabels( ///
        lnepu     "Log Economic Policy Uncertainty index" ///
        lnju      "Log Jurado et al. index" ///
        lndis     "Log Forecasters disagreement" ///
        first_l   "Lagged real-time GDP growth" ///
        L.emp1    "Lagged real-time employment rate" ///
        0.employ  "Being unemployed" ///
        L.worst_case "Lagged dependent variable" ///
		_cons "Constant") ///
    stats(N N_clust1 r2_a, fmt(0 0 2) labels("Number of observations" "Number of individuals" "Adjusted R-squared"))

	
	 

/**********************************************************************
 Appendix A
**********************************************************************/
 
*========================
* Table 7
*========================
* Panel A
xtsum mean_direct mean_mam mean_gbd sd_mam sd_gbd sd_eprs lower_bound upper_bound span

* Panel B Gender: Female = 1,  Unemployed: employ = 0
tab gender if !missing(mean_direct)
tab employ if !missing(mean_direct)
sum age1 if !missing(mean_direct)&age1>16&age1<100


*========================
* Figure 8 (b) change data structure
*========================
collapse (mean) mean_direct sd_mam, by(date)
twoway ///
    (line mean_direct date, yaxis(1) lcolor(navy) lwidth(medthick)) ///
    (line sd_mam  date, yaxis(2) lcolor(forest_green) lwidth(medthick) lpattern(shortdash)) ///
    , ///
    ylabel(, angle(horizontal) grid) ///
    ylabel(, axis(2) angle(horizontal)) ///
    ytitle("Mean expectations (%)") ///
    ytitle("Subjective uncertainty (%)", axis(2)) ///
    legend(order(1 "Mean expectations provided respondents" 2 "Subjective uncertainty (MAM)") ///
           pos(6) ring(0) col(1) region(lstyle(none))) ///
	plotregion(margin(zero) lstyle(none) color(white)) ///
    graphregion(color(white) lstyle(none)) ///
    scheme(s2color)

	
/**********************************************************************
 Appendix B.1
**********************************************************************/
*========================
* Table 10
*========================
xtset userid date
eststo clear

* Panel A Columns 1-9
eststo: reghdfe mean_direct lnepu  l.mean_direct i.year i.month, vce(cluster userid date)
eststo: reghdfe mean_direct lnepu first_l   l.emp1  0.employ  l.mean_direct i.year i.month covid , vce(cluster userid date)
eststo: reghdfe mean_direct l.mean_direct  lnepu 0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)
eststo: reghdfe mean_direct lnju  l.mean_direct i.year i.month, vce(cluster userid date)
eststo: reghdfe mean_direct lnju   0.employ l.emp1 first_l  l.mean_direct i.year i.month covid , vce(cluster userid date)
eststo: reghdfe mean_direct l.mean_direct lnju  0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)
eststo: reghdfe mean_direct lndis l.mean_direct i.year i.month, vce(cluster userid date)
eststo: reghdfe mean_direct lndis   0.employ l.emp1 first_l  l.mean_direct i.year i.month covid , vce(cluster userid date)
eststo: reghdfe mean_direct l.mean_direct lndis  0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)

* Panel A Columns 10-18
eststo: reghdfe mean_mam l.mean_mam lnepu i.year i.month, vce(cluster userid date)
eststo: reghdfe mean_mam l.mean_mam lnepu   0.employ l.emp1 first_l i.year i.month covid , vce(cluster userid date)
eststo: reghdfe mean_mam l.mean_mam lnepu  0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)
eststo: reghdfe mean_mam l.mean_mam lnju i.year i.month, vce(cluster userid date)
eststo: reghdfe mean_mam l.mean_mam lnju   0.employ l.emp1 first_l i.year i.month covid , vce(cluster userid date)
eststo: reghdfe mean_mam l.mean_mam lnju  0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)
eststo: reghdfe mean_mam l.mean_mam lndis i.year i.month, vce(cluster userid date)
eststo: reghdfe mean_mam l.mean_mam lndis   0.employ l.emp1 first_l i.year i.month covid , vce(cluster userid date)
eststo: reghdfe mean_mam l.mean_mam lndis  0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)

* Panel B Columns 1-9
eststo: reghdfe mean_gbd l.mean_gbd lnepu i.year i.month, vce(cluster userid date)
eststo: reghdfe mean_gbd l.mean_gbd lnepu   0.employ l.emp1 first_l i.year i.month covid , vce(cluster userid date)
eststo: reghdfe mean_gbd l.mean_gbd lnepu  0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)
eststo: reghdfe mean_gbd l.mean_gbd lnju  i.year i.month, vce(cluster userid date)
eststo: reghdfe mean_gbd l.mean_gbd lnju   0.employ l.emp1 first_l i.year i.month covid , vce(cluster userid date)
eststo: reghdfe mean_gbd l.mean_gbd lnju  0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)
eststo: reghdfe mean_gbd l.mean_gbd lndis i.year i.month, vce(cluster userid date)
eststo: reghdfe mean_gbd l.mean_gbd lndis   0.employ l.emp1 first_l i.year i.month covid , vce(cluster userid date)
eststo: reghdfe mean_gbd l.mean_gbd lndis  0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)

esttab using "${OUT}\hh_table10.csv", replace ///
    star(* 0.10 ** 0.05 *** 0.01) ///
   se ///
    drop(*.year *.month covid) nogap ///
    order(lnepu lnju lndis first_l L.emp1 0.employ ///
          L.mean_direct L.mean_gbd L.mean_mam _cons) ///
	    varlabels( ///
        lnepu     "Log EPU" ///
        lnju      "Log JU" ///
        lndis     "Log Disagreement" ///
        first_l   "Lagged real-time GDP growth" ///
        L.emp1    "Lagged real-time employment rate" ///
        0.employ  "Being unemployed" ///
        L.mean_direct "Lagged dependent variable" ///
		_cons "Constant") ///
    stats(N N_clust1 r2_a, fmt(0 0 2) labels("Number of observations" "Number of individuals" "Adjusted R-squared"))


/**********************************************************************
 Appendix B.2
**********************************************************************/
*========================
* Table 12
*========================
xtset userid date
eststo clear
* Panel A Columns 1-9
xtset userid date
eststo clear
eststo: reghdfe sd_mam lnepu i.year i.month l.sd_mam, vce(cluster userid date)
eststo: reghdfe sd_mam lnepu   0.employ l.emp1 first_l  l.sd_mam i.year i.month covid , vce(cluster userid date)
eststo: reghdfe sd_mam l.sd_mam lnepu  0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)
eststo: reghdfe sd_mam lnju i.year i.month l.sd_mam, vce(cluster userid date)
eststo: reghdfe sd_mam lnju   0.employ l.emp1 first_l  l.sd_mam i.year i.month covid , vce(cluster userid date)
eststo: reghdfe sd_mam l.sd_mam lnju  0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)
eststo: reghdfe sd_mam lndis  i.year i.month l.sd_mam, vce(cluster userid date)
eststo: reghdfe sd_mam lndis   0.employ l.emp1 first_l  l.sd_mam i.year i.month covid , vce(cluster userid date)
eststo: reghdfe sd_mam l.sd_mam lndis 0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)

* Panel A Columns 10-18
eststo: reghdfe sd_gbd l.sd_gbd lnepu i.year i.month, vce(cluster userid date)
eststo: reghdfe sd_gbd l.sd_gbd lnepu   0.employ l.emp1 first_l i.year i.month covid , vce(cluster userid date)
eststo: reghdfe sd_gbd l.sd_gbd lnepu  0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)
eststo: reghdfe sd_gbd l.sd_gbd lnju i.year i.month, vce(cluster userid date)
eststo: reghdfe sd_gbd l.sd_gbd lnju   0.employ l.emp1 first_l i.year i.month covid , vce(cluster userid date)
eststo: reghdfe sd_gbd l.sd_gbd lnju  0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)
eststo: reghdfe sd_gbd l.sd_gbd lndis i.year i.month, vce(cluster userid date)
eststo: reghdfe sd_gbd l.sd_gbd lndis   0.employ l.emp1 first_l i.year i.month covid , vce(cluster userid date)
eststo: reghdfe sd_gbd l.sd_gbd lndis  0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)

* Panel B Columns 1-9
eststo: reghdfe sd_eprs l.sd_eprs lnepu i.year i.month, vce(cluster userid date)
eststo: reghdfe sd_eprs l.sd_eprs lnepu   0.employ l.emp1 first_l i.year i.month covid , vce(cluster userid date)
eststo: reghdfe sd_eprs l.sd_eprs lnepu  0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)
eststo: reghdfe sd_eprs l.sd_eprs lnju i.year i.month, vce(cluster userid date)
eststo: reghdfe sd_eprs l.sd_eprs lnju   0.employ l.emp1 first_l i.year i.month covid , vce(cluster userid date)
eststo: reghdfe sd_eprs l.sd_eprs lnju  0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)
eststo: reghdfe sd_eprs l.sd_eprs lndis i.year i.month, vce(cluster userid date)
eststo: reghdfe sd_eprs l.sd_eprs lndis   0.employ l.emp1 first_l i.year i.month covid , vce(cluster userid date)
eststo: reghdfe sd_eprs l.sd_eprs lndis  0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)
esttab using "${OUT}\hh_table12.csv", replace ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    se ///
    drop(*.year *.month covid) nogap ///
    order(lnepu lnju lndis first_l L.emp1 0.employ ///
          L.sd_mam L.sd_gbd) ///
	    varlabels( ///
        lnepu     "Log EPU" ///
        lnju      "Log JU" ///
        lndis     "Log Disagreement" ///
        first_l   "Lagged real-time GDP growth" ///
        L.emp1    "Lagged real-time employment rate" ///
        0.employ  "Being unemployed" ///
        L.sd_mam "Lagged dependent variable" ///
		_cons "Constant") ///
    stats(N N_clust1 r2_a, fmt(0 0 2) labels("Number of observations" "Number of individuals" "Adjusted R-squared"))
	

*========================
* Table 14
*========================
xtset userid date
eststo clear

* Panel A Columns 1-9
eststo: reghdfe sd_mam lnepu i.year i.month covid  l.sd_mam if _NUM_CAT == "High", vce(cluster userid date)
eststo: reghdfe sd_mam lnepu  0.employ l.emp1 first_l  l.sd_mam i.year i.month covid if _NUM_CAT == "High", vce(cluster userid date)
eststo: reghdfe sd_mam l.sd_mam lnepu 0.employ l.emp1 first_l  i.year i.month covid if _NUM_CAT == "High", vce(cluster userid date) abs(userid)
eststo: reghdfe sd_mam lnju i.year i.month covid  l.sd_mam if _NUM_CAT == "High", vce(cluster userid date)
eststo: reghdfe sd_mam lnju  0.employ l.emp1 first_l  l.sd_mam i.year i.month covid if _NUM_CAT == "High", vce(cluster userid date)
eststo: reghdfe sd_mam l.sd_mam lnju 0.employ l.emp1 first_l  i.year i.month covid if _NUM_CAT == "High", vce(cluster userid date) abs(userid)
eststo: reghdfe sd_mam lndis i.year i.month covid  l.sd_mam if _NUM_CAT == "High", vce(cluster userid date)
eststo: reghdfe sd_mam lndis  0.employ l.emp1 first_l  l.sd_mam i.year i.month covid if _NUM_CAT == "High", vce(cluster userid date)
eststo: reghdfe sd_mam l.sd_mam lndis 0.employ l.emp1 first_l  i.year i.month covid if _NUM_CAT == "High", vce(cluster userid date) abs(userid)

* Panel A Columns 10-18
eststo: reghdfe sd_mam lnepu i.year i.month covid  l.sd_mam if _NUM_CAT == "Low", vce(cluster userid date)
eststo: reghdfe sd_mam lnepu  0.employ l.emp1 first_l  l.sd_mam i.year i.month covid if _NUM_CAT == "Low", vce(cluster userid date)
eststo: reghdfe sd_mam l.sd_mam lnepu 0.employ l.emp1 first_l  i.year i.month covid if _NUM_CAT == "Low", vce(cluster userid date) abs(userid)
eststo: reghdfe sd_mam lnju i.year i.month covid  l.sd_mam if _NUM_CAT == "Low", vce(cluster userid date)
eststo: reghdfe sd_mam lnju  0.employ l.emp1 first_l  l.sd_mam i.year i.month covid if _NUM_CAT == "Low", vce(cluster userid date)
eststo: reghdfe sd_mam l.sd_mam lnju 0.employ l.emp1 first_l  i.year i.month covid if _NUM_CAT == "Low", vce(cluster userid date) abs(userid)
eststo: reghdfe sd_mam lndis i.year i.month covid  l.sd_mam if _NUM_CAT == "Low", vce(cluster userid date)
eststo: reghdfe sd_mam lndis  0.employ l.emp1 first_l  l.sd_mam i.year i.month covid if _NUM_CAT == "Low", vce(cluster userid date)
eststo: reghdfe sd_mam l.sd_mam lndis 0.employ l.emp1 first_l  i.year i.month covid if _NUM_CAT == "Low", vce(cluster userid date) abs(userid)

* Panel B Columns 1-9
eststo: reghdfe sd_gbd lnepu i.year i.month covid  l.sd_gbd if _NUM_CAT == "High", vce(cluster userid date)
eststo: reghdfe sd_gbd lnepu  0.employ l.emp1 first_l  l.sd_gbd i.year i.month covid if _NUM_CAT == "High", vce(cluster userid date)
eststo: reghdfe sd_gbd l.sd_gbd lnepu 0.employ l.emp1 first_l  i.year i.month covid if _NUM_CAT == "High", vce(cluster userid date) abs(userid)
eststo: reghdfe sd_gbd lnju i.year i.month covid  l.sd_gbd if _NUM_CAT == "High", vce(cluster userid date)
eststo: reghdfe sd_gbd lnju  0.employ l.emp1 first_l  l.sd_gbd i.year i.month covid if _NUM_CAT == "High", vce(cluster userid date)
eststo: reghdfe sd_gbd l.sd_gbd lnju 0.employ l.emp1 first_l  i.year i.month covid if _NUM_CAT == "High", vce(cluster userid date) abs(userid)
eststo: reghdfe sd_gbd lndis i.year i.month covid  l.sd_gbd if _NUM_CAT == "High", vce(cluster userid date)
eststo: reghdfe sd_gbd lndis  0.employ l.emp1 first_l  l.sd_gbd i.year i.month covid if _NUM_CAT == "High", vce(cluster userid date)
eststo: reghdfe sd_gbd l.sd_gbd lndis 0.employ l.emp1 first_l  i.year i.month covid if _NUM_CAT == "High", vce(cluster userid date) abs(userid)

* Panel B Columns 10-18
eststo: reghdfe sd_gbd lnepu i.year i.month covid  l.sd_gbd if _NUM_CAT == "Low", vce(cluster userid date)
eststo: reghdfe sd_gbd lnepu  0.employ l.emp1 first_l  l.sd_gbd i.year i.month covid if _NUM_CAT == "Low", vce(cluster userid date)
eststo: reghdfe sd_gbd l.sd_gbd lnepu 0.employ l.emp1 first_l  i.year i.month covid if _NUM_CAT == "Low", vce(cluster userid date) abs(userid)
eststo: reghdfe sd_gbd lnju i.year i.month covid  l.sd_gbd if _NUM_CAT == "Low", vce(cluster userid date)
eststo: reghdfe sd_gbd lnju  0.employ l.emp1 first_l  l.sd_gbd i.year i.month covid if _NUM_CAT == "Low", vce(cluster userid date)
eststo: reghdfe sd_gbd l.sd_gbd lnju 0.employ l.emp1 first_l  i.year i.month covid if _NUM_CAT == "Low", vce(cluster userid date) abs(userid)
eststo: reghdfe sd_gbd lndis i.year i.month covid  l.sd_gbd if _NUM_CAT == "Low", vce(cluster userid date)
eststo: reghdfe sd_gbd lndis  0.employ l.emp1 first_l  l.sd_gbd i.year i.month covid if _NUM_CAT == "Low", vce(cluster userid date)
eststo: reghdfe sd_gbd l.sd_gbd lndis 0.employ l.emp1 first_l  i.year i.month covid if _NUM_CAT == "Low", vce(cluster userid date) abs(userid)

esttab using "${OUT}\hh_table14.csv", replace ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    se ///
    drop(*.year *.month covid) nogap ///
    order(lnepu lnju lndis first_l L.emp1 0.employ ///
          L.sd_mam L.sd_gbd) ///
	    varlabels( ///
        lnepu     "Log EPU" ///
        lnju      "Log JU" ///
        lndis     "Log Disagreement" ///
        first_l   "Lagged real-time GDP growth" ///
        L.emp1    "Lagged real-time employment rate" ///
        0.employ  "Being unemployed" ///
        L.sd_mam "Lagged dependent variable" ///
		_cons "Constant") ///
    stats(N N_clust1 r2_a, fmt(0 0 2) labels("Number of observations" "Number of individuals" "Adjusted R-squared"))


*========================
* Table 15
*========================
* Job tenure
sum sd_mam sd_gbd if job_length<5 //work in main job < 5 years
sum sd_mam sd_gbd if job_length==5 //work in main job >= 5 years

* Education level
sum sd_mam sd_gbd if _EDU_CAT !="College" //no college degree
sum sd_mam sd_gbd if _EDU_CAT =="College" //have a college degree
	

*========================
* Table 16 Household subjective uncertainty (MAM) by personal instability
*========================	
xtset userid date
eststo clear
* Panel A Columns 1-9
eststo: reghdfe sd_mam lnepu i.year i.month covid  l.sd_mam if job_length<5, vce(cluster userid date)
eststo: reghdfe sd_mam lnepu   0.employ l.emp1 first_l  l.sd_mam i.year i.month covid if job_length<5, vce(cluster userid date)
eststo: reghdfe sd_mam l.sd_mam lnepu  0.employ l.emp1 first_l  i.year i.month covid if job_length<5, vce(cluster userid date) abs(userid)
eststo: reghdfe sd_mam lnju   i.year i.month covid  l.sd_mam if job_length<5, vce(cluster userid date)
eststo: reghdfe sd_mam lnju   0.employ l.emp1 first_l  l.sd_mam i.year i.month covid if job_length<5, vce(cluster userid date)
eststo: reghdfe sd_mam l.sd_mam lnju  0.employ l.emp1 first_l  i.year i.month covid if job_length<5, vce(cluster userid date) abs(userid)
eststo: reghdfe sd_mam lndis  i.year i.month covid  l.sd_mam if job_length<5, vce(cluster userid date)
eststo: reghdfe sd_mam lndis   0.employ l.emp1 first_l  l.sd_mam i.year i.month covid if job_length<5, vce(cluster userid date)
eststo: reghdfe sd_mam l.sd_mam lndis  0.employ l.emp1 first_l  i.year i.month covid if job_length<5, vce(cluster userid date) abs(userid)

* Panel A Columns 10-18
eststo: reghdfe sd_mam lnepu  i.year i.month covid  l.sd_mam if job_length==5, vce(cluster userid date)
eststo: reghdfe sd_mam lnepu   0.employ l.emp1 first_l  l.sd_mam i.year i.month covid if job_length==5, vce(cluster userid date)
eststo: reghdfe sd_mam l.sd_mam lnepu  0.employ l.emp1 first_l  i.year i.month covid if job_length==5, vce(cluster userid date) abs(userid)
eststo: reghdfe sd_mam lnju  i.year i.month covid l.sd_mam if job_length==5, vce(cluster userid date)
eststo: reghdfe sd_mam lnju   0.employ l.emp1 first_l  l.sd_mam i.year i.month covid if job_length==5, vce(cluster userid date)
eststo: reghdfe sd_mam l.sd_mam lnju  0.employ l.emp1 first_l  i.year i.month covid if job_length==5, vce(cluster userid date) abs(userid)
eststo: reghdfe sd_mam lndis  i.year i.month covid  l.sd_mam if job_length==5, vce(cluster userid date)
eststo: reghdfe sd_mam lndis   0.employ l.emp1 first_l  l.sd_mam i.year i.month covid if job_length==5, vce(cluster userid date)
eststo: reghdfe sd_mam l.sd_mam lndis  0.employ l.emp1 first_l  i.year i.month covid if job_length==5, vce(cluster userid date) abs(userid)

* Panel B Columns 1-9
eststo: reghdfe sd_mam lnepu  i.year i.month covid  l.sd_mam if _EDU_CAT !="College", vce(cluster userid date)
eststo: reghdfe sd_mam lnepu   0.employ l.emp1 first_l  l.sd_mam i.year i.month covid if _EDU_CAT !="College", vce(cluster userid date)
eststo: reghdfe sd_mam l.sd_mam lnepu  0.employ l.emp1 first_l  i.year i.month covid if _EDU_CAT !="College", vce(cluster userid date) abs(userid)
eststo: reghdfe sd_mam lnju  i.year i.month covid l.sd_mam if _EDU_CAT !="College", vce(cluster userid date)
eststo: reghdfe sd_mam lnju   0.employ l.emp1 first_l  l.sd_mam i.year i.month covid if _EDU_CAT !="College", vce(cluster userid date)
eststo: reghdfe sd_mam l.sd_mam lnju  0.employ l.emp1 first_l  i.year i.month covid if _EDU_CAT !="College", vce(cluster userid date) abs(userid)
eststo: reghdfe sd_mam lndis  i.year i.month covid l.sd_mam if _EDU_CAT !="College", vce(cluster userid date)
eststo: reghdfe sd_mam lndis   0.employ l.emp1 first_l  l.sd_mam i.year i.month covid if _EDU_CAT !="College", vce(cluster userid date)
eststo: reghdfe sd_mam l.sd_mam lndis  0.employ l.emp1 first_l  i.year i.month covid if _EDU_CAT !="College", vce(cluster userid date) abs(userid)

* Panel B Columns 10-18
eststo: reghdfe sd_mam lnepu  i.year i.month covid l.sd_mam if _EDU_CAT =="College", vce(cluster userid date)
eststo: reghdfe sd_mam lnepu   0.employ l.emp1 first_l  l.sd_mam i.year i.month covid if _EDU_CAT =="College", vce(cluster userid date)
eststo: reghdfe sd_mam l.sd_mam lnepu  0.employ l.emp1 first_l  i.year i.month covid if _EDU_CAT =="College", vce(cluster userid date) abs(userid)
eststo: reghdfe sd_mam lnju  i.year i.month covid l.sd_mam if _EDU_CAT =="College", vce(cluster userid date)
eststo: reghdfe sd_mam lnju   0.employ l.emp1 first_l  l.sd_mam i.year i.month covid if _EDU_CAT =="College", vce(cluster userid date)
eststo: reghdfe sd_mam l.sd_mam lnju  0.employ l.emp1 first_l  i.year i.month covid if _EDU_CAT =="College", vce(cluster userid date) abs(userid)
eststo: reghdfe sd_mam lndis i.year i.month covid l.sd_mam if _EDU_CAT =="College", vce(cluster userid date)
eststo: reghdfe sd_mam lndis   0.employ l.emp1 first_l  l.sd_mam i.year i.month covid if _EDU_CAT =="College", vce(cluster userid date)
eststo: reghdfe sd_mam l.sd_mam lndis  0.employ l.emp1 first_l  i.year i.month covid if _EDU_CAT =="College", vce(cluster userid date) abs(userid)

esttab using "${OUT}\hh_table16.csv", replace ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    se ///
    drop(*.year *.month covid) nogap ///
    order(lnepu lnju lndis first_l L.emp1 0.employ ///
          L.sd_mam L.sd_gbd) ///
	    varlabels( ///
        lnepu     "Log EPU" ///
        lnju      "Log JU" ///
        lndis     "Log Disagreement" ///
        first_l   "Lagged real-time GDP growth" ///
        L.emp1    "Lagged real-time employment rate" ///
        0.employ  "Being unemployed" ///
        L.sd_mam "Lagged dependent variable" ///
		_cons "Constant") ///
    stats(N N_clust1 r2_a, fmt(0 0 2) labels("Number of observations" "Number of individuals" "Adjusted R-squared"))

*========================
* Table 17 Household subjective uncertainty (GBD) by personal instability
*========================	
xtset userid date
eststo clear

* Panel A Columns 1-9	
eststo: reghdfe sd_gbd lnepu  i.year i.month covid  l.sd_gbd if job_length<5, vce(cluster userid date)
eststo: reghdfe sd_gbd lnepu   0.employ l.emp1 first_l  l.sd_gbd i.year i.month covid if job_length<5, vce(cluster userid date)
eststo: reghdfe sd_gbd l.sd_gbd lnepu  0.employ l.emp1 first_l  i.year i.month covid if job_length<5, vce(cluster userid date) abs(userid)
eststo: reghdfe sd_gbd lnju  i.year i.month covid  l.sd_gbd if job_length<5, vce(cluster userid date)
eststo: reghdfe sd_gbd lnju    0.employ l.emp1 first_l  l.sd_gbd i.year i.month covid if job_length<5, vce(cluster userid date)
eststo: reghdfe sd_gbd l.sd_gbd lnju  0.employ l.emp1 first_l  i.year i.month covid if job_length<5, vce(cluster userid date) abs(userid)
eststo: reghdfe sd_gbd lndis  i.year i.month covid  l.sd_gbd if job_length<5, vce(cluster userid date)
eststo: reghdfe sd_gbd lndis   0.employ l.emp1 first_l  l.sd_gbd i.year i.month covid if job_length<5, vce(cluster userid date)
eststo: reghdfe sd_gbd l.sd_gbd lndis  0.employ l.emp1 first_l  i.year i.month covid if job_length<5, vce(cluster userid date) abs(userid)

* Panel A Columns 10-18
eststo: reghdfe sd_gbd lnepu  i.year i.month covid  l.sd_gbd if job_length==5, vce(cluster userid date)
eststo: reghdfe sd_gbd lnepu   0.employ l.emp1 first_l  l.sd_gbd i.year i.month covid if job_length==5, vce(cluster userid date)
eststo: reghdfe sd_gbd l.sd_gbd lnepu  0.employ l.emp1 first_l  i.year i.month covid if job_length==5, vce(cluster userid date) abs(userid)
eststo: reghdfe sd_gbd lnju  i.year i.month covid  l.sd_gbd if job_length==5, vce(cluster userid date)
eststo: reghdfe sd_gbd lnju   0.employ l.emp1 first_l  l.sd_gbd i.year i.month covid if job_length==5, vce(cluster userid date)
eststo: reghdfe sd_gbd l.sd_gbd lnju  0.employ l.emp1 first_l  i.year i.month covid if job_length==5, vce(cluster userid date) abs(userid)
eststo: reghdfe sd_gbd lndis  i.year i.month covid  l.sd_gbd if job_length==5, vce(cluster userid date)
eststo: reghdfe sd_gbd lndis   0.employ l.emp1 first_l  l.sd_gbd i.year i.month covid if job_length==5, vce(cluster userid date)
eststo: reghdfe sd_gbd l.sd_gbd lndis  0.employ l.emp1 first_l  i.year i.month covid if job_length==5, vce(cluster userid date) abs(userid)

* Panel B Columns 1-9
eststo: reghdfe sd_gbd lnepu  i.year i.month covid  l.sd_gbd if _EDU_CAT !="College", vce(cluster userid date)
eststo: reghdfe sd_gbd lnepu   0.employ l.emp1 first_l  l.sd_gbd i.year i.month covid if _EDU_CAT !="College", vce(cluster userid date)
eststo: reghdfe sd_gbd l.sd_gbd lnepu  0.employ l.emp1 first_l  i.year i.month covid if _EDU_CAT !="College", vce(cluster userid date) abs(userid)
eststo: reghdfe sd_gbd lnju  i.year i.month covid  l.sd_gbd if _EDU_CAT !="College", vce(cluster userid date)
eststo: reghdfe sd_gbd lnju   0.employ l.emp1 first_l  l.sd_gbd i.year i.month covid if _EDU_CAT !="College", vce(cluster userid date)
eststo: reghdfe sd_gbd l.sd_gbd lnju  0.employ l.emp1 first_l  i.year i.month covid if _EDU_CAT !="College", vce(cluster userid date) abs(userid)
eststo: reghdfe sd_gbd lndis  i.year i.month covid  l.sd_gbd if _EDU_CAT !="College", vce(cluster userid date)
eststo: reghdfe sd_gbd lndis   0.employ l.emp1 first_l  l.sd_gbd i.year i.month covid if _EDU_CAT !="College", vce(cluster userid date)
eststo: reghdfe sd_gbd l.sd_gbd lndis  0.employ l.emp1 first_l  i.year i.month covid if _EDU_CAT !="College", vce(cluster userid date) abs(userid)

* Panel B Columns 10-18
eststo: reghdfe sd_gbd lnepu  i.year i.month covid  l.sd_gbd if _EDU_CAT =="College", vce(cluster userid date)
eststo: reghdfe sd_gbd lnepu   0.employ l.emp1 first_l  l.sd_gbd i.year i.month covid if _EDU_CAT =="College", vce(cluster userid date)
eststo: reghdfe sd_gbd l.sd_gbd lnepu  0.employ l.emp1 first_l  i.year i.month covid if _EDU_CAT =="College", vce(cluster userid date) abs(userid)
eststo: reghdfe sd_gbd lnju  i.year i.month covid  l.sd_gbd if _EDU_CAT =="College", vce(cluster userid date)
eststo: reghdfe sd_gbd lnju   0.employ l.emp1 first_l  l.sd_gbd i.year i.month covid if _EDU_CAT =="College", vce(cluster userid date)
eststo: reghdfe sd_gbd l.sd_gbd lnju  0.employ l.emp1 first_l  i.year i.month covid if _EDU_CAT =="College", vce(cluster userid date) abs(userid)
eststo: reghdfe sd_gbd lndis  i.year i.month covid  l.sd_gbd if _EDU_CAT =="College", vce(cluster userid date)
eststo: reghdfe sd_gbd lndis   0.employ l.emp1 first_l  l.sd_gbd i.year i.month covid if _EDU_CAT =="College", vce(cluster userid date)
eststo: reghdfe sd_gbd l.sd_gbd lndis  0.employ l.emp1 first_l  i.year i.month covid if _EDU_CAT =="College", vce(cluster userid date) abs(userid)

esttab using "${OUT}\hh_table16.csv", replace ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    se ///
    drop(*.year *.month covid) nogap ///
    order(lnepu lnju lndis first_l L.emp1 0.employ ///
          L.sd_mam L.sd_gbd) ///
	    varlabels( ///
        lnepu     "Log EPU" ///
        lnju      "Log JU" ///
        lndis     "Log Disagreement" ///
        first_l   "Lagged real-time GDP growth" ///
        L.emp1    "Lagged real-time employment rate" ///
        0.employ  "Being unemployed" ///
        L.sd_mam "Lagged dependent variable" ///
		_cons "Constant") ///
    stats(N N_clust1 r2_a, fmt(0 0 2) labels("Number of observations" "Number of individuals" "Adjusted R-squared"))




/**********************************************************************
 Appendix B.3 Table 18	
**********************************************************************/
xtset userid date
eststo clear
* Panel A Columns 1-4
eststo: reghdfe mean_direct ln_daily_epu i.year i.month covid  l.mean_direct, vce(cluster userid date)
eststo: reghdfe mean_direct ln_daily_epu  0.employ l.emp1 first_l  l.mean_direct i.year i.month covid , vce(cluster userid date)
eststo: reghdfe mean_direct l.mean_direct ln_daily_epu 0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)
eststo: reghdfe mean_direct l.mean_direct ln_daily_epu ln_daily_epu_ma30 0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)


* Panel A Columns 5-8
eststo: reghdfe mean_mam ln_daily_epu i.year i.month covid  l.mean_mam, vce(cluster userid date)
eststo: reghdfe mean_mam ln_daily_epu  0.employ l.emp1 first_l  l.mean_mam i.year i.month covid , vce(cluster userid date)
eststo: reghdfe mean_mam l.mean_mam ln_daily_epu 0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)
eststo: reghdfe mean_mam l.mean_mam ln_daily_epu ln_daily_epu_ma30 0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)

* Panel A Columns 9-12
eststo: reghdfe mean_gbd ln_daily_epu i.year i.month covid  l.mean_gbd, vce(cluster userid date)
eststo: reghdfe mean_gbd ln_daily_epu  0.employ l.emp1 first_l  l.mean_gbd i.year i.month covid , vce(cluster userid date)
eststo: reghdfe mean_gbd l.mean_gbd ln_daily_epu 0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)
eststo: reghdfe mean_gbd l.mean_gbd ln_daily_epu ln_daily_epu_ma30 0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)

* Panel B Columns 1-4
eststo: reghdfe sd_mam ln_daily_epu i.year i.month covid l.sd_mam, vce(cluster userid date)
eststo: reghdfe sd_mam ln_daily_epu  0.employ l.emp1 first_l  l.sd_mam i.year i.month covid , vce(cluster userid date)
eststo: reghdfe sd_mam l.sd_mam ln_daily_epu 0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)
eststo: reghdfe sd_mam l.sd_mam ln_daily_epu ln_daily_epu_ma30 0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)

* Panel B Columns 5-8
eststo: reghdfe sd_gbd l.sd_gbd ln_daily_epu i.year i.month covid , vce(cluster userid date)
eststo: reghdfe sd_gbd l.sd_gbd ln_daily_epu  0.employ l.emp1 first_l i.year i.month covid , vce(cluster userid date)
eststo: reghdfe sd_gbd l.sd_gbd ln_daily_epu 0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)
eststo: reghdfe sd_gbd l.sd_gbd ln_daily_epu ln_daily_epu_ma30 0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)

* Panel B Columns 9-12
eststo: reghdfe sd_eprs l.sd_eprs ln_daily_epu i.year i.month covid , vce(cluster userid date)
eststo: reghdfe sd_eprs l.sd_eprs ln_daily_epu  0.employ l.emp1 first_l i.year i.month covid , vce(cluster userid date)
eststo: reghdfe sd_eprs l.sd_eprs ln_daily_epu 0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)
eststo: reghdfe sd_eprs l.sd_eprs ln_daily_epu ln_daily_epu_ma30 0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)

* Panel C Columns 1-4
eststo: reghdfe span l.span ln_daily_epu i.year i.month covid , vce(cluster userid date)
eststo: reghdfe span l.span ln_daily_epu  0.employ l.emp1 first_l i.year i.month covid , vce(cluster userid date)
eststo: reghdfe span l.span ln_daily_epu 0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)
eststo: reghdfe span l.span ln_daily_epu ln_daily_epu_ma30 0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)
esttab using "${OUT}\hh_table18.csv", replace ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    se ///
    drop(*.year *.month covid) nogap ///
    order(ln_daily_epu ln_daily_epu_ma30   first_l L.emp1 0.employ ///
          L.sd_mam L.sd_gbd) ///
	    varlabels( ///
        lnepu     "Log EPU" ///
        lnju      "Log JU" ///
        lndis     "Log Disagreement" ///
		ln_daily_epu "Log Daily EPU" ///
		ln_daily_epu_ma30 "Log average Daily EPU in past 30 days" ///
        first_l   "Lagged real-time GDP growth" ///
        L.emp1    "Lagged real-time employment rate" ///
        0.employ  "Being unemployed" ///
        L.sd_mam "Lagged dependent variable" ///
		_cons "Constant") ///
    stats(N N_clust1 r2_a, fmt(0 0 2) labels("Number of observations" "Number of individuals" "Adjusted R-squared"))


/**********************************************************************
 Appendix B.4 Table 20
**********************************************************************/

xtset userid date
eststo clear
* Panel A Columns 1-9
eststo: reghdfe lower_bound lnepu 0.employ l.emp1 first_l  l.lower_bound , vce(cluster userid date)
eststo: reghdfe lower_bound lnepu  0.employ l.emp1 first_l  l.lower_bound i.year i.month covid , vce(cluster userid date)
eststo: reghdfe lower_bound l.lower_bound lnepu 0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)
eststo: reghdfe lower_bound lnju 0.employ l.emp1 first_l  l.lower_bound , vce(cluster userid date)
eststo: reghdfe lower_bound lnju  0.employ l.emp1 first_l  l.lower_bound i.year i.month covid , vce(cluster userid date)
eststo: reghdfe lower_bound l.lower_bound lnju 0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)
eststo: reghdfe lower_bound lndis 0.employ l.emp1 first_l  l.lower_bound , vce(cluster userid date)
eststo: reghdfe lower_bound lndis  0.employ l.emp1 first_l  l.lower_bound i.year i.month covid , vce(cluster userid date)
eststo: reghdfe lower_bound l.lower_bound lndis 0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)


* Panel A Columns 10-18
eststo: reghdfe upper_bound l.upper_bound lnepu 0.employ l.emp1 first_l , vce(cluster userid date)
eststo: reghdfe upper_bound l.upper_bound lnepu  0.employ l.emp1 first_l i.year i.month covid , vce(cluster userid date)
eststo: reghdfe upper_bound l.upper_bound lnepu 0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)
eststo: reghdfe upper_bound l.upper_bound lnju 0.employ l.emp1 first_l , vce(cluster userid date)
eststo: reghdfe upper_bound l.upper_bound lnju  0.employ l.emp1 first_l i.year i.month covid , vce(cluster userid date)
eststo: reghdfe upper_bound l.upper_bound lnju 0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)
eststo: reghdfe upper_bound l.upper_bound lndis 0.employ l.emp1 first_l , vce(cluster userid date)
eststo: reghdfe upper_bound l.upper_bound lndis  0.employ l.emp1 first_l i.year i.month covid , vce(cluster userid date)
eststo: reghdfe upper_bound l.upper_bound lndis 0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)

* Panel B Columns 1-9
eststo: reghdfe span l.span lnepu 0.employ l.emp1 first_l , vce(cluster userid date)
eststo: reghdfe span l.span lnepu  0.employ l.emp1 first_l i.year i.month covid , vce(cluster userid date)
eststo: reghdfe span l.span lnepu 0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)
eststo: reghdfe span l.span lnju 0.employ l.emp1 first_l , vce(cluster userid date)
eststo: reghdfe span l.span lnju  0.employ l.emp1 first_l i.year i.month covid , vce(cluster userid date)
eststo: reghdfe span l.span lnju 0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)
eststo: reghdfe span l.span lndis 0.employ l.emp1 first_l , vce(cluster userid date)
eststo: reghdfe span l.span lndis  0.employ l.emp1 first_l i.year i.month covid , vce(cluster userid date)
eststo: reghdfe span l.span lndis 0.employ l.emp1 first_l  i.year i.month covid , vce(cluster userid date) abs(userid)

esttab using "${OUT}\hh_table20.csv", replace ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    se ///
    drop(*.year *.month covid) nogap ///
    order(lnepu lnju lndis first_l L.emp1 0.employ ///
          L.lower_bound) ///
	    varlabels( ///
        lnepu     "Log EPU" ///
        lnju      "Log JU" ///
        lndis     "Log Disagreement" ///
		ln_daily_epu "Log Daily EPU" ///
		ln_daily_epu_ma30 "Log average Daily EPU in past 30 days" ///
        first_l   "Lagged real-time GDP growth" ///
        L.emp1    "Lagged real-time employment rate" ///
        0.employ  "Being unemployed" ///
        L.lower_bound  "Lagged dependent variable" ///
		_cons "Constant") ///
    stats(N N_clust1 r2_a, fmt(0 0 2) labels("Number of observations" "Number of individuals" "Adjusted R-squared"))	
