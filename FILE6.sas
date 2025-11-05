*libname;
libname savepath "/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Data";
	
ods rtf file="/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Results/Table1.rtf";
ods escapechar="^"; 
%LET PLUSMIN=%SYSFUNC(BYTE(177));

proc format;
	value $Characteristicf ' 1' = "Total Clinicians, No. (%)"
	' 2' = 'AltaMed Medical Group'
	' 3' = 'Northwestern Medicine'
	' 4' = '^{style ^{NBSPACE 5}}NMG Central'
	' 5' = '^{style ^{NBSPACE 5}}NMG North'
	' 6' = '^{style ^{NBSPACE 5}}RMG Northwest'
	' 7' = '^{style ^{NBSPACE 5}}RMG West'
	' 8' = 'Patient Type, No. (%)'
	' 9' = "^{style ^{NBSPACE 5}}Naive"
	'10' = "^{style ^{NBSPACE 5}}At-Risk"
	'11' = "^{style ^{NBSPACE 5}}Chronic"
	'12' = "^{style ^{NBSPACE 5}}Undefined"
	'13' = "License Years, ^{unicode '00B1'x}^{unicode 03C3}"
	'14' = "Biological Sex, No. (%)"
	'15' = "^{style ^{NBSPACE 5}}Female"
	'16' = "^{style ^{NBSPACE 5}}Male"
	'17' = "^{style ^{NBSPACE 5}}Missing"
	'18' = "Clinician Specialty, No. (%)"
  '19' = '^{style ^{NBSPACE 5}}Family Medicine'
	'20' = '^{style ^{NBSPACE 5}}Geriatric Medicine'
	'21' = '^{style ^{NBSPACE 5}}Internal Medicine'
	'22' = '^{style ^{NBSPACE 5}}Other'
	'23' = "Clinician Type, No. (%)"
	'24' = '^{style ^{NBSPACE 5}}APRN'
	'25' = '^{style ^{NBSPACE 5}}Fellow/Attending'
	'26' = '^{style ^{NBSPACE 5}}Nurse Practitioner'
	'27' = '^{style ^{NBSPACE 5}}Physician'
	'28' = '^{style ^{NBSPACE 5}}Physician Assistant'
	'29' = "Clinic Type, No. (%)"
	'30' = '^{style ^{NBSPACE 5}}Community'
	'31' = '^{style ^{NBSPACE 5}}Hospital'
	'32' = 'Clinic Location, No. (%)'
	'33' = '^{style ^{NBSPACE 5}}Rural'
	'34' = "^{style ^{NBSPACE 5}}Suburban"
	'35' = "^{style ^{NBSPACE 5}}Urban";
run;

*NU;
proc import datafile = "/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Data/AESOPS_R33_Trial1_ClinicianDemo.xlsx"
out = nu
replace
dbms = xlsx;
run;

*AltaMed;
proc import datafile = "/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Data/table1_altamed.xlsx"
out = alta
replace
dbms = xlsx;
run;

*combine NU + AltaMed;
proc sql;
	create table clinician as
	select randomization, gender_v2 as gender, specialty, clinician_type, clinic_type, " " as region, clinic_location, . as yr_medical, "Alta" as inst from alta
	union all 
	select randomization, gender, specialty, clinician_type, clinic_type, region, clinic_location, yr_medical, "NU" as inst from NU;
quit;

*years practicing;
data clinician;
	set clinician;
	years_md = 2025-yr_medical;
	where randomization ne .;
run;

*count by study arm for each characteristic;
%macro counts(char);
%do i = 0 %to 1;
proc sql;
	create table counts&i as
	select count(*) as ct, &char from clinician
  %if &char = region %then %do;
  where randomization = &i and inst = 'NU'
	%end;
	%else %do;
	where randomization = &i
	%end;
	group by &char;
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
	(select &char, catx(' ', ct, cat('(', round(ct/sum(ct),.0001)*100, ')')) as c from counts0) t
	full join 
	(select &char, catx(' ', ct, cat('(', round(ct/sum(ct),.0001)*100, ')')) as i from counts1) l
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
%counts(gender);
%counts(specialty);
%counts(clinician_type);
%counts(clinic_type);
%counts(region);
%counts(clinic_location);
%counts(inst);

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
%title(gender, aa);
%title(specialty, aa);
%title(clinician_type, aa);
%title(clinic_type, aa);
%title(region, aa);
%title(clinic_location, aa);
%title(bpa, aa);

 *mean years practicing;
 %macro years(label, group);
 proc sql;
  create table yearsmean&label as
  select "a" as trait, catx(' ', mean_years, cat( '(', sd_years, ')')) as &label from
	(select round(avg(years_md),.01) as mean_years, round(std(years_md),.01) as sd_years from clinician
	where randomization = &group);
quit;
%mend years;
%years(Control, 0);
%years(Intervention, 1);

*combine MD years by study group;
proc sql;
	create table yearsmean as 
	select t.trait, t.Control, l.Intervention from yearsmeancontrol t, yearsmeanintervention l;
quit;

*total in each study arm;
proc sql;
	create table total_no as 
	select count(*) as ct, randomization from clinician 
	group by randomization;
quit;

*transpose data;
proc transpose data = total_no out = total_not (where = (_NAME_ ne 'randomization'));
run;

proc sql;
	create table total_not as 
	select 'aaa' as trait, catx(' ', COL1, cat('(', round(COL1/(COL1+COL2),.0001)*100, ')')) as Control, 
	catx(' ', COL2, cat('(', round(COL2/(COL1+COL2),.0001)*100, ')')) as Intervention from total_not;
quit;

*append and add format;
data total;
	length trait $ 32.;
	retain Characteristic Control Intervention;
	set total_not inst region bpatitle savepath.bpa 
	yearsmean gendertitle gender 
	specialtytitle specialty 
	clinician_typetitle clinician_type 
	clinic_typetitle clinic_type 
	clinic_locationtitle clinic_location;
	Character = _n_;
	Characteristic = put(Character, 2.);
	drop Character trait;
	format Characteristic $Characteristicf.;
run;

proc report data = total;
	/*compute after _page_/ style={just=left bordertopcolor=black borderrightcolor=white borderleftcolor=white borderbottomcolor=white};
    line "^Includes 487 clinicians with active prescription in study period who were not exposed to BPA in the control group (n = 6).";*/
    endcomp;
run;
ods rtf close;