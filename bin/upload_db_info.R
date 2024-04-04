library(googlesheets4)
library(tidyverse)
library(RMariaDB)

## Este script tiene como objetivo organizar la información en las tablas requeridas para la base de datos.

## Leer datos del google drive

data_admid <- read_sheet("https://docs.google.com/spreadsheets/d/1wvnoiju2UjHW3QezTI0kvmReMf8_adq5mSQEpWRdpk8/edit?usp=sharing", sheet = "Hoja1", col_types = "icicccccccciccccccccdddcddddcdiiccccc")

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

## tabla que liga el colector con el ejemplar (408 ejemplares), la de colectores la subi a mano

colectores_ind <- data_admid %>% separate(Colector, into = c("col1","col2", "col3"), sep = ",") %>% select(order,ID, ind, "ID campo", starts_with("col")) %>% pivot_longer(cols = starts_with("col"), values_to = "colector") %>% drop_na()

colectores <- group_by(colectores_ind,colector) %>% 
  summarise(tot = n()) %>%
  mutate(codigo = ifelse(colector == " Alberto Perez Pedreza", "APP",
                         ifelse(colector == " Antonio López","ALC",
                                ifelse(colector == " Melissa Naranjo Bravo","MNB",
                                       ifelse(colector == "Hernando Rodriguez Correa","HRC","RGL")))))
  

colectores_ind <- left_join(colectores_ind,colectores[,-2],by = "colector") %>%
  select(order,codigo) %>% 
  rename("id_ejemplar" = order, "id_colector" = codigo)

dbWriteTable(conn = conn,name = "07_individuos_colectores", overwrite = T,value = colectores_ind, header = T,row.names=F)

## tabla de individuos 

temp <- data_admid %>% 
  mutate(Lat=Grados1+Minutos1/60+Segundos1/3600, Lon = -(abs(Grados2)+Minutos2/60+Segundos2/3600)) %>%
  mutate(Lat = ifelse(is.na(Lat)&!is.na(LatGD),LatGD,Lat), Lon = ifelse(is.na(Lon)&!is.na(LonGD),LonGD,Lon)) %>%
  mutate(Especie = str_remove(Especie, "aff. ")) %>% 
  mutate(localidad = ifelse(!is.na(`Localidad 2`),paste(`Localidad 1`,`Localidad 2`, sep = "; "),`Localidad 1`)) %>%
  group_by(Género,Especie) %>% 
  mutate(id_especie = cur_group_id()) %>% 
  ungroup() 


taxonomia <- temp %>% group_by(id_especie) %>% summarise(familia = unique(Familia),
                                                         genero = unique(Género),
                                                         epiteto_especifico = unique(Especie),
                                                         autoridad_taxonomica = unique(`Autoridad taxonómica`),
                                                         fecha_descripcion = unique(`año descripcion`))

#dbWriteTable(conn,"12_taxonomia",overwrite = T,value = taxonomia, header = T,row.names=F)

edo_mun <- dbSendQuery(conn,"select m.id_municipio,m.municipio, e.id_estado, e.estado  from municipios m 
              left join estados_municipios em on m.id_municipio = em.id_municipio 
              left join estados e on em.id_estado = e.id_estado ") %>%
  dbFetch()


ind_edo_mun <- left_join(temp, edo_mun, by = c("Municipio"="municipio","Estado"="estado")) %>% select(order,Municipio,id_municipio, Estado, id_estado)


ind_veg <- temp[,c("order","Observación BioEco")] %>% 
  mutate(tipo_veg = str_extract(`Observación BioEco`,regex("Tipo de vegetación(.*?),")),
         tipo_veg = ifelse(is.na(tipo_veg),
                           str_extract(`Observación BioEco`,regex("Tipo de vegetación(.*?)$")),tipo_veg),
         tipo_veg = str_remove(tipo_veg, "Tipo de vegetación"),
         tipo_veg = str_remove(tipo_veg, ","),
         tipo_veg = str_remove(tipo_veg, "^ "),
         tipo_veg = str_remove(tipo_veg, " $")) %>%
  group_by(tipo_veg) %>%
  mutate(id_veg = cur_group_id()) %>% 
  select(order,tipo_veg,id_veg)

ind_veg$id_veg[which(ind_veg$id_veg==18)] <- NA

tipo_veg <- ind_veg %>% group_by(tipo_veg) %>% summarise(id_veg = unique(id_veg))

#dbWriteTable(conn,"11_tipos_vegetacion",overwrite = T,value = tipo_veg, header = T,row.names=F)

temp2 <- temp %>%
  select(order,ind,Lat,Lon,Elevación,"ID campo",localidad,`Observación BioEco`,id_especie,Comentarios) %>%
  left_join(ind_edo_mun[,c("order","id_estado","id_municipio")], by = "order") %>% 
  left_join(ind_veg[,c("order","id_veg")], by = "order") %>%
    rename(id_ejemplar = order, 
         id_individuo = ind, 
         latitud = Lat,
         longitud = Lon,
         altitud = Elevación,
         codigo_colecta = `ID campo`,
         desc_localidad = localidad,
         observaciones = `Observación BioEco`,
         comentarios = Comentarios)%>%
  mutate(id_pais = "MEX",
         prec_horizontal = NA,
         prec_vertical = NA,
         fecha = NA) %>%
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
# 5 = no precision vertical/horizontal
# 6 = no fecha

## Arreglar flag 3

library(sp)
library(elevatr)
library("tidygeocoder")

miss <- filter(temp2,flag3 == 3 & is.na(flag1))

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
  filter(!id_ejemplar %in% elev$id_ejemplar) %>% 
  bind_rows(elev) %>% 
  mutate(flag3 = NA) %>%
  select(-c(county,state))


### Añadir los registros de flag 3 corregidos 

temp3 <- temp2 %>% 
  filter(!id_ejemplar %in% missing$id_ejemplar) %>% 
  bind_rows(missing) %>% 
  select(-starts_with("flag"))

#desc_localidad <- read.csv("../data/localidades.csv") %>% 
#  select(id_individuo, desc_localidad)%>%
#  unique() ## No reproducible en R, lo que hice fue copiar y pegar la información de los registros en los que había diferencias (excel )

#obs_com <- read.csv("../data/obs_com.csv") %>% 
#  select(id_individuo, observaciones, comentarios)%>%
#  unique() # igual que el anterior


individuos <- temp3 %>% 
  left_join(desc_localidad,by = "id_individuo") %>%
  left_join(obs_com,by = "id_individuo") %>% 
  select(id_individuo, 
         latitud, 
         longitud, 
         prec_horizontal, 
         altitud, 
         prec_vertical,
         fecha, 
         desc_localidad = desc_localidad.y, 
         observaciones = observaciones.y,
         id_estado,
         id_pais, 
         id_municipio, 
         id_veg,
         id_especie,
         comentarios = comentarios.y)%>%
  unique()

#dbWriteTable(conn,"06_individuos",overwrite = T,value = individuos, header = T,row.names=F)

ejemplares <- temp3 %>%
  left_join(data_admid[c("order","ID, nombre o localización de la caja")], by = c("id_ejemplar"="order")) %>%
  mutate(fecha_ingreso_bd = "2022-06-13") %>%
  select(id_ejemplar, id_individuo,codigo_colecta,localizacion = "ID, nombre o localización de la caja", fecha_ingreso_bd) 

#dbWriteTable(conn,"02_ejemplares",overwrite = T,value = ejemplares, header = T,row.names=F)

flags <- temp2 %>% 
  filter(!id_ejemplar %in% missing$id_ejemplar) %>% 
  bind_rows(missing) %>% 
  select(id_ejemplar,starts_with("flag")) %>%
  pivot_longer(cols = starts_with("flag"), values_to = "flag") %>%
  select(-name) %>%
  drop_na()

dbWriteTable(conn,"13_flags",overwrite = T,value = flags, header = T,row.names=F)  



# Fotos
library(jpeg)
library(data.table)

files <- list.files("../db/Herbario/",full.names = F)

foto_info <- data.frame(file = files) %>% 
  mutate(id_foto = str_extract(file,"BN\\d{1,3}"),
                                    id_ejemplar = str_extract(id_foto,"\\d{1,3}"),
                                    posicion = str_extract(file,"(?<=_)\\d")) %>%
  select(id_ejemplar,posicion, id_foto)

dbWriteTable(conn,"04_fotos_ejemplares",value = foto_info,overwrite = T, header = T, rownames = F)


