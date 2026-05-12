# Glossary

Core cartographic and project terms for standardizing communication.

---

## Spatial Data Concepts

### CRS (Coordinate Reference System)

The mathematical framework defining how coordinates map to real-world locations. Every spatial layer must have an explicit CRS. Common choices in this project:

- **EPSG:4326** — WGS84, geographic (latitude/longitude). Used for raw downloads.
- **EPSG:3400** — NAD83 / Alberta 10-TM. Preferred for provincial-scale Alberta maps.
- **EPSG:3857** — Web Mercator. Used only when overlaying web tile sources.
- **EPSG:3347** — Statistics Canada Lambert. Used for national-scale Canadian maps.

### Vector Data

Spatial data represented as points, lines, or polygons with associated attributes. Stored as `.gpkg` (GeoPackage) or `.shp` (Shapefile). Formats used in this project: GeoPackage (preferred), GeoJSON (interchange), Shapefile (legacy sources).

### Raster Data

Spatial data represented as a grid of cells (pixels), each holding a value (elevation, color, etc.). Common sources: satellite imagery, DEM (Digital Elevation Models), aerial photography. Stored as `.tif` (GeoTIFF).

### DEM (Digital Elevation Model)

A raster grid encoding terrain elevation. Used for hillshading, terrain context, and hydrological analysis. NRCan provides DEMs for Canada at various resolutions.

### Feature

A single spatial object — one polygon, one point, one line — with its associated attribute data.

### Layer

A collection of features of the same geometry type (all polygons, all points, etc.) representing one thematic topic (e.g., "Edmonton neighborhoods", "Alberta rivers").

---

## Map Types

### Choropleth Map

A map where regions (polygons) are shaded according to a data value. Requires careful choice of classification scheme (jenks, quantile, equal interval) and a perceptually appropriate color palette.

### Point Map

A map displaying discrete locations as symbols. Used for places, events, addresses, observations. Symbol size, color, and shape encode additional dimensions.

### Reference Map

A map whose primary purpose is orientation — showing roads, place names, boundaries — rather than communicating a specific data variable.

### Basemap

A background map layer providing geographic context (streets, terrain, coastlines) over which thematic data is drawn. Can be raster tiles or a minimalist vector layer.

### Hillshade

A raster layer simulating terrain shadow from a light source. Adds depth and topographic context to maps without distracting from the thematic content.

---

## Workflow Terms

### Raw Layer

Any spatial file downloaded directly from a source portal, unmodified. Stored in `data-public/raw/` or `data-private/raw/`. Never edited in place.

### Processed Layer

A spatial file that has been reprojected, clipped, cleaned, or joined. Stored in `data-public/derived/`. Produced by a processing script that is fully reproducible.

### Map Script

An R or Python script that ingests processed layers and produces a finished map image. Lives in `analysis/<map-name>/`.

### Map Theme

A reusable ggplot2/tmap style definition (fonts, background color, grid visibility, legend placement). Defined in `scripts/graphing/map-theme.R`.

### Scale Family

A group of maps sharing the same geographic extent and CRS — e.g., all "Edmonton city-scale" maps or all "Alberta provincial-scale" maps. Sharing a scale family enables consistent style and direct visual comparison.

---

## Storage Folders

### `data-public/raw/`

Immutable raw inputs from open-data sources. Organized by provider (e.g., `alberta-gov/`, `edmonton/`, `nrcan/`).

### `data-public/derived/`

Processed, analysis-ready spatial layers and finished map exports. Organized by theme or map name.

### `data-private/raw/` / `data-private/derived/`

Licensed or sensitive spatial data not suitable for public sharing.

### `analysis/<map-name>/`

One folder per map project. Contains the rendering script(s), a README, and any map-specific notes.

---

## Documentation Files

### INPUT-manifest

`data-public/metadata/INPUT-manifest.md` — registry of all raw data sources. Each entry records: source name, URL, retrieval date, license, CRS, and file location.

### CACHE-manifest

`data-public/metadata/CACHE-manifest.md` — registry of processed/derived layers. Each entry records: input source, processing script, output file, CRS, and intended use.

---

## General Terms

### Artifact

Any generated output (map image, processed layer, report) subject to version control or archival.

### Persona

A role-specific instruction set shaping AI assistant behavior within this project.

### Memory Entry

A logged decision or observation stored in `ai/memory/memory-human.md`.

---

*Expand as new data sources, projections, and map families are established.*