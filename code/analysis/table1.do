clear all

*-------------------------------------------------------
* project: Abortion and Crime
*-------------------------------------------------------

local pgm  "table1" // file name
local who  "Ben Xue"            // author
local dte  "2026-10-26"            // created date
local dte2 "`c(current_date)'"     // last run date
local tag  "`pgm'.do, created by `who' on `dte', last run on `dte2'"
display "`tag'"

/*
Table 1. Impact of Abortion Provider Distance on Crime, Baseline
Poisson DiD, agency and year FE, exposure agency population, SE clustered by county.
For each treatment threshold (25, 50, 100 miles): without covariates, then with county demographics.
Output: ./result/table/table1_panelA_property.csv
        ./result/table/table1_panelB_nonproperty.csv
*/

use "./data_clean/sample_agency.dta", clear
xtset orin year

* covariates
global x white_shr black_shr nonhispan_shr age_15_44_f_shr age_le9_shr age_10_19_shr age_20_29_shr age_30_39_shr age_40_49_shr age_50_59_shr

global tab_opt	"stats(pct ame ame_se N y_mean countyDemo agencyFE yearFE , fmt(1 3 3 0 3) labels(`"% effect"' `"AME"' `"AME S.E."' `"N"' `"E[Y|Pre, Treat]"' `"County Demographics"'  `"Agency FE"' `"Year FE"' )) "

*********************
**# Poisson DiD
*********************
estimates clear
eststo clear
foreach v in index_property nonproperty {
	foreach T in up25 up50 up100 {
		di "`v' `T'"
		// with county demographics
		ppmlhdfe `v'  `T'  $x if (t_sample_0==1 | t_sample_`T' == 1) , absorb(orin year ) vce(cluster countyfips) d exp(agency_population)
		gen sample_`T'_`v' = e(sample)
		su `v' if e(sample) == 1 & t_sample_`T' == 1 & (year<tgroup_`T') // treat pre
		estadd scalar y_mean = r(mean)
		estadd scalar pct = 100*(exp(_b[`T']) - 1)
		// AME: 0/1 change at the treated pre-period observations
		margins, at(`T'=(0 1)) subpop(if t_sample_`T' == 1 & year<tgroup_`T') contrast(atcontrast(r) nowald)
		estadd scalar ame = r(b)[1,1]
		estadd scalar ame_se  = sqrt(r(V)[1,1])
		estadd local countyDemo = "Y", replace
		estadd local agencyFE = "Y", replace
		estadd local yearFE   = "Y", replace
		eststo `v'_`T'_1

		// without covariates, same sample
		ppmlhdfe `v'  `T' if sample_`T'_`v'==1 , absorb(orin year ) vce(cluster countyfips) d exp(agency_population)
		su `v' if e(sample) == 1 & t_sample_`T' == 1 & (year<tgroup_`T') // treat pre
		estadd scalar y_mean = r(mean)
		estadd scalar pct = 100*(exp(_b[`T']) - 1)
		margins, at(`T'=(0 1)) subpop(if t_sample_`T' == 1 & year<tgroup_`T') contrast(atcontrast(r) nowald)
		estadd scalar ame = r(b)[1,1]
		estadd scalar ame_se  = sqrt(r(V)[1,1])
		estadd local agencyFE = "Y", replace
		estadd local yearFE   = "Y", replace
		eststo `v'_`T'_0
	}
}

* Panel A. Property crime
esttab index_property_up25_0 index_property_up25_1 index_property_up50_0 index_property_up50_1 index_property_up100_0 index_property_up100_1, ///
	b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) rename(up25 Treatment up50 Treatment up100 Treatment) keep(Treatment) $tab_opt
esttab index_property_up25_0 index_property_up25_1 index_property_up50_0 index_property_up50_1 index_property_up100_0 index_property_up100_1 ///
	using "./result/table/table1_panelA_property.csv", ///
	b(3) se(3) csv star(* 0.10 ** 0.05 *** 0.01) rename(up25 Treatment up50 Treatment up100 Treatment) keep(Treatment) $tab_opt ///
	mtitles("25 miles" "25 miles" "50 miles" "50 miles" "100 miles" "100 miles") replace

* Panel B. Non-property crime
esttab nonproperty_up25_0 nonproperty_up25_1 nonproperty_up50_0 nonproperty_up50_1 nonproperty_up100_0 nonproperty_up100_1, ///
	b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) rename(up25 Treatment up50 Treatment up100 Treatment) keep(Treatment) $tab_opt
esttab nonproperty_up25_0 nonproperty_up25_1 nonproperty_up50_0 nonproperty_up50_1 nonproperty_up100_0 nonproperty_up100_1 ///
	using "./result/table/table1_panelB_nonproperty.csv", ///
	b(3) se(3) csv star(* 0.10 ** 0.05 *** 0.01) rename(up25 Treatment up50 Treatment up100 Treatment) keep(Treatment) $tab_opt ///
	mtitles("25 miles" "25 miles" "50 miles" "50 miles" "100 miles" "100 miles") replace
