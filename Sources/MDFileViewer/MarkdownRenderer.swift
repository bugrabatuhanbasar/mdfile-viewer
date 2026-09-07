import Foundation
import Markdown

struct TOCItem: Identifiable, Hashable {
    let id: String
    let level: Int
    let title: String
}

enum MarkdownRenderer {
    static func render(_ raw: String) -> (html: String, toc: [TOCItem]) {
        let document = Document(parsing: raw, options: [.parseBlockDirectives])
        var visitor = HTMLVisitor()
        let body = visitor.visit(document)
        return (body, visitor.toc)
    }
}

private struct HTMLVisitor: MarkupVisitor {
    typealias Result = String

    var toc: [TOCItem] = []
    private var slugCounts: [String: Int] = [:]

    mutating func defaultVisit(_ markup: Markup) -> String {
        markup.children.map { visit($0) }.joined()
    }

    mutating func visitDocument(_ document: Document) -> String {
        document.children.map { visit($0) }.joined(separator: "\n")
    }

    mutating func visitText(_ text: Text) -> String {
        escapeHTML(text.string)
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) -> String { "\n" }
    mutating func visitLineBreak(_ lineBreak: LineBreak) -> String { "<br>\n" }
    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) -> String { "<hr>" }

    mutating func visitEmphasis(_ emphasis: Emphasis) -> String {
        "<em>\(emphasis.children.map { visit($0) }.joined())</em>"
    }

    mutating func visitStrong(_ strong: Strong) -> String {
        "<strong>\(strong.children.map { visit($0) }.joined())</strong>"
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) -> String {
        "<del>\(strikethrough.children.map { visit($0) }.joined())</del>"
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) -> String {
        "<code>\(escapeHTML(inlineCode.code))</code>"
    }

    mutating func visitInlineHTML(_ inlineHTML: InlineHTML) -> String {
        inlineHTML.rawHTML
    }

    mutating func visitHTMLBlock(_ html: HTMLBlock) -> String {
        html.rawHTML
    }

    mutating func visitParagraph(_ paragraph: Paragraph) -> String {
        if let parent = paragraph.parent, parent is ListItem {
            let onlyChild = (parent.childCount == 1)
            if onlyChild {
                return paragraph.children.map { visit($0) }.joined()
            }
        }
        return "<p>\(paragraph.children.map { visit($0) }.joined())</p>"
    }

    mutating func visitHeading(_ heading: Heading) -> String {
        let inner = heading.children.map { visit($0) }.joined()
        let plain = plainText(heading)
        let baseSlug = slugify(plain)
        let count = (slugCounts[baseSlug] ?? 0) + 1
        slugCounts[baseSlug] = count
        let slug = count == 1 ? baseSlug : "\(baseSlug)-\(count - 1)"
        toc.append(TOCItem(id: slug, level: heading.level, title: plain))
        return "<h\(heading.level) id=\"\(slug)\">\(inner)</h\(heading.level)>"
    }

    mutating func visitLink(_ link: Link) -> String {
        let href = link.destination.map(escapeAttribute) ?? ""
        let title = link.title.map { " title=\"\(escapeAttribute($0))\"" } ?? ""
        let inner = link.children.map { visit($0) }.joined()
        return "<a href=\"\(href)\"\(title)>\(inner)</a>"
    }

    mutating func visitImage(_ image: Image) -> String {
        let src = image.source.map(escapeAttribute) ?? ""
        let alt = escapeAttribute(plainText(image))
        let title = image.title.map { " title=\"\(escapeAttribute($0))\"" } ?? ""
        return "<img src=\"\(src)\" alt=\"\(alt)\"\(title)>"
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> String {
        "<blockquote>\n\(blockQuote.children.map { visit($0) }.joined(separator: "\n"))\n</blockquote>"
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> String {
        let lang = codeBlock.language?.trimmingCharacters(in: .whitespaces) ?? ""
        let classAttr = lang.isEmpty ? "" : " class=\"language-\(escapeAttribute(lang))\""
        return "<pre><code\(classAttr)>\(escapeHTML(codeBlock.code))</code></pre>"
    }

    mutating func visitOrderedList(_ orderedList: OrderedList) -> String {
        let start = orderedList.startIndex
        let startAttr = start == 1 ? "" : " start=\"\(start)\""
        let items = orderedList.children.map { visit($0) }.joined(separator: "\n")
        return "<ol\(startAttr)>\n\(items)\n</ol>"
    }

    mutating func visitUnorderedList(_ unorderedList: UnorderedList) -> String {
        let items = unorderedList.children.map { visit($0) }.joined(separator: "\n")
        return "<ul>\n\(items)\n</ul>"
    }

    mutating func visitListItem(_ listItem: ListItem) -> String {
        let inner = listItem.children.map { visit($0) }.joined(separator: "\n")
        if let checkbox = listItem.checkbox {
            let checked = checkbox == .checked ? " checked" : ""
            return "<li class=\"task-list-item\"><input type=\"checkbox\" disabled\(checked)> \(inner)</li>"
        }
        return "<li>\(inner)</li>"
    }

    mutating func visitTable(_ table: Table) -> String {
        var html = "<table>\n"
        let headRow = table.head
        html += "<thead>\n<tr>"
        for (i, cell) in headRow.cells.enumerated() {
            let align = alignmentAttr(table.columnAlignments[safe: i] ?? nil)
            html += "<th\(align)>\(cell.children.map { visit($0) }.joined())</th>"
        }
        html += "</tr>\n</thead>\n"
        html += "<tbody>\n"
        for row in table.body.rows {
            html += "<tr>"
            for (i, cell) in row.cells.enumerated() {
                let align = alignmentAttr(table.columnAlignments[safe: i] ?? nil)
                html += "<td\(align)>\(cell.children.map { visit($0) }.joined())</td>"
            }
            html += "</tr>\n"
        }
        html += "</tbody>\n</table>"
        return html
    }

    private func alignmentAttr(_ alignment: Table.ColumnAlignment?) -> String {
        guard let alignment = alignment else { return "" }
        switch alignment {
        case .left: return " style=\"text-align:left\""
        case .center: return " style=\"text-align:center\""
        case .right: return " style=\"text-align:right\""
        }
    }

    private func plainText(_ markup: Markup) -> String {
        var out = ""
        for child in markup.children {
            if let text = child as? Text {
                out += text.string
            } else if let code = child as? InlineCode {
                out += code.code
            } else {
                out += plainText(child)
            }
        }
        return out
    }
}

private func escapeHTML(_ s: String) -> String {
    var out = ""
    out.reserveCapacity(s.count)
    for c in s {
        switch c {
        case "&": out += "&amp;"
        case "<": out += "&lt;"
        case ">": out += "&gt;"
        case "\"": out += "&quot;"
        case "'": out += "&#39;"
        default: out.append(c)
        }
    }
    return out
}

private func escapeAttribute(_ s: String) -> String {
    escapeHTML(s)
}

private func slugify(_ s: String) -> String {
    // Matches github-slugger: lowercase, drop chars that aren't letters,
    // digits, whitespace, hyphens, or underscores, then replace each
    // whitespace character with a single hyphen — WITHOUT collapsing
    // consecutive hyphens. This keeps our heading ids compatible with the
    // in-document `#fragment` links most authors write.
    var out = ""
    let space = CharacterSet.whitespacesAndNewlines
    for scalar in s.lowercased().unicodeScalars {
        if space.contains(scalar) {
            out.append("-")
        } else if CharacterSet.alphanumerics.contains(scalar)
                  || scalar == "-" || scalar == "_" {
            out.unicodeScalars.append(scalar)
        }
    }
    return out.isEmpty ? "section" : out
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
