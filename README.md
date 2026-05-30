# MarkdownReader

A minimal macOS Markdown viewer with a dark theme. No dependencies — the Markdown parser is written from scratch in Swift.

## Features

- Renders headers, paragraphs, bold, italic, strikethrough, inline code
- Fenced code blocks with language annotation
- Unordered and ordered lists
- Blockquotes
- Tables with column alignment
- Links and images
- Horizontal rules
- Dark theme (Typora-inspired)

## Usage

Open a `.md` or `.markdown` file via:
- **File → Open** (⌘O)
- Drag and drop a file onto the window
- Double-click a Markdown file in Finder (once associated)

## Requirements

- macOS 26.4+
- Xcode 26+

## Building

```bash
open MarkdownReader.xcodeproj
```

Then press ⌘R.

> **Note:** App Sandbox is disabled in the Debug configuration to allow WKWebView's helper processes to run. Re-enable it before App Store submission and add the appropriate entitlements.
