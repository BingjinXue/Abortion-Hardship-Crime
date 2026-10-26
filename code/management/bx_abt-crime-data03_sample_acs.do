*-------------------------------------------------------
* project: Abortion and Crime
*-------------------------------------------------------

local pgm  "bx_abt-crime-data03_sample_acs" // file name
local who  "Ben Xue"            // author
local dte  "2026-10-26"            // created date
local dte2 "`c(current_date)'"     // last run date
local tag  "`pgm'.do, created by `who' on `dte', last run on `dte2'"
display "`tag'"

/*
ACS sample (Table 3, Panel B): ACS persons merged with the county treatment, with the treatment and control groups
defined as in the agency sample.
Output: ./data_clean/sample_acs.dta (person x year)
*/

use "./data_clean/acs_tx.dta", clear

* merge: distance to nearest abortion clinic
merge m:1 countyfips year using "./data_clean/distance_annual_tx.dta", nogen keep(master match)
tab year

* define treatment shocks
// counties affected by the temporary clinic closure in McAllen are recoded to control (as in the agency sample)
foreach T in up25 up50 up100 {
	replace `T'=0 if inlist(countyfips, 48061, 48215, 48427, 48489, 48505)
}

// find the first year that td increases more than a threshold, used for staggered did analysis
foreach t in up25 up50 up100 {
	// label years that td increases >= a threshold
	gen year_of_treat_`t' = year*`t' if `t'!=0
	// for each agency, find the first year that td increases >= a threshold
	bys countyfips: egen tgroup_`t' = min(year_of_treat_`t')
	replace tgroup_`t' = 0 if tgroup_`t' >= .
	drop year_of_treat_`t'
	// ever experience the corresponding td shock
	bys countyfips: egen t_`t' = max(`t')
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

foreach t in 0 up25 up50 up100 {
	di "Number of unique counties in sample: `t'"
	distinct countyfips if t_sample_`t' == 1
}

drop td

* labels
label var countyfips "county FIPS code"
label var incearn_2010 "total personal earned income, 2010 dollars"
label var white "white"
label var black "black"
label var nonhispan "non-Hispanic"
label var female_fertage "woman aged 15-44"
foreach a in le9 10_19 20_29 30_39 40_49 50_59 {
	label var age_`a' "age group `a'"
}
foreach t in 25 50 100 {
	label var up`t' "treated: from the first year distance rises >= `t' miles (McAllen area 0)"
	label var tgroup_up`t' "first treated year, `t' miles (0 = never)"
	label var t_sample_up`t' "county in the `t'-mile treatment group"
}
label var t_sample_0 "county in the control group (distance never rises 25 miles)"

order year serial pernum
sort year serial pernum
isid year serial pernum
compress
save "./data_clean/sample_acs.dta", replace
