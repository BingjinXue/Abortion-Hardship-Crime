clear all

*-------------------------------------------------------
* project: Abortion and Crime
*-------------------------------------------------------

local pgm  "figure2" // file name
local who  "Ben Xue"            // author
local dte  "2026-10-26"            // created date
local dte2 "`c(current_date)'"     // last run date
local tag  "`pgm'.do, created by `who' on `dte', last run on `dte2'"
display "`tag'"

/*
Figure 2. Crime Rates by Treatment Status, 2009-2019
Yearly crime rates per 10,000 population, weighted by agency covered population, for the control group and the
25-, 50- and 100-mile treatment groups.
Output: ./result/figure/figure2_panelA_property.png
        ./result/figure/figure2_panelB_nonproperty.png
*/

use "./data_clean/sample_agency.dta", clear

* trend in outcome rates
foreach v in index_property nonproperty {
	preserve
	// population weights
	foreach s in 0 up25 up50 up100 {
		gen w_`s' = t_sample_`s' * agency_population
	}

	// yearly average outcomes for each sample
	egen avg_`v'_0 = wtmean(`v'_r), weight(w_0) by(year)
	egen avg_`v'_25 = wtmean(`v'_r), weight(w_up25) by(year)
	egen avg_`v'_50 = wtmean(`v'_r), weight(w_up50) by(year)
	egen avg_`v'_100 = wtmean(`v'_r), weight(w_up100) by(year)

	// gen figure
	collapse (first) avg_`v'_*, by(year)
	list
	if "`v'" ==  "index_property" { // plot range
		local min =  200
		local max =  450
		local panel = "A_property"
	}
	else {
		local min =  100
		local max =  250
		local panel = "B_nonproperty"
	}

	twoway ///
	(connected avg_`v'_0 year, lp(solid) lc(k) mc(k) msymbol(Oh) lw(thick)) ///
	(connected avg_`v'_25 year, msymbol(O) lc("31 119 180") mc("31 119 180") ) ///
	(connected avg_`v'_50 year, msymbol(T) lc("214 39 40") mc("214 39 40")) ///
	(connected avg_`v'_100 year , msymbol(S) lc("44 160 44") mc("44 160 44") ), ///
	legend(order(1 "Control" 2 "Treated 25 miles" 3 "Treated 50 miles" 4 "Treated 100 miles") pos(6) col(4)) ///
	xline(2012.6, lp(dash)) ///
	ytitle("Population Weighted Crime Rate per 10,000") ///
	ylabel(`min'(50)`max') ///
	xtitle("Year")  ///
	graphregion(color(white))  ///
	xlabel(#11, angle(45))
	graph export "./result/figure/figure2_panel`panel'.png", replace width(1500)
	restore
}
