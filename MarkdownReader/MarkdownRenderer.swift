import Foundation

enum MarkdownRenderer {

    static func html(for markdown: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="color-scheme" content="dark">
        <style>\(css)</style>
        </head>
        <body><article>\(convert(markdown))</article></body>
        </html>
        """
    }

    // MARK: - Block-level parsing

    private static func convert(_ markdown: String) -> String {
        let lines = markdown.components(separatedBy: "\n")
        var html = ""
        var i = 0

        while i < lines.count {
            let line = lines[i]

            // Fenced code block
            if line.hasPrefix("```") {
                let lang = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var codeLines: [String] = []
                i += 1
                while i < lines.count && !lines[i].hasPrefix("```") {
                    codeLines.append(lines[i])
                    i += 1
                }
                let code = codeLines.joined(separator: "\n").htmlEscaped
                let cls = lang.isEmpty ? "" : " class=\"language-\(lang)\""
                html += "<pre><code\(cls)>\(code)</code></pre>\n"
                i += 1
                continue
            }

            // ATX headers
            if let (level, text) = parseHeader(line) {
                html += "<h\(level)>\(inline(text))</h\(level)>\n"
            }
            // Setext header H1 (underline ===)
            else if i + 1 < lines.count && !lines[i + 1].isEmpty &&
                        lines[i + 1].allSatisfy({ $0 == "=" }) && !line.isEmpty {
                html += "<h1>\(inline(line))</h1>\n"
                i += 1
            }
            // Setext header H2 (underline ---)
            else if i + 1 < lines.count && !lines[i + 1].isEmpty &&
                        lines[i + 1].allSatisfy({ $0 == "-" }) && lines[i + 1].count >= 2 && !line.isEmpty {
                html += "<h2>\(inline(line))</h2>\n"
                i += 1
            }
            // Horizontal rule
            else if isHorizontalRule(line) {
                html += "<hr>\n"
            }
            // Blockquote
            else if line.hasPrefix("> ") || line == ">" {
                var quoteLines: [String] = [line.hasPrefix("> ") ? String(line.dropFirst(2)) : ""]
                while i + 1 < lines.count && (lines[i + 1].hasPrefix("> ") || lines[i + 1] == ">") {
                    i += 1
                    quoteLines.append(lines[i].hasPrefix("> ") ? String(lines[i].dropFirst(2)) : "")
                }
                html += "<blockquote>\(convert(quoteLines.joined(separator: "\n")))</blockquote>\n"
            }
            // Unordered list
            else if isUnorderedListItem(line) {
                var items: [String] = [unorderedItemText(line)]
                while i + 1 < lines.count && isUnorderedListItem(lines[i + 1]) {
                    i += 1
                    items.append(unorderedItemText(lines[i]))
                }
                let lis = items.map { "<li>\(inline($0))</li>" }.joined(separator: "\n")
                html += "<ul>\n\(lis)\n</ul>\n"
            }
            // Ordered list
            else if isOrderedListItem(line) {
                var items: [String] = [orderedItemText(line)]
                while i + 1 < lines.count && isOrderedListItem(lines[i + 1]) {
                    i += 1
                    items.append(orderedItemText(lines[i]))
                }
                let lis = items.map { "<li>\(inline($0))</li>" }.joined(separator: "\n")
                html += "<ol>\n\(lis)\n</ol>\n"
            }
            // Table: pipe row followed by separator row
            else if isTableRow(line) && i + 1 < lines.count && isTableSeparator(lines[i + 1]) {
                let headers = parseTableRow(line)
                let alignments = parseTableAlignments(lines[i + 1])
                i += 2
                var rows: [[String]] = []
                while i < lines.count && isTableRow(lines[i]) {
                    rows.append(parseTableRow(lines[i]))
                    i += 1
                }
                var table = "<table>\n<thead>\n<tr>"
                for (j, header) in headers.enumerated() {
                    let align = j < alignments.count ? alignments[j] : ""
                    let style = align.isEmpty ? "" : " style=\"text-align:\(align)\""
                    table += "<th\(style)>\(inline(header))</th>"
                }
                table += "</tr>\n</thead>\n<tbody>\n"
                for row in rows {
                    table += "<tr>"
                    for (j, cell) in row.enumerated() {
                        let align = j < alignments.count ? alignments[j] : ""
                        let style = align.isEmpty ? "" : " style=\"text-align:\(align)\""
                        table += "<td\(style)>\(inline(cell))</td>"
                    }
                    table += "</tr>\n"
                }
                table += "</tbody>\n</table>\n"
                html += table
                continue
            }
            // Empty line
            else if line.trimmingCharacters(in: .whitespaces).isEmpty {
                html += ""
            }
            // Paragraph
            else {
                var paraLines: [String] = [line]
                while i + 1 < lines.count {
                    let next = lines[i + 1]
                    if next.trimmingCharacters(in: .whitespaces).isEmpty { break }
                    if parseHeader(next) != nil { break }
                    if isHorizontalRule(next) { break }
                    if next.hasPrefix("> ") || next.hasPrefix("```") { break }
                    if isUnorderedListItem(next) || isOrderedListItem(next) { break }
                    i += 1
                    paraLines.append(next)
                }
                let hardBreak = paraLines.map { inline($0) }.joined(separator: "\n")
                html += "<p>\(hardBreak)</p>\n"
            }

            i += 1
        }

        return html
    }

    // MARK: - Inline parsing

    private static func inline(_ text: String) -> String {
        // Split on backticks: odd-indexed parts are code content
        let parts = text.components(separatedBy: "`")
        var result = ""
        for (index, part) in parts.enumerated() {
            if index % 2 == 0 {
                result += processInlineMarkdown(part)
            } else {
                result += "<code>\(part.htmlEscaped)</code>"
            }
        }
        return result
    }

    private static func processInlineMarkdown(_ text: String) -> String {
        var s = text

        // Images (before links)
        s = s.replacingOccurrences(
            of: #"!\[([^\]]*)\]\(([^)]+)\)"#,
            with: "<img alt=\"$1\" src=\"$2\">",
            options: .regularExpression
        )

        // Links
        s = s.replacingOccurrences(
            of: #"\[([^\]]+)\]\(([^)]+)\)"#,
            with: "<a href=\"$2\">$1</a>",
            options: .regularExpression
        )

        // Bold + italic
        s = s.replacingOccurrences(of: #"\*\*\*(.+?)\*\*\*"#, with: "<strong><em>$1</em></strong>", options: .regularExpression)
        s = s.replacingOccurrences(of: #"___(.+?)___"#, with: "<strong><em>$1</em></strong>", options: .regularExpression)

        // Bold
        s = s.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "<strong>$1</strong>", options: .regularExpression)
        s = s.replacingOccurrences(of: #"__(.+?)__"#, with: "<strong>$1</strong>", options: .regularExpression)

        // Italic
        s = s.replacingOccurrences(of: #"\*(.+?)\*"#, with: "<em>$1</em>", options: .regularExpression)
        s = s.replacingOccurrences(of: #"(?<![_])_([^_]+)_(?![_])"#, with: "<em>$1</em>", options: .regularExpression)

        // Strikethrough
        s = s.replacingOccurrences(of: #"~~(.+?)~~"#, with: "<del>$1</del>", options: .regularExpression)

        return s
    }

    // MARK: - Helpers

    private static func parseHeader(_ line: String) -> (Int, String)? {
        guard line.hasPrefix("#") else { return nil }
        var level = 0
        for ch in line {
            if ch == "#" { level += 1 } else { break }
        }
        guard level <= 6 else { return nil }
        let rest = line.dropFirst(level)
        guard rest.hasPrefix(" ") else { return nil }
        return (level, String(rest.dropFirst()))
    }

    private static func isHorizontalRule(_ line: String) -> Bool {
        let s = line.replacingOccurrences(of: " ", with: "")
        return (s == "---" || s == "***" || s == "___") && s.count >= 3
    }

    private static func isUnorderedListItem(_ line: String) -> Bool {
        line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ")
    }

    private static func unorderedItemText(_ line: String) -> String {
        String(line.dropFirst(2))
    }

    private static func isOrderedListItem(_ line: String) -> Bool {
        line.range(of: #"^\d+\. "#, options: .regularExpression) != nil
    }

    private static func orderedItemText(_ line: String) -> String {
        line.replacingOccurrences(of: #"^\d+\. "#, with: "", options: .regularExpression)
    }

    private static func isTableRow(_ line: String) -> Bool {
        let cols = line.components(separatedBy: "|")
        return cols.count >= 3
    }

    private static func isTableSeparator(_ line: String) -> Bool {
        let cells = parseTableRow(line)
        return !cells.isEmpty && cells.allSatisfy { cell in
            let s = cell.trimmingCharacters(in: .whitespaces)
            return !s.isEmpty && s.allSatisfy { $0 == "-" || $0 == ":" }
        }
    }

    private static func parseTableRow(_ line: String) -> [String] {
        var s = line
        if s.hasPrefix("|") { s = String(s.dropFirst()) }
        if s.hasSuffix("|") { s = String(s.dropLast()) }
        return s.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private static func parseTableAlignments(_ separatorLine: String) -> [String] {
        parseTableRow(separatorLine).map { cell in
            let s = cell.trimmingCharacters(in: .whitespaces)
            if s.hasPrefix(":") && s.hasSuffix(":") { return "center" }
            if s.hasSuffix(":") { return "right" }
            if s.hasPrefix(":") { return "left" }
            return ""
        }
    }

    // MARK: - CSS

    private static let css = """
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    body {
        font-family: -apple-system, BlinkMacSystemFont, 'Helvetica Neue', sans-serif;
        font-size: 16px;
        line-height: 1.75;
        color: #c8c8c8;
        background: #2b2b2b;
        padding: 48px 72px 96px;
    }

    article {
        max-width: 780px;
        margin: 0 auto;
    }

    h1, h2, h3, h4, h5, h6 {
        font-weight: 600;
        line-height: 1.25;
        margin-top: 1.75em;
        margin-bottom: 0.5em;
        color: #efefef;
    }

    h1 { font-size: 2em; border-bottom: 1px solid #444; padding-bottom: 0.3em; }
    h2 { font-size: 1.5em; border-bottom: 1px solid #444; padding-bottom: 0.3em; }
    h3 { font-size: 1.25em; }
    h4 { font-size: 1em; }
    h5 { font-size: 0.875em; }
    h6 { font-size: 0.85em; color: #888; }

    article > h1:first-child,
    article > h2:first-child { margin-top: 0; }

    p { margin-bottom: 1em; }

    a { color: #6ab0f5; text-decoration: none; }
    a:hover { text-decoration: underline; }

    strong { font-weight: 600; color: #e8e8e8; }
    em { font-style: italic; }
    del { color: #777; text-decoration: line-through; }

    code {
        font-family: 'SF Mono', 'Menlo', 'Monaco', 'Consolas', monospace;
        font-size: 0.875em;
        background: #383838;
        border: 1px solid #4a4a4a;
        border-radius: 4px;
        padding: 0.15em 0.4em;
        color: #c8c8c8;
    }

    pre {
        background: #333333;
        border: 1px solid #444;
        border-radius: 6px;
        padding: 16px 20px;
        overflow-x: auto;
        margin-bottom: 1em;
        line-height: 1.5;
    }

    pre code {
        background: none;
        border: none;
        border-radius: 0;
        padding: 0;
        font-size: 0.875em;
        color: #c8c8c8;
    }

    blockquote {
        border-left: 4px solid #555;
        padding: 4px 16px;
        margin: 1em 0;
        color: #999;
    }

    blockquote p { margin-bottom: 0.5em; }
    blockquote p:last-child { margin-bottom: 0; }

    ul, ol {
        padding-left: 2em;
        margin-bottom: 1em;
    }

    li { margin-bottom: 0.3em; }
    li:last-child { margin-bottom: 0; }

    hr {
        border: none;
        border-top: 1px solid #444;
        margin: 2em 0;
    }

    img {
        max-width: 100%;
        height: auto;
        border-radius: 6px;
    }

    table {
        border-collapse: collapse;
        width: 100%;
        margin-bottom: 1em;
    }

    th, td {
        border: 1px solid #444;
        padding: 8px 12px;
        text-align: left;
    }

    th { background: #333; font-weight: 600; color: #e0e0e0; }
    tr:nth-child(even) { background: #303030; }
    """
}

private extension String {
    var htmlEscaped: String {
        self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
