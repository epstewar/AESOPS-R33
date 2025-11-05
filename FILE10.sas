libname savepath "/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Data";
	
*NU patient sample;
proc sql;
	create table pats as 
	select distinct pat_id, bpa, bpa_exp from savepath.mixed_analytic
	where post = 1 and inst = "NU";
quit;

*tx;
proc sql;
	create table tx as 
	select distinct pat_id, max(assignment) as max_tx from savepath.mixed_analytic
	where inst = "NU"
	group by pat_id;
quit;

*join Tx with patient sample;
proc sql;
	create table pats_v2 as 
	select t.*, l.max_tx from pats t 
	left join 
	tx l 
	on t.pat_id = l.pat_id;
quit;

*tx = 1 AB;
proc sql;
	create table pat_ab as 
	select distinct pat_id, 1 as tx from pats_v2 where bpa in ('A', 'B') and max_tx = 1;
quit;

*tx = 1 C;
proc sql;
	create table pat_c as 
	select distinct pat_id, 1 as tx from pats_v2 where bpa = 'C' and max_tx = 1;
quit;

*control group AB;
proc sql;
	create table cont_ab as 
	select distinct pat_id, 0 as tx from pats_v2
	where bpa_exp in ('A', 'B') and max_tx = 0;
quit;

*control group C;
proc sql;
	create table cont_c as 
	select distinct pat_id, 0 as tx from pats_v2
	where bpa_exp = 'C' and max_tx = 0;
quit;

*append TX and control;
data AB;
	set pat_ab cont_ab;
run;

data LTHD;
	set pat_c cont_c;
run;

*remove chronic patients from AB sample (samples should be mutuall exclusive);
proc sql;
	create table temp_ab as 
	select t.*, l.pat_id as chronic_pat_id from AB t 
	left join 
	LTHD l 
	on t.pat_id = l.pat_id;
quit;

	data ab;
	set temp_ab;
	if chronic_pat_id ne '' then delete;
	run;

	proc sql;
	select count(distinct pat_id) as ct_distinct_pat, count(*) as ct from ab;
	quit; 
	
	*overall;
	data total;
		set ab lthd;
	run;
	
*ED visits;
proc import datafile = "/schaeffer-a/sch-data-library/dua-data/AESOPS/Original_data/Data/20240731_Download/AESOPS_R33_Trial1_Pt_BiAnnual.csv"
	out = pattemp
	replace
	dbms = csv;
run;	

data pattemp;
	informat pat_id $ 36.;
	set pattemp;
	pat_id = put(cohort_patient_id, 32.);
	if num_ed_vst = "NULL" then num_ed = 0;
	else num_ed = num_ed_vst;
	if num_ed_opioid_vst = "NULL" then num_ed_op = 0;
	else num_ed_op = num_ed_opioid_vst;
	format pat_id $36.;
run;

*total number of ed visits/patient;
proc sql;
	create table pat_ed as 
	select pat_id, sum(num_ed) as sum_ed, sum(num_ed_op) as sum_ed_op 
	from pattemp
	where tm ne 1
	group by pat_id;
quit;

*combine BPA patients with ED visits;
%macro analysis(dat);
	
	*select distinct patients and combine with ED data;
	proc sql;
		create table bpa_&dat._ed as 
		select t.*, l.sum_ed, l.sum_ed_op,
		/*binary ed visits*/
	  case 
		when sum_ed GT 0 then 1 
		else 0
		end as ed_yn,
		case 
		when sum_ed_op GT 0 then 1 
		else 0
		end as ed_op_yn
		from &dat t
		left join 
		pat_ed l 
		on t.pat_id = l.pat_id
		;
	quit;
	
	proc sql;
		select count(distinct pat_id) as ct_distinct_pat, count(*) as ct, tx from bpa_&dat._ed
		group by tx;
	quit; 

proc freq data = bpa_&dat._ed;
	title "ED visit counts by study arm &dat";
	table tx*ed_yn/chisq oddsratio;
run;

proc freq data = bpa_&dat._ed;
	title "ED OP visit counts by study arm &dat";
	table tx*ed_op_yn/chisq oddsratio;
run;

%mend analysis;
%analysis(AB);
%analysis(LTHD);
%analysis(total);


	
	

