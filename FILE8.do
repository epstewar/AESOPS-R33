

*directory info.
include setup.do
global log $dua/AESOPS/R33_NU/Recent_25Mar25
local dt = "`c(current_date)' `c(current_time)'"
log using "$log/Logs/results_`dt'.log"
global data $dua/AESOPS/R33_NU/Recent_25Mar25/Data

*data 
use $data/tobit_analytic_18Aug25_ABC, clear 
rename *, lower
drop wk
gen wk = week - 26
gen intxwk = 0
replace intxwk = wk if wk > 0
gen infuwk = 0
replace infuwk = wk if wk > 78
save $data/tobit_knot, replace

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
use $data/figure3, clear 
rename *, lower
predict xb, xb
predict error, stdp
save $data/figure3_predictions, replace
list 

