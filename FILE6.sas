/**********************************************************************************************************************************************
**GOAL
***1. Calculate Table 1 counts, compile, format, and output
***********************************************************************************************************************************************/

*libname;
libname savepath "/directory";
ods rtf file="/directory/Table1.rtf";

*format for overall table;
proc format;
	value $Characteristicf 
	' 1' = "Clinics^{super 1}"
	' 2' = "Total Clinics, No. (%)"
	' 3' = '^{style ^{NBSPACE 5}}AltaMed Medical Group'
	' 4' = '^{style ^{NBSPACE 5}}Northwestern Medicine'
	' 5' = "Clinic Type, No. (%)"
	' 6' = '^{style ^{NBSPACE 5}}Community'
	' 7' = '^{style ^{NBSPACE 5}}Hospital'
	' 8' = 'Clinic Location, No. (%)'
	' 9' = '^{style ^{NBSPACE 5}}Rural'
	'10' = "^{style ^{NBSPACE 5}}Suburban"
	'11' = "^{style ^{NBSPACE 5}}Urban"
	'12' = "Clinicians^{super 2}"
	'13' = "Total Clinicians, No. (%)"
	'14' = '^{style ^{NBSPACE 5}}AltaMed Medical Group'
	'15' = '^{style ^{NBSPACE 5}}Northwestern Medicine'
	'16' = "Clinician Type, No. (%)"
	'17' = '^{style ^{NBSPACE 5}}Community'
	'18' = '^{style ^{NBSPACE 5}}Hospital'
	'19' = 'Clinician Location, No. (%)'
	'20' = '^{style ^{NBSPACE 5}}Rural'
	'21' = "^{style ^{NBSPACE 5}}Suburban"
	'22' = "^{style ^{NBSPACE 5}}Urban"
	'23' = "License Years, ^{unicode '00B1'x}^{unicode 03C3}^{super 3}"
	'24' = "Biological Sex, No. (%)"
	'25' = "^{style ^{NBSPACE 5}}Female"
	'26' = "^{style ^{NBSPACE 5}}Male"
	'27' = "^{style ^{NBSPACE 5}}Unknown or not reported"
	'28' = "Clinician Specialty, No. (%)"
  '29' = '^{style ^{NBSPACE 5}}Family Medicine'
	'30' = '^{style ^{NBSPACE 5}}Geriatric Medicine'
	'31' = '^{style ^{NBSPACE 5}}Internal Medicine'
	'32' = '^{style ^{NBSPACE 5}}Other'
	'33' = "Clinician Type, No. (%)"
	'34' = '^{style ^{NBSPACE 5}}APRN'
	'35' = '^{style ^{NBSPACE 5}}Nurse Practitioner'
	'36' = '^{style ^{NBSPACE 5}}Physician'
	'37' = '^{style ^{NBSPACE 5}}Physician Assistant'
	'38' = "Patients^{super 4}"
	'39' = "Total Patients, No. (%)"
	'40' = '^{style ^{NBSPACE 5}}AltaMed Medical Group'
	'41' = '^{style ^{NBSPACE 5}}Northwestern Medicine' 
	'42' = 'Race, No. (%)'
	'43' = "^{style ^{NBSPACE 5}}American Indian/Alaska Native"
	'44' = "^{style ^{NBSPACE 5}}Asian"
	'45' = "^{style ^{NBSPACE 5}}Black"
	'46' = "^{style ^{NBSPACE 5}}Native Hawaiian or Other Pacific Islander"
	'47' = "^{style ^{NBSPACE 5}}White"
	'48' = "^{style ^{NBSPACE 5}}More than one race"
	'49' = "^{style ^{NBSPACE 5}}Unknown or not reported"
	'50' = 'Ethnicity, No. (%)'
	'51' = "^{style ^{NBSPACE 5}}Hispanic or Latino"
	'52' = "^{style ^{NBSPACE 5}}Not Hispanic or Latino"
	'53' = "^{style ^{NBSPACE 5}}Unknown or not reported"
	'54' = "Biological Sex, No. (%)"
	'55' = "^{style ^{NBSPACE 5}}Female"
	'56' = "^{style ^{NBSPACE 5}}Male"
	'57' = "^{style ^{NBSPACE 5}}Unknown or not reported"
	'58' = "Age, ^{unicode '00B1'x}^{unicode 03C3}"
	'59' = "Prescriptions^{super 5}"
	'60' = "Total Prescriptions, No. (%)"
	'61' = '^{style ^{NBSPACE 5}}AltaMed Medical Group'
	'62' = '^{style ^{NBSPACE 5}}Northwestern Medicine'
	'63' = 'Prescription Type, No. (%)'
	'64' = "^{style ^{NBSPACE 5}}Naive"
	'65' = "^{style ^{NBSPACE 5}}Recently Exposed"
	'66' = "^{style ^{NBSPACE 5}}LTHD"
	'67' = "^{style ^{NBSPACE 5}}Other";
run;

*format for analtyic sample;
proc format;
	value $Characteristicfa 
	' 1' = "Total Clinicians, No. (%)"
	' 2' = '^{style ^{NBSPACE 5}}AltaMed Medical Group'
	' 3' = '^{style ^{NBSPACE 5}}Northwestern Medicine'
	' 4' = "Clinician Type, No. (%)"
	' 5' = '^{style ^{NBSPACE 5}}Community'
	' 6' = '^{style ^{NBSPACE 5}}Hospital'
	' 7' = 'Clinician Location, No. (%)'
	' 8' = '^{style ^{NBSPACE 5}}Rural'
	' 9' = "^{style ^{NBSPACE 5}}Suburban"
	'10' = "^{style ^{NBSPACE 5}}Urban"
	'11' = "License Years, ^{unicode '00B1'x}^{unicode 03C3}^{super 1}"
	'12' = "Biological Sex, No. (%)"
	'13' = "^{style ^{NBSPACE 5}}Female"
	'14' = "^{style ^{NBSPACE 5}}Male"
	'15' = "^{style ^{NBSPACE 5}}Unknown or not reported"
	'16' = "Clinician Specialty, No. (%)"
  '17' = '^{style ^{NBSPACE 5}}Family Medicine'
	'18' = '^{style ^{NBSPACE 5}}Geriatric Medicine'
	'19' = '^{style ^{NBSPACE 5}}Internal Medicine'
	'20' = '^{style ^{NBSPACE 5}}Other'
	'21' = "Clinician Type, No. (%)"
	'22' = '^{style ^{NBSPACE 5}}APRN'
	'23' = '^{style ^{NBSPACE 5}}Nurse Practitioner'
	'24' = '^{style ^{NBSPACE 5}}Physician'
	'25' = '^{style ^{NBSPACE 5}}Physician Assistant';
run;

*NU;
proc import datafile = "/directory/AESOPS_R33_Trial1_ClinicianDemo.xlsx"
out = nu
replace
dbms = xlsx;
run;

*AltaMed;
proc import datafile = "/directory/table1_altamed_24Oct25.xlsx"
out = alta
replace
dbms = xlsx;
run;

*change prov_id to character;
data alta;
	informat prov_deid $ 5.;
	set alta;
	prov_deid = put(prov_id, 5.);
	format prov_deid $5.;
run;

*clinic data;
data alta_clinic;
	do rn = 1 to 26;
		clinic_id = 'ID';
		clinic_inst = "Alta";
		cclinic_type = "Community";
		cclinic_location = "urban";
		if rn LE 13 then randomization = 0;
		else randomization = 1;
		drop rn;
		output;
	end;
run;

*NU clinic info.;
proc sql;
	create table nu_clinic as 
	select distinct "NU" as clinic_inst,
	clinic_id, clinic_type as cclinic_type, clinic_location as cclinic_location, randomization from nu;
quit;

*combine alta and NU for clinic data;
data clinic;
	set alta_clinic nu_clinic;
run;

*combine NU + AltaMed for clinician data;
*in analytic sample (1 = yes, 0 = no);
proc sql;
	create table clinician as
	select t.*, l.prov_deid as prov_analytic from 
	(select prov_deid, randomization, gender_v2 as gender, specialty, clinician_type, clinic_type, clinic_location, . as yr_medical, "Alta" as inst from alta
	union all 
	select prov_id as prov_deid, randomization, gender, specialty, clinician_type, clinic_type, clinic_location, yr_medical, "NU" as inst from NU) t 
	left join 
	(select distinct prov_deid from savepath.mixed_analyticu) l 
	on t.prov_deid = l.prov_deid;
quit;

*years practicing;
data clinician;
	set clinician;
	if clinician_type = "Fellow/Attending" then clinician_type = "Physician";
	years_md = 2025-yr_medical;
	where randomization ne .;
run;

*analytic clinicians;
data cliniciana (rename = (gender = gendera specialty = specialtya clinician_type = clinician_typea clinic_type = clinic_typea clinic_location = clinic_locationa inst = insta));
	set clinician;
	if clinician_typea = "Fellow/Attending" then clinician_typea = "Physician";
	years_md = 2025-yr_medical;
	where randomization ne . and prov_analytic ne '';
run;

*change inst name in Rx file;
data analytic;
	set savepath.mixed_analyticu (rename = (inst = rx_inst assignment = randomization));
run;

data analytic_pat;
	set savepath.mixed_analyticu (rename = (bpa_exp = patbpa assignment = randomization));
run;

*count by study arm for each characteristic;
%macro counts(char, dat);
%do i = 0 %to 1;
proc sql;
	create table counts&i as
	%if &dat = analytic_pat %then %do;
	select count(distinct pat_id) as ct, &char from &dat
	where randomization = &i
	group by &char;
  %end;
  
  %else %do;
	select count(*) as ct, &char from &dat
	where randomization = &i
	group by &char;
	%end;
quit;
%end;

proc sql;
	create table &char as
	select * from 
	(select 
	case 
	when traiti = '' then traitc
	else traiti 
  end as trait, 
  case 
  when c = '' then '0' 
  else c 
  end as Control,
  case 
  when i = '' then '0'
  else i 
  end as Intervention 
  from 
	(select l.&char as traiti, t.&char as traitc, t.c, l.i from 
	(select &char, catx(' ', ct, cat('(', round(ct/sum(ct),.001)*100, ')')) as c from counts0) t
	full join 
	(select &char, catx(' ', ct, cat('(', round(ct/sum(ct),.001)*100, ')')) as i from counts1) l
	on t.&char = l.&char))
	order by trait;
quit;

data &char;
	set &char;
	%if &char = region %then %do;
	if trait = '' then delete;
  %end;
run;
%mend counts;
%counts(gender, clinician);
%counts(specialty, clinician);
%counts(clinician_type, clinician);
%counts(clinic_type, clinician);
%counts(clinic_location, clinician);
%counts(inst, clinician);
%counts(gendera, cliniciana);
%counts(specialtya, cliniciana);
%counts(clinician_typea, cliniciana);
%counts(clinic_typea, cliniciana);
%counts(clinic_locationa, cliniciana);
%counts(insta, cliniciana);
%counts(cclinic_type, clinic);
%counts(cclinic_location, clinic);
%counts(clinic_inst, clinic);
%counts(rx_inst, analytic);
%counts(bpa_exp, analytic);
%counts(patbpa, analytic_pat);

*title rows;
%macro title(char, num);
proc sql;
		create table &char.title 
		(trait char(32),
		Control char(32),
		Intervention char(32));
		
		insert into &char.title
		values("&num", ' ', ' ');
quit;
%mend title;
%title(clinics, aa)
%title(gender, aa);
%title(specialty, aa);
%title(clinician, aa);
%title(clinician_type, aa);
%title(clinic_type, aa);
%title(clinic_location, aa);
%title(bpa, aa);
%title(pat, aa);
%title(race, aa);
%title(ethnicity, aa);
%title(rx, aa);

*mean years practicing;
%macro years(label, datname, dat, group);
 proc sql;
  create table yearsmean&label.&datname as
  select "a" as trait, catx(' ', mean_years, cat( '(', sd_years, ')')) as &label from
	(select round(avg(years_md),.1) as mean_years, round(std(years_md),.1) as sd_years from &dat
	where randomization = &group);
quit;

%mend years;
%years(Control, all, clinician, 0);
%years(Intervention, all, clinician, 1);
%years(Control, an, cliniciana, 0);
%years(Intervention, an, cliniciana, 1);

*combine MD years by study group;
proc sql;
	create table yearsmean as 
	select t.trait, t.Control, l.Intervention from yearsmeancontrolall t, yearsmeaninterventionall l;
quit;

proc sql;
	create table yearsmeana as 
	select t.trait, t.Control, l.Intervention from yearsmeancontrolan t, yearsmeaninterventionan l;
quit;

%macro tots(dat);
*total in each study arm;
proc sql;
	create table total_no as 
	select count(*) as ct, randomization from &dat
	group by randomization;
quit;

*transpose data;
proc transpose data = total_no out = total_not (where = (_NAME_ ne 'randomization'));
run;

proc sql;
	create table total_&dat as 
	select 'aaa' as trait, catx(' ', COL1, cat('(', round(COL1/(COL1+COL2),.01)*100, ')')) as Control, 
	catx(' ', COL2, cat('(', round(COL2/(COL1+COL2),.01)*100, ')')) as Intervention from total_not;
quit;
%mend tots;
%tots(clinician);
%tots(cliniciana);
%tots(clinic);
%tots(analytic);

*append and add format;
data total;
	length trait $ 32.;
	retain Characteristic Control Intervention;
	set 
	clinicstitle
	total_clinic clinic_inst
	clinic_typetitle cclinic_type 
	clinic_locationtitle cclinic_location
	cliniciantitle
	total_clinician inst 
	clinic_typetitle clinic_type 
	clinic_locationtitle clinic_location
	yearsmean
	gendertitle gender 
	specialtytitle specialty 
	clinician_typetitle clinician_type
	pattitle
	savepath.total_pat
	savepath.pat_inst
	racetitle savepath.pat_race
	ethnicitytitle savepath.pat_ethn
	gendertitle savepath.pat_gender
  savepath.pat_age
  rxtitle  
  total_analytic rx_inst
  bpatitle bpa_exp;
	Character = _n_;
	Characteristic = put(Character, 2.);
	drop Character trait;
	format Characteristic $Characteristicf.;
run;

proc report data = total nowd;
	 define control / style(column)={cellwidth=1.25in};
	 define intervention / style(column)={cellwidth=1.25in};
	 compute after / style={just=l};
 	 line "Abbreviations: LTHD, Long-Term High-Dose; APRN, Advanced Practice Registered Nurse.";
	 line "^{super 1}Randomized clinics." ;
	 line "^{super 2}Participating clinicians practicing at randomized clinics." ;
	 line "^{super 3}Data only available for Northwestern Medicine clinicians (n = 374).";
	 line "^{super 4}Patients who received at least one opioid prescription during the study period from a clinician in the analytic sample (n = 493).";
   line "^{super 5}Prescribed during the study period by clinicians in the analytic sample (n = 493).";
   endcomp;
run;

*analytic sample;
data total_analytic;
	length trait $ 32.;
	retain Characteristic Control Intervention;
	set 
	total_cliniciana insta 
	clinic_typetitle clinic_typea
	clinic_locationtitle clinic_locationa
	yearsmeana
	gendertitle gendera 
	specialtytitle specialtya 
	clinician_typetitle clinician_typea;
	Character = _n_;
	Characteristic = put(Character, 2.);
	drop Character trait;
	format Characteristic $Characteristicfa.;
run;

proc report data = total_analytic nowd;
	 define control / style(column)={cellwidth=1.25in};
	 define intervention / style(column)={cellwidth=1.25in};
	 compute after / style={just=l};
 	 line "Abbreviations: APRN, Advanced Practice Registered Nurse.";
	 line "^{super 1}Data only available for Northwestern Medicine clinicians (n = 366).";
   endcomp;
run;
ods rtf close;

*statistics for abstract;
proc freq data = clinic;
	table cclinic_type cclinic_location;
	title "Clinic percentages for abstract";
run;

proc freq data = clinician;
	table gender clinician_type specialty;
	title "Clinician percentages for abstract";
run;

proc sql;
	title "Number of distinct patients whose clinician was exposed to a BPA";
	select count(distinct pat_id) as ct from savepath.mixed_analytic;
quit;

*number of clinicians with > 21 years of med school experience;
data temp;
	set clinician;
	if years_md = . then  yr_med = .;
	else if years_md GT 21 then yr_med = 1;
	else yr_med = 0;
run;

proc freq data = temp;
	table yr_med;
run;

proc print data = temp;
	var years_md yr_med;
run;

