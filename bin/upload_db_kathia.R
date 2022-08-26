## Subir información de Kathia a la base de datos 

library(googlesheets4)
library(tidyverse)
library(RMariaDB)

ss_ejemplares = "https://docs.google.com/spreadsheets/d/1NuKfYd4ByR0DxSks5Y81o4EFFkyxq2mQSjFiXapZjug/edit?usp=sharing"

# Leer y añadir columna de individuos y codigos de ejemplar y de individuo
data <- read_sheet(ss_ejemplares, sheet = "Hoja 1", col_types = "iiccccccccccddiccDc") %>% 
  mutate(ind = str_remove(codigo_colecta,"[a-f]$"), .before = codigo_colecta) %>% 
  group_by(ind) %>% 
  mutate(id_individuo = cur_group_id()+300,.before = ind) %>%
  group_by(codigo_colecta) %>%
  mutate(id_ejemplar = cur_group_id()+408, .before = codigo_colecta)%>%
  ungroup() 

##

conn <- dbConnect(
  drv = RMariaDB::MariaDB(), 
  username = "root",
  password = "sofia", 
  host = "localhost", 
  port = 3306,
  dbname = "ejemplares"
)

## Formar tablas de información

## IDs 
#id_individuo(varchar 10)
#id_ejemplar (varchar 10)
#id_foto (varchar 50)
#id_colector(char 3)
#id_muestra (varchar 10)
#id_estado (char 5)
#id_pais (varchar 5)
#id_veg (varchar 50)
#id_municipio (varchar 5)
#id_especie (varchar 5)
#id_flag (int 100)




## Colectores

colectores_ind <- data %>% 
  separate(Colectores, into = c("col1","col2", "col3","col4","col5"), sep = ",") %>% 
  select(caja, id_individuo, id_ejemplar, starts_with("col")) %>% 
  pivot_longer(cols = starts_with("col"), values_to = "colector") %>% 
  drop_na() 

codigos_colectores <- read_sheet(ss = ss_ejemplares,sheet = "colectores")

ind_colector <- colectores_ind %>% mutate(
  colector = str_remove(colector, "^ "),
  colector_in = sapply(str_extract_all(colector, '[A-Z]+'),paste0, collapse = '')
)%>%
  left_join(codigos_colectores, by = "colector_in") %>% 
  select(id_ejemplar,id_colector)%>%
  unique()

#  codigo usado para generar hoja de codigos de colectores
#  group_by(colector_in)%>%
#  summarise(unique(colector))%>%
#  write_sheet(ss = ss_ejemplares,sheet = "colectores")

dbWriteTable(conn = conn,name = "07_individuos_colectores", append = T,value = ind_colector, header = T,row.names=F)

ind_colector %>% group_by(id_colector) %>% summarise(unique(colector))


## Tabla de individuos 

ind_raw <- data %>% select(id_individuo, ind,
                latitud = Latitud, 
                longitud = Longitud, 
                altitud = Altitud,
                fecha = Fecha_colecta,
                desc_localidad = Localidad,
                Estado,
                Pais,
                Municipio,
                Tipo_vegetacion)%>%
  mutate(prec_horizontal = NA,prec_vertical = NA,observaciones = NA,id_especie = NA, comentarios = NA) %>% unique() 

edo <- dbSendQuery(conn,"select * from 03_estados") %>% dbFetch()
municipio <- dbSendQuery(conn,"select * from 09_municipios") %>% dbFetch()

edo_mun <- dbSendQuery(conn,"select m.id_municipio,
                                    m.municipio, 
                                    e.id_estado, 
                                    e.estado  
                              from 09_municipios m 
              left join 14_estados_municipios em on m.id_municipio = em.id_municipio 
              left join 03_estados e on em.id_estado = e.id_estado ") %>%
  dbFetch()


tipos_veg <- dbSendQuery(conn, "select * from 11_tipos_vegetacion") %>% dbFetch()


individuos <- ind_raw %>% 
  left_join(edo_mun, by = c("Estado"="estado","Municipio"="municipio")) %>% 
  left_join(tipos_veg, by = c("Tipo_vegetacion"="tipo_veg")) %>%
  select(-c(Estado,Municipio,Tipo_vegetacion)) %>%
  mutate(id_pais = ifelse(Pais == "México","MX","GT"),.before = Pais) %>% 
  mutate(flag1 = ifelse(is.na(latitud)|is.na(longitud),1,NA),
         flag2 = ifelse(is.na(id_especie),2,NA),
         flag3 = ifelse(is.na(id_estado)|is.na(id_municipio)|is.na(altitud),3,NA),
         flag4 = ifelse(is.na(id_veg),4,NA),
         flag5 = ifelse(is.na(prec_horizontal)|is.na(prec_vertical),5,NA),
         flag6 = ifelse(is.na(fecha),6,NA))

# Flags
# 0 = pass
# 1 = no coordinates
# 2 = no identification
# 3 = no estado, municipio, altitud o localidad
# 4 = no tipo de vegetación
# 5 = no precisión vertical/horizontal
# 6 = no fecha  
  
library(sp)
library(elevatr)
library("tidygeocoder")

miss <- filter(individuos,flag3 == 3 & is.na(flag1))

loc <- reverse_geo(
  lat = miss$latitud,
  long = miss$longitud,
  method = "osm",
  full_results = TRUE
)

loc_id <- left_join(loc[,c("county","state")],edo_mun, by = c("county"="municipio","state"="estado")) %>% rename(osm_edo = id_estado, osm_municipio = id_municipio)

mis_edo_mun <- miss %>% 
  bind_cols(loc_id) %>% 
  mutate(id_estado = ifelse(is.na(id_estado),osm_edo,id_estado),
         id_municipio = ifelse(is.na(id_municipio), osm_municipio,id_municipio)) %>% 
  select(-starts_with("osm"))

elev_missing <- mis_edo_mun %>% filter(!is.na(latitud) & is.na(altitud))

coordinates(elev_missing) <- ~longitud+latitud
prj <- "EPSG:4326"

df_elev_aws <- get_elev_point(SpatialPoints(elev_missing),prj = prj, src = "aws")

elev <- mis_edo_mun %>% filter(!is.na(latitud) & is.na(altitud)) %>% mutate(data.frame(altitud =df_elev_aws$elevation))

missing <- 
  mis_edo_mun %>% 
  filter(!id_individuo %in% elev$id_individuo) %>% 
  bind_rows(elev) %>% 
  mutate(flag3 = NA) %>%
  select(-c(county,state))


### Añadir los registros de flag 3 corregidos 

individuos <- individuos %>% 
  filter(!id_individuo %in% missing$id_individuo) %>% 
  bind_rows(missing) 
  
flags <- select(individuos, id_individuo, starts_with("flag")) %>% 
  left_join(data[,c("id_individuo","id_ejemplar")], by = "id_individuo") %>% 
  select(-id_individuo) %>% pivot_longer(cols = starts_with("flag"), values_to = "flag")%>%
  select(-name) %>% drop_na()

individuos_fin <- individuos %>%
  select(id_individuo,
         latitud,
         longitud,
         prec_horizontal,
         altitud,
         prec_vertical,
         fecha,
         desc_localidad,
         observaciones,
         id_estado,
         id_pais,
         id_municipio,
         id_veg,
         id_especie,
         comentarios)

#dbWriteTable(conn,value = individuos_fin, name = "06_individuos", header = T, row.names = F, append = T)

ejemplares <- data %>% select(id_ejemplar, id_individuo, codigo_colecta, localizacion = caja) %>% mutate( fecha_ingreso_bd = "2022-06-15") 

#dbWriteTable(conn, value = ejemplares, name = "02_ejemplares", header = T, row.names= F, append = T)

#dbWriteTable(conn, value = flags, name = "13_flags", append = T, header = T, row.names = F)


foto_ejemplar <- data %>% 
  select(id_ejemplar, Codigo_Foto_HAZ,Codigo_Foto_REVES) %>% 
  pivot_longer(cols = starts_with("Codigo"), values_to = "id_foto") %>% 
  mutate(posicion = str_extract(id_foto,"_[1-2]{1}"),.before = id_foto,
         posicion = str_remove(posicion,"_"),
         id_foto = str_remove(id_foto,"_[1-2]{1}"))%>%
  select(-name) %>% drop_na()

dbWriteTable(conn, value = foto_ejemplar, name = "04_fotos_ejemplares", append = T, header = T, row.names = F)
