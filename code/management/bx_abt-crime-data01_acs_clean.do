*-------------------------------------------------------
* project: Abortion and Crime
*-------------------------------------------------------

local pgm  "bx_abt-crime-data01_acs_clean" // file name
local who  "Ben Xue"            // author
local dte  "2026-10-26"            // created date
local dte2 "`c(current_date)'"     // last run date
local tag  "`pgm'.do, created by `who' on `dte', last run on `dte2'"
display "`tag'"

/*
This file cleans the ACS person records (IPUMS USA, 1-year samples 2009-2019, Texas) used for the personal income
interquartile range (Table 3, Panel B): residents aged 15-44, not in institutional group quarters, in identifiable counties.
Input:  ./data_raw/ACS/acs.dta (IPUMS extract)
Output: ./data_clean/acs_tx.dta (person x year)
*/

use year serial pernum perwt statefip countyfip gqtype sex age race hispan incearn_cpiu_2010 using "./data_raw/ACS/acs.dta", clear

drop if countyfip==0 // drop missing values in connty fips
tostring statefip, gen(statefips) format(%02.0f)
tostring countyfip, gen(countyfip2) format(%03.0f)
egen countyfips = concat(statefips countyfip2)
destring countyfips, replace
drop countyfip2 statefips

ta year
distinct countyfips  // 38 counties
sort serial year

* restrictions
keep if inrange(age, 15, 44) // 15-44 years old
keep if gqtype==0 // not instutionalized

* demographics
gen white = race==1
replace white = . if race==.
gen black = race==2
replace black = . if race==.
gen nonhispan = hispan==0
replace nonhispan = . if hispan==. | hispan==9
gen female= sex==2
replace female = .  if sex==. | sex==9

drop if age==. | age==999
gen age_le9 = inrange(age,0,9)
gen age_10_19 = inrange(age,10,19)
gen age_20_29 = inrange(age,20,29)
gen age_30_39 = inrange(age,30,39)
gen age_40_49 = inrange(age,40,49)
gen age_50_59 = inrange(age,50,59)

gen female_fertage = (female==1) & inrange(age,15,44)
replace female_fertage = . if female==. | age==.

* income: total personal earned income, 2010 dollars
ren incearn_cpiu_2010 incearn_2010
replace incearn_2010 = . if incearn_2010 == 999999999

keep year serial pernum perwt countyfips white black nonhispan female_fertage age_le9 age_10_19 age_20_29 age_30_39 age_40_49 age_50_59 incearn_2010
compress
save "./data_clean/acs_tx.dta", replace
