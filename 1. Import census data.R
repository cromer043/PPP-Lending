#Date (DMY): 08/3/2023
#Author: CSR
#This file downloads the census data to be merged with the MDI list from FDIC

#Setup
###################################################

#Check if packages are installed and install if not
package_list <- c("tidyverse",
                  "purrr",
                  "scales",
                  "openxlsx", 
                  "scales",
                  "devtools", 
                  "kableExtra",
                  "tidycensus")

#install.packages(package_list) #if you need to install remove first # on this line
#webshot::install_phantomjs()
lapply(package_list,
       require,
       character.only = T)

#devtools::install_github(repo = 'UrbanInstitute/urbnmapr')
library(urbnmapr)

#key <- "Insert your census API key here"
#census_api_key(key = key)

#Clear workspace
rm(list=ls())
#Data Importation
########################################
#import data

zcta_demographics2021 <- get_acs(geography = "zcta",
                                 variables = c("Median Income, Zip" = "S1901_C01_012E", 
                                               "Percent below poverty level, zip" = "S1701_C03_001E",
                                               "Total Population" = "DP05_0070E",
                                               "White" =  "DP05_0077E",
                                               "Latino" = "DP05_0071E",
                                               "Black" = "DP05_0078E", #Non-hispanic Black
                                               "AIAN" = "DP05_0079E",
                                               "Asian" = "DP05_0080E",
                                               "AAPI" = "DP05_0081E",
                                               "Other" = "DP05_0082E",
                                               "Twoplus" = "DP05_0083E"
                                 ),
                                 year = 2021,
                                 output = "wide")

demographics <- zcta_demographics2021 %>% 
  mutate(`zip code` = str_pad(as.character(GEOID),
                              side = "left",
                              width = 5,
                              pad = "0")
  ) %>% 
  select(-c(S1901_C01_012M,
            S1701_C03_001M,
            NAME,
            GEOID))

write_csv(demographics,
          "0. Data/census data.csv")

#Get how many zip codes there are that are AIAN majority
max(demographics %>% #Get unique number of  AIAN zips by MDIs
  filter(AIAN/ `Total Population` >= .5) %>% 
  select(`zip code`) %>% 
  row_number())

max(demographics %>% #Get unique number of loans made to AIAN zips by MDIs
      select(`zip code`) %>% 
      row_number())
