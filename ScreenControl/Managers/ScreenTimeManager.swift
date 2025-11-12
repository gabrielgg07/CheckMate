import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

@MainActor
class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()
    private let store = ManagedSettingsStore()

    @Published var authorized = false
    @Published var selection = FamilyActivitySelection()
    @Published var selectedAppNames: [String] = []

    // MARK: - Authorization
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authorized = true
        } catch {
            print("❌ ScreenTime auth failed:", error)
        }
    }

    // MARK: - Shielding
    func applyShield() {
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = .specific(selection.categoryTokens)
        print("🛡️ Shield applied for \(selection.applicationTokens.count) apps.")
        updateSelectedApps()
        saveSelection()
    }

    func removeShield() {
        store.clearAllSettings()
        print("🧹 Shields removed.")
        selectedAppNames.removeAll()
        saveSelection()
    }

    // MARK: - Selection Updates
    func updateSelectedApps() {
        selectedAppNames = selection.applications.compactMap { $0.localizedDisplayName }
        print("📋 Selected Apps:", selectedAppNames)
    }

    // MARK: - Persistence
    private let selectionKey = "SavedFamilyActivitySelection"

    func saveSelection() {
        do {
            let data = try JSONEncoder().encode(selection)
            UserDefaults.standard.set(data, forKey: selectionKey)
            print("💾 Selection saved (\(selection.applicationTokens.count) apps)")
        } catch {
            print("⚠️ Failed to encode selection:", error)
        }
    }

    func loadSelection() {
        if let data = UserDefaults.standard.data(forKey: selectionKey),
           let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = saved
            updateSelectedApps()
            print("📂 Loaded saved selection (\(selection.applicationTokens.count) apps)")
        } else {
            print("⚠️ No saved selection found.")
        }
    }
    
    @MainActor
    func requestAccess() async {
        guard let url = URL(string: "\(APIConfig.baseURL)/health") else {
            print("❌ Invalid backend URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var health: Bool = false

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                return
            }

            if httpResponse.statusCode == 200 {
                if let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let status = result["status"] as? String, status == "ok" {
                    print("✅ Backend healthy!")
                    health = true
                } else {
                    print("⚠️ Unexpected JSON:", String(data: data, encoding: .utf8) ?? "")
                    health = false
                }
            } else {
                print("❌ Health check failed with status:", httpResponse.statusCode)
                health = false
            }

        } catch {
            print("❌ Network error:", error.localizedDescription)
            health = false
        }
        
        if health {
            self.removeShield()
        }
    }

}
