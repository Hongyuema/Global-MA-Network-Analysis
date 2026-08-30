#!/usr/bin/env Rscript

source("R/utils_ma_network.R")

year <- get_arg("year", "2020")
min_n <- as_integer_arg("min_n", 30)
control_variable <- get_arg("control", "GDP per capita, PPP (constant 2021 international $)")
input_file <- get_arg("input", file.path("data", "processed", paste0("All_OWID_", year, "_vlookup_code_or_entity.csv")))
output_dir <- get_arg("output_dir", file.path("data", "matrices", "two_star"))
encoding <- get_arg("encoding", "UTF-8")
ensure_dir(output_dir)

indicator <- read_indicator_matrix(input_file, encoding = encoding)
X <- indicator$X
if (!(control_variable %in% colnames(X))) {
  stop("Control variable not found in the indicator matrix: ", control_variable)
}
control_vec <- X[, control_variable]
message("Input matrix: ", nrow(X), " countries/regions x ", ncol(X), " variables")
message("Two-star control variable: ", control_variable)

partial_cor_residual <- function(x, y, z, min_n = 30) {
  idx <- which(!is.na(x) & !is.na(y) & !is.na(z))
  n <- length(idx)
  if (n < min_n) return(list(r = NA_real_, n = n))
  x <- x[idx]
  y <- y[idx]
  z <- z[idx]
  rx <- residuals(lm(x ~ z))
  ry <- residuals(lm(y ~ z))
  if (stats::sd(rx) == 0 || stats::sd(ry) == 0) return(list(r = NA_real_, n = n))
  list(r = stats::cor(rx, ry), n = n)
}

n_var <- ncol(X)
p_corr_mat <- matrix(NA_real_, n_var, n_var, dimnames = list(colnames(X), colnames(X)))
pair_n_mat <- matrix(NA_integer_, n_var, n_var, dimnames = list(colnames(X), colnames(X)))

for (i in seq_len(n_var)) {
  if (i %% 50 == 0) message("Progress: ", i, "/", n_var)
  xi <- X[, i]
  for (j in i:n_var) {
    res <- partial_cor_residual(xi, X[, j], control_vec, min_n = min_n)
    p_corr_mat[i, j] <- res$r
    p_corr_mat[j, i] <- res$r
    pair_n_mat[i, j] <- res$n
    pair_n_mat[j, i] <- res$n
  }
}

diag(p_corr_mat) <- ifelse(colSums(!is.na(X) & !is.na(control_vec)) >= min_n, 1, NA)

partial_file <- file.path(output_dir, paste0("OWID_item_partial_correlation_", year, "_GDPcontrolled_min", min_n, ".csv"))
pair_n_file <- file.path(output_dir, paste0("OWID_item_partial_pairwise_n_", year, "_GDPcontrolled_min", min_n, ".csv"))
write.csv(p_corr_mat, file = partial_file, row.names = TRUE)
write.csv(pair_n_mat, file = pair_n_file, row.names = TRUE)

message("Two-star partial-correlation matrix written to: ", partial_file)
message("Two-star pairwise sample-size matrix written to: ", pair_n_file)
