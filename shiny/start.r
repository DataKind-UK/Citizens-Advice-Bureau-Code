library(ggplot2)
library(scales)
library(data.table)
library(plyr)
library(reshape2)
library(shiny)
library(lubridate)

data <- fread("data_merged_compact_orig.csv")

data$gov.region <- as.factor(data$gov.region)
data$tier1 <- as.factor(data$tier1)
data$tier2 <- as.factor(data$tier2)
data$tier3 <- as.factor(data$tier3)
data$date <- as.Date(data$date)
data$weight <- as.numeric(data$weight)

dates <- table(data$date)

data.tier2 <- data.frame(date = as.Date(names(dates)))
for (nm in levels(data$tier2)) {
    d <- ddply(data, .(date), function(x) sum(x[x$tier2 == nm,]$weight))
    data.tier2[[nm]] <- d$V1
}

# data.tier2.class <- data.frame(date = as.Date(names(dates)))
# data.tier2.class <- 

# data.tier2 <- read.csv("tier2.csv")
data.tier2$date <- as.Date(data.tier2$date)
data.tier2$date.week <- floor_date(data.tier2$date, "week")

data.by.week <- ddply(data.tier2, .(date.week), numcolwise(sum))
data.by.week <- data.by.week[-nrow(data.by.week),]

last.n.days <- function(n) {
    res <- ddply(data.tier2[as.numeric(last.day - data.tier2$date) < n, ], NULL, numcolwise(sum))
    res <- res[, !names(res) %in% c(".id", "Not recorded/not applicable")]
    res
}

last.day <- tail(data.tier2$date, 1)
first.day <- head(data.tier2$date, 1)
num.days <- as.numeric(last.day - first.day)

last.week <- last.n.days(7)
last.month <- last.n.days(30)
last.month3 <- last.n.days(91)
last.month6 <- last.n.days(182)
last.year <- last.n.days(365)
overall <- last.n.days(9999999)
    
db <- melt(data.tier2, id.vars = "date")
