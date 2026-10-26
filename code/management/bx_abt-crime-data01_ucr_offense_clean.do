*-------------------------------------------------------
* project: Abortion and Crime
*-------------------------------------------------------

local pgm  "bx_abt-crime-data01_ucr_offense_clean" // file name
local who  "Ben Xue"            // author
local dte  "2026-10-26"            // created date
local dte2 "`c(current_date)'"     // last run date
local tag  "`pgm'.do, created by `who' on `dte', last run on `dte2'"
display "`tag'"

/*
This file cleans the UCR offenses known data (Kaplan, Return A, yearly 1960-2020) for Texas agencies, 2009-2019.
Input:  ./data_raw/ucr_offenses_known_yearly_1960_2020/offenses_known_yearly_1960_2020.dta
Output: ./data_clean/ucr_offenses_tx.dta (agency x year)
*/

use ori ori9 agency_name agency_type state_abb fips_state_code fips_state_county_code fips_place_code year ///
	population population_1 covered_by_ori number_of_months_missing ///
	actual_burg_total actual_theft_total actual_mtr_veh_theft_total ///
	actual_murder actual_rape_by_force actual_robbery_total actual_assault_aggravated actual_assault_simple actual_index_violent ///
	using "./data_raw/ucr_offenses_known_yearly_1960_2020/offenses_known_yearly_1960_2020.dta" if inrange(year, 2009, 2019), clear

ta year

// fips
rename fips_state_county_code countyfips
destring countyfips, replace
destring fips_state_code, replace
rename fips_state_code statefips
rename state_abb state
drop if missing(countyfips) //!!!!!!!!!!!
drop if countyfips == 0 //!!!!!!!!!!!

// Texas
keep if statefips == 48 //!!!!!!!!!!!
order ori ori9 agency_name agency_type state statefips countyfips year, first

// 9-character ORI = ori + "00"; blank for newer agencies, fill with the same rule (used to merge arrests)
count if ori9 != "" & ori9 != ori + "00"
count if ori9 == ""
replace ori9 = ori + "00" if ori9 == ""

// agency population (FBI)
rename population agency_population

// insepction: county, agency
dis "number of agencies:"
distinct ori
dis "number of counties:"
distinct countyfips
tab number_of_months_missing, missing

sort ori year
compress
save "./data_clean/ucr_offenses_tx.dta", replace
