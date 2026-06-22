import UIKit
import WebKit
import UniformTypeIdentifiers

class ViewController: UIViewController {

    private var webView: WKWebView!
    private var currentURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupNavigationBar()
        render(markdown: welcomeText)
    }

    private func setupWebView() {
        webView = WKWebView(frame: view.bounds)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(webView)
    }

    private func setupNavigationBar() {
        title = "MarkdownReader"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "folder.badge.plus"),
            style: .plain,
            target: self,
            action: #selector(openDocument)
        )
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    @objc private func openDocument() {
        let types: [UTType] = [
            UTType(filenameExtension: "md") ?? .plainText,
            UTType(filenameExtension: "markdown") ?? .plainText,
            .plainText
        ]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    func openFile(url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }
        currentURL = url
        title = url.lastPathComponent
        render(markdown: content)
    }

    private func render(markdown: String) {
        webView.loadHTMLString(MarkdownRenderer.html(for: markdown), baseURL: Bundle.main.bundleURL)
    }

    private let welcomeText = """
    # Welcome to MarkdownReader

    Open a Markdown file to get started.

    - Tap the **folder icon** (top right) to pick a file
    - Or open a `.md` file from the Files app

    ---

    ## Supported formatting

    **Bold**, *italic*, `inline code`, ~~strikethrough~~, and [links](https://example.com).

    ### Code blocks

    ```swift
    let greeting = "Hello, Markdown!"
    print(greeting)
    ```

    > Blockquotes are supported too.

    ### Tables

    | Syntax | Example | Renders as |
    |--------|---------|------------|
    | `**text**` | `**bold**` | **bold** |
    | `*text*` | `*italic*` | *italic* |
    | `~~text~~` | `~~strike~~` | ~~strike~~ |
    """
}

extension ViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        openFile(url: url)
    }
}
