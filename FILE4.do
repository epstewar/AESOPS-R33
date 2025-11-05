/**********************************************************************************************************************************************
**GOALS
***1. Get mixed left-censored coefficients for primary outcome, mean clinician-weekly MME, and sensitivity analysis, total clinician-weekly MME
***2. Trim baseline values by 1% 
***3. Execute above analyses on all Rx types: A,B, C, A-C, AB, 'Other' and All (A-C + 'Other')
***4. Get mixed linear estimates for secondary outcome, proportion of patients w/high dose Rx per clinician-week
***5. Output all model statistics (e.g., coefficients, SE, p value) to matrices 
***********************************************************************************************************************************************/

*primary outcome
foreach n in A B C total {
use $data/tobit_analytic_29Apr25_`n', clear
rename *, lower

*change institution to numeric
gen inst_di = inst == "ALTA"

*run models
*ln_avg_total_mme is the log of average MME per-clinician, per-week 
*ln_sum_total_mme is the lof of summed MME per-clinician, per-week 
metobit ln_avg_total_mme post##assignment num_vsts inst_di || clinic_id: || prov_deid:, noestimate
matrix define b = e(b)
metobit ln_avg_total_mme post##assignment num_vsts inst_di || clinic_id: || prov_deid:, from(b) startvalues(iterate(0)) intmethod(mcaghermite)

*matrix coefficients
matrix `n'co = r(table)
matrix list `n'co
matrix `n'1 = `n'co[1..6,2]
matrix `n'2 = `n'co[1..6,3]
matrix `n'3 = `n'co[1..6,5]
matrix `n'4 = `n'co[1..6,9]
matrix `n'5 = `n'co[1..6,11..16]

*merge matrices
matrix `n'cot = `n'1, `n'2, `n'3, `n'4, `n'5
matrix colnames `n'cot = :int :post-int :arm :arm*int :arm*post-int :num_vsts :inst :constant :var(clinic) :var(clinic[presid])
matrix rownames `n'cot = coefficient SE t P-value lcl ucl 
matrix list `n'cot

*put coefficients in spreadsheet 
*output to excel 
putexcel set $output/results.xlsx, sheet(results_`n') modify
putexcel A1 = "Log average weekly MME-Tobit", bold 
putexcel A2 = matrix(`n'cot'), names nformat(number_d3) 
putexcel A3:A12 B2:G2, bold

*adjusted baseline values
keep if post == 0

*replace baseline obs. with post = 1 to get adjusted weekly value
replace post = 1

*remove outliers equal to or greater than 99th percentile
egen float pct = pctile(avg_total_mme), p(99)
keep if avg_total_mme < pct
tabstat avg_total_mme, by(assignment) stat(mean)

*save file to use for SAS 95% CI bootstrapping
save $data/est_`n', replace
}

*secondary outcome
use $data/secondary_analytic_prop, clear
rename *, lower

*change institution to numeric
gen inst_di = inst == "ALTA"
table inst_di

*mixed effects testing proportion of patients w/high dose Rx (=>50 MME) per-week, per-clinician pre-to-post between arms 
mixed prop_daily post##assignment inst_di || clinic_id: || prov_deid:

*matrix coefficients
*mixed procedure does not ouput RE variances or 95% CIs in r(table). Will input manually by hand. 
matrix hidose = r(table)
matrix list hidose
matrix hidose1 = hidose[1..6,2..3]
matrix hidose2 = hidose[1..6,5]
matrix hidose3 = hidose[1..6,9]
matrix hidose4 = hidose[1..6,11..15]

*merge matrices
matrix hidoset = hidose1, hidose2, hidose3, hidose4
matrix list hidoset
matrix colnames hidoset = :int :post-int :arm :arm*int :arm*post-int :inst :constant :var(clinic) :var(clinic[presid])
matrix rownames hidoset = coefficient SE t P-value lcl ucl 
matrix list hidoset

*marginal effects
*proportion of high dose patients at each level 
margins assignment, at(post=(0 1)) coeflegend post

*proportions at each level
matrix mest = r(table)'
matrix pre0 = mest[1,1..6]
matrix pre1 = mest[2,1..6]
matrix post0 = mest[3,1..6]
matrix post1 = mest[4,1..6]
matrix pre = pre0, pre1
matrix post = post0, post1
matrix mean = pre\post
matrix colnames mean = :0est :0SE :0Z :0pvalue :0ll :0ul :1est :1SE :1Z :1pvalue :1ll :1ul 
matrix rownames mean = pre_mean post_mean
matrix list mean

*difference in pre-to-post probs. 
*control 
lincom (_b[2._at#0bn.assignment]-_b[1bn._at#0bn.assignment])  
matrix cdiff = r(estimate)
matrix se = r(se)
matrix z = r(z)
matrix p = r(p)
matrix lb = r(lb)
matrix ub = r(ub)
matrix contdiff = cdiff, se, z, p, lb, ub
matrix colnames contdiff = :est :SE :Z :pvalue :ll :ul
matrix rownames contdiff = diff_mean
matrix list contdiff

*intervention 
lincom (_b[2._at#1.assignment]-_b[1bn._at#1.assignment]) 
matrix idiff = r(estimate)
matrix se = r(se)
matrix z = r(z)
matrix p = r(p)
matrix lb = r(lb)
matrix ub = r(ub)
matrix intdiff = idiff, se, z, p, lb, ub
matrix colnames intdiff = :est :SE :Z :pvalue :ll :ul
matrix rownames intdiff = diff_mean
matrix list intdiff

*merge diffs
matrix diffs = contdiff, intdiff
matrix list diffs

*diff-in-diff 
lincom ((_b[2._at#1.assignment]-_b[1bn._at#1.assignment]) - (_b[2._at#0bn.assignment]-_b[1bn._at#0bn.assignment]))
matrix d = r(estimate)
matrix se = r(se)
matrix z = r(z)
matrix p = r(p)
matrix lb = r(lb)
matrix ub = r(ub)
matrix did = d, se, z, p, lb, ub,.,.,.,.,.,.
matrix colnames did = :0est :0SE :0Z :0pvalue :0ll :0ul :1est :1SE :1Z :1pvalue :1ll :1ul 
matrix rownames did = diff_in_diff
matrix list did

*append all matrices 
matrix totalpat = mean\diffs\did
matrix list totalpat
 
*output secondary results to excel
putexcel set $output/results.xlsx, sheet(secondary_high_dose) modify
putexcel A1 = "Secondary analysis: prop. of patients prescribed high dose Rx (=>50 daily MME) per-week, per-clinician" I1 = "Marginal Effects", bold 
putexcel A2 = matrix(hidoset') I2 = matrix(totalpat), names nformat(number_d3) 
putexcel A3:A12 B2:G2 I3:I6 J2:U2, bold


