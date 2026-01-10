# rack-icu4x-locale Specification

## Overview

Rack middleware that generates an array of ICU4X::Locale instances (in preference order) from Accept-Language header and cookies. Provides script-safe language negotiation using ICU4X's `maximize` method.

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
  default: "en"                            # Optional: fallback locale
```

### Options

| Option | Required | Default | Description |
|--------|----------|---------|-------------|
| `available_locales` | Yes | - | Array of available locale identifiers (String or ICU4X::Locale) |
| `cookie` | No | nil | Cookie name for locale override |
| `default` | No | nil | Fallback locale when no match is found (String or ICU4X::Locale) |

### Environment Key

`rack.icu4x.locale` - Array of `ICU4X::Locale` instances in preference order

## Locale Detection Priority

1. Cookie (when `cookie` option is set, user's explicit choice)
2. Accept-Language header (sorted by quality value)

If no match is found and no `default` is set, an empty array is returned. Use the `default` option or handle empty results with application fallback logic.

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

## References

- [icu4x gem](https://rubygems.org/gems/icu4x)
- [ICU4X LocaleExpander](https://docs.rs/icu_locale/latest/icu_locale/struct.LocaleExpander.html)
- [UTS #35: Likely Subtags](https://unicode.org/reports/tr35/#Likely_Subtags)
- [BCP 47](https://www.rfc-editor.org/info/bcp47) - Language tag specification

## Notes

- Cookie management is the application's responsibility (locale switching actions, etc.)
- Use `default` option or handle empty results with application fallback logic
