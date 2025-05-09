ods excel file="/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Results/did_tables.xlsx";

libname savepath "/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Data";
	
	proc format;
	value Parameterf 11 = "Prescribers (clinics)"
  21 = "Baseline"
	31 = "Intervention"
	41 = "Increment (Baseline to intervention)"
	51 = "Difference in increment"
	12 = "Prescribers (clinics)"
  22 = "Baseline"
	32 = "Post-intervention"
	42 = "Increment (Baseline to post-intervention)"
	52 = "Difference in increment";
run;

%macro imp(var);	
*import data;
proc import datafile =  "/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Data/est_&var..dta"
	out = est&var
	dbms = dta;
run;

*pre- and post-means, and differences;
proc sql;
	create table obs as 
	select round(avg(avg_total_mme),0.01) as pre,
	count(distinct prov_deid) as prov_ct,
	count(distinct clinic_id) as clinic_ct,
	round(avg(mme_int_adj),0.01) as post1,
	round(avg(mme_post_adj),0.01) as post2,
	round(avg(int_diff),0.01) as post1_diff,
	round(avg(post_int_diff),0.01) as post2_diff,
	assignment
	from est&var
	group by assignment
	order by assignment;
quit;

*diff-in-diff intervention;
%macro did;
	%do i = 1 %to 2;
proc sql;
	create table post&i._did as 
	select round((t.int_diff-l.cont_diff),0.01) as did from 
	(select post&i._diff as int_diff from obs where assignment = 1) t,
	(select post&i._diff as cont_diff from obs where assignment = 0) l;
quit;
%end;
%mend did;
%did;

/*proc print data = obs;
	title "Observed and adjusted means and diffs &var";
run;

proc print data = post1_did;
	title "Diff-in-diff intervention &var";
run;

proc print data = post2_did;
	title "Diff-in-diff post-intervention &var";
run;*/

*randomly sample;
ods exclude all;
proc surveyselect data = est&var out = boot
seed = 1347566 method = urs
samprate = 1 outhits rep = 2000;
title "Sampling criteria" noprint;
run;
ods exclude none;

*get estimates for each bootstrapped sample;
proc sql;
	create table boot_stats as 
	select avg(avg_total_mme) as pre,
	avg(mme_int_adj) as post1,
	avg(mme_post_adj) as post2,
	avg(int_diff) as post1_diff,
	avg(post_int_diff) as post2_diff,
	assignment,
	replicate
	from boot
	group by replicate, assignment
	order by replicate, assignment;
quit;

*get median, and 2.5% and 97.5% cutoffs by intervention;
proc sort data = boot_stats;
	by assignment;
run;

proc univariate data = boot_stats noprint;
	var pre post1 post2 post1_diff post2_diff;
	output out = diff_percentiles 
	pctlpts = 2.5 97.5 
	pctlpre = pre_P post1_P post2_P post1_diff_P post2_diff_P;
	by assignment;
run;

*add 95% CIs to observed values;
proc sort data = obs;
	by assignment;
run;

proc sort data = diff_percentiles;
	by assignment;
run;

data est;
	merge obs diff_percentiles;
	by assignment;
run;

*diff-in-diff;
*pre-to-post diff. control;
proc sql;
	create table diffcont as 
	select replicate, post1_diff as post1_diff_cont, post2_diff as post2_diff_cont from boot_stats
	where assignment = 0;
quit;

*pre-to-post diff. intervention;
proc sql;
	create table diffint as 
	select replicate, post1_diff as post1_diff_int, post2_diff as post2_diff_int from boot_stats
	where assignment = 1;
quit;

*difference-in-differences (diff in means between control and intervention);
proc sql;
	create table did as 
	select t.replicate, t.post1_diff_cont, l.post1_diff_int, t.post2_diff_cont, l.post2_diff_int,
	(l.post1_diff_int - t.post1_diff_cont) as post1_did,
	(l.post2_diff_int - t.post2_diff_cont) as post2_did
	from diffcont t 
	left join 
	diffint l 
	on t.replicate = l.replicate;
quit;

*95% CIs;
proc univariate data = did noprint;
	var post1_did post2_did;
	output out = did_percentiles 
	pctlpts = 2.5 97.5 
	pctlpre = post1_did_P post2_did_P;
run;

*Table 3;
%macro arm(title, rand);
options validvarname = ANY;

%do i = 1 %to 2;
proc sql;
	create table est&rand&i as 
	select 1&i as Parameter, 
	catx(" ", prov_ct, cat("(", clinic_ct, ")")) as &title from est where assignment = &rand
	union 
	select 2&i as Parameter, 
	catx(" ", round(pre, 0.01), cat("(", round(pre_P2_5,0.01), ", ", round(pre_p97_5,0.01),")")) as &title from est where assignment = &rand
	union 
	select  3&i as Parameter, catx(" ", round(post&i, 0.01), cat("(", 
	round(post&i._P2_5,0.01), ", ", round(post&i._p97_5,0.01),")")) as &title from est where assignment = &rand
	union
	select 4&i as Parameter, catx(" ", round(post&i._diff, 0.01), cat("(", round(post&i._diff_P2_5,0.01), ", ",
	round(post&i._diff_p97_5,0.01),")")) as &title from est where assignment = &rand;
quit;
%end;

%mend arm;
%arm(Control,0);
%arm(Intervention,1);

%macro did;
	%do i = 1 %to 2;
*add 95% CIs to obs. DID;
proc sql;
	create table post&i._did_cis as 
	select 51 as Parameter, catx(" ", t.did, cat("(", round(l.post&i._did_p2_5,0.01), ", ", round(l.post&i._did_p97_5,0.01), ")")) as Control from post&i._did t,
	did_percentiles l;
quit;

*combine pre-, post-, diffs, with DID;
proc sql;
	create table total&i as 
	select t.*, l.* from
	(select * from est0&i
	union 
	select * from post&i._did_cis) t 
	left join 
	est1&i l
	on t.parameter = l.parameter;
quit;

*print Table 3;
proc sort data = total&i;
	by Parameter;
run;

proc print data = total&i;
	format Parameter Parameterf.;
	title "&var, &i";
run;
%end;
%mend did;
%did;

%mend imp;
%imp(A);
%imp(B);
%imp(C);
%imp(total);
ods excel close;