# PPP-Lending
This Folder is the PPP Loan Project
We use data from SBA and the FDIC’s list of MDI’s to examine how and where PPP Loans went
0.	Data houses all the data
1.	Draft: houses outline of the blog and the drafts 
2.	Output: houses all created excel sheets that create the graphs and tables
3.	Graphs: houses all graphs created
4.	Tables: houses all tables as HTMLs PDF and JPGs
5.	Outmoded: Previous versions of the study
6.	Final Product: Houses the final draft to be published online
In the main folder is the code
0.	Full PPP Loans Code.Py downloads all the data by scraping from the web, and places necessary files in 0. Data. Some data cleaning takes place and banks are merged in an initial stage, then some names are cleaned/updated, some cities are neighborhoods and that is corrected and a fuzzy merge is performed. We get a final number of MDIs
1.	Import census data.r : Imports census data for analysis in MDI and non-MDI communities
2.	Non MDI PPP Loan code.py gets numbers for analysis for Non-MDIs
3.	MDI PPP loan code.r gets numbers for analysis for MDIs 
4.	Graph codes: Puts all of the numbers from 2 and 3 into graphs and tables
5.	AIAN Troubleshoot: We found that AIAN banks didn’t loan to minority majority zip codes, so we examine if they loaned to majority minority census tracts instead
