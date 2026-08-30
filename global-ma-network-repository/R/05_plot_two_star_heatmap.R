#!/usr/bin/env Rscript

library(ComplexHeatmap)
library(circlize)
library(grid)
source("R/utils_ma_network.R")

year <- get_arg("year", "2020")
min_links <- as_integer_arg("min_links", 30)
input_matrix_file <- get_arg("input_matrix", file.path("data", "matrices", "two_star", paste0("OWID_item_partial_correlation_", year, "_GDPcontrolled_min", min_links, ".csv")))
indicator_file <- get_arg("indicator", file.path("data", "processed", paste0("All_OWID_", year, "_vlookup_code_or_entity.csv")))
output_dir <- get_arg("output_dir", file.path("outputs", "figures"))
table_dir <- get_arg("table_dir", file.path("outputs", "tables"))
encoding <- get_arg("encoding", "UTF-8")
ensure_dir(output_dir)
ensure_dir(table_dir)

corr_mat <- read_square_matrix(input_matrix_file)
message("Input matrix dimension: ", nrow(corr_mat), " x ", ncol(corr_mat))

topic_vec <- map_topics_to_matrix(indicator_file, colnames(corr_mat), encoding = encoding)
filtered <- filter_by_min_links(corr_mat, topic_vec, min_links = min_links)
corr_filt <- filtered$matrix
topic_filt <- filtered$topic
message("Retained variables for plotting: ", ncol(corr_filt))

diag(corr_filt) <- 1
corr_plot <- corr_filt

row_hc <- hclust(association_profile_distance(corr_plot), method = "average")
col_hc <- hclust(association_profile_distance(corr_plot), method = "average")

topic_colors <- topic_colors_default(unique(topic_filt))

top_anno <- HeatmapAnnotation(
  Topic = topic_filt,
  col = list(Topic = topic_colors),
  show_annotation_name = TRUE,
  annotation_name_gp = gpar(fontsize = 10, fontface = "bold"),
  annotation_name_side = "left",
  simple_anno_size = unit(3, "mm"),
  gp = gpar(col = NA),
  show_legend = TRUE,
  annotation_legend_param = list(
    Topic = list(
      title = "Topic",
      nrow = 2,
      title_gp = gpar(fontsize = 10, fontface = "bold"),
      labels_gp = gpar(fontsize = 8)
    )
  )
)

left_anno <- rowAnnotation(
  Topic = topic_filt,
  col = list(Topic = topic_colors),
  show_annotation_name = FALSE,
  simple_anno_size = unit(3, "mm"),
  gp = gpar(col = NA),
  show_legend = FALSE
)

col_fun <- colorRamp2(c(-1, 0, 1), c("#2C7BB6", "#D9F0D3", "#D7301F"))

ht <- Heatmap(
  corr_plot,
  name = "Partial r",
  col = col_fun,
  na_col = "#E5E5E5",
  cluster_rows = row_hc,
  cluster_columns = col_hc,
  top_annotation = top_anno,
  left_annotation = left_anno,
  show_row_names = FALSE,
  show_column_names = FALSE,
  use_raster = FALSE,
  rect_gp = gpar(col = NA),
  width = unit(15, "cm"),
  height = unit(15, "cm"),
  row_dend_width = unit(1.6, "cm"),
  column_dend_height = unit(1.6, "cm"),
  heatmap_legend_param = list(
    title = "Partial r",
    at = c(-1, -0.5, 0, 0.5, 1),
    legend_height = unit(5, "cm"),
    title_gp = gpar(fontsize = 10, fontface = "bold"),
    labels_gp = gpar(fontsize = 8)
  )
)

output_prefix <- get_arg("output_prefix", file.path(output_dir, paste0("OWID_two_star_heatmap_", year, "_final")))
pdf_file <- paste0(output_prefix, ".pdf")
png_file <- paste0(output_prefix, ".png")

pdf(pdf_file, width = 11, height = 9)
draw(ht, heatmap_legend_side = "right", annotation_legend_side = "bottom", merge_legends = FALSE,
     padding = unit(c(2, 2, 4, 2), "mm"))
dev.off()

png(png_file, width = 3300, height = 2700, res = 300)
draw(ht, heatmap_legend_side = "right", annotation_legend_side = "bottom", merge_legends = FALSE,
     padding = unit(c(2, 2, 4, 2), "mm"))
dev.off()

mapping_used <- data.frame(
  partial_correlation_matrix_column = colnames(corr_plot),
  mapped_topic = topic_filt,
  stringsAsFactors = FALSE
)
mapping_file <- file.path(table_dir, paste0("OWID_two_star_heatmap_", year, "_item_topic_mapping_final.csv"))
write.csv(mapping_used, mapping_file, row.names = FALSE)

message("Heatmap PDF written to: ", pdf_file)
message("Heatmap PNG written to: ", png_file)
message("Topic mapping written to: ", mapping_file)
