import Foundation
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    @Published private(set) var settings: Settings
    @Published private(set) var secrets: Secrets

    private let defaults: UserDefaults
    private let keychainService = "com.typemagic.mac"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.settings = SettingsStore.loadSettings(from: defaults)
        self.secrets = SettingsStore.loadSecrets(service: keychainService)
    }

    func updateSettings(_ mutate: (inout Settings) -> Void) {
        var copy = settings
        mutate(&copy)
        settings = copy
        persistSettings()
    }

    func updateSecret(_ keyPath: WritableKeyPath<Secrets, String>, value: String) {
        var copy = secrets
        copy[keyPath: keyPath] = value
        secrets = copy
        persistSecrets()
    }

    private func persistSettings() {
        defaults.set(settings.provider.rawValue, forKey: "provider")
        defaults.set(settings.openAIModel, forKey: "openAIModel")
        defaults.set(settings.geminiModel, forKey: "geminiModel")
        defaults.set(settings.claudeModel, forKey: "claudeModel")
        defaults.set(settings.fastApiEndpoint, forKey: "fastApiEndpoint")
        defaults.set(settings.ollamaEndpoint, forKey: "ollamaEndpoint")
        defaults.set(settings.ollamaModel, forKey: "ollamaModel")
        defaults.set(settings.useMarkdown, forKey: "useMarkdown")
        defaults.set(settings.customSystemPrompt, forKey: "customSystemPrompt")
    }

    private func persistSecrets() {
        try? KeychainHelper.save(secrets.openAIKey, service: keychainService, account: "openAIKey")
        try? KeychainHelper.save(secrets.geminiKey, service: keychainService, account: "geminiKey")
        try? KeychainHelper.save(secrets.claudeKey, service: keychainService, account: "claudeKey")
    }

    private static func loadSettings(from defaults: UserDefaults) -> Settings {
        var settings = Settings.default
        if let providerRaw = defaults.string(forKey: "provider"),
           let provider = ProviderType(rawValue: providerRaw) {
            settings.provider = provider
        }
        settings.openAIModel = defaults.string(forKey: "openAIModel") ?? settings.openAIModel
        settings.geminiModel = defaults.string(forKey: "geminiModel") ?? settings.geminiModel
        settings.claudeModel = defaults.string(forKey: "claudeModel") ?? settings.claudeModel
        settings.fastApiEndpoint = defaults.string(forKey: "fastApiEndpoint") ?? settings.fastApiEndpoint
        settings.ollamaEndpoint = defaults.string(forKey: "ollamaEndpoint") ?? settings.ollamaEndpoint
        settings.ollamaModel = defaults.string(forKey: "ollamaModel") ?? settings.ollamaModel
        settings.useMarkdown = defaults.bool(forKey: "useMarkdown")
        settings.customSystemPrompt = defaults.string(forKey: "customSystemPrompt") ?? settings.customSystemPrompt
        return settings
    }

    private static func loadSecrets(service: String) -> Secrets {
        var secrets = Secrets()
        secrets.openAIKey = KeychainHelper.load(service: service, account: "openAIKey")
        secrets.geminiKey = KeychainHelper.load(service: service, account: "geminiKey")
        secrets.claudeKey = KeychainHelper.load(service: service, account: "claudeKey")
        return secrets
    }
}