# Define server logic required to summarize and view the selected
# dataset
library(data.table)
library(gbm)
data.case.weekly <- readRDS("cache/weekly_data.rds")

mod <- readRDS("cache/mod_gbm.rds")

query.input <- function(gov.region.x, 
  tier1.x, tier2.x, data.case.weekly.x){
  data.input <- data.case.weekly[
    gov.region == gov.region.x &
    tier1 == tier1.x & 
    tier2 == tier2.x, ] %>% tail(1)
  data.input
}

### function that given a predicted value and the row used for prediction
### creates an "updated" row

pred.mult.periods <- function(data.input, no.periods = 1, mod){
  list.preds <- list()
  data.input.x <- data.input
  pred.x <- predict(mod, data.input.x, 950)
  for(x in 1:no.periods){
    data.input.pred <- data.input.x
    data.input.pred$lagged.prop.1 <- data.input.x$prop
    data.input.pred$lagged.prop.2 <- data.input.x$lagged.prop.1
    data.input.pred$lagged.prop.3 <- data.input.x$lagged.prop.2
    data.input.pred$lagged.prop.4 <- data.input.x$lagged.prop.3
    data.input.pred$lagged.prop.5 <- data.input.x$lagged.prop.4
    data.input.pred$lagged.prop.6 <- data.input.x$lagged.prop.5
    data.input.pred$prop <- data.input.x$prop + pred.x
    data.input.pred$weekly.change <- pred.x
    data.input.pred$date.week <- data.input.pred$date.week + 7
    list.preds[[length(list.preds) + 1]] <- data.input.pred
    pred.x <- predict(mod, data.input.x, 950)
    data.input.x <- data.input.pred
  }

  Reduce(rbind, list.preds)
}

prediction.plot <- function(gov.region.x, 
  tier1.x, tier2.x, no.periods.x, data.case.weekly.x){
  out <- query.input(gov.region.x, tier1.x, tier2.x,
    data.case.weekly) %>%
    pred.mult.periods(no.periods.x, mod)

  data.plot <- data.case.weekly[
      gov.region == gov.region.x &
      tier1 == tier1.x & 
      tier2 == tier2.x & 
      date.week >= as.Date("2013-01-01"), ] 
  out$data.source <- "prediction"
  data.plot$data.source <- "historic"
  data.plot.1 <- rbind(data.plot, out)

  gg <- ggplot(data.plot.1, aes(x = date.week, y = 100 * prop, 
    colour = data.source)) + geom_line(size = 2) + 
    scale_color_manual(values = wes.palette(2, "Royal1")) +
    theme_bw() + ylab("Proportion") + xlab("Date")
  gg
}


shinyServer(function(input, output) {  
  output$plot_ben <- renderPlot({
    print(prediction.plot(input$gov.region,
       input$tier1, input$tier2_ben, input$no.periods, data.case.weekly))
  })
  output$plot_deb <- renderPlot({
    print(prediction.plot(input$gov.region,
       input$tier1, input$tier2_deb, input$no.periods, data.case.weekly))
  })
})
