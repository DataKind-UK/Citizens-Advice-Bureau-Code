# Citizens Advice Bureau
##### DataDive London
##### 7-8 June 2014

For full write ups please refer to HackPad entry here: https://hackpad.com/DataKind-UK-Summer-DataDive-2014-QataALEE3nb

### Google Keyword Textual Analysis
##### Methodology
The main finding is that there seems to be a very high proportion of searches are related to work and small claims instead of unemployment benefit. The small claims finding was inline with some of the other survey that the CAB has done in the past. It maybe useful to advocate for simpler processes or finding out the root causes for small claims (damages, poor services, etc) and deal with them at the cause level.

##### Methodology
1. We imported the keywords data from GAPageTracking_WithKeywordsAndSocialMedia.csv
2. Removed records which has no keyword terms - "(not set)", "(not provided" or "" <empty string>
3. Break down the keyword terms into individual words
4. Remove common English words (http://en.wikipedia.org/wiki/Most_common_words_in_English)
5. Remove common CAB related terms - e.g. advice, citizen, etc - and other plurals terms (e.g. benefits - as benefit already capture the meaning)
6. Take top 20 keywords and see how they appear as a combination of one another.
