# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

relaton-cli is a Ruby CLI tool for managing bibliographic references to standards (ISO, IEC, IETF, NIST, etc.). It provides commands to fetch, convert, and organize standards metadata in XML, YAML, BibTeX, and HTML formats. Part of the broader Relaton/Metanorma ecosystem.

## Common Commands

```bash
# Install dependencies
bundle install

# Run all tests
bundle exec rspec

# Run a single test file
bundle exec rspec spec/relaton/cli/command_spec.rb

# Run a specific test by line number
bundle exec rspec spec/relaton/cli/command_spec.rb:42

# Build the gem
bundle exec rake build

# Lint (RuboCop, inherits from Ribose OSS guide)
bundle exec rubocop
bundle exec rubocop -a  # auto-fix
```

## Architecture

### Entry Point & CLI Framework

The executable `exe/relaton` calls `Relaton::Cli.start(ARGV)` which routes to `Relaton::Cli::Command`, a Thor-based command class. Thor handles argument parsing, option definitions, and subcommand routing.

### Command Structure

- `lib/relaton/cli/command.rb` — Main Thor command class with top-level commands (fetch, extract, concatenate, split, yaml2xml, xml2yaml, xml2html, yaml2html, convert, fetch-data)
- `lib/relaton/cli/subcommand_collection.rb` — `relaton collection` subcommands (create, info, list, get, find, fetch, import, export)
- `lib/relaton/cli/subcommand_db.rb` — `relaton db` subcommands (create, mv, clear, fetch, fetch_all, doctype)

### Option Forwarding Pattern

`Command#fetch` and `SubcommandDb#fetch` use the shared `fetch_document` helper (in `Relaton::Cli` private methods at the bottom of `command.rb`). This helper transforms Thor's kebab-case option keys to snake_case symbols via `gsub("-", "_").to_sym` and splats them as `**dup_opts` to `Relaton.db.fetch` / `Relaton.db.fetch_std`. Adding a new Thor option to these commands automatically forwards it to the underlying library with no method changes needed.

`SubcommandCollection#fetch` calls `Relaton.db.fetch` directly (not through `fetch_document`), so new options must be explicitly forwarded there.

Current fetch options that use this pattern: `--no-cache`, `--all-parts`, `--keep-year`, `--publication-date-before`, `--publication-date-after`.

### Core Data Classes

- `lib/relaton/bibdata.rb` — `Relaton::Bibdata` wraps `RelatonBib::BibliographicItem`, adding URL type handling and serialization to XML/YAML/Hash. Uses `method_missing` to delegate to the underlying bibitem.
- `lib/relaton/bibcollection.rb` — `Relaton::Bibcollection` represents a collection of bibliographic items with title/author/doctype metadata. Handles XML/YAML round-tripping.
- `lib/relaton/element_finder.rb` — Mixin providing XPath utilities with namespace handling.

### Converters (Template Method Pattern)

- `lib/relaton/cli/base_convertor.rb` — Abstract base defining the conversion flow (convert_and_write, write_to_file_collection)
- `lib/relaton/cli/xml_convertor.rb` — XML → YAML conversion
- `lib/relaton/cli/yaml_convertor.rb` — YAML → XML conversion (includes processor detection via doctype)
- `lib/relaton/cli/xml_to_html_renderer.rb` — Renders XML/YAML to HTML using Liquid templates from `templates/`

### File Operations

`lib/relaton/cli/relaton_file.rb` — Static methods for extract (pull bibdata from Metanorma XML), concatenate (combine files into a collection), and split (break a collection into individual files).

### Database (Singleton)

`Relaton::Cli::RelatonDb` (in `lib/relaton/cli.rb`) is a Singleton managing a `Relaton::Db` instance. DB path is persisted in `~/.relaton/dbpath`. The `relaton` gem's registry auto-discovers 30+ standard-body processors.

### Processor Detection

`Relaton::Cli.processor(doc)` and `.parse_xml(doc)` detect the correct processor (ISO, IEC, IETF, etc.) from a document's `docidentifier` element type attribute, falling back to prefix matching.

## Test Structure

- `spec/acceptance/` — End-to-end CLI integration tests using `rspec-command`
- `spec/relaton/cli/` — Unit tests for command, converters, subcommands, DB
- `spec/relaton/` — Unit tests for Bibcollection and Bibdata
- `spec/support/` — Test setup: SimpleCov, WebMock, VCR, equivalent-xml matchers
- `spec/fixtures/` and `spec/vcr_cassettes/` — Test data and recorded HTTP responses

Tests use VCR cassettes to replay HTTP interactions with standards registries. WebMock blocks real HTTP requests in tests.

## Key Dependencies

- `relaton ~> 1.20.0` — Core library providing DB, registry, and all standard-body processors
- `thor` / `thor-hollaback` — CLI framework
- `liquid ~> 5` — HTML template rendering
- `nokogiri` (transitive via relaton) — XML parsing

## Ruby Version

Requires Ruby >= 3.0.0 (set in gemspec and `.rubocop.yml`).
