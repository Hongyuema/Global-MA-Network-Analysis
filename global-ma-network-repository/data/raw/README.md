# Raw data

Place raw OWID source files here if the complete source directory is redistributed or available locally. The script `R/01_build_owid_indicator_matrix.R` scans this directory recursively for `.csv` and `.xlsx` files.

The raw files should contain a `Year` column and either a `Code` column or an `Entity` column. ISO-code matching is used preferentially; country-name matching is used as a fallback when ISO codes are unavailable.
