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

struct UserGuideView: View {
    let onClose: () -> Void

    init(onClose: @escaping () -> Void = {}) {
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close User Guide")
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("TypeMagic User Guide")
                        .font(.title2)
                        .bold()

                    Section(header: guideHeader("Getting Started")) {
                        guideStep(number: "1", title: "Launch TypeMagic") {
                            Text("Find the wand icon in your menu bar. If it is hidden, enable it in Control Center → Menu Bar Only Apps.")
                        }
                        guideStep(number: "2", title: "Grant permissions") {
                            Text("Allow Accessibility and Input Monitoring so TypeMagic can read, correct, and paste text in other apps.")
                        }
                        guideStep(number: "3", title: "Enter API keys") {
                            Text("Open Settings (gear icon) to provide your preferred provider and API key, mirroring the Chrome extension schema.")
                        }
                    }

                    Divider()

                    Section(header: guideHeader("Using Cmd+Option+T")) {
                        guideStep(number: "1", title: "Select text in any app") {
                            Text("Highlight the text you want TypeMagic to fix. Most editors work out of the box.")
                        }
                        guideStep(number: "2", title: "Press Cmd + Option + T") {
                            Text("TypeMagic captures the selection, sends it through your chosen model, and replaces the text automatically when possible.")
                        }
                        guideStep(number: "3", title: "Clipboard fallback") {
                            Text("If an app blocks edits, TypeMagic copies the corrected text to your clipboard and prompts you to paste.")
                        }
                    }

                    Divider()

                    Section(header: guideHeader("Manual Panel")) {
                        guideStep(number: "1", title: "Manual input") {
                            Text("Paste or enter text in the Manual Text box, then choose Correct, Bulletize, or Summarize.")
                        }
                        guideStep(number: "2", title: "Tone + Markdown") {
                            Text("Use the tone picker and Markdown toggle to match the behavior you expect from the Chrome extension.")
                        }
                    }

                    Divider()

                    Section(header: guideHeader("Troubleshooting")) {
                        guideStep(number: "•", title: "Shortcut not firing") {
                            Text("Confirm TypeMagic is enabled in System Settings → Privacy & Security → Accessibility and Input Monitoring, then relaunch the app.")
                        }
                        guideStep(number: "•", title: "No replacement occurred") {
                            Text("Some apps only support the clipboard flow. Check the status message for guidance after each run.")
                        }
                    }

                    Text("Need more help?")
                        .font(.headline)
                    Text("Email support@typemagic.app or revisit the Chrome extension guide for provider-specific tips.")
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(width: 480, height: 560)
    }

    private func guideHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .textCase(.uppercase)
            .foregroundColor(.secondary)
    }

    private func guideStep<Content: View>(number: String, title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 28, height: 28)
                .overlay(Text(number).font(.subheadline).bold())
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                content()
                    .font(.footnote)
            }
        }
    }
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
            UserGuideView(onClose: { model.showUserGuide = false })
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