library("googlesheets4")
library("tidygeocoder")
library(tidyverse)
library(sp)
library(elevatr)

data <- read_sheet("https://docs.google.com/spreadsheets/d/1V_I9P1PLCvbQlBw3BCMpELiWZFF1ofelMJgs7lAnZ0I/edit?usp=sharing", sheet = "sin_etiqueta", col_names  = T, col_types = "iccciccccccddiccDc") %>% rownames_to_column(var = "row")


miss  <- dplyr::filter(data, is.na(Pais) & !is.na(Latitud)) 

miss <- dplyr::filter(data,ETIQUETA == "NO" & !is.na(Longitude_gps) & is.na(Pais))

loc <- reverse_geo(
  lat = miss$Latitud,
  long = miss$Longitud,
  method = "osm",
  full_results = TRUE
)


datos_faltantes <- left_join(miss,loc[c("lat","long","county","state","country")], by = c("Longitud"="long", "Latitud" = "lat")) %>% mutate(Pais = country, Estado = state, Municipio = county) %>% select(names(data)) 
names(data)

fin_par <- left_join(data,datos_faltantes[,c("codigo_colecta","Pais","Estado","Municipio")],by = "codigo_colecta") %>% mutate(Pais = coalesce(Pais.x,Pais.y), Estado = coalesce(Estado.x,Estado.y), Municipio = coalesce(Municipio.x,Municipio.y)) %>% select(! ends_with(".x")& !ends_with(".y")) %>% select(names(data)) %>% distinct()

elev_missing <- fin_par %>% filter(!is.na(Latitud) & is.na(Altitud))

coordinates(elev_missing) <- ~Longitud+Latitud
prj <- "EPSG:4326"

df_elev_aws <- get_elev_point(SpatialPoints(elev_missing),prj = prj, src = "aws")

elev <- fin_par %>% filter(!is.na(Latitud) & is.na(Altitud)) %>% mutate(data.frame(Altitud =df_elev_aws$elevation))



fin <- left_join(fin_par,elev[c("row","Altitud")],by = "row") %>% mutate(Altitud = coalesce(Altitud.x,Altitud.y))%>% select(names(data))

write_sheet(fin, ss = "https://docs.google.com/spreadsheets/d/1V_I9P1PLCvbQlBw3BCMpELiWZFF1ofelMJgs7lAnZ0I/edit?usp=sharing")

