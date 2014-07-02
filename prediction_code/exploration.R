library(data.table)
library(magrittr)
library(plyr)
library(dplyr)
library(reshape2)
library(ggplot2)
library(gridExtra)
library(lubridate)

data.case <- fread("data/data_merged_orig.csv")

### Number of tier2 codes per tier1

data.case[, list(length(unique(tier2))), list(tier1)]
counts.tier.deb <- data.case[tier1 == "DEB", .N, list(tier2)]
counts.tier.ben <- data.case[tier1 == "BEN", .N, list(tier2)]

counts.tier.deb$prop <- counts.tier.deb$N / sum(counts.tier.deb$N)
counts.tier.ben$prop <- counts.tier.ben$N / sum(counts.tier.ben$N)

counts.tier.deb$tier2 <- counts.tier.deb$tier2 %>% factor %>%
  reorder(counts.tier.deb$prop, decreasing = TRUE)
gg.1 <- ggplot(counts.tier.deb, aes(x = tier2, y = prop)) + 
  geom_bar(stat = "identity") + coord_flip()

counts.tier.ben$tier2 <- counts.tier.ben$tier2 %>% factor %>%
  reorder(counts.tier.ben$prop, decreasing = TRUE)
gg.2 <- ggplot(counts.tier.ben, aes(x = tier2, y = prop)) + 
  geom_bar(stat = "identity") + coord_flip()

grid.arrange(gg.1, gg.2, nrow = 2)

# data.ga.events <- fread("data/GaEvents.csv")
# data.ga.tracking <- fread("data/GAPageTracking.csv")

# ==============
# = Clustering =
# ==============

data.case[, list(tier1, tier2, tier3)] %>% unique %>% dim
data.case[, date := as.Date(date)]
data.case$date.week <- floor_date(data.case$date, "week")

data.1 <- data.case[, .N, list(date, tier1, tier2, tier3)]
data.1[, aux.tier := paste(tier1, tier2, tier3, sep = ".")]
data.1[, N.std := (N  - mean(N)) / sd(N), aux.tier]

ggplot(data.1, aes(date, y = N.std, group = aux.tier)) + 
  geom_line(alpha = 0.1)
data.1[is.na(N.std), N.std := 0]

ts.mat <- dcast.data.table(data.1, tier1 + tier2 + tier3 ~ date, 
  value.var = "N.std", fill = 0) 

ts.mat.1 <- ts.mat %>% select(-(tier1:tier3)) %>% as.matrix

set.seed(314)
system.time({
clust.fit <- kmeans(ts.mat.1, centers = 8, nstart = 15)
})

clust.dt <- data.table(ts.mat[, list(tier1, tier2, tier3)],
   clust.fit$cluster) %>%
  as.data.table

data.case.1 <- join(data.case, clust.dt)
data.2 <- data.case.1[, .N, list(date.week, tier1, tier2, tier3, V2)]
data.2[, aux.tier := paste(tier1, tier2, tier3, sep = ".")]
data.2[, N.std := (N  - mean(N)) / sd(N), aux.tier]

png(file = "prediction_code/plots/ts_plots.png",
  width = 500, height = 650)
print(gg)
dev.off()

plot(table(data.case$tier1, data.case$tier2))

data.2.deb <- data.2[tier1 == "DEB", ]

plot.tier.2 <- function(data.x){
  data.x.1 <- data.x[, list(N = .N), list(tier2)]
  data.x.1$prop <- data.x.1$N / sum(data.x.1$N)
  data.x.1$tier2 <- data.x.1$tier2 %>% factor %>%
    reorder(data.x.1$prop, decreasing = TRUE)
  gg <- ggplot(data.x.1, aes(x = tier2, y = round(100 * prop))) + 
    geom_bar(stat = "identity") + coord_flip() + xlab("") +
    ylab("")
  gg
}

tab <- data.2.deb[, list(N = .N), list(tier2, V2)]
write.csv(dcast(tab, tier2 ~ V2, fill = 0))


gg.grid <- grid.arrange(plot.tier.2(data.case.1[V2 == 1, ]),
  plot.tier.2(data.case.1[V2 == 2, ]),
  plot.tier.2(data.case.1[V2 == 3, ]),
  plot.tier.2(data.case.1[V2 == 4, ]),
  plot.tier.2(data.case.1[V2 == 5, ]),
  plot.tier.2(data.case.1[V2 == 6, ]),
  plot.tier.2(data.case.1[V2 == 7, ]),
  plot.tier.2(data.case.1[V2 == 8, ]), ncol = 2)

png(file = "prediction_code/plots/grid_plot.png",
  width = 600, height = 1200)
 grid.arrange(plot.tier.2(data.case.1[V2 == 1, ]),
  plot.tier.2(data.case.1[V2 == 2, ]),
  plot.tier.2(data.case.1[V2 == 3, ]),
  plot.tier.2(data.case.1[V2 == 4, ]),
  plot.tier.2(data.case.1[V2 == 5, ]),
  plot.tier.2(data.case.1[V2 == 6, ]),
  plot.tier.2(data.case.1[V2 == 7, ]),
  plot.tier.2(data.case.1[V2 == 8, ]), ncol = 2)

dev.off()


l.plots <- dlply(data.case.1, "V2", function(sub)  plot.tier.2(sub))
grid.arrange(gg.1, gg.2, nrow = 2)

plot.tier.2(data.case.1[V2 == 1, ])


