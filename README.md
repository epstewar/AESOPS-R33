PURPOSE
The AESOPS-R33 repository provides code for manuscript, "###" published in xyz journal in mm yyyy

DOI: ##########

DATA (acquired from June 1, 2020 to August 7, 2023)
    1. Clinician, patient, and prescription data acquired from Northwestern Medicine and AltaMed Medical Group 
    3. MME Conversion factors, drug names and strengths, and drug NDCs obtained from Centers for Disease Control and Prevention 
       a. Opioid National Drug Code and Oral MME Conversion File Update. https://www.cdc.gov/opioids/data-resources/index.html (2023). 

ANALYSES 
     PRIMARY
     1.  Multi-level (mixed effects) left censored regression testing pre-to-post change in log MME between study arms for AESOPS clinicians (n = 488)
     2.  Coefficients used to derive adjusted MME to test whether difference in average mean pre-to-post MME differed between study arms 

     SECONDARY
     1. Proportion of patients who received an Rx => 50 MME
     
CONTENTS 
		 1. File code descriptions in order which they should be executed 
		 2. Analytic sample data dictionary 
		 3. Contact information 
 
SOFTWARE
SAS version 9.4, STATA software version 16, and R version 4.3.2

LICENSE
Schaeffer Center for Health Policy and Economics, University Southern California

CODE
    File 1: NU_MME.sas 
    Goal: Import and clean prescription, BPA and clinician data, and merge into one file ('sample_mme_bpa.sas7bdat')
        1. Imports raw AESOPS and CDC data [lines 25-35]
        	 a. Opioid prescriptions with '' replacing nulls (/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_12June24/Data/rx_temp.xlsx)
        	 b. CDC conversion factors (/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Data/mme_cw.xlsx)
        	 c. Clinician demographics (/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_12June24/Data/AESOPS_R33_Trial1_ClinicianDemo.xlsx)
        	 d. Best Practice Alerts (BPAs) (/schaeffer-a/sch-data-library/dua-data/AESOPS/Original_data/Data/20240731_Download/AESOPS_R33_Trial1_BPA.xlsx)
        2. Merges daily MME extracted from sigline (savepath.rx_cw_v4) with prescriptions by prescription ID [lines 37-59]
        3. Merges clinician demos. (assignment, region, clinic) with prescription data and creates 'post' variable using study dates [lines 72-87]
        4. Rx, patient, and clincians counts [lines 96-126, 136-157] and removal of suppositories, injectables and powders [128-133]
        5. Merges CDC info. (e.g., conversion factor) with prescription data [lines 150-157]  
        6. Cleans Rx strength, qty, etc., and calculates average daily and total MME [lines 159-221]
           a.  For analysis, we used daily MME from sig line. This was summed by visit to acquire total visit DMME (total_visit_dmme) for visits with multiple Rxs. 
        7. Exports medication names and conversion factors for Supplemental Table 1 [lines 223-237]
        8. Add BPA label to BPA file and merge with Rx file by visit ID [lines 239-265]
        9. Removes subsequent BPAs for same encounter, outputs Rxs that occur in study period ('post ne .') among study clinicians (prov_deid ne '')
           and checks clinician and clinic counts [267-285]
        	 a. File 'sample_mme_bpa.sas7bdat' saved to directory. Contains 137,769 unique Rxs. 
        	 
    File 2: bpa_classification.sas 
    Goal: Classify each Rx in study as Naive, At-Risk or Chronic (n = 137,769)
    		1. Imports prescription data ('rx_temp.xlsx') [lines 3-11]
    		2. Aggregates dmme (total_visit_dmme) by visit ID, and gets all Rxs with start dates previous to current ordering date [lines 13-58]
    		3. Create file with index prescription, and append with previous prescriptions [lines 60-113]
    		   a. Get number of days between ordering date and start date (days_diff_start) and end_date (days_diff_end) using SAS intck procedure 
    		   b. Create 90-day, and 3-6 month variables based on ordering, start, and end dates to classify Rxs
    		4. Sum number of Rxs 90 days, and 91-180 days previous to current Rx for A (Naive), B (At-Risk), and C (Chronic) [lines 115-124]
    		5. Merge number of 90-day, and 3-6 month previous Rxs with index Rx info. (e.g., clinician, randomization, etc.) [lines 126-135]
    		   a. Saves file 'bpa_type.sas7bdat' to directory
    		6. Clinician and clinic counts in analytic file by study arm [lines 137-142]
    		
    File 3: analytic_data.sas
    Goal: Create analytic data for Tobit regression 
        1. Imports control variable, weekly no. clinician visits (clinician_weekly.xlsx), study week (weeks.xlsx), and AltaMed analytic data [lines 3-65] 
           a. mixed_model_altamed_sample_01Jul24 is study data for Naive, At-Risk, and Chronic patients ONLY 
           b. MIXED_MODEL_ALTAMED_SAMPLE_01JUL24_UNDEFINED_PATS includes Undefined patients, in addition to Naive, At-Risk, and Chronic 
        2. AltaMed clinician and clinic counts [lines 67-78]
        3. Create BPA expected (A-C) variable (bpa_exp) for each Rx [lines 80-93]
        4. Create and export table counts for BPA classification (Table 2) [lines 95-129]
        5. Add study week and no. of clinician visits per-week to analytic sample [lines 131-163]
        6. Check clinician and clinic counts by study arm for CONSORT diagram and check study weeks by ordering dates [lines 165-178]
        7. Append (UNION) AltaMed and NU samples for analytic file (excludes Undefined patients) [lines 180-186] 
        8. Append (UNION) AltaMed and NU samples for Table 1 (includes Undefined patients) [lines 188-194]
        9. Table 1 patient count columns [lines 196-227]
           a. file 'bpa.sas7bdat' saved to directory 
       10. Distinct patient and clinician counts for Paragraph 1 of paper and CONSORT [lines 229-256]
       11. Export analytic file for mixed effect analysis (STATA's mixed command) that does not include weeks with 0 MME [lines 258-267]
       12. Analytic data for tobit model. Includes all weeks during study for every clinician. Weeks that are missing MME are 0. [lines 269-518]
           a. Aggregates MME by clinician week [lines 271-289]
           b. Takes log MME, adds clinician-weeks where MME is missing (therefore 0), and merges to add clinic, assignment, and institution [lines 291-344]
           c. Reorder columns, combine weeks for NU and AltaMed, and union data with, and without missing MME to get all weeks for every clinician [lines 346-378]
           d. Remove duplicate weeks with 0 MME for clinicians where same week already has preexisting MME value [lines 380-394]
           e. Confirm correct number of study weeks per clinician and export STATA tobit analytic files for A, B, and C (e.g., tobit_analytic_29Apr25_A.dta) [lines 396-419]
           f. Clinician counts and mean MME by study arm [lines 421-432]
           g. Combine A, B, and C samples to create TOBIT analytic sample with all patients and export file (tobit_analytic_29Apr25_total.dta) [lines 438-485]
           h. Check counts and mean MME and export STATA file [lines 487-519]
       13. Analytic data for secondary outcome [lines 521-573]
           a. Classify each Rx as high dose, => 50 MME, check clinician count, and export STATA file for logistic model (secondary_analytic_logistic.dta) [lines 521-549]
           b. Proportion of patients per clinician-week with at least one high dose Rx (=> 50 MME) and export file (secondary_analytic_prop.dta) [lines 551-573]
           
    File 4: qq_plot.do
    Goal: Create excel document to determine how much to trim baseline means for Table 3. Output QQ plots.
        1. Create and export QQ plot for (non-log) MME [lines 7-9]
        2. Create and export QQ plot for log MME [lines 11-13]
        3. Create and export excel doc. with baseline control and intervention means for each percentile trim (90-100) [lines 15-92]
           a. Baseline means for all patients [lines 18-35]
           b. For Naive patients [lines 37-54]
           c. For At-Risk patients [lines 56-73]
           d. For Chronic patients [lines 75-92]
           
    File 5: analysis.do
    Goal: Execute statistical models for primary outcome among all patients and by patient type, and for secondary outcome. Export results to xlsx spreadsheet. 
        1. Primary outcome-log average weekly MME [lines 10-80]
           a. Include directories, import analytic data, make variables lowercase, and institution variable numeric [lines 1-16]
           b. Execute left censored mixed regression on all patients, and by patient type, convert to matrices, and export to results.xlsx [lines 18-45]
           c. Trim baseline values by 1%, and multiply by adjusted percentage change using model estimates [lines 47-78]
           d. Save 'est.dta' file with trimmed baseline values, adjusted post means, and difference in baseline and post means per-clinician, per-week [lines 80-82]  
        2. Secondary outcome-proportion of patients who recieved at least one high dose prescription => 50 MME [lines 84-180]
           a. import analytic data, make variables lowercase, and institution variable numeric [lines 84-90]
           b. Execute mixed logistic regression, convert coefficients to matrices [lines 92-109]
           c. Use margins command to get probabilities at each predictor level, and convert to matrices [lines 111-126]
           d. Use lincom command to get marginal effects: differences in pre-to-post predicted probailities for each study arm, and the 
              difference-in-difference between arms. Convert marginal effects to matrices to export. [lines 128-170]
           e. Append matrices for Table 4, and export Table 4 to results.xlsx [lines 172-180]
           
    File 6: bootstrapped_did.sas
    Goal: Bootstrap 95% confidence intervals for difference-in-difference Table 3
    		1. Export xlsx directory, libname, and format for Table 3 [lines 1-16]
    		2. Import 'est.dta' (created in analysis.do) for all patients, Naive, At-Risk, and Chronic [lines 18-23]
    		3. Proc sql to create table with baseline and intervention means, and differences in mean by study arm [lines 25-39]
    		4. Macro and proc sql to get diff-in-diff pre-to-post, and pre- to post-intervention [lines 41-52]
    		5. Proc print tables [lines 54-64]
    		6. Proc surveyselect to excecute unlimited random sampling 2000 times on pre- and adjusted post MMEs [lines 66-73]
    		7. Proc sql to create table with pre-, post, and post-intervention means by study arm and sample (replicate) number [lines 75-88]
    		8. Proc univariate to get 2.5 and 97.5 pre-, post, and post-intervention cuftoffs for each arm [lines 90-101]
    		9. Datastep to add 95% confidence intervals to observed pre-to-post means [lines 103-115]
    	 10. Proc sql to create pre-to-post difference in means tables for each arm [lines 117-130]
    	 11. Proc sql to create difference-in-difference table [lines 132-142]
    	 12. Proc univariate difference-in-difference in 95% confidence intervals [lines 144-150]
    	 13. Proc sql to append clinician (clinic) count, pre-, post-, and post-intervention means for control and intervention Table 3 columns [lines 152-175]
    	 14. Macro and proc sql to add 95% CIs to difference-in-difference, append diff-in-diff to pre-to-post, and pre- to post-intervention means [177-196]
    	 15. Macro and proc print to print Table 3 for all patients, Naive, At-Risk, and Chronic [lines 198-216]
    	 
    File 7: Table1.sas
    Goal: Create Table 1 clinician demographics for paper and export with formatting 
        1. Libname, RTF to export table, and proc format [lines 1-44]
        2. Proc import to import clinician demos for AltaMed and NU [lines 46-58]
        3. Proc sql to union AltaMed and NU demos. [lines 60-66]
        4. Get NU 'years practicing' variable [lines 68-73]
        5. Macro and do loop to get counts and percentages by study arm for each characteristic [lines 75-129]
        6. Macro and proc sql to create title rows for Table 1 [lines 131-149]
        7. Macro and proc sql to get row for mean (SD) years practicing for each arm; proc sql to merge mean years for each arm [lines 151-167]
        8. Proc sql and proc transpose to get total number of clinicians [lines 169-184]
        9. Append all clinician demos and apply format [lines 186-200]
       10. Proc report and ods RTF to output Table 1 [lines 202-207]
       
ANALYTIC FILES
    Analytic files for mixed-model analysis (excludes weeks with 0). Made in 'analytic_data.sas'. 
 		 File: 'mixed_analytic_29Apr25.dta'. Contains all patients except undefined (A-C). 
 		   1. prov_deid: clinician ID (character, string)
 		   2. clinic_id: clinic ID for which each clinician was assigned (character string)
 		   3. pat_id: patient ID (character, string)
 		   4. index_rx: prescription ID (number, digit) which can be linked to raw NU Rx data ('/schaeffer-a/sch-data-library/dua-data/AESOPS/Original_data/Data/20240731_Download/AESOPS_R33_Trial1_Prescription.xlsx')
 		      a. Missing for AltaMed 
 		   5. week: study week (number, 1-131)
 		      a. baseline: weeks 1-26
 		      b. intervention period: weeks 27-104
 		      c. post-intervention: weeks 105-131
 		   6. total MME (number, integer), total MME (strength x quantity x conversion factor) calculated for each Rx
 		   7. ln_total_MME (number, decimal), log total MME
 		   8. avg_daily_MME (number, decimal), average daily MME based on 30 days' supply (strength x (quantity/30) x conversion)
 		   9. ln_daily_MME (number, decimal), log average daily MME 
 		  10. assignment: (number, 0-1) clinic assignment 
 		      a. 0 = control
 		      b. 1 = intervention 
 		  11. post: study period (number, 0-2) 
 		      a. 0 = baseline
 		      b. 1 = intervention
 		      c. 2 = post-intervention
 		  12. BPA: patient type, (character, A-C)
 		      a. A = Naive 
 		      b. B = At-Risk 
 		      c. C = Chronic 
 		  13. Inst: medical institution, (character, string)
 		      a. ALTA = AltaMed
 		      b. NU = Northwestern 
 		  14. num_vsts: number of clinician visits per week (number, integer)
 		  
 		Analytic files for Tobit analysis (includes weeks with 0). Made in file 'analytic_data.sas'.
 		 File 1: 'tobit_analytic_29Apr25_total.dta'. Contains all patients except undefined (A-C).  
 		  1. prov_deid: clinician ID (character, string)
 		  2. clinic_id: clinic ID for which each clinician was assigned (character, string)
 		  3. week: study week (number, 1-131)
 		      a. baseline: weeks 1-26
 		      b. intervention period: weeks 27-104
 		      c. post-intervention: weeks 105-131
 		      d. weeks where clinician did not prescribe Rx are 0 
 		  4. assignment: (number, 0-1) clinic assignment 
 		      a. 0 = control
 		      b. 1 = intervention 
 		  5. post: study period (number, 0-2) 
 		      a. 0 = baseline
 		      b. 1 = intervention
 		      c. 2 = post-intervention
 		  6. Inst: medical institution, (character, string)
 		      a. ALTA = AltaMed
 		      b. NU = Northwestern 
 		  7. num_vsts: number of clinician visits per week (number, integer)
 		      a. weeks where clinician did not have visits are 0 
 		  8. avg_total_mme: mean MME per-clinician, per-week (number, integer)
 		  9. ln_avg_total_mme: log of the mean MME per-clinician, per-week (number, decimal)
 		 10. sum_total_mme: summed MME per-clinician, per-week (number, integer)
 		 11. ln_sum_total_mme: log of summed MME per-clinician, per-week (number, decimal)
 		 
 	 Files 2-4: 'tobit_analytic_25Mar25_A.dta', 'tobit_analytic_25Mar25_B.dta', 'tobit_analytic_25Mar25_C.dta'
 	   1. suffix 'A' contains Naive patients *only* 
 	   2. suffix 'B' contians At-Risk patients *only*
 	   3. suffix 'C' contains Chronic patients *only*
 	   
 	 Analytic file for secondary analysis (proportion of patients given a high dose Rx => 50 MME). Made in 'analytic_data.sas'.
 	  File: 'secondary_analytic_prop.dta' 
 	    1. prov_deid: clinician ID (character, string)
 		  2. clinic_id: clinic ID for which each clinician was assigned (character string)
 		  3. week: study week (number, 1-131)
 		      a. baseline: weeks 1-26
 		      b. intervention period: weeks 27-104
 		      c. post-intervention: weeks 105-131
 		      d. does not include week with 0 clinician Rxs 
 		  4. assignment: (number, 0-1) clinic assignment 
 		      a. 0 = control
 		      b. 1 = intervention 
 		  5. post: study period (number, 0-2) 
 		      a. 0 = baseline
 		      b. 1 = intervention
 		      c. 2 = post-intervention
 		  6. Inst: medical institution, (character string)
 		      a. ALTA = AltaMed
 		      b. NU = Northwestern 
 		  7. num_vsts: number of clinician visits per week (number, integer)
 		      a. weeks where clinician did not have visits are 0 
 		  8. sum_daily_pat: number of patients per clinician-week who received high dose Rx
 		  9. total_week: total number of patients per clinician-week 
 		  10. prop_daily: proportion of patients per clinician-week who recevied high dose Rx (number, decimal from 0 to 1)
 		     a. sum_daily_pat/total_week
 	  
CONTACT
For questions regarding code email Emily Stewart, epstewar@usc.edu. For questions regarding data access, email corresponding author Jason Doctor, jdoctor@usc.edu. PURPOSE
The epstewar/AESOPS-R33 repository provides code for manuscript, "####" published in ### in mm yyyy

