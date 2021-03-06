require(rgdal)
require(rmapshaper)
require(maptools)
require(data.table)
require(stringr)
require(dplyr)

#1 Prostorová data
setwd("C://Users//irina//ownCloud//Shared//BILAN_UPOV")
#Loading
#--------------------
povodi_0 <- readOGR('data/geo/E_HEIS$UPV_HLGP#P2$wm.shp', 'E_HEIS$UPV_HLGP#P2$wm')
reky_0 <- readOGR('data/geo/E_ISVS$UPOV_R.shp', 'E_ISVS$UPOV_R')
jezera_0 <- readOGR('data/geo/E_ISVS$UPOV_J.shp', 'E_ISVS$UPOV_J')
nadrze_0 <- readOGR('data/geo/nadrze.shp')

#Preparation of data
#--------------------
povodi_0 <- spTransform(povodi_0, CRS("+init=epsg:4326"))
povodi <- ms_simplify(povodi_0, keep_shapes = TRUE, keep = 0.01)
#--------------------
proj4string(reky_0) <- CRS("+title=Krovak JTSK +proj=krovak +lat_0=49.5 +lon_0=24.83333333333333 +alpha=30.28813975277778 +k=0.9999 +x_0=0 +y_0=0 +ellps=bessel +units=m +towgs84=570.8,85.7,462.8,4.998,1.587,5.261,3.56 +no_defs <>")
reky_0 <- spTransform(reky_0, CRS("+init=epsg:4326"))
reky <- ms_simplify(reky_0, keep_shapes = TRUE, keep = 0.10)
#--------------------
proj4string(jezera_0) <- CRS("+title=Krovak JTSK +proj=krovak +lat_0=49.5 +lon_0=24.83333333333333 +alpha=30.28813975277778 +k=0.9999 +x_0=0 +y_0=0 +ellps=bessel +units=m +towgs84=570.8,85.7,462.8,4.998,1.587,5.261,3.56 +no_defs <>")
jezera_0 <- spTransform(jezera_0, CRS("+init=epsg:4326"))
jezera <- ms_simplify(jezera_0, keep_shapes = TRUE, keep = 0.05)

proj4string(nadrze_0) <- CRS("+title=Krovak JTSK +proj=krovak +lat_0=49.5 +lon_0=24.83333333333333 +alpha=30.28813975277778 +k=0.9999 +x_0=0 +y_0=0 +ellps=bessel +units=m +towgs84=570.8,85.7,462.8,4.998,1.587,5.261,3.56 +no_defs <>")
nadrze <- spTransform(nadrze_0, CRS("+init=epsg:4326"))

kraje_0 <- readOGR('data/geo/admin/kraje.shp')
kraje <- spTransform(kraje_0, CRS("+init=epsg:4326"))
kraje <- ms_simplify(kraje_0, keep_shapes = TRUE, keep = 0.10)

a <- kraje_0$NAZEV
a[1] <- "Ústecký"
kraje_0$NAZEV <- kraje_0$NK
kraje_0$NAZEV <- a


okresy_0 <- readOGR('data/geo/admin/okresy.shp')
okresy_0 <- spTransform(okresy_0, CRS("+init=epsg:4326"))
okresy <- ms_simplify(okresy_0, keep_shapes = TRUE, keep = 0.10)

#Saving
#--------------------
#writeSpatialShape(povodi,"data/prep/povodi")
# writeSpatialShape(reky,"data/prep/reky")
# writeSpatialShape(jezera,"data/prep/jezera")

writeOGR(povodi, "C://Users//irina//ownCloud//Shared//BILAN_UPOV//used_data//webapp_data//geo", "povodi", driver="ESRI Shapefile", encoding  = "UTF-8")
writeOGR(reky, "data/prep", "reky", driver="ESRI Shapefile", encoding  = "UTF-8")
writeOGR(jezera, "data/prep", "jezera", driver="ESRI Shapefile", encoding  = "UTF-8")
writeOGR(nadrze, "data/prep", "nadrze", driver="ESRI Shapefile", encoding  = "UTF-8")
#writeOGR(kraje, "data/prep", "kraje", driver="ESRI Shapefile", encoding  = "UTF-8")
writeOGR(okresy, "data/prep", "okresy", driver="ESRI Shapefile", encoding  = "UTF-8")

kraje <- readOGR("data/prep/kraje.shp")
a <- as.character(kraje$NAZEV)
a[2] <- "Ústecký"
kraje <- ms_simplify(kraje, keep_shapes = TRUE, keep = 0.10)
kraje$NAZEV <- a 

writeSpatialShape(kraje,"data/prep/kraje")

povodi_III_0 <- readOGR('data/geo/A08_Povodi_III.shp')
povodi_III_0 <- spTransform(povodi_III_0, CRS("+init=epsg:4326"))
povodi_III <- ms_simplify(povodi_III_0, keep_shapes = TRUE, keep = 0.10)

writeSpatialShape(povodi_III,"data/prep/povodi_III")

.datadir <- "s:\\SOUKROMÉ ADRESÁŘE\\Irina\\sucho_data\\webapp_data"
hranice <- readOGR(file.path(.datadir, "geo\\CZE_adm0.shp"))
hranice <- spTransform(hranice, CRS("+init=epsg:4326"))
hranice <- rmapshaper::ms_simplify(hranice, keep_shapes = TRUE, keep = 0.10)
saveRDS(hranice, file.path(.datadir, "geo_rds\\hranice.rds"))

# leaflet() %>%
#   addTiles() %>% 
#   addPolygons(data=kraje, color="#000000", fillColor = "#595959", 
#               weight = 2, opacity = 1,
#               popup = kraje$NAZEV)

#2 Měsiční bilance

#Loading
#--------------------
.datadir <- "C:\\Users\\irina\\Disk Google\\1_CZU\\Sucho\\data\\bilan_ts"
r = readRDS(file.path(.datadir, 'BER_0010.rds'))

#Preparation of data
#--------------------
i ='BER_0010.rds'
M = list()
for (i in dir(.datadir)){
  r = readRDS(file.path(.datadir,i))
  mr = melt(r, id.vars = 'DTM')
  m1 = mr[variable!='T', .(value = sum(value)), by = .(year(DTM), month(DTM), variable)]
  m2 = mr[variable=='T', .(value = mean(value)), by = .(year(DTM), month(DTM), variable)]
  m = rbind(m1,m2)
  m[, DTM:=as.Date(paste(year, month, 1, sep = '-'))]
  M[[length(M)+1]] = m
}

names(M) = gsub('\\.rds', '', dir(.datadir))
BM = rbindlist(M, idcol = 'UPOV_ID')

.datadir <- "C:\\Users\\irina\\Disk Google\\1_CZU\\Sucho\\data"
saveRDS(BM, file.path(.datadir, "mbilan\\bilan_month_dt_2018.rds"))

#Saving
#--------------------
# setwd("./data")
# BM <- readRDS(file.path(.datadir, "webapp_data/mbilan/bilan_month.rds"))

mesice <- c("Leden","Unor","Brezen","Duben","Kveten","Cerven",
            "Cervenec","Srpen","Zari","Rijen","Listopad","Prosinec")

seasons <- data.frame(month = c(1:12), seasons = c("Zima", "Zima", "Jaro", "Jaro", "Jaro", "Leto", "Leto",
                                                   "Leto","Podzim", "Podzim", "Podzim", "Zima"))

BM <- BM %>% left_join(seasons, by="month") 
BM$month2 <- as.factor(BM$month)
levels(BM$month2) <- mesice

BM <- BM %>% group_by(UPOV_ID, year, variable) %>% mutate(annual.avg = mean(value)) %>% ungroup

BM <- BM %>% group_by(UPOV_ID, variable) %>% mutate(mean_ep = mean(value)) %>%  ungroup

# quarter <- data.frame(month=c(1:12), quarter = rep(1:4, each=3)) 
# BM <- BM %>% left_join(quarter, by="month")
# 
# BM <- BM %>% group_by(UPOV_ID, year, quarter, variable) %>% mutate(quarterly.avg = mean(value)) %>% ungroup

BM.long <- dcast(BM, month+year+UPOV_ID+DTM~variable)
BM.long$m <- as.factor(BM.long$month)
levels(BM.long$m) <- mesice

BM <- as.data.table(BM)

saveRDS(BM, file.path(.datadir, 'webapp_data/mbilan/bilan_month.rds'))
saveRDS(BM.long, file.path(.datadir, 'webapp_data/mbilan/bilan_month_long.rds'))
saveRDS(BM, file.path(.datadir, 'webapp_data/mbilan/bilan_month_data_table.rds'))

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

# stanice <- readOGR(file.path(.datadir, "webapp_data/geo/stanice.shp"))
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

QD <- select(QD, -OBDOBI.S.DATY.DENNICH.PRUTOKU, -NAZEV.STANICE, -TOK, -Plocha..km2.)

# QD <- readRDS(file.choose())

#Saving
#--------------------
saveRDS(QD, "QD.rds")
writeOGR(stanice, "data/prep", "stanice", driver="ESRI Shapefile", encoding  = "UTF-8")


#4 uzivani_ocistene
#Loading
#--------------------
u <- read.csv('data/vuv/uzivani_utvary_06_16.csv',encoding = 'UTF-8', header = TRUE, sep = ";")
u <- readRDS('data/uzivani/79_15/uzivani.rds')
#Preparation of data
#--------------------

u <- u[complete.cases(X, Y)]
u$DTM <- as.character(u$DTM)

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

u <- u[!is.na(u$X)|!is.na(u$Y),] #vynechani bodu s neznamymi souradnicemi 

#Saving
#--------------------
setwd("C:/Users/Irina/Disk Google/1_ČZU/Sucho")
saveRDS(u, "data/uzivani/06_16/uzivani_NA.rds") #obsahuje NA
saveRDS(u, 'data/uzivani/06_16/uzivani_na_rm.rds') #vynechane NA

### doplneni zaznamu od bodu se stejnym ICOC
u <- readRDS('data/uzivani/06_16/uzivani_NA.rds')

u$na <- as.numeric(is.na(u$X))
# u <- u %>% group_by(ICOC, JEV) %>% mutate(mean.na = mean(na))
u <- u %>% group_by(ICOC) %>% mutate(mean.X = mean(X, na.rm = T), mean.Y = mean(Y, na.rm = T)) %>% ungroup
u$X[is.na(u$X)] <- u$mean.X[is.na(u$X)]
u$Y[is.na(u$Y)] <- u$mean.Y[is.na(u$Y)]

u <- u[!is.na(u$X)|!is.na(u$Y),]

saveRDS(u, 'data/uzivani/06_16/uzivani_na_nahraz.rds') # NA nahrazene průměrem za ICOC

u <- select(u, -ROCNI.MNOZSTVI.tis.m3, -POVOLENE.MNOZSTVI.ROK.tis.m3 , -HEIS_POZN, -na, -CZ_NACE)

saveRDS(u, file.path(.datadir, 'webapp_data/uzivani/06_16/uzivani_na_nahraz.rds')) # NA nahrazene průměrem za ICOC zmenseny

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


#6 uzivani / UPOV_ID
#--------------------
require(rgeos)

povodi <- readOGR("data/prep/povodi.shp")
popis 
povodi <- sp::merge(povodi, popis, by='UPOV_ID')

u <- readRDS('data/uzivani/79_15/uzivani.rds')

u <- u[complete.cases(X, Y)]
xy <- SpatialPoints(u[, c("X", "Y")], proj4string = CRS("+init=epsg:2065"))
xy <- spTransform(xy, CRS("+init=epsg:4326") )

### 524, 525, 751, 752 - CHYBA 
# Error in createPolygonsComment(p) : 
# rgeos_PolyCreateComment: orphaned hole, cannot find containing polygon for hole at index 2
# In addition: Warning message:
#   In RGEOSBinPredFunc(spgeom1, spgeom2, byid, func) :
#   spgeom1 and spgeom2 have different proj4 strings
### 1112 1113 1114 1115 1116 1117 1118 1119 1120 1121
# Error in povodi[povodi$UPOV_ID == i, ] : NAs not permitted in row index
# In addition: There were 50 or more warnings (use warnings() to see the first 50)

pocitadlo <- 0

for (i in povodi$UPOV_ID) {
  kde <- gIntersects(povodi[povodi$UPOV_ID==i,], xy, byid = TRUE)
  u$UPOV_ID[kde[,1]] <- i
  pocitadlo <- pocitadlo+1
  print(paste(i, (pocitadlo/1121)*100, '%'))
}

 saveRDS(u, 'data/uzivani/79_15/uzivani_upovid.rds')
 
 #7 indikatory
 #--------------------
 
 spi <- readRDS(file.path(.datadir, "indikatory/spi.Rds"))
 spi$month <- month(spi$DTM) 
 spi$year <- year(spi$DTM)

 spei <- readRDS(file.path(.datadir, "indikatory/spei.Rds"))
 
 spi <- select(spi, -IID)
 spei <- select(spei, -IID)
 
 saveRDS(spi, file.path(.datadir, "webapp_data/indikatory/spi.rds")) 
 saveRDS(spei, file.path(.datadir, "webapp_data/indikatory/spei.rds")) 
 
 spi <- as.data.table(spi)
 spei <- as.data.table(spei)
 
 .datadir <- "/home/irina/ownCloud/Shared/BILAN_UPOV/used_data"
 
 spi <- readRDS(file.path(.datadir, "webapp_data/spi.rds")) 
 spei <- readRDS(file.path(.datadir, "webapp_data/spei.rds")) 
 
 for(i in unique(spi$scale)){
  x <- spi[scale == i]
  saveRDS(x,
          paste0("/home/irysek/ownCloud/Shared/BILAN_UPOV/used_data/webapp_data/indikatory/", "spi_", i, ".rds"))
 }
 
 for(i in unique(spei$scale)){
   x <- spei[scale == i]
   saveRDS(x,
           paste0("/home/irysek/ownCloud/Shared/BILAN_UPOV/used_data/webapp_data/indikatory/", "spei_", i, ".rds"))
 }
 
 spei_filter <- spei[scale == input$krok]
 
 #8 pars
 #--------------------
 pars <- readRDS(file.path(.datadir, "pars/pars.rds"))
 
 data <- c()
 name <- names(pars)
 for(i in 1:length(pars)){
   tab <- pars[[i]]
   data <- rbind(data,
                 data.frame(UPOV_ID = rep(name[i],6), tab$pars))
   print(paste("Processing....",i))
   
 }
 
 saveRDS(data, file.path(.datadir, "webapp_data/pars/pars.rds"))
 
 #9 popis txt to rds
 #--------------------
 
popis <- read.table('used_data/webapp_data/E_ISVS$UTV_POV.txt',encoding = 'UTF-8', header = TRUE, sep=';')
popis <- select(popis, UPOV_ID, NAZ_UTVAR, NAZ_POVODI, NAZ_OBLAST, KTG_UPOV, U_PMU)
saveRDS(popis, file.path(.datadir, "webapp_data/popis.rds"))

#10 uzivani_leaflet
#--------------------

u <- readRDS(file.path(.datadir, "webapp_data/uzivani/06_16/uzivani_na_nahraz.rds"))
u <- as.data.table(u)
saveRDS(u, file.path(.datadir, "webapp_data/uzivani/06_16/uzivani_na_nahraz_dt.rds"))

  u_leaflet <- u %>% group_by(UPOV_ID, NAZICO, POVODI, JEV, X, Y, ICOC) %>% summarise(mean=mean(value))
  u_leaflet <- SpatialPointsDataFrame(u_leaflet[, c("X", "Y")], u_leaflet, proj4string = CRS("+init=epsg:2065"))
  u_leaflet <- spTransform(u_leaflet, CRS("+init=epsg:4326"))
  
saveRDS(u_leaflet, file.path(.datadir, "webapp_data/uzivani/u_leaflet.rds"))

#11 cara prekroceni rds
#--------------------

BM <- readRDS(file.path(.datadir, "webapp_data/mbilan/bilan_month.rds"))

cp <- BM %>% group_by(UPOV_ID, variable) %>% mutate(k = rank(-value), n = n()) %>% mutate(p_year = (k-0.3)/(n+0.4)) 

cp <- cp %>%  group_by(UPOV_ID, variable, seasons) %>% mutate(k = rank(-value), n = n()) %>% mutate(p_season = (k-0.3)/(n+0.4))

cp <- cp %>%  group_by(UPOV_ID, variable, month) %>% mutate(k = rank(-value), n = n()) %>% mutate(p_month = (k-0.3)/(n+0.4))

# cpa <- cp %>% ungroup() %>% filter(UPOV_ID == "DUN_0010", variable == "P", seasons == "Zima") %>% select(value, p_season) 
# plot(cpa)

cp_final <- cp %>% ungroup() %>% select(UPOV_ID, variable, p_year, p_month, p_season, seasons, month2, value)

saveRDS(cp_final, file.path(.datadir, "webapp_data/to_from/cara_prekroceni.rds"))

cp <- as.data.table(cp_final)
saveRDS(cp, "C:\\Users\\irina\\ownCloud\\Shared\\BILAN_UPOV\\used_data\\webapp_data\\to_from\\cara_prekroceni_dt_2018.rds")
saveRDS(cp, file.path(.datadir, "webapp_data/to_from/cara_prekroceni_dt.rds"))

#12 m-denní prutoky (chars)
#--------------------
chars<- readRDS(file.path(.datadir, "chmu/chars_mm.rds"))

chars <- chars %>% select(UPOV_ID, Qa, choices.mday)

saveRDS(chars, file.path(.datadir, "webapp_data/chmu/chars_mm.rds"))

#qmd

chars <- readRDS(file.path(.datadir, "webapp_data/chmu/chars_mm.rds"))
CatCa::qmd()


#13 VALIDACE
#--------------------

dbcn_to_upov <- readRDS(file.path(.datadir, "chmu/dbcn_uid_mon.rds"))

QD <- merge(dbcn_to_upov, QD, by = 'DBCN')
QD <- QD[order(QD$DTM),]
saveRDS(QD, file.choose())

mdta_val <- readRDS(file.path(.datadir,"chmu/mdta_2016.rds"))
mdta_val <- mdta_val[, c(1,3,4,6,7,8)]
mdta_val <- merge(mdta_val, dbcn_to_upov, by = 'DBCN')
saveRDS(mdta_val, file.path(.datadir, "webapp_data/chmu/mdta_2016.rds"))

#avg_u <- readRDS(file.path(.datadir,"uzivani/avg_uziv_denni/BER_0010.rds"))


#14 simulovana mesicni data validace
#--------------------

list_of_files <- dir(file.path(.datadir, "routed-0_bilan_bez_VN/"))

dta <- c()  

for(i in list_of_files){
  x <- readRDS(file.path(.datadir, "routed-0_bilan_bez_VN/",i))
  upov_name <- gsub(".rds","",i)
  x$UPOV_ID <- upov_name
  dta <- rbind(dta,x)
  print(paste("scream ",round(which(i== list_of_files)/length(list_of_files),4)*100,"%"))
}

saveRDS(dta, file.path(.datadir,"used_data/webapp_data/chmu/dta_routed0.rds"))

dta$m <- as.factor(substr(dta$DTM,6,7))
dta$y <- as.factor(substr(dta$DTM,1,4))

dta_m <- dta %>% group_by(m,y,UPOV_ID) %>% summarise(RM = mean(TRM_mm_d)) %>% mutate(DTM = as.Date(paste(y,m,"15",sep="-")))
new_dta_m <- merge(mdta_val, dta_m, by=c("DTM","UPOV_ID"))

saveRDS(new_dta_m, file.path(.datadir, "webapp_data/chmu/data_validace.rds"))

#15 update -> vyhledove uzivani 
#--------------------

require(dplyr)
require(data.table)

.datadir <- "S:/SOUKROMÉ ADRESÁŘE/Irina/sucho_data"

vhb <- readxl::read_xlsx(file.path(.datadir, "webapp_data/uzivani/vhb_2017.xlsx"))

vhb_val <- vhb %>% select(ICOC, JEV, POVODI, NAZICO, X, Y, starts_with("MVM"))

vhb_val = melt(vhb_val, id.vars = c("ICOC", "JEV", "POVODI", "NAZICO", "X", "Y"))

vhb_val$variable <- gsub("MVM*", "", vhb_val$variable)

vhb_val$DTM <- paste0("01", stringr::str_sub(paste0("00", vhb_val$variable),-2,-1), "2017")
vhb_val$DTM <- as.Date(vhb_val$DTM, format = "%d%m%Y")

vhb_val$ROK <- 2017
colnames(vhb_val)[7] <- "MESIC"

vhb_val$X <- as.numeric(vhb_val$X)
vhb_val$Y <- as.numeric(vhb_val$Y)
vhb_val$ICOC <- as.numeric(vhb_val$ICOC)

vhb_val <- vhb_val %>% group_by(ICOC) %>% mutate(mean.X = mean(X, na.rm = T), mean.Y = mean(Y, na.rm = T)) %>% ungroup
vhb_val$X[is.na(vhb_val$X)] <- vhb_val$mean.X[is.na(vhb_val$X)]
vhb_val$Y[is.na(vhb_val$Y)] <- vhb_val$mean.Y[is.na(vhb_val$Y)]

vhb_val <- vhb_val[!is.na(vhb_val$X)|!is.na(vhb_val$Y),] #vynechani bodu s neznamymi souradnicemi 

uz_up <- readRDS(file.path(.datadir, "webapp_data/uzivani/uzivani_upovid.rds"))
prop <- uz_up %>% select(ICOC, UPOV_ID)
prop2 <- prop[!duplicated(ICOC),]

vhb_val <- left_join(vhb_val, prop2, by="ICOC")

vhb_val <- vhb_val %>% select(ICOC, JEV, POVODI, NAZICO, X, Y, UPOV_ID, ROK, MESIC, value, DTM, mean.X, mean.Y)

saveRDS(vhb_val, file.path(.datadir, "webapp_data/uzivani/u_2017.rds"))

u_6_16 <- readRDS(file.path(.datadir, "webapp_data/uzivani/06_16/uzivani_na_nahraz_dt.rds"))

u_6_17 <- bind_rows(u_6_16, vhb_val)

u_6_17 <- as.data.table(u_6_17)
saveRDS(u_6_17, file.path(.datadir, "webapp_data/uzivani/uzivani_06_17_dt.rds"))

#16 uivani - pasport 
#--------------------
.datadir <- "S:/SOUKROMÉ ADRESÁŘE/Irina/sucho_data"

vhb <- readxl::read_xlsx(file.path(.datadir, "webapp_data/uzivani/vhb_2017.xlsx"))

vhb_p <- vhb %>% select(ICOC, JEV, NAZICO, VLASTNIK, PROVOZOVATEL, OBEC, HG_RAJON,
                        CHP, TOK, PMM3_ROK, PMM3_MES, VHPOV_VYDAL, DATUM, DAT_PL_DO)

vhb_p$ICOC <- as.numeric(vhb_p$ICOC)

saveRDS(vhb_p, file.path(.datadir, "webapp_data/uzivani/uzivani_pas.rds"))

#17 indikatory 2018
#--------------------

.dir1 <- "C:/Users/Georgievova/Documents/indikatory_new"

spi <- readRDS(file.path(.dir1, "spi.rds"))

spei <- readRDS(file.path(.dir1, "spei.Rds"))

spi <- select(spi, -IID)
spei <- select(spei, -IID)

spi <- as.data.table(spi)
spei <- as.data.table(spei)


for(i in unique(spi$scale)){
  x <- spi[scale == i]
  saveRDS(x,
          paste0("s:/SOUKROMÉ ADRESÁŘE/Irina/sucho_data/webapp_data/indikatory_updt/", "spi_", i, ".rds"))
}

for(i in unique(spei$scale)){
  x <- spei[scale == i]
  saveRDS(x,
          paste0("s:/SOUKROMÉ ADRESÁŘE/Irina/sucho_data/webapp_data/indikatory_updt/", "spei_", i, ".rds"))
}

#18 geo to st_read_rds
#--------------------

require(sf)
require(rgdal)

.datadir <- "S:/SOUKROMÉ ADRESÁŘE/Irina/sucho_data"
  
povodi <- st_read(file.path(.datadir, "webapp_data/geo/povodi.shp"), quiet = TRUE)
reky <- st_read(file.path(.datadir, "webapp_data/geo/reky.shp"), quiet = TRUE)
jezera <- st_read(file.path(.datadir, "webapp_data/geo/jezera.shp"), quiet = TRUE)
nadrze <- st_read(file.path(.datadir, "webapp_data/geo/nadrze.shp"), quiet = TRUE)
kraje <- st_read(file.path(.datadir, "webapp_data/geo/kraje.shp"), quiet = TRUE)
okresy <- st_read(file.path(.datadir, "webapp_data/geo/okresy.shp"), quiet = TRUE)
povodi_III <- st_read(file.path(.datadir, "webapp_data/geo/povodi.shp"), quiet = TRUE)

QD_stanice <- readOGR(file.path(.datadir, "webapp_data/geo/stanice.shp"))
saveRDS(QD_stanice, file.path(.datadir, "webapp_data/geo_rds/stanice.rds"))

QD_stanice <- st_read(file.path(.datadir, "webapp_data/geo/stanice.shp"), quiet = TRUE)
# QD_stanice <- st_zm(QD_stanice, drop = T, what = "ZM")

saveRDS(povodi, file.path(.datadir, "webapp_data/st_read_rds/povodi.rds"))
saveRDS(reky, file.path(.datadir, "webapp_data/st_read_rds/reky.rds"))
saveRDS(jezera, file.path(.datadir, "webapp_data/st_read_rds/jezera.rds"))
saveRDS(nadrze, file.path(.datadir, "webapp_data/st_read_rds/nadrze.rds"))
saveRDS(kraje, file.path(.datadir, "webapp_data/st_read_rds/kraje.rds"))
saveRDS(okresy, file.path(.datadir, "webapp_data/st_read_rds/okresy.rds"))
saveRDS(povodi_III, file.path(.datadir, "webapp_data/st_read_rds/povodi_III.rds"))
saveRDS(QD_stanice, file.path(.datadir, "webapp_data/st_read_rds/stanice.rds"))





