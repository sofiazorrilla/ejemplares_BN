library(tidyverse)
library(googlesheets4)

## Comando para generar etiquetas. Nota: Me equivoque y generé el id del ejemplar mal (debía haber empezado en 1633), por lo que manualmente cambié el id del primer ejemplar del individuo 823 a 1731

quarto render labels.qmd -P min:1 -P max:107 -P min_id_ejemplar:1906 -P path_to_coordinates:"https://docs.google.com/spreadsheets/d/1-d5ca4A9eL5cDq0Y2zFuN6OiYeAoe8m4LcQCQbpYV74/edit?usp=sharing" -P col_types:"ddcccccddddccDcccccc" -o labels_1_107_corregidas.html

## Generar tabla individuos_ejemplares

data <- read_sheet("https://docs.google.com/spreadsheets/d/1-d5ca4A9eL5cDq0Y2zFuN6OiYeAoe8m4LcQCQbpYV74/edit?usp=sharing", col_types = 'ddcccccddddccDcccccc')

ind_ej <- select(data,id_individuo,ejemplares) 

reps <- c()
for(i in 1:nrow(ind_ej)){
  
  r <- rep(as.numeric(rownames(ind_ej)[i]),ind_ej[[i,"ejemplares"]])
  reps <- c(reps,r) 
}

inds <- ind_ej[reps,] %>% select(-ejemplares)
write_sheet(ss = "https://docs.google.com/spreadsheets/d/1-d5ca4A9eL5cDq0Y2zFuN6OiYeAoe8m4LcQCQbpYV74/edit?usp=sharing",inds, sheet = "individuos_ejemplares2")
