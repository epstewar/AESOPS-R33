*get data
use /schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Data/tobit_analytic_29Apr25_total, clear

*output
global output /schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Results

*MME where MME ne 0
qnorm avg_total_mme if avg_total_mme > 0, title("Quantile-Quantile (Q-Q) Plot") legend(on label(1 "Weekly MME")) legend(on label(2 "Normal distribution")) graphregion(fcolor(white)) ytitle("MME by clinician-week")  xtitle("Theoretical quantiles")
graph export "$output/qqplot_mme.pdf", replace

*log MME or VME
qnorm ln_avg_total_mme if ln_avg_total_mme > 0, title("Quantile-Quantile (Q-Q) Plot") graphregion(fcolor(white)) legend(on label(1 "Log weekly MME")) legend(on label(2 "Normal distribution")) ytitle(`"Log(MME) by clinician-week"') xtitle("Theoretical quantiles")
graph export "$output/qqplot_ln_mme.pdf", replace

*check mean by letter to see which percentile cutoff is best
putexcel set "$output/trimmed_means.xlsx", modify

*total
putexcel set "/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Results/trimmed_means.xlsx", sheet(total) modify
forval i = 90(1)99 {
use /schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Data/tobit_analytic_29Apr25_total, clear
*make variables lower-case
rename *, lower
keep if post == 0
egen float pct = pctile(avg_total_mme), p(`i')
keep if avg_total_mme < pct 
tabstat avg_total_mme, by(assignment) stat(mean) save
matrix m`i' = r(Stat1), r(Stat2)
matrix colnames m`i' = :00 :01 
matrix rownames m`i' = :`i'
if `i' == 90 matrix means_rand_total = m`i'
else matrix means_rand_total = (means_rand_total \ m`i')
}
matrix list means_rand_total
putexcel A1 = matrix(means_rand_total), names

*A
putexcel set "/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Results/trimmed_means.xlsx", sheet(A) modify
forval i = 90(1)99 {
use /schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Data/tobit_analytic_29Apr25_A, clear
*make variables lower-case
rename *, lower
keep if post == 0
egen float pct = pctile(avg_total_mme), p(`i')
keep if avg_total_mme < pct 
tabstat avg_total_mme, by(assignment) stat(mean) save
matrix m`i' = r(Stat1), r(Stat2)
matrix colnames m`i' = :00 :01 
matrix rownames m`i' = :`i'
if `i' == 90 matrix means_randA = m`i'
else matrix means_randA = (means_randA \ m`i')
}
matrix list means_randA
putexcel A1 = matrix(means_randA), names

*B
putexcel set "/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Results/trimmed_means.xlsx", sheet(B) modify
forval i = 90(1)99 {
use /schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Data/tobit_analytic_29Apr25_B, clear
*make variables lower-case
rename *, lower
keep if post == 0
egen float pct = pctile(avg_total_mme), p(`i')
keep if avg_total_mme < pct 
tabstat avg_total_mme, by(assignment) stat(mean) save
matrix m`i' = r(Stat1), r(Stat2)
matrix colnames m`i' = :00 :01 
matrix rownames m`i' = :`i'
if `i' == 90 matrix means_randB = m`i'
else matrix means_randB = (means_randB \ m`i')
}
matrix list means_randB
putexcel A1 = matrix(means_randB), names

*C
putexcel set "/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Results/trimmed_means.xlsx", sheet(C) modify
forval i = 90(1)99 {
use /schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Data/tobit_analytic_29Apr25_C, clear
*make variables lower-case
rename *, lower
keep if post == 0
egen float pct = pctile(avg_total_mme), p(`i')
keep if avg_total_mme < pct 
tabstat avg_total_mme, by(assignment) stat(mean) save
matrix m`i' = r(Stat1), r(Stat2)
matrix colnames m`i' = :00 :01 
matrix rownames m`i' = :`i'
if `i' == 90 matrix means_randC = m`i'
else matrix means_randC = (means_randC \ m`i')
}
matrix list means_randC
putexcel A1 = matrix(means_randC), names