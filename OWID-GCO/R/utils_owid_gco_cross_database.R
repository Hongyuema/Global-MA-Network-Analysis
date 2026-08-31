# Utility functions for OWID-GCO cross-database macro association analysis
# The functions in this file are shared by the one-star and two-star scripts.

suppressPackageStartupMessages({
  library(dplyr)
  library(readxl)
})

safe_as_numeric <- function(x) {
  x <- as.character(x)
  x <- trimws(x)
  x[x == ""] <- NA_character_
  x <- gsub(",", "", x, fixed = TRUE)
  x <- gsub("%", "", x, fixed = TRUE)
  suppressWarnings(as.numeric(x))
}

clean_column_name <- function(x) {
  x <- trimws(x)
  x <- gsub("[[:space:]]+", " ", x)
  x <- gsub("\\$", " dollar ", x)
  x <- gsub("[()]", " ", x)
  x <- gsub("[,:\"]", " ", x)
  x <- gsub("[-_/]", " ", x)
  x <- tolower(x)
  x <- gsub("[[:space:]]+", " ", x)
  trimws(x)
}

find_gdp_control <- function(column_names) {
  column_names_clean <- clean_column_name(column_names)
  target_keywords <- c("gdp", "per capita", "ppp", "constant", "2021", "international")
  score <- vapply(
    column_names_clean,
    function(x) sum(vapply(target_keywords, function(k) grepl(k, x, fixed = TRUE), logical(1))),
    numeric(1)
  )
  if (length(score) == 0 || max(score, na.rm = TRUE) == 0) {
    stop("No suitable GDP per capita control variable was found.", call. = FALSE)
  }
  column_names[which.max(score)]
}

read_owid_cancer_input <- function(owid_file) {
  owid <- readxl::read_excel(owid_file)
  owid <- as.data.frame(owid, stringsAsFactors = FALSE)
  colnames(owid) <- trimws(colnames(owid))

  meta_cols <- intersect(c("NAME", "Entity", "Continent", "Continents", "Code", "ISO"), colnames(owid))
  if (!("ISO" %in% colnames(owid))) {
    stop("The OWID input file must contain an ISO column.", call. = FALSE)
  }

  value_cols <- setdiff(colnames(owid), meta_cols)
  topic_row <- as.character(owid[1, value_cols])
  names(topic_row) <- value_cols

  blank_topic <- is.na(topic_row) | trimws(topic_row) == ""
  if (any(blank_topic)) {
    print(names(topic_row)[blank_topic])
    stop("The OWID topic row is incomplete.", call. = FALSE)
  }

  owid_df <- owid[-c(1, 2), , drop = FALSE]
  owid_df$ISO <- toupper(trimws(as.character(owid_df$ISO)))
  owid_df[value_cols] <- lapply(owid_df[value_cols], safe_as_numeric)

  list(
    data = owid_df,
    value_cols = value_cols,
    topic_row = topic_row,
    meta_cols = meta_cols
  )
}

read_gco_input <- function(cancer_file, cancer_iso_col = "ISO") {
  cancer <- readxl::read_excel(cancer_file)
  cancer <- as.data.frame(cancer, stringsAsFactors = FALSE)
  colnames(cancer) <- trimws(colnames(cancer))

  if (!(cancer_iso_col %in% colnames(cancer))) {
    stop("The GCO input file must contain the specified ISO column.", call. = FALSE)
  }

  cancer <- cancer %>% rename(ISO = all_of(cancer_iso_col))
  cancer$ISO <- toupper(trimws(as.character(cancer$ISO)))

  exclude_cols <- intersect(c("ISO", "NAME", "Entity", "Country"), colnames(cancer))
  cancer_vars <- setdiff(colnames(cancer), exclude_cols)
  cancer[cancer_vars] <- lapply(cancer[cancer_vars], safe_as_numeric)

  list(data = cancer, cancer_vars = cancer_vars)
}

build_topic_mapping <- function(matrix_columns, owid_value_cols, topic_row) {
  topic_map_df <- data.frame(
    original_name = owid_value_cols,
    sanitized_name = make.names(owid_value_cols, unique = TRUE),
    topic = unname(topic_row),
    stringsAsFactors = FALSE
  )

  match_original <- match(matrix_columns, topic_map_df$original_name)
  match_sanitized <- match(matrix_columns, topic_map_df$sanitized_name)
  final_match <- ifelse(!is.na(match_original), match_original, match_sanitized)

  if (any(is.na(final_match))) {
    unmatched <- matrix_columns[is.na(final_match)]
    print(unmatched)
    stop("Some matrix columns could not be matched to OWID topic annotations.", call. = FALSE)
  }

  topic_vec <- topic_map_df$topic[final_match]
  names(topic_vec) <- matrix_columns

  if (any(is.na(topic_vec) | trimws(topic_vec) == "")) {
    invalid <- names(topic_vec)[is.na(topic_vec) | trimws(topic_vec) == ""]
    print(invalid)
    stop("Some mapped topic annotations are invalid.", call. = FALSE)
  }

  topic_vec
}

partial_cor_residual <- function(x, y, z, min_n = 30) {
  idx <- which(!is.na(x) & !is.na(y) & !is.na(z))
  n_pair <- length(idx)
  if (n_pair < min_n) return(list(r = NA_real_, n = n_pair))

  x2 <- x[idx]
  y2 <- y[idx]
  z2 <- z[idx]

  if (sd(x2) == 0 || sd(y2) == 0 || sd(z2) == 0) {
    return(list(r = NA_real_, n = n_pair))
  }

  rx <- resid(lm(x2 ~ z2))
  ry <- resid(lm(y2 ~ z2))

  if (sd(rx) == 0 || sd(ry) == 0) {
    return(list(r = NA_real_, n = n_pair))
  }

  list(r = cor(rx, ry, method = "pearson"), n = n_pair)
}

standardize_cancer_names <- function(x) {
  cancer_name_map <- c(
    "Gallbladder" = "Gallbladder cancer",
    "Stomach" = "Stomach cancer",
    "Hypopharynx" = "Hypopharyngeal cancer",
    "Lip,oral cavity" = "Lip and oral cavity cancer",
    "Lip, oral cavity" = "Lip and oral cavity cancer",
    "Larynx" = "Laryngeal cancer",
    "Leukaemia" = "Leukemia",
    "Leukemia" = "Leukemia",
    "Non-melanoma skin cancer" = "Nonmelanoma skin cancer",
    "Nonmelanoma skin cancer" = "Nonmelanoma skin cancer",
    "Prostate" = "Prostate cancer",
    "Ovary" = "Ovarian cancer",
    "Thyroid" = "Thyroid cancer",
    "Oropharynx" = "Oropharyngeal cancer",
    "Bladder" = "Bladder cancer",
    "Hodokin lymopha" = "Hodgkin lymphoma",
    "Hodgkin lymphoma" = "Hodgkin lymphoma",
    "Corpus uteri" = "Uterine corpus cancer",
    "Testis" = "Testicular cancer",
    "Colon" = "Colon cancer",
    "Kidney" = "Kidney cancer",
    "Pancreas" = "Pancreatic cancer",
    "Brain,CNS" = "Brain and CNS cancers",
    "Brain, CNS" = "Brain and CNS cancers",
    "Lung" = "Lung cancer",
    "Rectum" = "Rectal cancer",
    "Mesothelioma" = "Mesothelioma",
    "Melanoma of skin" = "Melanoma of skin",
    "Breast" = "Breast cancer",
    "Multiple myeloma" = "Multiple myeloma",
    "Non-Hodgkin lymphoma" = "Non-Hodgkin lymphoma",
    "Salivary gland" = "Salivary gland cancer",
    "Anus" = "Anal cancer",
    "Vulva" = "Vulvar cancer",
    "Penis" = "Penile cancer",
    "Vagina" = "Vaginal cancer",
    "Kaposi sarcoma" = "Kaposi's sarcoma",
    "Kaposi's sarcoma" = "Kaposi's sarcoma",
    "Cervix uteri" = "Cervical cancer",
    "Nasopharynx" = "Nasopharyngeal cancer",
    "Liver" = "Liver cancer",
    "Oesophagus" = "Esophageal cancer",
    "Esophagus" = "Esophageal cancer"
  )
  ifelse(x %in% names(cancer_name_map), cancer_name_map[x], x)
}
