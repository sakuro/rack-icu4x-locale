# rack-icu4x-locale Specification

## Overview

Rack middleware that generates an array of ICU4X::Locale instances (in preference order) from various sources (query parameters, cookies, Accept-Language header). Provides script-safe language negotiation using ICU4X's `maximize` method.

## Dependencies

- Ruby 3.2+
- Rack 3.0+
- icu4x ~> 0.8

## API

### Middleware Configuration

```ruby
use Rack::ICU4X::Locale,
  from: %w[en-US en-GB ja],                              # Required: available locales
  detectors: [{query: "lang"}, {cookie: "locale"}, :header],  # Optional: detection sources
  default: "en"                                          # Optional: fallback locale
```

### Options

| Option | Required | Default | Description |
|--------|----------|---------|-------------|
| `from` | Yes | - | Array of available locale identifiers (String or ICU4X::Locale) |
| `detectors` | No | `[:header]` | Array of detector specifications (see below) |
| `default` | No | nil | Fallback locale when no match is found (String or ICU4X::Locale) |

### Detector Specifications

Detectors are tried in order. The first detector that returns a locale matching an available locale wins.

| Format | Example | Description |
|--------|---------|-------------|
| Symbol | `:header` | Accept-Language header detector |
| Symbol | `:cookie` | Cookie detector (default name: `"locale"`) |
| Symbol | `:query` | Query detector (default param: `"locale"`) |
| Hash | `{cookie: "user_locale"}` | Cookie detector with custom cookie name |
| Hash | `{query: "lang"}` | Query detector with custom parameter name |
| Proc | `->(env) { env["rack.session"]&.[]("locale") }` | Custom detection logic |
| Callable | Any object responding to `#call(env)` | Custom detector object |

### Built-in Detectors

| Class | Symbol | Default Argument | Description |
|-------|--------|------------------|-------------|
| `Detector::Header` | `:header` | - | Accept-Language header |
| `Detector::Cookie` | `:cookie` | `"locale"` | Cookie value |
| `Detector::Query` | `:query` | `"locale"` | Query string parameter |

### Detector Return Values

All detectors must return one of:
- `String` - Single locale (e.g., `"ja"`)
- `Array<String>` - Multiple locales in preference order (e.g., `["ja", "en"]`)
- `nil` - No locale detected (try next detector)

### Environment Key

`rack.icu4x.locale` - Array of `ICU4X::Locale` instances in preference order

## Locale Detection Flow

1. Iterate through detectors in order
2. For each detector, get candidate locale(s)
3. Negotiate candidates against available locales
4. Return first successful match
5. If no match found, return `[default]` if set, otherwise `[]`

## Language Negotiation

> **Note:** Examples below show string representations for readability. Actual results are `ICU4X::Locale` instances.

Returns all matching available locales in preference order:

```ruby
# available: ["en-US", "en-GB", "ja"]
# request: "en-AU, ja"
# result: ["en-US", "ja"]
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

## Error Handling

### Invalid Locale Strings

When a locale string cannot be parsed (e.g., typos, malformed values):

- The invalid locale is skipped
- A warning is logged to `rack.logger` (if available) or `rack.errors`
- Processing continues with remaining locales

Example: `Accept-Language: invlaid, ja` → `ja` is matched, `invlaid` is logged and skipped.

## References

- [icu4x gem](https://rubygems.org/gems/icu4x)
- [ICU4X LocaleExpander](https://docs.rs/icu_locale/latest/icu_locale/struct.LocaleExpander.html)
- [UTS #35: Likely Subtags](https://unicode.org/reports/tr35/#Likely_Subtags)
- [BCP 47](https://www.rfc-editor.org/info/bcp47) - Language tag specification

## Notes

- Cookie/session management is the application's responsibility (locale switching actions, etc.)
- Use `default` option or handle empty results with application fallback logic
