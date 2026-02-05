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
    @Published var selectedAppBundleIDs: [String] = []
    @Published var selectedAppNames: [String] = []
    @Published var isLoading = true
    
    private let appGroupID = "group.com.13110inc.ScreenControl"
    private let selectionKey = "shared.selection"

    
    init() {
        Task {
            print("App group available:",
                  FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID))

            await self.refreshAuthorization()
            self.reapplyShieldOnLaunch()
            self.loadSelection()       // <-- IMPORTANT

        }
    }


    func refreshAuthorization() async {
        await MainActor.run { self.isLoading = true }
        do {
            // Re-requesting does NOT show the prompt again if already granted
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } catch {
            print("❌ Authorization request failed:", error)
        }

        let status = AuthorizationCenter.shared.authorizationStatus

        await MainActor.run {
            self.authorized = (status == .approved)
            self.isLoading = false
        }
    }

    // MARK: - Authorization
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } catch {
            print("❌ ScreenTime auth failed:", error)
        }

        await refreshAuthorization()
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
        TokenStorage.save(tokens: selection.applicationTokens)
        print("💾 Saved \(selection.applicationTokens.count) tokens")
    }





    func saveSelection() {
        let shared = SharedSelection(selection)
        do {
            let defaults = UserDefaults(suiteName: appGroupID)
            let data = try JSONEncoder().encode(shared)
            UserDefaults(suiteName: appGroupID)?.set(data, forKey: selectionKey)
            
            if let rawData = try? JSONEncoder().encode(selection) {
                if let jsonString = String(data: rawData, encoding: .utf8) {
                    print("RAW JSON:\n\(jsonString)")
                } else {
                    print("❌ Could not decode JSON string")
                }
                    defaults?.set(rawData, forKey: "shared.selection.raw")
                    print("saved raw selection")
            }
            print("💾 Saved selection to App Group: \(shared.apps.count) apps, \(shared.categories.count) categories, \(shared.webDomains.count) domains")
        } catch {
            print("❌ Failed to encode selection:", error)
        }
    }



    func loadSelection() {
        guard
            let data = UserDefaults(suiteName: appGroupID)?.data(forKey: selectionKey),
            let stored = try? JSONDecoder().decode(SharedSelection.self, from: data)
        else {
            print("⚠️ No saved selection found in App Group.")
            return
        }

        self.selection = stored.toFamilySelection()
        print("📂 Loaded selection from App Group: \(self.selection.applicationTokens.count) apps")
    }


    
    func reapplyShieldOnLaunch() {
        guard !selection.applicationTokens.isEmpty else { return }

        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens

        print("🔄 Re-applied shields on launch for \(selection.applicationTokens.count) apps")
    }


    
    func test30SecondUnlock() {
        // 1. Remove shield NOW (user gets temporary access)

        print("🟢 Temporary unlock started (600 seconds)")

        let center = DeviceActivityCenter()
        
        let calendar = Calendar.current
        let now = Date()

        let startDate = now     // 1 minute later
        let endDate   = now.addingTimeInterval(900)    // 15 minutes later

        let startComponents = calendar.dateComponents([.hour, .minute], from: startDate)
        let endComponents   = calendar.dateComponents([.hour, .minute], from: endDate)

        print("Start:", startComponents)
        print("End:", endComponents)

        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: false
        )

        do {
            try center.startMonitoring(.thirtySecondTest, during: schedule)
            print("⏱️ Scheduled!")
        } catch {
            print("❌ Failed to start monitoring:", error)
        }

        let activities = center.activities
        print("🔍 Registered DeviceActivity:", activities)
        //let defaults = UserDefaults(suiteName: "group.com.13110inc.ScreenControl")
        let defaults = UserDefaults(suiteName: "group.com.13110inc.ScreenControl")

        print("STATUS:", defaults?.string(forKey: "extension.status") ?? "none")
        print("DEBUG:", defaults?.string(forKey: "extension.debug") ?? "none")
        print("shouldApplyShield:", defaults?.bool(forKey: "shouldApplyShield") ?? false)





    }


}

import DeviceActivity

extension DeviceActivityName {
    static let thirtySecondTest = Self("thirtySecondTest")
}

import FamilyControls



struct SharedSelection: Codable {
    let apps: [ApplicationToken]
    let categories: [ActivityCategoryToken]
    let webDomains: [WebDomainToken]

    init(_ selection: FamilyActivitySelection) {
        self.apps = Array(selection.applicationTokens)
        self.categories = Array(selection.categoryTokens)
        self.webDomains = Array(selection.webDomainTokens)
    }

    func toFamilySelection() -> FamilyActivitySelection {
        var s = FamilyActivitySelection()
        s.applicationTokens = Set(apps)
        s.categoryTokens = Set(categories)
        s.webDomainTokens = Set(webDomains)
        return s
    }
}



