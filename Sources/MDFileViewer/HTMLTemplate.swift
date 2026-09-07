import Foundation

enum HTMLTemplate {
    static func wrap(body: String) -> String {
        let templateURL = Bundle.main.url(forResource: "template", withExtension: "html")
        let template = templateURL.flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? Self.fallback
        return template.replacingOccurrences(of: "{{CONTENT}}", with: body)
    }

    private static let fallback = """
    <!doctype html><html><head><meta charset="utf-8"></head><body>{{CONTENT}}</body></html>
    """
}
