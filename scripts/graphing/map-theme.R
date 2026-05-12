# map-theme.R
# Shared map style definitions for the maps project.
# Source this file at the top of any map rendering script.

library(ggplot2)

# ── Palettes ──────────────────────────────────────────────────────────────────

# Sequential palette for choropleth maps (light → dark)
palette_sequential <- function(n) {
  colorRampPalette(c("#f7fbff", "#08306b"))(n)  # Blues (ColorBrewer)
}

# Diverging palette centered on zero / midpoint
palette_diverging <- function(n) {
  colorRampPalette(c("#d73027", "#f7f7f7", "#1a6dbf"))(n)
}

# Qualitative palette for categorical layers (max ~8 classes)
palette_qualitative <- c(
  "#4e79a7", "#f28e2b", "#59a14f", "#e15759",
  "#76b7b2", "#edc948", "#b07aa1", "#ff9da7"
)

# ── Water / land background colors ────────────────────────────────────────────

color_water    <- "#d6e8f5"
color_land     <- "#f5f0e8"
color_border   <- "#b0a090"
color_road     <- "#d4c9b8"

# ── ggplot2 map theme ─────────────────────────────────────────────────────────

theme_map <- function(base_size = 11, base_family = "") {
  theme_void(base_size = base_size, base_family = base_family) +
    theme(
      # Titles
      plot.title    = element_text(face = "bold", size = base_size * 1.4, hjust = 0),
      plot.subtitle = element_text(size = base_size, hjust = 0, color = "#555555"),
      plot.caption  = element_text(size = base_size * 0.75, hjust = 1, color = "#888888"),
      # Legend
      legend.position   = "right",
      legend.title      = element_text(size = base_size * 0.9, face = "bold"),
      legend.text       = element_text(size = base_size * 0.8),
      legend.key.height = unit(0.6, "cm"),
      legend.key.width  = unit(0.3, "cm"),
      # Margins
      plot.margin = margin(12, 12, 12, 12)
    )
}

# ── tmap defaults (call once per session if using tmap) ──────────────────────

# Uncomment and run if using tmap:
# library(tmap)
# tmap_options(
#   bg.color      = color_water,
#   frame         = FALSE,
#   fontfamily    = "sans",
#   legend.outside = TRUE
# )

# ── CRS constants ─────────────────────────────────────────────────────────────

CRS_WGS84         <- 4326   # Geographic; raw downloads
CRS_ALBERTA_10TM  <- 3400   # NAD83 / Alberta 10-TM; provincial maps
CRS_CANADA_LAEA   <- 3347   # Statistics Canada Lambert; national maps
CRS_WEB_MERCATOR  <- 3857   # Web tiles overlay only

# ── Export helper ─────────────────────────────────────────────────────────────

#' Save a finished map to data-public/derived/maps/
#' @param plot   A ggplot object
#' @param name   File base name (no extension), e.g. "edmonton-parks-2024"
#' @param width  Width in inches (default 10)
#' @param height Height in inches (default 8)
#' @param dpi    Resolution (default 300 for print quality)
save_map <- function(plot, name, width = 10, height = 8, dpi = 300) {
  out_dir <- here::here("data-public", "derived", "maps")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  png_path <- file.path(out_dir, paste0(name, ".png"))
  pdf_path <- file.path(out_dir, paste0(name, ".pdf"))
  ggplot2::ggsave(png_path, plot, width = width, height = height, dpi = dpi)
  ggplot2::ggsave(pdf_path, plot, width = width, height = height)
  message("Saved: ", png_path)
  invisible(png_path)
}
