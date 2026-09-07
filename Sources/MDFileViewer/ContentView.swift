import SwiftUI

struct ContentView: View {
    let document: MarkdownDocument

    @State private var toc: [TOCItem] = []
    @State private var html: String = ""
    @State private var activeID: String?
    @State private var scrollRequest: ScrollRequest?
    @State private var showSidebar: Bool = true

    private struct ScrollRequest: Equatable {
        let id: String
        let nonce: Int
    }

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(showSidebar ? .all : .detailOnly)) {
            ScrollViewReader { proxy in
                List {
                    Section {
                        ForEach(Array(toc.enumerated()), id: \.element.id) { index, item in
                            TOCRow(item: item, isSelected: activeID == item.id) {
                                activeID = item.id
                                let nextNonce = (scrollRequest?.nonce ?? 0) &+ 1
                                scrollRequest = ScrollRequest(id: item.id, nonce: nextNonce)
                            }
                            .padding(.top, index == 0 ? 8 : 0)
                            .id(item.id)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    } header: {
                        Text("Contents")
                            .padding(.bottom, 4)
                    }
                }
                .listStyle(.sidebar)
                .navigationSplitViewColumnWidth(min: 200, ideal: 260, max: 360)
                .onChange(of: activeID) { _, newID in
                    guard let id = newID else { return }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        } detail: {
            MarkdownWebView(
                html: html,
                scrollToID: scrollRequest?.id,
                scrollNonce: scrollRequest?.nonce ?? 0,
                onActiveHeadingChange: { id in
                    if activeID != id { activeID = id }
                }
            )
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
        self.activeID = result.toc.first?.id
    }
}

private struct TOCRow: View {
    let item: TOCItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Text(item.title)
                .font(.system(
                    size: max(11, 13 - CGFloat(min(item.level, 4))),
                    weight: item.level <= 2 ? .semibold : .regular
                ))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .padding(.leading, CGFloat((item.level - 1) * 10))
            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}
