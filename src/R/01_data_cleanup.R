## Define script-wide constants ================================================

INPUT <- file.path("data", "processed")
OUTPUT <- file.path("output")

PROTEINS <- c(
  "Gfp" = "nls-GFP",
  "Aka" = "Anakonda",
  "Gli" = "Gliotactin",
  "M6" = "M6"
)
EXPERIMENTS <- c(
  "Control" = "Control",
  "Full" = "Control",
  "Extracellular" = "Aka[N]",
  "Transmembrane" = "Aka[C]",
  "Cotransfected" = "Aka[C] + Aka[N] CT",
  "Supernatant" = "Aka[C] + Aka[N] SN",
  "Cotransfected1" = "Aka[C] + Aka[R1] CT"
)


## Read and process measured aggregations ======================================

# Main dataframe.
data_aggregations <-
  list.files(INPUT,
             pattern = "aggregations.csv",
             full = T,
             rec = T) %>%
  lapply(read.csv) %>%
  Reduce(f = rbind) %>%
  rename(
    Protein = Prot,
    Experiment = Exp,
    Cluster = cluster,
    Cells = cells
  ) %>%
  mutate(
    Protein = factor(Protein, names(PROTEINS), PROTEINS),
    Experiment = factor(Experiment, names(EXPERIMENTS), EXPERIMENTS),
    Date = as.Date(as.character(Date), format = "%Y%m%d"),
    Cells = ifelse(Cells == 0, 1, Cells)
  )


## Export cleaned data to CSV and EXCEL ========================================

write.csv(data_aggregations, file = file.path(OUTPUT, "tables", "aggregations.csv"))
write.xlsx(list(Aggregations = data_aggregations),
           file = file.path(OUTPUT, "tables", "aggregations.xlsx"))
