// Tests/CheBiblatexMCPTests/APAReferenceTests.swift
// Comprehensive tests using official biblatex-apa test .bib files.
// Validates parser, validator, and rule engine against all 382 reference examples.

import XCTest
@testable import CheBiblatexMCPCore

final class APAReferenceTests: XCTestCase {

    // MARK: - Test Data

    static let referencesPath = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // Tests/CheBiblatexMCPTests
        .deletingLastPathComponent()  // Tests
        .deletingLastPathComponent()  // project root
        .appendingPathComponent("references/biblatex-apa/doc/biblatex-apa-test-references.bib")

    static let citationsPath = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("references/biblatex-apa/doc/biblatex-apa-test-citations.bib")

    static let miscPath = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("references/biblatex-apa/doc/biblatex-apa-test-misc.bib")

    // MARK: - Parser Tests

    func testParseReferencesFile() throws {
        let content = try String(contentsOf: Self.referencesPath, encoding: .utf8)
        let bibFile = BibParser.parse(content: content)

        XCTAssertEqual(bibFile.entries.count, 283,
            "Should parse all 283 entries from biblatex-apa-test-references.bib")
    }

    func testParseCitationsFile() throws {
        let content = try String(contentsOf: Self.citationsPath, encoding: .utf8)
        let bibFile = BibParser.parse(content: content)

        XCTAssertEqual(bibFile.entries.count, 90,
            "Should parse all 90 entries from biblatex-apa-test-citations.bib")
    }

    func testParseMiscFile() throws {
        let content = try String(contentsOf: Self.miscPath, encoding: .utf8)
        let bibFile = BibParser.parse(content: content)

        XCTAssertEqual(bibFile.entries.count, 9,
            "Should parse all 9 entries from biblatex-apa-test-misc.bib")
    }

    // MARK: - Entry Type Recognition

    func testAllEntryTypesRecognized() throws {
        let content = try String(contentsOf: Self.referencesPath, encoding: .utf8)
        let bibFile = BibParser.parse(content: content)

        var unrecognized: [(String, String)] = []
        for entry in bibFile.entries {
            let type = entry.normalizedType
            if !APADataModel.allEntryTypes.contains(type) {
                unrecognized.append((entry.key, type))
            }
        }

        XCTAssertTrue(unrecognized.isEmpty,
            "Unrecognized entry types: \(unrecognized.map { "\($0.0) (@\($0.1))" }.joined(separator: ", "))")
    }

    func testEntryTypeDistribution() throws {
        let content = try String(contentsOf: Self.referencesPath, encoding: .utf8)
        let bibFile = BibParser.parse(content: content)

        var typeCounts: [String: Int] = [:]
        for entry in bibFile.entries {
            typeCounts[entry.normalizedType, default: 0] += 1
        }

        // Verify expected types are present
        let expectedTypes = [
            "BOOK", "ARTICLE", "ONLINE", "VIDEO", "REPORT",
            "INCOLLECTION", "PRESENTATION", "IMAGE", "AUDIO",
            "SOFTWARE", "DATASET", "NAMEONLY"
        ]
        for t in expectedTypes {
            XCTAssertTrue((typeCounts[t] ?? 0) > 0,
                "Expected at least one @\(t) entry, found \(typeCounts[t] ?? 0)")
        }
    }

    // MARK: - Field Parsing

    func testAllEntriesHaveKeys() throws {
        let content = try String(contentsOf: Self.referencesPath, encoding: .utf8)
        let bibFile = BibParser.parse(content: content)

        let emptyKeys = bibFile.entries.filter { $0.key.isEmpty }
        XCTAssertTrue(emptyKeys.isEmpty,
            "Found \(emptyKeys.count) entries with empty keys")
    }

    func testMultiLineFieldParsing() throws {
        // Entry 10.5:63 has multi-line MAINTITLE and TITLE fields
        let content = try String(contentsOf: Self.referencesPath, encoding: .utf8)
        let bibFile = BibParser.parse(content: content)

        let entry = bibFile.entries.first { $0.key == "10.5:63" }
        XCTAssertNotNil(entry, "Should find entry 10.5:63")

        if let e = entry {
            let maintitle = e.fields["MAINTITLE"] ?? e.fields["maintitle"]
            XCTAssertNotNil(maintitle, "10.5:63 should have MAINTITLE")
            XCTAssertTrue(maintitle!.contains("Perspectives on Resilience"),
                "MAINTITLE should contain 'Perspectives on Resilience'")

            let editora = e.fields["EDITORA"] ?? e.fields["editora"]
            XCTAssertNotNil(editora, "10.5:63 should have EDITORA")
        }
    }

    func testNestedBracesParsing() throws {
        let content = try String(contentsOf: Self.referencesPath, encoding: .utf8)
        let bibFile = BibParser.parse(content: content)

        // Entries with nested braces like {Conceptualization} inside title
        let entry = bibFile.entries.first { $0.key == "10.5:63" }
        if let e = entry {
            let maintitle = e.fields["MAINTITLE"] ?? e.fields["maintitle"]
            XCTAssertNotNil(maintitle)
            // The nested brace {Conceptualization} should be preserved
            XCTAssertTrue(maintitle!.contains("Conceptualization"),
                "Nested braces content should be preserved")
        }
    }

    // MARK: - Validator Tests (No False Errors on Official Examples)

    func testNoValidationErrorsOnOfficialReferences() throws {
        let content = try String(contentsOf: Self.referencesPath, encoding: .utf8)
        let bibFile = BibParser.parse(content: content)

        var errors: [ValidationIssue] = []
        for entry in bibFile.entries {
            let issues = BibValidator.validate(entry: entry)
            let entryErrors = issues.filter { $0.severity == .error }
            errors.append(contentsOf: entryErrors)
        }

        // Official test file includes various legitimate patterns:
        // - Citation-only examples (APA 9.x) that intentionally lack TITLE/DATE
        // - Entries using EVENTDATE or URLDATE instead of DATE
        // - Entries without AUTHOR (religious works, republished works)
        // - NAMEONLY entries (citation format only)
        let citationOnlyPrefixes = ["9.8:", "9.46:", "9.47:", "9.48:", "9.49:"]
        let unexpectedErrors = errors.filter { issue in
            let entry = bibFile.entries.first { $0.key == issue.key }
            // NAMEONLY entries don't need standard fields
            if entry?.normalizedType == "NAMEONLY" { return false }
            // Citation-only examples (no TITLE by design)
            if citationOnlyPrefixes.contains(where: { issue.key.hasPrefix($0) }) {
                return false
            }
            // Entries with alternative date fields (EVENTDATE, URLDATE, PUBSTATE)
            if issue.message.contains("Missing required field: DATE"), let e = entry {
                if hasField(e, "PUBSTATE") || hasField(e, "EVENTDATE")
                    || hasField(e, "URLDATE") { return false }
            }
            // Entries without AUTHOR that have EDITOR or are authorless works
            if issue.message.contains("Missing required field: AUTHOR"), let e = entry {
                if hasField(e, "EDITOR") || hasField(e, "TITLE") { return false }
            }
            // Only check types we have required field definitions for
            let type = entry?.normalizedType ?? ""
            let definedTypes = ["ARTICLE", "PRESENTATION", "REPORT", "BOOK",
                                "INCOLLECTION", "INPROCEEDINGS", "THESIS"]
            if !definedTypes.contains(type) { return false }
            return true
        }

        if !unexpectedErrors.isEmpty {
            let desc = unexpectedErrors.prefix(20).map { $0.description }
                .joined(separator: "\n")
            XCTFail("Unexpected validation errors (\(unexpectedErrors.count) total):\n\(desc)")
        }
    }

    // MARK: - PRESENTATION Sub-type Tests

    func testPresentationStandaloneDetection() throws {
        let content = try String(contentsOf: Self.referencesPath, encoding: .utf8)
        let bibFile = BibParser.parse(content: content)

        // 10.5:60 — Conference session (standalone, has TITLEADDON)
        let entry60 = bibFile.entries.first { $0.key == "10.5:60" }
        XCTAssertNotNil(entry60)
        if let e = entry60 {
            XCTAssertEqual(e.normalizedType, "PRESENTATION")
            XCTAssertFalse(hasField(e, "MAINTITLE"),
                "10.5:60 should NOT have MAINTITLE (standalone)")
            XCTAssertTrue(hasField(e, "TITLEADDON"),
                "10.5:60 should have TITLEADDON")
            let titleaddon = caseInsensitiveGet(e, "TITLEADDON")
            XCTAssertEqual(titleaddon, "Conference session")

            // Validator should NOT warn about TITLEADDON (it exists)
            let issues = BibValidator.validate(entry: e)
            let titleAddonWarning = issues.first {
                $0.message.contains("TITLEADDON")
            }
            XCTAssertNil(titleAddonWarning,
                "Should not warn about TITLEADDON when it's present")
        }

        // 10.5:61 — Paper presentation (standalone, has TITLEADDON)
        let entry61 = bibFile.entries.first { $0.key == "10.5:61" }
        XCTAssertNotNil(entry61)
        if let e = entry61 {
            XCTAssertFalse(hasField(e, "MAINTITLE"))
            XCTAssertTrue(hasField(e, "TITLEADDON"))
            let titleaddon = caseInsensitiveGet(e, "TITLEADDON")
            XCTAssertEqual(titleaddon, "Paper presentation")
        }

        // 10.5:62 — Poster presentation (standalone, has TITLEADDON)
        let entry62 = bibFile.entries.first { $0.key == "10.5:62" }
        XCTAssertNotNil(entry62)
        if let e = entry62 {
            XCTAssertFalse(hasField(e, "MAINTITLE"))
            XCTAssertTrue(hasField(e, "TITLEADDON"))
            let titleaddon = caseInsensitiveGet(e, "TITLEADDON")
            XCTAssertEqual(titleaddon, "Poster presentation")
        }
    }

    func testPresentationSymposiumDetection() throws {
        let content = try String(contentsOf: Self.referencesPath, encoding: .utf8)
        let bibFile = BibParser.parse(content: content)

        // 10.5:63 — Symposium (has MAINTITLE, no standalone TITLEADDON)
        let entry63 = bibFile.entries.first { $0.key == "10.5:63" }
        XCTAssertNotNil(entry63)
        if let e = entry63 {
            XCTAssertEqual(e.normalizedType, "PRESENTATION")
            XCTAssertTrue(hasField(e, "MAINTITLE"),
                "10.5:63 should have MAINTITLE (symposium)")
            XCTAssertTrue(hasField(e, "MAINTITLEADDON"),
                "10.5:63 should have MAINTITLEADDON = {Symposium}")
            XCTAssertTrue(hasField(e, "EDITORA"),
                "10.5:63 should have EDITORA (chair)")
            XCTAssertTrue(hasField(e, "EDITORATYPE"),
                "10.5:63 should have EDITORATYPE = {chair}")

            // Validator should NOT warn about missing TITLEADDON
            let issues = BibValidator.validate(entry: e)
            let titleAddonWarning = issues.first {
                $0.message.contains("TITLEADDON")
            }
            XCTAssertNil(titleAddonWarning,
                "Symposium should NOT get TITLEADDON warning")
        }
    }

    func testPresentationStandaloneMissingTitleAddonWarns() {
        // Create a standalone PRESENTATION without TITLEADDON — should warn
        var fields = OrderedDict()
        fields["AUTHOR"] = "Doe, J."
        fields["TITLE"] = "Some Presentation"
        fields["EVENTTITLE"] = "Some Conference"
        fields["VENUE"] = "New York, NY"
        fields["DATE"] = "2024"
        // No TITLEADDON, no MAINTITLE → standalone → should warn

        let entry = BibEntry(
            entryType: "PRESENTATION",
            key: "test_standalone",
            fields: fields,
            rawText: "",
            lineNumber: 0
        )

        let issues = BibValidator.validate(entry: entry)
        let titleAddonWarning = issues.first {
            $0.message.contains("TITLEADDON")
        }
        XCTAssertNotNil(titleAddonWarning,
            "Standalone PRESENTATION without TITLEADDON should produce warning")
    }

    func testPresentationSymposiumMissingTitleAddonNoWarning() {
        // Create a symposium PRESENTATION (has MAINTITLE) — should NOT warn about TITLEADDON
        var fields = OrderedDict()
        fields["AUTHOR"] = "Doe, J."
        fields["TITLE"] = "Talk in Symposium"
        fields["MAINTITLE"] = "The Big Symposium"
        fields["MAINTITLEADDON"] = "Symposium"
        fields["EDITORA"] = "Smith, A."
        fields["EDITORATYPE"] = "chair"
        fields["EVENTTITLE"] = "Some Conference"
        fields["VENUE"] = "Chicago, IL"
        fields["DATE"] = "2024"

        let entry = BibEntry(
            entryType: "PRESENTATION",
            key: "test_symposium",
            fields: fields,
            rawText: "",
            lineNumber: 0
        )

        let issues = BibValidator.validate(entry: entry)
        let titleAddonWarning = issues.first {
            $0.message.contains("TITLEADDON")
        }
        XCTAssertNil(titleAddonWarning,
            "Symposium PRESENTATION should NOT warn about TITLEADDON")
    }

    // MARK: - Rule Engine Tests

    func testRuleEngineNoFalseFixesOnOfficialExamples() throws {
        let content = try String(contentsOf: Self.referencesPath, encoding: .utf8)
        let bibFile = BibParser.parse(content: content)

        var typeChanges: [(String, String)] = []
        for entry in bibFile.entries {
            let result = APARuleEngine.fix(entry: entry)
            // Official examples should not need type changes
            let typeActions = result.actions.filter { $0.kind == FixAction.Kind.typeChanged }
            for a in typeActions {
                typeChanges.append((entry.key, a.message))
            }
        }

        // Some type upgrades are expected and correct:
        // - PHDTHESIS/MASTERSTHESIS → THESIS (biblatex alias)
        // - INBOOK → INCOLLECTION (rule engine suggestion for entries with EDITOR)
        // - MISC → ONLINE (rule engine suggestion for entries with URL)
        let expectedUpgrades = ["PHDTHESIS", "MASTERSTHESIS", "INBOOK", "MISC"]
        let unexpectedTypeChanges = typeChanges.filter { pair in
            !expectedUpgrades.contains(where: { pair.1.contains($0) })
        }

        if !unexpectedTypeChanges.isEmpty {
            let desc = unexpectedTypeChanges.prefix(10)
                .map { "\($0.0): \($0.1)" }.joined(separator: "\n")
            XCTFail("Unexpected type changes:\n\(desc)")
        }
    }

    func testRuleEngineSymposiumPresentationRecommendations() throws {
        let content = try String(contentsOf: Self.referencesPath, encoding: .utf8)
        let bibFile = BibParser.parse(content: content)

        // 10.5:63 is a well-formed symposium — rule engine should not suggest TITLEADDON
        let entry63 = bibFile.entries.first { $0.key == "10.5:63" }!
        let result = APARuleEngine.fix(entry: entry63)

        let titleAddonAction = result.actions.first {
            $0.message.contains("TITLEADDON")
        }
        XCTAssertNil(titleAddonAction,
            "Rule engine should not suggest TITLEADDON for symposium")
    }

    func testRuleEngineStandalonePresentationRecommendsTitleAddon() {
        // Standalone without TITLEADDON
        var fields = OrderedDict()
        fields["AUTHOR"] = "Doe, J."
        fields["TITLE"] = "My Talk"
        fields["EVENTTITLE"] = "Conference"
        fields["VENUE"] = "City"
        fields["DATE"] = "2024"

        let entry = BibEntry(
            entryType: "PRESENTATION",
            key: "test_no_titleaddon",
            fields: fields,
            rawText: "",
            lineNumber: 0
        )

        let result = APARuleEngine.fix(entry: entry)
        let titleAddonAction = result.actions.first {
            $0.message.contains("TITLEADDON")
        }
        XCTAssertNotNil(titleAddonAction,
            "Rule engine should recommend TITLEADDON for standalone presentation")
    }

    // MARK: - Bulk Validation (All Files)

    func testBulkParseAndValidateAllFiles() throws {
        let paths = [Self.referencesPath, Self.citationsPath, Self.miscPath]
        var totalEntries = 0
        var totalErrors = 0
        var totalWarnings = 0
        var parseFailures: [String] = []

        for path in paths {
            guard let content = try? String(contentsOf: path, encoding: .utf8) else {
                XCTFail("Cannot read file: \(path.lastPathComponent)")
                continue
            }
            let bibFile = BibParser.parse(content: content)
            totalEntries += bibFile.entries.count

            if bibFile.entries.isEmpty {
                parseFailures.append(path.lastPathComponent)
            }

            for entry in bibFile.entries {
                let issues = BibValidator.validate(entry: entry)
                totalErrors += issues.filter { $0.severity == ValidationIssue.Severity.error }.count
                totalWarnings += issues.filter { $0.severity == ValidationIssue.Severity.warning }.count
            }
        }

        XCTAssertTrue(parseFailures.isEmpty,
            "Failed to parse entries from: \(parseFailures.joined(separator: ", "))")
        XCTAssertEqual(totalEntries, 382,
            "Expected 382 total entries across all 3 files")

        // Print summary for visibility
        print("=== Bulk Test Summary ===")
        print("Total entries parsed: \(totalEntries)")
        print("Validation errors: \(totalErrors)")
        print("Validation warnings: \(totalWarnings)")
    }

    // MARK: - Section Classification Tests

    /// Extract APA section number from an entry key (e.g. "10.5:63" → "10.5").
    private func expectedSection(from key: String) -> String? {
        // Keys follow pattern: "section:example" like "10.1:1", "10.5:63", "11.4:A1"
        guard let colonIndex = key.firstIndex(of: ":") else { return nil }
        let section = String(key[key.startIndex..<colonIndex])
        // Validate it looks like a section number (e.g., "10.1", "11.9")
        let parts = section.split(separator: ".")
        guard parts.count == 2,
              let ch = Int(parts[0]), (ch == 10 || ch == 11),
              Int(parts[1]) != nil else { return nil }
        return section
    }

    func testSectionClassificationOnAllReferences() throws {
        let content = try String(contentsOf: Self.referencesPath, encoding: .utf8)
        let bibFile = BibParser.parse(content: content)

        // Only test entries from Chapter 10 & 11 (reference examples)
        // Skip Chapter 9 entries (citation format examples, not reference types)
        let refEntries = bibFile.entries.filter { entry in
            guard let section = expectedSection(from: entry.key) else { return false }
            return section.hasPrefix("10.") || section.hasPrefix("11.")
        }

        XCTAssertTrue(refEntries.count > 150,
            "Expected 150+ reference entries, got \(refEntries.count)")

        var correct = 0
        var incorrect: [(key: String, expected: String, got: String)] = []

        for entry in refEntries {
            guard let expected = expectedSection(from: entry.key) else { continue }
            let classified = APADataModel.classifySection(entry: entry)

            if classified.number == expected {
                correct += 1
            } else {
                incorrect.append((entry.key, expected, classified.number))
            }
        }

        let total = correct + incorrect.count
        let accuracy = Double(correct) / Double(total) * 100.0

        print("=== Section Classification Results ===")
        print("Total: \(total), Correct: \(correct), Accuracy: \(String(format: "%.1f", accuracy))%")

        if !incorrect.isEmpty {
            print("\nMisclassifications (\(incorrect.count)):")
            for m in incorrect {
                print("  \(m.key): expected \(m.expected), got \(m.got)")
            }
        }

        // Require at least 90% accuracy
        XCTAssertGreaterThanOrEqual(accuracy, 90.0,
            "Section classification accuracy \(String(format: "%.1f", accuracy))% is below 90% threshold. \(incorrect.count) misclassified.")
    }

    func testEachSectionHasAtLeastOneCorrectClassification() throws {
        let content = try String(contentsOf: Self.referencesPath, encoding: .utf8)
        let bibFile = BibParser.parse(content: content)

        // Group entries by their expected section
        var sectionEntries: [String: [BibEntry]] = [:]
        for entry in bibFile.entries {
            guard let section = expectedSection(from: entry.key) else { continue }
            guard section.hasPrefix("10.") || section.hasPrefix("11.") else { continue }
            sectionEntries[section, default: []].append(entry)
        }

        var failingSections: [String] = []

        for (section, entries) in sectionEntries.sorted(by: { $0.key < $1.key }) {
            let anyCorrect = entries.contains { entry in
                APADataModel.classifySection(entry: entry).number == section
            }
            if !anyCorrect {
                failingSections.append(section)
            }
        }

        XCTAssertTrue(failingSections.isEmpty,
            "No correct classification for sections: \(failingSections.joined(separator: ", "))")
    }

    func testSpecificSectionClassifications() throws {
        let content = try String(contentsOf: Self.referencesPath, encoding: .utf8)
        let bibFile = BibParser.parse(content: content)

        func entry(_ key: String) -> BibEntry? {
            bibFile.entries.first { $0.key == key }
        }

        // 10.1 Periodicals — journal article
        if let e = entry("10.1:1") {
            XCTAssertEqual(APADataModel.classifySection(entry: e).number, "10.1",
                "10.1:1 should classify as 10.1 Periodicals")
        }

        // 10.2 Books
        if let e = entry("10.2:16") {
            XCTAssertEqual(APADataModel.classifySection(entry: e).number, "10.2",
                "10.2:16 should classify as 10.2 Books")
        }

        // 10.3 Edited Book Chapters
        if let e = entry("10.3:42") {
            XCTAssertEqual(APADataModel.classifySection(entry: e).number, "10.3",
                "10.3:42 should classify as 10.3 Edited Book Chapters")
        }

        // 10.4 Reports
        if let e = entry("10.4:50") {
            XCTAssertEqual(APADataModel.classifySection(entry: e).number, "10.4",
                "10.4:50 should classify as 10.4 Reports")
        }

        // 10.5 Presentations — standalone
        if let e = entry("10.5:60") {
            XCTAssertEqual(APADataModel.classifySection(entry: e).number, "10.5",
                "10.5:60 should classify as 10.5 Conference Presentations")
        }

        // 10.5 Presentations — symposium
        if let e = entry("10.5:63") {
            XCTAssertEqual(APADataModel.classifySection(entry: e).number, "10.5",
                "10.5:63 should classify as 10.5 Conference Presentations")
        }

        // 10.6 Dissertations
        if let e = entry("10.6:65") {
            XCTAssertEqual(APADataModel.classifySection(entry: e).number, "10.6",
                "10.6:65 should classify as 10.6 Dissertations and Theses")
        }

        // 10.7 Reviews — article reviewing a work
        if let e = entry("10.7:67") {
            XCTAssertEqual(APADataModel.classifySection(entry: e).number, "10.7",
                "10.7:67 should classify as 10.7 Reviews")
        }

        // 10.8 Unpublished
        if let e = entry("10.8:70") {
            XCTAssertEqual(APADataModel.classifySection(entry: e).number, "10.8",
                "10.8:70 should classify as 10.8 Unpublished Works")
        }

        // 10.9 Data Sets
        if let e = entry("10.9:75") {
            XCTAssertEqual(APADataModel.classifySection(entry: e).number, "10.9",
                "10.9:75 should classify as 10.9 Data Sets")
        }

        // 10.10 Computer Software
        if let e = entry("10.10:77") {
            XCTAssertEqual(APADataModel.classifySection(entry: e).number, "10.10",
                "10.10:77 should classify as 10.10 Software")
        }

        // 10.11 Tests/Scales
        if let e = entry("10.11:81") {
            XCTAssertEqual(APADataModel.classifySection(entry: e).number, "10.11",
                "10.11:81 should classify as 10.11 Tests/Scales")
        }

        // 10.12 Audiovisual
        if let e = entry("10.12:84a") {
            XCTAssertEqual(APADataModel.classifySection(entry: e).number, "10.12",
                "10.12:84a should classify as 10.12 Audiovisual")
        }

        // 10.13 Audio
        if let e = entry("10.13:91") {
            XCTAssertEqual(APADataModel.classifySection(entry: e).number, "10.13",
                "10.13:91 should classify as 10.13 Audio")
        }

        // 10.14 Visual
        if let e = entry("10.14:96") {
            XCTAssertEqual(APADataModel.classifySection(entry: e).number, "10.14",
                "10.14:96 should classify as 10.14 Visual")
        }

        // 10.15 Social Media
        if let e = entry("10.15:103a") {
            XCTAssertEqual(APADataModel.classifySection(entry: e).number, "10.15",
                "10.15:103a should classify as 10.15 Social Media")
        }

        // 10.16 Webpages
        if let e = entry("10.16:110a") {
            XCTAssertEqual(APADataModel.classifySection(entry: e).number, "10.16",
                "10.16:110a should classify as 10.16 Webpages")
        }

        // 11.4 Court Decisions
        if let e = entry("11.4:1") {
            XCTAssertEqual(APADataModel.classifySection(entry: e).number, "11.4",
                "11.4:1 should classify as 11.4 Court Decisions")
        }

        // 11.5 Statutes
        if let e = entry("11.5:1") {
            XCTAssertEqual(APADataModel.classifySection(entry: e).number, "11.5",
                "11.5:1 should classify as 11.5 Statutes")
        }

        // 11.9 Constitutions
        if let e = entry("11.9:1") {
            XCTAssertEqual(APADataModel.classifySection(entry: e).number, "11.9",
                "11.9:1 should classify as 11.9 Constitutions")
        }
    }

    // MARK: - Helpers

    private func hasField(_ entry: BibEntry, _ name: String) -> Bool {
        let lower = name.lowercased()
        return entry.fields.keys.contains { $0.lowercased() == lower }
    }

    private func caseInsensitiveGet(_ entry: BibEntry, _ name: String) -> String? {
        let lower = name.lowercased()
        if let key = entry.fields.keys.first(where: { $0.lowercased() == lower }) {
            return entry.fields[key]
        }
        return nil
    }
}
