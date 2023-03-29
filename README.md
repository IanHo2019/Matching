# Matching
I first learned **matching** in 2021 spring, when I studied Econometrics at University of Wisconsin-Madison. My professor was [Harold D. Chiang](https://sites.google.com/view/haroldchiang/home), a patient, detail-oriented, young professor, whose research interests include machine learning and causal inference. In 2023 spring, it is my second time to meet matching. Thanks to Professor Chiang (and other great Econometrics professors at UW-Madison) and Professor [Guido W. Imbens](https://gsb-faculty.stanford.edu/guido-w-imbens/), I have some improved understanding of matching (especially propensity score matching).

In this repository, I will share my Stata coding for estimating propensity score and applying a matching estimator to estimating treatment effect. Comments on better coding and error corrections are welcomed. **Contact:** [ianhe2019@ou.edu](mailto:ianhe2019@ou.edu?subject=[GitHub]%20Matching).

## "psmatch2" versus "teffects psmatch"
There are two popular commands in Stata for propensity score matching:
  1. **psmatch2** (written by [Edwin Leuven](https://leuven.economists.nl/) and [Barbara Sianesi](https://www.iza.org/people/fellows/7649/barbara-sianesi)): To use it, please install the `psmatch2` package. It by default estimates the *average treatment effect on the treated* (ATT or ATET) and uses a *probit* model to estimate propensity score. It is outdated because its estimation of standard error doesn't take into account that the propensity score is estimated instead of given/known.
  1. **teffects psmatch**: It by default estimates the *average treatment effect* (ATE) and uses a *logit* model to estimate propensity score. It was introduced in Stata 13 (no need for manual installation) for estimating treatment effects in various ways (including propensity score). Importantly, it takes into account the fact that propensity scores are estimated when estimating standard errors, due to [Abadie & Imbens (2012)](https://www.jstor.org/stable/43866448).
  
More differences are summarized in the following table.

| | psmatch2 | teffects psmatch |
| :--- | :--- | :--- |
| Installation | `psmatch2` | no need |
| Default estimate | ATT (or ATET) | ATE |
| Model for estimating PS | probit | logit |
| Estimating s.e. | incorrect | correct |
| Default number of tied neighbors | one | all |
| Weighting variable | automatically generate | no |
| Control unit(s) indicator | no | `gen(match)` option |

One suggestion: If a propensity score matching model can be done using both `teffects psmatch` and `psmatch2`, then
  * to get the correct standard error, use `teffects psmatch`;
  * to get a variable for weighting, use `psmatch2`.

`teffects` actually is a powerful command not only designed to do propensity score matching. It has totally six subcommands:
  * `teffects psmatch` for propensity score matching, which is my focus here;
  * `teffects ra` for regression adjustment;
  * `teffects ipw` for inverse probability weighting (IPW);
  * `teffects aipw` for augmented IPW, also called "doubly robust";
  * `teffects ipwra` for IPW regression adjustment;
  * `teffects nnmatch` for nearest neighbor matching.

For greater details, please read Stata documentation (which you can find by running `help teffects` in Stata).

Also, please take a look at my do file (here) for examples. I used the two commands (`psmatch2` and `teffects psmatch`) with a pseudo dataset from Social Science Computing Cooperative at University of Wisconsin-Madison. Note that in the dataset,
  * probability of getting treated, $Pr(t=1)$, is positively correlated with `x1` and `x2`.
  * Both `x1` and `x2` are positively correlated with `y`.

## Propensity Score Estimation Method from [Imbens & Rubin (2015)](https://www.cambridge.org/core/books/causal-inference-for-statistics-social-and-biomedical-sciences/71126BE90C58F1A431FE9B2DD07938AB)
To be continued...
