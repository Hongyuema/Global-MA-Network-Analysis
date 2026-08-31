# Compute one-star OWID-GCO cross-database correlations
# Rows are GCO cancer subtypes and columns are OWID indicators.

suppressPackageStartupMessages({
  library(dplyr)
})

source("R/utils_owid_gco_cross_database.R")

owid_file <- "data/cross_database/owid_gco/input/All_OWID_Data_2020_Cancer_incidence.xlsx"
cancer_file <- "data/cross_database/owid_gco/input/GCO_cancer_incidence_2020_standardized_cancer_names.xlsx"
out_dir <- "data/cross_database/owid_gco/matrices/one_star"
metadata_dir <- "data/cross_database/owid_gco/metadata"
processed_dir <- "data/cross_database/owid_gco/processed"
min_n <- 30

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(metadata_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

owid <- read_owid_cancer_input(owid_file)
gco <- read_gco_input(cancer_file, cancer_iso_col = "ISO")

merged <- inner_join(
  gco$data,
  owid$data,
  by = "ISO",
  suffix = c("_cancer", "_owid")
)

matched_cols <- intersect(c("ISO", "NAME", "NAME_cancer", "NAME_owid"), colnames(merged))
write.csv(
  merged[, matched_cols, drop = FALSE],
  file.path(processed_dir, "cancer_OWID_matched_countries_by_ISO.csv"),
  row.names = FALSE
)

corr_mat <- matrix(
  NA_real_,
  nrow = length(gco$cancer_vars),
  ncol = length(owid$value_cols),
  dimnames = list(gco$cancer_vars, owid$value_cols)
)

pair_n_mat <- matrix(
  NA_integer_,
  nrow = length(gco$cancer_vars),
  ncol = length(owid$value_cols),
  dimnames = list(gco$cancer_vars, owid$value_cols)
)

for (i in seq_along(gco$cancer_vars)) {
  y <- as.numeric(merged[[gco$cancer_vars[i]]])
  message("Processing one-star correlation: ", i, "/", length(gco$cancer_vars), " - ", gco$cancer_vars[i])
  for (j in seq_along(owid$value_cols)) {
    x <- as.numeric(merged[[owid$value_cols[j]]])
    idx <- which(!is.na(x) & !is.na(y))
    n_pair <- length(idx)
    pair_n_mat[i, j] <- n_pair
    if (n_pair >= min_n && sd(x[idx]) > 0 && sd(y[idx]) > 0) {
      corr_mat[i, j] <- cor(x[idx], y[idx], method = "pearson")
    }
  }
}

write.csv(
  corr_mat,
  file.path(out_dir, "cancer_vs_OWID_correlation_min30_ISOmatched.csv"),
  row.names = TRUE
)

write.csv(
  pair_n_mat,
  file.path(out_dir, "cancer_vs_OWID_pairwise_n_min30_ISOmatched.csv"),
  row.names = TRUE
)

topic_vec <- build_topic_mapping(colnames(corr_mat), owid$value_cols, owid$topic_row)
write.csv(
  data.frame(correlation_matrix_column = names(topic_vec), mapped_topic = unname(topic_vec)),
  file.path(metadata_dir, "cancer_vs_OWID_one_star_heatmap_item_topic_mapping_used.csv"),
  row.names = FALSE
)

message("One-star OWID-GCO correlation analysis completed.")
