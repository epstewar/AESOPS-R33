libname savepath "yourdirectory";
ods pdf file = "yourdirectory";

/******************************************************************************************************************
**GOALS
***1. Calculate MME per Rx 
***2. Merge with BPA file, and get observed BPA per encounter 

**NU STUDY TIME FRAME
***Baseline: 6/1/2020-11/29/2020 (weeks 1-26)
***Int: 11/30/2020-5/29/2022 (27-104)
***Post: 5/30/2022-11/30/2022 (105-131)
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
%imp(yourdirectory, mme_cw, cw);
%imp(yourdirectory, AESOPS_R33_Trial1_ClinicianDemo, clinicians);
%imp(yourdirectory, AESOPS_R33_Trial1_BPA, bpas);

*add DMME (found in savepath.rx_cw_v4) to rx file;
*remove duplicates;
data temp;
set savepath.rx_cw_v4;
*two rxs have more than one dmme-changing to accurate number;
if prescription_id = 2356429760 then dmme = 5;
else if prescription_id = 2411580511 then dmme = 2.5;
drop hv_discr_freq_id frequency;
run;
	
proc sql;
	create table distinct_dmme as 
	select distinct * from temp;
quit;

*merge DMME with Rx file;
proc sql;
	create table rx as 
	select t.*, l.dmme from rx t 
	left join 
	distinct_dmme l 
	on t.prescription_id = l.prescription_id;
quit;
	
*get prov. assignment;
proc sql;
	create table rx as 
	select t.*,
	case 
	when '01JUN2020'd <= ordering_date <= '29NOV2020'd then 0
	when '11NOV2020'd <= ordering_date <= '29MAY2022'd then 1
	when '30MAY2022'd <= ordering_date <= '30NOV2022'd then 2
	else .
  end as post,
	l.randomization, l.region, l.clinic_id
	from rx t 
	left join 
	clinicians l
	on t.prov_deid = l.prov_id;
quit;

*check dates match post variable;
proc sql;
	title "Study Period Dates";
	select min(ordering_date) format=mmddyy10. as min, max(ordering_date) format=mmddyy10. as max, post from rx 
	group by post;
quit;

*no. Rxs, clinicians, and patients overall;
proc sql;
	title "No. of Rxs, patients, clinicians overall-# not in Rx file";
	select count(prescription_id) as ct_rx, count(distinct prov_deid) as ct_prov, count(distinct clinic_id) as ct_clinic, count(distinct cohort_patient_id) as ct_pat from rx
	where randomization ne .;
quit;

*no. Rxs, clinicians, and patients overall;
proc sql;
	title "No. of Rxs, patients, clinicians overall-# not in Rx file during study period";
	select count(prescription_id) as ct_rx, count(distinct prov_deid) as ct_prov, count(distinct clinic_id) as ct_clinic, count(distinct cohort_patient_id) as ct_pat from rx
	where post ne . and randomization ne .;
quit;

*by study arm;
proc sql;
	title "No. of Rxs, patients, clinicians by study arm-overall";
	select count(prescription_id) as ct_rx, count(distinct prov_deid) as ct_prov, count(distinct clinic_id) as ct_clinic, count(distinct cohort_patient_id) as ct_pat, randomization from rx
	where randomization ne .
	group by randomization
	order by randomization;
quit;

*by study arm;
proc sql;
	title "No. of Rxs, patients, clinicians by study arm in study period";
	select count(prescription_id) as ct_rx, count(distinct prov_deid) as ct_prov, count(distinct clinic_id) as ct_clinic, count(distinct cohort_patient_id) as ct_pat, randomization from rx
	where post ne . and randomization ne .
	group by randomization
	order by randomization;
quit;

*convert medication_id to number and remove injectables, suppositories and powders;
data savepath.rx;
	set rx;
	medication_idn = input(medication_Id, 8.);
	where medication_id not in (15210, 210364, 3758, 10227, 10227, 5340, 9219);
run;

*after removing Rxs;
proc sql;
	title "No. of Rxs, patients, providers in sample after removing suppositories, injectionables, etc.";
	select count(prescription_id) as ct_rx, count(distinct prov_deid) as ct_prov, count(distinct clinic_id) as ct_clinic, count(distinct cohort_patient_id) as ct_pat from savepath.rx
	where post ne . and randomization ne .;
quit;

*by study arm;
proc sql;
	title "No. of Rxs, patients, providers in sample after removing suppositories, injectionables, etc. by study arm";
	select count(prescription_id) as ct_rx, count(distinct prov_deid) as ct_prov, count(distinct clinic_id) as ct_clinic, count(distinct cohort_patient_id) as ct_pat, randomization from savepath.rx
	where post ne . and randomization ne .
	group by randomization;
quit;

*Merge CDC variables for MME calculation;
proc sql;
	create table sample_mme as 
	select t.*, l.strength_per_unit, l.OP_Qtotal, l.has_op, l.mme_factor, l.route, l.form
	from savepath.rx t 
	left join 
	(select distinct generic_name, medication_id, strength_per_unit, OP_Qtotal, has_op, mme_factor, form, route from cw) l 
	on t.medication_id = l.medication_id;
quit; 

*MME;
data sample_mme;
	length form_v2 $ 32.;
	set sample_mme;
	
	/*change 155 patch to 15*/
	quantity = prxchange('s/155 patch/15/', -1, quantity);
	
	/*extract unit for liquids*/
	locunit = prxparse('/\d+?.?\d+ ML ORAL| ?(\d+ ML)/');
	loc2unit = prxmatch(locunit, med_name);
	unit = prxposn(locunit, 0, med_name);
	unitn = input(compress(unit, , 'a'), 8.);
	
	/*extract drugname*/
 	locdrug = prxparse('/CODEINE|COD|HYDROCODONE|HYDROMORPHONE|LEVORPHANOL|METHADONE|MORPHINE|NUCYNTA|OXYCODONE|OXYCONTIN|OXYMORPHONE|TAPENTADOL|ULTRACET|TRAMADOL|ULTRAM|FENTANYL|VIRTUSSIN|HYDROMET|GUAIATUSSIN|MEPERIDINE|OPIUM/');
	loc2drug = prxmatch(locdrug, med_name);
	drug = prxposn(locdrug, 0, med_name);
	if drug = 'COD' then drug = 'CODEINE';
  
 	locdrug2 = prxparse('/GUAIFENESIN|ACETAMINOPHEN|PSEUDOEPHEDRINE|PROMETHAZINE|HOMATROPINE|CPM|CHLORPHENIRAMINE|COMPOUND/');
	loc2drug2 = prxmatch(locdrug2, med_name);
	drug2 = prxposn(locdrug2, 0, med_name);
	if drug2 = '' then drug2 = "NONE";
	
	/*strength per unit*/
	if medication_idn in (4952, 5176, 10655, 5828) then OP_Qtotal = strength_per_unit;
	if unitn ne . then strengthn = OP_Qtotal/unitn;
	else strengthn = OP_Qtotal;
	strengthn = round(strengthn, .01);
	
	/*round mme factor, and remove letters from quantity*/
	mme_factor = round(mme_factor, .01);
	quantityn = input(compress(quantity, , 'a'), 8.);
	if prescription_id = 2319782021 then quantityn = 60;
	
	/*change "1 bottle" to mL*/
	if medication_id =  9335 and quantity = "1 Bottle" then quantityn = 2.5;
	if medication_id in (174087, 9582, 6627, 199002, 36663) and quantity = "1 Bottle" then quantityn = 120;
	if medication_id in (10655) and quantity = "1 Bottle" then quantityn = 30;
	if medication_id = 8947 and quantity = "1 Bottle" then quantityn = 100;

	/*Days' supply*/
	days = end_date - start_date;
  
  /*MME*/
	if days <= 0 then days = 30;
  avg_daily_MME = strengthn*(quantityn/30)*MME_factor;
  total_MME = strengthn*quantityn*MME_factor;
  if days ne 0 then do;
  avg_daily_mme_v2 = strengthn*(quantityn/days)*mme_factor;
  end;

  /*standardize drug forms*/
 	if medication_id in (210364, 3758) then form = 'Solution';
  if form = '' then form_v2 = '';
  else if form in ('Concentrate', 'Syrup', 'Syringe', 'Suspension', 'Solution', 'Liquid', 'suspension,extended rel 12 hr', 'Tincture', 'spray,non-aerosol') then form_v2 = "Solution";
  else if form = "Suppository" then form_v2 = "Suppository";
  else if form = "patch 72 hour" then form_v2 = "Patch";
  else form_v2 = "Tablet";
  
  /*remove Rxs with missing MME (no pill qty)*/
  if total_mme ne . then output;
run;

*supplemental Table 1;
proc sql;
	create table table_s1 as 
	select distinct has_op, MME_factor from sample_mme
	order by has_op;
quit;

proc export data = table_s1
outfile = "/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Results/table_s1.xlsx"
dbms = xlsx
replace;
run;

*add BPA label (A, B, C) for BPA file;
proc sql;
	create table bpa_sample as 
	select distinct cohort_patient_id, bpa_obs, visit_id from  
	(select *,
	case 
	when BPA_ID in (1255, 1222) then 'A'
	when BPA_ID in (1360, 1358) then 'B'
	else 'C'
  end as BPA_obs from bpas);
quit;

*BPA counts;
proc sql;
	Title "Observed BPA counts by BPA type";
	select count(distinct visit_id) as BPA_ct, BPA from savepath.bpa_sample
	group by bpa;
quit;

proc sql;
	Title "Observed BPA counts by BPA ID";
	select count(distinct visit_id) as BPA_ct, BPA_ID from bpas
	group by bpa_id;
quit;

*merge by visit id;
proc sql;
	create table sample_mme_bpa as 
	select t.*, l.bpa_obs from sample_mme t 
	left join 
	bpa_sample l 
	on t.visit_id = l.visit_id;
quit;

*remove subsequent BPAs for same encounter (n = 13);
proc sort data = sample_mme_bpa;
	by visit_Id prescription_id bpa_obs;
run;

data savepath.sample_mme_bpa;
	set sample_mme_bpa;
	by visit_id prescription_id;
	if first.prescription_id then rn = 1;
	else rn+1;
	if rn = 1 and (post ne .) and (prov_deid ne "") then output;
run;

*counts;
proc sql;
	Title "Observed BPA counts by study period and randomization";
	select randomization, post, bpa_obs, count(*) as BPA_ct from savepath.sample_mme_bpa
	group by randomization, post, bpa_obs
	order by randomization, post, bpa_obs;
quit;

proc sql;
	Title "Observed BPA counts during intervention among clinicians randomized to intervention (n = 11,609)";
	select randomization, post, bpa_obs, count(*) as BPA_ct from savepath.sample_mme_bpa
	where randomization = 1 and post = 1 
	group by randomization, post, bpa_obs
	order by randomization, post, bpa_obs;
quit;

*clinician and clinic counts;
proc sql;
	title "No. clinicians and clinics in analytic sample";
	select count(distinct prov_deid), count(distinct clinic_id), randomization from savepath.sample_mme_bpa
	group by randomization;
quit;
ods pdf close;
