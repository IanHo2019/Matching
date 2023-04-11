* This do file does summary statistics and estimates propensity scores for NSW Data (Dehejia-Wahha Sample) using Imbens & Rubin (2015)'s procedure.
* Author: Ian He
* Date: Apr 8, 2023
***********************************************************************

clear all

* File paths
global localdir "D:\research\Propensity Score Matching"

global dtadir "$localdir\Data"
global tabdir "$localdir\Tables"



***********************************************************************
**# Summary statistics
use "$dtadir\nswre74.dta", clear

* Change earning unit to thousand dollars
local numlist = "74 75 78"
foreach n in `numlist' {
	replace re`n' = re`n'/10^3
}

* Generate indicators for unemployment
gen unempl74 = (re74==0)
gen unempl75 = (re75==0)


preserve

* Calculate summary statistics
local outlist = "black hisp age married nodeg educ re74 unempl74 re75 unempl75"

foreach var in `outlist' {
	qui{
		ttest `var', by(treat)
		local m1_`var' = `r(mu_1)'
		local sd1_`var' = `r(sd_1)'
		local m2_`var' = `r(mu_2)'
		local sd2_`var' = `r(sd_2)'
		local t_`var' = `r(t)'
		local nd_`var' = (`r(mu_2)' - `r(mu_1)')/((`r(sd_2)'^2 + `r(sd_1)'^2)/2)^0.5
	}
}
	
g labels = ""
local row = 1

* Covariate name
replace labels = " Black" in `row'
local ++row
replace labels = " Hispanic" in `row'
local ++row
replace labels = " Age" in `row'
local ++row
replace labels = " Married" in `row'
local ++row
replace labels = " No degree" in `row'
local ++row
replace labels = " Education" in `row'
local ++row
replace labels = " Earning74" in `row'
local ++row
replace labels = " Uemployed74" in `row'
local ++row
replace labels = " Earning75" in `row'
local ++row
replace labels = " Uemployed75" in `row'
local ++row

* Input values in a table
foreach var in m1 sd1 m2 sd2 t nd {
	qui{
		local row = 1
		if "`var'"=="t" {
			local decimal = 1
		}
		else{
			local decimal = 2
		}
		
		g `var' = ""
		replace `var' = string(``var'_black', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_hisp', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_age', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_married', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_nodeg', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_educ', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_re74', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_unempl74', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_re75', "%12.`decimal'f") in `row'
		local ++row
		replace `var' = string(``var'_unempl75', "%12.`decimal'f") in `row'
		local ++row
	}
}


* Construct a tabular in LaTeX
	*Tab begin
		g tab = "\begin{tabular}{l*{6}{r}}" in 1
	*Title
		g panel = " & \multicolumn{2}{c}{Controls} & \multicolumn{2}{c}{Trainees} & & " in 1
		g titlerow = "Covariate & Mean & Std Dev & Mean & Std Dev & \textit{t}-stat & Nor Diff" in 1
	*hline
		g hline = "\hline" in 1
	*Tab end
		g end = "\end{tabular}" in 1


	* Design a table: install "listtex" package
	listtex tab if _n == 1 using "$tabdir/NSW_summary_stat.tex", replace rstyle(none)
	listtex hline if _n == 1, appendto("$tabdir/NSW_summary_stat.tex") rstyle(none)
	listtex hline if _n == 1, appendto("$tabdir/NSW_summary_stat.tex") rstyle(none)
	listtex panel if _n==1, appendto("$tabdir/NSW_summary_stat.tex") rstyle(tabular)
	listtex titlerow if _n==1, appendto("$tabdir/NSW_summary_stat.tex") rstyle(tabular)
	listtex hline if _n == 1, appendto("$tabdir/NSW_summary_stat.tex") rstyle(none)
	listtex labels m1 sd1 m2 sd2 t nd if _n<=10, appendto("$tabdir/NSW_summary_stat.tex") rstyle(tabular)
	listtex hline if _n == 1, appendto("$tabdir/NSW_summary_stat.tex") rstyle(none)
	listtex hline if _n == 1, appendto("$tabdir/NSW_summary_stat.tex") rstyle(none)
	listtex end if _n == 1, appendto("$tabdir/NSW_summary_stat.tex") rstyle(none)

restore



***********************************************************************
**# Estimate propensity scores
psestimate treat re74 re75 unempl74 unempl75, notry(re78) genps(pscore)
return list, all

* Propensity score calculated below should be the same as above.
eststo est_ps: logit `r(tvar)' `r(h)'
predict pscore_hat, pr

estout est_ps, ///
	varlabels(_cons "Constant") ///
	coll(none) cells(b(nostar fmt(2)) se(par fmt(2)))


	***********************************************************************
**# Estimate ATE
sum pscore, detail

eststo est_ate1: teffects psmatch (re78) (treat re74 re75 unempl74 unempl75 nodeg hisp educ c.educ#c.nodeg c.nodeg#c.re74 c.educ#c.unempl75), atet vce(r)

* Cutoff values from Imbens (2015)
drop if pscore < 0.1299
drop if pscore > 0.8701

eststo est_ate2: teffects psmatch (re78) (treat re74 re75 unempl74 unempl75 nodeg hisp educ c.educ#c.nodeg c.nodeg#c.re74 c.educ#c.unempl75), atet vce(r)

estout est_ate*, ///
	varlabels(_cons "Constant") ///
	coll(none) cells(b(star fmt(4)) se(par fmt(4))) ///
	stats(N, labels("Observations") fmt("%9.0fc"))
