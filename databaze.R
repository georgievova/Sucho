require(DBI)
require(odbc)
require(dplyr)
require(dbplyr)
require(data.table)

con <- dbConnect(odbc::odbc(), .connection_string = "Driver={PostgreSQL Unicode(x64)};", uid = 'postgres', pwd='postgres', database = 'dta_Sucho')

setwd("C:/Users/Irina/Downloads/fake_bil")
d = dir()

R = list()
for (i in d){
  cat(i, '\n')
  R[[i]] = readRDS(i)
}


names(R) = gsub('\\.rds', '', names(R))  

RR = rbindlist(R, idcol = 'UPOV_ID')
dbWriteTable(con, 'bil_daily', RR)

setwd("C:/Users/Irina/Disk Google/1_ČZU/Sucho")

BM <- readRDS('data/mbil/bilan_month.rds')

BM.long <- dcast(BM, month+year+UPOV_ID~variable)

mesice <- c("Leden","Únor","Březen","Duben","Květen","Červen",
            "Červenec","Srpen","Září","Říjen","Listopad","Prosinec")

seasons <- data.frame(month = c(1:12), seasons = c("Zíma", "Zíma", "Jaro", "Jaro", "Jaro", 
                                                   "Léto", "Léto", "Léto","Podzim", "Podzim", "Podzim", "Zíma"))
BM.long$m <- as.factor(BM.long$month)

BM <- BM %>% left_join(seasons, by="month") 

dbWriteTable(con, 'bil_monthly', BM)
dbWriteTable(con, 'bil_monthly_long', BM.long)

u <- readRDS('data/uzivani.rds')
u <- u[complete.cases(X, Y)]
u$DTM <- as.character(u$DTM)
dbWriteTable(con, 'uzivani', u)

QD <- readRDS('data/QD.rds')
dbWriteTable(con, 'flow_rates_chmu', QD)

dbDisconnect(con)

# bday = tbl(con, 'bil_daily')
# BM = tbl(con, 'bil_monthly')
#
# a = bday %>% filter(UPOV_ID=='BER_0010')
# a = collect(a)
# 
# e = bday %>% group_by(UPOV_ID) %>% summarise(mean(RM))
# e
# QD <- DBI::dbReadTable(con, 'bil_monthly')
# QD <- sqldf("select * from dta_Sucho.bil_monthly")

system.time(BM <- dbGetQuery(con, "SELECT * from bil_monthly"))
system.time(BM1 <- tbl(con, 'bil_monthly'))
system.time(BM1 <- collect(BM1))
system.time(BM2 <- readRDS('data/mbil/bilan_month.rds'))
system.time({
  BM11 <- BM1 %>% filter(month == 3)
collect(BM11)})
system.time(BM22 <- BM2 %>% filter(month == 3))
