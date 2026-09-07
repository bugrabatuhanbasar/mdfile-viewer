import SwiftUI
import WebKit

final class MarkdownWebCoordinator: NSObject, WKNavigationDelegate {
    weak var webView: WKWebView?

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow); return
        }
        if navigationAction.navigationType == .linkActivated {
            if isSameDocumentAnchor(url, in: webView) {
                let fragment = url.fragment ?? ""
                scroll(to: fragment, in: webView)
                decisionHandler(.cancel)
                return
            }
            if let scheme = url.scheme?.lowercased(),
               ["http", "https", "mailto", "tel"].contains(scheme) {
                NSWorkspace.shared.open(url)
            }
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    private func isSameDocumentAnchor(_ url: URL, in webView: WKWebView) -> Bool {
        guard url.fragment != nil else { return false }
        guard let current = webView.url else {
            // Loaded via loadHTMLString: any pure-fragment link (no scheme, no host) is same-doc.
            return url.scheme == nil && url.host == nil
        }
        return url.scheme == current.scheme &&
               url.host == current.host &&
               url.path == current.path
    }

    private func scroll(to fragment: String, in webView: WKWebView) {
        guard !fragment.isEmpty else { return }
        let decoded = fragment.removingPercentEncoding ?? fragment
        let encoded = jsString(decoded)
        let js = """
        (function(){
          var id = \(encoded);
          var el = document.getElementById(id) || document.querySelector('[name="' + id + '"]');
          if (el) el.scrollIntoView({behavior:'smooth', block:'start'});
        })();
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    private func jsString(_ s: String) -> String {
        if let data = try? JSONSerialization.data(withJSONObject: [s]),
           let str = String(data: data, encoding: .utf8) {
            return String(str.dropFirst().dropLast())
        }
        return "\"\""
    }
}

struct MarkdownWebView: NSViewRepresentable {
    let html: String
    var scrollToID: String?

    func makeCoordinator() -> MarkdownWebCoordinator { MarkdownWebCoordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        context.coordinator.webView = webView
        loadHTML(into: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        if context.coordinator.currentHTML != html {
            loadHTML(into: webView)
            context.coordinator.currentHTML = html
        }
        if let id = scrollToID {
            let js = "var el=document.getElementById(\(jsString(id))); if(el){el.scrollIntoView({behavior:'smooth', block:'start'});}"
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    private func loadHTML(into webView: WKWebView) {
        let baseURL = Bundle.main.resourceURL
        webView.loadHTMLString(html, baseURL: baseURL)
    }

    private func jsString(_ s: String) -> String {
        let data = try? JSONSerialization.data(withJSONObject: [s])
        if let data = data, let str = String(data: data, encoding: .utf8) {
            let trimmed = str.dropFirst().dropLast()
            return String(trimmed)
        }
        return "\"\""
    }
}

extension MarkdownWebCoordinator {
    private static var currentHTMLKey: UInt8 = 0
    var currentHTML: String? {
        get { objc_getAssociatedObject(self, &Self.currentHTMLKey) as? String }
        set { objc_setAssociatedObject(self, &Self.currentHTMLKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}
