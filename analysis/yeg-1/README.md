# YEG-1: Topographic Map of Edmonton

Layered static topographic map of Edmonton and inner suburbs (ring road extent +
St. Albert, Sherwood Park, Windermere).

## Map Objectives

Produce a publication-quality static PNG/PDF with these layers, bottom to top:

1. **Hillshade** — terrain texture derived from a DEM
2. **Elevation colour ramp** — blended under the hillshade for depth
3. **Contour lines** — 10 m interval, labelled at 25 m
4. **Water** — North Saskatchewan River, tributaries, lakes
5. **Green space** — parks, river valley, wooded areas
6. **Roads** — ring road, arterials (no residential clutter)
7. **Labels** — key district names, river label, ring road label

## Files

| File | Role |
|---|---|
| `yeg-1.R` | Data acquisition, processing, all ggplot2 code |
| `yeg-1.qmd` | Quarto report: rendered map + methodology notes |

## Bounding Box

```r
yeg_bbox <- c(xmin = -113.80, ymin = 53.38, xmax = -113.27, ymax = 53.72)
```

CRS for rendering: **EPSG:3400** (NAD83 / Alberta 10-TM Forest)

## Data Sources

| Layer | Source | Method |
|---|---|---|
| Elevation | AWS Terrain Tiles | `elevatr::get_elev_raster()` |
| Rivers / lakes | OpenStreetMap | `osmdata::opq()` |
| Parks | OpenStreetMap | `osmdata::opq()` |
| Roads | OpenStreetMap | `osmdata::opq()` |
| City boundary | City of Edmonton Open Data | manual download → `data-public/raw/edmonton/` |

## Reference

- Package landscape: [libs/docs/map-making/00-r-packages-landscape.md](../../libs/docs/map-making/00-r-packages-landscape.md)
- Data sources: [libs/docs/map-making/01-data-sources.md](../../libs/docs/map-making/01-data-sources.md)
