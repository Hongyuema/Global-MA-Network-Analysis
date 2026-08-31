# OWID-GCO cross-database MA network materials

This folder contains the code, input data, processed outputs and supporting documentation for the cross-database macro association (MA) analysis linking Our World in Data (OWID) indicators with Global Cancer Observatory (GCO/GLOBOCAN 2020) cancer incidence estimates.

## Contents

The package includes the core materials required to inspect and reproduce the OWID-GCO analysis reported in the manuscript:

1. Source-level input workbooks for the 2020 OWID indicator matrix and GCO cancer-incidence table.
2. ISO-matched country list used for the OWID-GCO linkage.
3. One-star cancer × OWID Pearson correlation matrix.
4. Two-star cancer × OWID GDP-adjusted partial-correlation matrix.
5. Two-star pairwise complete-case sample-size matrix.
6. Long-format one-star and two-star association tables.
7. Cancer subtype name standardization tables.
8. OWID item-to-topic mapping tables used for one-star and two-star heatmaps.
9. R scripts for recomputing correlations and reproducing heatmaps.

## Directory structure

```text
R/
  utils_owid_gco_cross_database.R
  07_compute_owid_gco_one_star_correlation.R
  08_compute_owid_gco_two_star_partial_correlation.R
  09_plot_owid_gco_one_star_heatmap.R
  10_plot_owid_gco_two_star_heatmap.R
  11_run_owid_gco_cross_database_pipeline.R

data/cross_database/owid_gco/
  input/
  processed/
  matrices/one_star/
  matrices/two_star/
  metadata/

outputs/figures/
docs/
```

## Data files

### Input

- `data/cross_database/owid_gco/input/All_OWID_Data_2020_Cancer_incidence.xlsx`
- `data/cross_database/owid_gco/input/GCO_cancer_incidence_2020_standardized_cancer_names.xlsx`

### Processed matching output

- `data/cross_database/owid_gco/processed/cancer_OWID_matched_countries_by_ISO.csv`

### One-star output

- `data/cross_database/owid_gco/matrices/one_star/cancer_vs_OWID_correlation_min30_ISOmatched.csv`
- `data/cross_database/owid_gco/matrices/one_star/cancer_vs_OWID_correlation_min30_long_ISOmatched.csv`

### Two-star output

- `data/cross_database/owid_gco/matrices/two_star/cancer_vs_OWID_partial_correlation_GDPcontrolled_min30_ISOmatched.csv`
- `data/cross_database/owid_gco/matrices/two_star/cancer_vs_OWID_partial_pairwise_n_GDPcontrolled_min30_ISOmatched.csv`
- `data/cross_database/owid_gco/matrices/two_star/cancer_vs_OWID_partial_correlation_GDPcontrolled_min30_long_ISOmatched.csv`

### Metadata

- `data/cross_database/owid_gco/metadata/cancer_subtype_name_standardization_table.csv`
- `data/cross_database/owid_gco/metadata/cancer_subtype_name_corrections_used_Pearson.csv`
- `data/cross_database/owid_gco/metadata/cancer_subtype_name_corrections_used_partial.csv`
- `data/cross_database/owid_gco/metadata/cancer_vs_OWID_one_star_heatmap_item_topic_mapping_used.csv`
- `data/cross_database/owid_gco/metadata/cancer_vs_OWID_two_star_heatmap_item_topic_mapping_used.csv`

## Analysis rules

One-star analysis uses pairwise Pearson correlation between each cancer subtype and each OWID item across ISO-matched countries. Two-star analysis uses GDP-adjusted partial correlation based on the residual method. Associations are retained only when supported by at least 30 complete country-level observations. Missing or non-estimable associations are retained as `NA` in the matrices.

For heatmap visualization, cancer subtypes are clustered according to their association profiles using pairwise-complete Pearson similarity and average-linkage hierarchical clustering. OWID indicators are ordered by the predefined OWID topic categories rather than clustered. Cancer subtype labels are standardized for figure display; numerical association values are not changed by label standardization.

## Reproducibility

Run the full OWID-GCO workflow from the repository root with:

```r
source("R/11_run_owid_gco_cross_database_pipeline.R")
```

The scripts use repository-relative paths and do not depend on local desktop paths.
