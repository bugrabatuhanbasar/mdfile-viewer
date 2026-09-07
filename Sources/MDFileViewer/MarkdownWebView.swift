import SwiftUI
import WebKit

final class MarkdownWebCoordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    weak var webView: WKWebView?
    var onActiveHeadingChange: ((String) -> Void)?

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

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard message.name == "activeHeading",
              let id = message.body as? String,
              !id.isEmpty else { return }
        onActiveHeadingChange?(id)
    }

    private func isSameDocumentAnchor(_ url: URL, in webView: WKWebView) -> Bool {
        guard url.fragment != nil else { return false }
        guard let current = webView.url else {
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

private let scrollSpyScript = """
(function(){
  function collect(){
    return Array.from(document.querySelectorAll('h1[id],h2[id],h3[id],h4[id],h5[id],h6[id]'));
  }
  var headings = collect();
  var current = null;
  function report(id){
    if (!id || id === current) return;
    current = id;
    try { window.webkit.messageHandlers.activeHeading.postMessage(id); } catch(e){}
  }
  function update(){
    if (headings.length === 0) { headings = collect(); if (headings.length === 0) return; }
    var threshold = window.scrollY + Math.max(80, window.innerHeight * 0.2);
    var active = headings[0];
    for (var i = 0; i < headings.length; i++) {
      var top = headings[i].getBoundingClientRect().top + window.scrollY;
      if (top <= threshold) active = headings[i];
      else break;
    }
    report(active.id);
  }
  var ticking = false;
  function onScroll(){
    if (ticking) return;
    ticking = true;
    window.requestAnimationFrame(function(){ update(); ticking = false; });
  }
  window.addEventListener('scroll', onScroll, {passive:true});
  window.addEventListener('resize', onScroll);
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function(){ headings = collect(); update(); });
  } else {
    update();
  }
})();
"""

struct MarkdownWebView: NSViewRepresentable {
    let html: String
    var scrollToID: String?
    var scrollNonce: Int = 0
    var onActiveHeadingChange: ((String) -> Void)?

    func makeCoordinator() -> MarkdownWebCoordinator { MarkdownWebCoordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptCanOpenWindowsAutomatically = false

        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "activeHeading")
        let userScript = WKUserScript(source: scrollSpyScript,
                                      injectionTime: .atDocumentEnd,
                                      forMainFrameOnly: true)
        controller.addUserScript(userScript)
        config.userContentController = controller

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        context.coordinator.webView = webView
        context.coordinator.onActiveHeadingChange = onActiveHeadingChange
        loadHTML(into: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.onActiveHeadingChange = onActiveHeadingChange
        if context.coordinator.currentHTML != html {
            loadHTML(into: webView)
            context.coordinator.currentHTML = html
            context.coordinator.lastScrollNonce = 0
        }
        if let id = scrollToID, scrollNonce != context.coordinator.lastScrollNonce {
            context.coordinator.lastScrollNonce = scrollNonce
            let js = "var el=document.getElementById(\(jsString(id))); if(el){el.scrollIntoView({behavior:'smooth', block:'start'});}"
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    private func loadHTML(into webView: WKWebView) {
        let baseURL = Bundle.main.resourceURL
        webView.loadHTMLString(html, baseURL: baseURL)
    }

    private func jsString(_ s: String) -> String {
        if let data = try? JSONSerialization.data(withJSONObject: [s]),
           let str = String(data: data, encoding: .utf8) {
            return String(str.dropFirst().dropLast())
        }
        return "\"\""
    }
}

extension MarkdownWebCoordinator {
    private static var currentHTMLKey: UInt8 = 0
    private static var lastScrollNonceKey: UInt8 = 0
    var currentHTML: String? {
        get { objc_getAssociatedObject(self, &Self.currentHTMLKey) as? String }
        set { objc_setAssociatedObject(self, &Self.currentHTMLKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    var lastScrollNonce: Int {
        get { (objc_getAssociatedObject(self, &Self.lastScrollNonceKey) as? Int) ?? 0 }
        set { objc_setAssociatedObject(self, &Self.lastScrollNonceKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}
