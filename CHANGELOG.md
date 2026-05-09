## [Unreleased]

### Changed

- Collect matches from all detectors instead of stopping at first match (#16)

## [0.6.0] - 2026-05-08

### Changed

- Raise minimum Ruby version requirement to 3.3

## [0.5.0] - 2026-01-11

### Added

- Pluggable detector system for locale sources (#10)
- Locale detection from query parameters, cookies, and Accept-Language header
- Script-safe language negotiation using ICU4X's maximize
- Sinatra demo application in `examples/`
