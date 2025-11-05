libname savepath "/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25";

*import NU BPA file;
proc import datafile = "/schaeffer-a/sch-data-library/dua-data/AESOPS/Original_data/Data/20240731_Download/AESOPS_R33_Trial1_BPA.xlsx"
	out = BPA
	replace
	dbms = xlsx;
run;

*Import AltaMed file;
proc import datafile = "/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Data/AltaMed_tapers.xlsx"
	out = alta
	replace
	dbms = xlsx;
run;

*1C BPAs for all patients;
proc sql;
	create table chronic as 
	select distinct cohort_patient_id, bpa_id, bpa_name, dt_bpa_firing from BPA 
	where bpa_id in (1906, 1724, 1770, 1839, 1909)
	order by cohort_patient_id, dt_bpa_firing;
quit;

data chronic;
	set chronic;
	by cohort_patient_id dt_bpa_firing;
	if first.cohort_patient_id then rn = 1;
	else rn+1;
run;

proc sql;
	title "No. of distinct patients where 1st BPA is not enrollment";
	select t.ct_no_enroll, l.total_pat from 
	(select count(*) as ct_no_enroll from chronic 
	where rn = 1 and bpa_id ne 1724) t,
	(select count(*) as total_pat from chronic where rn = 1) l;
quit;

proc sql;
	select count(*) as ct, bpa_name from chronic
	where (bpa_id ne 1724 and rn = 1)
	group by bpa_name;
quit;

*total number of BPAs;
proc sql;
	create table chronic_v2 as 
	select t.*, l.total_bpa from chronic t 
	left join 
	(select cohort_patient_id, max(rn) as total_bpa from chronic 
	group by cohort_patient_id) l 
	on t.cohort_patient_id = l.cohort_patient_id;
quit;

proc sql;
	select count(distinct cohort_patient_id) from chronic_v2;
quit;

*total number of patients with only 1 chronic bpa;
/*proc sql;
	title "No. of patients lost to follow up after BPA enrollment";
	select count(distinct cohort_patient_id) as pat_ct, total_bpa from chronic_v2 
	group by total_bpa;
quit;*/

data chronic_v2;
	set chronic_v2;
	if bpa_id = 1724 then enroll = 1;
	else enroll = 0;
	if bpa_id = 1770 then justify = 1;
	else justify = 0;
	if rn = 1 and bpa_id ne 1724 then enroll_not_first = 1;
	else enroll_not_first = 0;
	if bpa_id = 1839 then reminder = 1;
	else reminder = 0;
run;

*whether patient enrolled or justified;
proc sql;
	create table chronic_v3 as
	select distinct t.cohort_patient_id, 
	t.total_bpa, 
	l.total_enroll,
	l.enroll_yn, 
	l.justify_yn, 
	l.enroll_not_first_yn,
	l.reminder_yn
	from chronic_v2 t 
	left join 
	(select cohort_patient_id, 
	max(enroll) as enroll_yn,
  max(enroll_not_first) as enroll_not_first_yn, 
	max(justify) as justify_yn,
	max(reminder) as reminder_yn,
	sum(enroll) as total_enroll
	from chronic_v2 
	group by cohort_patient_Id) l
	on t.cohort_patient_id = l.cohort_patient_id;
quit;

data savepath.chronic_v3;
	set chronic_v3;
	if (total_enroll = total_bpa) or (total_bpa = 1) then lost_follow_up_yn = 1;
	else lost_follow_up_yn = 0;
	if lost_follow_up_yn = 1 then engage_taper_yn = .;
	else if justify_yn = 0 then engage_taper_yn = 1;
	else engage_taper_yn = 0;
	if lost_follow_up_yn = 1 then active_engage_taper_yn = .;
	else if (justify_yn = 0) and (reminder_yn = 1) then active_engage_taper_yn = 1;
	else active_engage_taper_yn = 0;
	if lost_follow_up_yn = 1 then not_engaged_yn = .;
	else if justify_yn = 0 and reminder_yn = 0 then not_engaged_yn = 1;
	else not_engaged_yn = 0;
	drop total_bpa;
run;
	
*add altamed;
data chronic_v4;
	set chronic_v3 alta;
run;

proc freq data = chronic_v4;
	table enroll_yn enroll_not_first_yn
	justify_yn reminder_yn lost_follow_up_yn engage_taper_yn active_engage_taper_yn not_engaged_yn;
run;



