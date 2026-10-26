*-------------------------------------------------------
* project: Abortion and Crime
*-------------------------------------------------------

local pgm  "bx_abt-crime-data02_sample_agency" // file name
local who  "Ben Xue"            // author
local dte  "2026-10-26"            // created date
local dte2 "`c(current_date)'"     // last run date
local tag  "`pgm'.do, created by `who' on `dte', last run on `dte2'"
display "`tag'"

/*
Analysis sample: balanced panel of Texas law enforcement agencies, 2009-2019.
 1. merge crime, arrests, county covariates, county outcomes and distance (agency x year)
 2. sample restrictions
 3. outcomes
 4. treatment and control groups
Output: ./data_clean/sample_agency.dta (agency x year)
*/

********************************
**# merge
********************************
** crime data: agency-level
use "./data_clean/ucr_offenses_tx.dta", clear

** arrests: agency-years with a 12-month arrest report
merge 1:1 ori ori9 countyfips year fips_place_code using "./data_clean/ucr_arrests_tx.dta", keep(master match) nogen

** SEER population and demographics: county-level
merge m:1 countyfips year using "./data_clean/seer_tx.dta", nogen keep(master match)

** labor market: county-level
merge m:1 countyfips year using "./data_clean/labor_market_tx.dta", nogen keep(master match)

** per capita income: county-level
merge m:1 countyfips year using "./data_clean/bea_tx.dta", nogen keep(master match)

** debt to income ratio: county-level
merge m:1 countyfips year using "./data_clean/debt_to_income_tx.dta", nogen keep(master match)

** mortgage delinquency: county-level
merge m:1 countyfips year using "./data_clean/delinquent_90plus_tx.dta", nogen keep(master match)

** eviction filings: county-level
merge m:1 countyfips year using "./data_clean/eviction_tx.dta", nogen keep(master match)

** distance to nearest abortion clinic
merge m:1 countyfips year using "./data_clean/distance_annual_tx.dta", nogen keep(master match)

ta year
distinct countyfips

********************************
**# sample restrictions
********************************
drop if population_1 == 0                 // restrict to agencies who cover at least some population
drop if number_of_months_missing != 0     // all 12 months reported
drop if covered_by_ori != ""              // crime not reported by another agency

// balanced panel: agencies that report all 12 months in all 11 years (2009-2019)
bys ori: gen n_full_years = _N
tab n_full_years
keep if n_full_years == 11
drop n_full_years

sort ori year
egen orin = group(ori)

dis "number of agencies:"
distinct ori
dis "number of counties:"
distinct countyfips

********************************
**# outcomes
********************************
ren actual_assault_aggravated actual_assault_agg
ren actual_mtr_veh_theft_total actual_mtr_theft
ren actual_index_violent index_violent
ren actual_assault_simple assault_simple

foreach var of varlist index_violent actual_murder actual_robbery_total actual_assault_agg actual_burg_total actual_mtr_theft actual_theft_total property_* {
	replace `var' = 0 if `var'<0
}

// property crime: burglary + larceny-theft + motor vehicle theft
gen index_property = actual_burg_total + actual_mtr_theft + actual_theft_total
// non-property crime: murder + rape + robbery + aggravated assault + simple assault
gen nonproperty = index_violent + assault_simple
// violent other: murder + rape + aggravated assault (Figure 3)
gen violent_other = actual_murder + actual_rape_by_force + actual_assault_agg
label var index_property "property crime"
label var nonproperty "non-property crime"
label var violent_other "murder, rape and aggravated assault"

// crime rate per 10,000 agency covered population
foreach v in index_property nonproperty {
	gen `v'_r = `v'/agency_population*10000
}
su index_property nonproperty index_property_r nonproperty_r agency_population

********************************
**# treatment
********************************
// counties affected by the temporary clinic closure in McAllen (the clinic reopened in 2014) are recoded to control
/* Cameron County (48061), Hidalgo County (48215), Starr County (48427), Willacy County (48489), Zapata County (48505)*/
foreach T in up25 up50 up100 {
	replace `T'=0 if inlist(countyfips, 48061, 48215, 48427, 48489, 48505)
}

* define treatmnet cohorts
foreach t in up25 up50 up100 {
	// label years that td increases >= a threshold
	gen year_of_treat_`t' = year*`t' if `t'!=0
	// for each agency, find the first year that td increases >= a threshold
	bys countyfips: egen tgroup_`t' = min(year_of_treat_`t')
	// cohort by year of treatment, used for staggered did analysis
	replace tgroup_`t' = 0 if tgroup_`t' >= .
	drop year_of_treat_`t'
	// cohort by treatmnet intensity
	bys countyfips: egen t_`t' = max(`t')
	/* note: if an agency belongs to the up100 group, it is also contained in up50 group and up25 group */
	gen t_sample_`t'= (t_`t' == 1) // alias for treatment groups
	drop t_`t'
}

// examine defined treatment shocks
foreach t in up25 up50 up100 {
	ta tgroup_`t'
}

* define the control group
// control group: td shock never exceeded 25 miles
gen t_sample_0 = t_sample_up25 == 0

* sample label
gen t_sample_lab = 0 if t_sample_0==1
foreach n in 25 50 100 {
	replace t_sample_lab = `n' if t_sample_up`n' == 1
}
tab t_sample_lab if year == 2012

// number of agencies and counties in each group
foreach t in 0 up25 up50 up100 {
	distinct orin countyfips if t_sample_`t' == 1
}

keep ori orin countyfips year agency_population county_pop *_shr ///
	index_property nonproperty index_property_r nonproperty_r ///
	actual_burg_total actual_mtr_theft actual_theft_total actual_robbery_total violent_other assault_simple property_* ///
	num_labor_force unemprate pc_inc debt_to_inc_ub delinquent_90plus filings_observed ///
	td up25 up50 up100 tgroup_* t_sample_*
order ori orin countyfips year
sort orin year
xtset orin year

* labels
label var ori "agency ORI (7 characters)"
label var orin "agency id"
label var countyfips "county FIPS code"
label var year "year"
label var agency_population "agency covered population (FBI)"
label var county_pop "county population (SEER)"
label var white_shr "county share white, %"
label var black_shr "county share black, %"
label var nonhispan_shr "county share non-Hispanic, %"
label var age_15_44_f_shr "county share women 15-44, %"
label var age_le9_shr "county share age 0-9, %"
label var age_10_19_shr "county share age 10-19, %"
label var age_20_29_shr "county share age 20-29, %"
label var age_30_39_shr "county share age 30-39, %"
label var age_40_49_shr "county share age 40-49, %"
label var age_50_59_shr "county share age 50-59, %"
label var index_property_r "property crime per 10,000 agency population"
label var nonproperty_r "non-property crime per 10,000 agency population"
label var actual_burg_total "burglary"
label var actual_mtr_theft "motor vehicle theft"
label var actual_theft_total "larceny-theft"
label var actual_robbery_total "robbery"
label var assault_simple "simple assault"
label var num_labor_force "county labor force (BLS LAUS)"
label var unemprate "county unemployment rate, % (BLS LAUS)"
label var pc_inc "county per capita personal income, 2010 dollars (BEA)"
label var debt_to_inc_ub "county household debt-to-income ratio, upper bound (Federal Reserve)"
label var delinquent_90plus "county share of mortgages 90+ days delinquent, % (CFPB)"
label var filings_observed "county eviction filings (Eviction Lab)"
foreach t in 25 50 100 {
	label var up`t' "treated: from the first year distance rises >= `t' miles (McAllen area 0)"
	label var tgroup_up`t' "first treated year, `t' miles (0 = never)"
	label var t_sample_up`t' "county in the `t'-mile treatment group"
}
label var t_sample_0 "county in the control group (distance never rises 25 miles)"
label var t_sample_lab "group: 0 control, 25, 50, 100 miles (largest)"

compress
save "./data_clean/sample_agency.dta", replace
