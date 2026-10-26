*-------------------------------------------------------
* project: Abortion and Crime
*-------------------------------------------------------

local pgm  "bx_abt-crime-data01_distance_clean" // file name
local who  "Ben Xue"          // author
local dte  "2026-10-26"            // created date
local dte2 "`c(current_date)'"     // last run date
local tag  "`pgm'.do, created by `who' on `dte', last run on `dte2'"
display "`tag'"

/*
Travel distance to the nearest abortion facility and the treatment variables, Texas counties.
Distance: Myers Abortion Facility Database, county x month.
Treatment: td = yearly mean travel distance; up<k> = 1 from the first year td rises by >= k miles over the previous
year (absorbing), k = 25, 50, 100.
Input:  ./data_raw/Myers Abt data/2025.07.01_abortionaccess_countyxmonth.dta
Output: ./data_clean/distance_monthly_tx.dta (county x month, Figure 1)
        ./data_clean/distance_annual_tx.dta  (county x year)
*/

use "./data_raw/Myers Abt data/2025.07.01_abortionaccess_countyxmonth.dta", clear

// generate statefips
gen statefips = substr(origin_fips_code, 1, 2)
destring statefips, replace
keep if statefips == 48 //!!!!!!!!!!!

// generate countyfips
destring origin_fips_code, gen(countyfips)

// population of female 15-44
ren origin_population pop_female_fertage

ren distance_origintodest td //travel distance in miles
keep countyfips year month td pop_female_fertage
sort countyfips year month

***************************************************************
**# monthly sample
***************************************************************
gen ym = ym(year, month)
format ym %tm
label var td "travel distance to the nearest provider, miles"
label var pop_female_fertage "female population 15-44"
label var countyfips "county FIPS code"
label var ym "year-month"
save "./data_clean/distance_monthly_tx.dta", replace

***********************************
**# Annual sample
***********************************
* collapse to yearly means
collapse (mean) td, by(countyfips year)
label var td "travel distance to the nearest provider, miles (yearly mean)"

* baseline definition
sort countyfips year
xtset countyfips year

by countyfips: gen jump = td - L.td
replace jump = 0 if jump == .
label var jump "td(yr) - td(yr-1), miles"

foreach k in 25 50 100 {
	local nm = "up`k'" //name
	by countyfips: egen `nm'_yr = min(cond(jump >= `k', year, .))
	gen `nm' = year >= `nm'_yr & `nm'_yr < .
	label var `nm'_yr "onset year: first year td >= `k' miles above last year"
	label var `nm' "from the first year td >= `k' miles above the previous year (absorbing)"
}

// treatment onsets
tab up25_yr if year == 2013, missing
tab up25_yr up100_yr if year == 2013, missing

keep countyfips year td up25 up50 up100
save "./data_clean/distance_annual_tx.dta", replace
