import SwiftUI
import WebKit

extension Notification.Name {
    static let mdToggleFind = Notification.Name("MDFileViewer.toggleFind")
    static let mdFindNext = Notification.Name("MDFileViewer.findNext")
    static let mdFindPrevious = Notification.Name("MDFileViewer.findPrevious")
}

@MainActor
final class FindController: ObservableObject {
    weak var webView: WKWebView?

    @Published var isVisible: Bool = false
    @Published var query: String = ""
    @Published var lastResultFound: Bool? = nil

    func toggle() {
        if isVisible {
            close()
        } else {
            isVisible = true
        }
    }

    func close() {
        isVisible = false
        lastResultFound = nil
    }

    func findNext() { performFind(backwards: false) }
    func findPrevious() { performFind(backwards: true) }

    private func performFind(backwards: Bool) {
        guard let webView, !query.isEmpty else {
            lastResultFound = nil
            return
        }
        let config = WKFindConfiguration()
        config.backwards = backwards
        config.wraps = true
        config.caseSensitive = false
        webView.find(query, configuration: config) { [weak self] result in
            Task { @MainActor in
                self?.lastResultFound = result.matchFound
            }
        }
    }
}
