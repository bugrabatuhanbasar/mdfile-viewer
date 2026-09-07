import SwiftUI

struct ContentView: View {
    let document: MarkdownDocument

    @State private var toc: [TOCItem] = []
    @State private var html: String = ""
    @State private var selectedID: String?
    @State private var scrollTarget: String?
    @State private var showSidebar: Bool = true

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(showSidebar ? .all : .detailOnly)) {
            List(selection: $selectedID) {
                Section("Contents") {
                    ForEach(toc) { item in
                        Button {
                            selectedID = item.id
                            scrollTarget = item.id
                        } label: {
                            HStack {
                                Text(item.title)
                                    .font(.system(size: 13 - CGFloat(min(item.level, 4)), weight: item.level <= 2 ? .semibold : .regular))
                                    .padding(.leading, CGFloat((item.level - 1) * 10))
                                    .lineLimit(2)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 200, ideal: 260, max: 360)
        } detail: {
            MarkdownWebView(html: html, scrollToID: scrollTarget)
                .background(Color(NSColor.textBackgroundColor))
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    withAnimation { showSidebar.toggle() }
                } label: {
                    Image(systemName: "sidebar.leading")
                }
                .help("Toggle table of contents")
            }
        }
        .onAppear(perform: rebuild)
        .onChange(of: document.text) { _, _ in rebuild() }
    }

    private func rebuild() {
        let result = MarkdownRenderer.render(document.text)
        self.toc = result.toc
        self.html = HTMLTemplate.wrap(body: result.html)
    }
}
