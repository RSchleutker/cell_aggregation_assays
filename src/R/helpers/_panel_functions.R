require(DescTools)


panel.clusters <- function (x, y, ...) {
  x <- seq_along(x) - 1
  x <- x / max(x)

  y <- sort(y)

  panel.polygon(c(0, x, 1), c(0, y, 0), ...)
}

panel.lorenz <- function (x, y, ...) {
  x <- seq_along(x) - 1
  x <- x / max(x)

  y <- sort(y)
  y <- cumsum(y) / sum(y)

  gini <- Gini(y) |> round(3)
  ltext(0, .9, paste0("G = ", gini), adj = c(0, 1))

  panel.polygon(c(0, x, 1), c(0, y, 0), ...)
  panel.lines(c(0, 1), c(0, 1), col = "red")
}
