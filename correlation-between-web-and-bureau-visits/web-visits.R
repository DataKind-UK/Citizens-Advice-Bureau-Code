function.plotWebVisits <- function(dataSet, tierCode, tierColumnIndex, tierForTitle) {

  datesForVisits = dataSet[ dataSet[, tierColumnIndex] == tierCode, 1 ]
  numberOfVisitsByDate = dataSet[ dataSet[, tierColumnIndex] == tierCode, 7 ]
  plot(datesForVisits, numberOfVisitsByDate, main=paste("Number of website visits per day for", tierForTitle, "queries", sep=" "), xlab="Date", ylab="Number of EBEFs")
}

# Opening data file
setwd("~/Work/Projects/datakind/data")
webVisits = read.csv("CAB-GAVisitsByMonth.csv")
webVisits$Time = as.Date(webVisits$Time, "%Y-%m-%d")

# Querying unique Segment values
unique(webVisits$Segment)

# Plot the BEN and DEB records individually because they also exist in the EBEF dataset
function.plotWebVisits(webVisits, "BEN", 4, "Benefit")
function.plotWebVisits(webVisits, "DEB", 4, "Debt")