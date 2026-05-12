# Methodology

The cartographic workflow for this project follows a simple three-stage pattern: **acquire → process → render**.

## Stage 1: Acquire

- Download boundary files, raster tiles, and attribute data from open-data portals (Alberta, Edmonton, NRCan).
- Store all raw inputs in `data-public/raw/` (or `data-private/raw/` for licensed/sensitive layers).
- Document every source in `data-public/metadata/INPUT-manifest.md` with URL, retrieval date, license, and CRS.
- Never modify raw files — treat them as immutable inputs.

## Stage 2: Process

- Clean, reproject, clip, and join spatial layers in dedicated scripts under `scripts/`.
- Use a consistent CRS per map family (e.g., EPSG:3400 — NAD83 / Alberta 10-TM for provincial work).
- Write processed layers to `data-public/derived/` as `.gpkg` or `.parquet` files.
- Keep processing scripts idempotent: re-running produces the same output.

## Stage 3: Render

- Each finished map lives in `analysis/<map-name>/` as a paired `<name>.R` + `<name>.qmd` (or standalone `.R` for quick outputs).
- R maps: use `sf` + `ggplot2` + `tmap`; Python maps: use `geopandas` + `matplotlib`.
- Export finals to `data-public/derived/maps/` as `.png` (300 dpi) and `.pdf` where print quality matters.
- Style constants (palettes, fonts, themes) live in `scripts/graphing/map-theme.R`.

## Reproducibility Standards

- All scripts run top-to-bottom without manual intervention.
- Coordinate reference systems are always explicitly set — never assumed.
- Package dependencies declared in `environment.yml` (Python) and `utility/install-packages.R` (R).
- Major design decisions logged in `ai/memory/memory-human.md`.

## Documentation

- `data-public/metadata/INPUT-manifest.md` — raw data provenance.
- `data-public/metadata/CACHE-manifest.md` — processed layer registry.
- Each `analysis/<map-name>/README.md` — map intent, data used, projection rationale.