clear all

*-------------------------------------------------------
* project: Abortion and Crime
*-------------------------------------------------------

local pgm  "table2" // file name
local who  "Ben Xue"            // author
local dte  "2026-10-26"            // created date
local dte2 "`c(current_date)'"     // last run date
local tag  "`pgm'.do, created by `who' on `dte', last run on `dte2'"
display "`tag'"

/*
Table 2. Impact of Abortion Provider Distance on Labor Market Outcomes
County x year panel of the counties in the agency sample; county and year FE.
 Panel A: number of individuals in the labor force, Poisson (exposure county population)
 Panel B: unemployment rate, linear (weighted by county population)
For each treatment threshold (25, 50, 100 miles): without covariates, then with county demographics.
Output: ./result/table/table2_panelA_labor_force.csv
        ./result/table/table2_panelB_unemployment.csv
*/

use "./data_clean/sample_agency.dta", clear

* covariates
global x white_shr black_shr nonhispan_shr age_15_44_f_shr age_le9_shr age_10_19_shr age_20_29_shr age_30_39_shr age_40_49_shr age_50_59_shr

global optionmech	"stats(ame ame_se N y_mean countyDemo countyFE yearFE , fmt(3 3 0 3 0 ) labels(`"AME"' `"AME S.E."' `"N"' `"E[Y|Pre, Treat]"' `"County Demographics"'  `"County FE"' `"Year FE"' )) "

// collapse to county level analysis, so that sample for mechanism and main results are consistent
collapse num_labor_force unemprate t_sample_* tgroup* up* county_pop $x , by(countyfips year)
xtset countyfips year

estimates clear
eststo clear
foreach T in up25 up50 up100 {
	// Poisson model
	foreach v in num_labor_force {
		di "`v' `T'"
		ppmlhdfe `v'  `T' if (t_sample_0==1 | t_sample_`T' == 1), absorb(countyfips year) vce(robust) d exp(county_pop)
		su `v' if e(sample) == 1 & t_sample_`T' == 1 & (year<tgroup_`T')
		estadd scalar y_mean = r(mean)
		// AME: 0/1 change at the treated pre-period observations
		margins, at(`T'=(0 1)) subpop(if t_sample_`T' == 1 & year<tgroup_`T') contrast(atcontrast(r) nowald)
		estadd scalar ame = r(b)[1,1]
		estadd scalar ame_se  = sqrt(r(V)[1,1])
		estadd local countyFE = "Y", replace
		estadd local yearFE   = "Y", replace
		eststo `v'_`T'_0

		ppmlhdfe `v'  `T' $x if (t_sample_0==1 | t_sample_`T' == 1), absorb(countyfips year) vce(robust) d exp(county_pop)
		su `v' if e(sample) == 1 & t_sample_`T' == 1 & (year<tgroup_`T')
		estadd scalar y_mean = r(mean)
		margins, at(`T'=(0 1)) subpop(if t_sample_`T' == 1 & year<tgroup_`T') contrast(atcontrast(r) nowald)
		estadd scalar ame = r(b)[1,1]
		estadd scalar ame_se  = sqrt(r(V)[1,1])
		estadd local countyDemo = "Y", replace
		estadd local countyFE = "Y", replace
		estadd local yearFE   = "Y", replace
		eststo `v'_`T'_1
	}

	// Linear model
	foreach v in unemprate {
		di "`v' `T'"
		reghdfe `v'  `T'  [aw=county_pop] if (t_sample_0==1 | t_sample_`T' == 1) , absorb(countyfips year) vce(robust)
		su `v' [aw=county_pop] if e(sample) == 1 & t_sample_`T' == 1 & (year<tgroup_`T')
		estadd scalar y_mean = r(mean)
		estadd local countyFE = "Y", replace
		estadd local yearFE   = "Y", replace
		eststo `v'_`T'_0

		reghdfe `v'  `T' $x  [aw=county_pop] if (t_sample_0==1 | t_sample_`T' == 1) , absorb(countyfips year) vce(robust)
		su `v' [aw=county_pop] if e(sample) == 1 & t_sample_`T' == 1 & (year<tgroup_`T')
		estadd scalar y_mean = r(mean)
		estadd local countyDemo = "Y", replace
		estadd local countyFE = "Y", replace
		estadd local yearFE   = "Y", replace
		eststo `v'_`T'_1
	}
}

* Panel A. Number of individuals in the labor force
esttab num_labor_force_up25_0 num_labor_force_up25_1 num_labor_force_up50_0 num_labor_force_up50_1 num_labor_force_up100_0 num_labor_force_up100_1, ///
	b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) rename(up25 Treatment up50 Treatment up100 Treatment) keep(Treatment) $optionmech
esttab num_labor_force_up25_0 num_labor_force_up25_1 num_labor_force_up50_0 num_labor_force_up50_1 num_labor_force_up100_0 num_labor_force_up100_1 ///
	using "./result/table/table2_panelA_labor_force.csv", ///
	b(3) se(3) csv star(* 0.10 ** 0.05 *** 0.01) rename(up25 Treatment up50 Treatment up100 Treatment) keep(Treatment) $optionmech ///
	mtitles("25 miles" "25 miles" "50 miles" "50 miles" "100 miles" "100 miles") replace

* Panel B. Unemployment rate
esttab unemprate_up25_0 unemprate_up25_1 unemprate_up50_0 unemprate_up50_1 unemprate_up100_0 unemprate_up100_1, ///
	b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) rename(up25 Treatment up50 Treatment up100 Treatment) keep(Treatment) $optionmech
esttab unemprate_up25_0 unemprate_up25_1 unemprate_up50_0 unemprate_up50_1 unemprate_up100_0 unemprate_up100_1 ///
	using "./result/table/table2_panelB_unemployment.csv", ///
	b(3) se(3) csv star(* 0.10 ** 0.05 *** 0.01) rename(up25 Treatment up50 Treatment up100 Treatment) keep(Treatment) $optionmech ///
	mtitles("25 miles" "25 miles" "50 miles" "50 miles" "100 miles" "100 miles") replace
