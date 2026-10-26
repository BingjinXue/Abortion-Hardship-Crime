*-------------------------------------------------------
* project: Abortion and Crime
*-------------------------------------------------------

local pgm  "bx_abt-crime-data01_ucr_arrest_clean" // file name
local who  "Ben Xue"            // author
local dte  "2026-10-26"            // created date
local dte2 "`c(current_date)'"     // last run date
local tag  "`pgm'.do, created by `who' on `dte', last run on `dte2'"
display "`tag'"

/*
This file cleans the UCR arrest data (Kaplan, Arrests by Age, Sex and Race, index crimes by age, 1974-2021) for
Texas agencies, 2009-2019. Only property crime arrests (burglary, theft, motor vehicle theft) by sex and age
(juvenile < 18, adult >= 18) are kept (Figure 3, Panel B).
Agency-years with fewer than 12 months of arrest reports are dropped; their arrests are missing after the merge.
Input:  ./data_raw/ucr_offenses_known_yearly_1960_2020/ucr_arrests_yearly_data_1974_2021_dta/ucr_arrests_yearly_index_crimes_age_1974_2021.dta
Output: ./data_clean/ucr_arrests_tx.dta (agency x year)
*/

use ori ori9 fips_state_code fips_state_county_code fips_place_code year number_of_months_reported ///
	burglary_tot_female_juv burglary_tot_female_adult burglary_tot_male_juv burglary_tot_male_adult ///
	theft_tot_female_juv theft_tot_female_adult theft_tot_male_juv theft_tot_male_adult ///
	mtr_veh_theft_tot_female_juv mtr_veh_theft_tot_female_adult mtr_veh_theft_tot_male_juv mtr_veh_theft_tot_male_adult ///
	using "./data_raw/ucr_offenses_known_yearly_1960_2020/ucr_arrests_yearly_data_1974_2021_dta/ucr_arrests_yearly_index_crimes_age_1974_2021.dta" ///
	if inrange(year, 2009, 2019), clear

// fips
rename fips_state_county_code countyfips
destring countyfips, replace
destring fips_state_code, replace
rename fips_state_code statefips
drop if missing(countyfips) //!!!!!!!!!!!!!!!!!!!!!
drop if countyfips == 0 //!!!!!!!!!!!!!!!!!!!!!
keep if statefips == 48 //!!!!!!!!!!!!!!!!!!!!!

// 12 months of arrest reports
tab number_of_months_reported
drop if number_of_months_reported <12 //!!!!!!!!!!!!!!!!!!!!!

// 9-character ORI = ori + "00" where blank (as in the offense data)
replace ori9 = ori + "00" if ori9 == ""
duplicates drop ori ori9 countyfips year fips_place_code, force

// property crime arrests by sex and age
egen property_fe_juv = rowtotal(burglary_tot_female_juv theft_tot_female_juv mtr_veh_theft_tot_female_juv), missing
egen property_fe_adult = rowtotal(burglary_tot_female_adult theft_tot_female_adult mtr_veh_theft_tot_female_adult), missing
egen property_m_juv = rowtotal(burglary_tot_male_juv theft_tot_male_juv mtr_veh_theft_tot_male_juv), missing
egen property_m_adult = rowtotal(burglary_tot_male_adult theft_tot_male_adult mtr_veh_theft_tot_male_adult), missing
label var property_fe_juv "property crime arrests: women < 18"
label var property_fe_adult "property crime arrests: women >= 18"
label var property_m_juv "property crime arrests: men < 18"
label var property_m_adult "property crime arrests: men >= 18"

keep ori ori9 countyfips year fips_place_code property_*
su property_*

compress
save "./data_clean/ucr_arrests_tx.dta", replace
