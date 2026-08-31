# Run OWID-GCO cross-database analysis workflow.
# Input files must be placed in data/cross_database/owid_gco/input/ before running.

source("R/07_compute_owid_gco_one_star_correlation.R")
source("R/08_compute_owid_gco_two_star_partial_correlation.R")
source("R/09_plot_owid_gco_one_star_heatmap.R")
source("R/10_plot_owid_gco_two_star_heatmap.R")
