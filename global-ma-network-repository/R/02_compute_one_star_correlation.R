#!/usr/bin/env Rscript

source("R/utils_ma_network.R")

year <- get_arg("year", "2020")
min_n <- as_integer_arg("min_n", 30)
input_file <- get_arg("input", file.path("data", "processed", paste0("All_OWID_", year, "_vlookup_code_or_entity.csv")))
output_dir <- get_arg("output_dir", file.path("data", "matrices", "one_star"))
encoding <- get_arg("encoding", "UTF-8")
ensure_dir(output_dir)

indicator <- read_indicator_matrix(input_file, encoding = encoding)
X <- indicator$X
message("Input matrix: ", nrow(X), " countries/regions x ", ncol(X), " variables")

non_na <- !is.na(X)
pair_n <- crossprod(non_na)
message("Pairwise sample-size matrix calculated.")

corr_mat <- cor(X, use = "pairwise.complete.obs", method = "pearson")
corr_mat[pair_n < min_n] <- NA
diag(corr_mat) <- ifelse(colSums(!is.na(X)) >= min_n, 1, NA)

corr_file <- file.path(output_dir, paste0("OWID_item_correlation_matrix_", year, "_min", min_n, ".csv"))
pair_n_file <- file.path(output_dir, paste0("OWID_item_pairwise_n_", year, "_min", min_n, ".csv"))
write.csv(corr_mat, file = corr_file, row.names = TRUE)
write.csv(pair_n, file = pair_n_file, row.names = TRUE)

message("One-star Pearson correlation matrix written to: ", corr_file)
message("Pairwise sample-size matrix written to: ", pair_n_file)
