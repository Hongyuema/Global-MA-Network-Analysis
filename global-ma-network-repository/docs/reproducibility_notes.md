# Reproducibility notes

This code release follows the analytical choices described in the manuscript.

## Country and variable matching

Country-level indicators are matched preferentially by ISO code. When ISO codes are missing or not included in the target country list, country names are used as a fallback through `data/metadata/country_iso_map.csv`.

## Matrix structure

Processed OWID matrices contain two annotation rows before country-level values: row 1 for topics and row 2 for subtopics. The analysis scripts remove these annotation rows before converting indicator columns to numeric values.

## One-star analysis

One-star MA networks use pairwise Pearson correlations. Pairwise-complete observations are used for each variable pair. Associations with fewer than 30 paired country-level observations are set to missing.

## Two-star analysis

Two-star MA networks use residual partial correlations adjusted for GDP per capita. For each variable pair, complete cases are identified across variable A, variable B, and the control variable. Associations with fewer than 30 complete observations are set to missing.

## Heatmap visualization

Missing associations are retained as missing in the plotted matrix and displayed in grey. Missing similarities are replaced by zero only for constructing complete clustering-distance matrices. Topic annotations are displayed as heatmap annotation bars and are not used in the clustering algorithm.
