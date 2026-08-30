#!/usr/bin/env Rscript

source("R/utils_ma_network.R")

years_arg <- get_arg("years", "2000,2005,2010,2015,2020")
years <- strsplit(years_arg, ",", fixed = TRUE)[[1]]
years <- trimws(years)

run_step <- function(cmd) {
  message("Running: ", cmd)
  status <- system(cmd)
  if (status != 0) stop("Command failed: ", cmd)
}

for (year in years) {
  run_step(paste("Rscript R/02_compute_one_star_correlation.R --year=", year, sep = ""))
  run_step(paste("Rscript R/03_compute_two_star_partial_correlation.R --year=", year, sep = ""))
  run_step(paste("Rscript R/04_plot_one_star_heatmap.R --year=", year, sep = ""))
  run_step(paste("Rscript R/05_plot_two_star_heatmap.R --year=", year, sep = ""))
}
