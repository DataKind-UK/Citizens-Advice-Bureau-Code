function.plotEbefQuery <- function(dataSet, tierCode, tierColumnIndex, tierForTitle) {
  
  datesForVisits = dataSet[ dataSet[, tierColumnIndex] == tierCode, 1 ]
  numberOfVisitsByDate = aggregate(data.frame(count = datesForVisits), list(date = datesForVisits), length)
  plot(numberOfVisitsByDate$date, numberOfVisitsByDate$count, main=paste("Number of Bureau visits per day for", tierForTitle, "queries", sep=" "), xlab="Date", ylab="Number of EBEFs")
}

# Opening data file
setwd("~/Work/Projects/datakind/data")
bureauVisitRecords = read.csv("data_merged_compact_badLinesSkipped.csv")
bureauVisitRecords$X.date = as.Date(bureauVisitRecords$X.date, "%Y-%m-%d")

# Querying unique Tier1 values
unique(bureauVisitRecords$tier1)

# Plot them individually
function.plotEbefQuery(bureauVisitRecords, "BEN", 3, "Benefit")
function.plotEbefQuery(bureauVisitRecords, "DEB", 3, "Debt")