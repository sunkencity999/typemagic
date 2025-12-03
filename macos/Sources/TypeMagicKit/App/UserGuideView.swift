import SwiftUI

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
                            Text("When prompted, allow Accessibility and Input Monitoring. These permissions let TypeMagic read, correct, and paste text in other apps.")
                        }
                        guideStep(number: "3", title: "Enter API keys") {
                            Text("Open Settings (gear icon) and provide your preferred provider + API key. The schema mirrors the Chrome extension so migration is simple.")
                        }
                    }

                    Divider()

                    Section(header: guideHeader("Using Cmd+Option+T")) {
                        guideStep(number: "1", title: "Select text in any app") {
                            Text("Highlight the text you want to improve. Most native and web editors are supported.")
                        }
                        guideStep(number: "2", title: "Press Cmd + Option + T") {
                            Text("TypeMagic captures the selection, runs the correction, and replaces the text automatically when the target app allows it.")
                        }
                        guideStep(number: "3", title: "Clipboard fallback") {
                            Text("If an app blocks direct edits, TypeMagic copies the selection, returns the corrected text to your clipboard, and notifies you to paste.")
                        }
                    }

                    Divider()

                    Section(header: guideHeader("Manual Panel")) {
                        guideStep(number: "1", title: "Manual input") {
                            Text("Paste or type text into the Manual Text box inside the popover and click Correct, Bulletize, or Summarize.")
                        }
                        guideStep(number: "2", title: "Tone + Markdown") {
                            Text("Use the tone picker and Markdown toggle to match the output style you prefer.")
                        }
                    }

                    Divider()

                    Section(header: guideHeader("Troubleshooting")) {
                        guideStep(number: "•", title: "Shortcut not firing") {
                            Text("Confirm TypeMagic is enabled in System Settings → Privacy & Security → Accessibility and Input Monitoring. Restart the app after toggling.")
                        }
                        guideStep(number: "•", title: "No replacement occurred") {
                            Text("Some apps require the clipboard fallback. Check the status message in the popover after running the shortcut.")
                        }
                    }

                    Text("Need more help?")
                        .font(.headline)
                    Text("Email support@typemagic.app or revisit the Chrome extension guide for provider-specific tips.")
                        .font(.body)
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
                Text(title).font(.subheadline).bold()
                content().font(.footnote)
            }
        }
    }
}
