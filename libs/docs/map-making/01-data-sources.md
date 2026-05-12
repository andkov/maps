# Data Sources for Edmonton Maps

Where to get the raw ingredients: elevation, boundaries, roads, rivers, land cover.
Focused on the YEG ring-road extent but applicable to Alberta broadly.

---

## 1. Elevation (DEM)

### AWS Terrain Tiles via `{elevatr}` *(recommended starting point)*

- **Coverage**: Global
- **Resolution**: Variable by zoom level (z = 12 ≈ 19 m/px for YEG scale)
- **Format**: Returned as R raster object (no manual download needed)
- **Cost**: Free, no account
- **Licence**: Mapzen/AWS Terrain Tiles — open, attribution appreciated
- **How**: `elevatr::get_elev_raster(locations = bbox_sf, z = 12)`
- **Notes**: Tiles are mosaicked from multiple sources (SRTM, NED, CDEM). Good
  enough for hillshade and contour generation. Not survey-grade.

### NRCAN Canadian Digital Elevation Model (CDEM)

- **Coverage**: Canada
- **Resolution**: 0.75 arc-second (~20 m) for most of Alberta
- **Format**: GeoTIFF tiles (1° × 1° each)
- **Cost**: Free
- **Licence**: Open Government Licence — Canada
- **Portal**: <https://open.canada.ca/data/en/dataset/7f245e4d-76c2-4caa-951a-45d1d2051333>
- **Direct FTP**: `ftp://ftp.geogratis.gc.ca/pub/nrcan_rncan/elevation/cdem_mnec/`
- **YEG tiles**: You need tiles `083h` and `083i` (NTS map sheet codes for the
  Edmonton area)
- **Notes**: Higher accuracy than AWS tiles but requires manual download and
  mosaic. Use when publication-quality precision matters.

### NRCAN High Resolution DEM (HRDEM) — CanElevation

- **Coverage**: Urban centres and southern Canada (Edmonton covered)
- **Resolution**: 1 m or 2 m (LiDAR-derived)
- **Format**: GeoTIFF
- **Cost**: Free
- **Licence**: Open Government Licence — Canada
- **Portal**: <https://open.canada.ca/data/en/dataset/957782bf-847c-4644-a757-e383c0057995>
- **Notes**: Best available data for Edmonton. LiDAR-derived; shows buildings,
  trees. Large files (multi-GB for city extent). Worth it for high-detail renders.

### SRTM (NASA Shuttle Radar Topography Mission)

- **Coverage**: Global 56°S–60°N
- **Resolution**: 1 arc-second (~30 m)
- **Format**: HGT files, available repackaged as GeoTIFF
- **Cost**: Free
- **Portal**: <https://earthexplorer.usgs.gov/> (requires free account)
  or <https://srtm.csi.cgiar.org/> (no account)
- **Notes**: Older (2000) but well-tested and widely used. Slightly coarser than
  CDEM; similar accuracy for gentle terrain like Edmonton.

---

## 2. Administrative Boundaries

### Statistics Canada — Census Boundaries

- **What**: Province, CMA, census subdivision (municipality), census tract polygons
- **Edmonton CMA**: Includes St. Albert, Sherwood Park, Spruce Grove, etc.
- **Format**: Shapefile or GeoJSON
- **Cost**: Free
- **Licence**: Statistics Canada Open Licence
- **Portal**: <https://www12.statcan.gc.ca/census-recensement/2021/geo/sip-pis/boundary-limites/index2021-eng.cfm>
- **Useful layers**:
  - `lcd_000a21a_e` — Census divisions (county-level)
  - `lcsd000a21a_e` — Census subdivisions (municipalities)
  - `lct_000a21a_e` — Census tracts (neighbourhood-level)
- **R access**: `cancensus` package (see below) or direct download

### `{cancensus}` R Package

- **What**: Programmatic access to Statistics Canada census data + boundaries
- **CRAN**: <https://mountainmath.github.io/cancensus/>
- **Requires**: Free API key from <https://censusmapper.ca/users/sign_up>
- **Example**:

```r
library(cancensus)
# Get Edmonton CMA boundary
edmonton_cma <- get_census(
  dataset = "CA21", regions = list(CMA = "48835"),
  level = "CSD", geo_format = "sf"
)
```

### City of Edmonton Open Data

- **Portal**: <https://data.edmonton.ca/>
- **Useful datasets**:
  - [City Boundary](https://data.edmonton.ca/dataset/City-Boundary/jfvj-x253)
  - [Neighbourhoods](https://data.edmonton.ca/dataset/City-of-Edmonton-Neighbourhoods/65fr-66s6)
  - [Arterial Roadway Network](https://data.edmonton.ca/dataset/Arterial-Roadway-Network/7c49-eejm)
  - [River Valley Parks](https://data.edmonton.ca/dataset/River-Valley-Parks/5cdh-kqhh)
- **Format**: GeoJSON, Shapefile, CSV (geometry)
- **Licence**: Open Government Licence — City of Edmonton

### Alberta Government Open Data

- **Portal**: <https://open.alberta.ca/> and <https://geodiscover.alberta.ca/>
- **Useful layers**:
  - Alberta Municipal Boundaries
  - Alberta Hydrographic Network (rivers, lakes)
  - Alberta Road Network
  - Land use / land cover
- **Access**: Many datasets downloadable directly; some via ArcGIS REST API

---

## Decision: osmextract + Geofabrik over osmdata + Overpass

**Date**: 2026-05-12

### Problem

`{osmdata}` queries the public Overpass API. When multiple queries are fired in
rapid succession (e.g., 5 layers in a script), the server imposes an exponential
backoff — typically 60 s × number of retries, cycling through 20–30 retries before
newly queued requests proceed. In practice this means a 5-layer download script
can hang for **30–60 minutes** before producing any data. Switching Overpass mirrors
(`overpass-api.de` → `overpass.kumi.systems`) did not help; both shared the same
IP-based rate-limit state.

### Decision

All OSM vector data in `analysis/yeg-*/` is acquired via **`{osmextract}` +
Geofabrik Alberta PBF**:

- The Alberta PBF (`~200 MB`) is downloaded once via `oe_get()` and stored in
  `data-public/raw/osm/`.
- All layer reads (`lines`, `multipolygons`) use `oe_read()` with a SQL
  `WHERE` filter and a WKT bounding box — local GDAL reads, no network.
- Re-running the script on a fresh machine requires one download; after that
  it is fully offline.

### Consequences

- `{osmdata}` is **not installed or used** in this project. Do not add it back.
- The Alberta PBF file is large; it is listed in `.gitignore` (not committed).
  Reproducing on a new machine requires running the script once with internet
  access to trigger `oe_get()` download.
- Geofabrik updates Alberta daily; if you need a specific OSM snapshot, archive
  the PBF manually before Geofabrik overwrites it.
- The GeoPackage sidecar files (`geofabrik_alberta-latest.gpkg`) are also large
  and gitignored. They are regenerated automatically on first `oe_get()` call.

### Reproduction on a new machine

```r
# Step 1: install once
install.packages("osmextract")

# Step 2: set download dir and trigger PBF + GeoPackage creation
library(osmextract)
options(osmextract.download_directory = "data-public/raw/osm")
oe_get("Alberta", provider = "geofabrik", layer = "lines",
       download_only = TRUE)
oe_get("Alberta", provider = "geofabrik", layer = "multipolygons",
       download_only = TRUE)

# Step 3: all subsequent yeg-*.R runs read from disk — no internet needed
```

---

## 3. Roads and Transportation

### OpenStreetMap via `{osmdata}` *(recommended for scripted workflows)*

Best for reproducible pipelines — no manual download, queries directly from R.

```r
library(osmdata)

roads <- opq(bbox = c(-113.80, 53.38, -113.27, 53.72)) |>
  add_osm_feature(key = "highway",
                  value = c("motorway", "trunk", "primary", "secondary",
                            "tertiary", "residential")) |>
  osmdata_sf()
```

Key `highway` values for cartographic layering:

| Value | Cartographic role |
|---|---|
| `motorway` | Ring road (Henday / Whitemud) |
| `trunk` | Major connectors (Yellowhead, Gateway) |
| `primary` | Main arterials |
| `secondary` | Secondary arterials |
| `tertiary` | Collector roads |
| `residential` | Local streets (usually omitted at city scale) |

### Geofabrik Alberta Extract *(for bulk/offline use)*

- **Portal**: <https://download.geofabrik.de/north-america/canada/alberta.html>
- **Format**: PBF (OpenStreetMap binary), updated daily
- **Size**: ~200 MB compressed for all of Alberta
- **Use**: Download once, clip to YEG extent with `osmextract` package or
  `osmium` CLI tool
- **When to prefer**: Large area queries that time out with Overpass API

### `{osmextract}` R Package *(recommended for scripted workflows)*

- **CRAN**: <https://docs.ropensci.org/osmextract/>
- **What**: Downloads Geofabrik PBF files and reads them into `sf` objects via GDAL
- **Avoids**: Overpass API rate limits entirely — all queries run locally after first download
- **Alberta PBF**: ~200 MB, downloaded once, stored in `data-public/raw/osm/`
- **Usage pattern used in this project**:

```r
library(osmextract)
options(osmextract.download_directory = "data-public/raw/osm")

# Download Alberta PBF + convert layers (idempotent)
oe_get("Alberta", provider = "geofabrik", layer = "lines",
       download_only = TRUE, quiet = TRUE)
oe_get("Alberta", provider = "geofabrik", layer = "multipolygons",
       download_only = TRUE, quiet = TRUE)

pbf_path <- list.files("data-public/raw/osm",
                       pattern = "alberta.*\\.osm\\.pbf$",
                       full.names = TRUE)[1]

# Read any feature locally — instant, no network
rivers <- oe_read(pbf_path, layer = "lines",
  query = "SELECT * FROM lines WHERE waterway IN ('river','stream','canal')",
  wkt_filter = st_as_text(st_geometry(bbox_sf)), quiet = TRUE)
```

---

## 4. Water Features

### OpenStreetMap (see above)

Primary source for rivers, streams, lakes for a map at city scale.

```r
water_lines <- opq(bbox = yeg_bb) |>
  add_osm_feature(key = "waterway",
                  value = c("river", "stream", "canal")) |>
  osmdata_sf()

water_polys <- opq(bbox = yeg_bb) |>
  add_osm_feature(key = "natural", value = "water") |>
  osmdata_sf()
```

Note: The North Saskatchewan River and its valley are well-mapped in OSM.

### NRCAN National Hydro Network (NHN)

- **Portal**: <https://open.canada.ca/data/en/dataset/a4b190fe-e090-4e6d-881e-b87956c07977>
- **Format**: GeoPackage or Shapefile by watershed
- **Drainage area for YEG**: `08HA` (North Saskatchewan River basin)
- **When to prefer**: When OSM water data is incomplete or you need official
  waterbody classifications

---

## 5. Land Cover and Green Space

### OpenStreetMap Leisure / Natural Tags

For parks, golf courses, nature reserves, wooded areas at city scale.

```r
green <- opq(bbox = yeg_bb) |>
  add_osm_feature(key = "leisure",
                  value = c("park", "nature_reserve", "golf_course")) |>
  osmdata_sf()

forest <- opq(bbox = yeg_bb) |>
  add_osm_feature(key = "natural", value = c("wood", "scrub", "grassland")) |>
  osmdata_sf()
```

### AAFC Annual Crop Inventory

- **Coverage**: Canada (annual raster)
- **Resolution**: 30 m
- **Format**: GeoTIFF
- **Portal**: <https://open.canada.ca/data/en/dataset/ba2645d5-4458-414d-b196-6303ac06c1c9>
- **Use**: Broad land-cover classification (cropland, urban, water, forest)
  for regional context maps

---

## 6. Basemap Tiles (for QC and interactive preview)

Not used in the final static map, but useful for inspecting data during development.

### `{maptiles}` R Package

- **CRAN**: <https://riatelab.github.io/maptiles/>
- **What**: Downloads raster basemap tiles (OpenStreetMap, CartoDB, Stamen, Esri)
  as `SpatRaster` for use with `terra` / `ggplot2`

### `{tmap}` Interactive Mode

```r
library(tmap)
tmap_mode("view")  # opens interactive Leaflet map in RStudio viewer
tm_shape(rivers) + tm_lines()
```

---

## Summary: Recommended Acquisition Sequence for YEG-1

```
Step 1  Elevation       elevatr::get_elev_raster()  z = 12
Step 2  City boundary   City of Edmonton Open Data  (manual download once)
Step 3  Ring road       osmdata — highway=motorway/trunk
Step 4  Rivers          osmdata — waterway=river/stream + natural=water
Step 5  Parks           osmdata — leisure=park + natural=wood
Step 6  Neighbourhoods  Statistics Canada CSD / cancensus (optional)
```

Store downloads in:

- `data-public/raw/nrcan/` — elevation GeoTIFFs
- `data-public/raw/edmonton/` — City of Edmonton Open Data
- `data-public/raw/osm/` — cached OSM extracts (if using Geofabrik PBF)
- `data-public/raw/alberta-gov/` — provincial datasets

OSM data fetched live via `{osmdata}` does not need to be stored unless you
want reproducibility against a specific OSM snapshot.
