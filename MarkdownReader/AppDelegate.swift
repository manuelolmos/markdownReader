//
//  AppDelegate.swift
//  MarkdownReader
//
//  Created by Manuel Olmos Gil on 30/05/2026.
//

import Cocoa
import UniformTypeIdentifiers

private class RecentDocumentController: NSDocumentController {
    override var maximumRecentDocumentCount: Int { 6 }
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!

    private var viewController: ViewController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = RecentDocumentController()
        let vc = ViewController()
        viewController = vc
        window.contentViewController = vc
        window.setContentSize(NSSize(width: 960, height: 720))
        window.minSize = NSSize(width: 400, height: 300)
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        let url = URL(fileURLWithPath: filename)
        viewController?.openFile(url: url)
        NSDocumentController.shared.noteNewRecentDocumentURL(url)
        return true
    }

    @IBAction func openDocument(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            UTType(filenameExtension: "md") ?? .plainText,
            UTType(filenameExtension: "markdown") ?? .plainText,
            UTType(filenameExtension: "txt") ?? .plainText
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.beginSheetModal(for: window) { [weak self] response in
            guard let self, response == .OK, let url = panel.url else { return }
            viewController?.openFile(url: url)
            NSDocumentController.shared.noteNewRecentDocumentURL(url)
        }
    }
}

