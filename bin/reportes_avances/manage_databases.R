library(tidyverse)

inventario <- read.csv("compilado_inventario.csv",header = T)

gps <- read.csv("coordenadas_gps.csv",header = T) %>% mutate(copia_codigo = Name)

join <- left_join(inventario,gps, by = c("Codigo" = "Name"))

write_csv(join,"joined_raw.csv")

names(join) %>% as.data.frame()
