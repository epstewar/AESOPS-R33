libname savepath "yourdirectory";

/******************************************************************************************************************
**GOALS
***1. Classify each Rx in sample_mme_bpa.sas7bdat (n = 137,769) as naive, recently exposed, LTHD, or 'other'
*******************************************************************************************************************/
	
*import data;
%macro imp(directory, infile, outfile);
proc import datafile = "&directory/&infile..xlsx"
	out = &outfile
	replace
	dbms = xlsx;
run;
%mend imp;
%imp(yourdirectory, rx, rx);

*total visit dMME;
proc sql;
create table total_visit_dmme as 
select visit_id, 
sum(dmme) as total_visit_dmme from savepath.sample_mme_bpa 
group by visit_id;
quit;

*Rxs previous to index Rx;
proc sql;
	create table previous_rxs as
	select '' as prov_deid length=32,
	. as randomization,
	'' as clinic_id,
	. as post, 
	t.cohort_patient_id, 
	t.visit_id,
	t.ordering_date,
	t.prescription_id as index_rx,
	l.order_class,
	l.order_status,
	l.is_pending_ord_yn,
	l.enc_type,
	l.start_date,
	l.end_date,
	'' as freq_name,
	'' as hv_discrete_dose,
	'' as dose_unit,
	'' as med_name,
	'' as quantity,
  l.prescription_Id as previous_rx,
     . as total_visit_dmme,
     . as dmme,
     . as total_mme,
     . as avg_daily_mme,
     '' as bpa_obs,
	0 as file
	from savepath.sample_mme_bpa t
	join
	savepath.rx l 
	on t.cohort_patient_id = l.cohort_patient_id 
	and l.start_date < t.ordering_date
	and t.prescription_id ne l.prescription_id
	where l.start_date ne . and l.end_date ne .
  and (l.start_date ne l.end_date);
quit;

*prepare variables to be appended to previous opioid Rxs and merge per-visit dMME;
proc sql;
create table rx_index as 
select t.prov_deid length=32,
t.randomization,
t.clinic_id,
t.post,
t.cohort_patient_id, 
t.visit_id,
t.ordering_date,
t.prescription_id as index_rx,
t.order_class,
t.order_status,
t.is_pending_ord_yn,
t.enc_type,
t.start_date,
t.end_date,
t.freq_name,
t.hv_discrete_dose,
t.dose_unit,
t.med_name,
t.quantity,
. as previous_rx, 
t.dmme,
t.total_mme,
t.avg_daily_mme,
l.total_visit_dmme,
t.bpa_obs,
1 as file from savepath.sample_mme_bpa t
left join 
(select distinct visit_id, total_visit_dmme from total_visit_dmme) l 
on t.visit_id = l.visit_id;
quit;

*combine index Rx and previous Rxs;
data bpa_class_temp;
set rx_index previous_rxs;

*no. days between ordering date and start date;
if file = 0 then do;
days_diff_start = intck('day', ordering_date, start_date);
days_diff_end = intck('day', ordering_date, end_date);
end;

*Naive and Recently exposed 90-day trigger rules;
if ((-90 > days_diff_start) and (-90 <= days_diff_end)) or (-90 <= days_diff_start) then ninety = 1;
else ninety = 0;
*LTHD 90-day trigger rules;
if ((-90 > days_diff_start) and (-90 <= days_diff_end <= -1)) or (-90 <= days_diff_start <= -1) then c_ninety = 1;
else c_ninety = 0;
*90- to 180-day trigger rules;
if ((-180 > days_diff_start) and (-180 <= days_diff_end <= -91)) or (-180 <= days_diff_start <= -91) then sixmnth = 1;
else sixmnth = 0;
run;

*sum total number of rxs by index_rx;
proc sql;
	create table sumrxs as 
	select index_rx,
	sum(ninety) as total_ninety,
	sum(c_ninety) as total_cninety,
	sum(sixmnth) as total_sixmnth
	from bpa_class_temp
	group by index_rx;
quit;

*merge total Rxs in each time period with index_rx;
proc sql;
	create table savepath.bpa_type as 
	select t.cohort_patient_id, t.prov_deid, t.randomization, t.clinic_id, t.post, t.visit_id, t.ordering_date, 
	t.dmme, t.total_visit_dmme, t.total_mme, t.avg_daily_mme, t.bpa_obs, t.med_name, l.* from
	(select * from bpa_class_temp where file = 1) t
	left join 
	sumrxs l 
	on t.index_rx = l.index_rx;
quit;

*clinician and clinic counts;
proc sql;
	title "No. clinicians and clinics in analytic sample";
	select count(distinct prov_deid) as prov_ct, count(distinct clinic_id) as clinic_ct, randomization from savepath.bpa_type
	group by randomization;
quit;

