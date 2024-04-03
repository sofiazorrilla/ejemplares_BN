## Organization and exploration of specimen data 19/04/2022

library(googlesheets4)
library(tidyverse)
library(googledrive)
library(gtools)

ej_admid <- read_sheet("https://docs.google.com/spreadsheets/d/1wvnoiju2UjHW3QezTI0kvmReMf8_adq5mSQEpWRdpk8/edit?usp=sharing",sheet = "Hoja1",col_names = T) 



apply(ej_admid,2,function(x)sum(is.na(x)))


# Hay 90 registros sin coordenadas
filt1_coor <- ej_admid %>% filter(is.na(Grados1)&is.na(Grados2)&is.na(Minutos1)&is.na(Minutos2)&is.na(Segundos1)&is.na(Segundos2)&is.na(LonGD)&is.na(LatGD))


# Asignar coordenadas decimales para todos
con_coor <- ej_admid %>% filter(!ID %in% filt1_coor$ID)

## Corregir longitudes > 0
con_coor[which(con_coor$LonGD>0),"LonGD"] <- con_coor[which(con_coor$LonGD>0),"LonGD"] *-1
con_coor[which(con_coor$Grados2>0),"Grados2"] <- con_coor[which(con_coor$Grados2>0),"Grados2"] *-1

## Convertir coordenadas Gdos, min, seg a grados decimales
con_coor[is.na(con_coor$LatGD),] <- con_coor[is.na(con_coor$LatGD),] %>% mutate(LatGD=Grados1+Minutos1/60+Segundos1/3600, LonGD=(abs(Grados2)+Minutos2/60+Segundos2/3600)*-1)

## crear CSV para revisar en google earth

#con_coor %>% select(ID,LatGD,LonGD) %>% dplyr::arrange(mixedorder(ID)) %>% .[mixedorder(.$ID),] %>% write.csv("../outputs/admid_revisar_coord_190422.csv", row.names = F)

con_coor %>% group_by(Especie)%>% summarise(numero_ejemplares = n()) %>% View

