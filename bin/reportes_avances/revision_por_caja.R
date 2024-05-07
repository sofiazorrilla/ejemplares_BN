## Revision de ejemplares por caja 

library(RMariaDB)
library(googlesheets4)
library(tidyverse)
library(gtools)

conn <- dbConnect(
  drv = RMariaDB::MariaDB(), 
  username = "sofia",
  password = "sofia", 
  host = "localhost", 
  port = 3306,
  dbname = "ejemplares_BN"
)


sql_search <- "SELECT e.id_ejemplar, 
	   e.id_individuo, 
	   e.localizacion, 
	   e.codigo_colecta, 
	   edo.estado, 
	   i.fecha, 
	   fe.id_foto 
FROM ejemplares e 
left join individuos i on e.id_individuo = i.id_individuo 
left JOIN estados edo on i.id_estado = edo.id_estado 
LEFT JOIN fotos_ejemplares fe on e.id_ejemplar = fe.id_ejemplar 
WHERE e.localizacion REGEXP '^[0-9]+$' OR ISNULL(e.localizacion) 
ORDER BY CAST(e.localizacion AS UNSIGNED);
"


ejemplares <- dbSendQuery(conn, sql_search) %>% dbFetch()

lista_ejemplares <- ejemplares %>% group_by(localizacion) %>% 
  mutate(revision = "", localizacion = as.numeric(localizacion))%>% 
  distinct() %>% 
  arrange(localizacion) %>% 
  group_split() 


ss1 <- "https://docs.google.com/spreadsheets/d/1y_48Pjkdxh7Omxs0nK0Fu-vEkkVi5KWDzA1h7ugzpzw/edit?usp=sharing"


for(i in seq_along(lista_ejemplares)){
  write_sheet(lista_ejemplares[[i]],ss = ss1,sheet = paste0("caja_",unique(lista_ejemplares[[i]]$localizacion)))
  
}

## Caja 18 (chimalapas 2023)

ss = "https://docs.google.com/spreadsheets/d/121j3-WTRLWDTDmYH-bZ9eTLDdUvtPrmcqY4eLixgz50/edit?usp=sharing"

individuos <- read_sheet(ss,sheet = 1) %>% 
  select(id_individuo, localizacion = caja, codigo_colecta, estado = Estado, fecha = Fecha_colecta ) %>% 
  mutate(fecha = as.Date(fecha))

ind_ej <- read_sheet(ss,sheet = 2) %>% 
  select(id_ejemplar, id_individuo, id_foto = Codigo_Foto_HAZ) %>% 
  mutate(id_foto = str_remove(id_foto, "_\\d"))

left_join(ind_ej, individuos, by = "id_individuo") %>% select(id_ejemplar,	id_individuo,	localizacion,	codigo_colecta,	estado,	fecha,	id_foto) %>% mutate(revision = "") %>% write_sheet(.,ss = ss1,sheet = paste0("caja_",unique(.$localizacion)))

## Caja 19 Rancho la Onza

ss = "https://docs.google.com/spreadsheets/d/1-d5ca4A9eL5cDq0Y2zFuN6OiYeAoe8m4LcQCQbpYV74/edit?usp=sharing"

individuos <- read_sheet(ss,sheet = 1) %>% 
  select(id_individuo, codigo_colecta, estado = Estado, fecha = Fecha_colecta ) %>% 
  mutate(fecha = as.Date(fecha), localizacion = "")

ind_ej <- read_sheet(ss,sheet = 2) %>% 
  select(id_ejemplar, id_individuo, id_foto = Codigo_Foto_HAZ) %>% 
  mutate(id_foto = str_remove(id_foto, "_\\d"))

left_join(ind_ej, individuos, by = "id_individuo") %>% select(id_ejemplar,	id_individuo,	localizacion,	codigo_colecta,	estado,	fecha,	id_foto) %>% mutate(revision = "") %>% write_sheet(.,ss = ss1,sheet = paste0("caja_",unique(.$localizacion)))


## Caja 21 (El Zamorano)

ss = "https://docs.google.com/spreadsheets/d/1dymbG-dIjeXGbZNJ_-4p44JDXZDvfKNcnfdRCtS4Tu0/edit?usp=sharing"

individuos <- read_sheet(ss,sheet = 1) %>% 
  select(id_individuo, codigo_colecta, estado = Estado, fecha = Fecha_colecta ) %>% 
  mutate(fecha = as.Date(fecha), localizacion = "")

ind_ej <- read_sheet(ss,sheet = 2) %>% 
  select(id_ejemplar, id_individuo) %>% 
  mutate(id_foto = "")

left_join(ind_ej, individuos, by = "id_individuo") %>% select(id_ejemplar,	id_individuo,	localizacion,	codigo_colecta,	estado,	fecha,	id_foto) %>% mutate(revision = "") %>% write_sheet(.,ss = ss1,sheet = paste0("caja_",unique(.$localizacion)))


