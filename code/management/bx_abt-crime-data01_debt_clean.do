*-------------------------------------------------------
* project: Abortion and Crime
*-------------------------------------------------------

local pgm  "bx_abt-crime-data01_debt_clean" // file name
local who  "Ben Xue"            // author
local dte  "2026-10-26"            // created date
local dte2 "`c(current_date)'"     // last run date
local tag  "`pgm'.do, created by `who' on `dte', last run on `dte2'"
display "`tag'"

/*
This file cleans the county household debt-to-income ratio (Federal Reserve, Enhanced Financial Accounts), Texas,
2009-2019, fourth quarter of each year.
Source: https://www.federalreserve.gov/releases/z1/dataviz/household_debt/; access date 2024-09-01
Input:  ./data_raw/household-debt-by-county/household-debt-by-county.csv
Output: ./data_clean/debt_to_income_tx.dta (county x year)
*/

insheet using "./data_raw/household-debt-by-county/household-debt-by-county.csv", clear
keep if qtr == 4

rename area_fips countyfips
rename high debt_to_inc_ub // upper bound of the ratio
keep if floor(countyfips/1000) == 48 //!!!!!!!!!!!
keep if inrange(year, 2009, 2019)

keep countyfips year debt_to_inc_ub
su debt_to_inc_ub

save "./data_clean/debt_to_income_tx.dta", replace
