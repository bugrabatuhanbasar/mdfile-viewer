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
        HSplitView {
            if showSidebar {
                sidebar
                    .frame(minWidth: 260, idealWidth: 320, maxWidth: 500)
                    .layoutPriority(0)
            }
            detail
                .frame(minWidth: 480)
                .layoutPriority(1)
        }
        .frame(minWidth: 720, minHeight: 480)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showSidebar.toggle() }
                } label: {
                    Image(systemName: "sidebar.leading")
                }
                .help("Toggle table of contents")
            }
        }
        .onAppear(perform: rebuild)
        .onChange(of: document.text) { _, _ in rebuild() }
    }

    private var sidebar: some View {
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
            .onChange(of: activeID) { _, newID in
                guard let id = newID else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
        }
    }

    private var detail: some View {
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
