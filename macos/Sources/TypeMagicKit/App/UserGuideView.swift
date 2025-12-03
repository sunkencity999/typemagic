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
                        guideStep(number: "1", title: "Copy the text you want to improve") {
                            Text("Highlight any text, press ⌘C, and keep the cursor near the original location. This ensures macOS grants TypeMagic access to the content.")
                        }
                        guideStep(number: "2", title: "Press Cmd + Option + T") {
                            Text("TypeMagic reads your clipboard, calls the selected AI provider, and writes the improved text back to the clipboard.")
                        }
                        guideStep(number: "3", title: "Paste the corrected result") {
                            Text("Return to your document and paste (⌘V). Because the workflow is clipboard-first, it works consistently across sandboxed macOS apps.")
                        }
                        guideStep(number: "4", title: "Watch the wand badge") {
                            Text("When new clipboard text is ready, the menu-bar wand turns dark and shows a gold badge. Once you paste the content, it returns to its idle glow.")
                        }
                    }

                    Divider()

                    Section(header: guideHeader("Manual Panel")) {
                        guideStep(number: "1", title: "Manual input") {
                            Text("Paste text directly into the Manual Text box, then click Correct, Bulletize, or Summarize. The corrected text replaces the input and is copied to your clipboard automatically.")
                        }
                        guideStep(number: "2", title: "Tone + Markdown") {
                            Text("Use the tone picker and Markdown toggle to match the output style you prefer before copying it back into other apps.")
                        }
                    }

                    Divider()

                    Section(header: guideHeader("Troubleshooting")) {
                        guideStep(number: "•", title: "Shortcut not firing") {
                            Text("Confirm TypeMagic is enabled in System Settings → Privacy & Security → Accessibility and Input Monitoring, and that you copied text before pressing Cmd+Option+T.")
                        }
                        guideStep(number: "•", title: "Clipboard stayed unchanged") {
                            Text("Re-copy the text and try again—some editors clear the clipboard after short delays. The status line in the popover shows the last operation result. Also, check the menu-bar badge for any error messages.")
                        }
                    }

                    Text("Need more help?")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email support@typemagic.pro for assistance.")
                        Link("Visit typemagic.pro for tutorials and updates", destination: URL(string: "https://typemagic.pro")!)
                    }
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
