//
//  DeviceActivityMonitorExtension.swift
//  ScreenControlMonitor
//
//  Created by Gabriel Gonzalez on 11/14/25.
//

import DeviceActivity
import ManagedSettings
import ScreenTime
import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

// Optionally override any of the functions below.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let appGroupID = "group.com.13110inc.ScreenControl"
    private let selectionKey = "shared.selection"
    private let store = ManagedSettingsStore()

   // let screen = ScreenTimeManager.shared
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        let defaults = UserDefaults(suiteName: appGroupID)
        if let data = defaults?.data(forKey: "shared.selection.raw"){
           //let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {

            //store.shield.applications = selection.applicationTokens
            //store.shield.applicationCategories = .specific(selection.categoryTokens)
            //store.shield.webDomains = selection.webDomainTokens
        }

        defaults?.set("applied shields", forKey: "extension.debug")
        defaults?.set(true, forKey: "shouldApplyShield")
        //store.clearAllSettings()
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        // Handle the end of the interval.
        //print("Ended")
        // Example: Re-apply shield or change logic
        let defaults = UserDefaults(suiteName: "group.com.13110inc.ScreenControl")


        
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        // Handle the event reaching its threshold.
    }
    
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        
        // Handle the warning before the interval starts.
    }
    
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        
        // Handle the warning before the interval ends.
    }
    
    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)
        
        // Handle the warning before the event reaches its threshold.
    }
}



struct SharedSelection: Codable {
    let apps: [ApplicationToken]
    let categories: [ActivityCategoryToken]
    let webDomains: [WebDomainToken]
}
