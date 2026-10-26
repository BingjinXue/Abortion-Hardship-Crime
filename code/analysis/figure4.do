clear all

*-------------------------------------------------------
* project: Abortion and Crime
*-------------------------------------------------------

local pgm  "figure4" // file name
local who  "Ben Xue"            // author
local dte  "2026-10-26"            // created date
local dte2 "`c(current_date)'"     // last run date
local tag  "`pgm'.do, created by `who' on `dte', last run on `dte2'"
display "`tag'"

/*
Figure 4. Dynamic Impact of Abortion Provider Distance on Property Crime
 Panel A: Poisson event study (crime counts)
 Panel B: Borusyak, Jaravel and Spiess (2024) imputation estimator (crime rates)
 Panel C: Sun and Abraham (2021) estimator (crime rates)
All with county demographics, on the Table 1 estimation sample (columns 2, 4, 6).
Output: ./result/figure/figure4_panelA_poisson.png
        ./result/figure/figure4_panelB_bjs.png
        ./result/figure/figure4_panelC_sa.png
*/

use "./data_clean/sample_agency.dta", clear
xtset orin year

* covariates
global x white_shr black_shr nonhispan_shr age_15_44_f_shr age_le9_shr age_10_19_shr age_20_29_shr age_30_39_shr age_40_49_shr age_50_59_shr

* estimation sample of Table 1
foreach T in up25 up50 up100 {
	foreach v in index_property {
		qui ppmlhdfe `v'  `T'  $x if (t_sample_0==1 | t_sample_`T' == 1) , absorb(orin year ) vce(cluster countyfips) d exp(agency_population)
		gen sample_`T'_`v' = e(sample)
		tab sample_`T'_`v'
	}
}

*********************
**# Poisson Event Study
*********************
global plot_opts omit keep(e*) vert mc(gs0)  xline(5, lp(dash)) yline(0, lc(gs5) ) xtitle("Years to Treatment") ytitle("ATT") coeflabels(em5="<=-5" em4="-4" em3 = "-3" em2 = "-2" em1 = "-1" e0 ="0" e1 = "1" e2 = "2" e3 = "3" e4 = "4" e5 = ">=5" ) levels(95) graphregion(color(white))

estimates clear
eststo clear
foreach T in up25 up50 up100 {
	capture drop rel_`T' g_`T'
	capture drop em5 em4 em3 em2 em1 e0 e1 e2 e3 e4 e5

    * First treatment year
    bysort orin (year): egen g_`T' = min(cond(`T'==1, year, .))

	* relative/event time
	gen rel_`T' = year - g_`T'

    * Leads
    gen em5 = rel_`T' <= -5
    gen em4 = rel_`T' == -4
    gen em3 = rel_`T' == -3
    gen em2 = rel_`T' == -2

    * -1 omitted
	gen em1=0

    * Treatment/post
    gen e0 = rel_`T' == 0
    gen e1 = rel_`T' == 1
    gen e2 = rel_`T' == 2
    gen e3 = rel_`T' == 3
    gen e4 = rel_`T' == 4
    gen e5 = rel_`T' >= 5

	foreach v in index_property {
		ppmlhdfe `v' em5 em4 em3 em2 em1 e0 e1 e2 e3 e4 e5 $x if sample_`T'_`v'==1, absorb(orin  year) vce(cluster countyfips) d exp(agency_population)
		estimates store `v'_`T'
	}
}

foreach v in index_property {
	coefplot (`v'_up25, label("25 miles")  msymbol(O)) (`v'_up50, label("50 miles") msymbol(T)) (`v'_up100, label("100 miles") msymbol(S)), $plot_opts
	graph export "./result/figure/figure4_panelA_poisson.png", replace width(1500)
}

*******************
**# BJS
*******************
global plot_optsbjs omit keep(pre4 pre3 pre2 pre1 tau0 tau1 tau2 tau3 tau4 tau5) order(pre4 pre3 pre2 pre1 tau0 tau1 tau2 tau3 tau4 tau5) vert mc(gs0)  xline(5, lp(dash)) yline(0, lc(gs5) ) xtitle("Years to Treatment") ytitle("ATT") coeflabels(pre6="-6" pre5="-5" pre4="-4" pre3 = "-3" pre2 = "-2" pre1 = "-1" tau0 ="0" tau1 = "1" tau2 = "2" tau3 = "3" tau4 = "4" tau5 = "5" tau6 = "6") levels(95)  graphregion(color(white))

estimates clear
eststo clear
foreach T in up25 up50 up100 {
	capture drop tgroup_`T'_m
	gen tgroup_`T'_m = tgroup_`T'
	replace tgroup_`T'_m = . if tgroup_`T' == 0
	/* did_imputation requires setting the never treated group to missing*/

	foreach v in index_property {
		did_imputation `v'_r orin year tgroup_`T'_m [aw=agency_population] if sample_`T'_`v'==1 , c($x ) clus(countyfips) tol(10e-4) maxit(3000) hor(0/5) pretrend(5) autosample minn(10)
		estimates store `v'_`T'
	}
}

foreach v in index_property {
	coefplot (`v'_up25, label("25 miles")  msymbol(O)) (`v'_up50, label("50 miles") msymbol(T)) (`v'_up100, label("100 miles") msymbol(S)), $plot_optsbjs
	graph export "./result/figure/figure4_panelB_bjs.png", replace width(1500)
}

*********************
**# Sun and Abraham
*********************
estimates clear
eststo clear
foreach T in up25 up50 up100 {
	capture drop tgroup_`T'_m
	gen tgroup_`T'_m = tgroup_`T'
	replace tgroup_`T'_m = . if tgroup_`T' == 0

	capture drop rel_`T' g_`T'
	capture drop em4 em3 em2 em1 e0 e1 e2 e3 e4 e5

    * First treatment year
    bysort orin (year): egen g_`T' = min(cond(`T'==1, year, .))

	* relative/event time
	gen rel_`T' = year - g_`T'

    * Leads
    gen em4 = rel_`T' == -4
    gen em3 = rel_`T' == -3
    gen em2 = rel_`T' == -2

    * -1 omitted
	gen em1=0

    * Treatment/post
    gen e0 = rel_`T' == 0
    gen e1 = rel_`T' == 1
    gen e2 = rel_`T' == 2
    gen e3 = rel_`T' == 3
    gen e4 = rel_`T' == 4
    gen e5 = rel_`T' >= 5

	foreach v in index_property {
		eventstudyinteract `v'_r em4 em3 em2 em1 e0 e1 e2 e3 e4 e5 [pw=agency_population] if sample_`T'_`v' == 1 , cohort(tgroup_`T'_m) control_cohort(t_sample_0) absorb(orin  year) vce(cluster countyfips) covariates($x )

        matrix C = e(b_iw)
        mata st_matrix("A",sqrt(diagonal(st_matrix("e(V_iw)"))))
        matrix C_`T'_`v' = C \ A'
	}
}

foreach v in index_property {
	coefplot (matrix(C_up25_`v'[1]), se(C_up25_`v'[2]) label("25 miles")  msymbol(O)) (matrix(C_up50_`v'[1]), se(C_up50_`v'[2]) label("50 miles") msymbol(T)) (matrix(C_up100_`v'[1]), se(C_up100_`v'[2]) label("100 miles") msymbol(S)), $plot_opts
	graph export "./result/figure/figure4_panelC_sa.png", replace width(1500)
}
