###########################################################
## Ejemplo de conversión de tabla de BD_ejemplares a DwC
###########################################################

library(tidyverse)
library(googlesheets4)


ss = "https://docs.google.com/spreadsheets/d/121j3-WTRLWDTDmYH-bZ9eTLDdUvtPrmcqY4eLixgz50/edit?usp=sharing"

ind <- read_sheet(ss, sheet = 1, skip = 1, col_types = 'c')

tax <- read.csv("../../data/catalogoTaxonomico/dwca-SNIB-CS008-v1.16/occurrence.csv",sep = "\t")

tax %>% select(specificEpithet, acceptedNameUsage)