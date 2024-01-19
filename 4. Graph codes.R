#Date (DMY): 07/24/2023
#Author: CSR
#This file explores the PPP Loan data merged with the MDI list from FDIC
# We want to graph what was made in 3. MDI PPP Loan code
setwd("C:/Users/csromer/OneDrive - National Bankers Association/Blogs/2023/PPP Loan Blog")
package_list <- c("tidyverse",
                  "purrr",
                  "kableExtra",
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

# Import data
lmi_majmin <- read_csv('2. Output/LMI and Minority Status.csv')
lmi_majmin_race <- read_csv("2. Output/PPP loans by LMI and majority-minority status.csv")
ppp_loan_size <- read_csv("2. Output/PPP loan size distribution by bank type.csv")
ppp_loan_dollars <- read_csv("2. Output/PPP Loan Dollars.csv")
ppp_loan_minorityLMI <- read_csv( "2. Output/PPP loan LMI and maj-min status.csv")
state_table_loans <- read_csv("2. Output/state_table_loans_plot.csv")
ppp_loan_summary_table <- read_csv("2. Output/PPP loan summary by race.csv")
loan_size_table <- read_csv("2. Output/PPP loan size table by race.csv")
combo <- read_csv('2. Output/LMI and Minority Status.csv')
font_import() 
#LMI Maj Min
#############################
#LMI Maj Min

overall_table_plot <- lmi_majmin %>% 
  mutate(Group = case_when(Group == "Not LMI, majority-minority" |
                             Group == "Neither LMI nor majority-minority" ~ "Not an LMI",
                           Group == "LMI and majority-minority" |
                             Group == "LMI, not majority-minority" ~ "LMI",
                           T~ "No data available on ethnic/racial composition"),
         `Bank type` = case_when(`Bank type` == "non-MDI" ~ "Non-MDI",
                                 T ~ `Bank type`)) %>%
  filter(Group!="No data available on ethnic/racial composition") %>% 
  ggplot(aes(x = Group,
             fill = `Bank type`,
             y = as.numeric(str_remove(`Percent of loans`, "%"))/100))+
  geom_bar(position = "dodge",
           stat = "identity")+
  # geom_text(aes(label = comma(`Number of loans`)),
  #           position = position_dodge(.9),
  #           stat = "identity",
  #           vjust = 1.5, 
  #           colour = "white")+
  scale_fill_manual(values = c("#2FB3a1",
                               "light gray"))+
  facet_grid(~maj_min)+
  scale_y_continuous(labels = scales::percent,
                     limits = c(0.,0.6),
                     breaks = c(#.05,
                                .15,
                                #.25,
                                .35,
                                #.45,
                                .55),
                     expand = c(0, 0)) +
  labs(
    x = "",
    y = "Percentage of loans",
    title = "Figure 3: MDIs issued a greater share of their PPP loans to \nmajority-minority zip-codes than did Non-MDIs",
    fill = "",
    caption = "Source: National Bankers Association Foundation analysis of SBA's PPP loan data and \nAmerican Community Survey 2021 5-year estimates")+
  theme_bw()+
  theme(axis.text.x = element_text(#angle = 45,
                                  # vjust=  .8,
                                  # hjust = .9,
                                   face="bold"),
        title = element_text(face="bold"),
        text=element_text(family="Arial Rounded MT Bold"),
        legend.position = "bottom")

ggsave(overall_table_plot, 
       filename = "3. Graphs/Figure 3.pdf",
       width = 6,
       height = 6)
ggsave(overall_table_plot, 
       filename = "3. Graphs/Figure 3.jpg",
       width = 6,
       height = 6)


#LMI Maj Min By race
#############################
#LMI Maj Min By Race

non_mdi_lmi_maj_min <- as.numeric(lmi_majmin_race %>% 
  filter(race_bank == "non-MDI",
         `Majority minority status` == "Majority minority",
         Group == "LMI") %>% 
  select(`Percent of loans`))
non_mdi_notlmi_maj_min <- as.numeric(lmi_majmin_race %>% 
                                    filter(race_bank == "non-MDI",
                                           `Majority minority status` == "Majority minority",
                                           Group == "Not an LMI") %>% 
                                    select(`Percent of loans`))
non_mdi_notlmi_notmaj_min <- as.numeric(lmi_majmin_race %>% 
                                       filter(race_bank == "non-MDI",
                                              `Majority minority status` == "Not majority minority",
                                              Group == "Not an LMI") %>% 
                                       select(`Percent of loans`))
non_mdi_lmi_notmaj_min <- as.numeric(lmi_majmin_race %>% 
                                       filter(race_bank == "non-MDI",
                                              `Majority minority status` == "Not majority minority",
                                              Group == "LMI") %>% 
                                       select(`Percent of loans`))

overall_table_plot_by_Race <- lmi_majmin_race %>% 
  mutate(text = case_when( `Majority minority status` == "Majority minority"&
                             Group == "LMI" ~ "Line: non-MDI loan percentage"),
         line = case_when(`Majority minority status` == "Not majority minority" &
                            Group == "LMI" ~ non_mdi_lmi_notmaj_min,
                          `Majority minority status` == "Not majority minority" &
                            Group == "Not an LMI" ~ non_mdi_notlmi_notmaj_min,
                          `Majority minority status` == "Majority minority" &
                            Group == "Not an LMI" ~ non_mdi_notlmi_maj_min,
                          `Majority minority status` == "Majority minority"&
                            Group == "LMI" ~ non_mdi_lmi_maj_min),
         race_bank = factor(case_when(race_bank == "American Indian or Alaska Native" ~ "AIAN",
                               race_bank == "Asian American or Pacific Islander" ~ "AAPI",
                               race_bank == "Black or African American" ~ "Black",
                               race_bank == "Hispanic or Latino" ~ "Hispanic",
                               T ~ race_bank),
                            levels = c("non-MDI",
                                       "All MDIs",
                                       "AAPI",
                                       "Black",
                                       "Hispanic"))) %>% 
  filter(Group!="No data available on ethnic/racial composition",
         race_bank != "AIAN",
         race_bank != "non-MDI"
         ) %>% 
  ggplot()+
  geom_bar(aes(x = race_bank,
               y = `Percent of loans`,
               fill = race_bank),
           position = "dodge",
           stat = "identity")+
  scale_fill_manual(values = c("light gray",
                               "#0F2453",
                               "#2FB3A1",
                               "#FFB400"))+
  geom_hline(aes(yintercept = line
                  ),
             linewidth = 1/2)+
  geom_text(aes(x = 2.5,
                y = line+.2,
                label = text))+
  facet_wrap(Group~`Majority minority status`)+
  scale_y_continuous(labels = scales::percent,
                     limits = c(0.,0.75),
                     breaks = c(.1,
                                .3,
                                .5,
                                .7),
                     expand = c(0, 0)) +
  labs(
    x = "",
    y = "Percentage of loans",
    title = "Figure 4: Asian, Black, and Hispanic MDIs each issued a \ngreater share of their PPP lending to majority-minority \nzip-codes than non-MDIs",
    fill = "",
    caption = "Source: National Bankers Association Foundation analysis of SBA's PPP loan data and \nAmerican Community Survey 2021 5-year estimates")+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 45,
     vjust=  .8,
     hjust = .9,
    face="bold"),
    title = element_text(face="bold"),
    text=element_text(family="Arial Rounded MT Bold"),
    legend.position = "none")

ggsave(overall_table_plot_by_Race, 
       filename = "3. Graphs/Figure 4.pdf",
       width = 6,
       height = 6)

ggsave(overall_table_plot_by_Race, 
       filename = "3. Graphs/Figure 4.jpg",
       width = 6,
       height = 6)
#PPP Loan Size
##################################
#PPP Loan Size

ppp_loan_size_plot <- ppp_loan_size %>% 
  mutate(ppp_loan_size = factor(ppp_loan_size,
                                levels = c("$0-$10k",
                                           "$10k-$50k",
                                           "$50k-$100k",
                                           "$100k-$500k",
                                           "$500k-$1m" ))) %>% 
  ggplot()+
  geom_bar(aes(x = ppp_loan_size,
               y = n,
               fill = group),
           position = "dodge",
           stat = "identity")+
  scale_fill_manual(values = c("#2FB3a1",
                               "light gray"))+
  scale_y_continuous(labels = scales::percent,
                     limits = c(0.,0.6),
                     expand = c(0, 0))+
  labs(
    x = "PPP loan size",
    y = "Percentage of loans",
    fill = "",
    title = "Figure 1: MDIs issued a similar range of PPP loan sizes \nas non-MDIs",
    caption = "Source: National Bankers Association Foundation analysis of SBA's PPP loan data")+
  theme_bw()+
  theme(axis.text.x = element_text(#angle = 45,
    # vjust=  .8,
    # hjust = .9,
    face="bold"),
    title = element_text(face="bold"),
    text=element_text(family="Arial Rounded MT Bold"),
    legend.position = "bottom")

ggsave(plot = ppp_loan_size_plot,
       filename = "3. Graphs/Figure 1.pdf",
       width = 6,
       height = 6)

ggsave(plot = ppp_loan_size_plot,
       filename = "3. Graphs/Figure 1.jpg",
       width = 6,
       height = 6)


####################

state_table_loans_plot <- state_table_loans  %>% 
  ggplot() + 
  geom_polygon(
    color = "white",
    size = .25 ,
    mapping = aes(x = long, 
                  y = lat,
                  fill = n,
                  group = group)) +
  scale_fill_gradient( trans = "log",
                       breaks = c(50,
                                  500,
                                  5000,
                                  50000),
                       high = "#2FB3a1",
                       low  = "light gray")+
  #  scale_fill_gradient(labels = scales::percent,
  #                   guide = guide_colorbar(title.position = "top"))+
  coord_map(projection = "albers", lat0 = 39, lat1 = 45)+
  labs(title = "Figure 2: MDI PPP Loans Reached All 50 States",
       fill = "Number of MDI loans by state:",
       caption = "Source: National Bankers Association Foundation analysis of SBA's PPP loan data")+
  theme_void()+
  theme(legend.title = element_text(),
        legend.key.width = unit(.5, "in"),
        title = element_text(face="bold"),
        text=element_text(family="Arial Rounded MT Bold"),
        legend.position = "bottom") 

ggsave(plot = state_table_loans_plot,
       filename = "3. Graphs/Figure 2.pdf",
       width = 6,
       height = 6)
ggsave(plot = state_table_loans_plot,
       filename = "3. Graphs/Figure 2.jpg",
       width = 6,
       height = 6)


ppp_loan_summary_table_kable <- kbl(ppp_loan_summary_table ,
                                 format.args = list(big.mark = ","),
                                 caption = "<b>Tables 1: Descriptive Statistics for PPP Lending<b>") %>% 
  row_spec(seq(1,nrow(ppp_loan_summary_table),2), background="#DEDEDE") %>% 
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
df[,c(1,2,3,4)]
loan_size_table_kable <- kbl(loan_size_table[,c("ppp_loan_size",
                                                "Non-MDI",
                                                "All MDIs",
                                                "AAPI MDI",
                                                "AIAN MDI",
                                                "Black MDI",
                                                "Hispanic MDI",
                                                "Multi-Racial MDI")] %>% 
                               mutate(ppp_loan_size = factor(ppp_loan_size,
                                                             levels= c("$0-$10k",
                                                                       "$10k-$50k",
                                                                       "$50k-$100k",
                                                                       "$100k-$500k",
                                                                       "$500k-$1m",
                                                                       "$1m+"))) %>% 
                               rename(`PPP Loan Size` = ppp_loan_size) %>% 
                               arrange(`PPP Loan Size`),
                                    format.args = list(big.mark = ","),
                                    caption = "<b>Table 2: Descriptive Statistics for PPP Lending<b>") %>% 
  row_spec(seq(1,nrow(loan_size_table),2), background="#DEDEDE") %>% 
  kable_classic(full_width = F, html_font = "Arial") %>% 
  kable_styling(#bootstrap_options = c("striped", "hover"),
    full_width = F,
    font_size = 12,
    html_font = "Arial")


loan_size_table_kable %>% 
  save_kable("4. Tables/Table 2.jpg")
save_kable(loan_size_table_kable, file = "4. Tables/Table 2.html")
webshot("4. Tables/Table 2.html", 
        "4. Tables/Table 2.pdf")

####################################
#Table 4
###################################
table4 <- kbl(combo[,c("Bank type",
                       "Group",
                       "Number of loans",
                       "Percent of loans",
                       "Amount of loan dollars (in billions)",
                       "Percent of loan dollars")] %>% 
                               filter(Group != "No data available on ethnic/racial composition") %>% 
                mutate(`Bank type` = case_when(`Bank type` == "non-MDI" ~"Non-MDI",
                                               T~`Bank type`)),
                             format.args = list(big.mark = ","),
                             caption = "<b>Table 4: Demographic Statistics for PPP Lending<b>") %>% 
  row_spec(seq(1,nrow(combo)-2,2), background="#DEDEDE") %>% 
  kable_classic(full_width = F, html_font = "Arial") %>% 
  kable_styling(#bootstrap_options = c("striped", "hover"),
    full_width = F,
    font_size = 12,
    html_font = "Arial")


table4 %>% 
  save_kable("4. Tables/Table 4.jpg")
save_kable(table4, file = "4. Tables/Table 4.html")
webshot("4. Tables/Table 4.html", 
        "4. Tables/Table 4.pdf")
 