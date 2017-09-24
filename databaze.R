require(DBI)
require(odbc)
require(dplyr)
require(dbplyr)
require(sqldf)

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

BM <- readRDS('data/mbil/bilan_month.rds')
dbWriteTable(con, 'bil_monthly', BM)

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
