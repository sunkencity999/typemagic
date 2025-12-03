import SwiftUI

struct ControlPanelView: View {
    @ObservedObject var model: AppViewModel
    @State private var showSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            tonePicker
            Toggle("Use Markdown", isOn: Binding(get: { model.useMarkdown }, set: { model.updateMarkdown($0) }))
                .toggleStyle(SwitchToggleStyle())
            Text("Manual Text")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: $model.manualInput)
                .frame(minHeight: 140)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
            HStack {
                Button(action: { model.runManualCorrection() }) {
                    Label("Correct Text", systemImage: "text.badge.checkmark")
                }
                Button(action: { model.runManualCorrection(bulletize: true) }) {
                    Label("Bulletize", systemImage: "list.bullet")
                }
                Button(action: { model.runManualCorrection(summarize: true) }) {
                    Label("Summarize", systemImage: "text.page")
                }
            }
            .buttonStyle(.borderedProminent)
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Text("Selection Controls")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Button(action: { model.runFocusedCorrection() }) {
                        Label("Correct Selection", systemImage: "sparkles")
                    }
                    Button(action: { model.runFocusedCorrection(bulletize: true) }) {
                        Label("Bulletize Selection", systemImage: "list.clipboard")
                    }
                    Button(action: { model.runFocusedCorrection(summarize: true) }) {
                        Label("Summarize Selection", systemImage: "doc.text.magnifyingglass")
                    }
                }
                .buttonStyle(.bordered)
            }
            statusBar
        }
        .padding(16)
        .frame(width: 420)
        .sheet(isPresented: $showSettings) {
            SettingsView(settingsStore: model.settingsStore)
        }
        .sheet(isPresented: $model.showUserGuide) {
            UserGuideView()
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("TypeMagic for macOS")
                    .font(.headline)
                Text(model.statusMessage)
                    .font(.caption)
                    .foregroundStyle(model.isProcessing ? Color.orange : Color.secondary)
            }
            Spacer()
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
            Button(action: { model.showUserGuide = true }) {
                Image(systemName: "questionmark.circle")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open TypeMagic User Guide")
        }
    }

    private var tonePicker: some View {
        VStack(alignment: .leading) {
            Text("Tone")
                .font(.caption)
                .foregroundStyle(.secondary)
            Picker("Tone", selection: $model.selectedTone) {
                ForEach(Tone.allCases) { tone in
                    Text(tone.displayName).tag(tone)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var statusBar: some View {
        HStack {
            if model.isProcessing {
                ProgressView()
            }
            Text(model.statusMessage)
                .font(.footnote)
            Spacer()
        }
    }
}