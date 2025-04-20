library(dplyr)
library(openxlsx)
library(lattice)


source_folder <- file.path("src", "R")

# Read and process data --------------------------------------------------------
source(file.path(source_folder, "01_data_cleanup.R"))

# Run statistical analysis -----------------------------------------------------
source(file.path(source_folder, "02_statistics.R"))

# Create and export plots ------------------------------------------------------
source(file.path(source_folder, "03_visualiaztion.R"))
