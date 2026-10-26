# Replication package: Abortion, Economic Hardship, and Crime

Erkmen G. Aslim, Wei Fu, Caitlin Myers, Erdal Tekin, Bingjin Xue

This package replicates the tables and figures in the main text of the paper (Tables 1-3, Figures 1-5). It starts from the cleaned Texas data in `data_clean/`. Every input comes from public sources ([Data sources](#data-sources)). The code that builds the cleaned data from the raw files is in `code/management/` for reference (the authors do not have permission to redistribute the raw data; all raw data are publicly available). 

This reposite will be updated regularly as the project progresses.

Ungated (old) version of the paper [NBER version](https://www.nber.org/papers/w34245)

## Quick start

1. Open `main.do` and change the `cd` line to the folder of this package.
2. Run `main.do` in Stata (version 18 or later). It installs the user-written packages and writes every table and figure to `result/`.

Each analysis file can also be run on its own: set the working directory to this folder and `do` the file.

## Folder structure

```
replication_clean/
├── README.md
├── main.do                  runs the analysis
├── code/
│   ├── analysis/            one do-file per table or figure
│   └── management/          how data_clean/ was built from the raw data (not run)
├── data_clean/              cleaned Texas data (see Codebook)
├── result/
│   ├── table/               csv tables
│   └── figure/              png figures
└── log/                     Stata log of main.do
```

## Software

Stata 18 or later (tested with StataNow 19.5 MP). `main.do` installs these user-written packages from SSC:

| Package | Used for |
|---|---|
| `ftools`, `reghdfe`, `ppmlhdfe` | Poisson and linear fixed-effects regressions |
| `estout` | `eststo`, `estadd`, `esttab` |
| `coefplot` | Figures 3-5 |
| `_gwtmean` | `egen wtmean()`, Figure 2 |
| `did_imputation` | Borusyak, Jaravel and Spiess (2024) estimator, Figures 4-5 |
| `eventstudyinteract`, `avar` | Sun and Abraham (2021) estimator, Figures 4-5 |
| `rif` | `rifhdreg`, Table 3, Panel B |
| `spmap` | Figure 1 map |

Results can differ slightly with other package versions.

## Tables and figures (`code/analysis/`)

| File | Paper | Input (`data_clean/`) | Output (`result/`) |
|---|---|---|---|
| `figure1.do` | Figure 1. Variation in Driving Distance to the Nearest Abortion Facility | `distance_monthly_tx.dta`, `txdb.dta`, `txcoord.dta` | `figure/figure1_panelA_trend.png`, `figure/figure1_panelB_map.png` |
| `figure2.do` | Figure 2. Crime Rates by Treatment Status, 2009-2019 | `sample_agency.dta` | `figure/figure2_panelA_property.png`, `figure/figure2_panelB_nonproperty.png` |
| `figure3.do` | Figure 3. Impact of Abortion Provider Distance on Crime by Type and Offender Characteristics | `sample_agency.dta` | `figure/figure3_panelA_type.png`, `figure/figure3_panelB_age_sex.png`, `table/figure3_estimates_up*.csv` |
| `figure4.do` | Figure 4. Dynamic Impact of Abortion Provider Distance on Property Crime | `sample_agency.dta` | `figure/figure4_panelA_poisson.png`, `figure/figure4_panelB_bjs.png`, `figure/figure4_panelC_sa.png` |
| `figure5.do` | Figure 5. Dynamic Impact of Abortion Provider Distance on Non-Property Crime | `sample_agency.dta` | `figure/figure5_panelA_poisson.png`, `figure/figure5_panelB_bjs.png`, `figure/figure5_panelC_sa.png` |
| `table1.do` | Table 1. Impact of Abortion Provider Distance on Crime, Baseline | `sample_agency.dta` | `table/table1_panelA_property.csv`, `table/table1_panelB_nonproperty.csv` |
| `table2.do` | Table 2. Impact of Abortion Provider Distance on Labor Market Outcomes | `sample_agency.dta` | `table/table2_panelA_labor_force.csv`, `table/table2_panelB_unemployment.csv` |
| `table3.do` | Table 3. Impact of Abortion Provider Distance on Financial Outcomes | `sample_agency.dta`, `sample_acs.dta` | `table/table3_panelA_income.csv`, `table/table3_panelB_income_iqr.csv`, `table/table3_panelC_debt_to_income.csv`, `table/table3_panelD_mortgage_delinquency.csv`, `table/table3_panelE_evictions.csv` |

`figure1.do` also writes the city label file `data_clean/txcities.dta` for the map.

Column layout of the table csv files (same as the paper):

- (1)-(2) 25 miles, (3)-(4) 50 miles, (5)-(6) 100 miles.
- In each pair, the first column has no covariates and the second adds the county demographics.
- Rows:
  - the treatment coefficient and its standard error;
  - for Poisson models, the average marginal effect (AME) and its standard error;
  - N;
  - the mean outcome of the treated group before treatment (`E[Y|Pre, Treat]`).

Tables 2 and 3 (except Table 3, Panel B) collapse `sample_agency.dta` to county x year inside the do-file.

## Codebook (`data_clean/`)

### `sample_agency.dta`: agency x year analysis sample

Texas law enforcement agencies, 2009-2019. 7,953 observations: 723 agencies x 11 years. Identified by `orin year`. To be included, an agency must, in every one of the 11 years:

- cover some population;
- report all 12 months;
- not have its crimes reported by another agency.

County variables are merged on the agency's county.

| Variable | Description | Source |
|---|---|---|
| `ori` | agency ORI (7 characters) | UCR |
| `orin` | agency id (1-723) | |
| `countyfips` | county FIPS code | UCR |
| `year` | year | |
| `agency_population` | agency covered population | UCR |
| `index_property` | property crime: burglary + larceny-theft + motor vehicle theft | UCR |
| `nonproperty` | non-property crime: murder + rape + robbery + aggravated assault + simple assault | UCR |
| `index_property_r`, `nonproperty_r` | crimes per 10,000 agency covered population | UCR |
| `actual_burg_total`, `actual_theft_total`, `actual_mtr_theft` | burglary, larceny-theft, motor vehicle theft | UCR |
| `actual_robbery_total` | robbery | UCR |
| `violent_other` | murder + rape + aggravated assault | UCR |
| `assault_simple` | simple assault | UCR |
| `property_fe_juv`, `property_fe_adult`, `property_m_juv`, `property_m_adult` | property crime arrests (burglary, larceny-theft, motor vehicle theft), women/men, under 18/18 and over; missing if the agency did not report arrests for all 12 months (6,445 non-missing) | UCR arrests |
| `county_pop` | county population | SEER |
| `white_shr`, `black_shr`, `nonhispan_shr` | county share white, black, non-Hispanic (%) | SEER |
| `age_15_44_f_shr` | county share women aged 15-44 (%) | SEER |
| `age_le9_shr`, `age_10_19_shr`, `age_20_29_shr`, `age_30_39_shr`, `age_40_49_shr`, `age_50_59_shr` | county share by age group (%) | SEER |
| `num_labor_force` | county labor force | BLS LAUS |
| `unemprate` | county unemployment rate (%) | BLS LAUS |
| `pc_inc` | county per capita personal income, 2010 dollars (CPI-U) | BEA |
| `debt_to_inc_ub` | county household debt-to-income ratio, upper bound, fourth quarter (7,590 non-missing) | Federal Reserve |
| `delinquent_90plus` | county share of mortgages 90 or more days delinquent (%), yearly mean (3,091 non-missing) | CFPB |
| `filings_observed` | county eviction filings, through 2018 (6,774 non-missing) | Eviction Lab |
| `td` | yearly mean travel distance to the nearest abortion facility (miles) | Myers |
| `up25`, `up50`, `up100` | treatment: 1 from the first year `td` rises by at least 25, 50 or 100 miles over the previous year | Myers |
| `tgroup_up25`, `tgroup_up50`, `tgroup_up100` | first treated year (0 = never treated) | |
| `t_sample_up25`, `t_sample_up50`, `t_sample_up100` | county ever has a 25-, 50- or 100-mile rise (treatment group) | |
| `t_sample_0` | control group: county distance never rises by 25 miles | |
| `t_sample_lab` | group label: 0 control, 25, 50, 100 (largest rise) | |

The five McAllen-area counties had only a temporary closure, so they are coded as control in all treatment variables. The counties are Cameron (48061), Hidalgo (48215), Starr (48427), Willacy (48489) and Zapata (48505).

### `sample_acs.dta`: ACS person x year sample (Table 3, Panel B)

ACS 1-year samples, 2009-2019. Texas residents aged 15-44 who are not in group quarters and live in identifiable counties. 769,964 observations, identified by `year serial pernum`.

| Variable | Description |
|---|---|
| `year`, `serial`, `pernum` | survey year, household serial number, person number (IPUMS) |
| `perwt` | person weight |
| `incearn_2010` | total personal earned income, 2010 dollars (IPUMS `incearn_cpiu_2010`) |
| `countyfips` | county FIPS code |
| `white`, `black`, `nonhispan` | race and Hispanic origin indicators |
| `female_fertage` | woman aged 15-44 |
| `age_le9`, `age_10_19`, `age_20_29`, `age_30_39`, `age_40_49`, `age_50_59` | age group indicators |
| `up25`, `up50`, `up100`, `tgroup_*`, `t_sample_*` | county treatment and group variables, defined as in `sample_agency.dta` |

### `distance_monthly_tx.dta`: county x month travel distance (Figure 1)

Texas counties, January 2009-December 2025. 50,800 observations, identified by `countyfips ym`.

| Variable | Description |
|---|---|
| `countyfips` | county FIPS code |
| `year`, `month`, `ym` | year, month, year-month (`%tm`) |
| `td` | travel distance to the nearest abortion facility on the first day of the month (miles) |
| `pop_female_fertage` | county population of women aged 15-44 (weight for Figure 1, Panel A) |

### `txdb.dta`, `txcoord.dta`: Texas county map (Figure 1, Panel B)

Converted from the TxDOT county boundaries shapefile with `shp2dta, genid(id) gencentroids(c)`.

| File | Variables |
|---|---|
| `txdb.dta` | one row per county (254): `id` map id, `x_c`/`y_c` centroid, `CNTY_FIPS` county FIPS code (string), `CNTY_NM` county name |
| `txcoord.dta` | polygon coordinates: `_ID` (= `id`), `_X`, `_Y` |

## Data sources

The cleaned data were built from these public sources by the files in `code/management/`, which read the raw files from `data_raw/` (not included).

| Source | Used for |
|---|---|
| FBI Uniform Crime Reporting Program, Offenses Known and Clearances by Arrest, yearly 1960-2020, concatenated by Jacob Kaplan (openICPSR 100707) | crime outcomes, agency population, sample |
| FBI Uniform Crime Reporting Program, Arrests by Age, Sex, and Race, yearly 1974-2021, concatenated by Jacob Kaplan (openICPSR 102263) | property crime arrests by sex and age (Figure 3, Panel B) |
| SEER U.S. county population estimates, 1990-2024, 19 age groups, 4 expanded races by Hispanic origin (https://seer.cancer.gov/popdata/) | county population and demographic covariates |
| Myers Abortion Facility Database, county x month travel distance to the nearest abortion facility, July 2025 version (Myers 2025) | travel distance and treatment |
| BLS Local Area Unemployment Statistics, county annual averages (https://www.bls.gov/lau/) | Table 2 |
| BEA, CAINC1 county personal income (https://apps.bea.gov/regional/) | Table 3, Panel A |
| Federal Reserve, Enhanced Financial Accounts, household debt-to-income ratio by county (https://www.federalreserve.gov/releases/z1/dataviz/household_debt/) | Table 3, Panel C |
| CFPB, Mortgage Performance Trends, county share of mortgages 90 or more days delinquent (https://www.consumerfinance.gov/data-research/mortgage-performance-trends/) | Table 3, Panel D |
| Eviction Lab, county court-issued eviction records 2000-2018 (Gromis et al. 2022, PNAS; https://evictionlab.org) | Table 3, Panel E |
| IPUMS USA, American Community Survey 1-year samples 2009-2019 (Ruggles et al., https://usa.ipums.org) | Table 3, Panel B |
| Texas Department of Transportation, Texas county boundaries shapefile | Figure 1, Panel B |

## Run time

About 11 minutes with StataNow 19.5 MP on a Mac. The event-study estimators in Figures 4-5 and the RIF regressions in Table 3 take most of the time.
