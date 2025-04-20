template <- function (subset = TRUE, groups = Experiment, panel.func = NULL, ...) {
  ps <- substitute(subset)
  pg <- substitute(groups)

  xyplot(
    Cells ~ Cluster | eval(pg),
    data = data_aggregations,
    subset = eval(ps),
    groups = eval(pg),
    panel = \(x, y, ...) {
      panel.grid(-1, -1)
      panel.superpose(x, y, panel.groups = panel.func, ...)

      ymax <- current.panel.limits()[["ylim"]][2]
      ltext(0, .85 * ymax, paste(sum(y), "Cells"), pos = 4)
      ltext(0, .65 * ymax, paste(length(x), "Cluster"), pos = 4)
    },
    xlim = c(-.1, 1.1),
    xlab = "Clusters ordered by number of cells",
    scales = list(
      x = list(
        alternating = 1,
        at = c(0, .2, .4, .6, .8, 1),
        labels = c("0", "0.2", "0.4", "0.6", "0.8", "1")
      ),
      y = list(alternating = 1)
    ),
    as.table = TRUE,
    ...
  )
}
