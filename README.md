# Rack::ICU4X::Locale

Rack middleware for locale detection using ICU4X. Detects user's preferred locales from Accept-Language header and cookies, with sophisticated language negotiation that respects script differences.

## Features

- Parses Accept-Language header with quality values
- Cookie-based locale override
- Script-safe language negotiation (zh-TW won't fallback to zh-CN)
- Three negotiation strategies: `:filtering`, `:matching`, `:lookup`
- Uses ICU4X for accurate locale maximization

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rack-icu4x-locale'
```

And then execute:

```bash
bundle install
```

## Requirements

- Ruby 3.2+
- Rack 3.0+

## Usage

### Basic Usage

```ruby
require 'rack/icu4x/locale'

use Rack::ICU4X::Locale, available_locales: %w[en ja de fr]

run ->(env) {
  locales = env['rack.icu4x.locale']
  [200, {}, ["Detected locales: #{locales.map(&:to_s).join(', ')}"]]
}
```

### With Cookie Support

```ruby
use Rack::ICU4X::Locale,
  available_locales: %w[en ja de fr],
  cookie: 'locale'
```

When a `locale` cookie is present, it takes priority over Accept-Language header.

### Negotiation Strategies

#### `:filtering` (default)

Returns all matching locales in preference order.

```ruby
use Rack::ICU4X::Locale,
  available_locales: %w[en-US en-GB ja],
  strategy: :filtering

# Request: Accept-Language: en-AU, ja
# Result: ["en-US", "ja"]
```

#### `:matching`

Returns unique best matches (no duplicates).

```ruby
use Rack::ICU4X::Locale,
  available_locales: %w[en ja],
  strategy: :matching

# Request: Accept-Language: en-US, en-GB
# Result: ["en"]
```

#### `:lookup`

Returns a single best match, with a required default fallback.

```ruby
use Rack::ICU4X::Locale,
  available_locales: %w[en ja],
  strategy: :lookup,
  default_locale: 'en'

# Request: Accept-Language: zh-CN
# Result: ["en"]
```

### Script-Safe Matching

The middleware uses ICU4X's locale maximization to infer scripts from regions, ensuring politically and culturally sensitive locales are handled correctly:

```ruby
negotiator = Rack::ICU4X::Negotiator.new(%w[zh-CN], strategy: :filtering)

negotiator.negotiate(%w[zh-TW])   # => []  (Traditional won't match Simplified)
negotiator.negotiate(%w[zh-Hans]) # => ["zh-CN"]
negotiator.negotiate(%w[zh])      # => ["zh-CN"]  (bare zh defaults to Hans)
```

## Accessing Detected Locales

The detected locales are stored in `env['rack.icu4x.locale']` as an array of `ICU4X::Locale` objects:

```ruby
run ->(env) {
  locales = env['rack.icu4x.locale']

  primary = locales.first
  puts primary.language  # => "ja"
  puts primary.script    # => "Jpan"
  puts primary.region    # => "JP"

  [200, {}, ["OK"]]
}
```

## Demo Application

See the `examples/` directory for a Sinatra demo app demonstrating all features.

```bash
cd examples
bundle install
bundle exec rackup
```

Then open http://localhost:9292

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sakuro/rack-icu4x-locale.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
