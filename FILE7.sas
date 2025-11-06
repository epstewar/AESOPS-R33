/**********************************************************************************************************************************************
**GOAL
***1. Calculate Table 1 patient counts to be used in FILE6
***2. Get overall patient counts for 'Sample' section of Results 
***********************************************************************************************************************************************/

*libname;
libname savepath "/yourdirectory";

*23568 unique patients in NU sample, 23811 in Table 1 (saw Tx and control clinician);
*import NU patient data;
proc import datafile = "/yourdirectory/20240731_Download/AESOPS_R33_Trial1_Pt_demo.xlsx"
	out = savepath.nu
	replace
	dbms = xlsx;
run;

*make patient id character;
data nu;
	set savepath.nu;
	pat_id = put(cohort_patient_id, 32.);
	format pat_id $36.;
run;

*import AltaMed patient data;
proc import datafile = "/yourdirectory/ALTA_PATIENT_TABLE1.xlsx"
	out = alta_pat
	replace
	dbms = xlsx;
run;

*make age consistent with NU;
data alta_pat;
	set alta_pat;
	if age_rc > 89 then age = '89+';
	else age = age_rc;
	inst = "alta";
	drop age_rc;
run;

*join patient treatment by patient demos for NU;
proc sql;
	create table nu_pat as 
	select distinct t.pat_id, l.race, l.age, l.gender, l.ethnicity, t.assignment, t.inst from 
	(select distinct pat_id, assignment, inst from savepath.mixed_analyticu where inst = 'NU') t
	left join 
	nu l 
	on t.pat_id = l.pat_id;
quit;

*append to altamed data;
data pat;
	set nu_pat alta_pat;
	if age = '89+' then age_cont = 89;
	else age_cont = age;
	race = lowcase(race);
	ethnicity = lowcase(ethnicity);
	if inst = 'alta' then inst_rc = 'a';
	else inst_rc = 'z';
run;

*recode;
proc sql;
	create table savepath.pat_v2 as 
	select *, 
	
	/*ethnicity*/
	case 
	when ethnicity like ('%cuban%') or ethnicity like ('%hispanic or latino%') or ethnicity like ('%mexican%')
	or ethnicity like ('%puerto%') or ethnicity like ('%other%') or ethnicity like ('%yes%') then 'h'
	when ethnicity like ('%decline%') or ethnicity like ('%null%') or ethnicity like ('%to respond%') or ethnicity like ('%unknown%') then 'uk'
	else 'nh'
  end as ethnicity_rc, 
  
  /*race*/
  case 
  
  /*mixed*/
  when race like ('%2%') or race like ('%native/b%') or race like ('%asian/w%') or race like ('%asian/am%') or race like ('%native/w%')
  or race like ('%can/a%') or race like ('%can/na%') or race like ('%can/w%') or race like ('%ese/wh%') 
  or race like ('%ite/a%') or race like ('%ite/na%') or race like ('%ite/b%') or race like ('%ite/o%') or race like ('%white/patient declined to respond/american%')
  then 'nmixed'
  
  /*asian*/
  when race like ('%asian%') or race like ('%ese%') or race like ('%fil%') or race like ('%kor%') then 'asian'
  
  /*white*/
  when race like ('%white%') then 'mwhite'
  
  when race like ('%sam%') or race like ('%pac%') or race like ('%guam%') or race like ('%haw%') then 'bna'
  
  /*american indian*/
  when race like ('%alaska%') then 'ai'
  
  /*black*/
  when race like ('%black%') then 'black'
  
   /*unknown*/
  when race like ('%decline %') or race like ('%above%') or race like ('%other%') or race like ('%patient%') or race like ('%un%') or race like ('%his%')
  or race = '' then 'uk'
 
	end as race_rc,
	
	/*gender*/
	case
	when gender in ('O', 'U', 'X') then 'uk'
	else gender 
	end as gender_rc
  
  from pat;
quit;

*TABLE 1: number of patients by patient/bpa type and study arm;
%macro patcts(var, dat);
	%do i = 0 %to 1;
proc sql;
	create table &var&i as 
	select trait, catx(' ', ct, cat('(', round(ct/sum(ct),.001)*100, ')')) as rand&i 
	from 
	(select &var as trait, count(distinct pat_id) as ct from savepath.pat_v2
	where assignment = &i
	group by &var);
quit;

 *age;
 proc sql;
  create table age&i as
  select "age" as trait, catx(' ', mean_age, cat( '(', sd_age, ')')) as rand&i from
	(select round(avg(age_cont),.01) as mean_age, round(std(age_cont),.01) as sd_age from savepath.pat_v2
	where assignment = &i);
quit;
%end;

*merge control and intervention;
proc sql;
	create table savepath.&dat as 
	select t.trait, t.rand0 as Control, l.rand1 as Intervention from &var.0 t
	left join 
	&var.1 l 
	on t.trait = l.trait;
quit;

proc sort data = savepath.&dat;
	by trait;
run;

proc print data = savepath.&dat;
run;
%mend patcts;
%patcts(gender_rc, pat_gender);
%patcts(race_rc, pat_race);
%patcts(ethnicity_rc, pat_ethn);
%patcts(inst_rc, pat_inst);

*merge control and intervention for age;
proc sql;
	create table savepath.pat_age as 
	select t.trait, t.rand0 as Control, l.rand1 as Intervention from age0 t
	left join 
	age1 l 
	on t.trait = l.trait;
quit;

*total in each study arm;
proc sql;
	create table total_pa as 
	select count(distinct pat_id) as ct, assignment from savepath.pat_v2
	group by assignment;
quit;

*transpose data;
proc transpose data = total_pa out = total_pat (where = (_NAME_ ne 'ASSIGNMENT'));
run;

*create table;
proc sql;
	create table savepath.total_pat as 
	select 'aaa' as trait, catx(' ', COL1, cat('(', round(COL1/(COL1+COL2),.001)*100, ')')) as Control, 
	catx(' ', COL2, cat('(', round(COL2/(COL1+COL2),.001)*100, ')')) as Intervention from total_pat;
quit;

*overall stats for 'Sample' section of Results ;
*distinct patients;
proc sql;
	create table pat_v3 as 
	select distinct pat_id, gender_rc, race_rc, ethnicity_rc, age_cont from savepath.pat_v2;
quit;

*counts and percentages;
proc freq data = pat_v3;
	title "Patient Gender, Race, Ethnicity for Paragraph 2 of 'Sample' in Results";
	table gender_rc race_rc ethnicity_rc;
run;

proc means data = pat_v3 mean std;
	title "Overall Patient Age and SD Paragraph 2 of 'Sample' in Results";
	var age_cont;
run;

*BPA percentage by study arm (Table S2);
proc sql;
	title "Table S3 Number of Patients who Received Each Rx Type by Assignment";
	select count(distinct pat_id) as ct, bpa_exp, assignment from savepath.mixed_analyticu
	group by bpa_exp, assignment
	order by assignment, bpa_exp;
quit;

*overall counts (under 'Sample' section of paper);
*number of unique patients;
proc sql;
	title "Total Patients in Study Period Paragraph 2 of 'Sample' in Results";
	select count(distinct pat_id) as ct_pat from savepath.mixed_analyticu;
quit;

*by study arm;
proc sql;
	title "Table 2 Patient Counts by Study Arm";
	select count(distinct pat_id) as ct_pat, assignment from savepath.mixed_analyticu
	group by assignment;
quit;

*Overall Rx counts (second paragraph of "Sample" in Results);
proc sql;
	create table temp_pat as 
	select distinct pat_id, bpa_exp from savepath.mixed_analyticu
	group by bpa_exp
	order bpa_exp;
quit;

*BPA type;
proc freq data = temp_pat;
	table BPA_EXP;
	Title "Overall Rx Counts in 2nd Paragraph of 'Sample' in Results";
run;

