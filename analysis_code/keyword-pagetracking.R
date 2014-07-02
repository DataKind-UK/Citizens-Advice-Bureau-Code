#Source file location
SOURCE_FILE = "~/temp/datakind/CitizensAdviceBureau/data/GAPageTracking_WithKeywordsAndSocialMedia.csv"

#Loading 
GAPageTracking <- read.csv(SOURCE_FILE, header = TRUE, quote="")
#remove quotation marks
GAPageTracking$keyword <-gsub("\"", "", GAPageTracking$keyword)

# Rename a column and converting the type
names(GAPageTracking)[11]<-"daily.unique.page.view"
GAPageTracking$daily.unique.page.view <- as.numeric(GAPageTracking$daily.unique.page.view)

# House keeping information
cat(sprintf("Total %s rows containing %s unique keywords loaded\n",
            format(length(GAPageTracking$Time), big.mark=","),
            format(length(unique(GAPageTracking$keyword)), big.mark=",")))

cat(sprintf("Total number of unique page view: %s\n", 
            format(sum(GAPageTracking$daily.unique.page.view), big.mark=",")))
cat("\n")

cat("1. Cleaning up keywords...\n")
# Number of times a particular search term has appeared
freq = aggregate(GAPageTracking$daily.unique.page.view,
                 list(GAPageTracking$keyword), sum)

# Cleaning up rows with no keywords
# a. (not set)
a = freq[which(freq$Group.1==("(not set)")),]
cat(sprintf("   a) (not set): %s\n", 
            format(a$x, big.mark=",")))

# b. (not provided)
b = freq[which(freq$Group.1==("(not provided)")),]
cat(sprintf("   b) (not provided): %s\n", 
            format(b$x, big.mark=",")))

#c. <empty string>
c = freq[which(freq$Group.1==("")),]
cat(sprintf("   c) <empty string>: %s\n", 
            format(c$x, big.mark=",")))

cleanupphases <- c("", "(not set)", "(not provided)")
GAPageTracking <- GAPageTracking[!GAPageTracking$keyword %in% cleanupphases,]

# run aggregate function again to check
cleanup = a$x + b$x + c$x
freq = aggregate(GAPageTracking$daily.unique.page.view,
                 list(GAPageTracking$keyword), sum)


cat(sprintf("   Total unique page views removed: %s\n", 
            format(cleanup, big.mark=",")))

cat(sprintf("   Total unique page views left: %s\n",
            format(sum(freq$x), big.mark=",")))

cat("2. Split string into words...\n")
# Spliting string into words using space as the delimiter
s<-strsplit(freq$Group.1, split=" ")
# Create a new row (which includes frequency count) for every word 
# in the string
stringdata <- data.frame(frequency=rep(freq$x, sapply(s,length)),
                         keyword=unlist(s))
# Consolidate - counting the number of occurance of each word in the
# search term
aggStringData = aggregate(stringdata$frequency,
                          list(stringdata$keyword),sum)
# Sort by popularity
aggStringData <- aggStringData[order(-aggStringData$x),]

# Source: http://en.wikipedia.org/wiki/Most_common_words_in_English
# Plus variations starting with "are"
commonwords <- c("the","be","to","of","and","a","in","that","have","i","it","for",
                 "not","on","with","he","as","you","do","at","this","but","his",
                 "by","from","they","we","say","her","she","or","an","will","my",
                 "one","all","would","there","their","what","so","up","out","if",
                 "about","who","get","which","go","me","when","make","can","like",
                 "time","no","just","him","know","take","people","into","year",
                 "your","good","some","could","them","see","other","than","then",
                 "now","look","only","come","its","over","think","also","back",
                 "after","use","two","how","our","work","first","well","way",
                 "even","new","want","because","any","these","give","day","most",
                 "us", "are", "am", "does", "-", "should", "u", "www", "&", "is")

aggStringData <- aggStringData[!aggStringData$Group.1 %in% commonwords,]

# removing cab words and also purals of common issues - benefits, claims
cabwords <- c("citizen", "citizens","advice","advices" ,"bureau", "cab", "uk",
              "benefits", "claims")

aggStringData <- aggStringData[!aggStringData$Group.1 %in% cabwords,]


barplot(aggStringData$x,names.arg=aggStringData$Group.1)

View(aggStringData)

# top 100 words
vec100 = as.vector(aggStringData$Group.1[1:100])
permu100 = expand.grid(vec100, vec100)
# remove the same terms
combind100 = t(apply(permu100[permu100[,2]!=permu100[,1],], 1, sort))
# remove duplicated terms in different order
combind100_2 = combind100[!duplicated(combind100),]

rescount = apply(combind100_2, 1, function(row){
  #print(row)
  var1 <- row[1]
  var2 <- row[2]
  #regex = var1 + ".*" + var2 + "\\|" + var2 + ".*" + var1
  regex = paste(var1, ".*", var2,"|", var2, ".*", var1, sep="")
  #print(regex)
  answer = sum(GAPageTracking[grep(regex,
                      GAPageTracking$keyword), ]$daily.unique.page.view)
  #print(answer)
  return(answer)
})

combind100_2 <- as.data.frame(combind100_2)

combind100_2["freq"] <- NA
combind100_2["freq"] <- rescount

combind100_2 <- combind100_2[order(-combind100_2$freq),]

barplot(combind100_2$freq[1:20], names.arg=paste(combind100_2$V1, ",", combind100_2$V2,sep="")[1:20], las = 3)

View(combind100_2)
