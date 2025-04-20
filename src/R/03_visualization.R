source(file.path("src", "R", "helpers", "_theme.R"))
source(file.path("src", "R", "helpers", "_plot_template.R"))
source(file.path("src", "R", "helpers", "_panel_functions.R"))


## Define script-wide constants ================================================

WIDTH <- 178.5  # Standard width of plots in mm.
HEIGHT <- 40  # Standard height of plots in mm.
DPI <- 300  # Resolution of PNG plots.


## Generate plots ==============================================================

plot_aka_constructs <- template(
  subset = Protein %in% c("nls-GFP", "Anakonda") &
    Experiment != "Aka[C] + Aka[N] SN",
  groups = interaction(Protein, Experiment),
  panel.func = panel.clusters,
  layout = c(6, 1),
  strip = strip.custom(
    factor.levels = c(
      "nls-GFP",
      "Aka[Full]",
      "Aka[N]",
      "Aka[C]",
      "Aka[C] + Aka[N] CT",
      "Aka[C] + Aka[R1] CT"
    )
  )
) |> print()

plot_aka_constructs_lorenz <- template(
  subset = Protein %in% c("nls-GFP", "Anakonda") &
    Experiment != "Aka[C] + Aka[N] SN",
  groups = interaction(Protein, Experiment),
  panel.func = panel.lorenz,
  ylim = c(-.05, 1.05),
  layout = c(6, 1),
  strip = strip.custom(
    factor.levels = c(
      "nls-GFP",
      "Aka[Full]",
      "Aka[N]",
      "Aka[C]",
      "Aka[C] + Aka[N] CT",
      "Aka[C] + Aka[R1] CT"
    )
  )
) |> print()

plot_tcj_proteins <- template(
  subset = Experiment %in% c("Control", "Aka[Full]"),
  panel.func = panel.clusters,
  groups = Protein
) |> print()

plot_tcj_proteins_lorenz <- template(
  subset = Experiment %in% c("Control", "Aka[Full]"),
  panel.func = panel.lorenz,
  ylim = c(-.05, 1.05),
  groups = Protein
) |> print()


## Export plots ================================================================

# Loop through all objects in the global environment and consider all those with
# names starting with 'plot_[...]'.
for (obj in ls(pattern = "plot_")) {
  current_plot <- get(obj)
  
  for (fmt in c("pdf", "png")) {
    device <- get(fmt)
    filename <- file.path(OUTPUT, "plots", paste0(obj, ".", fmt))
    
    if (fmt == "pdf")
      device(file = filename, WIDTH / 25, HEIGHT / 25)
    else
      device(file = filename, WIDTH, HEIGHT, units = "mm", res = DPI)
    
    trellis.par.set(theme)
    print(current_plot)
    
    dev.off()
    
  }
}
