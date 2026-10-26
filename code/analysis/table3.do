clear all

*-------------------------------------------------------
* project: Abortion and Crime
*-------------------------------------------------------

local pgm  "table3" // file name
local who  "Ben Xue"            // author
local dte  "2026-10-26"            // created date
local dte2 "`c(current_date)'"     // last run date
local tag  "`pgm'.do, created by `who' on `dte', last run on `dte2'"
display "`tag'"

/*
Table 3. Impact of Abortion Provider Distance on Financial Outcomes
 Panels A, C, D, E: county x year panel of the counties in the agency sample; county and year FE
   A: personal income per capita (BEA), linear (weighted by county population)
   C: debt-to-income ratio, linear (weighted by county population)
   D: mortgage delinquency rate (>= 90 days), linear (weighted by county population)
   E: number of evictions, Poisson (exposure county population)
 Panel B: interquartile range of personal earned income (ACS persons aged 15-44), RIF regression (Rios-Avila 2020)
For each treatment threshold (25, 50, 100 miles): without covariates, then with demographics.
Output: ./result/table/table3_panelA_income.csv
        ./result/table/table3_panelB_income_iqr.csv
        ./result/table/table3_panelC_debt_to_income.csv
        ./result/table/table3_panelD_mortgage_delinquency.csv
        ./result/table/table3_panelE_evictions.csv
*/

global optionmech	"stats(ame ame_se N y_mean countyDemo countyFE yearFE , fmt(3 3 0 3 0 ) labels(`"AME"' `"AME S.E."' `"N"' `"E[Y|Pre, Treat]"' `"Demographic Controls"'  `"County FE"' `"Year FE"' )) "

******************************
**# Panels A, C, D, E: county level
******************************
use "./data_clean/sample_agency.dta", clear

* covariates
global x white_shr black_shr nonhispan_shr age_15_44_f_shr age_le9_shr age_10_19_shr age_20_29_shr age_30_39_shr age_40_49_shr age_50_59_shr

// collapse to county level analysis, so that sample for mechanism and main results are consistent
collapse pc_inc debt_to_inc_ub delinquent_90plus filings_observed t_sample_* tgroup* up* county_pop $x , by(countyfips year)
xtset countyfips year

estimates clear
eststo clear
foreach T in up25 up50 up100 {
	// Linear model
	foreach v in pc_inc debt_to_inc_ub delinquent_90plus {
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

	// Poisson model
	foreach v in filings_observed {
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
}

* Panel A. Personal income (per capita)
esttab pc_inc_up25_0 pc_inc_up25_1 pc_inc_up50_0 pc_inc_up50_1 pc_inc_up100_0 pc_inc_up100_1, ///
	b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) rename(up25 Treatment up50 Treatment up100 Treatment) keep(Treatment) $optionmech
esttab pc_inc_up25_0 pc_inc_up25_1 pc_inc_up50_0 pc_inc_up50_1 pc_inc_up100_0 pc_inc_up100_1 ///
	using "./result/table/table3_panelA_income.csv", ///
	b(3) se(3) csv star(* 0.10 ** 0.05 *** 0.01) rename(up25 Treatment up50 Treatment up100 Treatment) keep(Treatment) $optionmech ///
	mtitles("25 miles" "25 miles" "50 miles" "50 miles" "100 miles" "100 miles") replace

* Panel C. Debt-to-income ratio
esttab debt_to_inc_ub_up25_0 debt_to_inc_ub_up25_1 debt_to_inc_ub_up50_0 debt_to_inc_ub_up50_1 debt_to_inc_ub_up100_0 debt_to_inc_ub_up100_1, ///
	b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) rename(up25 Treatment up50 Treatment up100 Treatment) keep(Treatment) $optionmech
esttab debt_to_inc_ub_up25_0 debt_to_inc_ub_up25_1 debt_to_inc_ub_up50_0 debt_to_inc_ub_up50_1 debt_to_inc_ub_up100_0 debt_to_inc_ub_up100_1 ///
	using "./result/table/table3_panelC_debt_to_income.csv", ///
	b(3) se(3) csv star(* 0.10 ** 0.05 *** 0.01) rename(up25 Treatment up50 Treatment up100 Treatment) keep(Treatment) $optionmech ///
	mtitles("25 miles" "25 miles" "50 miles" "50 miles" "100 miles" "100 miles") replace

* Panel D. Mortgage delinquency rate (>= 90 days)
esttab delinquent_90plus_up25_0 delinquent_90plus_up25_1 delinquent_90plus_up50_0 delinquent_90plus_up50_1 delinquent_90plus_up100_0 delinquent_90plus_up100_1, ///
	b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) rename(up25 Treatment up50 Treatment up100 Treatment) keep(Treatment) $optionmech
esttab delinquent_90plus_up25_0 delinquent_90plus_up25_1 delinquent_90plus_up50_0 delinquent_90plus_up50_1 delinquent_90plus_up100_0 delinquent_90plus_up100_1 ///
	using "./result/table/table3_panelD_mortgage_delinquency.csv", ///
	b(3) se(3) csv star(* 0.10 ** 0.05 *** 0.01) rename(up25 Treatment up50 Treatment up100 Treatment) keep(Treatment) $optionmech ///
	mtitles("25 miles" "25 miles" "50 miles" "50 miles" "100 miles" "100 miles") replace

* Panel E. Number of evictions
esttab filings_observed_up25_0 filings_observed_up25_1 filings_observed_up50_0 filings_observed_up50_1 filings_observed_up100_0 filings_observed_up100_1, ///
	b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) rename(up25 Treatment up50 Treatment up100 Treatment) keep(Treatment) $optionmech
esttab filings_observed_up25_0 filings_observed_up25_1 filings_observed_up50_0 filings_observed_up50_1 filings_observed_up100_0 filings_observed_up100_1 ///
	using "./result/table/table3_panelE_evictions.csv", ///
	b(3) se(3) csv star(* 0.10 ** 0.05 *** 0.01) rename(up25 Treatment up50 Treatment up100 Treatment) keep(Treatment) $optionmech ///
	mtitles("25 miles" "25 miles" "50 miles" "50 miles" "100 miles" "100 miles") replace

******************************
**# Panel B: personal income IQR, ACS
******************************
use "./data_clean/sample_acs.dta", clear

* covariates
global x white black nonhispan female_fertage age_le9 age_10_19 age_20_29 age_30_39 age_40_49 age_50_59

global option1	"stats(N y_mean demo countyFE yearFE , fmt(0 3) labels(`"N"' `"E[Y|Pre, Treat]"' `"Demographic Controls"' `"County FE"' `"Year FE"' )) "

estimates clear
eststo clear
foreach T in up25 up50 up100 {
	foreach v in incearn_2010 {
		di "`v' `T'"
		rifhdreg `v' `T' if (t_sample_0==1 | t_sample_`T' == 1) [pweight=perwt], rif(iqr(25 75)) abs(countyfips year)  iseed(123) over(`T') rwlogit() att vce(cluster countyfips)
		// baseline: IQR of the treated group before treatment, weighted as the regression
		_pctile `v' [pw=perwt] if e(sample) == 1 & t_sample_`T' == 1 & `T' == 0, p(25 75)
		estadd scalar y_mean = r(r2) - r(r1)
		estadd local countyFE = "Y", replace
		estadd local yearFE   = "Y", replace
		eststo `v'_`T'_0

		rifhdreg `v' `T' $x if (t_sample_0==1 | t_sample_`T' == 1) [pweight=perwt], rif(iqr(25 75)) abs(countyfips year)  iseed(123) over(`T') rwlogit($x ) att vce(cluster countyfips)
		_pctile `v' [pw=perwt] if e(sample) == 1 & t_sample_`T' == 1 & `T' == 0, p(25 75)
		estadd scalar y_mean = r(r2) - r(r1)
		estadd local demo = "Y", replace
		estadd local countyFE = "Y", replace
		estadd local yearFE   = "Y", replace
		eststo `v'_`T'_1
	}
}

* Panel B. Personal income interquartile range (IQR)
esttab incearn_2010_up25_0 incearn_2010_up25_1 incearn_2010_up50_0 incearn_2010_up50_1 incearn_2010_up100_0 incearn_2010_up100_1, ///
	b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) rename(up25 Treatment up50 Treatment up100 Treatment) keep(Treatment) $option1
esttab incearn_2010_up25_0 incearn_2010_up25_1 incearn_2010_up50_0 incearn_2010_up50_1 incearn_2010_up100_0 incearn_2010_up100_1 ///
	using "./result/table/table3_panelB_income_iqr.csv", ///
	b(3) se(3) csv star(* 0.10 ** 0.05 *** 0.01) rename(up25 Treatment up50 Treatment up100 Treatment) keep(Treatment) $option1 ///
	mtitles("25 miles" "25 miles" "50 miles" "50 miles" "100 miles" "100 miles") replace
