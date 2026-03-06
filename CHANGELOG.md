# Changelog

## [0.4.0] - 2026-03-06

### Changed
- **Architecture: shared `biblatex-apa-swift` module** — Extracted 6 core files (`BibParser`, `BibWriter`, `BibValidator`, `APADataModel`, `APARuleEngine`, `ZoteroDiff`) into the [`biblatex-apa-swift`](https://github.com/kiki830621/biblatex-apa-swift) Swift package. This shared module is now also used by `che-zotero-mcp`, eliminating code duplication between the two servers.
- Server.swift uses `@_exported import BiblatexAPA` to re-export all symbols — existing tool behavior is fully backward-compatible.
- Version bump: 0.3.1 → 0.4.0

## [0.3.1] - 2026-03-06

### Fixed
- `countBraces` now skips `\"` (LaTeX umlaut) instead of treating it as a BibTeX quote delimiter — fixes parser merging multiple entries when author names contain `G\"{u}ltas`, `M\"{u}ller`, etc.
- `extractValue` quoted-value branch now handles `\"` inside `"..."` delimited values

### Added
- 3 new parser tests for LaTeX diacritical handling (`\"`, `\'`, `\~`, `\^`, `` \` ``)

## [0.3.0] - 2026-03-06

### Added
- Idempotent `bib_add_entry`: checks for existing citation key before adding; returns "Skipped (duplicate)" if key already exists
- Idempotent `bib_import`: inherits duplicate detection from `addEntry` when appending to file
- `AddEntryResult` struct with `isDuplicate` flag for programmatic status reporting

## [0.2.1] - 2026-03-06

### Changed
- Normalize all entry types and field names to UPPERCASE per biblatex-apa convention (`@article` → `@ARTICLE`, `author` → `AUTHOR`)
- `bib_normalize` / `bib_fix_entry` now uppercase all field keys, not just aliased ones
- `bib_add_entry` / `bib_update_entry` now auto-uppercase entry type and field keys on write
- `BibWriter.serialize` always outputs UPPERCASE entry types and field names
- `BibEntry` accessors use case-insensitive lookup via `OrderedDict.caseInsensitiveValue`

## [0.2.0] - 2026-03-06

### Added
- `bib_fix_entry` — auto-fix entry to APA 7 format (type upgrades, field normalization, author/date formatting)
- `bib_normalize` — batch normalize all entries in a .bib file
- `bib_import` — import plain-text APA citation into BibEntry
- APA 7 data model hardcoded from official `apa.dbx` (v9.17) — 30+ entry types, field definitions
- APA section classifier — identify which APA 7 manual section (10.1–11.10) an entry belongs to (96.5% accuracy on official examples)
- Context-aware PRESENTATION validation: symposium (MAINTITLE) vs standalone (TITLEADDON)
- Official biblatex-apa test suite (382 entries) as reference data
- 20 comprehensive tests covering parser, validator, rule engine, and section classification

### Changed
- BibValidator now uses context-aware recommended fields for @PRESENTATION
- APARuleEngine Phase 8 uses symposium-aware logic

## [0.1.0] - 2026-03-06

### Added
- `bib_list_entries` — list all entries with optional type filter
- `bib_get_entry` — get entry by citation key
- `bib_search` — keyword search across key, title, authors, type
- `bib_validate` — APA 7 field validation (required + recommended fields)
- `bib_add_entry` — add new entry to .bib file
- `bib_update_entry` — update fields on existing entry
- `bib_delete_entry` — delete entry by key
- `bib_diff_zotero` — compare .bib against Zotero SQLite (read-only)
- BibLaTeX parser with nested brace handling and ordered field preservation
- Zotero field mapping (meetingName→EVENTTITLE, presentationType→TITLEADDON, etc.)
