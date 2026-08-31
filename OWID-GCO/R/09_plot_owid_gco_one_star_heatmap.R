# Plot the one-star OWID-GCO cross-database heatmap from post-run data.

suppressPackageStartupMessages({
  library(ComplexHeatmap)
  library(circlize)
  library(grid)
})

source("R/utils_owid_gco_cross_database.R")

matrix_file <- "data/cross_database/owid_gco/matrices/one_star/cancer_vs_OWID_correlation_min30_ISOmatched.csv"
topic_file <- "data/cross_database/owid_gco/metadata/cancer_vs_OWID_one_star_heatmap_item_topic_mapping_used.csv"
out_dir <- "outputs/figures"
min_non_missing <- 30

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

corr_mat <- as.matrix(read.csv(matrix_file, row.names = 1, check.names = FALSE))
mode(corr_mat) <- "numeric"

old_names <- rownames(corr_mat)
new_names <- standardize_cancer_names(old_names)
rownames(corr_mat) <- new_names
write.csv(
  data.frame(original_cancer_name = old_names, corrected_cancer_name = new_names),
  "data/cross_database/owid_gco/metadata/cancer_subtype_name_corrections_used_Pearson.csv",
  row.names = FALSE
)

topic_map <- read.csv(topic_file, stringsAsFactors = FALSE, check.names = FALSE)
topic_vec <- topic_map$mapped_topic
names(topic_vec) <- topic_map$correlation_matrix_column

keep_items <- colSums(!is.na(corr_mat)) >= min_non_missing
corr_filt <- corr_mat[, keep_items, drop = FALSE]
common_items <- intersect(colnames(corr_filt), names(topic_vec))
corr_filt <- corr_filt[, common_items, drop = FALSE]
topic_filt <- topic_vec[common_items]

topic_order <- c(
  "Education and Knowledge",
  "Energy and Environment",
  "Food and Agriculture",
  "Health",
  "Human Rights and Democracy",
  "Innovation and Technological Change",
  "Living Conditions, Community and Wellbeing",
  "Population and Demographic Change",
  "Poverty and Economic Development",
  "Violence and War"
)

topic_factor <- factor(topic_filt, levels = topic_order)
col_order <- order(is.na(topic_factor), topic_factor, names(topic_filt))
corr_plot <- corr_filt[, col_order, drop = FALSE]
topic_plot <- topic_filt[col_order]

dist_fun_rows <- function(mat) {
  sim <- cor(t(mat), use = "pairwise.complete.obs", method = "pearson")
  diag(sim) <- 1
  sim[is.na(sim)] <- 0
  as.dist(1 - sim)
}
row_hc <- hclust(dist_fun_rows(corr_plot), method = "average")

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
extra_topics <- setdiff(unique(topic_plot), names(topic_colors))
if (length(extra_topics) > 0) {
  extra_cols <- grDevices::colorRampPalette(c("#8dd3c7", "#80b1d3", "#bebada", "#fb8072"))(length(extra_topics))
  names(extra_cols) <- extra_topics
  topic_colors <- c(topic_colors, extra_cols)
}

top_anno <- HeatmapAnnotation(
  Topic = topic_plot,
  col = list(Topic = topic_colors),
  show_annotation_name = FALSE,
  simple_anno_size = unit(3, "mm"),
  gp = gpar(col = NA),
  show_legend = FALSE
)

col_fun <- colorRamp2(c(-1, 0, 1), c("#2C7BB6", "#D9F0D3", "#D7301F"))

ht <- Heatmap(
  corr_plot,
  name = "Pearson r",
  col = col_fun,
  na_col = "#E5E5E5",
  cluster_rows = row_hc,
  cluster_columns = FALSE,
  top_annotation = top_anno,
  show_row_names = TRUE,
  row_names_side = "right",
  row_names_gp = gpar(fontsize = 7),
  show_column_names = FALSE,
  use_raster = FALSE,
  rect_gp = gpar(col = NA),
  width = unit(26, "cm"),
  height = unit(12, "cm"),
  heatmap_legend_param = list(
    title = "Pearson r",
    at = c(-1, -0.5, 0, 0.5, 1),
    legend_height = unit(5, "cm"),
    title_gp = gpar(fontsize = 10, fontface = "bold"),
    labels_gp = gpar(fontsize = 8)
  )
)

lgd_topic <- Legend(
  title = "Topic",
  at = names(topic_colors),
  legend_gp = gpar(fill = topic_colors),
  nrow = 2,
  by_row = TRUE,
  title_gp = gpar(fontsize = 10, fontface = "bold"),
  labels_gp = gpar(fontsize = 8)
)

png(file.path(out_dir, "cancer_vs_OWID_one_star_heatmap.png"), width = 6000, height = 2600, res = 300)
draw(ht, heatmap_legend_side = "right", annotation_legend_list = list(lgd_topic), annotation_legend_side = "bottom", merge_legends = FALSE, padding = unit(c(2, 2, 10, 2), "mm"))
dev.off()

pdf(file.path(out_dir, "cancer_vs_OWID_one_star_heatmap.pdf"), width = 20, height = 8.8)
draw(ht, heatmap_legend_side = "right", annotation_legend_list = list(lgd_topic), annotation_legend_side = "bottom", merge_legends = FALSE, padding = unit(c(2, 2, 10, 2), "mm"))
dev.off()

message("One-star OWID-GCO heatmap completed.")
