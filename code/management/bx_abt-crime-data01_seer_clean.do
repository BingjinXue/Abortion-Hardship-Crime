*-------------------------------------------------------
* project: Abortion and Crime
*-------------------------------------------------------

local pgm  "bx_abt-crime-data01_seer_clean" // file name
local who  "Ben Xue"      // author
local dte  "2026-10-26"            // created date
local dte2 "`c(current_date)'"     // last run date
local tag  "`pgm'.do, created by `who' on `dte', last run on `dte2'"
display "`tag'"

/*
County population and demographic shares (covariates) for Texas counties, 2009-2019, from the SEER all-states file
with 19 age groups (vintage 2024, 4 races by Hispanic origin).
Age codes: 00 = 0, 01 = 1-4, 02 = 5-9, 03 = 10-14, ..., 18 = 85+ (so 0-9 = codes 0-2, 10-19 = 3-4, 20-29 = 5-6,
30-39 = 7-8, 40-49 = 9-10, 50-59 = 11-12, women 15-44 = codes 4-9).
Shares are in percent of the county population.
Input:  ./data_raw/SEER/us.1990_2024.20ages.adjusted.txt
Output: ./data_clean/seer_tx.dta (county x year)
*/

infix ///
int year 			1-4 ///
str2 state 			5-6 ///
str2 statefips		7-8 ///
str3 county			9-11 ///
byte race			14-14 ///
byte origin			15-15 ///
byte sex			16-16 ///
byte age			17-18 ///
long population		19-26 ///
using "./data_raw/SEER/us.1990_2024.20ages.adjusted.txt" if statefips == "48" & inrange(year, 2009, 2019), clear

gen long countyfips = real(statefips + county)

gen double age_le9   = population*inrange(age, 0, 2)
gen double age_10_19 = population*inrange(age, 3, 4)
gen double age_20_29 = population*inrange(age, 5, 6)
gen double age_30_39 = population*inrange(age, 7, 8)
gen double age_40_49 = population*inrange(age, 9, 10)
gen double age_50_59 = population*inrange(age, 11, 12)
gen double age_15_44_f = population*(inrange(age, 4, 9) & sex == 2)
gen double white     = population*(race == 1)
gen double black     = population*(race == 2)
gen double nonhispan = population*(origin == 0)

collapse (sum) age_le9 age_10_19 age_20_29 age_30_39 age_40_49 age_50_59 age_15_44_f white black nonhispan population, by(countyfips year)
foreach v in white black nonhispan age_15_44_f age_le9 age_10_19 age_20_29 age_30_39 age_40_49 age_50_59 {
	gen `v'_shr = `v'/population*100
}
rename population county_pop
keep countyfips year county_pop *_shr

distinct countyfips
su

save "./data_clean/seer_tx.dta", replace
