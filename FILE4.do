/***********************************************************************************************************************
**GOALS
***1. Output QQ plots for Supplemental Figures S2 and S3 
***2. Run loop that trims baseline MME from 1% to 10%, increasing by 1% w/each iteration
***3. Output xlsx with trimmed baseline mean MME in each study arm for every percentage cutoff (1% to 10%)
***4. Subtract mean trimmed MME between study arms 
***5. Determine which percentage cutoff results in smallest baseline difference between study arms (we used 1%)
************************************************************************************************************************/

*import analytic data
use /directory/tobit_analytic_18Aug25_total, clear

*MME where MME ne 0
qnorm avg_total_mme if avg_total_mme > 0, title("Quantile-Quantile (Q-Q) Plot") legend(on label(1 "Weekly MME")) legend(on label(2 "Normal distribution")) graphregion(fcolor(white)) ytitle("MME by clinician-week")  xtitle("Theoretical quantiles")
graph export "/directory/qqplot_mme.pdf", replace

*log MME where log MME ne 0
qnorm ln_avg_total_mme if ln_avg_total_mme > 0, title("Quantile-Quantile (Q-Q) Plot") graphregion(fcolor(white)) legend(on label(1 "Log weekly MME")) legend(on label(2 "Normal distribution")) ytitle(`"Log(MME) by clinician-week"') xtitle("Theoretical quantiles")
graph export "/directory/qqplot_ln_mme.pdf", replace

*mean baseline MME between study arms trimmed from 1% to 10% for A-C Rx types
foreach rx in A B C ABC total {
	
putexcel set "/directory/trimmed_means.xlsx", sheet(`rx') modify
forval i = 90(1)99 {
use /directory/tobit_analytic_18Aug25_`rx', clear
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
}
