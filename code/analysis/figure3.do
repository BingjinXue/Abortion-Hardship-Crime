clear all

*-------------------------------------------------------
* project: Abortion and Crime
*-------------------------------------------------------

local pgm  "figure3" // file name
local who  "Ben Xue"            // author
local dte  "2026-10-26"            // created date
local dte2 "`c(current_date)'"     // last run date
local tag  "`pgm'.do, created by `who' on `dte', last run on `dte2'"
display "`tag'"

/*
Figure 3. Impact of Abortion Provider Distance on Crime by Type and Offender Characteristics
Poisson DiD with county demographics (as Table 1, columns 2, 4, 6) for
 Panel A: offenses by crime type
 Panel B: property crime arrests by sex and age of the arrestee
Output: ./result/figure/figure3_panelA_type.png
        ./result/figure/figure3_panelB_age_sex.png
        ./result/table/figure3_estimates_up25.csv, _up50.csv, _up100.csv (the plotted estimates)
*/

use "./data_clean/sample_agency.dta", clear
xtset orin year

* covariates
global x white_shr black_shr nonhispan_shr age_15_44_f_shr age_le9_shr age_10_19_shr age_20_29_shr age_30_39_shr age_40_49_shr age_50_59_shr

global tab_opt	"stats(pct ame ame_se N y_mean countyDemo agencyFE yearFE , fmt(1 3 3 0 3) labels(`"% effect"' `"AME"' `"AME S.E."' `"N"' `"E[Y|Pre, Treat]"' `"County Demographics"'  `"Agency FE"' `"Year FE"' )) "

***********************************
**# Heterogeneity Anlaysis: Crime
***********************************
estimates clear
eststo clear
foreach T in up25 up50 up100 {
	foreach v in actual_burg_total actual_mtr_theft actual_theft_total actual_robbery_total violent_other assault_simple property_fe_juv property_m_juv property_fe_adult property_m_adult {
		di "`v' `T'"
		ppmlhdfe `v'  `T'  $x if (t_sample_0==1 | t_sample_`T' == 1), absorb(orin year) vce(cluster countyfips) d exp(agency_population)
		su `v' if e(sample) == 1 & t_sample_`T' == 1 & (year<tgroup_`T')
		estadd scalar y_mean = r(mean)
		estadd scalar pct = 100*(exp(_b[`T']) - 1)
		margins, at(`T'=(0 1)) subpop(if t_sample_`T' == 1 & year<tgroup_`T') contrast(atcontrast(r) nowald)
		estadd scalar ame = r(b)[1,1]
		estadd scalar ame_se  = sqrt(r(V)[1,1])
		estadd local countyDemo = "Y", replace
		estadd local agencyFE = "Y", replace
		estadd local yearFE   = "Y", replace
		eststo `v'_`T'
	}
	esttab *_`T' using "./result/table/figure3_estimates_`T'.csv", b(3) se(3) csv star(* 0.10 ** 0.05 *** 0.01) keep(`T') $tab_opt replace
}

* Panel A. heterogeneity by types of crime
coefplot actual_burg_total_up25 actual_burg_total_up50 actual_burg_total_up100 , bylabel("Burglary") || ///
  actual_mtr_theft_up25 actual_mtr_theft_up50 actual_mtr_theft_up100, bylabel("Motor Vehicle Theft")|| ///
  actual_theft_total_up25 actual_theft_total_up50 actual_theft_total_up100 , bylabel("Theft")  || ///
  actual_robbery_total_up25 actual_robbery_total_up50 actual_robbery_total_up100  , bylabel("Robbery") || ///
  violent_other_up25 violent_other_up50 violent_other_up100  , bylabel("Violent Other") || ///
  assault_simple_up25 assault_simple_up50 assault_simple_up100  , bylabel("Assault Simple") || , keep(up25 up50 up100) coeflabels(up25="25 miles" up50="50 miles" up100="100 miles") bycoefs xline(0) byopts(compact rows(1) legend(off) ) graphregion(color(white))
graph export "./result/figure/figure3_panelA_type.png", as(png) replace width(1500)

* Panel B. heterogeneity by gender and age
coefplot property_fe_juv_up25 property_fe_juv_up50 property_fe_juv_up100 , bylabel("Women <18 years old") || ///
  property_m_juv_up25 property_m_juv_up50 property_m_juv_up100, bylabel("Men <18 years old")|| ///
  property_fe_adult_up25 property_fe_adult_up50 property_fe_adult_up100, bylabel("Women >=18 years old")  || ///
  property_m_adult_up25 property_m_adult_up50 property_m_adult_up100 , bylabel("Men >=18 years old") || , keep(up25 up50 up100) coeflabels(up25="25 miles" up50="50 miles" up100="100 miles") bycoefs xline(0) byopts(compact rows(1) legend(off) ) graphregion(color(white))
graph export "./result/figure/figure3_panelB_age_sex.png", as(png) replace width(1500)
