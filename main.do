*-------------------------------------------------------
* project: Abortion and Crime
*-------------------------------------------------------
version 18
clear all

local pgm  "main" // file name
local who  "Ben Xue"            // author
local dte  "2026-10-26"            // created date
local dte2 "`c(current_date)'"     // last run date
local tag  "`pgm'.do, created by `who' on `dte', last run on `dte2'"

/*
This is the main do file: it replicates the tables and figures in the main text of
"Abortion, Economic Hardship, and Crime" (Aslim, Fu, Myers, Tekin, Xue), starting from the cleaned Texas data in ./data_clean/.
--- before you start
set working directory, replace the string after the cd command
execute this do file
*/

**# set working directory here
cd "/Users/benxue/Dropbox/research/paper/Abortion-Crime-test/replication_clean/"

capture log close
log using "./log/main.log", replace text
display "`tag'"

*********************************
**# 00 - install necessary packages
*********************************
cap ssc install ftools
cap ssc install reghdfe
cap ssc install ppmlhdfe
cap ssc install estout           // eststo / esttab / estadd
cap ssc install coefplot
cap ssc install _gwtmean         // egen wtmean(), Figure 2
cap ssc install did_imputation   // BJS estimator
cap ssc install eventstudyinteract // Sun and Abraham estimator
cap ssc install avar             // required by eventstudyinteract
cap ssc install rif              // rifhdreg, Table 3 Panel B
cap ssc install spmap            // Figure 1 map

*********************************
**# 01 - data clean (raw data not included; the cleaned data are in ./data_clean/, see README.md)
*********************************
/*
do "./code/management/bx_abt-crime-data01_ucr_offense_clean.do"   // UCR offenses known, agency x year
do "./code/management/bx_abt-crime-data01_ucr_arrest_clean.do"    // UCR property crime arrests by sex and age, agency x year
do "./code/management/bx_abt-crime-data01_seer_clean.do"          // SEER county population and demographics
do "./code/management/bx_abt-crime-data01_labor_market_clean.do"  // BLS LAUS labor force and unemployment rate
do "./code/management/bx_abt-crime-data01_bea_clean.do"           // BEA per capita personal income
do "./code/management/bx_abt-crime-data01_debt_clean.do"          // Federal Reserve debt-to-income ratio
do "./code/management/bx_abt-crime-data01_mortgage_clean.do"      // CFPB mortgage delinquency
do "./code/management/bx_abt-crime-data01_eviction_clean.do"      // Eviction Lab eviction filings
do "./code/management/bx_abt-crime-data01_distance_clean.do"      // Myers travel distance and treatment
do "./code/management/bx_abt-crime-data01_acs_clean.do"           // ACS persons aged 15-44
do "./code/management/bx_abt-crime-data02_sample_agency.do"       // agency x year analysis sample
do "./code/management/bx_abt-crime-data03_sample_acs.do"          // ACS analysis sample
*/

*********************************
**# 02 - tables and figures
*********************************
do "./code/analysis/figure1.do"
do "./code/analysis/figure2.do"
do "./code/analysis/figure3.do"
do "./code/analysis/figure4.do"
do "./code/analysis/figure5.do"
do "./code/analysis/table1.do"
do "./code/analysis/table2.do"
do "./code/analysis/table3.do"

log close
