# Input workbooks for OWID-GCO cross-database analysis

This directory contains the source-level input workbooks needed to rerun the OWID-GCO cross-database MA analysis.

- `All_OWID_Data_2020_Cancer_incidence.xlsx`: OWID 2020 country-level indicator matrix used for the cancer-incidence linkage. The first row contains OWID topic annotations and the second row contains subtopic annotations.
- `GCO_cancer_incidence_2020_standardized_cancer_names.xlsx`: GCO/GLOBOCAN 2020 cancer-incidence table matched by ISO code. Cancer subtype column names have been standardized to the English labels used in the manuscript figures. Numerical values were not changed.

Country matching is performed by ISO code. The matched-country table produced by the analysis is stored in `data/cross_database/owid_gco/processed/`.
