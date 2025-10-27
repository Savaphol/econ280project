* Code to explore the dataset used to produce the first figure in Hazell et al. (2022)
* Savaphol Hiruntiaranakul

* Housekeeping
clear all
set more off
 set matsize 800
eststo clear
clear matrix

* Set your path
cd "C:/Users/Master/Desktop/Replication_Package_Assignment2_SavapholH"

* Load the dataset
import delimited "data/raw/data_stock_watson_fred.csv", clear

* Create a histogram
hist unrate

* Save output
graph save "results/histogram_unemployment", replace
graph export "results/histogram_unemployment.pdf", replace