import SwiftUI

@main
struct TypeMagicMacApp: App {
    @StateObject private var model = AppViewModel()

    var body: some Scene {
        MenuBarExtra("TypeMagic", systemImage: "wand.and.stars") {
            ControlPanelView(model: model)
        }
        .menuBarExtraStyle(.window)
    }
}
