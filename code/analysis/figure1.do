clear all

*-------------------------------------------------------
* project: Abortion and Crime
*-------------------------------------------------------

local pgm  "figure1" // file name
local who  "Ben Xue"            // author
local dte  "2026-10-26"            // created date
local dte2 "`c(current_date)'"     // last run date
local tag  "`pgm'.do, created by `who' on `dte', last run on `dte2'"
display "`tag'"

/*
Figure 1. Variation in Driving Distance to the Nearest Abortion Facility
 Panel A: average county travel distance on the first day of each quarter, 2009-2019, weighted by the county population
          of women aged 15-44
 Panel B: change in travel distance between July 1, 2013 and July 1, 2014, by county
Output: ./result/figure/figure1_panelA_trend.png
        ./result/figure/figure1_panelB_map.png
*/

**************************
**# Panel A. Statewide trend in average distance
**************************
use "./data_clean/distance_monthly_tx.dta", clear
keep if inrange(year, 2009, 2019)
keep if inlist(month, 1, 4, 7, 10) // first day of each quarter

// weighted by the county population of women aged 15-44
collapse (mean) td [aw=pop_female_fertage], by(year month)
gen yq = yq(year, (month+2)/3)
format yq %tq
list year month td, sep(4)

twoway (line td yq, lc("23 55 83") lw(thick)), ///
	ytitle("Distance (miles)") xtitle("") ///
	xlabel(`=yq(2009,3)'(4)`=yq(2019,3)', format(%tqCCYY) noticks nogrid) xtick(`=yq(2009,1)'(4)`=yq(2020,1)', tlength(*3)) ///
	ylabel(20(10)50, angle(0) nogrid) ///
	legend(off) graphregion(color(white)) plotregion(color(white))
graph export "./result/figure/figure1_panelA_trend.png", replace width(1500)

**************************
**# Panel B. Changes in distance, July 1, 2013 to July 1, 2014
**************************
* Texas county map: ./data_clean/txdb.dta and ./data_clean/txcoord.dta, converted from the TxDOT county shapefile with
* shp2dta using "County.shp", database("txdb") coordinates("txcoord") genid(id) gencentroids(c)
* (txdb keeps id x_c y_c CNTY_FIPS CNTY_NM)

* change in distance
use "./data_clean/distance_monthly_tx.dta", clear
keep if inlist(ym, ym(2013,7), ym(2014,7))
keep countyfips ym td
reshape wide td, i(countyfips) j(ym)
gen td_change = td`=ym(2014,7)' - td`=ym(2013,7)'
su td_change, detail
tempfile change
save `change'

use "./data_clean/txdb", clear
gen countyfips = real(CNTY_FIPS)
merge 1:1 countyfips using `change', keep(master match) nogen

* city labels at the centroid of the city's county
preserve
gen city = ""
replace city = "El Paso" if countyfips == 48141
replace city = "Lubbock" if countyfips == 48303
replace city = "Midland" if countyfips == 48329
replace city = "San Angelo" if countyfips == 48451
replace city = "Dallas" if countyfips == 48113
replace city = "Waco" if countyfips == 48309
replace city = "Bryan" if countyfips == 48041
replace city = "Austin" if countyfips == 48453
replace city = "Houston" if countyfips == 48201
replace city = "Beaumont" if countyfips == 48245
replace city = "San Antonio" if countyfips == 48029
replace city = "Corpus Christi" if countyfips == 48355
replace city = "McAllen" if countyfips == 48215
keep if city != ""
// label position: centered above the point (Houston below, next to Beaumont)
gen x_l = x_c
gen y_l = y_c + 28000
replace y_l = y_c - 28000 if city == "Houston"
keep x_c y_c x_l y_l city
save "./data_clean/txcities.dta", replace
restore

spmap td_change using "./data_clean/txcoord", id(id) ///
	clmethod(custom) clbreaks(-1000 5 25 50 100 1000) ///
	fcolor(gs13 "158 188 218" "107 142 185" "65 105 155" "23 55 83") ///
	ocolor(gs10 ..) osize(vthin ..) ndfcolor(gs13) ///
	point(data("./data_clean/txcities") xcoord(x_c) ycoord(y_c) size(*0.6) fcolor(black)) ///
	label(data("./data_clean/txcities") xcoord(x_l) ycoord(y_l) label(city) length(14) size(*0.8) position(0) color(black)) ///
	legend(order(2 "< 5" 3 "5-25" 4 "25-50" 5 "50-100" 6 ">= 100") title("Change in distance to nearest abortion facility (miles)", size(small)) pos(6) ring(1) rows(1) size(small)) ///
	graphregion(color(white) margin(r+5))
graph export "./result/figure/figure1_panelB_map.png", replace width(1500)
