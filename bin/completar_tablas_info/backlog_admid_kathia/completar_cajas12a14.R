## Este script es para completar la información de la BD de las cajas 12 a 14. 
## Falta añadir la fecha de colecta, la localización, prec. horizontal en cajas y la información de las fotos. 


library(googlesheets4)
library(RMariaDB)
library(tidyverse)

conn <- dbConnect(
  drv = RMariaDB::MariaDB(),
  username = "sofia",
  password = "sofia", # contraseña laptop sofia
  host = "localhost", 
  port = 3306,
  dbname = "ejemplares_BN"
)


datosDB <- dbSendQuery(conn, "SELECT e.id_ejemplar, 
                              	   e.id_individuo, 
                              	   e.localizacion, 
                              	   e.codigo_colecta, 
                              	   edo.estado, 
                              	   i.fecha, 
                              	   fe.id_foto, 
                              	   i.latitud, 
                              	   i.longitud   
                              FROM ejemplares e 
                              left join individuos i on e.id_individuo = i.id_individuo 
                              left JOIN estados edo on i.id_estado = edo.id_estado 
                              LEFT JOIN fotos_ejemplares fe on e.id_ejemplar = fe.id_ejemplar 
                              WHERE ISNULL(e.localizacion) 
                              ORDER BY i.id_individuo, e.id_ejemplar ") %>% dbFetch()

datosDB <- select(datosDB, -c(localizacion,id_foto,fecha))


datos <- read_sheet(ss = "https://docs.google.com/spreadsheets/d/1IloUmr7sYNDFX1yjt5BgXKrP3ty4bCYTsPQnTyMYEUg/edit?usp=sharing", sheet = 1) %>% 
  select(id_individuo, Localizacion, Fecha_colecta, id_foto_haz, id_foto) %>% 
  mutate(Fecha_colecta = as.Date(Fecha_colecta)) %>% 
  pivot_longer(cols = starts_with("id_foto"), names_to = "temp", values_to = "id_foto") %>% 
  mutate(posicion = ifelse(temp == "id_foto_haz",1,2),.before = id_foto, id_foto = str_remove(id_foto,"_\\d$")) %>% 
  select(-temp) 


## Encontré un error en los codigos de las fotos de estos ejemplares. Si se supone el codigo está conformado por 2 letras del pais, 2 letras del estado y el id_ejemplar. Sin embargo, a partir del individuo 694 se repetía el número de ejemplar 1281 y 1282. No hay problema con los codigos de las fotos porque los sitios son distintos. Pero hay que revisar si hay que corregir los nombes de los archivos. 

datos_sin_posicion <- datos %>% 
  distinct() %>% 
  mutate(id_ejemplar = str_remove(id_foto, "[A-Z]{1,}")) %>% 
  arrange(id_individuo,id_ejemplar) %>% 
  mutate(id_ejemplar = as.numeric(ifelse(id_individuo >= 694 ,as.numeric(id_ejemplar)+2,id_ejemplar)))

final_data <- left_join(datosDB,datos_sin_posicion, by = c("id_individuo" = "id_individuo","id_ejemplar" = "id_ejemplar"))

#write.csv(final_data,file = "datos_faltantes_cajas12a14.csv")

## Añadir datos id_fotos porque esos ejemplares no estaban en la tabla

#select(datos_sin_posicion, id_ejemplar,posicion,id_foto) %>% dbWriteTable(conn, value = ., name = "fotos_ejemplares", header = T, row.names= F, append = T)

# La localización la añadí manualmente pegando las celdas del csv.

