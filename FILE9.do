/**********************************************************************************************************************************************
**GOALS
***1. Run metobit mixed linear left-censored regression to get coefficients (intxwk*assignment & infuwk*assignment)
***2. Import fixed linear predictor levels (xb) and get adjusted log MME 
***3. Export data for Figure S4
************************************************************************************************************************************************/

*data 
use directory/tobit_analytic_18Aug25_ABC, clear 
rename *, lower

*truncated time for intervention
gen wk = week - 26
gen intxwk = 0
replace intxwk = wk if wk > 0

*truncated time for follow-up
gen infuwk = 0
replace infuwk = wk if wk > 78

*save data 
save directory/tobit_knot, replace

*check time variables 
egen tag = tag(week wk intxwk infuwk)
keep if tag == 1
list post wk intxwk infuwk

*knotted spline model
use $data/tobit_knot, clear
metobit ln_avg_total_mme c.wk c.intxwk##assignment c.infuwk##assignment || clinic_id: || prov_deid:,  noestimate
matrix define b = e(b)
metobit ln_avg_total_mme c.wk c.intxwk##assignment c.infuwk##assignment || clinic_id: || prov_deid:, from(b) startvalues(iterate(0)) intmethod(mcaghermite)

*predicted values 
use directory/figure3, clear 
rename *, lower

*adjusted log MME and standard error
predict xb, xb
predict error, stdp

*save data for FILE8.r 
save directory/figure3_predictions, replace


