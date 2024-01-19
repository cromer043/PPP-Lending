#Date (DMY): 07/24/2023
#Author: CSR
#This file explores the PPP Loan data merged with the MDI list from FDIC
# We want to know:
#Overall MDIs:

#what percent of PPP #, $ amount went to:

#Places with higher Poverty rate than the national rate 2021:

#  Majority-Minority communities:

# Majority minority + higher poverty rate than the national rate

#Setup
###################################################

#Check if packages are installed and install if not
package_list <- c("tidyverse",
                  "purrr",
                  "scales",
                  "openxlsx", 
                  "scales",
                  "webshot",
                  "devtools",
                  "magick",
                  "kableExtra",
                  "tidycensus")

#install.packages(package_list) #if you need to install remove first # on this line
#webshot::install_phantomjs()
#install.packages("magick")
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
setwd("C:/Users/csromer/OneDrive - National Bankers Association/Blogs/2023/PPP Loan Blog")
data <- read_csv("0. Data/PPP Loan Data MDI.csv") #From python Code

fips_to_region <- read_csv("0. Data/Fips to region.csv")
state_to_fips <- read_csv("0. Data/us-state-ansi-fips.csv")
zip_to_zcta <- read_csv("0. Data/ZIPCodetoZCTACrosswalk2021UDS.csv")
census_data <- read_csv("0. Data/census data.csv")
non_mdi_lmi_maj_min <- read_csv("2. Output/Non MDIs LMI and Minority Status.csv")
ppp_loan_summaries <- read_csv("0. Data/ppp_loan_summaries_by_race.csv")
ppp_loan_size_table <- read_csv("0. Data/ppp_loan_size_table.csv")
ppp_loan_dollars_table <- read_csv("0. Data/ppp_loan_dollars_size_table.csv")


#Begin Data Cleaning
##############################
#Begin Data Cleaning
ppp_loan_data <- data %>% 
  mutate(ZIP_CODE = case_when(str_detect(BorrowerZip,
                                         "-") == F ~ paste0(BorrowerZip, "-0000"),
                              T ~ BorrowerZip),
         ZIP_CODE = str_sub(ZIP_CODE,
                            end = 5)) %>% 
  left_join(.,
            zip_to_zcta) %>% 
  mutate(
    ppp_loan_size = factor(case_when(
      InitialApprovalAmount < 10000 ~ "$0-$10k",
      InitialApprovalAmount < 50000 ~ "$10k-$50k",
      InitialApprovalAmount < 100000 ~ "$50k-$100k",
      InitialApprovalAmount < 500000 ~ "$100k-$500k",
      InitialApprovalAmount < 1000000 ~ "$500k-$1m",
      InitialApprovalAmount >= 1000000 ~ "$1m+"
    ),
    levels = c("$0-$10k",
               "$10k-$50k",
               "$50k-$100k",
               "$100k-$500k",
               "$500k-$1m",
               "$1m+"
    )
    )) %>% 
  left_join(.,
            state_to_fips,
            by = c("BorrowerState" = "stusps")) %>% 
  rename(Bank = Name) %>% 
  left_join(.,
            fips_to_region %>% rename(RegionName = Name),
            by = c("st" = "State (FIPS)")) %>% 
  mutate(RegionName = case_when(!BorrowerState %in% state_to_fips$stusps ~ "Territories",
                                TRUE ~ RegionName)) 

ppp_loan_data <- left_join(ppp_loan_data,
                           census_data %>% 
                             rename(ZCTA = `zip code`)
) %>% 
  mutate(
    poverty = case_when(`Percent below poverty level, zip` >= 11.6 ~ 1,
                        `Percent below poverty level, zip` < 11.6 ~ 0),
    maj_min = case_when((AIAN+
                           Black +
                           Latino +
                           Asian +
                           AAPI +
                           Other +
                           Twoplus) /
                          `Total Population` >= .5 ~ 1,
                        (AIAN+
                           Black +
                           Latino +
                           Asian +
                           AAPI +
                           Other +
                           Twoplus)/ `Total Population` < .5 ~ 0),
    # maj_min = case_when(`White`/ `Total Population` > .5 ~ 0, #Sanity check on numbers-they're the same
    #                     `White`/ `Total Population` < .5 ~ 1),
    status = case_when(maj_min == 0 & 
                         LMIIndicator =="N" ~ "Neither LMI nor majority-minority",
                       maj_min == 0 &
                         LMIIndicator =="Y" ~ "LMI, not majority-minority",
                       maj_min == 1 & 
                         LMIIndicator =="N" ~ "Not LMI, majority-minority",
                       maj_min == 1 & 
                         LMIIndicator =="Y" ~ "LMI and majority-minority"
    ),
    
    # Minority Status (Alpha Code)
    # A - Asian or Pacific Islander American, or Majority of the Board Asian or Pacific Islander, serving a minority community
    # B - Black or African American, or Majority of the Board African American, serving a minority community
    # H - Hispanic American, or Majority of the Board Hispanic American, serving a minority community
    # M - Multi-racial, or Majority of the Board Multi-racial American, serving a minority community
    # N - Native American or Alaskan Native American, or Majority of the Board Native American or Alaskan Native American, serving a minority community
    # 
    # Minority Status (Numeric Code)
    # 1 - Black or African American owned
    # 2 - Hispanic American owned
    # 3 - Asian or Pacific Islander American owned
    # 4 - Native American or Alaskan Native American owned
    # 5 - Multi-racial American owned
    # 6 - Majority of the Board African American, serving a minority community
    # 7 - Majority of the Board Hispanic American, serving a minority community
    # 8 - Majority of the Board Asian or Pacific Islander, serving a minority community
    # 9 - Majority of the Board Native American or Alaskan Native American, serving a minority community
    # 10 - Majority of the Board Multi-racial American, serving a minority community
    blackBank = case_when(`Minority Status` == "B" ~ 1,
                          T ~ 0),
    hispanicBank = case_when(`Minority Status` == "H"  ~ 1,
                             T ~ 0),
    AAPIBank = case_when(`Minority Status` == "A" ~ 1,
                         T ~ 0),
    AIANBank = case_when(`Minority Status` == "N"  ~ 1,
                         T ~ 0),
    multiBank = case_when(`Minority Status` == "M"  ~ 1,
                          T ~ 0),
    mixedBank = case_when(#Check if any banks are owned by one racial group but serve another racial group
      blackBank+ 
        hispanicBank+
        AAPIBank+
        AIANBank+
        multiBank > 1 ~ 1,
      T ~ 0),
    race_bank = case_when(blackBank == 1 ~ "Black or African American",
                          hispanicBank == 1 ~ "Hispanic or Latino",
                          AAPIBank == 1 ~ "Asian American or Pacific Islander",
                          AIANBank == 1 ~ "American Indian or Alaska Native",
                          multiBank == 1 ~ "Multi racial")
  )


non_mdi_lmi_maj_min <- non_mdi_lmi_maj_min %>% 
  select(-`...1`) %>% 
  mutate(`Bank type` = "Non-MDI")

ppp_loan_summaries <- ppp_loan_summaries %>% 
  select(-`...1`)

write_csv(ppp_loan_data,
          "2. Output/Cleaned PPP MDI data.csv")
  #Create excel sheets of the data requested by anthony
####################################

# Majority minority + LMI OVERALL

percent_ppp_loans_maj_min_lmi <- ppp_loan_data %>% 
  group_by(status) %>% 
  add_count() %>% 
  select(n, maj_min) %>% 
  distinct() %>% 
  ungroup() %>% 
 # filter(!is.na(status)) %>% 
  mutate(
    maj_min = case_when(maj_min == 1 ~ "Majority minority",
                        maj_min == 0 ~ "Not majority minority",
                        T ~ "No data available on ethnic/racial composition"),
    Group = case_when(is.na(status) == T ~ "No data available on ethnic/racial composition",
                      T ~ status),
    `Number of loans` = comma(n),
    `Percent of loans` = percent(n/sum(n))
  ) %>% 
  select(-c(n,
            status))


#what percent of PPP $ amount went to:

#  Majority minority + LMI

percent_ppp_loan_dollars_maj_min_lmi <- ppp_loan_data %>% 
  group_by(status, maj_min) %>% 
  summarise(loan_dollars = sum(InitialApprovalAmount)) %>% 
  ungroup() %>% 
 # filter(!is.na(status)) %>% 
  mutate(maj_min = case_when(maj_min == 1 ~ "Majority minority",
                        maj_min == 0 ~ "Not majority minority",
                        T ~ "No data available on ethnic/racial composition"),
         Group = case_when(is.na(status) == T ~ "No data available on ethnic/racial composition",
                           T ~ status),
         `Amount of loan dollars (in billions)` = dollar(loan_dollars/1000000000),
         `Percent of loan dollars` = percent(loan_dollars/sum(loan_dollars))
  )%>% 
  select(-c(loan_dollars,
            status))

combo <- inner_join(percent_ppp_loan_dollars_maj_min_lmi,
                   percent_ppp_loans_maj_min_lmi
                    ) %>% 
  mutate(`Bank type` = "MDI")

combo <- rbind(combo,
               non_mdi_lmi_maj_min %>% 
                 mutate(`Amount of loan dollars (in billions)` = dollar(`Amount of loan dollars`/1000000000),
                        `Percent of loan dollars` = percent(`Percent of loan dollars`/100),
                        `Percent of loans` = percent(`Percent of loans`/100)
                        ) %>% 
                 select(-`Amount of loan dollars`) %>% 
                 filter(!Group %in% c("Not a majority minority zip code",
                                      "Majority minority zip code",
                                      "Not a Low or Middle Income Community",
                                      "Low or Middle Income Community")) %>% 
                 distinct()) %>% 
  distinct()



write_csv(combo,
          '2. Output/LMI and Minority Status.csv')



#Now do the same thing but by race
##############################################
#now do the same thing but by race


#what percent of PPP # amount went to:

# Majority minority + LMI 

percent_ppp_loans_maj_min_lmi <- ppp_loan_data %>% 
  group_by(status,race_bank) %>% 
  count() %>% 
  ungroup() %>% 
  group_by(race_bank) %>% 
  filter(!is.na(status)) %>% 
  mutate(
    Group = case_when(is.na(status) == T ~ "No data available on ethnic/racial composition",
                      T ~ status),
    `Number of loans` = comma(n),
    `Percent of loans` = percent(n/sum(n))
  ) %>% 
  select(-c(n,
            status))

percent_ppp_loan_dollars_maj_min_lmi <- ppp_loan_data %>% 
  group_by(status, race_bank) %>% 
  transmute(
    Group = case_when(is.na(status) == T ~ "No data available on ethnic/racial composition",
                      T ~ status),
    `Loan dollars (in millions)` = sum(InitialApprovalAmount)) %>%
  distinct() %>% 
  group_by(race_bank) %>% 
  mutate(`Percent of loan dollars` = percent(`Loan dollars (in millions)`/sum(`Loan dollars (in millions)`)),
         `Loan dollars (in millions)`= dollar(`Loan dollars (in millions)`/1000000)
  ) %>% 
  select(-status) 

percent_ppp_loans_maj_min_lmi <- inner_join(percent_ppp_loans_maj_min_lmi,
                                            percent_ppp_loan_dollars_maj_min_lmi ) %>% 
  mutate(maj_min = case_when(Group == "Not LMI, majority-minority" |
                               Group == "LMI and majority-minority" ~ "Majority minority",
                             Group == "Neither LMI nor majority-minority" |
                               Group == "LMI, not majority-minority" ~ "Not majority minority",
                             T ~ "No data available on ethnic/racial composition"
  ))
  

write_csv(percent_ppp_loans_maj_min_lmi,
          '2. Output/LMI and Minority Status by race.csv')


overall_table_plot <- percent_ppp_loans_maj_min_lmi %>% 
  select(race_bank,
         Group,
         `Percent of loans`,
         `Majority minority status` =maj_min) %>% 
  rbind(combo %>% 
          select(race_bank = `Bank type`,
                 Group,
                 `Percent of loans`,
                 `Majority minority status` =maj_min)) %>% 
  ungroup() %>% 
  mutate_all(str_remove_all,
             pattern = "%") %>% 
  mutate(Group = case_when(Group == "Not LMI, majority-minority" |
                      Group == "Neither LMI nor majority-minority" ~ "Not an LMI",
                    
                    Group == "LMI and majority-minority" |
                      Group == "LMI, not majority-minority" ~ "LMI",
                    T ~ "No data available on ethnic/racial composition"
  ),
  `Percent of loans` = as.numeric(`Percent of loans`)/100,
  race_bank = factor(case_when(race_bank == "MDI" ~ "All MDIs",
                                      T ~ race_bank),
                            levels= c("Non-MDI",
                                      "All MDIs", 
                                      "American Indian or Alaska Native",
                                      "Asian American or Pacific Islander",
                                      "Black or African American",
                                      "Hispanic or Latino",
                                      "Multi racial"
                                      ))) %>% 
  filter(# Group != "No data available on ethnic/racial composition",
          race_bank != "Multi racial"
         ) %>% 
  ungroup() %>% 
  distinct()

write_csv(overall_table_plot,
          "2. Output/PPP loans by LMI and majority-minority status.csv")


#Now create an excel sheet of the data by race
##############################################
#Now create an excel sheet of the data by race

#Get some basic information about all PPP Lenders
MDI_ppp_loan_size <- ppp_loan_data %>% 
  group_by(ppp_loan_size) %>% 
  count(name = "All MDIs")

MDI_ppp_loan_summary <- ppp_loan_data %>% 
  transmute(`Community Served` = "All MDIs",
            `Number Lenders` = length(unique(OriginatingLenderLocationID)),
            `Total Amt ($m)` = round(sum(InitialApprovalAmount)/1000000,
                                     digits = 1),
            Mean = round(mean(InitialApprovalAmount),
                         digits = 1),
            P10 = quantile(InitialApprovalAmount,
                           .1),
            P50 = quantile(InitialApprovalAmount,
                           .5),
            P90 = quantile(InitialApprovalAmount,
                           .9)) %>% 
  add_count(name = "Number Loans") %>% 
  distinct() 

MDI_ppp_loan_summary<- MDI_ppp_loan_summary[,c('Community Served',
                                               'Number Lenders',
                                               'Number Loans',
                                               'Total Amt ($m)',
                                               'Mean', 
                                               'P10',
                                               'P50',
                                               'P90')]



#Get some basic information about Black PPP Lenders
black_ppp_loan_size <- ppp_loan_data %>% 
  filter(blackBank == 1) %>% 
  group_by(ppp_loan_size) %>% 
  count(name = "Black MDI")

black_ppp_loan_summary <- ppp_loan_data %>% 
  filter(blackBank == 1) %>% 
  transmute(`Community Served` = "Black MDI",
            `Number Lenders` = length(unique(OriginatingLenderLocationID)),
            `Total Amt ($m)` = round(sum(InitialApprovalAmount)/1000000,
                                     digits = 1),
            Mean = round(mean(InitialApprovalAmount),
                         digits = 1),
            P10 = quantile(InitialApprovalAmount,
                           .1),
            P50 = quantile(InitialApprovalAmount,
                           .5),
            P90 = quantile(InitialApprovalAmount,
                           .9)) %>% 
  add_count(name = "Number Loans") %>% 
  distinct() 

black_ppp_loan_summary<- black_ppp_loan_summary[,c('Community Served',
                                                   'Number Lenders',
                                                   'Number Loans',
                                                   'Total Amt ($m)',
                                                   'Mean', 
                                                   'P10',
                                                   'P50',
                                                   'P90')]


#Get some basic information about Hispanic PPP Lenders
hispanic_ppp_loan_size <- ppp_loan_data %>% 
  filter(hispanicBank == 1) %>% 
  group_by(ppp_loan_size) %>% 
  count(name = "Hispanic MDI")

hispanic_ppp_loan_summary <- ppp_loan_data %>% 
  filter(hispanicBank == 1) %>% 
  transmute(`Community Served` = "Hispanic MDI",
            `Number Lenders` = length(unique(OriginatingLenderLocationID)),
            `Total Amt ($m)` = round(sum(InitialApprovalAmount)/1000000,
                                     digits = 1),
            Mean = round(mean(InitialApprovalAmount),
                         digits = 1),
            P10 = quantile(InitialApprovalAmount,
                           .1),
            P50 = quantile(InitialApprovalAmount,
                           .5),
            P90 = quantile(InitialApprovalAmount,
                           .9)) %>% 
  add_count(name = "Number Loans") %>% 
  distinct() 

hispanic_ppp_loan_summary<- hispanic_ppp_loan_summary[,c('Community Served',
                                                         'Number Lenders',
                                                         'Number Loans',
                                                         'Total Amt ($m)',
                                                         'Mean', 
                                                         'P10',
                                                         'P50',
                                                         'P90')]



#Get some basic information about Asian PPP Lenders
AAPI_ppp_loan_size <- ppp_loan_data %>% 
  filter(AAPIBank == 1) %>% 
  group_by(ppp_loan_size) %>% 
  count(name = "AAPI MDI")

AAPI_ppp_loan_summary <- ppp_loan_data %>% 
  filter(AAPIBank == 1) %>% 
  transmute(`Community Served` = "AAPI MDI",
            `Number Lenders` = length(unique(OriginatingLenderLocationID)),
            `Total Amt ($m)` = round(sum(InitialApprovalAmount)/1000000,
                                     digits = 1),
            Mean = round(mean(InitialApprovalAmount),
                         digits = 1),
            P10 = quantile(InitialApprovalAmount,
                           .1),
            P50 = quantile(InitialApprovalAmount,
                           .5),
            P90 = quantile(InitialApprovalAmount,
                           .9)) %>% 
  add_count(name = "Number Loans") %>% 
  distinct() 

AAPI_ppp_loan_summary<- AAPI_ppp_loan_summary[,c('Community Served',
                                                 'Number Lenders',
                                                 'Number Loans',
                                                 'Total Amt ($m)',
                                                 'Mean', 
                                                 'P10',
                                                 'P50',
                                                 'P90')]


#Get some basic information about Native PPP Lenders
AIAN_ppp_loan_size <- ppp_loan_data %>% 
  filter(AIANBank == 1) %>% 
  group_by(ppp_loan_size) %>% 
  count(name = "AIAN MDI")

AIAN_ppp_loan_summary <- ppp_loan_data %>% 
  filter(AIANBank == 1) %>% 
  transmute(`Community Served` = "AIAN MDI",
            `Number Lenders` = length(unique(OriginatingLenderLocationID)),
            `Total Amt ($m)` = round(sum(InitialApprovalAmount)/1000000,
                                     digits = 1),
            Mean = round(mean(InitialApprovalAmount),
                         digits = 1),
            P10 = quantile(InitialApprovalAmount,
                           .1),
            P50 = quantile(InitialApprovalAmount,
                           .5),
            P90 = quantile(InitialApprovalAmount,
                           .9)) %>% 
  add_count(name = "Number Loans") %>% 
  distinct() 

AIAN_ppp_loan_summary<- AIAN_ppp_loan_summary[,c('Community Served',
                                                 'Number Lenders',
                                                 'Number Loans',
                                                 'Total Amt ($m)',
                                                 'Mean', 
                                                 'P10',
                                                 'P50',
                                                 'P90')]



#Get some basic information about Multi PPP Lenders
multi_ppp_loan_size <- ppp_loan_data %>% 
  filter(multiBank == 1) %>% 
  group_by(ppp_loan_size) %>% 
  count(name = "Multi-Racial MDI")

multi_ppp_loan_summary <- ppp_loan_data %>% 
  filter(multiBank == 1) %>% 
  transmute(`Community Served` = "Multi-Racial MDI",
            `Number Lenders` = length(unique(OriginatingLenderLocationID)),
            `Total Amt ($m)` = round(sum(InitialApprovalAmount)/1000000,
                                     digits = 1),
            Mean = round(mean(InitialApprovalAmount),
                         digits = 1),
            P10 = quantile(InitialApprovalAmount,
                           .1),
            P50 = quantile(InitialApprovalAmount,
                           .5),
            P90 = quantile(InitialApprovalAmount,
                           .9)) %>% 
  add_count(name = "Number Loans") %>% 
  distinct() 

multi_ppp_loan_summary<- multi_ppp_loan_summary[,c('Community Served',
                                                   'Number Lenders',
                                                   'Number Loans',
                                                   'Total Amt ($m)',
                                                   'Mean', 
                                                   'P10',
                                                   'P50',
                                                   'P90')]

ppp_loan_summary_table <- rbind(ppp_loan_summaries,
                                rbind(MDI_ppp_loan_summary,
                                      rbind(AAPI_ppp_loan_summary ,
                                            rbind(AIAN_ppp_loan_summary ,
                                                  rbind(black_ppp_loan_summary,
                                                        rbind(hispanic_ppp_loan_summary,
                                                              multi_ppp_loan_summary))))))
ppp_loan_summary_table <- ppp_loan_summary_table %>% 
  rowwise() %>% 
  mutate_at(c('Number Loans',
              'Number Lenders'),
            comma)%>% 
  mutate_at(c('Total Amt ($m)',
              'Mean',
              'P10',
              'P50',
              'P90'),
            dollar) 

write_csv(ppp_loan_summary_table,
          "2. Output/PPP loan summary by race.csv")

loan_size_table <- left_join(ppp_loan_size_table,
                             left_join(MDI_ppp_loan_size, 
                                       left_join(black_ppp_loan_size,
                                                 left_join(hispanic_ppp_loan_size,
                                                           left_join(AAPI_ppp_loan_size,
                                                                     left_join(AIAN_ppp_loan_size,
                                                                                     multi_ppp_loan_size))))))

loan_size_table <- loan_size_table %>% 
  mutate_at(c("Non-MDI",
              "All MDIs",
              "Black MDI",
              "Hispanic MDI",
              "AAPI MDI",
              "AIAN MDI",
              "Multi-Racial MDI"),
            comma
  )

write_csv(loan_size_table,
          "2. Output/PPP loan size table by race.csv")


#Data visualizations
##############################################
#Data visualizations

#PPP number of loans by size
ppp_loan_size_plot <- ppp_loan_data %>% 
  group_by(ppp_loan_size) %>% 
  count(name = "All MDIs") %>% 
  ungroup() %>% 
  distinct() %>%
  inner_join(ppp_loan_size_table) %>% 
  mutate(`All MDIs` = `All MDIs`/sum(`All MDIs`),
         `Non-MDI` = `Non-MDI`/sum(`Non-MDI`)) %>% 
  pivot_longer(.,
               -ppp_loan_size,
               names_to = "group",
               values_to = "n") %>% 
  mutate(ppp_loan_size = factor(ppp_loan_size,
                                levels = c("$0-$10k",
                                           "$10k-$50k",
                                           "$50k-$100k",
                                           "$100k-$500k",
                                           "$500k-$1m",
                                           "$1m+")))

write_csv(ppp_loan_size_plot,
          "2. Output/PPP loan size distribution by bank type.csv")
  

#PPP amount of loan dollars by size
ppp_loan_dollars <- ppp_loan_data %>% 
  group_by(ppp_loan_size) %>% 
  transmute(`All MDIs` = sum(InitialApprovalAmount)) %>%  
  ungroup() %>% 
  distinct() %>% 
  inner_join(ppp_loan_dollars_table) %>% 
  mutate(`All MDIs` = `All MDIs`/sum(`All MDIs`),
         `Non-MDI` = `Non-MDI`/sum(`Non-MDI`),
         ppp_loan_size = factor(ppp_loan_size,
                                levels = c("$0-$10k",
                                           "$10k-$50k",
                                           "$50k-$100k",
                                           "$100k-$500k",
                                           "$500k-$1m",
                                           "1m+"))) %>% 
  pivot_longer(.,
               -ppp_loan_size,
               names_to = "group",
               values_to = "n")
write_csv(ppp_loan_dollars,
          "2. Output/PPP Loan Dollars.csv")
  



#Minority LMI 

ppp_loan_minorityLMI <- combo %>% 
  mutate(`Number of loans` = as.numeric(str_remove(`Number of loans`,
                                                   ",")),
         `Percent of loans` = as.numeric(str_remove(`Percent of loans`,
                                                    "%"))/100,
         Group = factor(Group,
                        levels = c("LMI and majority-minority",
                                   "LMI, not majority-minority",
                                   "Not LMI, majority-minority",
                                   "Neither LMI nor majority-minority",
                                   "No data available on ethnic/racial composition"))
  ) %>% 
  filter(Group!= "No data available on ethnic/racial composition") 
write_csv(ppp_loan_minorityLMI,
          "2. Output/PPP loan LMI and maj-min status.csv")
  



#Data Tables
#############################
#Data Tables

#Region table
region_table <- ppp_loan_data %>% 
  select(RegionName, InitialApprovalAmount) %>% 
  group_by(RegionName) %>% 
  add_count() %>% 
  mutate(
    `Total loan dollars (in millions)` = round(sum(InitialApprovalAmount)/1000000, 
                                               digits = 2),
    `Number of loans` = n) %>% 
  ungroup() %>% 
  select(-InitialApprovalAmount)%>% 
  distinct() %>% 
  mutate(Region = RegionName,
         percentage = `Total loan dollars (in millions)`/sum(`Total loan dollars (in millions)`),
         percentage_loans = `Number of loans`/sum(`Number of loans`))

write_csv(region_table %>% 
            select(c(Region,
                     `Number of loans`,
                     `Total loan dollars (in millions)`)) %>% 
            arrange(desc(`Total loan dollars (in millions)`)),
          "2. Output/Region Table.csv")

intermediate_region_table <- kbl(region_table %>% 
        select(c( Region,
                  `Number of loans`,
                  `Total loan dollars (in millions)`)) %>% 
        arrange(desc(`Total loan dollars (in millions)`)) %>% 
      mutate(`Total loan dollars (in millions)` = dollar(round(`Total loan dollars (in millions)`))),
      format.args = list(big.mark = ","),
      caption = "<b>Table 3: PPP Lending by Region<b>") %>% 
  row_spec(seq(1,nrow(region_table),2), background="#DEDEDE") %>% 
  kable_classic(full_width = F, html_font = "Arial") %>% 
  kable_styling(#bootstrap_options = c("striped", "hover"),
                full_width = F,
                font_size = 12,
                html_font = "Arial")


intermediate_region_table %>% 
  save_kable("4. Tables/Table 3.jpg")
save_kable(intermediate_region_table, file = "4. Tables/Table 3.html")
webshot("4. Tables/Table 3.html", 
        "4. Tables/Table 3.pdf")


#heat map of intensity for originations, and then two-column table of Top 10 states by lending amount Include PR

state_table <- ppp_loan_data %>% 
  select(BorrowerState, InitialApprovalAmount) %>% 
  left_join(state_to_fips,
            by = c("BorrowerState" = "stusps")) %>% 
  mutate(stname = case_when(BorrowerState == "GU" ~ "Guam",
                            BorrowerState == "PR" ~ "Puerto Rico",
                            BorrowerState == "VI" ~ "U.S. Virgin Islands",
                            BorrowerState == "AS" ~ "American Samoa",
                            BorrowerState == "MP" ~ "Northern Mariana Islands",
                            T ~ stname)) %>% 
  select(-c(st,BorrowerState)) %>% 
  rename(BorrowerState = stname) %>% 
  filter(!is.na(BorrowerState)) %>% 
  group_by(BorrowerState) %>% 
  add_count() %>% 
  mutate(
    `Total loan dollars (in millions)` = round(sum(InitialApprovalAmount)/1000000, 
                                               digits = 2),
    `Number of loans` = n) %>% 
  ungroup() %>% 
  select(-InitialApprovalAmount)%>% 
  distinct() %>% 
  mutate(State = BorrowerState,
         percentage = `Total loan dollars (in millions)`/sum(`Total loan dollars (in millions)`),
         percentage_loans = `Number of loans`/sum(`Number of loans`),
         number = factor(case_when(n < 50 ~ "<50",
                                   n < 100 ~ "50-100",
                                   n < 500 ~ "100-500",
                                   n < 1000 ~ "500-1000",
                                   n < 3000 ~ "1000-3000",
                                   n >= 3000 ~ "3000+"),
                         levels = c("<50",
                                    "50-100",
                                    "100-500",
                                    "500-1000",
                                    "1000-3000",
                                    "3000+")),
  )
write_csv(state_table %>% 
            select(c(State,
                     `Number of loans`,
                     `Total loan dollars (in millions)`)) %>% 
            arrange(desc(`Total loan dollars (in millions)`)),
          "2. Output/State Table.csv")


#Corrected to do it by group
state_table_loans_plot <- state_table %>%
  left_join(., 
            urbnmapr::states,
            by = c('BorrowerState' = 'state_name')) 
write_csv(state_table_loans_plot,
          "2. Output/state_table_loans_plot.csv")



state_table_loan_dollars <- state_table %>%
  mutate(Loans = factor(case_when(`Total loan dollars (in millions)` < 50 ~ "<50",
                                  `Total loan dollars (in millions)` < 100 ~ "50-100",
                                  `Total loan dollars (in millions)` < 500 ~ "100-500",
                                  `Total loan dollars (in millions)` < 1000 ~ "500-1000",
                                  `Total loan dollars (in millions)` > 1000 ~ "1000+"),
                        levels = c("<50",
                                   "50-100",
                                   "100-500",
                                   "500-1000",
                                   "1000+"))) %>% 
  left_join(., 
            urbnmapr::states,
            by = c('BorrowerState' = 'state_name'))
write_csv(state_table_loan_dollars,
          "2. Output/state_table_loan_dollars.plot")

#Miscalaneous Paper Facts
############################################
#Miscalaneous Paper Facts

#Find the average loan dollar went to minority communities
weighted.mean(ppp_loan_data$White/ppp_loan_data$`Total Population`,w =ppp_loan_data$InitialApprovalAmount, na.rm=T)

#Find what percentage of loan dollars went to LMI communities

helper <- ppp_loan_data %>%
  mutate(LMIIndicator = case_when(LMIIndicator == "Y" ~ 1, LMIIndicator == "N" ~0))
weighted.mean(helper$LMIIndicator,w =helper$InitialApprovalAmount, na.rm=T)

ppp_loan_data$LMIIndicator
#Find the average loan dollar went to what percentage poverty community
weighted.mean(ppp_loan_data$`Percent below poverty level, zip`,w =ppp_loan_data$InitialApprovalAmount, na.rm=T)

