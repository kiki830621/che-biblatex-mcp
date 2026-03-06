# che-biblatex-mcp

BibLaTeX MCP server — parse, validate (APA 7), auto-fix, section classify, and diff against Zotero.

## Features

- **Parse** `.bib` files with full LaTeX-aware parsing (nested braces, comments, multi-line values)
- **Validate** entries against APA 7 field requirements (context-aware for symposium vs standalone presentations)
- **Auto-fix** entries to APA 7 format — type upgrades, field normalization, author/date formatting
- **Classify** entries into APA 7 manual sections (10.1–11.10) with 96.5% accuracy
- **Import** plain-text APA citations into structured BibEntry
- **CRUD** operations on `.bib` entries with formatting preservation
- **Diff** `.bib` against local Zotero SQLite database (read-only, immutable mode)

## Installation

### Claude Code CLI

```bash
curl -L https://github.com/kiki830621/che-biblatex-mcp/releases/latest/download/CheBiblatexMCP -o ~/bin/CheBiblatexMCP
chmod +x ~/bin/CheBiblatexMCP
claude mcp add --scope user --transport stdio che-biblatex-mcp -- ~/bin/CheBiblatexMCP
```

### Build from Source

```bash
git clone https://github.com/kiki830621/che-biblatex-mcp.git
cd che-biblatex-mcp
swift build -c release
cp .build/release/CheBiblatexMCP ~/bin/
```

## Tools

| Tool | Description |
|------|-------------|
| `bib_list_entries` | List all entries (with optional type filter) |
| `bib_get_entry` | Get a single entry by citation key |
| `bib_search` | Search entries by keyword |
| `bib_validate` | Validate against APA 7 requirements |
| `bib_fix_entry` | Auto-fix entry to APA 7 format |
| `bib_normalize` | Batch normalize all entries |
| `bib_import` | Import plain-text APA citation |
| `bib_add_entry` | Add a new entry |
| `bib_update_entry` | Update fields on an existing entry |
| `bib_delete_entry` | Delete an entry by key |
| `bib_diff_zotero` | Compare .bib vs local Zotero database |

## Technical Details

- **Language**: Swift 5.9+
- **Platform**: macOS 14+
- **MCP SDK**: swift-sdk 0.11.x
- **Current Version**: v0.3.1

## Version History

| Version | Changes |
|---------|---------|
| v0.3.1 | Fix parser crash on LaTeX diacriticals (`\"`, `\'`, `\~`) — `G\"{u}ltas` no longer breaks entry boundary detection |
| v0.3.0 | Idempotent `bib_add_entry` and `bib_import` — skip duplicates by citation key |
| v0.2.1 | Normalize entry types and field names to UPPERCASE per biblatex-apa convention |
| v0.2.0 | APA 7 rule engine, section classifier, 3 new tools, symposium-aware validation, 20 tests |
| v0.1.0 | Initial release — 8 tools |

## License

MIT
