*-------------------------------------------------------
* project: Abortion and Crime
*-------------------------------------------------------

local pgm  "bx_abt-crime-data01_eviction_clean" // file name
local who  "Ben Xue"            // author
local dte  "2026-10-26"            // created date
local dte2 "`c(current_date)'"     // last run date
local tag  "`pgm'.do, created by `who' on `dte', last run on `dte2'"
display "`tag'"

/*
This file cleans the county number of eviction filings (Eviction Lab, court-issued records), Texas, 2009-2018.
Input:  ./data_raw/Eviction-PNAS/county_court-issued_2000_2018.csv
Output: ./data_clean/eviction_tx.dta (county x year)
*/

insheet using "./data_raw/Eviction-PNAS/county_court-issued_2000_2018.csv", clear
rename fips_county countyfips
keep if fips_state == 48 //!!!!!!!!!!!
keep if inrange(year, 2009, 2019)

keep countyfips year filings_observed
su filings_observed

save "./data_clean/eviction_tx.dta", replace
