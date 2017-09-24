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
saveRDS(BM, 'mbil/bilan_month.rds')


#3
#--------------------
setwd("..")

#--------------------
#Loading
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


