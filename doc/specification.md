# rack-icu4x-locale Specification

## Overview

Rack middleware that generates an array of ICU4X::Locale instances (in preference order) from Accept-Language header and cookies. Provides sophisticated language negotiation using ICU4X 0.8.0's `maximize`/`minimize` methods.

## Dependencies

- Ruby 3.2+
- Rack 3.0+
- icu4x ~> 0.8

## API

### Middleware Configuration

```ruby
use Rack::ICU4X::Locale,
  available_locales: %w[en-US en-GB ja],  # Required: available locales
  cookie: "locale",                        # Optional: cookie name
  strategy: :filtering,                    # Optional: negotiation strategy
  default_locale: "en-US"                  # Optional: default (required for :lookup)
```

### Options

| Option | Required | Default | Description |
|--------|----------|---------|-------------|
| `available_locales` | Yes | - | Array of available locale identifiers |
| `cookie` | No | nil | Cookie name for locale override |
| `strategy` | No | `:filtering` | Negotiation strategy |
| `default_locale` | No | nil | Default locale (required for `:lookup` strategy) |

### Environment Key

`rack.icu4x.locale` - Array of `ICU4X::Locale` instances in preference order

## Locale Detection Priority

1. Cookie (when `cookie` option is set, user's explicit choice)
2. Accept-Language header (sorted by quality value)
3. Default (order of `available_locales`)

## Negotiation Strategies

> **Note:** Examples below show string representations for readability. Actual results are `ICU4X::Locale` instances.

### `:filtering` (default)

Returns all matching available locales in preference order for each requested locale.

```ruby
# available: ["en-US", "en-GB", "ja"]
# request: "en-AU, ja"
# result: ["en-US", "ja"]
```

### `:matching`

Returns unique best matches for each requested locale (no duplicates).

```ruby
# available: ["en", "ja"]
# request: "en-US, en-GB"
# result: ["en"]
```

### `:lookup`

Returns a single best match. Falls back to `default_locale` when no match.

```ruby
# available: ["en", "ja"], default: "en"
# request: "zh-CN"
# result: ["en"]
```

## Script-Safe Matching

Uses ICU4X's `maximize` to infer scripts and prevent matching across different scripts.

### Critical Rule

**Different scripts must NEVER match.**

This avoids politically and culturally sensitive fallbacks.

### Chinese Examples

| Request | Available | Result | Reason |
|---------|-----------|--------|--------|
| zh-TW | zh-CN | No match | Hant ≠ Hans (different scripts) |
| zh-HK | zh-TW | Match | Both Hant (same script) |
| zh | zh-CN | Match | zh → Hans-CN (maximize result) |
| zh-Hans | zh-CN | Match | Same script |

### Serbian Examples

| Request | Available | Result | Reason |
|---------|-----------|--------|--------|
| sr-Latn | sr-Cyrl | No match | Different scripts |
| sr | sr-Cyrl | Match | sr → Cyrl (maximize result) |
| sr | sr-Latn | No match | sr → Cyrl ≠ Latn |

## Matching Algorithm

1. **Exact match**: Language + script + region all match
2. **Language + Script match**: Language and script match (region ignored)
3. **No language-only fallback**: Scripts must always match

```ruby
# ICU4X maximize examples
"en"     → "en-Latn-US"
"zh-CN"  → "zh-Hans-CN"
"zh-TW"  → "zh-Hant-TW"
"ja"     → "ja-Jpan-JP"
"sr"     → "sr-Cyrl-RS"
```

## Accept-Language Parsing

- Format: `ja,en;q=0.9,de;q=0.8`
- Sorted by quality value (descending)
- Preserves full locale string (does not extract language part only)

## References

- [icu4x gem](https://rubygems.org/gems/icu4x)
- [ICU4X LocaleExpander](https://docs.rs/icu_locale/latest/icu_locale/struct.LocaleExpander.html)
- [UTS #35: Likely Subtags](https://unicode.org/reports/tr35/#Likely_Subtags)
- [@fluent/langneg](https://github.com/projectfluent/fluent.js/tree/main/fluent-langneg) - Algorithm reference
- [BCP 47](https://www.rfc-editor.org/info/bcp47) - Language tag specification

## Notes

- Cookie management is the application's responsibility (locale switching actions, etc.)
- Future `rack-icu4x-*` gems may provide additional middleware
