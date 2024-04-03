library(googlesheets4)
library(tidyverse)
library(skimr)
library(gtools)


## Objetivo: renombrar las fotos de Admid de acuerdo al ID que tienen en la tabla de metadatos. Voy a mantener el codigo para saber que hice pero no se debe correr de nuevo a menos de que se encuentre algun error. 

# Leer metadatos Ejemplares_admid

data <- read_sheet("https://docs.google.com/spreadsheets/d/1wvnoiju2UjHW3QezTI0kvmReMf8_adq5mSQEpWRdpk8/edit?usp=sharing", sheet = "Hoja1", col_types = "ccccccccciccccccccdddcddddcdiiccccc")


# Seleccionar columnas de id. Con el codigo comentado me asegure de que la informacion del id de campo coincidiera con las anotaciones de la columna de fotos

id_data <- select(data,ID, `ID campo`, foto)  #%>% separate(foto,c("foto1","foto2"),sep = " y ") %>%  mutate(foto1 = str_remove(.$foto1, "_[0-9]"),foto2 = str_remove(.$foto2, "_[0-9]")) %>% pivot_longer(cols = starts_with("foto"), names_to = "num_foto", values_to = "foto") %>% select(-num_foto) %>% unique()

# Leer los nombres de los archivos, obtener el codigo (eliminar _1 o _2) y mantener la ubicación
fotos <- as_tibble(list.files("../db/Herbario/Herbario")) %>% rename(ID_file=value) %>% mutate(ID_foto = str_remove(.$ID_file, "_[0-9].JPG"), full_path = list.files("../db/Herbario/Herbario", full.names = T))

#Unir las fotos con el id de la tabla (ya sea con el ID de campo o con el ID)
fotos_id <- left_join(id_data,fotos,by = c("ID campo"="ID_foto")) %>% left_join(fotos,by = c("ID"= "ID_foto")) %>% mutate(id_file = coalesce(ID_file.x, ID_file.y), full_path = coalesce(full_path.x, full_path.y)) %>% select(-c(ID_file.x, ID_file.y, full_path.x, full_path.y))%>% .[mixedorder(.$ID),]

# Renombrar todos los archivos para que coincidan con el ID de los registros de la tabla. 
a <- filter(fotos_id, !is.na(id_file)) 
#file.rename(from = a$full_path, to = paste0("../db/Herbario/Herbario/",a$ID,str_extract(a$id_file, "_[0-9].JPG"),".JPG"))



 
