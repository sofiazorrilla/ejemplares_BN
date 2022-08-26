library("googlesheets4")
library("tidygeocoder")
library(tidyverse)
library(sp)
library(elevatr)
library(readxl)

## Leer la base de datos de google drive y darle formato 

## col_types indican el tipo de datos en esa columna, así se evita que se lean como lista (i = integer, c = character, d = double, D = date)

data <- read_sheet("https://docs.google.com/spreadsheets/d/1V_I9P1PLCvbQlBw3BCMpELiWZFF1ofelMJgs7lAnZ0I/edit?usp=sharing", sheet = "fin", col_types = 'iiccciccccccddiccDc') 

data <- read_excel("../data/Etiquetas_oaxaca_febrero2022.xlsx", sheet = "ESPECÍMENES")

## Seleccionar los campos que se utilizaran en las etiquetas

info_et <- data %>% as.data.frame()
info_et$caja <- 7

## codigo antiguo no correr
#info_et <- data %>% filter(ETIQUETA == "NO") %>% select(row,Codigo,DUPLICADOS,Longitude_gps,Latitude_gps,ALTITUD,Pais,Estado,Municipio,Localidad,Fecha_colecta,Colectores) %>% drop_na() %>% as.data.frame()

## Loop para crear un vector con los indices de las filas de acuerdo al numero de duplicados que hay. El objetivo es poder multiplicar el numero de filas para que sea igual al numero de etiquetas que se necesitan.

reps <- c()
for(i in 1:nrow(info_et)){

  r <- rep(as.numeric(rownames(info_et[i,])),info_et[[i,"Imprimir_etiquetas"]])
  print(r)
  reps <- c(reps,r) 
}

# Duplicar filas
etiquetas <- info_et[reps,]

## Grabar un csv para usar en word. Hay que quitar el signo # y correrlo.

write.table(etiquetas, "../outputs/info_etiquetas260422.csv",sep = ";",row.names = F)

 
