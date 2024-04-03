library("googlesheets4")
library("tidygeocoder")
library(tidyverse)
library(sp)
library(elevatr)


## Leer la base de datos de google drive y darle formato 

## col_types indican el tipo de datos en esa columna, así se evita que se lean como lista (i = integer, c = character, d = double, D = date)

data_comp <- read_sheet("https://docs.google.com/spreadsheets/d/1V_I9P1PLCvbQlBw3BCMpELiWZFF1ofelMJgs7lAnZ0I/edit?usp=sharing", sheet = "Hoja 1", col_types = 'iccccccccddiccDc') 



data_eti <-read_sheet("https://docs.google.com/spreadsheets/d/1V_I9P1PLCvbQlBw3BCMpELiWZFF1ofelMJgs7lAnZ0I/edit?usp=sharing", sheet = "sin_etiqueta", col_types = 'iccciccccccddiccDc')  %>% select(names(data_comp)) %>% mutate(Fecha_colecta = as.Date(Fecha_colecta))

data <- data_comp %>% bind_rows(data_eti)

data$codigo_temp <- str_remove(data$codigo_colecta,regex("[a-c]$"))

#Tenemos 235 individuos colectados 

data %>% group_by(codigo_temp) %>% tally() %>% ggplot(aes(x = n))+geom_bar(fill = "gray67")+theme_minimal()+labs(y = "Número de individuos", x = "Número de duplicados por individuo") + annotate(geom = "text", x = 4, y = 100, label = "Total de 235 individuos colectados y\n 378 ejemplares")


data %>% group_by(codigo_temp,Localidad) %>% summarise()%>% ggplot(aes(x = reorder(Localidad,Localidad,length)))+geom_bar(fill = "gray67")+theme_minimal() +theme(axis.text.x = element_text(angle = 90))+ labs(x = "", y = "Número de individuos")

data %>% ggplot(aes(x = Altitud, group = codigo_temp))+geom_histogram(fill = "gray67")+theme_minimal()+labs(y = "Número de individuos")


