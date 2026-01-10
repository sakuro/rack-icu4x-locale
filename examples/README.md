# Demo Application

A Sinatra app demonstrating `Rack::ICU4X::Locale` middleware.

## Setup

```bash
cd examples
bundle install
```

## Run

```bash
bundle exec rackup
```

Then open http://localhost:9292

## Features

- Shows detected locales from Accept-Language header
- Cookie-based locale override
- Available locales: en, ja, de, fr

## Testing with curl

```bash
# With Accept-Language header
curl -H "Accept-Language: ja,en;q=0.8" http://localhost:9292

# With cookie
curl -b "locale=de" http://localhost:9292
```
