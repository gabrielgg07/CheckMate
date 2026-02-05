//
//  ScreenControlApp.swift
//  ScreenControl
//
//  Created by Gabriel Gonzalez on 11/9/25.
//

import SwiftUI

@main
struct ScreenControlApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var appState = AppState.shared
    @StateObject var screen = ScreenTimeManager.shared
    init() {
        //NotificationManager.shared.register()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                .environmentObject(appState)
                .environmentObject(screen)
        }
    }
}



class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication,
         didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

        NotificationManager.shared.handleDeviceToken(deviceToken)
    }

    func application(_ application: UIApplication,
         didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for APNs:", error)
    }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("recieved backgground")
        NotificationManager.shared.route(userInfo)
        completionHandler(.newData)
    }

}
