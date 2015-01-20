library(shiny)

shinyServer(function(input, output) {
    output$selectIssues <- renderUI({
        issues <- switch(input$timeframe,
                         "Last week" = last.week,
                         "Last month" = last.month,
                         "Last 3 months" = last.month3,
                         "Last 6 months" = last.month6,
                         "Last year" = last.year,
                         overall)
        issues <- names(sort(issues, TRUE))
        checkboxGroupInput("issues", "Top issues (sorted descending):", issues, selected=head(issues, 3))
    })
    
    output$Plot <- renderPlot({
        columns <- input$issues
        firstDay <- first.day + input$timewindow[1] - 1
        lastDay <- first.day + input$timewindow[2] - 1
        dat <- db[db$variable %in% columns & db$date >= firstDay & db$date < lastDay,]
        plot <- ggplot(dat, aes(as.Date(date), value, color=variable)) + scale_x_date(labels = date_format("%Y-%m")) + geom_smooth(fill = NA, size = 2.5)
        print(plot)
        print(dim(dat))
        print(sprintf("%s %s %s", columns, firstDay, lastDay))
    })
})
