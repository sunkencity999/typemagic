import AppKit
import Foundation

@MainActor
public final class ServicesProvider: NSObject {
    private let settingsStore: SettingsStore
    private let engine: TypeMagicEngine
    
    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        self.engine = TypeMagicEngine(settingsStore: settingsStore)
        super.init()
    }
    
    @objc func correctText(_ pboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard let text = pboard.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            error.pointee = "No text provided" as NSString
            return
        }
        
        Task { @MainActor in
            do {
                let request = CorrectionRequest(
                    tone: .preserve,
                    bulletize: false,
                    summarize: false,
                    useMarkdown: self.settingsStore.settings.useMarkdown
                )
                let corrected = try await self.engine.correctServiceText(text, request: request)
                
                pboard.clearContents()
                pboard.setString(corrected, forType: .string)
            } catch {
                NSLog("TypeMagic Service Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func correctTextFormal(_ pboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        correctWithTone(pboard, tone: .professional, error: error)
    }
    
    @objc func correctTextCasual(_ pboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        correctWithTone(pboard, tone: .casual, error: error)
    }
    
    @objc func summarizeText(_ pboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard let text = pboard.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            error.pointee = "No text provided" as NSString
            return
        }
        
        Task { @MainActor in
            do {
                let request = CorrectionRequest(
                    tone: .preserve,
                    bulletize: false,
                    summarize: true,
                    useMarkdown: self.settingsStore.settings.useMarkdown
                )
                let corrected = try await self.engine.correctServiceText(text, request: request)
                
                pboard.clearContents()
                pboard.setString(corrected, forType: .string)
            } catch {
                NSLog("TypeMagic Service Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func bulletizeText(_ pboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard let text = pboard.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            error.pointee = "No text provided" as NSString
            return
        }
        
        Task { @MainActor in
            do {
                let request = CorrectionRequest(
                    tone: .preserve,
                    bulletize: true,
                    summarize: false,
                    useMarkdown: self.settingsStore.settings.useMarkdown
                )
                let corrected = try await self.engine.correctServiceText(text, request: request)
                
                pboard.clearContents()
                pboard.setString(corrected, forType: .string)
            } catch {
                NSLog("TypeMagic Service Error: \(error.localizedDescription)")
            }
        }
    }
    
    private func correctWithTone(_ pboard: NSPasteboard, tone: Tone, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard let text = pboard.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            error.pointee = "No text provided" as NSString
            return
        }
        
        Task { @MainActor in
            do {
                let request = CorrectionRequest(
                    tone: tone,
                    bulletize: false,
                    summarize: false,
                    useMarkdown: self.settingsStore.settings.useMarkdown
                )
                let corrected = try await self.engine.correctServiceText(text, request: request)
                
                pboard.clearContents()
                pboard.setString(corrected, forType: .string)
            } catch {
                NSLog("TypeMagic Service Error: \(error.localizedDescription)")
            }
        }
    }
}
