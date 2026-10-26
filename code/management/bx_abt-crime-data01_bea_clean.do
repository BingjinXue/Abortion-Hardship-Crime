*-------------------------------------------------------
* project: Abortion and Crime
*-------------------------------------------------------

local pgm  "bx_abt-crime-data01_bea_clean" // file name
local who  "Ben Xue"            // author
local dte  "2026-10-26"            // created date
local dte2 "`c(current_date)'"     // last run date
local tag  "`pgm'.do, created by `who' on `dte', last run on `dte2'"
display "`tag'"

/*
This file cleans BEA county per capita personal income (CAINC1), Texas, 2009-2019, in 2010 dollars.
Input:  ./data_raw/BEA/CAINC1_TX_1969_2019.csv
Output: ./data_clean/bea_tx.dta (county x year)
*/

import delimited using "./data_raw/BEA/CAINC1_TX_1969_2019.csv", clear
gen countyfip = substr(geofips, 3, 5)
drop in -4/l // footnotes
destring countyfip, gen(countyfips)

* keep per capita personal income
keep if description == "Per capita personal income (dollars) 2/"
drop if geoname=="Texas" //drop aggregate row

* renane vars
forvalues i=9/59 {
	ren v`i' pc_inc`=1960+`i''
}

keep countyfips pc_inc*
reshape long pc_inc, i(countyfips) j(year)
keep if inrange(year, 2009, 2019)

*cpi
/*
https://fred.stlouisfed.org/series/CPIAUCSL#
U.S. Bureau of Labor Statistics, Consumer Price Index for All Urban Consumers: All Items in U.S. City Average [CPIAUCSL], retrieved from FRED, Federal Reserve Bank of St. Louis; https://fred.stlouisfed.org/series/CPIAUCSL, July 5, 2025.
Consumer Price Index for All Urban Consumers: All Items in U.S. City Average, Index 1982-1984=100, Seasonally Adjusted (CPIAUCSL)
*/
gen cpi = .
replace cpi=214.565 if year==2009
replace cpi=218.076 if year==2010
replace cpi=224.923 if year==2011
replace cpi=229.586 if year==2012
replace cpi=232.952 if year==2013
replace cpi=236.715 if year==2014
replace cpi=237.002 if year==2015
replace cpi=240.005 if year==2016
replace cpi=245.121 if year==2017
replace cpi=251.100 if year==2018
replace cpi=255.653 if year==2019
assert !missing(cpi)

// 2010 dollars
replace pc_inc = pc_inc/cpi*218.076
drop cpi
su pc_inc

save "./data_clean/bea_tx.dta", replace
