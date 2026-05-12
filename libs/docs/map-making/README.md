# Map-Making Reference Library

A curated collection of guides, notes, and references for building static maps in R —
focused on the Edmonton / Alberta context but applicable broadly.

## Contents

| File | What it covers |
|---|---|
| [00-r-packages-landscape.md](00-r-packages-landscape.md) | Survey of R spatial packages: what each does, when to use it |
| [01-data-sources.md](01-data-sources.md) | Where to get elevation, boundary, roads, and land-cover data |

## Map Stack Used in This Project

The `analysis/yeg-*/` maps use a layered approach:

1. **Elevation raster** — downloaded via `{elevatr}`, processed with `{terra}`
2. **Hillshade** — computed from the DEM using `terra::shade()`
3. **Contour lines** — derived from the DEM using `terra::as.contour()`
4. **Physical features** — rivers, parks, roads from **OpenStreetMap via `{osmextract}` + Geofabrik PBF** (not `{osmdata}`)
5. **Boundaries** — ring road, city limits, neighbourhoods
6. **Rendering** — `{ggplot2}` + `{tidyterra}` + `{ggspatial}` for north arrow / scale bar

> **OSM data source decision**: `{osmdata}` (Overpass API) is **not used** in this project.
> Multiple rapid queries trigger exponential backoff (60 s × n retries) that makes
> scripted runs hang for 30+ minutes. `{osmextract}` downloads the Alberta Geofabrik
> PBF once (~200 MB) and all subsequent reads are local SQL queries — instant and
> fully reproducible with no network dependency. See `01-data-sources.md` §Decision.

## Quick Reference: Bounding Box for Edmonton

```r
# Ring road + inner suburbs (St. Albert, Sherwood Park, Windermere)
yeg_bbox <- c(
  xmin = -113.80,
  ymin =   53.38,
  xmax = -113.27,
  ymax =   53.72
)
```

CRS: WGS 84 (EPSG:4326) for data acquisition; reproject to NAD83 / Alberta 10-TM
(EPSG:3400) for accurate area/distance calculations and aesthetically correct rendering.
