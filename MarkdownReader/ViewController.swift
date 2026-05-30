import Cocoa
import WebKit

class ViewController: NSViewController {

    private var webView: WKWebView!

    override func loadView() {
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: config)
        webView.appearance = NSAppearance(named: .darkAqua)
        webView.underPageBackgroundColor = NSColor(srgbRed: 0.169, green: 0.169, blue: 0.169, alpha: 1)
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        render(markdown: welcomeText)
    }

    func openFile(url: URL) {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }
        render(markdown: content)
        view.window?.title = url.lastPathComponent
    }

    private func render(markdown: String) {
        webView.loadHTMLString(MarkdownRenderer.html(for: markdown), baseURL: Bundle.main.bundleURL)
    }

    private let welcomeText = """
    # Welcome to MarkdownReader

    Open a Markdown file to get started.

    - Use **File → Open** (⌘O) to pick a file
    - Or **drag and drop** a `.md` file onto the window

    ---

    ## Supported formatting

    **Bold**, *italic*, `inline code`, ~~strikethrough~~, and [links](https://example.com).

    ### Code blocks

    ```swift
    let greeting = "Hello, Markdown!"
    print(greeting)
    ```

    > Blockquotes are supported too.

    1. Ordered lists
    2. Work as expected
    3. With proper numbering

    ### Tables

    | Syntax | Example | Renders as |
    |--------|---------|------------|
    | `**text**` | `**bold**` | **bold** |
    | `*text*` | `*italic*` | *italic* |
    | `~~text~~` | `~~strike~~` | ~~strike~~ |
    """
}
