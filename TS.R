require(data.table)
require(ggplot2)
require(dplyr)
require(ggvis)
require(ggthemes)
require(dygraphs)

setwd("C:/Users/Irina/Disk Google/1_ČZU/Sucho/data/bilan")
BM <- readRDS('mbil/bilan_month.rds')

# P ... WEI - vystup modelu BILAN

# P ... srážky na povodí [mm]
# R ... odtok (pozorovaný) [mm]
# RM ... celkovy odtok (simulovaný) [mm]
# BF ... základní odtok (simulovaný) [mm]
# B ... základní odtok (odvozený) [mm]
# DS ... zásoba pro přímý odtok [mm]
# PET ... potenciální evapotranspirace [mm]
# ET ... územní výpar [mm]
# SW ... půdní vlhkost (zásoba vody v nenasycené zóně) [mm]
# SS ... zásoba vody ve sněhu [mm]
# GS ... zásoba podzemní vody [mm]
# INF ... infiltrace do půdy [mm]
# PERC ... perkolace z půdní vrstvy [mm]
# RC ... dotace zásoby podzemní vody [mm]
# T ... teplota vzduchu [°C]
# H ... vlhkost vzduchu [%]
# WEI ... váhy pro kalibraci odtoku [-]


BM[variable=='P' & month %in% c(3:5), mean(value), by = UPOV_ID]
BM[variable=='P',value]


n <- BM %>% filter(variable == 'P') %>% group_by(UPOV_ID) %>%  summarise(sum=sum(value))

srazky <- BM %>% filter(variable == 'P') %>% group_by(year, UPOV_ID) %>% mutate(yearly.avg = mean(value))

ggplot(srazky[srazky$UPOV_ID=='DUN_0010',])+geom_line(aes(y=value, x=DTM), colour="deepskyblue4")+
          ylab("srážky na povodí [mm]")+ xlab("čas")+theme_hc()+
          ggtitle("Sražky")+theme(plot.title = element_text(hjust = 0.5))




ts.srazky <- ts(srazky[srazky$UPOV_ID == 'DUN_0010',]$value, start = c(1961,1), frequency = 12)

dygraph(ts.srazky) %>% 
  dySeries('V1') %>%
  dyRangeSelector()



