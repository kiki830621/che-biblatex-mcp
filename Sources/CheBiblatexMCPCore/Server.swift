// Sources/CheBiblatexMCPCore/Server.swift
// MCP Server for biblatex file management.

import Foundation
import MCP
@_exported import BiblatexAPA

public actor CheBiblatexMCPServer {
    private let server: Server
    private let transport: StdioTransport

    public init() async throws {
        server = Server(
            name: "che-biblatex-mcp",
            version: "0.4.0",
            capabilities: .init(tools: .init())
        )
        transport = StdioTransport()
        await registerHandlers()
    }

    public func run() async throws {
        try await server.start(transport: transport)
        await server.waitUntilCompleted()
    }

    // MARK: - Tool Definitions

    private static let tools: [Tool] = [
        Tool(
            name: "bib_list_entries",
            description: "List all entries in a .bib file. Returns key, type, title, date, and authors for each entry.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "file_path": .object([
                        "type": .string("string"),
                        "description": .string("Absolute path to the .bib file")
                    ]),
                    "type_filter": .object([
                        "type": .string("string"),
                        "description": .string("Optional: filter by entry type (e.g. ARTICLE, PRESENTATION, REPORT)")
                    ])
                ]),
                "required": .array([.string("file_path")])
            ])
        ),
        Tool(
            name: "bib_get_entry",
            description: "Get a single entry by citation key. Returns all fields.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "file_path": .object([
                        "type": .string("string"),
                        "description": .string("Absolute path to the .bib file")
                    ]),
                    "key": .object([
                        "type": .string("string"),
                        "description": .string("Citation key (e.g. cheng_psychometrika_2025)")
                    ])
                ]),
                "required": .array([.string("file_path"), .string("key")])
            ])
        ),
        Tool(
            name: "bib_search",
            description: "Search entries by keyword across key, title, authors, and entry type.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "file_path": .object([
                        "type": .string("string"),
                        "description": .string("Absolute path to the .bib file")
                    ]),
                    "query": .object([
                        "type": .string("string"),
                        "description": .string("Search query (case-insensitive)")
                    ])
                ]),
                "required": .array([.string("file_path"), .string("query")])
            ])
        ),
        Tool(
            name: "bib_validate",
            description: "Validate entries against APA 7 field requirements. Checks required/recommended fields per entry type, author format, and CV categorization.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "file_path": .object([
                        "type": .string("string"),
                        "description": .string("Absolute path to the .bib file")
                    ]),
                    "key": .object([
                        "type": .string("string"),
                        "description": .string("Optional: validate a single entry by key. If omitted, validates all entries.")
                    ])
                ]),
                "required": .array([.string("file_path")])
            ])
        ),
        Tool(
            name: "bib_add_entry",
            description: "Add a new entry to a .bib file.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "file_path": .object([
                        "type": .string("string"),
                        "description": .string("Absolute path to the .bib file")
                    ]),
                    "entry_type": .object([
                        "type": .string("string"),
                        "description": .string("Entry type (e.g. ARTICLE, PRESENTATION, REPORT, BOOK, INPROCEEDINGS)")
                    ]),
                    "key": .object([
                        "type": .string("string"),
                        "description": .string("Citation key (e.g. cheng_psychometrika_2025)")
                    ]),
                    "fields": .object([
                        "type": .string("object"),
                        "description": .string("Field name-value pairs (e.g. {\"AUTHOR\": \"Cheng, Che\", \"TITLE\": \"...\"})")
                    ])
                ]),
                "required": .array([.string("file_path"), .string("entry_type"), .string("key"), .string("fields")])
            ])
        ),
        Tool(
            name: "bib_update_entry",
            description: "Update fields on an existing entry. Only specified fields are changed; others are preserved.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "file_path": .object([
                        "type": .string("string"),
                        "description": .string("Absolute path to the .bib file")
                    ]),
                    "key": .object([
                        "type": .string("string"),
                        "description": .string("Citation key of the entry to update")
                    ]),
                    "fields": .object([
                        "type": .string("object"),
                        "description": .string("Field name-value pairs to update")
                    ])
                ]),
                "required": .array([.string("file_path"), .string("key"), .string("fields")])
            ])
        ),
        Tool(
            name: "bib_delete_entry",
            description: "Delete an entry from a .bib file by citation key.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "file_path": .object([
                        "type": .string("string"),
                        "description": .string("Absolute path to the .bib file")
                    ]),
                    "key": .object([
                        "type": .string("string"),
                        "description": .string("Citation key of the entry to delete")
                    ])
                ]),
                "required": .array([.string("file_path"), .string("key")])
            ])
        ),
        Tool(
            name: "bib_diff_zotero",
            description: "Compare a .bib file against the local Zotero SQLite database. Matches by DOI then title, reports missing entries and field mismatches.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "file_path": .object([
                        "type": .string("string"),
                        "description": .string("Absolute path to the .bib file")
                    ]),
                    "zotero_db_path": .object([
                        "type": .string("string"),
                        "description": .string("Optional: path to Zotero SQLite database. Auto-detected if omitted.")
                    ])
                ]),
                "required": .array([.string("file_path")])
            ])
        ),
        Tool(
            name: "bib_fix_entry",
            description: "Auto-fix a single entry to conform to APA 7 biblatex format. Normalizes entry type, field names, author format, date format, and reports missing fields. Returns the fixed BibTeX and a list of changes.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "file_path": .object([
                        "type": .string("string"),
                        "description": .string("Absolute path to the .bib file")
                    ]),
                    "key": .object([
                        "type": .string("string"),
                        "description": .string("Citation key of the entry to fix")
                    ]),
                    "apply": .object([
                        "type": .string("boolean"),
                        "description": .string("If true, write the fixed entry back to the file. Default: false (dry-run).")
                    ])
                ]),
                "required": .array([.string("file_path"), .string("key")])
            ])
        ),
        Tool(
            name: "bib_normalize",
            description: "Batch-fix all entries in a .bib file to APA 7 format. Returns a report of all changes. Use apply=true to write changes.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "file_path": .object([
                        "type": .string("string"),
                        "description": .string("Absolute path to the .bib file")
                    ]),
                    "apply": .object([
                        "type": .string("boolean"),
                        "description": .string("If true, write all fixes back to the file. Default: false (dry-run).")
                    ])
                ]),
                "required": .array([.string("file_path")])
            ])
        ),
        Tool(
            name: "bib_import",
            description: "Parse a plain-text APA reference (e.g. copy-pasted from a paper) into a biblatex entry. Extracts authors, date, title, journal, DOI, etc.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "text": .object([
                        "type": .string("string"),
                        "description": .string("Plain-text APA citation (e.g. 'Author, A. A. (2020). Title. Journal, 1(2), 3–4. https://doi.org/...')")
                    ]),
                    "key": .object([
                        "type": .string("string"),
                        "description": .string("Optional: citation key. Auto-generated if omitted.")
                    ]),
                    "file_path": .object([
                        "type": .string("string"),
                        "description": .string("Optional: if provided, append the parsed entry to this .bib file.")
                    ])
                ]),
                "required": .array([.string("text")])
            ])
        ),
    ]

    // MARK: - Handler Registration

    private func registerHandlers() async {
        await server.withMethodHandler(ListTools.self) { _ in
            ListTools.Result(tools: CheBiblatexMCPServer.tools)
        }

        await server.withMethodHandler(CallTool.self) { params in
            try await self.handleToolCall(params)
        }
    }

    // MARK: - Dispatch

    private func handleToolCall(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        do {
            switch params.name {
            case "bib_list_entries":
                return try handleListEntries(params)
            case "bib_get_entry":
                return try handleGetEntry(params)
            case "bib_search":
                return try handleSearch(params)
            case "bib_validate":
                return try handleValidate(params)
            case "bib_add_entry":
                return try handleAddEntry(params)
            case "bib_update_entry":
                return try handleUpdateEntry(params)
            case "bib_delete_entry":
                return try handleDeleteEntry(params)
            case "bib_diff_zotero":
                return try handleDiffZotero(params)
            case "bib_fix_entry":
                return try handleFixEntry(params)
            case "bib_normalize":
                return try handleNormalize(params)
            case "bib_import":
                return try handleImport(params)
            default:
                return CallTool.Result(
                    content: [.text("Unknown tool: \(params.name)")],
                    isError: true
                )
            }
        } catch {
            return CallTool.Result(
                content: [.text("Error: \(error.localizedDescription)")],
                isError: true
            )
        }
    }

    // MARK: - Read Handlers

    private func handleListEntries(_ params: CallTool.Parameters) throws -> CallTool.Result {
        let filePath = params.arguments?["file_path"]?.stringValue ?? ""
        let typeFilter = params.arguments?["type_filter"]?.stringValue

        let bibFile = try BibParser.parse(filePath: filePath)
        var entries = bibFile.entries

        if let filter = typeFilter, !filter.isEmpty {
            entries = entries.filter { $0.normalizedType == filter.uppercased() }
        }

        if entries.isEmpty {
            return CallTool.Result(content: [.text("No entries found.")], isError: false)
        }

        var lines: [String] = ["Found \(entries.count) entries:\n"]
        for e in entries {
            let authors = (e.authors ?? "").prefix(60)
            let title = (e.title ?? "untitled").prefix(80)
            lines.append("[\(e.key)] @\(e.entryType)")
            lines.append("  Title: \(title)")
            if !authors.isEmpty { lines.append("  Authors: \(authors)") }
            if let date = e.date { lines.append("  Date: \(date)") }
            if let doi = e.doi { lines.append("  DOI: \(doi)") }
            lines.append("")
        }

        return CallTool.Result(content: [.text(lines.joined(separator: "\n"))], isError: false)
    }

    private func handleGetEntry(_ params: CallTool.Parameters) throws -> CallTool.Result {
        let filePath = params.arguments?["file_path"]?.stringValue ?? ""
        let key = params.arguments?["key"]?.stringValue ?? ""

        let bibFile = try BibParser.parse(filePath: filePath)
        guard let entry = bibFile.entry(forKey: key) else {
            return CallTool.Result(
                content: [.text("Entry not found: \(key)")],
                isError: true
            )
        }

        var lines: [String] = [
            "Entry: \(entry.key)",
            "Type: @\(entry.entryType)",
            "Line: \(entry.lineNumber)",
            "\nFields:"
        ]
        for pair in entry.fields.pairs {
            lines.append("  \(pair.key) = \(pair.value)")
        }
        lines.append("\nRaw BibTeX:")
        lines.append(entry.rawText)

        return CallTool.Result(content: [.text(lines.joined(separator: "\n"))], isError: false)
    }

    private func handleSearch(_ params: CallTool.Parameters) throws -> CallTool.Result {
        let filePath = params.arguments?["file_path"]?.stringValue ?? ""
        let query = params.arguments?["query"]?.stringValue ?? ""

        let bibFile = try BibParser.parse(filePath: filePath)
        let results = bibFile.search(query: query)

        if results.isEmpty {
            return CallTool.Result(content: [.text("No entries matching '\(query)'.")], isError: false)
        }

        var lines: [String] = ["Found \(results.count) entries matching '\(query)':\n"]
        for e in results {
            lines.append("[\(e.key)] @\(e.entryType) — \(e.title ?? "untitled")")
        }

        return CallTool.Result(content: [.text(lines.joined(separator: "\n"))], isError: false)
    }

    private func handleValidate(_ params: CallTool.Parameters) throws -> CallTool.Result {
        let filePath = params.arguments?["file_path"]?.stringValue ?? ""
        let key = params.arguments?["key"]?.stringValue

        let bibFile = try BibParser.parse(filePath: filePath)
        let issues: [ValidationIssue]

        if let key = key, !key.isEmpty {
            guard let entry = bibFile.entry(forKey: key) else {
                return CallTool.Result(
                    content: [.text("Entry not found: \(key)")],
                    isError: true
                )
            }
            issues = BibValidator.validate(entry: entry)
        } else {
            issues = BibValidator.validate(bibFile)
        }

        if issues.isEmpty {
            let scope = key != nil ? "Entry '\(key!)'" : "All \(bibFile.entries.count) entries"
            return CallTool.Result(
                content: [.text("\(scope) passed validation. No issues found.")],
                isError: false
            )
        }

        let errors = issues.filter { $0.severity == .error }
        let warnings = issues.filter { $0.severity == .warning }

        var lines: [String] = ["Validation: \(errors.count) errors, \(warnings.count) warnings\n"]
        for issue in issues {
            lines.append(issue.description)
        }

        return CallTool.Result(content: [.text(lines.joined(separator: "\n"))], isError: false)
    }

    // MARK: - Write Handlers

    private func handleAddEntry(_ params: CallTool.Parameters) throws -> CallTool.Result {
        let filePath = params.arguments?["file_path"]?.stringValue ?? ""
        let entryType = (params.arguments?["entry_type"]?.stringValue ?? "ARTICLE").uppercased()
        let key = params.arguments?["key"]?.stringValue ?? ""
        let fieldsObj = params.arguments?["fields"]?.objectValue ?? [:]

        // Normalize field keys to UPPERCASE (biblatex-apa convention)
        var fields = OrderedDict()
        for (k, v) in fieldsObj {
            if let s = v.stringValue {
                fields[k.uppercased()] = s
            }
        }

        let entry = BibEntry(
            entryType: entryType,
            key: key,
            fields: fields,
            rawText: "",
            lineNumber: 0
        )

        let result = try BibWriter.addEntry(to: filePath, entry: entry)

        if result.isDuplicate {
            return CallTool.Result(
                content: [.text("Skipped (duplicate): entry [\(key)] already exists in \(filePath).")],
                isError: false
            )
        }

        // Validate the new entry
        let issues = BibValidator.validate(entry: entry)
        var msg = "Added entry [\(key)] @\(entryType) to \(filePath)."
        if !issues.isEmpty {
            msg += "\n\nValidation notes:"
            for issue in issues {
                msg += "\n  \(issue)"
            }
        }

        return CallTool.Result(content: [.text(msg)], isError: false)
    }

    private func handleUpdateEntry(_ params: CallTool.Parameters) throws -> CallTool.Result {
        let filePath = params.arguments?["file_path"]?.stringValue ?? ""
        let key = params.arguments?["key"]?.stringValue ?? ""
        let fieldsObj = params.arguments?["fields"]?.objectValue ?? [:]

        var updatedFields: [String: String] = [:]
        for (k, v) in fieldsObj {
            if let s = v.stringValue {
                updatedFields[k] = s
            }
        }

        try BibWriter.updateEntry(in: filePath, key: key, updatedFields: updatedFields)

        let fieldList = updatedFields.keys.joined(separator: ", ")
        return CallTool.Result(
            content: [.text("Updated [\(key)]: fields \(fieldList).")],
            isError: false
        )
    }

    private func handleDeleteEntry(_ params: CallTool.Parameters) throws -> CallTool.Result {
        let filePath = params.arguments?["file_path"]?.stringValue ?? ""
        let key = params.arguments?["key"]?.stringValue ?? ""

        try BibWriter.deleteEntry(in: filePath, key: key)

        return CallTool.Result(
            content: [.text("Deleted entry [\(key)] from \(filePath).")],
            isError: false
        )
    }

    // MARK: - Diff Handler

    private func handleDiffZotero(_ params: CallTool.Parameters) throws -> CallTool.Result {
        let filePath = params.arguments?["file_path"]?.stringValue ?? ""
        let zoteroDbPath = params.arguments?["zotero_db_path"]?.stringValue

        let bibFile = try BibParser.parse(filePath: filePath)

        let dbPath: String
        if let provided = zoteroDbPath, !provided.isEmpty {
            dbPath = provided
        } else {
            guard let found = ZoteroLiteReader.findDatabase() else {
                return CallTool.Result(
                    content: [.text("Zotero database not found. Provide zotero_db_path or ensure Zotero is installed.")],
                    isError: true
                )
            }
            dbPath = found
        }

        let zoteroItems = try ZoteroLiteReader.readItems(dbPath: dbPath)
        let result = BibZoteroDiff.diff(bibFile: bibFile, zoteroItems: zoteroItems)

        return CallTool.Result(content: [.text(result.summary)], isError: false)
    }

    // MARK: - APA Fix Handlers

    private func handleFixEntry(_ params: CallTool.Parameters) throws -> CallTool.Result {
        let filePath = params.arguments?["file_path"]?.stringValue ?? ""
        let key = params.arguments?["key"]?.stringValue ?? ""
        let apply = params.arguments?["apply"]?.boolValue ?? false

        let bibFile = try BibParser.parse(filePath: filePath)
        guard let entry = bibFile.entry(forKey: key) else {
            return CallTool.Result(
                content: [.text("Entry not found: \(key)")],
                isError: true
            )
        }

        let result = APARuleEngine.fix(entry: entry)

        if !result.hasChanges {
            return CallTool.Result(
                content: [.text("[\(key)] Already conforms to APA 7. No changes needed.")],
                isError: false
            )
        }

        var lines: [String] = [result.summary, ""]

        if apply {
            // Write the fixed entry back
            let content = try String(contentsOfFile: filePath, encoding: .utf8)
            let fixedText = BibWriter.serialize(result.fixedEntry)
            let newContent = content.replacingOccurrences(of: entry.rawText, with: fixedText)
            try newContent.write(toFile: filePath, atomically: true, encoding: .utf8)
            lines.append("Changes written to \(filePath).")
        } else {
            lines.append("Fixed BibTeX (dry-run, not written):")
            lines.append(BibWriter.serialize(result.fixedEntry))
        }

        return CallTool.Result(content: [.text(lines.joined(separator: "\n"))], isError: false)
    }

    private func handleNormalize(_ params: CallTool.Parameters) throws -> CallTool.Result {
        let filePath = params.arguments?["file_path"]?.stringValue ?? ""
        let apply = params.arguments?["apply"]?.boolValue ?? false

        let bibFile = try BibParser.parse(filePath: filePath)
        let results = APARuleEngine.fixAll(bibFile)

        let changed = results.filter { $0.hasChanges }
        let totalActions = changed.reduce(0) { $0 + $1.actions.count }

        if changed.isEmpty {
            return CallTool.Result(
                content: [.text("All \(bibFile.entries.count) entries already conform to APA 7.")],
                isError: false
            )
        }

        var lines: [String] = [
            "APA 7 Normalization Report",
            "Total: \(bibFile.entries.count) entries, \(changed.count) need fixes, \(totalActions) actions\n"
        ]

        for r in changed {
            lines.append(r.summary)
            lines.append("")
        }

        if apply {
            var content = try String(contentsOfFile: filePath, encoding: .utf8)
            // Apply fixes in reverse order to preserve line positions
            for r in changed.reversed() {
                if let original = bibFile.entry(forKey: r.originalKey) {
                    let fixedText = BibWriter.serialize(r.fixedEntry)
                    content = content.replacingOccurrences(of: original.rawText, with: fixedText)
                }
            }
            try content.write(toFile: filePath, atomically: true, encoding: .utf8)
            lines.append("All changes written to \(filePath).")
        } else {
            lines.append("Dry-run complete. Use apply=true to write changes.")
        }

        return CallTool.Result(content: [.text(lines.joined(separator: "\n"))], isError: false)
    }

    private func handleImport(_ params: CallTool.Parameters) throws -> CallTool.Result {
        let text = params.arguments?["text"]?.stringValue ?? ""
        let suggestedKey = params.arguments?["key"]?.stringValue
        let filePath = params.arguments?["file_path"]?.stringValue

        guard let entry = APACitationParser.parse(text, suggestedKey: suggestedKey) else {
            return CallTool.Result(
                content: [.text("Could not parse citation text. Ensure it follows APA format:\n\nAuthor, A. A. (2020). Title. Journal, 1(2), 3–4. https://doi.org/...")],
                isError: true
            )
        }

        // Run APA fix on the parsed entry
        let fixed = APARuleEngine.fix(entry: entry)
        let finalEntry = fixed.fixedEntry
        let bibtex = BibWriter.serialize(finalEntry)

        var lines: [String] = [
            "Parsed citation → @\(finalEntry.entryType){\(finalEntry.key)}",
            ""
        ]

        if fixed.hasChanges {
            lines.append("Auto-corrections applied:")
            for a in fixed.actions {
                lines.append("  \(a)")
            }
            lines.append("")
        }

        lines.append("Generated BibTeX:")
        lines.append(bibtex)

        if let path = filePath, !path.isEmpty {
            let addResult = try BibWriter.addEntry(to: path, entry: finalEntry)
            if addResult.isDuplicate {
                lines.append("\nSkipped (duplicate): [\(finalEntry.key)] already exists in \(path).")
            } else {
                lines.append("\nAppended to \(path).")
            }
        }

        return CallTool.Result(content: [.text(lines.joined(separator: "\n"))], isError: false)
    }
}
