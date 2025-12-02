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
    private var coordinator: TypeMagicAppCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        coordinator = TypeMagicAppCoordinator()
    }
}
