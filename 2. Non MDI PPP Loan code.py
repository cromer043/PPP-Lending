# -*- coding: utf-8 -*-
"""
Created on Wed Aug  2 11:40:17 2023

@author: csromer
"""
import pandas as pd
import numpy as np

non_mdi_ppp_loan_data = pd.read_csv("C:/Users/csromer/OneDrive - National Bankers Association/Blogs/2023/PPP Loan Blog/0. Data/PPP Loan Data nonMDI.csv")
census_data = pd.read_csv("C:/Users/csromer/OneDrive - National Bankers Association/Blogs/2023/PPP Loan Blog/0. Data/census data.csv")
zip_to_zcta = pd.read_csv("C:/Users/csromer/OneDrive - National Bankers Association/Blogs/2023/PPP Loan Blog/0. Data/ZIPCodetoZCTACrosswalk2021UDS.csv")
non_mdi_ppp_loan_data['ZIP_CODE'] = pd.to_numeric(non_mdi_ppp_loan_data['BorrowerZip'].str.slice(0,5))

zcta_and_zip = pd.merge(zip_to_zcta,
                        census_data,
                        left_on= ['ZCTA'],
                        right_on= ['zip code'])

joined = pd.merge(non_mdi_ppp_loan_data,
                  zcta_and_zip,
                  how = 'left',
                  indicator= True)

#Repeat loan PPP Loan Size Table 
joined['ppp_loan_size'] = 'Unknown'
joined.loc[(pd.to_numeric(joined['InitialApprovalAmount'])<10000),
           'ppp_loan_size'] = '$0-$10k'
joined.loc[(pd.to_numeric(joined['InitialApprovalAmount'])>=10000) & 
           (pd.to_numeric(joined['InitialApprovalAmount'])<50000), 
           'ppp_loan_size'] = '$10k-$50k'
joined.loc[(pd.to_numeric(joined['InitialApprovalAmount'])>=50000) & 
           (pd.to_numeric(joined['InitialApprovalAmount'])<100000), 
           'ppp_loan_size'] = '$50k-$100k'
joined.loc[(pd.to_numeric(joined['InitialApprovalAmount'])>=100000) & 
           (pd.to_numeric(joined['InitialApprovalAmount'])<500000), 
           'ppp_loan_size'] = '$100k-$500k'
joined.loc[(pd.to_numeric(joined['InitialApprovalAmount'])>=500000) & 
           (pd.to_numeric(joined['InitialApprovalAmount'])<1000000), 
           'ppp_loan_size'] = '$500k-$1m'
joined.loc[(pd.to_numeric(joined['InitialApprovalAmount'])>=1000000) , 
           'ppp_loan_size'] = '$1m+'



ppp_loan_size_table = {'Non-MDI':joined.groupby('ppp_loan_size').size()
                       }

ppp_loan_size_table = pd.DataFrame(ppp_loan_size_table)
ppp_loan_size_table.to_csv("C:/Users/csromer/OneDrive - National Bankers Association/Blogs/2023/PPP Loan Blog/0. Data/ppp_loan_size_table.csv")


#Similarly get loan size by dollars
ppp_loan_dollars_size_table = {'Non-MDI':joined.groupby('ppp_loan_size')['InitialApprovalAmount'].sum()                               
                       }

ppp_loan_dollars_size_table = pd.DataFrame(ppp_loan_dollars_size_table)
ppp_loan_dollars_size_table.to_csv("C:/Users/csromer/OneDrive - National Bankers Association/Blogs/2023/PPP Loan Blog/0. Data/ppp_loan_dollars_size_table.csv")


#Repeat ppp loan summaries by race

ppp_loan_summaries_by_race = {'Community Served':['Non-MDI'],
        'Number Lenders':joined['ServicingLenderLocationID'].nunique(),
        'Number Loans':len(joined),
        'Total Amt ($m)':sum(joined['InitialApprovalAmount'])/1000000,
        'Mean': np.mean(joined['InitialApprovalAmount']),
        'P10': np.percentile(joined['InitialApprovalAmount'], 
                             10),
        'P50': np.percentile(joined['InitialApprovalAmount'], 
                             50),
        'P90': np.percentile(joined['InitialApprovalAmount'], 
                             90)
       }
  
ppp_loan_summaries_by_race = pd.DataFrame(ppp_loan_summaries_by_race)

ppp_loan_summaries_by_race.to_csv("C:/Users/csromer/OneDrive - National Bankers Association/Blogs/2023/PPP Loan Blog/0. Data/ppp_loan_summaries_by_race.csv")
#Get miscaleanneous numbers for paper
#Find the average loan dollar went to poverty communities

povertypercentage = np.ma.MaskedArray(joined['Percent below poverty level, zip'], mask=np.isnan(joined['Percent below poverty level, zip']))

np.average(povertypercentage, 
           weights=joined['InitialApprovalAmount'])
#Find the average loan dollar went to minority communities
joined['WhiteP'] = joined['White']/joined['Total Population']
Whitepercentage = np.ma.MaskedArray(joined['WhiteP'], mask=np.isnan(joined['WhiteP']))
np.average(Whitepercentage, 
           weights=joined['InitialApprovalAmount'])


#Find the average loan dollar went to LMI communities
joined['LMIindicator'] = 0
joined.loc[(joined['LMIIndicator']=="Y"),
           'LMIindicator'] = 1
np.average(joined['LMIindicator'], 
           weights=joined['InitialApprovalAmount'])


joined.groupby(by='LMIindicator')['InitialApprovalAmount'].sum()[0]

joined['WhiteP'].isnull().sum() * 100 / len(joined)

joinednarm = joined
joinednarm=joinednarm.dropna(subset=["WhiteP"])

#Create status indicator for Majority minority
joinednarm['maj_min'] = 0
joinednarm.loc[(joinednarm['WhiteP']<0.5),
           'maj_min'] = 1
sum(joinednarm['maj_min'])/len(joined)

#Create status indicator for Majority minority LMI
joinednarm['maj_minLMI'] = 0
joinednarm.loc[(joinednarm['WhiteP']<0.5) & (joinednarm['LMIIndicator']=="Y"),
           'maj_minLMI'] = 1
np.mean(joinednarm['maj_minLMI'])

#Create status indicator for Majority minority nonLMI
joinednarm['maj_min_non_LMI'] = 0
joinednarm.loc[(joinednarm['WhiteP']<0.5) & (joinednarm['LMIIndicator']=="N"),
           'maj_min_non_LMI'] = 1
np.mean(joinednarm['maj_min_non_LMI'])

#Create status indicator for Non Majority minority LMI
joinednarm['non_maj_min_LMI'] = 0
joinednarm.loc[(joinednarm['WhiteP']>=0.5) & (joinednarm['LMIIndicator']=="Y"),
           'non_maj_min_LMI'] = 1
np.mean(joinednarm['non_maj_min_LMI'])

#Create status indicator for Non Majority minority Non LMI
joinednarm['non_maj_min_nonLMI'] = 0
joinednarm.loc[(joinednarm['WhiteP']>=0.5) & (joinednarm['LMIIndicator']=="N"),
           'non_maj_min_nonLMI'] = 1
np.mean(joinednarm['non_maj_min_nonLMI'])

#Put into dataframe

LMI_and_Minority_Status = {'Group':[
                                       'LMI and majority-minority',
                                       'LMI, not majority-minority',
                                       'Neither LMI nor majority-minority',
                                       'Not LMI, majority-minority',
                                       'No data available on ethnic/racial composition'],
    
        'maj_min':['Majority minority',
                   'Not majority minority',
                   'Not majority minority',
                   'Majority minority',
                   'No data available on ethnic/racial composition'],
        'Number of loans':[
                           sum(joinednarm['maj_minLMI']),
                           sum(joinednarm['non_maj_min_LMI']),
                           sum(joinednarm['non_maj_min_nonLMI']),
                           sum(joinednarm['maj_min_non_LMI']),
                           len(joined)-len(joinednarm),
                           ],
        
        'Percent of loans':[
                            np.mean(joinednarm['maj_minLMI']),
                            np.mean(joinednarm['non_maj_min_LMI']),
                            np.mean(joinednarm['non_maj_min_nonLMI']),
                            np.mean(joinednarm['maj_min_non_LMI']),
                            (len(joined)-len(joinednarm))/len(joined)
                            ],
        'Amount of loan dollars':[
                                  joinednarm.groupby(by='maj_minLMI')['InitialApprovalAmount'].sum()[1],
                                  joinednarm.groupby(by='non_maj_min_LMI')['InitialApprovalAmount'].sum()[1],
                                  joinednarm.groupby(by='non_maj_min_nonLMI')['InitialApprovalAmount'].sum()[1],
                                  joinednarm.groupby(by='maj_min_non_LMI')['InitialApprovalAmount'].sum()[1],                                  
                                  sum(joined['InitialApprovalAmount'])-sum(joinednarm['InitialApprovalAmount'])
                                  ],
        'Percent of loan dollars':[
                                  joinednarm.groupby(by='maj_minLMI')['InitialApprovalAmount'].sum()[1]/sum(joined['InitialApprovalAmount']),
                                  joinednarm.groupby(by='non_maj_min_LMI')['InitialApprovalAmount'].sum()[1]/sum(joined['InitialApprovalAmount']),
                                  joinednarm.groupby(by='non_maj_min_nonLMI')['InitialApprovalAmount'].sum()[1]/sum(joined['InitialApprovalAmount']),
                                  joinednarm.groupby(by='maj_min_non_LMI')['InitialApprovalAmount'].sum()[1]/sum(joined['InitialApprovalAmount']),                                  
                                  (sum(joined['InitialApprovalAmount'])-sum(joinednarm['InitialApprovalAmount']))/sum(joined['InitialApprovalAmount'])
                                  ]
       }
  
LMI_and_Minority_Status = pd.DataFrame(LMI_and_Minority_Status)
LMI_and_Minority_Status['Percent of loans']= LMI_and_Minority_Status['Percent of loans']*100
LMI_and_Minority_Status['Percent of loan dollars']= LMI_and_Minority_Status['Percent of loan dollars']*100

LMI_and_Minority_Status.to_csv("C:/Users/csromer/OneDrive - National Bankers Association/Blogs/2023/PPP Loan Blog/2. Output/Non MDIs LMI and Minority Status.csv")


#non-MDI comparison with 5.AIAN Troubleshoot
joinednarm['AIANP'] = joinednarm['AIAN']/joinednarm['Total Population']
#Create status indicator for AIAN Majority 
joinednarm['aian_maj'] = 0
joinednarm.loc[(joinednarm['AIANP']>0.5),
           'aian_maj'] = 1
np.mean(joinednarm['aian_maj'])
aian_maj = joinednarm[joinednarm['aian_maj']==1]
print()
print(len(aian_maj))
print(aian_maj['zip code'].nunique())
AIAN_MDI_zips =(74960,
                                    74359,
                                    28372,
                                    28360,
                                    28383,
                                    28364,
                                    28386,
                                    99723,
                                    99926,
                                    86434,
                                    85256,
                                    86511,
                                    86515,
                                    86040,
                                    59417, 
                                    68071,
                                    57555,
                                    84026, 
                                    99670, 
                                    99576, 
                                    86504, 
                                    59521, 
                                    87026, 
                                    57752,
                                    54135, 
                                    54538, 
                                    58316, 
                                    58853, 
                                    58367,
                                    58369,
                                    58329,
                                    58538, 
                                    57642)
