require(dplyr, quietly = T, warn.conflicts = F)
require(data.table, quietly = T, warn.conflicts = F)

# vlastni cesty
# cat("Uzivatel? ")
# id <- scan("stdin", what = character(), n = 1, quiet = T)
# 
# if(id == "work"){
#   .path2 <- "s:/Odbor 210/SOUKROMÉ ADRESÁŘE/Irina/sucho_data/webapp_data"
#   .dir <- "s:/Odbor 210/SOUKROMÉ ADRESÁŘE/Irina/hamr-js/data"
# }else if(id == "lnx"){
#   .path2 <- '/home/irina/ownCloud/Shared/BILAN_UPOV/used_data/webapp_data'
#   .dir <- '/home/irina/git/hamr-js/data'
# }else if(id == "win"){
#   .path2 <- 'c:/Users/Irina/ownCloud/Shared/BILAN_UPOV/used_data/webapp_data'
#   .dir <- 'c:/Users/Irina/git/hamr-js/data'
# }

# mesicne
# scan pouze pro spousteni z terminalu, odstranit dle potreby
cat('Vytvorit novy BM_81-19.rds soubor z month_stable.rds?')
cat(c('Y|n'), sep = "\n")
new_bm_file <- scan("stdin", what = character(), n = 1, quiet = T)

if(new_bm_file == 'Y' | new_bm_file == 'y'){
  source(file.path(gsub('/data', '', .dir), 'R/updates/BM_81-19_monthly.R'))
  create_BM_file(FROM = .dir, TO = .path2)
}

# tydne

# SPEI, SGI, SRI

max_year = 2019

szn <- dir(file.path(.path2, "indikatory_2019"))

for(s in c('spei', 'sgi', 'sriF')){
    
    stbl <- readRDS(file.path(.path2, "indikatory_2019", paste0(s, '.rds')))
    new <- readRDS(file.path(.path2, "indikatory_2019", paste0(s, '_', max_year, '.rds')))
    
    if(max(stbl$DTM) < max(new$DTM)){
      if(s == 'spei'){
        new <- new %>% group_by(IID, year, week) %>% mutate(value = mean(SPEI, na.rm = T)) %>% ungroup()
      }else{
        new <- new[,-1] %>% group_by(IID, year, week) %>% mutate(value = mean(SPI, na.rm = T)) %>% ungroup()  
        new$value[is.nan(new$value)] <- NA
      }
      new <- new[, c("UPOV_ID", "DTM", "year", "week", "value")]
      new <- new[new$DTM > max(stbl$DTM),]
      
      stbl <- rbind(stbl, new)
      saveRDS(stbl, file.path(.path2, "indikatory_2019", paste0(s, '.rds')))
      
    }else{
      print(paste(s, 'je aktualni'))
      next
    }
    
    gc()
}

# DEF_PUDA, RETENCE 

new <- as.data.table(readRDS(file.path(.path2, 'indikatory_2019', 'AWV_l.rds')))
new <- new[,.(AWV = mean(AWV, na.rm = T), AWD = mean(AWD, na.rm = T), RATIO = mean(RATIO, na.rm = T)), by=.(IID, DTM)]
new[is.nan(new$AWD),]$AWD <- NA
new <- new[year(DTM) %in% seq(1981, 2019)]

for(s in c('def_puda', 'retence')){
  
  stbl <- readRDS(file.path(.path2, "indikatory_2019", paste0(s, '.rds')))
  
  if(max(stbl$DTM) < max(new$DTM)){
    if(s == 'retence'){
      new <- new[, c('year','week', 'value') := .(year(DTM), week(DTM), RATIO*100)] %>% select(UPOV_ID = IID, DTM, year, week, value)
    }else{
      new <- new[, c('year','week', 'value') := .(year(DTM), week(DTM), AWD)] %>% select(UPOV_ID = IID, DTM, year, week, value)
    }
    new <- new[new$DTM > max(stbl$DTM),]
    
    stbl <- rbind(stbl, new)
    saveRDS(stbl, file.path(.path2, "indikatory_2019", paste0(s, '.rds')))
    
  }else{
    print(paste(s, 'je aktualni'))
    next
  }
  
  gc()
}
