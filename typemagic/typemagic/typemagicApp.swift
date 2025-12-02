//
//  typemagicApp.swift
//  typemagic
//
//  Created by Christopher Bradford on 12/2/25.
//

import SwiftUI
import AppKit
import TypeMagicKit

@main
struct TypeMagicApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var coordinator: AnyObject?

    func applicationDidFinishLaunching(_ notification: Notification) {
        coordinator = startTypeMagicStatusItemApp()
    }
}
