import SwiftUI

public struct TypeMagicMenuBarScene: Scene {
    @StateObject private var model: AppViewModel

    public init() {
        let store = SettingsStore()
        _model = StateObject(wrappedValue: AppViewModel(settingsStore: store))
    }

    public var body: some Scene {
        MenuBarExtra("TypeMagic", systemImage: "wand.and.stars") {
            ControlPanelView(model: model)
        }
        .menuBarExtraStyle(.window)
    }
}
