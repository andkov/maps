# nolint start
# AI agents must consult ./analysis/yeg-1/README.md before making changes to this file.
rm(list = ls(all.names = TRUE))
cat("\014")
cat("Working directory: ", getwd())

# ---- load-packages -----------------------------------------------------------
library(magrittr)
library(ggplot2)
library(dplyr)
library(sf)           # vector spatial data
library(terra)        # raster / DEM processing
library(elevatr)      # elevation tile download
library(osmextract)   # Geofabrik PBF — no Overpass API rate limits
library(tidyterra)    # ggplot2 + terra bridge (geom_spatraster)
library(ggspatial)    # north arrow, scale bar

# Source shared map theme
source("scripts/graphing/map-theme.R")

# ---- httpgd (VS Code interactive plots) ------------------------------------
if (interactive() && requireNamespace("httpgd", quietly = TRUE)) {
  tryCatch({
    httpgd::hgd()
    message("httpgd started — open browser to view plots interactively")
  }, error = function(e) message("httpgd unavailable: ", conditionMessage(e)))
}

# ============================================================================
# SECTION 1: DEFINE AREA OF INTEREST
# ============================================================================

# ---- define-bbox -------------------------------------------------------------
# Ring road + inner suburbs (St. Albert, Sherwood Park, Windermere)
# WGS 84 (EPSG:4326) — used for data acquisition
yeg_bbox <- c(xmin = -113.80, ymin = 53.38, xmax = -113.27, ymax = 53.72)

# Convert to sf data frame for elevatr (bare sfc not accepted)
yeg_bbox_sf <- st_as_sf(st_as_sfc(st_bbox(yeg_bbox, crs = st_crs(4326))))

# Target CRS for rendering (NAD83 / Alberta 10-TM Forest)
crs_ab <- 3400

# ============================================================================
# SECTION 2: ELEVATION DATA
# ============================================================================

# ---- download-dem ------------------------------------------------------------
# z = 12 ≈ 19 m/px — good balance of detail and download size for city scale
# Set z = 11 for faster testing, z = 13 for more detail
dem_raw <- elevatr::get_elev_raster(
  locations = yeg_bbox_sf,
  z         = 12,
  src       = "aws"
)
dem <- terra::rast(dem_raw)                    # convert to SpatRaster
dem <- terra::project(dem, paste0("EPSG:", crs_ab))  # reproject

# ---- compute-hillshade -------------------------------------------------------
slope  <- terra::terrain(dem, "slope",  unit = "radians")
aspect <- terra::terrain(dem, "aspect", unit = "radians")
hill   <- terra::shade(slope, aspect, angle = 35, direction = 315)

# ---- extract-contours --------------------------------------------------------
# Contour interval: 10 m; label-worthy breaks every 25 m
contours <- terra::as.contour(dem, nlevels = 30) |>
  sf::st_as_sf() |>
  sf::st_transform(crs_ab)

# Map extent limits (from DEM extent, used in coord_sf)
map_ext <- terra::ext(dem)
xlims   <- c(map_ext$xmin, map_ext$xmax)
ylims   <- c(map_ext$ymin, map_ext$ymax)

# ============================================================================
# SECTION 3: VECTOR FEATURES (OpenStreetMap)
# ============================================================================

# OSM layers are read from the Geofabrik Alberta PBF via osmextract.
# The PBF (~200 MB) is downloaded once and stored in data-public/raw/osm/.
# All layer reads run locally — no Overpass API, no rate limits.
osm_dir  <- "data-public/raw/osm"
options(osmextract.download_directory = osm_dir)

clip_poly <- yeg_bbox_sf |> sf::st_transform(crs_ab)
safe_crop <- function(x, clip) {
  if (is.null(x) || nrow(x) == 0) return(x)
  sf::st_crop(sf::st_make_valid(x), clip)
}

# Ensure both layers of the GeoPackage exist (idempotent)
osmextract::oe_get("Alberta", provider = "geofabrik", layer = "lines",
                   download_only = TRUE, quiet = TRUE, download_directory = osm_dir)
osmextract::oe_get("Alberta", provider = "geofabrik", layer = "multipolygons",
                   download_only = TRUE, quiet = TRUE, download_directory = osm_dir)

pbf_path <- normalizePath(
  list.files(osm_dir, pattern = "alberta.*\\.osm\\.pbf$", full.names = TRUE)[1]
)

read_lines <- function(query) {
  osmextract::oe_read(pbf_path, layer = "lines", query = query,
                      wkt_filter = sf::st_as_text(sf::st_geometry(yeg_bbox_sf)),
                      quiet = TRUE) |>
    sf::st_transform(crs_ab) |> safe_crop(clip_poly)
}
read_polys <- function(query) {
  osmextract::oe_read(pbf_path, layer = "multipolygons", query = query,
                      wkt_filter = sf::st_as_text(sf::st_geometry(yeg_bbox_sf)),
                      quiet = TRUE) |>
    sf::st_transform(crs_ab) |> safe_crop(clip_poly)
}

# ---- osm-rivers --------------------------------------------------------------
rivers <- read_lines(
  "SELECT * FROM lines WHERE waterway IN ('river','stream','canal')")

# ---- osm-water-bodies --------------------------------------------------------
water_polys <- read_polys(
  "SELECT * FROM multipolygons WHERE natural = 'water'")

# ---- osm-parks ---------------------------------------------------------------
parks <- read_polys(
  "SELECT * FROM multipolygons WHERE leisure IN ('park','nature_reserve')")

# ---- osm-green-space ---------------------------------------------------------
green <- read_polys(
  "SELECT * FROM multipolygons WHERE natural IN ('wood','scrub','grassland')")

# ---- osm-roads ---------------------------------------------------------------
roads <- read_lines(
  "SELECT * FROM lines WHERE highway IN ('motorway','trunk','primary','secondary')"
) |>
  dplyr::mutate(
    road_class = dplyr::case_when(
      highway %in% c("motorway", "trunk")       ~ "major",
      highway %in% c("primary", "secondary")    ~ "arterial",
      TRUE                                        ~ "other"
    )
  )

# ============================================================================
# SECTION 4: RENDER MAP
# ============================================================================

# ---- map-g1 ------------------------------------------------------------------
# g1: Hillshade + contours only (terrain layer)

g1 <- ggplot() +
  # Hillshade base
  tidyterra::geom_spatraster(data = hill) +
  scale_fill_gradient(
    low    = "grey15",
    high   = "grey98",
    guide  = "none",
    na.value = "transparent"
  ) +
  # Contour lines
  geom_sf(
    data      = contours,
    colour    = "grey40",
    linewidth = 0.2,
    alpha     = 0.6
  ) +
  coord_sf(crs = crs_ab, xlim = xlims, ylim = ylims, expand = FALSE) +
  theme_map() +
  labs(
    title    = "Edmonton — Terrain",
    subtitle = "Hillshade + 10 m contours  |  DEM: AWS Terrain Tiles z=12",
    caption  = "CRS: NAD83 / Alberta 10-TM (EPSG:3400)"
  )

print(g1)

# ---- map-g2 ------------------------------------------------------------------
# g2: Full layered map — hillshade + water + parks + roads

g2 <- ggplot() +
  # Hillshade
  tidyterra::geom_spatraster(data = hill) +
  scale_fill_gradient(
    low  = "grey15",
    high = "grey98",
    guide = "none",
    na.value = "transparent"
  ) +
  # Green space
  geom_sf(data = green,      fill = "#c8dfc0", colour = NA, alpha = 0.6) +
  geom_sf(data = parks,      fill = "#b5d4a8", colour = NA, alpha = 0.7) +
  # Water
  geom_sf(data = water_polys, fill = color_water, colour = NA) +
  geom_sf(
    data      = rivers,
    colour    = color_water,
    linewidth = 0.5
  ) +
  # Roads
  geom_sf(
    data      = dplyr::filter(roads, road_class == "major"),
    colour    = "#d4945a",
    linewidth = 0.9
  ) +
  geom_sf(
    data      = dplyr::filter(roads, road_class == "arterial"),
    colour    = color_road,
    linewidth = 0.4
  ) +
  # Contours (subtle)
  geom_sf(
    data      = contours,
    colour    = "grey50",
    linewidth = 0.15,
    alpha     = 0.4
  ) +
  # Annotations
  ggspatial::annotation_scale(
    location      = "br",
    unit_category = "metric",
    text_cex      = 0.7
  ) +
  ggspatial::annotation_north_arrow(
    location = "tl",
    style    = ggspatial::north_arrow_minimal(text_size = 8)
  ) +
  coord_sf(crs = crs_ab, xlim = xlims, ylim = ylims, expand = FALSE) +
  theme_map() +
  labs(
    title    = "Edmonton Metropolitan Area",
    subtitle = "Topographic reference map  |  Ring road extent + inner suburbs",
    caption  = paste0(
      "Sources: AWS Terrain Tiles, OpenStreetMap / Geofabrik  |  ",
      "CRS: EPSG:3400"
    )
  )

print(g2)

# ---- save-outputs ------------------------------------------------------------
# Uncomment to save when satisfied with the layout
# ggsave("analysis/yeg-1/yeg-1-terrain.png",  g1, width = 12, height = 10, dpi = 200)
# ggsave("analysis/yeg-1/yeg-1-full.png",     g2, width = 12, height = 10, dpi = 200)

# nolint end
