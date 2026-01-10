# Rack::ICU4X::Locale

Rack middleware for locale detection using ICU4X. Detects user's preferred locales from Accept-Language header and cookies, with script-safe language negotiation.

## Installation

```ruby
gem 'rack-icu4x-locale'
```

## Requirements

- Ruby 3.2+
- Rack 3.0+

## Usage

```ruby
use Rack::ICU4X::Locale,
  available_locales: %w[en ja de fr],
  cookie: "locale",           # optional: cookie name for locale override
  default: "en"               # optional: fallback locale when no match

run ->(env) {
  locales = env["rack.icu4x.locale"]
  [200, {}, ["Locale: #{locales.first}"]]
}
```

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
