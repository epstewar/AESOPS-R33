	PURPOSE
	The AESOPS-R33 repository provides code for manuscript "The effect of personalized risk communication, precommitments, and accountability on opioid prescribing" 
	published in xyz journal on mm yyyy

	DOI: ##########

	DATA (acquired from June 1, 2020 to August 7, 2023)
    1. Clinician, patient, and prescription data acquired from Northwestern Medicine and AltaMed Medical Group 
    3. MME Conversion factors, drug names and strengths, and drug NDCs obtained from Centers for Disease Control and Prevention 
       a. Opioid National Drug Code and Oral MME Conversion File Update. https://www.cdc.gov/opioids/data-resources/index.html (2023). 

	ANALYSES 
	PRIMARY
	1.  Multi-level (mixed effects) left censored regression testing pre- to intervention and pre to follow-up change in log MME between study arms for AESOPS clinicians (n 	= 493)
	2.  Exponentiated coefficients result in percent decrease used to derive adjusted MME 

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
    	File 1: FILE1.sas 
    	Goal: Import and clean prescription, BPA and clinician data, and merge into one file ('sample_mme_bpa.sas7bdat')
        	1. Imports raw AESOPS and CDC data [lines 16-28]
        		 a. Opioid prescriptions with '' replacing nulls (rx.xlsx)
        	 	 b. CDC conversion factors (mme_cw.xlsx)
        	 	 c. Clinician demographics (AESOPS_R33_Trial1_ClinicianDemo.xlsx)
        	 	 d. Best Practice Alerts (BPAs) (AESOPS_R33_Trial1_BPA.xlsx)
        	2. Merges daily MME extracted from sigline (savepath.rx_cw_v4) with prescriptions by prescription ID [30-52]
        	3. Merges clinician demos. (assignment, region, clinic) with prescription data and creates 'post' variable using study dates [65-80]
        	4. Rx, patient, and clincians counts [lines 82-119, 128-141] and removal of suppositories, injectables and powders [121-126]
        	5. Merges CDC info. (e.g., conversion factor) with prescription data by medication ID (we do not have NDC) [143-151]  
        	6. Cleans Rx strength, qty, etc., and calculates average daily and total MME [153-216]
          	 a. To deterimine whether Rx was LTHD, we used daily MME from sig line. This was summed by visit to acquire total visit DMME (total_visit_dmme) for visits with multiple Rxs.
						 b. For model primary outcome, we used total MME (strength*qty*conversion factor)
        	7. Exports medication names and conversion factors for Supplemental Table 1 [218-229]
       		8. Add BPA label to BPA file and merge with Rx file by visit ID (unfortunately, we do not have 'prescription_id' in BPA file) [231-263]
        	9. Outputs index Rxs that occur in study period ('post ne .') among study clinicians (prov_deid ne '') and checks clinician and clinic counts [265-299]
        		 a. File 'sample_mme_bpa.sas7bdat' saved to directory. Contains 137,769 unique index Rxs.
        		 
      File 2: FILE2.sas
       Goal: Classify each Rx in 'sample_mme_bpa.sas7bdat' (n = 137,769) as naive, recently exposed, LTHD, or 'other' 
           1. Imports raw Rx data for previous opioid prescriptions [8-16]
           2. Proc sql calculates total visit dMME [18-24]
           3. Proc sql acquires all opioid Rxs previous (n = 2,501,244) to index Rx (n = 137,769) [26-63]
           4. Proc sql selects columns to append to previous Rxs and merges dMME by visit_ID [65-97]
           5. Data step appends index Rxs (rx_index) and previous Rxs (previous_rxs) [94-113]
          		a. Intck calculates number of days between index Rx ordering date and previous Rx start and end dates [103-107]
          		b. 90-day and 90- to 180-day trigger rules [109-117]
           6. Proc sql sums total number of 90-day (total_ninety) and 90- to 180-day (total_sixmnth) previous opioid Rxs per index Rx [120-129]
           7. Proc sql merges analytic variables with total_ninety and total_sixmnth by prescription_id (index_rx) [131-140]
           		a. Creates 'bpa_type' file to be used in File 3
           8. Proc sql counts number of clinicians and clinics by study arm [142-147]
           
      File 3: FILE3.sas
       Goal: Create analytic data set for mixed (per-prescription) and left-censored (tobit) clinician-week model
           1. Proc import imports clinician-weekly number of encounters and study date weeks [13-22]
           2. Proc import imports AltaMed analytic data [24-78]
           3. Datastep classifies each index Rx in analytic data (n = 137,769) as naive (A), recently exposed (B), or LTHD (C) [80-93]
              a. Converts NU patient ID to character to match AltaMed 
           4. Proc sql creates table comparing expected and actual (i.e., observed) index Rx type [95-115]
           5. Proc sql adds time period and number of visits per clinician-week to analytic sample [117-150]
           6. Proc sql appends NU and AltaMed data for A-C patients to create 'mixed_analytic' data [152-158]
           7. Proc sql appends NU and AltaMed data for A-C, and 'other' patients to create 'mixed_analyticu' data [160-166]
           8. Proc sql checks overall patient, clinic, and clinician counts, and by assignment and BPA type [168-203]
           9. Proc export exports mixed_analytic and mixed_analyticu data to .dta and .csv files [205-214]
           10. Proc sql calculates mean total MME (avg_total_mme) by clinician-week [216-232]
           11. Data step calculates log total MME (ln_avg_total_mme) [234-238]
           12. Proc sql creates 'empty' data with all clinician-weeks set to MME 0, appends to analytic data, and removes duplicate weeks with 0 MME for non-zero MME clinician-weeks [240-254]
               a. Proc sql creates 'empty' data [240-254]
               b. Datastep combines other analytic variables with 'empty data' [256-271]
               c. Datastep reorders variables [273-278]
               d. Proc sql appends AltaMed and NU number of clinician-week encounters [280-286]
           13. Proc sql adds number of visits per clinician-week and appends 'real' and 'empty' data [288-305]
           14. Proc sort and datastep removes duplicate rows with 0 MME for visits with non-zero MME [307-321]
           15. Proc sql checks clinician counts by BPA type and number of weeks per clinician [323-334]
           16. Proc export exports tobit analytic data for each Rx type (e.g., savepath.analytic_tobit_A) to .dta and .csv files [336-349]
           17. Data step appends A-B, and A-C Rxs [351-362]
           18. Proc sql sums all Rx types (A-C) by clinician-week [364-374]
           19. Proc sql checks clinician and clinic counts overall and by assignment [376-387]
           20. Proc export exports AB and ABC data to .dta and .csv files [389-402]
           21. Proc sort and datastep classifies Rx as 'high dose' and outputs one row per-patient clinician-week for high dose Rx (0 = no, 1 = yes) [404-426]
           22. Proc sql sums total patients, number of patients who received high dose Rx per clinician-week and calculates proportion (prop_week) [428-434]
           23. Proc export exports secondary analytic data to .dta and .csv files [436-445] 
       
           		
          