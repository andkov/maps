# maps

Making beautiful maps of the places I find beautiful.

## What this is

A personal cartography studio for visualizing places at multiple scales — from Edmonton neighborhoods to provincial Alberta landscapes to national Canadian patterns. Maps that are worth printing and hanging, and maps that deepen understanding of place.

## Tools

- **R**: `sf`, `ggplot2`, `tmap` — primary rendering environment
- **Python**: `geopandas`, `matplotlib` — secondary, for specific use cases
- **Data sources**: Alberta open data, City of Edmonton, Natural Resources Canada

## Repository Structure

```
analysis/          # One folder per finished map project
data-public/
  raw/             # Immutable source files (boundaries, rasters, attributes)
  derived/         # Processed layers + finished map exports
  metadata/        # INPUT-manifest.md and CACHE-manifest.md
data-private/      # Licensed or sensitive layers (not committed)
scripts/
  graphing/        # Shared map themes, palettes, style helpers
  common-functions.R
ai/
  project/         # mission.md, method.md, glossary.md
  memory/          # Human and AI decision logs
```

## Getting Started

1. Install R packages: `source("utility/install-packages.R")`
2. Install Python packages: `conda env create -f environment.yml`
3. Browse `analysis/` for existing maps or scaffold a new one.
4. All raw data goes in `data-public/raw/` — document it in `data-public/metadata/INPUT-manifest.md`.

## Conventions

- Raw source files are **never modified** — all processing is scripted.
- Every spatial layer has an **explicit CRS** set in code.
- Finished maps export to `data-public/derived/maps/` at 300 dpi.
- Map-specific decisions are logged in `ai/memory/memory-human.md`.
