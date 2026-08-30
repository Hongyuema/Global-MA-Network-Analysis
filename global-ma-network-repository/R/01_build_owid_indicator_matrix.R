#!/usr/bin/env Rscript

library(data.table)
library(readxl)
source("R/utils_ma_network.R")

raw_dir <- get_arg("raw_dir", "data/raw/Data_OWID")
year <- get_arg("year", "2020")
country_map_file <- get_arg("country_map", "data/metadata/country_iso_map.csv")
output_dir <- get_arg("output_dir", "data/processed")
ensure_dir(output_dir)

output_file <- file.path(output_dir, paste0("All_OWID_", year, "_vlookup_code_or_entity.csv"))
audit_file <- file.path(output_dir, paste0("All_OWID_", year, "_audit_code_or_entity.csv"))

country_map <- read.csv(country_map_file, stringsAsFactors = FALSE, check.names = FALSE)
if (!all(c("ISO", "Country") %in% colnames(country_map))) {
  stop("country_iso_map.csv must contain ISO and Country columns.")
}
iso_order <- country_map$ISO
country_to_iso <- setNames(country_map$ISO, country_map$Country)

result_list <- list(ISO = iso_order)
header_names <- c("ISO")
header_topic <- c("")
header_subtopic <- c("")
internal_col_counter <- 0
audit_list <- list()

normalize_year <- function(x) {
  x <- trimws(as.character(x))
  sub("\\.0+$", "", x)
}
normalize_code <- function(x) {
  x <- trimws(as.character(x))
  x[x == ""] <- NA
  x
}
normalize_entity <- function(x) {
  x <- trimws(as.character(x))
  x[x == ""] <- NA
  x
}
append_one_column <- function(raw_col_name, topic_name, subtopic_name, matched_values) {
  internal_col_counter <<- internal_col_counter + 1
  internal_name <- paste0("V", internal_col_counter)
  result_list[[internal_name]] <<- matched_values
  header_names <<- c(header_names, raw_col_name)
  header_topic <<- c(header_topic, topic_name)
  header_subtopic <<- c(header_subtopic, subtopic_name)
}
add_audit_row <- function(file_path, file_type, sheet_name, topic_name, subtopic_name,
                          has_code, has_year, has_entity, total_rows, rows_target_year,
                          value_cols_count, status, note) {
  audit_list[[length(audit_list) + 1]] <<- data.frame(
    file_path = file_path,
    file_type = file_type,
    sheet_name = sheet_name,
    topic = topic_name,
    subtopic = subtopic_name,
    has_code = has_code,
    has_year = has_year,
    has_entity = has_entity,
    total_rows = total_rows,
    rows_target_year = rows_target_year,
    value_cols_count = value_cols_count,
    status = status,
    note = note,
    stringsAsFactors = FALSE
  )
}
match_one_column <- function(df_sub, value_col, iso_order, country_to_iso) {
  out <- rep("", length(iso_order))
  code_vec <- if ("Code" %in% names(df_sub)) normalize_code(df_sub$Code) else rep(NA, nrow(df_sub))
  ent_vec <- if ("Entity" %in% names(df_sub)) normalize_entity(df_sub$Entity) else rep(NA, nrow(df_sub))
  val_vec <- as.character(df_sub[[value_col]])
  val_vec[is.na(val_vec)] <- ""
  final_iso <- code_vec
  need_fallback <- is.na(final_iso) | !(final_iso %in% iso_order)
  if (any(need_fallback) && "Entity" %in% names(df_sub)) {
    ent_match <- country_to_iso[ent_vec[need_fallback]]
    final_iso[need_fallback] <- unname(ent_match)
  }
  keep <- !is.na(final_iso) & final_iso %in% iso_order
  final_iso <- final_iso[keep]
  val_vec <- val_vec[keep]
  if (length(final_iso) == 0) return(out)
  tmp <- split(val_vec, final_iso)
  first_nonempty <- vapply(tmp, function(v) {
    v <- v[trimws(v) != ""]
    if (length(v) == 0) "" else v[1]
  }, character(1))
  idx <- match(names(first_nonempty), iso_order)
  valid <- !is.na(idx)
  out[idx[valid]] <- first_nonempty[valid]
  out
}
read_excel_all_text <- function(path, sheet) {
  read_excel(path, sheet = sheet, col_types = "text", .name_repair = "minimal")
}
read_csv_all_text <- function(path) {
  fread(path, colClasses = "character", data.table = FALSE, encoding = "UTF-8")
}
process_one_df <- function(df, file_path, file_type, sheet_name, topic_name, subtopic_name, target_year) {
  if (is.null(df)) {
    add_audit_row(file_path, file_type, sheet_name, topic_name, subtopic_name,
                  FALSE, FALSE, FALSE, 0, 0, 0, "skip", "read_failed")
    return(invisible(NULL))
  }
  has_code <- "Code" %in% names(df)
  has_year <- "Year" %in% names(df)
  has_entity <- "Entity" %in% names(df)
  if (nrow(df) == 0) {
    add_audit_row(file_path, file_type, sheet_name, topic_name, subtopic_name,
                  has_code, has_year, has_entity, 0, 0, 0, "skip", "empty_table")
    return(invisible(NULL))
  }
  if (!has_year) {
    add_audit_row(file_path, file_type, sheet_name, topic_name, subtopic_name,
                  has_code, has_year, has_entity, nrow(df), 0, 0, "skip", "missing_Year")
    return(invisible(NULL))
  }
  if (!has_code && !has_entity) {
    add_audit_row(file_path, file_type, sheet_name, topic_name, subtopic_name,
                  has_code, has_year, has_entity, nrow(df), 0, 0, "skip", "missing_Code_and_Entity")
    return(invisible(NULL))
  }
  if (has_code) df$Code <- normalize_code(df$Code)
  if (has_entity) df$Entity <- normalize_entity(df$Entity)
  df$Year <- normalize_year(df$Year)
  df_sub <- df[df$Year == target_year, , drop = FALSE]
  rows_target_year <- nrow(df_sub)
  if (rows_target_year == 0) {
    add_audit_row(file_path, file_type, sheet_name, topic_name, subtopic_name,
                  has_code, has_year, has_entity, nrow(df), 0, 0, "skip", "no_target_year_rows")
    return(invisible(NULL))
  }
  value_cols <- setdiff(names(df_sub), c("Entity", "Code", "Year"))
  value_cols_count <- length(value_cols)
  if (value_cols_count == 0) {
    add_audit_row(file_path, file_type, sheet_name, topic_name, subtopic_name,
                  has_code, has_year, has_entity, nrow(df), rows_target_year, 0, "skip", "no_value_columns")
    return(invisible(NULL))
  }
  for (col_name in value_cols) {
    matched_values <- match_one_column(df_sub, col_name, iso_order, country_to_iso)
    append_one_column(col_name, topic_name, subtopic_name, matched_values)
  }
  add_audit_row(file_path, file_type, sheet_name, topic_name, subtopic_name,
                has_code, has_year, has_entity, nrow(df), rows_target_year,
                value_cols_count, "ok", "captured")
  invisible(NULL)
}

all_files <- list.files(path = raw_dir, pattern = "\\.(xlsx|csv)$", recursive = TRUE, full.names = TRUE)
all_files <- all_files[!grepl("^~\\$", basename(all_files))]
message("Files found: ", length(all_files))

for (file in all_files) {
  file_parts <- strsplit(normalizePath(file, winslash = "/", mustWork = FALSE), "/")[[1]]
  topic_name <- if (length(file_parts) >= 3) tail(file_parts, 3)[1] else ""
  subtopic_name <- if (length(file_parts) >= 2) tail(file_parts, 2)[1] else ""
  if (grepl("\\.xlsx$", file, ignore.case = TRUE)) {
    sheets <- tryCatch(excel_sheets(file), error = function(e) NULL)
    if (is.null(sheets)) {
      add_audit_row(file, "xlsx", NA, topic_name, subtopic_name,
                    FALSE, FALSE, FALSE, 0, 0, 0, "skip", "excel_sheets_failed")
      next
    }
    for (sh in sheets) {
      df <- tryCatch(read_excel_all_text(file, sh), error = function(e) NULL)
      process_one_df(df, file, "xlsx", sh, topic_name, subtopic_name, target_year = year)
    }
  }
  if (grepl("\\.csv$", file, ignore.case = TRUE)) {
    df <- tryCatch(read_csv_all_text(file), error = function(e) NULL)
    process_one_df(df, file, "csv", NA, topic_name, subtopic_name, target_year = year)
  }
}

result_df <- as.data.frame(result_list, stringsAsFactors = FALSE, check.names = FALSE)
header_df <- as.data.frame(rbind(header_names, header_topic, header_subtopic), stringsAsFactors = FALSE, check.names = FALSE)

data.table::fwrite(header_df, output_file, col.names = FALSE)
data.table::fwrite(result_df, output_file, append = TRUE, col.names = FALSE)

audit_df <- if (length(audit_list) > 0) data.table::rbindlist(audit_list, fill = TRUE) else data.table::data.table()
data.table::fwrite(audit_df, audit_file)

message("Indicator matrix written to: ", output_file)
message("Audit file written to: ", audit_file)
message("Output columns, including ISO: ", ncol(result_df))
message("Audit rows: ", nrow(audit_df))
