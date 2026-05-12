# `data-public/raw/` Directory

Immutable raw spatial files downloaded from open-data portals. **Never edit files in this folder** — all transformations happen in scripts.

## Organization

Organize by data provider:

```
raw/
  alberta-gov/     # Alberta government open data
  edmonton/        # City of Edmonton open data
  nrcan/           # Natural Resources Canada (terrain, hydrology)
  osm/             # OpenStreetMap extracts
```

## Rules

- Every file added here must be documented in `data-public/metadata/INPUT-manifest.md` (source URL, retrieval date, license, CRS).
- Prefer open formats: `.gpkg`, `.geojson`, `.tif`, `.csv`. Avoid proprietary formats.
- Large raster files (>50 MB) should be listed in `.gitignore` and sourced via a download script instead of committed directly.
- Licensed layers that cannot be shared publicly go in `data-private/raw/` instead.
