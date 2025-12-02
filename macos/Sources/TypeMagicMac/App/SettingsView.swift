import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var settingsStore: SettingsStore

    @State private var openAIKey: String = ""
    @State private var geminiKey: String = ""
    @State private var claudeKey: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Provider") {
                    Picker("Provider", selection: binding(for: \Settings.provider)) {
                        ForEach(ProviderType.allCases) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                    TextField("FastAPI Endpoint", text: binding(for: \Settings.fastApiEndpoint))
                    TextField("Ollama Endpoint", text: binding(for: \Settings.ollamaEndpoint))
                    TextField("Ollama Model", text: binding(for: \Settings.ollamaModel))
                    TextField("OpenAI Model", text: binding(for: \Settings.openAIModel))
                    TextField("Gemini Model", text: binding(for: \Settings.geminiModel))
                    TextField("Claude Model", text: binding(for: \Settings.claudeModel))
                }

                Section("System Prompt") {
                    TextEditor(text: binding(for: \Settings.customSystemPrompt))
                        .frame(height: 100)
                }

                Section("Secrets") {
                    SecureField("OpenAI API Key", text: $openAIKey)
                    SecureField("Gemini API Key", text: $geminiKey)
                    SecureField("Claude API Key", text: $claudeKey)
                }
            }
            .navigationTitle("TypeMagic Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        settingsStore.updateSecret(\Secrets.openAIKey, value: openAIKey)
                        settingsStore.updateSecret(\Secrets.geminiKey, value: geminiKey)
                        settingsStore.updateSecret(\Secrets.claudeKey, value: claudeKey)
                        dismiss()
                    }
                }
            }
            .onAppear {
                openAIKey = settingsStore.secrets.openAIKey
                geminiKey = settingsStore.secrets.geminiKey
                claudeKey = settingsStore.secrets.claudeKey
            }
        }
        .frame(width: 480, height: 520)
    }

    private func binding<Value>(for keyPath: WritableKeyPath<Settings, Value>) -> Binding<Value> {
        Binding(
            get: { settingsStore.settings[keyPath: keyPath] },
            set: { newValue in settingsStore.updateSettings { $0[keyPath: keyPath] = newValue } }
        )
    }
}