require(rgdal)
require(rmapshaper)
require(maptools)
require(data.table)
require(stringr)
require(dplyr)

#1 Prostorová data
setwd()
#Loading
#--------------------
povodi_0 <- readOGR('data/E_HEIS$UPV_HLGP#P2$wm.shp', 'E_HEIS$UPV_HLGP#P2$wm')
reky_0 <- readOGR('data/E_ISVS$UPOV_R.shp', 'E_ISVS$UPOV_R')
jezera_0 <- readOGR('data/E_ISVS$UPOV_J.shp', 'E_ISVS$UPOV_J')

#Preparation of data
#--------------------
povodi_0 <- spTransform(povodi_0, CRS("+init=epsg:4326"))
povodi <- ms_simplify(povodi_0, keep_shapes = TRUE, keep = 0.05)
#--------------------
proj4string(reky_0) <- CRS("+proj=krovak +lat_0=49.4 +lon_0=24.833 +k=0.9999 +x_0=0 +y_0=0 +ellps=bessel +units=m +no_defs")
reky_0 <- spTransform(reky_0, CRS("+init=epsg:4326"))
reky <- ms_simplify(reky_0, keep_shapes = TRUE, keep = 0.10)
#--------------------
proj4string(jezera_0) <- CRS("+proj=krovak +lat_0=49.4 +lon_0=24.833 +k=0.9999 +x_0=0 +y_0=0 +ellps=bessel +units=m +no_defs")
jezera_0 <- spTransform(jezera_0, CRS("+init=epsg:4326"))
jezera <- ms_simplify(jezera_0, keep_shapes = TRUE, keep = 0.05)

#Saving
#--------------------
#writeSpatialShape(povodi,"data/prep/povodi")
# writeSpatialShape(reky,"data/prep/reky")
# writeSpatialShape(jezera,"data/prep/jezera")

writeOGR(povodi, "data/prep", "povodi", driver="ESRI Shapefile", encoding  = "UTF-8")
writeOGR(reky, "data/prep", "reky", driver="ESRI Shapefile", encoding  = "UTF-8")
writeOGR(jezera, "data/prep", "jezera", driver="ESRI Shapefile", encoding  = "UTF-8")


#2 Měsiční bilance

#Loading
#--------------------
r = readRDS('BER_0010.rds')

#Preparation of data
#--------------------
i ='BER_0010.rds'
M = list()
for (i in dir()){
  r = readRDS(i)
  mr = melt(r, id.vars = 'DTM')
  m1 = mr[variable!='T', .(value = sum(value)), by = .(year(DTM), month(DTM), variable)]
  m2 = mr[variable=='T', .(value = mean(value)), by = .(year(DTM), month(DTM), variable)]
  m = rbind(m1,m2)
  m[, DTM:=as.Date(paste(year, month, 1, sep = '-'))]
  M[[length(M)+1]] = m
}

names(M) = gsub('\\.rds', '', dir())
BM = rbindlist(M, idcol = 'UPOV_ID')

#Saving
#--------------------
# setwd("./data")
# BM <- readRDS('data/mbil/bilan_month - kopie.rds')

mesice <- c("Leden","Únor","Březen","Duben","Květen","Červen",
            "Červenec","Srpen","Září","Říjen","Listopad","Prosinec")

seasons <- data.frame(month = c(1:12), seasons = c("Zíma", "Zíma", "Jaro", "Jaro", "Jaro", 
                                                   "Léto", "Léto", "Léto","Podzim", "Podzim", "Podzim", "Zíma"))

BM <- BM %>% left_join(seasons, by="month") 
BM$month2 <- as.factor(BM$month)
levels(BM$month2) <- mesice

BM <- BM %>% group_by(UPOV_ID, year, variable) %>% mutate(annual.avg = mean(value)) %>% ungroup

quarter <- data.frame(month=c(1:12), quarter = rep(1:4, each=3)) 
BM <- BM %>% left_join(quarter, by="month")

BM <- BM %>% group_by(UPOV_ID, year, quarter, variable) %>% mutate(quarterly.avg = mean(value)) %>% ungroup

BM.long <- dcast(BM, month+year+UPOV_ID~variable)
BM.long$m <- as.factor(BM.long$month)
levels(BM.long$m) <- mesice

u <- readRDS('data/uzivani.rds')
u <- u[complete.cases(X, Y)]
u$DTM <- as.character(u$DTM)

saveRDS(BM, 'data/mbil/bilan_month.rds')
saveRDS(BM.long, 'data/mbil/bilan_month_long.rds')
saveRDS(u, 'data/uzivani2.rds')

#3 Denní průtoky
#--------------------
setwd("..")

#Loading
#--------------------

# getCPLConfigOption("data/chmu/156_stanic.shp")
# setCPLConfigOption("data/chmu/156_stanic.shp", NULL)
# 
# a <- stanice_0$NAZEV_TOK
# write.csv(a, "a.csv")

stanice_0 <- readOGR("data/chmu/156_stanic.shp")
seznam.st <- read.csv('data/chmu/156_stanic_seznam.csv',encoding = 'UTF-8', header = TRUE, sep = ";", 
                      colClasses = c("factor", "character", "character", "character", "character"))

QD <- read.table('data/chmu/QD_156_stanic.txt',encoding = 'UTF-8', header = TRUE, sep=',', 
                 colClasses = c("factor", "character", "numeric"), col.names = c("DBCN", "DTM", "value"))

#Preparation of data
#--------------------
colnames(seznam.st)[2] <- "NAZEV.STANICE"
colnames(seznam.st)[4] <- "OBDOBI.S.DATY.DENNICH.PRUTOKU"

stanice <- spTransform(stanice_0, CRS("+init=epsg:4326"))

QD$DTM <- as.Date(QD$DTM, format = "%d.%m.%Y")
QD <- merge(seznam.st,QD, by="DBCN")

#Saving
#--------------------
saveRDS(QD, "QD.rds")
writeOGR(stanice, "data/prep", "stanice", driver="ESRI Shapefile", encoding  = "UTF-8")


#4 uzivani_ocistene
#Loading
#--------------------
u <- read.csv('data/vuv/uzivani_utvary_06_16.csv',encoding = 'UTF-8', header = TRUE, sep = ";")

#Preparation of data
#--------------------

colnames(u)[1] <- "ICOC"
u = melt(u, id.vars = c("ICOC", "JEV", "CZ_NACE", "POVODI", "NAZEV", "ROCNI.MNOZSTVI.tis.m3", "POVOLENE.MNOZSTVI.ROK.tis.m3", "SOUR_X",	"SOUR_Y",	"UPOV_ID",	"HEIS_POZN", "ROK"
))

u$variable <- gsub("MVM*", "", u$variable)
u$value <- gsub(",", ".", u$value)

u$DTM <- paste0("01",str_sub(paste0("00",u$variable),-2,-1), u$ROK, sep="-")
u$DTM <- as.Date(u$DTM, format = "%d%m%Y")
u$value <- as.numeric(u$value)

colnames(u)[13] <- "MESIC"
colnames(u)[c(8,9)] <- c("X", "Y")
colnames(u)[5] <- "NAZICO"

u <- u[!is.na(u$X)|!is.na(u$Y),]


#Saving
#--------------------
setwd("C:/Users/Irina/Disk Google/1_ČZU/Sucho")
saveRDS(u, "data/uzivani_ocistene.rds")


# #5 Denni data
# #--------------------
# 
# setwd("C:/Users/Irina/Disk Google/1_ČZU/Sucho/data/bilan")
# 
# d = dir()
# 
# R = list()
# for (i in d){
#   cat(i, '\n')
#   R[[i]] = readRDS(i)
# }
# 
# names(R) = gsub('\\.rds', '', names(R))  
# RR = rbindlist(R, idcol = 'UPOV_ID')
# 
# #Saving
# #--------------------
# saveRDS(RR, "C:/Users/Irina/Disk Google/1_ČZU/Sucho/data/bilan_day.rds")

