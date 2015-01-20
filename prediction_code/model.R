library(data.table)
library(magrittr)
library(plyr)
library(dplyr)
library(reshape2)
library(ggplot2)
library(gridExtra)
library(lubridate)
library(gbm)
library(wesanderson)

data.case <- fread("data/data_merged_orig.csv")
data.case$date.week <- data.case$date %>% as.Date %>% floor_date("week")
data.case <- data.case[!is.na(date) & date != "" &
  !is.na(gov.region) & gov.region != "", ]

data.case.weekly <- data.case[, .N, list(date.week, tier1, tier2, 
  gov.region)]
data.case.weekly[, prop :=  N / sum(N),
  list(date.week, tier1, gov.region)]

### Select testing period
# 10 random weeks for testing + last 4 weeks
set.seed(314)
testing.dates <- c(sample(unique(data.case.weekly$date.week), 10), 
  unique(data.case.weekly$date.week) %>% sort %>% tail(4))
data.case.weekly[, test.bool := date.week %in% testing.dates]
data.case.weekly[, month := factor(month(date.week))]

### Interesting idea: predict CHANGE in proportion using 
### lagged proportions and lagged totals
# sub <- data.case.weekly[tier2 == "15 DLA-Care Component", ]

data.case.weekly[, lagged.prop.1 := lag(prop, 1), 
  list(tier1, tier2, gov.region)]
data.case.weekly[, lagged.prop.2 := lag(prop, 2), 
  list(tier1, tier2, gov.region)]
data.case.weekly[, lagged.prop.3 := lag(prop, 3), 
  list(tier1, tier2, gov.region)]
data.case.weekly[, lagged.prop.4 := lag(prop, 4), 
  list(tier1, tier2, gov.region)]
data.case.weekly[, lagged.prop.5 := lag(prop, 5), 
  list(tier1, tier2, gov.region)]
data.case.weekly[, lagged.prop.6 := lag(prop, 6), 
  list(tier1, tier2, gov.region)]


data.case.weekly[, 
  weekly.change := (prop - lagged.prop.1),
  list(tier1, tier2, gov.region)]
setkey(data.case.weekly, tier1, tier2, gov.region, date.week)
data.case.weekly <- data.case.weekly[!is.na(weekly.change), ]
data.case.weekly[, gov.region := factor(gov.region)] 
data.case.weekly[, tier1 := factor(tier1)] 
data.case.weekly[, tier2 := factor(tier2)] 
data.case.weekly[, month := factor(month)] 


library(gbm)
mod <- gbm(as.formula("weekly.change ~ lagged.prop.1 +
  lagged.prop.2 + lagged.prop.3 + lagged.prop.4 + lagged.prop.5 +
  lagged.prop.6 + tier2 +
  month + tier1 + gov.region"),
  data = data.case.weekly[test.bool == FALSE, ],
  distribution = "gaussian", cv.folds = 8, n.cores = 8,
  n.trees = 1500, interaction.depth = 5, shrinkage = 0.1
  )
gbm.perf(mod)
data.test <- data.case.weekly[test.bool == TRUE & ! is.na(weekly.change), ]
data.test$pred <- predict(mod, data.test, n.trees = 950)

mean(abs(data.test$pred - data.test$prop))

ggplot(data.test[, mean(100 * (weekly.change - pred)), 
  list(date.week, tier1, gov.region)],
  aes(x = date.week, y = V1, colour = tier1)) + geom_point() + 
  facet_wrap(~gov.region, ncol = 2) +
  ylab("Mean deviation (percentage points)")

plot(mod, c(8,6))


# ======================================
# = Function for predicting with Shiny =
# ======================================

### I need a function that given:
# - a government region
# - a tier 1 code
# - a tier 2 code
### computes the input necessary for predicting the change
### based on the last value observed for that series

### It's too slow to query the large data base
### I'll query data.case.weekly which is precomputed
### first case to write is making a 1 period prediction
### then use that for making a multi period prediction (somehow)

### get three weeks of data
setkey(data.case.weekly, "date.week")
saveRDS(data.case.weekly, 
  "prediction_code/prediction_app/cache/weekly_data.rds")
saveRDS(mod, "prediction_code/prediction_app/cache/mod_gbm.rds")

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
