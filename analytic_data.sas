libname savepath "/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Data";
	
*import data;
/*%macro imp(directory, infile, outfile);
proc import datafile = "&directory/&infile..xlsx"
	out = &outfile
	replace
	dbms = xlsx;
run;
%mend imp;
%imp(/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_12June24/Data, clinician_weekly, savepath.numvisits);
%imp(/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_12June24/Data, weeks, savepath.time); */

*AltaMed data-includes undefined patients;
%macro imp(file, outfile);
data savepath.&outfile;
      %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
			infile "/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Data/&file..csv"
			delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
     	informat PROV_DEID $32. ;
		  informat CLINIC_ID $10. ;
      informat PAT_ID $36. ;
      informat WEEK best32. ;
      informat TOTAL_MME best32. ;
      informat AVG_DAILY_MME best32. ;
      informat LN_DAILY_MME best32. ;
      informat LN_TOTAL_MME best32. ;
      informat ASSIGNMENT best32. ;
      informat POST best32. ;
      informat BPA $10. ;
      informat NUM_VSTS best32. ;
      informat INST $4. ;
      format PROV_DEID $32. ;
      format CLINIC_ID $10. ;
      format PAT_ID $36. ;
      format WEEK best12. ;
      format TOTAL_MME best12. ;
      format AVG_DAILY_MME best12. ;
      format LN_DAILY_MME best12. ;
      format LN_TOTAL_MME best12. ;
      format ASSIGNMENT best12. ;
      format POST best12. ;
      format BPA $10. ;
      format NUM_VSTS best12. ;
      format INST $4. ;
      input
     PROV_DEID  $
     CLINIC_ID  $
     PAT_ID  $
     WEEK
     TOTAL_MME
     AVG_DAILY_MME
     LN_DAILY_MME
     LN_TOTAL_MME
     ASSIGNMENT
     POST
     BPA  $
     NUM_VSTS
     INST  $
     ;
if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;
%mend imp;
%imp(mixed_model_altamed_sample_01Jul24_inc_6_control, alta);
%imp(MIXED_MODEL_ALTAMED_SAMPLE_01JUL24_UNDEFINED_PATS_INC_6_CONTROL, altau);

*check no. clinicians and clinics by assignment;
/*proc sql;
	title "Total clinicians and clinics in AltaMed analytic data";
	select count(distinct prov_deid) as prov_ct, count(distinct clinic_id) as clinic_ct, assignment from savepath.alta
	group by assignment;
quit;

proc sql;
	title "Total clinicians and clinics in AltaMed analytic data";
	select count(distinct prov_deid) as prov_ct, count(distinct clinic_id) as clinic_ct, assignment, bpa from savepath.alta
	group by assignment, bpa;
quit;*/

*bpa expected vs. observed;
data bpa_type_v2;
	length bpa_exp $ 32. bpa_obs $ 32. pat_id $36.;
	informat pat_id $ 36.;
	set savepath.bpa_type;
	*trigger criteria;
	if total_ninety = 0 then bpa_exp = 'A';
	else if (total_ninety GE 1) and (total_sixmnth = 0) then bpa_exp = 'B';
	else if (total_cninety GE 2) and (total_sixmnth GE 1) and (total_visit_dmme => 50) then bpa_exp = 'C';
	else bpa_exp = "None";
	if bpa_obs = "" then bpa_obs = "None";
	pat_id = put(cohort_patient_id, 8.);
	format pat_id $36.;
run;

*BPA match rate;	
options validvarname = any;
proc sql;
	create table match_rate as 
	select t.*, round(t.count/l.total_obs,0.001) as Percentage from
	
	/*observed and expected bpa A-C count in study period among randomized clinicians*/
	(select count(*) as Count, bpa_exp as 'BPA Expected'n, 
	bpa_obs as 'BPA Observed'n from bpa_type_v2
	where randomization = 1 and post = 1 
	group by bpa_obs, bpa_exp) t 
	
	left join
	
	/*total observed A-C bpas in study period among randomized clinicians*/
	(select bpa_obs, count(*) as total_obs from bpa_type_v2
	where randomization = 1 and post = 1
	group by bpa_obs) l 
	
	on t.'BPA Observed'n = l.bpa_obs;
quit;

proc sort data = match_rate;
	by 'BPA Observed'n 'BPA Expected'n ;
run;

/*proc print data = match_rate;
run;*/

*export;
/*proc export data = match_rate 
	outfile = "/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Results/match_rate.xlsx"
	dbms = xlsx
	replace;
run;*/

*add time period and number of visits to analytic sample;
proc sql;
	create table bpa_type_v3 as 
	select t.prov_deid, 
	t.clinic_id, 
	t.ordering_date,
	t.pat_id,
	t.index_rx,
	l.start_date,
	l.end_date,
	l.week,
	t.total_mme,
	log(t.total_mme) as ln_total_mme,
	t.avg_daily_mme,
	log(t.avg_daily_mme) as ln_daily_mme,
  t.randomization as assignment, 
  t.post,
  case 
  when (t.randomization = 1 and post = 1) then bpa_obs
  else bpa_exp
  end as bpa, 
  'NU' as INST, 
  n.num_vsts
  from
  bpa_type_v2 t 
	left join 
	savepath.time l 
	on l.start_date <= t.ordering_date <= l.end_date
	left join 
	savepath.numvisits n 
	on l.week = n.wks
	and t.prov_deid = n.prov_deid;
quit;

*clinician and clinic counts;
proc sql;
	title "No. clinicians and clinics in analytic sample where BPA ne 'None'";
	select count(distinct prov_deid) as prov_ct, count(distinct clinic_id) as clinic_ct, assignment from bpa_type_v3
	where BPA ne 'None'
	group by assignment;
quit;

*check dates by week;
/*proc sql;
select min(ordering_date) format=mmddyy10. as min_dt, max(ordering_date) format=mmddyy10. as max_dt, start_date, end_date, week from bpa_type_v3
group by start_date, end_date, week
order by week;
quit;*/

*combine altamed and NU data w/out undefined patients;
proc sql;
  create table savepath.mixed_analytic as
	(select prov_deid, clinic_id, pat_id, . as index_rx, week, total_mme, ln_total_mme, avg_daily_mme, ln_daily_mme, assignment, post, bpa length=20, inst, num_vsts from savepath.alta) 
	union all
	(select prov_deid, clinic_id, pat_id, index_rx as NU_prescription_id, week, total_mme, ln_total_mme, avg_daily_mme, ln_daily_mme, assignment, post, bpa length=20, inst, num_vsts from bpa_type_v3 where bpa ne 'None');
quit;

*combine altamed and NU data w/ undefined patients;
proc sql;
	create table savepath.mixed_analyticu as
	(select prov_deid, clinic_id, pat_id, . as index_rx, week, total_mme, ln_total_mme, avg_daily_mme, ln_daily_mme, assignment, post, bpa length=20, inst, num_vsts from savepath.altau) 
	union all
	(select prov_deid, clinic_id, pat_id, index_rx as NU_prescription_id, week, total_mme, ln_total_mme, avg_daily_mme, ln_daily_mme, assignment, post, bpa length=20, inst, num_vsts from bpa_type_v3);
quit;

*check number of patients by assignment, inst. and patient type;
proc sql;
	select count(distinct pat_id) as ct, inst, assignment, bpa from savepath.mixed_analyticu
	group by inst, assignment, bpa
	order by inst, assignment, bpa;
quit;

*TABLE 1: number of patients by patient/bpa type and study arm;
%macro patcts(rand, name);
proc sql;
	create table bpa&rand as 
	select trait, catx(' ', ct, cat('(', round(ct/sum(ct),.0001)*100, ')')) as &name 
	from 
	(select bpa as trait, count(distinct pat_id) as ct from savepath.mixed_analyticu
	where assignment = &rand 
	group by bpa);
quit;

/*proc print data = bpa&rand;
run;*/
%mend patcts;
%patcts(0, Control);
%patcts(1, Intervention);

*TABLE 1: merge patient and control counts;
proc sql;
	create table savepath.bpa as 
	select t.trait, t.Control, l.Intervention from bpa0 t
	left join 
	bpa1 l 
	on t.trait = l.trait;
quit;

*number of patients and clinicians by assignment for consort diagram;
proc sql;
	title "Patient and clinician counts for paragraph 1 of 'Results' and consort";
	select count(distinct pat_id) as ct_pat, count(distinct prov_deid) as ct_prov, count(distinct clinic_id) as ct_clinic, assignment from savepath.mixed_analytic
	group by assignment;
quit;

*clinician and patient count overall-Paragraph one of results;
proc sql;
	title "Number of distinct patients and clinicians in analytic sample for paragraph 1 of 'Results' ";
	select count(distinct pat_id) as ct_pat, count(distinct prov_deid) as ct_prov from savepath.mixed_analytic;
quit;

*number of patients and clinicians by BPA type;
proc sql;
	title "Patient and clinician counts by BPA type for paragraph 1 of 'Results'";
	select count(distinct pat_id) as ct_pat, count(distinct prov_deid) as ct_prov, count(distinct clinic_id) as ct_clinic, BPA from savepath.mixed_analytic
	group by BPA
	order by BPA;
quit;

*number of patients and clinicians by BPA type and assignment;
proc sql;
	title "Patient counts by assignment for Table 1 and clinician counts by assignment and BPA type for paragraph 1 of 'Results'";
	select count(distinct pat_id) as ct_pat, count(distinct prov_deid) as ct_prov, count(distinct clinic_id) as ct_clinic, BPA, assignment from savepath.mixed_analytic
	group by BPA, assignment
	order by BPA, assignment;
quit;

*export file for mixed effects (not tobit) to dta;
proc export data = savepath.mixed_analytic
	outfile = "/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Data/mixed_analytic_29Apr25.dta"
	replace;
run;

proc export data = savepath.mixed_analytic
	outfile = "/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Data/mixed_analytic_29Apr25.csv"
	replace;
run;

%macro tobit(var);

*grouping MME by week by prescriber-week;
proc sql;
create table temp as 
select 
avg(ln_total_mme) as avg_ln_total_mme,
avg(total_mme) as avg_total_mme,
sum(total_mme) as sum_total_mme,
avg(ln_daily_mme) as avg_ln_daily_mme,
avg(avg_daily_mme) as mean_avg_daily_mme,
inst,
prov_deid,
assignment, 
clinic_id, 
week,
post 
from savepath.mixed_analytic
where BPA = "&var"
group by inst, prov_deid, assignment, clinic_id, week, post;
quit;

*log MME;
data temp;
	set temp;
	ln_avg_total_mme = log(avg_total_mme);
	ln_mean_avg_daily_mme = log(mean_avg_daily_mme);
	ln_sum_total_mme = log(sum_total_mme);
run;

*weeks for all prescribers;
proc sql;
create table all_weeks as 
select t.prov_deid, 
l.week,
0 as avg_ln_total_mme,
0 as ln_avg_total_mme,
0 as avg_total_mme,
0 as sum_total_mme,
0 as mean_avg_daily_mme,
0 as avg_ln_daily_mme,
0 as ln_mean_avg_daily_mme,
0 as ln_sum_total_mme,
case 
when 1 <= week <= 26 then 0 
when 27 <= week <= 104 then 1
else 2
end as post
from 
(select distinct prov_deid from temp) t,
(select distinct week from savepath.time where week ne .) l;
quit;

*add clinic, assignment, inst;
proc sql;
create table all_weeks_v2 as 
select distinct 
t.avg_ln_total_mme,
t.ln_avg_total_mme,
t.sum_total_mme,
t.avg_total_mme,
t.mean_avg_daily_mme,
t.avg_ln_daily_mme,
t.ln_mean_avg_daily_mme,
t.ln_sum_total_mme,
l.inst,
t.prov_deid,
l.assignment, 
l.clinic_id, 
t.week,
t.post
from all_weeks t 
left join 
temp l 
on t.prov_deid = l.prov_deid;
quit;

*reorder columns for union (must match);
data all_weeks_v2;
	retain avg_ln_total_mme avg_total_mme sum_total_mme avg_ln_daily_mme mean_avg_daily_mme INST 
	PROV_DEID ASSIGNMENT CLINIC_ID WEEK POST ln_avg_total_mme ln_mean_avg_daily_mme ln_sum_total_mme;
	set all_weeks_v2;
run;

*combine no. weeks for AltaMed and NU;
proc sql;
	create table numvsts as 
	select prov_deid, week as wks, num_vsts from savepath.alta 
	union all 
	select prov_deid, wks, num_vsts from savepath.numvisits;
quit;

*combine weeks with and without data, and add number of visits;
proc sql;
	create table analytic_tobit as 
	/*step 2: add number of visits*/
	select t.*, n.num_vsts from 
	
	/*step 1: combine MME data with all weeks*/
	(select * from all_weeks_v2
	union all 
	select * from temp)
	/*end step 1*/
	
	t left join
  numvsts n 
	on t.week = n.wks
	and t.prov_deid = n.prov_deid;
	/*end step 2*/
quit;

*remove duplicate rows for week;
proc sort data = analytic_tobit;
	by prov_deid week descending avg_total_mme;
run;

data savepath.analytic_tobit_25Mar25_&var;
	set analytic_tobit;
	by prov_deid week;
	if first.week then rn = 1;
	else rn+1;
	where week ne .;
	if num_vsts = . then num_vsts = 0;
	if rn = 1 then output;
	drop rn;
run;

*# of prescribers in each sample A, B, C;
proc sql;
	title "Clinician count for BPA &var";
	select count(distinct prov_deid) as ct_pres, count(distinct clinic_id) as ct_clinic from savepath.analytic_tobit_25Mar25_&var;
quit;

*# weeks per prescriber-should be 131;
*A has 468 prescribers (N = 464*131 = 61,308);
*B has 464 prescribers (N = 464*131 = 60,784);
*C has 280 prescribers (N = 280*131 = 36,680);
proc sql;
	title "Check all clinicians have 131 weeks for tobit file";
	select count(*) as ct, prov_deid, inst from savepath.analytic_tobit_25Mar25_&var 
	group by prov_deid, inst;
quit;

*export analytic files to dta and csv;
proc export data = savepath.analytic_tobit_25Mar25_&var outfile = "/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Data/tobit_analytic_29Apr25_&var..dta"
replace;
run;

proc export data = savepath.analytic_tobit_25Mar25_&var outfile = "/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Data/tobit_analytic_29Apr25_&var..csv"
replace;
run;

*count clinicians by assignment;
proc sql;
	title "Clinician count for BPA &var";
	select count(distinct prov_deid) as ct_pres, count(distinct clinic_id) as ct_clinic, assignment from savepath.analytic_tobit_25Mar25_&var
	group by assignment;
quit;

*mean MME by assignment;
proc sql;
	select mean(avg_total_mme), assignment from savepath.analytic_tobit_25Mar25_&var
	group by assignment;
quit;
%mend tobit;
%tobit(A);
%tobit(B);
%tobit(C);

*total tobit sample;
proc sql;
	create table savepath.analytic_tobit_25Mar25_tot as 
	select * from savepath.analytic_tobit_25Mar25_a
	union all
	select * from savepath.analytic_tobit_25Mar25_b
	union all
	select * from savepath.analytic_tobit_25Mar25_c;
quit;

*combine BPAs;
proc sql;
	create table savepath.analytic_tobit_25Mar25_total as 
	select sum(avg_ln_total_mme) as avg_ln_total_mme, sum(avg_total_mme) as avg_total_mme, sum(sum_total_mme) as sum_total_mme, sum(avg_ln_daily_mme) as avg_ln_daily_mme,
	sum(mean_avg_daily_mme) as mean_avg_daily_mme, 	sum(ln_avg_total_mme) as ln_avg_total_mme, 
	sum(ln_mean_avg_daily_mme) as ln_mean_avg_daily_mme, sum(ln_sum_total_mme) as ln_sum_total_mme,
	INST, PROV_DEID, ASSIGNMENT, CLINIC_ID, WEEK, POST, NUM_VSTS from savepath.analytic_tobit_25Mar25_tot
	group by inst, prov_deid, assignment, clinic_id, week, post, num_vsts
	order by prov_deid, week;
quit;

*check number of providers;
*482 clinicians (N = 482*131 = 63,142);
/*proc sql;
	select count(distinct prov_deid) as ct_pres, count(distinct clinic_id) as ct_clinics from savepath.analytic_tobit_25Mar25_total;
quit;

proc sql;
	select count(distinct prov_deid) as ct_pres, count(distinct clinic_id) as ct_clinics, assignment from savepath.analytic_tobit_25Mar25_total
	group by assignment;
quit;

*check that there are 131 weeks per/clinician;
proc sql;
	select count(*), prov_deid, inst from savepath.analytic_tobit_25Mar25_total
	group by prov_deid, inst;
quit;*/

*export data;
proc export data = savepath.analytic_tobit_25Mar25_total 
outfile = "/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Data/tobit_analytic_29Apr25_total.csv"
replace;
run;

proc export data = savepath.analytic_tobit_25Mar25_total 
outfile = "/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Data/tobit_analytic_29Apr25_total.dta"
replace;
run;

*check counts and mean MME;
/*proc sql;
	select mean(avg_total_mme), assignment from savepath.analytic_tobit_25Mar25_total
	group by assignment;
quit;

*number of obs in pre-intervention period;
proc sql;
	select count(*), assignment, post from savepath.analytic_tobit_25Mar25_total
	group by assignment, post
	order by assignment, post;
quit;

*number of obs in pre-intervention period;
proc sql;
	select count(*), assignment, post from savepath.analytic_tobit_25Mar25_A
	group by assignment, post
	order by assignment, post;
quit;

*number of obs in pre-intervention period;
proc sql;
	select count(*), assignment, post from savepath.analytic_tobit_25Mar25_B
	group by assignment, post
	order by assignment, post;
quit;

*number of obs in pre-intervention period;
proc sql;
	select count(*) as ct, assignment, post from savepath.analytic_tobit_25Mar25_C
	group by assignment, post
	order by assignment, post;
quit;

/************Secondary outcome: Rx with largest MME per-patient, per-clinician, per-week*****************************/
/*proc sort data = savepath.mixed_analytic;
	by prov_deid week pat_id descending avg_daily_mme;
run;

data temp;
	set savepath.mixed_analytic;
	by prov_deid week pat_id;
	if first.pat_id then rn = 1;
	else rn+1;
	if avg_daily_mme ge 50 then hi_dose_daily = 1;
	else hi_dose_daily = 0;
run;

*check number of providers and clinics by assignment;
proc sql;
	select count(distinct prov_deid) as ct_prov, count(distinct clinic_id) as ct_clinic, assignment from temp
	group by assignment;
quit;

proc export data = temp
	outfile = "/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Data/secondary_analytic_logistic.dta"
	replace;
run;

proc export data = temp
	outfile = "/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Data/secondary_analytic_logistic.csv"
	replace;
run;

*secondary outcome: proportion of patients who received a high dose Rx out of total patients per-clinician, per-week;
*get highest Rx per-patient, per-clinician, per-week;
data temp;
	set temp;
	if rn = 1 then output;
run;

proc sql;
	create table secondary_analytic_prop as 
	select prov_deid, assignment, clinic_id, inst, week, post, num_vsts, sum(hi_dose_daily) as sum_daily_pat, count(*) as total_week, 
	(sum(hi_dose_daily)/count(*)) as prop_daily from temp
	group by prov_deid, assignment, clinic_id, inst, week, post, num_vsts;
quit;

proc export data = secondary_analytic_prop
	outfile = "/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Data/secondary_analytic_prop.dta"
	replace;
run;

proc export data = secondary_analytic_prop
	outfile = "/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Data/secondary_analytic_prop.csv"
	replace;
run;
