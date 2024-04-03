library(tidyverse)
library(googlesheets4)

## Comando para generar las etiquetas

#quarto render labels.qmd -P min:1 -P max:71 -P min_id_ejemplar:2011 -P path_to_coordinates:"https://docs.google.com/spreadsheets/d/1dymbG-dIjeXGbZNJ_-4p44JDXZDvfKNcnfdRCtS4Tu0/edit?usp=sharing" -P col_types:"ddcccccddddccDcccccc" -o labels_1_71.html

## Generar tabla individuos_ejemplares

data <- read_sheet("https://docs.google.com/spreadsheets/d/1dymbG-dIjeXGbZNJ_-4p44JDXZDvfKNcnfdRCtS4Tu0/edit?usp=sharing", col_types = 'ddcccccccddddcccccDcc')

ind_ej <- select(data,id_individuo,ejemplares) 

reps <- c()
for(i in 1:nrow(ind_ej)){
  
  r <- rep(as.numeric(rownames(ind_ej)[i]),ind_ej[[i,"ejemplares"]])
  reps <- c(reps,r) 
}

inds <- ind_ej[reps,] %>% select(-ejemplares)
write_sheet(ss = "https://docs.google.com/spreadsheets/d/1dymbG-dIjeXGbZNJ_-4p44JDXZDvfKNcnfdRCtS4Tu0/edit?usp=sharing",inds, sheet = "individuos_ejemplares")
