require(data.table)
require(dplyr)

.datadir <- "C:/Users/Irina/ownCloud/Shared/BILAN_UPOV/used_data/webapp_data/bilan_n"

BM <- readRDS(file.path('s:/Odbor 210/SOUKROMÉ ADRESÁŘE/Irina/hamr-js/data', 'month_stable.rds')) %>% select(UPOV_ID = IID, everything())

mesice <- c("Leden","Unor","Brezen","Duben","Kveten","Cerven",
            "Cervenec","Srpen","Zari","Rijen","Listopad","Prosinec")

seasons <- data.frame(month = c(1:12), seasons = c("Zima", "Zima", "Jaro", "Jaro", "Jaro", "Leto", "Leto",
                                                   "Leto","Podzim", "Podzim", "Podzim", "Zima"))

BM <- BM %>% left_join(seasons, by="month") 
BM$month2 <- as.factor(BM$month)
levels(BM$month2) <- mesice

var_list = unique(BM$variables)
BM_full <- NULL

for(i in var_list){
  if(i != 'T'){
    BM2 <- BM[variable == i, ] %>% group_by(UPOV_ID, year) %>% mutate(annual.avg = sum(value)) %>% ungroup
  }else{
    BM2<- BM[variable == i, ] %>% group_by(UPOV_ID, year) %>% mutate(annual.avg = mean(value)) %>% ungroup
  }
  BM2 <- BM2 %>% group_by(UPOV_ID) %>% mutate(mean_ep = mean(value)) %>%  ungroup
  BM_full <- rbind(BM_full, BM2)
}

saveRDS(BM_full, file.path(.datadir, 'BM_81-19.rds'))


#IND
#SPEI, SGI, SRI

szn <- dir(file.path(.datadir, "webapp_data/indikatory_2019"))

for(s in c('spei', 'sgi', 'sriF')){
  
  if(s == 'spei'){
    
    ind_ls <- grep(paste0(s, '_'), szn, value = T)
    ind_dta <- NULL
    
    for(i in 1:length(ind_ls)){
      x <- readRDS(file.path(.datadir, "webapp_data/indikatory_2019", ind_ls[i]))
      x <- x %>% group_by(IID, year, week) %>% mutate(value = mean(SPEI, na.rm = T)) %>% ungroup()
      x <- x[, c("UPOV_ID", "DTM", "year", "week", "value")]
      ind_dta <- rbind(ind_dta, x)
      gc()
    }
    
  }else{
    
    ind_ls <- grep(paste0(s, '_'), szn, value = T)
    ind_dta <- NULL
    
    for(i in 1:length(ind_ls)){
      x <- readRDS(file.path(.datadir, "webapp_data/indikatory_2019", ind_ls[i]))[,-1]
      x <- x %>% group_by(IID, year, week) %>% mutate(value = mean(SPI, na.rm = T)) %>% ungroup()
      x <- x[, c("UPOV_ID", "DTM", "year", "week", "value")]
      ind_dta <- rbind(ind_dta, x)
      gc()
    }
  }
  
  ind_dta$value[is.nan(ind_dta$value)] <- NA
  
  saveRDS(ind_dta, file.path(.datadir, "webapp_data/indikatory_2019", paste0(s, '.rds')))
}

# DEF_PUDA, RETENCE 

x <- as.data.table(readRDS(file.path(.datadir, 'webapp_data/indikatory_2019', 'AWV_l.rds')))
x <- x[,.(AWV = mean(AWV, na.rm = T), AWD = mean(AWD, na.rm = T), RATIO = mean(RATIO, na.rm = T)), by=.(IID, DTM)]
x[is.nan(x$AWD),]$AWD <- NA
x <- x[year(DTM) %in% seq(1981, 2019)]

for(s in c('def_puda', 'retence')){
  
    if(s == "retence"){
      ind_xx <- x[, c('year','week', 'value') := .(year(DTM), week(DTM), RATIO*100)] %>% select(UPOV_ID = IID, DTM, year, week, value)
    }else if(s == "def_puda"){
      ind_xx <- x[, c('year','week', 'value') := .(year(DTM), week(DTM), AWD)] %>% select(UPOV_ID = IID, DTM, year, week, value)
    }
  
  saveRDS(ind_xx, file.path(.datadir, "webapp_data/indikatory_2019", paste0(s, '.rds')))
  gc()
}

#UZV

###MAP###
require(sp)

povodi <- readRDS(file.path(.datadir, "webapp_data/geo_rds/povodi.rds"))
popis <- readRDS(file.path(.datadir, "webapp_data/popis.rds"))
povodi <- sp::merge(povodi, popis, by='UPOV_ID')

u <- readRDS(file.path(.dir, "u_clear.rds")) %>% rename(value = real)

u_map <- u %>% select(UPOV_ID, ICOC, JEV, NAZICO, POVODI, X, Y) %>% distinct()
u_map <- SpatialPointsDataFrame(coords = u_map[, c("X", "Y")], u_map[,1:5], proj4string = CRS("+init=epsg:2065"))
u_map <- spTransform(u_map, CRS("+init=epsg:4326") )

# plot(povodi)
# points(u_map, pch=20, col="red")

#clipping
bound <- readRDS(file.path(.datadir, "webapp_data/geo_rds/hranice.rds"))
bound <- spTransform(bound, CRS("+init=epsg:4326") )

u_map <- u_map[bound, ]

u_map$ID <- paste(u_map$ICOC, u_map$JEV, sep = '_')

saveRDS(u_map, file.path(.datadir, "webapp_data/uzivani", "u_leaflet_2019.rds"))

###TS###

u <- readRDS(file.path(.dir, "real_povol_fill_upov.rds")) %>% select(UPOV_ID, ICOC, JEV, X, Y, NAZICO, DTM = DTM.x, real = value.x, povol = value.y)
u <- u[!is.na(u$DTM),]
u <- u[!is.na(u$UPOV_ID),]

u_dt <- u

#complete missing JEV
JEV <- u_dt[!is.na(u_dt$JEV),] %>% select(-DTM, -real, -povol, -NAZICO) %>% distinct()
u_dt <- inner_join(u_dt, JEV, by = c("UPOV_ID", "ICOC", "X", "Y")) %>% select(-JEV.x, JEV = JEV.y)

u_dt <- u_dt[!is.na(u_dt$JEV),]

NAZICO_dt <- u_dt[, c("UPOV_ID", "ICOC", "JEV", "NAZICO")] %>% distinct() 
NAZICO_new <- NAZICO_dt[!duplicated(NAZICO_dt[,c("UPOV_ID","ICOC", "JEV")]),]
NAZICO_dt <- merge(NAZICO_dt, NAZICO_new, by = c("UPOV_ID","ICOC", "JEV")) %>% rename(NAZICO_new = NAZICO.y) %>% select(-NAZICO.x)

u_dt <- inner_join(u_dt, NAZICO_dt, by = c("UPOV_ID","ICOC", "JEV")) %>% select(-NAZICO, NAZICO = NAZICO_new)

u_dt <- u_dt %>% select(-X, -Y)

u_dt$ID <- paste(u_dt$ICOC, u_dt$JEV, sep = '_')

saveRDS(u_dt, file.path(.datadir, "webapp_data/uzivani", "uzivani_2019_TS.rds"))
