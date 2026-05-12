# R Spatial Package Landscape

A practical survey of the R packages used in static topographic map-making.
Organized by role in the pipeline, not alphabetically.

---

## 1. Foundation: Vector Data (`{sf}`)

**Package**: `sf` (Simple Features for R)
**CRAN**: <https://r-spatial.github.io/sf/>

The single most important spatial package in R. Nearly everything else either
depends on it or integrates with it.

### What it does

- Represents geographic features (points, lines, polygons) as ordinary data frames
  where one column holds the geometry (`sfc` list-column).
- Reads/writes all standard vector formats: GeoJSON, Shapefile, GeoPackage, KML,
  PostGIS, etc. via GDAL.
- Coordinate reference system (CRS) management: set, inspect, and reproject with
  `st_crs()` / `st_transform()`.
- Spatial operations: `st_intersection()`, `st_buffer()`, `st_union()`,
  `st_bbox()`, `st_crop()`, `st_distance()`, etc.

### Why you need it

Every vector layer in a map — roads, rivers, city boundaries, parks — lives in an
`sf` object. `ggplot2::geom_sf()` renders `sf` objects directly, which makes the
ggplot2 → sf pipeline essentially frictionless.

### Minimal example

```r
library(sf)
library(ggplot2)

# Load a polygon from a GeoJSON file
boundary <- st_read("data-public/raw/edmonton/city-boundary.geojson")

# Reproject to Alberta 10-TM (better for local work)
boundary_ab <- st_transform(boundary, crs = 3400)

ggplot(boundary_ab) +
  geom_sf(fill = "#f5f0e8", colour = "grey40") +
  theme_void()
```

---

## 2. Foundation: Raster Data (`{terra}`)

**Package**: `terra`
**CRAN**: <https://rspatial.github.io/terra/>

The modern replacement for the older `{raster}` package. Handles gridded
(raster) data: elevation models, satellite imagery, land-cover grids.

### What it does

- `SpatRaster` objects: single or multi-layer rasters (think: matrix + CRS + extent).
- Read/write GeoTIFF and many other formats.
- Raster math, resampling, reprojection, masking, and cropping.
- Key elevation workflows:
  - `terra::terrain()` — computes slope, aspect from a DEM.
  - `terra::shade()` — creates a hillshade raster from slope + aspect.
  - `terra::as.contour()` — extracts contour lines as an `sf` object.

### Why you need it

Elevation data arrives as raster (GeoTIFF). All DEM processing lives here.

### Minimal example

```r
library(terra)

dem <- rast("data-public/raw/nrcan/dem_yeg.tif")

# Compute hillshade
slope  <- terrain(dem, "slope",  unit = "radians")
aspect <- terrain(dem, "aspect", unit = "radians")
hill   <- shade(slope, aspect, angle = 35, direction = 315)

# Extract 50 m contour lines (returns sf object)
contours <- as.contour(dem, nlevels = 20) |> st_as_sf()
```

---

## 3. Elevation Data Acquisition (`{elevatr}`)

**Package**: `elevatr`
**CRAN**: <https://github.com/jhollist/elevatr>

Downloads elevation tiles from the AWS Terrain Tiles service (global, free, no
account needed) for any bounding box or set of points.

### What it does

- `get_elev_raster()` — returns a `RasterLayer` (or `SpatRaster` with `src = "aws"`).
- Resolution controlled by `z` zoom level (z = 10 ≈ 76 m/px; z = 12 ≈ 19 m/px;
  z = 14 ≈ 5 m/px). Higher z = more detail = bigger download.
- Works from a bounding box `sf` object or a data frame of lat/lon points.

### Why you need it

The easiest, most reproducible way to get elevation data. No manual downloading or
account setup. Downloads are ~10 MB for a city-scale z = 12 tile.

### Recommended zoom levels for YEG

| z  | Resolution | Use case |
|----|------------|----------|
| 10 | ~76 m/px  | Regional overview |
| 11 | ~38 m/px  | City-scale |
| 12 | ~19 m/px  | **Recommended for YEG ring-road extent** |
| 13 | ~10 m/px  | Neighbourhood detail |
| 14 | ~5 m/px   | Street-level (large file) |

### Minimal example

```r
library(elevatr)
library(sf)
library(terra)

# Define area of interest as an sf bbox
bbox_sf <- st_as_sfc(
  st_bbox(c(xmin = -113.80, ymin = 53.38, xmax = -113.27, ymax = 53.72),
          crs = st_crs(4326))
)

dem_raw <- get_elev_raster(locations = bbox_sf, z = 12, src = "aws")
dem     <- rast(dem_raw)  # convert to terra SpatRaster
```

---

## 4. OpenStreetMap Vector Data (`{osmdata}`)

**Package**: `osmdata`
**CRAN**: <https://docs.ropensci.org/osmdata/>

Queries the OpenStreetMap Overpass API and returns spatial data as `sf` objects.
No shapefiles to download manually.

### What it does

- Build queries by bounding box + feature tag (e.g., `highway`, `waterway`,
  `leisure`, `natural`).
- Returns an `osmdata` list: `$osm_points`, `$osm_lines`, `$osm_polygons`,
  `$osm_multipolygons`.
- Full OSM tag vocabulary at <https://wiki.openstreetmap.org/wiki/Map_features>.

### Key feature tags for a topographic map

| Tag key | Values | Layer |
|---|---|---|
| `waterway` | `river`, `stream`, `canal` | Rivers |
| `natural` | `water` | Lakes / reservoirs |
| `leisure` | `park`, `nature_reserve` | Parks |
| `natural` | `wood`, `scrub` | Green space |
| `highway` | `motorway`, `primary`, `secondary` | Roads |
| `boundary` | `administrative` + `admin_level=8` | City limits |

### Minimal example

```r
library(osmdata)
library(sf)

yeg_bb <- c(-113.80, 53.38, -113.27, 53.72)

rivers <- opq(bbox = yeg_bb) |>
  add_osm_feature(key = "waterway", value = c("river", "stream")) |>
  osmdata_sf() |>
  (\(x) x$osm_lines)()

parks <- opq(bbox = yeg_bb) |>
  add_osm_feature(key = "leisure", value = "park") |>
  osmdata_sf() |>
  (\(x) x$osm_polygons)()
```

> **Note**: Overpass queries time out for very large areas. For Alberta-scale
> downloads, prefer the Geofabrik PBF approach (see data-sources guide).

---

## 5. ggplot2 Integration: Rasters (`{tidyterra}`)

**Package**: `tidyterra`
**CRAN**: <https://dieghernan.github.io/tidyterra/>

Bridges `terra` `SpatRaster` objects and `ggplot2`. Without it, you must manually
convert rasters to data frames before plotting.

### What it does

- `geom_spatraster()` — renders a `SpatRaster` directly in a ggplot.
- `geom_spatraster_contour()` — contour lines from a raster in one call.
- Supports `scale_fill_*` for controlling hillshade / elevation color ramps.

### Minimal example

```r
library(tidyterra)
library(ggplot2)

ggplot() +
  geom_spatraster(data = hill, aes(fill = hillshade)) +
  scale_fill_gradient(low = "grey20", high = "grey95", guide = "none") +
  geom_spatraster_contour(data = dem, breaks = seq(620, 720, by = 10),
                          colour = "grey50", linewidth = 0.25) +
  theme_void()
```

---

## 6. Map Annotations (`{ggspatial}`)

**Package**: `ggspatial`
**CRAN**: <https://paleolimbot.github.io/ggspatial/>

Adds cartographic annotations to ggplot2 maps.

### What it does

- `annotation_north_arrow()` — adds a north arrow with style control.
- `annotation_scale()` — adds a scale bar (auto-calculates from CRS units).
- `layer_spatial()` — plots spatial objects as ggplot layers.

### Minimal example

```r
library(ggspatial)

ggplot() +
  geom_sf(data = boundary) +
  annotation_scale(location = "br", unit_category = "metric") +
  annotation_north_arrow(location = "tl", style = north_arrow_minimal())
```

---

## 7. Alternative Rendering (`{tmap}`)

**Package**: `tmap`
**CRAN**: <https://r-tmap.github.io/tmap/>

An alternative to ggplot2 for maps that follows a "grammar of map layers"
similar to ggplot2 but map-native. Supports both static (`tmap_mode("plot")`)
and interactive (`tmap_mode("view")`) output from the same code.

### When to prefer tmap over ggplot2

- You want a quick interactive preview to inspect data before finalising a static map.
- Faceted maps with `tm_facets()` are simpler than ggplot2 faceting for spatial data.
- You need built-in basemap tiles (OpenStreetMap, Stamen, etc.) without extra packages.

### Minimal example

```r
library(tmap)
tmap_mode("view")  # switch to "plot" for static

tm_shape(boundary) +
  tm_polygons(col = "#f5f0e8", border.col = "grey40") +
tm_shape(rivers) +
  tm_lines(col = "#6baed6", lwd = 1.5)
```

---

## 8. Advanced: 3D Renders (`{rayshader}`)

**Package**: `rayshader`
**CRAN**: <https://www.rayshader.com/>

Converts elevation rasters into photorealistic 3D hillshades and 3D renders.
Computationally heavy; outputs PNG / interactive 3D widget.

### When to use

- Feature maps for presentations or publications that benefit from dramatic terrain
  visualisation.
- Not for routine analysis maps.

---

## Decision Guide: Which Packages for YEG-1?

```
Elevation data   →  {elevatr}  (download)  +  {terra}  (process)
Hillshade        →  terra::shade()
Contour lines    →  terra::as.contour()  →  {sf} object
Physical layers  →  {osmdata}  (rivers, parks, roads)
Rendering        →  {ggplot2}  +  {tidyterra}  +  {ggspatial}
Interactive QC   →  {tmap}  (optional, for inspection)
```

All packages are on CRAN. Install once with:

```r
install.packages(c("sf", "terra", "elevatr", "osmdata",
                   "tidyterra", "ggspatial", "tmap"))
```
