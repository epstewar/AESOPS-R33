#load packages 
library(tidyverse)
library(dplyr)
library(readxl)

#function to bootstrapp 95% CIs for tobit coefficients for each Rx (BPA) type (e.g., A-C, 'other) 
boot <- function(bpa = "B", dat = est, intb = dat$int_b, int_std = dat$int_se,
													folb = dat$follow_b, fol_std = dat$follow_se,
														intpostb = dat$intpost_b, intpost_std = dat$intpost_se,
													folpostb = dat$followpost_b, folpost_std = dat$followpost_se) {

#import coefficients and standard errors 
dat <- read_xlsx("/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Data/R33_bootstrap_estimates.xlsx", sheet = bpa)
str(dat)

#intervention coefficient 
int_boot <- rnorm(1000, intb, int_std)
int_boot <-sort(int_boot)

#did intervention coefficient
intpost_boot <- rnorm(1000, intpostb, intpost_std)
intpost_boot <-sort(intpost_boot)

#follow up coefficient 
fol_boot <- rnorm(1000, folb, fol_std)
fol_boot <-sort(fol_boot)

#did follow up coefficient 
folpost_boot <- rnorm(1000, folpostb, folpost_std)
folpost_boot <-sort(folpost_boot)

#column names 
ci.name <-c("Int", "Int.lcl","Int.ucl", "Int.did", "Int.did.lcl","Int.did.ucl", 
						"Follow", "Follow.lcl","Follow.ucl", "Follow.did", "Follow.did.lcl","Follow.did.ucl")

#coefficient LCL and UCLs 
results <- c(intb, (int_boot[50]+int_boot[51])/2, (int_boot[950]+int_boot[951])/2,
						 intpostb, (intpost_boot[50]+intpost_boot[51])/2, (intpost_boot[950]+intpost_boot[951])/2,
						 folb, (fol_boot[50]+fol_boot[51])/2, (fol_boot[950]+fol_boot[951])/2,
						 folpostb, (folpost_boot[50]+folpost_boot[51])/2, (folpost_boot[950]+folpost_boot[951])/2) 

#add column names to data rows 
ci.data <-  data.frame(results, row.names = ci.name)

#return data 
return(as.data.frame(ci.data))
}

#run function to create dataframe 
B_boot <- boot()

#save dataframe to csv 
write.csv(B_boot, file = "/schaeffer-a/sch-projects/dua-data-projects/AESOPS/R33_NU/Recent_25Mar25/Data/B_boot.csv")