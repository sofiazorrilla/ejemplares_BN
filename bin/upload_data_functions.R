## Script para subir nuevas tablas de datos a la base de datos.

library(googlesheets4)
library(RMariaDB)
library(tidyverse)


## Paso 1. Definir variables 

# Link de google drive a los datos. 
# La tabla debe tener el formato del documento de muestra. 

ss = "https://docs.google.com/spreadsheets/d/1F-Q5FqYZhQ2fKJRnADKZfV4_0yPdrYFa84vUdVzefwc/edit?usp=sharing" 


conn <- dbConnect(
  drv = RMariaDB::MariaDB(),
  username = "sofia",
  password = "MDB!2019#", # contraseña mounstrito
  host = "localhost", 
  port = 3306,
  dbname = "ejemplares_BN"
)


## Paso 2. Generar tablas de BD (ver diseño en Manual de toma de datos)

get_id_ejemplar = function(min_id, info_etiquetas){

    ## Loop para crear un vector con los indices de las filas de acuerdo al numero de duplicados que hay. El objetivo es poder multiplicar el numero de filas para que sea igual al numero de etiquetas que se necesitan.

    reps <- c()
    for(i in 1:nrow(info_etiquetas)){

    r <- rep(as.numeric(rownames(info_etiquetas)[i]),info_etiquetas[[i,"ejemplares"]])
    reps <- c(reps,r)

    return(data)
    }
}

data = read_sheet(ss, sheet = 1, col_types = 'dddccccccccccddddcccDc')

# Revisar etiquetas para saber el mínimo y el máximo 
data_id_ejemplar = get_id_ejemplar(info_etiquetas = data, min_id = 1361)

data_fotos = read_sheet(ss, sheet = 2, col_types = 'ddccd')

# importar catalogos 

colectores =  dbSendQuery(conn, "SELECT * FROM colectores") %>% dbFetch()
paises = dbSendQuery(conn, "SELECT * FROM paises") %>% dbFetch()
estados_municipios = dbSendQuery(conn, "SELECT em.id_estado, em.id_municipio, e.estado, m.municipio FROM estados_municipios em 
left join estados e on em.id_estado = e.id_estado 
left join municipios m on em.id_municipio = m.id_municipio ") %>% dbFetch()
tipo_veg = dbSendQuery(conn, "SELECT * FROM tipos_vegetacion") %>% dbFetch()

# obtener ids

data_ids = data %>% filter(!is.na(id_individuo)) %>% 
           left_join(paises, by = c("Pais" = "pais")) %>% 
           left_join(estados_municipios, by = c("Municipio" = "municipio", "Estado" = "estado")) %>% 
           left_join(tipo_veg, by = c("Tipo_vegetacion" = "tipo_veg")) 


# Tablas

ejemplares_colectores = data_id_ejemplar %>% select(id_ejemplar, id_individuo, Colectores) %>% 
        separate(Colectores, into = c(paste0("col", seq(1:4)))) %>% 
        pivot_longer(cols = starts_with("col"), names_to = "n_colector", values_to = "id_colector") %>%
        select(id_ejemplar, id_colector)

loc = data_fotos %>% group_by(id_individuo) %>% summarise(localizacion = unique(caja))

ejemplares = data_id_ejemplar %>% select(id_ejemplar, id_individuo, codigo_colecta) %>%
             left_join(loc, by = "id_individuo") %>%
             mutate(fecha_ingreso_bd = as.Date("2023-09-26"))  

individuos = data_ids %>% select(id_individuo,
                                 latitud = Latitud,
                                 longitud = Longitud,
                                 prec_horizontal = Prec_horizontal,
                                 altitud = Altitud,
                                 fecha = Fecha_colecta,
                                 desc_localidad = Localidad,
                                 observaciones = Comentarios,
                                 id_estado,
                                 id_pais,
                                 id_municipio,
                                 id_veg) %>%
             mutate(comentarios = NULL) %>%
             filter(!is.na(id_individuo))

fotos_ejemplares = data_fotos %>% 
                   select(id_ejemplar, id_individuo, starts_with("Codigo") ) %>%
                   pivot_longer(cols = starts_with("Codigo"), names_to = "posicion", values_to = "id_foto") %>%
                   mutate(posicion = str_extract(id_foto, "\\d{1}$"), id_foto = str_remove(id_foto, "_\\d{1}")) %>%
                   select(id_ejemplar, posicion, id_foto)

## añadir datos 

# dbWriteTable(conn, value = individuos, name = "individuos", header = T, row.names= F, append = T)

# dbWriteTable(conn, value = ejemplares, name = "ejemplares", header = T, row.names= F, append = T)

# dbWriteTable(conn, value = ejemplares_colectores, name = "ejemplares_colectores", header = T, row.names= F, append = T)

# dbWriteTable(conn, value = fotos_ejemplares, name = "fotos_ejemplares", header = T, row.names= F, append = T)