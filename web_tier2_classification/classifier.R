library(stringr); library(data.table); library(ggplot2); library(lubridate)

topN = function(d, field, n) {
  print(d[, list(N=sum(daily_unique_pageviews)), by=field][order(-N)][1:n])
}

logs = fread('data/GAPageTracking_weekly.csv')
logs[, Profile := NULL]
logs[, Source := NULL]
logs[, Time := as.Date(Time, format='%d/%m/%Y')]
logs = logs[Time >= as.Date('2014-01-01') & Time < as.Date('2014-05-26')]

# CAB provided regex for tier 1
# logs[, tier_1 := NULL]
logs[, tier_1 := NA_character_]

logs[is.na(tier_1) & grepl("/england/benefits_e.htm", pagePath), tier_1 := "Non-leaf"]

logs[is.na(tier_1) & grepl("/benefits_.", pagePath), tier_1 := "Benefits"]
logs[is.na(tier_1) & grepl("/consumer_.", pagePath), tier_1 := "Consumer"]
logs[is.na(tier_1) & grepl("/work_.", pagePath) | grepl("tribunal", pagePath), tier_1 := "Work"]
logs[is.na(tier_1) & grepl("/debt_",  pagePath) & !grepl("insurance_|pensions_|savings_|banking_", pagePath), tier_1 := "Money (debt)"]
logs[is.na(tier_1) & grepl("/debt_",  pagePath) &  grepl("insurance_|pensions_|savings_|banking_", pagePath), tier_1 := "Money (fin)"]
logs[is.na(tier_1) & grepl("/discrimination_.", pagePath), tier_1 := "Discrimination"]
logs[is.na(tier_1) & grepl("/education_.", pagePath), tier_1 := "Education"]
logs[is.na(tier_1) & grepl("/relationship_.", pagePath), tier_1 := "Relationships"]
logs[is.na(tier_1) & grepl("/healthcare_.", pagePath), tier_1 := "Healthcare"]
logs[is.na(tier_1) & grepl("/housing_.", pagePath), tier_1 := "Housing"]
logs[is.na(tier_1) & grepl("/law_.", pagePath), tier_1 := "Law"]
logs[is.na(tier_1) & grepl("about_this_site|about_us|contact_us|support_us|search.htm|england.htm|wales.htm|help.htm|accessibility.htm", pagePath), tier_1 := "Admin"]
logs[is.na(tier_1) & grepl("index/index", pagePath), tier_1 := "Admin"]
logs[is.na(tier_1) & grepl("/tax_.", pagePath), tier_1 := "Tax"]
logs[is.na(tier_1) & grepl("/life/", pagePath), tier_1 := "Life"]
logs[is.na(tier_1) & grepl("/family_parent/", pagePath), tier_1 := "Family"]

# qplot(logs$tier_1) + coord_flip()
# topN(logs[tier_1 == 'Life'], 'pagePath', 30)

# logs[,tier_2 := NULL]
logs[,tier_2 := NA_integer_]

logs[tier_1 == 'Benefits' & is.na(tier_2) & grepl('coming_from_abroad', pagePath), tier_2 := 0L]
logs[tier_1 == 'Benefits' & is.na(tier_2) & grepl('reform', pagePath)            , tier_2 := 25L]
logs[tier_1 == 'Benefits' & is.na(tier_2) & grepl('benefit_cap', pagePath)       , tier_2 := 24L]
logs[tier_1 == 'Benefits' & is.na(tier_2) & grepl('sick_or_disabled', pagePath) & grepl('employment_and_support_allowance', pagePath),       tier_2 := 19L]
logs[tier_1 == 'Benefits' & is.na(tier_2) & grepl('sick_or_disabled', pagePath) & grepl('benefits_personal_independence_payment', pagePath), tier_2 := 21L]
logs[tier_1 == 'Benefits' & is.na(tier_2) & grepl('benefits_for_people_who_are_sick_or_disabled.htm', pagePath),                             tier_2 := 100L]
benefits_for_people_who_are_sick_or_disabled.htm
# logs[tier_1 == 'Benefits' & is.na(tier_2) & grepl('sick_or_disabled', pagePath), tier_2 := 21L]
logs[tier_1 == 'Benefits' & is.na(tier_2) & grepl('older_people', pagePath), tier_2 := 13L]
logs[tier_1 == 'Benefits' & is.na(tier_2) & grepl('low_income', pagePath) & grepl('council_tax', pagePath), tier_2 := 9L]
logs[tier_1 == 'Benefits' & is.na(tier_2) & grepl('low_income', pagePath) & grepl('housing_benefit', pagePath), tier_2 := 7L]
# logs[tier_1 == 'Benefits' & is.na(tier_2) & grepl('low_income', pagePath), tier_2 := 2L]
logs[tier_1 == 'Benefits' & is.na(tier_2) & grepl('in_work_or_looking_for_work', pagePath) & grepl('working_tax_credit', pagePath), tier_2 := 10L]
# logs[tier_1 == 'Benefits' & is.na(tier_2) & grepl('in_work_or_looking_for_work', pagePath), tier_2 := 11L]
logs[tier_1 == 'Benefits' & is.na(tier_2) & grepl('universal_credit', pagePath), tier_2 := 20L]
logs[tier_1 == 'Benefits' & is.na(tier_2), tier_2 := 1000L]


benefits = logs[tier_1 == 'Benefits']
topN(benefits[tier_2==1000], field='pagePath', 10)


logs[tier_1 == 'Money (debt)' & is.na(tier_2) & grepl('payday_loan',        pagePath), tier_2 := 22L]
logs[tier_1 == 'Money (debt)' & is.na(tier_2) & grepl('debt_relief_orders', pagePath), tier_2 := 49L]
logs[tier_1 == 'Money (debt)' & is.na(tier_2) & grepl('bailiffs',           pagePath), tier_2 := 41L]
logs[tier_1 == 'Money (debt)' & is.na(tier_2) & grepl('debt_credit_cards',  pagePath), tier_2 := 13L]
logs[tier_1 == 'Money (debt)' & is.na(tier_2) & grepl('debt_mortgage',      pagePath), tier_2 := 2L]
logs[tier_1 == 'Money (debt)' & is.na(tier_2) & grepl('rent_arrears',       pagePath), tier_2 := 6L]

tier_2_lookup = data.table(read.csv('data/tier_2_codes.csv'))
benefits = merge(logs[tier_1 == 'Benefits'],     tier_2_lookup[tier_1=='BEN', list(tier_2=tier_2_id, tier_2_text)], by='tier_2', all.x=T, all.y=F)
debt =     merge(logs[tier_1 == 'Money (debt)'], tier_2_lookup[tier_1=='DEB', list(tier_2=tier_2_id, tier_2_text)], by='tier_2', all.x=T, all.y=F)

# find unclasified tier 2
benefits[is.na(tier_2_text), .N, pagePath]

benefits_aggregated = benefits[, list(uniques=sum(daily_unique_pageviews)), by=list(Time, tier_2_text)]
benefits_aggregated = benefits[, list(uniques=sum(daily_unique_pageviews)), by=list(Time, tier_2)]
ggplot(data=benefits_aggregated[year(Time)==2013 & month(Time) %in% c(8,9)]) + geom_area(aes(x=Time, y=uniques, fill=tier_2_text), position='stack', stat='identity')

debt_aggregated = debt[, list(uniques=sum(daily_unique_pageviews)), by=list(Time, tier_2_text)]
ggplot(data=debt_aggregated) + geom_area(aes(x=Time, y=uniques, fill=tier_2_text), position='stack', stat='identity')


tier2items = unique(debt_aggregated[!is.na(tier_2_text)]$tier_2_text)
add_missing_items = function(d) {
  for(item in tier2items) {
    if(!item %in% d$tier_2_text) {
      d = rbind(d, data.table(tier_2_text=item, uniques=0L))
    }
  }
  d
}
debt_aggregated = debt_aggregated[, add_missing_items(.SD), by=Time]

# missing
# 'children_and_young_people' (small)
# 'bereavement' (very small)
# 'armed_forces_and_veterans' (very small)
# 'coming_from_abroad' (large: top 5 benefits)


