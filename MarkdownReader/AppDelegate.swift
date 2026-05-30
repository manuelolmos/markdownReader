//
//  AppDelegate.swift
//  MarkdownReader
//
//  Created by Manuel Olmos Gil on 30/05/2026.
//

import Cocoa
import UniformTypeIdentifiers

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!

    private var viewController: ViewController?

    func applicationDidFinishLaunching(_ notification: Notification) {
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
        viewController?.openFile(url: URL(fileURLWithPath: filename))
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
            if response == .OK, let url = panel.url {
                self?.viewController?.openFile(url: url)
            }
        }
    }
}

