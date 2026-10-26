*-------------------------------------------------------
* project: Abortion and Crime
*-------------------------------------------------------

local pgm  "bx_abt-crime-data01_labor_market_clean" // file name
local who  "Wei Fu"            // author
local dte  "2026-10-26"            // created date
local dte2 "`c(current_date)'"     // last run date
local tag  "`pgm'.do, created by `who' on `dte', last run on `dte2'"
display "`tag'"

/*
This file cleans the county labor force and unemployment rate (BLS LAUS), Texas, 2009-2019.
Input:  ./data_raw/Labor-Market/county_employment_1999_2020.xlsx (one sheet per year)
Output: ./data_clean/labor_market_tx.dta (county x year)
*/

tempfile labor
forvalues j = 2009/2019 {
	import excel using "./data_raw/Labor-Market/county_employment_1999_2020.xlsx", sheet("year`j'") firstrow clear
	keep st_fips cty_fips year num_labor_force unemprate
	// numbers are stored as text in some years
	foreach v in num_labor_force unemprate {
		capture confirm string variable `v'
		if !_rc {
			rename `v' `v'_str
			gen `v' = real(`v'_str)
			drop `v'_str
		}
	}
	capture confirm string variable year
	if !_rc {
		rename year year_st
		gen year = real(year_st)
		drop year_st
	}
	if `j' > 2009 append using `labor'
	save `labor', replace
}

** geographic identifier
gen statefips = real(st_fips)
gen countyfips = statefips * 1000 + real(cty_fips)
drop if countyfips == .
keep if statefips == 48 //!!!!!!!!!!!

keep countyfips year num_labor_force unemprate
order countyfips year num_labor_force unemprate
sort countyfips year
tab year
su

save "./data_clean/labor_market_tx.dta", replace
