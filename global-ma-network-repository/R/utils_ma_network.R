# Utility functions for global MA network analysis.
# All functions are deterministic and do not modify input files.

get_arg <- function(name, default = NULL) {
  args <- commandArgs(trailingOnly = TRUE)
  prefix <- paste0("--", name, "=")
  hit <- grep(paste0("^", prefix), args, value = TRUE)
  if (length(hit) == 0) return(default)
  sub(prefix, "", hit[1], fixed = TRUE)
}

as_integer_arg <- function(name, default) {
  value <- get_arg(name, as.character(default))
  suppressWarnings(as.integer(value))
}

ensure_dir <- function(path) {
  if (!dir.exists(path)) dir.create(path, recursive = TRUE, showWarnings = FALSE)
  invisible(path)
}

safe_as_numeric <- function(x) {
  x <- as.character(x)
  x <- trimws(x)
  x[x == ""] <- NA
  x <- gsub(",", "", x, fixed = TRUE)
  x <- gsub("%", "", x, fixed = TRUE)
  suppressWarnings(as.numeric(x))
}

metadata_columns <- function(x) {
  intersect(c("Entity", "Country", "Continent", "Continents", "Code", "ISO", "NAME"), x)
}

read_indicator_matrix <- function(file, encoding = "UTF-8") {
  dat <- tryCatch(
    read.csv(file, stringsAsFactors = FALSE, check.names = FALSE, fileEncoding = encoding),
    error = function(e) read.csv(file, stringsAsFactors = FALSE, check.names = FALSE)
  )
  if (nrow(dat) < 3) stop("The indicator matrix must contain topic, subtopic, and country-level rows.")
  meta_cols <- metadata_columns(colnames(dat))
  value_cols <- setdiff(colnames(dat), meta_cols)
  topic_row <- as.character(dat[1, value_cols])
  subtopic_row <- as.character(dat[2, value_cols])
  names(topic_row) <- value_cols
  names(subtopic_row) <- value_cols
  country_data <- dat[-c(1, 2), , drop = FALSE]
  X_df <- country_data[, value_cols, drop = FALSE]
  X_df[] <- lapply(X_df, safe_as_numeric)
  list(
    raw = dat,
    country_data = country_data,
    X = as.matrix(X_df),
    value_cols = value_cols,
    topic = topic_row,
    subtopic = subtopic_row,
    meta_cols = meta_cols
  )
}

remove_metadata_from_square_matrix <- function(mat) {
  bad <- intersect(c("ISO", "Entity", "Country", "Continent", "Continents", "Code", "NAME"), colnames(mat))
  if (length(bad) > 0) {
    mat <- mat[!(rownames(mat) %in% bad), !(colnames(mat) %in% bad), drop = FALSE]
  }
  mat
}

read_square_matrix <- function(file) {
  df <- read.csv(file, row.names = 1, check.names = FALSE, stringsAsFactors = FALSE)
  mat <- as.matrix(df)
  mode(mat) <- "numeric"
  remove_metadata_from_square_matrix(mat)
}

map_topics_to_matrix <- function(indicator_file, matrix_columns, encoding = "UTF-8") {
  ind <- read_indicator_matrix(indicator_file, encoding = encoding)
  topic_map <- data.frame(
    original_name = ind$value_cols,
    sanitized_name = make.names(ind$value_cols, unique = TRUE),
    topic = unname(ind$topic),
    stringsAsFactors = FALSE
  )
  match_original <- match(matrix_columns, topic_map$original_name)
  match_sanitized <- match(matrix_columns, topic_map$sanitized_name)
  final_match <- ifelse(!is.na(match_original), match_original, match_sanitized)
  if (any(is.na(final_match))) {
    stop("Topic mapping failed for one or more matrix columns: ",
         paste(matrix_columns[is.na(final_match)], collapse = "; "))
  }
  topic_vec <- topic_map$topic[final_match]
  names(topic_vec) <- matrix_columns
  if (any(is.na(topic_vec) | trimws(topic_vec) == "")) {
    stop("One or more mapped topic annotations are missing or empty.")
  }
  gsub("_[0-9]+$", "", topic_vec)
}

filter_by_min_links <- function(mat, topic_vec, min_links = 30) {
  non_na_counts <- rowSums(!is.na(mat))
  usable_links <- non_na_counts - ifelse(!is.na(diag(mat)), 1, 0)
  keep <- usable_links >= min_links
  list(
    matrix = mat[keep, keep, drop = FALSE],
    topic = topic_vec[keep],
    keep = keep,
    usable_links = usable_links
  )
}

association_profile_distance <- function(mat) {
  sim <- cor(mat, use = "pairwise.complete.obs", method = "pearson")
  diag(sim) <- 1
  sim[is.na(sim)] <- 0
  as.dist(1 - sim)
}

topic_colors_default <- function(topic_levels) {
  topic_colors <- c(
    "Education and Knowledge" = "#1f78b4",
    "Energy and Environment" = "#33a02c",
    "Food and Agriculture" = "#ff7f00",
    "Health" = "#e31a1c",
    "Human Rights and Democracy" = "#6a3d9a",
    "Innovation and Technological Change" = "#b15928",
    "Living Conditions, Community and Wellbeing" = "#a6cee3",
    "Population and Demographic Change" = "#b2df8a",
    "Poverty and Economic Development" = "#fb9a99",
    "Violence and War" = "#fdbf6f"
  )
  missing_topics <- setdiff(topic_levels, names(topic_colors))
  if (length(missing_topics) > 0) {
    extra_cols <- grDevices::colorRampPalette(c("#8dd3c7", "#80b1d3", "#bebada", "#fb8072"))(length(missing_topics))
    names(extra_cols) <- missing_topics
    topic_colors <- c(topic_colors, extra_cols)
  }
  topic_colors
}
