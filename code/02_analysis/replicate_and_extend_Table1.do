****************** Instruction ******************
* This file produces and extends Table 1 in Hazell et al. (2022). 
* It was adapted from the original replication code by Hazell et al. (2022).

* Housekeeping

clear all
set more off
set matsize 800

* Install the required packages

local install_packages = "no"

if "`install_packages'" == "yes" {
ssc install reghdfe
ssc install ranktest
ssc install moremata
ssc install carryforward
ssc install ivreg2
ssc install ftools
ssc install ivreghdfe
ssc install binscatter
ssc install estout, replace

* Fix errors (Source: https://github.com/sergiocorreia/ivreghdfe/issues/50)
net install ivreghdfe, from("https://raw.githubusercontent.com/sergiocorreia/ivreghdfe/master/src/") replace
}


****************** Step 0: Set the directory ******************

cd "C:/Users/Master/Desktop/econ280project"
use "data/analysis/data_for_regression.dta", clear


****************** Step 1: Estimate Psi ******************

* The first three regressions estimate a regression of inflation on the lag of unemployment with different fixed effects. The fourth one runs an IV specification where unemployment is instrumented with the lag of the bartik instrument.

* T = 20
eststo clear

	quietly eststo: reghdfe infl_reg_sign L4.mean_une L4.rp, absorb(constant) cluster(statecode)
	quietly eststo: reghdfe infl_reg_sign L4.mean_une L4.rp, absorb(i.statecode) cluster(statecode)
	quietly eststo: reghdfe infl_reg_sign L4.mean_une L4.rp, absorb(i.statecode i.date) cluster(statecode)
	eststo: ivreghdfe infl_reg_sign (L4.mean_une = L4.d20_qt_bartik_sa) L4.rp, absorb(i.statecode i.date) cluster(statecode)

esttab, se keep(L4.mean_une)

disp("Number of observations is ")
count if !missing(infl_reg_sign) & !missing(L4.mean_une) & !missing(L4.rp)

estout using "result/psi_full_sample.tex", style(tex) keep(L4.mean_une) varlabels(L4.mean_une "$\psi$") cells(b(star fmt(%9.3f)) se(par)) stats( , fmt(%7.0f %7.1f %7.2f)) nolabel replace mlabels(none) collabels(none) stardrop(L4.mean_une)
eststo clear

* T = 60
eststo clear

	quietly eststo: reghdfe infl_reg_sign L4.mean_une L4.rp, absorb(constant) cluster(statecode)
	quietly eststo: reghdfe infl_reg_sign L4.mean_une L4.rp, absorb(i.statecode) cluster(statecode)
	quietly eststo: reghdfe infl_reg_sign L4.mean_une L4.rp, absorb(i.statecode i.date) cluster(statecode)
	eststo: ivreghdfe infl_reg_sign (L4.mean_une = L4.d60_qt_bartik_sa) L4.rp, absorb(i.statecode i.date) cluster(statecode)

esttab, se keep(L4.mean_une)

disp("Number of observations is ")
count if !missing(infl_reg_sign) & !missing(L4.mean_une) & !missing(L4.rp)

estout using "result/psi_full_sample_extended.tex", style(tex) keep(L4.mean_une) varlabels(L4.mean_une "$\psi$") cells(b(star fmt(%9.3f)) se(par)) stats( , fmt(%7.0f %7.1f %7.2f)) nolabel replace mlabels(none) collabels(none) stardrop(L4.mean_une)
eststo clear


****************** Step 2: Estimate Kappa and Lambda ******************

* Here we run regressions using the ts2sls function of Chodorow-Reich and Weiland (2019). 
* The function lets us to run 2sls regressions in samples with gaps.
* (Need to place the ado file in the repository in your Stata personal folder.)

* T = 20
quietly {

	eststo: ts2sls infl_reg_time_agg (u_sum_20 rp_sum_20 = L4_mean_une L4_rp), absorb(constant) cluster(statecode)
	eststo: ts2sls infl_reg_time_agg (u_sum_20 rp_sum_20 = L4_mean_une L4_rp), absorb(statecode) cluster(statecode)
	eststo: ts2sls infl_reg_time_agg (u_sum_20 rp_sum_20 = L4_mean_une L4_rp) i.date, absorb(statecode) cluster(statecode)
	eststo: ts2sls infl_reg_time_agg (u_sum_20 rp_sum_20 = L4_d20_qt_bartik_sa L4_rp) i.date, absorb(statecode) cluster(statecode)

}
esttab, se keep(u_sum_20 rp_sum_20)

disp("Number of observations is ")
count if !missing(infl_reg_time_agg) & !missing(L4_mean_une) & !missing(L4_rp) & !missing(u_sum_20) & !missing(rp_sum_20)

estout using "result/kappa_full_sample.tex", style(tex) keep(u_sum_20) varlabels(u_sum_20 "$\kappa$") cells(b(star fmt(%9.4f)) se(par)) stats( , fmt(%7.0f %7.1f %7.2f)) nolabel replace mlabels(none) collabels(none) stardrop(u_sum_20)
estout using "result/lambda_full_sample.tex", style(tex) keep(rp_sum_20) varlabels(rp_sum_20 "$\lambda$") cells(b(star fmt(%9.4f)) se(par)) stats( , fmt(%7.0f %7.1f %7.2f)) nolabel replace mlabels(none) collabels(none) stardrop(rp_sum_20)

eststo clear
xtset statecode date

* T = 60
quietly {

	eststo: ts2sls infl_reg_time_agg (u_sum_60 rp_sum_60 = L4_mean_une L4_rp), absorb(constant) cluster(statecode)
	eststo: ts2sls infl_reg_time_agg (u_sum_60 rp_sum_60 = L4_mean_une L4_rp), absorb(statecode) cluster(statecode)
	eststo: ts2sls infl_reg_time_agg (u_sum_60 rp_sum_60 = L4_mean_une L4_rp) i.date, absorb(statecode) cluster(statecode)
	eststo: ts2sls infl_reg_time_agg (u_sum_60 rp_sum_60 = L4_d60_qt_bartik_sa L4_rp) i.date, absorb(statecode) cluster(statecode)

}
esttab, se keep(u_sum_60 rp_sum_60)

disp("Number of observations is ")
count if !missing(infl_reg_time_agg) & !missing(L4_mean_une) & !missing(L4_rp) & !missing(u_sum_60) & !missing(rp_sum_60)

estout using "result/kappa_full_sample_extended.tex", style(tex) keep(u_sum_60) varlabels(u_sum_60 "$\kappa$") cells(b(star fmt(%9.4f)) se(par)) stats( , fmt(%7.0f %7.1f %7.2f)) nolabel replace mlabels(none) collabels(none) stardrop(u_sum_60)
estout using "result/lambda_full_sample_extended.tex", style(tex) keep(rp_sum_60) varlabels(rp_sum_60 "$\lambda$") cells(b(star fmt(%9.4f)) se(par)) stats( , fmt(%7.0f %7.1f %7.2f)) nolabel replace mlabels(none) collabels(none) stardrop(rp_sum_60)

eststo clear
xtset statecode date

