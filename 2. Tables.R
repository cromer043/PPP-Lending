#Date: 2024/01/18
#Author: Carl Romer
#This file takes the SCF data from 1. Data Cleaning and makes tables for the blog

#########################################################
#Setup
#########################################################
package_list <- c("tidyverse",
                  "purrr",
                  "scales",
                  "openxlsx", 
                  "scales",
                  "devtools", 
                  "extrafont",
                  "tidycensus")

#install.packages(package_list) #if you need to install remove first # on this line
#webshot::install_phantomjs()
lapply(package_list,
       require,
       character.only = T)
#########################################################
#Build functions
#########################################################
S_sqrt <- function(x){sign(x)*sqrt(abs(x))}
IS_sqrt <- function(x){x^2*sign(x)}
S_sqrt_trans <- function() trans_new("S_sqrt",S_sqrt,IS_sqrt)

#########################################################
#Data importation
#########################################################
setwd("C:/Users/csromer/OneDrive - National Bankers Association/Blogs/2024/Survey of Consumer Finances")
net_worth <- read_csv(
  "2. Data Output/net worth.csv"
)

homeowner_net_worth <- read_csv(
  "2. Data Output/homeowner_net_worth.csv"
)

home_equity <- read_csv(
  "2. Data Output/home_equity.csv"
)


household_population <- read_csv(
  "2. Data Output/household pop.csv"
)

homeownership <- read_csv(
  "2. Data Output/homeownership.csv"
)

#########################################################
#tables
#########################################################

#########################################################
#Household population
#########################################################

household_population_kable <- kbl(household_population ,
                                    format.args = list(big.mark = ","),
                                    caption = "<b>Tables 1: DHousehold Population<b>") %>% 
  row_spec(seq(1,nrow(household_population),2), background="#DEDEDE") %>% 
  kable_classic(full_width = F, html_font = "Arial") %>% 
  kable_styling(#bootstrap_options = c("striped", "hover"),
    full_width = F,
    font_size = 12,
    html_font = "Arial")


ppp_loan_summary_table_kable %>% 
  save_kable("4. Tables/Table 1.jpg")
save_kable(ppp_loan_summary_table_kable, file = "4. Tables/Table 1.html")
webshot("4. Tables/Table 1.html", 
        "4. Tables/Table 1.pdf")