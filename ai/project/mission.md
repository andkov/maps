# Project Mission

Making beautiful maps of the places I find beautiful.

## Purpose

A personal cartography studio for exploring and visualizing places across multiple scales — from city blocks in Edmonton to provincial landscapes in Alberta to national patterns across Canada. The goal is equal parts aesthetic and analytical: maps that are worth printing and hanging, and maps that deepen understanding of place.

## Objectives

- Build a reproducible workflow for acquiring, processing, and rendering geographic data.
- Develop a personal library of map styles, projections, and color palettes in R (sf, ggplot2, tmap) and Python (geopandas, matplotlib).
- Create print-quality static maps and point-location visualizations drawing from authoritative open-data sources.
- Integrate raster/satellite imagery where it adds texture and context.
- Maintain a growing collection of finished maps organized by theme and scale.

## Data Sources

- Alberta government open data (boundaries, infrastructure, land use)
- City of Edmonton open data (neighborhoods, addresses, transit, parks)
- Natural Resources Canada (terrain, hydrology, elevation models)
- OpenStreetMap (as supplemental street/feature data)

## Success Metrics

- Each map is renderable from a single script with no manual steps.
- Raw source files are clearly separated from processed/derived layers.
- Finished map outputs live in `data-public/derived/` with documented provenance.
- New map ideas can be scaffolded in under 15 minutes using existing style templates.

## Non-Goals

- Database-driven ETL pipelines (Ellis/Ferry patterns).
- Statistical modeling or causal inference.
- Interactive web deployment (leaflet/Mapbox) — for now.

## Stakeholders

- Me: personal enrichment, aesthetic curiosity, sense of place.