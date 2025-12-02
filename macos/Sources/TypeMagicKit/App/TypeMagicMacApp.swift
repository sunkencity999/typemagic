import SwiftUI

@available(macOS 13.0, *)
@available(*, deprecated, message: "TypeMagic now uses a native NSStatusItem. Please use TypeMagicAppCoordinator instead of embedding this scene.")
public struct TypeMagicMenuBarScene: Scene {
    public init() {}

    public var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}