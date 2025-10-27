PURPOSE
The AESOPS-R33 repository provides code for manuscript "The effect of personalized risk communication, precommitments, and accountability on opioid prescribing" published in xyz journal on mm yyyy

DOI: ##########

DATA (acquired from June 1, 2020 to August 7, 2023)
    1. Clinician, patient, and prescription data acquired from Northwestern Medicine and AltaMed Medical Group 
    3. MME Conversion factors, drug names and strengths, and drug NDCs obtained from Centers for Disease Control and Prevention 
       a. Opioid National Drug Code and Oral MME Conversion File Update. https://www.cdc.gov/opioids/data-resources/index.html (2023). 

ANALYSES 
     PRIMARY
     1.  Multi-level (mixed effects) left censored regression testing pre- to intervention and pre to follow-up change in log MME between study arms for AESOPS clinicians (n = 493)
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
