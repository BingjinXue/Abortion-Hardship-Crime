*-------------------------------------------------------
* project: Abortion and Crime
*-------------------------------------------------------

local pgm  "bx_abt-crime-data01_mortgage_clean" // file name
local who  "Ben Xue"            // author
local dte  "2026-10-26"            // created date
local dte2 "`c(current_date)'"     // last run date
local tag  "`pgm'.do, created by `who' on `dte', last run on `dte2'"
display "`tag'"

/*
This file cleans the county share of mortgages 90 or more days delinquent (CFPB), Texas, 2009-2019 (yearly mean of
the monthly shares).
Input:  ./data_raw/CFPB_mortgage_delinquency/CountyMortgagesPercent-90-plusDaysLate-thru-2023-12.csv
Output: ./data_clean/delinquent_90plus_tx.dta (county x year)
*/

insheet using "./data_raw/CFPB_mortgage_delinquency/CountyMortgagesPercent-90-plusDaysLate-thru-2023-12.csv", clear
gen countyfips = substr(fipscode,2,5)
drop in 1
drop fipscode
drop regiontype
destring countyfips, replace
keep if floor(countyfips/1000) == 48 //!!!!!!!!!!!

reshape long v, i(county) j(monthcount)

// first monthcount = 5 stands for 2008 1
gen start = monthly("2008/1","YM")
gen monthly = start+monthcount-5
format monthly %tm
gen year = year(dofm(monthly))
gen month= month(dofm(monthly))

keep if inrange(year,2009,2019)

// collapse by year
collapse v, by(countyfips year)

ren v delinquent_90plus
su delinquent_90plus

save "./data_clean/delinquent_90plus_tx.dta", replace
