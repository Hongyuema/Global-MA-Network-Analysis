# Compute two-star GDP-adjusted OWID-GCO cross-database partial correlations
# Rows are GCO cancer subtypes and columns are OWID indicators.

suppressPackageStartupMessages({
  library(dplyr)
})

source("R/utils_owid_gco_cross_database.R")

owid_file <- "data/cross_database/owid_gco/input/All_OWID_Data_2020_Cancer_incidence.xlsx"
cancer_file <- "data/cross_database/owid_gco/input/GCO_cancer_incidence_2020_standardized_cancer_names.xlsx"
out_dir <- "data/cross_database/owid_gco/matrices/two_star"
metadata_dir <- "data/cross_database/owid_gco/metadata"
processed_dir <- "data/cross_database/owid_gco/processed"
min_n <- 30

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(metadata_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

owid <- read_owid_cancer_input(owid_file)
gco <- read_gco_input(cancer_file, cancer_iso_col = "ISO")

gdp_col <- find_gdp_control(colnames(owid$data))
message("GDP control variable: ", gdp_col)

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

pcorr_mat <- matrix(
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

z <- as.numeric(merged[[gdp_col]])
for (i in seq_along(gco$cancer_vars)) {
  y <- as.numeric(merged[[gco$cancer_vars[i]]])
  message("Processing two-star partial correlation: ", i, "/", length(gco$cancer_vars), " - ", gco$cancer_vars[i])
  for (j in seq_along(owid$value_cols)) {
    x <- as.numeric(merged[[owid$value_cols[j]]])
    out <- partial_cor_residual(x = x, y = y, z = z, min_n = min_n)
    pcorr_mat[i, j] <- out$r
    pair_n_mat[i, j] <- out$n
  }
}

write.csv(
  pcorr_mat,
  file.path(out_dir, "cancer_vs_OWID_partial_correlation_GDPcontrolled_min30_ISOmatched.csv"),
  row.names = TRUE
)

write.csv(
  pair_n_mat,
  file.path(out_dir, "cancer_vs_OWID_partial_pairwise_n_GDPcontrolled_min30_ISOmatched.csv"),
  row.names = TRUE
)

pcorr_long <- as.data.frame(as.table(pcorr_mat), stringsAsFactors = FALSE)
colnames(pcorr_long) <- c("Cancer_subtype", "OWID_item", "partial_r")
n_long <- as.data.frame(as.table(pair_n_mat), stringsAsFactors = FALSE)
colnames(n_long) <- c("Cancer_subtype", "OWID_item", "n_pair")
result_long <- left_join(pcorr_long, n_long, by = c("Cancer_subtype", "OWID_item"))
write.csv(
  result_long,
  file.path(out_dir, "cancer_vs_OWID_partial_correlation_GDPcontrolled_min30_long_ISOmatched.csv"),
  row.names = FALSE
)

topic_vec <- build_topic_mapping(colnames(pcorr_mat), owid$value_cols, owid$topic_row)
write.csv(
  data.frame(partial_correlation_matrix_column = names(topic_vec), mapped_topic = unname(topic_vec)),
  file.path(metadata_dir, "cancer_vs_OWID_two_star_heatmap_item_topic_mapping_used.csv"),
  row.names = FALSE
)

message("Two-star OWID-GCO partial-correlation analysis completed.")
