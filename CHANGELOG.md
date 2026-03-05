# Changelog

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
