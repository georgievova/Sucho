require(rgdal)
require(rmapshaper)
require(maptools)
require(data.table)

#1
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


#2

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
setwd("./data")

mesice <- c("Leden","Únor","Březen","Duben","Květen","Červen",
            "Červenec","Srpen","Září","Říjen","Listopad","Prosinec")

seasons <- data.frame(month = c(1:12), seasons = c("Zíma", "Zíma", "Jaro", "Jaro", "Jaro", 
                                                   "Léto", "Léto", "Léto","Podzim", "Podzim", "Podzim", "Zíma"))

BM <- BM %>% left_join(seasons, by="month") 
BM$month2 <- as.factor(BM$month)
levels(BM$month2) <- mesice

BM.long <- dcast(BM, month+year+UPOV_ID~variable)
BM.long$m <- as.factor(BM.long$month)

u <- readRDS('data/uzivani.rds')
u <- u[complete.cases(X, Y)]
u$DTM <- as.character(u$DTM)

saveRDS(BM, 'data/mbil/bilan_month.rds')
saveRDS(BM.long, 'data/mbil/bilan_month_long.rds')
saveRDS(u, 'data/uzivani2.rds')

#3
#--------------------
setwd("..")

#Loading
#--------------------
stanice_0 <- readOGR("data/chmu/156_stanic.shp")
seznam.st <- read.csv('data/chmu/156_stanic_seznam.csv',encoding = 'UTF-8', header = TRUE, sep = ";", 
                      colClasses = c("factor", "character", "character", "character", "character"))
QD <- read.table('data/chmu/QD_156_stanic.txt',encoding = 'UTF-8', header = TRUE, sep=',', 
                 colClasses = c("factor", "character", "numeric"), col.names = c("DBCN", "DTM", "value"))

#Preparation of data
#--------------------

stanice <- spTransform(stanice_0, CRS("+init=epsg:4326"))
QD <- merge(seznam.st,QD, by="DBCN")

#Saving
#--------------------
saveRDS(QD, "QD.rds")
writeOGR(stanice, "data/prep", "stanice", driver="ESRI Shapefile", encoding  = "UTF-8")


#4
#Loading
#--------------------
u <- read.csv('data/vuv/uzivani_utvary_06_16.csv',encoding = 'UTF-8', header = TRUE, sep = ";")

#Preparation of data
#--------------------

colnames(u)[1] <- "ICOC"
u = melt(u, id.vars = c("ICOC", "JEV", "CZ_NACE", "POVODI", "NAZEV", "ROCNI.MNOZSTVI.tis.m3", "POVOLENE.MNOZSTVI.ROK.tis.m3", "SOUR_X",	"SOUR_Y",	"UPOV_ID",	"HEIS_POZN", "ROK"
))
library(stringr)
u$variable <- gsub("MVM*", "", u$variable)
u$DTM <- paste("01",str_sub(paste0("00",u$variable),-2,-1), u$ROK, sep="-")
u$DTM <- as.Date(u$DTM, format = "%d-%m-%Y")
colnames(u)[13] <- "MESIC"
colnames(u)[c(8,9)] <- c("X", "Y")

#Saving
#--------------------
setwd("C:/Users/Irina/Disk Google/1_ČZU/Sucho")
saveRDS(u, "data/uzivani_ocistene.rds")
