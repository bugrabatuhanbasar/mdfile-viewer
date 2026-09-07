# MDFile Viewer — Sample Document

A quick demo of what this viewer renders.

## Text formatting

Regular text with **bold**, *italic*, ***bold italic***, ~~strikethrough~~, and `inline code`.
A [link to Apple](https://www.apple.com) and an autolink: <https://swift.org>.

> A blockquote. Useful for callouts.
>
> — Someone quotable

---

## Lists

Unordered:

- First item
- Second item
  - Nested item
  - Another nested
- Third item

Ordered:

1. Prepare
2. Build
3. Ship

Task list:

- [x] Design
- [x] Implement
- [ ] Ship v1

## Table

| Feature | Status | Notes |
| :--- | :---: | ---: |
| GFM Tables | ✅ | via swift-markdown |
| Task lists | ✅ | with checkboxes |
| Syntax highlight | ✅ | highlight.js |
| Dark mode | ✅ | follows system |

## Code

Swift:

```swift
import SwiftUI

@main
struct MDFileViewerApp: App {
    var body: some Scene {
        DocumentGroup(viewing: MarkdownDocument.self) { file in
            ContentView(document: file.document)
        }
    }
}
```

JSON:

```json
{
  "name": "MDFileViewer",
  "version": "1.0.0",
  "features": ["gfm", "toc", "dark-mode"]
}
```

Bash:

```bash
./scripts/build-app.sh --install
```

## Deep headings

### Level 3
#### Level 4
##### Level 5
###### Level 6

## Images

![Placeholder](https://via.placeholder.com/400x120.png?text=MDFile+Viewer)

Enjoy.
