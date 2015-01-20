library(shiny)

# Define UI for dataset viewer application
shinyUI(fluidPage(
  
  # Application title
  titlePanel("Predicting proportions"),
  
  # Sidebar with controls to select a dataset and specify the
  # number of observations to view
  sidebarLayout(
    sidebarPanel(
      numericInput("no.periods", label = "Number of periods", value = 5),
      selectInput("gov.region", label = "Government region", choices =
        list("East Midlands", "Eastern", "London",
         "North East", "North West", "South East",
         "South West", "Wales", "West Midlands",
         "Yorkshire & the Humber")),
      selectInput("tier1","Tier 1", list("DEB", "BEN")),
      conditionalPanel(condition="input.tier1 == 'DEB'",
       selectInput("tier2_deb","Tier 2", 
        choices = list(
          "10 Mag.Cts fines+comp.ord.arrears",
          "11 Maint.+child support arrears",
          "12 Bank+building soc.overdrafts",
          "13 Credit",
          "14 Unsecd personal loan debts",
          "15 Catalogue+mail order debts",
          "16 Water supply+sewerage debts",
          "17 Unpd parkg penalty+cong.chgs",
          "18 Overpayments of WTC+CTC",
          "19 Overpayments of IS+/or JSA",
          "2 Mortgage+secd loan arrears",
          "20 Overpts.Hou+Council Tax Bens.",
          "21 Social Fund debts",
          "3 Hire purchase arrears",
          "4 Fuel debts",
          "40 3rd pty debt coln excl bailiffs",
          "41 Private Bailiffs",
          "49 Debt relief order",
          "5 Telephone and Broadband debts",
          "50 Bankruptcy",
          "51 Other legal remedies",
          "6 Rent arrears-LAs or ALMOs",
          "7 Rent arrears-hsg assocs",
          "8 Rent arrears-priv.landlords",
          "9 Council tax",
          "99 Other",
          "1 Discrimination",
          "Not recorded/not applicable",
          "22 Payday loan debts",
          "25 Arrears of income tax"))
      ),
      conditionalPanel(condition = "input.tier1 == 'BEN'",
       selectInput("tier2_ben" ,"Tier 2",
        choices = list("11 Jobseekers Allowance",
            "12 National Insurance",
            "14 Incapacity Benefit",
            "16 DLA-Mobility Component",
            "17 Attendance Allowance",
            "18 Carers Allowance",
            "3 Pension Credit",
            "6 SF Community Care grants",
            "8 Child Benefit",
            "9 Council Tax Benefit",
            "10 Working+Child Tax Credits",
            "13 State Retirement Pension",
            "15 DLA-Care Component",
            "19 Employment Support Allowance",
            "2 Income Support",
            "4 Social Fund Loans-Crisis",
            "5 Social Fund Loans-Budgtg",
            "7 Housing Benefit",
            "99 Other benefits issues",
            "1 Discrimination",
            "23 Localised support for council tax",
            "25 Welfare reform benefit loss",
            "Not recorded/not applicable",
            "22 Localised social welfare",
            "24 Benefit cap",
            "21 Personal independence payment",
            "20 Universal credit"))
      )
    ),
    mainPanel(      
      helpText("Predictions:"),
      # tableOutput("predictions"),
      conditionalPanel(condition = "input.tier1 == 'BEN'",
        plotOutput("plot_ben", width = "100%", height = "300px")),
      conditionalPanel(condition = "input.tier1 == 'DEB'",
        plotOutput("plot_deb", width = "100%", height = "300px"))
      # textOutput("diag_text"),
      # tableOutput("summary"),
      # tableOutput("summary2")
      # tableOutput("plot")
    )
  )
))

