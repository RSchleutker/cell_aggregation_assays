pal <- c("#0b84a5",
         "#ca472f",
         "#9dd866",
         "#6f4e7c",
         "#f6c85f",
         "#ffa056",
         "#8dddd0")

theme <- list(
  fontsize = list(text = 9, points = 5),
  add.text = list(cex = .8),
  axis.components = list(
    left = list(tck = .8),
    top = list(tck  = 0),
    right = list(tck = 0),
    bottom = list(tck = .8)
  ),
  box.rectangle = list(col = "black", fill = "white"),
  box.umbrella = list(col = "black", lty = "solid"),
  box.dot = list(pch = "|"),
  barchart.plot.polygon = list(fill = "white"),
  dot.symbol = list(pch = 16),
  plot.symbol = list(pch = 16, col = "black"),
  superpose.symbol = list(col = pal),
  superpose.line = list(col = pal),
  superpose.polygon = list(col = paste0(pal, "40")),
  reference.line = list(col = "grey", lty = "dotted"),
  layout.widths = list(
    left.padding = 0,
    right.padding = 0,
    key.ylab.padding = 0,
    axis.right = 0,
    axis.left = .9
  ),
  layout.heights = list(
    strip = 1.2,
    top.padding = 0,
    axis.top = 0,
    main.key.padding = 0,
    bottom.padding = 0
  ),
  strip.background = list(col = "#ffffff")
)
