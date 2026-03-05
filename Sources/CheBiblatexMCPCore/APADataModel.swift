// Sources/CheBiblatexMCPCore/APADataModel.swift
// APA 7 data model — hardcoded from apa.dbx (Philip Kime, v9.17)
// + biblatex standard entry types.

import Foundation

public struct APADataModel {

    // MARK: - Entry Types

    /// APA-specific entry types declared in apa.dbx
    public static let apaEntryTypes: Set<String> = [
        "PRESENTATION", "CONSTITUTION", "LEGMATERIAL",
        "LEGADMINMATERIAL", "NAMEONLY"
    ]

    /// Standard biblatex entry types commonly used in APA style
    public static let standardEntryTypes: Set<String> = [
        "ARTICLE", "BOOK", "INBOOK", "INCOLLECTION", "INPROCEEDINGS",
        "PROCEEDINGS", "COLLECTION", "REFERENCE", "INREFERENCE",
        "REPORT", "THESIS", "PHDTHESIS", "MASTERSTHESIS",
        "ONLINE", "UNPUBLISHED", "MANUAL", "PATENT", "PERIODICAL",
        "MISC", "VIDEO", "AUDIO", "IMAGE", "SOFTWARE", "DATASET",
        "HARDWARE", "JURISDICTION", "LEGISLATION", "LEGAL"
    ]

    /// All valid entry types
    public static let allEntryTypes: Set<String> =
        apaEntryTypes.union(standardEntryTypes)

    // MARK: - Valid Fields per Entry Type (from apa.dbx)

    /// Fields declared in apa.dbx for @PRESENTATION
    public static let presentationFields: Set<String> = [
        "ADDENDUM", "AUTHOR", "BOOKSUBTITLE", "BOOKTITLE", "BOOKTITLEADDON",
        "CHAPTER", "DOI", "EDITOR", "EDITORTYPE", "EPRINT", "EPRINTCLASS",
        "EPRINTTYPE", "EVENTDAY", "EVENTENDDAY", "EVENTENDHOUR",
        "EVENTENDMINUTE", "EVENTENDMONTH", "EVENTENDSEASON", "EVENTENDSECOND",
        "EVENTENDTIMEZONE", "EVENTENDYEAR", "EVENTHOUR", "EVENTMINUTE",
        "EVENTMONTH", "EVENTSEASON", "EVENTSECOND", "EVENTTIMEZONE",
        "EVENTYEAR", "EVENTTITLE", "EVENTTITLEADDON", "ISBN", "LANGUAGE",
        "LOCATION", "MAINSUBTITLE", "MAINTITLE", "MAINTITLEADDON", "NOTE",
        "NUMBER", "ORGANIZATION", "PAGES", "PART", "PUBLISHER", "PUBSTATE",
        "SERIES", "SUBTITLE", "TITLE", "TITLEADDON", "VENUE", "VOLUME",
        "VOLUMES", "DATE", "EVENTDATE", "URL", "URLDATE",
        // Common universal fields
        "KEYWORDS", "ANNOTATION", "ABSTRACT", "WITH",
        "NARRATOR", "EXECPRODUCER", "EXECDIRECTOR"
    ]

    /// Fields declared in apa.dbx for @REPORT
    public static let reportFields: Set<String> = [
        "ADDENDUM", "AUTHOR", "AUTHORTYPE", "CHAPTER", "DOI", "EPRINT",
        "EPRINTCLASS", "EPRINTTYPE", "INSTITUTION", "ISRN", "LANGUAGE",
        "LOCATION", "NOTE", "NUMBER", "PAGES", "PAGETOTAL", "PUBSTATE",
        "SUBTITLE", "TITLE", "TITLEADDON", "TYPE", "VERSION", "DATE",
        "URL", "URLDATE", "KEYWORDS", "ANNOTATION", "ABSTRACT"
    ]

    /// Fields for @CONSTITUTION
    public static let constitutionFields: Set<String> = [
        "ARTICLE", "SECTION", "AMENDMENT", "TITLE", "DATE"
    ]

    /// Fields for @LEGMATERIAL
    public static let legmaterialFields: Set<String> = [
        "SOURCE", "TITLE", "DATE", "NUMBER", "URL"
    ]

    /// Fields for @LEGADMINMATERIAL
    public static let legadminmaterialFields: Set<String> = [
        "CITATION", "SOURCE", "TITLE", "DATE", "NUMBER", "URL"
    ]

    // MARK: - Required Fields (from apa.dbx constraints + APA 7 conventions)

    /// Mandatory fields — error if missing
    public static let requiredFields: [String: [String]] = [
        "ARTICLE":        ["AUTHOR", "TITLE", "JOURNALTITLE", "DATE"],
        "BOOK":           ["AUTHOR", "TITLE", "DATE"],
        "INBOOK":         ["AUTHOR", "TITLE", "BOOKTITLE", "DATE"],
        "INCOLLECTION":   ["AUTHOR", "TITLE", "BOOKTITLE", "DATE"],
        "INPROCEEDINGS":  ["AUTHOR", "TITLE", "BOOKTITLE", "DATE"],
        "REPORT":         ["AUTHOR", "TITLE", "DATE"],
        "PRESENTATION":   ["AUTHOR", "TITLE", "DATE"],
        "THESIS":         ["AUTHOR", "TITLE", "INSTITUTION", "DATE"],
        "PHDTHESIS":      ["AUTHOR", "TITLE", "INSTITUTION", "DATE"],
        "MASTERSTHESIS":  ["AUTHOR", "TITLE", "INSTITUTION", "DATE"],
        "ONLINE":         ["TITLE", "DATE"],  // AUTHOR or EDITOR recommended
        "VIDEO":          ["TITLE", "DATE"],
        "AUDIO":          ["TITLE", "DATE"],
        "SOFTWARE":       ["TITLE", "DATE"],
        "DATASET":        ["TITLE", "DATE"],
    ]

    /// Recommended fields — warning if missing
    public static let recommendedFields: [String: [String]] = [
        "ARTICLE":        ["DOI", "VOLUME", "PAGES"],
        "BOOK":           ["PUBLISHER"],
        "INCOLLECTION":   ["EDITOR", "PUBLISHER", "PAGES"],
        "INPROCEEDINGS":  ["PUBLISHER"],
        "REPORT":         ["INSTITUTION", "NUMBER"],
        "PRESENTATION":   ["EVENTTITLE", "TITLEADDON", "VENUE"],
        "THESIS":         ["TYPE"],
        "ONLINE":         ["URL", "AUTHOR"],
        "VIDEO":          ["PUBLISHER"],
    ]

    // MARK: - Field Aliases (non-APA → APA biblatex mapping)

    /// Maps commonly used non-biblatex field names to correct APA biblatex equivalents.
    public static let fieldAliases: [String: String] = [
        // BibTeX classic → biblatex
        "JOURNAL":       "JOURNALTITLE",
        "ADDRESS":       "LOCATION",
        "SCHOOL":        "INSTITUTION",
        "YEAR":          "DATE",

        // Common mistakes
        "CONFERENCE":    "EVENTTITLE",
        "MEETING":       "EVENTTITLE",
        "PLACE":         "VENUE",
        "CITY":          "LOCATION",
        "HOWPUBLISHED":  "NOTE",    // or URL if it contains a URL

        // Zotero export quirks
        "MEETINGNAME":   "EVENTTITLE",
        "CONFERENCENAME": "EVENTTITLE",
        "PRESENTATIONTYPE": "TITLEADDON",
    ]

    // MARK: - Entry Type Aliases (non-standard → standard APA biblatex)

    /// Maps legacy/non-standard entry types to APA biblatex equivalents.
    public static let entryTypeAliases: [String: String] = [
        // BibTeX classic types → biblatex
        "CONFERENCE":     "INPROCEEDINGS",
        "TECHREPORT":     "REPORT",
        "BOOKLET":        "BOOK",
        "INBOOK":         "INCOLLECTION",  // in biblatex-apa, INBOOK ≈ INCOLLECTION

        // Common conversions
        "WEBPAGE":        "ONLINE",
        "ELECTRONIC":     "ONLINE",
        "WWW":            "ONLINE",
        "MOVIE":          "VIDEO",
        "FILM":           "VIDEO",
    ]

    // MARK: - Entry Type Upgrade Rules

    /// Conditions under which an entry type should be changed.
    /// Returns (suggestedType, reason) or nil.
    public static func suggestTypeUpgrade(
        currentType: String,
        fields: OrderedDict
    ) -> (newType: String, reason: String)? {
        let type = currentType.uppercased()
        let fieldKeys = Set(fields.keys.map { $0.uppercased() })

        // MISC with URL → ONLINE
        if type == "MISC" && fieldKeys.contains("URL") && !fieldKeys.contains("DOI") {
            return ("ONLINE", "MISC with URL should use @ONLINE")
        }

        // INPROCEEDINGS with EVENTTITLE → PRESENTATION
        if type == "INPROCEEDINGS" && fieldKeys.contains("EVENTTITLE")
            && !fieldKeys.contains("BOOKTITLE") {
            return ("PRESENTATION",
                    "INPROCEEDINGS with EVENTTITLE (no BOOKTITLE) is better as @PRESENTATION")
        }

        // PHDTHESIS/MASTERSTHESIS → THESIS with type field
        if type == "PHDTHESIS" {
            return ("THESIS", "Use @THESIS with type={phdthesis} for APA biblatex")
        }
        if type == "MASTERSTHESIS" {
            return ("THESIS", "Use @THESIS with type={mathesis} for APA biblatex")
        }

        return nil
    }

    // MARK: - Date Patterns

    /// Valid DATE field patterns per APA 7 / biblatex
    public static let datePatterns: [(pattern: String, description: String)] = [
        (#"^\d{4}$"#,                      "Year only: 2020"),
        (#"^\d{4}-\d{2}$"#,               "Year-month: 2020-03"),
        (#"^\d{4}-\d{2}-\d{2}$"#,          "Full date: 2020-03-15"),
        (#"^\d{4}-\d{2}/\d{4}-\d{2}$"#,    "Date range: 2020-03/2020-04"),
        (#"^\d{4}-\d{2}-\d{2}/\d{4}-\d{2}-\d{2}$"#, "Date range: 2020-03-15/2020-03-20"),
        (#"^\d{4}-2[1-4]$"#,               "Season: 2020-21 (Spring)"),
        (#"^\d{4}-2[1-4]/\d{4}-2[1-4]$"#,  "Season range: 2020-21/2020-22"),
        (#"^\d{4}[a-z]$"#,                 "Disambiguated: 2020a"),
    ]

    /// Season codes used in biblatex date fields
    public static let seasonCodes: [String: String] = [
        "21": "Spring", "22": "Summer",
        "23": "Fall/Autumn", "24": "Winter"
    ]
}
