# -*- coding: utf-8 -*-
"""
Created on Wed July 5 11:40:17 2023

@author: csromer
"""
#pip install pandas
#pip install fuzzywuzzy
#pip install levenshtein
#pip install difflib
#pip install fuzzymatcher
#pip install cenpy
#pip install census
#pip install us
#pip install csv
#pip install datetime

from fuzzywuzzy import process
import pandas as pd
import numpy as np

#Import MDI Data
historical_mdi_link = 'https://www.fdic.gov/regulations/resources/minority/mdi-history.xlsx'
mdi_link_2023 = 'https://www.fdic.gov/regulations/resources/minority/2023q1.xlsx'

combined_mdi = pd.concat([pd.read_excel(historical_mdi_link,
                                            "2020",
                                            skiprows= 4,
                                            usecols = [1,2,3,8],
                                            names = ("Name",
                                                    "City",
                                                    "State",
                                                    "Minority Status")),
                          pd.read_excel(historical_mdi_link,
                                            "2021",
                                            skiprows= 4,
                                            usecols = [1,2,3,8],
                                            names = ("Name",
                                                    "City",
                                                    "State",
                                                    "Minority Status"))                         
                          
                             ])
combined_mdi = combined_mdi.reset_index() #reset rownames as they are based on which file they're frokm
combined_mdi = combined_mdi[combined_mdi.columns[1:]] #Remove those rownames

#normalize MDI data -- will do same procedure on other dataset to merge
combined_mdi = combined_mdi.dropna() #Remove Missing Data 
    
    
combined_mdi['Name'] = combined_mdi['Name'].str.replace('[^\w\s]',
                                                        '',
                                                        regex=True) #remove punctuation
combined_mdi['Name'] = combined_mdi['Name'].str.replace(' ', 
                                                        '',
                                                        regex=True) #remove spaces

combined_mdi['Name'] = combined_mdi['Name'].apply(str.lower) #Convert all data to lowercase


combined_mdi['City'] = combined_mdi['City'].astype(str) #convert to string
combined_mdi['City'] = combined_mdi['City'].apply(str.lower) #Convert all data to lowercase
combined_mdi['City'] = combined_mdi['City'].str.replace('[^\w\s]', #remove Punctuation
                                                        '',
                                                        regex=True)
combined_mdi['City'] = combined_mdi['City'].str.replace(' ', 
                                                        '',
                                                        regex=True) #remove spaces


combined_mdi['State'] = combined_mdi['State'].astype(str) #convert to string
combined_mdi['State'] = combined_mdi['State'].apply(str.lower) #Convert all data to lowercase
combined_mdi['State'] = combined_mdi['State'].str.replace('[^\w\s]', #remove Punctuation
                                                          '',
                                                          regex=True)
combined_mdi['State'] = combined_mdi['State'].str.replace(' ', 
                                                          '',
                                                          regex=True) #remove spaces

combined_mdi['Name'] = combined_mdi['Name'].replace('nationalassociation',
                                                    'na',
                                                    regex=True) 
combined_mdi['Name'] = combined_mdi['Name'].replace('nationalassn',
                                                    'na',
                                                    regex=True) 
combined_mdi['Name'] = combined_mdi['Name'].replace('andtrustcompany',
                                                    'trustco',
                                                    regex=True) 
combined_mdi['Name'] = combined_mdi['Name'].replace('btco','banktrustco',
                                                    regex=True) 
combined_mdi['Name'] = combined_mdi['Name'].replace('intl','international',
                                                    regex=True) 
combined_mdi['Name'] = combined_mdi['Name'].replace('california',
                                                    'ca',
                                                    regex=True) 
combined_mdi['Name'] = combined_mdi['Name'].replace('bank',
                                                    'bk',
                                                    regex=True) 
combined_mdi['Name'] = combined_mdi['Name'].replace('commerce',
                                                    'com',
                                                    regex=True)
combined_mdi['Name'] = combined_mdi['Name'].replace('the',
                                                    '',
                                                    regex=True) 
combined_mdi['Name'] = combined_mdi['Name'].replace('1st',
                                                    'first',
                                                    regex=True)
combined_mdi['Name'] = combined_mdi['Name'].replace('state',
                                                    'st',
                                                    regex=True) 
combined_mdi['Name'] = combined_mdi['Name'].replace('bof',
                                                    'bkof',
                                                    regex=True)        
combined_mdi['Name'] = combined_mdi['Name'].replace('national',
                                                    'n',
                                                    regex=True) 

combined_mdi = combined_mdi.drop_duplicates(ignore_index = True)

#Import PPP Loan Data
filenames = ("https://data.sba.gov/dataset/8aa276e2-6cab-4f86-aca4-a7dde42adf24/resource/738e639c-1fbf-4e16-beb0-a223831011e8/download/public_150k_plus_230930.csv",
                          "https://data.sba.gov/dataset/8aa276e2-6cab-4f86-aca4-a7dde42adf24/resource/a7fa66f4-fd2e-433c-8ef9-59780ef60ae5/download/public_up_to_150k_1_230930.csv",
                          "https://data.sba.gov/dataset/8aa276e2-6cab-4f86-aca4-a7dde42adf24/resource/7d2308a8-0ac1-48a8-b21b-f9eb373ac417/download/public_up_to_150k_2_230930.csv",
                          "https://data.sba.gov/dataset/8aa276e2-6cab-4f86-aca4-a7dde42adf24/resource/5158aae1-066d-4d01-a226-e44ecc9bdda7/download/public_up_to_150k_3_230930.csv",
                          "https://data.sba.gov/dataset/8aa276e2-6cab-4f86-aca4-a7dde42adf24/resource/d888bab1-da5b-46f2-bed2-a052d48af246/download/public_up_to_150k_4_230930.csv",
                          "https://data.sba.gov/dataset/8aa276e2-6cab-4f86-aca4-a7dde42adf24/resource/ee12d751-2bb4-4343-8330-32311ae4e7c7/download/public_up_to_150k_5_230930.csv",
                          "https://data.sba.gov/dataset/8aa276e2-6cab-4f86-aca4-a7dde42adf24/resource/27b874d9-a059-4296-bb74-374294c48616/download/public_up_to_150k_6_230930.csv",
                          "https://data.sba.gov/dataset/8aa276e2-6cab-4f86-aca4-a7dde42adf24/resource/434efae0-016a-48da-92dc-c6f113d827c1/download/public_up_to_150k_7_230930.csv",
                          "https://data.sba.gov/dataset/8aa276e2-6cab-4f86-aca4-a7dde42adf24/resource/4fc8e993-c3b9-4eb2-b9bb-dfbde9b1fb6f/download/public_up_to_150k_8_230930.csv",
                          "https://data.sba.gov/dataset/8aa276e2-6cab-4f86-aca4-a7dde42adf24/resource/7f9c6867-2b55-472e-a4f3-fd0f5f27f790/download/public_up_to_150k_9_230930.csv",
                          "https://data.sba.gov/dataset/8aa276e2-6cab-4f86-aca4-a7dde42adf24/resource/a8f2c8b2-facb-4e97-ad5f-7c8736c8b4b6/download/public_up_to_150k_10_230930.csv",
                          "https://data.sba.gov/dataset/8aa276e2-6cab-4f86-aca4-a7dde42adf24/resource/6f9787a3-afd6-45b2-b78e-ad0dc097c1c3/download/public_up_to_150k_11_230930.csv",
                          "https://data.sba.gov/dataset/8aa276e2-6cab-4f86-aca4-a7dde42adf24/resource/b6528428-fbd9-4ca6-ae08-9e3416f8ee7f/download/public_up_to_150k_12_230930.csv")
ppp_loan_data = pd.concat([pd.read_csv(f) for f in filenames])

check = ppp_loan_data
check[check['BorrowerName'] == 'SMARTSKY NETWORKS LLC']


#Normalize data -- have done same procedure on other dataset to merge
ppp_loan_data['BankName'] = ppp_loan_data['OriginatingLender'].str.replace(' ', 
                                                                                        '',
                                                                                        regex=True) #remove spaces
ppp_loan_data['BankName'] = ppp_loan_data['BankName'].astype(str) #convert to string
ppp_loan_data['BankName'] = ppp_loan_data['BankName'].apply(str.lower) #Convert all data to lowercase
ppp_loan_data['BankName'] = ppp_loan_data['BankName'].str.replace('[^\w\s]', #remove punctuation
                                                                                        '',
                                                                                        regex=True)
ppp_loan_data['BankName'] = ppp_loan_data['BankName'].str.replace(' ', 
                                                                                        '',
                                                                                        regex=True) #remove spaces

ppp_loan_data['BankCity'] = ppp_loan_data['OriginatingLenderCity'].astype(str) #convert to string
ppp_loan_data['BankCity'] = ppp_loan_data['BankCity'].apply(str.lower) #Convert all data to lowercase
ppp_loan_data['BankCity'] = ppp_loan_data['BankCity'].str.replace('[^\w\s]', #remove Punctuation
                                                                                        '',
                                                                                        regex=True)
ppp_loan_data['BankCity'] = ppp_loan_data['BankCity'].str.replace(' ', 
                                                                                        '',
                                                                                        regex=True) #remove spaces


ppp_loan_data['BankState'] = ppp_loan_data['OriginatingLenderState'].astype(str) #convert to string
ppp_loan_data['BankState'] = ppp_loan_data['BankState'].apply(str.lower) #Convert all data to lowercase
ppp_loan_data['BankState'] = ppp_loan_data['BankState'].str.replace('[^\w\s]', #remove Punctuation
                                                                                        '',
                                                                                        regex=True)
ppp_loan_data['BankState'] = ppp_loan_data['BankState'].str.replace(' ', 
                                                                                        '',
                                                                                        regex=True) #remove spaces


ppp_loan_data['BankName'] = ppp_loan_data['BankName'].replace('nationalassociation',
                                                                                    'na',
                                                                                    regex=True)
ppp_loan_data['BankName'] = ppp_loan_data['BankName'].replace('nationalassn',
                                                                                    'na',
                                                                                    regex=True) 
ppp_loan_data['BankName'] = ppp_loan_data['BankName'].replace('andtrustcompany',
                                                                                    'trustco',
                                                                                    regex=True) 
ppp_loan_data['BankName'] = ppp_loan_data['BankName'].replace('btco',
                                                                                    'banktrustco',
                                                                                    regex=True) 
ppp_loan_data['BankName'] = ppp_loan_data['BankName'].replace('intl',
                                                                                    'international', 
                                                                                    regex=True) 
ppp_loan_data['BankName'] = ppp_loan_data['BankName'].replace('california',
                                                                                    'california', 
                                                                                    regex=True) 
ppp_loan_data['BankName'] = ppp_loan_data['BankName'].replace('bank',
                                                                                    'bk', 
                                                                                    regex=True) 
ppp_loan_data['BankName'] = ppp_loan_data['BankName'].replace('commerce',
                                                                                    'com', 
                                                                                    regex=True) 
ppp_loan_data['BankName'] = ppp_loan_data['BankName'].replace('the',
                                                                                    '', 
                                                                                    regex=True) 
ppp_loan_data['BankName'] = ppp_loan_data['BankName'].replace('1st',
                                                                                    'first',
                                                                                    regex=True) 
ppp_loan_data['BankName'] = ppp_loan_data['BankName'].replace('state',
                                                                                    'st',
                                                                                    regex=True) 
ppp_loan_data['BankName'] = ppp_loan_data['BankName'].replace('bof',
                                                                                    'bkof',
                                                                                    regex=True)
ppp_loan_data['BankName'] = ppp_loan_data['BankName'].replace('national',
                                                                                    'n',
                                                                                    regex=True)
ppp_loan_data['BankName'] = ppp_loan_data['BankName'].replace('bank',
                                                              'bk',
                                                              regex=True) 

   

ppp_mdi = pd.merge(combined_mdi, 
                   ppp_loan_data, left_on= ['Name', 
                                            'City',
                                            'State'], 
                   right_on = ['BankName', 
                               'BankCity',
                               'BankState'], 
                   how='inner')

print("Total number of loans")
print(len(ppp_loan_data.index))
print("Total number of MDI loans")
print(len(ppp_mdi.index))
print("Total percentage of MDI Loans")
print(len(ppp_mdi.index)/len(ppp_loan_data.index))

print("Total loan dollars")
print(sum(ppp_loan_data['InitialApprovalAmount']))
print("Total MDI loan dollars")
print(sum(ppp_mdi['InitialApprovalAmount']))
print("Total percentage of MDI loan dollars")
print(sum(ppp_mdi['InitialApprovalAmount'])/sum(ppp_loan_data['InitialApprovalAmount']))


#Now try to fuzzy merge to get to the 4% figure that is referenced elsewhere

def fuzzy_merge(df_1, df_2, left_on, right_on, threshold, limit, matches):
    """
    :param df_1: the left table to join
    :param df_2: the right table to join
    :param left_on: key column of the left table
    :param right_on: key column of the right table
    :param threshold: how close the matches should be to return a match, based on Levenshtein distance
    :param limit: the amount of matches that will get returned, these are sorted high to low
    :return: dataframe with boths keys and matches
    """
   # c = list(df_1.columns) #get column names of first dataframe
    
    s = df_2[right_on].tolist() #Get vector of merging of second dataframe
    
    m = df_1[left_on].apply(lambda x: process.extract(x, s, limit=limit))  #merge vector of first dataframe with vector of second   
    
    df_1[matches] = m #Apply vector of matches to first dataframe
    m2 = df_1[matches].apply(lambda x: ', '.join([i[0] for i in x if i[1] >= threshold])) 
    df_1[matches] = m2
    return df_1
  

data1 = {'numbr': ['one','two','three','four','five', 'not a close string'],
                   'letter': ['a','b','c','d','e', 'l'],
                  'Third': ['every', 'good', 'boy', 'does', 'fine', 'a']
        }
data2 = {'numbrclose': ['on','twos','three','fourty','fiv', 'ive', 'fiv'],
                   'letters': ['x','y','z','r','f', 'h', 'g'],
                   'next': ['f','a','c','e','f','a','c']
        }
df1 = pd.DataFrame(data1)
colnames = list(df1.columns)

df2 = pd.DataFrame(data2)


fuzzy_merge(df1,df2,left_on = 'numbr', right_on = 'numbrclose', threshold = 80, limit = 100, matches = "match")
df1 = df1.set_index(colnames).apply(lambda x : x.str.split(',')).stack().apply(pd.Series).stack().unstack(level=2).reset_index(level=[0,1])


#Oklahoma State Bank 58846 changed name to RCB Bank

ppp_loan_data.loc[ppp_loan_data['BankName'] == 'rcbbk', "BankCity"] = 'vinita'
ppp_loan_data.loc[ppp_loan_data['BankName'] == 'rcbbk', "BankName"] = 'oklahomastatebk'

#California Pacific Bank 11867 to CA Pacific Bank

ppp_loan_data.loc[ppp_loan_data['OriginatingLender'] == 'California Pacific Bank', "BankName"] = 'capacificbk'

#Amerasia Bank 112305

ppp_loan_data.loc[ppp_loan_data['OriginatingLenderLocationID'] == 112305, "BankCity"] = 'flushing'

#Ponce Bank 88717

ppp_loan_data.loc[ppp_loan_data['OriginatingLenderLocationID'] == 88717, "BankCity"] = 'bronx'

#Banesco USA 437582

ppp_loan_data.loc[ppp_loan_data['OriginatingLenderLocationID'] == 437582, "BankCity"] = 'coralgables'


#California International Bank, A National Banking Association 437143

ppp_loan_data.loc[ppp_loan_data['OriginatingLenderLocationID'] == 437143, "BankName"] = 'cainternbkna'


#California International Bank, A National Banking Association 444264

ppp_loan_data.loc[ppp_loan_data['OriginatingLenderLocationID'] == 444264, "BankCity"] = 'flushing'


ppp_loan_data_banks = ppp_loan_data[['BankName',
                                     'OriginatingLenderLocationID']] #Originating Lender Location ID is bank unique identifier

ppp_loan_data_cities = ppp_loan_data[['BankCity',
                                     'OriginatingLenderLocationID']]

ppp_loan_data_states = ppp_loan_data[['BankState',
                                     'OriginatingLenderLocationID']]

ppp_loan_data_banks = ppp_loan_data_banks.drop_duplicates()
ppp_loan_data_cities = ppp_loan_data_cities.drop_duplicates()
ppp_loan_data_states = ppp_loan_data_states.drop_duplicates()

colnames_banks = list(ppp_loan_data_banks.columns)
colnames_cities = list(ppp_loan_data_cities.columns)
colnames_states = list(ppp_loan_data_states.columns)

fuzzy_merge(ppp_loan_data_banks,
            combined_mdi,
            left_on = 'BankName',
            right_on = 'Name', threshold = 85, limit = 10000, matches = "NameMatch")


fuzzy_merge(ppp_loan_data_cities,
            combined_mdi,
            left_on = 'BankCity',
            right_on = 'City', threshold = 85, limit = 200, matches = "CityMatch")


fuzzy_merge(ppp_loan_data_states,
            combined_mdi,
            left_on = 'BankState',
            right_on = 'State', threshold = 90, limit = 200, matches = "StateMatch")


ppp_loan_data_banks = ppp_loan_data_banks.set_index(colnames_banks).apply(lambda x : x.str.split(',')).stack().apply(pd.Series).stack().unstack(level=2).reset_index(level=[0,1])
ppp_loan_data_cities = ppp_loan_data_cities.set_index(colnames_cities).apply(lambda x : x.str.split(',')).stack().apply(pd.Series).stack().unstack(level=2).reset_index(level=[0,1])
ppp_loan_data_states = ppp_loan_data_states.set_index(colnames_states).apply(lambda x : x.str.split(',')).stack().apply(pd.Series).stack().unstack(level=2).reset_index(level=[0,1])

ppp_loan_data_banks['NameMatch'] = ppp_loan_data_banks['NameMatch'].str.replace(' ', 
                                                                                    '',
                                                                                    regex=True) #remove spaces
ppp_loan_data_cities['CityMatch'] = ppp_loan_data_cities['CityMatch'].str.replace(' ', 
                                                                                    '',
                                                                                    regex=True) #remove space
ppp_loan_data_states['StateMatch'] = ppp_loan_data_states['StateMatch'].str.replace(' ', 
                                                                                    '',
                                                                                    regex=True) #remove spaces

ppp_loan_data_banks = ppp_loan_data_banks.drop_duplicates()
ppp_loan_data_cities = ppp_loan_data_cities.drop_duplicates()
ppp_loan_data_states = ppp_loan_data_states.drop_duplicates()

ppp_loan_data_fuzzy_merged = pd.merge(ppp_loan_data_banks,
                                ppp_loan_data_cities,
                                how = 'inner')

ppp_loan_data_fuzzy_merged = pd.merge(ppp_loan_data_fuzzy_merged,
                                ppp_loan_data_states,
                                how = 'inner')
ppp_loan_data_fuzzy_merged = ppp_loan_data_fuzzy_merged.replace(r'^\s*$', np.nan, regex=True)
ppp_loan_data_fuzzy_merged = ppp_loan_data_fuzzy_merged.dropna(subset = ['NameMatch',
                                                             'CityMatch',
                                                             'StateMatch'])

#EVERTRUST BANK 119161 changed cities 
#Pacific Alliance 445008 changed cities
ppp_loan_data_fuzzy_merged.loc[ppp_loan_data_fuzzy_merged['NameMatch'] == 'evertrustbk', "CityMatch"] = 'pasadena'
ppp_loan_data_fuzzy_merged.loc[ppp_loan_data_fuzzy_merged['NameMatch'] == 'pacificalliancebk', "CityMatch"] = 'rosemead'


ppp_loan_data_fuzzy_merged =pd.merge(combined_mdi, 
                   ppp_loan_data_fuzzy_merged, 
                   left_on= ['Name',
                             'City',
                             'State'], 
                   right_on = ['NameMatch',
                               'CityMatch',
                               'StateMatch'], 
                   how='inner')
ppp_loan_data_fuzzy_merged = ppp_loan_data_fuzzy_merged[~(ppp_loan_data_fuzzy_merged['OriginatingLenderLocationID'].eq(69787) &  #More likely match found
                             ppp_loan_data_fuzzy_merged['NameMatch'].eq('unitynbkofhouston') )]

ppp_loan_data_fuzzy_merged = pd.merge(ppp_loan_data_fuzzy_merged, 
                                      ppp_loan_data, 
                                      how='inner')

MDIs_list = ppp_loan_data_fuzzy_merged['OriginatingLenderLocationID'].unique()

print("total unique lenders")
print(ppp_loan_data['OriginatingLenderLocationID'].nunique())

print("total unique mdi lenders")
print(ppp_loan_data_fuzzy_merged['OriginatingLenderLocationID'].nunique())

print("Total number of loans")
print(len(ppp_loan_data.index))
print("Total number of MDI loans")
print(len(ppp_loan_data_fuzzy_merged.index))
print("Total percentage of MDI Loans")
print(len(ppp_loan_data_fuzzy_merged.index)/len(ppp_loan_data.index)*100)

print("Total loan dollars")
print(sum(ppp_loan_data['InitialApprovalAmount']))
print("Total MDI loan dollars")
print(sum(ppp_loan_data_fuzzy_merged['InitialApprovalAmount']))
print("Total percentage of MDI loan dollars")
print(sum(ppp_loan_data_fuzzy_merged['InitialApprovalAmount'])/sum(ppp_loan_data['InitialApprovalAmount'])*100)

ppp_loan_data_fuzzy_merged.to_csv("C:/Users/csromer/OneDrive - National Bankers Association/Blogs/2023/PPP Loan Blog/0. Data/PPP Loan Data MDI.csv")

##########################################
#Generate data for non-MDIs

ppp_loan_data['MDI Flag'] = ppp_loan_data['OriginatingLenderLocationID'].isin(MDIs_list)

ppp_loan_data_non_MDI = ppp_loan_data[ppp_loan_data['MDI Flag'] == False]

ppp_loan_data_non_MDI.to_csv("C:/Users/csromer/OneDrive - National Bankers Association/Blogs/2023/PPP Loan Blog/0. Data/PPP Loan Data nonMDI.csv")
