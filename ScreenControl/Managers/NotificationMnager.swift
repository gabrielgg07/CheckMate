import Foundation
import UserNotifications
import UIKit

final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private let keychain = KeychainHelper.standard
    private let service = "com.screencontrol.deviceToken"
    private let account = "apns_token"

    
    func register() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("❌ Notifications not granted")
            }
        }
    }



    // Retrieve saved token if needed
    func getSavedDeviceToken() -> String? {
        keychain.read(service: service, account: account)
    }

    // 🔥 Send device token to backend using JWT
    private func sendDeviceTokenToServer(_ token: String) {
        // Get the JWT saved by AuthManager
        guard let jwt = KeychainHelper.standard.read(service: "ScreenControl", account: "jwt_token") else {
            print("⚠️ No JWT found — user not authenticated.")
            return
        }
        print("sending request to \(APIConfig.baseURL)/auth/register_device with JWT: \(jwt)")
        guard let url = URL(string: "\(APIConfig.baseURL)/auth/register_device") else {
            print("❌ Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONEncoder().encode(["device_token": token])

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("⚠️ Failed to send device token: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("✅ Device token successfully registered with backend")
                } else {
                    print("⚠️ Backend returned \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }

    // MARK: Notification display handlers
    func userNotificationCenter(_ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        print("received foreground!")
        route(notification.request.content.userInfo)
        completionHandler([.banner, .sound])
    }


    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void)
    {
        print("received background!")
        let info = response.notification.request.content.userInfo
            route(info)
            completionHandler()
    }

    
    func handleDeviceToken(_ deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()

        print("🔥 REAL APNS TOKEN:", token)

        keychain.save(token, service: service, account: account)
        sendDeviceTokenToServer(token)
    }
    
    func route(_ info: [AnyHashable : Any]) {
        guard let action = info["action"] as? String else { return }
        
        print("info is \(info)")
        print(action)
        DispatchQueue.main.async {
            switch action {

            case "lock_now":
                AppState.shared.isLocked = true
                AppState.shared.lastAction = "Locked"
                AppState.shared.debugMessage = "🔒 Received lock command"
                ScreenTimeManager.shared.applyShield()
            case "unlock_now":
                AppState.shared.isLocked = false
                AppState.shared.lastAction = "Unlocked"
                AppState.shared.debugMessage = "🔓 Received unlock command"
                ScreenTimeManager.shared.removeShield()
            case "extend_time":
                if let minutes = info["minutes"] as? Int {
                    AppState.shared.unlockedUntil = Date().addingTimeInterval(Double(minutes) * 60)
                    AppState.shared.lastAction = "Extended \(minutes)m"
                    AppState.shared.debugMessage = "⏱️ Extended \(minutes) minutes"
                }

            case "sync_status":
                AppState.shared.debugMessage = "🔄 Silent sync received"

            default:
                print("Unknown action:", action)
            }
            print("updated too \(AppState.shared.debugMessage)")
        }
    }


}
