# rack-icu4x-locale - Code Instructions for AI Coding Agents

## What is rack-icu4x-locale?

Rack middleware for locale detection using ICU4X. Detects user's preferred locales from Accept-Language header and cookies, with script-safe language negotiation.

## Documentation Map

| Purpose | Document |
|---------|----------|
| Project overview & usage | [README.md](README.md) |
| Detailed specification | [doc/specification.md](doc/specification.md) |
| Demo application | [examples/README.md](examples/README.md) |

## Core Principles

### Language Policy

- **Code & documentation**: English
- **Commit messages**: English with `:emoji:` notation (e.g., `:sparkles:`, `:bug:`)
- **Chat**: Use the user's language

### Terminology

- **ICU4X**: Unicode org's internationalization project
- **`icu4x`**: Ruby gem providing ICU4X bindings
- **Script-safe matching**: Locale matching that respects script differences (e.g., zh-TW won't match zh-CN)

### Skills

- Explore available skills and use them proactively when applicable

## Development Setup

```bash
bin/setup  # Installs dependencies
```

## Development Commands

```bash
bundle exec rake            # Run all checks (spec + rubocop)
bundle exec rspec           # Run tests
bundle exec rubocop -a      # Auto-fix style
bin/console                 # Interactive console
```

## Configuration

- **Ruby version**: >= 3.2
- **Rack version**: >= 3.0
- **RuboCop style**: Double quotes for strings
- **Release**: Automated via CI workflow

See [doc/specification.md](doc/specification.md) for detailed specification.
