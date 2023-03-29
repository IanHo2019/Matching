* This do file does propensity score matching (PSM) estimations in Stata, by the "psmatch2" and "teffects" commands with a pseudo dataset from Social Science Computing Cooperative at University of Wisconsin-Madison.
* Author: Ian He
* Date: Mar 28, 2023
***********************************************************************

clear

* File paths
global dtadir "D:\research\Propensity Score Matching\Data"



***********************************************************************
use "http://ssc.wisc.edu/sscc/pubs/files/psm", clear

label var t "treatment indicator"
label var x1 "covariate 1"
label var x2 "covariate 2"
label var y "outcome"

* Comparing the mean of y for the t=1 and t=0 groups overestimates the ATT.
ttest y, by(t) // true ATT is 1, but here the estimate is 2.31.

* A regression gives us a better picture of the situation.
reg y t x1 x2



***********************************************************************
**# Two commands for PSM

* Old method (s.e. is not adjusted)
* ssc install psmatch2, replace
psmatch2 t x1 x2, out(y) // the estimate is 1.0197 with s.e. of 0.1730.

* Modern method (s.e. is adjusted)
teffects psmatch (y) (t x1 x2, probit), atet // the estimate is 1.0197 with s.e. of 0.1228.

* The following two lines report the same coefficient estimate.
psmatch2 t x1 x2, out(y) logit ate
teffects psmatch (y) (t x1 x2)



***********************************************************************
**# Multiple Neighbors (no multiple Yang Sibal!)

* nn(#) tells Stata to match # nearest neighbors.
teffects psmatch (y) (t x1 x2), nn(2)
teffects psmatch (y) (t x1 x2), nn(3)



***********************************************************************
**# Postestimation
use "http://ssc.wisc.edu/sscc/pubs/files/psm", clear

* Generate a variable containing the row order (_n) of the observation that observation was matched with:
teffects psmatch (y) (t x1 x2), gen(match)
browse if _n==1 | _n==467 | _n==781

* "predict" with "te" option gives the treatment effect.
predict te, te
sum te			// ATE
sum te if t==1	// ATT

* "predict" with "ps" creates two variables containing propentity scores.
predict ps0 ps1, ps

* "predict" with "po" creates two variables containing potential outcomes.
predict y0 y1, po // for row 467, its y1 is observed, while its y0 is from the observation in row 781 (its nearest neighbor).



***********************************************************************
**# Regression on the Matched Sample
* Alert: The following coding is for showing how to run regressions on a matched sample; however, econometrically, this idea is very problemic.

use "http://ssc.wisc.edu/sscc/pubs/files/psm", clear

psmatch2 t x1 x2, out(y) logit
* "psmatch2" by default generates a variable for weighting (_weight), and it is missing for unmatched observations.
reg y x1 x2 t [fweight=_weight] // s.e. here is incorrect because it doesn't take into account the matching stage.


* "teffects" doesn't by default create a variable for weighting, so we have to find the weights manually.
teffects psmatch (y) (t x1 x2), gen(match) atet
gen ob_num = _n 							//store the observation numbers for future use
save "$dtadir\psm_fulldata.dta", replace	// save the complete data set

keep if t==1					// keep just the treated group
keep match1						// keep just the match1 variable (the observation orders of their matches)
bysort match1: gen weight=_N	// count how many times each control observation is a match
by match1: keep if _n==1		// keep just one row per control observation
ren match1 ob_num				// rename for merging

merge 1:m ob_num using "$dtadir\psm_fulldata.dta"	// merge back into the full data
replace weight=1 if t==1							// set weight to 1 for treated observations

assert weight==_weight	// Check: weights from two commands should be identical.

reg y x1 x2 t [fweight=weight]	// the results (both coefficient and s.e.) is the same as the regression with weights from "psmatch2"; as noted before, s.e. is incorrect!



***********************************************************************
**# Other Available Methods in teffects
teffects ra (y x1 x2) (t)			// regression adjustment
teffects ipw (y) (t x1 x2)			// inverse probability weighting (IPW)
teffects aipw (y x1 x2) (t x1 x2)	// augmented IPW
teffects ipwra (y x1 x2) (t x1 x2)	// IPW regression adjustment
teffects nnmatch (y x1 x2) (t)		// nearest neighbor matching