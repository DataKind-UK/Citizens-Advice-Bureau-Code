library(shiny)

shinyUI(pageWithSidebar(
    headerPanel("Citizens Advice Bureau: Top Issues"),

    sidebarPanel(
        selectInput('reg', 'Region', c("UK", "London", "East Midlands", "Eastern", "North East", "North West", "South East", "South West", "Wales", "West Midlands", "Yorkshire & the Humber"), selected="UK"),
        selectInput('tier', 'Tier', c("Tier 2", "Tier 3"), selected="Tier 2"),
        #selectInput('pastfuture', 'Model Type', c("History", "Prediction"), selected="History"),
        selectInput('criterium', 'Selection Criterium', c("Highest Count", "Highest Increase"), selected="Top Issue"),
        selectInput("timeframe", "Timeframe", choices = c("Overall", "Last year", "Last 6 months", "Last 3 months", "Last month", "Last week"),
                    selected = "Last week"),
        uiOutput("selectIssues")
        # checkboxGroupInput("issues", "Issues:", issues(), selected=head(issues(), 3))
    ),

    mainPanel(
        plotOutput("Plot"),
        sliderInput("timewindow", "Time Window (days):", min=1, max=num.days + 1, value=c(1,num.days + 1), step=1)
    )
))
