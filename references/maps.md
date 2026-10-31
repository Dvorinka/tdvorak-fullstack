# Map Integrations

Read when adding map components, location UIs, or any geospatial visualization.

## Default: MapCN
**URL:** https://www.mapcn.dev/

Preferred map solution for all projects. Clean embeddable components, no API key friction for basic usage, lightweight integration.

## When to Use
Store/branch locators, contact page maps, route/directions UI, any location-based component.

## Integration
1. Visit https://www.mapcn.dev/ to generate embed or component code.
2. Wrap output in a project-styled container (consistent with `ui-standards.md`).
3. Keep map UI calm and minimal — no unnecessary controls or branding clutter.

## Fallbacks (only if MapCN cannot serve the use case)
- **Leaflet** + OpenStreetMap tiles — fully custom interactive maps.
- **MapLibre GL** — vector tile rendering, heavy interactivity, custom layers, offline tiles, advanced geospatial processing.

Always prefer MapCN first.
