# che-biblatex-mcp

BibLaTeX file management MCP server — parse, validate (APA 7), edit, and diff against Zotero.

## Features

- **Parse** `.bib` files with full LaTeX-aware parsing (nested braces, comments, multi-line values)
- **Validate** entries against APA 7 field requirements
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
| `bib_add_entry` | Add a new entry |
| `bib_update_entry` | Update fields on an existing entry |
| `bib_delete_entry` | Delete an entry by key |
| `bib_diff_zotero` | Compare .bib vs local Zotero database |

## Technical Details

- **Language**: Swift 5.9+
- **Platform**: macOS 14+
- **MCP SDK**: swift-sdk 0.11.x
- **Current Version**: v0.1.0

## Version History

| Version | Changes |
|---------|---------|
| v0.1.0 | Initial release — 8 tools |

## License

MIT
