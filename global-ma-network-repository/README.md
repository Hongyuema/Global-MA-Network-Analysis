# Global MA Network Analysis

This repository contains code and documentation for constructing and visualizing global macro association (MA) networks from country-level public datasets. The workflow was used for the manuscript *The global MA network of global data in 2020: a macro association analysis*.

The repository is organized to support review and reuse. Processed data matrices and correlation outputs should be placed in the `data/` folders indicated below before running the scripts.

## Repository structure

```text
R/
  utils_ma_network.R
  01_build_owid_indicator_matrix.R
  02_compute_one_star_correlation.R
  03_compute_two_star_partial_correlation.R
  04_plot_one_star_heatmap.R
  05_plot_two_star_heatmap.R
  06_run_owid_ma_pipeline.R

data/
  raw/                 raw OWID source files, if redistributed or locally available
  processed/           harmonized country-by-indicator matrices
  matrices/one_star/   Pearson correlation matrices and pairwise-n matrices
  matrices/two_star/   GDP-adjusted partial-correlation matrices and pairwise-n matrices
  metadata/            country and variable metadata

outputs/
  figures/             exported heatmap figures
  tables/              mapping files and summary outputs

web/                   interactive Global MA Network Explorer

docs/                  technical notes for peer review and reuse
```

## Input files expected for the published workflow

The main scripts assume the following processed files are available, with `<YEAR>` replaced by `2000`, `2005`, `2010`, `2015`, or `2020`:

```text
data/processed/All_OWID_<YEAR>_vlookup_code_or_entity.csv
```

The first row after the header contains topic annotations, the second row contains subtopic annotations, and country-level observations start from the third data row. Metadata columns may include `ISO`, `Code`, `Entity`, `Continent`, `Continents`, or `NAME`; all remaining columns are treated as analyzable indicators.

The correlation and partial-correlation scripts generate:

```text
data/matrices/one_star/OWID_item_correlation_matrix_<YEAR>_min30.csv
data/matrices/one_star/OWID_item_pairwise_n_<YEAR>_min30.csv

data/matrices/two_star/OWID_item_partial_correlation_<YEAR>_GDPcontrolled_min30.csv
data/matrices/two_star/OWID_item_partial_pairwise_n_<YEAR>_GDPcontrolled_min30.csv
```

## Software requirements

The scripts were written for R and use the following packages:

- `data.table`
- `readxl`
- `ComplexHeatmap`
- `circlize`
- `grid`

`ComplexHeatmap` is distributed through Bioconductor.

```r
install.packages(c("data.table", "readxl", "circlize"))
if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")
BiocManager::install("ComplexHeatmap")
```

## Reproducing the main workflow from processed matrices

From the repository root:

```bash
Rscript R/02_compute_one_star_correlation.R --year=2020
Rscript R/03_compute_two_star_partial_correlation.R --year=2020
Rscript R/04_plot_one_star_heatmap.R --year=2020
Rscript R/05_plot_two_star_heatmap.R --year=2020
```

For the temporal analysis, repeat the same commands for `2000`, `2005`, `2010`, `2015`, and `2020`, or run:

```bash
Rscript R/06_run_owid_ma_pipeline.R --years=2000,2005,2010,2015,2020
```

## Rebuilding processed OWID matrices from raw source files

If the raw OWID directory structure is available locally, run:

```bash
Rscript R/01_build_owid_indicator_matrix.R   --raw_dir=data/raw/Data_OWID   --year=2020   --country_map=data/metadata/country_iso_map.csv
```

This step writes a harmonized country-by-indicator matrix and an audit file to `data/processed/`.

## Analytical rules

- One-star MA networks are based on pairwise Pearson correlations.
- Two-star MA networks are based on residual partial correlations adjusted for GDP per capita.
- Associations supported by fewer than 30 complete country-level observations are set to missing.
- Missing associations are retained as missing in matrices and displayed as grey cells in heatmaps.
- Missing values are replaced by zero only for clustering-distance construction, not for analysis or interpretation.
- Topic annotations are used for visualization and interpretation, not for statistical clustering.

## Interactive explorer

The interactive Global MA Network Explorer can be placed in `web/index.html`. It is intended as a web-based interface for querying variables, visualizing one-star and two-star association layers, inspecting scatter plots, exploring local network structures, and examining OWID-GCO cross-database associations.

## Data and code availability statement template

All source data are publicly available from the repositories described in the manuscript. Processed matrices, correlation outputs, scripts, documentation, and the interactive Global MA Network Explorer are provided in this repository for review and reuse.
