****************** Instruction ******************
* This file generates the data for the regressions used in the project. 
* It was adapted from the original replication code by Hazell et al. (2022).

clear all
set more off


****************** Step 0: Set the directory ******************

*The dataset contains these variables year state quarter mean_une statecode date constant infl_reg rp qt_bartik_sa

cd "C:/Users/Master/Desktop/econ280project"
use "data/raw/data_reg.dta", clear


****************** Step 1: Calculate present values ******************
* The point here is to compute the PV approach for unemployment and prices. We do this for a benchmark value of beta = 0.99, and robustness values beta = 0.9, 0.95. The variables rp_sum_* and u_sum_* contain the outcome.

* Set value of beta
global beta 0.99


* Vary truncation length
foreach truncation_length in 10 20 30 40 60 {

  * Calculate present value of unemployment
  quietly capture drop u_sum_`truncation_length'
  quietly generate u_sum_`truncation_length' = mean_une

  forvalues i = 1/`truncation_length' {

  	quietly replace u_sum_`truncation_length' = u_sum_`truncation_length' + $beta^`i'*F`i'.mean_une

  }


  * Calculate present value of relative prices. Similar procedure than for unemployment.
  quietly capture drop rp_sum_`truncation_length'
  quietly generate rp_sum_`truncation_length' = rp

  forvalues i = 1/`truncation_length' {

  	quietly replace rp_sum_`truncation_length' = rp_sum_`truncation_length' + $beta^`i'*F`i'.rp

  }

}

* Calculate present values for beta = 0.90, 0.95
foreach beta_local in 90 95 {

	local beta_local_adj = `beta_local' / 100

	quietly capture drop u_sum_20_`beta_local'
	quietly generate u_sum_20_`beta_local' = mean_une

	forvalues i = 1/20 {

		quietly replace u_sum_20_`beta_local' = u_sum_20_`beta_local' + `beta_local_adj'^`i'*F`i'.mean_une

	}
	quietly capture drop rp_sum_20_`beta_local'
	quietly generate rp_sum_20_`beta_local' = rp

	forvalues i = 1/20 {

		quietly replace rp_sum_20_`beta_local' = rp_sum_20_`beta_local' + `beta_local_adj'^`i'*F`i'.rp

	}
}


****************** Step 2: Generate Variables ******************

* Generate some useful variables. infl_reg_sign just changes the sign of inflation so that the coefficients have the sign as in the paper. infl_reg_time_agg divides by 4 because the model is written in quarterly terms and the data are 12-month inflation rates. d20_qt_bartik_sa takes 20 quarter differences of the seasonally adjusted bartik instrument. L4_* variables are 4 lags of the respective variables.

generate infl_reg_sign = -1 * infl_reg
generate infl_reg_time_agg = -1 * infl_reg / 4
generate L4_rp = L4.rp
generate L4_mean_une = L4.mean_une

* Generate variables for T = 20 and 60

generate d20_qt_bartik_sa = qt_bartik_sa - L20.qt_bartik_sa
generate L4_d20_qt_bartik_sa = L4.d20_qt_bartik_sa
generate d60_qt_bartik_sa = qt_bartik_sa - L60.qt_bartik_sa
generate L4_d60_qt_bartik_sa = L4.d60_qt_bartik_sa


****************** Step 3: Save the data ******************

save "data/analysis/data_for_regression.dta", replace
