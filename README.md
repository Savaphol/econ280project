# Repository for Econ 280 Project

This repository contains files replicating the results extended from Hazell et al. (2022). 
1.	create_data.do generates data needed for regression using data_reg.dta which was provided by the authors. The new data is saved as data_for_regression.dta.
2.	replicate_and_extend_Table1.do is the main file containing the code that loads the above data to replicate and extend the result in Table 1 in Hazell et al. (2022). 
3.	Note that the above code performs the two-sample two-stage least squares as in Chodorow-Reich and Wieland (2019) and requires the user to copy and paste the .ado and the helper files in their Stata personal directory.
4.	The regression results were saved in the result folder.
