# Rack::ICU4X::Locale

Rack middleware for locale detection using ICU4X. Detects user's preferred locales from various sources (query parameters, cookies, Accept-Language header), with script-safe language negotiation.

## Installation

```ruby
gem 'rack-icu4x-locale'
```

## Requirements

- Ruby 3.2+
- Rack 3.0+

## Usage

### Basic (Accept-Language header only)

```ruby
use Rack::ICU4X::Locale, from: %w[en ja de fr]

run ->(env) {
  locales = env["rack.icu4x.locale"]
  [200, {}, ["Locale: #{locales.first}"]]
}
```

### With Multiple Detectors

```ruby
use Rack::ICU4X::Locale,
  from: %w[en ja de fr],
  detectors: [
    {query: "lang"},      # ?lang=ja
    {cookie: "locale"},   # Cookie: locale=ja
    :header               # Accept-Language header
  ],
  default: "en"           # optional: fallback locale when no match
```

### With Custom Detector

```ruby
use Rack::ICU4X::Locale,
  from: %w[en ja de fr],
  detectors: [
    ->(env) { env["rack.session"]&.[]("locale") },
    :header
  ]
```

## Detector Types

| Type | Example | Description |
|------|---------|-------------|
| `:header` | `Accept-Language: ja` | Accept-Language header |
| `{cookie: "name"}` | `Cookie: name=ja` | Cookie value |
| `{query: "param"}` | `?param=ja` | Query string parameter |
| `Proc` | `->(env) { ... }` | Custom detection logic |

## Documentation

See [doc/specification.md](doc/specification.md) for detailed specification.

## Demo

```bash
cd examples
bundle install
bundle exec rackup
```

Open http://localhost:9292

## License

MIT License. See [LICENSE.txt](LICENSE.txt).
